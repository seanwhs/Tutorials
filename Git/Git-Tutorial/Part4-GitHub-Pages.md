Here's **Git Mastery - Part 4: Deployment 101 - GitHub Pages** in full:

---

## Part 4: Deployment 101 — GitHub Pages

**Series:** Mastering Version Control | **Prev:** Part 3 — The GitHub Workflow | **Next:** Part 5 — Time Travel & Recovery

---

### 1. Concept Explanation

#### 1.1 What GitHub Pages actually is

GitHub Pages is a **free static file host** built directly into every GitHub repository. "Static" is the key word: it serves HTML, CSS, JS, images, and other files exactly as they are — there is no server-side code execution (no Node.js, no databases, no API routes). It's perfect for: landing pages, documentation sites, portfolios, resumes, and any front-end project that doesn't require a backend.

Under the hood, GitHub Pages watches a specific **source** in your repo (a branch, and optionally a folder within it) and republishes its contents to a public URL every time that source updates:

```
https://<username>.github.io/<repository-name>/
```

(Or `https://<username>.github.io/` directly, if the repo is literally named `<username>.github.io` — the special "user site" case.)

#### 1.2 The two deployment sources: `gh-pages` branch vs. `docs/` folder vs. GitHub Actions

There are three common configurations:

| Strategy | How it works | Best for |
|---|---|---|
| **`/docs` folder on `main`** | Pages serves the `docs/` subfolder of your default branch | Simple sites where source *is* the output (plain HTML/CSS/JS) |
| **Dedicated `gh-pages` branch** | A separate branch holds only *built* output; source code lives on `main` | Projects with a build step (e.g. a static site generator) where you don't want build artifacts mixed into `main`'s history |
| **GitHub Actions workflow** | A CI job builds your project and deploys the output automatically on every push | Modern projects using frameworks (React, Vue, static exports) — most flexible and the current GitHub-recommended approach |

The philosophical point connecting this back to Part 1: **never commit build output to `main`.** If your site needs a build step, the *built* files belong on a separate branch (`gh-pages`) or are generated fresh by a CI workflow — keeping `main`'s history a clean record of source only.

#### 1.3 Why this matters for your career

Being able to say "I can take a static project from a Git repo to a live URL in under two minutes, for free, with zero server management" is a foundational deployment skill. It's also the natural stepping stone to understanding *why* Vercel exists (Part 6): GitHub Pages solves static hosting elegantly, but the moment you need server-side logic (API routes, databases, authentication, SSR), you need a platform that runs code — not just serves files.

---

### 2. Implementation — Step-by-Step Terminal Commands

#### 2.1 Method A — Simplest: `docs/` folder on `main` (no build step)

Best for plain HTML/CSS/JS projects.

```bash
mkdir gh-pages-demo && cd gh-pages-demo
git init

mkdir docs
cat > docs/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>My Live Site</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <h1>Deployed via GitHub Pages 🚀</h1>
</body>
</html>
EOF

cat > docs/styles.css << 'EOF'
body { font-family: system-ui, sans-serif; text-align: center; margin-top: 4rem; }
h1 { color: #2563eb; }
EOF

git add .
git commit -m "feat: initial static site in docs folder"

git remote add origin git@github.com:yourusername/gh-pages-demo.git
git push -u origin main
```

Now, on GitHub.com:
1. Go to your repo → **Settings** → **Pages** (left sidebar).
2. Under **Build and deployment** → **Source**: select **Deploy from a branch**.
3. **Branch**: `main`, folder: `/docs`. Click **Save**.
4. Wait ~1 minute, refresh — GitHub shows: "Your site is live at `https://yourusername.github.io/gh-pages-demo/`".

#### 2.2 Method B — Dedicated `gh-pages` branch (for projects with a build step)

Example: you have a source project on `main` that builds into a `dist/` folder.

```bash
# Assume you're on main with a normal source project, and running
# a build command produces ./dist
npm run build   # or whatever your build tool is

# Install the popular gh-pages npm package to automate branch publishing
npm install --save-dev gh-pages
```

Add a deploy script to `package.json`:

```json
{
  "scripts": {
    "build": "your-build-command",
    "deploy": "gh-pages -d dist"
  }
}
```

```bash
npm run build
npm run deploy
```

What this does under the hood: it takes the contents of `dist/`, commits them onto an orphan `gh-pages` branch (a branch with no shared history with `main` — appropriate, since build output isn't source), and force-pushes that branch to GitHub. Your `main` branch's history stays clean — it never sees a single build artifact.

Then on GitHub: **Settings → Pages → Source: Deploy from a branch → Branch: `gh-pages` → `/ (root)`**.

#### 2.3 Method C — GitHub Actions (modern, recommended for anything beyond trivial HTML)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

```bash
mkdir -p .github/workflows
# (paste the YAML above into .github/workflows/deploy.yml)
git add .github/workflows/deploy.yml
git commit -m "ci: add GitHub Actions workflow to deploy to Pages on push to main"
git push
```

On GitHub: **Settings → Pages → Source: GitHub Actions**. From now on, every push to `main` automatically rebuilds and redeploys your site — this is your first taste of CI/CD, expanded further in Part 6.

#### 2.4 Custom domain (optional, but common)

```bash
echo "www.yourdomain.com" > docs/CNAME    # or root, depending on method used
git add docs/CNAME
git commit -m "chore: add custom domain CNAME for GitHub Pages"
git push
```
Then add a `CNAME` record at your DNS provider pointing `www` to `yourusername.github.io`, and configure it in **Settings → Pages → Custom domain**.

---

### 3. Practice Exercise

**Step 1:** Create a new local repo `my-portfolio` with an `index.html` containing your name and a short bio, and a `styles.css`.

**Step 2:** Commit it with an atomic, well-messaged commit (callback to Part 1).

**Step 3:** Push it to a new GitHub repository.

**Step 4:** Configure GitHub Pages using **Method A** (`docs/` folder) — you'll need to move your files into a `docs/` subfolder first.

**Step 5:** Confirm the live URL loads correctly, then make one visible change (e.g. change the bio text), commit, push, and confirm the live site updates within a minute or two — this proves you understand that Pages redeploys automatically on every push to the configured source.

---

### 4. Solution & Explanation

```bash
mkdir my-portfolio && cd my-portfolio
git init
mkdir docs

cat > docs/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>My Portfolio</title><link rel="stylesheet" href="styles.css"></head>
<body>
  <h1>Jane Doe</h1>
  <p>Aspiring full-stack developer, learning Git one atomic commit at a time.</p>
</body>
</html>
EOF

cat > docs/styles.css << 'EOF'
body { font-family: system-ui; max-width: 600px; margin: 4rem auto; }
EOF

git add .
git commit -m "feat: add initial portfolio landing page"

git remote add origin git@github.com:yourusername/my-portfolio.git
git push -u origin main

# On GitHub.com: Settings -> Pages -> Deploy from a branch -> main -> /docs -> Save
# Wait, then visit https://yourusername.github.io/my-portfolio/

# Make a visible update
sed -i '' 's/learning Git/mastering Git/' docs/index.html   # macOS sed syntax; use sed -i 's/.../.../' on Linux
git add docs/index.html
git commit -m "docs: update bio wording"
git push
```

**Why this is correct:** GitHub Pages isn't a one-time export — it's a **live sync** with whatever source you configured (here, `main`'s `/docs` folder). Every `git push` to that source is automatically detected and redeployed, usually within a minute. This is the core mental model to carry forward: deployment isn't a separate manual step you do occasionally — with the right Git workflow, deployment *is* just "push to the right branch." This exact idea, generalized and automated further, becomes the CI/CD pipelines you'll build in Part 6 for Vercel.

---

**Next up:** Part 5 — the tools that let you move backward and sideways through history: `log`, `reset`, `revert`, and `stash`, plus how to recover from the mistakes every developer eventually makes.

Want **Part 5** next?
