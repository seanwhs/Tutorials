# Part 1: Architecture & Local Workspace Bootstrapping

By the end of this part, you will have: a running Next.js 16 app styled with Tailwind CSS, a local Sanity Studio embedded inside that same app with real `course`/`chapter`/`lesson` schemas, a live Neon PostgreSQL database, and a Prisma schema modeling `User`, `Enrollment`, and `Progress` — fully migrated and ready to query.

## 1.0 System Design Recap (Read Before Coding)

**The Concept:** Recall from Part 0 that Greymatter splits its data into two brains. Here's the exact request lifecycle diagram again, because every folder we create in this part maps directly onto one node in this diagram:

```
[Student Request] ──► Next.js Edge Middleware (Clerk Session Check)
│
▼
[App Router Page] (RSC)
│
┌───────────────┴───────────────┐
▼                               ▼
[Parallel Fetch A]              [Parallel Fetch B]
Sanity Content CDN             Neon DB User Progress
│                               │
└───────────────┬───────────────┘
▼
Combined Server Render
│
▼
[Dynamic Component Resolution] (RSC)
Maps Sanity customModule.moduleType
to imported Client chunk via React.lazy
```

Greymatter strictly segregates static assets, read-heavy structures, and transactional data specifically so a course page renders in under 100ms even under load [1]. In this part, "Parallel Fetch A" (Sanity) and "Parallel Fetch B" (Neon) both get built — but as two completely independent systems, so neither one knows the other exists yet. That's intentional; we're building foundations before wiring them together in Part 2.

---

## Step 1: Initialize the Next.js 16 Workspace with Tailwind CSS

**The Target:** A running Next.js 16 application, written in TypeScript, using the App Router, styled with Tailwind CSS, living inside your existing `greymatter-lms` folder from Part 0.

**The Concept:** `create-next-app` is a scaffolding tool — think of it like ordering a pre-assembled furniture frame instead of cutting your own wood. It gives you a working skeleton (build tooling, TypeScript config, folder conventions) so you spend your time on Greymatter's actual features, not on reinventing bundler configuration.

**The Implementation:**

Since we already have a git-initialized folder from Part 0, run the scaffolder *inside* it:

```bash
cd greymatter-lms
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir=false --import-alias "@/*"
```

You'll be prompted with a couple of confirmations since the folder isn't empty (it has `.gitignore` and `.env.example`) — answer **Yes** to continue.

This generates (among other files) the following key files. Let's look at what matters:

#### `package.json` (relevant excerpt after scaffolding)
```json
{
  "name": "greymatter-lms",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint"
  },
  "dependencies": {
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "tailwindcss": "^4.0.0",
    "@tailwindcss/postcss": "^4.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^16.0.0"
  }
}
```

#### `app/globals.css`
Tailwind CSS v4 uses a **CSS-first configuration** — instead of a separate `tailwind.config.js` listing theme colors, you declare them directly inside your CSS using an `@theme` block. Replace the generated file with this, which adds Greymatter's brand color tokens:

```css
@import "tailwindcss";

@theme {
  /* Greymatter brand palette — used across buttons, sidebar, and accents */
  --color-brand-50: #f4f5f7;
  --color-brand-500: #4b5563;
  --color-brand-600: #374151;
  --color-brand-900: #111827;

  /* Semantic accent used for "lesson completed" checkmarks in Part 4 */
  --color-success-500: #22c55e;
}

body {
  background-color: var(--color-brand-50);
  color: var(--color-brand-900);
}
```

#### `app/layout.tsx`
```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Greymatter LMS",
  description: "A hybrid-architecture Learning Management System.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
```

#### `app/page.tsx`

```tsx
export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-4xl font-bold text-brand-900">
        Greymatter LMS
      </h1>
      <p className="text-brand-600 max-w-md text-center">
        Workspace bootstrapped successfully. Tailwind CSS v4 is wired up
        and rendering with our custom brand theme tokens.
      </p>
      <span className="rounded-full bg-success-500 px-4 py-1 text-sm font-medium text-white">
        Step 1 verified ✓
      </span>
    </main>
  );
}
```

**The Verification:** Start the dev server and confirm everything renders correctly before moving forward.

```bash
npm run dev
```

Open `http://localhost:3000` in your browser. You should see:
- A heading "Greymatter LMS" in dark gray (`brand-900`)
- Descriptive paragraph text in a lighter gray (`brand-600`)
- A green pill-shaped badge reading "Step 1 verified ✓"

If the badge is unstyled (plain black text, no green background), Tailwind isn't processing correctly — double check that `app/globals.css` is imported in `app/layout.tsx` and that the dev server was restarted after editing the CSS file.

Commit this checkpoint:

```bash
git add .
git commit -m "feat: bootstrap Next.js 16 workspace with Tailwind CSS v4"
```
