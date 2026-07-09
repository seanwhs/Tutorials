# Neon Tutorial - Part 6: Neon + Drizzle ORM Integration

This part rebuilds the same Notes feature using Drizzle ORM — a lightweight, code-first alternative to Prisma. Compare this to Part 5 to decide which fits your project.

## 1. Install Drizzle

```bash
pnpm add drizzle-orm @neondatabase/serverless
pnpm add -D drizzle-kit tsx
```

- `drizzle-orm` — the query builder/runtime.
- `@neondatabase/serverless` — same driver used in Part 4, reused here as Drizzle's transport.
- `drizzle-kit` — CLI for generating/running migrations.
- `tsx` — runs TypeScript config/scripts directly (used by `drizzle-kit`).

## 2. Define the Schema in Code

```ts
// drizzle/schema.ts
import { pgTable, serial, text, timestamp } from "drizzle-orm/pg-core";

// Schema IS the source of truth in Drizzle — no separate DSL file
// like Prisma's schema.prisma. Plain TypeScript, fully type-inferred.
export const notesDrizzle = pgTable("notes_drizzle", {
  id: serial("id").primaryKey(),
  title: text("title").notNull(),
  content: text("content").notNull().default(""),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});

// Infer TS types directly from the schema — no codegen step needed.
export type NoteDrizzle = typeof notesDrizzle.$inferSelect;
export type NewNoteDrizzle = typeof notesDrizzle.$inferInsert;
```

## 3. Configure Drizzle Kit

```ts
// drizzle.config.ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./drizzle/schema.ts",
  out: "./drizzle/migrations",
  dialect: "postgresql",
  dbCredentials: {
    // Migrations run over the DIRECT connection, same reasoning as Prisma.
    url: process.env.DIRECT_URL!,
  },
});
```

## 4. Generate & Run Your First Migration

```bash
pnpm dlx drizzle-kit generate
pnpm dlx drizzle-kit migrate
```

`generate` diffs your schema file against the last known migration and writes a new SQL file into `drizzle/migrations/`. `migrate` applies pending migration files to Neon.

> Alternative for rapid prototyping: `pnpm dlx drizzle-kit push` pushes your schema straight to the database without generating migration files — convenient in early development, but prefer `generate`+`migrate` once you have a team or care about migration history.

## 5. Create the Drizzle Client

```ts
// src/lib/db-drizzle.ts
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import { env } from "@/lib/env";
import * as schema from "../../drizzle/schema";

// neon-http driver — stateless, HTTP-based, same transport model as
// Part 4's raw driver. Great for simple queries; Part 7 explains why
// db.transaction() needs a different driver (neon-serverless/WebSocket).
const sql = neon(env.DATABASE_URL);

export const db = drizzle(sql, { schema });
```

## 6. Read Data in a Server Component

```tsx
// src/app/notes-drizzle/page.tsx
import { db } from "@/lib/db-drizzle";
import { notesDrizzle } from "../../../drizzle/schema";
import { desc } from "drizzle-orm";
import Link from "next/link";

export default async function NotesDrizzlePage() {
  const notes = await db
    .select()
    .from(notesDrizzle)
    .orderBy(desc(notesDrizzle.createdAt));

  return (
    <main className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Notes (Drizzle)</h1>
      <ul className="space-y-2">
        {notes.map((note) => (
          <li key={note.id} className="border rounded p-3">
            <Link href={`/notes-drizzle/${note.id}`} className="font-medium underline">
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

## 7. Dynamic Route with Next.js 16 Async Params

```tsx
// src/app/notes-drizzle/[id]/page.tsx
import { db } from "@/lib/db-drizzle";
import { notesDrizzle } from "../../../../drizzle/schema";
import { eq } from "drizzle-orm";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function NoteDrizzlePage({ params }: PageProps) {
  const { id } = await params; // Next.js 16 requires awaiting params

  const [note] = await db
    .select()
    .from(notesDrizzle)
    .where(eq(notesDrizzle.id, Number(id)));

  if (!note) notFound();

  return (
    <main className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold">{note.title}</h1>
      <p className="mt-2 whitespace-pre-wrap">{note.content}</p>
    </main>
  );
}
```

## 8. CRUD via Server Actions

```ts
// src/actions/notes-drizzle.ts
"use server";

import { db } from "@/lib/db-drizzle";
import { notesDrizzle } from "../../drizzle/schema";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const noteSchema = z.object({
  title: z.string().min(1, "Title is required").max(200),
  content: z.string().max(5000).default(""),
});

export async function createNoteDrizzle(formData: FormData) {
  const parsed = noteSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0].message };
  }

  await db.insert(notesDrizzle).values(parsed.data);
  revalidatePath("/notes-drizzle");
  return { error: null };
}

export async function updateNoteDrizzle(id: number, formData: FormData) {
  const parsed = noteSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0].message };
  }

  await db.update(notesDrizzle).set(parsed.data).where(eq(notesDrizzle.id, id));
  revalidatePath("/notes-drizzle");
  revalidatePath(`/notes-drizzle/${id}`);
  return { error: null };
}

export async function deleteNoteDrizzle(id: number) {
  await db.delete(notesDrizzle).where(eq(notesDrizzle.id, id));
  revalidatePath("/notes-drizzle");
}
```

## 9. Relations Example (1:N) — Notes with Tags

```ts
// drizzle/schema.ts (add alongside notesDrizzle)
import { pgTable, serial, text, timestamp, integer, primaryKey } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

export const tags = pgTable("tags", {
  id: serial("id").primaryKey(),
  name: text("name").notNull().unique(),
});

export const noteTags = pgTable(
  "note_tags",
  {
    noteId: integer("note_id").notNull().references(() => notesDrizzle.id, { onDelete: "cascade" }),
    tagId: integer("tag_id").notNull().references(() => tags.id, { onDelete: "cascade" }),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.noteId, table.tagId] }),
  })
);

// The relations() helper enables db.query.notesDrizzle.findMany({ with: { tags: true } })
export const notesRelations = relations(notesDrizzle, ({ many }) => ({
  noteTags: many(noteTags),
}));

export const noteTagsRelations = relations(noteTags, ({ one }) => ({
  note: one(notesDrizzle, { fields: [noteTags.noteId], references: [notesDrizzle.id] }),
  tag: one(tags, { fields: [noteTags.tagId], references: [tags.id] }),
}));
```

```bash
pnpm dlx drizzle-kit generate
pnpm dlx drizzle-kit migrate
```

```ts
// Querying with the relational query API
const notesWithTags = await db.query.notesDrizzle.findMany({
  with: { noteTags: { with: { tag: true } } },
});
```

## 10. Prisma vs Drizzle — Quick API Comparison

| Operation | Prisma | Drizzle |
|---|---|---|
| Find many | `prisma.note.findMany()` | `db.select().from(notes)` |
| Find one | `prisma.note.findUnique({ where: { id } })` | `db.select().from(notes).where(eq(notes.id, id))` |
| Create | `prisma.note.create({ data })` | `db.insert(notes).values(data)` |
| Update | `prisma.note.update({ where, data })` | `db.update(notes).set(data).where(...)` |
| Delete | `prisma.note.delete({ where })` | `db.delete(notes).where(...)` |
| Schema definition | `schema.prisma` (custom DSL) | plain TypeScript (`pgTable`) |
| Codegen | Yes — `prisma generate` | No — types inferred directly |

## 11. Checkpoint

- [ ] Installed `drizzle-orm`, `@neondatabase/serverless`, `drizzle-kit`
- [ ] Defined `notesDrizzle` schema in plain TypeScript
- [ ] Ran `drizzle-kit generate` + `migrate` against Neon
- [ ] Built read/create/update/delete via Server Actions using Drizzle's query builder
- [ ] Understand the relations() API for joined queries

## Troubleshooting

| Problem | Fix |
|---|---|
| `drizzle-kit` can't find config | Ensure `drizzle.config.ts` is at the project root and run commands from there |
| Migration diff is empty after schema change | Confirm the schema file path in `drizzle.config.ts` matches where you actually edited |
| `relations` queries return empty `with` arrays | Confirm both `relations()` definitions exist and `schema` was passed into `drizzle(sql, { schema })` |

## Next

**Part 7: Database Branching for Preview Deployments** — connect Neon to Vercel so every pull request gets its own isolated, disposable database branch.
