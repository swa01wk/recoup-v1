# QUESTIONS: Recoup v1

Status: Open for Gate G1 · Date: 2026-11-27 · Requirements: [REQUIREMENTS.md](REQUIREMENTS.md)

Each question has the assumption (A-xx) we build on if nobody answers, and a recommendation with a confidence. Q-01 to Q-09 are PRD §16 #1–#9, kept in the same order. AWS facts are first-party and dated; anything not confirmed in AWS docs is marked **unverified**.

**Expensive to reverse** (project rules: the product owner decides): Q-02 pricing, Q-13 customer access scope, Q-18 auth, Q-21 model provider, Q-30 hosting region.

## Open questions by who must answer

### Product owner

| Q | Topic | Assumption (short) | Blocks |
|---|---|---|---|
| Q-02 | Pricing | Contingency; % after interviews | M2 (invoice), not M1 |
| Q-09 | Who signs G1–G5 | Product owner signs as PO and tech lead | **G1** |
| Q-10 | Approve PRD wording for new support plan names | NFR-10 uses current names | PRD revision |
| Q-13 | How customer logs reach Recoup | Customer uploads extracts; no log permission | **Stage 2** (ADR-003 scope) |
| Q-18 | Users, roles and sign-in | Named users; approver / contributor / viewer | **Stage 2** (auth) |
| Q-19 | Accounts per tenant | Several, each with its own role | Stage 2 |
| Q-21 | Agent steps in M1; model provider | No model in M1 | **Stage 2** (provider) |
| Q-22 | Deadline warning lead time | 14 and 3 days | M2 |
| Q-23 | Warning channel | Email via outbox | M2 |
| Q-24 | "One ready-to-file claim" | One packet per report | M1 |
| Q-25 | M-02 threshold | Not set in v1 | — |
| Q-26 | V-02 baseline | Grant rate alone | Pilot design |
| Q-27 | Retention and deletion; J-07 | Raw logs deleted 30 days after close | Stage 2 (SECURITY.md) |
| Q-28 | Recovery targets | RPO ≤5 min, RTO ≤4 h from M2 | Stage 2 |
| Q-29 | Availability target, accessibility, languages | WCAG 2.2 AA, English, no product SLA | Stage 2 |
| Q-30 | Hosting region | One region, not us-east-1 | **Stage 2** (cloud) |
| Q-31 | J-01 contact data; US-17 | Anonymous check, external booking link | M1 |
| Q-32 | P-06 operator, J-09, US-16 | Product owner acts as P-06 | M1 |
| Q-33 | V-03 hypothesis | Accept as hypothesis | G1 |
| Q-34 | KPI-11 | Accept, target ≥80% | G1 |
| Q-35 | Exact kill thresholds | KPI-02 <30%; KPI-10 <$10k | G1 |

### Interviews (KPI-01)

| Q | Topic | Assumption (short) |
|---|---|---|
| Q-03 | First 3–5 SLAs | API Gateway plus interviewees' top spend services |
| Q-04 | Share on a qualifying support plan | Majority |
| Q-06 | Next Signal use; demo | Unknown; demo before G1 |
| Q-07 | Read-only role acceptance; V-04 | Yes, if the list is short |
| Q-08 | Log retention | Often too short; design for partial evidence |

Interviews also feed Q-13 (what logs exist), Q-19 (account structure), Q-26 (past claims) and Q-12 (ask for a past SLA Credit line).

### AWS research

| Q | Topic | Assumption (short) |
|---|---|---|
| Q-05 | Reseller / MSP entitlement | Not supported in v1 |
| Q-11 | Member-account CUR 2.0 exports | Each member account exports its own data |
| Q-12 | Claim-to-Credit-line matching | Exact match or P-03 confirms |
| Q-14 | Deadline rule reading | Earlier reading |
| Q-15 | Public incident history for J-01 | Recoup records it from its own account |
| Q-16 | Health 90-day retention vs claim window | Store every event read; late connections fall back |
| Q-17 | Fallback input below a qualifying plan | Customer-entered incident list |
| Q-20 | AISPL and non-USD accounts | USD accounts sold by AWS Inc. only |

---

## Question details

### Q-02 Pricing: share of posted credits, and what %?
- **Assumption A-02:** contingency on *posted* credits only, % set after interviews. No pricing logic in M1.
- **Recommendation:** keep it out of the product until M-01 (invoice against reconciliation) is plausible; R-42 already records what an invoice would need. Confidence: high that nothing in M1 depends on it.
- **Who:** product owner. **Source:** PRD §16 #2.

### Q-03 Which 3–5 SLAs first?
- **Assumption A-03:** API Gateway first (its contract is already transcribed, with known defects, see [DISCOVERY.md](../discovery/DISCOVERY.md)); the rest from interviewees' top spend services. If interviews give no spend data by G3, use the largest services by spend in the first connected test accounts.
- **Who:** interviews. **Source:** PRD §16 #3. **Blocks:** R-16.

### Q-04 What share of targets have a qualifying support plan?
- **Assumption A-04:** a majority. Note the plan names changed (Q-10), and Business Support+ is priced per account from a low monthly minimum, so plan level may not track company size. Ask which plan each interviewee's production accounts are on.
- **Who:** interviews. **Source:** PRD §16 #4.

### Q-05 Under reseller or MSP arrangements, who may file and keep the credit?
- **Known:** customers who buy AWS Support through a reselling partner raise billing issues with that partner ([ADR-007](../adr/ADR-007-customer-files-claims-in-v1.md), AWS case-management docs read 2026-11-27).
- **Assumption A-05:** not supported in v1; such accounts are told so at connection.
- **Who:** AWS research plus the 2 MSP interviews. **Source:** PRD §16 #5.

### Q-06 Does any target already use Next Signal or a similar tool?
- **Assumption A-06:** unknown. The Next Signal demo (PRD §14, "demo before G1") is a G1 item in its own right.
- **Who:** interviews; the product owner books the demo. **Source:** PRD §16 #6.

### Q-07 Do customers accept a read-only role from an early-stage vendor? (+ proposed V-04)
- **Assumption A-07:** yes, if the permission list is short and the customer deploys the role ([ADR-003](../adr/ADR-003-customer-read-only-role.md)).
- **Proposal:** add V-04 "security reviewers approve a short, read-only, customer-deployed role from an early-stage vendor", proved by KPI-03 ≥30% and no request rejected for scope. Accepting this question's framing accepts V-04.
- **Who:** interviews (P-04 in each company, if possible). **Source:** PRD §16 #7.

### Q-08 Do customers keep request logs long enough for the claim window?
- **Assumption A-08:** often not; design for partial evidence (R-20: *unproven* when logs are missing).
- **Who:** interviews. **Source:** PRD §16 #8. Feeds Q-13.

### Q-09 Who signs G1–G5?
- **Assumption A-09:** the product owner signs as both product owner and tech lead; interview evidence stands in for client confirmation at G1.
- **Challenge:** one person signing both sides removes the check that G1 exists for. If no second person is available, record in STATUS.md which interview notes each G1 confirmation rests on.
- **Who:** product owner. **Source:** PRD §16 #9. **Blocks:** G1.

### Q-10 The support plan names in PRD §12 are outdated
- **Known (AWS, read 2026-11-27):**
  - AWS simplified Support into three paid plans: Business Support+, Enterprise Support and Unified Operations ([What's New, Dec 2025](https://aws.amazon.com/about-aws/whats-new/2025/12/aws-support-transformation-ai-powered-operations)).
  - Business Support (classic) and Enterprise On-Ramp are discontinued on 2027-01-01 ([AWS Support plans](https://docs.aws.amazon.com/awssupport/latest/user/aws-support-plans.html)); Developer Support also ends then ([AWS News Blog](https://aws.amazon.com/blogs/aws/new-and-enhanced-aws-support-plans-add-ai-capabilities-to-expert-guidance)).
  - The Health API needs Business Support+, Enterprise Support or Unified Operations; accounts not yet moved can use Business, Enterprise On-Ramp or Enterprise ([Health API reference](https://docs.aws.amazon.com/health/latest/APIReference/Welcome.html)). Some AWS pages (CLI reference, Health user guide) still give only the old names, so the docs disagree with each other.
- **Where the PRD is affected:** §12 (Support-plan dependency), §6 branch "support plan below Business", §8 F-15 "Business+ support" (now ambiguous, because Business Support+ is a plan name), §14 "segment on Business+".
- **Assumption A-10:** NFR-10 uses the current names. The PRD keeps its wording until the product owner approves a revision; then §12, §6, §8 and §14 are updated in both places with a dated note. From 2027-01-01 the "below" branch means Basic only.
- **Who:** product owner (approve the PRD edit). AWS research is done.

### Q-11 Can member accounts create their own CUR 2.0 export, or only the management account?
- **Known (AWS, read 2026-11-27, [CUR 2.0 table](https://docs.aws.amazon.com/cur/latest/userguide/table-dictionary-cur2.html)):**
  - A member account can create a CUR 2.0 export, and it contains only that member account's cost and usage. A management account's export covers the management account and all members.
  - A member account can export only data from the time it has been in its current organization.
  - The CUR 2.0 table inherits the organization's consolidated-billing settings.
  - Since 2026-04-14, Data Exports can deliver to an S3 bucket in a different account if that account's bucket policy allows it ([What's New](https://aws.amazon.com/about-aws/whats-new/2026/03/aws-data-exports-cross-account-delivery-cost)).
- **Unverified:** whether a management account can stop members from creating exports (for example with an SCP or billing access settings); whether a member's export can be backfilled by its own support case; which account's lines carry an SLA credit under consolidated billing (feeds Q-12).
- **Assumption A-11:** v1 connects each affected member account with its own role and its own export, which keeps access to that account's data only (least privilege). A management-account export is accepted only if the customer chooses it and P-04 accepts that it exposes every account's costs.
- **Stage 2 option, not decided:** cross-account delivery could send the export straight to a Recoup bucket, which removes the S3 read from the role but means Recoup holds the customer's full export. That trade-off belongs in an ADR-009 revision if pursued.
- **Recommendation:** prove member-account export and credit placement on a two-account test organization in M0. Confidence: high on the documented part, low on credit placement.
- **Who:** AWS research. **Source:** ADR-009 consequences. **Blocks:** R-25, R-42.

### Q-12 What rule matches a claim to its billing Credit line? (+ proposed US-18)
- **Known (AWS, read 2026-11-27, [line item details](https://docs.aws.amazon.com/cur/latest/userguide/Lineitem-columns.html)):** a `Credit` line item type covers credits AWS applied to the bill, with details in the description column; AWS may update a finalized month when it applies a credit afterwards.
- **Unverified:** the description text of an SLA credit; whether it carries the service's product code; which account and billing period it lands in; whether AWS posts one line per claim or merges several; tax treatment; whether the case ID appears anywhere.
- **Assumption A-12:** a Credit line in the claim's account, for the claim's service, in a billing period on or after the grant, whose amount equals the granted amount, is a match → *posted (verified)*. Anything else (amount differs, several candidates, no product code) is a *possible match* that P-03 confirms or rejects (US-18, R-43), recorded with who and when. Never match on amount alone.
- **Recommendation:** ask every interviewee who has received an SLA credit for the CUR rows of that credit, anonymised. That's the only way to fix the rule before M2. Confidence: medium that A-12 is close; low on details.
- **Who:** AWS research plus interviews and the first pilot claim. **Source:** ADR-009 consequences. **Blocks:** Stage 2 matching contract, R-42.

### Q-13 How does customer evidence (request logs, postmortems) reach Recoup? (+ proposed J-08, US-13)
- **Known:** eligibility needs the customer's own request data (PRD §6 J-03, §7 US-04, US-06). The ADR-003 role reads only billing data and Health ([ADR-003](../adr/ADR-003-customer-read-only-role.md) §4). The hackathon never read customer logs: its only "live" path reads a synthetic CloudWatch metric it injected itself ([DISCOVERY.md](../discovery/DISCOVERY.md), "Availability evidence").
- **Options:** (a) P-02 uploads log extracts for the incident window; no permission change. (b) Widen the role to read specific log groups or CloudWatch metrics, still read-only; needs an ADR-003 revision. **Unverified** for (b): whether a service's CloudWatch error metric matches its SLA's error definition (for API Gateway, the SLA counts only API Gateway internal errors).
- **Assumption A-13:** (a) in M1, with accepted formats listed per contract; raw files are handled per Q-27. Revisit (b) after interviews show what customers keep (Q-08).
- **Recommendation:** (a). It keeps the permission list short (Q-07) and works for logs kept outside AWS. Confidence: medium.
- **Who:** product owner (changes customer access scope), informed by interviews. **Blocks:** Stage 2, R-52.

### Q-14 How is "the end of the second billing cycle after the incident" read?
- **Known:** the API Gateway SLA sets the deadline as the end of the second billing cycle after the incident ([DISCOVERY.md](../discovery/DISCOVERY.md), "Catalog vs. the public SLA").
- **Two readings** for an incident in January: the end of February, or the end of March.
- **Assumption A-14:** use the earlier date for every deadline shown and every warning. A claim between the two dates is shown as "may have expired — check with AWS", not as claimable.
- **Recommendation:** ask AWS in a free Account and billing case from Recoup's own account, and record the answer per contract. Confidence: high that the earlier reading is the safe one.
- **Who:** AWS research. **Blocks:** R-30.

### Q-15 Where does J-01 get public incident history without customer access?
- **Known (AWS, read 2026-11-27, [Health concepts](https://docs.aws.amazon.com/health/latest/ug/aws-health-concepts-and-terms.html)):** public events appear in the AWS Health Dashboard and on the Service health page, which needs no sign-in. Health events can be viewed for up to 90 days. Public events aren't in AWS managed notifications; receiving them needs an EventBridge rule or a user-configured notification.
- **Unverified:** whether the Health API returns public events for the whole 90 days; any documented history beyond 90 days.
- **Assumption A-15:** Recoup's own account records public events continuously through EventBridge into its database from as early as possible. Incidents from before recording starts are entered by hand by P-06, each with its source URL and capture date. No scraping.
- **Recommendation:** start recording before M1 work begins, even as a small job. Each day not recorded is history the free check can never show. Confidence: high.
- **Who:** AWS research. **Blocks:** R-34.

### Q-16 AWS Health keeps events about 90 days; does that cover the claim window?
- **Known:** Health events can be viewed for up to 90 days, and organizational view keeps them 90 days with no increase ([aggregating events](https://docs.aws.amazon.com/health/latest/ug/aggregate-events.html), read 2026-11-27). The claim window can approach 90 days under the later reading of Q-14.
- **Assumption A-16:** Recoup stores every Health event it reads (R-12). For a connection made late in a window, account-specific events may already be gone; those incidents come from public events (A-15) or the customer (R-14) and stay *unproven* without logs.
- **Who:** AWS research. **Blocks:** R-12.

### Q-17 What is the fallback input below a qualifying plan? (+ proposed US-14)
- **Known:** the PRD §6 branch names a "Health Dashboard export". The Dashboard's event log shows the past 90 days ([account views](https://docs.aws.amazon.com/health/latest/ug/aws-health-account-views.html)). **Unverified:** that the console offers an export.
- **Assumption A-17:** a customer-entered incident list (service, region, start, end, source), labelled *customer-supplied* (R-14), plus public events (A-15).
- **Who:** AWS research.

### Q-18 Users, roles and sign-in within a tenant
- **Why:** approval must be bound to a person (R-36, R-38); case IDs and outcomes need who entered them (R-39, R-40). The PRD has no user model.
- **Assumption A-18:** each tenant has named users who sign in. Roles: *approver* (P-01) approves and revokes; *contributor* (P-02, P-03) supplies evidence, enters case IDs and outcomes, confirms matches; *viewer* (P-04) reads. The sign-in provider is chosen in Stage 2 with the product owner.
- **Who:** product owner (auth is expensive to reverse). **Blocks:** Stage 2.

### Q-19 How many AWS accounts per tenant?
- **Assumption A-19:** a tenant may connect several accounts, each with its own role and ExternalId ([ADR-003](../adr/ADR-003-customer-read-only-role.md) §1). Claims are per affected account, because the case is filed from that account ([ADR-007](../adr/ADR-007-customer-files-claims-in-v1.md) §1). Ask interviewees how their accounts are organised. Interacts with Q-11.
- **Who:** product owner, informed by interviews.

### Q-20 Accounts sold by AWS India (AISPL) or billed in other currencies
- **Known:** CUR 2.0 names the selling entity, and Amazon Web Services India Private Limited acts as a local reseller in India ([line item columns](https://docs.aws.amazon.com/cur/latest/userguide/table-dictionary-cur2-line-item.html), read 2026-11-27).
- **Unverified:** whether the same SLA terms and claim path apply to AISPL accounts; which currency their CUR amounts and credits are in.
- **Assumption A-20:** v1 supports accounts sold by Amazon Web Services, Inc. with USD amounts; others are told "not supported yet".
- **Recommendation:** answer this before outreach if Indian companies are in the first 10 interviews. Confidence: low on the facts.
- **Who:** AWS research plus product owner (target market).

### Q-21 Do the PRD §9 agent steps ship in M1, and on which model provider?
- **Why:** two agent steps sit in J-03 (M1). Any model needs a provider choice (expensive to reverse), evals and agent threat work in Stage 2. PRD §9 itself says start deterministic.
- **Assumption A-21:** no model in M1. Incident windows come from Health event times and customer-entered windows; the claim narrative is a per-contract template (R-28); denial reasons (M2) are a pick-list plus pasted text. R-49 – R-51 stay Could.
- **Recommendation:** A-21. Nothing in M1 needs judgement a template can't give, and it removes the model-provider decision from Stage 2. Revisit if KPI-08 shows P-02 time going into postmortem reading. Confidence: ~70%.
- **Who:** product owner. **Blocks:** Stage 2 (AGENT_ARCHITECTURE.md scope).

### Q-22 Deadline warning lead time N (US-11)
- **Assumption A-22:** two warnings, 14 days and 3 days before the deadline (the A-14 date).
- **Who:** product owner. **Source:** PRD §7 US-11 ("N set at Stage 1").

### Q-23 Warning channel for J-06
- **Assumption A-23:** email to the claim owner, sent through the outbox ([ADR-006](../adr/ADR-006-durable-state-no-fallback.md) §3). Slack and Jira are F-14, later.
- **Who:** product owner.

### Q-24 What does "one ready-to-file claim" mean in M1?
- **Known:** [ADR-001](../adr/ADR-001-free-check-first.md) and PRD J-03 say the read-only check gives the credits still claimable "plus one ready-to-file claim".
- **Assumption A-24:** the report lists every claimable credit with its estimate; M1 builds one full packet, for the ready claim with the largest estimate.
- **Recommendation:** build a packet for every ready claim. Once one packet works, more cost little, and holding back a claim we know is owed is a poor first impression for a trust product. If the limit is deliberate (to make the pilot conversation necessary), say so in ADR-001. Confidence: medium.
- **Who:** product owner.

### Q-25 M-02 proof threshold ("set at Stage 1")
- **Assumption A-25:** no threshold in v1; pilot volumes (tens of claims) can't support one. R-40 keeps the predicted result next to each outcome so M-02 can be measured later. Set the threshold once at least 30 claims have outcomes.
- **Who:** product owner. **Source:** PRD §10 M-02.

### Q-26 What baseline does V-02 compare against?
- **Why:** V-02's proof is a grant rate "above partners' past experience". If V-01 holds, most partners never filed, so there is no past rate.
- **Assumption A-26:** proof is a pilot grant rate ≥70% with every denial reason recorded; compare with past claims only where a partner has them.
- **Who:** product owner, informed by interviews.

### Q-27 Data retention and deletion (+ proposed J-07, US-15)
- **Why:** PRD §12 defers retention to SECURITY.md but gives no periods; disconnect behaviour beyond "stop retrying" isn't specified.
- **Assumption A-27:** raw uploaded logs are deleted 30 days after the claim closes (redacted excerpts and hashes kept); raw billing rows are kept only for the open claim window and open claims; audit and evidence-trail records are kept for the life of the tenant plus one year. On disconnect, reads stop at once and raw data is deleted within 30 days unless an open claim needs it and the customer agrees. Needs a legal check against the DPDP Act and GDPR.
- **Who:** product owner (legal input). **Blocks:** SECURITY.md, R-53.

### Q-28 Recovery targets
- **Assumption A-28:** RPO ≤5 minutes and RTO ≤4 hours from M2, in line with RDS point-in-time recovery ([ADR-008](../adr/ADR-008-postgresql-on-amazon-rds.md) §3); M1 uses the same RPO with best-effort RTO.
- **Who:** product owner. **Blocks:** NFR-12.

### Q-29 Recoup's own availability, accessibility and languages (not in the PRD)
- **Assumption A-29:** no availability commitment to customers in v1 (journey SLOs are set in OBSERVABILITY.md); customer screens meet WCAG 2.2 AA; English only; amounts in USD (A-20). These become NFRs only if the PRD adds them.
- **Who:** product owner.

### Q-30 Hosting region and data residency
- **Known:** ADR-008 leaves the region to SECURITY.md and suggests not depending on the region Recoup reports on most.
- **Assumption A-30:** one AWS region for all Recoup data, not us-east-1, chosen in Stage 2 with the product owner after knowing where the first design partners are and what DPDP / GDPR transfer rules then require.
- **Who:** product owner (cloud choice is expensive to reverse). **Blocks:** Stage 2.

### Q-31 What does J-01 collect about a prospect? (+ proposed US-17)
- **Assumption A-31:** the no-access check needs no sign-in and no contact details. Booking an interview uses an external scheduling link. Recoup stores an anonymous session ID and funnel events (KPI-03), and an email only if the prospect asks for the results to be sent.
- **Who:** product owner.

### Q-32 Who runs the catalog and public incident list? (+ proposed P-06, J-09, US-16)
- **Why:** [ADR-005](../adr/ADR-005-sla-catalog-pinned-snapshots.md) §3 and §5 need a person to review contract snapshots and recheck diffs; A-15 needs someone to enter older public incidents. No PRD persona does this.
- **Assumption A-32:** add P-06 Recoup operator (internal). The product owner acts as P-06 in v1. P-06 sees the catalog and public incidents, not tenant data; every P-06 action is audited.
- **Who:** product owner.

### Q-33 Add V-03 (filing effort)?
- **Proposal:** V-03 "a ready-to-file packet cuts claim effort enough that P-02 spends under 30 minutes per claim", proved by KPI-08 in the pilot. The PRD has the KPI and the persona goal but no hypothesis tying them to value.
- **Assumption A-33:** accepted as a hypothesis.
- **Who:** product owner.

### Q-34 Add KPI-11 (ready packets filed before deadline)?
- **Why:** with the customer filing ([ADR-007](../adr/ADR-007-customer-files-claims-in-v1.md)), drop-off between "ready" and "filed" is the main loss Recoup can't control, and ADR-007 §6 uses it as the trigger to revisit F-15.
- **Assumption A-34:** accept KPI-11 with a target of ≥80% in the pilot; below that, revisit F-15.
- **Who:** product owner.

### Q-35 Exact kill thresholds
- **Why:** KPI-02 says "well below" 50% and KPI-10 says "~$10–15k". A kill rule needs one number.
- **Assumption A-35:** kill B if fewer than 30% of interviewees had a claimable incident in 12 months (KPI-02), or if median expected annual credits per partner are under $10k (KPI-10).
- **Who:** product owner.

## Resolved

| Q | Question | Answer | Resolved by | Date |
|---|---|---|---|---|
| Q-01 | Who submits the claim: the customer, or Recoup on their behalf? (PRD §16 #1) | The customer files in AWS Support Center; Recoup prepares the packet and holds no filing permission (A-01). | [ADR-007](../adr/ADR-007-customer-files-claims-in-v1.md) | 2026-11-27 |
