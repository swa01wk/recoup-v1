# ADR-025: Build and deploy the public Health capture stack ahead of G2 and G3, as a single pre-M0 spec
Status: Accepted (delegated by the product owner, 2026-11-27)    Date: 2026-11-27

**Context:** [ADR-021](ADR-021-public-health-capture.md) captures public AWS Health events in Recoup's own account. Q-15 says history that isn't captured can never be shown, and STATUS.md lists it as time-sensitive. Every day before capture starts is either lost to the free check (J-01, R-34) and the 12-month part of KPI-02, or entered by hand by P-06 from the Health Dashboard ([ADR-021](ADR-021-public-health-capture.md) §6), with less detail and more effort.

PROCESS.md normally starts specs only after G3 (plan) and in milestone order. Running the rest of Stage 2 and Stage 3 first means days to weeks without capture.

The stack holds no customer data, needs no app code or database ([ADR-021](ADR-021-public-health-capture.md) §4), and costs little at this event volume.

**Decision:**
1. **One spec, SPEC-01 "Public Health capture infrastructure", runs before G2 and G3.** The number is reserved in DEVELOPMENT_PLAN.md, and Stage 3 fits the remaining M0 specs around it.
2. **Scope is ADR-021 §1–2 only:**
   - the per-Region rules (us-east-1 also matching global events);
   - the central `recoup-health` bus in us-west-2, with an indefinite, KMS-encrypted archive;
   - the `health-intake` SQS queue and its dead-letter queue;
   - the ADR-021 §8 alarms;
   - all in CDK per [ADR-019](ADR-019-iac-cdk-and-handwritten-customer-template.md).
   Out of scope: the intake worker, the database and any app code. They follow in M0 and replay from the archive.
3. **The same spec settles the two ADR-021 unknowns** on Recoup's account and records the answers in ADR-021:
   - whether EventBridge delivery of Health events needs a support plan;
   - whether `DescribeEvents` returns public events.
4. **The process isn't skipped:** a spec file, branch `feat/SPEC-01-health-capture`, a PR, CI (cfn-lint and `cdk synth`), review, and the product owner's approval before merge and deploy.
5. **Prerequisites the product owner provides**, because this session has no AWS credentials:
   - Recoup's production AWS account, with us-west-2 as home Region (ADR-012);
   - CDK bootstrapped in every supported Region;
   - a deploy role for the pipeline, or a person to run `cdk deploy`.
6. **Capture-start date** is recorded in STATUS.md on the day the first event lands in the archive, and shown in the free check (`capture_started_at`, [openapi.yaml](../contracts/openapi.yaml)).

**Alternatives:**
- *Wait for G3 and build it as the first M0 spec, as planned.* Rejected: it gives up history for process order, on a part that has no dependency on the rest of the design.
- *Console-created rules now, IaC later.* Rejected: an untracked setup in the account that will hold the record, and a rebuild later that could drop events.
- *Backfill everything by hand (ADR-021 §6).* Kept only for incidents before capture starts. It's slower and less detailed than captured events.

**Consequences:**
- Easier: capture starts as soon as the account and the PR are ready, not after the plan is signed.
- Harder: one spec runs outside the milestone plan, so Stage 3 has to include it as done; the CDK app's layout is set before the rest of M0 infrastructure exists.
- We must now: write SPEC-01 in its own thread (Stage 4 template), and record the capture-start date when the first event arrives.
