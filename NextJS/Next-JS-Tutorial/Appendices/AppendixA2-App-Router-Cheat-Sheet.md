# **Appendix A2 — Next.js 16 App Router Cheat Sheet**  
**The Complete Reference for the App Router**

> **Purpose:** This appendix is your daily quick-reference guide for the Next.js 16 App Router. Keep it handy while building — it covers routing, rendering, special files, patterns, and best practices in one place.

---

### Introduction

The **App Router** (introduced in Next.js 13 and matured in 16) is far more than a URL mapper.

**Old Mental Model:**
```text
Router = URL → Component
```

**Next.js 16 App Router:**
```text
URL Router
     + UI Composition Engine
     + Rendering Orchestrator
     + Data Fetching & Caching System
     + Streaming & Partial Prerendering Layer
```

It powers Server Components, nested layouts, streaming, and advanced caching out of the box.

---

### App Router Mental Model

**Traditional Frameworks:**
```text
Request → Route Handler → Response
```

**Next.js App Router:**
```text
URL
  ↓
Route Segment Tree
  ↓
Nested Layouts + Slots
  ↓
Page + Parallel Routes
  ↓
Server/Client Components
  ↓
Automatic Caching + Streaming
```

---

### Complete File System Conventions

```text
app/
├── layout.tsx          # Root layout (required)
├── page.tsx            # Page component
├── template.tsx        # Re-rendering wrapper
├── loading.tsx         # Suspense fallback
├── error.tsx           # Route error boundary
├── global-error.tsx    # Global error boundary
├── not-found.tsx       # 404 page
├── default.tsx         # Parallel route default
├── route.ts            # Route Handler (API)
├── globals.css
└── [folder]/
    └── page.tsx
```

---

### Core Special Files

#### `page.tsx` — The Page
Defines content for a specific URL.

**Static Example:**
```tsx
// app/page.tsx → /
export default function Home() {
  return <h1>Welcome</h1>;
}
```

**Dynamic Route:**
```tsx
// app/blog/[slug]/page.tsx
export default async function Post({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  return <h1>Post: {slug}</h1>;
}
```

**Supported Patterns:**
- `[slug]` → Dynamic segment
- `[...slug]` → Catch-all
- `[[...slug]]` → Optional catch-all

---

### `layout.tsx` — Persistent UI

Layouts wrap pages and **persist** across navigation (no re-render on route change).

```tsx
// app/layout.tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

**Nested Layout Example:**
```text
app/
├── dashboard/
│   ├── layout.tsx     # Applies to all /dashboard/*
│   └── page.tsx
```

**Layout Tree:**
```text
Root Layout
   ↓
Dashboard Layout
   ↓
Dashboard Page
```

---

### `template.tsx` — Force Re-render

Use when you need layouts to re-mount on navigation (e.g., animations, state reset).

**Difference Summary:**

| Feature     | `layout.tsx`       | `template.tsx`      |
|-------------|--------------------|---------------------|
| Persistence | Yes (recommended) | No                  |
| Re-renders  | Preserved          | On every navigation |
| Use Case    | Most layouts       | Entry animations    |

---

### Loading & Error States

#### `loading.tsx` — Instant Loading UI
Leverages React Suspense for streaming.

```tsx
export default function Loading() {
  return <div className="animate-pulse">Loading...</div>;
}
```

Nested `loading.tsx` files create granular loading states.

#### `error.tsx` — Route Error Boundary

```tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

#### `global-error.tsx` — Catastrophic Failures
Catches errors outside normal route boundaries. Must include `<html>` and `<body>`.

#### `not-found.tsx` — 404s

Trigger manually:
```ts
import { notFound } from "next/navigation";

if (!post) notFound();
```

---

### Route Handlers (`route.ts`)

For building APIs inside the App Router.

```ts
// app/api/users/route.ts
export async function GET() {
  return Response.json({ users: [] });
}

export async function POST(req: Request) {
  const body = await req.json();
  return Response.json(body, { status: 201 });
}
```

**Supported HTTP Methods:** `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`.

**Comparison:**
- **Route Handlers** → Traditional HTTP endpoints
- **Server Actions** → Form/submit-style function calls (`"use server"`)

---

### Advanced Routing Features

#### Route Groups `(folder)`
Organize routes without affecting the URL.

```text
app/
├── (marketing)/
│   └── about/page.tsx     → /about
├── (dashboard)/
│   └── analytics/page.tsx → /analytics
└── (auth)/login/page.tsx  → /login
```

#### Parallel Routes (`@slot`)
Render multiple independent pages in the same layout.

```text
app/
├── @feed/
├── @analytics/
├── @team/
└── layout.tsx
```

```tsx
export default function Layout({
  feed,
  analytics,
  team,
}: {
  feed: React.ReactNode;
  analytics: React.ReactNode;
  team: React.ReactNode;
}) {
  return (
    <div>
      {feed}
      {analytics}
      {team}
    </div>
  );
}
```

#### Intercepting Routes
Open content in modals while preserving history.

Prefixes: `(.)`, `(..)`, `(...)`

---

### Metadata & SEO

```ts
// Static
export const metadata = {
  title: "My App",
  description: "Next.js 16 App",
  openGraph: { images: [...] }
};

// Dynamic
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  return { title: slug };
}
```

**Static Generation:**
```ts
export async function generateStaticParams() {
  return [{ slug: "nextjs" }, { slug: "react" }];
}
```

---

### Middleware (`middleware.ts`)

Runs before requests.

```ts
import { NextResponse } from "next/server";

export function middleware(request: NextRequest) {
  // Auth, redirects, i18n, A/B testing, etc.
  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*"],
};
```

---

### Rendering & Caching (Next.js 16)

**Key Options:**
- `export const dynamic = "force-static" | "force-dynamic" | "auto";`
- `export const revalidate = 3600;` (ISR)
- `"use cache"` directive for Cache Components

**Partial Prerendering (PPR)** and improved caching make apps faster by default.

**Execution Order (Simplified):**
```text
middleware
   ↓
Root Layout
   ↓
Route Layouts
   ↓
Loading UI → Page Render → Streaming
```

---

### Quick Decision Tree

| Need                              | Use File              |
|-----------------------------------|-----------------------|
| Page content                      | `page.tsx`            |
| Persistent shared UI              | `layout.tsx`          |
| Force re-mount on navigation      | `template.tsx`        |
| Loading / streaming UI            | `loading.tsx`         |
| Route-specific error handling     | `error.tsx`           |
| App-wide fatal error              | `global-error.tsx`    |
| Custom 404                        | `not-found.tsx`       |
| API endpoint                      | `route.ts`            |
| Default Parallel Route content    | `default.tsx`         |

---

### Pro Tips for Next.js 16

- Prefer **Server Components** by default.
- Colocate route-specific code (use `_components`, `_lib` inside folders).
- Use **Route Groups** aggressively for clean organization.
- Leverage **Parallel + Intercepting Routes** for modern UIs (dashboards, modals).
- Enable **Turbopack** for lightning-fast dev experience.
- Combine with **Server Actions** for forms instead of traditional APIs when possible.

The App Router is not just routing — it is the **foundation** of modern Next.js applications.

*Updated for Next.js 16 — June 2026*
