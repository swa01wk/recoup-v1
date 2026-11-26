# ADR-021: Capture public AWS Health events with an EventBridge rule in every supported Region, forwarded to one archived bus in us-west-2, de-duplicated into PostgreSQL
Status: Accepted (designs the Q-15 decision; Stage 2a)    Date: 2026-11-27

**Context:** The free check (J-01, R-34) and the 12-month part of KPI-02 need a record of public AWS Health events that Recoup keeps itself. [Q-15](../product/QUESTIONS.md#q-15-public-incident-history-for-j-01--decided) decided to capture from Recoup's own account with EventBridge rules in every supported Region plus backup rules, forwarded to us-west-2 ([ADR-012](ADR-012-hosting-region-us-west-2.md) §2), de-duplicated as AWS advises, and to start as the first M0 spec, because history that isn't captured can never be shown. The application, database and worker won't exist on day one of M0. Health event text is untrusted input (NFR-09).

AWS facts (read 2026-11-27):
- **A rule is needed in each impacted Region.** Public events go to the impacted Region and to a backup Region only when a valid rule exists in the impacted Region ([public events](https://docs.aws.amazon.com/health/latest/ug/about-public-events.html)).
- **The single-rule shortcut doesn't cover public events.** Health's "simplified integration" (one rule in us-west-2) covers account-specific events only ([Region coverage](https://docs.aws.amazon.com/health/latest/ug/choosing-a-region.html)).
- **Backup Regions:** us-west-2 is the backup for every other commercial Region, and us-east-1 is the backup for us-west-2 ([Region coverage](https://docs.aws.amazon.com/health/latest/ug/choosing-a-region.html); [What's New, 2025-11](https://aws.amazon.com/about-aws/whats-new/2025/11/aws-health-amazon-eventbridge-flexibility-higher-resilience)). Backup copies carry `detail.backupEvent`.
- **Global events** need a rule in us-east-1 ([Region coverage](https://docs.aws.amazon.com/health/latest/ug/choosing-a-region.html)).
- **De-duplication:** AWS recommends de-duplicating on `eventArn` and `communicationId`, which stay the same in backup copies ([public events](https://docs.aws.amazon.com/health/latest/ug/about-public-events.html)).
- **Cross-Region routing:** EventBridge can send to an event bus in another Region, with every commercial Region supported as a destination ([What's New, 2021-11](https://aws.amazon.com/about-aws/whats-new/2021/11/amazon-eventbridge-cross-region-expands)).
- **Archive:** an archive keeps events indefinitely by default, and events can be replayed only to the bus they were archived from ([archive and replay](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-archive.html)).
- None of these pages states a support-plan requirement for EventBridge delivery of Health events. *Unverified either way*; the M0 spec checks it on Recoup's account.

**Decision:**
1. **A rule in every supported Region** on the default bus, matching `source: aws.health` and `detail.eventScopeCode: PUBLIC`. Its target is the central bus `recoup-health` in us-west-2.
   - The us-east-1 rule also matches global events.
   - Backup copies are **not** filtered out. Keeping both copies is the high-availability path, and step 3 removes the duplicates.
   - "Supported" means every commercial Region enabled in Recoup's account. The list lives in IaC config ([ADR-019](ADR-019-iac-cdk-and-handwritten-customer-template.md)), and the no-access check offers only Regions on it.
2. **The central bus in us-west-2 has:**
   - an **archive** with indefinite retention, encrypted with Recoup's KMS key. This is the lossless record from day one.
   - a rule targeting an **SQS queue** `health-intake` (SSE-KMS, 14-day retention), with a dead-letter queue.
3. **Intake (worker, `recoup_catalog` role per [ADR-018](ADR-018-tenant-isolation-row-level-security.md)):**
   - Store each message unchanged in `public_health_message`, with its SHA-256, delivery Region, `backupEvent` flag and receive time. The unique key `(event_arn, communication_id)` drops duplicates.
   - Rebuild the `public_incident` projection for that `eventArn`: service, event type, event Region, start, end, status and latest description, ordered by `lastUpdatedTime`.
4. **Day one, before the app exists:** the first spec ships points 1–2 only, ahead of G2 and G3 per [ADR-025](ADR-025-health-capture-before-g3.md) (rules, bus, archive, queue). Once intake runs, anything older than the queue's 14 days is replayed from the archive into the bus, so nothing captured is lost.
5. **Daily reconciliation, if AWS allows it:** a worker job calls the Health API from Recoup's account (Business Support+, Q-15) and inserts any public event the capture missed, labelled source `health_api`. *Unverified:* that `DescribeEvents` in Recoup's account returns public-scope events. The M0 spec checks it, and drops this step if it doesn't.
6. **History from before capture starts** is entered by P-06 through the operator console: service, Region, start, end, source URL on the AWS Health Dashboard, and capture date. It's labelled *entered by Recoup from the AWS Health Dashboard* everywhere it appears. No scraping (Q-15).
7. **Untrusted text:** descriptions are stored and shown as escaped text. They're never parsed for instructions or used to drive state; matching uses only service, Region and times (NFR-09).
8. **Alarms** (OBSERVABILITY.md, 2b): rule `FailedInvocations` in any Region, dead-letter queue depth above 0, and queue age above 1 hour.

**Alternatives:**
- *One rule in us-west-2 (simplified integration).* Rejected: it doesn't deliver public events.
- *Scrape the AWS Health Dashboard.* Rejected by Q-15: brittle, and it has no stable source to cite.
- *EventBridge → Lambda → database.* Rejected: a second runtime holding database credentials. SQS buffers until the worker is up, and the archive covers anything older.
- *Firehose to S3 as the raw record.* Not now: the archive gives the same day-one guarantee with fewer parts. S3 can be added later if we need to query raw history outside the database.

**Consequences:**
- Easier: capture starts before any app code; a Regional outage still reaches us through the backup copy; replay makes intake bugs recoverable.
- Harder: rules deploy per Region; EventBridge archive and cross-Region charges, which are small at this volume and costed in TECH_STACK.md; P-06 has to enter pre-capture history by hand.
- We must now: make this the first M0 spec, with a test that a duplicate or backup copy of a message changes nothing; verify the support-plan point and the reconciliation call on Recoup's account.
