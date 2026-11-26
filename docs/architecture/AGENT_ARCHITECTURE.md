# AGENT_ARCHITECTURE: Recoup v1

Status: Draft for Gate G2 (Stage 2a) · Date: 2026-11-27 · Decision: [ADR-011](../adr/ADR-011-no-model-in-v1.md)

## Summary: no agent workflows in v1

Recoup v1 has **no agent workflows and no language model** in M0, M1 or M2 ([ADR-011](../adr/ADR-011-no-model-in-v1.md)). Every step is deterministic code or a human decision: matching, eligibility, calculation, deadlines, packets, reconciliation, and the approval and case flow. No model provider is chosen.

This doc records three things: what that means for the PROCESS.md agent sections, the gate a future agent step must pass, and which agent-only M0 items don't apply. The deterministic workflow design is in [ARCHITECTURE.md](ARCHITECTURE.md).

## Maturity per workflow

PRD §9 names three agent steps with a target of L3 (REQUIREMENTS.md, "Agent steps"). None is built, so **no maturity level is claimed for any of them**. Everything else is deterministic and has no maturity level.

| PRD §9 step | Requirement | Target | Reached | v1 replacement (deterministic) | Approver of the v1 output |
|---|---|---|---|---|---|
| J-03 incident windows from postmortems or notes | R-49 (Could) | L3 | None, deferred past M2 | Health event start and end times; windows P-02 enters or confirms (`setIncidentWindow`) | P-02 |
| J-03 claim narrative | R-50 (Could) | L3 | None, deferred past M2 | Packet fields filled from the contract's `claim_fields` and verified claim data (R-28) | P-01 (approval, M2) |
| J-05 denial reason capture | R-51 (Could) | L3 | None, deferred past M2 | P-01 picks from a fixed list (`DenialReasonCode`); pasted case text is stored as data | P-01 |

## What still applies from PROCESS.md's agent architecture

The operating principle holds without agents: deterministic systems enforce rules and transitions, and authorised humans approve consequential decisions.

| Golden rule | v1 | Where |
|---|---|---|
| 1 Separate authority from intelligence | Applies: no actor type `agent` exists in the state machine, so nothing but a guarded command moves a claim | [claim-state-machine.yaml](../contracts/claim-state-machine.yaml) |
| 2 Start deterministic | Applies: the whole product | ADR-011 |
| 3 Contract in, evidence out (agent runs) | Not applicable: no agent runs. Commands and jobs have typed contracts instead | [openapi.yaml](../contracts/openapi.yaml), [events/](../contracts/events/) |
| 4 Bound all autonomy | Not applicable to agents. Jobs have retry ceilings and leases; Cost Explorer calls are bounded and shown in advance (R-10) | [ADR-020](../adr/ADR-020-jobs-in-postgresql.md), [ADR-009](../adr/ADR-009-billing-data-cur2-with-cost-explorer-bootstrap.md) §4 |
| 5 People approve consequential actions | Applies: approval binding (M2), P-03 match confirmation, P-06 catalog review | ADR-004, [ADR-022](../adr/ADR-022-cur2-credit-line-matching-rule.md) |
| 6 Untrusted by default | Applies: Health text, CUR descriptions, case text, logs and SLA pages are data (NFR-09) | ARCHITECTURE.md quality scenario NFR-09 |
| 7 Durable and recoverable | Applies | [ADR-006](../adr/ADR-006-durable-state-no-fallback.md), ADR-020 |
| 8 Auditable and observable | Applies | NFR-08; OBSERVABILITY.md (2b) |
| 9 Modular first | Applies: one modular monolith | [ADR-015](../adr/ADR-015-backend-python-fastapi.md) |

### Planes → components

| Plane | v1 component(s) | Note |
|---|---|---|
| Interaction | SPA, `http`, `ops` | No AG-UI stream; status endpoints are polled ([ADR-016](../adr/ADR-016-frontend-react-spa.md) §6) |
| Control | `claims`, `approvals`, `cases`, `identity` | Owns domain truth |
| Workflow | `jobs`, `reports` | Leases, fencing, explicit joins (ADR-020) |
| Agent harness | — | Not applicable |
| Execution | `aws_gateway` | The tool-gateway analogue: typed adapters, read-only allow-list, denial before any call, short-lived credentials |
| Context and evidence | `evidence`, `catalog`, `storage`, `audit` | Hashed, immutable versions |
| Assurance | CI contract tests, catalog CI, eligibility golden tests | Stage 3 TEST_STRATEGY.md |
| Operations | OBSERVABILITY.md, RUNBOOK.md | Stage 2b and hardening |

## The gate for adding an agent workflow

An agent step (R-49 – R-51, or any new one) is added only when **all** of these hold:

1. **The trigger in ADR-011 §6 is met:** pilot partners report KPI-08 above 30 minutes, and most of that time goes on reading postmortems or writing claim text. Or a new requirement, through change control, needs judgement that code can't give.
2. **A new ADR** supersedes the relevant part of ADR-011, and **the product owner chooses the model provider** (project rules: expensive to reverse), including data residency in us-west-2 or an accepted exception.
3. **Contracts first:** `TaskContract`, `ContextEnvelope`, `AgentResult` and tool schemas in [agent-tools/](../contracts/agent-tools/), and the AG-UI mapping in [agui/](../contracts/agui/) if anything streams.
4. **An eval set exists before the step ships** (NFR-13), with a deterministic grader for every hard check and an independent verifier.
5. **No authority moves:** the agent only proposes. P-02 or P-01 confirms (PRD §9 approvers), and the state machine gains no transition with actor `agent`.
6. **SECURITY.md covers the agent risks** (prompt injection, excessive agency, tenant crossover, stale results, stream leakage), and C05–C11 are planned as T-xx.
7. **The ten agent decisions** (below) each have an ADR.
8. **Maturity is claimed per workflow** only from the L3 exit evidence: representative tasks complete once, correctly, even after interruption.

## Agent-only M0 items: not applicable

PROCESS.md lists these M0 items for agentic products. In v1 they're **not applicable**, with ADR-011 as the reason. Stage 3 marks them so in TEST_STRATEGY.md and DEVELOPMENT_PLAN.md.

| PROCESS.md M0 item | v1 status | What we build instead, if anything |
|---|---|---|
| Harness interface with a fake model and fake tools | Not applicable | — |
| Agent tool gateway | Not applicable as an agent gateway | `aws_gateway` read-only allow-list (NFR-01) |
| AG-UI event stream | Not applicable | Polled status endpoints |
| Agent eval runner; `make eval` with `LIVE=1`; nightly live eval | Not applicable | `make eval` exits 0 and prints "not applicable (ADR-011)" so the Makefile shape stays standard |
| Agent telemetry (model and tool calls, tokens, cost, budgets) | Not applicable | Job and AWS-call telemetry (OBSERVABILITY.md, 2b) |
| `.cursor/rules/agent.mdc` | Not applicable | — (Stage 3 writes the other rules) |
| Model routing, prompt and skill releases | Not applicable | — |
| Agent contracts in `agent-tools/` and `agui/` | Not applicable | READMEs say so |

**Kept, because every workflow needs them** (ADR-011 consequences): the state machine, approvals, the outbox, audit, durable jobs, tenant isolation.

## Conformance scenarios (C01 – C14)

Stage 3 turns the applicable ones into T-xx.

| ID | Scenario | v1 | Deterministic form, or reason |
|---|---|---|---|
| C01 | Duplicate transition command | **Applies** | `Idempotency-Key` + unique `(tenant, claim, idempotency_key)` → one transition |
| C02 | Tool call outside the allowed capability | **Applies (analogue)** | `aws_gateway` refuses a non-allow-listed AWS action before sending; decision logged |
| C03 | Two dependencies complete at once | **Applies** | Report join enqueued once ([ADR-020](../adr/ADR-020-jobs-in-postgresql.md) §4) |
| C04 | Worker dies after an external write | **Applies** to v1's only external write, email | Outbox at least once; `deadline_notice` + `event_id` dedupe → one email |
| C05 | Approval bound to an old version | **Applies (M2)** | Approval invalid when content hash, amount, stage version or policy revision changes (R-36) |
| C06 | Tool output contains malicious instructions | **Applies (analogue)** | Injection fixtures in Health text, CUR descriptions, case text and logs: no state change (NFR-09) |
| C07 | Cross-tenant lookup | **Applies** | Per-layer tests ([ADR-018](../adr/ADR-018-tenant-isolation-row-level-security.md) §6) |
| C08 | Sub-agent asks for more privilege | Not applicable | No agents |
| C09 | Input edited during inference | **Applies (analogue)** | Evidence changes while eligibility runs → result for the old `stage_version` rejected |
| C10 | Stream reconnects after lost events | Not applicable | No stream; the UI re-reads authoritative state |
| C11 | Budget exhausted mid-loop | Not applicable | No model budget. The bounded Cost Explorer call count is covered by the R-10 tests |
| C12 | Old workflow resumes after a deploy | **Applies** | Job `payload_schema` version honoured or migrated; claims keep their pinned contract version |
| C13 | A repair agent changes trusted tests | Not applicable in the product | Development-process risk, handled by CODEOWNERS and human review (PROCESS.md) |
| C14 | Verified build differs from the deployed one | **Applies** | Deploy by image digest from the pipeline (Stage 3 CI/CD) |

## Agent review checklist (G2 item)

| Item | Result |
|---|---|
| Run, task, attempt and artifact owners named; lifecycle and guards documented | **Pass (deterministic form):** claim lifecycle and guards in [claim-state-machine.yaml](../contracts/claim-state-machine.yaml); job owner and attempts in ADR-020; artifacts (packets, excerpts, contract versions) hashed and versioned |
| Every privileged action has an authorisation check and an approval binding | **Pass:** `x-roles` on every operation; approval binding for M2 (R-36); P-03 confirmation for possible matches |
| The four schemas versioned; tool gateway denies forbidden calls independently of prompts | **Not applicable:** no agent schemas. `aws_gateway`'s allow-list is code, not prompt |
| Every external write idempotent or reconciled | **Pass:** v1's only external write is email through the outbox, exactly once per `deadline_notice` |
| UI can rebuild run state after reconnect; operator can explain every blocked or waiting state | **Pass (deterministic form):** every waiting state is a stage, flag or typed reason (`not_ready_reasons`, `Problem.code`) |
| Maturity of each workflow recorded with exit evidence | **Pass:** none claimed; table above |

## Agent decisions (ADRs)

| # | Topic | v1 |
|---|---|---|
| 1 | Authoritative state and transaction boundaries | [ADR-004](../adr/ADR-004-claim-state-from-system-of-record.md), [ADR-006](../adr/ADR-006-durable-state-no-fallback.md); write path in ARCHITECTURE.md |
| 2 | Harness interface and checkpoints | Not applicable (ADR-011) |
| 3 | Task and event schemas and compatibility | Events: [contracts README](../contracts/README.md#versioning-rules). Agent task schemas: not applicable |
| 4 | Sandbox isolation and tool authorisation | No sandboxes; AWS call authorisation in `aws_gateway` ([ADR-003](../adr/ADR-003-customer-read-only-role.md), [ADR-019](../adr/ADR-019-iac-cdk-and-handwritten-customer-template.md)) |
| 5 | Scheduler, leases, fencing, reconciliation | [ADR-020](../adr/ADR-020-jobs-in-postgresql.md) |
| 6 | Context freshness, retrieval permissions, memory | Not applicable; stale eligibility results rejected by `stage_version` |
| 7 | Model routing, budgets, fallback, data residency | Not applicable (ADR-011); data residency [ADR-012](../adr/ADR-012-hosting-region-us-west-2.md) |
| 8 | Artifacts, identity, provenance, trusted verification | [ADR-005](../adr/ADR-005-sla-catalog-pinned-snapshots.md), [ADR-017](../adr/ADR-017-auth-cognito-oidc-bff.md), [ADR-022](../adr/ADR-022-cur2-credit-line-matching-rule.md) |
| 9 | Streamed UI and approval binding | No stream ([ADR-016](../adr/ADR-016-frontend-react-spa.md) §6); approval binding R-36 and the state machine |
| 10 | Operational security, retention, SLOs, DR | Q-27, NFR-12, [ADR-008](../adr/ADR-008-postgresql-on-amazon-rds.md); SECURITY.md and OBSERVABILITY.md in Stage 2b |
