# **✅ Part 21 — Comments, Likes, Mutations, and the Architecture of State Change**

# GreyMatter Journal

## Part 21 — Comments, Likes, Mutations, and the Architecture of State Change

> **Goal of this lesson:** Implement comments and likes while learning how modern applications manage state changes, mutations, transactions, optimistic updates, and consistency.

---

# From Reading Systems to Interactive Systems

Up until now, GreyMatter Journal has been primarily a **read system**.

Our architecture has looked like this:

```text
Database
      ↓
Server Components
      ↓
HTML
      ↓
Reader
```

Readers consume information.

But modern applications are rarely read-only.

Users expect to:

* Comment
* Like
* Bookmark
* Follow
* Share
* Edit
* Collaborate

The moment users can change data, software becomes fundamentally more complex.

---

# Software Is State Change

One of the deepest ideas in computer science is:

> Software exists to transform state over time.

Consider a simple "Like" button.

Initially:

```text
Likes = 42
```

User clicks:

```text
Likes = 43
```

That tiny interaction hides a surprisingly large amount of complexity:

```text
User Intent
       ↓
Validation
       ↓
Mutation
       ↓
Database Update
       ↓
Cache Update
       ↓
UI Update
       ↓
Consistency
```

Modern applications are essentially machines for coordinating state changes.

---

# Queries vs Mutations

A useful distinction comes from distributed systems:

## Queries

Queries observe state.

```text
Current Likes?
Current Comments?
Current User?
```

Examples:

```typescript
const posts =
  await client.fetch(
    POSTS_QUERY
  );
```

Queries answer:

> What does the system currently look like?

---

## Mutations

Mutations change state.

Examples:

```text
Add Comment

Like Article

Delete Post

Publish Article
```

Mutations answer:

> How should the system evolve?

---

# Thinking in State Machines

Professional engineers often model systems as state machines.

Consider article publishing:

```text
Draft
   ↓
Review
   ↓
Published
   ↓
Archived
```

Not every transition is legal:

```text
Archived
    ↓
Draft
```

may be forbidden.

Similarly, comments have states:

```text
Created
      ↓
Pending Moderation
      ↓
Approved
      ↓
Visible
```

Thinking in states helps prevent invalid system behavior.

---

# Building Comments

Comments are our first example of user-generated content.

Create:

```text
studio/schemaTypes/comment.ts
```

```typescript
import {
  defineField,
  defineType,
} from "sanity";

export default defineType({
  name: "comment",
  title: "Comment",
  type: "document",

  fields: [
    defineField({
      name: "author",
      type: "string",
    }),

    defineField({
      name: "email",
      type: "string",
    }),

    defineField({
      name: "content",
      type: "text",
    }),

    defineField({
      name: "approved",
      type: "boolean",
      initialValue: false,
    }),

    defineField({
      name: "post",
      type: "reference",
      to: [
        {
          type: "post",
        },
      ],
    }),
  ],
});
```

Notice an important field:

```typescript
approved
```

New comments default to:

```text
false
```

This introduces moderation.

---

# Why Moderate Comments?

Suppose comments were automatically published:

```text
User
    ↓
Comment
    ↓
Immediately Public
```

This creates risks:

* Spam
* Abuse
* Malware links
* Harassment
* SEO poisoning

Instead, professional systems introduce a review stage:

```text
User
    ↓
Draft Comment
    ↓
Moderation
    ↓
Published Comment
```

This is another example of state machines.

---

# Creating the Comment Form

Create:

```text
components/comments/CommentForm.tsx
```

```tsx
"use client";

export default function CommentForm() {
  return (
    <form
      action="/api/comments"
      method="POST"
      className="space-y-6"
    >
      <input
        name="author"
        placeholder="Name"
        required
        className="
          w-full
          rounded-lg
          border
          p-3
        "
      />

      <input
        name="email"
        type="email"
        placeholder="Email"
        required
        className="
          w-full
          rounded-lg
          border
          p-3
        "
      />

      <textarea
        name="content"
        rows={6}
        placeholder="Comment"
        required
        className="
          w-full
          rounded-lg
          border
          p-3
        "
      />

      <button
        className="
          rounded-lg
          bg-black
          px-6
          py-3
          text-white
        "
      >
        Submit Comment
      </button>
    </form>
  );
}
```

This form performs a mutation.

---

# Creating the API Route

Create:

```text
app/api/comments/route.ts
```

```typescript
import { NextResponse }
  from "next/server";

import {
  writeClient,
} from "@/lib/sanity";

export async function POST(
  request: Request
) {
  const body =
    await request.json();

  await writeClient.create({
    _type: "comment",

    author:
      body.author,

    email:
      body.email,

    content:
      body.content,

    approved:
      false,

    post: {
      _type:
        "reference",

      _ref:
        body.postId,
    },
  });

  return NextResponse.json({
    success: true,
  });
}
```

The flow becomes:

```text
Browser
      ↓
API Route
      ↓
Sanity Mutation
      ↓
Database
```

---

# Adding Likes

Now let's implement likes.

Update:

```text
studio/schemaTypes/post.ts
```

```typescript
defineField({
  name: "likes",
  type: "number",
  initialValue: 0,
});
```

---

# Why Counters Are Difficult

Suppose two users click simultaneously.

Initial state:

```text
Likes = 42
```

User A:

```text
42 + 1 = 43
```

User B:

```text
42 + 1 = 43
```

Result:

```text
43
```

But the correct answer is:

```text
44
```

This problem is called:

```text
Race Condition
```

---

# Atomic Mutations

To solve this, Sanity provides atomic updates.

```typescript
await writeClient
  .patch(postId)
  .inc({
    likes: 1,
  })
  .commit();
```

Instead of:

```text
Read
    ↓
Modify
    ↓
Write
```

the database performs:

```text
Increment
```

as a single operation.

This guarantees correctness.

---

# Building the Like API

Create:

```text
app/api/likes/route.ts
```

```typescript
export async function POST(
  request: Request
) {
  const {
    postId,
  } =
    await request.json();

  await writeClient
    .patch(postId)
    .inc({
      likes: 1,
    })
    .commit();

  return Response.json({
    success: true,
  });
}
```

---

# Optimistic Updates

Users dislike waiting.

Traditional UI:

```text
Click
     ↓
Wait
     ↓
Server
     ↓
Update UI
```

Modern UI:

```text
Click
     ↓
Update UI Immediately
     ↓
Call Server
     ↓
Confirm
```

Example:

```text
42
 ↓ click
43
```

before the server even responds.

This technique is called:

```text
Optimistic UI
```

because we optimistically assume success.

---

# Handling Failure

What if the mutation fails?

```text
42
 ↓ click
43
 ↓
Server Error
 ↓
42
```

The UI rolls back.

Professional systems constantly balance:

```text
Correctness
       vs
Responsiveness
```

---

# Transactions and Consistency

Imagine publishing a post.

You may need to:

```text
Create Article

Update Search Index

Send Notification

Invalidate Cache
```

Should these happen:

```text
All together
```

or:

```text
One by one?
```

This introduces another fundamental idea:

```text
Transactions
```

A transaction guarantees:

```text
Everything succeeds

or

Everything fails
```

---

# Event-Driven Thinking

Modern applications increasingly use events:

```text
User Liked Post
          ↓
Increase Counter
          ↓
Notify Author
          ↓
Update Analytics
          ↓
Refresh Cache
```

Instead of:

```text
Call Function
```

we think:

```text
Emit Event
```

This allows systems to scale more naturally.

---

# State Machines Are Everywhere

Comments:

```text
Pending
    ↓
Approved
    ↓
Published
```

Likes:

```text
42
 ↓
43
```

Authentication:

```text
Anonymous
      ↓
Authenticated
      ↓
Authorized
```

Publishing:

```text
Draft
    ↓
Review
    ↓
Published
```

Modern software engineering is largely the art of designing valid state transitions.

---

# Mental Model To Remember Forever

Beginners think:

```text
User clicks button
```

Professional engineers think:

```text
User Intent
        ↓
State Transition
        ↓
Validation
        ↓
Mutation
        ↓
Consistency
        ↓
Persistence
        ↓
User Interface
```

More fundamentally:

```text
Software
      =
State
      +
Time
      +
Transitions
```

Applications are not collections of pages.

They are systems for managing change.

---

# Up Next — Part 22: Image Uploads, Object Storage, and CDN Delivery

We'll explore:

* Image uploads
* Object storage
* Asset pipelines
* CDNs
* Cache invalidation
* Transformation services

and discover why the modern web is fundamentally a global content delivery system.
