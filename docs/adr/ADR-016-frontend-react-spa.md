# ADR-016: The frontend is a React and TypeScript single-page app, built with Vite and served as static files from CloudFront
Status: Accepted (decided in Stage 2a; product owner to review at G2)    Date: 2026-11-27

**Context:** M1 has a public, anonymous no-access check (J-01, R-33 – R-35) and signed-in screens for connection, reports, evidence and packets (J-02, J-03, J-08). M2 adds approval, case tracking, reconciliation and the ledger. Screens are designed in Claude Design and rebuilt by Cursor as production code ([PROCESS.md](../PROCESS.md) Stage 2 screens). The frontend must mock the backend from contracts (G2: "backend, frontend and agent can each mock the others"). Customer screens meet WCAG 2.2 AA in English (Q-29). Tokens stay out of JavaScript ([ADR-017](ADR-017-auth-cognito-oidc-bff.md)).

**Decision:**
1. **React with TypeScript (strict), built by Vite into static files.** Routing with React Router; server state with TanStack Query; forms validated with the same JSON Schemas the API publishes.
2. **One app, two areas:** the public check at `/check` (no sign-in) and the signed-in product. The P-06 operator console is a separate route tree at `/ops` that only operator sessions can load data for (server-side authorisation; the bundle holds no secrets).
3. **API client and types are generated from [openapi.yaml](../contracts/openapi.yaml).** Mock Service Worker serves the same contract's examples in component tests and local development, so frontend work doesn't wait on the backend.
4. **Hosting:** static files in a private S3 bucket behind CloudFront in Recoup's account; CloudFront routes `/api/*` to the `api` service, so the app and API share one origin and the session cookie stays first-party ([ADR-023](ADR-023-runtime-ecs-fargate.md)).
5. **Money is rendered by one component** that requires a stage and a source label (R-02). There is no way to render a bare number as money.
6. **No live stream (AG-UI) in v1.** Long jobs (reports, connection tests) are polled through their status endpoints; nothing is pushed.

**Alternatives:**
- *Next.js with server rendering.* Rejected: it adds a Node server to run and secure, for SEO the free check doesn't need (outreach brings prospects to it; search doesn't).
- *Server-rendered HTML from FastAPI (Jinja, HTMX).* Rejected, with low confidence: simpler to run, but the process expects a separate frontend built against contracts, and the M2 screens (approvals, ledger) have enough client state to justify React.
- *No framework.* Rejected: accessibility and form handling would be rebuilt by hand.

**Consequences:**
- Easier: the frontend can ship against mocks; hosting is cheap and has no server; one origin keeps cookies and CSP simple.
- Harder: a second toolchain (Node) in CI; generated types must be regenerated in the same PR as any contract change (a CI check fails on drift).
- We must now: pin versions in TECH_STACK.md (2b); add the drift check and an axe accessibility run to M0 CI.
