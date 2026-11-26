# Recoup PRD v0.1 — AWS SLA Credit Recovery

**Status:** Draft for product owner review · **Version:** v0.1 · **Date:** 2026-11-27
**Owner:** Product owner (Recoup). This PRD is the input to PROCESS.md Stage 1; `REQUIREMENTS.md` (R-xx, NFR-xx) is derived from it in the new repo.
**Inputs:** `docs/sources/strategy-review-2026-11-26.md`, `docs/discovery/DISCOVERY.md`, `docs/adr/ADR-001-free-check-first.md` (D1), `docs/adr/ADR-002-new-repo-via-process.md` (D2), Recoup board (https://claude.ai/artifact/FvaaBYkbTX4d6xwJok8cpc).

> **Read this first.** Everything about customers in this PRD is a hypothesis. No prospective customer has been interviewed yet. Personas, journeys, KPIs and value claims become requirements only after Gate G1, which needs interview evidence.

---

## 1. Summary

Recoup helps AWS-heavy companies recover the SLA credits AWS owes them after service incidents. It matches AWS incidents to the customer's own services and regions, checks eligibility against the exact SLA version using the customer's own logs, estimates the credit from real billed charges, and prepares a ready-to-file claim before the deadline. In the pilot it also tracks each claim and confirms whether the credit actually posted to the bill.

The first release is a **free missed-credit check** (decision D1). It is both the product's entry point and our customer-discovery tool.

### Decisions this PRD rests on

The ADRs (`docs/adr/ADR-001-free-check-first.md` for D1, `docs/adr/ADR-002-new-repo-via-process.md` for D2) own these decisions. This PRD links to them rather than restating them.

| Decision | What it shapes in this PRD |
|---|---|
| **D1** — Free missed-credit check first; pilot features only for design partners it turns up | Goals 1–3 (§4), features F-00 to F-13 and their releases (§8), release plan (§13) |
| **D2** — New private repo built through PROCESS.md; port only listed modules | Dispositions in §3, M0 in §13, open question 9 (§16) |
| **Open decision #1** — Lead value stream: SLA credits vs. waste (not decided) | Non-goals (§4), F-16 and out of scope (§8, §15), kill metrics KPI-02 and KPI-10 (§11) |

## 2. Problem

- **Credits go unclaimed.** Most AWS SLAs require the customer to request credits: open a Support case with specific fields and logs, usually by the end of the second billing cycle after the incident. (Some instance-level terms, such as EC2's, waive certain charges automatically.) *(Hypothesis: most eligible customers don't file. To validate: V-01.)*
- **Eligibility is hard to prove.** Each service has its own SLA, versioned over time, measured on the customer's own requests, with exclusions. Public status pages don't show whether a given account breached.
- **Nobody can show what came back.** Credits post later as billing line items. Finance can't easily tie a posted credit to the claim and incident behind it.
- **Value is lumpy.** Most months are $0; large regional incidents (for example us-east-1, October 2025) can make several services eligible at once.

## 3. Current state: the hackathon build (baseline)

Source: `docs/discovery/DISCOVERY.md`, repo `swa01wk/recoup` @ `d009df7`. Labels per project rules. DISCOVERY.md owns the evidence; ADR-002 owns the port list.

| Capability | Status | Disposition in the new version |
|---|---|---|
| Read-only role with ExternalId (`infra/cdk/lib/stacks/iam-stack.ts`, `RecoupReadOnlyRole`) | IMPLEMENTED (single-account: trusts a role in the same account; default ExternalId constant) | **Port the pattern only**; rebuild as a customer-deployed role with billing-data and AWS Health reads (ADR-003) |
| Remediation role and live EC2 stop (`iam-stack.ts` `RecoupRemediationRole`, `tools/ec2_tools.py`) | IMPLEMENTED (write path) | **Drop.** Never port; no writes in v1 (ADR-003) |
| AWS waste scanners, 9 services, us-east-1, list-price estimates | IMPLEMENTED (heuristic) | **Out of scope for v1.** Stays in the hackathon repo; revisit with open decision #1 |
| Evidence packaging and recovery cases for waste findings | IMPLEMENTED (no new evidence gathered) | Out of scope for v1 |
| Human triage with approval bound to claim hash, amount, state version, 24h expiry (`approval/flow.py`) | IMPLEMENTED (logic) | **Port** into the control plane for M2 |
| "Execution" after approval | NOT ON PATH — approve jumps to RECOVERED | **Drop.** Never port |
| "Recovery Verified" panel and Recovery Ledger "Verified savings" | DEMO — static check marks, estimate copied as verified | **Drop.** Replace with the SLA credit ledger (F-13) |
| SNS "recovery report" email | IMPLEMENTED, delivery unverified, says "advisory" | **Drop** |
| SLA credit calculator, Decimal (`engines/calculator.py`) | REPLAY; any imperfect interval counts as fully down; no $1 minimum; exclusions never evaluated | **Port and fix** (ADR-005) |
| SLA contract catalog, 1 contract: API Gateway 2022-05-05 (`sla_catalog/`, `engines/sla_resolver.py`) | REPLAY; tiers and deadline match the public SLA; exclusions and required fields don't; `source_hash` placeholder that its test accepts | **Port and rebuild** as pinned snapshots (ADR-005) |
| Claim submission, case monitoring | STUBBED (made-up replay case ID when there is no valid approval; fails when there is one; monitoring always PENDING/$0) | **Rebuild** (ADR-004) |
| AWS Health event intake (`sqs_poller.py`) | Events acknowledged and dropped | **Rebuild** |
| Strands / AgentCore agent nodes | PARTIAL | **Defer** (start deterministic) |
| Opportunity, approval and outcome state | DynamoDB when reachable, silent in-memory fallback | **Rebuild** on PostgreSQL with an outbox, no fallback (ADR-006) |
| Tests and CI | Not run; no CI in repo | **Rebuild** under PROCESS.md M0 |

## 4. Goals and non-goals

**Goals (v1)**
1. Show a prospect, with no AWS access, which recent AWS incidents might have earned them credits (M1).
2. With read-only access, produce an account-specific list of credits still claimable, with one ready-to-file claim (M1).
3. For pilot partners, take a claim from approval to a confirmed posted credit, with every dollar labeled by stage (M2).
4. Learn from 10 interviews whether SLA credits are material enough to sell (KPI-02, KPI-10).

**Non-goals (v1)**
- Any write to a customer's AWS account.
- Waste remediation, recurring-savings tracking, commitment (RI/Savings Plan) management.
- Automatic claim submission through the AWS Support API (Could, later).
- Azure, GCP and other providers.
- Cost anomaly detection, chat-based cost Q&A.

## 5. Personas (hypotheses)

| ID | Persona | Job | Difficulties | Success means |
|---|---|---|---|---|
| P-01 | **FinOps lead** (buyer) | Report cost outcomes to finance; recover money owed | No owner for SLA claims; no time to read SLA terms | Credits filed on time and shown as posted, with a trail finance accepts |
| P-02 | **SRE / platform incident lead** (does the evidence work) | Run incidents and postmortems; holds the logs | Claims are low priority after an outage; log pulling is manual | Gives evidence in under 30 minutes per claim |
| P-03 | **Cloud finance analyst / controller** (verifies money) | Reconcile the AWS invoice | Can't tie a credit line to a claim | Each posted credit traces to its claim and incident |
| P-04 | **Security reviewer** (gatekeeper) | Approve third-party access | Broad roles fail review | A short, read-only permission list with ExternalId |
| P-05 | **MSP account manager** (secondary, hypothesis) | Serve many end-customer AWS accounts | One incident hits many customers | Batch claims across the book. *Entitlement under reseller arrangements unverified (Q-05)* |

## 6. User journeys

| ID | Journey | Trigger | Steps | Outcome | Release |
|---|---|---|---|---|---|
| J-01 | **No-access credit check** | Outreach, or a recent AWS incident | Pick regions, services, rough monthly spend → see AWS incidents in the open claim window that might qualify, with a $ range labeled *estimate* → book an interview or connect an account | Prospect sees possible credits; we get an interview | M1 |
| J-02 | **Connect read-only** | Prospect wants an account-specific check | Deploy the read-only role template (ExternalId) → security reviewer sees the exact permissions → connection test confirms CUR and AWS Health access | Account connected, read-only | M1 |
| J-03 | **Account-specific credit check** | Account connected | Ingest billing data and AWS Health history for the open claim window → match incidents to the account's services and regions → check eligibility against the contract version, using the customer's logs where available → estimate credit from billed charges → produce one ready-to-file claim with its deadline | Report of claimable credits; one claim ready | M1 |
| J-04 | **Approve and file** | Claim ready | FinOps lead reviews evidence → approves (bound to exact claim content and amount) → customer files the case in AWS Support Center using the packet → enters the case ID | Claim submitted, case ID recorded | M2 |
| J-05 | **Track and reconcile** | Case submitted | Update case status (granted / denied with reason) → match the posted credit to its billing Credit line → record variance vs estimate | Credit shown as posted (verified), or denied with reason | M2 |
| J-06 | **Deadline radar** | New billing cycle | Flag claimable incidents nearing their deadline → notify the owner | No claim expires unnoticed | M2 (Should) |

**Branches to design for:** support plan without AWS Health API access (Basic; Developer until 2027-01-01) → fall back to public AWS Health events and a customer-supplied incident list; logs unavailable (eligibility shown as *unproven*, claim not marked ready); credit under AWS's $1 minimum (not claimable); single-AZ incident against a region-level SLA (likely not eligible; say why).

## 7. User stories

| ID | Story | Journey | Release | Acceptance (summary) |
|---|---|---|---|---|
| US-01 | As P-01, I want to see which recent AWS incidents may have earned us credits without granting access, so I can decide if it's worth a closer look | J-01 | M1 | Incidents in the open claim window for chosen regions/services, each with deadline and $ range labeled *estimate* |
| US-02 | As P-04, I want a read-only role with an exact, minimal permission list, so I can approve access quickly | J-02 | M1 | Template deploys; permission list shown before deploy; no write actions |
| US-03 | As P-01, I want incidents matched to our actual services and regions, so I only see ones that affected us | J-03 | M1 | Each match cites the AWS Health event and the billed service/region |
| US-04 | As P-01, I want eligibility checked against the SLA version in force on the incident date, with exclusions, so I don't file weak claims | J-03 | M1 | Contract version, source URL and hash shown; exclusion checks listed; unproven cases marked unproven |
| US-05 | As P-03, I want the credit estimate computed from our billed charges, so it reflects what we paid | J-03 | M1 | Charges from billing data for service, region, month; Decimal math; $1 floor applied; labeled *estimate* |
| US-06 | As P-02, I want a ready-to-file claim in AWS's required format, so filing takes minutes | J-03 | M1 | Subject line, dates/times, region, resource IDs, log excerpts with sensitive data stripped; deadline shown |
| US-07 | As P-01, I want to approve a claim bound to its exact content and amount, so nothing changes after I sign off | J-04 | M2 | Any change to content or amount invalidates the approval |
| US-08 | As P-02, I want to record the case ID after filing, so the claim can be tracked | J-04 | M2 | Case ID stored; claim moves to *submitted* |
| US-09 | As P-03, I want each posted credit matched to its claim, so I can reconcile the invoice | J-05 | M2 | Billing Credit line matched; status *posted (verified)*; variance vs estimate shown |
| US-10 | As P-01, I want denied claims recorded with AWS's reason, so we learn what gets granted | J-05 | M2 | Denial reason stored; claim closed or resubmission tracked |
| US-11 | As P-01, I want warnings before a claim deadline passes | J-06 | M2 | Alert N days before deadline (N set at Stage 1) |
| US-12 | As P-03, I want an evidence trail per claim, so finance and AWS can audit it | J-05 | M2 | Incident, contract hash, evidence hashes, approval, case ID, credit line on one record |

## 8. Features: current vs enhancements

| ID | Feature | Hackathon status | v1 enhancement | Release | Priority |
|---|---|---|---|---|---|
| F-00 | Honest state and money model | DEMO (fake Recovered/Verified, mixed savings and credits) | No success shown before billing confirms; SLA credit stages only (eligible → approved → submitted → granted/denied → posted) | M0 | Must |
| F-01 | Read-only account connection | IMPLEMENTED | Add billing-data and AWS Health read; show permission list; connection test | M1 | Must |
| F-02 | Incident detection and account matching | Dropped | AWS Health (account-specific + public) matched to billed services/regions | M1 | Must |
| F-03 | SLA contract catalog | 1 contract | 3–5 contracts chosen from interview spend data; versioned, source-hashed | M1 | Must |
| F-04 | Eligibility and credit calculation | REPLAY, interval math wrong, exclusions hardcoded | Per-interval availability per contract definition; exclusions evaluated; $1 floor | M1 | Must |
| F-05 | Billed charges from billing data | Fixture | Charges for service/region/month from CUR / Data Exports | M1 | Must |
| F-06 | Claim packet with deadline | Replay packet | AWS required fields per contract; deadline computed | M1 | Must |
| F-07 | No-access estimator | None | Regions/services/spend → incidents and $ range | M1 | Must (not distinctive: a similar estimator exists at Next Signal) |
| F-08 | Bound approval | IMPLEMENTED (logic) | Port; add policy revision and revocation | M2 | Must |
| F-09 | Case tracking | STUBBED | Manual case ID and status entry first | M2 | Must |
| F-10 | Credit reconciliation to billing Credit line | None | Match claim → credit line; variance | M2 | Must (distinctive, hypothesis) |
| F-11 | Deadline radar | None | Alerts before deadlines | M2 | Should |
| F-12 | Per-claim evidence trail | Partial | Hashes, contract source, approval, case, credit line | M2 | Should (distinctive, hypothesis) |
| F-13 | SLA credit ledger | Mixed savings/credit ledger | Separate ledger; never summed with savings | M2 | Must |
| F-14 | Jira/Slack handoff to the SRE | Email to one topic | Task to P-02 to supply logs | Later | Could |
| F-15 | Automatic filing via AWS Support API | None | Requires a plan with Support API access (Business Support+, Enterprise Support or Unified Operations) and approval binding | Later | Could |
| F-16 | Waste remediation and savings | DEMO | — | — | Won't (v1) |

## 9. Agent steps and maturity

Following PROCESS.md: *start deterministic*. Eligibility, calculation, deadlines, matching and reconciliation are deterministic code. A model is used only where judgement adds value, and never authorises a transition.

| Journey step | Agent prepares | Human decision it feeds | Approver | Target maturity |
|---|---|---|---|---|
| J-03 incident windows from postmortems or free-text incident notes | Proposed incident windows and affected resources, with sources | Confirm windows before eligibility runs | P-02 | L3 |
| J-03 claim narrative | Draft claim text from verified facts only | Review before approval | P-01 | L3 |
| J-05 denial reason capture | Structured reason from AWS case text (treated as untrusted data) | Confirm classification | P-01 | L3 |
| Everything else | — (deterministic) | — | — | n/a |

No maturity level is claimed until tests show it.

## 10. Value and defensibility (hypotheses, in the order they'd be earned)

| ID | Hypothesis | Proof checkpoint |
|---|---|---|
| V-01 | Eligible customers lose credits because filing is effortful and deadlines pass | ≥50% of interviewees had a claimable incident in 12 months and call lost credits a real problem |
| V-02 | Evidence from the customer's own logs, per exact contract version, raises the grant rate | Pilot grant rate ≥70% and above partners' past experience |
| M-01 | Claim-to-billing-line reconciliation is trusted enough to invoice against | A partner pays a contingency invoice without its own check; zero disputes |
| M-02 | Claim outcomes across customers make eligibility predictions better than anyone else's | After enough claims, predicted vs actual grant outcomes measurably agree (threshold set at Stage 1) |
| M-03 | MSPs are a channel: one incident → claims across many accounts | One MSP pilots across its book (depends on Q-05) |

Competitive context (as of 2026-11-26): Next Signal markets SLA monitoring with claim preparation, a 60-day lookback and pricing from recovered credits; its public pages conflict on who submits AWS claims and don't document claim-to-billing reconciliation. UptimeAudit (third-party listing only) drafts claims from status pages and health endpoints for the customer to submit. M-01 and M-02 must be checked against a Next Signal demo before we call them gaps.

## 11. Success metrics (KPI-xx)

| ID | Metric | Target (hypothesis) | Measured by |
|---|---|---|---|
| KPI-01 | Interviews completed | 10 in 2 weeks (5 FinOps, 3 SRE/platform, 2 MSP) | Interview log |
| KPI-02 | Share of interviewees with ≥1 claimable incident in 12 months | ≥50% to confirm; well below → kill | Interview tally |
| KPI-03 | No-access check → read-only connection | ≥30% | Product analytics |
| KPI-04 | Time from connection to report | ≤24 hours | Job timestamps |
| KPI-05 | Claims filed per connected account | ≥1 in the pilot window | Claim records |
| KPI-06 | Grant rate of filed claims | ≥70% | Case outcomes |
| KPI-07 | Estimate accuracy | Posted within ±10% of estimate | Reconciliation records |
| KPI-08 | SRE time per claim | <30 minutes | Partner self-report |
| KPI-09 | Paid agreements | ≥1 contingency agreement in the pilot | Contracts |
| KPI-10 | Expected annual credits per partner | Below ~$10–15k → kill B | Pilot data |

## 12. Constraints and non-functional needs (become NFR-xx)

- **Read-only, least privilege.** No write to customer accounts in v1. ExternalId on every role. Permission list visible before deploy.
- **Money labeling.** Every dollar carries its stage (estimate, approved, submitted, granted, posted) and source. SLA credits are never summed with savings.
- **Exact math.** Decimal arithmetic; contract version pinned by incident date; source hash recorded.
- **Data handling.** Billing data is confidential. Logs may contain personal data: strip before including in claims (AWS asks for sensitive data to be removed). Retention and applicable law (e.g. DPDP Act, GDPR) set in `SECURITY.md`.
- **Tenant isolation** end to end.
- **Durability and audit.** State survives restarts; every consequential action is audited; audit failures are visible, not silent.
- **Untrusted input.** AWS case text, logs, postmortems and Health event text are data, never instructions.
- **Support-plan dependency.** AWS Health API and Support API need AWS Business Support+, Enterprise Support or Unified Operations; accounts not yet moved to these plans can use Business (classic), Enterprise On-Ramp or Enterprise until those plans end on 2027-01-01. Design a fallback for accounts without these plans.

## 13. Release plan

| Milestone | Delivers | Journeys | Exit (summary) |
|---|---|---|---|
| M0 Foundation | New repo per PROCESS.md, CI, harnesses, durable store, outbox, honest state model (F-00; D1 row 0, placed in M0 so it lands before any M1 work) | — | PROCESS.md M0 exit |
| M1 Free missed-credit check | F-01 to F-07 | J-01, J-02, J-03 | A connected test account gets a correct report; estimator live |
| M2 Pilot | F-08 to F-13 | J-04, J-05, J-06 | One real claim reconciled to a posted credit for a design partner |

Dates are set at Gate G3.

## 14. Dependencies and risks

| Risk | Impact | Mitigation |
|---|---|---|
| Credits too small or rare (KPI-10) | B fails as a business | Interviews before M1 build-out; kill rule |
| Customers won't share logs or billing data | No account-specific evidence | No-access path; minimal permission list; customer-supplied exports |
| Next Signal already does reconciliation | Differentiation collapses to price | Demo before G1 |
| Low support plans block Health/Support APIs | Narrower segment | Fallback inputs; segment on Business Support+ or higher |
| SLA terms change | Wrong eligibility | Versioned catalog with source hashes; periodic recheck |
| Contingency pricing needs reconciliation we can't yet do | Can't invoice | F-10 in M2 before charging |

## 15. Out of scope

Waste remediation and savings (hackathon scanners stay in the old repo), commitment management, automatic changes in AWS, automatic claim submission (later), other clouds, anomaly detection, chat Q&A, Strands/AgentCore runtime for v1.

## 16. Open questions (become Q-xx, each with an assumption)

| # | Question | Assumption if unanswered | Who answers |
|---|---|---|---|
| 1 | Who submits the claim: customer or Recoup on their behalf? | Customer files in v1 | Product owner, after interviews |
| 2 | Pricing: share of posted credits, and what %? | Contingency, % set after interviews | Product owner |
| 3 | Which 3–5 SLAs to support first? | Chosen from interviewees' top spend services | Interviews |
| 4 | What share of targets have Business+ support? | Majority of the segment | Interviews |
| 5 | Under reseller/MSP arrangements, who may file and keep the credit? | Not supported in v1 | Research + MSP interviews |
| 6 | Does any target already use Next Signal or a similar tool? | Unknown | Interviews |
| 7 | Do customers accept a read-only role from an early-stage vendor? | Yes, if the permission list is short | Interviews |
| 8 | Log retention: do customers keep request logs long enough for the claim window? | Often not; design for partial evidence | Interviews |
| 9 | Gate sign-off: who signs G1–G5? | Product owner signs as product owner and tech lead; interview evidence stands in for client confirmation at G1 | Product owner |

## Revision notes

- **v0.1, 2026-11-27:** First draft, written by Claude from the strategy review, decisions D1–D2 and the repository baseline, for the product owner to revise. Discovery-phase edits allowed in place until G3, per PROCESS.md.
- **v0.1, 2026-11-27 (revision 2):** Added "Decisions this PRD rests on" (§1); softened the claim-filing statement in §2 (most SLAs need a request; some instance-level terms waive charges automatically); noted in §13 that D1 row 0 ships in M0.
- **v0.1, 2026-11-27 (revision 3):** Updated the seed docs' references to their repo paths after the repo bootstrap: the "Inputs" line (strategy review, DISCOVERY.md, ADR-001, ADR-002), the decision-log reference in §1 (now the ADRs) and the baseline source in §3 (now DISCOVERY.md). Approved by the product owner. No other change.
- **v0.1, 2026-11-27 (revision 4):** Corrected §3 against `docs/discovery/DISCOVERY.md`: the role is single-account today; added the remediation role and EC2 stop path (drop); stated the calculator and catalog defects; restated the claim-submission stub; state is DynamoDB with a silent in-memory fallback. Dispositions now link ADR-003 to ADR-006. Approved by the product owner. No other section changed.
- **v0.1, 2026-11-27 (revision 5):** Updated AWS Support plan names to the current plans (Business Support+, Enterprise Support, Unified Operations; classic plans until 2027-01-01) in §6 branches, §8 F-15, §12 and §14, and replaced the unverified "Health Dashboard export" fallback with public Health events and a customer-supplied incident list. Answers QUESTIONS.md Q-10 and Q-17. Approved by the product owner (delegated to Claude, 2026-11-27). No other change.
