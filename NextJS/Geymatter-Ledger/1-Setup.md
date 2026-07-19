# Part 1: Setup, First Project & Toolbox

Before we write a single line of application code, we need to set up the workshop. A carpenter doesn't start cutting wood before checking their saw is sharp and their workbench is stable — we're doing the same thing here: installing the right tools, verifying each one works, then scaffolding the empty project we'll spend the next thirteen parts filling in.

## Step 1.1 — Installing Node.js

### The Target
Get Node.js 20.9+ (v22 LTS recommended) installed and verified on your machine.

### The Concept
A web browser can run JavaScript, but your computer's terminal cannot — not without help. **Node.js** is a program that lets JavaScript run *outside* the browser, directly on your computer. Think of it as a translator standing between you and your operating system: you write instructions in JavaScript (or TypeScript, JavaScript's stricter cousin), and Node translates them into things your computer can actually execute.

Next.js 16 specifically requires **Node 20.9 or higher**. Node 18 has reached "end-of-life," meaning it no longer gets security patches, and Next.js 16 will flatly refuse to start on it. We're using the **v22 LTS** ("Long-Term Support" — the most stable, longest-maintained release line) to avoid version headaches for the rest of the course.

### The Implementation

1. Go to **[nodejs.org](https://nodejs.org)**.
2. Download the button labeled **LTS** (as of this writing, Node 22.x).
3. Run the installer for your operating system, accepting all default options.

### The Verification

Open a terminal:
- **Windows:** search for "Terminal" or "PowerShell" in the Start menu.
- **Mac:** open "Terminal" from Spotlight (Cmd+Space, type "Terminal").
- **Linux:** you already know how to do this.

Type the following and press Enter:

```bash
node -v
```

Expected output:

```
v22.11.0
```

Any `v20.9.x` or higher, or any `v22.x`, is correct. If you see `v18.x.x` or lower, or a "command not found" error, revisit the install step before continuing.

Also check npm (Node's package manager, installed automatically alongside Node):

```bash
npm -v
```

Expected: a version number like `10.9.0`. If both commands print version numbers, Node.js is correctly installed.

---

## Step 1.2 — Installing Git

### The Target
Install Git, the tool that tracks every change you make to your project's code over time.

### The Concept
Imagine writing a novel in a word processor, but every single time you save, it also silently keeps the *entire previous draft* — so you can always rewind to any earlier version, compare two drafts side by side, or merge changes from two different people's copies. That's what **Git** does for code. It's called "version control." We'll use it in this part to initialize our project, and again in Part 13 to push our code to GitHub for deployment.

### The Implementation

1. Go to **[git-scm.com/downloads](https://git-scm.com/downloads)**.
2. Download the installer for your OS.
3. Run it, accepting the default options (on Windows, the defaults are fine for every prompt, including the default text editor choice).

### The Verification

```bash
git --version
```

Expected output (version number may differ slightly):

```
git version 2.47.0
```

Any recent version confirms Git is installed correctly.

One more one-time setup step — tell Git who you are, since every saved change gets labeled with an author:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

These commands produce no output on success — that's expected and correct.

---

## Step 1.3 — Installing VS Code

### The Target
Install Visual Studio Code (VS Code), the text editor we'll use to write every file in this course.

### The Concept
You could write code in Notepad, technically — the same way you could cut a steak with a spoon. It would work, painfully. **VS Code** is a free, purpose-built code editor: it understands the *structure* of the languages we're using, catches typos before you even run the code, and lets you open a terminal right inside the same window.

### The Implementation

1. Go to **[code.visualstudio.com](https://code.visualstudio.com)**.
2. Download and run the installer for your OS.
3. Accept the defaults. On Windows, make sure **"Add to PATH"** is checked (checked by default) — this lets you type `code .` in a terminal to open VS Code in the current folder.

### The Verification

Open a terminal, navigate to any folder (e.g., your Desktop), and run:

```bash
code .
```

VS Code should open, showing that folder in its sidebar. If it opens, you're set.

---

## Step 1.4 — A No-Code Tour of the Toolbox

Before we scaffold anything, let's slow down and understand — in plain English, zero code — what each major piece of our stack actually *does*, and critically, *why we need it at all*. This matters because Parts 4 through 7 build directly on these ideas without re-explaining them from scratch. If you skim this now, come back once code starts appearing.

### Next.js 16 — the app framework

**The analogy:** Imagine building a restaurant. You need a dining room (what customers see and interact with) and a kitchen (where food actually gets prepared, unseen by customers). Traditionally, web developers built these as two entirely separate projects — a frontend app and a backend API — that had to be deployed separately and configured to talk to each other.

**Next.js** lets you build both in a *single* project. A file can be a webpage (dining room) or it can be server-only logic (kitchen) that never gets sent to the browser — and they live side by side, able to call each other directly. This eliminates an entire category of configuration headaches for a beginner.

Next.js 16 specifically renames a special file called `middleware.ts` (which used to intercept every incoming request, e.g., "is this user logged in?") to `src/proxy.ts`. We'll create this exact file in Part 2 — which is exactly why getting our project onto a `src/` layout in this part matters.

### Tailwind CSS — styling

**The analogy:** Imagine decorating a room. One approach: write a long separate instruction document ("the couch should be blue, the wall should be beige") that someone else has to go read and apply elsewhere. Another approach: attach small labeled tags directly onto each piece of furniture — "blue," "large," "against-the-wall" — so anyone looking at the furniture itself immediately sees how it's supposed to look.

**Tailwind** is the second approach for web pages. Instead of separate `.css` files with rules like `.button { color: blue; }`, you write short utility labels ("classes") directly on your HTML elements, like `class="bg-blue-500 text-white rounded"`. It feels unusual for the first hour and then becomes extremely fast to work with.

### Clerk — authentication & organizations

**The analogy:** Every apartment building has a front desk that checks IDs before letting anyone upstairs. You could build your own front desk — hire a guard, write a procedures manual, install cameras — or you could contract a professional security company that already does this at scale, correctly, with all the edge cases handled (forgotten passwords, stolen sessions, etc.).

**Clerk** is that professional security company, for your web app. It handles account sign-up, sign-in, password resets, and session security — things that are deceptively dangerous to build yourself as a beginner. It also has a concept called **Organizations**, which we'll use so each *company* using Greymatter Ledger (not each individual person) has its own completely separate set of books — like separate floors in a building, where a keycard for Floor 3 doesn't open any door on Floor 5.

### Neon — the database

**The analogy:** Your app needs a permanent filing cabinet — somewhere that remembers every customer, invoice, and journal entry even after you turn your computer off. That filing cabinet is a **database**. Specifically, we use **Postgres**, one of the most trusted, battle-tested database systems in the world.

**Neon** is a company that runs Postgres *for* you, in the cloud, so you don't have to install, configure, and maintain a database server yourself. You get a free filing cabinet, hosted on the internet, reachable from your app via a "connection string" — a single line of text that's essentially the address and keycard for your filing cabinet, all in one.

### Drizzle — the database toolkit

**The analogy:** You could talk to your filing cabinet in its native, very literal language (raw SQL: `SELECT * FROM invoices WHERE...`). It works, but it's easy to make a silent typo that causes real damage — imagine mistyping a drawer label and accidentally deleting the wrong folder.

**Drizzle** is a translator and safety-checker that sits between your TypeScript code and the raw database. You describe your filing cabinet's drawers (tables) using ordinary code, and Drizzle both (a) creates and updates the real drawers to match your description, and (b) checks your queries *before* they run, catching mistakes like "you're trying to read a field that doesn't exist" as an error in your editor, not a crash in production.

### Inngest — background & scheduled jobs

**The analogy:** Imagine a restaurant host who, instead of making every customer wait at the counter while their order is prepared, takes the order, hands the customer a buzzer, and lets them sit down — the kitchen handles it in the background and buzzes them when it's ready. Some tasks (sending an email, generating a recurring invoice at 3 AM) don't need to happen *immediately* in front of the user, and shouldn't block them from continuing to use the app.

**Inngest** is a service for exactly this: "run this function later," "run this function in the background right now," or "run this function every day at a specific time," with automatic retries if something fails. We introduce it deliberately late in the course (Part 11), because Inngest is most useful once you actually have real actions worth automating — sending an invoice email only makes sense once invoices exist.

---

## Step 1.5 — Scaffolding the Next.js Project (Recommended Defaults)

### The Target
Use `create-next-app`'s fast "recommended defaults" path to instantly spin up TypeScript, ESLint, Tailwind, and the App Router — then perform one small, fully-understood manual step to move the project onto the `src/` layout this course relies on.

### The Concept
Think of ordering the "combo meal" at a fast food counter — you say one thing, and you get fries, a drink, and a burger bundled together automatically, without listing each item individually. That's what the recommended-defaults option does: one confirmation, and TypeScript, ESLint, Tailwind, and the App Router all get bundled in instantly.

The one thing this particular combo meal doesn't include is a side we specifically want: the `src/` directory. So we're going to accept the combo, then add that one side ourselves. This is a completely normal, safe, and common thing to do to a freshly scaffolded project — we're just reorganizing where files live, not changing what they do.

### The Implementation

Open your terminal. Navigate to wherever you'd like your projects to live:

```bash
cd Desktop
```

Run the scaffolding command:

```bash
npx create-next-app@latest greymatter-ledger
```

You'll be prompted with something like:

```
Would you like to use the recommended defaults?
❯ Yes, use recommended defaults
  No, customize
```

Select **"Yes, use recommended defaults"** and press Enter. The tool will instantly scaffold the project with TypeScript, ESLint, Tailwind, and the App Router — no further questions asked.

Once it finishes, move into the project folder and open it in VS Code:

```bash
cd greymatter-ledger
code .
```

**Now, confirm what we actually got.** Look at the sidebar in VS Code. With recommended defaults, you'll typically see:

```
greymatter-ledger/
├── node_modules/
├── app/                  ← sitting at the ROOT, not inside src/
│   ├── favicon.ico
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── public/
├── .gitignore
├── next.config.ts
├── package.json
├── tsconfig.json
└── eslint.config.mjs
```

Notice `app/` is at the project root. We're going to move it into a new `src/` folder.

**Why does this matter enough to fix by hand?** Next.js looks for `app/` (or `pages/`) in one of exactly two places: the project root, or inside a folder named `src/`. It auto-detects whichever one exists. Nothing breaks by moving it — Next.js will simply start looking in the new location, correctly, the moment it exists there instead. We want it in `src/` for two concrete reasons used throughout this course: (1) it keeps every piece of *our* code cleanly separated from root-level config files like `next.config.ts` and `package.json`, and (2) Next.js 16's special `proxy.ts` file (Part 2) is placed at `src/proxy.ts`, so our folder structure needs to already match.

**Step A — create the `src` folder and move `app` into it.**

In your terminal, still inside `greymatter-ledger/`:

**Mac/Linux:**
```bash
mkdir src
mv app src/app
```

**Windows (PowerShell):**
```powershell
mkdir src
move app src\app
```

**Step B — verify no other config references the old path.**

Open `tsconfig.json` and confirm the `paths` section looks like this (it should already be correct out of the box, since `@/*` is a generic alias that works regardless of whether `app` lives at the root or inside `src`):

**`tsconfig.json`** (relevant excerpt — leave the rest of the file untouched)
```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

If instead you see `"@/*": ["./*"]` (pointing at the root instead of `src`), change it to `"./src/*"` exactly as shown above — this tells TypeScript that `@/` now means "inside `src/`."

### The Verification

**1. Inspect the folder structure.** Confirm in VS Code's sidebar that you now see:

```
greymatter-ledger/
├── node_modules/
├── public/
├── src/
│   └── app/
│       ├── favicon.ico
│       ├── globals.css
│       ├── layout.tsx
│       └── page.tsx
├── .gitignore
├── next.config.ts
├── package.json
├── tsconfig.json
└── eslint.config.mjs
```

The critical check: `app/` must be nested *inside* `src/` — the path must read `src/app/page.tsx`.

**2. Run the development server.** In the terminal, inside `greymatter-ledger/`:

```bash
npm run dev
```

Expected output:

```
▲ Next.js 16.0.0 (Turbopack)
- Local:        http://localhost:3000
- Ready in 800ms
```

If you instead see an error like `Couldn't find any 'pages' or 'app' directory`, the move didn't complete correctly — re-check Step A, confirming `app` is a direct child of `src`, not nested one level too deep (e.g., not `src/app/app`).

**3. Open the app in a browser.** Visit `http://localhost:3000`. You should see the default Next.js welcome page — a logo, some links, and instructions. This confirms your entire toolchain (Node, npm, Next.js, Tailwind, TypeScript, and the `src/` layout) is correctly wired together and running.

Leave this terminal running — it's your live development server, and it automatically reloads the page whenever you save a file change. Open a **second terminal tab** (don't close this one) for the remaining commands in this course.

---

## Step 1.6 — First Git Commit

### The Target
Turn this folder into a Git repository and save our very first "snapshot" of the project.

### The Concept
Recall the novel-drafting analogy from Step 1.2 — Git keeps a history of drafts. Right now we have "draft one": a bare, freshly-scaffolded project, now correctly reorganized into the `src/` structure. We want to save this exact state as a checkpoint before we start modifying anything, so we always have a known-good point to compare against or return to.

### The Implementation

`create-next-app` already initialized a Git repository for you and created a `.gitignore` file (a list of things Git should *never* track — like the giant, disposable `node_modules` folder). Let's verify and make our first commit.

In your terminal, inside `greymatter-ledger/`:

```bash
git status
```

You should see a list of changed/untracked files, reflecting both the original scaffold and our `src/` reorganization.

Now stage and commit everything:

```bash
git add .
git commit -m "Initial commit: scaffold Next.js project, reorganized into src directory"
```

### The Verification

```bash
git log
```

Expected output: one commit listed, with the message `"Initial commit: scaffold Next.js project, reorganized into src directory"`, your name, and a timestamp. Press `q` to exit the log view if it opens in a pager.

This confirms version control is active and your first checkpoint is safely saved.

---

## ✅ Checkpoint — Part 1

At this point, you should have:

- [x] Node.js v20.9+ (ideally v22 LTS) installed, verified via `node -v`
- [x] Git installed and configured with your name/email
- [x] VS Code installed, launchable via `code .`
- [x] A working mental model (no code yet) of what Next.js, Tailwind, Clerk, Neon, Drizzle, and Inngest each do and *why* they're in this stack
- [x] A Next.js project named `greymatter-ledger`, scaffolded via recommended defaults, **manually reorganized so `app/` lives inside `src/`**, confirmed running locally at `http://localhost:3000`
- [x] `tsconfig.json`'s `@/*` alias confirmed pointing at `./src/*`
- [x] One Git commit saved as your first checkpoint

---

## 🔧 Troubleshooting — Part 1

**"`npx create-next-app` fails immediately, or hangs forever."**
Check your internet connection — the command downloads the tool fresh each time by default. If it hangs on a corporate/school network, try a personal hotspot once to rule out a firewall blocking npm's registry.

**"After moving `app` into `src`, `npm run dev` says it can't find an app or pages directory."**

Check that the move actually landed one level deep and no deeper — run `ls src` (Mac/Linux) or `dir src` (Windows) and confirm it prints `app`, not `app/app` or an empty folder. A common mistake is running the move command twice, which nests it as `src/app/app`. If that happened, fix it with:

**Mac/Linux:**
```bash
mv src/app/app/* src/app/
rmdir src/app/app
```

**Windows (PowerShell):**
```powershell
move src\app\app\* src\app\
rmdir src\app\app
```

Then re-run `npm run dev`.

**"I still don't see a `src` folder after using the flags."**
If you used the recommended-defaults path, `src/` genuinely does not exist yet until you complete Step A yourself — that's expected and by design in this version of the walkthrough, not an error. Just complete the `mkdir src` / `mv app src/app` steps above.

**"`npm run dev` says 'command not found' or 'no such file'."**
You're likely not inside the `greymatter-ledger` folder. Run `pwd` (Mac/Linux) or check the current path in your PowerShell prompt (Windows) to confirm your location, then `cd greymatter-ledger` and try again.

**"The browser shows 'This site can't be reached' at localhost:3000."**
Check the terminal running `npm run dev` — if it shows an error instead of "Ready," the server never actually started. Copy the exact error text and re-check Step 1.5. A common cause is another program already using port 3000 — if so, Next.js will usually auto-suggest port 3001 instead; check the terminal output for the actual URL it printed.

**"TypeScript errors appear everywhere after moving the folder, like it can't find `@/` imports."**
This means `tsconfig.json`'s path alias wasn't updated. Reopen `tsconfig.json` and confirm the `paths` block reads exactly:
```json
"paths": {
  "@/*": ["./src/*"]
}
```
Save the file, then restart the dev server (`Ctrl+C` in the terminal, then `npm run dev` again) so TypeScript picks up the change.

**"`git commit` says 'Please tell me who you are'."**
You skipped the `git config --global user.name`/`user.email` commands in Step 1.2 — go back and run them, then retry the commit.
