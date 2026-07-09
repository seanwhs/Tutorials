## AI SaaS Tutorial - Appendix C: Troubleshooting Guide

### Next.js 16 specific issues

**Problem:** "params.workspaceId is undefined" or a TypeScript error about params not having the expected shape
**Fix:** In Next.js 16, `params` is a Promise. Every dynamic page in this series must destructure it as: `const { workspaceId } = await params;` after typing the prop as `params: Promise<{ workspaceId: string }>`. Accessing `params.workspaceId` directly (without await) is a leftover Next.js 14/15 pattern and will not work.

**Problem:** `TypeError: headers(...).get is not a function`, or similar in a webhook route
**Fix:** `headers()` is async in Next.js 16 — you must await `headers()` before calling `.get()` on it. Check both `src/app/api/webhooks/clerk/route.ts` and `src/app/api/webhooks/stripe/route.ts` for a missing `await`.

**Problem:** App fails to start with an engine/version error, or Vercel build fails immediately
**Fix:** Confirm `node -v` is 20.9+ or 22 LTS locally, and check Vercel Project Settings → General → Node.js Version is not pinned to 18.x.

**Problem:** Tailwind classes aren't applying, or you get an error referencing `tailwind.config.js`
**Fix:** This project uses Tailwind CSS v4's CSS-first config — there is no `tailwind.config.js`. Confirm `src/app/globals.css` contains `@import "tailwindcss";` (and optionally an `@theme` block) — don't try to create or reference a `tailwind.config.js` file from an older tutorial or template.

### Database / Prisma

**Problem:** "relation Chunk does not exist" or migration errors mentioning vector type
**Fix:** Make sure you ran `CREATE EXTENSION IF NOT EXISTS vector;` in the Neon SQL editor BEFORE running `npx prisma migrate dev`. Prisma cannot create the extension itself.

**Problem:** Insert into Chunk fails with a dimension mismatch error
**Fix:** Your `EMBEDDING_MODEL`'s output dimension must exactly match the `vector(768)` column. If you switch embedding models, update both the Prisma migration column type and re-check the model's actual output dimension — they must match exactly or inserts will fail.

**Problem:** `npx prisma studio` shows tables but `Chunk.embedding` always looks empty/null in the UI
**Fix:** This is often just how Prisma Studio renders the `Unsupported` vector type. Confirm real data with a raw SQL check: `SELECT id, embedding IS NOT NULL as has_embedding FROM "Chunk";` via the Neon SQL editor.

### Clerk / Auth

**Problem:** `auth.protect()` redirects even on public routes
**Fix:** Double check your `isPublicRoute` matcher in `middleware.ts` includes the exact route pattern — route groups like `(marketing)` do not appear in the URL path, so match against the actual rendered path, not the folder name.

**Problem:** Webhook signature verification fails locally
**Fix:** Make sure you are using ngrok (or similar) to expose localhost, and that `CLERK_WEBHOOK_SIGNING_SECRET` matches the specific endpoint you registered — each endpoint gets its own secret.

**Problem:** User signs up but no row appears in your User table
**Fix:** Confirm the webhook endpoint is registered and subscribed to `user.created`, and check your server logs for errors during svix verification. Also confirm `CLERK_WEBHOOK_SIGNING_SECRET` is set in the same environment (local vs. deployed) you are testing in.

### Uploads / Processing

**Problem:** Document status stays stuck on PROCESSING forever
**Fix:** Check server logs for errors in `/api/documents/process`. Common causes: `NEXT_PUBLIC_APP_URL` is wrong (the fire-and-forget fetch from `onUploadComplete` cannot reach your own app), or the embedding provider is unreachable (Ollama not running, or a bad `EMBEDDING_BASE_URL`/API key).

**Problem:** PDF text extraction returns empty/garbled text
**Fix:** Some PDFs are scanned images with no real text layer — `pdf-parse` cannot extract text from an image. This tutorial's pipeline does not include OCR; scanned PDFs will fail extraction and the document will be marked FAILED, which is expected behavior, not a bug.

**Problem:** Upload fails immediately with "Document limit reached"
**Fix:** This is the Part 13 plan limit working as intended. Either delete existing documents, or upgrade the workspace to Pro via the billing page.

### Chat / RAG

**Problem:** Chat answers ignore the uploaded documents entirely
**Fix:** Confirm the document's status is READY (not PROCESSING/FAILED) — retrieval only searches READY documents. Also verify chunks actually have embeddings (see the Prisma/Database section above).

**Problem:** Chat says "I don't know based on the uploaded documents" even though the answer is clearly in there
**Fix:** Try lowering `minSimilarity` in `retrieve.ts` (Part 8) — the default 0.65 threshold may be too strict for your embedding model or phrasing. Also try increasing `topK` from 5 to a higher number.

**Problem:** Streaming never starts / hangs
**Fix:** Check that `CHAT_BASE_URL` / `GROQ_API_KEY` / `OPENROUTER_API_KEY` match the model you selected in the dropdown — each provider requires its own key, and the Part 11 provider factory throws if a required key is missing (check server logs for this specific error).

### Billing

**Problem:** Workspace plan does not flip to PRO after Checkout
**Fix:** Confirm the Stripe CLI is running (`stripe listen --forward-to localhost:3000/api/webhooks/stripe`) during local testing, and that `STRIPE_WEBHOOK_SECRET` matches the value the CLI printed. In production, check the Stripe dashboard's Webhooks page for delivery attempts/errors.

**Problem:** "No billing account yet" error when clicking Manage Billing
**Fix:** This means no Subscription row with a `stripeCustomerId` exists yet — the workspace must go through Checkout at least once (even if you cancel) before a Billing Portal session can be created, since a Stripe customer is created during that flow.

### Deployment

**Problem:** App works locally but embeddings/chat fail after deploying to Vercel
**Fix:** This is almost always because `EMBEDDING_PROVIDER`/`EMBEDDING_BASE_URL` still points at `http://localhost:11434` (Ollama), which Vercel's serverless functions cannot reach. Switch to a hosted embeddings endpoint and a Groq/OpenRouter chat model for production, per Part 15.

**Problem:** Prisma client errors on Vercel about missing generated client
**Fix:** Ensure your build script runs `prisma generate` before `next build` (see the package.json snippet in Part 15).

