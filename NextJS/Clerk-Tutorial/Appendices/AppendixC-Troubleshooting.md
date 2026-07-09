# Appendix C: Troubleshooting Guide (Next.js 16)

A consolidated, searchable troubleshooting reference across the entire series, built for Next.js 16. Each part also has its own inline troubleshooting section with more context — use this appendix when you just need a quick answer.

## Next.js 16 specific issues (read this section first if something feels version-related)

**`create-next-app` or `next dev`/`next build` fails with a Node version error.** Next.js 16 requires Node.js 20.9+ or 22 LTS. Run `node -v` and upgrade via nodejs.org or your version manager (nvm/fnm/volta) if it reports 18.x or lower — see Part 1.

**A Server Component, Server Action, or Route Handler throws an error or behaves oddly around `headers()`, `cookies()`, `params`, `searchParams`, `auth()`, or `currentUser()`.** These are all async in Next.js 16 (this rule started in Next.js 15) and must be `await`ed. Forgetting `await` is the single most common bug in this entire series — check Parts 7 and 13 specifically, and Appendix A's webhook route for a correct example.

**Terminal output mentions Turbopack and it looks unfamiliar.** Expected — Turbopack is the default bundler for both `next dev` and `next build` in Next.js 16. It doesn't require any extra configuration for this tutorial's code. If you ever suspect a Turbopack-specific bug, you can fall back temporarily with `next dev --webpack` / `next build --webpack`.

**No `tailwind.config.ts` file exists in my project and I expected one.** That's correct for Tailwind CSS v4's CSS-first setup (used throughout this series) — configuration lives in `src/app/globals.css` via `@import "tailwindcss";` and an optional `@theme` block. See Part 2 and Part 3.

## Environment & setup

**"node: command not found."** Restart your terminal (or computer) after installing Node.js — see Part 1.

**Port 3000 already in use.** Stop the other process, or run `npm run dev -- -p 3001`.

**`.env.local` changes don't seem to apply.** Restart `npm run dev` — env files are only read at server startup, not hot-reloaded.

## Tailwind

**Classes have no visual effect.** Check for typos in class names (Tailwind fails silently on unrecognized classes) and confirm `globals.css` still contains `@import "tailwindcss";` and is imported by `layout.tsx`.

## Clerk installation & middleware

**"Missing publishableKey" error.** `.env.local` isn't named exactly right, isn't in the project root, or the dev server wasn't restarted after creating/editing it.

**`clerkMiddleware is not a function`.** Import it from `@clerk/nextjs/server`, not `@clerk/nextjs`.

**Middleware not running at all.** File must be named `middleware.ts` at `src/middleware.ts` (if using a `src/` directory) or project-root `middleware.ts` otherwise — same level as `app/`.

**A route isn't actually protected.** Check your `createRouteMatcher([...])` pattern actually matches the path, and that `config.matcher` at the bottom of `middleware.ts` isn't excluding it.

## Sign-in / sign-up pages

**404 on `/sign-in` or `/sign-up` itself.** Folder must be named with the double-bracket optional catch-all syntax exactly: `[[...sign-in]]` / `[[...sign-up]]`. This convention is unchanged in Next.js 16.

**404 after successful sign-in/up.** Expected until you've built `/dashboard` (Part 8) — not a bug before that point.

**Verification email never arrives.** Check spam; use Clerk Dashboard → Users to manually verify a test account during development.

## Reading user/session data

**`user` is `null` / blank dashboard page.** Confirm the page/function is declared `async` and `currentUser()`/`auth()` calls are `await`ed — this is the Next.js 16 async-API rule again.

**`useUser()` stuck on loading forever.** Confirm `"use client";` is the first line of the file, and that `ClerkProvider` wraps the whole app in `layout.tsx`.

**TypeScript complains a value is possibly `null`.** Correct behavior for general-purpose Clerk functions — use optional chaining (`user?.firstName`) or an early-return guard.

## Custom auth UI (headless hooks)

**`signUp`/`signIn` is `undefined` when calling `.create()`.** Always guard with `if (!isLoaded) return;` before using `signUp`/`signIn` — they're undefined until Clerk finishes initializing client-side.

**`result.status === "missing_requirements"` after `signUp.create()`.** Your Clerk Dashboard settings require a field your form doesn't collect (e.g. username) — either disable that requirement in the dashboard or extend your form.

**Password rejected as "breached."** Clerk checks against known breached-password lists by default — use a more unique test password.

## Appearance / theming

**Appearance changes don't show up.** Restart the dev server and hard-refresh the browser (Cmd/Ctrl+Shift+R).

**`elements` class overrides don't apply.** Confirm you're targeting the correct internal element key (e.g. `formButtonPrimary`) — check Appendix D for the docs link with the full list.

## Organizations

**`OrganizationSwitcher` doesn't render or errors.** Confirm Organizations is enabled in Clerk Dashboard → Organizations.

**`orgId` is always `null`.** No organization is currently active — select/create one via the switcher, or intentionally "Personal account" is selected.

## Roles & permissions

**Both admin and member see an admin-only UI section.** Check the exact string comparison: `orgRole === "org:admin"` (note the `org:` prefix — a common typo is comparing to `"admin"` alone).

**A Server Action succeeds even for a non-admin.** You forgot to re-check `orgRole` (or similar) *inside* the Server Action itself — client-side hiding is not real security, see Part 12.

## Webhooks

**"Invalid signature" every time.** `CLERK_WEBHOOK_SECRET` doesn't match the specific endpoint you're receiving from — recopy it from the correct endpoint in Clerk Dashboard → Webhooks, and restart the dev server.

**Webhook never arrives locally.** Your ngrok tunnel likely expired or restarted with a new URL — update the endpoint URL registered in Clerk Dashboard to match.

**Body parsing / verification errors.** Use `req.text()` for the raw body, never `req.json()`, before passing to `wh.verify()`.

**Error or unexpected type around the result of `headers()` in the webhook route.** `headers()` from `next/headers` is async in Next.js 16 — you must write `const headerPayload = await headers();`. This is the most common webhook-specific mistake; see Part 13 and Appendix A (Note 4 of 4).

## Deployment

**Vercel build fails on type/lint errors that didn't show locally.** Run `npm run build` locally before pushing — production builds (via Turbopack) are stricter than the dev server.

**Vercel build fails citing an unsupported Node.js version.** Vercel normally auto-selects a compatible Node runtime, but if you've manually pinned an old version in project settings, update it to 20.x or 22.x.

**Clerk errors only in production, not locally.** A required environment variable is missing or mistyped in Vercel's project settings — double check every key from Appendix B, and redeploy after any change (env var edits require a new deployment).

**Webhook Message Attempts show `500`/`401` in production.** `500` → check Vercel's function logs for an unhandled error in your route handler (often the missing-`await headers()` mistake). `401`/`400` → `CLERK_WEBHOOK_SECRET` in Vercel doesn't match your production endpoint's actual secret.

## Still stuck?

If none of the above matches your issue: re-read the specific Part's own Troubleshooting section (they contain more context for that step), check the browser console and terminal output carefully for the exact error message, and consult Appendix D for links to Clerk's official docs (including their Next.js quickstart, which is kept current for each new major Next.js release) and community support channels.
