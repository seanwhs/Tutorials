# **✅ Appendix D3 — The Complete API Layer and Server Actions**

---

# Appendix D3 — The Complete API Layer and Server Actions

> **Goal of this appendix:** Provide the full API implementation for GreyMatter Journal, including Server Actions, mutations, and best practices for building robust backend logic in Next.js 16.

---

### Why We Need a Dedicated API Layer

As your application grows, putting all logic directly in routes becomes messy. A clean API layer provides:

- Separation of concerns
- Reusability
- Testability
- Clear boundaries between UI and business logic

---

### Recommended API Structure

```text
app/api/
├── comments/
│   └── route.ts
├── likes/
│   └── route.ts
├── draft/
│   └── route.ts
└── revalidate/
    └── route.ts
```

---

### 1. Comments API (`app/api/comments/route.ts`)

```typescript
import { writeClient } from "@/lib/sanity";
import { log } from "@/lib/logger";

export async function POST(request: Request) {
  try {
    const data = await request.formData();

    const comment = await writeClient.create({
      _type: "comment",
      author: data.get("author"),
      email: data.get("email"),
      content: data.get("content"),
      approved: false,
      post: {
        _type: "reference",
        _ref: data.get("postId"),
      },
    });

    log("comment_created", {
      commentId: comment._id,
      postId: data.get("postId"),
      author: data.get("author"),
    });

    return Response.json({ success: true, commentId: comment._id });
  } catch (error) {
    console.error(error);
    return Response.json({ success: false, error: "Failed to create comment" }, { status: 500 });
  }
}
```

---

### 2. Likes API (`app/api/likes/route.ts`)

```typescript
import { writeClient } from "@/lib/sanity";

export async function POST(request: Request) {
  try {
    const { postId } = await request.json();

    await writeClient
      .patch(postId)
      .inc({ likes: 1 })
      .commit();

    return Response.json({ success: true });
  } catch (error) {
    console.error(error);
    return Response.json({ success: false }, { status: 500 });
  }
}
```

---

### 3. Draft Mode API (`app/api/draft/route.ts`)

(Already covered in Part 19)

---

### Best Practices for API Routes

- Use Server Actions for form submissions when possible
- Validate input
- Log important events
- Handle errors gracefully
- Return consistent response shapes

---

### Server Actions Example (Alternative to API Routes)

For simpler mutations, use Server Actions:

```tsx
// In a Server Component or Action
"use server";

import { writeClient } from "@/lib/sanity";

export async function createComment(formData: FormData) {
  const comment = await writeClient.create({
    _type: "comment",
    author: formData.get("author"),
    content: formData.get("content"),
    post: { _type: "reference", _ref: formData.get("postId") },
  });

  return { success: true, comment };
}
```

---

**Appendix D3 Complete.**
