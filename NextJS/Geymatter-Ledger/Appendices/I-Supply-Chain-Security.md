# Appendix I: Dependency & Supply Chain Security

Every `npm install` in this course pulled in code you did not write and, realistically, will never fully read. This appendix inventories exactly what got installed across Parts 1–14.8, what each package can actually reach if compromised upstream (a real, recurring category of attack — malicious versions published to npm have hit far larger projects than this one), and what a solo builder should actually do about it after the course ends.

## I.1 — Full Dependency Inventory

Every package installed across the entire series, in the order it was introduced:

| Package | Introduced | What it's wired into | Blast radius if compromised |
|---|---|---|---|
| `next`, `react`, `react-dom` | Part 1 (scaffold) | Everything — the framework itself | Total. Runs on every request, server and client. |
| `typescript`, `eslint` | Part 1 | Dev-time only, never shipped to production | Low at runtime — but a compromised ESLint plugin *could* run arbitrary code during `npm install`/build |
| `tailwindcss` | Part 1 | Build-time CSS generation only | Low — no runtime code execution, purely a build tool |
| `@clerk/nextjs` | Part 2 | Every authenticated request, session tokens, `auth()`, `currentUser()` | **Critical** — sits directly in front of every protected route; a compromised version could exfiltrate session tokens or bypass auth entirely |
| `drizzle-orm`, `drizzle-kit` | Part 3 | Every database query, every migration | **Critical** — has full read/write access to the entire database, including `journal_lines`, `payments`, and (as of 14.8) `bank_connections.accessToken` |
| `@neondatabase/serverless` | Part 3 | The actual network transport to Postgres | **Critical** — literally the wire between the app and the database |
| `ws` | Part 6 | WebSocket support for `dbTransactional` | High — same trust level as the Neon driver, since it's part of the same connection path |
| `inngest` | Part 11 | Background job execution, `/api/inngest` | High — can trigger `runPayroll`, `voidJournalEntry`-adjacent logic, and the bank sync job if a function is ever registered maliciously |
| `papaparse` | Part 12 | Parsing user-uploaded CSV text only | Low-to-medium — scoped to parsing untrusted file content, never touches secrets or other tables directly |
| `@types/ws`, `@types/papaparse` | Parts 6, 12 | TypeScript type definitions only | None at runtime — these ship zero executable code, type-only |

## I.2 — Why "Blast Radius" Matters More Than "Is It Popular"

A common but shallow security instinct is "this package has a million weekly downloads, it's fine." Popularity correlates with scrutiny, but it does not eliminate risk — it changes the *shape* of the risk. A popular package is a higher-value target for a supply-chain attacker (compromise one maintainer's npm account, reach thousands of downstream apps at once), while an obscure package's risk is more about abandonment and unpatched bugs than active malicious takeover.

What actually matters for Greymatter Ledger specifically is the **blast radius** column above — what could a malicious version of this exact package do, given what it's actually wired into in *this* app. `@clerk/nextjs` and `drizzle-orm`/`@neondatabase/serverless` are the three packages that, if compromised, could do genuine, silent damage: read every organization's ledger, forge a session, or exfiltrate `DATABASE_URL` itself. `papaparse`, by contrast, only ever touches the text content of an uploaded CSV file — a compromised version could misparse data or attempt a denial-of-service via a malformed file, but has no direct path to your secrets or your database.

## I.3 — Concrete, Actionable Steps for a Solo Builder

These are the things actually worth doing, in order of effort-to-value ratio, for someone maintaining this project after the course ends — not generic "keep dependencies updated" advice.

### Immediate, zero-cost

```bash
npm audit
```
**Purpose:** Checks every installed package (including transitive dependencies you never directly `npm install`ed) against npm's known vulnerability database.
**Run when:** Right now, and periodically (monthly is reasonable for a small project) — not just once at the end of the course.
**What to actually do with the output:** `npm audit` will report vulnerabilities by severity. For "high" or "critical" findings in packages from the "Critical" blast-radius row above (`@clerk/nextjs`, `drizzle-orm`, `@neondatabase/serverless`), treat this as urgent. For findings in dev-only tools (`eslint`, `drizzle-kit`), it's lower urgency, since they never run in the deployed app.

```bash
npm audit fix
```
**Purpose:** Automatically upgrades packages to patched versions where a fix is available without a breaking change.
**Caution:** Always run `npm run build` and manually re-test the app (Part 13.8's end-to-end checklist is a good script to follow) after running this — an automatic fix can still change behavior in ways `npm audit fix` itself cannot fully verify for you.

### Low-cost, ongoing

**Enable Dependabot on GitHub** (Settings → Security → Code security → Dependabot alerts + Dependabot security updates). Once your repository is pushed (Part 13.2), this is a free, zero-maintenance service that automatically opens a pull request whenever a dependency has a known vulnerability with an available fix — turning "did I remember to check `npm audit` this month" into "GitHub tells me automatically."

**Pin exact versions for the "Critical" blast-radius packages**, rather than relying on caret ranges (`^6.x.x`) alone. This doesn't prevent supply-chain compromise, but it means an upgrade to `@clerk/nextjs` or `drizzle-orm` only happens when *you* deliberately run `npm update`, not silently on someone else's CI machine or a fresh `npm install` months later pulling in whatever the caret range now resolves to.

### Higher-effort, worth doing before real production use with real customer money

**Review the actual diff of any major-version upgrade** to `@clerk/nextjs` or `drizzle-orm` before deploying it — not just trusting the changelog summary. These two packages sit at the exact trust boundaries named in Appendix F (T1, T3) — a subtle behavioral change in how `auth()` resolves `orgRole`, for instance, could silently weaken the admin-gating built in Part 14.3.

**Consider a lockfile integrity check in CI** (e.g., `npm ci` instead of `npm install` in any automated deployment pipeline) — `npm ci` installs exactly what's in `package-lock.json`, refusing to proceed if it's out of sync with `package.json`, which prevents an unexpected, un-reviewed version from silently slipping into a build.

## I.4 — What This Course Deliberately Did Not Build

Consistent with the honesty principle running through Appendix A's "Known Gaps" and Appendix F's threat model: this course never set up automated dependency scanning, never pinned exact versions in any `package.json` shown in the text, and never demonstrated reviewing a dependency's actual source code before installing it. These are legitimate, valuable practices for a real production application that a from-scratch learning course reasonably leaves as an exercise — the same way Part 14.8's bank-feed integration was built as illustrative scaffolding rather than a hardened production integration.

## I.5 — The One-Sentence Summary

Three packages in this entire stack — `@clerk/nextjs`, `drizzle-orm`, and `@neondatabase/serverless` — carry genuinely critical blast radius, since together they sit at the authentication boundary and the entire database access layer; everything else installed across this course (Tailwind, ESLint, PapaParse, the two `@types/*` packages) is either build-time-only or scoped to a narrow, non-sensitive task, and deserves proportionally less ongoing scrutiny.
