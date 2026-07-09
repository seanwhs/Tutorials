# **Part 2: Development Environment Setup**:

---

# Part 2: Development Environment Setup

Goal: get every tool installed and every free account created, so Parts 3+ are pure building with no interruptions.

## 1. Install Node.js 20.9+ or 22 LTS

**Next.js 16 requires Node.js 20.9+ or Node 22 LTS.** Node 18 is EOL and unsupported.

**Mac/Linux (nvm):**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# restart terminal, then:
nvm install 22
nvm use 22
```

**Windows (nvm-windows):** install from https://github.com/coreybutler/nvm-windows/releases, then `nvm install 22` / `nvm use 22`

Verify:
```bash
node -v   # must be v20.9.0+ or v22.x.x
npm -v
```

(`nvm use 22` only affects your current terminal session — other projects on older Node versions are unaffected.)

## 2. Install pnpm
```bash
npm install -g pnpm
pnpm -v
```

## 3. Install Git + GitHub account
Install Git, create a free GitHub account (needed for Part 23 deployment).
```bash
git --version
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## 4. Code editor
**VS Code** recommended, with extensions: "ES7+ React/Redux snippets", "Tailwind CSS IntelliSense" (recent version — needs Tailwind v4 CSS-first syntax support), "Prettier".

## 5. Create free accounts now

- **Clerk** (clerk.com) — create application "EventHub", Email (+ optionally Google) sign-in. Free tier: 10,000 MAU.
- **Neon** (neon.tech) — create project "eventhub", note the connection string. Free tier: 0.5GB storage.
- **Inngest** (inngest.com) — sign up, create app (fully configured in Part 15). Free tier: 50,000 function runs/month.
- **Resend** (resend.com) — create API key "eventhub-dev". Free tier: 100 emails/day, 3,000/month.
- **Vercel** (vercel.com) — sign up via GitHub. Fully supports Next.js 16 + Turbopack on free Hobby tier.

## 6. Project folder
```bash
mkdir ~/code
cd ~/code
```

## Checkpoint
- [ ] `node -v` shows v20.9.0+ or v22.x.x
- [ ] `pnpm -v` works
- [ ] `git --version` works
- [ ] Accounts created: Clerk, Neon, Inngest, Resend, Vercel, GitHub
- [ ] VS Code installed

**Next: Part 3 — Next.js 16 Project Setup and Structure**
