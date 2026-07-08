# Part 3: Database — Prisma + Neon Postgres

Previous: Part 2 (Auth with Clerk).

Targets Prisma 6+. Not Next.js-version-specific, but we call out one Turbopack interaction below.

## 1. Concept

We design the **full database schema** up front, even though we won't use every model until later parts. Full schema mirrored in Appendix C.

Models: `User` (mirrors Clerk, stores role), `Client` (optionally linked to a User), `Project` (belongs to Client), `Proposal` (belongs to Project), `Invoice` + `InvoiceItem` (belongs to Project), `Message` (belongs to Project, sender is User), `Attachment` (belongs to Project or Proposal, uploaded by User).

## 2. Create a Neon database

1. console.neon.tech → new project "freelancer-portal".
2. Copy the **pooled connection string**.
3. Paste into `.env.local`:

```bash
DATABASE_URL="postgresql://USER:PASSWORD@HOST/DBNAME?sslmode=require"
```

## 3. Install Prisma

```bash
pnpm add -D prisma
pnpm add @prisma/client
pnpm dlx prisma init
```

Installs Prisma 6+. The Prisma CLI only reads `.env` (not `.env.local`), so keep a plain `.env` with the same `DATABASE_URL` too — both gitignored.

## 4. The full schema

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum Role {
  ADMIN
  CLIENT
}

enum ProjectStatus {
  ACTIVE
  ON_HOLD
  COMPLETED
}

enum ProposalStatus {
  DRAFT
  SENT
  APPROVED
  CHANGES_REQUESTED
}

enum InvoiceStatus {
  DRAFT
  SENT
  PAID
  OVERDUE
}

model User {
  id        String   @id @default(cuid())
  clerkId   String   @unique
  email     String   @unique
  name      String?
  role      Role     @default(CLIENT)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  clientProfile Client?      @relation("ClientUser")
  messages      Message[]
  attachments   Attachment[]
}

model Client {
  id        String   @id @default(cuid())
  name      String
  company   String?
  email     String
  userId    String?  @unique
  user      User?    @relation("ClientUser", fields: [userId], references: [id])
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  projects Project[]
}

model Project {
  id          String        @id @default(cuid())
  clientId    String
  client      Client        @relation(fields: [clientId], references: [id], onDelete: Cascade)
  name        String
  description String?
  status      ProjectStatus @default(ACTIVE)
  createdAt   DateTime      @default(now())
  updatedAt   DateTime      @updatedAt

  proposals   Proposal[]
  invoices    Invoice[]
  messages    Message[]
  attachments Attachment[]
}

model Proposal {
  id          String         @id @default(cuid())
  projectId   String
  project     Project        @relation(fields: [projectId], references: [id], onDelete: Cascade)
  title       String
  content     String
  amount      Decimal        @db.Decimal(10, 2)
  status      ProposalStatus @default(DRAFT)
  sentAt      DateTime?
  respondedAt DateTime?
  createdAt   DateTime       @default(now())
  updatedAt   DateTime       @updatedAt

  attachments Attachment[]
}

model Invoice {
  id                    String        @id @default(cuid())
  projectId             String
  project               Project       @relation(fields: [projectId], references: [id], onDelete: Cascade)
  number                String        @unique
  status                InvoiceStatus @default(DRAFT)
  dueDate               DateTime
  total                 Decimal       @db.Decimal(10, 2)
  stripeCheckoutId      String?
  stripePaymentIntentId String?
  paidAt                DateTime?
  createdAt             DateTime      @default(now())
  updatedAt             DateTime      @updatedAt

  items InvoiceItem[]
}

model InvoiceItem {
  id          String  @id @default(cuid())
  invoiceId   String
  invoice     Invoice @relation(fields: [invoiceId], references: [id], onDelete: Cascade)
  description String
  quantity    Int     @default(1)
  unitPrice   Decimal @db.Decimal(10, 2)
}

model Message {
  id        String   @id @default(cuid())
  projectId String
  project   Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)
  senderId  String
  sender    User     @relation(fields: [senderId], references: [id])
  body      String
  createdAt DateTime @default(now())
}

model Attachment {
  id           String    @id @default(cuid())
  url          String
  name         String
  uploadedById String
  uploadedBy   User      @relation(fields: [uploadedById], references: [id])
  projectId    String?
  project      Project?  @relation(fields: [projectId], references: [id], onDelete: Cascade)
  proposalId   String?
  proposal     Proposal? @relation(fields: [proposalId], references: [id], onDelete: Cascade)
  createdAt    DateTime  @default(now())
}
```

## 5. Run the first migration

```bash
pnpm dlx prisma migrate dev --name init
```

## 6. Prisma client singleton

```ts
// src/server/db.ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const db =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = db;
```

Needed because Next.js hot-reloads modules in dev (Turbopack included), which can exhaust Postgres connections without a singleton.

## 7. Prisma Studio

```bash
pnpm dlx prisma studio
```

Opens a GUI at `localhost:5555` to browse/edit rows — useful throughout the series.

## 8. Package.json script shortcuts

```json
{
  "scripts": {
    "db:studio": "prisma studio",
    "db:migrate": "prisma migrate dev",
    "db:generate": "prisma generate",
    "db:push": "prisma db push"
  }
}
```

## Checkpoint

- [ ] Migration runs, prints "in sync with your schema"
- [ ] Prisma Studio shows empty tables: User, Client, Project, Proposal, Invoice, InvoiceItem, Message, Attachment
- [ ] `src/server/db.ts` exists

## Troubleshooting

- **P1001 can't reach database**: confirm pooled connection string + `?sslmode=require`.
- **Too many connections**: not using the singleton somewhere.
- **Prisma Client feels stale under Turbopack**: run `pnpm dlx prisma generate` manually and restart `pnpm dev`.

## Next

Continue to **Part 4: tRPC Setup**.
