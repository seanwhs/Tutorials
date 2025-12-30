# 🧩 Sean Wong's Personal Programming Tutorials

Welcome! This is a **personal collection of programming tutorials**, curated **for myself** to **retain knowledge** across frontend, backend, full‑stack, and general programming topics.
It covers **Python, Django, full‑stack web development, JavaScript, HTML/CSS, architecture patterns, and DevOps practices**.

> This repository acts as a **personal reference, learning map, and cheat sheet** for building real apps, understanding architecture, and mastering software design patterns.

---

## **📚 Purpose**

* **Knowledge Retention:** Tutorials reinforce concepts I’ve learned.
* **Reference Hub:** Quickly find examples, patterns, and architectures.
* **Hands‑on Practice:** Includes code snippets, mini‑projects, and exercises.
* **Full‑Stack Integration:** Shows end‑to‑end flow from user events to backend data persistence.

**Core Principles:**

* **Separation of Concerns:** Frontend, backend, and database layers are distinct.
* **Modularity & Reusability:** Components and services are reusable.
* **Event‑Driven / Reactive:** Observer patterns used for updates.
* **DRY (Don’t Repeat Yourself):** Shared logic placed in services/utilities.

---

## **🗂 Repository Overview**

```
Tutorials/
├── Architecture/      # Software architecture diagrams, patterns, and best practices
├── DevOps/            # Deployment, CI/CD, monitoring, automation
├── Django/            # Django apps, models, views, templates, signals
├── Full‑Stack/        # Full‑stack projects (frontend + backend)
├── HTML‑CSS/          # Layouts, styling, responsive design, UI/UX
├── JavaScript/        # JS fundamentals, advanced patterns, utilities
├── JS‑Labs/           # Mini projects and experiments (Browser focused)
├── PyInsight/         # Data handling, utilities, notebooks
├── Python/            # Python fundamentals, scripts, tools
└── README.md
```

*(Directory list pulled from your GitHub — no `DRF/` or `React/` folders exist)* ([GitHub][1])

---

## **🌐 Full‑Stack Architecture & Patterns**

This diagram shows **how a full‑stack app works**, from user interaction to database, integrating frontend, backend, and patterns:

```
🔴 User / Client
+------------------------------------------------+
| Browser / SPA                                  |
| User Events: click, input, navigation          |
| Patterns: Observer, Event‑driven, Pub/Sub      |
+------------------------------------------------+
|
v

💙 Frontend Component Layer
+------------------------------------------------+
| UI Components (JS/HTML/CSS / frameworks)       |
| Patterns: Component abstraction, modular UI    |
+------------------------------------------------+
|
v

💙 State & Service Layer
+------------------------------------------------+
| Local state, API service adapters (fetch/axios)|
| Utilities: format, parse, validate              |
| Patterns: Adapter / Facade                     |
+------------------------------------------------+
|
v

💙 Data Layer / API Integration
+------------------------------------------------+
| REST APIs / Backend endpoints (Django)         |
| Patterns: Adapter / Facade                     |
+------------------------------------------------+
|
v

💚 Django Views / Controllers
+------------------------------------------------+
| Function/Class‑based views                     |
| Handles routing, input, auth                   |
| Patterns: MVC / Dispatch                       |
+------------------------------------------------+
|
v

💚 Django Service / Business Logic
+------------------------------------------------+
| Encapsulated in modules                        |
| Patterns: Service layer, reusable logic        |
+------------------------------------------------+
|
v

🟨 Django Models / ORM
+------------------------------------------------+
| Tables & Relations                             |
| Signals for hooks (post_save, pre_save)        |
| Patterns: Observer, Events                      |
+------------------------------------------------+
|
v

🟨 Database Layer
+------------------------------------------------+
| PostgreSQL / MySQL / SQLite                    |
| Patterns: Singleton (connection pool)          |
+------------------------------------------------+
|
v

🔴 Client UI Updated
```

*(This is a general full‑stack flow — tailored to your projects.)*

---

## **🧠 Patterns Applied per Layer**

| Layer                    | Component / Tool           | Patterns / Concepts    |
| ------------------------ | -------------------------- | ---------------------- |
| User / Client            | Browser / UI               | Observer, Event‑driven |
| Frontend Component Layer | JS / Templates             | Modular UI             |
| State & Service Layer    | JS Services / API Adapters | Adapter / Facade       |
| Backend Controllers      | Django Views               | MVC / Dispatch         |
| Service / Logic Layer    | Backend Modules            | Service Layer          |
| Data Layer (ORM)         | Django Models              | Observer / Signals     |
| Database                 | PostgreSQL / SQLite        | Singleton / Repository |

---

## **📌 Best Practices**

* Keep **components and services small and single‑responsibility**.
* Encapsulate API calls in **service/adapters** to decouple frontend and backend.
* Use **consistent folder structure** for scalability and readability.
* Apply **Observer / Event‑driven patterns** for reactive systems.
* Document **patterns in each module for fast recall**.

---

## **🗺 Learning Flow**

```
Python Fundamentals → Django → Full‑Stack Projects → DevOps & Deployment
```

---

## **📖 Table of Contents**

### 1. Architecture

* [Architecture Folder](Architecture/README.md)

### 2. DevOps

* [DevOps Folder](DevOps/README.md)

### 3. Django

* [Django Folder](Django/README.md)

### 4. Full‑Stack

* [Full‑Stack Folder](Full‑Stack/README.md)

### 5. HTML & CSS

* [HTML‑CSS Folder](HTML‑CSS/README.md)

### 6. JavaScript

* [JavaScript Folder](JavaScript/README.md)

### 7. JS Labs

* [JS‑Labs-Browser](JS‑Labs/Browser/README.md)

### 8. Python

* [Python Folder](Python/README.md)

### 9. PyInsight

* [PyInsight Folder](PyInsight/README.md)

---

### 💡 Notes

* This repository is **personal** — designed to **retain knowledge for myself**.
* Content is structured to **maximize memory recall**.
* Each folder contains **hands‑on code, patterns, and documentation**.

---

✅ **Sean’s Tutorials**: My **personal, full‑stack, knowledge‑retention playground**. ([GitHub][1])

---

