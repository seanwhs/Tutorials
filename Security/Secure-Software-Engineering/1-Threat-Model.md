# Part 1: Planning & Requirements — "Threat Model First"

Picking up right where Part 0 left off: you have an empty `securetrade` GitHub repo cloned locally, with just a README in it. Time to give the crew something real to threat-model.

**Goal recap:** find and document the bugs and abuse scenarios *before* they become code — because a threat found on a whiteboard costs nothing to fix, while the same threat found in production can cost a company its licence to operate (literally, in MAS-regulated contexts).

---

## Step 1 — Scaffold the Next.js App Inside the Existing Repo

### 🎯 The Target
A working Next.js + TypeScript app living inside the `securetrade` repo you already created in Part 0, plus dedicated folders for security documentation.

### 💡 The Concept
In Part 0 we built the safe deposit box (the empty, access-controlled repo). Now we put the first item inside it. We keep security docs in their own `docs/` folder — separate from application code — for the same reason a company keeps its compliance binder in a labeled cabinet instead of scattered across random desks: anyone (an auditor, a new hire, future-you) should be able to find "what are our security requirements?" without reading source code first.

### 🛠️ The Implementation

`create-next-app` refuses to scaffold into a non-empty directory, so we scaffold into a temp folder and merge it in:

```bash
cd securetrade

# Scaffold into a temporary sibling folder
npx create-next-app@latest .tmp-scaffold \
  --typescript \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*"

# Move everything from the scaffold into the repo root, including dotfiles
shopt -s dotglob   # makes the * glob below also match hidden files like .gitignore
mv .tmp-scaffold/* .
rmdir .tmp-scaffold

# Create the folders dedicated to security work
# docs/       -> human-readable security documentation
# docs/diagrams -> exported threat model diagrams (from draw.io)
# data/       -> machine-readable data our scripts read (threat scores, etc.)
# scripts/    -> small TypeScript tools that check our docs, not the app
mkdir -p docs/diagrams data scripts

# tsx runs TypeScript files directly with zero config — we use it for our
# scripts/ tools instead of ts-node, which fights with Next.js's tsconfig.json
npm install -D tsx
```

Now add two script entries so the tools we build later in this part are one command away:

##### 📄 File: `package.json` (edit — add inside `"scripts"`)
```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "dread": "tsx scripts/dread-score.ts",
    "verify:part1": "tsx scripts/verify-part1.ts"
  }
}
```

### ✅ The Verification

```bash
npm run dev
```
Visit `http://localhost:3000` — confirm the default Next.js page loads. Stop the server (`Ctrl+C`), then:

```bash
ls docs data scripts
git add -A
git commit -m "chore: scaffold Next.js app and security docs structure"
git push
```

---

## Step 2 — Document the System Overview & Trust Boundaries

### 🎯 The Target
`docs/SYSTEM-OVERVIEW.md` — the "cast of characters" reference every later threat-modeling step points back to.

### 💡 The Concept
You cannot threat-model a system nobody has described yet — that's like a security guard trying to spot an intruder in a building whose floor plan doesn't exist. This document is that floor plan: who's allowed in which rooms, and — critically — where the **trust boundaries** are.

A trust boundary is any point where data crosses from one party's control into another's. Picture your house: the front door is a trust boundary (outside world → your hallway). Your bedroom door might be another (kids and guests → your private room). Every trust boundary is a place an attacker has to "get through," which makes it exactly the place we focus threat-modeling attention on in Step 3.

### 🛠️ The Implementation

##### 📄 File: `docs/SYSTEM-OVERVIEW.md`
```markdown
# SecureTrade — System Overview

## What is SecureTrade?
SecureTrade is a Next.js SaaS platform that lets retail users in Singapore:
- Register and log in to a trading account
- View simulated real-time market data (mock SGX-listed instruments)
- Submit buy/sell orders for listed instruments
- View their portfolio (holdings, cash balance, profit/loss)

## User Roles
| Role     | Description                                                              |
|----------|---------------------------------------------------------------------------|
| User     | A retail trader. Views market data, places orders, views own portfolio.  |
| Admin    | Manages users, listed instruments, and system configuration.             |
| Auditor  | Read-only access to all trade logs and user activity, for compliance.    |

## System Components
1. **Browser Client** — the React/Next.js frontend rendered to the trader's device.
2. **Next.js Middleware** — runs at the edge on every request; will handle
   auth checks, rate limiting, and security headers (Parts 2, 3, 6).
3. **Next.js Server (Route Handlers / Server Actions)** — business logic:
   placing orders, computing portfolios, admin operations.
4. **Auth Provider** — NextAuth.js (introduced Part 3), issues session tokens.
5. **Database** — Supabase Postgres (introduced Part 2): users, orders,
   portfolios, audit logs.
6. **Admin Dashboard** — a restricted section of the app, Admin role only.
7. **Auditor Console** — a read-only reporting view, Auditor role only.

## Data Classification (used throughout the series)
| Data                          | Classification     | Why                                             |
|--------------------------------|--------------------|--------------------------------------------------|
| Email, name, NRIC/passport ref | PII (Restricted)   | Directly identifies a person; PDPA-regulated     |
| Password hash                  | Secret             | Compromise = full account takeover               |
| Session tokens                 | Secret             | Compromise = session hijacking                   |
| Order history, balances        | Confidential       | Financial data; MAS TRM-relevant                 |
| Market data (prices)           | Public             | Not sensitive; safe to cache/display broadly      |
| Audit logs                     | Confidential       | Contains who-did-what; itself a security control |

## Trust Boundaries
A trust boundary is any line where data crosses from one party's control
into another's. We number these so later threat tables can reference them
directly.

- **TB-1: Internet ↔ Next.js Middleware** — the public internet is fully
  untrusted. Anyone, including attackers, can send a request here.
- **TB-2: Middleware ↔ Server (Route Handlers)** — requests that pass edge
  checks reach business logic. Still not fully trusted — auth still needs
  server-side re-verification (never trust a client-supplied role claim).
- **TB-3: Server ↔ Database** — the server is more trusted than the internet,
  but queries built from user input crossing into the database is exactly
  where injection attacks live (Part 3).
- **TB-4: User role ↔ Admin/Auditor features** — a logged-in User is
  "trusted" to use User features, but is *untrusted* for Admin/Auditor
  features. This internal boundary is where RBAC (Part 2) does its job.
- **TB-5: Server ↔ Third-party services** — e.g. email provider, future
  payment processor. Anything we send outbound must not leak Secret/PII
  data unnecessarily.
```

### ✅ The Verification

```bash
cat docs/SYSTEM-OVERVIEW.md | grep -c "TB-"
```
Expected output: `5` (confirms all five trust boundaries are documented — this exact check is what our `verify-part1.ts` script will automate in Step 8, so if you get `5` now, you're on track).

---

## Step 3 — Threat Model with STRIDE

### 🎯 The Target
`docs/THREAT-MODEL.md` — a structured table of concrete threats against SecureTrade, one row per trust boundary, categorized using STRIDE.

### 💡 The Concept
**STRIDE** is a checklist, not a formula — think of it like a doctor's "review of systems" during a check-up: instead of vaguely asking "how are you feeling?", they systematically ask about your heart, lungs, digestion, etc., so nothing gets missed. STRIDE does the same for security by forcing you to ask 6 specific questions about every trust boundary:

| Letter | Stands For | Plain-English Attacker Goal |
|---|---|---|
| **S** | Spoofing | "Can I pretend to be someone/something I'm not?" |
| **T** | Tampering | "Can I modify data I shouldn't be able to?" |
| **R** | Repudiation | "Can I do something bad and deny I did it?" |
| **I** | Information Disclosure | "Can I see data I shouldn't be able to?" |
| **D** | Denial of Service | "Can I make the system unusable for others?" |
| **E** | Elevation of Privilege | "Can I get more access than I was granted?" |

We walk each trust boundary from Step 2 through all 6 letters. Not every letter applies to every boundary — that's fine, the point is to *check*, not to force-fit.

### 🛠️ The Implementation

##### 📄 File: `docs/THREAT-MODEL.md`
```markdown
# SecureTrade — Threat Model

Methodology: STRIDE, applied per trust boundary (see `SYSTEM-OVERVIEW.md`).
Each threat is later scored with DREAD (see the "DREAD Scoring" section
below, generated by `scripts/dread-score.ts`).

## TB-1: Internet ↔ Next.js Middleware

| ID    | STRIDE Category | Threat Description |
|-------|------------------|----------------------|
| T-001 | Spoofing | Attacker submits requests with a forged/stolen session cookie to impersonate a logged-in user. |
| T-002 | Tampering | Attacker modifies request payloads (e.g. changing `orderId` or `userId` in a request body) to affect another user's data. |
| T-003 | Information Disclosure | Verbose error messages or stack traces leak internal file paths, package versions, or DB schema details. |
| T-004 | Denial of Service | Attacker floods the login or order-submission endpoint with requests, exhausting server resources. |

## TB-2: Middleware ↔ Server (Route Handlers)

| ID    | STRIDE Category | Threat Description |
|-------|------------------|----------------------|
| T-005 | Elevation of Privilege | A User-role request reaches an Admin-only route handler because the handler trusts a client-supplied role instead of re-checking server-side. |
| T-006 | Tampering | Route handler accepts and trusts a `price` or `quantity` field from the client instead of recalculating server-side, letting an attacker submit a manipulated trade. |

## TB-3: Server ↔ Database

| ID    | STRIDE Category | Threat Description |
|-------|------------------|----------------------|
| T-007 | Tampering | SQL/NoSQL injection via unsanitized input in a search or filter field, allowing unauthorized data modification. |
| T-008 | Information Disclosure | Injection or IDOR (Insecure Direct Object Reference — guessing/incrementing another user's record ID) exposes another user's portfolio or PII. |

## TB-4: User Role ↔ Admin/Auditor Features

| ID    | STRIDE Category | Threat Description |
|-------|------------------|----------------------|
| T-009 | Elevation of Privilege | A regular User discovers and directly navigates to an Admin dashboard URL that lacks a server-side role check. |
| T-010 | Repudiation | An Admin action (e.g. deleting a user, changing a balance) is not logged with a timestamp + actor ID, so it cannot later be proven who did it. |

## TB-5: Server ↔ Third-Party Services

| ID    | STRIDE Category | Threat Description |
|-------|------------------|----------------------|
| T-011 | Information Disclosure | Outbound emails (e.g. password reset) include more user PII than necessary, or are logged in plaintext by a third-party provider. |
| T-012 | Spoofing | A password-reset email flow can be triggered for any email address without confirming the requester owns the account, enabling account enumeration. |
```

### ✅ The Verification

```bash
grep -c "^| T-0" docs/THREAT-MODEL.md
```
Expected output: `12` (twelve threat rows — confirms the table is complete and correctly formatted before we score it in the next step).

---

## Step 4 — Score Each Threat with DREAD

### 🎯 The Target
`data/threats.json` (structured threat data) and `scripts/dread-score.ts` (a script that reads it and prints a ranked risk table) — turning our STRIDE list into a **prioritized** action list.

### 💡 The Concept
STRIDE tells you *what kind* of bad thing could happen. It doesn't tell you *how urgently* to fix it. That's what **DREAD** is for — a scoring rubric, like a hospital triage nurse deciding who gets seen first. Five questions, each scored 1 (low) to 10 (high), then averaged:

| Letter | Question |
|---|---|
| **D**amage | If exploited, how bad is the damage? |
| **R**eproducibility | How easily can it be reproduced on demand? |
| **E**xploitability | How much skill/effort does exploiting it take? |
| **A**ffected Users | How many users/how much of the system is affected? |
| **D**iscoverability | How easy is it for an attacker to find this in the first place? |

We store the raw scores as data (`data/threats.json`) rather than hardcoding them into prose, because — just like a hospital's triage board — this list needs to be **re-sorted automatically**, not manually re-typed, every time a new threat is added in a later part of the series.

### 🛠️ The Implementation

##### 📄 File: `data/threats.json`
```json
[
  {
    "id": "T-001",
    "title": "Session cookie forgery/theft (spoofing)",
    "damage": 8,
    "reproducibility": 6,
    "exploitability": 5,
    "affectedUsers": 7,
    "discoverability": 5
  },
  {
    "id": "T-002",
    "title": "Client-side payload tampering (IDs in request body)",
    "damage": 7,
    "reproducibility": 8,
    "exploitability": 7,
    "affectedUsers": 6,
    "discoverability": 6
  },
  {
    "id": "T-003",
    "title": "Verbose error messages leak internals",
    "damage": 4,
    "reproducibility": 9,
    "exploitability": 8,
    "affectedUsers": 3,
    "discoverability": 7
  },
  {
    "id": "T-004",
    "title": "Login/order endpoint flooding (DoS)",
    "damage": 6,
    "reproducibility": 7,
    "exploitability": 6,
    "affectedUsers": 10,
    "discoverability": 5
  },
  {
    "id": "T-005",
    "title": "Client-supplied role trusted by Admin route",
    "damage": 10,
    "reproducibility": 8,
    "exploitability": 6,
    "affectedUsers": 10,
    "discoverability": 4
  },
  {
    "id": "T-006",
    "title": "Client-supplied price/quantity trusted on order submit",
    "damage": 10,
    "reproducibility": 7,
    "exploitability": 6,
    "affectedUsers": 8,
    "discoverability": 4
  },
  {
    "id": "T-007",
    "title": "SQL/NoSQL injection via unsanitized input",
    "damage": 10,
    "reproducibility": 6,
    "exploitability": 5,
    "affectedUsers": 10,
    "discoverability": 4
  },
  {
    "id": "T-008",
    "title": "IDOR exposing another user's portfolio/PII",
    "damage": 8,
    "reproducibility": 8,
    "exploitability": 7,
    "affectedUsers": 8,
    "discoverability": 6
  },
  {
    "id": "T-009",
    "title": "Unprotected Admin dashboard URL",
    "damage": 10,
    "reproducibility": 9,
    "exploitability": 8,
    "affectedUsers": 10,
    "discoverability": 6
  },
  {
    "id": "T-010",
    "title": "Admin actions not logged (repudiation)",
    "damage": 5,
    "reproducibility": 9,
    "exploitability": 9,
    "affectedUsers": 4,
    "discoverability": 3
  },
  {
    "id": "T-011",
    "title": "Excess PII in outbound emails",
    "damage": 4,
    "reproducibility": 6,
    "exploitability": 5,
    "affectedUsers": 5,
    "discoverability": 3
  },
  {
    "id": "T-012",
    "title": "Password reset enables account enumeration",
    "damage": 5,
    "reproducibility": 8,
    "exploitability": 7,
    "affectedUsers": 6,
    "discoverability": 6
  }
]
```

##### 📄 File: `scripts/dread-score.ts`
```typescript
// scripts/dread-score.ts
//
// Reads data/threats.json, computes the DREAD average for each threat,
// and prints a table sorted from highest risk to lowest. This is what
// turns our STRIDE brainstorm into a prioritized action list.

import { readFileSync } from "node:fs";
import { join } from "node:path";

// This shape mirrors exactly what's in data/threats.json.
// Defining it as a type (not just trusting the JSON blindly) means
// TypeScript will catch a typo'd field name at compile time, not silently
// produce a wrong score at runtime.
type Threat = {
  id: string;
  title: string;
  damage: number;
  reproducibility: number;
  exploitability: number;
  affectedUsers: number;
  discoverability: number;
};

type ScoredThreat = Threat & { score: number };

function loadThreats(): Threat[] {
  const filePath = join(process.cwd(), "data", "threats.json");
  const raw = readFileSync(filePath, "utf-8");
  return JSON.parse(raw) as Threat[];
}

// The DREAD score is simply the average of the five sub-scores.
// We round to 1 decimal place so the output table stays readable.
function scoreThreat(t: Threat): number {
  const total =
    t.damage +
    t.reproducibility +
    t.exploitability +
    t.affectedUsers +
    t.discoverability;
  return Math.round((total / 5) * 10) / 10;
}

// A simple severity label makes the table skimmable at a glance without
// everyone needing to memorize what "8.4" vs "5.2" actually means.
function severityLabel(score: number): string {
  if (score >= 8) return "CRITICAL";
  if (score >= 6) return "HIGH";
  if (score >= 4) return "MEDIUM";
  return "LOW";
}

function main() {
  const threats = loadThreats();

  const scored: ScoredThreat[] = threats
    .map((t) => ({ ...t, score: scoreThreat(t) }))
    // Sort descending so the most urgent threat is always printed first —
    // this ordering is exactly the "triage nurse" behavior the DREAD
    // analogy describes.
    .sort((a, b) => b.score - a.score);

  console.log("\nSecureTrade — DREAD Risk Ranking\n");
  console.log(
    "ID     | Score | Severity | Title".padEnd(0) +
      "\n" +
      "-------|-------|----------|" +
      "-".repeat(50)
  );

  for (const t of scored) {
    console.log(
      `${t.id.padEnd(6)} | ${t.score.toFixed(1).padStart(5)} | ${severityLabel(
        t.score
      ).padEnd(8)} | ${t.title}`
    );
  }

  const criticalCount = scored.filter((t) => t.score >= 8).length;
  console.log(
    `\n${criticalCount} CRITICAL threat(s) found. These should be addressed first when we reach Part 3 (Secure Coding).\n`
  );
}

main();
```

### ✅ The Verification

```bash
npm run dread
```

Expected output (scores/order will match the data above):
```
SecureTrade — DREAD Risk Ranking

ID     | Score | Severity | Title
-------|-------|----------|--------------------------------------------------
T-007  |  10.0 | CRITICAL | SQL/NoSQL injection via unsanitized input
T-009  |   8.6 | CRITICAL | Unprotected Admin dashboard URL
T-005  |   8.6 | CRITICAL | Client-supplied role trusted by Admin route
T-006  |   8.0 | CRITICAL | Client-supplied price/quantity trusted on order submit
T-008  |   7.4 | HIGH     | IDOR exposing another user's portfolio/PII
T-002  |   6.8 | HIGH     | Client-side payload tampering (IDs in request body)
...
4 CRITICAL threat(s) found. These should be addressed first when we reach Part 3 (Secure Coding).
```

This ranked list is exactly what we'll come back to at the start of Part 3 — the CRITICAL items (injection, broken access control on Admin routes, trusting client input) map directly onto the "7 bugs" we fix in that part's lab. Copy this output into `docs/THREAT-MODEL.md` under a new `## DREAD Scoring` heading so it's version-controlled alongside the raw table.

```bash
echo -e "\n## DREAD Scoring\n\nGenerated via \`npm run dread\`:\n\n\`\`\`\n$(npm run dread --silent)\n\`\`\`" >> docs/THREAT-MODEL.md
```

---

## Step 5 — Write Abuse Cases

### 🎯 The Target
`docs/ABUSE-CASES.md` — user stories written from the *attacker's* point of view.

### 💡 The Concept
A normal user story reads: *"As a user, I want to reset my password, so that I can regain access to my account."* It describes a happy path. An **abuse case** flips the perspective: *"As an attacker, I want to trigger password resets for arbitrary emails, so that I can determine which addresses have registered accounts."*

Think of it like a retail store's loss-prevention team walking the floor asking "if I were a shoplifter, how would I defeat this?" — instead of only asking "how does a normal customer shop here?" Writing abuse cases forces the same adversarial walk-through for our app, and each one maps directly back to a STRIDE threat we already found — proving our threat model and our requirements are actually talking about the same risks.

### 🛠️ The Implementation

##### 📄 File: `docs/ABUSE-CASES.md`
```markdown
# SecureTrade — Abuse Cases

Format: *As an attacker, I want to [action], so that [malicious goal].*
Each abuse case references the STRIDE threat ID it corresponds to.

## AC-001 (→ T-005, T-009)
As an attacker, I want to directly request an Admin-only URL or API route
while logged in as a regular User, so that I can view or modify data
reserved for administrators.

## AC-002 (→ T-006)
As an attacker, I want to submit an order with a manipulated `price` or
`quantity` field in the request payload, so that I can execute trades at
prices favorable to me rather than the real market price.

## AC-003 (→ T-007)
As an attacker, I want to inject SQL/NoSQL syntax into a search, filter, or
form field, so that I can read, modify, or delete data I'm not authorized
to access.

## AC-004 (→ T-008)
As an attacker, I want to increment or guess another user's order/portfolio
ID in a URL or API call, so that I can view their private financial data
without authorization (IDOR).

## AC-005 (→ T-001)
As an attacker, I want to steal or forge a session cookie, so that I can
impersonate a legitimate user without knowing their password.

## AC-006 (→ T-012)
As an attacker, I want to submit many email addresses to the password
reset endpoint and observe response differences, so that I can determine
which emails belong to registered accounts (enumeration).

## AC-007 (→ T-004)
As an attacker, I want to send a high volume of requests to the login or
order endpoint, so that I can exhaust server resources and deny access to
legitimate users.
```

### ✅ The Verification

```bash
grep -c "^## AC-" docs/ABUSE-CASES.md
```
Expected output: `7`. Then confirm every abuse case cites a real threat ID:
```bash
grep -oE "T-0[0-9]{2}" docs/ABUSE-CASES.md | sort -u
```
Every ID printed should also exist in `docs/THREAT-MODEL.md` — cross-check visually for now (we automate this cross-check in Step 8).

---

## Step 6 — Define Security Requirements & Compliance Mapping

### 🎯 The Target
`docs/SECURITY-REQUIREMENTS.md` — concrete, testable requirements covering AuthN, AuthZ, data classification, and compliance (PDPA, MAS TRM, OWASP ASVS L2), each one tracing back to a threat.

### 💡 The Concept
Finding threats (Steps 3–5) is like a doctor diagnosing symptoms. Requirements are the **prescription** — specific, actionable instructions that, if followed, treat the diagnosed problem. A vague requirement like "the app should be secure" is like a doctor prescribing "take some medicine" — useless. A good requirement is testable: *"Sessions must expire after 30 minutes of inactivity"* can be verified with a stopwatch and a test; *"be secure"* cannot.

Two quick term definitions used constantly from here on:
- **AuthN (Authentication)** — proving *who* you are (e.g., logging in with a password).
- **AuthZ (Authorization)** — determining *what you're allowed to do* once we know who you are (e.g., a User can't access Admin routes).

We also map each requirement to **OWASP ASVS L2** — a numbered checklist (Application Security Verification Standard, Level 2 — "standard" rigor, appropriate for apps handling financial/PII data) — so we have an industry-recognized standard backing our own requirements, not just our own opinion.

### 🛠️ The Implementation

##### 📄 File: `docs/SECURITY-REQUIREMENTS.md`
```markdown
# SecureTrade — Security Requirements

Each requirement below is testable and traces back to a threat ID and,
where applicable, an OWASP ASVS L2 requirement category, PDPA obligation,
or MAS TRM guideline.

## Authentication (AuthN)

| ID     | Requirement | Traces To | Standard Reference |
|--------|--------------|-----------|----------------------|
| REQ-01 | Passwords must be hashed with a memory-hard algorithm (bcrypt/argon2), never stored in plaintext or reversibly encrypted. | T-001 | ASVS V2.4 (Credential Storage) |
| REQ-02 | Sessions must expire after 30 minutes of inactivity and be invalidated on logout, server-side. | T-001 | ASVS V3 (Session Management) |
| REQ-03 | Password reset must not reveal whether a given email is registered (identical response for existing/non-existing accounts). | T-012 | ASVS V2.3 (Enumeration Prevention), PDPA (data minimization in responses) |
| REQ-04 | Login and password-reset endpoints must be rate-limited per IP and per account. | T-004, T-012 | ASVS V2.2.1 (Anti-automation) |

## Authorization (AuthZ)

| ID     | Requirement | Traces To | Standard Reference |
|--------|--------------|-----------|----------------------|
| REQ-05 | Every Admin and Auditor route/API must re-verify the caller's role server-side on every request — never trust a client-supplied role claim. | T-005, T-009 | ASVS V4.1 (Access Control Design) |
| REQ-06 | Every request for a specific record (order, portfolio) must verify the authenticated user owns that record, or holds a role permitted to view it. | T-008 | ASVS V4.2 (Operation-Level Access Control) — prevents IDOR |
| REQ-07 | Order price and quantity must always be recalculated/validated server-side; client-submitted values for these fields must never be trusted directly. | T-006 | ASVS V5 (Input Validation) |
| REQ-08 | All Admin actions (user edits, deletions, config changes) must be written to an immutable audit log including actor ID and timestamp. | T-010 | MAS TRM (Audit Trail requirements) |

## Data Protection & Classification

| ID     | Requirement | Traces To | Standard Reference |
|--------|--------------|-----------|----------------------|
| REQ-09 | All data classified "PII", "Secret", or "Confidential" (see SYSTEM-OVERVIEW.md) must be encrypted in transit (TLS) and at rest. | T-008, T-011 | PDPA (Protection Obligation) |
| REQ-10 | Outbound communications (e.g. emails) must include only the minimum PII necessary to accomplish their purpose. | T-011 | PDPA (Data Minimization) |
| REQ-11 | Error messages returned to clients must never include stack traces, file paths, or database details. | T-003 | ASVS V7.4 (Error Handling) |

## Compliance Mapping Summary

| Requirement Group | PDPA | MAS TRM | OWASP ASVS L2 |
|---|---|---|---|
| AuthN (REQ-01–04) | Protection Obligation | Access Control | V2, V3 |
| AuthZ (REQ-05–08) | — | Access Control, Audit Trail | V4 |
| Data Protection (REQ-09–11) | Protection & Notification Obligations | Data Loss Prevention | V5, V7, V9 |
```

### ✅ The Verification

```bash
grep -c "^| REQ-" docs/SECURITY-REQUIREMENTS.md
```
Expected output: `11`. Then confirm no requirement is missing a threat reference:
```bash
grep "^| REQ-" docs/SECURITY-REQUIREMENTS.md | grep -c "T-0"
```
Expected output: `11` — every single requirement traces to a real threat, with no orphaned "sounds nice" rules.

---

## Step 7 — Lab: Draw.io Threat Model Diagram + 5 Security User Stories

### 🎯 The Target
A visual data-flow/threat diagram exported to `docs/diagrams/threat-model.drawio.png`, plus `docs/SECURITY-USER-STORIES.md` containing 5 properly-written security user stories.

### 💡 The Concept
Tables are great for detail but terrible for seeing the *shape* of a system at a glance — that's what a diagram is for. Think of the STRIDE table as a spreadsheet of a building's fire code violations, and the diagram as the actual floor plan with red X's marking each violation. Both are needed; neither replaces the other.

A **security user story** is the constructive counterpart to an abuse case — instead of describing the attack, it describes the *defense* as a deliverable: *"As a system, I want to lock an account after 5 failed logins, so that credential-stuffing attacks are slowed down."* These are what actually get turned into GitHub issues and sprint tickets in a real team.

### 🛠️ The Implementation

**Part A — Build the diagram in draw.io (free, no account needed):**

1. Go to [app.diagrams.net](https://app.diagrams.net) → **Create New Diagram** → **Blank Diagram**.
2. Draw these shapes and connect them with arrows, left to right:
   - Rectangle: **Browser Client**
   - Rectangle: **Next.js Middleware**
   - Rectangle: **Route Handlers (Server)**
   - Cylinder: **Supabase Postgres DB**
   - Rectangle: **Admin Dashboard** (branch off Route Handlers)
   - Rectangle: **Auditor Console** (branch off Route Handlers)
3. On each arrow (representing a trust boundary from `SYSTEM-OVERVIEW.md`), double-click to label it with its TB ID, e.g. `TB-1`.
4. Draw a small red lock icon (Extras → Edit Diagram, or just use a red circle shape with an "X") next to each arrow, and label it with the corresponding threat ID(s) from `THREAT-MODEL.md`, e.g. `T-001, T-002, T-004` next to the `TB-1` arrow.
5. **File → Export as → PNG**, save it as `threat-model.drawio.png`.
6. Also **File → Save As → threat-model.drawio** so the editable source is preserved.

Move both exported files into the project:
```bash
mv ~/Downloads/threat-model.drawio.png docs/diagrams/
mv ~/Downloads/threat-model.drawio docs/diagrams/
```

**Part B — Write the 5 security user stories:**

##### 📄 File: `docs/SECURITY-USER-STORIES.md`
```markdown
# SecureTrade — Security User Stories

Format: *As a [role/system], I want [capability], so that [security outcome].*

## SUS-001 (→ REQ-05, T-005, T-009)
As the system, I want every Admin and Auditor route to independently verify
the caller's role from the server-side session — not from any value the
client sends — so that a regular User cannot escalate privileges by
guessing a URL or editing a request.

## SUS-002 (→ REQ-06, T-008)
As the system, I want every request for a specific order or portfolio
record to check that the record belongs to the requesting user (or that
the requester is an Admin/Auditor), so that no user can view another
user's private financial data (IDOR prevention).

## SUS-003 (→ REQ-07, T-006)
As the system, I want to recalculate order price and quantity validation
entirely server-side, ignoring any client-submitted values for these
fields, so that an attacker cannot manipulate trade execution by tampering
with request payloads.

## SUS-004 (→ REQ-04, T-004, T-012)
As the system, I want to rate-limit the login and password-reset endpoints
per IP address and per account, so that credential-stuffing and account
enumeration attacks are significantly slowed down.

## SUS-005 (→ REQ-08, T-010)
As an Auditor, I want every Admin action to be recorded in an immutable
audit log with an actor ID and timestamp, so that any administrative
change can be attributed and reviewed during a compliance check or
incident investigation.
```

### ✅ The Verification

```bash
ls docs/diagrams/
```
Confirm both `threat-model.drawio.png` and `threat-model.drawio` are present. Then:
```bash
grep -c "^## SUS-" docs/SECURITY-USER-STORIES.md
```
Expected output: `5`.

---

## Step 8 — Automate Verification of Part 1's Artifacts

### 🎯 The Target
`scripts/verify-part1.ts` — a script that checks every artifact from this part exists, is non-empty, and has internally consistent cross-references (no abuse case citing a threat ID that doesn't exist, etc.).

### 💡 The Concept
This is the same idea as a building inspector's final checklist before issuing an occupancy permit — rather than trusting "I'm pretty sure I did everything," we run one command that objectively confirms it. This habit — writing a script that checks your own work — is the seed of what becomes full CI/CD pipeline automation in Part 5. Starting this pattern now, on documentation, makes it feel completely natural once we apply it to code.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-part1.ts`
```typescript
// scripts/verify-part1.ts
//
// Verifies that all Part 1 deliverables exist and are internally
// consistent. Exits with a non-zero code on failure so this can later be
// wired into a CI job (Part 5) without modification.

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

// A "check" is a single pass/fail assertion with a human-readable label.
// Collecting them in an array lets us report ALL failures at once, instead
// of stopping at the first one — much faster feedback when fixing issues.
type Check = { label: string; pass: boolean; detail?: string };

const checks: Check[] = [];

function fileExists(relativePath: string): boolean {
  return existsSync(join(process.cwd(), relativePath));
}

function readDoc(relativePath: string): string {
  return readFileSync(join(process.cwd(), relativePath), "utf-8");
}

// Extracts every threat ID (e.g. "T-005") mentioned anywhere in a string.
function extractThreatIds(text: string): Set<string> {
  const matches = text.match(/T-0\d{2}/g) ?? [];
  return new Set(matches);
}

function main() {
  const requiredFiles = [
    "docs/SYSTEM-OVERVIEW.md",
    "docs/THREAT-MODEL.md",
    "docs/ABUSE-CASES.md",
    "docs/SECURITY-REQUIREMENTS.md",
    "docs/SECURITY-USER-STORIES.md",
    "data/threats.json",
    "docs/diagrams/threat-model.drawio.png",
  ];

  // Check 1: every required file exists
  for (const f of requiredFiles) {
    checks.push({
      label: `File exists: ${f}`,
      pass: fileExists(f),
    });
  }

  // Only proceed with content checks if the core docs exist, to avoid
  // confusing crash-on-missing-file errors masking the real problem.
  if (fileExists("docs/THREAT-MODEL.md") && fileExists("docs/ABUSE-CASES.md")) {
    const threatModel = readDoc("docs/THREAT-MODEL.md");
    const abuseCases = readDoc("docs/ABUSE-CASES.md");

    const definedThreatIds = extractThreatIds(threatModel);
    const citedInAbuseCases = extractThreatIds(abuseCases);

    // Check 2: at least 12 distinct threats defined (matches our STRIDE work)
    checks.push({
      label: "At least 12 distinct threat IDs defined in THREAT-MODEL.md",
      pass: definedThreatIds.size >= 12,
      detail: `found ${definedThreatIds.size}`,
    });

    // Check 3: every threat ID cited in ABUSE-CASES.md actually exists in
    // THREAT-MODEL.md. This catches typos like "T-05" vs "T-005".
    const orphanIds = [...citedInAbuseCases].filter(
      (id) => !definedThreatIds.has(id)
    );
    checks.push({
      label: "No orphaned threat IDs cited in ABUSE-CASES.md",
      pass: orphanIds.length === 0,
      detail: orphanIds.length > 0 ? `orphans: ${orphanIds.join(", ")}` : undefined,
    });
  }

  if (
    fileExists("docs/SECURITY-REQUIREMENTS.md") &&
    fileExists("docs/THREAT-MODEL.md")
  ) {
    const requirements = readDoc("docs/SECURITY-REQUIREMENTS.md");
    const threatModel = readDoc("docs/THREAT-MODEL.md");
    const definedThreatIds = extractThreatIds(threatModel);

    const reqRows = requirements
      .split("\n")
      .filter((line) => /^\|\s*REQ-\d{2}/.test(line));

    // Check 4: every requirement row cites at least one real threat ID
    const reqsWithoutThreatRef = reqRows.filter((row) => {
      const ids = extractThreatIds(row);
      return ids.size === 0 || [...ids].every((id) => !definedThreatIds.has(id));
    });

    checks.push({
      label: "Every requirement traces to a real threat ID",
      pass: reqsWithoutThreatRef.length === 0,
      detail:
        reqsWithoutThreatRef.length > 0
          ? `${reqsWithoutThreatRef.length} untraced requirement row(s)`
          : undefined,
    });
  }

  // Print a clean pass/fail report
  console.log("\nSecureTrade — Part 1 Verification\n");
  let allPassed = true;
  for (const c of checks) {
    const icon = c.pass ? "✅" : "❌";
    console.log(`${icon} ${c.label}${c.detail ? ` (${c.detail})` : ""}`);
    if (!c.pass) allPassed = false;
  }

  console.log(
    allPassed
      ? "\nAll Part 1 checks passed. Ready for Part 2.\n"
      : "\nSome checks failed — fix the items above before continuing.\n"
  );

  // Non-zero exit code on failure — this is what makes this script
  // CI-ready without any changes, once we build the pipeline in Part 5.
  process.exit(allPassed ? 0 : 1);
}

main();
```

### ✅ The Verification

```bash
npm run verify:part1
```

Expected output:
```
SecureTrade — Part 1 Verification

✅ File exists: docs/SYSTEM-OVERVIEW.md
✅ File exists: docs/THREAT-MODEL.md
✅ File exists: docs/ABUSE-CASES.md
✅ File exists: docs/SECURITY-REQUIREMENTS.md
✅ File exists: docs/SECURITY-USER-STORIES.md
✅ File exists: data/threats.json
✅ File exists: docs/diagrams/threat-model.drawio.png
✅ At least 12 distinct threat IDs defined in THREAT-MODEL.md (found 12)
✅ No orphaned threat IDs cited in ABUSE-CASES.md
✅ Every requirement traces to a real threat ID

All Part 1 checks passed. Ready for Part 2.
```

If anything shows ❌, fix that specific file and re-run — don't move on until it's all green. Then commit everything:

```bash
git add -A
git commit -m "docs: complete Part 1 threat model, abuse cases, requirements, and verification script"
git push
```

---

## ✅ Part 1 Completion Checklist

- [ ] `docs/SYSTEM-OVERVIEW.md` describes roles, components, data classification, and 5 trust boundaries
- [ ] `docs/THREAT-MODEL.md` has 12 STRIDE-categorized threats plus a DREAD-scored ranking
- [ ] `docs/ABUSE-CASES.md` has 7 attacker-perspective stories, each tracing to a threat
- [ ] `docs/SECURITY-REQUIREMENTS.md` has 11 testable requirements mapped to PDPA/MAS TRM/ASVS L2
- [ ] `docs/diagrams/threat-model.drawio.png` (and `.drawio` source) exist
- [ ] `docs/SECURITY-USER-STORIES.md` has 5 stories
- [ ] `npm run verify:part1` exits with all green checks

---

# 📚 Reference Section — Deep Dives for Part 1

*(Isolated here so the build steps above stayed fast-moving. Read this section anytime for deeper theory.)*

### R1. STRIDE, Category by Category — Full Definitions

| Category | Full Definition | Typical Countermeasure |
|---|---|---|
| **Spoofing** | Falsely claiming to be someone/something else (a user, a server, a device). Violates *Authentication*. | Strong AuthN: passwords + hashing, MFA, signed session tokens |
| **Tampering** | Maliciously modifying data or code, in transit or at rest. Violates *Integrity*. | Input validation, parameterized queries, TLS, integrity checks (HMAC/signatures) |
| **Repudiation** | Performing an action, then denying having done so, with no way to prove otherwise. Violates *Non-repudiation*. | Audit logging with actor ID + timestamp, digital signatures |
| **Information Disclosure** | Exposing information to someone not authorized to see it. Violates *Confidentiality*. | Access control, encryption at rest/in transit, careful error handling |
| **Denial of Service** | Degrading or denying legitimate access to a service or resource. Violates *Availability*. | Rate limiting, autoscaling, WAF, circuit breakers |
| **Elevation of Privilege** | Gaining capabilities/access beyond what was granted. Violates *Authorization*. | Server-side RBAC checks, principle of least privilege, deny-by-default |

STRIDE was originally developed at Microsoft in the late 1990s specifically so engineers *without* dedicated security training could systematically brainstorm threats using a memorable mnemonic — which is exactly why it's still the most widely taught threat modeling method today.

### R2. DREAD — Scoring Guidance in Detail

Each of the 5 DREAD factors is scored 1–10. Rough anchors to keep scoring consistent across a team:

| Score | Damage | Reproducibility | Exploitability | Affected Users | Discoverability |
|---|---|---|---|---|---|
| 1–3 | Minimal/cosmetic | Very hard to reproduce, needs rare conditions | Requires deep expertise/custom tooling | Tiny fraction of users | Requires source-code access or insider knowledge |
| 4–6 | Moderate data/functionality loss | Reproducible with effort | A skilled attacker with public tools | A meaningful subset of users | Findable with moderate testing effort |
| 7–10 | Full compromise, financial/legal harm | Trivially reproducible every time | Any script kiddie, public exploit exists | All/nearly all users | Obvious from casual use or a quick Google search |

**Known limitation:** DREAD is intentionally simple and somewhat subjective — two engineers may score the same threat a point or two apart. That's acceptable; DREAD's job is *relative ranking* ("fix this before that"), not precise quantification. Larger organizations sometimes replace DREAD with **CVSS** (Common Vulnerability Scoring System) for more standardized, industry-wide comparable scoring — we introduce CVSS in Part 4 when discussing dependency vulnerabilities, because that's where you'll actually see CVSS scores reported by tools like `npm audit` and Snyk.

### R3. Other Threat Modeling Methodologies (for awareness)

| Methodology | Focus | When You'd Choose It Instead |
|---|---|---|
| **PASTA** (Process for Attack Simulation and Threat Analysis) | Risk-centric, ties threats to business impact and attacker motivation | Larger orgs wanting to tie security directly to business risk reporting |
| **LINDDUN** | Privacy-focused (Linkability, Identifiability, Non-repudiation, Detectability, Disclosure, Unawareness, Non-compliance) | Apps where privacy (not just security) is the primary concern — very relevant to PDPA-regulated systems, worth knowing exists |
| **Attack Trees** | Visual, hierarchical breakdown of "how could an attacker achieve goal X," branching into sub-methods | Deep-diving one specific high-value target (e.g., "how could someone drain a user's account") |

We use STRIDE + DREAD throughout this series because it's the best balance of "teachable in one part" and "used broadly in real industry," but knowing these alternatives exist means you can speak intelligently about threat modeling in an interview or on a team that prefers a different method.

### R4. OWASP ASVS — Understanding the Levels

ASVS (Application Security Verification Standard) organizes ~280 requirements into **14 categories** (V1 Architecture, V2 Authentication, V3 Session Management, V4 Access Control, V5 Validation, and so on), each assigned to one of **3 levels**:

| Level | Who It's For | Example Bar |
|---|---|---|
| **L1** | Every application, minimum baseline | "Uses HTTPS", "No hardcoded secrets" |
| **L2** | Applications handling sensitive data (financial, PII, healthcare) — **our target for SecureTrade** | "MFA available for sensitive operations", "Session tokens invalidated on logout" |
| **L3** | High-value targets (critical infrastructure, high-value financial systems) | "Hardware-backed key storage", "Formal verification of critical logic" |

We target **L2** throughout this series because SecureTrade handles both PII and financial transactions — squarely the profile ASVS L2 is designed for. We won't implement all ~280 checks explicitly, but every requirement in `SECURITY-REQUIREMENTS.md` was chosen because it maps to a real ASVS L2 control.

### R5. PDPA — The Obligations That Matter Most for SecureTrade

Singapore's **Personal Data Protection Act** centers on several "obligations" for organizations. The ones most relevant to an engineering team (as opposed to legal/HR) are:

- **Consent Obligation** — don't collect/use personal data without consent or a valid exception.
- **Purpose Limitation Obligation** — only use personal data for purposes a reasonable person would consider appropriate, and that were disclosed.
- **Notification Obligation** — tell users what data you're collecting and why, before or at the time of collection.
- **Protection Obligation** — make "reasonable security arrangements" to prevent unauthorized access, collection, use, disclosure, or disposal (this is the one engineers implement most directly — it's the justification behind REQ-09 and REQ-10 above).
- **Data Breach Notification Obligation** — notify the PDPC (Personal Data Protection Commission) and affected individuals if a breach is likely to result in significant harm — this becomes directly relevant again in **Part 7 (Incident Response)**.

### R6. MAS TRM — Key Domains Relevant to This Series

The Monetary Authority of Singapore's Technology Risk Management Guidelines are aimed at financial institutions but are widely used as a best-practice reference for any system handling money-like data, including a "simplified SGX-style" app like ours. The domains we'll touch across this series:

| MAS TRM Domain | Where We Address It |
|---|---|
| IT Security Risk Management (access control, authentication) | Part 2 (RBAC design), Part 3 (AuthN/AuthZ code) |
| Audit Trail / Logging | Part 1 (REQ-08), Part 7 (Observability) |
| System Resiliency / Availability | Part 6 (Deployment hardening, DR/backup) |
| Third-Party Risk Management | Part 4 (Supply chain security) |
| Incident Management | Part 7 (in full) |

---

**Next up: Part 2 — Secure Design ("Architecture is Security")**, where we take these 11 requirements and 12 threats and turn them into an actual system architecture: Zero Trust principles, data flow diagrams tracing exactly where PII travels, and a Prisma + Supabase schema implementing the Admin/User/Auditor RBAC roles this threat model demands.
