# Appendix E2 — Securing Sanity Content with RBAC

> **Goal of this appendix:** Bridge your authentication system (Clerk) with your content management system (Sanity) to ensure that users only see, edit, or publish content they are authorized to touch.

---

## 1. The Core Challenge: Connecting Identity to Content

You have successfully synced users from Clerk to Sanity via webhooks. Now, we must enforce **Content Authorization**.

In professional applications, we don't just secure *pages*; we secure *data*. A user might have a valid Clerk session, but that does not mean they should be allowed to update the "Featured" status of an article or view unpublished drafts.

---

## 2. Implementing "Content Gating"

You should implement a two-tier security check.

### Tier 1: The API/Server Action Guard

Before your code even touches the Sanity Content Lake, verify the user's role using their Clerk session claims.

```typescript
// app/actions/posts.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { createClient } from "next-sanity";

export async function publishPost(postId: string) {
  const { sessionClaims } = await auth();
  
  // 1. Verify Role
  if (sessionClaims?.metadata?.role !== "admin") {
    throw new Error("Unauthorized: Only admins can publish.");
  }

  // 2. Perform Operation
  const client = createClient({ /* config */ });
  return await client.patch(postId).set({ status: "published" }).commit();
}

```

### Tier 2: The GROQ Query Guard

Even if a user is an "Author," you may want to restrict the data returned by your queries. You can dynamically adjust your GROQ queries based on the user's role.

```groq
// Only show drafts if the user has an 'editor' or 'admin' role
*[_type == "post" && (status == "published" || $userRole in ["admin", "editor"])]

```

---

## 3. Advanced Strategy: Sanity Document-Level Security

For even tighter control, you can define your Sanity schemas to include a `hidden` or `author` field that maps to your synced Clerk user.

### Recommended Schema Refinement

```typescript
{
  name: 'post',
  type: 'document',
  fields: [
    { name: 'title', type: 'string' },
    { 
      name: 'author', 
      type: 'reference', 
      to: [{ type: 'author' }] 
    },
    { 
      name: 'accessLevel', 
      type: 'string', 
      options: { list: ['public', 'internal', 'private'] } 
    }
  ]
}

```

---

## 4. The Professional Standard: "Least Privilege"

The goal of this architecture is **Least Privilege**: users should have exactly the permissions necessary to do their job, and nothing more.

* **Readers:** Can only execute queries filtered by `status == "published"`.
* **Authors:** Can create new posts but cannot change the `status` field to "published."
* **Editors:** Can view all posts and change statuses, but cannot delete the `author` documents.
* **Admins:** Full access to the Sanity Content Lake.

---

### Key Takeaways

1. **Validation is not optional:** Never assume that just because a button is hidden in the UI, the underlying API call is safe. Always re-validate the user role on the server.
2. **Use GROQ for filtering:** Instead of fetching all data and filtering it in your React components, filter the data at the database level using GROQ to prevent unauthorized data from ever leaving the server.
3. **Source of Truth:** Continue to treat Clerk as the *Identity Provider* and Sanity as the *Content Provider*. The "Role" is the bridge that connects the two.
