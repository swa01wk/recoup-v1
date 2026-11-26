# STATUS: Recoup v1        Updated: 2026-11-27
Current milestone: Stage 2 (Design) | Next gate: G2 on TBD

| Milestone | Scope | Status | Exit date |
|---|---|---|---|
| M0 Foundation | F-00 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)); see [PRD §13](../docs/sources/PRD-v0.1.md#13-release-plan) | Not started | Set at G3 |
| M1 Free missed-credit check | F-01 – F-07 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)) | Not started | Set at G3 |
| M2 Pilot | F-08 – F-13 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)) | Not started | Set at G3 |

## Gates
| Gate | Status | Signed by | Date |
|---|---|---|---|
| G1 Requirements baseline | **Signed, conditional** ([ADR-014](../docs/adr/ADR-014-build-before-interviews.md)). Condition: no M2 until ≥10 account reports and ≥5 conversations, read against the Q-35 kill thresholds. Recommended before M1 build-out: the Next Signal demo; the AISPL terms check (Q-20). See [G1 check](../docs/product/REQUIREMENTS.md#gate-g1-check). | Product owner | 2026-11-27 |

## M0 specs
| Spec | Requirements | Screens | Branch / PR | Status | Owner |
|---|---|---|---|---|---|

## Screens
| Screen | Requirements | Specs | Status |
|---|---|---|---|

## Open questions and risks
- Questions: [QUESTIONS.md](../docs/product/QUESTIONS.md). All decided on 2026-11-27 under delegation, except Q-04, Q-06, Q-07 and Q-08, which interviews must validate. Five AWS verification tasks are listed there.
- Discovery: interviews are replaced by the free check (ADR-014). Before M2: at least 10 account reports and 5 conversations, read against the Q-35 kill thresholds.
- Before M1 build-out (cheap, can change scope): the Next Signal demo; the AISPL terms check (Q-20).
- Time-sensitive: start capturing public AWS Health events (Q-15) as the first M0 spec. History not captured is lost to the free check.
- Risks: [PRD §14](../docs/sources/PRD-v0.1.md#14-dependencies-and-risks).
- Open decision #1 (lead value stream: SLA credits vs. waste) is not decided; see [PRD §1](../docs/sources/PRD-v0.1.md#decisions-this-prd-rests-on).

## Stage log
- 2026-11-27 Stage 1 draft: REQUIREMENTS.md, QUESTIONS.md, DISCOVERY.md (availability-evidence row added). Branch `docs/stage-1-intake`, [PR #2](https://github.com/swa01wk/recoup-v1/pull/2).
- 2026-11-27 Stage 1 answers (delegated): Q-01 – Q-35 decided or accepted; R-54 – R-56 added; ADR-010 – ADR-013; PRD revision 5 (support plan names), in the repo and the project copy.
- 2026-11-27 G1 signed, conditional (product owner); PRD revision 6 (build before interviews).

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
- [ADR-010](../docs/adr/ADR-010-customer-evidence-by-upload.md): Customer request-log evidence arrives by upload; no log or metric read permission. Accepted (delegated).
- [ADR-011](../docs/adr/ADR-011-no-model-in-v1.md): No language model in v1; agent steps deferred; no model provider chosen. Accepted (delegated).
- [ADR-012](../docs/adr/ADR-012-hosting-region-us-west-2.md): All Recoup data in us-west-2. Accepted (delegated).
- [ADR-013](../docs/adr/ADR-013-contingency-on-posted-credits.md): Free check; pilot priced at a contingency share of posted credits only, opening at 20%. Accepted (delegated).
- [ADR-014](../docs/adr/ADR-014-build-before-interviews.md): Build M0–M1 before interviews; the free check is the discovery instrument; conditional G1; discovery checkpoint before M2. Accepted (product owner).
