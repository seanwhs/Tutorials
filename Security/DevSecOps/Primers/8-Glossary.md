# 📖 SecureNotes DevSecOps Series — Complete Glossary

---

## A

**Analogy quick-reference:** every term that has a memory-hook analogy is marked with 🔗.

**Authentication (authN)** 🔗
Proving *who you are* — verifying identity. In `securenotes`, this is the `/auth/login` route confirming your credentials.
*Analogy:* Showing your passport at airport check-in.
*Appears:* Primer 2, Phase 2.
*Don't confuse with:* Authorization (below).

**Authorization (authZ)** 🔗
Proving *what you're allowed to do* — verifying permission, *after* identity is established. In `securenotes`, the per-user ownership checks that stop you touching anyone else's notes.
*Analogy:* Your boarding pass — grants access to this flight and seat, and nothing else.
*Appears:* Primer 2, Phase 2–3.
*Related failure:* skipping authZ causes **IDOR**.

**Attack surface**
The total set of points where an attacker could try to get in. Security work largely aims to *shrink* it (fewer packages, fewer open ports, less code in the final image).
*Appears:* Phase 3 (multi-stage builds), Phase 4 (Alpine base image).

**Audit log**
A structured, tamper-evident record of security-relevant events ("who did what, when") — e.g., logins and deletions. Directly counters the **Repudiation** threat.
*Appears:* Phase 5, threat model (Phase 1).

---

## B

**Base image** 🔗
The pre-made starting layer(s) a Dockerfile builds on top of (e.g. `node:20-alpine`). You inherit all its contents *and* its vulnerabilities.
*Analogy:* Standing on someone else's shoulders — convenient, but you carry their risks too.
*Appears:* Primer 3, Phase 3–4.

**bcrypt** 🔗
A password-hashing algorithm designed to be *intentionally slow* and *tunable* (via a "work factor"), so mass password-guessing is impractical while a single honest login stays fast.
*Analogy:* A bank-vault dial that takes 100ms per notch — trivial once, catastrophic for billions of guesses.
*Appears:* Primer 2, Phase 2.

**Branch (Git)** 🔗
An independent line of development — a parallel "draft" copy of the project you can change without affecting `main` until you merge.
*Analogy:* A draft copy of a document you scribble on freely, then merge back (or throw away).
*Appears:* Primer 5, used throughout for "scratch branch" experiments.

**Branch protection**
A GitHub rule that makes CI checks *mandatory* — the merge button is disabled until required checks pass. Converts scanners from advice into enforced policy.
*Analogy:* A locked turnstile that won't rotate without a valid ticket (see **Gate**).
*Appears:* Phase 2, Primer 4.

**Brute-force attack / lockout**
Repeatedly guessing credentials against the live login endpoint. Our Phase 5 guard locks out an IP after too many failures.
*Appears:* Phase 5, Primer 2 (online vs offline guessing).

---

## C

**CD (Continuous Delivery/Deployment)**
Automatically moving code that *passed* CI toward (or into) production. In our series, Phase 4's build→scan→sign→deploy pipeline.
*Appears:* Primer 4, Phase 4.

**CI (Continuous Integration)** 🔗
Automatically running your checks (tests, scans, builds) *every time* code is pushed, catching problems immediately.
*Analogy:* An always-on factory inspection station that pulls defective products off the line.
*Appears:* Primer 4, Phase 2–5.

**Connection pool**
A reusable set of open database connections shared across requests, instead of opening a new one each time — faster and prevents connection-exhaustion DoS.
*Appears:* Phase 3.

**Container** 🔗
A *running instance* of an image. One image can spawn many containers.
*Analogy:* The cooked meal made from a recipe (the image is the recipe).
*Appears:* Primer 3, Phase 3–4.
*Don't confuse with:* Image (below).

**Container registry** 🔗
A warehouse for storing and sharing container images. We use **GHCR** (GitHub Container Registry).
*Analogy:* A public library — you donate a book (push an image), others borrow it (pull).
*Appears:* Primer 3, Phase 4.

**Cosign / Sigstore** 🔗
Open-source tooling (Cosign is the CLI) for *keyless* image signing and verification, using OIDC identity instead of a stored private key; events are logged publicly in Rekor.
*Analogy:* A notary who checks your ID, stamps with a one-visit stamp, and records it in a public logbook.
*Appears:* Primer 6, Phase 4.

**cron**
A time-schedule syntax (five fields: minute, hour, day-of-month, month, day-of-week) used to trigger workflows on a schedule.
*Appears:* Primer 4, Phase 5 (weekly compliance report).

**CVE (Common Vulnerabilities and Exposures)** 🔗
A public catalog giving every known security flaw a unique ID (`CVE-YYYY-NNNNN`), so the whole world names the same flaw unambiguously.
*Analogy:* An ISBN for vulnerabilities — one exact ID, zero ambiguity.
*Appears:* Primer 7, Phase 2/4/5.

**CVSS (Common Vulnerability Scoring System)** 🔗
A standardized 0.0–10.0 severity score (CRITICAL/HIGH/MEDIUM/LOW) rating how dangerous a vulnerability is.
*Analogy:* The weather-warning scale — Tornado Warning (CRITICAL) vs gentle breeze (LOW); react proportionally.
*Appears:* Primer 7, Phase 2/5 (the number `severity: "HIGH,CRITICAL"` gates on).

---

## D

**DAST (Dynamic Application Security Testing)** 🔗
Testing the *running* application from the outside, like an attacker with no source access — sending real HTTP requests to probe for runtime flaws. We use OWASP ZAP.
*Analogy:* A mystery shopper who *tries things* rather than reading the store's policies.
*Appears:* Phase 4, contrasted with SAST/SCA in Phase 2.

**Defense in depth**
Layering multiple independent controls so that if one fails, others still protect you. We guard secrets at the IDE, at pre-commit, in CI, *and* in a vault.
*Appears:* Part 0, and threaded through every phase.

**Denial of Service (DoS)**
Overwhelming an app so real users can't use it (one of the STRIDE threats). Mitigated by rate limiting, body-size caps, and connection pooling.
*Appears:* Phase 1 threat model, Phases 1/3/5.

**Digest (image digest)** 🔗
A cryptographic hash (`sha256:...`) uniquely identifying an *exact* image by its content. Unlike a mutable tag, it can't be silently changed — so we sign and deploy by digest.
*Analogy:* An immutable fingerprint of the precise bytes.
*Appears:* Primer 3/6, Phase 4.

**Digital signature** 🔗
An artifact's hash sealed with a private key; proves both *authenticity* (who made it) and *integrity* (not one byte changed). Verifiable by anyone with the public key.
*Analogy:* A wax seal from a signet ring — everyone can check it against a reference card; only the ring-holder can create it.
*Appears:* Primer 6, Phase 4.

**Docker** 🔗
The most popular tool for building and running containers.
*Analogy:* The "Kleenex" of containers — a brand that became the word for the whole concept.
*Appears:* Primer 3, Phase 3–4.

**Docker Compose** 🔗
A tool to define multiple containers (e.g. app + database) in one YAML file and launch them together with `docker compose up`.
*Analogy:* A stage manager's script that cues the whole production at once.
*Appears:* Primer 3, Phase 3.

**Dependabot**
GitHub's built-in bot that watches dependencies and automatically opens pull requests to update vulnerable/outdated ones — turning "you're vulnerable" into "here's a ready-to-merge fix."
*Appears:* Phase 5.

**dotenv**
A library that loads variables from a `.env` file into the environment for local development.
*Appears:* Phase 1, Phase 3.

---

## E

**Elevation of privilege**
A normal user gaining powers they shouldn't have (a STRIDE threat). Mitigated by role/ownership checks and by running containers as a non-root user.
*Appears:* Phase 1 threat model, Phases 2/3/4.

**Environment variable**
A value provided to a program by its runtime environment rather than hardcoded in the source. Golden rule #1: *secrets live in environment variables, never in code.*
*Appears:* Phase 1 onward.

**ESLint**
A linter for JavaScript/TypeScript; with the security plugin it flags dangerous patterns (like `eval()`) as you type and in CI.
*Appears:* Phase 1.

**Exit code** 🔗
A number a command returns on finishing: **`0` = success**, any non-zero = failure. CI treats non-zero as a failed step — the mechanism behind every security gate.
*Analogy:* A thumbs-up (0) or thumbs-down (non-zero) at the end of each command.
*Appears:* Primer 4, Phases 2–5 (`exit-code: "1"`).

**Express**
The Node.js web framework `securenotes` is built on.
*Analogy:* A "waiter framework" that routes incoming requests to the right handler.
*Appears:* Phase 1 onward.

---

## G

**Gate** 🔗
A required check that *blocks progress* if it fails (a red gate stops the merge/deploy). What turns a scanner from advice into enforced policy.
*Analogy:* A turnstile that won't rotate without a valid ticket (vs. a sign you can ignore).
*Appears:* Primer 4, Phases 2 & 4.

**GHCR (GitHub Container Registry)**
GitHub's built-in container registry, where our images are pushed, scanned, signed, and pulled from.
*Appears:* Phase 4.

**Git** 🔗
A version-control system recording the complete history of every change, so you can review or roll back to any past state. The foundation our security hooks plug into.
*Analogy:* Permanent, labeled save points in a video game.
*Appears:* Primer 5, Phase 1 onward.

**Git hook** 🔗
An automatic script that fires at a moment in the Git workflow. A *pre-commit* hook runs during `git commit`, before the snapshot is saved — where we block secrets.
*Analogy:* A tripwire on the `git commit` boundary.
*Appears:* Phase 1, Primer 5.

**gitleaks**
An open-source scanner that detects secrets (API keys, tokens) in staged changes and across full Git history.
*Appears:* Phase 1 (pre-commit), Phase 3 (history scan), Phase 5 (compliance).

**GitHub Actions** 🔗
GitHub's built-in CI/CD system, configured via YAML files in `.github/workflows/`, triggered by events (push, PR, schedule).
*Analogy:* Hiring a fresh temp worker each run who follows a self-contained checklist on an empty desk.
*Appears:* Primer 4, Phases 2–5.

**Golden rules (the four)**
The security principles locked in from day one: (1) secrets in env vars, never code; (2) parameterized queries, never string concatenation; (3) validate all input at the edge; (4) scope every data query to the authenticated owner.
*Appears:* Part 0, Phase 1, enforced throughout.

---

## H

**Hashing** 🔗
A *one-way* function turning any input into a fixed-size fingerprint, with no reverse. Used to store passwords safely and to fingerprint artifacts for signing.
*Analogy:* A paper shredder — you can shred a document (hash it) but never reassemble the confetti.
*Appears:* Primer 2/6, Phase 2/4.
*Don't confuse with:* encryption (reversible, uses a key).

**Health check**
An endpoint (`/health`) that reports whether the app is alive, for load balancers and orchestrators. Deliberately leaks no sensitive info.
*Appears:* Phase 1, Phase 3 (Docker HEALTHCHECK).

**Helmet**
Express middleware that sets ~15 protective HTTP response headers (and hides `X-Powered-By`) to make browsers behave defensively.
*Appears:* Phase 1.

**HTTP (HyperText Transfer Protocol)** 🔗
The request→response rules computers use to talk over the web. The language `securenotes` speaks.
*Analogy:* A restaurant: the client orders (request), the kitchen answers (response); it never speaks unprompted.
*Appears:* Primer 1, Phase 1 onward.

**Husky**
A tool that makes Git hooks easy to install and share across a team via the repo.
*Appears:* Phase 1.

---

## I

**IaC (Infrastructure as Code)**
Describing servers, databases, and networks in version-controlled text files (e.g. Terraform) instead of clicking cloud-console buttons — so infrastructure can be reviewed and *scanned* like code.
*Analogy:* A building-code inspector reading the blueprints before construction.
*Appears:* Phase 3.

**IDOR (Insecure Direct Object Reference)**
A vulnerability where a logged-in user accesses others' data just by changing an ID (`/notes/123` → `/notes/124`). Prevented by golden rule #4 (scope every query to the owner).
*Appears:* Primer 2, Phase 2–3.

**Image (container image)** 🔗
A static, read-only package containing your app *plus its entire environment*. Not running — a template. The thing we scan and sign.
*Analogy:* A recipe (or cookie cutter); the container is the meal (or cookie).
*Appears:* Primer 3, Phase 3–4.

**Image signing** — see **Digital signature**, **Cosign / Sigstore**.

**Information disclosure**
Leaking data an attacker shouldn't see (a STRIDE threat) — e.g. stack traces, user-enumeration via error messages, or confirming a resource exists. Mitigated by generic errors, log redaction, and careful status-code choices (404 vs 403).
*Appears:* Phase 1 threat model, Phases 1/2/5.

**Integrity** 🔗
The guarantee that an artifact hasn't been altered by even one byte. Proven cryptographically by a digital signature.
*Appears:* Primer 6, Phase 4.

---

## J

**JSON (JavaScript Object Notation)**
A simple text format of `{"key": "value"}` pairs — the universal language of modern API request/response bodies.
*Appears:* Primer 1, Phase 1 onward.

**JWT (JSON Web Token)** 🔗
A signed, self-contained token carrying claims (like your user ID) plus a signature proving it was issued by the server and not tampered with. Fits HTTP's statelessness.
*Analogy:* A tamper-proof festival wristband — info printed on it, stamped with a hologram only the venue can make.
*Appears:* Primer 2, Phase 2.
*Key caution:* the payload is only base64-*encoded*, readable by anyone — never put secrets in it.

**JWT_SECRET**
The signing secret used to create/verify JWT signatures — the "crown jewel" asset. Leak = an attacker can forge any user's identity. Enforced ≥32 chars (Phase 1) and vaulted (Phase 3).
*Appears:* Phase 1–3, Primer 2.

---

## K

**Key pair (public/private key)** 🔗
Two mathematically-linked keys: a *private* key (kept secret, creates signatures) and a *public* key (shared freely, verifies them). Neither can be derived from the other.
*Analogy:* A signet ring (private, makes the seal) plus reference cards everyone holds (public, checks the seal).
*Appears:* Primer 6, Phase 4.

**Keyless signing** 🔗
Signing that eliminates the long-lived private key: prove your identity via OIDC, get a *momentary* signing certificate, sign, log it publicly, let the key expire. Nothing to store or leak.
*Analogy:* A notary using your ID and a one-visit stamp, instead of you owning a stamp forever.
*Appears:* Primer 6, Phase 4.

---

## L

**Layer (image layer)** 🔗
Each Dockerfile instruction creates a read-only layer; stacked layers form the image. Enables caching (fast rebuilds) and is why image scanning must inspect *every* layer.
*Analogy:* Transparent sheets on an overhead projector, stacked to form the full picture.
*Appears:* Primer 3, Phase 3–4.

**Least privilege**
Giving software (or a user) only the minimum power it needs — e.g. running a container as a non-root user, scoping IAM roles, limiting workflow permissions.
*Analogy:* A hotel key to your own room, not the master key to every room.
*Appears:* Phases 2/3/4/5.

**lint-staged**
Runs checks only on the files being committed (staged), keeping pre-commit fast.
*Appears:* Phase 1.

**Linter** 🔗
A "grammar-and-spell-checker for code" that flags risky or malformed patterns. Our security linter is a lightweight, real-time form of SAST.
*Appears:* Phase 1, Primer 4.

---

## M

**main() bootstrap**
The async startup function that loads config/secrets *before* wiring up and starting the server (needed once config became async in Phase 3).
*Appears:* Phase 3.

**Middleware** 🔗
A function that sits *between* the incoming request and the final handler; it can inspect, modify, block, or log the request. Runs top-to-bottom in order.
*Analogy:* Security guards posted in a hallway everyone must walk down.
*Appears:* Phase 1 onward.

**Multi-stage build** 🔗
A Dockerfile technique using multiple `FROM` stages: a "build" stage with all tooling, then copying only the finished output into a clean, minimal "runtime" stage.
*Analogy:* Cooking in a messy kitchen but serving on a clean plate.
*Appears:* Primer 3, Phase 3.

---

## N

**Non-root user (`USER node`)**
Running the container process as an unprivileged user so a compromise doesn't grant admin *inside* the container. The single most important security line in our Dockerfile.
*Analogy:* Giving guests a key to their own room, not the manager's office.
*Appears:* Primer 3, Phase 3–4.

**npm audit**
npm's built-in SCA tool; scans dependencies for known CVE advisories.
*Appears:* Phase 2, Phase 5.

---

## O

**OIDC (OpenID Connect)** 🔗
A standard letting one system prove its identity to another via short-lived, verifiable tokens. GitHub Actions uses it to prove "I am the release.yml workflow in this repo" for keyless signing.
*Analogy:* Showing government ID to a notary.
*Appears:* Primer 6, Phase 4.

**OWASP ZAP**
A free, industry-standard DAST tool (Zed Attack Proxy) that probes a running app for vulnerabilities.
*Appears:* Phase 4.

**Ownership check**
Enforcing golden rule #4: every note query includes `user_id`, so a user can only access their own data. Structurally prevents IDOR/Tampering.
*Appears:* Phase 2–3.

---

## P

**Parameterized query** 🔗
A database query using placeholders (`$1`, `$2`) for user input, sent separately from the SQL text — so input can never be executed as commands. Structurally defeats SQL injection.
*Analogy:* A fill-in-the-blank form (data slots into blanks) vs. a hand-written letter a stranger could add commands to.
*Appears:* Phase 2–3, golden rule #2.

**Pino**
The structured JSON logger used in Phase 5, with built-in redaction of sensitive fields.
*Appears:* Phase 5.

**Port** 🔗
A numbered "door" for network traffic. The app listens on port 3000 inside its container; `-p 3001:3000` publishes it to the host.
*Analogy:* An apartment's internal door (3000) reached via the building's street entrance (3001).
*Appears:* Primer 3, Phase 3.

**Pre-commit hook** — see **Git hook**.

**Provenance**
Verifiable evidence of *where an artifact came from and how it was built*. Attached to our image in Phase 4 alongside the SBOM.
*Appears:* Phase 4.

---

## R

**RASP (Runtime Application Self-Protection)** 🔗
Security logic *inside* the running app that monitors its own behavior and blocks attacks in real time (vs. an external firewall). Our brute-force guard and anomaly detector are lightweight RASP-style controls.
*Analogy:* The body's immune system detecting and attacking a threat from within.
*Appears:* Phase 5.
*Compare with:* WAF (below).

**Rate limiting**
Capping how many requests a client can make in a time window — our primary DoS mitigation.
*Appears:* Phase 1, Phase 5.

**Redaction (log redaction)**
Automatically censoring sensitive fields (tokens, passwords) in logs so they never hit disk. Configured once in the logger for secure-by-default logging.
*Appears:* Phase 5.

**Rekor**
Sigstore's public, append-only *transparency log* that permanently records every keyless signing event, making signatures auditable and non-repudiable.
*Analogy:* The notary's public logbook.
*Appears:* Primer 6, Phase 4.

**Repudiation**
Denying you performed an action because there's no record (a STRIDE threat). Countered by structured audit logging.
*Appears:* Phase 1 threat model, Phase 5.

**REST (Representational State Transfer)** 🔗
An API style modeling the app as *resources* (nouns, e.g. `/notes`) acted on by HTTP *methods* (verbs, e.g. `GET`/`DELETE`), returning appropriate status codes. Predictable by design.
*Appears:* Primer 1, Phase 2.

---

## S

**Salting**
Mixing random data into a password before hashing so identical passwords produce different hashes, defeating precomputed "rainbow table" attacks. Handled automatically by bcrypt.
*Appears:* Primer 2, Phase 2.

**SARIF**
A standard report format for static-analysis results, uploaded to GitHub's Security tab for centralized triage.
*Appears:* Phase 4.

**SAST (Static Application Security Testing)** 🔗
Scanning *your source code* without running it, to find vulnerable patterns (injection, unsafe APIs, hardcoded secrets). We use ESLint (light) and Semgrep (deep).
*Analogy:* A thorough copy-editor reading the manuscript.
*Appears:* Phase 1–2.
*Compare with:* SCA, DAST.

**SBOM (Software Bill of Materials)** 🔗
A complete, machine-readable inventory of every component (dependency, version, license) in your software. Lets you instantly answer "are we affected?" when a new CVE drops.
*Analogy:* An ingredients label used to check for allergens during a recall.
*Appears:* Primer 7, Phase 2/4/5.

**SCA (Software Composition Analysis)** 🔗
Scanning your *third-party dependencies* (direct and transitive) for known CVEs and license risks. We use `npm audit` and Trivy.
*Analogy:* Inventorying the huge hidden mass of an iceberg below the waterline.
*Appears:* Phase 2, contrasted with SAST/DAST.

**Secret manager** 🔗
A guarded vault (AWS Secrets Manager, Vault) that centrally stores credentials, fetched at startup via the app's identity — enabling rotation and access logging without `.env` files in production.
*Analogy:* A bank vault with an access log, instead of scattered copies of the key.
*Appears:* Phase 3.

**Semgrep**
An open-source SAST scanner with thousands of security rules, run in CI on every push/PR.
*Appears:* Phase 2.

**Session (session-based auth)** 🔗
An auth approach where the *server* stores your identity and gives you a random session ID to present each request. *Stateful* — contrasts with stateless JWTs.
*Analogy:* A coat-check ticket: your coat (identity) stays with the attendant; you carry only the numbered stub.
*Appears:* Primer 2.

**SIEM (Security Information and Event Management)**
A system that aggregates logs and security events for alerting and investigation — the natural next step beyond our Phase 5 logging.
*Appears:* Phase 5 reference.

**Spoofing**
Pretending to be someone else (a STRIDE threat) — e.g. forging a login. Countered by JWT auth + bcrypt.
*Appears:* Phase 1 threat model, Phase 2.

**SQL injection** 🔗
An attack where malicious input is interpreted as database *commands* instead of *data*. Made structurally impossible by parameterized queries.
*Appears:* Phase 1 threat model, Phase 2–3.

**Staging area (Git)** 🔗
The "holding zone" where you place specific changes to include in the next commit (via `git add`).
*Analogy:* The open box you pack with just the items you want to ship, before sealing it (`git commit`).
*Appears:* Primer 5, Phase 1.

**Stateless** 🔗
The server remembers *nothing* between requests; each request must carry everything needed to understand it. The reason JWTs exist.
*Analogy:* A kitchen that forgets you the instant it serves you — every order slip must be complete on its own.
*Appears:* Primer 1–2, Phase 2.

**Status code** 🔗
A three-digit HTTP result: 2xx success, 3xx redirect, 4xx client error, 5xx server error. Several carry security meaning (401 vs 403 vs 404).
*Analogy:* The kitchen's verdict on your order — served, can't-make-it, or kitchen-fire.
*Appears:* Primer 1, Phase 2.

**STRIDE** 🔗
A threat-modeling framework: **S**poofing, **T**ampering, **R**epudiation, **I**nformation disclosure, **D**enial of service, **E**levation of privilege. We used it to shape the whole design.
*Analogy:* A pilot's pre-flight checklist for "what could go wrong?"
*Appears:* Phase 1 threat model.

**Supply chain (security)**
Risks from the external code, dependencies, base images, and build tools you incorporate. Defended by SCA, image scanning, SBOMs, and signing.
*Appears:* Phase 1 threat model, Phases 2/4.

---

## T

**Tampering**
Modifying data you shouldn't (a STRIDE threat) — e.g. editing another user's note, or altering a JWT/image. Countered by ownership checks, parameterized queries, and signatures.
*Appears:* Phase 1 threat model, Phases 2–4.

**Terminal / command line** 🔗
A text-based interface for typing commands to the computer — precise, repeatable, automatable. (The `$` shown in docs is just the prompt; don't type it.)
*Analogy:* Texting exact instructions vs. pointing and grunting with a mouse.
*Appears:* Primer 5, every phase.

**Terraform**
The dominant IaC tool; you declare desired infrastructure and it makes reality match. We write it, then audit it (never `apply` in the tutorial).
*Appears:* Phase 3.

**Threat model / threat modeling** 🔗
A lightweight, up-front analysis of what you're protecting, who might attack, and how — done *before* coding, using STRIDE.
*Analogy:* A pilot's pre-flight checklist.
*Appears:* Phase 1.

**Transitive dependency**
A dependency pulled in by *your* dependencies (not chosen directly) — the hidden bulk of the dependency "iceberg." Tracked in the SBOM, scanned by SCA.
*Appears:* Primer 7, Phase 2.

**Trivy**
A versatile open-source scanner used for SCA (dependencies), image scanning (OS + libraries), IaC misconfig, and SBOM generation.
*Appears:* Phases 2/3/4/5.

**Trust boundary**
A point where untrusted data crosses into a trusted zone (Internet→API, API→DB, CI→registry). Each demands a control.
*Appears:* Phase 1 threat model.

**TypeScript** 🔗
JavaScript with *types* — labels on data (`string`, `User`) that catch mistakes before the program runs.
*Analogy:* A spell-checker for code.
*Appears:* Phase 1.

---

## W

**WAF (Web Application Firewall)**
A security layer *in front* of the app (at the network edge) inspecting traffic generically. Complementary to RASP (which lives inside the app with full context).
*Appears:* Phase 5 reference.
*Compare with:* RASP.

**Work factor (bcrypt cost)** 🔗
The tunable number (e.g. `12`) controlling how slow bcrypt hashing is; raised over time as hardware improves ("adaptively slow").
*Analogy:* How many notches the vault dial must turn — kept ~100ms for honest logins, brutal for mass guessing.
*Appears:* Primer 2, Phase 2.

**Working directory (Git)** 🔗
Your actual files with their current edits — the first of Git's three areas, before staging.
*Analogy:* Your messy desk with all your stuff on it.
*Appears:* Primer 5.

---

## Y – Z

**YAML (YAML Ain't Markup Language)** 🔗
A human-friendly config format built on key-value pairs, indentation-for-nesting, dashes-for-lists, and `#` comments. The language of CI workflows.
*Analogy:* An indented outline / nested folders — indentation shows what belongs inside what.
*Appears:* Primer 4, Phases 2–5.

**Zod**
A validation library that turns untrusted input (and env vars) into trusted, typed data at the edge — enforcing golden rule #3.
*Appears:* Phase 1 onward.

---

## Quick-reference tables

### The STRIDE threats → their defenses (built where)
| Threat | Primary defense | Phase |
|---|---|---|
| **S**poofing | JWT auth + bcrypt | 2 |
| **T**ampering | Ownership checks + parameterized queries + signing | 2–4 |
| **R**epudiation | Structured audit logging | 5 |
| **I**nformation disclosure | Input validation + generic errors + log redaction | 1/2/5 |
| **D**enial of service | Rate limiting + brute-force guard + body caps | 1/5 |
| **E**levation of privilege | Role/ownership checks + non-root container | 2–4 |
| (Supply chain) | SCA + image scan + signing | 2/4 |
| (Secrets leak) | Pre-commit + history scan + secret manager | 1/3 |

### The three scan types, side by side
| | Scans | Runs the code? | Catches | Phase |
|---|---|---|---|---|
| **SAST** | Your source code | No | Injection, unsafe APIs, hardcoded secrets | 1–2 |
| **SCA** | Third-party deps | No | Known CVEs, bad licenses | 2 |
| **DAST** | The running app | Yes | Runtime flaws, missing headers, auth bypass | 4 |
| *(Image scan)* | All image layers incl. OS | No | OS-package + library CVEs | 4 |

### The four golden rules
1. Secrets in **environment variables**, never in code.
2. **Parameterized queries**, never string concatenation.
3. **Validate all input** at the edge before trusting it.
4. **Scope every query** to the authenticated owner.
