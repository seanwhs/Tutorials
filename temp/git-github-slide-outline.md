# Git & GitHub: From Local Code to Collaborative Development

### Slide Outline Based on Smoljames Git & GitHub Notes

---

# Slide 1 — Title Slide

## Git & GitHub Fundamentals

### From Version Control to Team Collaboration

**Topics Covered**

* What is Git?
* What is GitHub?
* Git Workflow
* Branching Strategy
* Commits & Merges
* Merge Conflicts
* Repository Security
* GitHub Best Practices

Source: Smoljames Git & GitHub Notes ([smoljames.com][1])

---

# Slide 2 — Learning Objectives

By the end of this lesson, you should be able to:

* Explain the purpose of Git
* Differentiate Git from GitHub
* Understand the Git workflow
* Create and manage branches
* Commit and push code safely
* Resolve merge conflicts
* Protect sensitive information
* Collaborate using GitHub repositories

---

# Slide 3 — Why Version Control Matters

## Imagine Building Without Git

Without version control:

* Changes are easily lost
* No history of modifications
* Difficult to revert mistakes
* Team collaboration becomes chaotic
* Multiple developers overwrite each other’s work

### Git Solves These Problems

* Tracks every change
* Stores project history
* Enables experimentation
* Supports collaboration
* Allows rollback to previous versions

Source: Git castle analogy from notes ([smoljames.com][1])

---

# Slide 4 — What Is Git?

## Git = Version Control System

Git is a command-line tool that:

* Tracks file changes
* Creates snapshots of projects
* Stores project history
* Supports branching
* Enables collaboration

### Key Concept

Git records project snapshots called:

**Commits**

Each commit represents a saved version of your project.

Source: Introduction to Git ([smoljames.com][1])

---

# Slide 5 — What Is GitHub?

## GitHub = Online Repository Platform

GitHub stores Git repositories online.

GitHub allows developers to:

* Backup code
* Share projects
* Collaborate with teams
* Review changes
* Manage pull requests / merge requests

### Relationship

```text
Local Machine
      ↓
     Git
      ↓
   GitHub
```

Source: Repository definition and GitHub overview ([smoljames.com][1])

---

# Slide 6 — Git vs GitHub

| Git                  | GitHub                 |
| -------------------- | ---------------------- |
| Version control tool | Cloud hosting platform |
| Runs locally         | Runs online            |
| Tracks code history  | Stores repositories    |
| Manages branches     | Enables collaboration  |
| Command line focused | Web interface          |

---

# Slide 7 — Understanding Repositories

## What Is a Repository?

A repository (repo) is:

* A project folder
* Its complete history
* All commits
* All branches
* Collaboration metadata

Think of a repository as:

> A digital storage box for your code.

Source: Repository definition ([smoljames.com][1])

---

# Slide 8 — The Git Workflow

## Core Workflow

```text
Main Branch
     │
     ├── Feature Branch
     │
     ├── Bug Fix Branch
     │
     └── Hotfix Branch
```

Developers:

1. Create a branch
2. Make changes
3. Commit work
4. Push branch
5. Create merge request
6. Merge into main

Source: Git workflow section ([smoljames.com][1])

---

# Slide 9 — Why Use Branches?

Without branches:

* Everyone edits the same code
* High risk of conflicts
* Unstable production code

With branches:

* Isolated development
* Safe experimentation
* Easier testing
* Cleaner collaboration

Source: Why do we do this? section ([smoljames.com][1])

---

# Slide 10 — Main Branch vs Feature Branches

## Main Branch

Typically contains:

* Stable code
* Production-ready code
* Source of truth

## Feature Branches

Used for:

* New features
* Enhancements
* Experiments
* Bug fixes

Example:

```text
main
 ├── f/login-feature
 ├── f/dashboard
 └── h/navbar-fix
```

Source: Branch naming guidance ([smoljames.com][1])

---

# Slide 11 — Installing Git

## Verify Installation

Open terminal:

```bash
git version
```

Possible outcomes:

* Git version displayed
* Command not found

If missing:

* Install Git
* Verify installation again

Source: Installing Git section ([smoljames.com][1])

---

# Slide 12 — Authenticating GitHub

## Connecting Git to GitHub

Recommended approach:

### GitHub CLI

Install:

```bash
gh
```

Login:

```bash
gh auth login
```

Choose:

* HTTPS authentication
* GitHub credentials

Source: Authentication section ([smoljames.com][1])

---

# Slide 13 — GitHub Desktop Alternative

## GUI-Based Git

For beginners:

### GitHub Desktop

Benefits:

* No command line required
* Visual interface
* Easy commits
* Easy pushes
* Simple repository management

Source: GitHub Desktop chapter ([smoljames.com][1])

---

# Slide 14 — The Git Process Overview

```text
Initialize / Clone
        ↓
   Check Status
        ↓
    Pull Latest
        ↓
  Create Branch
        ↓
   Make Changes
        ↓
     Commit
        ↓
      Push
        ↓
 Merge Request
        ↓
      Merge
```

Source: Git Process section ([smoljames.com][1])

---

# Slide 15 — Initializing a Repository

## Create New Repository

```bash
git init
```

Creates:

```text
.git/
```

which contains Git tracking information.

Source: Git initialization process ([smoljames.com][1])

---

# Slide 16 — Cloning Existing Repositories

## Download Existing Project

```bash
git clone <repository-url>
```

Examples:

```bash
git clone https://github.com/user/project.git
```

Benefits:

* Full project history
* Existing branches
* Team collaboration

Source: Git clone process ([smoljames.com][1])

---

# Slide 17 — Checking Repository Status

## Most Important Command

```bash
git status
```

Shows:

* Modified files
* New files
* Current branch
* Staged changes
* Untracked files

Source: Git status explanation ([smoljames.com][1])

---

# Slide 18 — Synchronizing with Remote

## Pull Latest Changes

```bash
git pull origin
```

Purpose:

* Update local repository
* Synchronize with GitHub
* Avoid stale code

Best practice:

* Pull before starting work

Source: Pull workflow guidance ([smoljames.com][1])

---

# Slide 19 — Creating Branches

## Create and Switch

```bash
git checkout -b feature-name
```

Examples:

```bash
git checkout -b f/login
git checkout -b f/dashboard
git checkout -b h/navbar-fix
```

Source: Branch creation section ([smoljames.com][1])

---

# Slide 20 — Viewing Branches

## List Existing Branches

```bash
git branch
```

Output:

```text
* main
  f/login
  f/dashboard
```

The asterisk indicates:

Current branch.

Source: Branch management section ([smoljames.com][1])

---

# Slide 21 — Committing Changes

## Save Progress

```bash
git commit -am "Add login feature"
```

Good commit messages:

* Add user authentication
* Fix navbar responsiveness
* Refactor API client

Bad commit messages:

* stuff
* update
* fixes

Source: Commit workflow section ([smoljames.com][1])

---

# Slide 22 — Adding New Files

## Stage Files

```bash
git add .
```

Purpose:

* Include new files
* Prepare changes for commit

Workflow:

```bash
git add .
git commit -m "message"
```

Source: Git add explanation ([smoljames.com][1])

---

# Slide 23 — Pushing Changes

## Upload Work to GitHub

```bash
git push origin branch-name
```

Example:

```bash
git push origin f/login
```

After push:

* Branch appears on GitHub
* Others can review code

Source: Push workflow section ([smoljames.com][1])

---

# Slide 24 — Merge Requests (Pull Requests)

## Code Review Process

Workflow:

```text
Branch
  ↓
Push
  ↓
Create MR / PR
  ↓
Review
  ↓
Merge
```

Benefits:

* Quality control
* Team feedback
* Automated checks
* Safer deployments

Source: Merge request section ([smoljames.com][1])

---

# Slide 25 — Merge Conflicts

## What Are Merge Conflicts?

Occurs when:

* Two branches modify same code
* Git cannot automatically combine changes

Example:

```text
Developer A edits line 10
Developer B edits line 10
```

Git requires human intervention.

Source: Merge conflicts section ([smoljames.com][1])

---

# Slide 26 — Resolving Merge Conflicts

Typical Process:

```bash
git status
git checkout main
git pull origin
git checkout feature
git merge main
```

Then:

* Resolve conflicts
* Commit changes
* Push branch again

Source: Merge conflict workflow ([smoljames.com][1])

---

# Slide 27 — Repository Security

## Public vs Private Repositories

### Public

* Visible to everyone
* Open source
* Collaborative

### Private

* Restricted access
* Protects sensitive code
* Internal projects

Source: Security chapter ([smoljames.com][1])

---

# Slide 28 — Environment Variables

## Protecting Secrets

Never hardcode:

* API keys
* Passwords
* Tokens
* Credentials

Use:

```env
API_KEY=xxxxx
DB_PASSWORD=xxxxx
```

Stored in:

```text
.env
```

Source: Environment variables section ([smoljames.com][1])

---

# Slide 29 — The .gitignore File

## Prevent Sensitive Uploads

Example:

```gitignore
.env
node_modules
dist
```

Purpose:

* Exclude files from Git tracking
* Prevent accidental leaks
* Keep repositories clean

Source: .gitignore section ([smoljames.com][1])

---

# Slide 30 — HTTPS vs SSH Cloning

## Two Ways to Clone

### HTTPS

```bash
git clone https://...
```

Advantages:

* Easier setup
* Beginner friendly

### SSH

```bash
git clone git@github.com:...
```

Advantages:

* No repeated authentication
* Common in professional environments

Source: Cloning section ([smoljames.com][1])

---

# Slide 31 — Git Best Practices

### Always

* Pull before starting work
* Work on branches
* Commit frequently
* Write meaningful commit messages
* Review merge requests
* Protect secrets
* Use .gitignore

### Never

* Commit API keys
* Work directly on production branch
* Push untested code

Source: Git workflow and security guidance ([smoljames.com][1])

---

# Slide 32 — Essential Git Commands Cheat Sheet

```bash
git version
git init
git clone <repo>
git status
git pull origin
git checkout -b <branch>
git branch
git add .
git commit -m "message"
git push origin <branch>
git merge <branch>
```

Source: Git Process chapter ([smoljames.com][1])

---

# Slide 33 — End-to-End Workflow Lab

## Exercise

1. Create GitHub repository
2. Clone repository
3. Create feature branch
4. Add new file
5. Commit changes
6. Push branch
7. Open pull request
8. Merge changes
9. Pull latest main branch

Goal:

Experience the complete Git workflow from start to finish.

---

# Slide 34 — Key Takeaways

### Remember

* Git tracks project history
* GitHub hosts repositories online
* Branches enable safe collaboration
* Commits are project snapshots
* Pull Requests manage integration
* Merge conflicts are normal
* Security starts with `.env` and `.gitignore`

> Git is not just version control—it is the foundation of modern collaborative software engineering.

References:

* [Smoljames Git & GitHub Notes](https://smoljames.com/notes/git_github?utm_source=chatgpt.com)
* [GitHub Official Website](https://github.com?utm_source=chatgpt.com)
* [Git Official Documentation](https://git-scm.com/doc?utm_source=chatgpt.com)

[1]: https://smoljames.com/notes/git_github?utm_source=chatgpt.com "Smoljames ⋅ Notes"
