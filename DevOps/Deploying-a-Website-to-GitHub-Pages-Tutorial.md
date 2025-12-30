# 📘 Deploying a Website to GitHub Pages: Step-by-Step Guide

**Edition:** 1.0
**Audience:** Beginners, Bootcamp Learners, Web Developers
**Goal:** Learn to host a static website using GitHub Pages
**Prerequisites:**

* Git installed ([https://git-scm.com](https://git-scm.com))
* GitHub account
* Basic HTML/CSS/JS project

---

# 🏗️ Step 1: Create a Simple Website

Example project structure:

```
my-website/
├── index.html
├── style.css
└── script.js
```

**index.html**

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

**style.css**

```css
body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
```

**script.js**

```js
console.log("Website deployed on GitHub Pages!");
```

**Diagram (Project Layout):**

```
my-website/
 ├── index.html
 ├── style.css
 └── script.js
```

---

# ⚡ Step 2: Initialize Git Repository

1. Navigate to your project folder:

```bash
cd my-website
git init
```

2. Add files & commit:

```bash
git add .
git commit -m "Initial commit"
```

**Diagram (Git Flow):**

```
Working Directory
 ├── index.html
 ├── style.css
 └── script.js
        |
        v
Staging Area (git add)
        |
        v
Local Repo (git commit)
```

---

# 🏗️ Step 3: Create GitHub Repository

1. Go to [GitHub](https://github.com) → New Repository
2. Repository name: `my-website`
3. Visibility: Public
4. Click **Create repository**

**Diagram:**

```
Local Repo ----push----> GitHub Repo
```

---

# ⚡ Step 4: Connect Local Repo to GitHub

```bash
git remote add origin https://github.com/your-username/my-website.git
git branch -M main
git push -u origin main
```

---

# 🏗️ Step 5: Enable GitHub Pages

1. Go to **GitHub Repository → Settings → Pages**
2. Under **Source**, select **Branch: main** and **Folder: / (root)**
3. Click **Save**
4. GitHub Pages URL will appear like:

   ```
   https://your-username.github.io/my-website/
   ```

**Diagram (Deployment Flow):**

```
Local Repo (main branch)
        |
        v
Push to GitHub
        |
        v
GitHub Pages
        |
        v
Public URL: https://username.github.io/my-website/
```

---

# ⚡ Step 6: Update Website & Auto-Deploy

1. Make changes to `index.html`, `style.css`, or `script.js`

2. Stage, commit, and push:

```bash
git add .
git commit -m "Update website content"
git push
```

3. GitHub Pages **automatically updates** with the new content

**Diagram (Update Flow):**

```
Developer Edit
        |
        v
Git Add & Commit
        |
        v
Push to GitHub
        |
        v
GitHub Pages Auto-Deploy
        |
        v
Live Website Updated
```

---

# 🏗️ Step 7: Optional – Custom Domain

1. In **Settings → Pages → Custom Domain**, add your domain
2. Configure your domain’s DNS with **CNAME** pointing to `your-username.github.io`
3. HTTPS is automatically provided by GitHub

**Diagram:**

```
Custom Domain -> GitHub Pages
                     |
                     v
             HTTPS Enabled
```

---

# ⚡ Step 8: Tips & Best Practices

* Keep your website **static** (HTML/CSS/JS)
* Use **index.html** as the main entry point
* Commit **frequently**
* Use `.gitignore` for files you don’t want to publish
* For SPA (React/Vue/Angular), generate **build output** and deploy `build/` folder

---

# ✅ Key Takeaways

* GitHub Pages can host **static websites for free**
* Deploy workflow: **Local Repo → Push → GitHub → Public URL**
* Any change pushed to the main branch automatically updates the live site
* Can support **custom domains** with HTTPS

---

**Full Deployment Flow Overview (Text Diagram):**

```
Developer Local Repo
 ├── Edit Files
 ├── git add & commit
 └── git push
        |
        v
GitHub Repository
        |
        v
GitHub Pages
        |
        v
Live Website (https://username.github.io/my-website/)
```

---

