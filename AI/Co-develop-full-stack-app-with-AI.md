**# Co-Developing a Full-Stack Next.js App with Continue + Gemini-CLI**

This guide teaches you **how to co-develop** a production-grade full-stack application using **Continue** (in-editor AI) and **Gemini-CLI** (terminal AI) in tandem. You’ll build a complete **Posts + Comments** community app with authentication while learning a repeatable workflow that turns AI into a true pair-programming partner.

## Why This Workflow Wins
- **Continue** (VS Code) — Best for codebase-aware planning, refactors, component design, and precise code edits.
- **Gemini-CLI** (terminal) — Best for scaffolding, schema generation, error debugging, script writing, and automation.
- **Clear division**: Use Continue inside files for architecture and code quality. Use Gemini-CLI for terminal tasks and high-level orchestration.

You’ll learn the loop by actually building the app step by step.

---

### 1. Initial Project Setup

Start with a fresh Next.js app:

```bash
npx create-next-app@latest my-fullstack-app \
  --typescript --tailwind --eslint --app --yes

cd my-fullstack-app

npm install drizzle-orm postgres @vercel/postgres bcryptjs next-auth
npm install -D drizzle-kit
```

**First co-dev step:**

```bash
# Use Gemini-CLI to create the database client
echo "Create a lib/db.ts file using Drizzle ORM with postgres-js for a PostgreSQL connection" | gemini -p
```

Then create the file manually or let Continue refine it:

**lib/db.ts**
```ts
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

const connectionString = process.env.DATABASE_URL!;
const client = postgres(connectionString);
export const db = drizzle(client);
```

---

### 2. Project Architecture & Rules

Create a `PROMPTS.md` file to keep both AIs aligned:

```markdown
# Co-Development Rules
- Always use Next.js App Router + Server Actions
- Prefer Server Components by default
- Client Components only for interactivity (useActionState, forms)
- Validate everything server-side
- Use Drizzle ORM
- Revalidate cache after mutations
- Keep components small and focused
```

**Ask Continue to generate the folder structure:**

1. Open VS Code in the project.
2. Use Continue with prompt:  
   **“@codebase Create the recommended folder structure for a full-stack Next.js app with posts, comments, and auth using App Router.”**

---

### 3. Database Schema (Step-by-Step Co-Dev)

**Use Gemini-CLI first:**

```bash
echo "Generate a complete Drizzle schema for users, posts, and comments with proper relations, timestamps, and indexes" | gemini -p > drizzle/schema.ts
```

Review and improve with Continue:
- Open `drizzle/schema.ts`
- Prompt Continue: **“Review this schema for best practices and add relations using Drizzle relations API.”**

**drizzle/schema.ts** (final version):
```ts
import { pgTable, serial, text, timestamp, integer } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
  password: text("password"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const posts = pgTable("posts", {
  id: serial("id").primaryKey(),
  title: text("title").notNull(),
  content: text("content").notNull(),
  authorId: integer("author_id").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
});

export const comments = pgTable("comments", {
  id: serial("id").primaryKey(),
  content: text("content").notNull(),
  postId: integer("post_id").references(() => posts.id),
  authorId: integer("author_id").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
});

export const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(users, { fields: [posts.authorId], references: [users.id] }),
  comments: many(comments),
}));

export const commentsRelations = relations(comments, ({ one }) => ({
  author: one(users, { fields: [comments.authorId], references: [users.id] }),
  post: one(posts, { fields: [comments.postId], references: [posts.id] }),
}));
```

Apply it:

```bash
npx drizzle-kit generate
npx drizzle-kit push
```

---

### 4. Authentication Setup

**Gemini-CLI task:**

```bash
echo "Create lib/auth.ts with NextAuth using Credentials provider and Drizzle for user lookup" | gemini -p
```

Then refine with Continue:
- Prompt: **“Improve this auth file with proper error handling and session typing.”**

**lib/auth.ts** (key file):
```ts
import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";
import { db } from "./db";
import { users } from "@/drizzle/schema";
import { eq } from "drizzle-orm";
import bcrypt from "bcryptjs";

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Credentials({
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) return null;

        const user = await db.query.users.findFirst({
          where: eq(users.email, credentials.email as string),
        });

        if (!user?.password || !bcrypt.compareSync(credentials.password as string, user.password)) {
          return null;
        }

        return { id: user.id.toString(), email: user.email, name: user.name };
      },
    }),
  ],
  pages: { signIn: "/login" },
  session: { strategy: "jwt" },
});
```

Create the route handler and continue refining.

---

### 5. Server Actions (Core Mutations)

**In Continue:**
- Create `app/actions.ts`
- Prompt: **“Write all Server Actions for register, createPost, createComment, and deletePost with proper auth checks and revalidation.”**

**app/actions.ts**
```ts
'use server';

import { db } from '@/lib/db';
import { posts, comments, users } from '@/drizzle/schema';
import { revalidatePath } from 'next/cache';
import { auth } from '@/lib/auth';
import { eq } from 'drizzle-orm';
import bcrypt from 'bcryptjs';

export async function register(formData: FormData) { ... } // (as in previous version)

export async function createPost(formData: FormData) { ... }

export async function createComment(postId: number, formData: FormData) { ... }

export async function deletePost(id: number) { ... }
```

---

### 6. Building the UI with Continue

**Main Feed (`app/page.tsx`)**

Prompt Continue:  
**“Create the home page as a Server Component that fetches posts with relations and conditionally shows the create form for logged-in users.”**

**CreatePostForm** (Client Component)

Prompt:  
**“Build a client component using useActionState for creating posts with good UX and error handling.”**

**PostCard + CommentSection**

Prompt Continue iteratively:
- “Create PostCard server component that shows delete button for author only.”
- “Build CommentSection as client component with inline create form using Server Action.”

---

### 7. Login Page

Use Continue:
**“Create app/login/page.tsx with register form (Server Action) and login form (NextAuth signIn).”**

---

### 8. Master Co-Development Loop (Repeat for Every Feature)

1. **Define** the feature in one clear sentence.
2. **Plan with Continue** — `@codebase Suggest implementation following our rules.`
3. **Scaffold with Gemini-CLI** if needed (schemas, scripts).
4. **Implement small changes** in Continue → Review diffs carefully.
5. **Test** — `npm run dev`
6. **Debug with Gemini-CLI**:
   ```bash
   npm run build 2>&1 | gemini -p "Find root cause and suggest exact fix"
   ```
7. **Polish with Continue** — “Apply the fix with better TypeScript and error boundaries.”
8. **Commit smartly**:
   ```bash
   git diff --cached | gemini -p "Write a conventional commit message"
   ```

---

### 9. Running & Deploying

Add environment variables (`DATABASE_URL`, `NEXTAUTH_SECRET`) to `.env.local`.

```bash
npm run dev
```

**Deploy to Vercel** — Use Gemini-CLI to generate a deployment script:

```bash
echo "Create a deploy.sh script for Vercel with Drizzle migrations" | gemini -p
```

---

### 10. Next-Level Extensions (Practice the Loop)

- Add protected routes middleware (use Continue).
- Implement infinite scroll (Gemini-CLI for query, Continue for component).
- Add file uploads with uploadthing.
- Generate tests with Gemini-CLI.

---

**This workflow transforms AI from a simple autocomplete tool into a powerful co-developer.** 

**Recommended Habits:**
- Keep Continue focused on **code inside the repo**.
- Keep Gemini-CLI focused on **terminal, logs, and generation**.
- Always review AI suggestions before accepting.
- Maintain `PROMPTS.md` as your shared rulebook.

You now have a complete, working full-stack app **and** the skills to co-develop any future feature efficiently with Continue + Gemini-CLI.
