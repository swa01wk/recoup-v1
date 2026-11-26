# STATUS: Recoup v1        Updated: 2026-11-27
Current milestone: Stage 2 (Design): 2a done, 2b next | Next gate: G2 on TBD

| Milestone | Scope | Status | Exit date |
|---|---|---|---|
| M0 Foundation | F-00 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)); see [PRD §13](../docs/sources/PRD-v0.1.md#13-release-plan) | Not started | Set at G3 |
| M1 Free missed-credit check | F-01 – F-07 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)) | Not started | Set at G3 |
| M2 Pilot | F-08 – F-13 ([REQUIREMENTS.md](../docs/product/REQUIREMENTS.md#features-f-xx)) | Not started | Set at G3 |

## Gates
| Gate | Status | Signed by | Date |
|---|---|---|---|
| G1 Requirements baseline | **Signed, conditional** ([ADR-014](../docs/adr/ADR-014-build-before-interviews.md)). Condition: no M2 until ≥10 account reports and ≥5 conversations, read against the Q-35 kill thresholds. Recommended before M1 build-out: the Next Signal demo; the AISPL terms check (Q-20). See [G1 check](../docs/product/REQUIREMENTS.md#gate-g1-check). | Product owner | 2026-11-27 |
| G2 Design review | **Partial (2a):** architecture, ADRs and contracts checked; threat model (2b) and screens (2c) open. See [G2 check](../docs/architecture/ARCHITECTURE.md#gate-g2-check-partial-stage-2a). | — | — |

## M0 specs
| Spec | Requirements | Screens | Branch / PR | Status | Owner |
|---|---|---|---|---|---|

## Screens
| Screen | Requirements | Specs | Status |
|---|---|---|---|

## Open questions and risks
- Questions: [QUESTIONS.md](../docs/product/QUESTIONS.md). All decided on 2026-11-27 under delegation, except Q-04, Q-06, Q-07 and Q-08, which interviews must validate. Five AWS verification tasks are listed there.
- Raised and decided in Stage 2a (delegated): Q-36 (self-serve tenants; approvers manage members), Q-37 (only `DEFAULT_5XX` without a Lambda 5xx counts as an API Gateway error), Q-38 (approval valid until the later deadline; case-opened date recorded), Q-39 (round once, to the cent, half-even). Still to confirm: Q-37 with AWS in the Q-14 case; Q-39 against the first grants. Q-31 revised: no emailed results.
- Stage 2a verifications for the first M0 spec ([ADR-021](../docs/adr/ADR-021-public-health-capture.md)): whether EventBridge delivery of Health events needs a support plan; whether `DescribeEvents` in Recoup's account returns public events.
- Discovery: interviews are replaced by the free check (ADR-014). Before M2: at least 10 account reports and 5 conversations, read against the Q-35 kill thresholds.
- Before M1 build-out (cheap, can change scope): the Next Signal demo; the AISPL terms check (Q-20).
- Time-sensitive: start capturing public AWS Health events (Q-15) as the first M0 spec. History not captured is lost to the free check. [ADR-025](../docs/adr/ADR-025-health-capture-before-g3.md): SPEC-01 (rules, bus, archive, queue) runs ahead of G2 and G3. **Waiting on the product owner:** Recoup's production AWS account, CDK bootstrap and a deploy role. Capture-start date: not yet.
- Risks: [PRD §14](../docs/sources/PRD-v0.1.md#14-dependencies-and-risks).
- Open decision #1 (lead value stream: SLA credits vs. waste) is not decided; see [PRD §1](../docs/sources/PRD-v0.1.md#decisions-this-prd-rests-on).

## Stage log
- 2026-11-27 Stage 1 draft: REQUIREMENTS.md, QUESTIONS.md, DISCOVERY.md (availability-evidence row added). Branch `docs/stage-1-intake`, [PR #2](https://github.com/swa01wk/recoup-v1/pull/2).
- 2026-11-27 Stage 1 answers (delegated): Q-01 – Q-35 decided or accepted; R-54 – R-56 added; ADR-010 – ADR-013; PRD revision 5 (support plan names), in the repo and the project copy.
- 2026-11-27 G1 signed, conditional (product owner); PRD revision 6 (build before interviews).
- 2026-11-27 Stage 2a: ARCHITECTURE.md, AGENT_ARCHITECTURE.md, ADR-015 – ADR-024, docs/contracts/ (OpenAPI, events, claim state machine, SLA contract format, upload formats, DB schema draft); Q-36 – Q-39 raised. Branch `docs/stage-2a-architecture`, [PR #4](https://github.com/swa01wk/recoup-v1/pull/4).
- 2026-11-27 Stage 2a answers (delegated): ADR-017 confirmed; ADR-025 (Health capture ahead of G3); Q-36 – Q-39 decided; Q-31 revised. Same PR.

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
- [ADR-015](../docs/adr/ADR-015-backend-python-fastapi.md): Python modular monolith (FastAPI, SQLAlchemy, Alembic), api and worker processes. Accepted (Stage 2a).
- [ADR-016](../docs/adr/ADR-016-frontend-react-spa.md): React + TypeScript SPA (Vite), static on CloudFront; client generated from OpenAPI. Accepted (Stage 2a).
- [ADR-017](../docs/adr/ADR-017-auth-cognito-oidc-bff.md): Cognito user pools, required TOTP MFA; API-side OIDC and session cookie; roles in the DB. Accepted (delegated under Q-18), confirmed 2026-11-27.
- [ADR-018](../docs/adr/ADR-018-tenant-isolation-row-level-security.md): PostgreSQL row-level security plus tenant-scoped repositories; separate DB roles. Accepted (Stage 2a).
- [ADR-019](../docs/adr/ADR-019-iac-cdk-and-handwritten-customer-template.md): CDK (TypeScript) for Recoup; hand-written CloudFormation for the customer role. Accepted (Stage 2a).
- [ADR-020](../docs/adr/ADR-020-jobs-in-postgresql.md): Jobs and schedules in PostgreSQL with leases and fencing. Accepted (Stage 2a).
- [ADR-021](../docs/adr/ADR-021-public-health-capture.md): Public Health capture: a rule per Region, central archived bus in us-west-2, SQS, de-duplicated. Accepted (designs Q-15).
- [ADR-022](../docs/adr/ADR-022-cur2-credit-line-matching-rule.md): CUR 2.0 credit-line matching rule. Accepted (makes Q-12 exact).
- [ADR-023](../docs/adr/ADR-023-runtime-ecs-fargate.md): ECS Fargate behind CloudFront; RDS IAM auth; SES. Accepted (Stage 2a).
- [ADR-024](../docs/adr/ADR-024-claim-per-account-contract-region-cycle.md): A claim is account × contract × Region × billing cycle. Accepted (Stage 2a).
- [ADR-025](../docs/adr/ADR-025-health-capture-before-g3.md): Public Health capture stack built and deployed ahead of G2 and G3, as SPEC-01. Accepted (delegated).
