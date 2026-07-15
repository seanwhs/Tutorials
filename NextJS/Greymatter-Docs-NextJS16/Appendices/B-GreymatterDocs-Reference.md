# Appendix B — Greymatter Docs Reference Guide (Next.js Edition)

## A Consolidated Reference for API Routes, Environment Variables, and Database Schema

> **Purpose:** While Appendix A covers the *architecture* [1], this appendix serves as a quick-lookup reference for the concrete pieces — every API route, every environment variable, and the full database schema — built across Parts 1–11 of the Next.js/JS conversion.

---

### API Route Reference

| Route | Method | Purpose | Introduced In |
|---|---|---|---|
| `/api/health` | GET | Checks database, template, and output directory health | Part 1, expanded Part 10 |
| `/api/customers` | GET | Lists all customers | Part 2 |
| `/api/generate-letter` | GET | Generates a single customer letter | Part 3 |
| `/api/generate-batch` (early version) | GET | Generates a small batch of letters | Part 4 |
| `/api/generate-invoice` | GET | Generates one invoice document via the orchestrator | Part 5, rewired Part 7 |
| `/api/generate-batch` (final version) | POST | Runs a batch of invoice jobs through the orchestrator | Part 7 |
| `/api/deliver-invoice` | GET | Generates, exports to PDF, and emails an invoice | Part 8 |
| `/api/batch-generate` | POST | Runs `BatchProcessor` with progress tracking and reports | Part 9 |
| `/api/backup` | POST | Backs up the SQLite database and prunes old backups | Part 10 |
| `/api/scheduled-batch` | POST | Cron-secured endpoint for unattended batch runs | Part 10, wired in Part 11 |

---

### Environment Variables Reference

| Variable | Purpose | Introduced In |
|---|---|---|
| `NODE_ENV` | Sets development/production mode | Part 1 |
| `DATABASE_FILE` | Overrides SQLite file path | Part 10 |
| `TEMPLATES_DIR` | Overrides templates directory path | Part 10 |
| `OUTPUT_DIR` | Overrides generated output directory path | Part 10 |
| `LOGS_DIR` | Overrides logs directory path | Part 10 |
| `MAX_BATCH_SIZE` | Caps batch job size | Part 10 |
| `SMTP_SERVER` / `SMTP_PORT` / `SMTP_USERNAME` / `SMTP_PASSWORD` / `SMTP_SENDER` | Email delivery configuration | Part 8 |
| `CRON_SECRET` | Bearer-token secret for the scheduled batch endpoint | Part 10, used Part 11 |

---

### Database Schema Reference

Reflecting the same layered data strategy as the original — a single-responsibility schema that grows incrementally chapter by chapter [9]:

```text
customers
────────────────────────────────────
id, first_name, last_name, company,
email, phone, address, city, country,
created_at

invoices
────────────────────────────────────
id, customer_id (FK → customers.id),
invoice_number, invoice_date, created_at

invoice_items
────────────────────────────────────
id, invoice_id (FK → invoices.id),
description, quantity, unit_price

delivery_queue
────────────────────────────────────
id, job_id, customer_id (FK → customers.id),
recipient_email, pdf_path, status
(PENDING | SENT | FAILED), error_message,
created_at, updated_at
```

---

### Challenge Lab — Tying It All Together

1. Draw the full request lifecycle for `/api/deliver-invoice` by hand, labeling every layer it passes through (API route → Orchestrator → Repositories → Services), similar in spirit to tracing `main.py`'s original responsibilities before the Orchestrator existed [4].
2. Identify which environment variables would need to change if migrating from the free-tier `/tmp` SQLite setup to a hosted database — and which application code would need to change (answer: none above the `DatabaseManager` layer, by design).
3. Add a new table to the schema reference above (e.g., `templates` for user-uploaded templates, echoing the original's optional Challenge 4 of allowing users to upload their own template file [10]) and sketch its foreign key relationships.
