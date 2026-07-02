# Getting Started with SQLite and Prisma 7 in Next.js 16

If you’re building a Next.js 16 application and the thought of managing a bulky database server sounds like a headache, SQLite is your best friend. It’s serverless, file-based, and built right into your development environment.

With **Prisma 7**, the architecture has shifted to use **Driver Adapters**, offering a more modular and performant way to connect to your database.

---

## 1. Installation & Setup

In Prisma 7, you need the CLI, the client, and a specific driver adapter. For local SQLite development, we use `better-sqlite3`.

```bash
# Install the core packages
npm install @prisma/client @prisma/adapter-better-sqlite3 better-sqlite3
npm install prisma --save-dev

```

---

## 2. Configuration (The Prisma 7 Way)

Prisma 7 moves the connection configuration out of the schema file and into a dedicated config file.

### A. Update `prisma/schema.prisma`

The `datasource` block no longer requires a URL. We also specify a custom output path for better type safety.

```prisma
generator client {
  provider = "prisma-client-js"
  output   = "../generated/client"
}

datasource db {
  provider = "sqlite"
}

```

### B. Create `prisma.config.mjs`

Create this file in your project root to define your database URL.

```javascript
import { defineConfig } from 'prisma/config';
import 'dotenv/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: {
    url: process.env.DATABASE_URL || 'file:./dev.db',
  },
});

```

---

## 3. Defining Your First Model

Define your structure in `prisma/schema.prisma`.

```prisma
model Post {
  id     Int    @id @default(autoincrement())
  userId Int
  title  String
  body   String
}

```

Apply your changes with a migration:

```bash
npx prisma migrate dev --name init

```

---

## 4. The Singleton Client (Required for Next.js 16)

Next.js hot-reloading can spin up multiple database connections in development. Use a singleton pattern to keep one connection alive.

Create `lib/prisma.js`:

```javascript
import { PrismaClient } from '../generated/client';
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3';

const globalForPrisma = global;

const adapter = new PrismaBetterSqlite3({ 
  url: process.env.DATABASE_URL || 'file:./dev.db' 
});

export const prisma = globalForPrisma.prisma ?? new PrismaClient({ adapter });

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}

```

---

## 5. Visualizing Data

You can still use **Prisma Studio** to view and edit your data in real-time:

```bash
npx prisma studio

```

---

## Final Pro-Tip for Next.js 16

Next.js 16’s aggressive build optimization might prune the Prisma Query Engine binary. If you face deployment errors, update your `next.config.ts`:

```typescript
const nextConfig = {
  outputFileTracingIncludes: {
    '/api/**/*': ['./node_modules/.prisma/client/**/*'],
  },
};
export default nextConfig;

```

SQLite is an incredible tool for development. Since your database is just a `dev.db` file, you can always reset by deleting the file and running your migrations again. Happy coding!

---

*Are you planning to link your `userId` to a formal `User` table, or should the `userId` remain a simple integer for your current prototype?*
