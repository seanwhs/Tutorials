# Next.js 16 for Absolute Beginners

# Part 28 — Building Nexus CMS: Project Setup, Repository Architecture, and Engineering Foundations

> **Goal of this lesson:** Create the foundation of our production-grade Nexus CMS by setting up Next.js 16, TypeScript, PostgreSQL, Prisma, project architecture, development workflow, and engineering conventions.

---

# Welcome to Real Software Engineering

Most tutorials begin like this:

```bash
npx create-next-app
```

Then immediately:

```text
Build Todo App
```

Professional engineering begins differently:

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

Because most software failures are architectural failures.

---

# What We're Building

By the end of this capstone, we'll have:

```text
                    Nexus CMS
                         |
         +---------------+---------------+
         |               |               |
         V               V               V
     Public Site     Dashboard      APIs
         |               |               |
         +---------------+---------------+
                         |
                    PostgreSQL
```

---

# Step 1 — Create the Project

Open your terminal:

```bash
npx create-next-app@latest nexus-cms
```

Answer:

```text
✔ TypeScript?           Yes
✔ ESLint?               Yes
✔ Tailwind?             Yes
✔ src directory?        No
✔ App Router?           Yes
✔ Turbopack?            Yes
✔ Import alias?         @/*
```

---

# Why These Choices?

### TypeScript

Because:

```text
Correctness
    >
Convenience
```

---

### App Router

Because Next.js 16 is built around:

```text
Server Components
Server Actions
Cache Components
```

---

### Tailwind

Because it reduces:

```text
CSS complexity
```

---

# Enter the Project

```bash
cd nexus-cms
```

---

# Install Dependencies

We'll install:

```bash
npm install \
@prisma/client \
bcryptjs \
zod \
uuid \
date-fns
```

Development dependencies:

```bash
npm install -D \
prisma \
tsx \
dotenv-cli
```

---

# Why These Packages?

| Package  | Purpose            |
| -------- | ------------------ |
| Prisma   | Database ORM       |
| bcryptjs | Password hashing   |
| zod      | Validation         |
| uuid     | IDs                |
| date-fns | Date formatting    |
| tsx      | TypeScript scripts |

---

# Step 2 — Enable Next.js 16 Cache Components

Open:

```text
next.config.ts
```

Add:

```ts
import type {
  NextConfig
} from "next";

const nextConfig: NextConfig = {

  cacheComponents: true,

};

export default nextConfig;
```

---

# Why?

Because Next.js 16's architecture centers around:

```text
Cache Components
```

which enable:

```text
"use cache"

cacheTag()

cacheLife()

revalidateTag()
```

---

# Step 3 — Initialize Git

```bash
git init
git add .
git commit -m "Initial commit"
```

---

# Why Commit Immediately?

Professional workflow:

```text
Small commits
      |
Easy rollback
      |
Safer development
```

---

# Step 4 — Create Engineering Folder Structure

Delete unnecessary files.

Create:

```text
nexus-cms/

├── app/
│
├── components/
│
├── actions/
│
├── auth/
│
├── db/
│
├── hooks/
│
├── lib/
│
├── services/
│
├── types/
│
├── tests/
│
├── docs/
│
├── prisma/
│
├── public/
│
└── scripts/
```

---

# Why This Structure?

Beginners organize by:

```text
File type
```

Professionals organize by:

```text
Responsibility
```

---

# Architecture Visualization

```text
                    Application
                          |
        +-----------------+-----------------+
        |                 |                 |
        V                 V                 V
     UI Layer      Domain Layer     Data Layer
```

---

# Components Folder

```text
components/

    ui/

    forms/

    dashboard/

    blog/

    shared/
```

---

# Actions Folder

```text
actions/

    auth/

    posts/

    comments/

    uploads/
```

---

# Services Folder

```text
services/

    search/

    email/

    storage/

    analytics/
```

---

# Docs Folder

```text
docs/

    architecture/

    adr/

    api/

    deployment/
```

---

# Why Documentation?

Because future you will forget.

---

# Step 5 — Create Environment Variables

Create:

```bash
touch .env
touch .env.example
```

---

# .env

```bash
DATABASE_URL=

AUTH_SECRET=

APP_URL=http://localhost:3000

NODE_ENV=development
```

---

# .env.example

```bash
DATABASE_URL=

AUTH_SECRET=

APP_URL=
```

---

# Never Commit

```text
.env
```

to Git.

---

# Update .gitignore

```gitignore
.env
.env.local
.env.production
```

---

# Step 6 — Install PostgreSQL

We'll use PostgreSQL because it provides:

```text
Transactions

Relations

Reliability

Maturity
```

---

# Install Prisma

Initialize:

```bash
npx prisma init
```

This creates:

```text
prisma/

    schema.prisma
```

---

# Configure Prisma

Open:

```text
prisma/schema.prisma
```

---

# Configure Database

```prisma
generator client {

  provider =
    "prisma-client-js"

}

datasource db {

  provider =
    "postgresql"

  url =
    env("DATABASE_URL")

}
```

---

# Visualizing Prisma

```text
Application
      |
Prisma Client
      |
PostgreSQL
```

---

# Step 7 — Create First Database Model

```prisma
model User {

  id String
     @id
     @default(uuid())

  email String
        @unique

  name String?

  createdAt DateTime
            @default(now())
}
```

---

# Visualizing Database

```text
Users

+----------------+
| id             |
| email          |
| name           |
| created_at     |
+----------------+
```

---

# Run Migration

```bash
npx prisma migrate dev \
--name init
```

---

# What Happens?

```text
Schema
    |
Migration
    |
SQL
    |
Database
```

---

# Generate Client

```bash
npx prisma generate
```

---

# Create Database Singleton

Create:

```text
db/client.ts
```

---

```ts
import {
  PrismaClient
} from "@prisma/client";

const globalForPrisma =
  globalThis as unknown as {

    prisma?:
      PrismaClient;

  };

export const db =
  globalForPrisma.prisma ??

  new PrismaClient();

if (
  process.env.NODE_ENV !==
  "production"
) {

  globalForPrisma.prisma =
    db;

}
```

---

# Why Singleton?

Without it:

```text
Reload
   |
New connection
   |
Connection leak
```

---

# Step 8 — Create Health Route

Create:

```text
app/api/health/route.ts
```

---

```ts
export async function GET() {

  return Response.json({

    status:
      "healthy",

    timestamp:
      new Date(),

  });

}
```

---

# Test

Open:

```text
http://localhost:3000/api/health
```

Output:

```json
{
  "status": "healthy"
}
```

---

# Step 9 — Create Utility Functions

Create:

```text
lib/utils.ts
```

---

```ts
export function sleep(
  ms: number
) {

  return new Promise(

    resolve =>

      setTimeout(
        resolve,
        ms
      )

  );

}
```

---

# Create Constants

```text
lib/constants.ts
```

---

```ts
export const APP_NAME =

  "Nexus CMS";

export const POSTS_PER_PAGE =

  10;
```

---

# Create Types

```text
types/common.ts
```

---

```ts
export interface PageProps {

  params:
    Promise<
      Record<
        string,
        string
      >
    >;

}
```

---

# Step 10 — Create Architecture Documentation

Create:

```text
docs/architecture.md
```

---

```markdown
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

---

# Create First ADR

Create:

```text
docs/adr/
```

---

# ADR-001.md

```markdown
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

---

# Step 11 — Create Development Scripts

Add:

```json
{
  "scripts": {

    "dev":
      "next dev",

    "build":
      "next build",

    "lint":
      "eslint .",

    "db:generate":
      "prisma generate",

    "db:migrate":
      "prisma migrate dev",

    "db:studio":
      "prisma studio"
  }
}
```

---

# Create Project README

```markdown
# Nexus CMS

Production-grade content platform built with:

- Next.js 16
- React 19
- PostgreSQL
- Prisma
- Cache Components
```

---

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

---

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

---

# Engineering Principle

Beginners ask:

```text
What should I code?
```

Professional engineers ask:

```text
How should the system
be organized before
I write code?
```

Because architecture compounds.

Good architecture makes future work easier.

Bad architecture makes future work impossible.

---

# Exercises

## Exercise 1

Add:

```text
config/
```

folder.

What belongs there?

---

## Exercise 2

Create:

```text
ADR-002
```

for choosing Next.js.

---

## Exercise 3

Create:

```text
scripts/seed.ts
```

to seed the database.

---

## Exercise 4

Draw the repository architecture diagram.

---

# Part 29 Preview

In the next chapter we'll design our entire database system, including:

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
