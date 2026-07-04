# **✅ Part 21 — Comments, Likes, Mutations, and the Architecture of State Change**

# GreyMatter Journal

## Part 21 — Comments, Likes, Mutations, State Machines, and the Architecture of Change

> **Goal of this lesson:** Implement comments and likes while learning one of the deepest truths in software engineering: applications are fundamentally systems for managing state changes over time.

---

# The Moment Software Becomes Difficult

Up until now, GreyMatter Journal has largely been a **read system**.

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

This architecture is relatively straightforward because nothing changes.

However, modern applications are rarely read-only.

Users expect to:

* Comment
* Like
* Bookmark
* Follow
* Subscribe
* Edit
* Collaborate
* Publish

The moment users can change data, software becomes fundamentally more complex.

Because software is not really about displaying information.

Software is about managing change.

---

# Software Is State Over Time

One of the deepest ideas in computer science is:

> Software exists to transform state through time.

Consider the simplest possible feature:

```text
Likes = 42
```

A user clicks:

```text
Likes = 43
```

That tiny interaction hides an astonishing amount of complexity.

```text
User Intent
       ↓
Validation
       ↓
Authorization
       ↓
Mutation
       ↓
Persistence
       ↓
Consistency
       ↓
Cache Updates
       ↓
UI Updates
       ↓
Observability
```

What appears to be:

```text
Click Button
```

is actually:

```text
Coordinate Reality Change
```

This is what modern applications do.

---

# Applications Are State Machines

Beginners often think:

```text
Application
      =
Pages
```

Professional engineers think:

```text
Application
      =
State
      +
Transitions
```

For example:

```text
Article

Draft
   ↓
Review
   ↓
Published
   ↓
Archived
```

Or:

```text
Authentication

Anonymous
      ↓
Authenticated
      ↓
Authorized
```

Or:

```text
Comment

Created
      ↓
Moderated
      ↓
Approved
      ↓
Visible
```

Software bugs frequently occur when systems permit transitions that should never happen.

For example:

```text
Deleted
      ↓
Published
```

or:

```text
Anonymous
      ↓
Administrator
```

without proper validation.

Modern software engineering is largely the art of designing valid state transitions.

---

# Queries Versus Mutations

Distributed systems often separate operations into two categories.

## Queries

Queries observe state.

They ask:

> What does reality currently look like?

Examples:

```typescript
const posts =
  await client.fetch(
    POSTS_QUERY
  );
```

Or:

```text
How many likes?

Who is logged in?

What comments exist?

What articles are published?
```

Queries do not change reality.

They only observe it.

---

## Mutations

Mutations change state.

They ask:

> How should reality evolve?

Examples:

```text
Add Comment

Like Article

Delete Post

Publish Article

Create User
```

Mutations alter reality.

---

This distinction appears everywhere:

```text
REST

GET
      ↓
Query

POST
PUT
PATCH
DELETE
      ↓
Mutation
```

Or more fundamentally:

```text
Query
      =
Observe Reality

Mutation
      =
Change Reality
```

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

Notice one particularly important field:

```typescript
approved
```

which defaults to:

```text
false
```

This creates our first workflow state machine.

---

# Why Moderate Comments?

Suppose comments were automatically published:

```text
User
    ↓
Comment
    ↓
Public Website
```

This introduces serious risks:

* Spam
* Harassment
* Malware links
* SEO poisoning
* Abuse

Professional systems introduce additional states:

```text
User
    ↓
Created
    ↓
Pending Review
    ↓
Approved
    ↓
Published
```

Notice what happened.

We didn't add a feature.

We added a state machine.

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
        required
        placeholder="Name"
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
        required
        placeholder="Email"
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
        required
        placeholder="Comment"
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

This form performs our first user-generated mutation.

---

# Creating the Mutation Endpoint

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

The mutation pipeline becomes:

```text
Browser
      ↓
API Route
      ↓
Validation
      ↓
Database Mutation
      ↓
Persistence
      ↓
Response
```

---

# Implementing Likes

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

At first glance this appears trivial.

It isn't.

---

# The Problem of Time

Suppose two users click simultaneously.

Initial state:

```text
Likes = 42
```

User A reads:

```text
42
```

User B reads:

```text
42
```

User A writes:

```text
43
```

User B writes:

```text
43
```

Final result:

```text
43
```

But reality should be:

```text
44
```

This problem is called a:

```text
Race Condition
```

And race conditions are one of the fundamental problems of distributed systems.

---

# Atomic Operations

To solve this problem, databases provide atomic operations.

Instead of:

```text
Read
    ↓
Modify
    ↓
Write
```

we perform:

```text
Increment
```

as a single operation.

Sanity provides this through:

```typescript
await writeClient
  .patch(postId)
  .inc({
    likes: 1,
  })
  .commit();
```

The database guarantees:

```text
42
 ↓
43
 ↓
44
```

even when multiple users act simultaneously.

---

# Building the Like Endpoint

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

Our mutation pipeline now becomes:

```text
User Intent
       ↓
API Route
       ↓
Atomic Mutation
       ↓
Database
       ↓
Updated Reality
```

---

# Optimistic User Interfaces

Users dislike waiting.

Traditional applications behave like this:

```text
Click
     ↓
Wait
     ↓
Server
     ↓
Update UI
```

Modern applications behave differently:

```text
Click
     ↓
Update UI Immediately
     ↓
Call Server
     ↓
Confirm Later
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

because the system optimistically predicts the future.

---

# The UI Is Predicting Reality

This is a profound idea.

Consider:

```text
Server Reality:
42 likes
```

The user clicks:

```text
UI Reality:
43 likes
```

before the server confirms it.

The UI temporarily displays:

```text
Predicted Future State
```

rather than:

```text
Current State
```

Modern applications constantly predict reality.

---

# What Happens When Predictions Fail?

Suppose the server rejects the mutation.

```text
42
 ↓ click
43
 ↓
Server Error
 ↓
42
```

The system rolls back.

Professional software constantly balances:

```text
Correctness

versus

Responsiveness
```

This tradeoff appears throughout distributed systems.

---

# Transactions

Consider publishing an article.

You might need to:

```text
Create Article

Update Search Index

Send Notifications

Refresh Cache

Record Analytics
```

What happens if step three fails?

This introduces another foundational concept:

```text
Transactions
```

A transaction guarantees:

```text
Everything succeeds

or

Everything fails
```

Transactions protect system consistency.

---

# Event-Driven Systems

Modern systems increasingly think in terms of events.

Instead of:

```text
Call Function
```

we think:

```text
User Liked Post
          ↓
Update Counter
          ↓
Notify Author
          ↓
Update Analytics
          ↓
Refresh Cache
          ↓
Record Activity Feed
```

The event becomes the source of truth.

This architectural style scales naturally because systems communicate through events rather than direct dependencies.

---

# Eventual Consistency

One of the deepest truths in distributed systems is:

> Not all systems become consistent simultaneously.

Example:

```text
User likes article
        ↓
Database updated
        ↓
Analytics updated
        ↓
Search updated
        ↓
Cache updated
        ↓
Notification delivered
```

For a brief period:

```text
Different systems
see different realities.
```

This property is called:

```text
Eventual Consistency
```

Modern software constantly balances:

```text
Strong Consistency

versus

Scalability
```

---

# State Machines Are Everywhere

Comments:

```text
Created
     ↓
Moderated
     ↓
Approved
     ↓
Published
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

Likes:

```text
42
 ↓
43
```

Applications themselves are simply collections of interacting state machines.

---

# Mental Model To Remember Forever

Beginners think:

```text
User clicked button.
```

Professional engineers think:

```text
User expressed intent.
         ↓
System validated intent.
         ↓
State transition executed.
         ↓
Consistency preserved.
         ↓
Reality changed.
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
      +
Constraints
```

Applications are not collections of pages.

They are systems for coordinating change over time.

---

# Up Next — Part 22: Image Uploads, Object Storage, and Global Content Delivery

We'll explore:

* Image uploads
* Object storage
* Asset pipelines
* Content delivery networks
* Cache invalidation
* Transformation services
* Global edge delivery

and discover why the modern web is fundamentally a distributed content distribution system.
