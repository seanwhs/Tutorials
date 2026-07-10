# Secure by Design — Part 4: Data Protection & Cryptography

## 1. Concept & Architecture Rationale

### Encryption is a layered decision, not a checkbox

"Is the data encrypted?" is the wrong question. The right question: encrypted **where**, **with whose keys**, and **against which threat**? There are three distinct zones to protect:

- **Data at rest** — database files on disk, backups, object storage. Threat: an attacker (or malicious insider) with filesystem/storage access but no application access.
- **Data in transit** — network hops between browser↔app, app↔database, app↔third-party API. Threat: network-level interception (covered in depth in Part 6's mTLS discussion).
- **Data in use** — decrypted values held in application memory during processing. Threat: memory dumps, debug logs accidentally capturing plaintext.

### Encryption-at-rest: platform-managed vs application-managed

Managed Postgres providers (Neon, RDS, Supabase) provide **transparent, platform-managed encryption-at-rest** by default (AES-256 on the underlying storage volume) — this protects against physical disk theft but does **not** protect against a compromised database credential or a SQL injection reading plaintext columns. For genuinely sensitive fields (SSNs, bank account numbers, health data) add **application-layer, column-level encryption** — the database itself never sees plaintext, so even a full database dump or an injection vulnerability yields only ciphertext.

### Secrets management via environment isolation

The free, zero-infrastructure baseline: never commit secrets, use per-environment isolation (dev/staging/production have distinct secrets, distinct database credentials, distinct API keys), and use a secrets manager rather than plaintext `.env` files in production. GitHub Actions Environments (free) provide exactly this: environment-scoped secrets with required reviewers before a deploy job can access production secrets.

### The OWASP Top 10, reframed as taint flows (continuing Part 3's model)

- **Injection (SQL/NoSQL/Command)**: untrusted input (source) reaches a query/command builder (sink) without parameterization (sanitizer).
- **SSRF (Server-Side Request Forgery)**: untrusted input (source) reaches an outbound HTTP request's URL/host (sink) without an allowlist (sanitizer) — allowing an attacker to make your server call internal-only endpoints (e.g., cloud metadata services).
- **XSS (Cross-Site Scripting)**: untrusted input (source) reaches rendered HTML (sink) without escaping/CSP (sanitizer/mitigating control).

## 2. Implementation

### Step 1 — Zod as your single input-validation choke point

Every external input — form submission, API request body, query param, webhook payload — must pass through a Zod schema before touching business logic. This is the concrete, code-level implementation of "sanitizer" in the taint model.

Schema example for an invoice creation endpoint, conceptually: `CreateInvoiceSchema` is a Zod object requiring `customerId` as a UUID string, `amountCents` as a positive integer (never trust floating point for money), `dueDate` as a coerced date that must be in the future, and `memo` as an optional string capped at 500 characters and stripped of any HTML tags via a `.transform()` step. Parsing untrusted input with `CreateInvoiceSchema.parse(rawBody)` inside the Server Action, before any database call, means malformed, oversized, or type-confused input never reaches your query layer at all — this single choke point defeats most naive Injection and business-logic-abuse attempts before they start.

### Step 2 — Parameterized queries as the Injection defense (Drizzle ORM example)

Drizzle ORM, like all reputable query builders, parameterizes by default when you use its query builder methods (`.where(eq(column, value))`) rather than raw template strings. The architectural rule to enforce via the Part 3 Semgrep custom rules: ban `` sql`...${rawUserInput}...` `` string interpolation entirely; require `sql.raw()` or template-tagged parameter binding for any case where raw SQL is unavoidable (e.g., dynamic column names in a reporting feature), and require an explicit allowlist of permitted column names rather than accepting an arbitrary string.

### Step 3 — SSRF defense: allowlist outbound destinations

For any server-side feature that fetches a URL derived from user input (e.g., "import from URL", webhook delivery, link preview generation), never fetch directly. Instead: resolve the hostname, reject if it resolves to a private/link-local/loopback IP range (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8, 169.254.0.0/16 — this last range is critical, as it covers cloud metadata endpoints like 169.254.169.254), reject non-HTTP(S) schemes, and only then perform the fetch — ideally through a dedicated, network-isolated egress proxy (a preview of Part 6's egress filtering) rather than directly from your main application's network context.

### Step 4 — XSS defense: escaping by default plus a strict CSP

React/Next.js escapes interpolated values by default — the risk concentrates entirely in explicit escape hatches: `dangerouslySetInnerHTML`, `eval`, and third-party libraries that inject raw HTML (rich text editors, markdown renderers). Any use of `dangerouslySetInnerHTML` must pass content through a sanitizer library (DOMPurify) first, with an explicit allowlist of permitted tags/attributes — never a denylist.

As a second, independent layer (Defense-in-Depth again), configure a strict Content-Security-Policy response header in your Next.js `next.config` headers function: `default-src` restricted to `'self'`, `script-src` restricted to `'self'` plus any explicitly trusted CDN origins with no `'unsafe-inline'` or `'unsafe-eval'`, `style-src` similarly restricted, `frame-ancestors` set to `'none'` to prevent clickjacking, and `object-src` set to `'none'`. Even if a sanitizer bypass or a compromised third-party script slips through, a well-configured CSP prevents it from executing or exfiltrating data — this is precisely the "WAF at the edge vs. sanitization in the app" layered-defense question from the syllabus: CSP is a browser-enforced, network-adjacent control that catches what application-layer sanitization misses, and neither replaces the other.

### Step 5 — Application-layer column encryption for sensitive fields

For fields requiring protection even from a database-level compromise: encrypt with AES-256-GCM at the application layer before writing, using a Data Encryption Key (DEK) that is itself encrypted by a Key Encryption Key (KEK) held in a secrets manager, never in application code or environment variables directly accessible to the app process at rest (this "envelope encryption" pattern is the same one AWS KMS/GCP KMS use, achievable with free/open-source primitives via libsodium or Node's built-in `crypto` module for smaller-scale systems). Store the ciphertext, the authentication tag, and the initialization vector (IV) alongside the row; decrypt only at the point of use, never in a logging statement.

### Step 6 — Secrets orchestration without a paid vault

Free-tier viable pattern: GitHub Actions Environments for CI/CD secrets (dev/staging/production each with isolated secret sets and, for production, required-reviewer approval gates before secrets are exposed to a deploy job); platform-native secret injection at runtime (Vercel Environment Variables scoped per-environment, never bundled into client code — enforce via the `NEXT_PUBLIC_` prefix convention audit: anything without that prefix must never be referenced from client components); and for anything requiring rotation or dynamic secrets beyond simple env vars, the free and open-source **HashiCorp Vault** (OSS edition) or **Infisical** (open-source secrets manager) self-hosted on a free-tier VM.

### Step 7 — Trufflehog as the last line of defense against secret leakage

Even with disciplined environment isolation, secrets leak into commits accidentally. Run Trufflehog (free, open-source) in CI on every PR — `trufflehog git file://. --since-commit HEAD~1 --only-verified` scans new commits for verified live credentials (it doesn't just pattern-match, it actively validates whether a found credential is still active), and should be a required status check alongside Semgrep and Dependency-Track from Part 3.

## 3. Exercise Challenge

1. Define a Zod schema for your most security-sensitive form (payment, account settings, or admin action) with explicit length caps, type coercion, and a `.transform()` sanitization step; wire it as the first line of the corresponding Server Action.
2. Audit every use of `dangerouslySetInnerHTML` in your codebase (grep for it); replace unsanitized instances with DOMPurify-sanitized output.
3. Configure a strict CSP header in your Next.js config and verify it in browser devtools (Network tab, response headers) — confirm inline scripts are blocked.
4. Identify one sensitive database column and implement application-layer AES-256-GCM envelope encryption for it.
5. Add Trufflehog as a required CI status check.

## 4. Solution & Explanation

The worked solution applies this to the QB Clone's customer PII fields (e.g., bank account numbers referenced in the Plaid integration): the `amountCents`-style Zod pattern is applied to every invoice/bill/payment input; the CSP header blocks any inline script injection attempt even if a future markdown-rendering feature for invoice memos has a sanitizer bug; bank account numbers are envelope-encrypted at the application layer before insertion, meaning the `postJournalEntry` function and reporting queries never need plaintext access, only masked/last-4-digit display values decrypted on demand at the UI boundary.

Why this is architecturally sound: encryption, validation, and CSP each defend against a **different** failure mode of the *same* underlying risk (sensitive data exposure) — a single bypassed control does not equal a breach, which is the definition of Defense-in-Depth applied to data protection specifically.

## 5. Key Takeaways

- Ask "encrypted where, with whose keys, against which threat" — not just "is it encrypted."
- Zod (or equivalent) at every external input boundary is your primary Injection/business-logic-abuse defense; parameterized queries are the second, independent layer.
- SSRF defense requires resolving and validating the destination IP range, not just the URL string — cloud metadata endpoints are the highest-value target.
- CSP and output sanitization are independent, complementary XSS defenses — CSP catches what sanitization misses.
- Envelope encryption (DEK encrypted by a KEK in a secrets manager) protects sensitive fields even from a full database compromise.
- Trufflehog closes the loop on secrets that leak into git history despite disciplined environment isolation.

Next: Part 5 — Infrastructure & Pipeline Security, where we sign container images, harden GitHub Actions runners, and scan Infrastructure-as-Code before it's ever applied.

