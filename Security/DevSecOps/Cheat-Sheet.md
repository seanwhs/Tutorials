# 🔒 SecureNotes DevSecOps — Pocket Cheat Sheet

---

## ⭐ The 4 Golden Rules (never break these)

| # | Rule | Defends |
|---|---|---|
| 1 | **Secrets in env vars / vault — never in code** | Secrets leak, Info disclosure |
| 2 | **Parameterized queries (`$1,$2`) — never string concat** | SQL injection (Tampering) |
| 3 | **Validate all input at the edge (Zod) before trusting it** | Info disclosure, Tampering |
| 4 | **Scope every query to the authenticated owner** | IDOR (Elevation of privilege) |

---

## 🎯 STRIDE → Defense (fast lookup)

| Threat | Defense (phase) |
|---|---|
| **S**poofing | JWT + bcrypt (P2) |
| **T**ampering | ownership checks + parameterized queries + signing (P2–4) |
| **R**epudiation | audit logging (P5) |
| **I**nfo disclosure | validation + generic errors + log redaction (P1/2/5) |
| **D**enial of service | rate limit + brute-force guard + body caps (P1/5) |
| **E**levation of privilege | ownership/role checks + non-root container (P2–4) |
| Supply chain | SCA + image scan + Cosign signing (P2/4) |
| Secrets leak | pre-commit + CI history scan + secret manager (P1/3) |

---

## 🏗️ The Pipeline at a Glance

```
DEVELOP        BUILD              PACKAGE            DEPLOY          RUN
(laptop)       (CI)               (CI)               (staging)      (prod)
──────────     ──────────────     ──────────────     ───────────    ────────────
pre-commit     SAST (Semgrep)     build image        verify sig     audit logging
IDE lint       SCA (npm/Trivy)    image scan(Trivy)  (cosign)       brute-force
gitleaks       secret history     Cosign sign        deploy by      anomaly detect
               IaC audit          DAST (ZAP)         DIGEST         compliance
               branch protect                                       Dependabot

◄──── cheap to fix ·············· DEFENSE IN DEPTH ·············· expensive ────►
       each ▶ is a GATE: a failure blocks progress to the next stage
```

---

## 🛠️ Tool → Job (who does what)

| Tool | Job |
|---|---|
| **ESLint** (+security) | IDE/CI SAST — dangerous code patterns |
| **Semgrep** | Deep SAST in CI |
| **gitleaks** | Secret scanning (pre-commit + full history) |
| **npm audit / Trivy** | SCA — vulnerable dependencies |
| **Trivy (image)** | OS + library CVEs in image layers |
| **Trivy / Checkov** | IaC & Dockerfile misconfig audit |
| **OWASP ZAP** | DAST — attack the running app |
| **Cosign / Sigstore** | Keyless image signing + verify |
| **bcrypt** | Password hashing (work factor 12) |
| **Zod** | Input + env-var validation |
| **Helmet** | Protective HTTP headers |
| **Pino** | Structured logging + redaction |
| **Dependabot** | Auto-PRs to fix vulnerable deps |

---

## 💻 Everyday Commands

### App lifecycle
```bash
npm run dev        # run locally (hot reload)
npm run build      # type-check + compile to dist/
npm start          # run compiled app
npm test           # run tests
npm run lint       # ESLint (SAST)
```

### Database (local)
```bash
docker compose up -d       # start PostgreSQL
docker compose ps          # check it's healthy
docker compose down        # stop it
```

### Docker image
```bash
docker build -t securenotes:local .
docker run --rm securenotes:local whoami   # should print "node", NOT root
docker images securenotes:local            # check size (~180MB, not 1GB+)
docker run --rm -p 3001:3000 \
  -e DATABASE_URL="postgres://securenotes:localdevpassword@host.docker.internal:5432/securenotes" \
  -e JWT_SECRET="dev-only-super-long-secret-change-me-in-production-1234" \
  securenotes:local
```

### Git flow (+ where guards fire)
```bash
git add .                        # → staging
git commit -m "msg"              # → history   🛡️ pre-commit hook fires HERE
git push                         # → GitHub    🛡️ CI pipeline fires HERE
git checkout -b my-branch        # new branch (safe experiments)
git checkout main                # switch back
git branch -D my-branch          # delete branch
git log --oneline                # view history
```

---

## 🔍 Run the Scanners Locally (before you push)

```bash
# SAST
semgrep --config p/security-audit --config p/typescript src/

# SCA
npm audit --audit-level=high
trivy fs --severity HIGH,CRITICAL .

# Secrets (whole history)
gitleaks detect --source . --no-banner

# IaC / Dockerfile misconfig
trivy config . --severity HIGH,CRITICAL
checkov -d . --framework terraform dockerfile

# Image scan
trivy image --severity HIGH,CRITICAL --vuln-type os,library securenotes:local

# DAST (app must be running)
docker run --rm --network host -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:3000 -a

# Verify image signature
cosign verify \
  --certificate-identity-regexp "https://github.com/<OWNER>/securenotes/.github/workflows/release.yml@.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/<OWNER>/securenotes@sha256:<DIGEST>
```

---

## 🌐 API Quick-Test (curl)

```bash
# Register → get token
TOKEN=$(curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"a@x.com","password":"supersecret123"}' \
  | node -pe 'JSON.parse(require("fs").readFileSync(0)).token')

# Create a note (auth required)
curl -s -X POST http://localhost:3000/notes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Hello","body":"world"}'

# List my notes
curl -s http://localhost:3000/notes -H "Authorization: Bearer $TOKEN"

# Health check
curl -s http://localhost:3000/health
```

---

## 🔢 HTTP Status Codes That Carry Security Meaning

| Code | Meaning | When |
|---|---|---|
| `200` | OK | successful read |
| `201` | Created | note created |
| `204` | No Content | note deleted |
| `400` | Bad Request | failed Zod validation |
| `401` | Unauthorized | **"who are you?"** — no/bad token |
| `403` | Forbidden | **"I know you, and no."** |
| `404` | Not Found | missing **or not yours** (hides existence) |
| `429` | Too Many Requests | rate limit / brute-force lockout |
| `500` | Server Error | generic msg only — never leak stack trace |

> **401 vs 403 vs 404:** 401 = unknown identity · 403 = known but denied · 404 = deliberately used for "not yours" to avoid confirming a resource exists (Info disclosure).

---

## 🧠 Concept Confusions — Settled

| A | vs | B |
|---|---|---|
| **AuthN** (who you are: login) | ≠ | **AuthZ** (what you can touch: ownership) |
| **Hashing** (one-way, no key) | ≠ | **Encryption** (reversible, has key) — *hash passwords* |
| **Image** (recipe, static) | ≠ | **Container** (meal, running) |
| **SAST** (your code) | ≠ | **SCA** (deps) ≠ **DAST** (running app) |
| **RASP** (inside app, has context) | ≠ | **WAF** (edge, generic) — complementary |
| **Tag** `:latest` (mutable) | ≠ | **Digest** `sha256:` (immutable) — *deploy by digest* |
| Pre-commit hook (bypassable) | ≠ | CI gate (un-skippable) — *use both* |

---

## 📋 CI / YAML Quick Rules

- **Jobs run in parallel; steps run in order.** Force sequence with `needs:`.
- **Gate mechanism = exit code:** `0` = pass, non-zero = fail.
- **Fail only on serious findings:** `severity: "HIGH,CRITICAL"` + `exit-code: "1"`.
- **Full-history scan needs** `fetch-depth: 0`.
- **Reproducible installs:** `npm ci` (not `npm install`).
- **Least privilege:** set `permissions:` to the minimum (`contents: read`).
- **YAML:** spaces not tabs · indentation = nesting · `-` = list item · `#` = comment.

---

## 📦 Vulnerability Triage (Phase 5 SLAs)

| Severity | CVSS | Fix by |
|---|---|---|
| CRITICAL | 9.0–10 | **24 hours** |
| HIGH | 7.0–8.9 | **7 days** |
| MEDIUM | 4.0–6.9 | 30 days |
| LOW/INFO | <4.0 | backlog |

**Triage flow:** verify it's real → assess exploitability (reachable in *our* usage?) → assign severity+owner+SLA → remediate (merge Dependabot PR / fix / accept-with-justification) → re-scan to verify.
**Any suppression needs:** CVE ID · reason · review date · owner.

---

## 🔑 CVE · CVSS · SBOM (in one line)

> **SBOM** (what you ship) → matched against **CVE** (known flaws) → ranked by **CVSS** (severity) → gated + triaged + auto-fixed (Dependabot).

- **CVE** = the flaw's unique ID (like an ISBN).
- **CVSS** = 0–10 severity score → the number your gates fire on.
- **SBOM** = ingredients label → answers "are we affected?" instantly.

---

## 🚨 Break-It-To-Prove-It (verify your guardrails)

| Plant this… | …and this guard catches it |
|---|---|
| Fake AWS key in a file → `git commit` | pre-commit gitleaks (commit aborted) |
| `eval(userInput)` → `npm run lint` | ESLint `no-eval` |
| `npm install lodash@4.17.11` → `npm audit` | SCA HIGH CVEs |
| Fetch another user's note | `404` (ownership isolation) |
| Terraform SG `0.0.0.0/0` → checkov | open-ingress finding |
| `cosign verify` wrong identity | verification fails |
| Request w/ `Authorization` header → check logs | field shows `[REDACTED]` |
| 6 failed logins + `UNION SELECT` body | `429` + `400` "suspicious pattern" |

---

## 🔐 Non-Negotiables (frame these)

1. **Shift left** — catch it on the laptop; ~10x cheaper than prod.
2. **Defense in depth** — assume any one control fails; stack them.
3. **Gates over advice** — a warning gets ignored; a blocked merge gets fixed.
4. **Eliminate dangerous secrets** — don't store passwords (hash), don't store signing keys (keyless), vault the rest.
5. **Keep developers fast** — low-noise, auto-fixing, frictionless controls are the ones that survive.
6. **Prove it** — signatures, SBOMs, audit logs, compliance reports = evidence, not vibes.
If you'd like, I can finish the whole package with a **top-level Table of Contents / reading-path index** that stitches every piece together into one navigable front page (with suggested paths for beginners vs. experienced readers). Want that last piece?
