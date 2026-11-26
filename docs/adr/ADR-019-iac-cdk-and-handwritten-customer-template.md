# ADR-019: Recoup's own infrastructure is defined in AWS CDK (TypeScript); the customer role template is a hand-written CloudFormation file, versioned and contract-tested
Status: Accepted (decided in Stage 2a; product owner to review at G2)    Date: 2026-11-27

**Context:** PROCESS.md requires infrastructure as code. [ADR-008](ADR-008-postgresql-on-amazon-rds.md) and [ADR-012](ADR-012-hosting-region-us-west-2.md) put the database and region in M0 IaC. Recoup's AWS footprint is: RDS, ECS, CloudFront and S3, Cognito, SQS, KMS, SES, plus EventBridge rules in every supported Region for Health capture ([ADR-021](ADR-021-public-health-capture.md)). There are two kinds of infrastructure with different readers:
- **Recoup's own account(s)**, read by Recoup's engineers.
- **The customer's role template** ([ADR-003](ADR-003-customer-read-only-role.md)), read line by line by P-04, deployed by the customer, and parsed by a contract test (R-06, R-08, NFR-01).

The hackathon used CDK in TypeScript (`infra/cdk/`); ADR-002 ports only the read-only role's pattern from it.

AWS fact (read 2026-11-27): CloudFormation has an `AWS::BCMDataExports::Export` resource for CUR 2.0 exports ([reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-bcmdataexports-export.html)). That answers the Stage 2 check in [ADR-009](ADR-009-billing-data-cur2-with-cost-explorer-bootstrap.md) §1.

**Decision:**
1. **Recoup's infrastructure: AWS CDK v2 in TypeScript**, in `infra/`. One app; one stack per concern (network, data, compute, identity, edge, health-capture). The health-capture stack is deployed to every supported Region. Environments are dev, staging and prod, each in its own AWS account.
2. **Customer template: plain CloudFormation YAML**, hand-written, in `infra/customer-template/recoup-readonly-role.yaml`. It isn't synthesised by CDK, so the file a security reviewer reads is exactly the file that gets deployed.
   - Parameters: `ExternalId` (no default, `MinLength` enforced), plus `CurBucketName` and `CurPrefix`.
   - An optional `CreateCurExport` condition creates the CUR 2.0 export with `AWS::BCMDataExports::Export`, and its bucket, in the customer's account (ADR-009 §1).
   - The template is published to a versioned, public-read S3 path with its SHA-256. The quick-create link names the exact version.
3. **Contract tests on the template** (M0/M1 CI): cfn-lint; no write action in any `Allow` statement (NFR-01); the deny-all-writes statement is present (R-08); `ExternalId` has no default (NFR-02); no `support:CreateCase` (ADR-007); the template's action list equals the list in SECURITY.md (R-07).
4. **Changes:** both kinds go through a normal PR and deploy through the pipeline. `cdk diff` output is posted on infra PRs.

**Alternatives:**
- *Terraform or OpenTofu.* Rejected: provider-neutral, but v1 is AWS only, the customer artifact has to be CloudFormation anyway, and it adds state management. Confidence medium; it's a reasonable choice that we're not making.
- *CDK for the customer template too.* Rejected: synthesised templates carry generated names and metadata that make P-04's review harder, and the template a customer sees would differ from the source we review.
- *CDK in Python, to match the backend.* Rejected, weakly: TypeScript is CDK's best-supported language, and the frontend already uses TypeScript.

**Consequences:**
- Easier: the customer template stays short and readable; Recoup's infra uses one AWS-native tool.
- Harder: three languages in the repo (Python, TypeScript, YAML templates); Region-wide Health stacks need a per-Region deploy loop.
- We must now: record the CDK version in TECH_STACK.md; build the template and its contract tests in the M1 connection spec; build the health-capture stack as the first M0 spec (ADR-021).
