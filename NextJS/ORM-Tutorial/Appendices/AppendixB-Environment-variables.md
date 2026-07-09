# Appendix B: package.json & Environment Variables Reference

## 1. Full `package.json` — Prisma Variant

```json
{
  "name": "orm-nextjs-demo-prisma",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "db:migrate": "prisma migrate dev",
    "db:deploy": "prisma migrate deploy",
    "db:generate": "prisma generate",
    "db:studio": "prisma studio",
    "db:seed": "prisma db seed",
    "postinstall": "prisma generate"
  },
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  },
  "dependencies": {
    "next": "16.0.0",
    "react": "19.0.0",
    "react-dom": "19.0.0",
    "@prisma/client": "^6.0.0",
    "@prisma/adapter-neon": "^6.0.0",
    "@neondatabase/serverless": "^0.10.0",
    "ws": "^8.18.0",
    "zod": "^3.24.0",
    "clsx": "^2.1.0",
    "lucide-react": "^0.460.0"
  },
  "devDependencies": {
    "prisma": "^6.0.0",
    "typescript": "^5.7.0",
    "tsx": "^4.19.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/ws": "^8.5.0",
    "tailwindcss": "^4.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "16.0.0"
  }
}
```

## 2. Full `package.json` — Drizzle Variant

```json
{
  "name": "orm-nextjs-demo-drizzle",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "tsx src/db/migrate.ts",
    "db:push": "drizzle-kit push",
    "db:studio": "drizzle-kit studio",
    "db:seed": "tsx src/db/seed.ts",
    "db:check": "drizzle-kit check"
  },
  "dependencies": {
    "next": "16.0.0",
    "react": "19.0.0",
    "react-dom": "19.0.0",
    "drizzle-orm": "^0.36.0",
    "@neondatabase/serverless": "^0.10.0",
    "zod": "^3.24.0",
    "clsx": "^2.1.0",
    "lucide-react": "^0.460.0"
  },
  "devDependencies": {
    "drizzle-kit": "^0.28.0",
    "typescript": "^5.7.0",
    "tsx": "^4.19.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "tailwindcss": "^4.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "16.0.0"
  }
}
```

> Pin exact versions in a real project via `pnpm add pkg@x.y.z` — ranges above are illustrative minimums for Next.js 16 / React 19 compatibility.

## 3. Environment Variables — Full Reference Table

| Variable | Used By | Points To | Purpose |
|---|---|---|---|
| `DATABASE_URL` | Both (runtime) | Neon **pooled** endpoint (`-pooler` in hostname) | All app-level queries: Server Components, Server Actions, Route Handlers |
| `DIRECT_URL` | Both (migrations only) | Neon **direct** endpoint (no `-pooler`) | `prisma migrate`, `drizzle-kit generate/migrate`, schema introspection |
| `NODE_ENV` | Both | Set automatically by Next.js | Controls singleton client caching behavior in dev vs prod |

```bash
# .env.example — commit this file (without real secrets) so teammates
# know exactly which vars to set locally
DATABASE_URL=""
DIRECT_URL=""
```

```bash
# .env.local — for per-developer overrides, never committed
# (Next.js loads .env.local with higher priority than .env)
```

## 4. Neon Connection String Anatomy

```
postgresql://<user>:<password>@<endpoint-host>/<database>?sslmode=require
                                 └─ pooled: ep-xxxx-pooler.region.aws.neon.tech
                                 └─ direct: ep-xxxx.region.aws.neon.tech
```

- `sslmode=require` is mandatory — Neon rejects unencrypted connections.
- The **only** difference between pooled/direct URLs is the `-pooler` suffix on the host — easy to misconfigure by copy-pasting the wrong one. Always double check which var each tool reads.

## 5. Vercel Project Environment Variables (Dashboard Setup)

| Key | Environment | Value source |
|---|---|---|
| `DATABASE_URL` | Production, Preview, Development | Neon pooled connection string |
| `DIRECT_URL` | Production, Preview, Development | Neon direct connection string |

> Set `DIRECT_URL` even though it's unused at runtime — CI/CD deploy steps (Appendix E) invoke migration commands that need it during the build/deploy phase.

Continue to **Appendix C: Troubleshooting & Common Errors**.
