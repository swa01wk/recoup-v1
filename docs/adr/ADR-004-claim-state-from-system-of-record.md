# ADR-004: A claim moves to a stage only on evidence from its system of record; nothing is ever simulated in product code
Status: Accepted    Date: 2026-11-27

**Context:** PRD F-00 requires an honest state and money model: no success is shown before billing confirms. PRD §12 requires every dollar to carry its stage and source. The project rules keep the claim stages separate and never show a later stage until its system of record confirms it. The hackathon build returns a made-up `replay-<hash>` case ID when there is no valid approval, always reports cases as `PENDING` with $0, and jumps approved claims straight to `RECOVERED` ([DISCOVERY.md](../discovery/DISCOVERY.md), difference 5 and the "Execution" row).

**Decision:**
1. **Stages, in order:** detected → eligible (or unproven) → approved → submitted → granted or denied → posted. The names are fixed in Stage 2 contracts; the order is not.
2. **Each move needs named evidence:**

   | Moves to | Evidence | Source in the PRD |
   |---|---|---|
   | eligible / unproven | Calculation result against a pinned contract version ([ADR-005](ADR-005-sla-catalog-pinned-snapshots.md)) | US-04, F-04 |
   | approved | An approval bound to the exact claim content and amount | US-07, F-08 |
   | submitted | An AWS Support case ID, recorded with who entered it and when | US-08, F-09 |
   | granted / denied | The case outcome, recorded with its source | US-10, F-09 |
   | posted | A matched Credit line in the customer's billing data | US-09, F-10 |

   Only *posted* is verified money. Every earlier amount stays labelled *estimate* or by its stage.
3. **No simulated values in product code.** No placeholder case IDs, statuses or amounts, and no demo or replay mode in the product. Fakes live only in tests and can't reach product state. The hackathon's replay and demo paths are not ported ([ADR-002](ADR-002-new-repo-via-process.md)).
4. **Fail closed.** A step that can't complete returns a typed failure, and the claim stays at its last confirmed stage.
5. **Who files is not decided here.** That is open question 1 (PRD §16), with the assumption that the customer files in v1. This ADR holds either way: if the customer files, the case ID is customer-entered and labelled so; if Recoup ever files, the case ID comes from the AWS Support API response.

**Alternatives:**
- *Keep a demo mode with simulated stages for sales.* Rejected: the hackathon shows how demo states leak into the product. If a demo is needed, it runs against a real test account.
- *Advance stages optimistically and correct them later.* Rejected: it breaks F-00 and KPI-07, which needs posted amounts to compare with estimates.

**Consequences:**
- Easier: every number on screen can be traced to its evidence, which is what M-01 (invoicing against reconciliation) needs.
- Harder: the UI has to show waiting states honestly (for example "submitted, waiting for AWS"); M2 can't show a success until a credit actually posts.
- We must now: model the stages as a state machine with guards in Stage 2; add M0 tests that no product path can produce a stage without its evidence; record who-files as a Q-xx in Stage 1.
