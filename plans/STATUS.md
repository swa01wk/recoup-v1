# STATUS: Recoup v1        Updated: 2026-11-27
Current milestone: Stage 1 (Requirements intake) | Next gate: G1 on TBD

| Milestone | Scope | Status | Exit date |
|---|---|---|---|
| M0 Foundation | See [PRD §13](../docs/sources/PRD-v0.1.md#13-release-plan) | Not started | Set at G3 |
| M1 Free missed-credit check | See [PRD §13](../docs/sources/PRD-v0.1.md#13-release-plan) | Not started | Set at G3 |
| M2 Pilot | See [PRD §13](../docs/sources/PRD-v0.1.md#13-release-plan) | Not started | Set at G3 |

## M0 specs
| Spec | Requirements | Screens | Branch / PR | Status | Owner |
|---|---|---|---|---|---|

## Screens
| Screen | Requirements | Specs | Status |
|---|---|---|---|

## Open questions and risks
- Open questions: [PRD §16](../docs/sources/PRD-v0.1.md#16-open-questions-become-q-xx-each-with-an-assumption) until Stage 1 moves them to [QUESTIONS.md](../docs/product/QUESTIONS.md).
- Risks: [PRD §14](../docs/sources/PRD-v0.1.md#14-dependencies-and-risks).
- Open decision #1 (lead value stream: SLA credits vs. waste) is not decided; see [PRD §1](../docs/sources/PRD-v0.1.md#decisions-this-prd-rests-on).

## Recent decisions
- [ADR-001](../docs/adr/ADR-001-free-check-first.md): Free missed-credit check first. Accepted.
- [ADR-002](../docs/adr/ADR-002-new-repo-via-process.md): New repo built through PROCESS.md; port only listed modules. Accepted.
- [ADR-003](../docs/adr/ADR-003-customer-read-only-role.md): Customer-deployed read-only role with a Recoup-generated ExternalId; no write role. Accepted.
- [ADR-004](../docs/adr/ADR-004-claim-state-from-system-of-record.md): Claim stages move only on system-of-record evidence; nothing simulated. Accepted.
- [ADR-005](../docs/adr/ADR-005-sla-catalog-pinned-snapshots.md): SLA contracts as pinned, hashed snapshots; per-contract calculation. Accepted.
- [ADR-006](../docs/adr/ADR-006-durable-state-no-fallback.md): PostgreSQL and outbox for all state and audit; no fallback. Accepted.
