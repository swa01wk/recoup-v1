# ADR-003: Customer access is one read-only role per customer account, deployed by the customer, with a Recoup-generated ExternalId
Status: Accepted    Date: 2026-11-27

**Context:** PRD §12 requires read-only, least-privilege access, an ExternalId on every role, and the permission list shown before deploy. PRD §4 makes any write to a customer's AWS account a v1 non-goal. J-02, US-02 and F-01 need a role a security reviewer (P-04) can approve quickly. The hackathon role trusts a role in Recoup's own account, defaults its ExternalId to a constant, and sits next to a write role that the code calls ([DISCOVERY.md](../discovery/DISCOVERY.md), differences 1 and 2).

AWS guidance (IAM User Guide, read 2026-11-27): the vendor generates a unique ExternalId for each customer, and that value is controlled by the vendor, not by its customers ([confused deputy](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html); [third-party access](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_third-party.html)). The Well-Architected security pillar adds that a reused ExternalId across customers is an anti-pattern, and that the customer keeps control of the role's permissions ([SEC03-BP05](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec03-bp05.html)).

**Decision:**
1. **The customer deploys the role in their own account** from a CloudFormation template that Recoup publishes. Customers need no tooling beyond the AWS console. One role per connected account.
2. **Trust:** the role trusts one named Recoup access role in Recoup's AWS account (a role ARN, not the account root), and requires `sts:ExternalId`.
3. **ExternalId:** Recoup generates a random, unique value for each connection and passes it into the template. It is stored with the tenant, never reused, and never defaulted. The template has no default value, so it can't be deployed without one.
4. **Permissions:** read-only, and only what M1 uses: billing data and AWS Health reads. A deny-all-writes statement (the `NotActions` pattern ported per [ADR-002](ADR-002-new-repo-via-process.md)) backs up the allow list. The exact permission list is owned by `SECURITY.md` (Stage 2) and shown to the customer before deploy (US-02).
5. **No write role and no write action in v1.** `RecoupRemediationRole` and `tools/ec2_tools.py` are not ported. A future write needs its own ADR, an approval binding, audit, rollback and a verification step (project rules).
6. **Connection test (J-02):** Recoup assumes the role with the ExternalId and checks each permission it needs, then reports any that failed.
7. **Revocation:** the customer disconnects by deleting the stack. Recoup treats a failed assume-role as disconnected, not as a reason to retry forever.

**Alternatives:**
- *Keep the hackathon's same-account role.* Rejected: a customer can't use it.
- *Let the customer choose the ExternalId.* Rejected: AWS says the vendor should generate and control it, to prevent the confused-deputy problem.
- *Long-term access keys.* Rejected: Well-Architected lists them as an anti-pattern for third-party access.
- *The AWS-managed `ReadOnlyAccess` policy.* Rejected: it reads far more than we need, so it fails P-04's review.
- *A remediation role for the pilot.* Rejected: out of scope for v1 (PRD §4, §15).

**Consequences:**
- Easier: a short, auditable permission list for security review; access is revocable by the customer at any time.
- Harder: Recoup must store an ExternalId per connection with tenant isolation (PRD §12), and must ship and version the template.
- We must now: write the permission list and the ExternalId handling in `SECURITY.md` (Stage 2); add a contract test that the template has no write action and no default ExternalId; port only the read-only pattern.
- Open: which billing-data source (CUR or Data Exports) and how its S3 bucket is read is decided in Stage 2.
