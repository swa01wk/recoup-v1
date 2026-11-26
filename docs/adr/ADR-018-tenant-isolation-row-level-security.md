# ADR-018: Tenant isolation uses PostgreSQL row-level security as the enforcing layer, with tenant-scoped repositories on top, and the same tenant key on files, jobs and logs
Status: Accepted (decided in Stage 2a; product owner to review at G2)    Date: 2026-11-27

**Context:** NFR-06 requires tenant isolation end to end: database, files, queues, logs and caches. NFR-04 requires billing data and logs readable only within their tenant, and NFR-02 requires ExternalIds stored tenant-scoped with a cross-tenant lookup failing. [ADR-008](ADR-008-postgresql-on-amazon-rds.md) §5 left the choice between row-level security (RLS) and tenant filters to Stage 2, and requires plain PostgreSQL. One database serves all tenants. Some data is global by nature: the SLA catalog and public incidents, which tenants read but never write, and which P-06 curates without seeing tenant data (Q-32).

**Decision:**
1. **Every tenant-owned table has a `tenant_id` column and an RLS policy**, with `ENABLE` and `FORCE ROW LEVEL SECURITY`. The policy compares `tenant_id` with `current_setting('app.tenant_id')`. The draft is in [schema.sql](../contracts/db/schema.sql).
2. **Database roles:**
   - `recoup_owner` owns the schema and runs migrations only. Never used by the app.
   - `recoup_app`: used by `api` and `worker` for tenant work. No `BYPASSRLS`. It reads global tables and can't write them.
   - `recoup_catalog`: used only by the catalog sync, the Health intake and the operator routes. Writes global tables and has **no grant on any tenant table**, so P-06 can't reach tenant data even through a bug.
   - `recoup_lifecycle`: used only by the deletion job (R-53). Deletes tenant rows through RLS, one tenant per transaction.
3. **The tenant is set per transaction**, never per connection. `SET LOCAL app.tenant_id` runs at the start of each unit of work, from the authenticated session or from the job's tenant. With pooled connections, a setting left over from an earlier transaction can't leak. With no tenant set, the policy matches no rows (fail closed).
4. **Repositories also filter by tenant** (defence in depth), and a test fails if any query on a tenant table lacks the filter.
5. **The same key everywhere else:**
   - S3 object keys start with `tenants/<tenant_id>/`, and objects are encrypted with KMS using an encryption context of `tenant_id`, which every read checks.
   - Jobs and outbox events carry `tenant_id`, and the worker sets it before running. The `job` and `outbox_event` tables aren't under RLS, because the claim loop and the relay must see every tenant's work. So they hold **references only** (IDs, hashes, stage names), never tenant content, and a schema test rejects any other payload field.
   - Sign-in sessions (`auth_session`) are looked up before the tenant is known, so that table isn't under RLS either. Only the auth module reads it, and it holds no tenant content.
   - Logs and traces carry `tenant_id` as a field. There are no tenant caches in v1.
6. **Cross-tenant tests (C07)** at each layer: SQL with the wrong or no tenant, an API call naming another tenant's ID (404, audited), an S3 key or encryption context from another tenant, and a job whose payload's tenant differs from its row.

**Alternatives:**
- *Application filters only.* Rejected: one missed `WHERE` leaks data, and NFR-06 asks for isolation that a code review alone can't prove.
- *A schema or database per tenant.* Rejected for now: migrations multiply, the pool grows with tenants, and at pilot scale (tens of tenants) RLS gives the same guarantee. Revisit if a partner contract requires physical separation.
- *RLS with a session-level setting.* Rejected: a pooled connection could keep the previous tenant.

**Consequences:**
- Easier: a missing filter returns nothing instead of another tenant's rows; P-06's database role can't read tenant data at all.
- Harder: every migration adds its policy (a CI check fails on a tenant table without one); bulk jobs run per tenant; RLS policies cost a little at query time.
- We must now: write the role grants and the "table without policy" check in M0; add the C07 tests to TEST_STRATEGY.md (Stage 3).
