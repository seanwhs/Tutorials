# 📝 Part A — Primer Quizzes (Foundations)

*(The 7 primers already have "Self-check" questions built in. These are additional, differently-framed questions so you're not just re-answering what you saw — good for spaced repetition.)*

## Quiz P1 — HTTP & REST

**P1.1** 🟢 Which HTTP method is meant to be "safe" (read-only, never changing data)?
A) POST  B) GET  C) DELETE  D) PATCH

**P1.2** 🟡 A client sends `POST /notes` but omits `Content-Type: application/json`. What's the most likely consequence in our app?
A) The server crashes  B) The request is rate-limited  C) `req.body` may be empty because the JSON parser didn't engage  D) The JWT is rejected

**P1.3** 🟡 Match the status code to the situation:
1. Valid token, but you're not allowed to do this → ___
2. No/invalid token → ___
3. Input failed validation → ___
4. Note created successfully → ___
(Options: `201`, `400`, `401`, `403`)

**P1.4** 🔴 In two sentences, explain why HTTP being *stateless* is the reason JWTs exist.

---

## Quiz P2 — How Auth Works

**P2.1** 🟢 True/False: Encryption is the correct way to store passwords because you can decrypt them to check a login.

**P2.2** 🟡 Why is bcrypt's *slowness* considered a feature rather than a flaw?

**P2.3** 🟡 Which part of a JWT can *anyone* holding the token read without any secret?
A) The signature  B) The payload  C) Nothing — it's all encrypted  D) Only the header

**P2.4** 🔴 An app correctly authenticates users but lets any logged-in user fetch `/notes/{anyID}`. Name the vulnerability class, the STRIDE category it violates, and the golden rule that prevents it.

---

## Quiz P3 — Containers & Docker

**P3.1** 🟢 An image is to a container as a ______ is to a ______.
A) meal / recipe  B) recipe / meal  C) library / book  D) port / door

**P3.2** 🟡 Why does our Dockerfile `COPY package.json` and run `npm ci` *before* copying `src/`?

**P3.3** 🟡 Phase 2's *source* scan is clean, but Phase 4's *image* scan finds a HIGH CVE. Where does the CVE most likely live, and why did source scanning miss it?

**P3.4** 🔴 Explain how a multi-stage build *and* `USER node` each reduce risk — and which STRIDE threat `USER node` specifically addresses.

---

## Quiz P4 — CI/CD & YAML

**P4.1** 🟢 In YAML, what does indentation represent?
A) Decoration  B) Nesting / what belongs inside what  C) Comments  D) Priority

**P4.2** 🟡 With no `needs:` declared, do three jobs run sequentially or in parallel? What about the steps inside a single job?

**P4.3** 🟡 A Trivy step has `exit-code: "1"` and `severity: "HIGH,CRITICAL"`. Under exactly what condition does it fail the pipeline?

**P4.4** 🔴 A pre-commit hook already blocks secrets locally. Why *also* run a secret scan in CI? Use the terms "bypass" and "defense in depth."

---

## Quiz P5 — Command Line & Git

**P5.1** 🟢 You see `$ npm run dev` in a tutorial. What exactly do you type?

**P5.2** 🟡 Put these in order and name each: `git commit`, `git push`, `git add`. Then state which Git *area* each moves changes *into*.

**P5.3** 🟡 On which Git boundary does the pre-commit hook fire, and why is that the ideal spot to block a secret?

**P5.4** 🔴 You committed a password, then deleted it in the next commit. Is it gone? Explain, and state the *two* actions truly required.

---

## Quiz P6 — Public-Key Crypto & Signing

**P6.1** 🟢 Which key *creates* a signature, and which *verifies* it?

**P6.2** 🟡 A signature sits publicly next to the image in the registry. Why can't an attacker use it to forge a signature for a malicious image?

**P6.3** 🟡 Why sign the image *digest* (`sha256:...`) rather than the tag `:latest`?

**P6.4** 🔴 An attacker uploads a malicious image and signs it with *their own valid* Sigstore identity. Our deploy runs `cosign verify` with `--certificate-identity-regexp` pinned to our `release.yml`. Does it deploy? Why or why not?

---

## Quiz P7 — Vulnerability Ecosystem

**P7.1** 🟢 What does a CVE ID uniquely provide?

**P7.2** 🟡 A finding is CVSS 9.8 CRITICAL, but it's in a library function your code never calls. Per Phase 5's triage, is the score the final word? What do you assess?

**P7.3** 🟡 A new CVE hits `some-lib@2.3.0` overnight across 40 services. Which artifact lets you answer "are we affected?" in minutes, and how?

**P7.4** 🔴 Write the one-sentence "finding" a scanner produces, correctly using all three of: SBOM, CVE, CVSS.

---

# 📝 Part B — Phase Quizzes (Hands-On Build)

## Quiz 1 — Phase 1: Shift Left Foundation

**1.1** 🟢 What is the purpose of the `!.env.example` line in `.gitignore`?

**1.2** 🟡 Why does `src/config.ts` enforce `JWT_SECRET` minimum length and `process.exit(1)` on failure? What is this pattern called?

**1.3** 🟡 Name the two security middlewares added in Phase 1 and the STRIDE threat each addresses.

**1.4** 🔴 A teammate runs `git commit --no-verify` and pushes a hardcoded AWS key. Which Phase 1 control failed, and which *later* phase's control still catches it?

**1.5** 🟢 True/False: `.gitignore` deletes secret files.

---

## Quiz 2 — Phase 2: SAST & SCA

**2.1** 🟢 SAST scans ______; SCA scans ______.

**2.2** 🟡 Why does the notes store require a `userId` on *every* method (create/list/find/delete)?

**2.3** 🟡 Why do we use `npm ci` in CI instead of `npm install`?

**2.4** 🔴 On login failure we return a generic `"Invalid credentials"` rather than `"no such email"`. What attack does this prevent, and which STRIDE category is it?

**2.5** 🟡 What single mechanism makes the branch-protection "gate" actually block a merge? (Hint: it's a number.)

---

## Quiz 3 — Phase 3: Secrets & IaC

**3.1** 🟢 What makes a parameterized query (`$1`, `$2`) immune to SQL injection?

**3.2** 🟡 Why does Phase 3's CI checkout use `fetch-depth: 0` for the gitleaks job?

**3.3** 🟡 Give two distinct reasons the secret-manager pattern is safer than shipping `.env` files to production.

**3.4** 🔴 An IaC scanner (Checkov) fails on a security group with `cidr_blocks = ["0.0.0.0/0"]` on port 5432. Explain the real-world danger and why catching it in IaC is dramatically cheaper than catching it post-deploy.

**3.5** 🟢 Which file prevents your local `.env` from being copied into the Docker image?

---

## Quiz 4 — Phase 4: DAST & Container Security

**4.1** 🟢 DAST tests the app in what state?
A) As source code  B) As a stopped image  C) Running  D) As a Terraform plan

**4.2** 🟡 Why does the `sign` job declare `needs: [build, scan]` rather than running in parallel?

**4.3** 🟡 What does the deploy-time `cosign verify` step actually guarantee before deployment proceeds?

**4.4** 🔴 Order these and justify the order: `sign`, `deploy`, `scan`, `build`. Then explain why deploying by *digest* (not tag) matters for the signature to be meaningful.

**4.5** 🟡 Why did choosing `node:20-alpine` as the base image make the image scan quieter?

---

## Quiz 5 — Phase 5: Runtime & Compliance

**5.1** 🟢 What STRIDE threat does structured audit logging primarily counter?

**5.2** 🟡 Why is log *redaction* configured once in the logger rather than left to each caller? What design principle is this?

**5.3** 🟡 bcrypt already slows *offline* password guessing. What attack does the Phase 5 brute-force guard stop that bcrypt does not?

**5.4** 🔴 Our scanners fail the build only on HIGH/CRITICAL and Dependabot auto-opens fix PRs. Explain how *both* choices serve the same underlying principle, and name it.

**5.5** 🟢 True/False: The compliance report exits non-zero if any control has HIGH/CRITICAL findings.

---

# 📝 Part C — Capstone Final Exam

*20 questions spanning the whole series. Aim for 16/20 to consider yourself series-fluent.*

**C1** 🟡 Trace a single code change from a developer's keyboard to running in production. Name the *security guardrail* at each of the five lifecycle stages (Develop, Build, Package, Deploy, Run).

**C2** 🟢 Match tool → job:
Semgrep · Trivy · gitleaks · Cosign · OWASP ZAP · bcrypt · Zod · Helmet
(Jobs: password hashing · SAST · secret scanning · image signing · DAST · dependency/image/IaC scanning · input validation · security headers)

**C3** 🔴 The same threat — "secrets leak" — is defended at *four* different points in this series. Name all four and the stage each operates at.

**C4** 🟡 Explain the difference between authentication and authorization using a concrete `securenotes` example of each.

**C5** 🟡 Why is a JWT payload *not* a safe place to store a secret, even though the token is "signed"?

**C6** 🔴 A scanner reports CVSS 9.8 CRITICAL in a transitive dependency. Walk through the Phase 5 triage flow (all 5 steps) and describe two legitimate outcomes.

**C7** 🟢 Which of these can a developer bypass with `--no-verify`: the pre-commit hook, or the CI pipeline? What does that tell you about where enforcement belongs?

**C8** 🟡 Explain why "delete the committed secret" is insufficient, referencing Git's permanence and the required follow-up action.

**C9** 🔴 Describe how keyless signing eliminates the single most dangerous secret in traditional signing, and how the deploy gate turns a signature into an *enforced* control.

**C10** 🟡 Name the four golden rules and give the STRIDE threat each most directly defends.

**C11** 🟢 True/False: Image scanning and SCA are redundant. Justify.

**C12** 🟡 In the CI YAML, `jobs` run in parallel but `steps` run in order. Give one place in the series where we *deliberately override* the parallel default, and the keyword used.

**C13** 🔴 A junior dev says "we already have a WAF, so the in-app anomaly detector is pointless." Rebut this using the RASP-vs-WAF distinction and defense in depth.

**C14** 🟡 Why does our error handler send `{"error":"Internal server error"}` to the client but log full detail server-side? Which STRIDE threat does this address?

**C15** 🟢 What does an SBOM let you do the day a new Log4Shell-style CVE is announced?

**C16** 🟡 Explain the purpose of `USER node` in the Dockerfile and the security principle it embodies.

**C17** 🔴 Rate limiting, body-size caps, connection pooling, and the brute-force guard all defend one STRIDE threat. Which one, and briefly how each contributes.

**C18** 🟡 Why is `fetch-depth: 0` required for full-history secret scanning but not for a normal build job?

**C19** 🟢 What's the difference between an image *tag* and an image *digest*, and which do we deploy by?

**C20** 🔴 In 3–4 sentences, articulate the core thesis of the entire series: what "shifting left" means, why defense in depth matters, and why keeping developers fast is a security goal (not a compromise).

---

# 🛠️ Part D — Practical Skills Test (Hands-On)

*Prove you can actually operate the pipeline. Each task has a pass criterion.*

**D1 — Break and catch a secret.** On a scratch branch, add a file with a fake AWS key and attempt to commit it.
✅ *Pass:* the commit is aborted by the pre-commit hook.

**D2 — Break and catch code.** Add a function using `eval(userInput)` and run `npm run lint`.
✅ *Pass:* ESLint fails with `no-eval` / `security/detect-eval-with-expression`.

**D3 — Break and catch a dependency.** `npm install lodash@4.17.11` then `npm audit`.
✅ *Pass:* audit reports HIGH-severity CVEs. (Then uninstall.)

**D4 — Prove ownership isolation.** Create a note as user A (token A); attempt to fetch it as user B (token B).
✅ *Pass:* B receives `404`, not the note.

**D5 — Break and catch a misconfiguration.** Set a Terraform DB security group to `0.0.0.0/0` and run Checkov.
✅ *Pass:* Checkov fails with an open-ingress finding. (Then revert.)

**D6 — Verify a signature.** Run `cosign verify` against your signed image with the correct identity regexp, then again with a *wrong* identity.
✅ *Pass:* first succeeds, second fails.

**D7 — Prove redaction.** Make a request with an `Authorization` header and inspect the app logs.
✅ *Pass:* the logged `authorization` field reads `[REDACTED]`.

**D8 — Trigger the immune system.** Fire 6 failed logins from one IP, then send a body containing `UNION SELECT`.
✅ *Pass:* the 6th login returns `429`; the injection attempt returns `400` and logs a "suspicious pattern" warning.

---
---

# ✅ ANSWER KEYS

## Part A — Primer Quiz Keys

**P1.1** B — `GET` is the safe, read-only method; using it to change data is a classic vulnerability.
**P1.2** C — Without the JSON `Content-Type`, Express's `express.json()` parser may not engage, leaving `req.body` empty.
**P1.3** 1→`403`, 2→`401`, 3→`400`, 4→`201`. (401 = "who are you?"; 403 = "I know you, and no.")
**P1.4** Because the server keeps no memory between requests (stateless), it can't "remember" you logged in; therefore each request must carry its own proof of identity — a self-contained, signed token (JWT) is exactly that.

**P2.1** False — passwords must be *hashed* (one-way), not encrypted. Encryption is reversible, so a stolen key exposes every password.
**P2.2** Slowness (~100ms/hash) is imperceptible for one honest login but drops an attacker from billions of guesses/sec to a handful, making brute-forcing stolen hashes infeasible. It's also adaptive (raise the work factor over time).
**P2.3** B — the payload is only base64-*encoded*, readable by anyone; only the *signature* requires the secret to create.
**P2.4** IDOR (Insecure Direct Object Reference); violates **Elevation of privilege / Tampering**; prevented by golden rule #4 (scope every query to the authenticated owner's ID).

**P3.1** B — recipe (image) / meal (container). One recipe → many meals.
**P3.2** Dependencies change rarely, code changes constantly. Putting the slow `npm ci` in an earlier layer lets Docker *cache* it, so editing code doesn't force a re-install — faster builds.
**P3.3** In a *lower layer* — most likely an OS package in the `node:20-alpine` base image. Source scanning only sees your code layer; image scanning inspects *all* layers including the inherited OS.
**P3.4** Multi-stage build ships only compiled output + prod deps (no compilers/dev deps/source) → smaller attack surface. `USER node` drops root so a compromise is confined to an unprivileged user → addresses **Elevation of privilege**.

**P4.1** B — nesting (what belongs inside what).
**P4.2** With no `needs:`, jobs run **in parallel**; steps inside a single job run **in sequence** (top to bottom).
**P4.3** Only when Trivy finds a **HIGH or CRITICAL** vulnerability — it then exits non-zero (`1`), failing the step/job. MEDIUM/LOW are reported but don't fail it.
**P4.4** A local hook can be *bypassed* (`git commit --no-verify`) and doesn't cover pre-existing history; the server-side CI scan can't be bypassed and scans everything. Running both = **defense in depth** (same threat guarded at two layers).

**P5.1** Just `npm run dev` — the `$` is only the prompt symbol; you never type it.
**P5.2** Order: `git add` → `git commit` → `git push`. `git add` moves changes into the **staging area**; `git commit` moves them into **history (the repository)**; `git push` sends history to the **remote server (GitHub)**.
**P5.3** On the **`git commit`** boundary — after staging, before the snapshot is sealed into history. Ideal because a detected secret is blocked *before* it ever enters permanent history.
**P5.4** No, it's not gone — history is permanent; the secret persists in the earlier commit. Required: (1) rewrite history to purge it, and (2) **rotate** the leaked credential (assume it's already compromised).

**P6.1** The **private** key creates the signature; the **public** key verifies it.
**P6.2** Forging requires the **private key**, which the attacker lacks. Reading a signature only needs the public key (verification); creating one needs the secret private key — an asymmetry they can't overcome.
**P6.3** A tag (`:latest`) is *mutable* and can be repointed to different bytes after verification; a **digest** is the immutable fingerprint of exact content, so signing/verifying by digest guarantees the vetted bytes are the ones that run (defeats time-of-check/time-of-use swaps).
**P6.4** **No.** Verification demands the signer's identity match our *specific* `release.yml`. The attacker's own identity — even if a valid Sigstore signature — doesn't match the pinned regexp, so `cosign verify` returns non-zero and the deploy gate blocks it.

**P7.1** A single, unambiguous, globally-shared ID for one specific known vulnerability (like an ISBN).
**P7.2** No — CVSS is a starting point, not the verdict. You assess **exploitability/reachability**: is the vulnerable code path actually reachable by untrusted input in *your* usage? If not, real-world urgency may be lower (document it in the accepted-risk register).
**P7.3** The **SBOM** — query each service's SBOM (inventory) for `some-lib@2.3.0` to instantly list which services ship the vulnerable version.
**P7.4** Example: *"Your SBOM shows you ship lodash@4.17.11, which contains CVE-2021-23337, rated CVSS 7.2 (HIGH) — remediate within the HIGH SLA."*

---

## Part B — Phase Quiz Keys

**1.1** The `!` un-ignores `.env.example` so the *template* (fake values, documents required vars) is committed, while the real `.env` stays ignored.
**1.2** To fail fast at startup on misconfiguration (and reject a weak, short signing secret) rather than running silently broken — the **fail-fast configuration** pattern. It also enforces golden rule #1.
**1.3** **Helmet** (protective HTTP headers — mitigates info disclosure/clickjacking) and **express-rate-limit** (request flooding — mitigates **Denial of Service**).
**1.4** The **pre-commit hook** was bypassed (it can be skipped with `--no-verify`). The **Phase 3 CI full-history gitleaks scan** (server-side, un-skippable) still catches it.
**1.5** False — `.gitignore` makes files *invisible to Git* (never committed); it doesn't delete anything on disk.

**2.1** SAST scans **your own source code**; SCA scans **third-party dependencies**.
**2.2** So it's structurally impossible to access data without scoping to an owner — enforcing golden rule #4 and preventing IDOR/Tampering by design, not by remembering to add a check.
**2.3** `npm ci` installs the *exact* versions from `package-lock.json` and fails if the lockfile is out of sync — reproducible and tamper-evident (supply-chain integrity), unlike `npm install` which can drift.
**2.4** Prevents **user enumeration** (discovering which emails are registered) — a form of **Information disclosure**.
**2.5** The **exit code** — a non-zero exit from a required check fails the status check, which branch protection requires to be green before enabling merge.

**3.1** The SQL text and the data travel on separate channels; parameters are always treated as *data*, never parsed as SQL *commands*, so injected commands can't execute.
**3.2** `fetch-depth: 0` pulls the **entire commit history** (not just the latest commit) so gitleaks can scan every past commit for secrets already baked into history.
**3.3** Any two: (a) centralizes control + access logging + rotation without redeploys; (b) avoids `.env` files being copied/backed-up/accidentally-logged across many machines; (c) uses the app's identity (IAM role) so no static credentials are stored in code/env.
**3.4** `0.0.0.0/0` on port 5432 opens the database to the *entire internet* — a full data-breach exposure. Catching it in the IaC blueprint is a one-line code edit; catching it post-deploy could mean an actual breach and incident response (the ~10x cost principle).
**3.5** `.dockerignore`.

**4.1** C — running.
**4.2** To force an order so you only sign an image that has *successfully built and passed scanning* — signing a vulnerable/unscanned image would be meaningless.
**4.3** That the exact image (by digest) was signed by *our* trusted release workflow (verified identity + issuer) and hasn't been tampered with — otherwise deployment is blocked.
**4.4** Order: **build → scan → sign → deploy.** You must build before you can scan, scan before you vouch (sign), and verify the signature before you deploy. Deploying by *digest* ensures the exact bytes that were scanned/signed are the ones that run; a mutable tag could be swapped after verification, making the signature worthless.
**4.5** Alpine is a minimal base with far fewer OS packages than a full distro — fewer packages means fewer potential CVEs, so the layer scan surfaces far less.

**5.1** **Repudiation** (a tamper-evident record of who did what, when).
**5.2** Configuring redaction once in the logger makes safe logging the *default*, so no individual `logger.info(...)` call can accidentally leak a token/password — the **secure-by-default** principle (doesn't rely on human vigilance).
**5.3** bcrypt slows *offline* guessing against a stolen hash DB; the brute-force guard stops *online* guessing — hammering the live login endpoint — by locking out an IP after repeated failures. (Two attacks, two defenses = defense in depth.)
**5.4** Both minimize **developer friction** (keeping developers fast). Failing only on HIGH/CRITICAL avoids alert fatigue on trivial findings; Dependabot auto-opening fix PRs turns "you have a problem" into "here's the fix." Principle: *a security control developers find frictionless is one they'll actually keep using.*
**5.5** True.

---

## Part C — Capstone Exam Key

**C1** Develop → pre-commit hooks / IDE lint / secret scan. Build → SAST (Semgrep) + SCA (npm/Trivy) + secret-history scan + IaC audit. Package → container image scan + Cosign signing. Deploy → signature verification gate + deploy by digest. Run → audit logging + brute-force/anomaly RASP + compliance reporting.
**C2** Semgrep→SAST; Trivy→dependency/image/IaC scanning; gitleaks→secret scanning; Cosign→image signing; OWASP ZAP→DAST; bcrypt→password hashing; Zod→input validation; Helmet→security headers.
**C3** (1) IDE/pre-commit hook — Develop; (2) CI full-history gitleaks scan — Build; (3) secret manager (vault) — Deploy/Run; (4) log redaction preventing secrets leaking into logs — Run. (Also acceptable: `.gitignore`/`.dockerignore` at Develop/Package.)
**C4** AuthN example: `/auth/login` verifying Alice's email+password (who she is). AuthZ example: the ownership check letting Alice fetch only *her* notes, not Bob's (what she may touch).
**C5** The payload is only base64-*encoded*, not encrypted — anyone with the token can read it. The signature proves integrity/authenticity but doesn't hide contents.
**C6** Steps: (1) verify it's a true positive; (2) assess exploitability/reachability in our usage; (3) assign severity+owner+SLA; (4) remediate (merge Dependabot PR / fix code / or suppress with justification+review date+compensating control); (5) verify the fix by re-running the scanner. Two legitimate outcomes: *fix it* (merge the update) **or** *formally accept the risk* (document in the register if unreachable/no-fix).
**C7** A developer can bypass the **pre-commit hook** (`--no-verify`); they **cannot** bypass the CI pipeline. Enforcement therefore belongs *centrally* (in CI + branch protection), with the local hook as a fast first layer.
**C8** Git history is permanent — the secret persists in the earlier commit even after deletion in a later one. Required follow-up: **rotate the credential** (and, to fully remove, rewrite history), because you must assume it's already compromised.
**C9** Keyless signing removes the long-lived **private signing key** (nothing to store or leak); trust is based on short-lived, verifiable OIDC identity logged publicly in Rekor. The deploy gate runs `cosign verify` and *blocks deployment* (non-zero exit) unless the signature matches our exact workflow identity — turning the signature from decoration into an enforced control.
**C10** (1) Secrets in env vars → Secrets-leak/Info-disclosure; (2) Parameterized queries → Tampering/Info-disclosure (SQLi); (3) Validate input at edge → Info-disclosure/Tampering; (4) Scope queries to owner → Elevation of privilege/Tampering (IDOR).
**C11** False. SCA scans your *npm dependencies*; image scanning also covers the *OS-package layer* baked into the base image, which SCA doesn't see. They overlap on libraries but each covers ground the other doesn't.
**C12** Phase 4's `release.yml` uses `needs:` (e.g., `scan` needs `build`, `sign` needs `[build, scan]`, `deploy` needs `[build, scan, sign]`) to force sequence. Keyword: **`needs:`**.
**C13** A WAF sits at the network edge and inspects traffic generically; RASP lives *inside* the app with full context (which user, route, data) and can catch context-specific abuse the WAF can't see. They're complementary layers — **defense in depth** — not substitutes.
**C14** Returning a raw error/stack trace would leak internal implementation details attackers can exploit (**Information disclosure**); the generic client message + detailed server-side log gives us debuggability without leaking.
**C15** Instantly query the SBOM inventory to determine exactly which services/components ship the affected library version — answering "are we affected?" in minutes.
**C16** It runs the container process as an unprivileged user instead of root, so a compromise is confined (can't act as admin inside the container) — the **least privilege** principle (defends Elevation of privilege).
**C17** **Denial of Service.** Rate limiting caps requests per IP; body-size caps stop huge-payload memory exhaustion; connection pooling prevents DB connection exhaustion; the brute-force guard blocks credential-flooding of the login endpoint.
**C18** Full-history secret scanning must examine every past commit, which requires the complete history (`fetch-depth: 0`); a normal build only needs the latest snapshot, so the default shallow checkout is fine (and faster).
**C19** A *tag* is a mutable label that can point to different images over time; a *digest* (`sha256:...`) is an immutable content fingerprint. We deploy by **digest**.
**C20** "Shifting left" means moving security checks earlier (to the developer's laptop and CI) where flaws are ~10x cheaper to fix. Defense in depth stacks multiple independent controls so that if one fails (e.g., a bypassed hook), another catches the issue. Keeping developers fast — failing only on serious findings, automating fixes, low-noise gates — is itself a security goal, because a control that's too annoying gets disabled, and a disabled control protects nothing.

---

## Part D — Practical Skills Test Key (expected results)

**D1** Commit aborted; gitleaks reports a detected secret (non-zero exit). *Cleanup:* `git reset` + `rm` the file.
**D2** `npm run lint` fails on `no-eval`/`security/detect-eval-with-expression`. *Cleanup:* delete the file.
**D3** `npm audit` lists HIGH CVEs for lodash 4.17.11. *Cleanup:* `npm uninstall lodash`.
**D4** User B gets `404 {"error":"Not found"}` — never the note (ownership isolation / golden rule #4). Returning 404 (not 403) also avoids confirming the note exists.
**D5** Checkov fails: "security group allows ingress from 0.0.0.0/0 to port 5432." *Cleanup:* revert to `var.app_subnet_cidr`.
**D6** Correct identity regexp → verification succeeds (prints cert + Rekor entry). Wrong identity → verification fails (non-zero). Demonstrates the gate blocks look-alike/attacker-signed images.
**D7** The request log line shows `"authorization": "[REDACTED]"` — the token never hits disk.
**D8** 1st–5th failed logins → `401`; 6th → `429` with `Retry-After`. The `UNION SELECT` body → `400 {"error":"Request rejected"}` plus a `"Suspicious request pattern detected"` WARN log with source IP.

---

## 📊 Scoring guide

| Assessment | Questions | "Fluent" threshold |
|---|---|---|
| Each Primer quiz | 4 | 3 / 4 |
| Each Phase quiz | 5 | 4 / 5 |
| Capstone Final Exam | 20 | 16 / 20 |
| Practical Skills Test | 8 tasks | 7 / 8 pass criteria met |

**Interpretation:**
- **Below threshold on a quiz** → re-read that phase/primer; the wrong answers point to the exact section.
- **Capstone ≥ 16 but Practical < 7** → you understand the *why* but need more hands-on reps; redo the failed Practical tasks.
- **Practical ≥ 7 but Capstone < 16** → you can operate the tools but should shore up the conceptual "why" (revisit the primers) so you can *adapt* the pipeline, not just run it.
