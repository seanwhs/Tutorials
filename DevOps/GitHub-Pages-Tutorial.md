# 📘 GitHub Pages Tutorial

*A Deep Conceptual and Practical Guide to Static Publishing with GitHub*

**Edition:** 1.0
**Audience:** Beginner → Intermediate
**Primary Goal:** Confidently publish static sites, documentation, and frontend builds using **GitHub Pages**
**Secondary Goal:** Build an **unbreakable mental model** of how GitHub Pages, Markdown, Jekyll, and CI/CD actually work together

---

# 1️⃣ The Only Mental Model That Matters

Before learning *how* to use GitHub Pages, you must understand *what it fundamentally is*.

> **GitHub Pages is a static file publishing system driven by Git commits.**

That’s it.
Everything else is an implementation detail.

---

## What “Static” Truly Means (Re-explained Carefully)

When we say *static*, we mean:

* Files are **served exactly as stored**
* There is **no server-side execution**
* There is **no runtime environment**
* All logic runs **after download**, in the browser

This has very concrete consequences:

❌ No Python, Ruby, PHP, Node
❌ No databases
❌ No APIs running on GitHub

✅ HTML
✅ CSS
✅ JavaScript
✅ Images, fonts, media
✅ Files generated *before* deployment

---

## The Universal Publishing Pipeline (Memorize This)

Every GitHub Pages site — without exception — reduces to this:

```
Git Repository
      ↓
Static Files
      ↓
Public Website (CDN)
```

GitHub Pages does **not** care:

* how files were written
* what language they came from
* whether they started as Markdown, JSX, or HTML

It only cares about **the final static files**.

---

# 2️⃣ GitHub Pages Has Three Publishing Modes (Not One)

This is the most misunderstood part of GitHub Pages.

GitHub Pages does **not** have a single workflow.
It supports **three distinct publishing models**.

Understanding this removes 90% of confusion.

---

## Mode 1 — Raw Static Files (HTML / CSS / JS)

You write HTML directly.

```
index.html
style.css
script.js
```

GitHub Pages:

* Does nothing
* Touches nothing
* Serves files as-is

```
HTML → Git Push → GitHub Pages → Browser
```

No processing.
No transformation.
Pure hosting.

---

## Mode 2 — Markdown → Jekyll → HTML (Documentation Sites)

You write **Markdown**, not HTML.

```
index.md
README.md
docs.md
```

But browsers **cannot render Markdown**.

So something must convert it.

That “something” is **Jekyll**.

```
Markdown → Jekyll → HTML → GitHub Pages → Browser
```

This happens **automatically** on GitHub’s servers.

---

## Mode 3 — Framework Build → Deploy (React / Vue / Svelte)

You write **source code**, not deployable files.

```
.jsx
.tsx
.vue
```

You must build first:

```
Source → Build → Static Files → GitHub Pages
```

GitHub Actions performs the build.

---

## 🔁 Same Destination, Different Paths

All three modes end here:

```
Static HTML / CSS / JS
        ↓
GitHub Pages CDN
```

GitHub Pages **only ever serves static files**.

---

# 3️⃣ The Repository Is the Deployment Engine

A GitHub repository is not just storage.

It is:

* The **deployment trigger**
* The **version history**
* The **audit log**
* The **automation entry point**

Without Git, GitHub Pages cannot function.

---

## Local vs Remote Reality

```
Your Computer
┌───────────────────┐
│ Files             │
│ git commit        │
└─────────┬─────────┘
          |
          | git push
          v
GitHub Repository
┌───────────────────┐
│ main branch       │
│ Version history  │
└─────────┬─────────┘
          |
          v
GitHub Pages
```

A **push is a deployment event**.

---

# 4️⃣ Static HTML Publishing (Baseline Case)

This is the simplest form and the baseline for everything else.

---

## Minimal Structure

```
my-site/
├── index.html
├── style.css
└── script.js
```

`index.html` is mandatory because browsers request `/`.

---

## Why This Matters Conceptually

This mode teaches you:

* What GitHub Pages does **not** do
* That no magic exists
* That deployment = publishing files

Every other mode builds on this understanding.

---

# 5️⃣ Markdown-Only Repositories (Integrated, Not “Extra”)

Now we introduce Markdown — **properly**.

---

## Markdown Is Authoring Format, Not Deployment Format

Markdown exists to help **humans write**.

Browsers do **not** understand Markdown.

So this will NOT work:

```
# My Docs
This is Markdown
```

Browsers understand only:

* HTML
* CSS
* JavaScript

Therefore, conversion is mandatory.

---

## Jekyll’s Exact Role (Explained Slowly)

**Jekyll is a static site generator.**

It:

* Reads Markdown files
* Converts them to HTML
* Applies templates and themes
* Outputs static files

Crucially:

> Jekyll runs **once at build time**, not at runtime.

---

## GitHub Pages + Jekyll (The Hidden Superpower)

GitHub Pages has **Jekyll built in**.

This means:

* You do NOT install Ruby
* You do NOT run Jekyll locally
* You do NOT write a build script

GitHub does it for you.

---

## Minimal Markdown-Only Repository

```
my-docs/
└── index.md
```

```md
# My Documentation Site

Welcome to my GitHub Pages docs.
```

Enable Pages → done.

GitHub will:

1. Detect Markdown
2. Run Jekyll
3. Generate HTML
4. Publish

---

## What Actually Happens Behind the Scenes

```
index.md
   |
   v
Jekyll Processor
   |
   v
index.html (generated)
   |
   v
GitHub Pages CDN
```

You never see the HTML — but it exists.

---

## Re-Explaining This Differently (Important)

Think of Markdown as **source code**.

Think of HTML as **compiled output**.

Jekyll is the **compiler**.

GitHub Pages hosts the compiled output.

---

# 6️⃣ Jekyll Themes (Zero-HTML Websites)

Jekyll themes allow you to create full websites **without writing HTML**.

---

### `_config.yml`

```yaml
theme: minima
title: My Docs
description: Markdown-powered site
```

Now your Markdown gets:

* Layout
* Navigation
* Styling
* Responsiveness

Still static.
Still Git-based.
Still free.

---

# 7️⃣ When (and Why) to Disable Jekyll

Sometimes you want **raw file serving**.

Create:

```
.nojekyll
```

This tells GitHub Pages:

> “Do not transform anything.”

Used when:

* Hosting raw assets
* Serving pre-built files
* Avoiding Jekyll conventions

---

# 8️⃣ Re-Explaining the Three Modes (Final Pass)

Let’s lock this in.

---

### Mode 1 — HTML Sites

```
HTML → GitHub Pages → Browser
```

You control everything.

---

### Mode 2 — Markdown Docs

```
Markdown → Jekyll → HTML → GitHub Pages → Browser
```

GitHub controls the conversion.

---

### Mode 3 — Framework Apps

```
Source → Build → HTML → GitHub Pages → Browser
```

You control the build.

---

## Same Truth, Every Time

GitHub Pages:

* Does not run code
* Does not host servers
* Does not execute backends

It **publishes static files**.

---

# 9️⃣ The Unified Mental Model (Final)

```
Authoring Format
   |
   | (optional build / conversion)
   v
Static Files
   |
   v
Git Commit
   |
   v
GitHub Pages
   |
   v
Public Website
```

Whether you start with:

* HTML
* Markdown
* React

You always end with:

**Static files served globally via CDN.**

---

## 🔚 Final Takeaway (Burn This In)

GitHub Pages turns Git repositories into websites.

* Git is the trigger
* Static files are the output
* Browsers do the execution
* GitHub does the hosting

Once you understand this,
**nothing about GitHub Pages is mysterious ever again.**

---

