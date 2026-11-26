# ADR-002: Build v1 in a new private repo through PROCESS.md; port only the modules listed here
Status: Accepted    Date: 2026-11-27

> **Provenance.** This is decision D2. The original decision log (`claude/decision-log.md`) was not available in this session. This ADR was rebuilt on 2026-11-27 from PRD v0.1 §1, §3 and §13 and the code review in [DISCOVERY.md](../discovery/DISCOVERY.md). The port list below is the PRD §3 "Port" rows made exact. Additions not in PRD §3 are marked *(added)*. The product owner should confirm it matches the original.

**Context:** The hackathon build (`swa01wk/recoup` @ `d009df7`) shows fake success. Approving a claim marks it recovered, submission and case monitoring are stubs, and every dollar is a fixture or a constant. It has no CI, its tests weren't run, and it includes a write role and a live `StopInstances` path that v1 must not have (v1 is read-only). See [DISCOVERY.md](../discovery/DISCOVERY.md) for the evidence. A few modules do hold logic worth keeping.

**Decision:** Build v1 in the new private repo `swa01wk/recoup-v1`, stage by stage through [PROCESS.md](../PROCESS.md), starting with M0. The hackathon repo is for reference only. Only the modules below are ported, each through its own spec, with tests in the new repo, and with the fixes listed:

| Module (hackathon path) | What to keep | Fix or change when porting |
|---|---|---|
| `infra/cdk/lib/stacks/iam-stack.ts` — `RecoupReadOnlyRole` only | The pattern: ExternalId condition, scoped allow list, `DenyAllWrites` with `NotActions` | Rebuild as a template the customer deploys, trusting the Recoup account with a per-customer ExternalId (no default constant). Replace the scanner permissions with billing-data (CUR / Data Exports) and AWS Health reads. **Do not port `RecoupRemediationRole`.** |
| `backend/src/recoup/approval/flow.py` | Binding to claim hash, amount, state version and expiry; decline and revoke | Add policy revision and revocation (PRD F-08). Store in PostgreSQL through the outbox. Drop the SNS call and the in-memory fallback in `approval/store.py`. |
| `backend/src/recoup/engines/calculator.py` | Decimal math, rounding, the calculation trace | Average per-interval availability per the contract definition, evaluate exclusions, apply the $1 minimum. |
| `sla_catalog/` | The versioned contract format | Compute the real `source_hash`. Make the test check the hash itself, not just its prefix. Correct the exclusions and required fields against the public SLA. Extend to the 3–5 contracts chosen in Stage 1. |
| `backend/src/recoup/engines/sla_resolver.py` *(added)* | Version selection by incident date | Needed to load the catalog. |
| `backend/src/recoup/models/sla.py`, `models/approval.py`, `models/availability.py` *(added)* | The types the modules above import | Re-check them against the contracts written in Stage 2. |

Nothing else is ported or copied. That includes the waste scanners, the agent nodes, the UI, the scripts and the remediation tools.

**Alternatives:**
- *Keep building in the hackathon repo.* Rejected: its demo states, replay paths and write role would have to be found and removed one by one, and none of it ran under CI.
- *Port everything and clean it up later.* Rejected: it carries fake success states and a write path into a product whose first rule is honest state and read-only access.
- *Rewrite with nothing ported.* Rejected: the approval binding and the calculator's Decimal handling are sound, and rewriting them adds risk for no gain.

**Consequences:**
- Easier: every ported line arrives with a spec, a test and a review, and nothing reaches `main` without CI.
- Harder: M0 has to build the foundation (repo, CI, harnesses, durable store, outbox) before any feature work, and porting is slower than copying.
- We must now: follow PROCESS.md stage by stage; treat this table as the only allowed port list (changing it needs a new ADR); and have Stage 1 decide who signs gates G1–G5 (PRD §16 question 9).
