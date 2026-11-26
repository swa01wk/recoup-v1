# ADR-023: Run api and worker on Amazon ECS on Fargate in us-west-2, behind CloudFront; the database is reached with IAM authentication; email through Amazon SES
Status: Accepted (decided in Stage 2a; product owner to review at G2)    Date: 2026-11-27

**Context:** [ADR-015](ADR-015-backend-python-fastapi.md) makes the backend one image with two process types. [ADR-016](ADR-016-frontend-react-spa.md) serves the frontend as static files on one origin with the API. [ADR-008](ADR-008-postgresql-on-amazon-rds.md) §6 left open how the app authenticates to the database. [ADR-012](ADR-012-hosting-region-us-west-2.md) puts everything in us-west-2. The worker must reach STS, AWS Health, Cost Explorer, customer S3 buckets and the published SLA pages (R-17). Deadline emails go through the outbox (R-45, Q-23). The public check is anonymous, so it needs abuse protection.

**Decision:**
1. **Compute: ECS on Fargate**, private subnets in three Availability Zones in us-west-2.
   - `api`: at least 2 tasks in production, behind an internal-facing Application Load Balancer.
   - `worker`: 1 task, which can safely scale out because jobs are claimed with `SKIP LOCKED` ([ADR-020](ADR-020-jobs-in-postgresql.md)).
2. **Edge:** CloudFront serves the SPA from S3 and routes `/api/*` to the ALB through a CloudFront VPC origin, so the ALB is never public. AWS WAF on CloudFront rate-limits the anonymous endpoints (`/api/v1/estimates`, `/api/v1/funnel-events`) and applies AWS managed rule groups.
3. **Egress:** VPC endpoints for S3, STS, SQS, KMS, Secrets Manager and CloudWatch Logs; a NAT gateway for everything else (Health and Cost Explorer endpoints, customer buckets in other Regions, aws.amazon.com SLA pages). Egress is restricted by security group to HTTPS.
4. **Identity per process:** separate ECS task roles for `api` and `worker`. Only the worker's task role is the principal the customer role trusts ([ADR-003](ADR-003-customer-read-only-role.md) §2).
5. **Database authentication: RDS IAM authentication**, no static app passwords.
   - The `api` task role may connect as `recoup_app` and `recoup_catalog`.
   - The `worker` task role may connect as `recoup_app`, `recoup_catalog` and `recoup_lifecycle` ([ADR-018](ADR-018-tenant-isolation-row-level-security.md)).
   - The master credential is managed by RDS in Secrets Manager and used only by migrations, through a one-off ECS task.
6. **Email: Amazon SES in us-west-2**, sending from a verified Recoup domain (DKIM, SPF, DMARC). Sending is done only by the outbox consumer. M2 only.
7. **Files:** one S3 bucket for evidence uploads and packet attachments, private, SSE-KMS with a customer-managed key, versioning on, with lifecycle rules backing up the Q-27 deletions ([ADR-018](ADR-018-tenant-isolation-row-level-security.md) §5 for keys and encryption context).

**Alternatives:**
- *AWS Lambda for the API and jobs.* Rejected: report jobs can run for many minutes, the worker loop is long-lived, and a container matches local Docker Compose (PROCESS.md: same image locally and in AWS).
- *App Runner.* Rejected: less control over VPC egress and task roles, and no separate worker shape.
- *EKS.* Rejected: a cluster to run for two services.
- *Static database passwords in Secrets Manager with rotation.* Rejected, weakly: it works, but IAM authentication removes a secret entirely. IAM authentication's connection-rate limits don't matter at our scale.

**Consequences:**
- Easier: the same container locally and in AWS; no public load balancer; no static app database password.
- Harder: a NAT gateway and three-AZ networking are a fixed cost from M0 (TECH_STACK.md); IAM database tokens must be refreshed by the connection pool.
- We must now: put this in the M0 CDK stacks; set the WAF rate limits in SECURITY.md (2b); cost it in TECH_STACK.md (2b).
