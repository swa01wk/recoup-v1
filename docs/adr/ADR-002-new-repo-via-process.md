# ADR-002: Build v1 in a new private repo through PROCESS.md; port only the modules listed here
Status: Accepted    Date: 2026-11-27

> **Provenance.** This is decision D2. The original decision log (`claude/decision-log.md`) was not available in this session. This ADR was rebuilt on 2026-11-27 from PRD v0.1 §1, §3 and §13 and the code review in [DISCOVERY.md](../discovery/DISCOVERY.md). The port list below is the PRD §3 "Port" rows made exact. Additions not in PRD §3 are marked *(added)*. The product owner should confirm it matches the original.

**Context:** The hackathon build (`swa01wk/recoup` @ `d009df7`) shows fake success. Approving a claim marks it recovered, submission and case monitoring are stubs, and every dollar is a fixture or a constant. It has no CI, its tests weren't run, and it includes a write role and a live `StopInstances` path that v1 must not have (v1 is read-only). See [DISCOVERY.md](../discovery/DISCOVERY.md) for the evidence. A few modules do hold logic worth keeping.

**Decision:** Build v1 in the new private repo `swa01wk/recoup-v1`, stage by stage through [PROCESS.md](../PROCESS.md), starting with M0. The hackathon repo is for reference only. Only the modules below are ported, each through its own spec, with tests in the new repo, and with the fixes listed:

| Module (hackathon path) | What to keep | Fix or change when porting |
|---|---|---|
| `infra/cdk/lib/stacks/iam-stack.ts` — `RecoupReadOnlyRole` only | The pattern: ExternalId condition, scoped allow list, `DenyAllWrites` with `NotActions` | Rebuild per [ADR-003](ADR-003-customer-read-only-role.md). **Do not port `RecoupRemediationRole`.** |
| `backend/src/recoup/approval/flow.py` | Binding to claim hash, amount, state version and expiry; decline and revoke | Add policy revision and revocation (PRD F-08). Store per [ADR-006](ADR-006-durable-state-no-fallback.md). Drop the SNS call, the CloudWatch audit write and `approval/store.py`. |
| `backend/src/recoup/engines/calculator.py` | Decimal math, rounding, the calculation trace | Fix per [ADR-005](ADR-005-sla-catalog-pinned-snapshots.md): per-contract measurement definition, exclusions, minimum credit. |
| `sla_catalog/` | The versioned contract format | Rebuild per [ADR-005](ADR-005-sla-catalog-pinned-snapshots.md): snapshot, real hash, fields taken from the published terms. |
| `backend/src/recoup/engines/sla_resolver.py` *(added; not in PRD §3)* | Version selection by incident date | The catalog can't be used without it. Small, and its logic is sound. |

Data types are **not** ported. The modules above get new types written from the Stage 2 contracts ("contracts before code", PROCESS.md principle 5); the hackathon's `models/` folder isn't copied.

Nothing else is ported or copied. That includes the waste scanners, the agent nodes, the UI, the scripts, the replay and demo paths and the remediation tools.

**Alternatives:**
- *Keep building in the hackathon repo.* Rejected: its demo states, replay paths and write role would have to be found and removed one by one, and none of it ran under CI.
- *Port everything and clean it up later.* Rejected: it carries fake success states and a write path into a product whose first rule is honest state and read-only access.
- *Rewrite with nothing ported.* Rejected: the approval binding and the calculator's Decimal handling are sound, and rewriting them adds risk for no gain.

**Consequences:**
- Easier: every ported line arrives with a spec, a test and a review, and nothing reaches `main` without CI.
- Harder: M0 has to build the foundation (repo, CI, harnesses, durable store, outbox) before any feature work, and porting is slower than copying.
- We must now: follow PROCESS.md stage by stage; treat this table as the only allowed port list (changing it needs a new ADR); and have Stage 1 decide who signs gates G1–G5 (PRD §16 question 9).

**Revisions:**
- 2026-11-27: The port list now links ADR-003 to ADR-006. `sla_resolver.py` stays on the list. The three model files were taken off it, because types come from the Stage 2 contracts. Made before this ADR was first merged.
