# ADR-024: A claim is one AWS account × one SLA contract × one Region × one billing cycle, and holds every matched incident in that cycle
Status: Accepted (decided in Stage 2a; product owner to review at G2)    Date: 2026-11-27

**Context:** The requirements speak of incidents and claims together (R-13, R-18, R-28, R-30). The SLAs measure something else. The API Gateway SLA, for example, sets a Monthly Uptime Percentage for each AWS Region during a monthly billing cycle, averaged over every 5-minute interval in the cycle, and computes the credit as a share of that Region's charges for that cycle ([DISCOVERY.md](../discovery/DISCOVERY.md#catalog-vs-the-public-sla); SLA page read 2026-11-27). Two incidents in the same cycle and Region therefore feed **one** uptime figure and **one** credit, and AWS asks for the dates, times and Regions of *each* incident in one request (R-28). Claims are filed from the affected account (ADR-007 §1), and credits can't move between accounts (Q-11, Q-19). Modelling one claim per incident would double-count credits and produce two packets for one AWS request.

**Decision:**
1. **The claim key is `(tenant, AWS account, contract, Region, billing cycle)`.** The contract version is pinned when the claim is created, chosen by the first incident's date ([ADR-005](ADR-005-sla-catalog-pinned-snapshots.md) §4). If incidents in one cycle fall under two versions, the claim is marked *unproven*, with the reason "contract changed mid-cycle", until P-06 reviews it.
2. **Incidents attach to the claim** through `claim_incident`. Each keeps its own source (account Health event, public event, customer-supplied, operator-entered), its window and its evidence.
3. **Eligibility and credit are computed once per claim**, over the whole cycle.
   - Inside each incident window, availability comes from the customer's evidence. An interval with no requests counts as the contract says; for API Gateway that's 100%. A window with no evidence makes the claim *unproven* (R-20).
   - Intervals outside every incident window count as fully available. That can only understate the credit, never overstate it, and it's stated in the calculation trace.
4. **Deadline:** one per claim, from the cycle (R-30, Q-14 earlier reading).
5. **Contracts with a different scope** (for example per instance or per table) declare their scope in the contract file. A contract whose scope isn't Region × cycle gets its own key in a dated revision of this ADR before it enters the catalog.

**Alternatives:**
- *One claim per incident.* Rejected: it double-counts the cycle's credit and splits one AWS request in two.
- *One claim per account and cycle across all services.* Rejected: each SLA has its own credit, contract and required fields.

**Consequences:**
- Easier: one packet per AWS request; the credit can't be counted twice; reconciliation has one granted amount per claim.
- Harder: a new incident late in a cycle changes an existing claim, so its eligibility is recomputed and any approval is invalidated by the content-hash change (R-36), which is the intended behaviour.
- We must now: use this key in the [DB schema](../contracts/db/schema.sql) and [API](../contracts/openapi.yaml); add golden tests with two incidents in one cycle.
