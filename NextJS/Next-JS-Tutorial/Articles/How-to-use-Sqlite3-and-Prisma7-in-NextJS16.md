# How to Use SQLite and Prisma 7 in Next.js 16

Next.js 16 and Prisma 7 are a powerful combination for building full‑stack apps, but Prisma 7 introduces a new driver adapter system that breaks many older code examples—especially when using SQLite. In this guide, you’ll learn how to set up **SQLite + Prisma 7** in a **Next.js 16** project, and avoid the dreaded:

> Using engine type "client" requires either "adapter" or "accelerateUrl" to be provided to PrismaClient constructor.

We’ll build a minimal blog with `/posts` and `/posts/[id]` using SQLite as the database and Prisma 7 as the ORM.

***

## 1. Install dependencies

In a Next.js 16 project, you’ll need Prisma, the Prisma client, and the SQLite driver adapter for Prisma 7. For SQLite with `better-sqlite3`, install: [zenn](https://zenn.dev/nt_log/articles/54037156f2b75e?locale=en)

```bash
npm install @prisma/client @prisma/adapter-better-sqlite3 better-sqlite3
npm install -D prisma
```

Ensure the versions of `prisma`, `@prisma/client`, and `@prisma/adapter-better-sqlite3` match (for example, `^7.8.0` for all three), which is what Prisma’s driver adapter docs recommend. [zenn](https://zenn.dev/nt_log/articles/54037156f2b75e)

***

## 2. Configure the Prisma schema for SQLite

Create `prisma/schema.prisma` and define a simple blog schema:

```prisma
// prisma/schema.prisma

generator client {
  provider      = "prisma-client-js"
  output        = "../generated/client"
  // Use native binary for Node/Turbopack
  binaryTargets = ["native"]
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model Post {
  id     Int    @id @default(autoincrement())
  userId Int
  title  String
  body   String
}
```

Here: [prisma](https://www.prisma.io/docs/orm/core-concepts/supported-databases/sqlite)

- `provider = "sqlite"` selects the SQLite connector.
- `url = env("DATABASE_URL")` offloads the actual file path to an environment variable.
- `output = "../generated/client"` puts the generated Prisma client in a dedicated folder, which is handy for teaching, monorepos, or clear separation of generated code.

***

## 3. Set up the SQLite database URL

In your project root, create `.env`:

```env
DATABASE_URL="file:./dev.db"
```

Prisma expects a `file:` URI for SQLite, not just a path. This points to a `dev.db` file in your project directory. [prisma](https://www.prisma.io/docs/prisma-orm/quickstart/sqlite)

If the file doesn’t exist yet, Prisma can create it via `db push`, or you can create an empty file manually:

```bash
mkdir prisma
cd prisma
type NUL > dev.db  # Windows
# or: touch dev.db on macOS/Linux
```

***

## 4. Add `prisma.config.ts` for Prisma 7

Prisma 7 uses `prisma.config.ts` to describe the schema and datasource for CLI and tooling: [prisma](https://www.prisma.io/docs/orm/core-concepts/supported-databases/sqlite)

```ts
// prisma.config.ts
import { defineConfig } from 'prisma/config';
import 'dotenv/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: {
    url: process.env.DATABASE_URL || 'file:./dev.db',
  },
});
```

This file:

- Points Prisma to `prisma/schema.prisma`.
- Sets the datasource URL explicitly, matching your `DATABASE_URL`.
- Plays nicely with environment configuration when you change DB locations later.

***

## 5. Generate the Prisma client

With the schema and config in place, generate the client: [zenn](https://zenn.dev/nt_log/articles/54037156f2b75e?locale=en)

```bash
npx prisma generate
```

Prisma will generate the client (including types) in the directory specified by `output`—in this case, `../generated/client`. [zenn](https://zenn.dev/nt_log/articles/54037156f2b75e)

Whenever you change the schema, run `npx prisma generate` again so your TypeScript types stay in sync.

***

## 6. Initialize PrismaClient with the SQLite driver adapter

This is where Prisma 7 differs from most older examples. If you write:

```ts
// lib/prisma.ts (old pattern)
import { PrismaClient } from '../generated/client';

const globalForPrisma = global as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: ['query'],
  });

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
```

you’ll hit:

> Using engine type "client" requires either "adapter" or "accelerateUrl" to be provided to PrismaClient constructor.

To fix this, you must give Prisma 7 a **driver adapter** for SQLite. For `better-sqlite3`, use `PrismaBetterSqlite3`: [zenn](https://zenn.dev/nt_log/articles/54037156f2b75e?locale=en)

```ts
// lib/prisma.ts (Next.js 16 + Prisma 7 + SQLite)
import { PrismaClient } from '../generated/client';
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3';

const adapter = new PrismaBetterSqlite3({
  url: process.env.DATABASE_URL ?? 'file:./dev.db',
});

// Singleton pattern for Next.js dev
const globalForPrisma = globalThis as unknown as {
  prisma?: PrismaClient;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    adapter,
    log: ['query'],
  });

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
```

Key changes: [zenn](https://zenn.dev/nt_log/articles/54037156f2b75e)

- Import `PrismaBetterSqlite3` from `@prisma/adapter-better-sqlite3`.
- Instantiate `adapter` with a `url` matching the SQLite database URI.
- Pass `adapter` into `new PrismaClient({ adapter })`.

Once you do this, the “engine type client requires adapter or accelerateUrl” error disappears because the client now knows how to talk to SQLite through the driver adapter.

***

## 7. Query SQLite from Next.js 16 server components

With `lib/prisma.ts` wired correctly, you can use Prisma directly in Next.js 16 server components.

### Posts list page

```tsx
// app/posts/page.tsx
import Link from 'next/link';
import { prisma } from '@/lib/prisma';

const PostsPage = async () => {
  const posts = await prisma.post.findMany();

  return (
    <div className="space-y-8">
      <section className="space-y-4">
        <h1 className="text-center text-4xl font-semibold text-zinc-900 sm:text-5xl">
          Posts
        </h1>

        <ul className="space-y-3">
          {posts.slice(0, 5).map((post) => (
            <li key={post.id}>
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <Link
                  href={`/posts/${post.id}`}
                  className="text-lg font-semibold text-zinc-950 hover:text-blue-500"
                >
                  {post.title.charAt(0).toUpperCase() + post.title.slice(1)}
                </Link>
              </div>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
};

export default PostsPage;
```

This uses `prisma.post.findMany()` at render time, which is a natural fit for Next.js 16’s server components. [dev](https://dev.to/myogeshchavan97/how-to-build-a-task-management-app-using-nextjs-16-and-prisma-7-4mcf)

### Single post page

```tsx
// app/posts/[id]/page.tsx
import { prisma } from '@/lib/prisma';
import { notFound } from 'next/navigation';

const PostPage = async ({ params }: { params: { id: string } }) => {
  const { id } = params;

  const post = await prisma.post.findUnique({
    where: { id: Number(id) },
  });

  if (!post) {
    notFound();
  }

  return (
    <article className="space-y-6">
      <div className="space-y-4">
        <h1 className="text-center text-4xl font-semibold text-zinc-950 sm:text-5xl">
          {post.title.charAt(0).toUpperCase() + post.title.slice(1)}
        </h1>
        <p className="text-lg leading-8 text-zinc-700">{post.body}</p>
      </div>
    </article>
  );
};

export default PostPage;
```

Using `notFound()` from `next/navigation` gives you a proper 404 page when the record isn’t present, which is ideal for blogs and CRUD apps. [robinwieruch](https://www.robinwieruch.de/next-prisma-sqlite/)

***

## 8. Run migrations and start the dev server

Once schema, config, and Prisma initialization are in place:

1. Generate the client (again, if needed):

   ```bash
   npx prisma generate
   ```

2. Push schema to the SQLite database:

   ```bash
   npx prisma db push
   ```

3. Start Next.js:

   ```bash
   npm run dev
   ```

Visit `/posts` and `/posts/1` to see data coming directly from your SQLite database via Prisma 7. [prisma](https://www.prisma.io/docs/guides/frameworks/nextjs)

***

## Summary

To use **SQLite and Prisma 7 in Next.js 16** without hitting the new constructor error, remember:

- SQLite now requires a **driver adapter**, typically `@prisma/adapter-better-sqlite3`. [zenn](https://zenn.dev/nt_log/articles/54037156f2b75e?locale=en)
- Configure `datasource db` with `provider = "sqlite"` and `url = env("DATABASE_URL")`. [prisma](https://www.prisma.io/docs/prisma-orm/quickstart/sqlite)
- Set `DATABASE_URL="file:./dev.db"` (or your preferred file path) in `.env`. [prisma](https://www.prisma.io/docs/orm/core-concepts/supported-databases/sqlite)
- Initialize `PrismaClient` with a `PrismaBetterSqlite3` adapter in a singleton `lib/prisma.ts`. [zenn](https://zenn.dev/nt_log/articles/54037156f2b75e)
