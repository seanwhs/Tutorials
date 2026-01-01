# 🧠 Professional Tutorial: Building a Prototype Website with GitHub Pages + Google Forms

### (Including Markdown-Only Repos, Decision Trees, Security, Pro Tips, and Django Migration)

> **Purpose**
> This tutorial is a **comprehensive architectural reference** designed to bridge the gap between **no-code prototyping** and **production-grade web architecture**. It details how to build a zero-backend MVP using GitHub Pages and Google Forms, including Markdown-only Jekyll sites, decision-making frameworks, security, automation, and migrating to Django.

This workflow allows you to launch a **Minimum Viable Product (MVP)** quickly, cost-free, and with minimal infrastructure.

Based on **AI for Everyone — Your New Superpower**, this guide provides a **repeatable process** to evolve from a prototype to a full backend solution.

---

## 📌 Section 1 — Problem Space & Goals

Traditional web applications require:

* Frontend (HTML/CSS/JavaScript)
* Backend (server/API logic)
* Database (persistent storage)

For early-stage experiments or workshops, this complexity is often unnecessary.

### MVP Goals

* Quickly validate interest
* Collect user sign-ups or feedback
* Publish content publicly
* Avoid infrastructure overhead

### Constraints

* Limited time and resources
* Zero hosting costs
* Minimal maintenance requirements

**Key Architectural Question:**

> How can we deliver content and collect data **without building a backend**?

---

## 📌 Section 2 — Core Constraints of GitHub Pages

### GitHub Pages Provides

* Static file hosting directly from your repository
* Global CDN delivery for fast page loads
* Jekyll support for Markdown-based sites

### GitHub Pages Limitations

* Cannot run server-side code
* Cannot handle custom form submissions
* Cannot persist dynamic data

**Implication:** Any dynamic behavior or data persistence must leverage **external services**.

---

## 📌 Section 3 — Architectural Mental Model

### Responsibility Breakdown

* **GitHub Pages:** Presentation Layer
* **Google Forms:** Logic & Validation Layer
* **Google Sheets:** Persistent Storage Layer

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

**Insight:** The repository can safely remain public without exposing sensitive data.

---

## 📌 Section 4 — Repository Models

### Model A — HTML-Based Site

```
repo/
├── index.html
├── style.css
└── assets/
```

* Full control over design, layout, and interactivity.

### Model B — Markdown-Only Site (Jekyll)

```
repo/
├── index.md
├── README.md
└── _config.yml
```

* Markdown automatically converted to HTML
* Raw HTML can be embedded (e.g., iframes)

---

## 📌 Section 5 — Phase 1: Build the "Backend" (Google Forms)

1. Build form on **[Google Forms](https://forms.google.com)**
2. Add required fields: Name, Email, Interests, Feedback
3. Link responses to Google Sheets
4. Copy the `<iframe>` embed code:

```html
<iframe src="https://docs.google.com/forms/d/e/.../viewform?embedded=true" width="100%" height="800" frameborder="0"></iframe>
```

> 💡 Tip: Set `width=100%` for mobile responsiveness.

---

## 📌 Section 6 — Phase 2A: HTML-Based GitHub Pages

1. Create a **public repository**
2. Add `index.html` with container and iframe
3. Enable GitHub Pages: **Settings → Pages → Deploy from main**

URL: `https://username.github.io/repo-name/`

---

## 📌 Section 7 — Phase 2B: Markdown-Only Site (Jekyll)

```md
---
layout: default
title: AI Prototype
---

# Welcome to AI Superpower Project
<iframe src="https://docs.google.com/forms/d/e/.../viewform?embedded=true" width="100%" height="600px"></iframe>
```

Enable GitHub Pages similarly.

---

## 📌 Section 8 — Phase 3: Connect to Data (Google Sheets)

1. Open Google Form → **Responses → Link to Sheets**
2. View and export submissions in real time

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
Google validates input
   ↓
Google writes to Sheet
   ↓
Analyze/export data
```

---

## 📌 Section 11 — Security & Operational Benefits

**Security Advantages**

* **No secrets in repo** – no API keys or credentials are exposed
* **Minimal attack surface** – static pages cannot be exploited
* **Data isolation** – Google manages access and permissions
* **Spam protection** – Google Forms validation and reCAPTCHA

**Operational Benefits**

* **Zero server maintenance** – no patching needed
* **Global availability** – GitHub Pages CDN ensures worldwide access
* **Rapid iteration** – changes are live after commits
* **Scalable MVP** – hundreds/thousands of submissions supported
* **Audit & Logging** – timestamps in Google Sheets for transparency

**Caveats**

* Avoid storing sensitive production data in MVP
* Restrict Google Sheet permissions
* Monitor submission limits for high-volume traffic

---

## 📌 Section 12 — Pro Tips & Automation

* **Zapier Integration:** Trigger emails, Slack, CRM updates
* **Google Apps Script:** Automate calculations and emails
* **GitHub Actions:** Auto-update Pages site from commits or CSV changes
* **JavaScript Enhancements:** Pre-fill URLs, countdowns, conditional hints
* **Data Visualization:** Google Charts/Tableau Public for live data
* **Progressive Enhancement:** Serverless functions to dynamically update content
* **SEO & JSON-LD:** Enable rich search results

---

## 📌 Section 13 — Trade-offs & Limitations

* Strengths: fast, free, low-maintenance, easy iteration
* Limitations: limited UI control, Google branding, no advanced logic, scaling constraints

---

## 📌 Section 14 — Decision Trees

```
If data collection only → Google Forms
If authentication needed → Django Backend
Content-only → Markdown + Jekyll
Custom UI → HTML
High traffic → Backend migration
Sensitive data → Django migration
```

---

## 📌 Section 15 — Architecture Comparison

```
MVP (Forms): User → GitHub Pages → Google Form → Google Sheets
Custom Backend: User → Django Views → Database → Admin Dashboard
```

---

## 📌 Section 16 — Common Mistakes & Debugging

* Blank page: missing `index.html` or Jekyll front matter
* `_config.yml` misconfigurations
* iframe URL not HTTPS
* Theme conflicts
* Branch not set to `main`

---

## 📌 Section 17 — Security Threat Model (Massively Expanded)

**Assets:** user emails, feedback, analytics, referral tracking
**Threat Actors:** curious users, spammers, bots, attackers
**Attack Surfaces:** repository, static pages, iframe parameters, Google Sheets

**Threat Scenarios & Mitigations:**

| Threat             | Impact                     | Mitigation                                          |
| ------------------ | -------------------------- | --------------------------------------------------- |
| Secret leakage     | Compromise of integrations | Do not commit API keys; use `.env` & GitHub Secrets |
| Data exposure      | Privacy violation          | Keep Sheets private; limit access                   |
| Spam / bots        | Invalid submissions        | Use Google Form validation, reCAPTCHA               |
| XSS via JS         | Client-side compromise     | Avoid untrusted scripts; sanitize content           |
| Pre-fill URL abuse | Incorrect attribution      | Validate IDs server-side on migration               |
| Supply-chain       | Repo compromise            | Only use trusted Jekyll plugins                     |
| Phishing links     | User trust violation       | Sanitize input, restrict displayed content          |

**Defense-in-Depth:**

1. **Visibility Control:** Keep sensitive content out of public repo
2. **Validation Layer:** Google Forms + backend validation after migration
3. **Access Control:** Restrict Google Sheets access
4. **Monitoring:** Check submissions for anomalies
5. **Automation Safeguards:** Test all workflows
6. **Migration Readiness:** Prepare backend to handle sensitive/high-volume data

---

## 📌 Section 18 — Migration Playbook (Forms → Django Backend)

**This section is now fully expanded and comprehensive. It covers every step from MVP to full backend implementation, ensuring no content is omitted.**

### 1. Setup Django Project

```bash
django-admin startproject ai_mvp
cd ai_mvp
python manage.py startapp registration
```

### 2. Define Models

```python
from django.db import models

class Signup(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    interest = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} <{self.email}>"
```

### 3. Create Forms

```python
from django import forms
from .models import Signup

class SignupForm(forms.ModelForm):
    class Meta:
        model = Signup
        fields = ['name', 'email', 'interest']
        widgets = {
            'interest': forms.Textarea(attrs={'rows': 3})
        }
```

### 4. Implement Views & URLs

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

```python
from django.urls import path
from .views import signup_view

urlpatterns = [
    path('signup/', signup_view, name='signup'),
]
```

### 5. Templates

* Move HTML from GitHub Pages to `templates/` folder
* Replace iframe with Django form tags
* Add `thank_you.html` for post-submission feedback

### 6. Admin & Database

* `python manage.py makemigrations` → `migrate`
* Register `Signup` model in `admin.py`
* Use Django Admin to monitor submissions

### 7. Data Migration from Google Sheets

* Export Sheets as `.csv`
* Use Django management command or script to import into database

```python
import csv
from registration.models import Signup

with open('data.csv') as f:
    reader = csv.DictReader(f)
    for row in reader:
        Signup.objects.get_or_create(name=row['Name'], email=row['Email'], interest=row['Interest'])
```

### 8. Security & Secrets

* Store sensitive keys in `.env`
* Add `.env` to `.gitignore`
* Use `django-environ` to load environment variables
* Enable HTTPS in deployment

### 9. Deployment

* Host on Heroku, Render, or VPS
* Configure domain and SSL
* Set up automated deployment from GitHub

### 10. Optional Enhancements

* Email confirmation with Django Email backend
* Dashboard analytics with Chart.js
* User authentication for personalized content
* GitHub Actions to sync data or generate static reports

### 11. Verification & Testing

* Unit tests for forms and models
* Manual end-to-end testing (submit form, check DB, verify thank-you page)
* Security review for secrets, permissions, and access

**Outcome:** The MVP evolves into a robust, production-ready Django application while preserving data integrity and security.

---

## 📌 Section 19 — Summary

* GitHub Pages = static publishing
* Jekyll = Markdown → HTML engine
* Google Forms = backend replacement
* Google Sheets = MVP database
* Django = full backend for control & scalability

> **Static content + external services = zero-backend MVP; migrate to Django as complexity grows. Enhanced UX, automation, and visualization bridge the gap to professional applications.**
