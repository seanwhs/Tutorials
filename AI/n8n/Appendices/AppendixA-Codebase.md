## Appendix A: Codebase Reference

The full repository structure for the n8n Infrastructure-as-Code project built throughout this series.

### A.1 Full Repository Tree

```
n8n-production-stack/
├── docker-compose.yml              # local dev (Part 1)
├── docker-compose.prod.yml         # production Queue Mode (Part 8)
├── .env.example                    # committed template, never real secrets
├── .env                            # gitignored, real local secrets
├── .gitignore
├── README.md                       # setup instructions, links to this series
│
├── caddy/
│   └── Caddyfile                   # TLS reverse proxy config (Part 8)
│
├── n8n-data/                       # gitignored — n8n's own persistent state
├── postgres-data/                  # gitignored — Postgres data directory
├── ollama-data/                    # gitignored — pulled model weights
│
├── workflows/
│   ├── export/                     # versioned workflow JSON (Part 7)
│   │   ├── part2-hardened-webhook-intake.json
│   │   ├── part4-customer-create.json
│   │   ├── part4-customer-read.json
│   │   ├── part4-customer-update.json
│   │   ├── part4-customer-delete.json
│   │   ├── part5-ai-agent.json
│   │   ├── part5-rag-ingestion.json
│   │   ├── part6-global-error-handler.json
│   │   └── part6-reprocess-dead-letters.json
│   └── README.md                   # naming convention, ownership, credential name table
│
├── sql/
│   ├── 001_n8n_bootstrap.sql        # nothing needed — n8n manages its own schema
│   ├── 002_app_db_schema.sql        # customers, audit_log (Part 4)
│   ├── 003_error_observability.sql  # error_log, dead_letter_queue, job_locks (Part 6)
│   └── 004_rag_pgvector.sql         # kb_chunks + pgvector extension (Part 5)
│
├── scripts/
│   ├── export-all.sh               # Part 7
│   ├── import-all.sh               # Part 7
│   ├── validate-workflows.js       # Part 7 CI check
│   └── generate-secrets.sh         # helper to produce encryption key + passwords
│
├── .github/
│   ├── pull_request_template.md
│   └── workflows/
│       ├── validate-on-pr.yml      # Part 7
│       └── deploy-on-merge.yml     # Part 7
│
└── credentials-template/
    └── credential-names.md         # documented list of expected credential names per environment (Part 7.8)
```

### A.2 `sql/` Directory Convention

Number SQL files sequentially and never edit an already-applied file — add a new numbered file for any schema change, mirroring a migrations folder even without a formal migration tool.

```bash
docker compose exec -T postgres psql -U n8n_admin -d app_db < sql/002_app_db_schema.sql
```

### A.3 `generate-secrets.sh`

```bash
#!/usr/bin/env bash
# scripts/generate-secrets.sh — run once when bootstrapping a new environment
set -euo pipefail

echo "N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)"
echo "POSTGRES_PASSWORD=$(openssl rand -base64 24)"
echo "WEBHOOK_HMAC_SECRET=$(openssl rand -hex 32)"
echo ""
echo "Copy these into your .env (local) or your secrets manager / GitHub Actions secrets (production)."
```

### A.4 `README.md` Skeleton (Top-Level)

```markdown
# n8n Production Stack

Self-hosted n8n Community Edition, versioned as Infrastructure as Code.

## Quick Start (Local)
1. `cp .env.example .env` and fill in values (see `scripts/generate-secrets.sh`)
2. `docker compose up -d`
3. Visit http://localhost:5678

## Deploying Changes
See Part 7 of "Mastering Workflow Orchestration" — export workflows, open a PR,
CI validates, merge triggers deploy-on-merge.yml.

## Production
See Part 8 — `docker-compose.prod.yml`, Queue Mode, Caddy TLS.

## Directory Guide
- `workflows/export/` — versioned workflow JSON, one file per workflow
- `sql/` — numbered, append-only schema files
- `scripts/` — operational helper scripts
- `caddy/` — reverse proxy config
```

### A.5 `workflows/README.md` Skeleton

```markdown
# Workflow Inventory

| File | Purpose | Owner | Error Workflow Attached? |
|---|---|---|---|
| part2-hardened-webhook-intake.json | Public order intake | Platform Team | ✅ |
| part4-customer-create.json | CRUD - Create | Platform Team | ✅ |
| part4-customer-read.json | CRUD - Read | Platform Team | ✅ |
| part4-customer-update.json | CRUD - Update | Platform Team | ✅ |
| part4-customer-delete.json | CRUD - Soft Delete | Platform Team | ✅ |
| part5-ai-agent.json | Chat agent w/ tools | AI Team | ✅ |
| part5-rag-ingestion.json | KB embedding pipeline | AI Team | ✅ |
| part6-global-error-handler.json | Central error sink | Platform Team | N/A (this IS the handler) |
| part6-reprocess-dead-letters.json | Manual replay tool | Platform Team | ✅ |

## Credential Name Convention
See `credentials-template/credential-names.md` — names must match exactly across local/staging/production.
```

This structure is the single source of truth referenced throughout Parts 1–8; treat it as the deliverable you actually `git clone` when starting a new n8n project from this series.
