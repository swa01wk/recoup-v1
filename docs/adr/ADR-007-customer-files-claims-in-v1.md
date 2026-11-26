# ADR-007: The customer files each claim in AWS Support Center; Recoup prepares it and never holds a permission to file
Status: Accepted (decision delegated by the product owner)    Date: 2026-11-27

**Context:** PRD §16 question 1 asks who submits the claim, assuming the customer files in v1. The project rules list "who submits claims" as the product owner's call; on 2026-11-27 they asked for it to be decided here. Customer access is read-only ([ADR-003](ADR-003-customer-read-only-role.md)), and a claim moves to *submitted* only on a case ID ([ADR-004](ADR-004-claim-state-from-system-of-record.md)). F-15 (automatic filing through the Support API) is a later Could. The board notes that Next Signal's public pages conflict on who submits.

AWS facts (read 2026-11-27):
- AWS SLAs say a credit is claimed by opening a case in the AWS Support Center (for example the [S3](https://aws.amazon.com/s3/sla/) and [compute](https://aws.amazon.com/compute/sla/) SLAs).
- Account and billing cases are available to all AWS customers, whatever their support plan ([case management](https://docs.aws.amazon.com/awssupport/latest/user/case-management.html)). Customers of a partner that resells AWS Support raise billing issues with that partner instead.
- Creating a case through the Support API (`CreateCase`) needs a Business Support+, Enterprise Support or Unified Operations plan. The older Business, Enterprise On-Ramp and Enterprise plans still work where an account hasn't moved to the new plans ([CreateCase](https://docs.aws.amazon.com/awssupport/latest/APIReference/API_CreateCase.html)).

**Decision:**
1. **In v1 the customer files.** Recoup gives them a ready-to-file packet (F-06): the subject line, fields and log excerpts each contract asks for, plus the deadline. The customer opens an Account and billing case in Support Center from the affected account, then enters the case ID in Recoup (US-08, F-09).
2. **Recoup never holds `support:CreateCase`** or any other permission that files, edits or comments on a case. Filing is a write, and v1 is read-only (ADR-003).
3. **Filing is made fast instead of automatic:** one-click copy of the subject and body, the log excerpts as an attachment with sensitive data removed, a direct link to the Support Center create-case page, and a reminder before the deadline (F-11).
4. **Case status:** entered by the customer in v1, and labelled as customer-entered (ADR-004). Reading status with `support:DescribeCases` (read-only) where the customer's plan allows the Support API is a Stage 2 option, not a v1 requirement.
5. **Resold support:** when a customer buys AWS Support through a partner, the filing path goes through that partner. This becomes part of PRD §16 question 5 (MSPs and resellers) and isn't supported in v1.
6. **When to revisit Recoup filing (F-15):** only if the pilot shows filing itself is where claims are lost (claims prepared but not filed before the deadline). That needs its own ADR, with approval binding, audit, a receipt and reconciliation, and only for accounts on a plan that supports the API.

**Alternatives:**
- *Recoup files through the Support API.* Rejected for v1. It needs a write permission in the customer's account, it only works on paid support plans, and filing on a customer's behalf raises an authority question we haven't validated (PRD §16 question 7).
- *Recoup files by email or from its own account.* Rejected: credits are claimed by the customer's account through Support Center.

**Consequences:**
- Easier: works on every support plan; the permission list stays read-only; nothing in v1 acts in the customer's name.
- Harder: Recoup depends on the customer actually filing. The prepared → filed drop-off becomes a metric (it sits between KPI-05 and KPI-06), and the packet has to save real time (KPI-08).
- We must now: record PRD §16 question 1 as resolved by this ADR in Stage 1. PRD §12 also names support plans that AWS has since replaced; Stage 1 should update NFRs that mention support plans to the new names.
