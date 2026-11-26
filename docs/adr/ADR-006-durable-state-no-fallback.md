# ADR-006: All state and audit live in PostgreSQL with a transactional outbox; there is no in-memory fallback
Status: Accepted    Date: 2026-11-27

**Context:** PRD §12 requires that state survives restarts, that every consequential action is audited, and that audit failures are visible, not silent. The project constraints set a modular monolith with PostgreSQL and an outbox ([PROCESS.md](../PROCESS.md) golden rule 9) unless an ADR says otherwise. The hackathon stores approvals and outcomes in DynamoDB when it's reachable, otherwise in a module-level dict, and logs a warning and carries on when a write fails ([DISCOVERY.md](../discovery/DISCOVERY.md), difference 5).

**Decision:**
1. **PostgreSQL holds all product state:** tenants, connections, incidents, claims and their stages, approvals and audit records. DynamoDB is not used.
2. **Audit records are written in the same transaction as the state change they describe.** If either fails, both fail.
3. **External effects go through a transactional outbox** (notifications today; any future write). Consumers handle at-least-once delivery and dedupe by event ID.
4. **No fallback store, in any environment.** If the database is unavailable, the operation fails and the error is shown. Local development and tests use a real PostgreSQL in a container (PROCESS.md testing model), never an in-memory substitute.
5. **Not decided here:** where PostgreSQL is hosted, and backups and recovery targets. Hosting is a cloud choice made with the product owner in Stage 2; recovery targets come from the NFRs.

**Alternatives:**
- *Keep DynamoDB.* Rejected: the project constraint is PostgreSQL, claims need transactional updates across claim, approval and audit, and nothing in the PRD needs DynamoDB's scale.
- *Keep an in-memory fallback for local development.* Rejected: it hides failures and makes local runs behave unlike production.

**Consequences:**
- Easier: a crash or restart loses no accepted work; every stage change has its audit record.
- Harder: the database becomes a hard dependency for every request, so its availability matters from M0.
- We must now: build the database, migrations and outbox in M0 (PRD §13); add an M0 test that a failed audit write rolls back the state change.
