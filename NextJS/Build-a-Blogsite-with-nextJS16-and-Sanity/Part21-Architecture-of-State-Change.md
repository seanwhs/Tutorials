# **✅ Part 21 — Comments, Likes, Mutations, and State Changes**

---

# GreyMatter Journal  
## Part 21 — Comments, Likes, Mutations, and the Architecture of State Change

> **Goal of this lesson:** Add interactive features (comments & likes) while understanding mutations, state transitions, optimistic updates, and transactions.

---

### From Read-Only to Interactive

So far we’ve built a powerful **read** system. Now we add **write** capabilities.

---

### Key Concepts

- **Query** → Observe current state
- **Mutation** → Transform state
- **State Machine** → Valid states + legal transitions

---

### 1. Comments

**Schema** (`studio/schemaTypes/comment.ts`):

```typescript
export default defineType({
  name: "comment",
  title: "Comment",
  type: "document",
  fields: [
    defineField({ name: "author", type: "string" }),
    defineField({ name: "email", type: "string" }),
    defineField({ name: "content", type: "text" }),
    defineField({ name: "approved", type: "boolean", initialValue: false }),
    defineField({ name: "post", type: "reference", to: [{ type: "post" }] }),
  ],
});
```

**Comment Form** (`components/CommentForm.tsx`):

Simple HTML form that posts to an API route.

**API Endpoint** (`app/api/comments/route.ts`):

Uses a write client to create new comment documents (marked as unapproved for moderation).

---

### 2. Likes

**Add to Post schema:**

```typescript
defineField({ name: "likes", type: "number", initialValue: 0 }),
```

**Like API** (`app/api/likes/route.ts`):

Uses `patch().inc()` for atomic increment.

---

### Optimistic Updates

UI shows the new count immediately, then confirms with the server (rollback on failure).

---

### Mental Model To Remember Forever

**Software = Machines for transforming state over time.**

Every user action is a state transition. Professional systems carefully manage these transitions with validation, transactions, optimistic UI, and eventual consistency.

---

### Up Next — Part 22: Image Uploads and CDN Delivery

We’ll handle image uploads, object storage, transformation pipelines, and why the modern web is built around intelligent content delivery.
