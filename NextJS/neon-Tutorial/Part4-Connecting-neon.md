# Neon Tutorial - Part 4: Connecting Neon via `@neondatabase/serverless` (Raw SQL)

This part builds a small **Notes** CRUD feature using Neon's official driver directly — no ORM. This is the leanest possible way to talk to Neon and a great baseline before adding Prisma (Part 5) or Drizzle (Part 6).

## 1. Install the Driver

```bash
pnpm add @neondatabase/serverless
```

`@neondatabase/serverless` ships two connection modes:

| Mode | Import | Use When |
|---|---|---|
| HTTP (`neon()`) | `import { neon } from "@neondatabase/serverless"` | Simple one-shot queries, works in Edge Runtime, no transactions across multiple statements |
| WebSocket (`Pool`) | `import { Pool } from "@neondatabase/serverless"` | Need multi-statement transactions, `LISTEN/NOTIFY`, or a `pg`-compatible `Pool`/`Client` API |

We use the **HTTP mode** in this part since it's simpler and edge-compatible; Part 8 covers when to reach for `Pool` instead.

## 2. Create the Database Client

```ts
// src/lib/db-raw.ts
import { neon } from "@neondatabase/serverless";
import { env } from "@/lib/env";

// neon() returns a tagged-template SQL function. Each call is a
// single HTTP request to Neon — no persistent socket to manage,
// which is exactly why this works great in serverless/edge functions.
export const sql = neon(env.DATABASE_URL);
```

## 3. Create the Table

Run this once in the Neon SQL Editor (or via `psql`):

```sql
CREATE TABLE IF NOT EXISTS notes (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## 4. Read Data in a Server Component

```tsx
// src/app/notes/page.tsx
import { sql } from "@/lib/db-raw";
import Link from "next/link";

type Note = {
  id: number;
  title: string;
  content: string;
  created_at: string;
};

// Server Components can be async and query the database directly —
// no client-side fetch, no API route needed for a simple read.
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

## 5. Read a Single Note (Next.js 16 Async Params)

```tsx
// src/app/notes/[id]/page.tsx
import { sql } from "@/lib/db-raw";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ id: string }>; // Promise — Next.js 16 requirement
};

export default async function NotePage({ params }: PageProps) {
  const { id } = await params; // must await before use

  const [note] = await sql`
    SELECT id, title, content, created_at
    FROM notes
    WHERE id = ${Number(id)}
  `;

  if (!note) notFound(); // triggers the nearest not-found.tsx / 404

  return (
    <main className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold">{note.title}</h1>
      <p className="mt-2 whitespace-pre-wrap">{note.content}</p>
    </main>
  );
}
```

## 6. Write Data via a Server Action

```ts
// src/actions/notes-raw.ts
"use server";

import { sql } from "@/lib/db-raw";
import { revalidatePath } from "next/cache";
import { z } from "zod";

// Validate input at the boundary — never trust raw FormData values.
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

  // Tagged-template queries are parameterized automatically —
  // ${parsed.data.title} is NEVER string-concatenated into the SQL,
  // so this is safe against SQL injection out of the box.
  await sql`
    INSERT INTO notes (title, content)
    VALUES (${parsed.data.title}, ${parsed.data.content})
  `;

  // Re-fetch the notes list on next navigation to /notes
  revalidatePath("/notes");
  return { error: null };
}

export async function deleteNote(id: number) {
  await sql`DELETE FROM notes WHERE id = ${id}`;
  revalidatePath("/notes");
}
```

## 7. Wire the Form Up with `useActionState` (React 19 / Next.js 16)

```tsx
// src/app/notes/new/page.tsx
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

## 8. Why the HTTP Driver Has No Multi-Statement Transactions

```ts
// ❌ This does NOT work with neon() HTTP mode — each tagged-template
// call is its own isolated HTTP request; there's no shared connection
// to hold a transaction open across them.
await sql`BEGIN`;
await sql`UPDATE notes SET title = 'a' WHERE id = 1`;
await sql`UPDATE notes SET title = 'b' WHERE id = 2`;
await sql`COMMIT`;
```

```ts
// ✅ Instead, use sql.transaction() — Neon's HTTP driver DOES support
// this specific helper, which batches multiple queries into one
// atomic request under the hood.
const results = await sql.transaction([
  sql`UPDATE notes SET title = 'a' WHERE id = 1`,
  sql`UPDATE notes SET title = 'b' WHERE id = 2`,
]);
```

For anything more complex (conditional logic between statements), switch to the WebSocket `Pool` — covered in Part 8.

## 9. Checkpoint

- [ ] Installed `@neondatabase/serverless`
- [ ] Created `notes` table in Neon
- [ ] Built a Server Component that reads notes with `sql\`...\``
- [ ] Built a dynamic `[id]` page using Next.js 16 async `params`
- [ ] Built a Server Action that validates input with Zod and inserts via parameterized `sql`
- [ ] Understand why `sql.transaction([...])` is used instead of raw `BEGIN`/`COMMIT`

## Troubleshooting

| Problem | Fix |
|---|---|
| `NeonDbError: password authentication failed` | Double check `DATABASE_URL` in `.env.local` matches the console exactly, including URL-encoded password characters |
| Query returns rows but TypeScript complains about `unknown[]` | The driver returns `Record<string, unknown>[]` by default — cast with `as Note[]` or use a validation library (Zod) for runtime safety |
| Works locally but times out on Vercel | Confirm you're using the **pooled** connection string (`-pooler` in hostname), not the direct one, for `DATABASE_URL` |

## Next

**Part 5: Neon + Prisma ORM Integration** — add schema management, migrations, and type-safe queries with Prisma.
