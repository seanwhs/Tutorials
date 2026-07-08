# Part 0: Introduction & Architecture

Welcome! In this series you'll build a **Freelancer Client Portal** from scratch — a real, working SaaS application where freelancers manage clients and clients get a polished portal to review and pay for work.

This series targets **Next.js 16** as the baseline throughout (App Router, React 19, Turbopack default, async dynamic APIs). This is Part 0 of a 15-part series (Parts 0–14) plus reference appendices.

## 1. What we're building

Two "sides" of one Next.js app, gated by role:

**Admin side (you, the freelancer)**
- Dashboard listing clients & projects
- Create/edit clients and projects
- Create proposals and send them to a client
- Create invoices and send them to a client
- Chat with any client, per project
- See payment status of invoices

**Client side (your customers)**
- Sign in to a portal scoped only to *their* data
- View their project(s)
- Review a proposal and Approve or Request Changes
- View invoices and pay outstanding ones via Stripe Checkout
- Chat with the admin (you), per project

## 2. Why this stack

| Tool | Why |
|---|---|
| **Next.js 16 (App Router)** | One codebase for pages, API routes (via tRPC), and server-side rendering. React 19, Turbopack default dev/build bundler. |
| **tRPC** | End-to-end typesafe API calls without hand-writing REST/OpenAPI. Your frontend autocompletes your backend. |
| **Prisma (6+)** | Typesafe ORM. Define your schema once, get a typed client, run migrations safely. |
| **Neon (Postgres)** | Free-tier serverless Postgres. Scales to zero, perfect for side projects. |
| **Clerk** | Drop-in auth with hosted UI, session management, and metadata for roles (admin vs client). Uses current async `auth()`/`clerkMiddleware()`. |
| **UploadThing** | Simple, typesafe file uploads without managing S3 directly. |
| **Resend** | Developer-friendly transactional email API. |
| **Stripe** | Stripe Checkout (hosted payment page) + webhooks — minimal PCI-compliance surface area. |
| **Tailwind CSS v4 + shadcn/ui** | CSS-first config (no `tailwind.config.js`) + ownable component primitives. |
| **Vercel** | Zero-config deploys, generous free tier. |

## 3. Runtime requirement: Node.js

Next.js 16 requires **Node.js 20.9 or newer**. Node 22 (current LTS) is recommended. Node 18 has reached end-of-life and will not run Next.js 16 — Part 1 has you verify your Node version as its very first step.

## 4. High-level architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Next.js 16 App (Turbopack)                │
│  ┌───────────────┐        ┌────────────────────────────┐    │
│  │  App Router    │        │        tRPC API           │    │
│  │  Pages (RSC)   │◄──────►│  routers/*.ts (typesafe)   │    │
│  │  /admin/*      │        │  clients, projects,        │    │
│  │  /portal/*     │        │  proposals, invoices,      │    │
│  └───────┬───────┘        │  messages, uploads         │    │
│          │                └─────────────┬──────────────┘    │
│          │                              │                   │
│    ┌─────▼─────┐                  ┌─────▼──────┐            │
│    │  Clerk     │                  │  Prisma     │            │
│    │  (auth)    │                  │  Client     │            │
│    └────────────┘                  └─────┬──────┘            │
│                                            │                  │
└────────────────────────────────────────────┼──────────────────┘
                                             │
                    ┌────────────────────────┼───────────────────┐
                    │                        ▼                   │
              ┌─────▼─────┐          ┌───────────────┐    ┌───────▼──────┐
              │   Neon     │          │  UploadThing  │    │   Stripe     │
              │  Postgres  │          │  (file store) │    │  (payments)  │
              └────────────┘          └───────────────┘    └──────────────┘
                                                                    │
                                                             ┌──────▼──────┐
                                                             │   Resend    │
                                                             │  (emails)   │
                                                             └─────────────┘
```

**Key idea:** Every piece of data flows through **tRPC procedures**, which use **Prisma** to talk to **Postgres**. The UI never queries the database directly — always through typesafe tRPC calls. This keeps authorization logic in one place: the tRPC procedure.

## 5. The Next.js 16 async-params pattern (used constantly from Part 5 onward)

Next.js 16 treats dynamic route `params`, `searchParams`, and Clerk's `headers()`/`cookies()`/`auth()` helpers as asynchronous:

```ts
// Any dynamic [id] page, e.g. src/app/admin/clients/[id]/page.tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  // ...
}
```

```ts
// Any dynamic API route, e.g. src/app/api/webhooks/clerk/route.ts
import { headers } from "next/headers";

export async function POST(req: Request) {
  const headerPayload = await headers();
  // ...
}
```

Forgetting the `await` is the single most common mistake when following this series.

## 6. Data model preview

Built over Parts 3, 5, 6, 7, 8, 9: `User`, `Client`, `Project`, `Proposal`, `Invoice`/`InvoiceItem`, `Message`, `Attachment`. Full schema in Part 3 and Appendix C.

## 7. Roles & authorization model

- Every Clerk user has `publicMetadata.role` = `"ADMIN"` or `"CLIENT"`.
- Exactly **one admin** (you) for MVP.
- A `CLIENT` user links to exactly one `Client` record via `Client.userId`.
- Every tRPC procedure checks: is the caller ADMIN, or the CLIENT who owns this record?

## 8. What "done" looks like

By the end of Part 13: sign in as admin, create a client/project/proposal/invoice; client signs in, approves proposal, pays invoice via Stripe test card; emails fire at each step; both parties chat on the project page.

## 9. How this tutorial is organized

Each part: **Concept → Schema changes → Server logic (tRPC) → UI → Checkpoint**. Code blocks always start with a file-path comment.

## Next

Continue to **Part 1: Dev Environment & Project Setup**.
