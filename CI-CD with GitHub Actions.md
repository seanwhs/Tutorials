# 📘 GitHub Actions CI/CD Tutorial — Step-by-Step

**Edition:** 1.0
**Audience:** Beginners → Intermediate
**Goal:** Learn CI/CD with GitHub Actions using a simple project
**Prerequisites:** Git & GitHub account, basic project (Node.js, Python, or any code)

---

# 🏗️ Step 1: Create a Simple Project

Example: **Node.js app**

```
my-ci-cd-project/
├── index.js
├── package.json
└── test.js
```

**`index.js`**

```js
function add(a, b) {
  return a + b;
}

module.exports = add;
```

**`test.js`**

```js
const add = require('./index');

if (add(2,3) === 5) {
  console.log("Test Passed ✅");
} else {
  console.log("Test Failed ❌");
}
```

**`package.json`**

```json
{
  "name": "my-ci-cd-project",
  "version": "1.0.0",
  "scripts": {
    "test": "node test.js"
  }
}
```

> **Mental Model:** Think of your code + tests as a **self-contained unit** ready for automated checks. CI/CD automates these checks every time your code changes.

---

# ⚡ Step 2: Initialize Git & Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/your-username/my-ci-cd-project.git
git push -u origin main
```

**ASCII Diagram — Local → Remote Flow**

```
Local Repository ----push----> GitHub Repository
```

> **Tip:** Always use `main` or `master` as your main branch; PRs will merge into this branch for CI/CD.

---

# 🏗️ Step 3: Create GitHub Actions Workflow

1. Create workflow folder:

```
my-ci-cd-project/
└── .github/
    └── workflows/
        └── ci.yml
```

2. Example **Node.js CI workflow**:

```yaml
name: Node.js CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm test
```

**ASCII Diagram — CI Workflow**

```
GitHub Repo (main branch)
        |
        v
GitHub Actions Trigger (push / PR)
        |
        v
CI Job:
 ├─ Checkout code
 ├─ Setup Node.js
 ├─ Install dependencies
 └─ Run tests
```

> **Teaching Tip:** Workflows are **event-driven pipelines**. Each step is **idempotent**, so you can rerun safely.

---

# ⚡ Step 4: Commit Workflow File

```bash
git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
git push
```

* GitHub Actions triggers automatically on push
* Monitor **Actions tab** in GitHub to see job progress

---

# 🏗️ Step 5: Add Deployment Step (Optional)

Example: Deploy to **GitHub Pages** for frontend projects:

```yaml
jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm run build
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

**ASCII Diagram — CI/CD Flow**

```
Code Push → GitHub Repo
        |
        v
GitHub Actions:
 ├─ Build
 ├─ Test
 └─ Deploy (GitHub Pages / Server)
```

> **Mental Model:** Think of CI as “**green-light gate**” before code reaches deployment.

---

# 🏗️ Step 6: Add Secrets for Production Deployment

* Go to **Settings → Secrets → Actions** in your GitHub repo
* Example secrets:

  * `PROD_SERVER_USER`
  * `PROD_SERVER_HOST`
  * `SSH_KEY`

**Example SSH Deployment Step**

```yaml
- name: Deploy to server
  uses: appleboy/ssh-action@v0.1.6
  with:
    host: ${{ secrets.PROD_SERVER_HOST }}
    username: ${{ secrets.PROD_SERVER_USER }}
    key: ${{ secrets.SSH_KEY }}
    script: |
      cd /var/www/my-app
      git pull
      npm install
      pm2 restart all
```

---

# ⚡ Step 7: Branch Workflow & Pull Request Integration

1. Create a feature branch:

```bash
git checkout -b feature/new-feature
```

2. Push branch:

```bash
git push -u origin feature/new-feature
```

3. Open a Pull Request (PR) to merge into `main`

* CI triggers automatically for PRs
* Only merge if tests pass

**ASCII Diagram — Branch CI/CD**

```
Feature Branch PR
        |
        v
GitHub Actions (Test)
        |
        v
Merge → main branch triggers full CI/CD
```

> **Tip:** PR-based workflows **prevent broken code** from reaching production.

---

# 📝 Step 8: Best Practices

* Test everything in CI before merging PRs
* Store sensitive data in **GitHub Secrets**
* Keep workflow files under version control
* Split jobs for clarity: build, test, deploy separately
* Add CI badges in README:

```markdown
![CI](https://github.com/username/repo/actions/workflows/ci.yml/badge.svg)
```

---

# ✅ Key Takeaways

* GitHub Actions automates **CI/CD pipelines**
* Workflows trigger on **push/PR events**
* Code can **build, test, deploy automatically**
* Secrets enable **secure deployment**
* Branching + CI/CD ensures **safe code integration**

---

**Text-Based Overview — End-to-End CI/CD Flow**

```
Developer Pushes Code
        |
        v
GitHub Repo (main or feature branch)
        |
        v
GitHub Actions Workflow
 ├─ Checkout code
 ├─ Install dependencies
 ├─ Run tests
 └─ Deploy (if tests pass)
        |
        v
Production Server / GitHub Pages
```

> **Teaching Tip:** Always visualize CI/CD as **a pipeline of transformations**: code → tests → artifacts → deploy.

---

