# Next.js 16 for Absolute Beginners

# Part 28 — Building Nexus CMS: Project Setup, Repository Architecture, and Engineering Foundations

> **Goal of this lesson:** Create the foundation of our production-grade Nexus CMS by setting up Next.js 16, TypeScript, PostgreSQL, Prisma, project architecture, development workflow, and engineering conventions.

***

# Welcome to Real Software Engineering

Most tutorials begin like this:

```bash
npx create-next-app
```

Then they jump straight to:

```text
Build a Todo App
```

Professional engineering starts differently:

```text
Requirements
       |
Architecture
       |
Repository Design
       |
Tooling
       |
Conventions
       |
Implementation
```

That order matters because many software failures are architectural failures, not coding failures.

***

# What We're Building

By the end of this capstone, we'll have:

```text
                    Nexus CMS
                         |
         +---------------+---------------+
         |               |               |
         V               V               V
     Public Site     Dashboard        APIs
         |               |               |
         +---------------+---------------+
                         |
                    PostgreSQL
```

This is a real application shape: one product, multiple surfaces, shared data, and clear boundaries.

***

# Step 1 — Create the Project

Open your terminal:

```bash
npx create-next-app@latest nexus-cms
```

Choose:

```text
✔ TypeScript?           Yes
✔ ESLint?               Yes
✔ Tailwind?             Yes
✔ src directory?        No
✔ App Router?           Yes
✔ Turbopack?            Yes
✔ Import alias?         @/*
```

These defaults give us a modern, production-friendly starting point.

***

# Why These Choices

### TypeScript

Because correctness matters more than convenience.

TypeScript helps us catch mistakes earlier and scale the codebase more safely.

### App Router

Because Next.js 16 is built around:

```text
Server Components
Server Actions
Cache Components
```

### Tailwind

Because it reduces CSS overhead and keeps UI development fast and consistent.

***

# Enter the Project

```bash
cd nexus-cms
```

***

# Install Dependencies

Install the core runtime packages:

```bash
npm install \
@prisma/client \
bcryptjs \
zod \
uuid \
date-fns
```

Install development tools:

```bash
npm install -D \
prisma \
tsx \
dotenv-cli
```

***

# Why These Packages

| Package | Purpose |
| --- | --- |
| Prisma | Database ORM |
| bcryptjs | Password hashing |
| zod | Validation |
| uuid | Unique IDs |
| date-fns | Date formatting |
| tsx | TypeScript scripts |

Each package supports a concrete engineering need, not just a tutorial demo.

***

# Step 2 — Enable Cache Components

Open:

```text
next.config.ts
```

Add:

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  cacheComponents: true,
};

export default nextConfig;
```

This matters because Next.js 16 centers its rendering model around Cache Components and explicit caching behavior. [nextjs](https://nextjs.org/blog/next-16)

***

# Step 3 — Initialize Git

```bash
git init
git add .
git commit -m "Initial commit"
```

Commit early so you always have a safe rollback point.

Small commits make development easier to understand, review, and recover.

***

# Step 4 — Create the Architecture

Delete unnecessary files and create a structure organized by responsibility:

```text
nexus-cms/

├── app/
├── components/
├── actions/
├── auth/
├── db/
├── hooks/
├── lib/
├── services/
├── types/
├── tests/
├── docs/
├── prisma/
├── public/
└── scripts/
```

Beginners often organize by file type.

Professionals organize by responsibility.

***

# Layered Structure

```text
                    Application
                          |
        +-----------------+-----------------+
        |                 |                 |
        V                 V                 V
     UI Layer      Domain Layer     Data Layer
```

This makes the project easier to reason about as it grows.

***

# Folder Roles

## Components

```text
components/
  ui/
  forms/
  dashboard/
  blog/
  shared/
```

Use this for reusable UI and feature-specific visual pieces.

## Actions

```text
actions/
  auth/
  posts/
  comments/
  uploads/
```

Use this for server-side mutations and application workflows.

## Services

```text
services/
  search/
  email/
  storage/
  analytics/
```

Use this for integrations and external systems.

## Docs

```text
docs/
  architecture/
  adr/
  api/
  deployment/
```

Use this to capture decisions before they are forgotten.

***

# Step 5 — Create Environment Variables

Create:

```bash
touch .env
touch .env.example
```

### `.env`

```bash
DATABASE_URL=

AUTH_SECRET=

APP_URL=http://localhost:3000

NODE_ENV=development
```

### `.env.example`

```bash
DATABASE_URL=

AUTH_SECRET=

APP_URL=
```

Never commit `.env` to Git.

***

# Update `.gitignore`

```gitignore
.env
.env.local
.env.production
```

This protects secrets from accidental exposure.

***

# Step 6 — Set Up PostgreSQL

We'll use PostgreSQL because it gives us:

```text
Transactions
Relations
Reliability
Maturity
```

That makes it a strong choice for a content platform with users, posts, comments, permissions, and audit trails. [prisma](https://www.prisma.io/docs/guides/frameworks/nextjs)

***

# Initialize Prisma

```bash
npx prisma init
```

This creates:

```text
prisma/schema.prisma
```

***

# Configure Prisma

Open `prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url = env("DATABASE_URL")
}
```

Prisma is a common fit for Next.js + PostgreSQL projects because it gives us a type-safe database layer and a clean workflow for schema-driven development. [prisma](https://www.prisma.io/docs/ai/prompts/nextjs)

***

# Step 7 — Create the First Model

```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
}
```

This is our starting point.

We'll expand it later with roles, sessions, posts, comments, and permissions.

***

# Run the Migration

```bash
npx prisma migrate dev --name init
```

This turns schema changes into database changes.

That is one of the most important habits in a professional workflow.

***

# Generate the Client

```bash
npx prisma generate
```

Now Prisma can be used safely from our application code.

***

# Create the Database Singleton

Create:

```text
db/client.ts
```

```ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma?: PrismaClient;
};

export const db = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```

This pattern helps prevent multiple PrismaClient instances during development hot reloads. [medium](https://medium.com/@simarpalsingh13/stop-copy-pasting-globalthis-prisma-hot-reload-in-node-js-vs-next-js-explained-e664ec6ced23)

***

# Step 8 — Create a Health Route

Create:

```text
app/api/health/route.ts
```

```ts
export async function GET() {
  return Response.json({
    status: "healthy",
    timestamp: new Date(),
  });
}
```

This gives us a fast way to verify the app is alive.

***

# Step 9 — Create Utilities

Create:

```text
lib/utils.ts
```

```ts
export function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

Create:

```text
lib/constants.ts
```

```ts
export const APP_NAME = "Nexus CMS";
export const POSTS_PER_PAGE = 10;
```

Create:

```text
types/common.ts
```

```ts
export interface PageProps {
  params: Promise<Record<string, string>>;
}
```

These shared files help keep the codebase consistent and reusable.

***

# Step 10 — Document the System

Create:

```text
docs/architecture.md
```

```md
# Nexus CMS Architecture

Frontend:
- Next.js 16
- React 19

Backend:
- Server Actions
- Route Handlers

Database:
- PostgreSQL
- Prisma

Caching:
- Cache Components
- cacheTag
- cacheLife

Authentication:
- Session based
```

Create:

```text
docs/adr/ADR-001.md
```

```md
# ADR-001

Decision:
Use PostgreSQL.

Context:
Need transactions,
relationships,
consistency.

Alternatives:
MongoDB

Consequences:
Less flexible schema,
better reliability.
```

***

# Step 11 — Add Scripts

Update `package.json`:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "lint": "eslint .",
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev",
    "db:studio": "prisma studio"
  }
}
```

These scripts turn repeatable tasks into a reliable workflow.

***

# Create README

```md
# Nexus CMS

Production-grade content platform built with:

- Next.js 16
- React 19
- PostgreSQL
- Prisma
- Cache Components
```

A good README helps future you, collaborators, and deployment pipelines understand the project quickly.

***

# Final Repository Structure

```text
nexus-cms/

├── app/
├── actions/
├── auth/
├── components/
├── db/
├── docs/
├── hooks/
├── lib/
├── prisma/
├── public/
├── scripts/
├── services/
├── tests/
└── types/
```

This is the foundation we will keep evolving throughout the capstone.

***

# What We've Built

We now have:

```text
✓ Next.js 16
✓ TypeScript
✓ Cache Components
✓ PostgreSQL
✓ Prisma
✓ Environment variables
✓ Documentation
✓ ADRs
✓ Health checks
✓ Repository architecture
```

That is a serious starting point.

***

# Engineering Principle

Beginners ask:

```text
What should I code?
```

Professional engineers ask:

```text
How should the system be organized
before I write code?
```

That difference matters because architecture compounds.

Good architecture makes future work easier.

Bad architecture makes future work expensive.

***

# Exercises

## Exercise 1

Add a `config/` folder.

What belongs there?

## Exercise 2

Create `ADR-002` for choosing Next.js.

## Exercise 3

Create `scripts/seed.ts` to seed the database.

## Exercise 4

Draw the repository architecture diagram from memory.

***

# Part 29 Preview

In the next chapter, we'll design the database system for Nexus CMS, including:

```text
✓ Users
✓ Sessions
✓ Posts
✓ Categories
✓ Tags
✓ Comments
✓ Notifications
✓ Uploads
✓ Analytics
✓ Audit logs
✓ Permissions
✓ Indexes
✓ Relationships
```

This is where software engineering starts becoming data engineering.

***

[realcoding](https://realcoding.blog/en/2025/01/20/nextjs-prisma-singleton-pattern/)
