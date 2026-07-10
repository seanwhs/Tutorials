# Part 7: Final Polish and Deployment

Goal: replace bare/missing states with proper loading, error, and empty states across the app, add navigation cohesion, then deploy to Vercel's free tier with all environment variables correctly configured.

## 1. Document processing status in the UI
Right now, uploading feels instant or stuck with no feedback while chunking/embedding/extraction run inline (Part 3/4). Add a small polling status indicator.

`src/app/api/documents/route.ts`:
```ts
import { NextResponse } from "next/server";
import { db } from "@/lib/db";

export async function GET() {
  const documents = await db.document.findMany({
    orderBy: { createdAt: "desc" },
    select: { id: true, fileName: true, status: true, createdAt: true },
    take: 20,
  });

  return NextResponse.json({ documents });
}
```

`src/components/document-list.tsx`:
```tsx
"use client";

import { useEffect, useState } from "react";
import { Badge } from "@/components/ui/badge";

interface DocumentRow {
  id: string;
  fileName: string;
  status: "PENDING" | "CHUNKING" | "EXTRACTING" | "DONE" | "FAILED";
  createdAt: string;
}

const STATUS_VARIANT: Record<DocumentRow["status"], "default" | "secondary" | "destructive" | "outline"> = {
  PENDING: "outline",
  CHUNKING: "secondary",
  EXTRACTING: "secondary",
  DONE: "default",
  FAILED: "destructive",
};

export function DocumentList() {
  const [documents, setDocuments] = useState<DocumentRow[]>([]);

  useEffect(() => {
    let active = true;

    async function poll() {
      const res = await fetch("/api/documents");
      const data = await res.json();
      if (active) setDocuments(data.documents);
    }

    poll();
    const interval = setInterval(poll, 4000);
    return () => {
      active = false;
      clearInterval(interval);
    };
  }, []);

  if (documents.length === 0) {
    return <p className="text-sm text-muted-foreground">No documents uploaded yet.</p>;
  }

  return (
    <ul className="space-y-1">
      {documents.map((doc) => (
        <li key={doc.id} className="flex items-center justify-between text-sm">
          <span>{doc.fileName}</span>
          <Badge variant={STATUS_VARIANT[doc.status]}>{doc.status}</Badge>
        </li>
      ))}
    </ul>
  );
}
```

Why polling every 4 seconds instead of a websocket/SSE setup: for a free-tier, beginner-scoped PoC, a simple interval poll is far simpler to reason about and deploy than a persistent connection, and 4 seconds is fast enough to feel responsive for a background pipeline that itself takes several seconds per chunk. A real production system with many concurrent users would eventually move this to Server-Sent Events or a webhook-driven update.

Add `<DocumentList />` under the upload form in `src/app/page.tsx`.

## 2. Loading and empty states with shadcn Skeleton
Update the graph view (Part 5) to show a proper skeleton instead of a plain "Loading graph..." string.

`src/components/graph-view.tsx` (replace the loading branch):
```tsx
if (isLoading) {
  return (
    <div className="space-y-3 p-8">
      <Skeleton className="h-6 w-48" />
      <Skeleton className="h-[60vh] w-full" />
    </div>
  );
}
```
Add the import: `import { Skeleton } from "@/components/ui/skeleton";`

## 3. Error boundaries
App Router supports per-route error boundaries automatically via an `error.tsx` file.

`src/app/graph/error.tsx`:
```tsx
"use client";

import { Button } from "@/components/ui/button";

export default function GraphError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="mx-auto max-w-md px-6 py-16 text-center">
      <h2 className="text-lg font-semibold">Something went wrong loading the graph</h2>
      <p className="mt-2 text-sm text-muted-foreground">{error.message}</p>
      <Button className="mt-4" onClick={reset}>
        Try again
      </Button>
    </div>
  );
}
```

This catches unexpected render-time errors specifically within the `/graph` route segment without crashing the whole app — a good safety net given the graph view depends on a third-party canvas library and a network fetch, both potential failure points.

## 4. Global navigation
`src/app/layout.tsx` (add a simple nav header inside the body, above `{children}`):
```tsx
import Link from "next/link";

// ... inside the <body> of the existing RootLayout, before {children}:
<header className="border-b">
  <nav className="mx-auto flex max-w-6xl items-center gap-4 px-6 py-3 text-sm">
    <Link href="/" className="font-semibold">Cortex</Link>
    <Link href="/" className="text-muted-foreground hover:text-foreground">Upload & Search</Link>
    <Link href="/graph" className="text-muted-foreground hover:text-foreground">Graph</Link>
  </nav>
</header>
```

## 5. Guard against missing environment variables at startup
A common deployment failure mode is discovering a missing env var only when a user hits a broken feature in production. Add a small check that fails loudly and early instead.

`src/lib/env-check.ts`:
```ts
const REQUIRED_ENV_VARS = ["DATABASE_URL", "DIRECT_URL"] as const;

export function checkRequiredEnv() {
  const missing = REQUIRED_ENV_VARS.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(", ")}. ` +
      `Check your .env.local (dev) or Vercel project settings (production).`
    );
  }
}
```

Call `checkRequiredEnv()` at the top of `src/lib/db.ts`, right before the `PrismaClient` is constructed, so a misconfigured deployment fails with a clear message on the very first database access rather than a cryptic Prisma connection error deep in a request.

## 6. Pre-deployment checklist
- [ ] `npm run build` succeeds locally with zero errors.
- [ ] Every env var used in code has a corresponding entry ready for Vercel (full list in Appendix A).
- [ ] Confirm your chosen LLM/embedding setup works from a non-localhost environment: if you were using local Ollama for embeddings and/or extraction during development, you must switch `EXTRACTION_MODEL_ID` to a hosted free provider (Groq or OpenRouter) before deploying, since Vercel's servers cannot reach `localhost:11434` on your machine. The same applies to `OLLAMA_BASE_URL`-based embeddings — either point it at a hosted Ollama-compatible embedding endpoint, or swap in a hosted free embedding API for production.
- [ ] `.env.local` is confirmed gitignored (checked in Part 1) so no secrets are committed.

## 7. Push to GitHub
```bash
git init
git add .
git commit -m "Cortex - Context-Aware Knowledge Graph Manager"
gh repo create cortex-kg-manager --public --source=. --push
```
(Or push manually to a repo created via github.com if you don't have the `gh` CLI.)

## 8. Deploy to Vercel
```bash
npm install -g vercel
vercel login
vercel
```
Answer the prompts (link to existing project: No; project name: cortex-kg-manager; directory: ./; override settings: No — Next.js is auto-detected).

Then set environment variables for the production deployment:
```bash
vercel env add DATABASE_URL
vercel env add DIRECT_URL
vercel env add GROQ_API_KEY
vercel env add OPENROUTER_API_KEY
vercel env add DEFAULT_MODEL_ID
vercel env add EXTRACTION_MODEL_ID
vercel env add OLLAMA_BASE_URL
```
For each, paste the production-appropriate value when prompted (remember: swap any `localhost` Ollama references for a hosted equivalent, per the checklist above, unless you've set up a publicly reachable Ollama instance).

Deploy to production:
```bash
vercel --prod
```

## 9. Run the Prisma migration against production
Vercel's build step does not run `prisma migrate deploy` unless you tell it to. Add it to the build command.

`package.json` (update the `"build"` script):
```json
"scripts": {
  "build": "prisma generate && prisma migrate deploy && next build"
}
```
Commit this change and redeploy (`vercel --prod`) so future pushes automatically apply pending migrations to the Neon production database before building.

## 10. Final verification checkpoint
1. Visit your `*.vercel.app` production URL.
2. Upload a real document end-to-end in production.
3. Confirm the document list status progresses to `DONE`, the graph renders the new nodes/edges, and a semantic search against the new content returns relevant results with related node badges.
4. Check Vercel's function logs (Vercel dashboard -> your project -> Logs) for any runtime errors, particularly around missing env vars or unreachable Ollama URLs — the most common first-deploy failure for this project.

Next: Appendix A - Full Codebase Reference and Environment Variables.
