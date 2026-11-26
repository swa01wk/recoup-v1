# ADR-010: In v1 the customer supplies request-log evidence by upload; the read-only role gets no log or metric permission
Status: Accepted (decision delegated by the product owner)    Date: 2026-11-27

**Context:** Eligibility must be proven from the customer's own request data (PRD §6 J-03, US-04, US-06; [REQUIREMENTS.md](../product/REQUIREMENTS.md) R-18, R-52). The role in [ADR-003](ADR-003-customer-read-only-role.md) reads only billing data and AWS Health, so nothing in the design delivers that data. The hackathon never read customer logs either. Its only "live" source was a CloudWatch metric it had injected itself ([DISCOVERY.md](../discovery/DISCOVERY.md), "Availability evidence"). P-04 approves short permission lists (Q-07), and customers may keep logs outside AWS or not long enough (Q-08). Raised as [QUESTIONS.md](../product/QUESTIONS.md) Q-13.

**Decision:**
1. **Evidence comes in as files the customer uploads** for one incident window. Each contract's structured file ([ADR-005](ADR-005-sla-catalog-pinned-snapshots.md)) lists the formats and fields it accepts (for API Gateway: per-request timestamp, status and API ID from access logs).
2. **The ADR-003 role is not widened.** It gets no CloudWatch Logs, CloudWatch metrics or S3 log-bucket read.
3. **Uploads are untrusted input** (NFR-09). They are parsed, never executed, with size and type limits. They are hashed on receipt and stored encrypted under the tenant.
4. **Availability is computed in code** from the parsed requests, per the contract's measurement definition (R-18). Only redacted excerpts go into a packet (R-29). Raw files are deleted on the schedule in Q-27.
5. **Postmortems and free-text notes** can be attached for context, but only incident windows that P-02 enters or confirms feed eligibility (no model, [ADR-011](ADR-011-no-model-in-v1.md)).
6. **When to revisit:** if the pilot shows that uploading is where claims stall (ready rate, KPI-08 or KPI-11), propose a read-only metric or log read as an ADR-003 revision. First, verify that the service's CloudWatch error metric matches its SLA's error definition (for API Gateway, the SLA counts only API Gateway internal errors).

**Alternatives:**
- *Read CloudWatch Logs through the role.* Rejected: it exposes whole log groups that hold personal data and lengthens the permission list for P-04.
- *Read CloudWatch metrics through the role.* Deferred: lighter, but whether the metrics match each SLA's error definition is unverified.
- *Ship a script the customer runs to extract and summarise logs.* Deferred: running our code in the customer's environment is a new trust surface to review.

**Consequences:**
- Easier: the permission list stays short; it works wherever the customer keeps logs; Recoup holds only the incident window.
- Harder: P-02 does manual work per claim, which KPI-08 measures; each contract needs a parser and fixtures for its formats.
- We must now: define accepted formats per contract in the catalog (Stage 2 contracts); add upload limits, hashing and redaction to SECURITY.md; plan parser golden tests in Stage 3.
