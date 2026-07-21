# 🔒 Modern DevSecOps: Building Secure Software Delivery Pipelines

## Part 0: Introduction — Your Roadmap to Continuous Security

> *"Security is everyone's job now. This series is how you actually do that job — one automated guardrail at a time."*

Welcome. Before we write a single line of code, run a single scanner, or sign a single container image, we're going to spend this part doing something that great engineers do and rushed engineers skip: **establishing shared context.** By the end of Part 0, you'll know exactly what we're building, why it's structured the way it is, who this is for, and what your hands will actually be doing over the coming phases.

Think of Part 0 as the **trailhead map at the start of a long hike.** We'll show you the whole mountain, mark the rest stops, tell you what to pack, and warn you about the tricky switchbacks — so that once we start climbing, you're never lost.

---

## 0.1 — What Is DevSecOps, Really?

Let's define the core term inline, because the whole series orbits around it.

> **Definition — DevSecOps:** A cultural and technical practice that weaves **Sec**urity directly into the existing **Dev**elopment and **Op**erations workflow — making it *automated, continuous, and shared*, rather than a manual gate at the end.

Here's the analogy that makes it click.

Imagine building a house.

- **Traditional security** is like finishing the entire house — walls, plumbing, electrical, drywall, paint — and *then* calling an inspector. If the inspector finds the wiring is unsafe, you have to tear open finished walls to fix it. Expensive, slow, and infuriating.
- **DevSecOps** is like having a licensed electrician *on the crew*, checking every wire as it's installed, with a checklist taped to the wall that anyone can follow. Problems are caught while the wall is still open and cheap to fix.

The industry has a nickname for moving these checks earlier: **"shifting left."** Picture your software timeline as a straight line running left (writing code) to right (running in production). The further *right* a security bug travels before you catch it, the more it costs to fix. Studies consistently show remediation is roughly **10x more expensive** once code reaches production versus catching it on the developer's laptop. Our entire strategy is to catch problems as far *left* as possible.

### The three big mindset shifts

| Old DevOps thinking | DevSecOps thinking |
|---|---|
| "Security reviews us before release." | "Security tooling reviews *every commit*, automatically." |
| "The security team owns security." | "Everyone owns security; the security team owns the *guardrails*." |
| "Scans slow us down." | "Automated scans keep us fast by preventing painful rework." |
| "We fix vulnerabilities when we're breached." | "We prevent, detect, and triage continuously." |

---

## 0.2 — Who This Series Is For (Target Audience)

This series is deliberately written to be **beginner-friendly on the outside and expert-grade on the inside.** That means the *explanations* assume very little, but the *code* is production-quality — proper error handling, environment variables, type safety, and real security controls.

You'll get the most out of this if you're one of these people:

- **🧑‍💻 The Application Developer** who writes features all day, has heard "we need to shift left," and wants to understand what all these scanners actually do — and how to stop them from blocking your pull requests for silly reasons.
- **⚙️ The DevOps / Platform Engineer** who owns the CI/CD pipeline and needs to bolt security stages onto it without turning a 5-minute build into a 45-minute ordeal.
- **🛡️ The Security Practitioner / AppSec Engineer** who understands threats deeply but wants to see how to *operationalize* them as automated, developer-friendly controls instead of PDF reports nobody reads.
- **🎓 The Curious Learner / Student** who wants a single, coherent, hands-on project that ties together the buzzwords (SAST, SCA, DAST, IaC, image signing, RASP) into one working system.

### What we assume you already know

To keep the series moving, we assume you're comfortable with:

- **The command line** — you can `cd` into folders, run commands, and aren't scared of a terminal.
- **Basic Git** — commit, push, pull, branch. (We'll explain the security-specific Git bits.)
- **Reading code** — you don't need to be a TypeScript expert; we define terms inline, but you should be able to follow a function.

### What you do *NOT* need to know

You do **not** need prior experience with: any specific security scanner, Docker, Kubernetes, Terraform, CI/CD systems, threat modeling frameworks, or cryptographic signing. **We build all of that from zero, together, with complete explanations.** Every tool is introduced with a real-world analogy before you're asked to use it.

---

## 0.3 — The Application We'll Secure: `securenotes`

You can't learn security in the abstract — you need something *real* to protect. So throughout every phase we'll build and progressively harden a single, deliberately realistic application called **`securenotes`**.

**What it does:** A REST API where authenticated users can create, read, update, and delete their own private notes.

Why a notes app? Because it's small enough to understand in an afternoon, but it contains *every classic security concern in miniature*:

- **Authentication** (proving who you are) → so we can practice defending against spoofing.
- **Authorization** (only touching *your* notes) → so we can practice preventing users from reading each other's data.
- **A database** → so we can practice defeating SQL injection and securing credentials.
- **User input everywhere** → so we can practice input validation.
- **Open-source dependencies** → so we can practice supply-chain scanning.
- **A deployable container** → so we can practice image scanning and signing.
- **A running production surface** → so we can practice runtime monitoring.

### Our technology stack (and why)

We chose boring, popular, well-supported tools on purpose. Security loves boring — boring means well-documented, widely-scanned, and battle-tested.

| Layer | Tool | Why we picked it |
|---|---|---|
| Language | **TypeScript** on Node.js | Types catch bugs before runtime; huge ecosystem to demonstrate SCA. |
| Web framework | **Express** | The most common Node framework — most likely to match your job. |
| Validation | **Zod** | Turns untrusted input into trusted, typed data at the edge. |
| Database | **PostgreSQL** | Industry-standard relational DB; lets us demo parameterized queries. |
| Auth | **JWT + bcrypt** | Standard token auth and password hashing. |
| Containerization | **Docker** | The universal packaging format we'll scan and sign. |
| CI/CD | **GitHub Actions** | Free, ubiquitous, and YAML-based — easy to read and copy. |
| IaC | **Terraform** | The dominant Infrastructure-as-Code tool we'll audit. |

> Don't worry if half those words are unfamiliar — each gets a friendly introduction the moment we first use it.

---

## 0.4 — The Ultimate Architecture You'll Build

Here's the mountain we're climbing. By the final phase, every one of these boxes will exist as real, working code and configuration in your repository. This diagram maps the **five stages of the software delivery lifecycle** to the **five phases of this series.**

```
                         THE SECURE SOFTWARE DELIVERY PIPELINE
                         (each stage adds an automated security guardrail)

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │  ① DEVELOP        │  ② BUILD          │  ③ PACKAGE       │  ④ DEPLOY  │ ⑤ RUN  │
  │  (your laptop)    │  (CI server)      │  (CI server)     │ (staging)  │ (prod) │
  ├───────────────────┼───────────────────┼──────────────────┼────────────┼────────┤
  │                   │                   │                  │            │        │
  │  • Threat model   │  • SAST scan      │  • Container     │  • DAST    │ • RASP │
  │  • IDE linter     │    (your code)    │    image scan    │    sweep   │   agent│
  │  • Pre-commit     │  • SCA scan       │  • IaC audit     │  • Deploy  │ • Log  │
  │    hooks          │    (dependencies) │    (Terraform)   │    gate    │   aggr.│
  │  • Secret scan    │  • Unit tests     │  • Image signing │            │ • Comp-│
  │                   │                   │    (provenance)  │            │  liance│
  │                   │                   │                  │            │  report│
  │   PHASE 1 & 3     │     PHASE 2       │   PHASE 3 & 4    │  PHASE 4   │ PHASE 5│
  └───────────────────┴───────────────────┴──────────────────┴────────────┴────────┘
        SHIFT LEFT ◄────────────────────────────────────────────────────► SHIFT RIGHT
        (cheap to fix)                                          (expensive to fix)

  Guiding rule: a failure at ANY guardrail can BLOCK the pipeline before the
  vulnerable artifact ever advances to the next stage.
```

Read that diagram left-to-right and you're reading the journey of a single code change — from a developer typing it, to it running live in production — with a security checkpoint at every border crossing.

---

## 0.5 — The Five Phases at a Glance

Here's your itinerary. Each phase produces tangible, working artifacts you'll commit to the repo.

### 🌱 Phase 1 — The Shift Left Foundation
**Focus:** Culture, Threat Modeling & IDE Integration.
You'll bootstrap the `securenotes` app, write a **STRIDE threat model** *before* coding, configure IDE security linting, and install **pre-commit hooks** that block hardcoded secrets from ever leaving your laptop. This is where "security culture" becomes concrete files.

### 🔍 Phase 2 — Code & Dependency Security (SAST & SCA)
**Focus:** Automated Code Analysis & Supply Chain Defense.
Since modern apps are 80–90% open-source code, we set up **SAST** (Static Application Security Testing — a scanner that reads *your* source code for vulnerable patterns) and **SCA** (Software Composition Analysis — a scanner for vulnerable *third-party dependencies*), wiring both into CI so they run on every pull request.

### 🔑 Phase 3 — Secrets Management & Infrastructure as Code
**Focus:** Preventing Credential Leaks & Hardening IaC.
Exposed API keys and misconfigured cloud infra are leading breach causes. You'll add repo-wide **secret scanning**, learn to store credentials in a proper **secret manager** instead of code, and **audit Terraform** for misconfigurations and compliance drift.

### 💥 Phase 4 — Dynamic Testing & Container Security
**Focus:** DAST, Container Scanning & Image Signing.
We go beyond static files to the *running* app. You'll run **DAST** (Dynamic Application Security Testing — attacking your live app like a hacker would), scan your Docker image layer-by-layer for vulnerable OS packages, and **digitally sign** your image so its integrity can be proven downstream.

### 📡 Phase 5 — Runtime Protection & Continuous Compliance
**Focus:** Observability, Incident Response & Pipeline Governance.
Security doesn't stop at deploy. You'll add **runtime protection**, structured **audit logging** (remember "repudiation" from the threat model?), **anomaly monitoring**, and **automated compliance reporting** — all while keeping developer friction low through smart vulnerability triage.

---

## 0.6 — How Each Step Is Structured

Consistency helps you learn faster. Every single technical step in Phases 1–5 follows the same four-beat rhythm, so you always know where you are:

1. **🎯 The Target** — the exact file, config, or feature we're building *right now*.
2. **🧠 The Concept** — a plain-English explanation using a real-world analogy, with technical terms defined the first time they appear.
3. **⌨️ The Implementation** — complete, copy-pasteable, unabbreviated code with the exact filename and path labeled. **No `// todo`, no `// rest of code here` — ever.**
4. **✅ The Verification** — precise commands or actions to *prove* the step worked before you move on (terminal output, `curl` requests, browser results, or scanner logs).

At the end of each phase you'll also find **📚 Reference Sections** — optional deep dives into tool internals and API breakdowns, kept *separate* from the main flow so the tutorial stays fast and practical. Skip them on the first pass; return when you want mastery.

---

## 0.7 — Prerequisites & Setup Checklist

Before Phase 1, make sure your machine has these installed. Version numbers are minimums.

```bash
# Check each of these — install any that are missing.

node --version        # need v20+   (the JavaScript runtime our app runs on)
npm --version         # need v10+   (Node's package manager)
git --version         # need v2.30+ (version control; our hooks plug into it)
docker --version      # need v24+   (container packaging — used from Phase 4)
```

Additionally, you'll want:

- **A code editor with an extension marketplace** — VS Code is assumed, but any modern IDE works. (Phase 1 configures IDE security linting.)
- **A free GitHub account** — we use GitHub Actions for CI/CD starting in Phase 2.
- **~2–3 GB free disk space** — mostly for Docker images and scanner databases.

> **You do not need to install every scanner now.** Each phase installs its own tools with full instructions, exactly when they're first needed. This keeps setup incremental and never overwhelming.

### A note on cost
Everything in this series can be completed for **$0** using free tiers and open-source tools. Where a commercial option exists, we'll mention it, but the hands-on path always uses a free, open-source tool so nobody is blocked by a paywall.

---

## 0.8 — Expectations & How to Get the Most From This Series

A few honest expectations to set before we begin:

- **This is hands-on. Type the code — don't just read it.** The muscle memory of running a scanner and *seeing it catch a real bug you planted* is the entire point. We'll deliberately introduce vulnerabilities so you can watch the guardrails catch them.
- **The build is cumulative.** Each step depends on the last. We never introduce a package, folder, or config without first explaining *why* it's needed. If you jump into the middle, back up — the earlier files won't exist yet.
- **Security is layered, not a single fix.** You'll notice we defend the same threat in multiple phases (e.g., secrets are protected at the IDE, at pre-commit, *and* in CI). This is **defense in depth** — the assumption that any single control can fail, so we stack several.
- **Friction is the enemy of adoption.** Throughout, we optimize for keeping developers fast. A security control nobody uses because it's annoying is worse than no control at all. You'll see us tune scanners to fail on *real* problems, not noise.

### The golden rules we lock in from Day 1
These four principles (drawn straight from the threat model we build in Phase 1) will govern every line of code we write:

1. **Secrets live in environment variables — never in code.**
2. **Database access uses parameterized queries — never string concatenation.**
3. **All external input is validated at the edge before it's trusted.**
4. **Every data query is scoped to the authenticated user who owns the data.**

---

## 0.9 — Ready to Begin

Here's what happens next. We transition immediately into the technical build. Phase 1 starts by scaffolding the `securenotes` project, writing our threat model, and turning your laptop into the first automated security checkpoint with IDE linting and pre-commit hooks.

You'll finish Phase 1 with a running, security-configured API and a Git repository that *physically refuses* to accept a hardcoded secret. That's the "shift left" promise made real — and it's just the foundation.

Grab your terminal. Let's build something secure. 🚀
