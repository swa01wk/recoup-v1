# ADR-005: SLA contracts are pinned, hashed snapshots of the published terms, and the calculator follows each contract's own definition
Status: Accepted    Date: 2026-11-27

**Context:** US-04 needs the contract version, source URL and hash shown with exclusion checks. F-03 and F-04 need versioned, source-hashed contracts and per-contract calculation with the $1 floor. PRD §12 requires exact math pinned by incident date. PRD §14 names SLA changes as a risk, mitigated by a versioned catalog with source hashes and a periodic recheck. The hackathon catalog's hash is a placeholder that its test accepts; its exclusions and required fields differ from the published API Gateway SLA; and its calculator treats any imperfect interval as fully down and ignores the $1 minimum ([DISCOVERY.md](../discovery/DISCOVERY.md), difference 4).

**Decision:**
1. **Each contract version has two files.** One is a text snapshot of the terms as published, with its URL, the date it was read and the page's "last updated" date. The other is a structured file: commitment, measurement definition, credit tiers, minimum credit, claim deadline rule, required claim fields and exclusions.
2. **`source_hash` is the SHA-256 of the snapshot file.** A test recomputes it and fails on a mismatch or a placeholder. Hashing the live web page is rejected, because the page's surrounding markup changes even when the terms don't.
3. **Every structured field cites the snapshot clause it comes from.** Exclusions and required fields are taken from the snapshot, not paraphrased into new categories. Anything that needs interpretation (for example which errors count as AWS's) becomes a Q-xx.
4. **Versions never change in place.** A changed term is a new version with a new snapshot. Contracts are chosen by incident date (resolver logic ported per [ADR-002](ADR-002-new-repo-via-process.md)).
5. **A scheduled recheck** reads each published SLA, compares it with the latest snapshot, and opens a review when they differ. It never edits a contract by itself.
6. **The calculator implements each contract's own measurement definition and minimum credit.** For API Gateway that means averaging per-interval availability (an interval with no requests counts as 100%) and issuing no credit unless the amount exceeds $1. Exclusions are evaluated against evidence. One that can't be ruled out makes eligibility *unproven*, not eligible (PRD §6 branches).
7. **Which contracts ship first** is open question 3 (PRD §16), answered from interviews.

**Alternatives:**
- *Keep the YAML-only catalog and fill in the hash later.* Rejected: a hash with no stored snapshot proves nothing, and the hackathon's test shows how a placeholder survives.
- *Read SLA terms live at claim time.* Rejected: results would change with the page, and old claims couldn't be reproduced.
- *One calculator formula for every service.* Rejected: SLAs measure availability differently.

**Consequences:**
- Easier: any eligibility result can be reproduced from the contract version and the snapshot behind it.
- Harder: each new contract means transcribing and reviewing its terms; the recheck job has to be built and watched.
- We must now: make golden tests per contract from the published examples and edge cases (the $1 floor, empty intervals, the tier boundaries); plan the recheck job in Stage 3.
