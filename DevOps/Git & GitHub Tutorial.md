**Edition:** 1.0
**Audience:** Beginners → Intermediate
**Goal:** Learn Git (version control) and GitHub (remote repository hosting)
**Prerequisites:**

* Git installed (`git --version`)
* GitHub account

---

# 🧭 Mental Model

Git is a **local version control system**. Think of it as a **time machine for your code**:

```
Working Directory ---> Staging Area ---> Local Repository ---> Remote Repository
       |                  |                  |                     |
       v                  v                  v                     v
  Files you edit      Files you commit    Snapshot history       Backup on GitHub
```

* **Working Directory** – where you make changes
* **Staging Area** – “ready to commit” changes
* **Local Repository** – saved history of your project
* **Remote Repository** – GitHub storage & collaboration

---

# 🏗️ Step 1: Initialize Local Git Repository

```bash
# Go to project folder
cd my-project

# Initialize Git
git init
```

**ASCII Diagram: Local Repo Initialization**

```
my-project/
├── index.html
└── style.css
       |
       v
git init → Creates .git directory
```

---

# ⚡ Step 2: Track Files & Commit

1. Stage files:

```bash
git add .
```

2. Commit changes:

```bash
git commit -m "Initial commit"
```

**ASCII Diagram: Commit Flow**

```
Working Directory → git add → Staging Area → git commit → Local Repository
```

> Mental Tip: Always write **clear commit messages** like: `"Add homepage layout"`

---

# 🏗️ Step 3: Connect to GitHub

1. Create a repository on GitHub → `my-project`
2. Add remote origin:

```bash
git remote add origin https://github.com/username/my-project.git
```

**ASCII Diagram: Local ↔ Remote**

```
Local Repository ----push----> GitHub Repository
```

3. Push initial commit:

```bash
git branch -M main
git push -u origin main
```

---

# ⚡ Step 4: Basic Git Commands

| Command                   | Purpose                         |
| ------------------------- | ------------------------------- |
| `git status`              | Check modified/untracked files  |
| `git diff`                | See file changes                |
| `git log`                 | View commit history             |
| `git add <file>`          | Stage specific file             |
| `git commit -m "message"` | Commit staged changes           |
| `git push`                | Push commits to GitHub          |
| `git pull`                | Pull latest changes from GitHub |

**ASCII Diagram: Workflow**

```
Edit Files → Stage → Commit → Push → GitHub
```

---

# 🏗️ Step 5: Branching & Merging

1. Create a new branch:

```bash
git checkout -b feature/login
```

2. Make changes → stage → commit

3. Switch branches:

```bash
git checkout main
```

4. Merge feature branch:

```bash
git merge feature/login
```

**ASCII Diagram: Branching**

```
main:      A---B---C
feature:       \---D---E
merge:      A---B---C---F
```

> **Mental Model:** Branches = **parallel universes** of your project

---

# ⚡ Step 6: Collaboration Workflow

**Fork & Pull Requests (PRs):**

1. Fork repo
2. Clone fork:

```bash
git clone https://github.com/your-username/forked-repo.git
```

3. Create branch → make changes → push → open PR
4. Project maintainers review and merge

**ASCII Diagram: Fork + PR**

```
Original Repo
       ^
       | Pull Request
Forked Repo (your changes)
       ^
       | git push
Local Repo
```

---

# 🏗️ Step 7: Resolving Conflicts

1. Pull latest changes:

```bash
git pull origin main
```

2. Conflicts may appear in files:

```
<<<<<<< HEAD
your changes
=======
incoming changes
>>>>>>> branch
```

3. Edit, stage, commit:

```bash
git add <file>
git commit -m "Resolve merge conflict"
```

---

# ⚡ Step 8: Tags & Releases

1. Tag a version:

```bash
git tag v1.0.0
git push origin v1.0.0
```

2. Use GitHub Releases to attach binaries or notes

**ASCII Diagram: Tagging**

```
A---B---C (main)
          |
         v1.0.0
```

---

# 🏗️ Step 9: Undo Mistakes

| Command                     | Usage                                         |
| --------------------------- | --------------------------------------------- |
| `git checkout -- <file>`    | Undo changes in working directory             |
| `git reset HEAD <file>`     | Unstage a file                                |
| `git revert <commit>`       | Create a new commit undoing a previous commit |
| `git reset --hard <commit>` | Reset branch to a previous commit (danger!)   |

**Mental Model:** Commit history is a **timeline — you can branch off, rewind, or fix mistakes safely**

---

# 🏗️ Step 10: GitHub Pages Integration

Once comfortable with Git, you can deploy your project using **GitHub Pages**.
See [GitHub Pages Tutorial](#) for **full deployment workflow**.

**ASCII Diagram: Full Flow**

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
Branches / PRs / CI/CD
        |
        v
Optional: GitHub Pages / Server Deployment
```

---

# 📝 Best Practices

* Write **atomic commits**: one logical change per commit
* Use **branches for features** → merge back main
* Pull before pushing to avoid conflicts
* Use **.gitignore** to avoid committing unnecessary files
* Add a **README.md** to explain your project

---

# ✅ Key Takeaways

* Git = **local version control**, GitHub = **remote collaboration**
* Commit early, commit often, use clear messages
* Branching + Pull Requests = safe collaboration
* Conflicts are normal → learn to resolve them
* Tags & releases help versioning
* Git + GitHub → foundation for CI/CD and GitHub Pages

---
