# REQUIREMENTS: Recoup v1

Status: Draft for Gate G1 · Date: 2026-11-27 · Source: [PRD v0.1](../sources/PRD-v0.1.md) (revision 4)
Questions and assumptions: [QUESTIONS.md](QUESTIONS.md). Decisions: [ADR-001](../adr/ADR-001-free-check-first.md) to [ADR-013](../adr/ADR-013-contingency-on-posted-credits.md). Questions decided 2026-11-27 under delegation from the product owner.

> **Everything about customers here is a hypothesis.** No prospective customer has been interviewed (KPI-01: 0 of 10). Personas, journeys, stories, KPIs and value claims stay hypotheses until interview evidence passes G1. Requirements built on them are what we would build *if* the hypotheses hold.

**How to read this doc.** The PRD owns the personas, journeys, stories, agent steps and value hypotheses; this doc links to them, records whether each is confirmed, and adds what was missing. This doc owns the R-xx, NFR-xx and KPI-xx. The ADRs own the decisions; requirements link to them instead of restating them. Items added in Stage 1 (P-06, J-07 – J-09, US-13 – US-18, V-03, V-04, KPI-11) were accepted on 2026-11-27 (delegated); like the PRD's own items, they stay hypotheses until interviews.

---

## Product framing

### What we know, what we believe, what we must validate

| Kind | Items | Basis |
|---|---|---|
| **Know** (repo or first-party AWS docs, dated) | The hackathon build shows no real dollar and has no customer-log reader ([DISCOVERY.md](../discovery/DISCOVERY.md)). AWS SLAs are claimed by a Support Center case ([ADR-007](../adr/ADR-007-customer-files-claims-in-v1.md)). CUR 2.0 has a Credit line type and AWS may update a finalized month ([ADR-009](../adr/ADR-009-billing-data-cur2-with-cost-explorer-bootstrap.md)). The AWS Health API needs a paid support plan and keeps events about 90 days; the plan names changed (Q-10, Q-16). | Code at `d009df7`; AWS docs read 2026-11-27 |
| **Believe** (PRD hypotheses) | Personas P-01 to P-05, journeys J-01 to J-06, stories US-01 to US-12, value and moat hypotheses V-01, V-02, M-01 to M-03, KPI targets | PRD §5–§11, strategy review |
| **Must validate** | V-01 first (KPI-02), then KPI-10 materiality, Q-07 access acceptance, Q-08 log retention; Next Signal demo (PRD §14) | 10 interviews (KPI-01) |

### Personas ([PRD §5](../sources/PRD-v0.1.md#5-personas-hypotheses))

| ID | Status | Notes |
|---|---|---|
| P-01 FinOps lead (buyer) | Hypothesis, unconfirmed | Approver for claims (US-07) and two agent steps (PRD §9). |
| P-02 SRE / platform incident lead | Hypothesis, unconfirmed | Hands Recoup log extracts by upload: J-08 / US-13 ([ADR-010](../adr/ADR-010-customer-evidence-by-upload.md)). |
| P-03 Cloud finance analyst | Hypothesis, unconfirmed | Confirms ambiguous credit-line matches (US-18, Q-12). |
| P-04 Security reviewer | Hypothesis, unconfirmed | V-04 tests their acceptance (Q-07). |
| P-05 MSP account manager | Hypothesis, unconfirmed; **no v1 journey or requirement** | Kept only for M-03. v1 doesn't support resellers (A-05). |
| **P-06 Recoup operator** (internal) | Accepted (Q-32); the product owner acts as P-06 in v1 | Someone at Recoup has to review SLA snapshots and recheck diffs ([ADR-005](../adr/ADR-005-sla-catalog-pinned-snapshots.md) §3, §5) and curate public incidents (A-15). No PRD persona does this. |

### User journeys ([PRD §6](../sources/PRD-v0.1.md#6-user-journeys))

| ID | Release | Status | Gap or challenge |
|---|---|---|---|
| J-01 No-access credit check | M1 | Hypothesis | Public incidents come from Recoup's own Health capture (Q-15). The check is anonymous; booking uses an external link (Q-31). |
| J-02 Connect read-only | M1 | Hypothesis | The connection test must also report the support-plan branch (Health API unavailable). |
| J-03 Account-specific check | M1 | Hypothesis | Logs arrive by upload ([ADR-010](../adr/ADR-010-customer-evidence-by-upload.md), J-08). Health keeps events ~90 days, so Recoup stores every event it reads (Q-16). One free packet per report (Q-24, R-55). |
| J-04 Approve and file | M2 | Hypothesis | Only the approver role approves (Q-18, R-38, R-56). |
| J-05 Track and reconcile | M2 | Hypothesis | Matching rule set in Q-12; card refunds kept apart (R-54). |
| J-06 Deadline radar | M2 (Should) | Hypothesis | Email warnings at 14 and 3 days, using the earlier deadline reading (Q-14, Q-22, Q-23). |
| **J-07 Disconnect and delete** | M1 | Accepted (Q-27), hypothesis | Trigger: the customer deletes the stack or asks to leave. Steps: Recoup detects the failed assume-role ([ADR-003](../adr/ADR-003-customer-read-only-role.md) §7) → stops reads → deletes or keeps data per the retention rule. Outcome: no further access, data handled as promised. |
| **J-08 Supply evidence** | M1 | Accepted (Q-13), hypothesis | Trigger: a matched incident needs request logs. Steps: P-02 gets a request for the incident window → supplies log extracts (and optionally a postmortem) → Recoup computes availability and redacts. Outcome: eligibility proven or stays *unproven*. |
| **J-09 SLA terms change review** | M1 | Accepted (Q-32), hypothesis | Trigger: the scheduled recheck finds a difference ([ADR-005](../adr/ADR-005-sla-catalog-pinned-snapshots.md) §5). Steps: P-06 reviews the diff → publishes a new version or dismisses. Outcome: the catalog is current; old claims stay reproducible. |

PRD §6 branches are carried into requirements: below-paid-plan fallback → R-14; logs unavailable → R-20; under the minimum credit → R-21; single-AZ against a region-level SLA → R-22.

### User stories ([PRD §7](../sources/PRD-v0.1.md#7-user-stories))

US-01 to US-12 are taken as written (all hypotheses, unconfirmed). Notes: US-05's "$1 floor" is the contract's own minimum credit ([ADR-005](../adr/ADR-005-sla-catalog-pinned-snapshots.md) §6), so R-21 states it per contract; US-11's N is Q-22.

Stories added in Stage 1 (accepted 2026-11-27, still hypotheses):

| ID | Story | Journey | Release | Acceptance (summary) | Q |
|---|---|---|---|---|---|
| US-13 | As P-02, I want to hand over request logs for just the incident window, so eligibility can be proven without giving Recoup standing access to our logs | J-08 | M1 | Accepted formats listed per contract; availability computed from them; sensitive data redacted before anything is stored in a packet | Q-13 |
| US-14 | As P-01 on a plan without the Health API, I want to tell Recoup which incidents hit us, so I still get a check | J-03 branch | M1 | Incidents entered with service, region, start and end; labelled *customer-supplied* | Q-17 |
| US-15 | As P-04, I want disconnecting to stop all access and delete our data on a stated schedule, so access is truly revocable | J-07 | M1 | Failed assume-role marks the account disconnected; deletion follows the retention rule | Q-27 |
| US-16 | As P-06, I want to review each detected change in published SLA terms before it reaches any calculation, so eligibility follows the terms in force | J-09 | M1 | A new version is published only after review; nothing changes in place | Q-32 |
| US-17 | As P-01, I want to try the no-access check without leaving contact details, and book an interview only if I choose to | J-01 | M1 | Check works anonymously; booking is an explicit action | Q-31 |
| US-18 | As P-03, I want to confirm or reject a possible credit-line match myself, so a credit is marked posted only when I agree it's ours | J-05 | M2 | Ambiguous matches wait for P-03; decision recorded with who and when | Q-12 |

### Agent steps and target maturity ([PRD §9](../sources/PRD-v0.1.md#9-agent-steps-and-maturity))

All three agent steps have a target maturity (L3) and a named approver, as G1 requires. Everything else is deterministic code. No maturity is claimed until tests show it.

| Journey step | Target | Approver | Requirement | Note |
|---|---|---|---|---|
| J-03 incident windows from postmortems or free text | L3 | P-02 | R-49 | Deferred past M2 ([ADR-011](../adr/ADR-011-no-model-in-v1.md)). Health event times plus windows P-02 enters cover v1. |
| J-03 claim narrative | L3 | P-01 | R-50 | Deferred past M2 (ADR-011). A per-contract template meets R-28. |
| J-05 denial reason capture | L3 | P-01 | R-51 | Deferred past M2 (ADR-011). A fixed list plus pasted case text covers v1. |

No model and no model provider in v1 ([ADR-011](../adr/ADR-011-no-model-in-v1.md)). The L3 targets stand for when a model is added.

### Value and defensibility ([PRD §10](../sources/PRD-v0.1.md#10-value-and-defensibility-hypotheses-in-the-order-theyd-be-earned))

| ID | Status | Challenge |
|---|---|---|
| V-01 | Hypothesis, unproven | The kill test for the whole product. Nothing in M1 build-out should start before KPI-02 is read (PRD §14). |
| V-02 | Hypothesis, unproven | "Above partners' past experience" may have no baseline: if V-01 is true, most partners never filed (Q-26). |
| M-01 | Hypothesis, unproven | Depends on the Q-12 matching rule holding against a real SLA Credit line, and on contingency pricing ([ADR-013](../adr/ADR-013-contingency-on-posted-credits.md)). |
| M-02 | Hypothesis, unproven | Not earnable at pilot scale (tens of claims). Threshold deferred (Q-25). |
| M-03 | Hypothesis, unproven | Blocked by reseller entitlement (Q-05). No v1 work. |
| **V-03** | Accepted (Q-33), hypothesis | "A ready-to-file packet cuts claim effort enough that P-02 spends under 30 minutes per claim." Proof: KPI-08 in the pilot. PRD has the KPI and the persona goal but no hypothesis. |
| **V-04** | Accepted (Q-07), hypothesis | "Security reviewers approve a short, read-only, customer-deployed role from an early-stage vendor." Proof: KPI-03 ≥30% and no access request rejected for scope. |

Competitive gaps (reconciliation, contract-version evidence) are unverified until a Next Signal demo (PRD §10, §14).

---

## Features (F-xx)

Feature IDs are the PRD's own (PRD §8). Each groups the R-xx below.

| Feature | Release | Priority | Requirements |
|---|---|---|---|
| F-00 Honest state and money model | M0 | Must | R-01 – R-05 |
| F-01 Read-only account connection | M1 | Must | R-06 – R-11 |
| F-02 Incident detection and account matching | M1 | Must | R-12 – R-14 |
| F-03 SLA contract catalog | M1 | Must | R-15 – R-17 |
| F-04 Eligibility and credit calculation | M1 | Must | R-18 – R-24 |
| F-05 Billed charges from billing data | M1 | Must | R-25 – R-27 |
| F-06 Claim packet with deadline | M1 | Must | R-28 – R-32, R-55 |
| F-07 No-access estimator | M1 | Must | R-33 – R-35 |
| F-08 Bound approval | M2 | Must | R-36 – R-38, R-56 |
| F-09 Case tracking | M2 | Must | R-39 – R-41 |
| F-10 Credit reconciliation | M2 | Must | R-42 – R-44, R-54 |
| F-11 Deadline radar | M2 | Should | R-45 – R-46 |
| F-12 Per-claim evidence trail | M2 | Should | R-47 |
| F-13 SLA credit ledger | M2 | Must | R-48 |
| Agent steps (PRD §9) | After M2 (ADR-011) | Could | R-49 – R-51 |
| Evidence supply and data lifecycle (J-07, J-08) | M1 | Must / Should | R-52 – R-53 |
| F-14, F-15, F-16 | Later / Won't | — | Out of scope (below) |

## Functional requirements (R-xx)

"Story" lists the user story and journey each requirement serves. *Customer-entered* means a value typed by a customer user, labelled as such ([ADR-004](../adr/ADR-004-claim-state-from-system-of-record.md)).

### F-00 Honest state and money model (M0)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-01 | A claim moves through the stages in [ADR-004](../adr/ADR-004-claim-state-from-system-of-record.md) only on that stage's evidence, and every view shows only its last confirmed stage. | §8 F-00, §12 | US-09 / J-05 | Must | **Given** an approved claim with no case ID, **when** any screen or API shows it, **then** its stage is *approved* and no submitted, granted or posted value appears. | ADR-004 |
| R-02 | Every dollar shown or exported carries its stage (estimate, approved, submitted, granted, posted) and its source (Cost Explorer, CUR 2.0, customer-entered, calculation). | §12, §8 F-00 | US-05 / J-03 | Must | **Given** any amount in a screen, export or API response, **when** it is rendered, **then** its stage label and source are present; **and** an amount without both fails a contract test. | ADR-004, ADR-009 |
| R-03 | Totals sum amounts of one stage only, and SLA credits are never summed with savings (v1 has no savings type). | §12, §4 | US-09 / J-05 | Must | **Given** claims at different stages, **when** a total is shown, **then** there is one total per stage and no cross-stage or credits-plus-savings total. | Open decision #1 |
| R-04 | Product code contains no simulated, placeholder or replayed case IDs, statuses or amounts; fakes exist only in tests. | §8 F-00, §3 | — (not user-facing) | Must | **Given** the product build, **when** the M0 guard test scans product paths, **then** no fixture, replay or demo source can produce claim state. | ADR-004 §3, ADR-002 |
| R-05 | A step that can't complete returns a typed failure and the claim stays at its last confirmed stage. | §8 F-00 | US-09 / J-05 | Must | **Given** the CUR read fails during reconciliation, **when** the job ends, **then** the claim is unchanged and the failure is visible with its type. | ADR-004 §4 |

### F-01 Read-only account connection (M1)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-06 | Recoup publishes a CloudFormation template the customer deploys in their own account, creating one read-only role per account as [ADR-003](../adr/ADR-003-customer-read-only-role.md) specifies (trust, per-connection ExternalId, no default). | §8 F-01, §12 | US-02 / J-02 | Must | **Given** a new connection, **when** the customer opens the deploy link, **then** the template carries that connection's ExternalId and fails to deploy without one. | ADR-003 §1–3 |
| R-07 | The exact permission list is shown before deploy. | §12, §6 J-02 | US-02 / J-02 | Must | **Given** a prospect at the connect step, **when** they view it, **then** every IAM action and resource in the template is listed before any deploy link. | ADR-003 §4; list owned by SECURITY.md |
| R-08 | The template grants no write action and includes a deny-all-writes statement. | §4, §12 | US-02 / J-02 | Must | **Given** any template version, **when** the contract test parses it, **then** it finds no write action in any allow statement and finds the deny statement. | ADR-003 §4–5 |
| R-09 | A connection test assumes the role with the ExternalId, checks each permission the check needs (CUR export read, Health, Cost Explorer), and reports each pass or fail, including "Health API not available on this support plan". | §6 J-02, §12 | US-02 / J-02 | Must | **Given** a deployed role on an account without a qualifying plan, **when** the test runs, **then** CUR and Cost Explorer pass, Health shows the plan reason, and the check offers the fallback (R-14). | ADR-003 §6, NFR-10 |
| R-10 | Before connecting, the customer sees how many Cost Explorer calls the first report will make and what they cost. | §8 F-05, §6 J-02 | US-02 / J-02 | Must | **Given** chosen services, regions and the claim window, **when** the connect step loads, **then** it shows the expected call count and cost, billed to the customer's account. | ADR-009 §3–4 |
| R-11 | A failed assume-role marks the connection *disconnected*; Recoup stops retrying on a backoff limit and tells the tenant. | §12 | US-15 / J-07 | Must | **Given** the customer deleted the stack, **when** the next read fails with access denied, **then** the account shows *disconnected* and no read is retried after the limit. | ADR-003 §7 |

### F-02 Incident detection and account matching (M1)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-12 | For each connected account, Recoup reads account-specific and public AWS Health events covering the open claim window and stores each event it reads with its ARN and read time. | §8 F-02, §6 J-03 | US-03 / J-03 | Must | **Given** an account with a qualifying plan, **when** the check runs, **then** every Health event in the window is stored and cited by ARN. | Q-15, Q-16 |
| R-13 | Incidents are matched to the account's billed services and regions; each match cites the Health event and the billed service and region it matched. | §8 F-02 | US-03 / J-03 | Must | **Given** a Health event for a service the account has no charges for, **when** matching runs, **then** it isn't shown as affecting the account. | — |
| R-14 | Where the Health API isn't available, the customer can enter the incidents that hit them; these are labelled *customer-supplied* and matched like Health events. | §6 branches, §12 | US-14 / J-03 | Should | **Given** a Basic-plan account, **when** the customer enters an incident, **then** it is matched and labelled *customer-supplied* everywhere it appears. | Q-17, NFR-10 |

### F-03 SLA contract catalog (M1)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-15 | Each contract version is a pinned snapshot plus a structured file whose source hash is verified in CI, and the version used is chosen by incident date. | §8 F-03, §12 | US-04 / J-03 | Must | **Given** a snapshot whose SHA-256 differs from its recorded hash, or a placeholder hash, **when** CI runs, **then** the build fails. | [ADR-005](../adr/ADR-005-sla-catalog-pinned-snapshots.md) §1–4 |
| R-16 | The catalog holds 3–5 contracts at M1 exit, chosen per Q-03. | §8 F-03 | US-04 / J-03 | Must | **Given** M1 exit, **when** the catalog is listed, **then** it holds 3–5 contracts, each with golden tests from the published examples. | Q-03, ADR-005 |
| R-17 | A scheduled recheck compares each published SLA with its latest snapshot and opens a review on a difference; it never edits a contract. | §14 | US-16 / J-09 | Should | **Given** a changed SLA page, **when** the recheck runs, **then** a review is opened and no contract changes until P-06 publishes a new version. | ADR-005 §5, Q-32 |

### F-04 Eligibility and credit calculation (M1)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-18 | Eligibility is computed with each contract's own measurement definition from the customer's evidence, and returns *eligible*, *unproven* or *not eligible*, with the reason. | §8 F-04, §6 J-03 | US-04 / J-03 | Must | **Given** API Gateway intervals where one interval has 99% availability, **when** eligibility runs, **then** that interval counts as 99%, not 0%, and an interval with no requests counts as 100%. | ADR-005 §6 |
| R-19 | Every exclusion in the contract is evaluated and listed with its result; one that can't be ruled out makes the result *unproven*. | §8 F-04 | US-04 / J-03 | Must | **Given** a contract with four exclusions and no evidence for one, **when** eligibility runs, **then** all four are listed and the result is *unproven*. | ADR-005 §6 |
| R-20 | With no customer evidence for the window, eligibility is *unproven* and the claim is not marked ready. | §6 branches | US-04 / J-03 | Must | **Given** a matched incident and no logs, **when** the report is built, **then** the incident shows *unproven* with "logs needed" and no packet is marked ready. | Q-13 |
| R-21 | A credit at or below the contract's minimum is shown as not claimable, with the reason. | §8 F-04, §6 branches | US-05 / J-03 | Must | **Given** an API Gateway credit of $1.00, **when** calculated, **then** it shows *not claimable: below the contract minimum* (credits are issued only above $1). | ADR-005 §6 |
| R-22 | An incident scoped below the contract's measurement scope (for example one AZ against a region-level SLA) is shown as likely not eligible, with the reason. | §6 branches | US-04 / J-03 | Must | **Given** a single-AZ event and a region-level contract, **when** eligibility runs, **then** the result explains the scope mismatch. | — |
| R-23 | All money math uses Decimal with the contract's rounding, and every result keeps its calculation trace. | §12 | US-05 / J-03 | Must | **Given** any credit, **when** its trace is opened, **then** inputs, tier, rounding and result reproduce the amount exactly. | ADR-002 (calculator port) |
| R-24 | Every eligibility result shows the contract version, source URL and source hash it used. | §7 US-04 | US-04 / J-03 | Must | **Given** a result, **when** viewed, **then** version, URL and hash are shown and match the catalog. | ADR-005 |

### F-05 Billed charges (M1)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-25 | Charges per service, region, account and month come from the customer's CUR 2.0 export; while the export has no history, from Cost Explorer, labelled *estimate, source Cost Explorer*. | §8 F-05 | US-05 / J-03 | Must | **Given** a new export with no history, **when** the first report runs, **then** every charge shows source Cost Explorer and none counts toward *posted*. | [ADR-009](../adr/ADR-009-billing-data-cur2-with-cost-explorer-bootstrap.md) §1–3 |
| R-26 | When CUR 2.0 later covers a month first estimated from Cost Explorer, both figures and the variance are shown. | §8 F-05 | US-05 / J-03 | Should | **Given** a Cost Explorer estimate and a later CUR figure, **when** the claim is viewed, **then** both and their difference are shown. | ADR-009 consequences |
| R-27 | Without a usable export the check still runs on Cost Explorer estimates; reconciliation is shown as unavailable and the customer is told how to request a backfill. | §8 F-05, §14 | US-05 / J-03 | Must | **Given** no export, **when** the report is built, **then** it completes with estimates and states that posted credits can't be confirmed without CUR 2.0. | ADR-009 §5–6, Q-11 |

### F-06 Claim packet (M1)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-28 | A packet contains every field the contract snapshot requires (for API Gateway: subject "SLA Credit Request", incident dates, times and regions, API IDs, billing cycle, request logs). | §8 F-06 | US-06 / J-03 | Must | **Given** a contract's required-fields list, **when** a packet is built, **then** each field is filled or the packet is not ready, naming what's missing. | ADR-005 §1, ADR-007 §1 |
| R-29 | Log excerpts have sensitive data removed before they enter a packet, and P-02 sees what was removed before the packet is final. | §12 data handling | US-06 / J-03 | Must | **Given** a log line with an email address and IP, **when** the excerpt is built, **then** both are redacted and the redaction is listed for review. | NFR-05 |
| R-30 | Each packet shows its filing deadline, computed from the contract's deadline rule. | §8 F-06 | US-06 / J-03 | Must | **Given** an incident date and contract, **when** the packet is built, **then** the deadline shown is the earlier reading of the contract's rule, and a claim between the two readings shows "may have expired — check with AWS". | Q-14 |
| R-31 | Filing aids: copy subject and body, download excerpts as an attachment, and open the Support Center create-case page. | §8 F-06 | US-06 / J-04 | Should | **Given** a ready packet, **when** P-02 files, **then** all three actions work without retyping. | ADR-007 §3 |
| R-32 | A claim is marked *ready* only if it is eligible (not unproven), above the minimum, before its deadline and its packet is complete. | §6, §8 F-06 | US-06 / J-03 | Must | **Given** an eligible claim past its deadline, **when** the report is built, **then** it is shown as expired, not ready. | — |
| R-55 | The free account report lists every claimable credit with its estimate, deadline and stage, and builds one complete packet: the ready claim with the largest estimate. Packets for every ready claim are built for tenants with a pilot agreement. | §6 J-03, §4 goal 2 | US-06 / J-03 | Must | **Given** a free report with three ready claims, **when** it is built, **then** all three are listed with deadlines and only the largest has a packet; **and given** a pilot tenant, **then** all three have packets. | Q-24, ADR-001, ADR-013 |

### F-07 No-access estimator (M1)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-33 | A prospect enters regions, services and rough monthly spend without AWS access. | §6 J-01, §4 goal 1 | US-01 / J-01 | Must | **Given** a visitor with no account connected, **when** they submit regions, services and spend, **then** results appear without any AWS permission. | Q-31 |
| R-34 | Results list public incidents in the open claim window that may qualify, taken from Recoup's own record of public AWS Health events, each with its deadline and a dollar range labelled *estimate*, and the assumptions behind the range. | §6 J-01 | US-01 / J-01 | Must | **Given** a public incident in us-east-1 for a chosen service, **when** results show, **then** it appears with its source event, deadline, range, the label *estimate* and the spend assumption used. | Q-15 |
| R-35 | Results offer two next steps: book an interview, or connect an account. Each choice is recorded as a funnel event. | §6 J-01, §11 KPI-03 | US-01 / J-01 | Must | **Given** results, **when** the visitor picks either action, **then** a funnel event is recorded for KPI-03. | Q-31 |

### F-08 Bound approval (M2)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-36 | An approval binds the approver, the claim content hash, the amount, the claim state version, the policy revision and an expiry; any change to these invalidates it. | §8 F-08 | US-07 / J-04 | Must | **Given** an approved claim, **when** one log excerpt changes, **then** the approval is invalid and re-approval is required. | ADR-002 (approval port) |
| R-37 | An approver can decline (with a reason) or revoke an approval before the claim is submitted. | §8 F-08 | US-07 / J-04 | Must | **Given** an approved, unsubmitted claim, **when** the approver revokes, **then** it returns to *eligible* and the revocation is audited. | — |
| R-38 | Only a user holding the approver role for that tenant can approve. | §8 F-08 | US-07 / J-04 | Must | **Given** a contributor, **when** they try to approve, **then** the request is denied and audited. | Q-18 |
| R-56 | Each tenant has named users who sign in individually with MFA and hold one role: approver, contributor or viewer. Every action is attributed to the user who took it. | §8 F-08, §12 audit | US-07 / J-04 | Must | **Given** a viewer, **when** they try to enter a case ID, **then** it is denied; **and given** any state change, **then** its audit record names the user. | Q-18 |

### F-09 Case tracking (M2)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-39 | A customer user records the AWS case ID for an approved claim; the claim moves to *submitted*, and the ID is labelled customer-entered with who and when. | §8 F-09 | US-08 / J-04 | Must | **Given** an approved claim, **when** a case ID is entered, **then** the stage is *submitted* and the record shows the user and time. | ADR-004, ADR-007 §1 |
| R-40 | A customer user records the outcome: *granted* with the amount, or *denied* with AWS's reason; both labelled customer-entered. Recoup keeps the predicted result next to the outcome. | §8 F-09 | US-10 / J-05 | Must | **Given** a submitted claim, **when** a denial is entered, **then** the reason is stored and the prediction and outcome are both on the claim. | ADR-007 §4, Q-25 |
| R-41 | A denied claim is either closed or resubmitted, and a resubmission is linked to the original. | §7 US-10 | US-10 / J-05 | Must | **Given** a denied claim, **when** it is resubmitted, **then** a new submission links to the first and both stay visible. | — |

### F-10 Credit reconciliation (M2)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-42 | A granted claim becomes *posted (verified)* only when a CUR 2.0 Credit line matches it under the matching rule; the variance from the estimate is recorded. | §8 F-10 | US-09 / J-05 | Must | **Given** a granted claim and a matching Credit line, **when** reconciliation runs, **then** the claim is *posted* with the line's ID and the variance. | ADR-004, ADR-009 §2, Q-12 |
| R-43 | A possible but ambiguous match is shown to P-03 to confirm or reject; the claim stays *granted* until confirmed. | §8 F-10 | US-18 / J-05 | Must | **Given** two candidate Credit lines, **when** reconciliation runs, **then** neither is applied automatically and P-03 is asked. | Q-12 |
| R-44 | Reconciliation re-reads finalized months, because AWS may add a credit to a month after it closes. | §8 F-10 | US-09 / J-05 | Must | **Given** a credit added to a finalized month, **when** the next refresh lands, **then** reconciliation finds it. | ADR-009 (AWS fact) |
| R-54 | A granted claim with no Credit line after its matching window is flagged *credit not seen*. If the customer reports a refund outside the bill (for example to a card), it is recorded as *refunded outside the bill (customer-entered)*, never as *posted (verified)*, and never counted in the posted total. | §8 F-10, §12 money labelling | US-09 / J-05 | Must | **Given** a granted claim and a customer-entered card refund, **when** the ledger opens, **then** the amount sits under *refunded outside the bill* and the posted total excludes it. | Q-12, ADR-013 §3 |

### F-11 Deadline radar (M2, Should)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-45 | The claim owner is emailed 14 days and 3 days before each ready or unproven claim's deadline. | §8 F-11 | US-11 / J-06 | Should | **Given** a claim due in 14 days, **when** the daily job runs, **then** exactly one email goes to the owner through the outbox, and again at 3 days. | Q-22, Q-23, ADR-006 §3 |
| R-46 | At each new billing cycle, claimable incidents nearing their deadline are listed for the tenant. | §6 J-06 | US-11 / J-06 | Should | **Given** a new cycle, **when** the job runs, **then** the list shows each claim with days left. | — |

### F-12, F-13 Evidence trail and ledger (M2)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-47 | One record per claim holds the incident, contract version and hash, evidence hashes, approval, case ID and Credit line, and can be exported. | §8 F-12 | US-12 / J-05 | Should | **Given** a posted claim, **when** its trail is exported, **then** every listed item is present and each hash re-verifies. | ADR-004, ADR-005 |
| R-48 | An SLA credit ledger lists every claim with its amount at each stage reached and totals per stage. | §8 F-13 | US-09 / J-05 | Must | **Given** claims at several stages, **when** the ledger opens, **then** each stage has its own total and only *posted* is called verified. | R-02, R-03 |

### Agent steps (PRD §9)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-49 | An agent proposes incident windows and affected resources from postmortems or free-text notes, with sources; P-02 confirms before eligibility uses them. | §9 | US-04 / J-03 | Could | **Given** a postmortem, **when** the agent proposes a window, **then** nothing uses it until P-02 confirms, and each proposed value cites its source text. | ADR-011, NFR-09 |
| R-50 | An agent drafts the claim narrative from verified facts only; P-01 reviews it before approval. | §9 | US-06 / J-03 | Could | **Given** a draft with a fact not in the claim record, **when** validation runs, **then** the draft is rejected. | ADR-011 |
| R-51 | An agent proposes a structured denial reason from pasted AWS case text; P-01 confirms the classification. | §9 | US-10 / J-05 | Could | **Given** case text containing instructions, **when** the agent runs, **then** they are treated as data and only a reason from the fixed list is proposed. | ADR-011, NFR-09 |

### Evidence supply and data lifecycle (J-07, J-08)

| ID | Requirement | PRD § | Story | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| R-52 | P-02 can supply request-log evidence for an incident window in the formats each contract lists; Recoup computes availability from it and keeps only redacted excerpts and hashes. | §6 J-03, §5 P-02, §12 | US-13 / J-08 | Must | **Given** an API Gateway access-log extract for the window, **when** uploaded, **then** per-interval availability is computed and the raw file is deleted 30 days after the claim closes. | ADR-010, Q-27 |
| R-53 | On disconnect or tenant exit, reads stop at once and customer data is deleted on the stated schedule, with the deletion audited. | §12 data handling | US-15 / J-07 | Should | **Given** a disconnected tenant, **when** 30 days have passed with no open claim the customer asked to keep, **then** raw billing rows and logs are gone and an audit record says so. | Q-27, R-11 |

## Non-functional requirements (NFR-xx)

| ID | Category | Requirement | PRD § | Priority | Acceptance | Links |
|---|---|---|---|---|---|---|
| NFR-01 | Security | No v1 code path, template or credential can write to a customer AWS account. | §4, §12 | Must | A CI contract test fails on any write action in templates or adapter allow-lists; no `support:CreateCase`. | ADR-003, ADR-007 §2 |
| NFR-02 | Security | ExternalIds are generated by Recoup, unique per connection, never reused or defaulted, and stored tenant-scoped. | §12 | Must | Uniqueness constraint in the schema; template has no default; test proves cross-tenant lookup fails. | ADR-003 §3 |
| NFR-03 | Correctness | Money uses Decimal end to end (no floats in storage, API or UI formatting); contracts are pinned by incident date with the source hash recorded. | §12 | Must | Static check rejects float money types; every result stores contract version and hash. | ADR-005 |
| NFR-04 | Confidentiality | Billing data and logs are encrypted in transit and at rest and readable only within their tenant. | §12 | Must | TLS required; encrypted storage with a customer-managed key; access test across tenants fails. | ADR-008 §2 |
| NFR-05 | Privacy | Personal and sensitive data is removed from log excerpts before storage in a packet; retention, deletion and the applicable law (DPDP Act, GDPR) follow SECURITY.md. | §12 | Must | Redaction tests on seeded personal data; retention rule documented in SECURITY.md (Q-27). | Q-27 |
| NFR-06 | Security | Tenant isolation end to end: database, files, queues, logs, caches and any model context. | §12 | Must | Cross-tenant tests at each layer (process conformance C07). | — |
| NFR-07 | Durability | All state survives restart, with no in-memory or fallback store in any environment. | §12 | Must | Restart test loses no accepted work; no fallback code path exists. | ADR-006 |
| NFR-08 | Audit | Every consequential action is audited in the same transaction as its state change; a failed audit write fails the action visibly. | §12 | Must | M0 test: forced audit failure rolls back the change and returns an error. | ADR-006 §2 |
| NFR-09 | Security (untrusted input) | AWS case text, logs, postmortems and Health event text are data: never instructions, never able to change state or permissions. | §12, §9 | Must | Injection fixtures in each input path cause no state change (conformance C06). | — |
| NFR-10 | Dependency | The AWS Health API needs AWS Business Support+, Enterprise Support or Unified Operations; accounts not yet moved to these can use Business (classic), Enterprise On-Ramp or Enterprise until those end on 2027-01-01. Other accounts get the fallback path (R-14). | §12 | Must | Connection test (R-09) distinguishes `SubscriptionRequiredException` from other failures. | Q-10 |
| NFR-11 | Performance | The account-specific report is ready within 24 hours of a successful connection test. | §11 KPI-04 | Must | Job timestamps show ≤24 h for test accounts, Cost Explorer bootstrap included. | ADR-009 §3 |
| NFR-12 | Recoverability | RPO ≤5 minutes and RTO ≤4 hours from M2 (Q-28), rehearsed before go-live. | §12 durability | Must | Restore drill meets both targets in hardening. | ADR-008 §3, Q-28 |
| NFR-13 | AI quality | Any agent step has a versioned eval set and claims no maturity level until tests show it; the model never authorises a transition. | §9 | Should | Eval suite exists before an agent step ships; no state transition is reachable from model output alone. Not exercised in v1 (ADR-011). | ADR-011 |

Decided outside the PRD and applied as Stage 2 design inputs: no customer availability commitment in v1, WCAG 2.2 AA, English only (Q-29); all data in us-west-2 ([ADR-012](../adr/ADR-012-hosting-region-us-west-2.md)). They become NFRs at the next PRD revision.

## Success metrics (KPI-xx)

From PRD §11. "Type" says where the number comes from; product-measured KPIs become analytics events in Stage 2 (OBSERVABILITY.md).

| ID | Metric | Target (hypothesis) | Measured by | Type | When |
|---|---|---|---|---|---|
| KPI-01 | Discovery evidence before M2 | ≥10 account-specific reports and ≥5 follow-up conversations | Report records; conversation log | Discovery | Before M2 (ADR-014) |
| KPI-02 | Share of connected accounts with ≥1 claimable incident in 12 months | ≥50% to confirm; kill below 30% (Q-35) | Account reports: proven claims in the open window, plus public incidents matched to billed services and regions over 12 months (estimate) | Discovery (kill metric) | Before M2 (ADR-014) |
| KPI-03 | No-access check → read-only connection | ≥30% | Funnel events (R-35, R-09) | Product | M1 |
| KPI-04 | Time from connection to report | ≤24 hours | Job timestamps | Product | M1 (NFR-11) |
| KPI-05 | Claims filed per connected account | ≥1 in the pilot window | Claim records (R-39) | Product | M2 |
| KPI-06 | Grant rate of filed claims | ≥70% | Case outcomes (R-40) | Product | M2 |
| KPI-07 | Estimate accuracy | Posted within ±10% of estimate | Reconciliation variance (R-42) | Product | M2 |
| KPI-08 | SRE time per claim | <30 minutes | Partner self-report | Pilot | M2 |
| KPI-09 | Paid agreements | ≥1 contingency agreement in the pilot | Contracts | Commercial | M2 |
| KPI-10 | Expected annual credits per partner | Kill if the median is below $10k (Q-35) | Account-report estimates before M2; pilot data after | Commercial (kill metric) | Before M2, then M2 |
| **KPI-11** (added, Q-34) | Ready packets filed before their deadline | ≥80%; below it, revisit F-15 | Claim records (R-32, R-39) | Product | M2 |

## Out of scope

| Item | Source |
|---|---|
| Any write to a customer AWS account, including remediation and the hackathon `RecoupRemediationRole` / EC2 stop path | PRD §4, §15; ADR-003 |
| Waste remediation, recurring-savings tracking and all savings figures (F-16, Won't) | PRD §4, §8, §15; open decision #1 |
| Commitment (RI / Savings Plan) management | PRD §4, §15 |
| Recoup filing claims, including automatic filing through the Support API (F-15, Could, later) | PRD §4, §8; ADR-007 |
| Jira / Slack handoff to the SRE (F-14, Could, later) | PRD §8 |
| Azure, GCP and other providers | PRD §4, §15 |
| Cost anomaly detection, chat-based cost Q&A | PRD §4, §15 |
| Strands / AgentCore runtime | PRD §3, §15 |
| Legacy CUR | ADR-009 §6 |
| MSP and reseller claims (P-05, M-03) | PRD §16 #5 (A-05) |
| Hackathon items marked Drop: "Execution" after approval, "Recovery Verified" panel and savings ledger, SNS recovery report | PRD §3; ADR-002 |
| Accounts sold by AWS India (AISPL) or billed in a currency other than USD — until verified | Q-20 |
| Any language model, and the PRD §9 agent steps (R-49 – R-51 after M2) | ADR-011 |
| Log or metric read in the customer account | ADR-010 |
| Pricing logic in the product | ADR-013 §5 |

## Coverage: PRD section → R-xx

| PRD section | Covered by |
|---|---|
| Header, "Read this first" | Framing note above; G1 check |
| §1 Summary; decisions D1, D2, open decision #1 | All features; ADR-001, ADR-002; out of scope (savings) |
| §2 Problem | V-01 (framing); R-18, R-28, R-42 |
| §3 Current state | Port: R-15, R-23, R-36 (ADR-002). Rebuild: R-01, R-12, R-39, NFR-07. Drop: out of scope. Evidence: DISCOVERY.md |
| §4 Goals 1–3 | Goal 1: R-33 – R-35. Goal 2: R-06 – R-32. Goal 3: R-36 – R-48 |
| §4 Goal 4 | KPI-01, KPI-02, KPI-10 (discovery, not product) |
| §4 Non-goals | Out of scope; NFR-01 |
| §5 Personas | Product framing; P-06 added (Q-32) |
| §6 Journeys | Product framing; J-07 – J-09 added; branches → R-14, R-20, R-21, R-22 |
| §7 Stories | R-xx "Story" column; US-13 – US-18 added |
| §8 F-00 – F-13 | R-01 – R-48, R-54 – R-56 |
| §8 F-14 – F-16 | Out of scope |
| §9 Agent steps | R-49 – R-51, NFR-09, NFR-13 |
| §10 Value and defensibility | Product framing; competitive check → Q-06 |
| §11 KPIs | KPI-01 – KPI-10; NFR-11 |
| §12 Constraints | NFR-01 – NFR-10, NFR-12; R-02, R-29 |
| §13 Release plan | Release column per feature; dates at G3 |
| §14 Risks | R-14, R-17, R-27; the rest to DELIVERY_PLAN.md RAID (Stage 3) |
| §15 Out of scope | Out of scope |
| §16 Open questions | QUESTIONS.md Q-01 – Q-09 (decided or accepted) |
| Revision notes | Not a requirement source |

## Gate G1 check

Re-checked 2026-11-27 under [ADR-014](../adr/ADR-014-build-before-interviews.md): build first; the free check replaces the interviews.

| G1 criterion | Result | Status |
|---|---|---|
| Personas, journeys, stories and value hypotheses exist and the client has confirmed them | **Conditional** | All exist and are accepted as hypotheses. Evidence moves to the free check, and the ADR-014 discovery checkpoint must be met before M2. |
| Every user-facing Must R-xx traces to a user story and journey | Pass | — |
| Every agent step has a target maturity and an approver | Pass | Deferred past M2 (ADR-011). |
| Every PRD section maps to an R-xx or is out of scope | Pass | Coverage table above. |
| Every Must has acceptance criteria | Pass | — |
| The client has answered the questions or accepted the assumptions | Pass | 31 decided; Q-04, Q-06, Q-07 and Q-08 to be measured through the free check. |
| PRD §14: Next Signal demo before G1 | **Open** | Recommended before M1 build-out (ADR-014 §5). |
| PRD revision for ADR-014 | Done | PRD revision 6, 2026-11-27. |
| Signature (Q-09) | **Signed, conditional** | Product owner, 2026-11-27. Condition: no M2 until the ADR-014 discovery checkpoint is met. |
