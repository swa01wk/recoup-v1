# ADR-008: Host PostgreSQL on Amazon RDS for PostgreSQL in Recoup's own AWS account
Status: Accepted (decision delegated by the product owner)    Date: 2026-11-27

**Context:** [ADR-006](ADR-006-durable-state-no-fallback.md) puts all state and audit in PostgreSQL with an outbox and left hosting open. The project rules list cloud and database choices as the product owner's call; on 2026-11-27 they asked for this one to be decided here. The constraints are AWS only for v1 and a modular monolith. PRD §12 requires durability, audit and tenant isolation, and treats billing data as confidential. Expected load in M1 and M2 is small: a handful of connected accounts and claims counted in tens.

**Decision:**
1. **Amazon RDS for PostgreSQL**, in Recoup's AWS account, in private subnets with no public access.
2. **Encrypted at rest** with a customer-managed KMS key, with TLS required for connections.
3. **Automated backups with point-in-time recovery** in every environment. Recovery targets come from the NFRs (Stage 1) and are rehearsed in hardening (PROCESS.md).
4. **Single-AZ for dev and staging. Multi-AZ for production** before the first design partner's data goes in (M2).
5. **Plain PostgreSQL only:** no engine-specific features that would block moving to Aurora or anywhere else. Tenant isolation is enforced in the schema (row-level security or tenant filters, chosen in Stage 2).
6. **Not decided here:** the region, which goes with data residency in `SECURITY.md`; instance sizes, which go in `TECH_STACK.md`; and how the app authenticates to the database (Stage 2). For the region, the first claim to weigh is that Recoup shouldn't depend on the region whose outages it reports on most.

**Alternatives:**
- *Aurora PostgreSQL (provisioned or Serverless v2).* Not now: its strengths (storage scaling, fast failover, many read replicas) aren't needed at pilot scale. Moving later is supported: an RDS for PostgreSQL instance can migrate to Aurora through an Aurora read replica or a snapshot ([Aurora migration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Migrating.html)).
- *PostgreSQL on EC2 or in containers that we run.* Rejected: we would own backups, patching and failover.
- *A managed PostgreSQL outside AWS.* Rejected: AWS only for v1, and it adds a second provider for confidential billing data.

**Consequences:**
- Easier: managed backups, patching and failover; the same engine in local containers (ADR-006) and in AWS.
- Harder: a fixed monthly cost from M0 even with no customers; Multi-AZ roughly doubles database cost in production.
- We must now: put the database in the M0 infrastructure-as-code; record its cost in `TECH_STACK.md`; choose the region in `SECURITY.md`.
