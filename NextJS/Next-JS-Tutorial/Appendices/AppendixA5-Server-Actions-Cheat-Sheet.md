# **Appendix A5 — Next.js 16 Server Actions Cheat Sheet**  
**The Complete Guide to `"use server"` and Server-Side Mutations**

> **Purpose:** This appendix is the definitive reference for Server Actions in Next.js 16. They fundamentally simplify mutations, forms, and client-server interactions while maintaining security and performance.

---

### Introduction

**Before Server Actions:**
```text
Browser → fetch() → API Route → Validation → DB
```

**With Server Actions:**
```text
Browser → Server Action → Validation → DB → Cache Update
```

The API layer often disappears for internal operations.

---

### The Big Mental Shift

**Traditional:** Separate frontend + backend with REST/GraphQL.  
**Next.js 16:** **RPC-style** functions that execute securely on the server, called directly from React components.

Server Actions are **React-integrated server functions** that feel like regular async functions but run with full server context.

---

### What Is a Server Action?

A function marked with `"use server"` that:
- Executes **only on the server**.
- Can be imported and called from Client or Server Components.
- Automatically handles serialization.
- Supports progressive enhancement (especially with forms).

---

### Basic Syntax

```ts
"use server";

export async function createPost(title: string) {
  // Full server context: DB, auth, files, etc.
  await db.post.create({ data: { title } });
}
```

**Requirements:**
- Must be `async`.
- Arguments and return values must be serializable.
- Runs in a secure server environment (no browser APIs).

---

### Calling Server Actions

#### 1. With Forms (Recommended)

```tsx
// actions.ts
"use server";
export async function createPost(formData: FormData) {
  const title = formData.get("title") as string;
  await db.post.create({ data: { title } });
}
```

```tsx
// Page or Component
import { createPost } from "./actions";

export default function Page() {
  return (
    <form action={createPost}>
      <input name="title" required />
      <button type="submit">Create Post</button>
    </form>
  );
}
```

**Benefits:** Native form behavior, accessibility, progressive enhancement, loading states.

#### 2. Programmatically (Client Components)

```tsx
"use client";
import { createPost } from "./actions";

export function CreateButton() {
  async function handleClick() {
    await createPost("My New Post");
  }

  return <button onClick={handleClick}>Create</button>;
}
```

---

### FormData Handling

```ts
"use server";
export async function savePost(formData: FormData) {
  const title = String(formData.get("title"));
  const published = formData.get("published") === "on";
  const tags = formData.getAll("tags");

  // Validation recommended
}
```

---

### Validation & Security

**Always validate on the server:**

```ts
import { z } from "zod";

const schema = z.object({
  title: z.string().min(1).max(200),
  body: z.string().min(10),
});

export async function createPost(formData: FormData) {
  const data = schema.parse({
    title: formData.get("title"),
    body: formData.get("body"),
  });

  // Proceed safely
}
```

**Authorization (Critical):**
```ts
const session = await auth();
if (!session?.user) throw new Error("Unauthorized");

if (session.user.role !== "admin") {
  throw new Error("Forbidden");
}
```

---

### Advanced Patterns

#### Redirects
```ts
import { redirect } from "next/navigation";

export async function saveAndRedirect() {
  // ... save logic
  redirect("/dashboard");   // Server-side redirect
}
```

#### Cache Revalidation
```ts
import { updateTag } from "next/cache";

export async function createPost(...) {
  await db.post.create(...);
  updateTag("posts");        // Or revalidateTag()
}
```

#### File Uploads
```ts
"use server";
export async function uploadFile(formData: FormData) {
  const file = formData.get("file") as File;
  // Process with fs, upload to S3, etc.
}
```

---

### Error Handling

Server Actions integrate naturally with React error boundaries:

```ts
export async function createPost(formData: FormData) {
  try {
    // logic
  } catch (error) {
    // Throw to trigger error.tsx or useFormStatus
    throw new Error("Failed to create post");
  }
}
```

---

### Architecture Recommendations

**Folder Structure:**
```text
app/
  actions/           # Or colocated
    posts.ts
    auth.ts
    users.ts
modules/
  posts/
    actions.ts
    queries.ts
    validators.ts
```

**Best Practice:** Keep actions thin — delegate complex logic to services or domain layers.

---

### Server Actions vs API Routes

| Feature                  | Server Actions              | API Routes (`route.ts`)    |
|--------------------------|-----------------------------|----------------------------|
| Form handling            | Excellent (native)          | Manual                     |
| React integration        | Seamless                    | None                       |
| Progressive enhancement  | Yes                         | No                         |
| External clients         | Limited                     | Excellent                  |
| Webhooks / Public APIs   | Not ideal                   | Recommended                |
| Serialization            | Automatic                   | Manual                     |
| Use Case                 | Internal mutations          | External integrations      |

---

### Proven Patterns

- **CRUD Operations** — Full create/read/update/delete with cache updates.
- **Optimistic UI** — Update local state first, then call action.
- **Transactions** — Use Prisma `$transaction` or similar for atomicity.
- **Authentication** — Check session at the start of every sensitive action.

---

### Common Mistakes to Avoid

1. Using browser-only APIs (`window`, `document`, `localStorage`).
2. Skipping server-side validation and authorization.
3. Forgetting to revalidate/update cache after mutations.
4. Putting heavy business logic directly in actions (extract to services).
5. Overusing actions for public APIs (use `route.ts` instead).

---

### Decision Tree

- **User-facing form or mutation?** → **Server Action**
- **Need external access (mobile, third-party)?** → **API Route**
- **Webhook or public endpoint?** → **API Route**
- **Internal admin/CMS/dashboard?** → **Server Action**

---

### Final Mental Model

Beginners think:  
*“Server Actions are just better API routes.”*

Professionals think:  
*“Server Actions are **secure RPC** built directly into React.”*

They don’t eliminate the need for a backend — they eliminate the boilerplate of building a large part of your HTTP layer for internal operations.

*Master Server Actions and forms become delightful, mutations become simple, and your full-stack development velocity skyrockets.*

*Updated for Next.js 16 — June 2026*
