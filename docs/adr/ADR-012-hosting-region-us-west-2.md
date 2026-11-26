# ADR-012: Host all Recoup data in us-west-2 (Oregon)
Status: Accepted (decision delegated by the product owner)    Date: 2026-11-27

**Context:** [ADR-008](ADR-008-postgresql-on-amazon-rds.md) left the region open, suggesting Recoup shouldn't depend on the region whose outages it reports on most. PRD §12 treats billing data as confidential and names the DPDP Act and GDPR. v1 serves accounts sold by Amazon Web Services, Inc. and billed in USD ([QUESTIONS.md](../product/QUESTIONS.md) Q-20), so customers can be anywhere; no design partner is known yet. The region is cheap to change before M1 puts customer data in it, and expensive after. Raised as Q-30.

**Decision:**
1. **All Recoup data, compute and backups live in us-west-2.** No customer data is copied to another region.
2. **Recoup's own AWS Health capture** (Q-15) uses EventBridge rules in each supported region, forwarded to us-west-2. The AWS Health API's global endpoint is served from us-east-1 with failover, so Health reads follow AWS's high-availability endpoint guidance rather than a fixed us-east-1 call.
3. **Cross-border transfer terms** for India (DPDP Act) and the EU (GDPR) are written in SECURITY.md in Stage 2, before M1.
4. **When to revisit:** before the first design partner's data lands, if their contract or law requires in-country storage. That needs a new ADR; until then nothing moves.

**Alternatives:**
- *us-east-1.* Rejected: it is the region whose incidents Recoup reports most, so a regional outage would take Recoup down just when customers look for it.
- *ap-south-1 (Mumbai).* Not now: it fits Indian customers, but v1 excludes AISPL accounts (Q-20), and no partner needs Indian data residency yet.
- *An EU region.* Not now: no EU partner yet; GDPR transfers can be covered contractually.

**Consequences:**
- Easier: a mature region with broad service coverage, independent of us-east-1 outages.
- Harder: transfer terms must be explained to Indian and EU customers; Health intake needs rules in several regions.
- We must now: put us-west-2 in M0 infrastructure as code; record the transfer terms in SECURITY.md.
