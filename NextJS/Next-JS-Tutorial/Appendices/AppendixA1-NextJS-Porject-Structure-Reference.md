# Appendix A1 — Next.js 16 Project Structure Reference

## The Complete Guide to Organizing Next.js Applications

> **Purpose:** This appendix serves as the canonical reference for organizing, structuring, and scaling Next.js 16 applications from small projects to enterprise systems.

---

# Introduction

One of the biggest mistakes beginners make is believing that project structure doesn't matter.

For small applications:

```text
100 files
```

almost any structure works.

For large applications:

```text
10,000 files
```

project structure becomes architecture.

---

# The First Rule of Project Structure

Folders are not for organizing files.

Folders are for organizing:

```text
Ownership

Responsibilities

Dependencies

Complexity
```

---

# The Evolution of Next.js Projects

Most developers progress through several stages.

---

## Stage 1 — Beginner Project

```text
my-app/

├── app/
├── components/
├── lib/
└── public/
```

Suitable for:

```text
Tutorials
Portfolios
Small projects
```

---

## Stage 2 — Intermediate Project

```text
my-app/

├── app/
├── components/
├── hooks/
├── lib/
├── types/
├── services/
├── actions/
└── public/
```

Suitable for:

```text
Small SaaS
Dashboards
Internal tools
```

---

## Stage 3 — Professional Project

```text
my-app/

├── app/
├── modules/
├── shared/
├── infrastructure/
├── services/
├── lib/
├── types/
├── tests/
└── public/
```

Suitable for:

```text
Production applications
Teams
Long-term projects
```

---

## Stage 4 — Enterprise Project

```text
my-app/

├── app/
├── domains/
├── infrastructure/
├── platform/
├── shared/
├── testing/
├── tools/
├── docs/
└── scripts/
```

Suitable for:

```text
Large teams
Multiple products
Enterprise systems
```

---

# The Official Next.js 16 Structure

A modern Next.js 16 application often looks like:

```text
my-app/

├── app/
├── components/
├── lib/
├── public/
├── middleware.ts
├── next.config.ts
├── package.json
├── tsconfig.json
└── .env
```

Let's examine each piece.

---

# The app/ Directory

The `app` directory is the heart of Next.js.

```text
app/

├── page.tsx
├── layout.tsx
├── loading.tsx
├── error.tsx
└── not-found.tsx
```

Think of it as:

```text
Application Router
        +
UI Tree
        +
Rendering Engine
```

---

# Example

```text
app/

├── page.tsx
├── about/
│   └── page.tsx
├── blog/
│   ├── page.tsx
│   └── [slug]/
│       └── page.tsx
└── dashboard/
    └── page.tsx
```

Creates:

```text
/
/about
/blog
/blog/post
/dashboard
```

---

# page.tsx

Represents:

```text
A route.
```

Example:

```tsx
export default function HomePage() {
  return (
    <h1>Hello World</h1>
  );
}
```

---

# layout.tsx

Represents:

```text
Shared UI.
```

Example:

```tsx
export default function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <nav>Navbar</nav>
      {children}
    </>
  );
}
```

---

# loading.tsx

Represents:

```text
Loading UI.
```

Example:

```tsx
export default function Loading() {
  return <p>Loading...</p>;
}
```

---

# error.tsx

Represents:

```text
Error boundaries.
```

Example:

```tsx
"use client";

export default function Error() {
  return (
    <h1>
      Something went wrong
    </h1>
  );
}
```

---

# not-found.tsx

Represents:

```text
404 pages.
```

Example:

```tsx
export default function NotFound() {
  return (
    <h1>404</h1>
  );
}
```

---

# route.ts

Represents:

```text
API endpoints.
```

Example:

```text
app/api/users/route.ts
```

```ts
export async function GET() {
  return Response.json({
    users: [],
  });
}
```

---

# Dynamic Routes

Example:

```text
app/blog/[slug]/page.tsx
```

URLs:

```text
/blog/hello
/blog/world
/blog/nextjs
```

---

# Catch-All Routes

Example:

```text
app/docs/[...slug]/page.tsx
```

Matches:

```text
/docs
/docs/api
/docs/api/auth
/docs/api/auth/login
```

---

# Route Groups

Example:

```text
app/

(auth)/
(marketing)/
(admin)/
```

These folders:

```text
DO NOT
appear
in URLs.
```

---

# Example

```text
app/

(marketing)/

    about/page.tsx

(admin)/

    dashboard/page
```
