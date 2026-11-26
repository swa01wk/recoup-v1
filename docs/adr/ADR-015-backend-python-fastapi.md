# ADR-015: The backend is one Python modular monolith (FastAPI, SQLAlchemy, Alembic) run as two process types: api and worker
Status: Accepted (decided in Stage 2a; product owner to review at G2)    Date: 2026-11-27

**Context:** The constraints set a modular monolith with PostgreSQL and an outbox ([PROCESS.md](../PROCESS.md) golden rule 9; [ADR-006](ADR-006-durable-state-no-fallback.md)). [ADR-002](ADR-002-new-repo-via-process.md) ports four Python modules from the hackathon: the calculator, the approval binding, the SLA resolver and the catalog format. Money must be Decimal end to end (NFR-03, R-23). The billing system of record is CUR 2.0 delivered as Parquet ([ADR-009](ADR-009-billing-data-cur2-with-cost-explorer-bootstrap.md)). All AWS access goes through STS, Health, Cost Explorer and S3 APIs. There's no model in v1 ([ADR-011](ADR-011-no-model-in-v1.md)), so nothing pulls the backend towards an agent framework. The team is small, and load at M1–M2 is a handful of tenants.

**Decision:**
1. **Language: Python 3.** The exact minor version and every library version are pinned in `TECH_STACK.md` (Stage 2b).
2. **One codebase, one container image, two process types.**
   - `api` serves the HTTP API ([openapi.yaml](../contracts/openapi.yaml)).
   - `worker` runs jobs, the scheduler and the outbox relay ([ADR-020](ADR-020-jobs-in-postgresql.md)).
   - Only `worker` ever assumes a customer role. `api` never calls a customer account.
3. **Libraries (the choice; versions in TECH_STACK.md):** FastAPI with Pydantic v2 for the HTTP layer and schemas; SQLAlchemy 2 Core and ORM on psycopg 3; Alembic for migrations; boto3 for AWS; pyarrow to read CUR 2.0 Parquet; pytest with Testcontainers PostgreSQL for tests.
4. **Module boundaries are enforced, not just named.** Each component in [ARCHITECTURE.md](../architecture/ARCHITECTURE.md#components-c4-level-3) is a Python package with a public interface module. An import-linter contract in CI rejects imports of another module's internals, and any import of `boto3` outside `aws_gateway`.
5. **Money:** a `Money` value type wraps `decimal.Decimal` with currency, stage and source. Float money types are rejected by a lint rule (NFR-03). Values from CUR (Parquet `double`) are converted at the adapter boundary with `Decimal(str(value))`, and the original string is kept in the evidence.

**Alternatives:**
- *TypeScript on Node.* Rejected: the ported modules are Python; Decimal needs a library everywhere; Parquet reading is less mature.
- *Go or Kotlin.* Rejected: a rewrite of the ported modules for no product gain, and slower iteration for a small team.
- *Django.* Rejected: its ORM and admin suit CRUD apps. Here the core is a guarded state machine and explicit transactions, which SQLAlchemy Core expresses directly.
- *Separate services per domain.* Rejected by golden rule 9 until an ADR shows the need.

**Consequences:**
- Easier: the ported modules keep their language; one image to build, scan and deploy; Decimal and Parquet are first-class.
- Harder: Python's typing is opt-in, so `mypy --strict` runs in CI on every module; CPU-heavy log parsing runs in the worker, never in a request.
- We must now: pin versions in TECH_STACK.md; add the import-linter and float-money rules to M0 CI; generate API models from [openapi.yaml](../contracts/openapi.yaml) or test them against it (contract test).
