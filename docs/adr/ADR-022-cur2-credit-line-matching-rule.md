# ADR-022: The claim-to-Credit-line matching rule: group CUR 2.0 Credit and Refund rows into credit lines, auto-match only an exact, unique Credit line for the claim's account, service and window, and send everything else to P-03
Status: Accepted (makes the Q-12 decision exact; Stage 2a)    Date: 2026-11-27

**Context:** A granted claim becomes *posted (verified)* only when a CUR 2.0 Credit line matches it (R-42; [ADR-004](ADR-004-claim-state-from-system-of-record.md)). Ambiguous matches wait for P-03 (R-43, US-18). Finalized months are re-read (R-44). Card refunds are kept apart (R-54). Contingency revenue is a share of posted credits only ([ADR-013](ADR-013-contingency-on-posted-credits.md)), so a false match costs the customer money and a missed one costs us revenue. [Q-12](../product/QUESTIONS.md#q-12-claim-to-credit-line-matching--decided-verify) fixed the rule's outline: account and service, the grant's billing period or the one after, the exact granted amount, P-03 for anything else, and never a match on amount alone. It left the CUR description text, product code and posting account to verify on the first real credit.

AWS facts (read 2026-11-27):
- `line_item_line_item_type` includes **Credit** (credits AWS applied to the bill; details in the description column) and **Refund** (negative charges AWS refunded). AWS may update a finalized report to add either ([line item columns](https://docs.aws.amazon.com/cur/latest/userguide/table-dictionary-cur2-line-item.html); [line item details](https://docs.aws.amazon.com/cur/latest/userguide/Lineitem-columns.html)).
- `line_item_unblended_cost` is a `double` ([CUR 2.0 line item columns](https://docs.aws.amazon.com/cur/latest/userguide/table-dictionary-cur2-line-item.html)).
- `identity_line_item_id` is unique only within a partition, isn't consistent between reports, and can't identify the same line across reports ([identity columns](https://docs.aws.amazon.com/cur/latest/userguide/table-dictionary-cur2-identity.html)). So it can't be the stored identity of a matched line.
- A member account's export contains only that account's data (Q-11).

**Decision:**
1. **What a claim brings:** usage account `A`; the contract's `cur_product_codes` ([SLA contract format](../contracts/sla-contract/README.md)); the granted amount `G` (customer-entered, USD, two decimals); and the grant's billing period `Bg`, the UTC calendar month containing the customer-entered grant date. The window is `{Bg, Bg+1}` (Q-12).
2. **Credit lines are built from CUR rows**, because one credit may be split over several rows:
   - Take rows where `line_item_line_item_type IN ('Credit','Refund')`, `line_item_usage_account_id = A`, `line_item_currency_code = 'USD'` and `line_item_unblended_cost < 0`, in a billing period within the window.
   - Group them by `(bill_billing_period_start_date, line_item_usage_account_id, line_item_product_code, line_item_line_item_type, line_item_line_item_description)`.
   - A group's amount is `-Σ Decimal(str(line_item_unblended_cost))`.
   - Its **fingerprint** is the SHA-256 of the group key plus the amount. The fingerprint, the group key, the export's delivery time and the source file keys are stored as the evidence; `identity_line_item_id` is not.
3. **Verified match (automatic):** the claim becomes *posted (verified)* when **exactly one** credit line in the window
   - is of type `Credit`,
   - has a `line_item_product_code` in the contract's `cur_product_codes`,
   - has an amount equal to `G` when both are rounded to the cent with `ROUND_HALF_EVEN`, and
   - isn't already matched to another claim (unique constraint per tenant on the fingerprint).
   Variances are stored: posted minus estimate (KPI-07) and posted minus granted.
4. **Possible match, which P-03 confirms or rejects (R-43):** every credit line in the window that fails point 3 only because of one of these:
   - its amount differs from `G`;
   - its product code is empty or outside the contract's codes;
   - it is a `Refund`;
   - more than one line meets point 3.
   The claim stays *granted*. A confirmed line moves it to *posted (verified, confirmed by P-03)*, recorded with who and when. A rejected line is never proposed for that claim again.
5. **Never matched:** a line outside the window, from another account, or in another currency; and any line on amount alone, which point 4 covers instead.
6. **Credit not seen (R-54):** once the export holds data for any day after the end of `Bg+1` and no line has been confirmed, the claim is flagged *credit not seen*. Reconciliation keeps re-reading the window on every export refresh (R-44) until the claim is posted, recorded as refunded outside the bill, or closed.
7. **A matched line that later disappears or changes** (AWS restating a month) changes nothing automatically. The claim is flagged *posted line changed*, an operator alert fires, and P-03 decides. Nothing reverses silently.
8. **Verify on the first real SLA credit** (the Q-12 task): the description text, the product code and the posting account. If AWS posts SLA credits with an empty product code, every credit becomes a P-03 confirmation until the rule is revised by a dated note here.

**Alternatives:**
- *Match on `identity_line_item_id`.* Rejected: AWS says it isn't stable across reports.
- *Match on amount within a tolerance.* Rejected: Q-12 says never on amount alone, and a tolerance invites false matches with promotional credits.
- *Match on description text.* Not now: the text is unverified. Once verified, it can raise confidence, never replace points 3–4.
- *Cost Explorer credits.* Rejected: aggregates only, not a line finance can tie to a claim ([ADR-009](ADR-009-billing-data-cur2-with-cost-explorer-bootstrap.md)).

**Consequences:**
- Easier: a deterministic rule with golden tests; every posted claim cites a reproducible fingerprint.
- Harder: until the first real credit is seen, some matches will need P-03; restated months need an operator path.
- We must now: add `cur_product_codes` to every contract file; build golden tests for each case above (exact, split rows, two candidates, refund, empty product code, restatement, credit not seen).
