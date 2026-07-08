# Part 2: Environment Variables and Upstash Redis

Goal: connect the app to a real Upstash Redis database, and validate environment variables at startup so misconfiguration fails loudly instead of silently.

---

## 1. Create an Upstash Redis database

1. Go to https://upstash.com and create a free account.
2. Create a new Redis database (any region close to you is fine).
3. Open the database's REST API section and copy:
   - `UPSTASH_REDIS_REST_URL`
   - `UPSTASH_REDIS_REST_TOKEN`

---

## 2. Create `.env.local`

In your project root:

```bash
touch .env.local
```

Add:

```env
UPSTASH_REDIS_REST_URL="paste_your_url_here"
UPSTASH_REDIS_REST_TOKEN="paste_your_token_here"
AUTH_COOKIE_SECRET="replace-this-with-a-long-random-string-at-least-32-chars"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
```

Generate a strong secret:

```bash
node -e "console.log(crypto.randomBytes(32).toString('hex'))"
```

Paste the output as `AUTH_COOKIE_SECRET`.

Make sure `.env.local` is listed in `.gitignore` (it is, by default, in `create-next-app` projects) — never commit real secrets.

---

## 3. Validate environment variables with zod

Create `src/lib/env.ts`:

```ts
import { z } from "zod";

const envSchema = z.object({
  UPSTASH_REDIS_REST_URL: z.string().url(),
  UPSTASH_REDIS_REST_TOKEN: z.string().min(1),
  AUTH_COOKIE_SECRET: z.string().min(32),
  NEXT_PUBLIC_APP_URL: z.string().url().default("http://localhost:3000"),
});

export const env = envSchema.parse({
  UPSTASH_REDIS_REST_URL: process.env.UPSTASH_REDIS_REST_URL,
  UPSTASH_REDIS_REST_TOKEN: process.env.UPSTASH_REDIS_REST_TOKEN,
  AUTH_COOKIE_SECRET: process.env.AUTH_COOKIE_SECRET,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
});
```

If any variable is missing or malformed, this throws immediately with a clear zod error instead of failing mysteriously later.

---

## 4. Create the Redis client

Create `src/lib/redis.ts`:

```ts
import { Redis } from "@upstash/redis";
import { env } from "@/lib/env";

export const redis = new Redis({
  url: env.UPSTASH_REDIS_REST_URL,
  token: env.UPSTASH_REDIS_REST_TOKEN,
});
```

---

## 5. Add a health check route

Create `src/app/api/health/route.ts`:

```ts
import { redis } from "@/lib/redis";

export const runtime = "nodejs";

export async function GET() {
  const startedAt = Date.now();
  await redis.set("health:last_ping", new Date().toISOString(), { ex: 60 });
  const value = await redis.get<string>("health:last_ping");

  return Response.json({
    ok: true,
    redis: value !== null,
    value,
    latencyMs: Date.now() - startedAt,
  });
}
```

Restart the dev server after editing env vars:

```bash
npm run dev
```

Visit `http://localhost:3000/api/health`. Expected:

```json
{
  "ok": true,
  "redis": true,
  "value": "2024-...",
  "latencyMs": 87
}
```

---

## Checkpoint

- [ ] `.env.local` has all four variables set.
- [ ] `src/lib/env.ts` parses without throwing.
- [ ] `/api/health` returns `ok: true` and `redis: true`.

---

## Troubleshooting

**`ZodError: AUTH_COOKIE_SECRET ... at least 32 character(s)`**
Regenerate the secret with the `node -e` command above and paste the full output.

**`Invalid url` for `UPSTASH_REDIS_REST_URL`**
The URL must start with `https://` exactly as copied from the Upstash console.

**Env changes don't seem to take effect**
Stop (`Ctrl+C`) and restart `npm run dev`. Next.js only reads `.env.local` at process startup.

**`/api/health` returns `redis: false`**
Double check both Upstash values were copied correctly, with no extra whitespace or quotes duplicated.

---

Are you're ready for **Part 3 — Styling and Shared UI**.
