# Neon Tutorial - Appendix A (3 of 3): App Pages & Routes

Full final-state contents of every `src/app` page and route file across Parts 3-8.

## `src/app/page.tsx` (Part 3)

```tsx
import { env } from "@/lib/env";

export default function Home() {
  const dbConfigured = Boolean(env.DATABASE_URL && env.DIRECT_URL);

  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold">Neon + Next.js 16 Tutorial</h1>
      <p className="mt-2">
        Environment variables configured: {dbConfigured ? "✅ Yes" : "❌ No"}
      </p>
    </main>
  );
}
```

## `src/app/notes/page.tsx` (Part 4 — raw driver)

```tsx
import { sql } from "@/lib/db-raw";
import Link from "next/link";

type Note = {
  id: number;
  title: string;
  content: string;
  created_at: string;
};

export default async function NotesPage() {
  const notes = (await sql`
    SELECT id, title, content, created_at
    FROM notes
    ORDER BY created_at DESC
  `) as Note[];

  return (
    <main className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Notes (raw driver)</h1>
      <ul className="space-y-2">
        {notes.map((note) => (
          <li key={note.id} className="border rounded p-3">
            <Link href={`/notes/${note.id}`} className="font-medium underline">
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

## `src/app/notes/[id]/page.tsx` (Part 4)

```tsx
import { sql } from "@/lib/db-raw";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function NotePage({ params }: PageProps) {
  const { id } = await params;

  const [note] = await sql`
    SELECT id, title, content, created_at
    FROM notes
    WHERE id = ${Number(id)}
  `;

  if (!note) notFound();

  return (
    <main className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold">{note.title}</h1>
      <p className="mt-2 whitespace-pre-wrap">{note.content}</p>
    </main>
  );
}
```

## `src/app/notes/new/page.tsx` (Part 4)

```tsx
"use client";

import { useActionState } from "react";
import { createNote } from "@/actions/notes-raw";

const initialState = { error: null as string | null };

export default function NewNotePage() {
  const [state, formAction, isPending] = useActionState(
    async (_prevState: typeof initialState, formData: FormData) => {
      return await createNote(formData);
    },
    initialState
  );

  return (
    <main className="p-8 max-w-md mx-auto">
      <h1 className="text-2xl font-bold mb-4">New Note</h1>
      <form action={formAction} className="space-y-3">
        <input
          name="title"
          placeholder="Title"
          className="w-full border rounded p-2"
        />
        <textarea
          name="content"
          placeholder="Content"
          className="w-full border rounded p-2"
          rows={4}
        />
        {state.error && <p className="text-red-600 text-sm">{state.error}</p>}
        <button
          type="submit"
          disabled={isPending}
          className="bg-black text-white rounded px-4 py-2 disabled:opacity-50"
        >
          {isPending ? "Saving..." : "Save Note"}
        </button>
      </form>
    </main>
  );
}
```

## `src/app/notes-prisma/page.tsx` (Part 5)

```tsx
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

## `src/app/notes-prisma/[id]/page.tsx` (Part 5)

```tsx
import { prisma } from "@/lib/db-prisma";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function NotePrismaPage({ params }: PageProps) {
  const { id } = await params;

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

## `src/app/notes-drizzle/page.tsx` (Part 6)

```tsx
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

## `src/app/notes-drizzle/[id]/page.tsx` (Part 6)

```tsx
import { db } from "@/lib/db-drizzle";
import { notesDrizzle } from "../../../../drizzle/schema";
import { eq } from "drizzle-orm";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function NoteDrizzlePage({ params }: PageProps) {
  const { id } = await params;

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

## `src/app/api/notes/route.ts` (Part 8 — Edge Runtime example)

```tsx
export const runtime = "edge";

import { neon } from "@neondatabase/serverless";
import { env } from "@/lib/env";
import { NextResponse } from "next/server";

const sql = neon(env.DATABASE_URL);

export async function GET() {
  const notes = await sql`SELECT id, title FROM notes ORDER BY created_at DESC LIMIT 10`;
  return NextResponse.json({ notes });
}
```

## File-to-Part Map

| File | Introduced In |
|---|---|
| `src/lib/env.ts` | Part 3 |
| `src/app/page.tsx` | Part 3 |
| `src/lib/db-raw.ts`, `src/app/notes/**`, `src/actions/notes-raw.ts` | Part 4 |
| `src/lib/db-prisma.ts`, `src/app/notes-prisma/**`, `src/actions/notes-prisma.ts`, `prisma/schema.prisma` | Part 5 |
| `src/lib/db-drizzle.ts`, `src/app/notes-drizzle/**`, `src/actions/notes-drizzle.ts`, `drizzle/schema.ts`, `drizzle.config.ts` | Part 6 |
| `scripts/migrate.ts`, `scripts/seed.ts` | Part 7 |
| `src/lib/db-pool.ts`, `src/lib/db-drizzle-pool.ts`, `src/app/api/notes/route.ts` | Part 8 |
| `scripts/audit-branches.ts` | Part 10 |

This completes the full codebase reference. See **Appendix B** for environment variables and **Appendix C** for troubleshooting.

---

Appendix A is done (all 3 parts). Say **"next"** to continue to **Appendix B: Environment Variables Reference**, or name any Part/Appendix to jump directly.
