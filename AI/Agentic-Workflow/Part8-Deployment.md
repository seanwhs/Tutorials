# Part 8: Deployment & Governance

## 1. What "Deploying an Agent" Actually Means

Unlike a stateless REST API, an agentic service has extra concerns: it holds a session's worth of in-flight state across multiple model calls (seconds to minutes for a full Plan-and-Execute run), depends on multiple external services simultaneously (model API, Postgres/pgvector, n8n, Langfuse), and has spend that scales with usage unlike typical CRUD API compute cost. Deployment means containerizing the whole stack, securing secrets, and building operational guardrails.

## 2. Containerizing the Next.js + LangGraph App

**Dockerfile:**
```dockerfile
FROM node:20-slim AS base
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile

FROM base AS build
COPY . .
RUN pnpm build

FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/.next ./.next
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/public ./public
EXPOSE 3000
CMD ["node_modules/.bin/next", "start"]
```

**.dockerignore:**
```
node_modules
.next
.env
.env.local
*.log
```

Multi-stage rationale: `build` stage carries devDependencies needed only to produce `.next`; `runtime` copies only build output and production `node_modules`, keeping the image smaller with less attack surface.

## 3. Full Stack docker-compose for a VPS

**docker-compose.prod.yml:**
```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    env_file: .env.production
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: pgvector/pgvector:pg16
    env_file: .env.production
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    env_file: .env.production
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped

  langfuse-db:
    image: postgres:16
    env_file: .env.production
    volumes:
      - langfuse_db:/var/lib/postgresql/data
    restart: unless-stopped

  langfuse:
    image: langfuse/langfuse:latest
    depends_on:
      - langfuse-db
    ports:
      - "3001:3000"
    env_file: .env.production
    restart: unless-stopped

volumes:
  pgdata:
  n8n_data:
  langfuse_db:
```

**VPS deployment commands:**
```bash
git clone <your-repo> && cd <your-repo>
cp .env.production.example .env.production   # fill in real secrets — never commit this file
docker compose -f docker-compose.prod.yml up -d --build
```

**Caddyfile (reverse proxy for TLS):**
```
your-agent-domain.com {
  reverse_proxy app:3000
}

n8n.your-agent-domain.com {
  reverse_proxy n8n:5678
}

langfuse.your-agent-domain.com {
  reverse_proxy langfuse:3000
}
```

Caddy handles automatic HTTPS provisioning/renewal — no manual cert management.

## 4. Secrets and API Key Rotation

Never bake API keys into the Docker image or commit `.env.production`.

**Rotation procedure (model API key example):**
1. Generate a new key in the provider dashboard (don't revoke the old one yet).
2. Update `.env.production` on the VPS.
3. `docker compose -f docker-compose.prod.yml up -d app` (recreates only the `app` service).
4. Confirm via Langfuse that new traces succeed with no auth errors.
5. Revoke the old key.

Automate this on a schedule (e.g., quarterly), not just reactively.

**src/agent/model.ts (startup validation):**
```typescript
export function getModel() {
  if (!process.env.AGENT_API_KEY) {
    throw new Error(
      "AGENT_API_KEY is not set. Refusing to start with no model credentials."
    );
  }
  return new ChatOpenAI({
    model: process.env.AGENT_MODEL ?? "gpt-4o-mini",
    temperature: 0,
    apiKey: process.env.AGENT_API_KEY,
    configuration: {
      baseURL: process.env.AGENT_BASE_URL ?? "https://api.openai.com/v1",
    },
  });
}
```

## 5. Cost Caps as Code, Not Just Policy

A hard cap enforced before spend happens — a per-day budget tracked in Postgres.

**src/agent/nodes/costGuard.ts:**
```typescript
import { db } from "../../infra/db.js";

const DAILY_BUDGET_CENTS = Number(process.env.AGENT_DAILY_BUDGET_CENTS ?? 5000);

export async function assertUnderBudget() {
  const { rows } = await db.query(
    `SELECT COALESCE(SUM(cost_cents), 0) AS total
     FROM agent_runs WHERE created_at > now() - interval '1 day'`
  );
  if (Number(rows[0].total) >= DAILY_BUDGET_CENTS) {
    throw new Error("Daily agent spend budget exceeded. Halting new runs.");
  }
}
```

Call `assertUnderBudget()` at the top of the Route Handler, before invoking the graph — rejects new work once the cap is hit rather than alerting after the fact.

## 6. Agent Lifecycle: Versioning Prompts and Graphs

**src/agent/version.ts:**
```typescript
export const AGENT_VERSION = "2024.1-reflective-plan-execute";
```

Include `AGENT_VERSION` in every Langfuse trace's metadata and in the `agent_runs` table — lets you answer "did the regression start after we changed the Critique prompt on version X" months later.

## 7. Zero-Downtime-ish Redeploys

```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --no-deps --build app
```

`--no-deps` avoids restarting Postgres/n8n/Langfuse just to redeploy the app image. Beyond this, true zero-downtime needs a multi-VPS setup behind a load balancer — flagged as the natural next investment once traffic justifies it.

## 8. Exercise Challenge

`assertUnderBudget` is a global daily cap. Extend it to a per-user cap so one high-usage user can't exhaust the org's entire daily budget.

## 9. Solution

```typescript
export async function assertUnderBudget(userId: string) {
  const [globalRows, userRows] = await Promise.all([
    db.query(
      `SELECT COALESCE(SUM(cost_cents), 0) AS total FROM agent_runs
       WHERE created_at > now() - interval '1 day'`
    ),
    db.query(
      `SELECT COALESCE(SUM(cost_cents), 0) AS total FROM agent_runs
       WHERE user_id = $1 AND created_at > now() - interval '1 day'`,
      [userId]
    ),
  ]);

  if (Number(globalRows.rows[0].total) >= DAILY_BUDGET_CENTS) {
    throw new Error("Org-wide daily agent spend budget exceeded.");
  }
  const perUserCapCents = Number(process.env.AGENT_PER_USER_DAILY_CAP_CENTS ?? 500);
  if (Number(userRows.rows[0].total) >= perUserCapCents) {
    throw new Error("Your daily agent usage limit has been reached.");
  }
}
```

Why two separate checks: the org cap protects against aggregate runaway cost; the per-user cap protects fairness/availability across users. They fail for different reasons and should produce different error messages.

## Series Wrap-Up
Parts 1-8 now form one continuous, buildable system: a ReAct/Plan-and-Execute/Reflective LangGraph agent, backed by typed tools and dual-layer memory, integrated with n8n for external actions, fully traced in Langfuse, and deployable with real cost/security guardrails on a single VPS. The three Appendices turn this into a decision-support reference for future projects.
