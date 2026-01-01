# 🧠 Enhanced Tutorial: Building a Prototype Website with GitHub Pages + Google Forms

### (Including Markdown-Only Repos, Decision Trees, Security, and Backend Migration)

> **Purpose (Knowledge Retention / Textbook-Style Reference)**
> This document is a **comprehensive, textbook-style tutorial** bridging the gap between **no-code prototyping** and **professional software architecture**. It explains **how and why** to build a *zero-backend prototype website* using GitHub Pages and Google Forms, including Markdown-only sites with Jekyll, decision-making frameworks, security considerations, and migration to a Django backend.

Creating a prototype website using GitHub Pages and Google Forms allows you to launch a **Minimum Viable Product (MVP)** quickly and without hosting costs.

Based on the **AI for Everyone — Your New Superpower** project, this tutorial documents a **complete, repeatable process**, showing how to evolve from a zero-backend MVP to a full Django backend.

---

## 📌 Section 1 — The Problem This Architecture Solves

Traditional web apps require:

* Frontend (HTML/CSS/JS)
* Backend (server, APIs)
* Database (persistent storage)

For early-stage ideas, workshops, or experiments, this is often unnecessary overhead.

### MVP Goals

* Validate interest quickly
* Collect sign-ups or feedback
* Publish content publicly
* Avoid infrastructure complexity

### Constraints

* Limited time
* Minimal budget
* No desire to maintain servers

**Key Question:**

> How can we publish content and collect data **without building a backend**?

---

## 📌 Section 2 — Core Constraints of GitHub Pages

### GitHub Pages Provides

* Static hosting of repository files
* Global CDN delivery

### GitHub Pages Cannot

* Run server-side code
* Handle custom form submissions
* Persist data

Any dynamic functionality must be delegated to **external services**.

---

## 📌 Section 3 — Architectural Mental Model

### Responsibility Split

* **GitHub Pages** → Presentation Layer
* **Google Forms** → Logic & Validation Layer
* **Google Sheets** → Persistent Storage Layer

### Architecture Diagram

```
User Browser
   │
   ▼
GitHub Pages (Static / Jekyll)
   │
   └── iframe embed
          │
          ▼
     Google Forms
          │
          ▼
     Google Sheets
```

Insight: The repository never handles sensitive data, safe for public hosting.

---

## 📌 Section 4 — Repository Models for GitHub Pages

### Model A — HTML-Based

```
repo/
├── index.html
├── style.css
└── assets/
```

* Full control over CSS and layout

### Model B — Markdown-Only (Jekyll)

```
repo/
├── index.md
├── README.md
└── _config.yml
```

* Markdown converted to HTML automatically
* Supports raw HTML (iframe embeds)

---

## 📌 Section 5 — Phase 1: Build the "Backend" (Google Forms)

1. Build form on **[forms.google.com](https://forms.google.com)**
2. Add required fields (Name, Email, Interest, Feedback)
3. Link responses to **Google Sheets**
4. Copy the `<iframe>` embed code

```html
<iframe src="https://docs.google.com/forms/d/e/.../viewform?embedded=true" width="100%" height="800" frameborder="0"></iframe>
```

> 💡 Tip: Set `width=100%` for mobile responsiveness.

---

## 📌 Section 6 — Phase 2A: Publish HTML-Based Site

1. Create a **Public Repo**
2. Add `index.html` with container and iframe
3. Enable GitHub Pages: **Settings → Pages → Deploy from main**

URL: `https://username.github.io/repo-name/`

---

## 📌 Section 7 — Phase 2B: Publish Markdown-Only Site (Jekyll)

Example `index.md`:

```md
---
layout: default
title: AI Prototype
---

# Welcome to AI Superpower Project

<iframe src="https://docs.google.com/forms/d/e/.../viewform?embedded=true" width="100%" height="600px"></iframe>
```

Enable GitHub Pages as above.

---

## 📌 Section 8 — Phase 3: Connect to Data (Google Sheets)

1. Open Google Form → **Responses → Link to Sheets**
2. View submissions in real time

---

## 📌 Section 9 — Responsiveness & UX

```html
<div class="form-container">
  <iframe src="..."></iframe>
</div>
```

```css
.form-container {
  position: relative;
  width: 100%;
  padding-bottom: 150%;
  height: 0;
}
.form-container iframe {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
}
```

---

## 📌 Section 10 — End-to-End Data Flow

```
User submits form
   ↓
Google validates
   ↓
Google writes to Sheets
   ↓
You analyze/export data
```

---

## 📌 Section 11 — Security & Operational Benefits

* No secrets stored in repo
* Minimal attack surface
* Safe for public repos

---

## 📌 Section 12 — Pro Tips & Automation

* **Zapier** triggers on submission
* **Google Apps Script** for automation
* **GitHub Actions** for workflows

---

## 📌 Section 13 — Trade-offs & Limitations

* **Strengths:** Fast, free, low-maintenance
* **Limitations:** Limited UI, Google branding, no advanced logic

---

## 📌 Section 14 — Decision Trees ("If X, do Y")

**Architecture Choice:**

```
If only collecting emails → Google Forms
If authentication needed → Django Backend
```

**Deployment Model:**

```
Content-only → Markdown + Jekyll
Custom UI → HTML
```

**Scaling Triggers:**

```
High traffic → Consider backend migration
Sensitive data → Migrate to Django
```

---

## 📌 Section 15 — Architecture Comparison (ASCII Diagram)

**MVP (Google Forms)**

```
User → GitHub Pages → Google Form → Google Sheets
```

**Custom Backend (Django)**

```
User → Django Views → Database → Admin Dashboard
```

---

## 📌 Section 16 — Common Mistakes & Debugging GitHub Pages

* Blank page: missing `index.html` or Jekyll front matter
* `_config.yml` misconfigurations
* iframe URL not HTTPS
* Theme conflicts
* Branch not set to `main`

---

## 📌 Section 17 — Security Threat Model

| Threat           | Mitigation                       |
| ---------------- | -------------------------------- |
| Secret leakage   | Never commit `.env` or API keys  |
| Spam submissions | Use Form validation or reCAPTCHA |
| Data privacy     | Keep Sheets private              |
| Supply-chain     | Avoid untrusted Jekyll plugins   |

---

## 📌 Section 18 — Migration Playbook (Forms → Django Backend)

1. **Setup Django Project**

```
django-admin startproject ai_mvp
cd ai_mvp
python manage.py startapp registration
```

2. **Create Models**

```python
class Signup(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    interest = models.TextField()
```

3. **Create Forms**

```python
from django import forms
class SignupForm(forms.ModelForm):
    class Meta:
        model = Signup
        fields = ['name', 'email', 'interest']
```

4. **Views & URLs**

```python
from django.shortcuts import render, redirect
from .forms import SignupForm

def signup_view(request):
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('thank_you')
    else:
        form = SignupForm()
    return render(request, 'signup.html', {'form': form})
```

5. **Templates**: Move HTML from GitHub Pages → Django `templates/`
6. **Admin & DB**: `makemigrations` → `migrate`, use Django Admin
7. **Deployment**: Host on Heroku/Render/VPS, enable HTTPS

Completes MVP → Django migration.

---

## 📌 Section 19 — Retention Summary

* GitHub Pages = static publishing
* Jekyll = Markdown → HTML engine
* Google Forms = backend replacement
* Google Sheets = MVP database
* Django = full backend for control & scalability

> **Static content + external services = zero-backend MVP; migrate to Django as complexity grows**
