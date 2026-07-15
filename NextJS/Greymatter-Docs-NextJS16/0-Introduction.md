# Part 0 — Welcome to Greymatter Docs (Next.js Edition)

> **Build a Production-Ready Automated Document Generation Platform with Next.js 16 and JavaScript**

This is the Next.js/JavaScript adaptation of the original Greymatter Docs series, which was built with **Python, SQLite, and LibreOffice UNO** [13]. We're keeping the same philosophy, the same milestones, and the same beginner-friendly, code-heavy teaching style — just swapping the underlying tools for a modern JS stack.

## Why Greymatter Docs?

Greymatter Docs is a document generation platform: you feed it structured data (customers, invoices), a template, and it produces polished, ready-to-deliver documents automatically. The original series builds this piece by piece so nothing feels like "magic" — every layer is small, testable, and understandable before moving to the next [13].

## The Architecture (Next.js Version)

The original pipeline was:

```
SQLite Database → Data Access Layer → Template Processor → LibreOffice UNO API → Generated Documents → ODT/PDF Output → Email/Archive
```

In our Next.js version, we'll build the same conceptual pipeline, with these swaps:

| Original (Python/UNO) | Next.js/JS Edition |
|---|---|
| Python application | Next.js 16 (App Router) |
| SQLite via raw driver | SQLite via `better-sqlite3` (or Prisma) |
| Repository pattern (`CustomerRepository`) | JS repository modules (same pattern) |
| `.ott` templates + regex placeholders | `docx`/`docxtemplater` templates with `{{placeholder}}` syntax |
| LibreOffice UNO API bridge | `docxtemplater` + `libreoffice-convert` (or a headless conversion service) for DOCX → PDF |
| `SmtpService` (Python) | `nodemailer` |
| Gradio web UI (Part 11) | Native Next.js UI (App Router pages, Server Actions) |
| Deploy to Hugging Face Spaces | Deploy to Vercel (or similar free-tier host) |

Every architectural idea from the original — layered design, repository pattern, orchestrator, batch processing, structured logging — carries over exactly. Only the implementation language and libraries change.

## The Complete Roadmap

We'll follow the same ten-part structure as the original series, each delivering a working milestone [13]:

| Part | Topic | Milestone |
|---|---|---|
| **Part 0** | Welcome | Understand the project and architecture |
| **Part 1** | Foundations & Initial Setup | Next.js project scaffolded, structure and logging in place |
| **Part 2** | Data Strategy | Database and data access layer operational |
| **Part 3** | Template Architecture | Placeholder detection and template design complete |
| **Part 4** | Document Engine Bridge | Next.js connected to the document generation engine |
| **Part 5** | Processor Engine | Documents generated from live data, including dynamic tables |
| **Part 6** | Production Mechanics | Logging, config, custom errors, validation |
| **Part 7** | Orchestrator | End-to-end pipeline wired together |
| **Part 8** | Output & Delivery | PDF export and email delivery |
| **Part 9** | Polish | Batch processing, progress tracking, execution reports |
| **Part 10** | Deployment & Scale | Production hardening |
| **Part 11** | Deploy for Free | Ship a live web app |

## What You'll Need

- Node.js 20+ and npm/pnpm
- Basic JavaScript/React familiarity (we'll explain everything else as we go)
- A code editor (VS Code recommended)
- No prior document-automation or Next.js 16 experience required — we build it step by step, code-heavy, one working piece at a time

## How This Series Works

Just like the original, each part will:
1. Explain the theory and architecture for that stage
2. Build it — real, runnable code, one step at a time
3. Give you a challenge lab to extend what you built
4. Include a troubleshooting table for common issues

Ready? Let's move to **Part 1 — Foundations**, where we scaffold the Next.js 16 project, set up the folder structure, and get a basic logging system running before we touch any documents or databases.
