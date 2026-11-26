# DISCOVERY: the hackathon build (swa01wk/recoup)

Status: Draft for product owner review · Date: 2026-11-27
Repo: `swa01wk/recoup` @ `d009df77945f3c883b247eb94cc54c06a3b020ad` (2026-09-15). Paths below are relative to that repo.

> **Provenance.** The original seed doc (`claude/repository-baseline.md`) was not available in this session. This doc was rebuilt on 2026-11-27 by reading the code at the commit above, and checked against PRD v0.1 §3. Where it differs from PRD §3, it says so under "Differences from PRD §3".

Evidence ranking follows the project rules: code reachable from a real entry point > tests > fixtures and replays > docs and UI copy.

## What I could not check

- **No test was run.** The workspace has no network for installing packages, and `structlog` is not installed. Test files are cited as written, not as passing.
- **No AWS calls were made.** Every AWS integration below is described from code, not from a run.
- **Not re-read for this doc:** the Strands / AgentCore agent nodes (`agents/strands_agents.py`, `adapters/agentcore.py`) and the frontend beyond the files named here.

## Current behaviour

| Capability | Label | Evidence | Notes |
|---|---|---|---|
| Read-only analysis role with ExternalId | IMPLEMENTED (single-account) | `infra/cdk/lib/stacks/iam-stack.ts` L139–300 | Scoped allow list plus a `DenyAllWrites` statement using `NotActions`. The trust principal is `RecoupRuntimeRole` in the **same** account (`runtimeRoleArn`, L54), and the ExternalId defaults to a constant `"recoup-demo-external-id"` (L53). It is not yet a template a customer deploys in their own account. It has no CUR / Data Exports or `health:*` permissions. |
| Remediation role and live EC2 stop | IMPLEMENTED (write path) | `iam-stack.ts` L304–346; `backend/src/recoup/tools/ec2_tools.py` L194–198 | `RecoupRemediationRole` allows `ec2:StopInstances` on instances tagged `RecoupDemo=true`; `TerminateInstances` is denied. `stop_demo_instance` calls `ec2.stop_instances`. This is a write to an AWS account. |
| AWS Health and Support read | IMPLEMENTED (permissions only) | `infra/cdk/lib/stacks/recoup-infra-stack.ts` L290–316 | `RecoupReadConnectorRole` (Lambda service role) has `health:Describe*` and `support:DescribeCases`. |
| AWS Health event intake | STUBBED OR PARTIAL | `backend/src/recoup/sqs_poller.py` L42–48 | Health events are received and deleted from the queue ("ack only"). Nothing is stored or matched. |
| Waste scanners (9) | IMPLEMENTED (heuristic) | `backend/src/recoup/scanners/` (cost_explorer, cwlogs, ebs, ec2, eip, lambda, lb, rds, s3) | Out of scope for v1. |
| SLA contract catalog | DEMO/REPLAY/SIMULATED | `sla_catalog/api_gateway/2022-05-05.yaml` | One contract. `source_hash` is `"sha256:PLACEHOLDER_UPDATE_IN_CI"`. The test (`backend/tests/unit/test_sla_catalog.py` L48–54) only checks the `sha256:` prefix, so the placeholder passes. See "Catalog vs. the public SLA". |
| Contract resolution by incident date | IMPLEMENTED (logic) | `backend/src/recoup/engines/sla_resolver.py` L40–60 | Picks the latest version whose `effective_from`/`effective_to` covers the incident date. Reads only the local catalog. |
| SLA credit calculator | DEMO/REPLAY/SIMULATED | `backend/src/recoup/engines/calculator.py`; called from `graph/nodes.py` L293 and `api/routes/quality.py` L160 | Decimal math with explicit rounding. Defects: any interval below 100% counts as fully unavailable (L41), but the SLA averages per-interval availability; no $1 minimum; exclusions are never evaluated (`graph/nodes.py` L397 always passes an empty list). |
| Billed charges | DEMO/REPLAY/SIMULATED | `backend/src/recoup/graph/nodes.py` L199–223 | From an injected billing snapshot (`scripts/inject_sla_traffic.py`), else a hard-coded `$3.51` with 6 of 8,640 bad intervals. No CUR or Data Exports read. |
| Approval bound to claim | IMPLEMENTED (logic) | `backend/src/recoup/approval/flow.py` | Binds approval to `claim_hash` (SHA-256 of the claim package), `amount`, `state_version` and a 24-hour expiry; supports decline and revoke. Also writes a CloudWatch audit event and sends SNS. |
| Approval and outcome storage | STUBBED OR PARTIAL | `approval/store.py` L6, L31, L88; `graph/outcome_repository.py` L24, L45–50 | DynamoDB when reachable; otherwise a module-level in-memory dict. On write failure, `outcome_repository` logs a warning and carries on. |
| "Execution" after approval | DEMO/REPLAY/SIMULATED | `backend/src/recoup/api/routes/approvals.py` L284–299 | For every action except `stop_demo_instance`, approving moves the opportunity to `APPROVED` and then straight to `RECOVERED`, so the ledger shows it as recovered. |
| Claim submission | STUBBED OR PARTIAL | `backend/src/recoup/graph/nodes.py` L523–552 | Without a valid approval it returns a made-up `replay-<hash>` case ID. With a valid approval it returns the error "live submission not yet implemented". |
| Case monitoring | STUBBED OR PARTIAL | `backend/src/recoup/graph/nodes.py` L559–575 | Always returns `PENDING` with a `$0.00` credit. |
| Policy gate on submission | DEMO/REPLAY/SIMULATED | `backend/src/recoup/safety/cedar.py` | A Python simulation of `infra/policy/recoup-policy.cedar`. |
| "Recovery Verified" and Recovery Ledger | DEMO/REPLAY/SIMULATED | `frontend/src/components/recoup/recovery-verified-hero.tsx`, `frontend/src/components/ui/recovery-ledger.tsx` | UI only. Backed by the `RECOVERED` jump above, not by billing data. |
| Tests | DOCUMENTED ONLY (not run) | `backend/tests/` (unit, adversarial, e2e, trajectory, tool_contracts); `frontend/e2e/` | Not run in this pass. |
| CI | None | No `.github/` directory | — |

## Catalog vs. the public SLA

Compared with the AWS API Gateway SLA page (https://aws.amazon.com/api-gateway/sla/, last updated May 5, 2022, read 2026-11-27):

- **Match:** 99.95% commitment, 5-minute intervals, credit tiers 10% / 25% / 100%, claim deadline of the end of the second billing cycle after the incident.
- **Calculation differs:** the SLA takes the average availability across all 5-minute intervals, where each interval's availability is the share of requests without an API Gateway internal error, and an interval with no requests counts as 100%. The calculator counts any interval below 100% as fully down.
- **Missing:** credits are issued only if the cycle's amount exceeds $1; the catalog and calculator don't apply this.
- **Required claim fields differ:** the SLA asks for the subject line "SLA Credit Request", incident dates, times and regions, the API IDs, the billing cycle, and request logs with sensitive data removed. The catalog omits the subject line and adds `error_logs` and `billing_record`, which the SLA doesn't list.
- **Exclusions differ:** the SLA lists factors outside AWS's control, the customer's own actions, equipment or software, not following the developer guide, and suspension of the account. The catalog lists `planned_maintenance` and `backend_lambda_failures`, which aren't on the SLA's list. Backend failures are already left out by the SLA's definition of an Error, not by an exclusion.

## Integration points

| System | How the hackathon build touches it | Evidence |
|---|---|---|
| AWS IAM / STS | Assumes the read-only and remediation roles | `iam-stack.ts`, `config.py` L114 |
| EC2 | Describe calls; `StopInstances` on demo-tagged instances | `scanners/ec2_scanner.py`, `tools/ec2_tools.py` |
| CloudWatch / Logs | Metrics and log reads for scanners; audit events | `iam-stack.ts` L161–176, `approval/flow.py` L69 |
| Cost Explorer | Cost reads for scanners | `iam-stack.ts` L179–193 |
| AWS Health | Events via SQS, acknowledged and dropped | `sqs_poller.py` |
| AWS Support | `DescribeCases` permission only; no case is created | `recoup-infra-stack.ts` L313 |
| DynamoDB | Opportunities, approvals, tool audits, outcomes | `iam-stack.ts` L65–71, `approval/store.py`, `graph/outcome_repository.py` |
| SNS | Approval and "recovery report" notifications | `approval/flow.py`, `notifications.py` |
| Bedrock AgentCore / Strands | Agent runtime adapters (not re-read) | `adapters/agentcore.py`, `agents/strands_agents.py` |

## Constraints for v1

- **The write path must not come across.** `RecoupRemediationRole` and `tools/ec2_tools.py` write to an AWS account, and v1 is read-only.
- **The read-only role must be rebuilt for customer accounts.** It needs to trust the Recoup account with a per-customer ExternalId (no default constant), and needs billing-data and AWS Health permissions it doesn't have today.
- **The calculator and catalog need the fixes above** before any number is shown as an estimate.
- **No dollar from this build is real.** Every amount is a fixture, a replay or a constant.

## Differences from PRD §3

PRD v0.1 §3 as first written differed from the code on these points. PRD revision 4 corrects them, and each is resolved by an ADR:

| # | Difference | Resolved by |
|---|---|---|
| 1 | §3 called the role a "read-only cross-account role". In the code it trusts a role in the same account and has a default ExternalId constant. | [ADR-003](../adr/ADR-003-customer-read-only-role.md) |
| 2 | §3 didn't mention that `iam-stack.ts` also defines `RecoupRemediationRole`, or that `tools/ec2_tools.py` calls `StopInstances`. | [ADR-003](../adr/ADR-003-customer-read-only-role.md), [ADR-002](../adr/ADR-002-new-repo-via-process.md) |
| 3 | §3 said opportunity state is "in memory". It's DynamoDB when reachable, with a silent in-memory fallback. | [ADR-006](../adr/ADR-006-durable-state-no-fallback.md) |
| 4 | §3 didn't mention that the catalog hash test passes on the placeholder, or that the catalog's exclusions and required fields differ from the public SLA. | [ADR-005](../adr/ADR-005-sla-catalog-pinned-snapshots.md) |
| 5 | §3 listed "Claim submission" as STUBBED (replay IDs). The replay ID is returned only when there is **no** valid approval; with a valid approval, submission fails. | [ADR-004](../adr/ADR-004-claim-state-from-system-of-record.md) |

What to port is decided in [ADR-002](../adr/ADR-002-new-repo-via-process.md), not here.
