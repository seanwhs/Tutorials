## Mastering Version Control: Git, GitHub, and GitHub Pages for Professional Development

A comprehensive, code-heavy, 6-part tutorial series written from a **Principal Software Engineer's perspective**. This series treats Git not as a backup tool, but as the **orchestration layer** for how professional software evolves over time — and treats GitHub Pages / Vercel as the deployment targets that make your work real and visible.

### Who this is for
Beginners through intermediate developers who can already write code (HTML/CSS/JS, or any language) but have never used version control professionally — or have used `git add . && git commit -m "stuff"` and want to actually understand what they're doing and why.

### Tooling (100% free/open-source)
- **Git CLI** (the actual tool — not a GUI substitute; GUIs hide the mental model you need)
- **GitHub** (remote hosting, PRs, code review, Pages, Actions)
- **VS Code** (editor + integrated terminal + built-in Git diff viewer)
- **GitHub Pages** (free static hosting)
- **Vercel** (free tier — for dynamic/full-stack apps, introduced in Part 6)

### Series Structure

| Part | Title | Core Question Answered |
|---|---|---|
| 1 | The Git Philosophy | What *is* a repository, and why do we commit in small pieces? |
| 2 | Branching & Merging | How do I work on a feature without breaking `main`? |
| 3 | The GitHub Workflow | How do teams collaborate safely through Pull Requests? |
| 4 | Deployment 101 — GitHub Pages | How do I turn a folder into a live website for free? |
| 5 | Time Travel & Recovery | How do I undo mistakes without panicking? |
| 6 | Professional Pipelines | How do senior engineers rebase, and how do I graduate to Vercel CI/CD? |
| Appendices | Cheat Sheet / Troubleshooting / Deployment Matrix | Fast lookup references |

Each part includes:
1. **Concept Explanation** — the mental model, in plain English, with diagrams-in-text
2. **Implementation** — exact, copy-typeable terminal command sequences
3. **Practice Exercise** — a concrete task ("Step 1: Deploy a static landing page...")
4. **Solution & Explanation** — worked answer with reasoning

### Prerequisites Setup (do this before Part 1)

```bash
# 1. Check if Git is installed
git --version
# If not installed: https://git-scm.com/downloads (Windows/Mac/Linux installers)

# 2. Set your identity — Git stamps every commit with this, permanently
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# 3. (Recommended) Set VS Code as your default Git editor/diff tool
git config --global core.editor "code --wait"

# 4. Set the default branch name for new repos to "main" (modern standard)
git config --global init.defaultBranch main

# 5. Create a free GitHub account at https://github.com if you don't have one

# 6. Verify your config
git config --list
```

> **Note on SSH vs HTTPS:** In Part 3 we'll set up SSH keys or a Personal Access Token for pushing to GitHub. You don't need this yet for Part 1 (local-only work).

### Notes Naming Convention
All notes in this series are titled with the prefix **"Git Mastery - "** for easy searching:
- Git Mastery - INDEX (Start Here)
- Git Mastery - Part 1: The Git Philosophy
- Git Mastery - Part 2: Branching & Merging
- Git Mastery - Part 3: The GitHub Workflow
- Git Mastery - Part 4: Deployment 101 - GitHub Pages
- Git Mastery - Part 5: Time Travel & Recovery
- Git Mastery - Part 6: Professional Pipelines
- Git Mastery - Appendices (Cheat Sheet, Troubleshooting, Deployment Matrix)

### The Big Idea That Ties This Series Together

> **Git history is living documentation.** A well-maintained commit log tells the story of *why* code looks the way it does — better than comments, better than a changelog someone forgot to update. Every part of this series reinforces one habit: **make history worth reading.** Atomic commits, descriptive messages, clean branches, and reviewed PRs aren't bureaucracy — they're how a project remains understandable six months (or six hires) later.
