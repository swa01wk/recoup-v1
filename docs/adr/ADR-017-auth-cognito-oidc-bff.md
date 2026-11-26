# ADR-017: Sign-in uses Amazon Cognito user pools with required TOTP MFA; the API runs the OIDC flow and issues its own session cookie; roles live in Recoup's database
Status: Accepted (decision delegated by the product owner under Q-18)    Date: 2026-11-27

**Context:** [Q-18](../product/QUESTIONS.md#q-18-users-roles-and-sign-in--decided) decided named users per tenant, each signing in individually with MFA, holding one role (approver, contributor, viewer), and delegated the provider choice to Stage 2 with an ADR. R-38 and R-56 need every action attributed to a user and only approvers able to approve. The project rules list auth as expensive to reverse. Constraints: AWS only for v1; all data in us-west-2 ([ADR-012](ADR-012-hosting-region-us-west-2.md)); the free check (J-01) needs no sign-in (Q-31). P-06 sees the catalog and public incidents, never tenant data (Q-32).

AWS facts (read 2026-11-27):
- When a user pool requires MFA, every user must set up and complete an MFA factor to sign in, and managed login prompts them to set it up ([Adding MFA](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa.html)).
- MFA can't be required in a pool that allows passkeys or one-time-password first factors ([same page](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa.html)).
- Managed login needs the Essentials plan or higher ([feature plans](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-sign-in-feature-plans.html)); TOTP is supported with managed login ([TOTP MFA](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa-totp.html)).

**Decision:**
1. **Identity provider: Amazon Cognito user pools in us-west-2, Essentials plan, managed login.**
   - **Customer pool:** email and password, MFA **required**, TOTP authenticator apps only (no SMS: SIM-swap risk, plus SMS sending cost and setup). No social sign-in. No passkeys, since Cognito won't require MFA alongside them.
   - **Operator pool:** a separate pool for P-06, same MFA rule, sign-up disabled. Operator users can't sign in to tenant routes, and customer users can't sign in to `/ops`.
2. **Authentication only.** Cognito proves who the user is (the `sub`). **Tenant membership and role live in Recoup's database** (`tenant_member`), checked by the control plane on every request. Cognito groups aren't used for authorisation, so changing provider later touches sign-in only.
3. **Backend-for-frontend session.** The `api` runs the OIDC authorisation-code flow with PKCE against Cognito, validates the ID token, and sets its own `HttpOnly; Secure; SameSite=Lax` session cookie whose session ID is stored server-side in PostgreSQL. Cognito tokens never reach browser JavaScript. State-changing requests also need a custom header (`X-Recoup-CSRF`) that matches the session (CSRF defence).
4. **Sessions:** idle timeout 30 minutes, absolute lifetime 12 hours, revoked on sign-out, on membership removal and on role change. Approvals check that the session completed MFA (`amr` claim) less than 12 hours ago.
5. **Anonymous free check:** no Cognito session. A random anonymous session ID in a first-party cookie ties funnel events together (Q-31, R-35). It's linked to a tenant only if that visitor later signs up.
6. **Who manages members** is a gap, raised as [Q-36](../product/QUESTIONS.md#q-36-who-creates-a-tenant-and-manages-its-members--open-assumption-a-36). Until it's answered, the design builds on A-36: the first user creates the tenant and becomes its approver, and approvers invite members and change roles.

**Alternatives:**
- *Auth0, Clerk or WorkOS.* Rejected for v1: better enterprise SSO, but they add a second vendor that holds identities, outside AWS and possibly outside us-west-2. Revisit if a design partner requires SAML SSO; Cognito supports SAML too, so that alone doesn't force a move.
- *Our own password and MFA store.* Rejected: we'd own credential storage, reset and lockout.
- *Tokens in the SPA (implicit or code flow in the browser).* Rejected: tokens readable by JavaScript widen the impact of any XSS.
- *Roles as Cognito groups.* Rejected: it splits authorisation between Cognito and the database, and ties role logic to the provider.

**Consequences:**
- Easier: MFA and credential handling are managed; identities stay in us-west-2; authorisation is one table the control plane owns.
- Harder: we own the session table and the CSRF check; TOTP-only means some users need an authenticator app; Essentials is a paid tier (cost in TECH_STACK.md).
- We must now: in SECURITY.md (2b), write the auth threats and session rules; in M0, an auth skeleton spec with tests for required MFA, cross-pool rejection and role checks (R-38, R-56); answer Q-36.
