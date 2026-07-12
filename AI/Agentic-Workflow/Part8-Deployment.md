# Part 8: Deployment & Governance

> Recap: Parts 1-7 built, in order, the reasoning loop, the tool layer, dual-layer memory, planning, self-critique, external action via n8n, and full tracing via Langfuse. Everything up to now has run on a laptop, invoked from a script. This Part is the one where all of that has to survive contact with the real world — a VPS that reboots, secrets that need to be rotated without downtime, and a budget that someone, somewhere, is actually paying.

## 1. What "Deploying an Agent" Actually Means

It's worth being precise about how this differs from deploying a typical stateless REST API, because the differences drive nearly every decision in this Part. An agentic service holds a session's worth of in-flight state across multiple model calls — Part 4's Plan-and-Execute run alone can span seconds to minutes of real wall-clock time across several Reason/Act/Critique cycles, not the tens-of-milliseconds a typical CRUD endpoint takes. It depends on multiple external services *simultaneously* to complete a single request — the model API, Postgres/pgvector (Part 3), n8n (Part 6), and Langfuse (Part 7) — meaning a single agent run's success depends on the availability of a whole small constellation of services, not just your own application code. And its spend scales with usage in a way typical API compute cost doesn't: a CRUD endpoint's marginal cost per request is close to negligible and roughly fixed; an agent run's marginal cost is a real, variable dollar figure that depends on how many reasoning steps, tool calls, and critique passes a given request happened to need. Deployment, for a system with these three properties, means containerizing the whole stack, securing secrets across all of it, and building operational guardrails that a stateless API deployment simply wouldn't need — this Part builds exactly those three things, in that order.

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

The multi-stage build here is worth understanding at the level of "what problem does each stage solve," not just as boilerplate to copy. The `base` stage installs dependencies once, with `--frozen-lockfile` — refusing to silently resolve to different versions than what's committed in `pnpm-lock.yaml`, which matters a great deal for an agent system specifically: a silent dependency drift in, say, the LangChain packages underpinning every node built across Parts 1-7 is exactly the kind of change that could alter model-calling behavior in a way that's hard to attribute later. The `build` stage carries devDependencies needed only to compile `.next` — TypeScript, build tooling, everything from `tsconfig.json` back in Part 1 — none of which needs to exist in the artifact that actually runs in production. The `runtime` stage then copies over *only* the build output and production `node_modules`, deliberately leaving the build tooling behind. The result: a smaller image, which matters for deploy speed, and a smaller attack surface, which matters more — every package that exists in a running container is a package whose vulnerabilities you've inherited, whether or not your application code ever touches it. `.dockerignore` closes the more urgent version of that same risk: without it, a plain `COPY . .` would happily bake your local `.env` file — API keys and all — straight into an image layer, which is a much worse failure than a slightly bloated image, since a leaked image layer is much harder to fully remediate than a large one.

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

Look at this file next to the individual `docker-compose.yml` snippets from Parts 3, 6, and 7 — nothing here is new architecturally, this is literally those three earlier files' services merged into one, plus the app itself, plus `restart: unless-stopped` added uniformly across every service. That restart policy is a small line doing real work for an unattended VPS: if the box reboots (a provider-initiated maintenance restart, a power blip) or any one container crashes, Docker brings it back up on its own, without a human needing to notice and intervene. Notice too that `postgres` here is the *same* pgvector-enabled instance from Part 3 — your application's relational data and long-term memory — while `langfuse-db` remains its own separate Postgres instance, exactly the separation argued for in Part 7, section 3, now carried through into the production topology unchanged.

**VPS deployment commands:**

```bash
git clone <your-repo> && cd <your-repo>
cp .env.production.example .env.production   # fill in real secrets — never commit this file
docker compose -f docker-compose.prod.yml up -d --build
```

The `.env.production.example` / `.env.production` split mirrors the `.env.example` / `.env` pattern from Part 1's `model.ts` section, extended to the whole stack: a committed, secret-free template documenting *which* variables exist, and a real, gitignored file containing the actual values. That distinction — document the shape, never commit the substance — is worth treating as a hard rule for every environment file this series has introduced, not a style preference.

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

Caddy handles automatic HTTPS provisioning and renewal via Let's Encrypt behind the scenes — no manual certificate generation, no cron job to remember to renew before expiry, which is a common, easy-to-forget source of production outages in hand-rolled TLS setups. Notice the three subdomains map exactly to the three user-facing web UIs in the stack — your app, n8n's workflow editor, Langfuse's trace viewer — each getting its own certificate and its own routing rule, while Postgres (both instances) stays entirely unexposed to the public internet, reachable only from other containers on the same Docker network. That's not incidental: a database has no business being reachable from outside the VPS at all, and the Caddyfile's silence on Postgres is the correct, deliberate absence of a route, not an oversight to fix later.

## 4. Secrets and API Key Rotation

Never bake API keys into the Docker image or commit `.env.production` — both mistakes turn a temporary credential into a permanent one, since anything baked into an image layer or committed to git history persists indefinitely, discoverable long after you think you've "removed" it.

**Rotation procedure (model API key example):**

1. Generate a new key in the provider dashboard (don't revoke the old one yet).
2. Update `.env.production` on the VPS.
3. `docker compose -f docker-compose.prod.yml up -d app` (recreates only the `app` service).
4. Confirm via Langfuse that new traces succeed with no auth errors.
5. Revoke the old key.

The ordering here is the entire point of the procedure, and it's worth naming explicitly why each step comes where it does. Generating the new key *before* revoking the old one, and only revoking at the very last step, is what makes this rotation zero-downtime: there's a brief window (steps 2-4) where both keys are technically valid, which means an in-flight request using the old key doesn't suddenly fail mid-run when you swap the environment variable — it's still valid until step 5. Step 4's Langfuse check — confirming *new* traces succeed with no auth errors before revoking anything — is the safety check that prevents a bad rotation (a typo'd key, a key with insufficient permissions) from becoming an outage: if step 4 fails, you still have the old, working key live, and you can simply not proceed to step 5 while you debug. Skip step 4, revoke immediately after step 2, and a bad new key means your agent stops working entirely with no fallback — that's the specific failure this ordering exists to prevent.

Automate this on a schedule — quarterly, say — not just reactively, in response to a suspected leak. A rotation you only ever perform in a panic, under time pressure, right after discovering a credential leaked, is a rotation you're likely to get wrong precisely because you're rushing it. A rotation you perform routinely, calmly, on a schedule, is a rotation your team has practiced and trusts — and, as a side benefit, it caps the useful lifetime of any credential that *does* leak without your knowledge, since it'll be rotated out within a quarter regardless.

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

Compare this against Part 1's original `getModel()`, which quietly fell back to `apiKey: process.env.AGENT_API_KEY ?? "ollama"` — a sensible default for local development against Ollama, where no real key is needed at all, but a dangerous one to carry unmodified into production. Without this explicit check, a production deployment that's missing `AGENT_API_KEY` due to a misconfigured `.env.production` wouldn't fail to start; it would start successfully, silently fall back to the literal string `"ollama"` as an API key, and only fail — confusingly, with an authentication error deep inside a model call — the moment the first real request came in. Failing loudly and immediately at startup, with a clear error message, is strictly better than failing quietly and confusingly on the first request: it turns a production incident discovered by a confused user into a deployment that simply refuses to come up, caught by whoever's watching the deploy.

## 5. Cost Caps as Code, Not Just Policy

Part 7, section 7 built an n8n watchdog that *alerts* on cost overruns after the fact — useful, but reactive: by the time the alert fires, the spend has already happened. This section closes that gap with a hard cap enforced *before* spend happens, not just observed afterward — a per-day budget tracked directly in Postgres and checked synchronously, in the request path, before any model call is made.

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

`COALESCE(SUM(cost_cents), 0)` is a small but easy-to-get-wrong detail worth flagging: `SUM` over zero rows returns SQL `NULL`, not `0`, and comparing `NULL >= DAILY_BUDGET_CENTS` would evaluate to `NULL` — which is neither true nor false in SQL's three-valued logic, and would silently fail to trigger the guard on a day with no prior runs at all. `COALESCE(..., 0)` forces that edge case to the correct value before the comparison ever happens, so "no spend yet today" reliably evaluates as "under budget," not as an ambiguous non-answer.

Call `assertUnderBudget()` at the top of the Route Handler — the same `POST` handler Part 6, section 7 wired up for n8n to call into — *before* invoking the graph. Placement matters: this rejects *new* work once the cap is hit, cheaply, with no model call incurred at all, rather than letting a request start, consume tokens across however many Reason/Act/Critique cycles it needs, and only report the overage after the money's already spent. That's the fundamental difference between this section's guard and Part 7's watchdog: the watchdog observes spend that already happened and alerts a human; this guard prevents the *next* dollar from being spent at all, deterministically, in code, before any LLM call — the same "hard ceiling enforced in code, not policy" discipline this series has applied to loop steps (Part 1), plan length (Part 4), and refinement attempts (Part 5), now applied to money.

## 6. Agent Lifecycle: Versioning Prompts and Graphs

**src/agent/version.ts:**

```typescript
export const AGENT_VERSION = "2024.1-reflective-plan-execute";
```

A single exported string, and it's worth resisting the urge to underrate how much this one line buys you. Include `AGENT_VERSION` in every Langfuse trace's metadata and in the `agent_runs` table, and every single trace and every row of spend/behavior data from this point forward carries a durable answer to "which version of the prompts, the Critique criteria, the tool descriptions produced this." That's what lets you answer a question that otherwise becomes nearly unanswerable months later: "did the regression start after we changed the Critique prompt on version X" — a question that, without a version tag threaded through every trace, would require trying to reconstruct *when* a code change shipped and cross-referencing it against timestamps by hand. With the tag, it's a filter in the Langfuse UI. Bump this string deliberately, as part of your normal change process, any time you touch a prompt, a Critique criterion, a tool description, or the graph's wiring — treat it the same discipline you'd apply to a semantic version bump on a public API, because from the point of view of the model's behavior, that's exactly what it is.

## 7. Zero-Downtime-ish Redeploys

```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --no-deps --build app
```

The "-ish" in the section title is honest, not hedging for its own sake — this is a meaningfully better redeploy than a naive `docker compose up -d --build` for the whole stack, but it's not a true zero-downtime deploy, and it's worth understanding exactly what it does and doesn't buy you. `--no-deps` is the specific flag doing the work: it tells Compose to rebuild and restart *only* the `app` service, explicitly skipping its declared dependency (`postgres`, per section 3's `depends_on`). Without `--no-deps`, a routine app redeploy would restart Postgres, n8n, and Langfuse right along with it — services that didn't change at all — incurring unnecessary downtime on your database and your tracing infrastructure for a change that only touched application code. There's still a brief gap between the old `app` container stopping and the new one becoming ready to serve traffic — that's the "-ish" — but it's a gap measured in the seconds it takes Next.js to boot, not the longer interruption of a full-stack restart.

Beyond this, true zero-downtime — no gap at all, ever, even during app redeploys — needs a multi-VPS setup behind a load balancer, where new instances come up and pass health checks before old instances are drained and removed, so there's never a moment with zero healthy instances serving traffic. That's flagged here deliberately as the natural next investment once traffic actually justifies it, not built out in this Part, because a single-VPS deployment with a few seconds of redeploy gap is the right amount of infrastructure for most of this series' audience, and building a load-balanced multi-instance setup before you need one is the same premature-complexity mistake Part 1's folder structure warned against in miniature: don't scaffold for a scale you haven't reached.

## 8. Exercise Challenge

`assertUnderBudget`, as written in section 5, is a purely global daily cap — it sums *every* run across the entire org. That leaves an obvious gap: one high-usage user, whether through heavy legitimate use or a runaway integration bug on their end, can single-handedly exhaust the org's entire daily budget, starving every other user of agent access for the rest of the day even though their own usage was completely reasonable. Extend the guard to a per-user cap so that one user's usage can't crowd out everyone else's.

Notice this is a fairness problem layered on top of a cost problem, and the two need to be checked — and reported — separately, which is exactly what the solution below does.

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

Two implementation details worth flagging beyond the headline logic. First, `Promise.all` runs both queries concurrently rather than sequentially — a small performance choice, but one worth making a habit of: these two queries are entirely independent of each other, so there's no reason to pay their latency cost twice in serial when they can run in parallel and you simply wait for the slower of the two. Second, and more important architecturally: the two checks are genuinely independent conditions with genuinely independent, distinct error messages, not one merged check with one generic message.

Why two separate checks, stated as the general principle: the org cap protects against aggregate runaway cost — the scenario where total usage across everyone exceeds what the business can afford, regardless of how fairly it's distributed. The per-user cap protects fairness and availability across users — the scenario where total cost is perfectly fine, but one user's share of it is crowding out everyone else's access. These are genuinely different problems with genuinely different remedies (raise the org budget vs. talk to one specific heavy user, or raise their individual cap), and they should fail with genuinely different, specific error messages rather than a single undifferentiated "budget exceeded" — because whoever's debugging a user complaint about being blocked needs to know immediately which of the two situations they're looking at, and a merged message would force them to go query the database by hand to find out, defeating the purpose of a clear error message in the first place.

## Series Wrap-Up

Parts 1-8 now form one continuous, buildable system, and it's worth tracing the throughline rather than just listing the parts: a **ReAct** loop (Part 1) that reduces every agentic decision to a probabilistic node feeding a deterministic router, given real teeth by a **typed tool layer** (Part 2) that treats tool contracts with the same rigor as any public API. That loop is grounded by **dual-layer memory** (Part 3) that refuses to conflate a fast session window with a slow, relevance-ranked long-term store. For goals too large for a single loop, it's extended into **Plan-and-Execute** (Part 4), trading upfront planning cost for reduced drift on long tasks. Every output the system produces before it's trusted passes through **Reflection** (Part 5) — a second, adversarially-framed pass that catches what a first pass can't catch in itself. External side effects are handed off to **n8n** (Part 6) along a deliberately drawn boundary between judgment and mechanism. The whole system is made legible after the fact through **Langfuse tracing** (Part 7), because a probabilistic system's history is the only real record of why it did what it did. And finally, all of it is made to survive contact with a real VPS, a real budget, and real rotating secrets in **Part 8**.

The pattern worth carrying forward past this series, more than any single code snippet: at every layer, the same question got asked — can this decision be made deterministic, structural, and enforced in code, or does it genuinely require the model's judgment? Step ceilings, schema-enforced confirmations, cost guards, and retry logic all answered "yes, push it into code." Tool selection, plan decomposition, and critique verdicts all answered "no, this needs the model." Getting that split right, layer by layer, is most of what separates a demo from a system you can actually operate. The three Appendices — testing (B), governance (C), and whatever's referenced elsewhere in your own copy of this series — turn everything built across these eight Parts into a decision-support reference for future projects, so the next agent you build doesn't have to re-derive any of this from first principles.
