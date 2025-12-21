# 📘 GitHub Actions CI/CD Tutorial: Step-by-Step

**Edition:** 1.0
**Audience:** Beginners → Intermediate
**Goal:** Learn CI/CD using GitHub Actions with a simple project
**Prerequisites:**

* Git & GitHub account
* Basic project (e.g., Node.js, Python, or any code)

---

# 🏗️ Step 1: Create a Simple Project

Example: **Node.js app**

```
my-ci-cd-project/
├── index.js
├── package.json
└── test.js
```

**index.js**

```js
function add(a, b) {
  return a + b;
}

module.exports = add;
```

**test.js**

```js
const add = require('./index');

if (add(2,3) === 5) {
  console.log("Test Passed ✅");
} else {
  console.log("Test Failed ❌");
}
```

**package.json**

```json
{
  "name": "my-ci-cd-project",
  "version": "1.0.0",
  "scripts": {
    "test": "node test.js"
  }
}
```

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

**Diagram:**

```
Local Repository ----push----> GitHub Repository
```

---

# 🏗️ Step 3: Create GitHub Actions Workflow

1. Create workflow folder:

```
my-ci-cd-project/
└── .github/
    └── workflows/
        └── ci.yml
```

2. Example `ci.yml` for Node.js project:

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

**Diagram (CI Workflow):**

```
GitHub Repo (main branch)
        |
        v
GitHub Actions Trigger (on push or PR)
        |
        v
CI Job:
 ├─ Checkout code
 ├─ Setup Node.js
 ├─ Install dependencies
 └─ Run tests
```

---

# ⚡ Step 4: Commit Workflow File

```bash
git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
git push
```

* GitHub Actions will automatically run the workflow
* Go to **GitHub → Actions** to see the build & test status

---

# 🏗️ Step 5: Add Deployment Step (Optional)

Example: Deploy to **GitHub Pages** (for a frontend project)

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

**Diagram (CI/CD Workflow):**

```
Code Push → GitHub Repo
        |
        v
GitHub Actions:
 ├─ Build
 ├─ Test
 └─ Deploy (GitHub Pages / Server)
```

---

# 🏗️ Step 6: Add Secrets for Production Deployment

* For private servers, Docker, AWS, or Heroku:
  Go to **Settings → Secrets → Actions** in GitHub repository
  Add keys like:

  * `PROD_SERVER_USER`
  * `PROD_SERVER_HOST`
  * `SSH_KEY`

**Example Deployment Step via SSH:**

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

2. Push branch to GitHub:

```bash
git push -u origin feature/new-feature
```

3. Open a Pull Request (PR) to merge into `main`

* Workflow triggers on PR automatically
* CI runs tests before merging

**Diagram (Branch CI/CD):**

```
Feature Branch PR
        |
        v
GitHub Actions (Test)
        |
        v
Merge → main branch triggers full CI/CD
```

---

# 📝 Step 8: Best Practices

* Always test in CI before merging PRs
* Use **secrets** for sensitive information
* Keep workflow files version-controlled
* Split jobs if workflow is long (e.g., build, test, deploy separately)
* Use badges in README to show CI status:

```markdown
![CI](https://github.com/username/repo/actions/workflows/ci.yml/badge.svg)
```

---

# ✅ Key Takeaways

* GitHub Actions provides **automated CI/CD**
* Workflows are **triggered on push/PR**
* Can **build, test, and deploy** code automatically
* Secrets allow **secure deployment**
* Branching + CI/CD ensures **safe code integration**

---

**Text-Based Overview of Full CI/CD Flow:**

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

---


Do you want me to create that template next?
