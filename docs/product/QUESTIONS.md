# QUESTIONS: Recoup v1

Status: Decided for Gate G1 · Date: 2026-11-27 · Requirements: [REQUIREMENTS.md](REQUIREMENTS.md)

On 2026-11-27 the product owner delegated every answer to Claude ("answer them yourself … based on the product capability and the intention it's built for"). Each answer below says who decided it and what it rests on. AWS facts are first-party and dated; anything not confirmed in AWS docs is marked **unverified**.

Statuses:
- **Decided:** no further input needed.
- **Decided, verify:** the decision stands, but a named fact must be confirmed; if it comes out differently, the decision is revisited.
- **Accepted, validate:** a fact about customers that only interviews can answer. We build on the assumption, and it stays a hypothesis until interview evidence exists. Nobody can decide it on the customer's behalf.
- **Open, assumption:** raised after G1 (Stage 2a). Design builds on the assumption A-xx until the named person answers.

## Summary

| Q | Topic | Status | Answer (short) | Owning doc |
|---|---|---|---|---|
| Q-01 | Who files claims | Decided | Customer files; Recoup prepares | [ADR-007](../adr/ADR-007-customer-files-claims-in-v1.md) |
| Q-02 | Pricing | Decided | Contingency on posted credits only, opening 20%; check free | [ADR-013](../adr/ADR-013-contingency-on-posted-credits.md) |
| Q-03 | First SLAs | Decided, verify | API Gateway, S3, DynamoDB first; confirm against interview spend | This doc |
| Q-04 | Share on a Health API plan | Accepted, validate | Majority | Interviews |
| Q-05 | Resellers and MSPs | Decided | Not supported in v1; detected at connection | This doc |
| Q-06 | Next Signal use; demo | Accepted, validate | Unknown; demo before G1 | Interviews |
| Q-07 | Read-only role acceptance; V-04 | Accepted, validate | Yes if short; V-04 accepted | Interviews |
| Q-08 | Log retention | Accepted, validate | Often short; partial evidence | Interviews |
| Q-09 | Gate signers | Decided | Product owner signs G1–G5 | This doc |
| Q-10 | Support plan names | Decided | PRD revision 5 | [PRD §12](../sources/PRD-v0.1.md#12-constraints-and-non-functional-needs-become-nfr-xx) |
| Q-11 | Member-account CUR 2.0 | Decided, verify | Each member account exports its own data | This doc |
| Q-12 | Credit-line matching | Decided, verify | Exact match, or P-03 confirms; card refunds kept apart | R-42 – R-44, R-54 |
| Q-13 | Evidence intake | Decided | Upload; no log permission | [ADR-010](../adr/ADR-010-customer-evidence-by-upload.md) |
| Q-14 | Deadline reading | Decided, verify | Earlier reading | R-30 |
| Q-15 | Public incident history | Decided | EventBridge capture from Recoup's account, starting now | This doc |
| Q-16 | Health 90-day retention | Decided | Store every event read; late connections fall back | R-12 |
| Q-17 | Fallback below a Health API plan | Decided | Public events plus customer-entered incidents | R-14, PRD revision 5 |
| Q-18 | Users, roles, sign-in | Decided | Named users with MFA; approver / contributor / viewer | R-38, R-56 |
| Q-19 | Accounts per tenant | Decided | Several, each with its own role | This doc |
| Q-20 | AISPL and non-USD accounts | Decided, verify | Out of v1 until verified | Out of scope |
| Q-21 | Model in M1 | Decided | No model in v1 | [ADR-011](../adr/ADR-011-no-model-in-v1.md) |
| Q-22 | Warning lead time | Decided | 14 and 3 days | R-45 |
| Q-23 | Warning channel | Decided | Email via outbox | R-45 |
| Q-24 | "One ready-to-file claim" | Decided | One free packet per report; all packets in the pilot | R-55 |
| Q-25 | M-02 threshold | Decided | Set after 30 decided claims | This doc |
| Q-26 | V-02 baseline | Decided | Grant rate ≥70% alone | This doc |
| Q-27 | Retention and deletion | Decided | Schedule below | R-53 |
| Q-28 | Recovery targets | Decided | RPO ≤5 min, RTO ≤4 h from M2 | NFR-12 |
| Q-29 | Availability, accessibility, languages | Decided | No customer SLA; WCAG 2.2 AA; English | This doc |
| Q-30 | Hosting region | Decided | us-west-2 | [ADR-012](../adr/ADR-012-hosting-region-us-west-2.md) |
| Q-31 | J-01 contact data | Decided | Anonymous; external booking link; no emailed results (revised 2026-11-27) | R-33, R-35 |
| Q-32 | P-06 operator, J-09 | Decided | Accepted; product owner acts as P-06 | REQUIREMENTS.md |
| Q-33 | V-03 | Decided | Accepted | REQUIREMENTS.md |
| Q-34 | KPI-11 | Decided | Accepted, ≥80% | REQUIREMENTS.md |
| Q-35 | Kill thresholds | Decided | KPI-02 <30%; KPI-10 median <$10k | KPI table |
| Q-36 | Who creates a tenant and manages members | Decided | First user creates it and is approver; approvers manage members; always ≥1 approver | [ADR-017](../adr/ADR-017-auth-cognito-oidc-bff.md) |
| Q-37 | API Gateway access-log fields for an internal error | Decided, verify | Only `DEFAULT_5XX` with no Lambda 5xx counts; named customer-side types never count | [uploads](../contracts/uploads/README.md#evidence-rules) |
| Q-38 | Approval expiry length | Decided | Valid until the claim's later deadline; content changes invalidate sooner; case-opened date recorded | R-36, KPI-11 |
| Q-39 | Rounding where the SLA is silent | Decided, verify | Full precision; final credit rounded to the cent, half-even | [SLA contract format](../contracts/sla-contract/README.md) |

## Still open

**Validated through the free check, not interviews** ([ADR-014](../adr/ADR-014-build-before-interviews.md)): Q-04, Q-07 and Q-08, plus the spend check in Q-03, are recorded at connection or in the report. Q-06 waits for the Next Signal demo. In the conversation offered to each connected prospect, cover:
1. Their support plan per production account (Q-04).
2. Who sells them AWS: AWS Inc., AWS India, or a reseller (Q-05, Q-20).
3. How their accounts are organised (Q-11, Q-19).
4. The CUR rows of any SLA credit they've received, anonymised (Q-12).
5. Their reaction to a 20% contingency (Q-02).

**Raised and decided in Stage 2a (2026-11-27, delegated by the product owner):** Q-36 – Q-39. Q-37 and Q-39 still need confirming: add Q-37 to the Q-14 Account and billing case; check Q-39 against the first grants.

**AWS verification tasks** (decisions stand until these say otherwise):

| Task | For | How |
|---|---|---|
| Confirm the deadline reading | Q-14 | Ask AWS in a free Account and billing case from Recoup's account |
| Confirm where an SLA credit posts under consolidated billing, and its description and product code | Q-11, Q-12 | First real credit, or an interviewee's past CUR rows |
| Confirm that a member account can export (no SCP block) on a two-account test organization | Q-11 | M0 test setup |
| Confirm whether SLAs and Support Center claims apply to AISPL accounts | Q-20 | AWS India terms; ask an AISPL interviewee |
| Transcribe and check the S3 and DynamoDB SLA snapshots | Q-03 | ADR-005 snapshot process |

---

## Answers

### Q-01 Who submits the claim? — Decided
The customer files in AWS Support Center; Recoup prepares the packet and holds no filing permission. **Decided by:** [ADR-007](../adr/ADR-007-customer-files-claims-in-v1.md), 2026-11-27.

### Q-02 Pricing — Decided
Contingency only. The free check is free, and the pilot is priced as a share of posted (verified) credits, opening at 20%, tested in interviews before the first agreement. **Why:** value is lumpy, and only posted money is verified. **Decided by:** Claude under delegation, [ADR-013](../adr/ADR-013-contingency-on-posted-credits.md). Confidence: high on the model, low on the percentage.

### Q-03 Which SLAs first? — Decided, verify
- **Answer:** API Gateway (its contract is already transcribed), then S3 and DynamoDB, for 3 contracts at M1 exit. Add up to two more (candidates: Lambda, RDS Multi-AZ) if interview spend puts them ahead.
- **Why these:** the product's edge is proof from the customer's own request data (V-02, ADR-010). So the first contracts should (a) require a claim, (b) measure availability from request-level errors the customer can export, and (c) cover services with large spend.
- **Why not EC2 first:** EC2's region-level SLA is hard to prove from customer logs, and AWS's instance-level credit is applied without a claim for qualifying hours (it "applies automatically", [compute SLA, prior version](https://aws.amazon.com/compute/sla/historical)), so it is less of a recovery opportunity.
- **Verify:** the S3 and DynamoDB measurement definitions when their snapshots are transcribed (ADR-005), and that interview spend doesn't rank other services far ahead.

### Q-04 Share on a plan with Health API access — Accepted, validate
Assume a majority. Business Support+ is priced per account from a low monthly minimum, so plan level may not track company size. Ask about each production account.

### Q-05 Resellers and MSPs — Decided
- **Answer:** not supported in v1.
- **Known:** customers who buy AWS Support through a reselling partner raise billing issues with that partner (ADR-007, AWS case-management docs, read 2026-11-27).
- **How it's detected:** at connection, the customer answers "Who sells you AWS?", and Recoup checks the seller and payer fields in CUR 2.0. Partner-sold accounts get a clear "not supported yet".
- **Why:** filing would go through the partner, and entitlement is unverified. M-03 waits for MSP interviews.

### Q-06 Next Signal — Accepted, validate
Unknown. The product owner books a Next Signal demo before G1 (PRD §14). It's a G1 item.

### Q-07 Read-only role acceptance (+ V-04) — Accepted, validate
Assume yes, because the permission list is short and the customer deploys the role (ADR-003; ADR-010 keeps logs out of it). V-04 is accepted as a hypothesis, with proof KPI-03 ≥30% and no request rejected for scope.

### Q-08 Log retention — Accepted, validate
Assume often too short. Evidence can be partial; eligibility is *unproven* without logs (R-20).

### Q-09 Who signs G1–G5 — Decided
- **Answer:** the product owner signs every gate, as product owner and as tech lead. Claude drafts the checks and doesn't sign.
- **G1 condition:** the framing confirmation rests on interview evidence. STATUS.md records which interview notes support each confirmed persona, journey and value hypothesis.

### Q-10 Support plan names — Decided
- **Known (AWS, read 2026-11-27):**
  - Support now has three paid plans: Business Support+, Enterprise Support and Unified Operations ([What's New](https://aws.amazon.com/about-aws/whats-new/2025/12/aws-support-transformation-ai-powered-operations)).
  - Business (classic) and Enterprise On-Ramp end on 2027-01-01 ([plans](https://docs.aws.amazon.com/awssupport/latest/user/aws-support-plans.html)).
  - The Health API needs one of the new plans, or a classic plan on accounts not yet moved ([Health API](https://docs.aws.amazon.com/health/latest/APIReference/Welcome.html)).
- **Answer:** PRD revision 5 updates §6, §8 F-15, §12 and §14 in both copies. NFR-10 follows it.

### Q-11 Member-account CUR 2.0 exports — Decided, verify
- **Known (AWS, read 2026-11-27, [CUR 2.0 table](https://docs.aws.amazon.com/cur/latest/userguide/table-dictionary-cur2.html)):**
  - A member account's export contains only that account's data, and covers only its time in the current organization; a management account's export covers all accounts.
  - Since 2026-04-14, exports can be delivered to another account's bucket if that bucket's policy allows it ([What's New](https://aws.amazon.com/about-aws/whats-new/2026/03/aws-data-exports-cross-account-delivery-cost)).
  - SLA terms say credits can't be moved to another account ([Amazon Quick SLA](https://aws.amazon.com/quick/sla/), as an example of the standard clause).
- **Answer:** each affected member account is connected with its own role and its own export. That keeps access to that account's data only, which matches where its credits apply. A management-account export is accepted only when the customer chooses it and P-04 accepts that it shows every account's costs. Cross-account delivery to a Recoup bucket isn't used in v1: it would make Recoup hold the full export, against ADR-009 §1.
- **Verify:** that no SCP or billing setting blocks member exports, on the M0 test organization.

### Q-12 Claim-to-Credit-line matching — Decided, verify
- **Known (AWS, read 2026-11-27):**
  - CUR has a `Credit` line type, with details in the description, and AWS may update a finalized month to add a credit ([line items](https://docs.aws.amazon.com/cur/latest/userguide/Lineitem-columns.html)).
  - A confirmed credit is issued within one billing cycle after the month of the request ([Aurora SLA](https://aws.amazon.com/aurora/sla/)).
  - Some SLAs let AWS issue the credit to the card used to pay instead ([S3 SLA](https://aws.amazon.com/s3/sla/)).
- **Answer:**
  1. **Verified match:** a Credit line in the claim's account and service, in the billing period of the grant or the one after, for exactly the granted amount. The claim becomes *posted (verified)* (R-42).
  2. **Possible match** (amount differs, several candidates, no product code): P-03 confirms or rejects it (US-18, R-43), recorded with who and when. Never match on amount alone.
  3. **No line after the window:** the claim stays *granted* and is flagged *credit not seen*. If the customer says it was refunded to a card, it is recorded as *refunded outside the bill (customer-entered)*. That is never *posted (verified)* and never in the posted total (R-54).
- **Verify:** description text, product code and posting account, from the first real credit or an interviewee's past rows.

### Q-13 How evidence reaches Recoup — Decided
By upload, for one incident window at a time. The role gets no log or metric permission. **Decided by:** Claude under delegation, [ADR-010](../adr/ADR-010-customer-evidence-by-upload.md).

### Q-14 Deadline reading — Decided, verify
- **Known:** the SLAs read "by the end of the second billing cycle after which the incident occurred" ([AWS Budgets SLA](https://aws.amazon.com/aws-cost-management/aws-budgets/sla)). For a January incident, that could mean the end of February or the end of March.
- **Answer:** every deadline shown and every warning uses the earlier date. A claim between the two dates shows "may have expired — check with AWS".
- **Why:** filing early never hurts a claim, and filing late loses it.
- **Verify:** ask AWS, record the answer per contract, and switch R-30 to the confirmed reading.

### Q-15 Public incident history for J-01 — Decided
- **Known (AWS, read 2026-11-27):**
  - Health events carry an `eventScopeCode` of `PUBLIC` or `ACCOUNT_SPECIFIC` ([Event](https://docs.aws.amazon.com/health/latest/APIReference/API_Event.html)).
  - An EventBridge rule on `aws.health` delivers both kinds. AWS recommends a backup-region rule and de-duplicating on `eventArn` plus `communicationId` ([public events](https://docs.aws.amazon.com/health/latest/ug/about-public-events.html)).
- **Answer:**
  - Recoup's own AWS account captures public events with EventBridge rules in every region the check supports, plus backup rules, forwarded to us-west-2 (ADR-012) and de-duplicated as AWS advises.
  - Incidents from before capture starts are entered by P-06, each with its Service health source and capture date. No scraping.
  - Recoup's account goes on Business Support+ so it can also use the Health API.
- **Timing:** start capture as the first M0 spec. History not captured can never be shown.

### Q-16 Health 90-day retention — Decided
Recoup stores every Health event it reads, with ARN and read time (R-12). For connections made late in a window, events AWS has already dropped come from Recoup's own capture (Q-15) or from the customer (R-14), and stay *unproven* without logs.

### Q-17 Fallback below a Health API plan — Decided
Public events (Q-15), plus incidents the customer enters (service, region, start, end, source), labelled *customer-supplied* (R-14). No "Health Dashboard export" is relied on, because no such export is documented. PRD revision 5.

### Q-18 Users, roles and sign-in — Decided
- **Roles:** each tenant has named users, each signing in individually with MFA. *Approver* (P-01) approves, declines and revokes; *contributor* (P-02, P-03) uploads evidence, enters case IDs and outcomes, and confirms matches; *viewer* (P-04) reads.
- **Attribution and audit:** every action is attributed to a user and audited (R-56).
- **Why MFA:** the product holds confidential billing data and binds approvals to a person.
- **Sign-in provider:** chosen in Stage 2 TECH_STACK under this delegation, with an ADR.

### Q-19 Accounts per tenant — Decided
A tenant can connect several AWS accounts, each with its own role and ExternalId (ADR-003 §1). Claims are per affected account, because the case is filed from that account (ADR-007 §1) and credits can't move between accounts (Q-11). Reports show each account and a tenant total per stage (R-03).

### Q-20 AISPL and non-USD accounts — Decided, verify
- **Answer:** v1 supports accounts sold by Amazon Web Services, Inc. with USD amounts. Accounts sold by Amazon Web Services India Private Limited, a local reseller named in CUR's seller field ([line items](https://docs.aws.amazon.com/cur/latest/userguide/table-dictionary-cur2-line-item.html)), are told "not supported yet".
- **Why:** whether the same SLAs, claim path and currency apply is unverified, and a wrong claim is worse than none.
- **Revisit:** at once if two or more of the first five interviewees are AISPL customers. Given where our network is, that's likely, so this verification comes first.

### Q-21 Agent steps and model provider — Decided
No model in v1. Templates and human confirmation cover the three PRD §9 steps. No model provider is chosen. **Decided by:** Claude under delegation, [ADR-011](../adr/ADR-011-no-model-in-v1.md).

### Q-22 Warning lead time — Decided
Two warnings, 14 days and 3 days before the deadline (the earlier date, Q-14). **Why:** 14 days leaves time to pull logs; 3 days is the last useful nudge.

### Q-23 Warning channel — Decided
Email to the claim owner, sent through the outbox (ADR-006 §3). Slack and Jira stay F-14, later.

### Q-24 "One ready-to-file claim" — Decided
- **Answer:** the free report lists every claimable credit with its estimate, deadline and stage, and includes one complete packet: the ready claim with the largest estimate. Packets for every ready claim come with the pilot agreement (R-55).
- **I'm reversing my Stage 1 recommendation** of a packet for every claim. With the customer filing (ADR-007) and pricing on posted credits (ADR-013), the packets and tracking are what the pilot sells. Giving all of them away removes the reason to sign, while one free packet proves the quality.
- **Nothing is hidden:** every claim and its deadline is shown, so the customer can still file the rest alone.

### Q-25 M-02 threshold — Decided
No threshold in v1. R-40 keeps the predicted result next to each outcome. The threshold is set once 30 claims have outcomes.

### Q-26 V-02 baseline — Decided
V-02 is proven by a pilot grant rate ≥70% with every denial reason recorded. The comparison with past experience is used only where a partner has past claims; if V-01 holds, most won't.

### Q-27 Retention and deletion — Decided
- **Raw uploads:** deleted 30 days after the claim closes. Redacted excerpts and hashes are kept.
- **Raw billing rows:** kept only while inside the open claim window or tied to an open claim.
- **Audit and evidence-trail records:** kept for the life of the tenant plus one year.
- **On disconnect:** reads stop at once; raw data is deleted within 30 days unless an open claim needs it and the customer agrees in writing.
- SECURITY.md adds the DPDP Act and GDPR basis in Stage 2. Legal review is advised before the first partner signs.

### Q-28 Recovery targets — Decided
From M2: RPO ≤5 minutes and RTO ≤4 hours, in line with RDS point-in-time recovery (ADR-008 §3). M1 has the same RPO and a best-effort RTO.

### Q-29 Availability, accessibility, languages — Decided
- **Answer:** no availability commitment to customers in v1 (journey SLOs are set internally in OBSERVABILITY.md). Customer screens meet WCAG 2.2 AA. English only. Amounts in USD.
- **Why not NFRs yet:** these aren't in the PRD, so they apply as Stage 2 design inputs and become NFRs at the next PRD revision.

### Q-30 Hosting region — Decided
us-west-2. **Decided by:** Claude under delegation, [ADR-012](../adr/ADR-012-hosting-region-us-west-2.md).

### Q-31 J-01 contact data — Decided
The no-access check needs no sign-in and no contact details. Booking uses an external scheduling link. Recoup stores an anonymous session ID and funnel events (KPI-03). **Why:** less personal data to protect, and a lower barrier for the discovery tool.
- **Revised 2026-11-27 (Stage 2a, delegated):** dropped "an email only if the prospect asks for results to be sent". No R-xx asked for it, and it would be the only personal data the anonymous check holds. Each result has its own URL (`GET /estimates/{id}`), which a prospect can bookmark or forward to a colleague.

### Q-32 P-06 operator, J-09, US-16 — Decided
Accepted. The product owner acts as P-06 in v1. P-06 sees the catalog and public incidents, never tenant data, and every P-06 action is audited.

### Q-33 V-03 — Decided
Accepted as a hypothesis, with proof KPI-08 in the pilot.

### Q-34 KPI-11 — Decided
Accepted, target ≥80% of ready packets filed before their deadline. Below that, revisit F-15 (ADR-007 §6).

### Q-35 Kill thresholds — Decided
Kill option B if fewer than 30% of interviewees had a claimable incident in 12 months (KPI-02), or if median expected annual credits per partner come in under $10k (KPI-10). **Why:** 30% is "well below" the 50% confirm line; $10k is the low end of the board's range, so we don't kill on a borderline result.

### Q-36 Who creates a tenant and manages its members? — Decided
- **Gap:** R-56 and Q-18 define named users with one of three roles, but no requirement says who creates a tenant, who invites users, or who changes roles.
- **Answer:**
  - **Self-serve.** The first person to sign up creates the tenant and becomes its approver.
  - **Approvers manage members.** They invite by email (invitations expire after 7 days), change roles and remove members. A removal or role change revokes that member's sessions (ADR-017 §4).
  - **There is always at least one approver.** Removing or demoting the last one is refused.
  - **Every change is audited** (R-56). Recoup operators (P-06) can't add or change tenant members (Q-32).
- **Why:** the free check is a self-serve funnel (J-01 → J-02, KPI-03). A sales-led setup by Recoup would add a step between the check and a connection, and would give P-06 a reason to touch tenant data. A single approver can lock themselves out, so the last-approver rule keeps every tenant able to approve claims.
- **Decided by:** Claude under delegation, 2026-11-27. Supersedes A-36.

### Q-37 Which API Gateway access-log fields mark an internal error? — Decided, verify
- **Gap:** the API Gateway SLA counts only requests that fail with an API Gateway internal service error. Which access-log fields show that is interpretation (ADR-005 §3).
- **Known (AWS, read 2026-11-27):**
  - Several customer-side causes also return 5xx: an invalid API configuration (`API_CONFIGURATION_ERROR`, 500), a custom or Cognito authorizer that can't be reached or fails (`AUTHORIZER_CONFIGURATION_ERROR`, `AUTHORIZER_FAILURE`, 500), and integration failures or timeouts (`INTEGRATION_FAILURE`, `INTEGRATION_TIMEOUT`, 504).
  - `DEFAULT_5XX` is the fallback for a 5xx with no more specific type.
  - Changing `DEFAULT_5XX`'s status code changes every other 5xx response too, so the HTTP status alone can't be trusted ([gateway response types](https://docs.aws.amazon.com/apigateway/latest/developerguide/supported-gateway-response-types.html)).
  - `$context.error.responseType` logs the gateway response type. For Lambda proxy integrations, `$context.integrationStatus` is the status code from AWS Lambda itself, not from the function code ([access-log variables](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-variables-for-access-logging.html)).
- **Answer:** an Error is a request whose `errorResponseType` is `DEFAULT_5XX` and whose `integrationStatus` is empty or not 5xx.
  - Every named type above, and every throttling, quota or WAF type, never counts.
  - A 5xx row without `errorResponseType` makes the claim *unproven*.
  - This replaces A-37, which would have counted authorizer and configuration errors as AWS's.
- **Why:** Recoup's edge is claims that get granted (V-02, KPI-06 ≥70%). Overstating errors loses grants and the customer's trust. Understating only lowers an estimate.
- **Verify:** ask AWS in the Q-14 Account and billing case whether an API Gateway internal error is always logged as `DEFAULT_5XX`. If AWS names another type, add it to the rule by a dated revision.
- **Decided by:** Claude under delegation, 2026-11-27. Confidence: high on what to exclude; medium that `DEFAULT_5XX` is the only internal type.

### Q-38 How long is an approval valid? — Decided
- **Gap:** R-36 binds an expiry to every approval but gives no length. The hackathon used 24 hours.
- **Answer:**
  - **An approval stays valid until the end (UTC) of the claim's later deadline**, the last day a filing could still count (Q-14). Any change to content, amount, stage version or policy revision invalidates it sooner (R-36).
  - **With the case ID, the customer also enters the date the case was opened in Support Center** (`case_opened_on`). It must be on or before the later deadline. A case opened after the earlier deadline is accepted, flagged *filed after the earlier deadline*, and counts against KPI-11.
  - If an approval expires with no case recorded, the claim goes back through eligibility and shows as expired.
- **Why:**
  - R-36's binding already stops a stale approval from covering changed content. A fixed short window would only force re-approval of an unchanged claim while the approver (P-01) waits for the SRE (P-02) to file, which adds to KPI-08 with no safety gain.
  - The deadline is the only real time limit.
  - The case-opened date is what KPI-11 (filed before deadline) needs; the date the ID is typed in isn't.
  - This replaces A-38 (7 days).
- **Decided by:** Claude under delegation, 2026-11-27.

### Q-39 How is a credit rounded when the SLA says nothing? — Decided, verify
- **Gap:** R-23 says "the contract's rounding", but the API Gateway SLA states no rounding rule.
- **Answer:** compute in full Decimal precision and round only the final credit to the cent, half-even. The trace shows both values. Contract files mark this `basis: recoup_default`, and a contract that states its own rule uses that rule instead.
- **Why:** rounding once, at the end, keeps the error under half a cent per claim, well inside KPI-07's ±10%. Half-even avoids a systematic upward bias across many claims.
- **Verify:** compare with the first granted amounts (KPI-07 variance). A consistent one-cent gap means AWS rounds another way, and the default changes by a dated revision.
- **Decided by:** Claude under delegation, 2026-11-27.

## Resolved

All questions except Q-04, Q-06, Q-07 and Q-08 are decided as above (2026-11-27). Those four are accepted assumptions awaiting interview evidence. Q-36 – Q-39 were raised and decided in Stage 2a (delegated); Q-37 and Q-39 still need confirming.
