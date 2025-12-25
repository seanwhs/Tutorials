# 📘 GitHub Pages Tutorial — Step-by-Step

**Edition:** 1.0
**Audience:** Beginners → Intermediate
**Goal:** Learn to deploy a static site or frontend project to GitHub Pages
**Prerequisites:**

* Git & GitHub account
* Basic HTML/CSS/JS project or frontend framework (React, Vue, etc.)

---

# 🏗️ Step 1: Create a GitHub Repository

1. Go to GitHub → New repository
2. Name it, e.g., `my-website`
3. Initialize with **README** (optional)
4. Choose **public** (GitHub Pages works for public repos free)

**Diagram — Local & Remote Repository**

```
Local Project
   |
   v
Git Init → Local Git Repo
   |
   v
Git Push → GitHub Repository
```

---

# ⚡ Step 2: Prepare Your Project

**Example: Simple HTML Project**

```
my-website/
├── index.html
├── style.css
└── script.js
```

**`index.html`**

```html
<!DOCTYPE html>
<html>
<head>
  <title>My Website</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>Hello, GitHub Pages!</h1>
  <script src="script.js"></script>
</body>
</html>
```

**`script.js`**

```js
console.log("GitHub Pages works!");
```

**`style.css`**

```css
body {
  font-family: Arial, sans-serif;
  text-align: center;
  margin-top: 50px;
}
```

> Mental Model: Think of **GitHub Pages as a static file server** — all your HTML, CSS, JS, and assets are deployed “as-is.”

---

# 🏗️ Step 3: Initialize Git & Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/your-username/my-website.git
git push -u origin main
```

**ASCII Diagram — Local → GitHub**

```
Local Repository ----push----> GitHub Repository
```

---

# ⚡ Step 4: Enable GitHub Pages

1. Go to GitHub → Repository → Settings → Pages
2. Under **Source**, choose branch: `main`
3. Folder: `/ (root)`
4. Click **Save**

> After a few minutes, GitHub provides a URL: `https://your-username.github.io/my-website/`

**ASCII Diagram — Workflow**

```
GitHub Repository (main branch)
        |
        v
GitHub Pages Service
        |
        v
https://username.github.io/my-website/
```

---

# 🏗️ Step 5: Test Locally (Optional)

You can serve your project locally to verify:

```bash
# If Node.js installed
npx http-server .  # or `python -m http.server`
```

Open `http://localhost:8080` in browser

> **Tip:** Always test locally before pushing — ensures static assets load correctly.

---

# ⚡ Step 6: Deploy Updates

1. Make changes:

```bash
echo "<p>Updated content!</p>" >> index.html
```

2. Commit & push:

```bash
git add .
git commit -m "Update homepage content"
git push
```

3. GitHub Pages automatically updates your site within seconds/minutes.

**Diagram — Update Flow**

```
Edit Local Files
        |
        v
Git Commit & Push
        |
        v
GitHub Pages Auto-Deploy
        |
        v
Live Site Updated
```

---

# 🏗️ Step 7: Custom Domains (Optional)

1. Go to GitHub → Repository → Settings → Pages → Custom Domain
2. Enter domain: `www.example.com`
3. Update DNS CNAME to point to `your-username.github.io`

**ASCII Diagram — Custom Domain Routing**

```
www.example.com
        |
        v
CNAME → username.github.io
        |
        v
GitHub Pages serves your static site
```

---

# ⚡ Step 8: Using GitHub Actions for Automation (Optional)

If you use frameworks (React, Vue, Svelte), you can build + deploy automatically:

**Example `gh-pages.yml` Workflow:**

```yaml
name: Deploy React App

on:
  push:
    branches:
      - main

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npm run build
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build
```

**ASCII Diagram — CI/CD Deployment**

```
Code Push → GitHub Repo
        |
        v
GitHub Actions:
 ├─ Build React App
 └─ Deploy /build → GitHub Pages
```

---

# 📝 Step 9: Best Practices

* Keep site content **static** and minimal for fast loading
* Use a `/docs` folder if your repo contains source + site
* Version control your workflow files (`.yml`)
* Leverage GitHub Actions for **automatic builds** from modern frameworks
* Monitor your GitHub Pages site after every deployment

---

# ✅ Key Takeaways

* GitHub Pages is a **free static site hosting solution**
* You can deploy **plain HTML/JS/CSS** or **built frontend frameworks**
* Push updates → auto-deployed within seconds/minutes
* Use **custom domains** and **GitHub Actions** for automation

---

**Full Text-Based Deployment Flow:**

```
Local Project
        |
        v
Git Commit & Push
        |
        v
GitHub Repository
        |
        v
GitHub Pages Service
        |
        v
Live Website (https://username.github.io/repo/)
```

---

