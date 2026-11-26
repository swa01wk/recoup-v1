# ADR-020: Background work and schedules run as jobs in PostgreSQL, claimed by the worker with leases and fencing tokens
Status: Accepted (decided in Stage 2a; product owner to review at G2)    Date: 2026-11-27

**Context:** v1 has long-running and scheduled work:
- the account report (Cost Explorer bootstrap, CUR 2.0 ingest, Health reads, matching, eligibility, packets), within 24 hours (NFR-11);
- connection tests (R-09) and evidence parsing (R-52);
- the daily SLA recheck (R-17) and deadline warnings at 14 and 3 days (R-45);
- the billing-cycle deadline list (R-46);
- reconciliation on each CUR refresh (R-42 – R-44);
- the daily Health reconciliation (ADR-021) and deletion on the retention schedule (R-53).

[ADR-006](ADR-006-durable-state-no-fallback.md) requires external effects through the outbox and no in-memory fallback. PROCESS.md requires leases and fencing so a late attempt can't commit over accepted work, readiness computed in code, and explicit joins. Volume is small: tens of tenants, a few hundred jobs a day.

**Decision:**
1. **A `job` table in PostgreSQL is the queue** ([schema.sql](../contracts/db/schema.sql)). A job is enqueued **in the same transaction** as the state change that needs it, so a committed change always has its job and a rolled-back one never does.
2. **Claiming:** the worker selects ready jobs with `FOR UPDATE SKIP LOCKED` and sets a lease (`lease_until`) and a fresh `fencing_token`. Every write a job makes checks the token in the same transaction, so a stale attempt fails instead of overwriting.
3. **Retries by failure class** (PROCESS.md): transient AWS errors and throttling back off and retry up to a ceiling; access denied or policy denial stops without retry (R-11); malformed input fails with a typed reason (R-05). A failed job leaves its claim at its last confirmed stage.
4. **Dependencies:** a report is a parent job with child jobs (billing, Health, per-incident eligibility). A child that completes checks, in the same transaction, whether every required sibling has completed, and only then enqueues the join step. The join is "all required", and it runs exactly once (C03).
5. **Schedules are code**, a fixed list in the worker. A scheduler loop holds a PostgreSQL advisory lock and enqueues each due slot with a unique key `(schedule, slot_time)`, so two workers or a restart can't enqueue a slot twice.
6. **The outbox relay** is a worker loop. It publishes `outbox_event` rows to their in-process consumers (email through SES, job triggers), marks each one sent, and is at-least-once; consumers dedupe by `event_id`.
7. **SQS is used only to buffer AWS Health events** coming from EventBridge (ADR-021). It holds no product state.

**Alternatives:**
- *SQS, EventBridge Scheduler and Lambda.* Rejected: enqueueing outside the database transaction makes a dual write (state commits, the message doesn't, or the other way round); job state would live in two systems; more infrastructure to secure.
- *Celery or RQ with Redis.* Rejected: another stateful service for a few hundred jobs a day, and still a dual write.
- *Step Functions for the report workflow.* Rejected: it would own workflow state outside PostgreSQL, and the workflow is a short DAG.
- *An off-the-shelf PostgreSQL queue library (for example Procrastinate).* Not chosen now, low confidence: it may save code, but the fencing-token check inside product transactions and the tenant context are ours either way. The M0 spec may adopt one if it meets points 1–5 and the conformance tests.

**Consequences:**
- Easier: one place for state and work; restart-safe; jobs are auditable and can be inspected in SQL.
- Harder: we own a small scheduler and queue; long jobs must renew their lease; queue polling adds a little database load.
- We must now: build the job table, claim loop, scheduler and outbox relay in M0, with C01 (duplicate command), C03 (join once) and C04 (crash after an external write) tests.
