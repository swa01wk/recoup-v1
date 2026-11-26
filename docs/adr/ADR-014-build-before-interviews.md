# ADR-014: Build M0 and M1 before customer interviews; the free check becomes the discovery instrument, and G1 is signed with conditions
Status: Accepted (product owner, 2026-11-27)    Date: 2026-11-27

**Context:** Gate G1 needs the personas, journeys and value hypotheses confirmed, and per Q-09 that confirmation rests on interview evidence. PRD §14 plans interviews before M1 build-out. On 2026-11-27 the product owner decided interviews aren't possible now: build the product first and use the free check (the "nudge") for discovery once it's ready. [ADR-001](ADR-001-free-check-first.md) already makes the free check the discovery tool. Everything else in G1 passes ([REQUIREMENTS.md](../product/REQUIREMENTS.md#gate-g1-check)).

**Decision:**
1. **Build order:** M0 and M1 proceed without interview evidence. M2 (the pilot) does not start until the discovery checkpoint below is met.
2. **G1 is signed with conditions.** The product owner signs it as a baseline of *hypotheses*. Personas, journeys, stories, V-xx and M-xx stay labelled as hypotheses everywhere.
3. **Discovery moves into the product.** The free check's own results replace the interview tally:
   - KPI-02 (share with a claimable incident) is measured from account-specific reports (R-25 – R-32), not from what people remember.
   - KPI-10 (materiality) is measured from the estimates in those reports.
   - KPI-03 and the access-acceptance assumption (Q-07) are measured by the connection funnel.
   - Q-04, Q-08 and Q-20 are recorded at connection: support plan, log availability, seller.
   - Each connected prospect is offered a 30-minute conversation (ADR-001) to cover what the product can't measure: whether lost credits feel like a real problem, and willingness to pay 20% (ADR-013).
4. **Discovery checkpoint before M2:** at least 10 account-specific reports, with KPI-02 and KPI-10 read against the kill thresholds in Q-35, and at least 5 conversations held. The kill rule applies there.
5. **Cheap checks that don't wait for the product:** the Next Signal demo (PRD §14) and the AISPL terms check (Q-20). Both stay recommended before M1 build-out because they can change M1 scope.

**Alternatives:**
- *Interviews before any build (the PRD §14 plan).* Rejected by the product owner: not possible now.
- *Skip discovery altogether.* Rejected: the kill rule exists because credits may be too small or too rare.

**Consequences:**
- Easier: building starts now, and discovery rests on measured credits rather than recall.
- Harder: if credits turn out immaterial, the M0 and M1 effort is spent before we learn it. M0 is mostly reusable foundation, so most of the risk sits in M1. The SLA choice (Q-03) and the AISPL decision (Q-20) go ahead without interview input.
- We must now: add discovery fields to the connection flow (Stage 2 UI_DESIGN.md and OBSERVABILITY.md events); put the discovery checkpoint into DELIVERY_PLAN.md as the M2 entry gate (Stage 3). The PRD still says interviews come first (§4 goal 4, §11 KPI-01 and KPI-02 "measured by", §14), so it needs a revision the product owner approves.
