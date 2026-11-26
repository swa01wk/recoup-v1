# STATUS: Recoup v1        Updated: 2026-11-27
Current milestone: Stage 1 (Requirements intake) — draft done, G1 not passed | Next gate: G1 on TBD (needs interviews, see below)

| Milestone | Scope | Status | Exit date |
|---|---|---|---|
| M0 Foundation | F-00 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)); see [PRD §13](../docs/sources/PRD-v0.1.md#13-release-plan) | Not started | Set at G3 |
| M1 Free missed-credit check | F-01 – F-07 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)) | Not started | Set at G3 |
| M2 Pilot | F-08 – F-13 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)) | Not started | Set at G3 |

## Gates
| Gate | Status | Signed by | Date |
|---|---|---|---|
| G1 Requirements baseline | **Not passed.** Fails: framing unconfirmed (0 of 10 interviews); 3 Must R-xx trace to proposed stories; 34 open questions; Next Signal demo not done. See [G1 check](../docs/product/REQUIREMENTS.md#gate-g1-check-2026-11-27). | — (signer is Q-09) | — |

## M0 specs
| Spec | Requirements | Screens | Branch / PR | Status | Owner |
|---|---|---|---|---|---|

## Screens
| Screen | Requirements | Specs | Status |
|---|---|---|---|

## Open questions and risks
- Open questions: [QUESTIONS.md](../docs/product/QUESTIONS.md), grouped by who answers (product owner, interviews, AWS research). Q-01 resolved by ADR-007.
- Blocking Stage 2 (expensive to reverse, product owner): Q-13 customer log access, Q-18 auth, Q-21 model provider, Q-30 hosting region.
- Time-sensitive: Q-15. Recoup should start recording public AWS Health events now; history not recorded is lost to the free check.
- Risks: [PRD §14](../docs/sources/PRD-v0.1.md#14-dependencies-and-risks).
- Open decision #1 (lead value stream: SLA credits vs. waste) is not decided; see [PRD §1](../docs/sources/PRD-v0.1.md#decisions-this-prd-rests-on).

## Stage log
- 2026-11-27 Stage 1 draft: REQUIREMENTS.md (R-01 – R-53, NFR-01 – NFR-13, KPI-01 – KPI-11), QUESTIONS.md (Q-01 – Q-35), DISCOVERY.md (availability-evidence row added). Branch `docs/stage-1-intake`.

## Recent decisions
- [ADR-001](../docs/adr/ADR-001-free-check-first.md): Free missed-credit check first. Accepted.
- [ADR-002](../docs/adr/ADR-002-new-repo-via-process.md): New repo built through PROCESS.md; port only listed modules. Accepted.
- [ADR-003](../docs/adr/ADR-003-customer-read-only-role.md): Customer-deployed read-only role with a Recoup-generated ExternalId; no write role. Accepted.
- [ADR-004](../docs/adr/ADR-004-claim-state-from-system-of-record.md): Claim stages move only on system-of-record evidence; nothing simulated. Accepted.
- [ADR-005](../docs/adr/ADR-005-sla-catalog-pinned-snapshots.md): SLA contracts as pinned, hashed snapshots; per-contract calculation. Accepted.
- [ADR-006](../docs/adr/ADR-006-durable-state-no-fallback.md): PostgreSQL and outbox for all state and audit; no fallback. Accepted.
- [ADR-007](../docs/adr/ADR-007-customer-files-claims-in-v1.md): The customer files claims in Support Center; Recoup prepares the packet and holds no filing permission. Accepted (delegated).
- [ADR-008](../docs/adr/ADR-008-postgresql-on-amazon-rds.md): PostgreSQL on Amazon RDS in Recoup's account; Multi-AZ in production from M2. Accepted (delegated).
- [ADR-009](../docs/adr/ADR-009-billing-data-cur2-with-cost-explorer-bootstrap.md): CUR 2.0 is the billing system of record; Cost Explorer only for the first estimate. Accepted (delegated).
