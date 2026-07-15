# Secure Software Engineering from Zero to Prod
## Part 0: Series Introduction — "Before We Build Anything"

Every construction crew has a kickoff meeting before anyone touches a shovel: what are we building, who's on the crew, what tools go in the truck, and how do we know when a wall is actually finished? That's what Part 0 is. It's short, it's mostly setup, but skipping it is exactly how people end up three parts deep, missing a tool, and stuck.

By the end of Part 0 you will have: a working dev machine with every tool this series needs, a GitHub account wired up and authenticated, and a clear mental model of how each of the next 8 parts is structured — so nothing surprises you later.

---

## 📖 Why This Series Exists

Most tutorials teach you to build an app, and *maybe* bolt security on at the end as a "bonus chapter" — usually just "add HTTPS" and a pat on the back. In the real world, that's backwards. Security debt compounds exactly like technical debt: the later you address it, the more it costs to fix, and the more likely a shortcut becomes a headline.

This series does the opposite. We treat security as a **first-class citizen at every stage** — from the very first sentence written about the app (Part 1), all the way to shutting it down safely years later (Part 8). We're not writing a "secure coding" tutorial with a few OWASP links glued on. We're simulating the actual lifecycle a professional engineering team goes through, using one real app (`SecureTrade`) as the constant thread.

---

## 🧠 How Each Part Is Structured (read this once, refer back anytime)

Every step in every part follows the exact same four-beat rhythm, so you always know what kind of information you're reading:

| Beat | What it answers |
|---|---|
| 🎯 **The Target** | What specific file/config/feature are we building *right now*? |
| 💡 **The Concept** | What's the underlying idea, explained with an everyday analogy, before code? |
| 🛠️ **The Implementation** | The full, copy-pasteable code — never abbreviated, never `// TODO` |
| ✅ **The Verification** | The exact command/request/click to *prove* it worked before moving on |

Starting from **Part 3 onward**, we add a fifth beat to most labs: **🔓 Break It First**. We'll deliberately write the vulnerable version of a feature, attack it ourselves with a real payload, watch it fail, and *then* patch it. You learn a defense far better once you've personally watched the attack succeed.

Deep theory (e.g., "what is STRIDE, in full detail" or "every NextAuth configuration option") never clutters the build steps — it's always pushed to a **Reference** section at the end of that part, like the one at the bottom of this document.

---

## 🗺️ Quick Recap: The 8-Part Journey

| Part | You will be able to... |
|---|---|
| 1 | Threat-model an app *before* writing code, using STRIDE/DREAD |
| 2 | Design a system architecture that limits blast radius when (not if) something breaks |
| 3 | Write Next.js code immune to the OWASP Top 10 |
| 4 | Stop supply-chain attacks hiding in your `node_modules` |
| 5 | Wire security scans into CI so bad code can't merge |
| 6 | Deploy hardened infra with proper headers, WAF, and monitoring |
| 7 | Detect and respond to a live breach like an incident commander |
| 8 | Keep the app secure for years, and prove it with metrics execs understand |

We now set up the crew's toolbox.

---

## Step 1 — Verify Your Prerequisite Knowledge

### 🎯 The Target
A short self-check — no code yet — to confirm you're ready for this series.

### 💡 The Concept
Think of this like a pre-flight checklist a pilot runs before a passenger ever boards. It's not about being an expert — it's about confirming the basic instruments work so nothing catches you off guard mid-flight.

You do **not** need prior security experience — that's the entire point of this series. But you should be comfortable with:

- **Basic JavaScript/TypeScript** — variables, functions, `async/await`, arrays/objects
- **Basic command line usage** — navigating folders (`cd`), running commands
- **Basic Git** — `git add`, `git commit`, `git push`, and what a "repository" is
- **Basic React concepts** — components, props, state (we'll explain Next.js-specific ideas as we go)

If any of those feel shaky, that's fine — we define every technical term the first time it appears, inline, in plain English. You're not expected to know *security* concepts yet (STRIDE, RBAC, CSP, etc.) — those are precisely what this series teaches, from scratch, starting in Part 1.

### ✅ The Verification
No command here — just an honest gut-check. If you can read this line and understand it, you're ready:

```ts
const total = items.reduce((sum, item) => sum + item.price, 0);
```
If that made sense, move on to Step 2.

---

## Step 2 — Install Node.js (via nvm)

### 🎯 The Target
Node.js installed and pinned to a specific version, using a **version manager** rather than a single global install.

### 💡 The Concept
Imagine every app you'll ever build needs a specific "engine size" (Node version) to run correctly. If you only ever own one engine (a single global Node install), swapping projects means constantly reinstalling engines. A **version manager** (`nvm` — Node Version Manager) is like a garage that stores multiple engines side by side, and lets you say "use *this* engine for *this* project" instantly.

We pin an exact version using a `.nvmrc` file so that — three parts from now — you (or a teammate, or a CI server) can run one command and get the *exact* same Node version every time. This "reproducibility" is itself a security property: mismatched runtime versions are a surprisingly common source of "works on my machine" bugs that hide vulnerabilities.

### 🛠️ The Implementation

**macOS / Linux:**
```bash
# Install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Reload your shell config so the `nvm` command becomes available
source ~/.bashrc   # or ~/.zshrc if you use zsh

# Install the latest Long-Term Support (LTS) version of Node
nvm install --lts

# Set it as the default for all new terminal sessions
nvm alias default lts/*
```

**Windows:** install [nvm-windows](https://github.com/coreybutler/nvm-windows/releases), then open a **new** terminal and run:
```powershell
nvm install lts
nvm use lts
```

Now create a version-pin file. We'll place this at the root of the project we scaffold in Part 1 Step 1 — for now, create it in a temporary folder so the habit is in place:

##### 📄 File: `.nvmrc`
```
lts/*
```

### ✅ The Verification
```bash
node -v
npm -v
```
You should see output like:
```
v22.11.0
10.9.0
```
(Exact numbers will differ — any current LTS is fine. What matters is that both commands return a version, not a "command not found" error.)

---

## Step 3 — Install and Configure Git

### 🎯 The Target
Git installed, and your identity (name + email) configured globally, so every commit you make throughout this series is correctly attributed.

### 💡 The Concept
Git is like a security camera system for your codebase — it records *who* changed *what*, and *when*. That audit trail becomes genuinely important later in this series (Part 7's incident response relies on being able to answer "what changed, and who changed it?"). Configuring your identity now means that trail is trustworthy from commit #1.

### 🛠️ The Implementation

Install Git:
- **macOS:** `brew install git` (or it's already bundled with Xcode Command Line Tools)
- **Windows:** download from [git-scm.com](https://git-scm.com/download/win)
- **Linux (Debian/Ubuntu):** `sudo apt update && sudo apt install git -y`

Configure your identity:
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Set the default branch name for new repos to "main" (modern convention)
git config --global init.defaultBranch main

# Store credentials so you're not typing your GitHub password on every push
git config --global credential.helper store
```

### ✅ The Verification
```bash
git --version
git config --global --list
```
Confirm `user.name` and `user.email` appear correctly in the output.

---

## Step 4 — Create a GitHub Account and Authenticate the CLI

### 🎯 The Target
A GitHub account, plus the **GitHub CLI** (`gh`) installed and authenticated on your machine.

### 💡 The Concept
GitHub is where our repository will live — think of it as the shared, off-site vault where the crew's blueprints are stored, so a laptop dying doesn't destroy months of work. The GitHub CLI lets us create repositories, open pull requests, and (crucially, from Part 5 onward) configure repository security settings — all from the terminal, without hunting through web UI menus.

If you don't have a GitHub account yet, create one free at [github.com/signup](https://github.com/signup) before continuing.

### 🛠️ The Implementation

Install the GitHub CLI:
```bash
# macOS
brew install gh

# Windows (with winget)
winget install --id GitHub.cli

# Linux (Debian/Ubuntu)
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
```

Authenticate:
```bash
gh auth login
```
Follow the interactive prompts: choose `GitHub.com` → `HTTPS` → `Login with a web browser`, and paste the one-time code shown into the browser tab that opens.

### ✅ The Verification
```bash
gh auth status
```
Expected output:
```
github.com
  ✓ Logged in to github.com account <your-username> (keyring)
  ✓ Git operations for github.com configured to use https protocol.
  ✓ Token: *******************
```

---

## Step 5 — Set Up Your Editor (VS Code + Security-Relevant Extensions)

### 🎯 The Target
Visual Studio Code installed, with a project-level `extensions.json` recommending the exact extensions this series depends on — so anyone who opens the project (including future-you) gets prompted to install the right tools automatically.

### 💡 The Concept
A workspace recommendations file is like a "packing list" taped inside a toolbox lid. It doesn't force anything on you, but the moment you open this project in VS Code, it politely says "hey, you'll probably want these tools for this job" — instead of you discovering you're missing something halfway through Part 3's Semgrep lab.

### 🛠️ The Implementation

Install VS Code from [code.visualstudio.com](https://code.visualstudio.com/).

Create a temporary folder to hold this config for now (we'll move it into the real project in Part 1):

##### 📄 File: `.vscode/extensions.json`
```json
{
  // These are *recommended*, not mandatory — VS Code will show a prompt
  // in the Extensions panel offering to install all of them at once.
  "recommendations": [
    "dbaeumer.vscode-eslint",           // Runs ESLint (and later ESLint security rules) inline in the editor
    "esbenp.prettier-vscode",           // Consistent code formatting across the whole team
    "prisma.prisma",                    // Syntax highlighting + autocomplete for Prisma schema (Part 2)
    "bradlc.vscode-tailwindcss",        // Autocomplete for Tailwind CSS classes used in the UI
    "usernamehw.errorlens",             // Surfaces errors/warnings inline instead of only in the Problems tab
    "checkmarx.semgrep-vscode",         // Lets Semgrep security findings show up directly in the editor (Part 3)
    "github.vscode-github-actions",     // View and edit GitHub Actions workflows with syntax support (Part 5)
    "eamodio.gitlens"                   // Shows who changed each line and when — useful for the audit trail from Step 3
  ]
}
```

##### 📄 File: `.vscode/settings.json`
```json
{
  // Format files automatically on save, using Prettier
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",

  // Run ESLint's auto-fixable rules on save too (catches simple issues immediately)
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },

  // Never let secrets accidentally get suggested/synced via editor telemetry
  "telemetry.telemetryLevel": "off"
}
```

### ✅ The Verification
Open the folder containing these two files in VS Code:
```bash
code .
```
Click the **Extensions** icon in the left sidebar — you should see a section titled **"Recommended"** listing all 8 extensions with an **Install All** button. Click it, then confirm each shows as installed (no "Install" button remaining next to it).

---

## Step 6 — Create Accounts for Services We'll Use Later

### 🎯 The Target
Free-tier accounts on **Supabase** (our database, from Part 2) and **Vercel** (our hosting platform, from Part 6) — created now so account-verification emails and org setup don't interrupt you mid-lab later.

### 💡 The Concept
This is like registering your business name and opening a bank account *before* your store's grand opening — not on opening day itself. These platforms sometimes require email verification or identity checks that take a few minutes; doing it now removes friction later.

### 🛠️ The Implementation
No code in this step — just account creation:

1. Go to [supabase.com](https://supabase.com) → **Start your project** → sign up with GitHub (recommended, since it links directly to the GitHub account from Step 4).
2. Go to [vercel.com](https://vercel.com) → **Sign Up** → also choose **Continue with GitHub**.

Using "Continue with GitHub" for both means neither service needs a separate password, and both automatically gain the ability to link directly to repositories we'll create later.

### ✅ The Verification
Log into both dashboards:
- `https://supabase.com/dashboard` should show an empty **"No projects yet"** screen (that's correct — we create the actual project in Part 2).
- `https://vercel.com/dashboard` should show an empty **"No projects yet"** screen (we deploy in Part 6).

---

## Step 7 — Create the GitHub Repository That Will Hold Everything

### 🎯 The Target
An empty, private GitHub repository named `securetrade`, cloned locally — the actual home for the app we scaffold in Part 1, Step 1.

### 💡 The Concept
We create the *repository* (the vault) before we create the *contents* (the app code) for the same reason you'd get a safe deposit box before depositing anything valuable into it — the container should exist and be access-controlled first.

We set it to **private** initially and deliberately choose to add security settings (branch protection, required reviews) starting in Part 5 — but reserving the name and access control now avoids scrambling later.

### 🛠️ The Implementation

```bash
# Create a new private repository on GitHub under your account, and clone it locally in one step
gh repo create securetrade --private --clone \
  --description "SecureTrade: a Next.js trading SaaS built across the 'Secure Software Engineering from Zero to Prod' series"

cd securetrade

# Add a starter README so the repo isn't literally empty
cat > README.md << 'EOF'
# SecureTrade

A simplified SGX-style trading SaaS, built as the running example for the
"Secure Software Engineering from Zero to Prod" tutorial series.

## Series Progress
- [x] Part 0 — Environment setup
- [ ] Part 1 — Threat Model First
- [ ] Part 2 — Secure Design
- [ ] Part 3 — Secure Coding
- [ ] Part 4 — Dependencies & Supply Chain Security
- [ ] Part 5 — Testing & CI/CD Security
- [ ] Part 6 — Secure Deployment & Cloud Config
- [ ] Part 7 — Detection, Response & Incident Handling
- [ ] Part 8 — Maintenance, Sunset & Security Culture
EOF

git add -A
git commit -m "chore: initialize securetrade repository"
git push
```

### ✅ The Verification
```bash
gh repo view securetrade --web
```
This opens the repository in your browser — confirm you see the README rendered with the checklist above, and that the repo visibility badge reads **Private**.

---

## ✅ Part 0 Completion Checklist

Before moving to Part 1, confirm all of these are true:

- [ ] `node -v` and `npm -v` both return version numbers
- [ ] `git config --global --list` shows your correct name and email
- [ ] `gh auth status` shows you logged in
- [ ] VS Code opens with all 8 recommended extensions installed
- [ ] You can log into both the Supabase and Vercel dashboards
- [ ] `gh repo view securetrade --web` opens your new private repo with the README visible

If every box is checked, your crew's toolbox is fully packed. **Part 1** picks up by scaffolding the actual Next.js app *inside* this `securetrade` repository and beginning the threat model.

---

## 📚 Reference Section: Glossary of Terms Used Throughout This Series

Use this as a lookup, not required reading — every term below will also be explained inline the first time it appears in context.

| Term | Plain-English Definition |
|---|---|
| **STRIDE** | A checklist of 6 attacker goals (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege) used to brainstorm threats systematically. Covered in depth in Part 1. |
| **DREAD** | A scoring method (Damage, Reproducibility, Exploitability, Affected users, Discoverability) used to rank how serious each threat found via STRIDE actually is. Covered in Part 1. |
| **RBAC** | Role-Based Access Control — restricting what a user can do based on their assigned role (e.g., Admin vs. User vs. Auditor), rather than checking each user individually. Covered in Part 2. |
| **PDPA** | Singapore's Personal Data Protection Act — the law governing how personal data must be collected, used, and protected. Referenced in Parts 1 and 7. |
| **MAS TRM** | Monetary Authority of Singapore's Technology Risk Management Guidelines — expectations for how financial-adjacent systems in Singapore manage technology risk. Referenced in Parts 1 and 7. |
| **OWASP ASVS** | The Application Security Verification Standard — a structured checklist of security requirements at increasing rigor levels (L1/L2/L3). We target L2 in this series. Covered in Part 1. |
| **OWASP Top 10** | The 10 most critical, most common web application security risks, as published and periodically updated by the OWASP Foundation. Addressed throughout Part 3. |
| **SAST** | Static Application Security Testing — scanning your *source code* for vulnerabilities without running it. Covered in Parts 3 and 5. |
| **DAST** | Dynamic Application Security Testing — scanning your *running* application by actually attacking it, like OWASP ZAP does. Covered in Part 5. |
| **SCA** | Software Composition Analysis — scanning your *dependencies* (npm packages) for known vulnerabilities. Covered in Part 4. |
| **SBOM** | Software Bill of Materials — a complete, structured list of every dependency (and sub-dependency) in your app, like an ingredients label. Covered in Part 4. |
| **CSP** | Content Security Policy — an HTTP header telling the browser exactly which sources of scripts/styles/images are allowed to load, blocking many injection attacks. Covered in Part 6. |
| **HSTS** | HTTP Strict Transport Security — an HTTP header forcing browsers to only ever connect over HTTPS, never plain HTTP. Covered in Part 6. |
| **WAF** | Web Application Firewall — a layer that inspects incoming HTTP traffic and blocks known attack patterns before they reach your app. Covered in Part 6. |
| **IR (Incident Response)** | The structured process a team follows when a security incident is suspected or confirmed: Detect → Contain → Eradicate → Recover → Lessons Learned. Covered in Part 7. |
| **TTX (Tabletop Exercise)** | A simulated incident walkthrough done as a discussion (no real systems touched) to rehearse the IR process. Covered in Part 7. |
| **Zero Trust** | A design philosophy where no request is automatically trusted just because it came from "inside" the network — every request is verified. Covered in Part 2. |
| **Idempotency** | A property of an API operation where making the same request multiple times has the same effect as making it once — critical for things like "submit order" buttons that might get double-clicked. Covered in Part 2. |

---

**Next up: Part 1 — Threat Model First**, where we scaffold the actual `SecureTrade` Next.js app inside this repo and produce our first real security artifact: `THREAT-MODEL.md`.
