# Appendix A — Greymatter Docs Architecture (Next.js Edition)

## Understanding the Complete System Design

This appendix provides a comprehensive overview of how our Next.js/JavaScript version of Greymatter Docs is structured, explaining how each component interacts to transform data into professional business documents — the JS equivalent of the original's architecture reference for developers who want to understand, maintain, or extend the platform [1].

---

## Layered Architecture

Just as the original data layer followed a strict single-direction flow (`main.py` → `CustomerRepository` → `DatabaseManager` → SQLite) [9], our Next.js version follows the same layered discipline:

```text
API Routes (src/app/api/*)
        │
        ▼
DocumentOrchestrator / BatchProcessor
        │
        ▼
Repositories (Customer, Invoice, Delivery)
        │
        ▼
DatabaseManager
        │
        ▼
SQLite (better-sqlite3)
```

Each layer has a single responsibility, matching the original's separation exactly [9]:

| Layer | Responsibility |
|---|---|
| SQLite | Stores application data |
| DatabaseManager | Opens connections and executes SQL |
| Repository | Reads and writes business data |
| Orchestrator | Coordinates repositories, processors, and services |
| API Routes | Receive requests, validate input, return results |

## Design Patterns Used

| Pattern | Purpose |
|---|---|
| Repository Pattern | Encapsulates all database operations [1] |
| Service Pattern | Encapsulates external integrations such as PDF conversion and SMTP email [1] |
| Orchestrator Pattern | Coordinates the end-to-end pipeline so business logic isn't scattered across route handlers [4] |

Without an orchestrator, business logic becomes scattered, entry-point files grow uncontrollably, and testing becomes more difficult [4]. With one, each service keeps one responsibility, workflow changes happen in one place, and the application becomes easier to extend [4].

## Document Generation Pipeline

The template processing flow mirrors the original's loosely-coupled design, where the processor doesn't know where data came from — it only receives an object of values, making the engine reusable [8]:

```text
SQLite
   │
   ▼
CustomerRepository / InvoiceRepository
   │
   ▼
JavaScript Object
   │
   ▼
TemplateProcessor
   │
   ▼
Placeholder Engine (docxtemplater)
   │
   ▼
.docx Template
   │
   ▼
Completed Document
```

## Output & Delivery Flow

Delivery follows the same PENDING → SENT/FAILED lifecycle as the original, so failed deliveries can be retried, delivery history is preserved, and administrators can monitor queue status without re-running document generation [3] [1]:

| Status | Meaning |
|---|---|
| PENDING | Waiting for delivery |
| SENT | Successfully delivered |
| FAILED | Delivery failed |

## Deployment Progression

The original recommends a staged deployment progression from local development through to production cloud hosting [1]. Our Next.js path follows the equivalent free-tier-friendly progression:

| Stage | Platform |
|---|---|
| Development | Local machine |
| Testing | Vercel Preview Deployment |
| Staging | Vercel Production (Hobby tier) |
| Production | Vercel Pro / dedicated hosting with persistent database (e.g., Turso, managed Postgres) |

## Closing Principles

The original series closes by noting that the principles used throughout — single responsibility, separation of concerns, repository patterns, structured logging, and layered architecture — are applicable far beyond document automation, providing a solid foundation for building maintainable, scalable business applications [11]. This holds equally true in our JavaScript/Next.js implementation: every repository, service, and orchestrator module we built stays swappable and testable in isolation, exactly as intended.
