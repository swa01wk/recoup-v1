# ADR-001: Ship a free missed-credit check first; build pilot features only for design partners it turns up
Status: Accepted    Date: 2026-11-27

> **Provenance.** This is decision D1. The original decision log (`claude/decision-log.md`) was not available in this session. This ADR was rebuilt on 2026-11-27 from the Recoup board (https://claude.ai/artifact/FvaaBYkbTX4d6xwJok8cpc, section "Build first, then the nudge that brings evaluators (decided 2026-11-27)") and PRD v0.1 §1, §8 and §13. The product owner should confirm it matches the original.

**Context:** The strategy review ([strategy-review-2026-11-26.md](../sources/strategy-review-2026-11-26.md)) recommends leading with SLA credit recovery (option B), at about 55% confidence. The main risk is that credits are too small or too rare to pay for. No prospective customer has been interviewed. We need something that is useful to a prospect on day one and that also gets us interviews. The SLA-credit feature list is in PRD §8; the requirements will come from Stage 1 (`REQUIREMENTS.md`).

**Decision:** The first release is a free missed-credit check, in two steps:
1. **No access:** the prospect picks regions, services and rough spend, and sees which recent AWS incidents might qualify, with a dollar range labelled *estimate*.
2. **Read-only access:** using billing data and AWS Health, the prospect sees the credits they can still claim, plus one ready-to-file claim.

In return we ask for a 30-minute interview. If the credit posts, we discuss contingency pricing.

On the board, rows 0–4 ship first as the free check. Row 0 (remove the fake Recovered/Verified states and split savings from credits) ships in M0, before any M1 work. Rows 5–8 (bound approval, claim-to-credit-line matching, deadline radar, evidence trail) ship with the pilot, only for design partners the check turns up. How these rows map to F-xx and milestones is owned by PRD §8 and §13.

**Alternatives:**
- *Build the full pilot workflow first.* Rejected: it spends build effort before interviews show that credits are material.
- *Lead with waste remediation (option A), or unified recovery (option C).* Rejected in the strategy review. Open decision #1 (lead value stream) stays open, and this ADR doesn't close it.
- *Offer only the no-access estimator.* Rejected as not distinctive: Next Signal's homepage already estimates recovery from spend (recorded on the board on 2026-11-26, not re-verified).

**Consequences:**
- Easier: an offer for outreach and a discovery tool in one; the funnel is measurable (outreach → interviews → access granted → claims filed → credits posted).
- Harder: the check must be honest from the first release. Every dollar is labelled *estimate* until billing confirms it, and the M0 honest state model comes before any M1 feature.
- We must now: run the interviews (PRD KPI-01, KPI-02); keep pilot-only features out of M1; and revisit this ADR if the kill criteria in the strategy review are met.
