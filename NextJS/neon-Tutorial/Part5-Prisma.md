# Neon Tutorial - Part 5: Neon + Prisma ORM Integration

## 1. Install Prisma

```bash
pnpm add prisma --save-dev
pnpm add @prisma/client

# The Neon adapter lets Prisma talk to Neon over HTTP/WebSocket instead
# of a raw TCP connection — required for reliable use in serverless
# and Edge runtimes where long-lived TCP sockets aren't guaranteed.
pnpm add @prisma/adapter-neon

pnpm dlx prisma init --datasource-provider postgresql
```

This creates `prisma/schema.prisma` and a `.env` (we already have `.env.local` from Part 3 — keep `DATABASE_URL`/`DIRECT_URL` there and Prisma will pick them up).

## 2. Define the Schema

```prisma
// prisma/schema.prisma
generator client {
  provider        = "prisma-client-js"
  output          = "../src/generated/prisma"
  previewFeatures = ["driverAdapters"] // required to use @prisma/adapter-neon
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")   // pooled — used at runtime
  directUrl = env("DIRECT_URL")     // direct — used for migrations
}

model Note {
  id        Int      @id @default(autoincrement())
  title     String
  content   String   @default("")
  createdAt DateTime @default(now()) @map("created_at")

  @@map("notes_prisma") // separate table name so this can coexist
                        // with the raw-driver `notes` table from Part 4
}
```

## 3. Run Your First Migration

```bash
# Migrations always run over the DIRECT connection (directUrl above) —
# they need session-level Postgres features a pooled connection can't
# guarantee (advisory locks used internally by Prisma Migrate).
pnpm dlx prisma migrate dev --name init
```

This creates `prisma/migrations/<timestamp>_init/migration.sql` and applies it to your Neon `main` branch, then generates the Prisma Client into `src/generated/prisma`.

```bash
# Optional: open Prisma Studio, a GUI to browse/edit your Neon data
pnpm dlx prisma studio
```

## 4. Create the Prisma Client with the Neon Adapter

```ts
// src/lib/db-prisma.ts
import { PrismaClient } from "@/generated/prisma";
import { PrismaNeon } from "@prisma/adapter-neon";
import { env } from "@/lib/env";

// The adapter wraps @neondatabase/serverless under the hood, so Prisma
// gets the same serverless/edge-friendly HTTP transport as Part 4's
// raw driver, instead of Prisma's default TCP connection pool.
const adapter = new PrismaNeon({ connectionString: env.DATABASE_URL });

// Global singleton pattern — prevents creating a new PrismaClient (and
// therefore a new connection pool) on every hot-reload in dev, which
// would otherwise exhaust Neon's connection limit quickly.
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ?? new PrismaClient({ adapter });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
```

## 5. Read Data in a Server Component

```tsx
// src/app/notes-prisma/page.tsx
import { prisma } from "@/lib/db-prisma";
import Link from "next/link";

export default async function NotesPrismaPage() {
  const notes = await prisma.note.findMany({
    orderBy: { createdAt: "desc" },
  });

  return (
    <main className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Notes (Prisma)</h1>
      <ul className="space-y-2">
        {notes.map((note) => (
          <li key={note.id} className="border rounded p-3">
            <Link href={`/notes-prisma/${note.id}`} className="font-medium underline">
              {note.title}
            </Link>
          </li>
        ))}
      </ul>
      {notes.length === 0 && <p className="text-gray-500">No notes yet.</p>}
    </main>
  );
}
```

## 6. Dynamic Route with Next.js 16 Async Params

```tsx
// src/app/notes-prisma/[id]/page.tsx
import { prisma } from "@/lib/db-prisma";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function NotePrismaPage({ params }: PageProps) {
  const { id } = await params; // Next.js 16 requires awaiting params

  const note = await prisma.note.findUnique({
    where: { id: Number(id) },
  });

  if (!note) notFound();

  return (
    <main className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold">{note.title}</h1>
      <p className="mt-2 whitespace-pre-wrap">{note.content}</p>
    </main>
  );
}
```

## 7. CRUD via Server Actions

```ts
// src/actions/notes-prisma.ts
"use server";

import { prisma } from "@/lib/db-prisma";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const noteSchema = z.object({
  title: z.string().min(1, "Title is required").max(200),
  content: z.string().max(5000).default(""),
});

export async function createNotePrisma(formData: FormData) {
  const parsed = noteSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0].message };
  }

  await prisma.note.create({ data: parsed.data });
  revalidatePath("/notes-prisma");
  return { error: null };
}

export async function updateNotePrisma(id: number, formData: FormData) {
  const parsed = noteSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0].message };
  }

  await prisma.note.update({ where: { id }, data: parsed.data });
  revalidatePath("/notes-prisma");
  revalidatePath(`/notes-prisma/${id}`);
  return { error: null };
}

export async function deleteNotePrisma(id: number) {
  await prisma.note.delete({ where: { id } });
  revalidatePath("/notes-prisma");
}
```

## 8. Relations Example (1:N) — Notes with Tags

```prisma
// prisma/schema.prisma (add alongside Note)
model Tag {
  id    Int    @id @default(autoincrement())
  name  String @unique
  notes NoteTag[]
}

model NoteTag {
  noteId Int
  tagId  Int
  note   Note @relation(fields: [noteId], references: [id], onDelete: Cascade)
  tag    Tag  @relation(fields: [tagId], references: [id], onDelete: Cascade)

  @@id([noteId, tagId])
}
```

```bash
pnpm dlx prisma migrate dev --name add_tags
```

```ts
// Querying with relations included
const notesWithTags = await prisma.note.findMany({
  include: { tags: { include: { tag: true } } },
});
```

## 9. Transactions

```ts
// Interactive transaction — all-or-nothing, useful when a later step
// depends on the result of an earlier one within the same transaction.
await prisma.$transaction(async (tx) => {
  const note = await tx.note.create({
    data: { title: "Meeting notes", content: "..." },
  });
  await tx.tag.upsert({
    where: { name: "work" },
    create: { name: "work" },
    update: {},
  });
  // ...link note to tag, etc.
  return note;
});
```

## 10. Checkpoint

- [ ] Installed `prisma`, `@prisma/client`, `@prisma/adapter-neon`
- [ ] `schema.prisma` uses both `url` (pooled) and `directUrl` (direct)
- [ ] Ran `prisma migrate dev` successfully against Neon
- [ ] Created a singleton Prisma Client using `PrismaNeon` adapter
- [ ] Built read/create/update/delete via Server Actions
- [ ] Understand `$transaction` for atomic multi-step writes

## Troubleshooting

| Problem | Fix |
|---|---|
| `Error: P1001: Can't reach database server` during migrate | Migrations use `DIRECT_URL` — confirm it's set and does **not** contain `-pooler` in the hostname |
| Too many connections error in dev | Ensure the singleton pattern in `db-prisma.ts` is used — without it, hot reload spawns a new client per save |
| `driverAdapters` preview feature warning | Expected — this is still a preview feature in Prisma 6.x; safe to use, just keep Prisma updated |

## Next

**Part 6: Neon + Drizzle ORM Integration** — the same Notes feature rebuilt with Drizzle's lightweight, code-first approach for direct comparison.
