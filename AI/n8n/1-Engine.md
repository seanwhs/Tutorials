## Part 1: The Automation Engine

Self-hosting n8n via Docker, with persistent PostgreSQL storage and Redis for future scaling.

### 1.1 Architecture: n8n Cloud vs n8n Community Edition

| Dimension | n8n Cloud (managed) | n8n Community (self-hosted, this series) |
|---|---|---|
| Hosting | n8n GmbH's infrastructure | Your Docker host / VPS |
| Cost | Paid subscription tiers | Free forever (fair-code license) |
| Execution limits | Plan-based caps | None — bounded only by your hardware |
| Data residency | On n8n's servers | Fully under your control |
| Scaling | Automatic, opaque | Manual but transparent (Queue Mode, Part 8) |
| Credentials | Stored in n8n Cloud's vault | Stored in your own encrypted Postgres |
| Node access | Full | Full (only enterprise features like advanced permissions/SSO are gated) |
| Upgrades | Automatic | You control the image tag and upgrade cadence |

We use Community Edition exclusively: free, fair-code licensed, and gives us full control over the execution model — essential for the resilience and deployment work in Parts 6–8.

### 1.2 The Node-Based Execution Model

Every n8n workflow is a directed graph of **nodes**. Four concepts to internalize:

1. **Items are the unit of data.** Every node receives/emits an array of "items," shaped `{ json: {...}, binary: {...} }`. A node runs once per item unless it explicitly batches.
2. **Connections carry item arrays, not single values.** 5 incoming items → typically 5 outgoing (1:1), unless aggregating (`Aggregate`, `Summarize`) or splitting (`Split Out`).
3. **Execution is push-based and synchronous per branch.** Nodes evaluate left-to-right; a node won't run until all required inputs have data (matters once we add error branches in Part 6).
4. **Expressions (`{{ }}`) evaluate per-item**, in a sandboxed JS context, with access to `$json`, `$node`, `$now`, `$workflow`, and `$('Node Name').item.json`.

### 1.3 Project Layout

```bash
mkdir n8n-production-stack && cd n8n-production-stack
git init
mkdir -p workflows credentials-template n8n-data postgres-data caddy scripts .github/workflows
```

### 1.4 The Docker Compose Stack

```yaml
# docker-compose.yml
version: "3.8"

services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 10
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 10

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      N8N_HOST: ${N8N_HOST}
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      WEBHOOK_URL: ${WEBHOOK_URL}
      GENERIC_TIMEZONE: ${GENERIC_TIMEZONE}

      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: ${POSTGRES_DB}
      DB_POSTGRESDB_USER: ${POSTGRES_USER}
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}

      N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
      N8N_BASIC_AUTH_ACTIVE: "false"

      EXECUTIONS_DATA_PRUNE: "true"
      EXECUTIONS_DATA_MAX_AGE: 336
    volumes:
      - ./n8n-data:/home/node/.n8n
      - ./workflows:/home/node/workflows
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
```

### 1.5 Environment Variables

```bash
# .env.example (copy to .env; .env is gitignored)
POSTGRES_USER=n8n_admin
POSTGRES_PASSWORD=change_me_super_secret
POSTGRES_DB=n8n

N8N_HOST=localhost
WEBHOOK_URL=http://localhost:5678/
GENERIC_TIMEZONE=America/New_York

# Generate with: openssl rand -hex 32
N8N_ENCRYPTION_KEY=replace_with_generated_hex_key
```

```bash
openssl rand -hex 32   # paste output into N8N_ENCRYPTION_KEY

cat > .gitignore << 'EOF'
.env
n8n-data/
postgres-data/
node_modules/
EOF
```

> **Why the encryption key matters:** n8n encrypts stored credentials at rest using `N8N_ENCRYPTION_KEY`. If you lose it, every saved credential becomes unrecoverable. Back it up in a password manager, not just `.env`.

### 1.6 First Boot

```bash
docker compose up -d
docker compose logs -f n8n
```

Visit `http://localhost:5678` and complete owner account setup.

### 1.7 Verifying Persistent Storage

```bash
# Create a throwaway workflow in the UI, then:
docker compose down
docker compose up -d
# Refresh the UI — the workflow must still be there.
```

```bash
docker compose exec postgres psql -U n8n_admin -d n8n -c "\dt"
# Expect: workflow_entity, execution_entity, credentials_entity, webhook_entity, ...
```

### 1.8 Understanding `execution_entity`

Every run of every workflow is a row here — status (`success`/`error`/`waiting`), timestamps, and (if not pruned) full node input/output. Part 6 queries this table for an audit dashboard.

### 1.9 Exercise Challenge

1. Add an `adminer` service (port `8080:8080`) to visually inspect the Postgres schema.
2. Change `EXECUTIONS_DATA_MAX_AGE` to 72 hours, confirm the change is picked up.
3. Intentionally set a wrong `POSTGRES_PASSWORD`, restart, and read the resulting error to learn the failure signature.

### 1.10 Solution Notes

For (1):
```yaml
  adminer:
    image: adminer:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      ADMINER_DEFAULT_SERVER: postgres
```

For (3): expect `password authentication failed for user "n8n_admin"` in the postgres logs, followed by n8n's retry/backoff and eventual crash-loop.

### 1.11 What's Next

Part 2 builds your first real entry points — Webhook, Cron, and polling triggers — with defensive patterns (signature verification, idempotency keys, dedup).
