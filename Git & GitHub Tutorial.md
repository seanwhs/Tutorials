# 📘 Git & GitHub Tutorial: Step-by-Step Guide with Diagrams

**Edition:** 1.0
**Audience:** Beginners, Bootcamp Learners, Engineers
**Goal:** Learn Git and GitHub by building a simple project from scratch

**Prerequisites:**

* Git installed ([https://git-scm.com/](https://git-scm.com/))
* GitHub account

---

# 🏗️ Step 1: Setup & Installation

1. **Install Git** (if not installed):

```bash
# Linux
sudo apt update
sudo apt install git

# MacOS (using Homebrew)
brew install git

# Windows
# Download from https://git-scm.com/download/win
```

2. **Verify Installation**:

```bash
git --version
```

3. **Configure Git globally**:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global core.editor "nano"  # optional
```

---

# 📝 Step 2: Create a Simple Project

Let’s create a **simple website project**:

```
my-simple-project/
├── index.html
├── style.css
└── script.js
```

**index.html**:

```html
<!DOCTYPE html>
<html>
<head>
  <title>My Simple Project</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>Hello, Git & GitHub!</h1>
  <script src="script.js"></script>
</body>
</html>
```

**style.css**:

```css
body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
```

**script.js**:

```js
console.log("Welcome to Git & GitHub Tutorial!");
```

---

# ⚡ Step 3: Initialize Git Repository

1. Navigate to the project folder:

```bash
cd my-simple-project
```

2. Initialize Git:

```bash
git init
```

**Text-based diagram:**

```
my-simple-project/ (working directory)
 └── .git/ (hidden git repo initialized)
```

3. Check repository status:

```bash
git status
```

---

# 🏗️ Step 4: Add & Commit Files

1. Add files to **staging area**:

```bash
git add .
```

2. Commit files to local repository:

```bash
git commit -m "Initial commit: add project files"
```

**Diagram:**

```
Working Directory
 ├── index.html
 ├── style.css
 └── script.js
        |
        v
Staging Area --> git add
        |
        v
Local Repository --> git commit
```

3. Check commit history:

```bash
git log --oneline
```

---

# 🌐 Step 5: Create GitHub Repository

1. Go to [GitHub](https://github.com/) → New Repository
2. Repository name: `my-simple-project`
3. Visibility: Public / Private
4. Click **Create repository**

---

# ⚡ Step 6: Connect Local Repository to GitHub

1. Add remote origin:

```bash
git remote add origin https://github.com/your-username/my-simple-project.git
```

2. Verify remote:

```bash
git remote -v
```

**Diagram:**

```
Local Repository ----push/pull----> GitHub Repository (remote)
```

---

# 🏗️ Step 7: Push Code to GitHub

```bash
git branch -M main       # ensure main branch
git push -u origin main  # push local commits to GitHub
```

* Now the project is online on GitHub

**Diagram:**

```
Local Repo (main branch)
 └── Initial commit
        |
        v
GitHub Repo (main branch)  <-- mirrored
```

---

# 📝 Step 8: Make Changes & Version Control

1. Edit `script.js`:

```js
console.log("GitHub version updated!");
```

2. Check status:

```bash
git status
```

3. Stage and commit changes:

```bash
git add script.js
git commit -m "Update script.js with console message"
```

4. Push changes:

```bash
git push
```

**Diagram (Commit History):**

```
Commit History:
[commit 2] Update script.js
[commit 1] Initial commit
```

---

# 🔀 Step 9: Branching & Merging

1. Create a new branch for a feature:

```bash
git checkout -b feature/add-footer
```

2. Make changes (e.g., add `<footer>` in `index.html`)

3. Stage & commit changes:

```bash
git add index.html
git commit -m "Add footer section"
```

4. Merge branch into main:

```bash
git checkout main
git merge feature/add-footer
```

5. Push main branch:

```bash
git push
```

**Diagram (Branch Workflow):**

```
main
 └── Initial commit
      \
       feature/add-footer --> commit with footer
       /
merge
 └── main updated
```

---

# 🌐 Step 10: Pull Requests (Optional on GitHub)

1. Push branch to GitHub:

```bash
git push -u origin feature/add-footer
```

2. Go to GitHub → Pull Requests → New Pull Request
3. Merge into `main` branch

**Diagram:**

```
GitHub Repo
 ├── main
 └── feature/add-footer --> Pull Request --> merge into main
```

---

# 🏗️ Step 11: Undo Changes & Revert

1. Undo uncommitted changes:

```bash
git checkout -- script.js
```

2. Reset last commit:

```bash
git reset --soft HEAD~1    # keep changes staged
git reset --hard HEAD~1    # discard changes
```

---

# ⚡ Step 12: Clone & Collaborate

1. Clone repository:

```bash
git clone https://github.com/your-username/my-simple-project.git
```

2. Work in a branch:

```bash
git checkout -b feature/new-change
```

3. Push and create pull request → team reviews → merge

**Team Workflow Diagram:**

```
Team Member A
 └── local branch ----push--> GitHub Repo <--pull--- Team Member B
```

---

# ✅ Step 13: Best Practices

* Commit frequently with clear messages
* Use branches for features & bug fixes
* Pull latest changes before starting work: `git pull origin main`
* Avoid committing sensitive info
* Use `.gitignore` to ignore unnecessary files

---

# 📘 Key Takeaways

* Git tracks **versions locally**
* GitHub stores **remote copies** and enables collaboration
* Branching allows **safe feature development**
* Pull Requests enable **code review and merging**
* Text-based diagrams help visualize **workflow and commits**

---

This tutorial is **complete for beginners**, with a **small project example**, **step-by-step commands**, and **text-based diagrams** showing workflows, branching, and GitHub collaboration.

---
