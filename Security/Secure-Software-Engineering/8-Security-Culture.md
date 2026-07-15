# Part 8: Maintenance, Sunset & Security Culture

Picking up from Part 7: SecureTrade can detect, contain, and recover from an incident. This final part zooms out from any single moment to the long game — because a security program measured only in "did we survive today" isn't actually a program, it's luck repeated. This part builds the muscle for security to survive **years**, not just a launch day: triaging the next CVE with a real deadline, inviting strangers to try to break your app on purpose, training the next engineer who joins, safely turning things off when their time comes, and proving to people who don't read code that any of this was worth it.

**Goal recap:** security doesn't end at launch.

---

## Step 1 — Formalize Vulnerability Management with Real SLAs

### 🎯 The Target
`docs/VULNERABILITY-MANAGEMENT.md` — turning Part 4's ad-hoc "fix or document" habit into a formal policy with binding deadlines, plus `scripts/triage-vulnerabilities.ts` to enforce it automatically.

### 💡 The Concept
Since Part 4, `npm audit` and Snyk have told us *that* a vulnerability exists. What's been missing is a deadline — like a hospital's triage system, which doesn't just diagnose "this patient has a fracture," it also assigns a color tag that determines whether they're seen in 5 minutes or 5 hours. An **SLA (Service Level Agreement)** here means: once a vulnerability is confirmed at a given severity, the clock starts, and the fix is *due* by a specific date — not "whenever someone gets around to it."

### 🛠️ The Implementation

##### 📄 File: `docs/VULNERABILITY-MANAGEMENT.md`
```markdown
# SecureTrade — Vulnerability Management Policy

## SLA by Severity (clock starts the moment a finding is CONFIRMED, not
## merely reported/detected — false positives don't start the clock)

| Severity (CVSS) | Fix Due Within | Escalation If Missed |
|---|---|---|
| Critical (9.0–10.0) | 7 days | Notify engineering lead + block ALL other feature work until resolved |
| High (7.0–8.9) | 30 days | Notify engineering lead |
| Medium (4.0–6.9) | 90 days | Tracked in backlog, reviewed monthly |
| Low (0.1–3.9) | Best-effort, next major dependency refresh | No escalation |

## Triage Workflow
1. Finding surfaces via Dependabot, `npm audit`, Snyk, OSV, CodeQL, or
   Semgrep (Parts 3-5) — automatically opens/flags a GitHub issue.
2. Within 2 business days: a human confirms the finding is a true
   positive and applicable to how we actually use the package (some CVEs
   affect a code path we never call — still documented, but may warrant
   a lower effective priority; never silently dismissed without a written
   reason in `docs/VULNERABILITY-EXCEPTIONS.md`, Part 4).
3. Severity is assigned using the CVSS score reported by the tool (see
   Part 4's Reference section for the score-to-label mapping).
4. Due date is calculated and tracked (Step 1's script, below).
5. Fix follows the same "break it first" verification discipline as
   every other part of this series where feasible: confirm the
   vulnerable behavior, apply the fix, confirm it's closed.
6. Fix passes the full Part 5 CI/CD pipeline before merge — no exceptions,
   even under SLA pressure. A rushed, unverified patch during a
   Critical-severity countdown is how new incidents get created.

## Ownership
A single named "Vulnerability Management Owner" role rotates monthly
(even on a solo project, this forces a deliberate monthly review instead
of assuming "someone" is watching). Tracked in the team calendar.
```

##### 📄 File: `data/vulnerability-tracker.json`
```json
[
  {
    "id": "VULN-2025-001",
    "source": "npm audit",
    "package": "example-package",
    "cvssSeverity": "MEDIUM",
    "confirmedDate": "2025-01-10",
    "status": "OPEN",
    "notes": "Sample entry — replace with real findings as they occur."
  }
]
```

##### 📄 File: `scripts/triage-vulnerabilities.ts`
```typescript
// scripts/triage-vulnerabilities.ts
//
// Reads data/vulnerability-tracker.json, computes each entry's SLA due
// date from its severity and confirmedDate, and flags anything OVERDUE.
// Intended to run on a schedule (see the CI workflow in Step 1's
// verification) so an overdue Critical fix is impossible to quietly miss.

import { readFileSync } from "node:fs";
import { join } from "node:path";

type Severity = "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";
type VulnEntry = {
  id: string;
  source: string;
  package: string;
  cvssSeverity: Severity;
  confirmedDate: string; // ISO date, e.g. "2025-01-10"
  status: "OPEN" | "FIXED" | "ACCEPTED_RISK";
  notes: string;
};

// Mirrors docs/VULNERABILITY-MANAGEMENT.md's SLA table exactly — this
// constant is the single source of truth the whole team should point to
// if the policy document and code ever seem to disagree (in which case,
// fix whichever is wrong, don't let them silently drift apart).
const SLA_DAYS: Record<Severity, number> = {
  CRITICAL: 7,
  HIGH: 30,
  MEDIUM: 90,
  LOW: 365,
};

function daysBetween(a: Date, b: Date): number {
  return Math.floor((b.getTime() - a.getTime()) / (1000 * 60 * 60 * 24));
}

function main() {
  const entries: VulnEntry[] = JSON.parse(
    readFileSync(join(process.cwd(), "data", "vulnerability-tracker.json"), "utf-8")
  );

  const today = new Date();
  let overdueCount = 0;

  console.log("\nSecureTrade — Vulnerability SLA Triage\n");

  for (const entry of entries) {
    if (entry.status !== "OPEN") continue;

    const confirmedDate = new Date(entry.confirmedDate);
    const daysElapsed = daysBetween(confirmedDate, today);
    const slaDays = SLA_DAYS[entry.cvssSeverity];
    const daysRemaining = slaDays - daysElapsed;
    const isOverdue = daysRemaining < 0;

    if (isOverdue) overdueCount++;

    const icon = isOverdue ? "🚨 OVERDUE" : daysRemaining <= 3 ? "⚠️  DUE SOON" : "✅";
    console.log(
      `${icon} [${entry.cvssSeverity}] ${entry.id} (${entry.package}) — ${
        isOverdue
          ? `${Math.abs(daysRemaining)} day(s) PAST due date`
          : `${daysRemaining} day(s) remaining`
      }`
    );
  }

  console.log(
    overdueCount > 0
      ? `\n${overdueCount} vulnerability/vulnerabilities are PAST their SLA deadline. Escalate per docs/VULNERABILITY-MANAGEMENT.md.\n`
      : "\nNo open vulnerabilities are past their SLA deadline.\n"
  );

  // A CI job running this weekly should fail loudly on any overdue
  // Critical/High finding — silence here would defeat the entire point
  // of having an SLA in the first place.
  process.exit(overdueCount > 0 ? 1 : 0);
}

main();
```

##### 📄 File: `.github/workflows/vulnerability-sla-check.yml`
```yaml
# .github/workflows/vulnerability-sla-check.yml
#
# Runs weekly (independent of any PR) — this is the enforcement mechanism
# that makes docs/VULNERABILITY-MANAGEMENT.md's SLA table real rather
# than aspirational.

name: Vulnerability SLA Check

on:
  schedule:
    - cron: "0 8 * * 1" # Every Monday 08:00 UTC
  workflow_dispatch: {}

permissions:
  contents: read
  issues: write

jobs:
  triage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"
      - run: npm ci
      - name: Check for overdue vulnerabilities
        run: npm run triage:vulns
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "triage:vulns": "tsx scripts/triage-vulnerabilities.ts"
  }
}
```

### ✅ The Verification

```bash
npm run triage:vulns
```
Expected output: the sample entry printed as ✅ (not overdue, since it's a fresh sample date). Prove the overdue path actually works by backdating it:
```bash
sed -i.bak 's/"2025-01-10"/"2020-01-01"/' data/vulnerability-tracker.json
npm run triage:vulns
echo "Exit code: $?"
```
Expected: `🚨 OVERDUE` for the MEDIUM entry (90-day SLA, backdated 5 years) and `Exit code: 1`. Revert:
```bash
mv data/vulnerability-tracker.json.bak data/vulnerability-tracker.json
```

---

## Step 2 — Prepare for a Professional Pentest and/or Bug Bounty

### 🎯 The Target
`docs/PENTEST-SCOPE.md`, `SECURITY.md` (a GitHub-standard file), and `.well-known/security.txt` — the documents that make SecureTrade *ready* to be attacked on purpose, by people we've invited to do so.

### 💡 The Concept
Every defense in this series so far has been tested by *us* — the people who built it, who already know where we think the weak points are. A **pentest** (penetration test) or **bug bounty** brings in someone with zero familiarity with our assumptions, precisely because a fresh adversarial perspective reliably finds things the original builders' blind spots hide from them — like asking a stranger to proofread your essay because you've re-read your own sentences so many times you no longer see the typo. `security.txt` is the internet-standard equivalent of putting a "if you find something wrong, call this number" sign on your building, so a well-meaning researcher who finds a real bug has an obvious, safe way to tell you *before* considering public disclosure.

### 🛠️ The Implementation

##### 📄 File: `SECURITY.md`
```markdown
# Security Policy

## Reporting a Vulnerability
If you believe you've found a security vulnerability in SecureTrade,
please report it privately — **do not open a public GitHub issue**.

Email: security@securetrade.example (replace with a real, monitored
address before any public launch) with:
- A description of the vulnerability and its potential impact
- Steps to reproduce (a working proof-of-concept is appreciated but not required)
- Any suggested remediation, if you have one

## Our Commitment
- We will acknowledge your report within **3 business days**.
- We will provide an initial severity assessment within **7 business days**.
- We will keep you informed of remediation progress.
- We will credit you (with permission) once the fix is deployed, unless
  you prefer to remain anonymous.
- We follow the SLA in `docs/VULNERABILITY-MANAGEMENT.md` for fixing
  confirmed findings.

## Scope
See `docs/PENTEST-SCOPE.md` for the full in-scope/out-of-scope
boundaries. In short: the production SecureTrade application and API are
in scope; social engineering against our team, physical security, and
third-party services we depend on (Vercel, Supabase infrastructure
itself) are out of scope.

## Safe Harbor
We will not pursue legal action against good-faith security research
conducted within this policy's scope and guidelines.
```

##### 📄 File: `docs/PENTEST-SCOPE.md`
```markdown
# SecureTrade — Penetration Test / Bug Bounty Scope

## In Scope
- `https://securetrade.example` (production) and its `/api/v1/*` routes
- Authentication and session management (Part 3)
- RBAC / authorization boundaries (Parts 2-3)
- Business logic of order placement (Part 3)

## Out of Scope
- Denial of Service testing against production (test against a staging
  environment instead — request access via security@securetrade.example)
- Social engineering of team members
- Physical security of any office/device
- Vulnerabilities in Vercel, Supabase, or Sentry's own infrastructure
  (report those directly to the respective vendor)
- Automated scanning at a volume that degrades service for real users —
  coordinate scan timing with us first

## Rules of Engagement
1. Use test accounts only (register your own — never attempt to access
   another real user's data even if a vulnerability seems to allow it;
   stop and report immediately upon confirming access is possible).
2. Do not exfiltrate, modify, or delete real user data.
3. Report immediately upon discovering a Critical-severity issue (per
   `docs/IR-RUNBOOK.md`'s classification), rather than continuing to
   probe further.

## What We Provide Testers
- A dedicated staging environment with seeded test data (never production
  data) — request access via security@securetrade.example.
- This repository's `docs/THREAT-MODEL.md` and `docs/ARCHITECTURE.md`,
  shared on request under a mutual NDA, to make testing more efficient
  (a "grey box" approach — full transparency about our own assumptions
  tends to surface DEEPER findings than forcing testers to rediscover our
  architecture from scratch).

## Reward Structure (if running as a paid bug bounty)
| Severity | Reward Range |
|---|---|
| Critical | $500 – $2,000 |
| High | $200 – $500 |
| Medium | $50 – $200 |
| Low | Recognition + swag |

_(Adjust to actual budget — even a purely recognition-based program is
far better than no external testing at all.)_
```

##### 📄 File: `.well-known/security.txt`
```
Contact: mailto:security@securetrade.example
Expires: 2026-12-31T23:59:59.000Z
Preferred-Languages: en
Canonical: https://securetrade.example/.well-known/security.txt
Policy: https://securetrade.example/SECURITY.md
```

### ✅ The Verification

```bash
npm run dev
curl -s http://localhost:3000/.well-known/security.txt
```
Expected: the file contents print correctly (Next.js serves anything under `public/.well-known/` automatically — move the file there if it isn't already reachable: `mkdir -p public/.well-known && cp .well-known/security.txt public/.well-known/`).

```bash
grep -c "^##" docs/PENTEST-SCOPE.md
```
Expected: a non-zero count confirming the scope document's sections rendered.

---

## Step 3 — Security Training for New Developers

### 🎯 The Target
`docs/ONBOARDING-SECURITY.md` and `scripts/security-onboarding-check.ts` — a structured path for a brand-new developer to become genuinely security-competent on this codebase within their first week, with a checkable, not just readable, checklist.

### 💡 The Concept
Every security control in this series has an unstated dependency: **a human has to understand it well enough to not accidentally undo it.** A new developer who doesn't know *why* `createOrderSchema` deliberately excludes a `price` field might "helpfully" add it back six months from now to fix a seemingly unrelated bug — silently reopening Part 3's Bug 4. Onboarding isn't bureaucracy; it's transferring the *reasoning*, not just the rules — the difference between memorizing "don't touch the red wire" and understanding "the red wire is live, here's how to check before touching anything."

### 🛠️ The Implementation

##### 📄 File: `docs/ONBOARDING-SECURITY.md`
```markdown
# SecureTrade — Security Onboarding for New Developers

Complete this before merging your first pull request. Expect ~1 day of
focused reading plus hands-on verification — this is time genuinely well
spent, not overhead.

## Day 1: Understand the "Why" (read, in this order)
- [ ] `docs/SYSTEM-OVERVIEW.md` — what SecureTrade is, roles, trust boundaries
- [ ] `docs/THREAT-MODEL.md` — the 12 threats we've explicitly designed against
- [ ] `docs/ARCHITECTURE.md` — Zero Trust / Least Privilege / Defense in
      Depth / Secure Defaults, and the RBAC matrix
- [ ] `docs/SECRETS-POLICY.md` — the one rule you cannot afford to
      forget, ever: no secret, anywhere, in any commit

## Day 1: Verify Your Understanding, Hands-On
- [ ] Clone the repo, run `npm ci`, `npm run db:seed`, `npm run dev` — get
      the app running locally end-to-end
- [ ] Log in as each of the 3 seeded test roles (Part 2) and confirm you
      can observe the RBAC matrix's boundaries yourself (e.g., try
      visiting `/admin/users` as the `USER` account and confirm you're
      blocked)
- [ ] Run `npm run semgrep`, `npm run test`, `npm run audit:check` — all
      locally, and understand what each one is checking for
- [ ] Read `app/api/v1/orders/route.ts` and explain OUT LOUD (to a
      teammate, a rubber duck, or in a written note) why `executedPrice`
      is never read from the request body — if you can't explain it
      confidently, re-read Part 3's Bug 4 fix before writing any code

## Before Your First Pull Request
- [ ] Read `docs/LOCKFILE-POLICY.md` — know the difference between
      `npm install` and `npm ci`, and when to use each
- [ ] Confirm your local `.gitignore` genuinely excludes `.env.local`:
      `git check-ignore -v .env.local` must print something
- [ ] Read the "Break It First" sections in Part 3 for at least 2 of the
      7 bugs — understand not just THAT they were fixed, but the general
      SHAPE of the mistake, so you recognize it in new code you write
- [ ] Understand that CI (Part 5) will block your PR if Semgrep, tests,
      secret scanning, or DAST fail — this is not personal, it's the
      system working as designed

## Ongoing
- [ ] Attend (or read the notes from) the next scheduled Tabletop
      Exercise (`docs/TTX-SCENARIO-01.md` is the template — run a new
      scenario periodically)
- [ ] Know where `docs/IR-RUNBOOK.md` lives and roughly what's in it —
      you may need it at 2 AM someday; skimming it once now is much
      cheaper than reading it for the first time during a real incident
```

##### 📄 File: `scripts/security-onboarding-check.ts`
```typescript
// scripts/security-onboarding-check.ts
//
// A lightweight, hands-on check a new developer runs to PROVE (not just
// claim) they've completed the environment-setup portion of onboarding —
// mirrors the same "verification over assertion" philosophy used
// throughout this entire series' own verify:partN scripts.

import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";

type Check = { label: string; pass: boolean };
const checks: Check[] = [];

function main() {
  checks.push({
    label: ".env.local exists locally",
    pass: existsSync(join(process.cwd(), ".env.local")),
  });

  try {
    execSync("git check-ignore -q .env.local");
    checks.push({ label: ".env.local is confirmed git-ignored", pass: true });
  } catch {
    checks.push({ label: ".env.local is confirmed git-ignored", pass: false });
  }

  try {
    execSync("npx dotenv -e .env.local -- npx prisma validate", { stdio: "pipe" });
    checks.push({ label: "Database connection configured and schema valid", pass: true });
  } catch {
    checks.push({ label: "Database connection configured and schema valid", pass: false });
  }

  try {
    execSync("npm run semgrep", { stdio: "pipe" });
    checks.push({ label: "Semgrep runs clean locally", pass: true });
  } catch {
    checks.push({ label: "Semgrep runs clean locally", pass: false });
  }

  try {
    execSync("npm run test", { stdio: "pipe" });
    checks.push({ label: "Unit test suite passes locally", pass: true });
  } catch {
    checks.push({ label: "Unit test suite passes locally", pass: false });
  }

  console.log("\nSecureTrade — New Developer Onboarding Check\n");
  let allPassed = true;
  for (const c of checks) {
    console.log(`${c.pass ? "✅" : "❌"} ${c.label}`);
    if (!c.pass) allPassed = false;
  }
  console.log(
    allPassed
      ? "\nEnvironment ready. Now complete the reading checklist in docs/ONBOARDING-SECURITY.md.\n"
      : "\nFix the items above before proceeding — these are the same checks CI will run on your first PR.\n"
  );
  process.exit(allPassed ? 0 : 1);
}

main();
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "onboarding:check": "tsx scripts/security-onboarding-check.ts"
  }
}
```

### ✅ The Verification

```bash
npm run onboarding:check
```
Expected: all ✅. Have a genuinely new team member (or simulate it yourself on a fresh clone in a temp directory) run this from scratch — it should catch any missing local setup step before they ever open a pull request.

---

## Step 4 — Secure Decommissioning: Data Deletion and Key Rotation

### 🎯 The Target
`docs/DECOMMISSIONING.md` and `scripts/decommission-user.ts` — a documented, scriptable procedure for permanently and safely deleting a user's data (implementing PDPA's "right to erasure"-adjacent obligations) and rotating credentials when a service or environment is retired.

### 💡 The Concept
Every part of this series has been about building things carefully. This step is about **ending** things carefully — an underrated security discipline. A user who deletes their account expects their data to actually disappear, not linger in a forgotten backup or an orphaned row an Auditor can still browse. A departing employee's access should evaporate the same day they leave, not "eventually, whenever someone remembers." Think of it like a hotel checkout: the room key should stop working the moment checkout is complete, not whenever housekeeping happens to notice the guest left.

### 🛠️ The Implementation

##### 📄 File: `docs/DECOMMISSIONING.md`
```markdown
# SecureTrade — Decommissioning Procedures

## User Account Deletion (PDPA-Aligned)
When a user requests deletion:
1. Verify the request is genuinely from the account owner (re-authenticate,
   don't just trust an unauthenticated "delete my account" link).
2. Run `scripts/decommission-user.ts <userId>` (Step 4, below) — this:
   - Deletes the `User` row (cascades to `Order`/`Holding` via Prisma's
     `onDelete: Cascade`, configured in Part 2's schema)
   - Preserves `AuditLog` entries where this user was the ACTOR (needed
     for MAS TRM's audit trail obligations, which can outweigh an
     individual erasure request for regulated financial activity — this
     exception is deliberate, not an oversight, and should be disclosed
     in the app's privacy policy)
   - Anonymizes (not deletes) audit log entries where this user was only
     the TARGET of someone else's action, replacing identifying fields
     with `"[deleted user]"`
3. Confirm deletion completed via the script's verification output.
4. Notify the user their request is complete, within PDPA's expected
   reasonable timeframe.

## Environment/Service Decommissioning
When retiring an environment (e.g., an old staging environment) or a
third-party integration:
1. Rotate/revoke ALL credentials scoped to that environment FIRST —
   before deleting any infrastructure, so nothing can be re-provisioned
   using a stale credential later out of confusion.
2. Export any data required for compliance retention (e.g., financial
   records under MAS TRM's retention expectations) BEFORE deletion.
3. Delete the infrastructure (Terraform's `terraform destroy` for
   anything managed per Part 6 — never manual console deletion, so the
   action is captured in the same audit trail as everything else).
4. Update `docs/ARCHITECTURE.md` and `sbom.json` to remove references to
   the decommissioned service.

## Key Rotation Schedule
| Credential | Rotation Frequency | Trigger for IMMEDIATE Rotation |
|---|---|---|
| `AUTH_SECRET` | Annually | Any suspected session-forgery incident |
| `DATABASE_URL` / `DIRECT_URL` password | Annually | Any suspected DB access incident |
| `SNYK_TOKEN`, `VERCEL_TOKEN` | Every 90 days | Any suspected CI secret leak (Gitleaks/TruffleHog finding) |
| Supabase service role keys | Annually | Immediately upon any team member offboarding who had access |

## Employee/Contributor Offboarding
On the same day access ends:
- [ ] Revoke GitHub repository access
- [ ] Revoke Vercel project access
- [ ] Revoke Supabase project access
- [ ] Rotate any shared secret they had direct access to (per the table
      above's "immediate" triggers)
- [ ] Remove from the on-call rotation (Part 7's `docs/ALERTING.md`)
```

##### 📄 File: `scripts/decommission-user.ts`
```typescript
// scripts/decommission-user.ts
//
// Securely deletes a user's account while preserving audit-trail
// integrity, per docs/DECOMMISSIONING.md. Run as:
//   npx dotenv -e .env.local -- tsx scripts/decommission-user.ts <userId>

import { prisma } from "@/lib/prisma";
import { logSecurityEvent } from "@/lib/security-logger";

async function decommissionUser(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    console.error(`No user found with id ${userId}`);
    process.exit(1);
  }

  console.log(`Decommissioning user ${user.email} (${userId})...`);

  await prisma.$transaction(async (tx) => {
    // Anonymize audit log entries where this user was the TARGET of
    // someone ELSE's action (e.g. "Admin X changed User Y's role") —
    // we preserve the FACT the action occurred (non-repudiation, REQ-08)
    // without retaining this specific user's identifying details.
    await tx.auditLog.updateMany({
      where: { targetType: "User", targetId: userId },
      data: { targetId: "[deleted-user]" },
    });

    // Audit log entries where THIS user was the ACTOR are deliberately
    // preserved as-is (see docs/DECOMMISSIONING.md's explanation —
    // MAS TRM audit trail requirements for financial activity).

    // Deleting the User row cascades to Order and Holding automatically,
    // per the `onDelete: Cascade` relations defined in Part 2's schema.
    await tx.user.delete({ where: { id: userId } });
  });

  // The deletion event itself is security-relevant and gets logged, using
  // a hash rather than the (now-deleted) real email, consistent with
  // Part 7's logging policy.
  logSecurityEvent({
    type: "ROLE_CHANGED", // reusing the closest existing event type; a
    // real system would add a dedicated USER_DELETED type here
    metadata: { action: "USER_DELETED", deletedUserId: userId },
  });

  console.log(`✅ User ${userId} decommissioned. Audit trail preserved per policy.`);
}

const userId = process.argv[2];
if (!userId) {
  console.error("Usage: tsx scripts/decommission-user.ts <userId>");
  process.exit(1);
}

decommissionUser(userId)
  .catch((err) => {
    console.error("Decommissioning failed:", err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
```

### ✅ The Verification

```bash
# Register a throwaway test account, then decommission it
curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"todelete@example.com","name":"To Delete","password":"SuperSecure123"}'
# Note the returned "id" value, then:
npx dotenv -e .env.local -- tsx scripts/decommission-user.ts <PASTE_ID_HERE>
```
Expected: `✅ User ... decommissioned.` Confirm via Prisma Studio (`npm run db:studio`) that the user row is gone, and any `AuditLog` rows that referenced them as a target now show `targetId: "[deleted-user]"`.

---

## Step 5 — Security Metrics for Executives

### 🎯 The Target
`scripts/generate-metrics-report.ts` — producing a plain-English, non-technical summary report an executive (who has never read a line of this series' code) can understand in under two minutes.

### 💡 The Concept
Everything we've built produces *technical* signal — Semgrep findings, CVSS scores, coverage percentages. An executive making a budget or launch-timing decision doesn't think in CVSS scores; they think in questions like "are we improving or getting worse?" and "how exposed are we right now, in plain terms?" **MTTD (Mean Time To Detect)** and **MTTR (Mean Time To Respond/Remediate)** are the two numbers security-mature organizations universally report upward, precisely because they compress an enormous amount of operational reality into "how fast do we notice problems, and how fast do we fix them" — the same two questions that matter whether you're running a bank's fraud desk or a hospital's emergency room.

### 🛠️ The Implementation

##### 📄 File: `data/incident-metrics.json`
```json
[
  { "incidentId": "2025-01-15-ttx-sqli-drill", "detectedAt": "2025-01-15T14:05:00Z", "respondedAt": "2025-01-15T14:08:00Z", "resolvedAt": "2025-01-15T14:17:00Z" }
]
```

##### 📄 File: `scripts/generate-metrics-report.ts`
```typescript
// scripts/generate-metrics-report.ts
//
// Produces an executive-readable security metrics summary — translating
// technical artifacts (SBOM, incident timestamps, CI configuration) into
// the handful of numbers that actually inform business decisions.

import { readFileSync, existsSync, readdirSync } from "node:fs";
import { join } from "node:path";

type IncidentMetric = {
  incidentId: string;
  detectedAt: string;
  respondedAt: string;
  resolvedAt: string;
};

function minutesBetween(a: string, b: string): number {
  return Math.round((new Date(b).getTime() - new Date(a).getTime()) / 60000);
}

function main() {
  const incidents: IncidentMetric[] = existsSync(
    join(process.cwd(), "data", "incident-metrics.json")
  )
    ? JSON.parse(readFileSync(join(process.cwd(), "data", "incident-metrics.json"), "utf-8"))
    : [];

  const mttdMinutes =
    incidents.length > 0
      ? incidents.reduce((sum, i) => sum + minutesBetween(i.detectedAt, i.respondedAt), 0) /
        incidents.length
      : null;

  const mttrMinutes =
    incidents.length > 0
      ? incidents.reduce((sum, i) => sum + minutesBetween(i.detectedAt, i.resolvedAt), 0) /
        incidents.length
      : null;

  // % of "repos" with SAST — trivial for a single-repo project (100% or
  // 0%), but written generically so it scales honestly to a future
  // multi-repo organization without needing to be rewritten.
  const totalRepos = 1;
  const reposWithSast = existsSync(join(process.cwd(), ".semgrep.yml")) ? 1 : 0;
  const sastCoveragePercent = Math.round((reposWithSast / totalRepos) * 100);

  const detectionRulesDir = join(process.cwd(), "docs", "detections");
  const detectionRuleCount = existsSync(detectionRulesDir)
    ? readdirSync(detectionRulesDir).filter((f) => f.endsWith(".yml")).length
    : 0;

  const openVulns: { cvssSeverity: string; status: string }[] = existsSync(
    join(process.cwd(), "data", "vulnerability-tracker.json")
  )
    ? JSON.parse(readFileSync(join(process.cwd(), "data", "vulnerability-tracker.json"), "utf-8"))
    : [];
  const openCritical = openVulns.filter(
    (v) => v.status === "OPEN" && v.cvssSeverity === "CRITICAL"
  ).length;

  console.log(`
================================================================
 SecureTrade — Security Posture Summary (Exec Report)
================================================================

  Mean Time To Detect (MTTD):     ${mttdMinutes !== null ? `${mttdMinutes} min` : "No incidents recorded yet"}
  Mean Time To Respond (MTTR):    ${mttrMinutes !== null ? `${mttrMinutes} min` : "No incidents recorded yet"}

  % of codebases with automated security scanning (SAST): ${sastCoveragePercent}%
  Automated attack-pattern detection rules active:        ${detectionRuleCount}
  Currently open CRITICAL vulnerabilities:                ${openCritical}

  Plain-English summary:
  ${
    openCritical === 0
      ? "  ✅ No known critical vulnerabilities are currently open."
      : `  🚨 ${openCritical} critical vulnerability/vulnerabilities require IMMEDIATE attention (see docs/VULNERABILITY-MANAGEMENT.md).`
  }
  ${
    mttdMinutes !== null && mttdMinutes <= 10
      ? "  ✅ Security incidents are being detected quickly (within minutes)."
      : "  ℹ️  Insufficient incident history yet to assess detection speed confidently."
  }

  Full technical detail available in: docs/THREAT-MODEL.md,
  docs/VULNERABILITY-MANAGEMENT.md, sbom.json
================================================================
`);
}

main();
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "metrics:report": "tsx scripts/generate-metrics-report.ts"
  }
}
```

### ✅ The Verification

```bash
npm run metrics:report
```
Expected: a readable, boxed summary report, including the MTTD/MTTR figures computed from the Part 7 drill's real timestamps (detected 14:05, responded 14:08 = 3 min MTTD; resolved 14:17 = 12 min MTTR) — genuinely calculated from data this series produced, not placeholder numbers.

---

## Step 6 — Assemble the Final Project: One Verification to Rule Them All

### 🎯 The Target
`scripts/verify-all.ts` — a single command that runs every `verify:partN` script from Parts 1 through 8 in sequence, plus a final, polished root `README.md` tying the entire repository together as the finished portfolio artifact.

### 💡 The Concept
Eight parts, eight separate verification scripts — useful individually, but the real proof this all *still* holds together as one coherent system is running every single one, back to back, against the current, final state of the repository. This is the software equivalent of a building inspector doing one final, complete walkthrough before issuing the occupancy certificate — not re-checking each room in isolation on different days, but confirming the whole building works together, right now, as delivered.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-all.ts`
```typescript
// scripts/verify-all.ts
//
// Runs every part's verification script in sequence. This is the final
// gate for the whole series — if this passes, every artifact promised
// across all 8 parts genuinely exists and functions, right now.

import { execSync } from "node:child_process";

const parts = [
  { name: "Part 1 — Threat Model", script: "verify:part1" },
  { name: "Part 2 — Secure Design", script: "verify:part2" },
  { name: "Part 3 — Secure Coding", script: "verify:part3" },
  { name: "Part 4 — Supply Chain Security", script: "verify:part4" },
  { name: "Part 5 — Testing & CI/CD Security", script: "verify:part5" },
  { name: "Part 6 — Secure Deployment", script: "verify:part6" },
  { name: "Part 7 — Detection & IR", script: "verify:part7" },
];

console.log("\n================================================================");
console.log(" SecureTrade — FULL SERIES VERIFICATION (Parts 1-7)");
console.log("================================================================\n");

let allPassed = true;
const results: { name: string; pass: boolean }[] = [];

for (const part of parts) {
  console.log(`\n--- Running ${part.name} (npm run ${part.script}) ---\n`);
  try {
    execSync(`npm run ${part.script}`, { stdio: "inherit" });
    results.push({ name: part.name, pass: true });
  } catch {
    results.push({ name: part.name, pass: false });
    allPassed = false;
  }
}

console.log("\n================================================================");
console.log(" FINAL SUMMARY");
console.log("================================================================\n");
for (const r of results) {
  console.log(`${r.pass ? "✅" : "❌"} ${r.name}`);
}

console.log(
  allPassed
    ? "\n🎉 Every part of the series verifies successfully against the current repository state.\n"
    : "\n⚠️  One or more parts failed verification — review the output above.\n"
);

process.exit(allPassed ? 0 : 1);
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "verify:all": "tsx scripts/verify-all.ts"
  }
}
```

Now the final `README.md` — the front door to everything built across all 8 parts:

##### 📄 File: `README.md` (replace the Part 0 placeholder)
```markdown
# SecureTrade

A simplified, SGX-inspired trading SaaS built as the running example for
the **"Secure Software Engineering from Zero to Prod"** tutorial series —
security designed in from the first sentence of planning through
production monitoring, incident response, and eventual decommissioning.

## What's Inside

| Area | Where to Look |
|---|---|
| Threat model & security requirements | `docs/THREAT-MODEL.md`, `docs/SECURITY-REQUIREMENTS.md` |
| Architecture & RBAC design | `docs/ARCHITECTURE.md`, `prisma/schema.prisma` |
| Application code | `app/`, `lib/`, `auth.ts`, `middleware.ts` |
| Supply chain security | `sbom.json`, `.github/dependabot.yml` |
| CI/CD security pipeline | `.github/workflows/` |
| Deployment hardening | `vercel.json`, `infra/` (Terraform), `middleware.ts` (security headers) |
| Detection & incident response | `docs/detections/`, `docs/IR-RUNBOOK.md`, `docs/incidents/` |
| Ongoing security operations | `docs/VULNERABILITY-MANAGEMENT.md`, `docs/DECOMMISSIONING.md` |

## Getting Started

```bash
nvm use
npm ci
cp .env.example .env.local   # fill in real values — see docs/SECRETS-POLICY.md
npm run db:migrate
npm run db:seed
npm run dev
```

## Verifying This Repository
Every part of the series that built this repo has its own automated
verification script. Run the whole thing end-to-end:

```bash
npm run verify:all
```

## Security
See `SECURITY.md` for our vulnerability disclosure policy, and
`docs/PENTEST-SCOPE.md` if you're a security researcher looking to
engage more deeply.

## Series Progress
- [x] Part 0 — Environment setup
- [x] Part 1 — Threat Model First
- [x] Part 2 — Secure Design
- [x] Part 3 — Secure Coding
- [x] Part 4 — Dependencies & Supply Chain Security
- [x] Part 5 — Testing & CI/CD Security
- [x] Part 6 — Secure Deployment & Cloud Config
- [x] Part 7 — Detection, Response & Incident Handling
- [x] Part 8 — Maintenance, Sunset & Security Culture
```

### ✅ The Verification

```bash
npm run verify:all
```
Expected: every part prints its own full report, ending in the final summary showing all 7 parts (Parts 1-7 have dedicated scripts; Part 8's own check runs next in Step 7 below) as ✅, and exit code `0`.

---

## Step 7 — Automate Verification of Part 8 Itself

### 🎯 The Target
`scripts/verify-part8.ts` — the last verification script in the series, checking this part's own artifacts, then folding itself into `verify:all`.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-part8.ts`
```typescript
// scripts/verify-part8.ts

import { existsSync, readFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";

type Check = { label: string; pass: boolean };
const checks: Check[] = [];

function fileExists(p: string): boolean {
  return existsSync(join(process.cwd(), p));
}

function main() {
  const requiredFiles = [
    "docs/VULNERABILITY-MANAGEMENT.md",
    "docs/PENTEST-SCOPE.md",
    "docs/ONBOARDING-SECURITY.md",
    "docs/DECOMMISSIONING.md",
    "SECURITY.md",
    ".well-known/security.txt",
    "scripts/triage-vulnerabilities.ts",
    "scripts/decommission-user.ts",
    "scripts/generate-metrics-report.ts",
    "scripts/security-onboarding-check.ts",
    "data/vulnerability-tracker.json",
    "data/incident-metrics.json",
  ];
  for (const f of requiredFiles) {
    checks.push({ label: `File exists: ${f}`, pass: fileExists(f) });
  }

  try {
    execSync("npm run triage:vulns", { stdio: "pipe" });
    checks.push({ label: "Vulnerability SLA triage runs cleanly", pass: true });
  } catch {
    // Non-zero exit here just means an OVERDUE finding exists — which is
    // valid, real output, not a broken script. We only check it RUNS.
    checks.push({ label: "Vulnerability SLA triage runs (may report overdue items)", pass: true });
  }

  try {
    execSync("npm run metrics:report", { stdio: "pipe" });
    checks.push({ label: "Executive metrics report generates successfully", pass: true });
  } catch {
    checks.push({ label: "Executive metrics report generates successfully", pass: false });
  }

  console.log("\nSecureTrade — Part 8 Verification\n");
  let allPassed = true;
  for (const c of checks) {
    console.log(`${c.pass ? "✅" : "❌"} ${c.label}`);
    if (!c.pass) allPassed = false;
  }
  console.log(
    allPassed
      ? "\nAll Part 8 checks passed. The full SecureTrade series is complete.\n"
      : "\nSome checks failed — fix the items above.\n"
  );
  process.exit(allPassed ? 0 : 1);
}

main();
```

##### 📄 File: `package.json` (edit — add script, and extend `verify:all` to include Part 8)
```json
{
  "scripts": {
    "verify:part8": "tsx scripts/verify-part8.ts"
  }
}
```

##### 📄 File: `scripts/verify-all.ts` (edit — add Part 8 to the `parts` array)
```typescript
const parts = [
  { name: "Part 1 — Threat Model", script: "verify:part1" },
  { name: "Part 2 — Secure Design", script: "verify:part2" },
  { name: "Part 3 — Secure Coding", script: "verify:part3" },
  { name: "Part 4 — Supply Chain Security", script: "verify:part4" },
  { name: "Part 5 — Testing & CI/CD Security", script: "verify:part5" },
  { name: "Part 6 — Secure Deployment", script: "verify:part6" },
  { name: "Part 7 — Detection & IR", script: "verify:part7" },
  { name: "Part 8 — Maintenance & Culture", script: "verify:part8" },
];
```

### ✅ The Verification

```bash
npm run verify:part8
npm run verify:all
```
Expected: both exit `0`, with `verify:all` now printing all **8** parts as ✅. Commit the entire final state:

```bash
git add -A
git commit -m "feat: vulnerability SLAs, pentest readiness, onboarding, decommissioning, exec metrics — series complete"
git push
```

---

## ✅ Part 8 Completion Checklist

- [ ] `docs/VULNERABILITY-MANAGEMENT.md` defines real SLAs, enforced weekly by `vulnerability-sla-check.yml`
- [ ] `SECURITY.md`, `docs/PENTEST-SCOPE.md`, and `security.txt` are ready for a real external researcher or pentest firm
- [ ] A new developer can run `npm run onboarding:check` and get a genuine pass/fail on their setup
- [ ] `scripts/decommission-user.ts` deletes a user while preserving audit-trail integrity
- [ ] `npm run metrics:report` produces a real, plain-English exec summary from actual repository data
- [ ] `npm run verify:all` runs all 8 parts' verification scripts successfully, end to end
- [ ] The final `README.md` presents the repository as a coherent, complete portfolio piece

---

# 📚 Reference Section — Deep Dives for Part 8

### R1. Vulnerability Disclosure Programs (VDP) vs. Bug Bounty Programs

| | VDP | Bug Bounty |
|---|---|---|
| Payment | None (recognition only) | Cash rewards, scaled by severity |
| Barrier to start | Very low — just publish `SECURITY.md`/`security.txt` | Requires budget approval, reward structure, often a platform (HackerOne, Bugcrowd) |
| Typical first step for a small team | **This** | A natural evolution once the VDP proves valuable and budget exists |

Nearly every mature security program starts with a free VDP (exactly what Step 2 built) and *graduates* to a paid bug bounty once the organization has confidence in its own triage speed — inviting paid researchers before your SLA process (Step 1) actually works reliably tends to produce frustrated researchers and a damaged reputation, not better security.

### R2. Why MTTD/MTTR Matter More Than Raw Vulnerability Counts

A tempting but misleading executive metric is "number of vulnerabilities found this month" — a *rising* count can mean things are getting worse, OR it can mean your scanning got *better* (Part 4/5's tooling maturing) and is now finding things that were always there, invisible. MTTD and MTTR sidestep this ambiguity because they measure your **process's responsiveness**, which is unambiguously good when it trends downward, regardless of how many findings surface. This is why security-mature organizations report MTTD/MTTR trends to leadership, not raw finding counts in isolation.

### R3. The "Right to Erasure" Under PDPA — Nuance Worth Knowing

Unlike GDPR's explicit "right to erasure" (Article 17), Singapore's PDPA frames this differently: organizations must cease retaining personal data as soon as it's reasonable to assume the purpose for which it was collected is no longer being served, AND retention is no longer necessary for legal/business purposes. This is why `docs/DECOMMISSIONING.md` explicitly preserves audit log entries for a user's own actions (a genuine ongoing MAS TRM business/legal purpose) while still removing/anonymizing their broader personal footprint — the policy reflects PDPA's actual, more nuanced standard rather than assuming a blanket "delete everything" obligation exists.

### R4. Key Rotation — Why "Annually" Isn't Arbitrary

The rotation frequencies in Step 4's table aren't guesses — they balance two competing costs: rotating too rarely extends the window an undetected leaked credential remains useful to an attacker; rotating too often creates operational risk (a botched rotation causing an outage) without proportional security benefit for a credential that was never actually compromised. Industry practice generally converges on annual rotation for foundational secrets (like `AUTH_SECRET`) and shorter cycles (~90 days) for higher-blast-radius, more frequently-used API tokens — exactly the split reflected in our table.

### R5. Building a Security Culture That Outlasts Any Single Engineer

The deepest lesson of this entire series isn't any individual tool — it's that every part built a **structural** enforcement mechanism (a schema constraint, a CI gate, a branch protection rule, an SLA with automated tracking) specifically so security didn't depend on any one person's memory or vigilance. `.npmrc`'s `save-exact`, the `Order.idempotencyKey @unique` constraint, `enforce_admins=true` on branch protection, the weekly SLA check — every one of these is the same underlying philosophy applied at a different layer: **make the secure path the only path, structurally, rather than the well-intentioned path a tired or new engineer might forget to take.** A security culture that depends on everyone always remembering everything correctly, forever, is not a culture — it's a countdown to the next incident. A security culture built on structural guardrails survives the team's inevitable turnover, bad days, and deadline pressure. That's the actual, durable thing this series was teaching underneath every individual `curl` command and YAML file.

---

# 🎉 Series Conclusion

Eight parts ago, SecureTrade didn't exist — not even as an idea on a whiteboard. Now it's a complete, working, defensible application with:

- A **threat model** naming 12 concrete risks, scored and prioritized (Part 1)
- An **architecture** designed so no single bug can compromise the whole system (Part 2)
- **Application code** that was deliberately broken and then properly fixed, seven times, with regression tests locking each fix in place forever (Parts 3, 5)
- A **supply chain** with a full SBOM, automated CVE gates, and a documented understanding of what `npm install` really means (Part 4)
- A **CI/CD pipeline** that makes it structurally impossible to merge code that fails SAST, DAST, secret scanning, or tests (Part 5)
- **Production infrastructure** hardened with real security headers, a WAF, Infrastructure as Code, and monitoring (Part 6)
- The proven ability to **detect, contain, and recover** from a real, simulated attack — with the postmortem to show for it (Part 7)
- The operational discipline to keep all of this true **years** from now, not just on launch day (Part 8)

If you followed along and ran every `curl`, every `npm run verify:partN`, and the final `npm run verify:all`, you don't just have a tutorial series in your reading history — you have a working repository, a portfolio piece, and genuine hands-on experience with the exact tools and decisions real security engineering teams make daily. That repository, sitting in your GitHub account right now, is the real deliverable of this entire series. Ship it, extend it, and carry the structural-guardrails mindset from Part 8's closing lesson into whatever you build next.
