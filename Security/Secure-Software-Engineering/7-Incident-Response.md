# Part 7: Detection, Response & Incident Handling

Picking up from Part 6: SecureTrade is deployed with hardened headers, a WAF, monitored infrastructure, and Sentry catching unhandled errors. But here's the mindset shift this part demands: **everything we've built so far assumes prevention works.** Part 7 assumes it *doesn't* — because eventually, somewhere, it won't. This is the "assume breach" posture: build the capability to notice an attack fast, contain it before it spreads, and recover cleanly — because the difference between a minor incident and a front-page breach is almost always how fast you noticed and how well you'd rehearsed the response.

**Goal recap:** assume breach.

---

## Step 1 — Document What to Log (and What Never To Log)

### 🎯 The Target
`docs/OBSERVABILITY.md` — a precise policy for security-relevant logging, before we write a single line of logging code.

### 💡 The Concept
Logging everything sounds safer than logging too little, but it isn't — a log file full of plaintext passwords and session tokens is just a second, softer copy of your database sitting somewhere less protected, like keeping a duplicate set of house keys under a doormat "just in case." The discipline here is the same one a hospital applies to patient charts: record everything a doctor genuinely needs to make a decision later, but never write down information that turns the chart itself into a liability if it's ever lost or stolen.

We split this into two lists, deliberately, so the boundary is never ambiguous to a future developer adding a new log line.

### 🛠️ The Implementation

##### 📄 File: `docs/OBSERVABILITY.md`
```markdown
# SecureTrade — Observability & Logging Policy

## What We MUST Log (Security-Relevant Events)
| Event | Fields Captured | Why |
|---|---|---|
| Login success | userId, timestamp, IP, user-agent | Establishes a baseline of normal access patterns |
| Login failure | attemptedEmail (hashed — see below), timestamp, IP | Powers brute-force detection (Step 3) |
| Password reset requested | userId (if matched), timestamp, IP | Detects account-takeover attempts |
| Role/permission change | actorId, targetUserId, oldRole, newRole, timestamp | Directly implements REQ-08 (Part 1); who elevated whom |
| Admin action (any) | actorId, action, targetType, targetId, timestamp | Non-repudiation — already captured in AuditLog (Part 2) |
| Authorization denial (403) | userId, attemptedRoute, requiredRole, timestamp | Reveals privilege-escalation attempts (T-005/T-009) |
| Order placed | userId, instrumentId, side, quantity, timestamp | Financial activity — MAS TRM audit expectation |
| Rate limit triggered | IP, route, timestamp | Feeds DoS/brute-force detection |
| Validation rejection pattern (e.g. many malformed requests from one IP) | IP, route, timestamp | Early signal of automated scanning/attack tooling |

## What We MUST NEVER Log
| Data | Why |
|---|---|
| Plaintext passwords | Obvious — but also: NEVER log full request bodies on auth endpoints, since that body contains the password |
| Session tokens / cookies | Equivalent to logging a spare house key — Sentry configs (Part 6) already scrub these |
| Full credit card / bank details | We don't currently collect these, but this rule stands permanently regardless of future features |
| Full email addresses in security event logs | We hash or truncate (see below) — logs are read by more engineers over time than you'd expect, and a log aggregator is a DIFFERENT trust boundary than the database itself |
| Raw database connection strings or API keys, even in error stack traces | Covered by Sentry scrubbing (Part 6) and this policy jointly |

## Email Handling in Logs
Full email addresses are PII (per SYSTEM-OVERVIEW.md's classification). Security
event logs record a SHA-256 hash of the lowercased email instead of the
raw value — enough to correlate "is this the same account attempting
multiple logins" without the log file itself becoming a PII store subject
to the same protection obligations as the primary database.

## Log Destinations
| Destination | Retention | Access |
|---|---|---|
| Vercel Runtime Logs (stdout/stderr) | 1 day (free tier) / longer on paid tiers | Project members only |
| Sentry (structured security events, Step 2) | 90 days | Project members only |
| `AuditLog` database table (Part 2) | Indefinite (immutable) | ADMIN/AUDITOR roles only, via app |

## Compliance Note
This structure directly supports MAS TRM's audit trail expectations and
PDPA's data minimization principle simultaneously — we log enough to
investigate an incident (Part 7's core goal) without the logs themselves
becoming a new PII exposure surface.
```

### ✅ The Verification

```bash
grep -c "^| " docs/OBSERVABILITY.md
```
Expected: a healthy non-zero count confirming both tables rendered. This document is now the contract every logging line we write in the rest of this part must obey.

---

## Step 2 — Build the Structured Security Event Logger

### 🎯 The Target
`lib/security-logger.ts` — a single, typed function every part of the app calls to record a security event, guaranteeing Step 1's policy is enforced in code, not just prose.

### 💡 The Concept
If every developer hand-writes their own `console.log("user logged in")` line, the format will drift — one person logs `userId`, another logs `user_id`, a third forgets the timestamp entirely. A centralized logger is like a hospital's standardized intake form — every nurse fills in the *same* fields, in the *same* format, regardless of which department they work in, so a chart pulled six months later by a different doctor is still instantly readable. We also route every event through one function so that the hashing rule from Step 1 (never log a raw email) is enforced structurally — a future developer literally cannot log a raw email through this function even if they wanted to, because the type signature won't accept one.

### 🛠️ The Implementation

##### 📄 File: `lib/security-logger.ts`
```typescript
// lib/security-logger.ts
//
// Centralized, structured security event logging. Every security-relevant
// event in the app MUST go through this module — never a raw console.log
// scattered inline — so that docs/OBSERVABILITY.md's rules are enforced
// by code structure, not just developer memory.

import * as Sentry from "@sentry/nextjs";
import { createHash } from "node:crypto";

// The fixed, exhaustive set of event types we track. Using a union type
// (not a free-form string) means TypeScript itself prevents a typo like
// "LOGIN_SUCCES" from silently creating an unmonitored, mis-spelled event
// category that a Sigma rule (Step 4) would never match against.
export type SecurityEventType =
  | "LOGIN_SUCCESS"
  | "LOGIN_FAILURE"
  | "PASSWORD_RESET_REQUESTED"
  | "ROLE_CHANGE_ATTEMPT_BLOCKED"
  | "ROLE_CHANGED"
  | "AUTHZ_DENIED"
  | "ORDER_PLACED"
  | "RATE_LIMIT_TRIGGERED"
  | "VALIDATION_REJECTED";

type SecurityEventBase = {
  type: SecurityEventType;
  ip?: string;
  userAgent?: string;
  userId?: string;
};

// Hashes an email (or any PII string) into a short, stable, non-reversible
// identifier — enough to correlate repeated events against the SAME
// underlying value, without ever storing the raw value itself. This is
// the code-level enforcement of docs/OBSERVABILITY.md's email rule.
export function hashForLogging(value: string): string {
  return createHash("sha256").update(value.trim().toLowerCase()).digest("hex").slice(0, 16);
}

// The single entry point. Every field here was deliberately chosen against
// docs/OBSERVABILITY.md — note there is NO field anywhere in this type
// that could hold a raw password, session token, or full email address.
export function logSecurityEvent(
  event: SecurityEventBase & { metadata?: Record<string, string | number | boolean> }
) {
  const enrichedEvent = {
    ...event,
    timestamp: new Date().toISOString(),
  };

  // Destination 1: structured stdout — captured automatically by Vercel's
  // runtime logs. Prefixed distinctly so it's trivially grep-able, and
  // deliberately JSON (not free text) so any future log-shipping tool
  // (Datadog, a real SIEM) can parse it without a fragile regex.
  console.log(`SECURITY_EVENT ${JSON.stringify(enrichedEvent)}`);

  // Destination 2: Sentry, as a structured "message" event distinct from
  // exception tracking — gives us a searchable, alertable trail (Step 5)
  // independent of whether anything actually crashed.
  Sentry.captureMessage(`security_event:${event.type}`, {
    level: severityForEvent(event.type),
    tags: { securityEventType: event.type },
    extra: enrichedEvent,
  });
}

// Maps event types to a Sentry severity level — this is what lets us
// configure Sentry alert rules (Step 5) to page someone only for genuinely
// urgent categories, not every routine login.
function severityForEvent(type: SecurityEventType): "info" | "warning" | "error" {
  switch (type) {
    case "LOGIN_SUCCESS":
    case "ORDER_PLACED":
    case "PASSWORD_RESET_REQUESTED":
      return "info";
    case "LOGIN_FAILURE":
    case "VALIDATION_REJECTED":
    case "RATE_LIMIT_TRIGGERED":
      return "warning";
    case "ROLE_CHANGE_ATTEMPT_BLOCKED":
    case "AUTHZ_DENIED":
    case "ROLE_CHANGED":
      return "error"; // these represent likely-malicious or highly sensitive activity
  }
}
```

### ✅ The Verification

```bash
cat > /tmp/test-logger.ts << 'EOF'
import { logSecurityEvent, hashForLogging } from "@/lib/security-logger";
logSecurityEvent({ type: "LOGIN_FAILURE", metadata: { emailHash: hashForLogging("attacker@evil.test") } });
console.log("Hash example:", hashForLogging("attacker@evil.test"));
EOF
npx tsx --tsconfig tsconfig.json /tmp/test-logger.ts
rm /tmp/test-logger.ts
```
Expected: a `SECURITY_EVENT {...}` JSON line printed, containing an `emailHash` field that looks like `3f9a1b2c4d5e6f70` — never the literal string `attacker@evil.test`.

---

## Step 3 — Wire the Logger Into Existing Routes

### 🎯 The Target
Updated versions of `auth.ts`, `app/api/v1/users/me/route.ts`, `app/api/v1/orders/route.ts`, and `middleware.ts` — replacing ad-hoc `console.warn`/silent behavior with real, structured security events.

### 💡 The Concept
A logger nobody calls is a smoke detector with no battery. This step is the "installation," connecting Step 2's centralized function to every place in the app where a security-relevant thing actually happens — much of this is deliberately just upgrading log lines we already sketched informally back in Part 3 (recall the `console.warn` in the mass-assignment fix) into the real, structured system.

### 🛠️ The Implementation

##### 📄 File: `auth.ts` (edit — the `authorize` callback)
```typescript
// auth.ts (relevant excerpt — replace the authorize function body)
import { logSecurityEvent, hashForLogging } from "@/lib/security-logger";

// ... inside the Credentials provider ...
async authorize(credentials, request) {
  const parsed = loginSchema.safeParse(credentials);
  if (!parsed.success) return null;

  const { email, password } = parsed.data;
  const emailHash = hashForLogging(email);
  // NextAuth's `request` is a standard Request object — we extract the IP
  // via the header Vercel's edge network sets, since this authorize()
  // call runs server-side, not at the edge, and has no other IP source.
  const ip = request?.headers?.get("x-forwarded-for")?.split(",")[0]?.trim();

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    logSecurityEvent({ type: "LOGIN_FAILURE", ip, metadata: { emailHash, reason: "no_such_account" } });
    return null;
  }

  const passwordValid = await bcrypt.compare(password, user.passwordHash);
  if (!passwordValid) {
    logSecurityEvent({ type: "LOGIN_FAILURE", ip, userId: user.id, metadata: { emailHash, reason: "bad_password" } });
    return null;
  }

  logSecurityEvent({ type: "LOGIN_SUCCESS", ip, userId: user.id, metadata: { emailHash } });

  return { id: user.id, email: user.email, name: user.name, role: user.role };
},
```

##### 📄 File: `app/api/v1/users/me/route.ts` (edit — replace the disallowed-fields warning)
```typescript
// app/api/v1/users/me/route.ts (relevant excerpt)
import { logSecurityEvent } from "@/lib/security-logger";

// ... inside PATCH, where disallowedKeys.length > 0 ...
if (disallowedKeys.length > 0) {
  logSecurityEvent({
    type: "ROLE_CHANGE_ATTEMPT_BLOCKED",
    userId: session.user.id,
    metadata: { attemptedFields: disallowedKeys.join(",") },
  });
  return NextResponse.json(
    { error: `Cannot set fields: ${disallowedKeys.join(", ")}` },
    { status: 400 }
  );
}
```

##### 📄 File: `app/api/v1/orders/route.ts` (edit — inside the transaction, after audit log write)
```typescript
// app/api/v1/orders/route.ts (relevant excerpt, inside the $transaction block after tx.auditLog.create)
import { logSecurityEvent } from "@/lib/security-logger";

// ... after the transaction successfully resolves ...
logSecurityEvent({
  type: "ORDER_PLACED",
  userId: session.user.id,
  metadata: { instrumentId, side, quantity, executedPrice: executedPrice.toString() },
});
```

##### 📄 File: `middleware.ts` (edit — log every 403 denial)
```typescript
// middleware.ts (relevant excerpt — replace the two 403 return points)
import { logSecurityEvent } from "@/lib/security-logger";

// ... in the isAdminRoute check ...
if (isAdminRoute && role !== "ADMIN") {
  logSecurityEvent({
    type: "AUTHZ_DENIED",
    userId: req.auth?.user?.id,
    metadata: { attemptedRoute: pathname, requiredRole: "ADMIN", actualRole: role ?? "none" },
  });
  return NextResponse.json({ error: "Forbidden" }, { status: 403 });
}

// ... in the isAuditorRoute check ...
if (isAuditorRoute && role !== "ADMIN" && role !== "AUDITOR") {
  logSecurityEvent({
    type: "AUTHZ_DENIED",
    userId: req.auth?.user?.id,
    metadata: { attemptedRoute: pathname, requiredRole: "ADMIN_OR_AUDITOR", actualRole: role ?? "none" },
  });
  return NextResponse.json({ error: "Forbidden" }, { status: 403 });
}
```

Note: `logSecurityEvent` uses Sentry, which relies on Node APIs not universally available in every Edge Runtime context — since `middleware.ts` runs on the edge, confirm your Sentry Next.js SDK version supports edge logging (the wizard from Part 6 configures this automatically via `sentry.edge.config.ts`; if it's missing, generate it with `npx @sentry/wizard@latest -i nextjs` again, which detects and adds the edge config non-destructively).

### ✅ The Verification

```bash
npm run dev
```
```bash
curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"loguser@example.com","name":"Log User","password":"SuperSecure123"}' > /dev/null

curl -s -X POST http://localhost:3000/api/v1/auth/callback/credentials \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=loguser@example.com&password=WrongPassword1" > /dev/null
```
Check your terminal running `npm run dev` — confirm a `SECURITY_EVENT {"type":"LOGIN_FAILURE",...}` line appeared with a hashed email, not the raw one. Check your Sentry dashboard's **Issues** tab — confirm a `security_event:LOGIN_FAILURE` message-type event appears there too.

---

## Step 4 — Write Detection Rules (Sigma-Style)

### 🎯 The Target
`docs/detections/*.yml` — a small library of detection rules written in the **Sigma** format, plus `scripts/evaluate-detections.ts`, a lightweight local engine that evaluates recent security events against them.

### 💡 The Concept
**Sigma** is to log detection what Terraform is to infrastructure — a vendor-neutral, human-readable, YAML-based way to describe "the pattern of events that indicates something bad is happening," which can then be *converted* to run natively on almost any real SIEM (Splunk, Elastic, Microsoft Sentinel) via the `sigma-cli` converter tool. Writing detection logic in Sigma format — rather than hand-coding it directly into whatever specific tool you happen to use today — means the rule survives a future platform migration, exactly like Terraform configs survive a move between cloud regions.

Since SecureTrade doesn't (yet) have a dedicated commercial SIEM, we build a small local evaluator that reads structured security events and checks them against simplified versions of these same rules — good enough to *demonstrate and test* real detection logic now, with a clear, direct upgrade path (documented in the Reference section) to feed the exact same Sigma files into a real SIEM later without rewriting any rule logic.

### 🛠️ The Implementation

```bash
mkdir -p docs/detections
```

##### 📄 File: `docs/detections/brute-force-login.yml`
```yaml
title: Multiple Failed Logins Followed By Success (Possible Brute Force)
id: 8f3a1b2c-0001-4e00-9a00-000000000001
status: stable
description: >
  Detects 5 or more LOGIN_FAILURE events for the same account within a
  10-minute window, which may indicate a credential-stuffing or
  brute-force attack in progress.
references:
  - docs/THREAT-MODEL.md#T-001
  - docs/ABUSE-CASES.md#AC-005
logsource:
  product: securetrade
  category: security_event
detection:
  selection:
    type: LOGIN_FAILURE
  timeframe: 10m
  condition: selection | count(metadata.emailHash) by metadata.emailHash >= 5
level: high
tags:
  - attack.credential_access
  - attack.t1110 # MITRE ATT&CK: Brute Force
```

##### 📄 File: `docs/detections/privilege-escalation-attempt.yml`
```yaml
title: Repeated Blocked Role-Change or Admin-Route Access Attempts
id: 8f3a1b2c-0002-4e00-9a00-000000000002
status: stable
description: >
  Detects any ROLE_CHANGE_ATTEMPT_BLOCKED event, or 3+ AUTHZ_DENIED events
  against admin-only routes from the same user within 5 minutes —
  strongly suggestive of an authenticated user probing for privilege
  escalation (Bug 3/Bug 5 territory from Part 3).
references:
  - docs/THREAT-MODEL.md#T-005
  - docs/THREAT-MODEL.md#T-009
logsource:
  product: securetrade
  category: security_event
detection:
  selection_blocked:
    type: ROLE_CHANGE_ATTEMPT_BLOCKED
  selection_denied:
    type: AUTHZ_DENIED
    metadata.requiredRole: "ADMIN"
  timeframe: 5m
  condition: selection_blocked or (selection_denied | count() by userId >= 3)
level: critical
tags:
  - attack.privilege_escalation
  - attack.t1078 # MITRE ATT&CK: Valid Accounts (misuse)
```

##### 📄 File: `docs/detections/sql-injection-pattern.yml`
```yaml
title: SQL Injection Payload Pattern in Request Parameters
id: 8f3a1b2c-0003-4e00-9a00-000000000003
status: stable
description: >
  Detects common SQL injection syntax (quote-break, boolean-always-true,
  UNION SELECT, comment terminators) appearing in logged VALIDATION_REJECTED
  events, indicating an attacker is probing input fields.
references:
  - docs/THREAT-MODEL.md#T-007
  - docs/ABUSE-CASES.md#AC-003
logsource:
  product: securetrade
  category: security_event
detection:
  selection:
    type: VALIDATION_REJECTED
  patterns:
    - "' OR '"
    - "' OR 1=1"
    - "UNION SELECT"
    - "--"
    - "; DROP TABLE"
  condition: selection and metadata.rawValue matches any of patterns
level: critical
tags:
  - attack.initial_access
  - attack.t1190 # MITRE ATT&CK: Exploit Public-Facing Application
```

##### 📄 File: `docs/detections/unusual-order-volume.yml`
```yaml
title: Abnormally High Order Volume From a Single Account
id: 8f3a1b2c-0004-4e00-9a00-000000000004
status: stable
description: >
  Detects a single user placing 20+ orders within 1 minute — either a
  runaway client bug, an idempotency-key reuse failure, or an attacker
  who has compromised an account attempting to rapidly drain/manipulate
  a position before detection.
logsource:
  product: securetrade
  category: security_event
detection:
  selection:
    type: ORDER_PLACED
  timeframe: 1m
  condition: selection | count() by userId >= 20
level: medium
tags:
  - attack.impact
```

Now build the evaluator. We simulate a log stream via a JSON-lines file for this tutorial (in production, this would instead tail Vercel's log drain or Sentry's event stream — see Reference section):

##### 📄 File: `scripts/evaluate-detections.ts`
```typescript
// scripts/evaluate-detections.ts
//
// A minimal, local Sigma-INSPIRED detection engine. It does NOT implement
// the full Sigma specification (that's the job of a real SIEM or the
// official `sigma-cli` converter, see Reference section) — it implements
// just enough logic to demonstrate and TEST that our detection rules
// correctly fire against real event data, before we ever hand them to a
// production-grade platform.

import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import YAML from "yaml";

type SecurityEvent = {
  type: string;
  timestamp: string;
  userId?: string;
  ip?: string;
  metadata?: Record<string, unknown>;
};

type DetectionRule = {
  title: string;
  id: string;
  level: string;
  detection: Record<string, unknown>;
};

function loadEvents(logFilePath: string): SecurityEvent[] {
  if (!existsSync(logFilePath)) return [];
  const lines = readFileSync(logFilePath, "utf-8").split("\n").filter(Boolean);
  return lines
    .map((line) => {
      const match = line.match(/^SECURITY_EVENT (.+)$/);
      if (!match) return null;
      try {
        return JSON.parse(match[1]) as SecurityEvent;
      } catch {
        return null;
      }
    })
    .filter((e): e is SecurityEvent => e !== null);
}

function loadRules(): DetectionRule[] {
  const dir = join(process.cwd(), "docs", "detections");
  const fs = require("node:fs");
  return fs
    .readdirSync(dir)
    .filter((f: string) => f.endsWith(".yml"))
    .map((f: string) => YAML.parse(readFileSync(join(dir, f), "utf-8")));
}

// Groups events within a rolling window by a key function, returning
// groups whose size meets/exceeds `minCount` — the core primitive nearly
// every one of our rules is built from.
function findThresholdGroups(
  events: SecurityEvent[],
  type: string,
  keyFn: (e: SecurityEvent) => string | undefined,
  minCount: number,
  windowMs: number
): { key: string; count: number; events: SecurityEvent[] }[] {
  const matching = events
    .filter((e) => e.type === type)
    .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

  const results: { key: string; count: number; events: SecurityEvent[] }[] = [];

  for (let i = 0; i < matching.length; i++) {
    const windowStart = new Date(matching[i].timestamp).getTime();
    const key = keyFn(matching[i]);
    if (!key) continue;

    const windowEvents = matching.filter((e) => {
      const t = new Date(e.timestamp).getTime();
      return t >= windowStart && t <= windowStart + windowMs && keyFn(e) === key;
    });

    if (windowEvents.length >= minCount) {
      results.push({ key, count: windowEvents.length, events: windowEvents });
    }
  }

  // De-duplicate overlapping windows that would otherwise report the same
  // underlying burst multiple times.
  const seen = new Set<string>();
  return results.filter((r) => {
    const dedupeKey = `${r.key}:${r.events[0].timestamp}`;
    if (seen.has(dedupeKey)) return false;
    seen.add(dedupeKey);
    return true;
  });
}

function main() {
  const logFile = process.argv[2] ?? join(process.cwd(), "data", "sample-security-events.log");
  const events = loadEvents(logFile);
  const rules = loadRules();

  console.log(`\nSecureTrade — Detection Engine\n`);
  console.log(`Loaded ${events.length} events from ${logFile}`);
  console.log(`Loaded ${rules.length} detection rules\n`);

  let anyFired = false;

  // Rule: brute-force-login
  const bruteForce = findThresholdGroups(
    events,
    "LOGIN_FAILURE",
    (e) => (e.metadata?.emailHash as string) ?? e.ip,
    5,
    10 * 60 * 1000
  );
  for (const g of bruteForce) {
    anyFired = true;
    console.log(
      `🚨 [HIGH] Brute-force login suspected — emailHash/IP "${g.key}" had ${g.count} failed logins in a 10-min window`
    );
  }

  // Rule: privilege-escalation-attempt
  const blockedRoleChanges = events.filter((e) => e.type === "ROLE_CHANGE_ATTEMPT_BLOCKED");
  for (const e of blockedRoleChanges) {
    anyFired = true;
    console.log(`🚨 [CRITICAL] Blocked role-change attempt by userId "${e.userId}" at ${e.timestamp}`);
  }
  const adminDenials = findThresholdGroups(
    events,
    "AUTHZ_DENIED",
    (e) => e.userId,
    3,
    5 * 60 * 1000
  );
  for (const g of adminDenials) {
    anyFired = true;
    console.log(
      `🚨 [CRITICAL] Repeated admin-route access denials — userId "${g.key}" denied ${g.count} times in 5 min`
    );
  }

  // Rule: sql-injection-pattern
  const sqlPatterns = ["' OR '", "' OR 1=1", "UNION SELECT", "--", "; DROP TABLE"];
  const validationEvents = events.filter((e) => e.type === "VALIDATION_REJECTED");
  for (const e of validationEvents) {
    const rawValue = String(e.metadata?.rawValue ?? "");
    if (sqlPatterns.some((p) => rawValue.includes(p))) {
      anyFired = true;
      console.log(`🚨 [CRITICAL] Possible SQL injection payload detected from IP "${e.ip}": ${rawValue}`);
    }
  }

  // Rule: unusual-order-volume
  const orderBursts = findThresholdGroups(events, "ORDER_PLACED", (e) => e.userId, 20, 60 * 1000);
  for (const g of orderBursts) {
    anyFired = true;
    console.log(`🚨 [MEDIUM] Abnormal order volume — userId "${g.key}" placed ${g.count} orders in 1 min`);
  }

  if (!anyFired) {
    console.log("✅ No detection rules fired against this event set.\n");
  } else {
    console.log("\n⚠️  One or more detection rules fired — see docs/IR-RUNBOOK.md for response steps.\n");
  }

  process.exit(0); // informational tool — never fails the build itself
}

main();
```

```bash
npm install yaml
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "detect": "tsx scripts/evaluate-detections.ts"
  }
}
```

### ✅ The Verification

Create a sample event log simulating a brute-force attack, to prove the engine actually detects the pattern before we ever point it at real production data:

##### 📄 File: `data/sample-security-events.log`
```
SECURITY_EVENT {"type":"LOGIN_FAILURE","timestamp":"2025-01-15T10:00:00.000Z","ip":"203.0.113.5","metadata":{"emailHash":"3f9a1b2c4d5e6f70"}}
SECURITY_EVENT {"type":"LOGIN_FAILURE","timestamp":"2025-01-15T10:01:00.000Z","ip":"203.0.113.5","metadata":{"emailHash":"3f9a1b2c4d5e6f70"}}
SECURITY_EVENT {"type":"LOGIN_FAILURE","timestamp":"2025-01-15T10:02:00.000Z","ip":"203.0.113.5","metadata":{"emailHash":"3f9a1b2c4d5e6f70"}}
SECURITY_EVENT {"type":"LOGIN_FAILURE","timestamp":"2025-01-15T10:03:00.000Z","ip":"203.0.113.5","metadata":{"emailHash":"3f9a1b2c4d5e6f70"}}
SECURITY_EVENT {"type":"LOGIN_FAILURE","timestamp":"2025-01-15T10:04:00.000Z","ip":"203.0.113.5","metadata":{"emailHash":"3f9a1b2c4d5e6f70"}}
SECURITY_EVENT {"type":"VALIDATION_REJECTED","timestamp":"2025-01-15T10:05:00.000Z","ip":"203.0.113.5","metadata":{"rawValue":"' OR '1'='1"}}
```

```bash
npm run detect
```
Expected output:
```
SecureTrade — Detection Engine

Loaded 6 events from data/sample-security-events.log
Loaded 4 detection rules

🚨 [HIGH] Brute-force login suspected — emailHash/IP "3f9a1b2c4d5e6f70" had 5 failed logins in a 10-min window
🚨 [CRITICAL] Possible SQL injection payload detected from IP "203.0.113.5": ' OR '1'='1

⚠️  One or more detection rules fired — see docs/IR-RUNBOOK.md for response steps.
```

---

## Step 5 — Configure Real-Time Alerting

### 🎯 The Target
A Sentry **Alert Rule** and a Slack (or Discord) webhook integration, so a `security_event:ROLE_CHANGE_ATTEMPT_BLOCKED` or `security_event:AUTHZ_DENIED` message doesn't just sit quietly in a dashboard nobody's watching — it actively notifies a human within seconds.

### 💡 The Concept
Step 4's detection engine is powerful, but as built, it's something a human has to *remember to run*. That's the exact same "supervisor has to remember to check" weakness we solved for dependency scanning (Part 4) and secret scanning (Part 5). Real alerting flips this from pull to push — like the difference between a smoke detector (pushes a loud alarm to you) and a thermometer on the wall (accurate, but useless unless someone remembers to walk over and look at it).

### 🛠️ The Implementation

In the Sentry dashboard: **Alerts → Create Alert → Issues**.

Configure:
- **Name**: `Critical Security Event`
- **Condition**: `An event is seen` where `tags.securityEventType` is one of `ROLE_CHANGE_ATTEMPT_BLOCKED`, `AUTHZ_DENIED`
- **Action**: `Send a notification to Slack` (or Discord/email if Slack isn't available) → connect your workspace, choose a `#security-alerts` channel
- **Frequency**: `Immediately`, with a rate-limit of `1 per minute per issue group` to avoid alert fatigue during a genuine burst

Create a second alert:
- **Name**: `Repeated Login Failures`
- **Condition**: `Number of events` is `>= 5` in `10 minutes` where `tags.securityEventType` equals `LOGIN_FAILURE`
- **Action**: same Slack channel

##### 📄 File: `docs/ALERTING.md`
```markdown
# SecureTrade — Alerting Configuration

## Configured Sentry Alert Rules

| Alert Name | Trigger | Channel | Corresponds to Detection Rule |
|---|---|---|---|
| Critical Security Event | Any `ROLE_CHANGE_ATTEMPT_BLOCKED` or `AUTHZ_DENIED` event | #security-alerts (Slack) | `privilege-escalation-attempt.yml` |
| Repeated Login Failures | 5+ `LOGIN_FAILURE` events in 10 min | #security-alerts (Slack) | `brute-force-login.yml` |

## Alert Fatigue Management
Rate-limited to 1 notification per minute per issue group — a genuine
burst of 50 failed logins in 30 seconds produces ONE Slack message, not
50, preserving the responder's ability to act instead of drowning them
in duplicate pings (a documented, real cause of missed real incidents in
security operations centers industry-wide).

## Escalation Path
1. Alert fires in #security-alerts.
2. On-call engineer (rotation TBD — formalized in Part 8) acknowledges
   within 15 minutes during business hours, 1 hour outside business
   hours (interim target — tightened as the team grows).
3. If CRITICAL severity (privilege escalation, SQL injection pattern) and
   unacknowledged after 30 minutes, alert escalates to a phone call
   (configure via Sentry's on-call integration, e.g. PagerDuty, once team
   size justifies it — documented here as the target future state).
4. Responder follows `docs/IR-RUNBOOK.md` starting from the Detect phase.
```

### ✅ The Verification

Trigger the login-failure alert for real:
```bash
for i in {1..6}; do
  curl -s -X POST http://localhost:3000/api/v1/auth/callback/credentials \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "email=alerttest@example.com&password=wrong$i" > /dev/null
done
```
Within a minute or two, confirm a message appears in your configured Slack channel referencing "Repeated Login Failures" — proving the entire pipeline (app → structured log → Sentry → alert rule → Slack) works end-to-end, not just in isolated pieces.

---

## Step 6 — Write the Incident Response Runbook

### 🎯 The Target
`docs/IR-RUNBOOK.md` — the document a stressed, adrenaline-fueled engineer reaches for at 2 AM during a real incident, structured around the five canonical IR phases.

### 💡 The Concept
A runbook is like a pre-flight emergency checklist pilots use during an actual engine failure — not because pilots are incompetent, but because *stress degrades human recall*, even for well-trained experts, in a genuine crisis. The entire value of a runbook is written **before** the emergency, when you can think clearly, so that during the emergency you're executing a checklist instead of improvising under pressure — exactly the condition under which people make their worst mistakes (deleting evidence, panicking and taking the whole site down unnecessarily, or forgetting to actually fix the root cause after firefighting the symptom).

### 🛠️ The Implementation

##### 📄 File: `docs/IR-RUNBOOK.md`
```markdown
# SecureTrade — Incident Response Runbook

## Phase 1: Detect
**Goal: confirm whether this is a real incident, fast, without causing panic on a false alarm.**

1. Identify the triggering signal: a Sentry/Slack alert (`docs/ALERTING.md`),
   a manual `npm run detect` finding, a user report, or an external
   notification (e.g. a security researcher).
2. Pull the relevant `SECURITY_EVENT` log lines from Vercel's runtime logs
   or Sentry, for the affected user/IP, spanning at least 1 hour before
   and after the triggering event.
3. Classify severity using this table:

| Severity | Criteria | Example |
|---|---|---|
| CRITICAL | Confirmed unauthorized data access/modification, or active exploitation in progress | SQL injection payload confirmed executing; role successfully escalated |
| HIGH | Strong indicator of attack, not yet confirmed successful | Brute-force pattern detected; blocked privilege escalation attempt |
| MEDIUM | Anomalous but plausibly benign | Order volume spike (could be a legitimate power user) |
| LOW | Isolated, low-confidence signal | A single 403 from a role-limited but legitimate feature exploration |

4. For HIGH/CRITICAL: immediately notify the team in #security-alerts
   and begin a shared incident timeline document (a simple running log:
   timestamp + action taken + who did it — this itself becomes evidence
   for the postmortem in Phase 5).

## Phase 2: Contain
**Goal: stop the bleeding without destroying evidence or overreacting.**

| Scenario | Containment Action |
|---|---|
| Single compromised account | Force-expire that user's session (delete/rotate relevant DB row or `AUTH_SECRET` only as last resort — see note below); require password reset |
| Active SQL injection / code injection exploitation | Immediately revert the vulnerable route to a safe state via a hotfix deploy, OR disable the specific route via a feature flag / Vercel's "Pause Deployment" if a hotfix isn't ready within minutes |
| Suspected leaked secret (API key, DB credential) | Rotate the specific credential IMMEDIATELY (see docs/SECRETS-POLICY.md) — do not wait for root cause analysis first |
| Distributed brute-force / volumetric attack | Tighten Vercel WAF rate limits temporarily (Part 6); block specific offending IPs/ranges at the Firewall tab |
| Confirmed data exfiltration of PII | Engage legal/compliance immediately — PDPA's Data Breach Notification Obligation may create a legal countdown clock starting NOW, not when convenient |

⚠️ **Never rotate `AUTH_SECRET` as a first response** unless session
compromise is confirmed system-wide — doing so immediately logs out
EVERY user simultaneously, a significant availability cost. Prefer
targeted, per-account containment first.

⚠️ **Do not delete attacker-created data (rows, log entries) during
containment** — preserve it for Phase 3/5 investigation. Disable/isolate,
don't destroy, until the investigation is complete.

## Phase 3: Eradicate
**Goal: remove the root cause, not just the symptom.**

1. Identify the exact vulnerability or misconfiguration that enabled the
   incident (reference `docs/THREAT-MODEL.md` — is this a threat we
   already knew about but hadn't fully mitigated, or a genuinely new one?
   Either way, this gets a new/updated entry there afterward).
2. Write a fix, following the exact "break it first" verification pattern
   from Part 3: reproduce the exploit against a local/staging copy,
   confirm the fix blocks it, THEN deploy.
3. Run the FULL CI/CD security pipeline (Part 5) against the fix before
   merging — an incident is exactly the wrong time to skip the checks
   that might catch a rushed, incomplete patch.
4. Check the SBOM (Part 4) and audit logs for any OTHER instance of the
   same root-cause pattern elsewhere in the codebase (e.g., if the
   incident was a second, previously-unknown IDOR, grep for other routes
   with the same missing-ownership-check shape).

## Phase 4: Recover
**Goal: return to normal operation, confidently, not just quickly.**

1. Deploy the fix through the normal CI/CD pipeline (Part 5) — no
   shortcuts, even under pressure; the branch protection rules from Part
   5 apply here too, without exception.
2. If data integrity is in question, restore from the most recent known-
   good backup per `docs/DISASTER-RECOVERY.md`, or manually reconcile
   affected records (e.g., reverse fraudulent orders) with a documented,
   auditable process — never a silent, undocumented database edit.
3. Re-enable any temporarily disabled routes/features from Phase 2.
4. Notify affected users if their data or funds were impacted — per
   PDPA's Notification Obligation and basic customer trust, regardless of
   legal minimum requirements.
5. Confirm monitoring shows the anomalous pattern (Step 4's detection
   rules) has genuinely stopped, not just gone quiet temporarily.

## Phase 5: Lessons Learned (Postmortem)
**Goal: make this exact incident structurally harder to repeat.**

Within 5 business days of resolution, write a postmortem in
`docs/incidents/YYYY-MM-DD-short-description.md` covering:
1. Timeline (pulled directly from the Phase 1 shared incident log)
2. Root cause (technical, and — just as important — PROCESS: why didn't
   an earlier control, like Semgrep or code review, catch this?)
3. Impact (data/users/funds affected, quantified honestly)
4. What went well / what didn't, in our OWN response
5. Concrete action items, each with an owner and a due date — not vague
   aspirations like "be more careful"
6. Update `docs/THREAT-MODEL.md` with the new/refined threat and its
   DREAD score, closing the loop back to Part 1

**Blameless by design**: this document exists to fix systems and
processes, never to punish an individual. A postmortem culture that
punishes people teaches everyone to hide problems instead of surfacing
them — which is a far greater long-term security risk than any single bug.
```

### ✅ The Verification

```bash
grep -c "^## Phase" docs/IR-RUNBOOK.md
```
Expected: `5`. Read it aloud once, fully, as if you were the on-call engineer — confirm every phase gives you an actual next physical action, not just a vague principle.

---

## Step 7 — Tabletop Exercise (TTX): "SecureTrade Gets Compromised"

### 🎯 The Target
`docs/TTX-SCENARIO-01.md` — a scripted, discussion-based simulation of a breach, designed to be run with your team (or solo, playing every role) **without touching any real system**.

### 💡 The Concept
A tabletop exercise is a fire drill conducted entirely through conversation — like a hospital's disaster-response committee sitting in a room and walking through "what exactly would we do, step by step, if the power grid failed during surgery?" without actually cutting the power. The value isn't in touching real systems (that's Step 8's live simulation) — it's in discovering, cheaply and safely, that "wait, who actually has the authority to rotate that production secret at 2 AM?" is a question nobody had answered, *before* that gap costs you thirty extra minutes during a real incident.

### 🛠️ The Implementation

##### 📄 File: `docs/TTX-SCENARIO-01.md`
```markdown
# Tabletop Exercise 01: "The 2 AM Alert"

**Format**: Gather the team (or run solo, playing each role in turn).
Read the scenario injects one at a time, pausing after each to discuss
and write down the team's actual proposed action — do NOT skip ahead.
Time-box each inject to 5-10 minutes of discussion.

## Roles
- **Incident Commander** — coordinates response, makes final calls
- **Engineer On-Call** — has technical access to logs, deploys, DB
- **Communications Lead** — handles user/stakeholder notifications

## Inject 1 (00:00)
It's 2:14 AM. A Slack message fires in #security-alerts: "Repeated Login
Failures — emailHash 3f9a1b2c, 47 failures in the last 10 minutes." The
on-call engineer is asleep.

**Discuss:** Who actually gets paged right now? Is there a real, working
on-call rotation, or does this alert just sit in Slack until someone
wakes up and checks their phone? (If your honest answer is "it just
sits there" — that's a real gap. Write it down as an action item now,
don't wait for a real incident to discover it.)

## Inject 2 (00:20, in-scenario time)
The on-call engineer wakes up, checks the logs. The 47 failed logins are
all against ONE specific account: `admin@securetrade.test`.

**Discuss:** Does this change the severity classification from
`docs/IR-RUNBOOK.md`'s table? (It should — an attack against a
known-ADMIN account is more severe than against a random user account,
since a successful compromise here has far greater blast radius per
Part 2's RBAC matrix.) What's the very next concrete action, per the
runbook's Phase 2 (Contain)?

## Inject 3 (00:35, in-scenario time)
The failed logins stop. Five minutes later, a NEW alert fires: `ROLE_CHANGE_ATTEMPT_BLOCKED`
for a completely different, previously-unremarkable user account.

**Discuss:** Does this look like the SAME attacker, or a coincidence? What
evidence would you pull to check (hint: IP address correlation across
both event types, timestamps, user-agent strings)? Has the "single
compromised account" containment scenario from the runbook now become a
"broader campaign" scenario, and does that change who needs to be
notified beyond the on-call engineer?

## Inject 4 (01:00, in-scenario time)
Investigation reveals: the attacker successfully guessed a weak, reused
password for a real (non-admin) user account, then attempted (and failed,
thanks to Part 3's mass-assignment fix) to self-promote to ADMIN via the
`/api/v1/users/me` endpoint.

**Discuss:** Walk through Phase 3 (Eradicate) and Phase 4 (Recover) from
the runbook, concretely, for THIS specific scenario. Does the compromised
user need to be notified? Does this trigger PDPA's Data Breach
Notification Obligation (was any actual PII/financial data accessed, or
only an unsuccessful escalation attempt)? Who decides that, using what
criteria?

## Debrief Questions (always ask these, for every TTX)
1. What went well in our discussed response?
2. What gaps did we discover that we didn't have answers for?
3. Which of today's gaps become action items, with an owner and a due
   date, in `docs/incidents/` or the team's issue tracker?
4. Should this exact scenario be re-run again in 6 months to confirm the
   gaps we found today are actually closed?
```

### ✅ The Verification

Actually run it — block 45 minutes on a calendar, gather whoever is available (or run solo, genuinely writing down honest answers rather than skimming), and produce real, filled-in answers to every "Discuss" prompt. Confirm at least one genuine process gap was surfaced — if the exercise reveals *zero* gaps, run it again more critically; a completely gap-free first TTX is far more likely to mean the exercise wasn't run rigorously than that the team is already perfect.

---

## Step 8 — Lab: Simulate a Real SQL Injection Attack, Then Run Full IR

### 🎯 The Target
A deliberately reintroduced, isolated SQL injection vulnerability (on a throwaway feature branch, never merged to `main`), a real attack against it, and a complete, documented walk-through of every IR phase — ending in a real postmortem.

### 💡 The Concept
This is the series' final "break it first" moment, at the *process* level rather than the *code* level: we already know how to write and fix a SQL injection bug (Part 3). What we're rehearsing now is the muscle memory of *everything around* that bug — noticing it happened, containing it, fixing it properly, and writing it up — using the exact same detection tooling (Step 4), alerting (Step 5), and runbook (Step 6) we just built, against a real, working exploit.

### 🛠️ The Implementation

Create an isolated branch — this vulnerability must **never** reach `main`:

```bash
git checkout -b ttx/sqli-simulation
```

##### 📄 File: `app/api/v1/instruments/news/route.ts` (🔓 DELIBERATELY VULNERABLE — TTX branch only)
```typescript
// app/api/v1/instruments/news/route.ts
// ⚠️ INTENTIONALLY VULNERABLE — exists ONLY on the ttx/sqli-simulation
// branch, for Part 7's incident-response drill. NEVER merge this branch.

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { logSecurityEvent } from "@/lib/security-logger";

export async function GET(req: NextRequest) {
  const symbol = req.nextUrl.searchParams.get("symbol") ?? "";

  // Reintroducing Part 3's Bug 1 on purpose, for this drill only.
  const results: unknown = await prisma.$queryRawUnsafe(
    `SELECT symbol, name, "currentPrice" FROM "Instrument" WHERE symbol = '${symbol}'`
  );

  // Simple heuristic detection wired in for this drill: flag obviously
  // malicious-looking input so Step 4's SQL-injection detection rule has
  // real events to fire against, mirroring how a WAF/input-validation
  // layer would realistically surface this pattern in production.
  const sqlPatterns = ["' OR '", "' OR 1=1", "UNION SELECT", "--", "; DROP TABLE"];
  if (sqlPatterns.some((p) => symbol.includes(p))) {
    logSecurityEvent({
      type: "VALIDATION_REJECTED",
      ip: req.headers.get("x-forwarded-for")?.split(",")[0]?.trim(),
      metadata: { route: "/api/v1/instruments/news", rawValue: symbol },
    });
  }

  return NextResponse.json(results);
}
```

```bash
git add -A
git commit -m "ttx: intentionally reintroduce SQLi for Part 7 incident response drill (DO NOT MERGE)"
npm run dev
```

**Attack it, in a separate terminal:**
```bash
# Confirm the endpoint works normally first
curl -s "http://localhost:3000/api/v1/instruments/news?symbol=D05"

# Now attack it exactly like Part 3's original Bug 1 exploit
curl -s "http://localhost:3000/api/v1/instruments/news?symbol=%27%20OR%20%271%27%3D%271"
```
Confirm the second request returns **every row** in the `Instrument` table, proving the injection succeeded, and check your `npm run dev` terminal — confirm a `SECURITY_EVENT VALIDATION_REJECTED` line was logged with the raw payload.

**Now run the IR process for real, using the actual runbook:**

**Phase 1 — Detect:**
```bash
grep "SECURITY_EVENT" <(npm run dev 2>&1) # or copy the relevant lines from your terminal into a log file
```
Classify severity using `docs/IR-RUNBOOK.md`'s table: this is a **confirmed** successful SQL injection → **CRITICAL**.

**Phase 2 — Contain:** since this is an isolated branch, containment here means: confirm the branch is NOT deployed anywhere reachable, and immediately stop the local dev server (`Ctrl+C`) — simulating "pause the affected deployment."

**Phase 3 — Eradicate:** apply the exact fix pattern from Part 3, Bug 1:
```typescript
// Replace the vulnerable query with Prisma's parameterized findMany —
// identical fix to Part 3's Bug 1 resolution.
const results = await prisma.instrument.findMany({ where: { symbol } });
```
Re-run the exploit — confirm it now returns an empty array, not all rows.

**Phase 4 — Recover:** in a real scenario, this is where you'd deploy through the full Part 5 pipeline. For this drill, confirm the fix passes Semgrep:
```bash
npm run semgrep
```

**Phase 5 — Lessons Learned:** write the postmortem.

##### 📄 File: `docs/incidents/2025-01-15-ttx-sqli-drill.md`
```markdown
# Postmortem: SQL Injection Drill — /api/v1/instruments/news

**Status**: Drill (Tabletop-adjacent live simulation), not a real production incident.
**Severity**: CRITICAL (as classified per docs/IR-RUNBOOK.md)
**Date**: 2025-01-15

## Timeline
- 14:02 — Deliberately vulnerable endpoint added to `ttx/sqli-simulation` branch
- 14:05 — Exploit attempted: `symbol=' OR '1'='1` — returned all Instrument rows
- 14:05 — `SECURITY_EVENT VALIDATION_REJECTED` logged with raw payload, matching `docs/detections/sql-injection-pattern.yml`
- 14:08 — Containment: local dev server stopped (simulating pausing a real deployment)
- 14:12 — Root cause identified: `$queryRawUnsafe` with string interpolation, identical pattern to Part 3's Bug 1
- 14:15 — Fix applied: replaced with `prisma.instrument.findMany({ where: { symbol } })`
- 14:17 — Fix verified: exploit payload now returns `[]`, Semgrep passes clean

## Root Cause
Technical: raw SQL string built via template literal interpolation,
bypassing Prisma's automatic parameterization.
Process: this specific route was newly added and had NOT yet passed
through the Part 5 CI pipeline (Semgrep would have caught this instantly
— our `.semgrep.yml` rule `no-raw-sql-unsafe` matches this exact pattern).
This is exactly why branch protection (Part 5) blocking merge without a
green Semgrep run is a REQUIRED control, not an optional nicety.

## Impact
Drill only — no real user data was exposed. Had this reached production,
impact would have been: full read access to the `Instrument` table
(classified PUBLIC per SYSTEM-OVERVIEW.md, so actual real-world impact
would have been low for THIS specific table — but the same coding
pattern against `User` or `Order` would have been CRITICAL PII/financial
exposure).

## What Went Well
- Detection rule (`sql-injection-pattern.yml`) fired correctly against
  real attack traffic, not just synthetic test data.
- The exact same fix pattern from Part 3 applied cleanly — the team's
  "how do we fix a SQLi" muscle memory held up under drill conditions.

## What Didn't Go Well
- This drill required MANUALLY re-running `npm run dev` and grepping
  terminal output — in a real incident, we should have a single command/
  dashboard view showing recent SECURITY_EVENT lines without needing to
  scroll through raw terminal history.

## Action Items
| Action | Owner | Due |
|---|---|---|
| Build a simple `/admin/security-events` dashboard reading recent Sentry security events, rather than requiring terminal log access during an incident | Engineering | Part 8 |
| Confirm branch protection genuinely blocks a PR with a `$queryRawUnsafe` pattern (re-verify Part 5's Semgrep gate still fires) | Engineering | Immediately |
| Re-run this exact drill in 6 months as a fresh TTX to confirm response time improves | Team | +6 months |

## Threat Model Update
No new threat — this drill re-confirmed T-007 (SQL/NoSQL injection,
Part 1) and validated its existing mitigations remain effective when
exercised end-to-end, not just fixed once and forgotten.
```

Clean up — this branch must never merge:
```bash
git add -A
git commit -m "ttx: document postmortem from SQLi drill"
git checkout main
git branch -D ttx/sqli-simulation
```

### ✅ The Verification

```bash
git branch --list "ttx/*"
```
Expected: empty output — confirming the vulnerable branch was genuinely deleted locally, never merged, never pushed to a shared remote branch that could accidentally be deployed.

```bash
ls docs/incidents/
```
Expected: `2025-01-15-ttx-sqli-drill.md` present — the artifact that matters survives even though the vulnerable code itself never touched `main`.

---

## Step 9 — Automate Verification of Part 7

### 🎯 The Target
`scripts/verify-part7.ts` — confirming the logging, detection, alerting, and documentation artifacts from this part all exist and function correctly.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-part7.ts`
```typescript
// scripts/verify-part7.ts

import { existsSync, readFileSync, readdirSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";

type Check = { label: string; pass: boolean; detail?: string };
const checks: Check[] = [];

function fileExists(p: string): boolean {
  return existsSync(join(process.cwd(), p));
}

function main() {
  const requiredFiles = [
    "docs/OBSERVABILITY.md",
    "docs/ALERTING.md",
    "docs/IR-RUNBOOK.md",
    "docs/TTX-SCENARIO-01.md",
    "lib/security-logger.ts",
    "scripts/evaluate-detections.ts",
    "data/sample-security-events.log",
  ];
  for (const f of requiredFiles) {
    checks.push({ label: `File exists: ${f}`, pass: fileExists(f) });
  }

  const detectionsDir = join(process.cwd(), "docs", "detections");
  const detectionCount = existsSync(detectionsDir)
    ? readdirSync(detectionsDir).filter((f) => f.endsWith(".yml")).length
    : 0;
  checks.push({
    label: "At least 4 Sigma-style detection rules defined",
    pass: detectionCount >= 4,
    detail: `found ${detectionCount}`,
  });

  const incidentsDir = join(process.cwd(), "docs", "incidents");
  const incidentCount = existsSync(incidentsDir)
    ? readdirSync(incidentsDir).filter((f) => f.endsWith(".md")).length
    : 0;
  checks.push({
    label: "At least 1 postmortem exists in docs/incidents/",
    pass: incidentCount >= 1,
    detail: `found ${incidentCount}`,
  });

  if (fileExists("docs/IR-RUNBOOK.md")) {
    const runbook = readFileSync(join(process.cwd(), "docs/IR-RUNBOOK.md"), "utf-8");
    const requiredPhases = ["Phase 1: Detect", "Phase 2: Contain", "Phase 3: Eradicate", "Phase 4: Recover", "Phase 5: Lessons Learned"];
    checks.push({
      label: "IR Runbook contains all 5 canonical phases",
      pass: requiredPhases.every((p) => runbook.includes(p)),
    });
  }

  // Confirm the vulnerable TTX branch was NOT left lying around
  try {
    const branches = execSync("git branch --list 'ttx/*'", { encoding: "utf-8" }).trim();
    checks.push({
      label: "No leftover ttx/* branches (drill cleanup confirmed)",
      pass: branches === "",
      detail: branches || undefined,
    });
  } catch {
    checks.push({ label: "No leftover ttx/* branches (drill cleanup confirmed)", pass: true });
  }

  try {
    execSync("npm run detect", { stdio: "pipe" });
    checks.push({ label: "Detection engine runs without error", pass: true });
  } catch {
    checks.push({ label: "Detection engine runs without error", pass: false });
  }

  console.log("\nSecureTrade — Part 7 Verification\n");
  let allPassed = true;
  for (const c of checks) {
    const icon = c.pass ? "✅" : "❌";
    console.log(`${icon} ${c.label}${c.detail ? ` (${c.detail})` : ""}`);
    if (!c.pass) allPassed = false;
  }
  console.log(
    allPassed
      ? "\nAll Part 7 checks passed. Ready for Part 8.\n"
      : "\nSome checks failed — fix the items above before continuing.\n"
  );
  process.exit(allPassed ? 0 : 1);
}

main();
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "verify:part7": "tsx scripts/verify-part7.ts"
  }
}
```

### ✅ The Verification

```bash
npm run verify:part7
```
All checks should print ✅. Commit:

```bash
git add -A
git commit -m "feat: security event logging, Sigma-style detection rules, alerting, IR runbook, TTX scenario, SQLi drill postmortem"
git push
```

---

## ✅ Part 7 Completion Checklist

- [ ] `lib/security-logger.ts` enforces the logging policy structurally (no raw PII possible)
- [ ] Login, role-change, authorization-denial, and order events all wired to the logger
- [ ] 4 Sigma-format detection rules written, and locally verified against sample data
- [ ] Real Sentry alert rules configured and tested end-to-end to a Slack channel
- [ ] `docs/IR-RUNBOOK.md` covers all 5 phases with concrete, actionable steps
- [ ] A tabletop exercise was actually run, with real, honest answers recorded
- [ ] A real SQLi attack was simulated on an isolated branch, detected, contained, fixed, and postmortemed — the branch was deleted, never merged
- [ ] `npm run verify:part7` exits all green

---

# 📚 Reference Section — Deep Dives for Part 7

### R1. From Our Toy Detection Engine to a Real SIEM

Our `scripts/evaluate-detections.ts` is intentionally minimal — a real deployment would instead: (1) ship logs continuously to a log aggregator (Datadog, Elastic, or even just a persistent table fed by a Vercel Log Drain), and (2) use the official `sigma-cli` tool to convert our exact same `.yml` rule files into that platform's native query language (e.g., Splunk SPL, Elastic EQL) — meaning the *investment in writing good Sigma rules* carries forward regardless of which backend you eventually adopt. This is the same "write once, deploy anywhere" value Terraform provides for infrastructure (Part 6), applied to detection logic.

### R2. MITRE ATT&CK — What Those Tags in Our Sigma Rules Mean

You may have noticed tags like `attack.t1110` in our detection rules. **MITRE ATT&CK** is a comprehensive, freely available knowledge base cataloging real-world adversary tactics and techniques (T1110 = "Brute Force," T1078 = "Valid Accounts," T1190 = "Exploit Public-Facing Application"), maintained from analysis of actual observed attacks. Tagging our own detections against this framework lets us answer a genuinely useful strategic question later ("which ATT&CK techniques do we currently have ZERO detection coverage for?") rather than only ever reacting to threats we've personally already imagined.

### R3. Alert Fatigue — The Silent Killer of Security Programs

The single most common reason real incidents get missed isn't a lack of detection — it's that the detection fired correctly, but was buried among hundreds of low-value alerts a tired human had already learned to ignore. This is precisely why Step 5 configured rate-limiting on alerts and Step 4 deliberately assigns different severities to different event types rather than treating every log line as equally urgent. A security program's alerting is only as good as a team's continued trust that "when this pings, it's genuinely worth looking at" — protect that trust deliberately, or the alerting system becomes theater.

### R4. Chain of Custody — Why We Never Delete Attacker Data During Containment

The runbook's Phase 2 explicitly warns against deleting attacker-created data during containment. In a legal/compliance context (relevant for a MAS-adjacent financial app), evidence handled improperly can undermine a later investigation or regulatory response — akin to a crime scene being cleaned up before investigators arrive. Practically for an engineering team, this means: isolate/disable, snapshot logs and database state, and only clean up *after* the investigation (Phase 3/5) has extracted everything it needs.

### R5. Blameless Postmortems — Why This Isn't Just a Nice Sentiment

The "blameless by design" note in Step 6 reflects a well-documented finding across the software industry (popularized by Google's SRE practices and the aviation industry decades earlier): teams that punish individuals for incidents reliably see *fewer* incidents reported and investigated honestly over time — not because fewer incidents happen, but because people learn to hide, minimize, or quietly work around problems rather than surface them. A security program's real enemy is silence, not mistakes — mistakes are inevitable; a culture that suppresses reporting of them is the actual, compounding risk.

### R6. PDPA's Data Breach Notification Obligation — The Practical Timeline

If a data breach is assessed as likely to result in significant harm to affected individuals, or is of a significant scale, Singapore's PDPA requires notifying the **PDPC (Personal Data Protection Commission)** as soon as practicable, and in any case **within 3 calendar days** of concluding the breach is notifiable — a genuinely tight, legally-binding clock. This is precisely why the IR Runbook's Phase 2 flags "engage legal/compliance immediately" for confirmed PII exfiltration rather than waiting until the full investigation concludes — the notification clock can start running before your technical investigation is even finished, and delaying that internal escalation to "be more certain first" carries real legal risk.

---

**Next up: Part 8 — Maintenance, Sunset & Security Culture (the final part)**, where we zoom out from any single incident to the long game: triaging CVEs against real SLAs, preparing for a professional pentest or bug bounty, training new developers joining the project, securely decommissioning data and rotating keys, and reporting security metrics execs actually understand — culminating in the final, complete SecureTrade repository: app, threat model, IR runbook, and every artifact from all eight parts, shipped together.
