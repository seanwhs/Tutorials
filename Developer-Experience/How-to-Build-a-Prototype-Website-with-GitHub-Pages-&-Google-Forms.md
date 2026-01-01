# 🧠 Tutorial: Building a Prototype Website with GitHub Pages + Google Forms

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

> How do we deliver content and collect data **without building a backend**?

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

**Implication:** Any dynamic behavior or data persistence must leverage **external services** like Google Forms.

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

1. Create your form on **[Google Forms](https://forms.google.com)**
2. Include necessary fields: Name, Email, Interests, Feedback
3. Link responses to a Google Sheet
4. Copy the `<iframe>` embed code:

```html
<iframe src="https://docs.google.com/forms/d/e/.../viewform?embedded=true" width="100%" height="800" frameborder="0"></iframe>
```

> 💡 Tip: Use `width=100%` for responsive design.

---

## 📌 Section 6 — Phase 2A: HTML-Based GitHub Pages

1. Create a **public repository**
2. Add `index.html` and include iframe
3. Enable Pages: **Settings → Pages → Deploy from main**

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
2. View and export submissions in real-time

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

## 📌 Section 11 — Security & Operational Benefits (Professional)

### Security Advantages

* **No secrets in repo:** No credentials or API keys are exposed.
* **Minimal attack surface:** Static pages cannot be exploited.
* **Data isolation:** Google manages access to form responses.
* **Spam protection:** Enable Google Forms validation and reCAPTCHA.

### Operational Benefits

* **Zero server maintenance:** No backend to patch or monitor.
* **Global availability:** Pages served via GitHub CDN.
* **Rapid iteration:** Updates take effect instantly after commit.
* **Scalable MVP:** Handles hundreds to thousands of form submissions.
* **Audit & Logging:** Google Sheets maintains submission timestamps for transparency.

### Caveats

* Avoid storing sensitive production data.
* Restrict Google Sheet access to authorized personnel.
* Monitor submission limits for high-traffic scenarios.

---

## 📌 Section 12 — Pro Tips, Automation & UX Enhancements (Professional)

### 1. Zapier / Automation

* Trigger workflows on form submissions (e.g., emails, Slack notifications, CRM updates).

### 2. Google Apps Script

* Automate Sheet operations, calculations, or email responses.
* Example: Auto-generate a personalized welcome email.

### 3. GitHub Actions

* Automate static page updates when data changes or content is committed.
* Example: Regenerate a leaderboard or statistics panel hourly.

### 4. JavaScript Enhancements

* Add dynamic behavior within HTML or Markdown pages.
* Examples: countdowns, conditional hints, AI-generated feedback, pre-filled form entries.

### 5. Invisible Integration Hack (UX)

* Use pre-filled URLs: `?entry.12345=source_abc`
* Automatically track referral sources or user IDs.
* Reduces typing friction and improves user experience.

### 6. Live Data Visualization (Social Proof)

* Publish Google Sheet as CSV → Fetch via JavaScript → Render live charts using Google Charts or Tableau Public.
* Shows percentages, counts, or progress in real-time.

### 7. Progressive Enhancement / Hybrid Bridge

* Introduce serverless functions (Netlify Functions or GitHub Actions Cron Jobs)
* Update stats, leaderboards, or summaries automatically without full backend.

### 8. Semantic SEO

* Include JSON-LD Schema in `<head>`: Course, SoftwareApplication, Organization
* Improves discoverability and enables rich results in search engines.

### Best Practices

* Keep automation loosely coupled; each service has a single responsibility.
* Test workflows thoroughly before production.
* Document automation and scripts for maintainers.

---

## 📌 Section 13 — Trade-offs & Limitations

* Strengths: fast, free, low-maintenance, easy iteration
* Limitations: limited UI control, Google branding, no advanced logic, scaling limits

---

## 📌 Section 14 — Decision Trees (“If X, do Y”)

```
If data collection only → Google Forms
If authentication/personalization → Django Backend
If content-only → Markdown + Jekyll
If custom UI → HTML
High traffic → Backend migration
Sensitive data → Django migration
```

---

## 📌 Section 15 — Architecture Comparison (ASCII Diagram)

```
MVP (Forms): User → GitHub Pages → Google Form → Google Sheets
Custom Backend: User → Django Views → Database → Admin Dashboard
```

---

## 📌 Section 16 — Common Mistakes & Debugging

* Missing `index.html` or Jekyll front matter
* `_config.yml` misconfigurations
* iframe URL not HTTPS
* Theme conflicts
* Branch not set to `main`

---

## 📌 Section 17 — Security Threat Model

| Threat           | Mitigation                      |
| ---------------- | ------------------------------- |
| Secret leakage   | Never commit `.env` or API keys |
| Spam submissions | Use Form validation / reCAPTCHA |
| Data privacy     | Keep Sheets private             |
| Supply-chain     | Avoid untrusted Jekyll plugins  |

---

## 📌 Section 18 — Migration Playbook (Forms → Django Backend)

1. Setup Django project & app
2. Create models and forms
3. Implement views, URLs, and templates
4. Replace iframe with native Django form
5. Admin access & database migrations
6. Deploy with HTTPS on Heroku/Render/VPS

---

## 📌 Section 19 — Retention Summary

* GitHub Pages = static publishing
* Jekyll = Markdown → HTML engine
* Google Forms = backend replacement
* Google Sheets = MVP database
* Django = full backend for control & scalability

> **Static content + external services = zero-backend MVP; migrate to Django as complexity grows. Enhanced UX, automation, and visualization bridge the gap to professional applications.**
