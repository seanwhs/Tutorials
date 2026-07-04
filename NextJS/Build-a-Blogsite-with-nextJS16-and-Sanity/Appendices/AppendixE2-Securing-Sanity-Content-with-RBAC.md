# **✅ Appendix E2 — Securing Sanity Content with RBAC**

---

# Appendix E2 — Securing Sanity Content with RBAC

> **Goal of this appendix:** Bridge your authentication system (Clerk) with your content management system (Sanity) to ensure users only see, edit, or publish content they are authorized to touch.

---

### 1. The Core Challenge: Connecting Identity to Content

You have synced users from Clerk to Sanity via webhooks. Now you must enforce **Content Authorization**.

In professional applications, we don’t just secure *pages* — we secure *data*.

---

### 2. Implementing Content Gating

#### Tier 1: The API/Server Action Guard

```typescript
// app/actions/posts.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { writeClient } from "@/lib/sanity";

export async function publishPost(postId: string) {
  const { sessionClaims } = await auth();

  if (sessionClaims?.metadata?.role !== "admin") {
    throw new Error("Unauthorized: Only admins can publish.");
  }

  return await writeClient
    .patch(postId)
    .set({ status: "published" })
    .commit();
}
```

#### Tier 2: The GROQ Query Guard

Dynamically filter data based on user role:

```groq
*[_type == "post" && (status == "published" || $userRole in ["admin", "editor"])]
```

---

### 3. Advanced Strategy: Document-Level Security

Refine your Sanity schema:

```typescript
{
  name: 'post',
  type: 'document',
  fields: [
    { name: 'title', type: 'string' },
    { name: 'author', type: 'reference', to: [{ type: 'author' }] },
    { name: 'accessLevel', type: 'string', options: { list: ['public', 'internal', 'private'] } }
  ]
}
```

---

### 4. The Professional Standard: Least Privilege

- **Readers**: Can only see published content
- **Authors**: Can create posts but not publish
- **Editors**: Can moderate and publish
- **Admins**: Full access

---

### Key Takeaways

1. Always re-validate roles on the server.
2. Filter data at the database level using GROQ.
3. Treat Clerk as the source of truth for identity and Sanity as the source of truth for content.

**Security = Trust Management Under Uncertainty.**

---

**Appendix E2 Complete.**
