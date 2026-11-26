# ADR-011: v1 uses no language model; the PRD §9 agent steps are deferred and no model provider is chosen
Status: Accepted (decision delegated by the product owner)    Date: 2026-11-27

**Context:** PRD §9 lists three L3 agent steps: incident windows from postmortems, the claim narrative, and denial-reason capture. The first two sit in J-03 (M1). PRD §9 and PROCESS.md golden rule 2 say to start deterministic. Any model needs a provider choice (the product owner's call, expensive to reverse), an agent harness, evals and agent threat work, all before M1. M1 is a free check whose value depends on being correct and honest. Raised as [QUESTIONS.md](../product/QUESTIONS.md) Q-21.

**Decision:**
1. **No model in M0, M1 or M2.** R-49, R-50 and R-51 stay *Could*, after M2.
2. **Incident windows** come from Health event start and end times, or are entered or confirmed by P-02.
3. **The claim narrative** is a per-contract template filled only from verified claim fields (R-28).
4. **Denial reasons** (M2) are picked by P-01 from a fixed list. The pasted AWS case text is stored as untrusted data (NFR-09).
5. **No model provider is chosen.** Adding a model later needs a new ADR, a provider decision by the product owner, an eval set (NFR-13) and the agent architecture from PROCESS.md.
6. **When to revisit:** if pilot partners report KPI-08 above 30 minutes and most of that time goes on reading postmortems or writing claim text.

**Alternatives:**
- *Ship the claim-narrative agent in M1.* Rejected: a template gives the same packet with no hallucination risk, and AWS asks for fixed fields, not prose.
- *Ship the incident-window agent in M1.* Rejected: Health events already give windows for the common case, and customer confirmation is needed either way.

**Consequences:**
- Easier: Stage 2 doesn't need a model provider, model routing or prompt-injection defences for model context. Every result is reproducible.
- Harder: P-02 enters windows by hand when Health has no event; the "agentic" parts of PROCESS.md mostly don't apply yet.
- We must now: in Stage 2, write AGENT_ARCHITECTURE.md as "no agent workflows in v1", stating the gate for adding one; in Stage 3, mark the agent-only M0 items (harness with fake model, live eval runner, the agent-specific conformance scenarios) as not applicable, with this ADR as the reason. Keep the parts every workflow needs: state machine, approvals, outbox, audit.
