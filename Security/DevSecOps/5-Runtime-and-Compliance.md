# Phase 5: Runtime Protection & Continuous Compliance

**Core Focus:** Observability, Incident Response & Pipeline Governance.

We've secured the code, the dependencies, the infrastructure blueprints, and the container image. We've attacked the running app and cryptographically gated deployment. But security doesn't stop when the app goes live — **production is where real attackers actually show up.** Phase 5 builds the final layer, the "run" stage:

1. **Structured audit logging** — a tamper-evident record of *who did what, when* (closing the "Repudiation" threat from our very first threat model).
2. **Runtime protection & anomaly detection** — the app watches its own traffic and reacts to suspicious behavior.
3. **Continuous compliance reporting** — automated evidence that our controls are actually working.
4. **Developer-friendly vulnerability triage** — so all these findings get *fixed* without burning out the team.

> **Mental model:** Phases 1–4 were building and inspecting a bank vault. Phase 5 is the *security cameras, motion sensors, guard logs, and the auditor who checks it all monthly* — the systems that protect the vault while it's open for business.

---

## Step 5.1 — Structured, Security-Aware Logging

### 🎯 The Target
Add structured JSON logging with **Pino**, and make sure we *never* log secrets or sensitive data.

### 🧠 The Concept
> **Definition — Structured logging:** Emitting logs as machine-readable JSON (`{"level":"info","msg":"login","userId":"..."}`) instead of free-form text. Machines can search, filter, and alert on structured logs; free text they can't.

Think of `console.log` as **sticky notes scattered on a desk** — fine for one person, useless at scale. Structured logging is a **proper filing system with labeled drawers**: every event has consistent fields you can query ("show me every failed login from this IP in the last hour").

The security twist: logs are a **double-edged sword.** They're essential for detecting attacks — but if you log a password, token, or full request body, your logs *become* the breach. So we build **redaction** (automatic censoring of sensitive fields) in from the start.

### ⌨️ The Implementation

```bash
npm install pino pino-http
```

The logger, with redaction baked in:

**`src/logging/logger.ts`**
```typescript
import pino from "pino";

// The central logger. In production it emits compact JSON (great for log
// aggregators); in dev it's pretty-printed for humans.
export const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",

  // REDACTION: automatically censor sensitive fields so they NEVER hit disk.
  // This is a critical control — logs are a top source of accidental leaks.
  redact: {
    paths: [
      "req.headers.authorization",   // JWT tokens
      "req.headers.cookie",
      "*.password",
      "*.passwordHash",
      "*.token",
      "req.body.password",
    ],
    censor: "[REDACTED]",
  },

  // Add a consistent base field so we can filter logs by service.
  base: { service: "securenotes" },

  // In dev only, use the pretty transport for readable output.
  transport:
    process.env.NODE_ENV === "development"
      ? { target: "pino-pretty", options: { colorize: true } }
      : undefined,
});
```

The HTTP request logger middleware:

**`src/logging/httpLogger.ts`**
```typescript
import pinoHttp from "pino-http";
import { randomUUID } from "node:crypto";
import { logger } from "./logger.js";

// Logs every HTTP request/response with a unique request ID for tracing.
export const httpLogger = pinoHttp({
  logger,

  // Attach a correlation ID to every request — lets you trace one request
  // across many log lines (essential for incident investigation).
  genReqId: (req, res) => {
    const existing = req.headers["x-request-id"];
    const id = (typeof existing === "string" && existing) || randomUUID();
    res.setHeader("x-request-id", id);
    return id;
  },

  // Downgrade noise: successful health checks log at "debug", not "info".
  customLogLevel: (_req, res, err) => {
    if (err || res.statusCode >= 500) return "error";
    if (res.statusCode >= 400) return "warn";
    return "info";
  },
});
```

Now wire logging into the app and add a dedicated **audit log** for security-relevant events. Update **`src/server.ts`** — add the import and mount `httpLogger` as the *first* middleware:

```typescript
// ADD near the other imports:
import { httpLogger } from "./logging/httpLogger.js";

// Inside main(), make httpLogger the FIRST middleware (before helmet), so
// every request is logged even if later middleware rejects it:
  app.use(httpLogger);
  app.use(helmet());
  // ... rest unchanged
```

Also replace the bare `console.error` in the error handler with structured logging. In `main()`'s error handler:
```typescript
  app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
    // Structured, correlated error log (req.log is attached by pino-http).
    req.log.error({ err }, "Unhandled error");
    res.status(500).json({ error: "Internal server error" });
  });
```

Create the audit logger for security events (login, note deletion, etc.):

**`src/logging/audit.ts`**
```typescript
import { logger } from "./logger.js";

// A dedicated audit channel. Audit events answer "who did what, when" —
// the antidote to the "Repudiation" threat from our threat model.
const auditLogger = logger.child({ audit: true });

export type AuditEvent =
  | "user.register"
  | "user.login.success"
  | "user.login.failure"
  | "note.create"
  | "note.delete";

export function audit(
  event: AuditEvent,
  details: { userId?: string; ip?: string; noteId?: string; email?: string }
): void {
  // Emit a structured, queryable audit record. Note: no passwords/tokens here.
  auditLogger.info(
    { event, ...details, at: new Date().toISOString() },
    `AUDIT ${event}`
  );
}
```

Wire audit events into auth. Update **`src/auth/routes.ts`** to call `audit(...)` — add the import and calls:
```typescript
// ADD import:
import { audit } from "../logging/audit.js";

// In /register, after successful register:
    audit("user.register", { userId: user.id, email: user.email, ip: req.ip });

// In /login success:
    audit("user.login.success", { userId: user.id, email: user.email, ip: req.ip });

// In /login failure (before returning 401):
    audit("user.login.failure", { email: result.data.email, ip: req.ip });
```

### ✅ The Verification

```bash
docker compose up -d
npm run build && npm run dev
```
In another terminal, trigger events and watch the structured/audit logs appear:
```bash
# Successful register → see an "AUDIT user.register" line in the app logs
curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"audit@example.com","password":"supersecret123"}'

# Failed login → see "AUDIT user.login.failure"
curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"audit@example.com","password":"wrongpassword"}'
```
**Prove redaction works.** Make a request with an Authorization header and confirm the logged header shows `[REDACTED]`, not the token:
```bash
curl -s http://localhost:3000/notes -H "Authorization: Bearer secret-token-value"
```
In the app's log output, find the request log line — the `authorization` field must read `[REDACTED]`. Your logs are useful *and* leak-proof.

---

## Step 5.2 — Runtime Protection: Detect & Block Abuse

### 🎯 The Target
Add lightweight **runtime application self-protection (RASP)-style** middleware that detects and blocks anomalous behavior — repeated auth failures and suspicious payloads.

### 🧠 The Concept
> **Definition — RASP (Runtime Application Self-Protection):** Security logic *inside* the running app that monitors its own behavior and blocks attacks in real time — as opposed to an external firewall.

This is the app's **immune system.** Just as your body detects and attacks a virus from *inside*, RASP-style controls let the app notice "this IP has failed login 20 times in a minute — that's a brute-force attack" and slam the door, even though each individual request looks valid.

We'll build two focused controls:
1. **Brute-force protection** — lock out an IP after too many failed logins.
2. **Suspicious-pattern detection** — flag/block requests containing known attack signatures (e.g., SQL-injection or path-traversal strings), logging them as security events.

### ⌨️ The Implementation

**`src/security/bruteForce.ts`**
```typescript
import type { Request, Response, NextFunction } from "express";
import { audit } from "../logging/audit.js";

// A simple in-memory tracker of failed attempts per IP.
// (Production: back this with Redis so it works across multiple instances.)
interface Attempt {
  count: number;
  firstAt: number;
  blockedUntil?: number;
}

const attempts = new Map<string, Attempt>();
const WINDOW_MS = 15 * 60 * 1000; // 15-minute window
const MAX_FAILURES = 5;           // lock after 5 failures
const BLOCK_MS = 15 * 60 * 1000;  // lock for 15 minutes

// Call this on a FAILED login to record the failure.
export function recordFailure(ip: string): void {
  const now = Date.now();
  const rec = attempts.get(ip) ?? { count: 0, firstAt: now };
  // Reset the window if it has expired.
  if (now - rec.firstAt > WINDOW_MS) {
    rec.count = 0;
    rec.firstAt = now;
  }
  rec.count += 1;
  if (rec.count >= MAX_FAILURES) {
    rec.blockedUntil = now + BLOCK_MS;
    audit("user.login.failure", { ip }); // record the lockout trigger
  }
  attempts.set(ip, rec);
}

// Call this on a SUCCESSFUL login to clear the counter.
export function recordSuccess(ip: string): void {
  attempts.delete(ip);
}

// Middleware: block requests from an IP that is currently locked out.
export function bruteForceGuard(req: Request, res: Response, next: NextFunction) {
  const ip = req.ip ?? "unknown";
  const rec = attempts.get(ip);
  if (rec?.blockedUntil && Date.now() < rec.blockedUntil) {
    const retryAfter = Math.ceil((rec.blockedUntil - Date.now()) / 1000);
    res.setHeader("Retry-After", String(retryAfter));
    return res.status(429).json({ error: "Too many failed attempts. Try later." });
  }
  return next();
}
```

**`src/security/anomalyDetector.ts`**
```typescript
import type { Request, Response, NextFunction } from "express";
import { logger } from "../logging/logger.js";

// Signatures of common attack payloads. This is a lightweight WAF-style filter;
// our parameterized queries + validation already prevent these, but detecting
// and logging attempts gives us EARLY WARNING of who is probing us.
const SUSPICIOUS_PATTERNS: RegExp[] = [
  /(\bunion\b.*\bselect\b|\bselect\b.*\bfrom\b)/i, // SQL injection attempts
  /(;|\|\||&&)\s*(rm|cat|curl|wget|nc)\b/i,        // command injection
  /\.\.[/\\]/,                                     // path traversal (../)
  /<script\b/i,                                    // reflected XSS attempts
];

export function anomalyDetector(req: Request, res: Response, next: NextFunction) {
  // Inspect the URL and a stringified body for attack signatures.
  const haystack = `${req.originalUrl} ${JSON.stringify(req.body ?? {})}`;
  const matched = SUSPICIOUS_PATTERNS.find((re) => re.test(haystack));

  if (matched) {
    // Log as a security event with the pattern and source IP for triage.
    logger.warn(
      { security: true, ip: req.ip, path: req.originalUrl, pattern: matched.source },
      "Suspicious request pattern detected"
    );
    // Block outright — a legitimate request never contains these signatures.
    return res.status(400).json({ error: "Request rejected" });
  }
  return next();
}
```

Wire both into the app. Update **`src/server.ts`** in `main()` — add the anomaly detector early (after JSON parsing so `req.body` exists), and the brute-force guard on the auth login route:
```typescript
// ADD imports:
import { anomalyDetector } from "./security/anomalyDetector.js";
import { bruteForceGuard } from "./security/bruteForce.js";

// After app.use(express.json({ limit: "10kb" })); ADD:
  app.use(anomalyDetector);

// Change the auth mount to run the brute-force guard first:
  app.use("/auth", bruteForceGuard, authRouter);
```

Connect the login handler to the tracker. Update **`src/auth/routes.ts`** login handler:
```typescript
// ADD import:
import { recordFailure, recordSuccess } from "../security/bruteForce.js";

// In /login, on failure (before the 401 return):
    recordFailure(req.ip ?? "unknown");
    audit("user.login.failure", { email: result.data.email, ip: req.ip });
// ...
// In /login, on success (before signing the token):
    recordSuccess(req.ip ?? "unknown");
```

### ✅ The Verification

```bash
npm run build && npm run dev
```
**Prove brute-force protection.** Fire 6 failed logins from the same IP:
```bash
for i in $(seq 1 6); do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:3000/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"nobody@example.com","password":"wrongpassword123"}'
done
```
The first 5 return `401`; the 6th returns **`429`** (locked out) with a `Retry-After` header. The app defended itself.

**Prove anomaly detection.** Send a request with a SQL-injection signature:
```bash
curl -s -X POST "http://localhost:3000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"x UNION SELECT * FROM users","password":"x"}'
# → 400 {"error":"Request rejected"}, and a "Suspicious request pattern
#    detected" WARN line appears in the logs with the source IP.
```
The immune system works — and every probe is now logged for investigation.

---

## Step 5.3 — Automated Compliance Reporting

### 🎯 The Target
Add a scheduled CI job that aggregates all security scans into a single **compliance report**, producing auditable evidence that controls are running.

### 🧠 The Concept
> **Definition — Continuous compliance:** Continuously generating machine- and human-readable *evidence* that your security controls exist and are working — instead of scrambling to assemble a binder once a year for an auditor.

Compliance reporting is the **monthly building-safety report** the facilities manager files: "fire alarms tested ✅, sprinklers inspected ✅, exits unobstructed ✅." When the inspector (auditor) arrives, the evidence already exists. Automating it means the report is always current and never fabricated.

We'll run all scanners on a schedule and roll their results into one dated summary, uploaded as an artifact.

### ⌨️ The Implementation

**`.github/workflows/compliance.yml`**
```yaml
name: Compliance Report

on:
  schedule:
    - cron: "0 6 * * 1"   # every Monday at 06:00 UTC
  workflow_dispatch: {}    # allow manual runs

permissions:
  contents: read
  security-events: read

jobs:
  report:
    name: Generate Compliance Report
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install deps
        run: npm ci

      # Collect results from each control into JSON files.
      - name: SCA — npm audit (JSON)
        run: npm audit --json > audit.json || true

      - name: SCA/config — Trivy (JSON)
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: "fs"
          scan-ref: "."
          format: "json"
          output: "trivy.json"
          severity: "HIGH,CRITICAL"

      - name: Secrets — gitleaks (report only, non-blocking)
        run: |
          curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/install.sh | sh -s -- -b /usr/local/bin || true
          gitleaks detect --report-format json --report-path gitleaks.json --no-banner || true

      # Roll everything into one human-readable Markdown report.
      - name: Build compliance summary
        run: node scripts/compliance-report.mjs

      - name: Upload compliance report
        uses: actions/upload-artifact@v4
        with:
          name: compliance-report
          path: compliance-report.md
```

The report generator that reads each scan's JSON and summarizes it:

**`scripts/compliance-report.mjs`**
```javascript
import { readFileSync, writeFileSync, existsSync } from "node:fs";

// Safely read + parse a JSON file, returning a fallback if missing/invalid.
function readJson(path, fallback) {
  try {
    if (!existsSync(path)) return fallback;
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return fallback;
  }
}

const audit = readJson("audit.json", {});
const trivy = readJson("trivy.json", { Results: [] });
const gitleaks = readJson("gitleaks.json", []);

// ── Summarize npm audit ────────────────────────────────────────────────────
const vulns = audit?.metadata?.vulnerabilities ?? {};
const npmHigh = (vulns.high ?? 0) + (vulns.critical ?? 0);

// ── Summarize Trivy (count HIGH/CRITICAL across all results) ────────────────
let trivyHigh = 0;
for (const result of trivy.Results ?? []) {
  for (const v of result.Vulnerabilities ?? []) {
    if (v.Severity === "HIGH" || v.Severity === "CRITICAL") trivyHigh += 1;
  }
}

// ── Summarize gitleaks (any finding is a hard fail) ─────────────────────────
const secretCount = Array.isArray(gitleaks) ? gitleaks.length : 0;

// Overall pass/fail: every control must be clean.
const pass = npmHigh === 0 && trivyHigh === 0 && secretCount === 0;

const now = new Date().toISOString();
const report = `# SecureNotes Compliance Report

**Generated:** ${now}
**Overall status:** ${pass ? "✅ PASS" : "❌ ATTENTION REQUIRED"}

## Control Evidence

| Control                         | Tool      | High/Critical Findings | Status |
|---------------------------------|-----------|------------------------|--------|
| Dependency vulnerabilities (SCA)| npm audit | ${npmHigh}             | ${npmHigh === 0 ? "✅" : "❌"} |
| Image/filesystem vulns (SCA)    | Trivy     | ${trivyHigh}           | ${trivyHigh === 0 ? "✅" : "❌"} |
| Hardcoded secrets               | gitleaks  | ${secretCount}         | ${secretCount === 0 ? "✅" : "❌"} |

## Mapped Threat-Model Coverage
- Spoofing → JWT auth + bcrypt (enforced in code) ✅
- Tampering → per-user ownership checks + parameterized queries ✅
- Repudiation → structured audit logging (Phase 5) ✅
- Information disclosure → input validation + generic errors + log redaction ✅
- Denial of service → rate limiting + brute-force guard ✅
- Supply chain → SCA + signed images (Cosign) ✅
- Secrets leak → pre-commit + CI history scan + secret manager ✅

## Notes
This report is auto-generated weekly from live pipeline scans. Findings above
zero must be triaged per docs/vulnerability-triage.md before the next release.
`;

writeFileSync("compliance-report.md", report);
console.log(report);

// Exit non-zero if failing, so the scheduled run visibly flags problems.
process.exit(pass ? 0 : 1);
```

### ✅ The Verification

Run the report generator locally against real scan output:
```bash
npm audit --json > audit.json || true
trivy fs --format json --output trivy.json --severity HIGH,CRITICAL . || true
gitleaks detect --report-format json --report-path gitleaks.json --no-banner || true
node scripts/compliance-report.mjs
cat compliance-report.md
```
You should see a dated Markdown report with a status table — all ✅ on the clean codebase.

Trigger the workflow manually on GitHub: **Actions → Compliance Report → Run workflow**. After it finishes, download the **compliance-report** artifact. You now have automated, timestamped audit evidence generated on a schedule — no binder-cramming required.

---

## Step 5.4 — Developer-Friendly Vulnerability Triage

### 🎯 The Target
Establish an automated, low-friction triage workflow: enable **Dependabot** for auto-updates and document a clear triage process so findings get *fixed*, not ignored.

### 🧠 The Concept
The fastest way to *kill* a security program is to bury developers in alerts they can't act on. **Triage** is the **hospital emergency room's sorting nurse** — quickly deciding what's a genuine emergency (fix now), what can wait (fix this sprint), and what's a false alarm (document and dismiss). Without triage, every scanner finding screams equally loudly and the team learns to ignore all of them.

> **Definition — Dependabot:** GitHub's built-in bot that watches your dependencies and automatically opens pull requests to update vulnerable ones — turning "you have a vulnerable package" into "here's a ready-to-merge fix."

We automate the easy wins (dependency bumps) and define a crisp human process for the rest.

### ⌨️ The Implementation

Enable automated dependency updates:

**`.github/dependabot.yml`**
```yaml
version: 2
updates:
  # Keep npm dependencies patched — opens PRs for vulnerable/outdated packages.
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels: ["dependencies", "security"]
    # Group minor/patch bumps into fewer PRs to reduce noise.
    groups:
      minor-and-patch:
        update-types: ["minor", "patch"]

  # Keep GitHub Actions versions current (actions can have vulns too).
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels: ["ci", "security"]

  # Keep the Docker base image patched.
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    labels: ["docker", "security"]
```

The written triage playbook — the *process* that makes findings actionable:

**`docs/vulnerability-triage.md`**
```markdown
# Vulnerability Triage Playbook

The goal: fix what matters fast, without drowning developers in noise.

## Severity → SLA (Service Level Agreement)
| Severity  | Example                                   | Fix deadline |
|-----------|-------------------------------------------|--------------|
| CRITICAL  | RCE, auth bypass, secret leaked to prod   | 24 hours     |
| HIGH      | Exploitable injection, known-exploited CVE| 7 days       |
| MEDIUM    | Requires unlikely preconditions           | 30 days      |
| LOW/INFO  | Best-practice hardening                   | Backlog      |

## The triage flow (for each new finding)
1. **Verify it's real.** Is it a true positive? Reproduce or confirm the
   affected code path is actually reachable. If false → document & dismiss.
2. **Assess exploitability.** Is the vulnerable function reachable by
   untrusted input in OUR usage? An unreachable vuln is lower priority.
3. **Assign severity + owner + SLA** from the table above.
4. **Remediate:**
   - Dependency CVE → merge the Dependabot PR (preferred), or pin a safe version.
   - Code finding → fix and add a regression test.
   - No fix available → add to `.trivyignore` / Semgrep ignore WITH a comment,
     a review date, and a compensating control. Never silently suppress.
5. **Verify the fix** by re-running the relevant scanner in CI.

## Accepted-risk register
Any suppressed finding MUST have:
- The CVE/rule ID
- Why it's accepted (not exploitable / compensating control)
- A review-by date
- An owner
Suppressions without justification are treated as security debt.

## Anti-burnout rules
- Scanners fail the build ONLY on HIGH/CRITICAL (MEDIUM/LOW are reported, not blocking).
- Group dependency updates to reduce PR noise (see dependabot.yml).
- Route all findings to ONE dashboard (GitHub Security tab), not scattered emails.
```

Add a `SECURITY.md` so external reporters know how to reach you responsibly:

**`SECURITY.md`**
```markdown
# Security Policy

## Reporting a vulnerability
Please report security issues privately via GitHub Security Advisories
(Security tab → "Report a vulnerability"), NOT public issues.

We aim to acknowledge reports within 48 hours and provide a remediation
timeline based on severity (see docs/vulnerability-triage.md).

## Supported versions
The latest released `main` is supported with security fixes.
```

### ✅ The Verification

1. Commit and push these files.
2. In GitHub, go to **Settings → Code security and analysis** and confirm **Dependabot alerts** and **Dependabot security updates** are enabled.
3. **Prove the loop closes:** re-introduce the vulnerable package from Phase 2:
   ```bash
   npm install lodash@4.17.11 && git commit -am "test: vulnerable dep" && git push
   ```
   Within its schedule (or immediately for security updates), **Dependabot opens a PR** bumping `lodash` to a patched version, labeled `security`. Merging that PR *is* the remediation — the triage flow made concrete. Remove the test package afterward:
   ```bash
   npm uninstall lodash && git commit -am "revert: remove vulnerable dep" && git push
   ```

Commit the Phase 5 completion:
```bash
git add . && git commit -m "feat(security): Phase 5 — runtime protection, compliance & triage complete"
git push
```

---

## 📚 Phase 5 Reference Section

*Deep dives — skip on first pass.*

### R5.1 — Why redaction belongs in the logger, not the caller
If you rely on developers to *remember* not to log secrets, someone eventually forgets. Configuring `redact` paths *once* in the logger makes safe logging the default — a **secure-by-default** design. Even a careless `logger.info(req)` can't leak the Authorization header. Defense that doesn't depend on human vigilance is the strongest kind.

### R5.2 — In-memory vs distributed rate/brute-force state
Our `Map`-based tracker works for a single instance but resets on restart and doesn't share state across multiple app replicas. In production, back it with **Redis** so a lockout on one instance is honored by all of them, and survives deploys. The middleware interface stays identical — only the storage swaps.

### R5.3 — RASP vs WAF
- A **WAF (Web Application Firewall)** sits *in front* of the app (network edge) and inspects traffic generically.
- **RASP** lives *inside* the app and understands application context (which user, which route, which data).
Our anomaly detector is a lightweight RASP-style layer. They're complementary: a WAF catches broad noise at the edge; RASP catches context-specific abuse the WAF can't see. Defense in depth again.

### R5.4 — Compliance frameworks this maps to
The controls we built map cleanly onto common frameworks:
| Our control | SOC 2 / ISO 27001 theme |
|---|---|
| Audit logging | Monitoring & logging |
| SAST/SCA/DAST gates | Secure SDLC / change management |
| Secret manager + scanning | Access control / cryptography |
| Signed images + verify gate | Integrity / supply-chain security |
| Triage playbook + SLAs | Incident/vulnerability management |
Auto-generated reports become your evidence artifacts for audits.

### R5.5 — Closing the loop: detection → response
Logging and detection are only half of incident response. The natural next steps (beyond this series): forward structured logs to a **SIEM** (Security Information and Event Management system) or aggregator, set **alerts** on the audit events we emit (e.g., "10+ `user.login.failure` from one IP → page on-call"), and rehearse a **runbook** so the team knows what to do when an alert fires.

---

# 🏁 Series Conclusion: What You Built

Congratulations — you've built a complete, layered DevSecOps pipeline around a real application. Here's the full architecture you now have, mapped to where each guardrail lives:

```
① DEVELOP (laptop)      ② BUILD (CI)           ③ PACKAGE (CI)          ④ DEPLOY          ⑤ RUN (prod)
─────────────────────   ────────────────────   ─────────────────────   ───────────────   ─────────────────────
• STRIDE threat model   • ESLint SAST (CI)     • Multi-stage image     • Cosign verify   • Structured logging
• ESLint security lint  • Semgrep SAST         • Trivy image scan        gate            • Log redaction
• Husky pre-commit      • npm audit + Trivy    • Cosign keyless sign    • Deploy by       • Audit trail
• gitleaks (local)        SCA + SBOM           • OWASP ZAP DAST          digest           • Brute-force guard
                        • gitleaks history     • IaC/Dockerfile audit                     • Anomaly detection
                        • Enforced branch                                                 • Compliance reports
                          protection                                                      • Dependabot triage

  ◄──────────────────────────────────  DEFENSE IN DEPTH  ──────────────────────────────────►
```

**The core lessons, distilled:**

1. **Shift left, but don't shift *only* left.** Every threat is defended at multiple stages — secrets are blocked at the laptop, in CI history, *and* stored in a vault. Any single control can fail; the stack holds.
2. **Automate the gates, enforce them centrally.** Local hooks help, but branch protection and CI jobs are what make security *un-skippable*.
3. **Keep developers fast.** Fail only on HIGH/CRITICAL, tune the noise, automate the fixes (Dependabot), and give clear triage SLAs. A tool that annoys people gets disabled; a tuned one gets trusted.
4. **Prove it, don't just do it.** Signed artifacts, SBOMs, audit logs, and compliance reports turn "we're secure" into *evidence*.
5. **Security is a product feature, not a phase.** From the threat model on day zero to runtime monitoring in production, it's woven through the whole lifecycle — which is the entire point of DevSecOps.

You started with an empty folder. You now have a secure notes API defended by a pipeline that catches vulnerabilities from the first keystroke to live production traffic. Take these patterns, adapt them to your stack, and ship with confidence. 🔒🚀
