# Appendix E: Troubleshooting and Common Errors

A consolidated collection of every troubleshooting note scattered throughout the series, plus a few additional common gotchas. Organized by area. This entire series targets Next.js 16 as its baseline — no hedging needed on that front; the notes below are the specific things worth double-checking as you build.

## Next.js 16 specifics (read this first)

- **Async dynamic APIs everywhere**: `params`, `searchParams`, `headers()`, `cookies()`, and Clerk's `auth()` are all Promise-based in Next.js 16. Every dynamic page and route handler in this series uses `const { id } = await params;` / `await headers()` / `await auth()`. If you paste a snippet from an older tutorial that destructures `params` directly without awaiting, it will break — fix it to match the pattern used consistently throughout this series.
- **Middleware**: `src/middleware.ts` at the project root (next to `src/app/`) is the correct location for this project's `src/` directory layout, using `clerkMiddleware` from `@clerk/nextjs/server` as shown in Part 2 and Appendix A. If a future Next.js release changes this convention, check the official upgrade guide and the changelog for `@clerk/nextjs` before assuming this file needs to move.
- **Turbopack by default**: `next dev` and `next build` use Turbopack automatically — you do not need `--turbo` flags. If you hit a bundler-specific error that doesn't make sense, you can temporarily fall back with `next dev --webpack` to isolate whether it's a Turbopack-specific issue, then report/investigate accordingly.
- **Tailwind CSS v4**: there is no `tailwind.config.js` anywhere in this project. All theme customization lives in `src/app/globals.css` via `@import "tailwindcss"` plus `@theme`/`@utility` blocks. If you find yourself looking for a config object and can't locate one, that's expected — check `globals.css` instead.
- **Node.js 20.9+ required**: Next.js 16 will not start on Node 18. Run `node -v` and confirm 20.9+ (22 LTS recommended) before troubleshooting anything else if `pnpm dev` fails immediately with cryptic errors.
- **React 19**: all major dependencies in this stack (`@clerk/nextjs`, `@trpc/react-query`, `uploadthing`/`@uploadthing/react`, shadcn/ui-generated components) are expected to be on versions that support React 19. If you see peer-dependency warnings during `pnpm add`, check for a newer version of that specific package before working around it.
- **Upgrading an existing project into this baseline**: if you started this series on an older Next.js version, run `pnpm dlx @next/codemod@latest upgrade` first to auto-fix mechanical breaking changes, then re-check the async-params pattern by hand across your dynamic routes.

## Part 1: Setup

- **`node -v` reports below 20.9**: install Node 22 via nvm (`nvm install 22 && nvm use 22`) or nodejs.org before doing anything else — nothing else in this series will work correctly on an unsupported Node version.
- shadcn `init` prompts differ slightly between CLI versions — if a prompt shown in Part 1 doesn't appear, accept the defaults; the resulting `components.json` is what matters, not the exact prompt wording.
- Looking for `tailwind.config.js` and not finding it: expected — Tailwind v4 config lives in `src/app/globals.css` (see Part 1, section 5).

## Part 2: Clerk auth

- **sessionClaims.metadata is undefined**: you skipped the "Customize session token" step in the Clerk dashboard (Sessions → Customize session token, add `{ "metadata": "{{user.public_metadata}}" }`), or you're using a stale session — sign out and back in.
- **Infinite redirect loop between /sign-in and /admin or /portal**: double-check `isPublicRoute` in `src/middleware.ts` includes `/sign-in(.*)` and `/sign-up(.*)`, and that the matcher config excludes Next's static assets.
- **Role change not taking effect**: Clerk session tokens are cached for a short window; sign out/in to force a refresh, or wait for the token to naturally expire and refresh.
- **Middleware seems to not run at all**: confirm the file is at `src/middleware.ts`, not `src/app/middleware.ts` — this project uses a `src/` directory, so middleware belongs at the `src/` root, not inside `app/`.

## Part 3: Database

- **Error: P1001: Can't reach database server**: confirm you copied the pooled connection string from Neon (not the direct/unpooled one) and that `?sslmode=require` is present.
- **Too many connections in dev**: you likely instantiated `new PrismaClient()` directly somewhere instead of importing the singleton from `src/server/db.ts` — grep your codebase for `new PrismaClient(` outside that one file.
- **Prisma CLI can't find DATABASE_URL**: the Prisma CLI (migrate, studio, generate) reads from a plain `.env` file, not `.env.local`. Keep both in sync locally (both gitignored).
- **Prisma Client feels stale after a schema change**: run `pnpm dlx prisma generate` manually and restart `pnpm dev` — Turbopack's fast refresh doesn't always trigger Prisma Client regeneration on its own.

## Part 4: tRPC

- **Cannot find module 'server-only'**: run `pnpm add server-only`.
- **404 on /api/trpc/...**: confirm the route file is exactly at `src/app/api/trpc/[trpc]/route.ts` (the folder name is literally `[trpc]`, including brackets).
- **ctx.user is undefined inside protectedProcedure**: expected until Part 5's Clerk webhook has created a matching User row for your account — sign up/sign in again after the webhook is wired up, or check Prisma Studio for your User row.

## Part 5: Clerk webhook + Clients/Projects

- **Webhook never fires locally**: Clerk needs a publicly reachable URL. Use a tunnel (ngrok or similar) pointed at `localhost:3000/api/webhooks/clerk`, or just test against your deployed Vercel URL once Part 13 is done.
- **Signature verification fails**: `CLERK_WEBHOOK_SECRET` doesn't match the endpoint you configured — each webhook endpoint in the Clerk dashboard has its own distinct secret.
- **User row created with wrong role**: check that you set `publicMetadata.role = "ADMIN"` (uppercase, exact string) in the correct Clerk instance (Development vs Production are entirely separate user bases — see Part 13).

## Part 6/10: Invoices & Stripe

- **Invoice numbers collide under concurrent creation**: the `count()`-based `generateInvoiceNumber` helper has a known small race condition under simultaneous requests; harmless for a single-admin MVP. See Part 14's roadmap for the sequence-based fix.
- **Stripe webhook never fires locally**: confirm `stripe listen --forward-to localhost:3000/api/webhooks/stripe` is running in a separate terminal, and `STRIPE_WEBHOOK_SECRET` in `.env.local` matches what the CLI printed (not your dashboard's production secret).
- **"No signatures found matching the expected signature"**: wrong webhook secret for the environment you're testing against — local CLI secret and dashboard-created endpoint secrets are different values.
- **Checkout Session created but invoice never updates**: check your terminal for errors thrown inside the webhook handler — Stripe retries on non-200 responses, but a silently-caught Prisma error (e.g. malformed invoiceId in metadata) needs your own logging to catch.
- **TypeScript complains about a Stripe apiVersion literal type**: this series deliberately omits the `apiVersion` option from `new Stripe(...)` and lets the SDK use its own default — if you added one manually, remove it.

## Part 8: UploadThing

- **Env var not picked up**: restart `pnpm dev` after adding `UPLOADTHING_TOKEN` — Next.js only reads `.env.local` at server start, not on hot reload.
- **Type error on .input(...) in core.ts**: different uploadthing SDK versions expect either a zod-callback form (`.input((z) => z.object(...))`) or a plain zod object with `import { z } from "zod"` at the top — check whichever your installed version's docs show.
- **CLIENT user can upload to another client's project**: verify the middleware ownership check in `ourFileRouter`'s `.middleware()` callback is actually throwing `UploadThingError("Forbidden")`, not just logging and continuing.

## Part 11: Resend

- **Email "sent" but never arrives**: if you're using the shared `onboarding@resend.dev` test sender, it only delivers to your own account's registered email — verify your own domain in Resend for sending to arbitrary client addresses.
- **"from" address rejected**: `EMAIL_FROM` must use a domain verified in your Resend account in production.

## Part 13: Deployment

- **500 error right after deploy, logs mention Prisma**: confirm the `postinstall: "prisma generate"` script exists in package.json, and that `prisma migrate deploy` has been run (or is part of your build script) against the production `DATABASE_URL`.
- **Signed in as yourself on production but redirected to /portal instead of /admin**: you set `publicMetadata.role = "ADMIN"` in the wrong Clerk instance — re-check which instance (Development vs Production) your live `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` belongs to; they're fully separate user bases with separate role assignments.
- **Stripe webhook returns 400 in production logs**: `STRIPE_WEBHOOK_SECRET` in Vercel doesn't match the production dashboard endpoint's secret (not the CLI's local one).
- **Clerk "development mode" banner shows on your live domain**: you're still using `pk_test_`/`sk_test_` keys from a Development instance instead of a Production instance's `pk_live_`/`sk_live_` keys.
- **Build fails with a Node engine mismatch warning**: confirm `engines.node` in package.json reads `">=20.9.0"` and that Vercel's project Settings → General → Node.js Version isn't pinned to an older release.

## General debugging tips

- Prisma Studio (`pnpm dlx prisma studio`) is your best friend for verifying whether a mutation actually wrote what you expect — use it constantly while debugging any feature in this series.
- tRPC's loggerLink (already wired up in `src/trpc/client.tsx`) prints every request/response to your browser console in development — check there before assuming a bug is server-side.
- When something "doesn't show up in the UI," always first ask: did the tRPC mutation actually succeed (check Network tab / console), and did you call `router.refresh()` (Server Component data) or `utils.invalidate()` (React Query data) afterward?
