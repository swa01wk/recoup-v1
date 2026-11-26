# Contracts: Recoup v1

Status: Draft for Gate G2 · Date: 2026-11-27 · Architecture: [ARCHITECTURE.md](../architecture/ARCHITECTURE.md)

Contracts come before code (PROCESS.md principle 5). Backend and frontend each build against these files, and either side can mock the other from them. A spec that changes a contract changes it here, in the same PR, with a version bump.

| Contract | File | Version | Who builds against it |
|---|---|---|---|
| HTTP API | [openapi.yaml](openapi.yaml) (OpenAPI 3.1) | 0.2.0 | backend `api`; frontend client and MSW mocks ([ADR-016](../adr/ADR-016-frontend-react-spa.md)) |
| Claim state machine | [claim-state-machine.yaml](claim-state-machine.yaml) | 1.1.0 | control plane guards; UI stage labels; tests |
| Event schemas | [events/](events/) (JSON Schema 2020-12; envelope + one file per type; examples) | envelope 1, each type 1 | outbox writers and consumers ([ADR-006](../adr/ADR-006-durable-state-no-fallback.md), [ADR-020](../adr/ADR-020-jobs-in-postgresql.md)) |
| SLA contract file | [sla-contract/](sla-contract/) | 1 | catalog authors; catalog CI; eligibility ([ADR-005](../adr/ADR-005-sla-catalog-pinned-snapshots.md)) |
| Evidence uploads | [uploads/](uploads/) | each format `/1` | upload parsers; P-02 instructions ([ADR-010](../adr/ADR-010-customer-evidence-by-upload.md)) |
| Database | [db/schema.sql](db/schema.sql) | 0.2.0 (draft) | first M0 migration ([ADR-018](../adr/ADR-018-tenant-isolation-row-level-security.md)) |
| Agent task, result and tool schemas | [agent-tools/](agent-tools/) | — | Not applicable in v1 ([ADR-011](../adr/ADR-011-no-model-in-v1.md)) |
| AG-UI | [agui/](agui/) | — | Not applicable in v1 ([ADR-011](../adr/ADR-011-no-model-in-v1.md)) |

## Changes

- 2026-11-27: API 0.2.0, state machine 1.1.0, DB 0.2.0. Submissions carry `case_opened_on`; approvals expire at the end of the claim's later deadline (Q-38).

## Versioning rules

- **API (`info.version`, SemVer).** Additive changes (new optional field, new endpoint, new enum value in a response) bump the minor version. Removing or renaming a field, tightening validation, or adding an enum value to a request bumps the major version and gets a new `/api/v2` path, run side by side until the frontend has moved. Before 1.0.0 (until G3), minor versions may break; each break is listed in the PR.
- **Events.** `schema_version` per type. Consumers accept the versions they declare. A breaking change is a new version written alongside the old one until every consumer has moved. Payloads hold references, hashes and stage names only ([ADR-018](../adr/ADR-018-tenant-isolation-row-level-security.md) §5); `additionalProperties: false` makes the contract test fail on anything else.
- **State machine.** A new state or transition is a minor version. Removing or reordering one needs an ADR-004 revision.
- **SLA contract file.** `schema_version` in each file. A new required field means a new schema version, and old contract versions keep validating against the version they were written in.
- **Upload formats.** A format ID carries its version (`/1`). A change is a new ID; the old one keeps working for files already uploaded.
- **DB schema.** Owned by Alembic migrations from the first M0 migration on; this file is regenerated from them.

## Contract tests (built in M0)

- API responses validate against `openapi.yaml`, and every amount is a `Money` object with stage and source (R-02).
- Frontend types are regenerated from `openapi.yaml`, and CI fails on drift ([ADR-016](../adr/ADR-016-frontend-react-spa.md)).
- Every outbox event validates against its schema before it's written.
- Every claim transition in code appears in `claim-state-machine.yaml`, and every one in the file is implemented or marked for a later milestone.
- The stage list is identical across the state machine, the DB enum, the API and the events (checked on 2026-11-27 for this draft).
