## Part 8: Production Deployment & Scaling

Deploying to a VPS, scaling with Queue Mode (Workers), and security best practices: credential management, CORS, and API keys.

### 8.1 Production Topology Overview

```
                        Internet
                           |
                      [Caddy: TLS]
                           |
              -------------------------
              |                       |
        [n8n Main]              [n8n Webhook(s)]
              |                       |
              -----------+-------------
                          |
                     [Redis Queue]
                          |
              -----------+-------------
              |                       |
        [n8n Worker 1]          [n8n Worker 2..N]
                          |
                     [Postgres]
```

In **Queue Mode**, "Main" handles UI/API/trigger registration; "Webhook" instances receive calls and enqueue to Redis; "Worker" instances pull jobs and execute. This decouples ingestion rate from processing rate.

### 8.2 Provisioning the VPS

Minimum spec: 4 vCPU / 8GB RAM / 80GB SSD (with local Ollama). Hosted-LLM-only: 2 vCPU / 4GB RAM.

```bash
apt update && apt upgrade -y
adduser deploy
usermod -aG sudo deploy
curl -fsSL https://get.docker.com | sh
usermod -aG docker deploy
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

```bash
su - deploy
git clone YOUR_REPO_URL /opt/n8n-production-stack
cd /opt/n8n-production-stack
```

### 8.3 docker-compose.prod.yml: Queue Mode

`n8n` splits into `n8n-main` and `n8n-worker`, sharing image/Postgres/Redis, plus Caddy for TLS.

**8.3.1 n8n-main**
```yaml
n8n-main:
  image: docker.n8n.io/n8nio/n8n:latest
  restart: unless-stopped
  environment:
    EXECUTIONS_MODE: queue
    QUEUE_BULL_REDIS_HOST: redis
    QUEUE_BULL_REDIS_PORT: 6379
    DB_TYPE: postgresdb
    DB_POSTGRESDB_HOST: postgres
    DB_POSTGRESDB_PORT: 5432
    DB_POSTGRESDB_DATABASE: ${POSTGRES_DB}
    DB_POSTGRESDB_USER: ${POSTGRES_USER}
    DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
    N8N_HOST: ${N8N_HOST}
    N8N_PROTOCOL: https
    WEBHOOK_URL: https://${N8N_HOST}/
    N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
    GENERIC_TIMEZONE: ${GENERIC_TIMEZONE}
  volumes:
    - ./n8n-data:/home/node/.n8n
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
```

**8.3.2 n8n-worker** (duplicate per replica)
```yaml
n8n-worker-1:
  image: docker.n8n.io/n8nio/n8n:latest
  restart: unless-stopped
  command: ["n8n", "worker"]
  environment:
    EXECUTIONS_MODE: queue
    QUEUE_BULL_REDIS_HOST: redis
    QUEUE_BULL_REDIS_PORT: 6379
    DB_TYPE: postgresdb
    DB_POSTGRESDB_HOST: postgres
    DB_POSTGRESDB_PORT: 5432
    DB_POSTGRESDB_DATABASE: ${POSTGRES_DB}
    DB_POSTGRESDB_USER: ${POSTGRES_USER}
    DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
    N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
    GENERIC_TIMEZONE: ${GENERIC_TIMEZONE}
  volumes:
    - ./n8n-data:/home/node/.n8n
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
```

> Copy as `n8n-worker-2`, `n8n-worker-3`, etc. to scale. Workers share `./n8n-data` safely — they only read cached definitions and write results to Postgres.

**8.3.3 caddy**
```yaml
caddy:
  image: caddy:2-alpine
  restart: unless-stopped
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./caddy/Caddyfile:/etc/caddy/Caddyfile
    - caddy_data:/data
    - caddy_config:/config
  depends_on:
    - n8n-main

volumes:
  caddy_data:
  caddy_config:
```

**8.3.4 Caddyfile**
```
your-domain.example.com {
  reverse_proxy n8n-main:5678
}
```
Caddy obtains/renews Let's Encrypt certs automatically — zero extra config.

### 8.4 Deployment Commands

```bash
cp .env.example .env
nano .env

docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml logs -f n8n-main
```
Scale workers by adding a new `n8n-worker-N` block and re-running `up -d`.

### 8.5 Scaling Guidance

| Symptom | Action |
|---|---|
| Webhook responses slow, workers idle | Add `n8n-main` replicas, or split webhook intake |
| Redis queue depth growing | Add more `n8n-worker-N` replicas |
| Postgres CPU pegged | Add PgBouncer transaction pooling; consider read replicas |
| Ollama inference slow | Move to dedicated GPU host, repoint credential |

### 8.6 Security: Credential Management

Never store secrets in workflow JSON. Credentials are encrypted at rest via `N8N_ENCRYPTION_KEY`, referenced by name — exports only contain a pointer. Rotate the encryption key only via the documented re-encryption procedure (export credentials, change key, re-import).

### 8.7 Security: Network Isolation

Postgres, Redis, Ollama should never be internet-reachable. Omit `ports:` publishing for these in production — only Caddy publishes 80/443.

### 8.8 Security: CORS

```
N8N_CORS_ALLOWED_ORIGINS=https://your-frontend.example.com
```
Prefer server-to-server calls (Next.js Server Action/Route Handler) over direct browser calls whenever a request carries an API key.

### 8.9 Security: API Keys for Webhooks

Every public webhook requires a credential (Header Auth/HMAC), never `authentication: none`. Protect n8n's own REST API with a dedicated **n8n API Key**, stored only in CI/CD secrets.

### 8.10 Exercise Challenge

1. Deploy end-to-end to a real VPS with DNS + live Caddy TLS cert.
2. Add a second worker replica; prove load distribution across 20 concurrent webhook calls.
3. Attempt to connect to Postgres via its public IP from your local machine — confirm it fails (no port published).

### 8.11 Solution Notes

For (3): expect a connection timeout, not an auth error — timeout proves the port isn't exposed at all.

### 8.12 What's Next

This closes the 8-part core series. Appendix A gives the full repo reference structure, Appendix B is your node-library cheat sheet, and Appendix C is the local-to-production migration checklist.
