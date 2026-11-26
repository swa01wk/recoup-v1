# ADR-009: Read billing data from CUR 2.0 (AWS Data Exports), and use the Cost Explorer API only to bootstrap the first estimate
Status: Accepted (decision delegated by the product owner)    Date: 2026-11-27

**Context:** F-05 and US-05 need billed charges by service, region and month to estimate each credit. F-10 and US-09 need each posted credit matched to its billing Credit line. KPI-04 targets a report within 24 hours of connecting (J-03). The claim window reaches back about two billing cycles. [ADR-003](ADR-003-customer-read-only-role.md) left the billing-data source open, and on 2026-11-27 the product owner asked for it to be decided here.

AWS facts (read 2026-11-27):
- CUR 2.0, delivered through AWS Data Exports, is AWS's recommended way to receive detailed cost and usage data ([Data Exports](https://docs.aws.amazon.com/bedrock/latest/userguide/cost-mgmt-understanding-cur-data.html)).
- The report has a Credit line item type for credits AWS applied to the bill, and AWS may update a finalized month when it applies a credit afterwards ([line item details](https://docs.aws.amazon.com/cur/latest/userguide/Lineitem-columns.html)).
- An export refreshes at least once a day ([export delivery](https://docs.aws.amazon.com/cur/latest/userguide/dataexports-export-delivery.html)).
- A new export has no history. Up to 14 months can be backfilled by opening a support case ([AWS blog](https://aws.amazon.com/blogs/aws-cloud-financial-management/how-and-why-you-should-move-to-cost-and-usage-report-cur-2-0/)).
- The Cost Explorer API covers up to 13 months of history plus the current month ([best practices](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-api-best-practices.html)), and can filter by record type, credits included ([API reference](https://docs.aws.amazon.com/sdkforruby/api/Aws/CostExplorer/Client.html#get_tags-instance_method)).
- Each paginated Cost Explorer API request costs $0.01, charged to the account that makes it ([FAQ](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/faqs/)).

**Decision:**
1. **CUR 2.0 is the system of record** for billed charges and posted credits. The customer has (or creates) a CUR 2.0 export in Parquet, delivered to an S3 bucket in their own account. Recoup's role reads only that bucket prefix. The customer can create it with the ADR-003 template or in the console; which one we offer depends on what CloudFormation supports, checked in Stage 2.
2. **Only CUR 2.0 data can mark a credit *posted*** ([ADR-004](ADR-004-claim-state-from-system-of-record.md)). Posted means a Credit line matched to the claim's service, account and billing period, with the variance from the estimate recorded (US-09).
3. **Cost Explorer bootstraps the first report.** When an export is new and has no history yet, Recoup reads monthly charges by service and region for the claim window from `ce:GetCostAndUsage`, so the first report meets KPI-04 without waiting for a backfill. Those amounts are labelled *estimate*, source Cost Explorer, and never count as posted.
4. **Cost Explorer calls are few and visible.** They are monthly granularity, limited to the services and regions in question, and the expected number of calls is shown before connecting, because the customer pays for them.
5. **If there is no usable export,** the check still works on Cost Explorer estimates, but reconciliation (F-10) and the pilot need the export. Recoup tells the customer how to request a backfill; it doesn't file that case for them (ADR-007).
6. **Legacy CUR is not supported** in v1.

**Alternatives:**
- *CUR 2.0 only.* Rejected: a new customer's export has no past months, so the first report would wait on a backfill case, which breaks KPI-04 and the free check.
- *Cost Explorer only.* Rejected for reconciliation: it gives aggregates, not the specific Credit line a finance team can tie to a claim (M-01), and every query costs the customer money.
- *Legacy CUR.* Rejected: AWS recommends CUR 2.0, and supporting both schemas doubles the parsing work.
- *The customer uploads billing exports by hand.* Kept only as a fallback for customers who won't grant access (PRD §14), not as the main path.

**Consequences:**
- Easier: one detailed source of truth for both charges and credits; no waiting for history before the first report.
- Harder: two adapters to build and test; estimates from Cost Explorer and later CUR figures can differ, so the variance has to be shown, not hidden; the export lives in the customer's account, so reading it depends on their bucket's settings.
- We must now: add the S3 read and `ce:GetCostAndUsage` to the permission list in `SECURITY.md`; define the claim-to-Credit-line matching rule in Stage 2. Raise as Stage 1 questions: whether member accounts in an AWS Organization can create their own export, or whether the management account has to; and how we handle a customer whose billing sits with a reseller (PRD §16 question 5).
