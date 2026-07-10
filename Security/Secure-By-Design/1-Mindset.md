# Secure by Design — Part 1: The Security-First Mindset

## 1. Concept & Architecture Rationale

### Why "Shift-Left"?

Every vulnerability found in production costs exponentially more to fix than one found at design time. The security-first mindset means asking "how does this fail, and who benefits from that failure?" during architecture review — not during incident response.

### The CIA Triad as a Design Lens

Every component you design should be evaluated against three properties:

- **Confidentiality** — Can an unauthorized party read this data? (encryption, access control, least privilege)
- **Integrity** — Can an unauthorized party modify this data or system state undetected? (signing, checksums, audit logs, immutability)
- **Availability** — Can an attacker deny legitimate access? (rate limiting, redundancy, circuit breakers)

A useful architecture review habit: for every new data flow diagram box and arrow, ask "which leg of CIA does this threaten, and what mitigates it?"

### Principle of Least Privilege (PoLP)

Every identity — human or machine — should hold the minimum permissions needed to perform its function, for the minimum time necessary. This applies to:

- Database roles (a reporting service should never hold `DELETE` on production tables)
- CI/CD tokens (a build job should not have write access to production secrets)
- IAM roles (a Lambda function should have one scoped role, not `AdministratorAccess`)

### STRIDE Threat Modeling

STRIDE is a mnemonic developed at Microsoft for categorizing threats during design review:

| Threat | Violates | Example |
|---|---|---|
| **S**poofing | Authentication | Attacker impersonates a user or service |
| **T**ampering | Integrity | Attacker modifies data in transit or at rest |
| **R**epudiation | Non-repudiation | User denies performing an action; no audit trail exists |
| **I**nformation Disclosure | Confidentiality | Sensitive data exposed to unauthorized parties |
| **D**enial of Service | Availability | Attacker exhausts resources, blocking legitimate use |
| **E**levation of Privilege | Authorization | Attacker gains capabilities beyond their grant |

## 2. Implementation: Running a STRIDE Threat Model

### Step 1 — Draw a Data Flow Diagram (DFD)

Use free tooling: **OWASP Threat Dragon** (open-source, web-based or desktop).

```bash
# Run OWASP Threat Dragon locally via Docker (fully open-source, no account needed for local mode)
docker run -p 3000:3000 owasp/threat-dragon:latest
```

Open `http://localhost:3000`, create a new threat model, and draw:
- **External entities** (rectangles): the end user, third-party APIs
- **Processes** (circles): your Next.js app, your API server
- **Data stores** (open rectangles): your Postgres database, your object storage
- **Trust boundaries** (dashed lines): the line between "internet" and "your VPC", between "app tier" and "data tier"

### Step 2 — Enumerate threats per element, per STRIDE category

Example for a "Login" process box:

```markdown
## Element: POST /api/login (Process)

- [S] Spoofing: Could an attacker submit credentials as someone else? 
      Mitigation: rate-limit by IP + account, require CAPTCHA after N failures.
- [T] Tampering: Could an attacker intercept and replay the request?
      Mitigation: enforce TLS 1.2+, HSTS, no HTTP fallback.
- [R] Repudiation: If an account is compromised, can we prove when/how?
      Mitigation: structured audit log of every auth event (success + failure) with IP, UA, timestamp.
- [I] Info Disclosure: Do error messages reveal whether an email exists?
      Mitigation: generic "invalid credentials" message for both wrong password AND unknown email.
- [D] DoS: Can an attacker lock out a legitimate user via failed attempts?
      Mitigation: exponential backoff per-account, not permanent lockout; CAPTCHA over hard lockout.
- [E] Elevation: Could a session token be reused to escalate privilege?
      Mitigation: short-lived access tokens, role claims re-verified server-side per request, not just at login.
```

### Step 3 — Score and prioritize with DREAD (optional refinement)

For each identified threat, score 1-3 on: **D**amage, **R**eproducibility, **E**xploitability, **A**ffected users, **D**iscoverability. Sum determines fix priority. This turns a qualitative list into a ranked backlog your team can actually act on.

### Step 4 — Codify the threat model as a living artifact

Store the Threat Dragon `.json` model file in the repo under `/security/threat-model.json`, and require it to be updated in the same PR that changes a trust boundary (new external API call, new data store, new auth flow). Enforce this via a lightweight CODEOWNERS rule:

```
# .github/CODEOWNERS
/security/ @security-team
/src/app/api/ @security-team
```

Any PR touching `/src/app/api/` requires sign-off from someone who will ask "did the threat model change?"

## 3. Setting Up a Security-Focused Git Workflow

### Branch protection (GitHub, free on public repos and available on private repos with GitHub Free for orgs with limits — core rules are free tier)

```bash
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["semgrep-scan", "dependency-review", "secret-scan"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null
}
EOF
```

### Enable GitHub's free native security features

```bash
# Enable secret scanning + push protection (free for public repos, 
# included in GitHub Advanced Security for private — but Dependabot + basic secret scanning are free)
gh api repos/:owner/:repo \
  --method PATCH \
  -f security_and_analysis[secret_scanning][status]=enabled \
  -f security_and_analysis[secret_scanning_push_protection][status]=enabled

# Enable Dependabot alerts + security updates
gh api repos/:owner/:repo \
  --method PATCH \
  -f security_and_analysis[dependabot_security_updates][status]=enabled
```

### Signed commits as an integrity control

```bash
# Generate a signing key (GPG) or use SSH signing (simpler, Git 2.34+)
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```

Require signed commits on `main` via branch protection (`required_signatures: true`). This directly mitigates the **Repudiation** threat: every commit is cryptographically attributable.

### Conventional, security-annotated commit messages

Adopt a lightweight convention so security-relevant changes are greppable in history:

```
feat(auth): add short-lived JWT rotation [SEC-42]
fix(api): sanitize markdown input to prevent stored XSS [SEC-51]
chore(deps): bump next 16.0.1 -> 16.0.3 (CVE-2025-XXXX)
```

## 4. Exercise Challenge

Take a system you are currently building (or the QB Clone / React19 tutorial app from your other notes, if you have one). Produce:

1. A DFD with at least 3 trust boundaries (browser↔app, app↔database, app↔third-party API).
2. A STRIDE table with at least one threat per category, with a concrete mitigation.
3. A `security/threat-model.json` Threat Dragon file committed to the repo.
4. Branch protection rules applied to `main` requiring at least one status check (even a placeholder CI job is fine for now — Part 3 will fill it with real SAST/SCA).

## 5. Solution & Explanation

A worked example against a minimal "Invoice SaaS" (same shape as the QB Clone project):

**Trust boundaries:**
- Boundary 1: Public internet ↔ Next.js edge (Vercel)
- Boundary 2: Next.js server functions ↔ Neon Postgres
- Boundary 3: App ↔ Clerk (identity provider, third-party)

**Highest-priority STRIDE finding:** Elevation of Privilege via Clerk Organization role trusted only on the client. **Mitigation:** every server action re-verifies `orgRole` server-side from Clerk's session claims (never trust a role passed from client state) — this becomes the concrete implementation topic of Part 2.

**Why this matters architecturally:** the threat model didn't just find a bug — it justified an architectural rule ("always re-verify role server-side") that Part 2 will bake into a reusable `requireRole()` guard used by every Server Action and API route in the system. This is the essence of Shift-Left: the design decision made here in Part 1 prevents an entire class of bugs before a single line of RBAC code is written.

## 6. Key Takeaways

- Security is a design property, not a QA checklist — model threats before writing implementation code.
- CIA Triad + STRIDE gives you a repeatable, teachable vocabulary for architecture reviews.
- Git workflow itself is an attack surface: branch protection, signed commits, and native GitHub security features (secret scanning, Dependabot) are free, zero-infrastructure first steps.
- Every threat model finding should produce either a concrete mitigation or an explicit, documented risk acceptance — "we noticed and chose not to fix" is a valid, auditable outcome; silence is not.

Next: **Part 2 — Identity & Access Orchestration**, where we implement the `requireRole()` server-side guard this threat model demanded, design short-lived token flows, and secure API boundaries end-to-end.
