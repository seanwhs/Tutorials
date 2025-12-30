# Git & GitHub Tutorial (Integrated Lab Workbook)

**Edition:** 1.0
**Audience:** Beginners → Intermediate
**Goal:** Learn Git (local version control) and GitHub (remote repository hosting) with hands-on exercises, branching, pull requests (PRs), code review, undo/rollback techniques, GitHub Pages publishing, and integrated CI/CD workflow using GitHub Actions.

---

## 📁 Folder Structure

```
GitHub-Lab-Workbook/
├── README.md                    # Overview & instructions
├── Exercises/
│   ├── Project1_HTML_CSS/
│   │   ├── index.html
│   │   └── style.css
│   ├── Project2_JS/
│   │   ├── index.html
│   │   └── script.js
│   │   └── package.json
│   └── Project3_Python/
│       ├── main.py
│       ├── utils.py
│       └── requirements.txt
├── .github/
│   └── workflows/
│       └── ci-cd.yml            # GitHub Actions workflow
└── Assets/
    └── ascii_diagrams.md        # Consolidated diagrams
```

> **Tip:** A clear folder structure ensures projects and exercises are easy to navigate, reduces mistakes, and allows consistent Git workflows.

---

## 🧭 Understanding Git (Verbose)

Git is a **distributed version control system (DVCS)** that tracks changes, allows collaboration, and enables recovery from mistakes. Think of Git as a **time machine for your code**.

### Git Workflow Diagram

```
Working Directory ---> Staging Area ---> Local Repository ---> Remote Repository
       |                  |                  |                     |
       v                  v                  v                     v
  Files you edit      Files you commit    Snapshot history       Backup on GitHub
```

### Key Concepts

1. **Working Directory** – Where you edit files. Any changes made here are not yet tracked.
2. **Staging Area (Index)** – Temporary holding area. You **stage** only the changes you want to include in the next commit.
3. **Local Repository** – Stores the complete commit history. Each commit is like a snapshot of your project at a point in time.
4. **Remote Repository** – Hosted on GitHub (or similar). Used for backup, collaboration, and deployment.

> **Why this matters:** Separating working files, staging, and commits prevents accidental overwrites, allows selective commits, and simplifies collaboration.

**Exercise:** Create `test.txt` in Project1_HTML_CSS. Check `git status`:

```bash
git status
```

* You’ll see it in the **untracked** section (working directory).

---

## Step 1: Initialize Local Repository

```bash
cd Exercises/Project1_HTML_CSS
git init
```

* Creates a hidden `.git` folder to track changes.
* `.git` contains objects, refs, configuration, and logs.

**Diagram:**

```
my-project/
├── index.html
├── style.css
└── .git/   <-- Git tracks all changes here
```

**Exercise:** Initialize and verify:

```bash
ls -a
```

---

## Step 2: Stage and Commit Files

```bash
git add .
git commit -m "Initial commit: Project1 HTML/CSS"
```

* `git add .` → stage all files
* `git commit -m "message"` → save snapshot in **local repository**

**Diagram:**

```
Working Directory → git add → Staging Area → git commit → Local Repository
```

**Exercise:** Stage & commit Project1 files with a descriptive message:

```bash
git commit -m "Add homepage layout and styling"
```

> **Tip:** Commit often and with clear messages. Each commit should represent **one logical change**.

---

## Step 3: Connect to GitHub

1. Create GitHub repository (Project1)
2. Link local repo:

```bash
git remote add origin https://github.com/username/Project1.git
git branch -M main
git push -u origin main
```

**Diagram:**

```
Local Repository ----push----> GitHub Repository
```

**Exercise:** Push Project1. Subsequent pushes:

```bash
git push
```

---

## Step 4: Common Git Commands

| Command               | Purpose               | Explanation                             |
| --------------------- | --------------------- | --------------------------------------- |
| `git status`          | Check file changes    | Shows staged, unstaged, untracked files |
| `git diff`            | Compare changes       | Working directory vs staging area       |
| `git log`             | View commit history   | Shows commit messages and SHA IDs       |
| `git add <file>`      | Stage specific file   | Stage only selected files               |
| `git commit -m "msg"` | Commit staged changes | Save snapshot to local repository       |
| `git push`            | Push to GitHub        | Sync local changes with remote repo     |
| `git pull`            | Pull from GitHub      | Update local repo with remote changes   |

**Exercise:** Modify `index.html`, stage, commit, push.

> **Tip:** Always check `git status` before committing.

---

## Step 5: Branching & Merging (Detailed)

Branches allow **parallel development**:

* `main` → production-ready code
* `feature/*` → new features, experiments, or fixes

**Create a branch:**

```bash
git checkout -b feature/login
```

* `feature/login` is independent from `main`.
* Work in branch, commit changes.

**Merge back to main:**

```bash
git checkout main
git merge feature/login
```

**Diagram:**

```
main:      A---B---C
feature:       \---D---E
merge:      A---B---C---F
```

> **Explanation:**
>
> * `main` continues independently.
> * `feature` branch allows experimentation.
> * Merge creates a **new commit** (`F`) integrating changes.

**Exercise:** Branch → edit `style.css` → stage → commit → merge to main.

> **Tip:** Branches are like **parallel universes**. Merge carefully.

---

## Step 6: Collaboration Workflow & Pull Requests (PRs)

1. **Fork repository**
2. **Clone fork locally**
3. **Create feature branch**
4. **Commit changes**
5. **Push branch**
6. **Open Pull Request** on GitHub
7. **Code review**, approve → **merge**

**Diagram:**

```
Original Repo
       ^
       | Pull Request (PR)
Forked Repo
       ^
       | git push
Local Repo
```

**Exercise:** Fork a repository, create branch, push changes, open PR, request review, merge.

> PRs are **safety checkpoints** before integrating your changes. Code review ensures **quality and consistency**.

---

## Step 7: Resolving Conflicts (Detailed)

A **merge conflict** occurs when **different changes** exist on the same lines of a file in two branches. Git cannot auto-merge.

**Steps:**

```bash
git pull origin main
# conflicts appear
# edit conflicting files manually
git add <file>
git commit -m "Resolve merge conflict"
```

**Conflict Example:**

```
<<<<<<< HEAD
your changes
=======
incoming changes
>>>>>>> feature/login
```

* `HEAD` → your current branch
* `incoming changes` → changes from branch being merged

**Exercise:** Simulate conflict:

1. Edit `style.css` in `main` → commit
2. Edit same lines in `feature/login` → commit
3. Merge → Git shows conflict
4. Edit manually, stage, commit

> **Tip:** Conflicts are normal. Resolve carefully to preserve intended functionality.

---

## Step 8: Tags & Releases

Tags mark **important points** (e.g., v1.0).

```bash
git tag v1.0.0
git push origin v1.0.0
```

**Diagram:**

```
A---B---C (main)
          |
         v1.0.0
```

**Exercise:** Tag Project1 as v1.0.0.

---

## Step 9: Undoing Mistakes & Rollback

1. **Discard local changes:**

```bash
git checkout -- style.css
```

2. **Unstage file:**

```bash
git reset HEAD style.css
```

3. **Undo commit safely:**

```bash
git revert <commit-id>
```

4. **Reset branch (danger!):**

```bash
git reset --hard <commit-id>
```

**Diagram:**

```
A---B---C---D
         ^
git reset --hard B
A---B
```

**Exercise:** Practice all techniques in safe branches.

---

## Step 10: GitHub Pages Deployment

1. Push Project1
2. Repository → Settings → Pages
3. Branch: `main`, Folder: `/root` or `/docs`
4. Access live site:

```
https://username.github.io/Project1
```

**Exercise:** Deploy, edit `index.html`, commit, push, verify online.

---

## Step 11: Project2_JS – Branching, PRs, CI/CD

* Initialize Project2_JS
* Create `feature/add-multiply` → edit `script.js` → stage → commit → push → PR → merge

**CI/CD Workflow (JS):**

```yaml
name: CI/CD JS Pipeline
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with: node-version: '16'
      - run: npm install
      - run: npm test
      - run: npm run build
      - run: npx gh-pages -d .
```

**Exercise:** Verify workflow runs → site deploys.

---

## Step 12: Project3_Python – Python CI/CD Lab

* Initialize repo → push files
* Feature branch → edit `utils.py`, add functions → commit → push → PR → merge

**Python CI/CD Workflow:**

```yaml
name: CI/CD Python Pipeline
on: [push, pull_request]
jobs:
  build-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with: python-version: '3.11'
      - run: pip install -r requirements.txt || echo "No dependencies"
      - run: python Exercises/Project3_Python/main.py
```

**Exercise:** Test workflow, check logs, verify script runs.

---

## Step 13: Publishing via GitHub Pages

* Project1_HTML_CSS and Project2_JS can be deployed to GitHub Pages
* CI/CD automates building and publishing for JS projects

**Exercise:** Edit a file → commit → push → observe automatic deployment.

---

## Step 14: Best Practices

* Atomic commits (one logical change per commit)
* Use feature branches and PRs
* Pull before pushing to avoid conflicts
* Use `.gitignore`
* Maintain clear `README.md`
* Automate repetitive tasks with GitHub Actions CI/CD
* Tag releases for versioning

---

## Step 15: Key Takeaways

* Git = local version control; GitHub = remote collaboration
* Commit frequently with descriptive messages
* Branching + PRs enable safe collaboration
* Conflicts are normal; learn to resolve them
* Tags & releases help with versioning
* GitHub Actions automates testing, building, deployment
* Git + GitHub + CI/CD = modern development workflow

---

# 📝 Addenum: Git & GitHub Labsheet 

**Edition:** 1.0
**Audience:** Beginners → Intermediate
**Goal:** Practice Git, GitHub, branching, merging, conflict resolution, pull requests, GitHub Pages deployment, and CI/CD workflows using GitHub Actions.

---

## 📁 Folder Structure

Before starting, **create the following folders and files**:

```
GitHub-Lab-Workbook/
└── Exercises/
    ├── Project1_HTML_CSS/
    │   ├── index.html
    │   └── style.css
    ├── Project2_JS/
    │   ├── index.html
    │   ├── script.js
    │   └── package.json
    └── Project3_Python/
        ├── main.py
        ├── utils.py
        └── requirements.txt
```

> **Tip:** Use `mkdir -p` to create nested folders. Example: `mkdir -p GitHub-Lab-Workbook/Exercises/Project1_HTML_CSS`


---

# Lab 1 – Initialize Repository & First Commit (Project1_HTML_CSS)

1. Navigate to the folder:

```bash
cd GitHub-Lab-Workbook/Exercises/Project1_HTML_CSS
```

2. Initialize Git:

```bash
git init
```

3. Verify `.git` folder:

```bash
ls -a
```

4. Stage files:

```bash
git add .
```

5. Commit files:

```bash
git commit -m "Initial commit"
```

**ASCII Diagram – Git Flow:**

```
Working Directory (index.html, style.css)
         |
         v
      git add
         |
         v
    Staging Area (files ready to commit)
         |
         v
      git commit
         |
         v
Local Repository (snapshot history)
```

> Commit messages should be descriptive, e.g., `"Initial homepage layout and styling"`.

---

# Lab 2 – Connect to GitHub & Push

1. Create a GitHub repository named `Project1_HTML_CSS`.
2. Link local repo:

```bash
git remote add origin https://github.com/username/Project1_HTML_CSS.git
git branch -M main
git push -u origin main
```

**ASCII Diagram – Local to Remote Push:**

```
Local Repository ----push----> GitHub Repository (Remote)
```

---

# Lab 3 – Common Git Commands

1. Modify `index.html` (add `<p>Practice paragraph</p>`).
2. Check status:

```bash
git status
```

3. See differences:

```bash
git diff
```

4. Stage file:

```bash
git add index.html
```

5. Commit:

```bash
git commit -m "Add practice paragraph"
```

6. Push:

```bash
git push
```

**ASCII Diagram – Git Commands Flow:**

```
Working Directory
   |
   v
git add --> Staging Area
   |
   v
git commit --> Local Repository
   |
   v
git push --> Remote Repository
```

---

# Lab 4 – Branching & Merging (Project2_JS)

Branches allow you to **develop features without affecting main**.

1. Navigate:

```bash
cd ../Project2_JS
```

2. Create feature branch:

```bash
git checkout -b feature/add-greet
```

3. Edit `script.js`:

```javascript
console.log("Feature branch active!");
```

4. Stage & commit:

```bash
git add script.js
git commit -m "Add feature branch log message"
```

5. Merge to main:

```bash
git checkout main
git merge feature/add-greet
```

**ASCII Diagram – Branching & Merging:**

```
main:     A---B---C
feature:      \---D---E
merge:     A---B---C---F
```

---

# Lab 5 – Conflict Resolution

Conflicts occur when **two branches edit the same line**.

1. Modify the same line in `script.js` on main and feature branch.
2. Merge:

```bash
git checkout main
git merge feature/add-greet
```

3. Git marks conflict:

```
<<<<<<< HEAD
main branch code
=======
feature branch code
>>>>>>> feature/add-greet
```

4. Resolve manually, stage, and commit:

```bash
git add script.js
git commit -m "Resolve merge conflict in script.js"
```

**ASCII Diagram – Conflict Flow:**

```
main:      A---B---C
feature:       \---D---E
merge:      conflict detected!
resolve & commit
merge complete: A---B---C---F
```

---

# Lab 6 – Tags & Releases (Project1_HTML_CSS)

```bash
git tag v1.0.0
git push origin v1.0.0
```

**ASCII Diagram – Tagging:**

```
A---B---C (main)
          |
         v1.0.0
```

---

# Lab 7 – Undo Changes (Project3_Python)

| Command                     | Action                          |
| --------------------------- | ------------------------------- |
| `git checkout -- <file>`    | Discard local changes           |
| `git reset HEAD <file>`     | Unstage a file                  |
| `git revert <commit>`       | Undo commit via new commit      |
| `git reset --hard <commit>` | Reset branch to previous commit |

**Exercise:** Modify `utils.py` and practice undoing changes safely.

---

# Lab 8 – Collaboration Workflow (Fork, PR, Code Review)

1. Fork a repository
2. Clone locally:

```bash
git clone https://github.com/your-username/forked-repo.git
```

3. Create branch, make changes, stage, commit, push.
4. Open Pull Request (PR) on GitHub
5. Perform **code review** and merge PR

**ASCII Diagram – Collaboration Flow:**

```
Original Repo
       ^
       | Pull Request
Forked Repo
       ^
       | git push
Local Repo
```

---

# Lab 9 – GitHub Pages Deployment (Project1_HTML_CSS)

1. Push project to GitHub
2. Enable Pages: **Settings → Pages → Branch main → Save**
3. Access site:

```
https://username.github.io/Project1_HTML_CSS
```

---

# Lab 10 – GitHub Actions CI/CD

Automate **build, test, deploy**.

1. Create `.github/workflows/ci-cd.yml`
2. JS workflow:

```yaml
name: CI/CD Pipeline
on: [push, pull_request]
jobs:
  build-js:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with: node-version: '16'
      - run: npm install
      - run: npm test
      - run: npm run build
```

3. Python workflow:

```yaml
  build-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with: python-version: '3.11'
      - run: pip install -r Exercises/Project3_Python/requirements.txt || echo "No dependencies"
      - run: python Exercises/Project3_Python/main.py
```

> Push changes and check **Actions tab** on GitHub.

---

# Lab 11 – Exercise Files

### Project1_HTML_CSS

**index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Project1 HTML/CSS Lab</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>Welcome to Git Lab 1</h1>
  <p>This project helps you practice init, commit, and GitHub Pages deployment.</p>
</body>
</html>
```

**style.css**

```css
body { font-family: Arial, sans-serif; background-color: #f0f0f0; color: #333; margin: 20px; }
h1 { color: #2a7ae2; }
p { font-size: 1.1rem; }
```

---

### Project2_JS

**index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Project2 JS Lab</title>
</head>
<body>
  <h1>JS Lab Project</h1>
  <p>Open console to see messages.</p>
  <script src="script.js"></script>
</body>
</html>
```

**script.js**

```javascript
console.log("Hello from Project2 JS Lab!");
function greet(name) { console.log(`Hello, ${name}!`); }
greet("CI/CD Workflow");
function add(a, b) { return a + b; }
console.log("2 + 3 =", add(2, 3));
```

**package.json**

```json
{
  "name": "project2-js-lab",
  "version": "1.0.0",
  "description": "JS lab for Git & GitHub CI/CD exercises",
  "main": "script.js",
  "scripts": { "test": "echo \"No tests yet\"", "build": "echo \"Building project...\"" },
  "keywords": ["git", "github", "lab", "ci-cd"],
  "author": "Your Name",
  "license": "MIT",
  "dependencies": {}
}
```

---

### Project3_Python

**main.py**

```python
from utils import greet
if __name__ == "__main__":
    greet("Lab 3 Python CI/CD")
```

**utils.py**

```python
def greet(name):
    print(f"Hello, {name}!")
def add(a, b):
    return a + b
if __name__ == "__main__":
    print("Test utils.py functions")
    print("2 + 3 =", add(2, 3))
```

**requirements.txt**

```
# Add Python packages here
# Example:
# requests==2.31.0
```

---

# 🌟 Master ASCII Diagram – Projects, Branches, PRs, CI/CD

```
Project1_HTML_CSS (Lab 1)
  A---B---C main
       |
      v1.0.0 Tag
       |
   GitHub Pages Deployment
       |
      CI/CD (optional for automation)

Project2_JS (Lab 4-5)
  main:  A---B---C
  feature/add-greet:   \---D---E
  merge → F
  PR → Code Review → Merge
  CI/CD: build-js → npm install → npm test → npm run build → deploy

Project3_Python (Lab 7, 10)
  main:  A---B---C
  modify utils.py
  undo mistakes / revert commits
  CI/CD: build-python → pip install → python main.py → report results
```

> This **master diagram** shows **all projects, branching, merges, PRs, CI/CD, and deployment** flows at a glance.

---


