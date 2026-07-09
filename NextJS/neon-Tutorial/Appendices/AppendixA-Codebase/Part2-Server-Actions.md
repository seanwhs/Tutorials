# Neon Tutorial - Appendix A (2 of 3): Server Actions & Schema Files

Full final-state contents of all Server Action files (Parts 4-6) and the Prisma/Drizzle schema definitions (Parts 5-6).

## `src/actions/notes-raw.ts` (Part 4)

```ts
"use server";

import { sql } from "@/lib/db-raw";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const createNoteSchema = z.object({
  title: z.string().min(1, "Title is required").max(200),
  content: z.string().max(5000).default(""),
});

export async function createNote(formData: FormData) {
  const parsed = createNoteSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0].message };
  }

  await sql`
    INSERT INTO notes (title, content)
    VALUES (${parsed.data.title}, ${parsed.data.content})
  `;

  revalidatePath("/notes");
  return { error: null };
}

export async function deleteNote(id: number) {
  await sql`DELETE FROM notes WHERE id = ${id}`;
  revalidatePath("/notes");
}
```

## `src/actions/notes-prisma.ts` (Part 5)

```ts
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

## `src/actions/notes-drizzle.ts` (Part 6)

```ts
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

## `prisma/schema.prisma` (Part 5)

```prisma
generator client {
  provider        = "prisma-client-js"
  output          = "../src/generated/prisma"
  previewFeatures = ["driverAdapters"]
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}

model Note {
  id        Int      @id @default(autoincrement())
  title     String
  content   String   @default("")
  createdAt DateTime @default(now()) @map("created_at")
  tags      NoteTag[]

  @@map("notes_prisma")
}

model Tag {
  id    Int       @id @default(autoincrement())
  name  String    @unique
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

## `drizzle/schema.ts` (Part 6)

```ts
import { pgTable, serial, text, timestamp, integer, primaryKey } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

export const notesDrizzle = pgTable("notes_drizzle", {
  id: serial("id").primaryKey(),
  title: text("title").notNull(),
  content: text("content").notNull().default(""),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});

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

export const notesRelations = relations(notesDrizzle, ({ many }) => ({
  noteTags: many(noteTags),
}));

export const noteTagsRelations = relations(noteTags, ({ one }) => ({
  note: one(notesDrizzle, { fields: [noteTags.noteId], references: [notesDrizzle.id] }),
  tag: one(tags, { fields: [noteTags.tagId], references: [tags.id] }),
}));

export type NoteDrizzle = typeof notesDrizzle.$inferSelect;
export type NewNoteDrizzle = typeof notesDrizzle.$inferInsert;
```

## Next

See **Appendix A (3 of 3)** for all `src/app` page and route files.
