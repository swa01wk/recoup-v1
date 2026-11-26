# Strategy review: who buys Recoup first

Date: 2026-11-26 · Status: Input to PRD v0.1 (product owner owns it)

> **Provenance.** The original (`claude/product-strategy-initial-recommendation.md`) was not available in this session. This doc was rebuilt on 2026-11-27 from the Recoup board (https://claude.ai/artifact/FvaaBYkbTX4d6xwJok8cpc), using only the sections added on 2026-11-26: the options, kill criteria, open questions, competitor features and customer discovery. The board's 2026-11-27 decision is in [ADR-001](../adr/ADR-001-free-check-first.md). Reasoning that was in the original but not on the board is lost. **Competitor facts are as recorded on the board, with no sources or dates of their own, and were not re-verified.** Treat each one as unverified.

**Headline:** lead with SLA credits, and kill the idea fast if the credits turn out to be immaterial.

## Options considered

| Option | Verdict | Why |
|---|---|---|
| A · Waste remediation and verified savings | Don't lead | AWS Compute Optimizer now auto-fixes unattached EBS volumes and gp2→gp3. CloudFix, PointFive, CloudZero and Harness already track realized savings. Recoup today has list-price estimates and no execution or verification. Kill test: compare against the customer's Cost Optimization Hub export. |
| **B · SLA credit recovery (recommended)** | **Lead, ~55% confidence** | Buyer: FinOps lead at AWS-heavy firms on Business+ Support. Job: file every owed credit before the deadline and prove it posted. Reuses the calculator, the contract catalog and the bound approval. Risk: credits too small or too rare to pay for. |
| C · Unified recovery | Not first | Two buyers, two cadences, twice the integrations. The repo already mixes savings and credits in one number. Revisit once B proves out. |

## Pilot workflow for B: one SLA claim, end to end

Detect (Health event + own logs) → Qualify (per-contract SLA + exclusions) → Estimate (credit from CUR charges) → Approve (bound to claim hash + amount) → Submit (customer files the case) → Track (case status + deadline) → Reconcile (match the CUR Credit line).

On the board, Qualify, Estimate and Approve are marked as hackathon code we can reuse; the rest has to be built for the pilot. Only Reconcile counts as verified money. Which modules are actually ported is decided in [ADR-002](../adr/ADR-002-new-repo-via-process.md).

## What would kill B

- Expected credits under about $10–15k a year per partner.
- Partners won't share request logs or CUR.
- A Next Signal demo shows filing, tracking and CUR reconciliation.
- A waste delta test finds 20% or more beyond Cost Optimization Hub → revisit A.

## Decide together next

1. Lead value stream: SLA credits vs. waste.
2. First buyer: companies directly vs. an MSP channel.
3. Who submits the claim, and contingency vs. subscription pricing.

## Open questions (unanswered on 2026-11-26)

| Question | Board's working guess |
|---|---|
| Which 3 design partners could we ask this week? | Two from our network, plus one MSP |
| What minimum yearly credits per customer make this worth selling? | About $10–15k |
| Do any target partners already use Next Signal? | Unknown |
| Have we spoken to any prospective customer yet? | Not yet |

## Competitor features: inherit, try to lead, or skip (proposed)

**Inherit: table stakes for SLA claims**
- Lookback over the open claim window (Next Signal).
- Read-only onboarding that connects in minutes (Next Signal, UptimeAudit).
- A label on every dollar: eligible → submitted → granted → posted (CloudFix pattern).
- Pricing paid from recovered money (Next Signal, nOps, ProsperOps).
- Handoff into Jira or Slack, not email (PointFive, Harness, FinOps Agent).
- An SLA catalog beyond API Gateway (Next Signal).
- Evidence from the customer's own telemetry (UptimeAudit, Next Signal).

**Try to lead: not found in public docs**
- Each claim matched to its CUR Credit line.
- Credit calculated to the exact contract version, with evidence hashed.
- Approval bound to the exact claim content (exists today).
- A deadline radar for claims about to expire.
- Denial reasons captured and resubmission tracked.

All five need checking in a Next Signal demo before we call them gaps.

**Skip for now: they pull us into option A**
- Automatic fixes and AutoStopping (CloudFix, GetFinOps, Harness).
- IaC pull-request fixes (PointFive).
- Commitment management (ProsperOps, nOps).
- Anomaly detection and cost chat (FinOps Agent, Harness).
- Hundreds of waste detections (PointFive, CloudFix).

If we ever do A, take estimates from Cost Optimization Hub, not from our own list prices.

## Customer discovery: learn this before building anything

**What we must learn** (ask about what happened, not what they'd do):
- Who owns SLA claims today, if anyone?
- The last AWS outage that hit you: did you file? What happened?
- How many claimable incidents in the last 12 months?
- What was a credit worth compared with the effort to file?
- What stops filing: logs, the deadline, effort, or not worth it?
- Did anyone check that the credit actually posted?
- What would a vendor need before you grant read access?
- Would you pay a share of recovered credits? What percentage?

**What a pilot needs from each partner:**
- A named owner (FinOps or SRE lead), about 30 minutes a week.
- Their support plan level (Business or higher).
- Rough AWS spend by service and region.
- Incidents or postmortems from the last 2 billing cycles.
- Read-only CUR and AWS Health access.
- Request logs for the affected services.
- A signed contingency letter of intent.

**How we learn it (next 2 weeks):**
- 10 interviews: 5 FinOps leads, 3 SRE or platform leads, 2 MSPs.
- Anchor every interview on their last real AWS incident.
- Tally: filed / didn't file / didn't know they could.
- **Confirm B** if half or more had a claimable incident and call lost credits a real problem.
- **Kill B** if credits are rare or tiny, or nobody will share logs.
- Pick 3 design partners from the interviews.
