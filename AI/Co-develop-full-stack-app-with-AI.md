# **Co-Developing a Full-Stack Next.js App with Continue + Gemini-CLI**

This guide delivers a **production-ready**, battle-tested workflow combining **Next.js App Router**, **Server Actions**, **TypeScript**, **Drizzle + PostgreSQL**, **Authentication**, and a powerful AI pair-programming setup with **Continue** (in-editor) and **Gemini-CLI** (terminal).

## Why This Workflow Wins
- **Continue** shines at codebase-aware reasoning, refactors, and architecture inside VS Code.
- **Gemini-CLI** excels at terminal orchestration, scaffolding, error analysis, and automation.
- Clean division of labor keeps you in control and minimizes hallucinations.

You’ll build a **Posts + Comments** community app with full CRUD, authentication (email/password), validation, optimistic patterns, and clean architecture — ready for scaling to real-time, file uploads, or testing.

## What You’re Building
- **Next.js 15+ App Router** (Server Components default, streaming, partial prerendering)
- **Server Actions** for all mutations (progressive enhancement)
- **Drizzle ORM + PostgreSQL**
- **Tailwind CSS** + modern dark UI
- **NextAuth** (Credentials provider)
- **TypeScript** (strict)
- Reusable patterns for auth, optimistic UI, and cache revalidation

---

### 1. Project Setup

```bash
npx create-next-app@latest my-fullstack-app \
  --typescript --tailwind --eslint --app --yes

cd my-fullstack-app

npm install drizzle-orm postgres @vercel/postgres bcryptjs next-auth
npm install -D drizzle-kit

# Optional: shadcn/ui for polished components
npx shadcn-ui@latest init
```

**lib/db.ts**
```ts
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

const connectionString = process.env.DATABASE_URL!;
const client = postgres(connectionString);
export const db = drizzle(client);
```

---

### 2. Install & Configure AI Tools

**Continue (VS Code)**
Install the Continue extension. Create/edit `~/.continue/config.yaml`:

```yaml
name: Next.js Co-dev
version: 0.1.0
models:
  - name: Gemini Flash
    provider: gemini
    model: gemini-1.5-flash
    apiKey: ${GEMINI_API_KEY}
    roles: [autocomplete, chat, edit, generate]
  - name: Gemini Pro
    provider: gemini
    model: gemini-1.5-pro
    apiKey: ${GEMINI_API_KEY}
    roles: [chat]
rules:
  - "Always use Next.js App Router and Server Actions"
  - "Prefer Server Components by default"
  - "Use TypeScript strictly"
  - "Validate all inputs server-side"
  - "Keep components small and composable"
```

**Gemini-CLI**
Follow installation from its repo. Test:

```bash
echo "Explain Server Actions best practices" | gemini -p
```

---

### 3. Project Architecture

```
my-fullstack-app/
├── app/
│   ├── actions.ts
│   ├── api/auth/[...nextauth]/route.ts
│   ├── globals.css
│   ├── layout.tsx
│   ├── login/page.tsx
│   ├── page.tsx
│   └── posts/[id]/page.tsx
├── components/
│   ├── AuthForm.tsx
│   ├── CreatePostForm.tsx
│   ├── PostCard.tsx
│   └── CommentSection.tsx
├── drizzle/
│   └── schema.ts
├── lib/
│   ├── auth.ts
│   ├── db.ts
│   └── utils.ts
├── .env.local
├── drizzle.config.ts
├── PROMPTS.md
├── next.config.ts
└── package.json
```

---

### 4. Database Schema (`drizzle/schema.ts`)

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

Run via Gemini-CLI or manually:
```bash
npx drizzle-kit generate
npx drizzle-kit push
```

---

### 5. Full Implementation

**lib/auth.ts**
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

**app/api/auth/[...nextauth]/route.ts**
```ts
import { handlers } from "@/lib/auth";
export { GET, POST } from "@/lib/auth";
```

**app/actions.ts**
```ts
'use server';

import { db } from '@/lib/db';
import { posts, comments, users } from '@/drizzle/schema';
import { revalidatePath } from 'next/cache';
import { auth } from '@/lib/auth';
import { eq } from 'drizzle-orm';
import bcrypt from 'bcryptjs';

export async function register(formData: FormData) {
  const name = formData.get('name')?.toString().trim();
  const email = formData.get('email')?.toString().trim();
  const password = formData.get('password')?.toString();

  if (!name || !email || !password) throw new Error("All fields are required");

  const hashed = bcrypt.hashSync(password, 12);
  await db.insert(users).values({ name, email, password: hashed });

  revalidatePath('/login');
  return { success: true, message: "Account created" };
}

export async function createPost(formData: FormData) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");

  const title = formData.get('title')?.toString().trim();
  const content = formData.get('content')?.toString().trim();

  if (!title || !content) throw new Error("Title and content required");

  await db.insert(posts).values({ title, content, authorId: parseInt(session.user.id) });
  revalidatePath('/');
  return { success: true };
}

export async function createComment(postId: number, formData: FormData) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");

  const content = formData.get('content')?.toString().trim();
  if (!content) throw new Error("Comment required");

  await db.insert(comments).values({
    content,
    postId,
    authorId: parseInt(session.user.id),
  });

  revalidatePath(`/posts/${postId}`);
  return { success: true };
}

export async function deletePost(id: number) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");

  await db.delete(posts).where(eq(posts.id, id));
  revalidatePath('/');
}
```

**app/layout.tsx**
```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Community • Next.js Starter",
  description: "Full-stack posts & comments with AI co-development",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full">
      <body className="min-h-full bg-zinc-950 text-zinc-50 antialiased">
        {children}
      </body>
    </html>
  );
}
```

**app/page.tsx**
```tsx
import { auth } from '@/lib/auth';
import { db } from '@/lib/db';
import { posts } from '@/drizzle/schema';
import { desc } from 'drizzle-orm';
import PostCard from '@/components/PostCard';
import CreatePostForm from '@/components/CreatePostForm';

export default async function Home() {
  const session = await auth();
  const allPosts = await db.query.posts.findMany({
    with: { author: true, comments: { with: { author: true } } },
    orderBy: [desc(posts.createdAt)],
  });

  return (
    <main className="max-w-3xl mx-auto p-6 pt-12">
      <div className="flex justify-between items-center mb-10">
        <h1 className="text-5xl font-bold tracking-tight">Community</h1>
        {session ? (
          <span className="text-sm text-zinc-400">Signed in as {session.user?.email}</span>
        ) : (
          <a href="/login" className="text-blue-400 hover:underline">Sign in</a>
        )}
      </div>

      {session && <CreatePostForm />}
      
      <div className="space-y-8 mt-8">
        {allPosts.map((post) => (
          <PostCard key={post.id} post={post} currentUserId={session?.user?.id} />
        ))}
      </div>
    </main>
  );
}
```

**components/CreatePostForm.tsx**
```tsx
'use client';

import { useActionState } from 'react';
import { createPost } from '@/app/actions';

export default function CreatePostForm() {
  const [state, formAction] = useActionState(createPost, null);

  return (
    <form action={formAction} className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 mb-8">
      <input name="title" required placeholder="Post title..." className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 mb-3" />
      <textarea name="content" required placeholder="What are your thoughts?" rows={4} className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 mb-4" />
      <button type="submit" className="bg-white text-black px-8 py-3 rounded-xl font-medium hover:bg-zinc-200 transition">Publish Post</button>
      {state?.success && <p className="text-green-400 mt-3">Post published successfully!</p>}
    </form>
  );
}
```

**components/PostCard.tsx**
```tsx
import { deletePost } from '@/app/actions';
import CommentSection from './CommentSection';

export default function PostCard({ post, currentUserId }: any) {
  const isAuthor = currentUserId === post.authorId?.toString();

  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-3xl p-8">
      <div className="flex justify-between items-start">
        <div>
          <h2 className="text-2xl font-semibold mb-1">{post.title}</h2>
          <p className="text-zinc-400 text-sm">by {post.author?.name}</p>
        </div>
        {isAuthor && (
          <form action={async () => { await deletePost(post.id); }}>
            <button type="submit" className="text-red-400 text-sm hover:underline">Delete</button>
          </form>
        )}
      </div>

      <p className="mt-6 text-lg leading-relaxed whitespace-pre-wrap">{post.content}</p>

      <CommentSection postId={post.id} comments={post.comments} />
    </div>
  );
}
```

**components/CommentSection.tsx**
```tsx
'use client';

import { useActionState } from 'react';
import { createComment } from '@/app/actions';

export default function CommentSection({ postId, comments }: { postId: number; comments: any[] }) {
  const [state, formAction] = useActionState((prev: any, formData: FormData) => createComment(postId, formData), null);

  return (
    <div className="mt-8 pt-6 border-t border-zinc-800">
      <h3 className="font-medium mb-4">Comments ({comments.length})</h3>
      
      <div className="space-y-4 mb-6">
        {comments.map((c) => (
          <div key={c.id} className="bg-zinc-950 border border-zinc-800 rounded-xl p-4">
            <p className="text-sm text-zinc-400 mb-1">by {c.author?.name}</p>
            <p>{c.content}</p>
          </div>
        ))}
      </div>

      <form action={formAction} className="flex gap-3">
        <input name="content" placeholder="Write a comment..." className="flex-1 bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3" required />
        <button type="submit" className="bg-blue-600 px-6 py-3 rounded-xl">Send</button>
      </form>
      {state?.success && <p className="text-green-400 text-sm mt-2">Comment added</p>}
    </div>
  );
}
```

**app/login/page.tsx** (Simple combined form)
```tsx
'use client';

import { useActionState } from 'react';
import { register } from '@/app/actions';
import { signIn } from 'next-auth/react';

export default function LoginPage() {
  const [regState, regAction] = useActionState(register, null);

  return (
    <div className="max-w-md mx-auto mt-20">
      <div className="bg-zinc-900 border border-zinc-800 rounded-3xl p-8">
        <h1 className="text-3xl font-bold mb-8 text-center">Join the Community</h1>

        {/* Register Form */}
        <form action={regAction} className="space-y-4">
          <input name="name" placeholder="Full name" required className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3" />
          <input name="email" type="email" placeholder="Email" required className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3" />
          <input name="password" type="password" placeholder="Password" required className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3" />
          <button type="submit" className="w-full bg-white text-black py-3 rounded-xl font-medium">Create Account</button>
        </form>

        {regState?.success && <p className="text-green-400 mt-4 text-center">Account created! Now sign in below.</p>}

        <div className="my-6 border-t border-zinc-800" />

        {/* Login */}
        <form onSubmit={(e) => { e.preventDefault(); signIn("credentials", { email: (e.target as any).email.value, password: (e.target as any).password.value, redirect: true }); }} className="space-y-4">
          <input name="email" type="email" placeholder="Email" required className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3" />
          <input name="password" type="password" placeholder="Password" required className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3" />
          <button type="submit" className="w-full bg-blue-600 py-3 rounded-xl font-medium">Sign In</button>
        </form>
      </div>
    </div>
  );
}
```

---

### 6. Master Co-Development Loop
1. Define feature in one sentence.
2. Use Continue (`@codebase`) to plan implementation.
3. Make small changes → Review diff.
4. Run `npm run dev`.
5. Debug with Gemini-CLI: `npm run build 2>&1 | gemini -p "Root cause + fix"`.
6. Polish with Continue.
7. Commit with Gemini-CLI.

---

### 7. Powerful Prompts & Golden Rules
(See **PROMPTS.md** in repo for full list.)

**Next.js Config** (optional body size):
```ts
// next.config.ts
const nextConfig = { experimental: { serverActions: { bodySizeLimit: '2mb' } } };
export default nextConfig;
```

---

### 8. Run Locally & Deploy
1. Add `DATABASE_URL` and `NEXTAUTH_SECRET` to `.env.local`
2. `npm install`
3. `npx drizzle-kit push`
4. `npm run dev`

**Deploy**: Vercel (easiest for Next.js + Server Actions). Push to GitHub and connect.

