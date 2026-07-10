# Part 2: The Developer Environment

## 2.1 Concept: Why Terminal-First?

GUIs hide what's happening. The terminal shows exactly what command ran and what it returned — critical when a deployment fails and you need to know *precisely* what broke. Professional developers live in three tools daily: an editor, a terminal, and Git. This part sets all three up properly, once, so every later Part just works.

## 2.2 VS Code Setup

Install VS Code, then install these extensions (Extensions panel, `Ctrl+Shift+X` / `Cmd+Shift+X`):

- **ESLint** — surfaces lint errors inline
- **Prettier - Code formatter** — auto-formats on save
- **Tailwind CSS IntelliSense** — autocomplete for utility classes (used from Part 7 onward)
- **GitLens** — inline Git blame/history

Recommended `settings.json` (Command Palette -> "Preferences: Open User Settings (JSON)"):

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.tabSize": 2,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "files.autoSave": "onFocusChange"
}
```

## 2.3 Terminal Mastery: The Commands You'll Actually Use

You do not need to memorize hundreds of commands. You need fluency in about 20:

```bash
# Navigation
pwd                     # print working directory — "where am I?"
ls -la                  # list all files, including hidden, with details
cd my-folder            # change directory
cd ..                   # go up one level
cd ~                    # go to home directory

# Files & folders
mkdir devboard          # create a directory
touch file.txt          # create an empty file
rm file.txt             # delete a file
rm -rf my-folder        # delete a folder and everything in it (careful!)
mv old.txt new.txt      # rename/move a file
cp file.txt copy.txt    # copy a file

# Inspecting
cat file.txt            # print a file's contents
which node              # show where a command is installed
node -v                 # check Node.js version
npm -v                  # check npm version

# Running things
npm install             # install dependencies from package.json
npm run dev             # run the "dev" script defined in package.json
npx create-next-app@latest   # run a package without installing it globally
```

**Habit to build now:** before running any command you don't fully recognize (especially from a tutorial online), read it left to right and ask "what does each word do?" This is how you avoid pasting something destructive.

## 2.4 Installing Node.js

Next.js 16 requires **Node.js 20.9+ or 22 LTS** (Node 18 is end-of-life and unsupported). Use a version manager rather than a single global install, so you can switch versions per project:

```bash
# macOS/Linux — install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# then, in a new terminal:
nvm install 22
nvm use 22
node -v   # v22.x.x
```

On Windows, use `nvm-windows` or install Node 22 LTS directly from nodejs.org.

## 2.5 Git: The Version Control Mental Model

Git tracks *snapshots* of your project over time. Three areas matter:

```
Working Directory  --(git add)-->  Staging Area  --(git commit)-->  Repository (history)
   (your edits)                    (what will be                   (permanent snapshot)
                                     in the next commit)
```

First-time global setup (once per machine):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

Core daily workflow:

```bash
git init                        # start tracking a new project
git status                      # what's changed?
git add .                       # stage all changes
git commit -m "Add DevBoard skeleton"   # snapshot with a message
git log --oneline                # view history compactly
```

Working with GitHub (remote repository):

```bash
git remote add origin https://github.com/yourname/devboard.git
git branch -M main
git push -u origin main          # first push
git push                         # subsequent pushes
```

Branching (used properly, this is how you avoid breaking `main`):

```bash
git checkout -b feature/add-card-form   # create + switch to new branch
# ... make changes, commit ...
git push -u origin feature/add-card-form
# open a Pull Request on GitHub, review, then merge into main
```

**Why this matters for deployment:** Vercel's entire deployment pipeline (Part 8, Appendix C) is triggered by Git pushes. Every `git push` to `main` becomes a production deploy; every push to another branch becomes a preview deploy with its own URL. Understanding Git isn't optional groundwork — it *is* the deployment mechanism.

## 2.6 GitHub: Creating Your First Repository

1. Go to github.com -> **New repository**.
2. Name it `devboard`, leave it public, **do not** initialize with a README (you'll push an existing local project).
3. Copy the commands GitHub shows you under "...or push an existing repository from the command line" — this is exactly the `git remote add` / `git push` sequence from 2.5.

## 2.7 Implementation: Scaffolding the DevBoard Project

This is the project skeleton every later Part builds on.

```bash
npx create-next-app@latest devboard
```

You'll be prompted — answer as follows (these choices matter for later Parts):

```
Would you like to use TypeScript?     Yes
Would you like to use ESLint?         Yes
Would you like to use Tailwind CSS?   Yes
Would you like to use `src/` directory?  No
Would you like to use App Router?     Yes
Would you like to customize the default import alias (@/*)?  Yes
```

Then:

```bash
cd devboard
git init                     # if not already initialized by create-next-app
git add .
git commit -m "Initial commit: DevBoard skeleton via create-next-app"
```

Create the GitHub repo (2.6), then:

```bash
git remote add origin https://github.com/yourname/devboard.git
git branch -M main
git push -u origin main
```

Run it locally:

```bash
npm run dev
```

Visit `http://localhost:3000` — you should see the default Next.js welcome page. This confirms your entire toolchain (Node, npm, Next.js, Git, GitHub) works end-to-end before you write a single feature.

## 2.8 The `.gitignore` You Should Never Delete

`create-next-app` generates this for you, but understand *why* each line matters:

```gitignore
# dependencies
/node_modules

# next.js build output
/.next/
/out/

# environment variables — NEVER commit secrets
.env*.local
.env

# misc
.DS_Store
*.pem
```

`node_modules` is regenerated from `package.json` via `npm install` — committing it bloats your repo for no benefit. `.env*` files hold secrets (API keys, database URLs) — committing these to a public GitHub repo is one of the most common real-world security incidents. You'll revisit this exact line in Part 8 when adding a database connection string.

## Exercise Challenge

1. Create a new branch called `feature/readme-update`.
2. Edit `README.md` to add a one-paragraph description of DevBoard.
3. Commit the change, push the branch, and (if you have a GitHub account handy) open a Pull Request into `main`.
4. Run `git log --oneline --graph --all` and explain what you see.

## Solution & Explanation

```bash
git checkout -b feature/readme-update
# edit README.md in VS Code
git add README.md
git commit -m "docs: describe DevBoard project"
git push -u origin feature/readme-update
```

The `git log --oneline --graph --all` output shows your `main` branch and `feature/readme-update` branch diverging from a shared commit — visually, this is a branch pattern you'll use constantly once collaborating with others, and it's exactly what Vercel's preview deployments key off of.

---
*Next: `Roadmap Tutorial - Part 3: The Semantic Web (HTML/CSS)`*

