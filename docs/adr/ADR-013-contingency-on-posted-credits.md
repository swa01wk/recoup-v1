# ADR-013: Price the pilot as a contingency share of posted (verified) credits only; the free check stays free
Status: Accepted (decision delegated by the product owner)    Date: 2026-11-27

**Context:** PRD §16 #2 asks for the pricing model and percentage, assuming contingency. The strategy review lists pricing paid from recovered money as table stakes. Value is lumpy: most months are $0 (PRD §2). [ADR-004](ADR-004-claim-state-from-system-of-record.md) makes *posted* the only verified money. M-01 tests whether reconciliation is trusted enough to invoice against. KPI-09 targets one contingency agreement in the pilot. Raised as [QUESTIONS.md](../product/QUESTIONS.md) Q-02.

**Decision:**
1. **The free check (M1) is free.** No charge for the no-access estimate, the account report or its one ready-to-file packet ([ADR-001](ADR-001-free-check-first.md), Q-24).
2. **The pilot (M2) is contingency only:** Recoup earns a share of each credit that reaches *posted (verified)* through a matched CUR 2.0 Credit line (R-42). No fee on estimates, approved, submitted or granted amounts, and no subscription.
3. **Credits refunded outside the bill** (for example to a card, R-54) are invoiced only if the customer confirms the refund in writing, since Recoup can't verify them.
4. **Opening share: 20% of posted credits.** It is tested in the interviews ("Would you pay a share of recovered credits? What percentage?") and set before the first pilot agreement. A change before any contract is signed needs only a dated revision note here.
5. **No pricing logic in the product in v1.** The invoice is drawn from the ledger (R-48) outside the product.

**Alternatives:**
- *Monthly subscription.* Rejected: most months bring $0 in credits, so a fixed fee is hard to justify before value is shown.
- *Fee per prepared or filed claim.* Rejected: it charges for denied claims and rewards filing weak ones, against V-02.
- *A share of estimated or granted credits.* Rejected: it bills money that may never post, which breaks the honest money model (F-00).

**Consequences:**
- Easier: the customer pays only for money that shows up on their bill; the pitch needs no budget line.
- Harder: revenue lags incidents by two to three billing cycles; revenue depends on reconciliation (Q-12) being right.
- We must now: put the 20% question to every interviewee; draft the pilot letter of intent with "posted (verified)" defined by R-42.
