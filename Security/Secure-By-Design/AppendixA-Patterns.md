# Appendix A: The Security Pattern Library

A reference table of core architectural patterns used throughout the series. For each pattern: what problem it solves, how it's implemented with free/open-source tooling, which CIA property it primarily protects, and which Part covers it in depth.

## Identity Federation

| Aspect | Detail |
|---|---|
| Problem solved | Avoids building and storing your own password/credential store; delegates authentication to a trusted, specialized identity provider. |
| Core mechanism | OAuth 2.0 / OpenID Connect (OIDC) — the app receives a signed token (JWT) asserting identity and claims, verified against the provider's public keys, never handling raw credentials itself. |
| Free/OSS implementation | Clerk (generous free tier), Auth0 (free tier), or fully self-hosted **Keycloak** (free, open-source, by Red Hat) for organizations wanting zero third-party dependency. GitHub Actions' own OIDC token issuance (used for keyless cosign signing in Part 5) is the same pattern applied to machine identity. |
| Primary CIA impact | Confidentiality (credentials never touch your infrastructure) + Integrity (signed, verifiable claims). |
| Series reference | Part 2 |

## Data Isolation

| Aspect | Detail |
|---|---|
| Problem solved | Prevents one tenant/customer/user from accessing another's data in a multi-tenant system, even given an application-layer bug. |
| Core mechanism | Layered: (1) application-layer tenant-scoped queries (WHERE org_id = ...), (2) database-layer Row-Level Security policies as an independent backstop, (3) at the extreme, physical isolation (separate database/schema per tenant) for the highest-sensitivity tenants. |
| Free/OSS implementation | Native Postgres RLS (`CREATE POLICY`), no additional tooling required. |
| Primary CIA impact | Confidentiality, with Integrity as a secondary benefit (prevents cross-tenant writes too). |
| Series reference | Part 2 |

## Input Validation

| Aspect | Detail |
|---|---|
| Problem solved | Stops malformed, oversized, or malicious input from reaching business logic, database queries, or rendered output. |
| Core mechanism | Schema-first parsing at every external input boundary (source in the taint-analysis model), rejecting anything that doesn't conform, before any sanitization/escaping is even needed downstream. |
| Free/OSS implementation | Zod (TypeScript), Pydantic (Python), Bean Validation (Java) — all free, open-source. Complemented by Semgrep taint-analysis rules (Part 3) that flag input reaching a sink without passing through validated types. |
| Primary CIA impact | Integrity (rejects malformed state changes) + Confidentiality (prevents injection-based data exposure). |
| Series reference | Parts 3 & 4 |

## Secret Orchestration

| Aspect | Detail |
|---|---|
| Problem solved | Prevents credentials, API keys, and encryption keys from being hardcoded, committed, or shared across environments with mismatched blast radius. |
| Core mechanism | Environment isolation (dev/staging/prod hold entirely distinct secrets), envelope encryption for data-at-rest keys, short-lived/rotated credentials wherever the consuming system supports it, and continuous scanning for accidental leakage. |
| Free/OSS implementation | GitHub Actions Environments (secret scoping + required reviewers), HashiCorp Vault OSS or Infisical (self-hosted secret management), Trufflehog (leak detection). |
| Primary CIA impact | Confidentiality primarily; Availability secondarily (a leaked credential that's rotated quickly limits downtime from forced revocation). |
| Series reference | Part 4 |

## Least Privilege Access

| Aspect | Detail |
|---|---|
| Problem solved | Limits the damage any single compromised identity (human or machine) can do. |
| Core mechanism | Fine-grained, scoped permissions (Part 2's requirePermission), least-privilege pipeline tokens (Part 5's scoped GITHUB_TOKEN), and time-bounded elevation rather than standing broad access. |
| Free/OSS implementation | Native RBAC in your identity provider, explicit `permissions:` blocks in GitHub Actions workflows, Postgres role grants scoped per service. |
| Primary CIA impact | Confidentiality + Integrity (bounds both read and write blast radius). |
| Series reference | Parts 1, 2 & 5 |

## Defense-in-Depth / Layered Validation

| Aspect | Detail |
|---|---|
| Problem solved | Ensures no single control's failure equals a full breach. |
| Core mechanism | Independent, redundant controls at different layers addressing the same risk — e.g., WAF (edge) + Zod validation (app) + parameterized queries (data layer) all independently mitigate injection. |
| Free/OSS implementation | ModSecurity + OWASP CRS (edge), Zod (app), Drizzle/parameterized queries (data layer) — see Parts 4 & 6. |
| Primary CIA impact | All three — the entire point of the pattern is resilience across CIA properties even under partial control failure. |
| Series reference | Parts 4 & 6 |

## Zero-Trust Service Identity

| Aspect | Detail |
|---|---|
| Problem solved | Prevents lateral movement inside a network perimeter once any single service is compromised. |
| Core mechanism | Cryptographic, short-lived, workload-bound identity (not IP-based trust) verified mutually on every hop. |
| Free/OSS implementation | Linkerd/Istio (service mesh auto-mTLS), SPIFFE/SPIRE (workload identity), step-ca (private CA). |
| Primary CIA impact | Confidentiality + Integrity of inter-service traffic; contains blast radius for Availability too (compromised service can't freely pivot to attack others). |
| Series reference | Part 6 |

## Policy-as-Code

| Aspect | Detail |
|---|---|
| Problem solved | Ensures infrastructure and pipeline configuration adhere to security standards automatically, without relying on manual review catching every violation. |
| Core mechanism | Machine-readable policy rules evaluated automatically against IaC plans, container builds, or admission requests — failing the pipeline on violation. |
| Free/OSS implementation | Open Policy Agent (OPA) + Rego + Conftest, Checkov, tfsec, OPA Gatekeeper (Kubernetes admission control). |
| Primary CIA impact | All three, by preventing entire classes of misconfiguration before deployment. |
| Series reference | Part 5 |

## Immutable Audit Trail

| Aspect | Detail |
|---|---|
| Problem solved | Answers "who did what, when" with evidence that survives even a compromised application, directly countering the Repudiation threat. |
| Core mechanism | Structured, append-only, centrally-shipped logs of every security-relevant decision (authz, admin actions, data exports), correlated by request ID across services. |
| Free/OSS implementation | Vector/Fluent Bit (shipping) + Loki/OpenSearch (storage/search) + Grafana (visualization/alerting). |
| Primary CIA impact | Integrity (of the historical record) supporting Confidentiality investigation and incident response. |
| Series reference | Part 7 |

## Assume-Breach Detection

| Aspect | Detail |
|---|---|
| Problem solved | Reduces time-to-detection and time-to-containment once preventive controls have already failed. |
| Core mechanism | Behavioral baselining plus rule-based alerting mapped explicitly to STRIDE categories, with automated response for high-confidence signals. |
| Free/OSS implementation | Wazuh (SIEM), Falco (runtime intrusion detection), Grafana Alerting. |
| Primary CIA impact | Availability + Confidentiality (faster containment limits both data exposure and service disruption). |
| Series reference | Part 7 |
