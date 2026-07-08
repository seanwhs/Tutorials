# Appendix C: Full Prisma Schema Reference

Targets Prisma 6+ (see Part 3). The complete `prisma/schema.prisma` as built across Part 3 (initial design) — no further model changes were needed in later parts (Parts 5-12 only added tRPC procedures and UI on top of this same schema). This schema is not Next.js-version-specific in any way.

```prisma
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

## Model-by-model notes

- **User**: mirrors Clerk. `clerkId` is how we look up "who is making this request" (see `trpc.ts`'s `protectedProcedure`). `role` defaults to `CLIENT`; only flipped to `ADMIN` manually via Clerk's `publicMetadata` (Part 2), which the webhook (Part 5) then syncs down.
- **Client**: `userId` is nullable and unique — nullable because you can create a Client record before they've signed up (e.g., while drafting a proposal before formally inviting them); unique because each portal user maps to at most one Client.
- **Project**: the hub every other feature hangs off of (proposals, invoices, messages, attachments all point at a `projectId`). Cascading deletes mean deleting a Project cleans up everything under it — be deliberate about ever exposing a "delete project" button in the UI (not built in this MVP on purpose).
- **Proposal**: `amount` is informational/display only in the MVP — it does not auto-generate an Invoice. Wiring "approve proposal → auto-create invoice" is a reasonable Phase 2 addition (see Part 14).
- **Invoice / InvoiceItem**: `total` is stored redundantly (not derived on read) so past invoices remain historically accurate even if your total-computation logic changes later. `stripeCheckoutId` and `stripePaymentIntentId` are populated by Part 10's flow and are nullable until a payment attempt begins.
- **Message**: one flat thread per Project, ordered by `createdAt`. No read-receipts or per-message attachments in the MVP.
- **Attachment**: deliberately has two nullable foreign keys (`projectId`, `proposalId`) rather than a polymorphic association table — simpler for an app this size; a Phase 2 refactor could introduce a generic `AttachableType` enum if attachments needed to hang off more entity types (e.g., Invoices too).

## Common schema change workflow (for Phase 2 work)

1. Edit `prisma/schema.prisma`.
2. Run `pnpm dlx prisma migrate dev --name describe_your_change` locally.
3. Commit both the schema change and the new file under `prisma/migrations/`.
4. On deploy, Part 13's build script (`prisma migrate deploy && next build`) applies it to production automatically.

Never hand-edit generated migration SQL files after they've been applied anywhere — create a new migration for further changes instead.
