## AI SaaS Tutorial - Part 1: Project Setup (Next.js 16)

### Goal
Create a new Next.js 16 App Router project with TypeScript and Tailwind CSS v4, and set up the base repo structure we'll use for the rest of the series.

### Step 0. Verify Node.js version
Next.js 16 requires Node.js 20.9+ or 22 LTS. Node 18 is end-of-life and will not work.
```bash
node -v
```
If below 20.9, install Node 22 LTS from nodejs.org before continuing.

### 1. Create the project
```bash
npx create-next-app@latest acme-docs-ai
```
When prompted, choose:
- TypeScript: Yes
- ESLint: Yes
- Tailwind CSS: Yes
- src/ directory: Yes
- App Router: Yes
- Turbopack: Yes (default in Next.js 16)
- Import alias: Yes (@/*)

```bash
cd acme-docs-ai
```

### 2. Verify it runs
```bash
npm run dev
```
Visit http://localhost:3000 — you should see the default Next.js welcome page, served via Turbopack.

**Checkpoint:** if you see the Next.js starter page with no errors in the terminal.

### 3. Confirm Tailwind CSS v4's CSS-first config
Next.js 16 scaffolds with Tailwind CSS v4, which no longer uses `tailwind.config.js` by default. Open `src/app/globals.css` and confirm it looks like this:
```css
@import "tailwindcss";

@theme {
  --color-brand: #4f46e5;
}
```
There is no `tailwind.config.js` file, and none is required. If you want custom design tokens (colors, fonts, spacing), define them inside the `@theme` block directly in CSS using custom properties — Tailwind v4 picks these up automatically. We won't need heavy customization for this project, but this is where you'd add it (e.g. `--color-brand` above is used later for buttons/links for a consistent accent color).

### 4. Clean up the starter template
Replace `src/app/page.tsx` with a placeholder:
```tsx
export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8">
      <h1 className="text-4xl font-bold">Acme Docs AI</h1>
      <p className="mt-2 text-gray-600">Chat with your documents.</p>
    </main>
  );
}
```

### 5. Repo structure we'll build toward
```
acme-docs-ai/
├── prisma/
│   └── schema.prisma
├── src/
│   ├── app/
│   │   ├── (marketing)/
│   │   ├── sign-in/[[...sign-in]]/
│   │   ├── sign-up/[[...sign-up]]/
│   │   ├── (dashboard)/
│   │   │   └── workspaces/[workspaceId]/
│   │   │       ├── documents/
│   │   │       ├── chat/
│   │   │       └── billing/
│   │   └── api/
│   │       ├── webhooks/
│   │       │   ├── clerk/
│   │       │   └── stripe/
│   │       ├── uploadthing/
│   │       ├── documents/process/
│   │       └── chat/
│   ├── components/
│   ├── lib/
│   │   ├── db.ts
│   │   ├── workspace.ts
│   │   ├── ai/
│   │   ├── billing/
│   │   └── rag/
│   └── middleware.ts
├── .env.local
└── package.json
```
We'll create these folders incrementally in later parts — no need to create empty folders now.

### 6. Initialize git
```bash
git init
git add -A
git commit -m "Initial Next.js 16 + Tailwind v4 setup"
```
Create a GitHub repo (via github.com/new) and push:
```bash
git remote add origin <your-repo-url>
git branch -M main
git push -u origin main
```

### 7. Install the core dependencies we'll need across the series
```bash
npm install @clerk/nextjs @prisma/client prisma ai @ai-sdk/openai-compatible @ai-sdk/react zod uploadthing @uploadthing/react stripe svix pdf-parse
npm install -D @types/node
```

Notes on packages:
- **@clerk/nextjs** — auth + Organizations (multi-tenancy), fully compatible with Next.js 16's async `auth()` API
- **prisma / @prisma/client** — database ORM, Prisma 6+ recommended for best Next.js 16/TypeScript 5+ compatibility
- **ai / @ai-sdk/react** — Vercel AI SDK core + React hooks
- **@ai-sdk/openai-compatible** — lets us point the AI SDK at any OpenAI-compatible free endpoint (Groq, OpenRouter, local Ollama all expose OpenAI-compatible APIs)
- **zod** — input validation
- **uploadthing / @uploadthing/react** — file uploads
- **stripe** — billing
- **svix** — Clerk webhook signature verification
- **pdf-parse** — PDF text extraction (used starting Part 6)

**Checkpoint:** `npm run dev` still works, `git log` shows your first commit, dependencies installed with no errors, and `globals.css` uses the `@import "tailwindcss"` + `@theme` pattern (no `tailwind.config.js` present).

**Next:** Part 2 — Database Schema (Prisma + Postgres + pgvector).
