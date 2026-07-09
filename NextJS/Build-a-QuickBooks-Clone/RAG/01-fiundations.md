```markdown
# QB Clone: Foundations - Environment, Next.js, Toolbox Concepts

File 2 of 8. Covers environment setup, creating the Next.js 16 project, and understanding the full toolbox conceptually before installing anything else. See file 00 Master Overview and Architecture for the big picture this fits into.

**Version note:** this build targets Next.js 16 (App Router, React 19, Turbopack as the default bundler), requiring Node.js 20.9+ (Node 22 LTS recommended).

---

## PART A: Setting Up Your Computer

### Install Node.js (20.9+ or 22 LTS)

1. Go to nodejs.org, download the LTS version (22.x at time of writing), run the installer accepting defaults, restart if prompted.
2. Verify in a terminal:
```
node -v
```
Expected: v22.11.0 or similar. Anything v20.9.0 or higher works; v18 or lower will not run Next.js 16.
```
npm -v
```
Expected: a version number, e.g. 10.9.0.

### Install VS Code

Go to code.visualstudio.com, download, install, open once.

### Install Git

1. Go to git-scm.com/downloads, download and install (Windows: accept all defaults).
2. Verify: `git --version` -> expected `git version 2.43.0` or similar.
3. One-time setup:
```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```
No output means success.

### Create a GitHub account

Go to github.com, sign up, verify email.

### Terminal basics

`cd folder-name` moves into a folder. `cd ..` moves up one folder. `ls` (Mac) / `dir` (Windows) lists files/folders here. `mkdir folder-name` creates a new folder. `pwd` prints current location.

Try it:

**Mac:**
```
cd ~/Desktop
mkdir qb-clone-course
cd qb-clone-course
pwd
```
**Windows:**
```
cd %USERPROFILE%\Desktop
mkdir qb-clone-course
cd qb-clone-course
cd
```

### Install VS Code extensions

Extensions icon (4 squares, left sidebar) -> install: ESLint, Prettier - Code formatter, Tailwind CSS IntelliSense.

### Checkpoint A
- node -v prints v20.9 or higher (v22.x recommended)
- npm -v and git --version print version numbers
- VS Code opens
- GitHub account created
- qb-clone-course folder exists

### Troubleshooting A

**"command not found" / "'node' is not recognized"** - Close ALL terminal/VS Code windows, reopen fresh, try again. If still failing, reinstall from nodejs.org and restart your computer.

**node -v prints v18 or lower** - Too old for Next.js 16. Reinstall the current LTS from nodejs.org (or `nvm install --lts && nvm use --lts` if you use a version manager), then close/reopen your terminal.

**Windows: "running scripts is disabled on this system"** - Open PowerShell as Administrator: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`, type Y, Enter.

**git config produces no output** - Normal, it succeeds silently. Verify with `git config --global user.name`.

**"code ." not recognized** - Open VS Code manually, Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows), type "Shell Command: Install 'code' command in PATH", select it, restart terminal.

---

## PART B: Your First Next.js Project

### What is a framework

Next.js is built on React and provides file-based routing, Server Components, Server Actions, API routes, and built-in optimization, so you don't build all the plumbing of a website by hand. Next.js 16 defaults to Turbopack (a fast Rust-based bundler) and requires dynamic request data (`params`, `searchParams`, `cookies()`, `headers()`) to be read asynchronously.

### Create the project

```
cd ~/Desktop/qb-clone-course
```
(Windows: `cd %USERPROFILE%\Desktop\qb-clone-course`)

```
npx create-next-app@latest
```

Answer each prompt:
```
What is your project named? qb-clone
Would you like to use TypeScript? Yes
Would you like to use ESLint? Yes
Would you like to use Tailwind CSS? Yes
Would you like your code inside a src/ directory? Yes
Would you like to use App Router? Yes
Would you like to use Turbopack for next dev? Yes
Would you like to customize the import alias? No
```

This scaffolds Next.js 16 with React 19, Turbopack, and Tailwind CSS v4 (CSS-first configuration - no `tailwind.config.js` file; just an `@import "tailwindcss";` line at the top of `globals.css`).

### Open and run

```
cd qb-clone
code .
```
In VS Code's terminal (Terminal menu -> New Terminal):
```
npm run dev
```
Expected:
```
▲ Next.js 16.x.x
- Local: http://localhost:3000
✓ Ready in 900ms
```
Open http://localhost:3000 - default Next.js welcome page. Leave this terminal running; open a second tab for other commands.

### Project structure

```
qb-clone/
- src/app/page.tsx (homepage)
- src/app/layout.tsx (wraps every page)
- src/app/globals.css
- public/
- package.json
- next.config.ts
- tsconfig.json
```

### File-based routing - your first new page

Create folder `src/app/about/`, inside it `page.tsx`:
```tsx
export default function AboutPage() {
  return (
    <div>
      <h1>About this app</h1>
      <p>This is a QuickBooks clone I'm building to learn Next.js.</p>
    </div>
  );
}
```
Save, visit http://localhost:3000/about - appears instantly, no restart needed (Turbopack recompiles almost instantly).

### Edit the homepage

Open `src/app/page.tsx`, replace entirely:
```tsx
export default function Home() {
  return (
    <main style={{ padding: "2rem" }}>
      <h1>QB Clone</h1>
      <p>Welcome to your QuickBooks clone project.</p>
    </main>
  );
}
```

### First Git commit

```
git status
git add .
git commit -m "Initial Next.js project setup with about page"
```

### Checkpoint B
- npm run dev runs with no errors, localhost:3000 loads
- localhost:3000/about shows the custom page
- Understand: folder + page.tsx inside src/app/ = a URL route
- git commit succeeded

### Troubleshooting B

**npx create-next-app@latest hangs/fails to download** - Check internet; corporate/school networks sometimes block npm's registry, try a different network.

**"npm error" in red after prompts** - Run `npm cache clean --force`, try again.

**npm run dev says "Cannot find module"** - You're not inside the qb-clone folder. Run `pwd`/`cd` to check. If still failing, delete `node_modules` and `package-lock.json`, run `npm install` again.

**"This site can't be reached" at localhost:3000** - Check the terminal running `npm run dev` for an actual error instead of "Ready"; scroll up to find it.

**Port 3000 already in use** - Next.js usually offers 3001 automatically - check terminal output for the real URL. To free port 3000 on Mac/Linux: `lsof -ti:3000 | xargs kill -9`. Windows: `netstat -ano | findstr :3000` then `taskkill /PID <number> /F`.

**Editing page.tsx doesn't update the browser** - Confirm the file was saved (Cmd+S/Ctrl+S). If still stuck, stop (Ctrl+C) and rerun `npm run dev`.

**git commit says "Please tell me who you are"** - You skipped the Part A git config step - run those two commands, then commit again.

**create-next-app or npm run dev complains about your Node.js version** - Next.js 16 requires Node 20.9+. Run `node -v`; if it's below that, revisit Part A and reinstall Node from nodejs.org, then fully close and reopen your terminal.

---

## PART C: Understanding Our Toolbox (conceptual, no code)

### The problem

The app can show pages, but a real accounting app also needs to: know who's using it, support multiple businesses each seeing only their own data, remember data permanently, safely query that data, and do things later or on a schedule.

### Clerk - authentication and multi-tenancy

Hosted service handling sign-up, sign-in, and sessions - you never write password-handling code. Its Organizations feature lets a user belong to multiple organizations and switch between them. Mapping used throughout this build: 1 Clerk Organization = 1 Company File. Route protection is wired through `src/proxy.ts`, Next.js 16's renamed `middleware.ts` file (same underlying Clerk API, new file name/location convention).

### Neon / Postgres - where data lives

Postgres is a mature, open-source relational database: tables that reference each other. Neon runs Postgres for you in the cloud, free tier with no inactivity expiry, plus "branching" (copying your whole database structure to experiment safely).

### Drizzle - talking to the database safely

An ORM: define tables as TypeScript, query with type-checked function calls instead of raw SQL text - typos in column names get caught before you run the code. Also provides migrations - a controlled, tracked way to evolve your database structure.

### Inngest - background and scheduled jobs

Write normal functions that run in response to events ("an invoice was created") or on a schedule ("every night at 2am"), with automatic retries if something fails, without blocking the user's page load.

### How it all connects - one example

A user (Clerk) creates an invoice in Joe's Landscaping (a Clerk Organization). Server code inserts it into Neon via Drizzle, tagged with that org's ID. Instead of generating a PDF and emailing it inline, the code tells Inngest "an invoice was created" - Inngest handles the email in the background, and later checks on its own schedule if it becomes overdue.

### Why this build order

"Boring plumbing" (auth, database) comes before real features, because features need that foundation first.

### Checkpoint C (conceptual, no code)
- What does Clerk do, and what does an "Organization" represent in this app?
- Difference between Postgres and Neon?
- Why Drizzle instead of raw SQL text?
- One example of something Inngest is good for that a normal page request is not
- Describe the invoice example above in your own words

### Troubleshooting C

No code was written in this part, so nothing to break. If any concept still feels unclear, re-read the relevant section before moving on - files covering auth (file 02) and the journal engine (file 03) build directly on these ideas without re-explaining them from scratch.

---
