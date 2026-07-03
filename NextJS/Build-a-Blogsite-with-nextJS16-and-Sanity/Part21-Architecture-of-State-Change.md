# GreyMatter Journal

# Part 21 — Comments, Likes, Mutations, and the Architecture of State Change

> **Goal of this lesson:** Add comments and likes to GreyMatter Journal while learning how mutations work, what state transitions are, why optimistic updates exist, how transactions guarantee consistency, and why software systems are fundamentally machines for transforming state over time. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

***

# Up Until Now, Our Blog Has Been Read-Only

Our architecture currently looks like:

```text
Sanity
    │
    ▼
Read Content
    │
    ▼
Display Content
```

Users can:

```text
✓ Read articles
✓ Search articles
✓ Browse categories
✓ Preview drafts
```

But they cannot:

```text
✗ Leave comments
✗ Like articles
✗ Interact
✗ Create content
```

In other words, we have only built:

```text
Queries
```

We’ve taught the system how to read; now we need to teach it how to write.

***

# The Other Half of Software

Most beginners think:

```text
Database
      =
Read Data
```

But databases support two fundamental operations:

```text
Read
Write
```

Or more formally:

```text
Query
Mutation
```

Diagram:

```text
Database

    │

    ├── Query
    │
    └── Mutation
```

Queries **observe** state; mutations **change** state.

***

# What Is a Mutation?

Suppose we have:

```text
Likes = 10
```

After a user clicks:

```text
❤️ Like
```

we now have:

```text
Likes = 11
```

Diagram:

```text
Old State
     │
     ▼

Operation

     │
     ▼

New State
```

A mutation is any operation that transforms one state of the system into another.

***

# Software Is Really About State

Most beginners think:

```text
Programming
        =
Writing Logic
```

But computers spend most of their time doing:

```text
Current State
        │
        ▼

Transformation
        │
        ▼

New State
```

Examples:

```text
Shopping Cart

Empty
  ↓
Add Item
  ↓
One Item
```

```text
Authentication

Logged Out
     ↓
Login
     ↓
Logged In
```

```text
Comments

No Comment
      ↓
Create Comment
      ↓
Comment Exists
```

Once you see everything as state and transitions, mutations stop being mysterious and start becoming systematic.

***

# Building Comments

We’ll extend posts with comments:

```text
Post
    │
    └── Comments
```

Diagram:

```text
Article

   │

   ├── Comment
   ├── Comment
   └── Comment
```

Each comment is a separate document that references a post.

***

# Step 1 — Create the Comment Schema

Create:

```text
studio/schemaTypes/comment.ts
```

Add:

```typescript
import { defineField, defineType } from "sanity";

export default defineType({
  name: "comment",
  title: "Comment",
  type: "document",
  fields: [
    defineField({
      name: "author",
      title: "Author",
      type: "string",
    }),
    defineField({
      name: "email",
      title: "Email",
      type: "string",
    }),
    defineField({
      name: "content",
      title: "Content",
      type: "text",
    }),
    defineField({
      name: "approved",
      title: "Approved",
      type: "boolean",
      initialValue: false,
    }),
    defineField({
      name: "post",
      title: "Post",
      type: "reference",
      to: [{ type: "post" }],
    }),
  ],
});
```

This gives us structured, relational comments with an explicit moderation flag. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# Why Add Approval?

Without moderation:

```text
User
   │
   ▼

Publish Immediately
```

Result:

```text
Spam
Bots
Abuse
Garbage
```

Instead, we want:

```text
User
   │
   ▼

Pending
   │
   ▼

Editor Approval
   │
   ▼

Published
```

We’re turning comments into a small workflow, not just raw text.

***

# This Is a State Machine

Diagram:

```text
Draft
   │
   ▼

Pending
   │
   ▼

Approved
```

A state machine is simply:

> A system with valid states and legal transitions.

You can later extend this with states like `Rejected`, `Flagged`, or `Archived` without changing the core mental model.

***

# Step 2 — Register the Schema

Open:

```text
studio/schemaTypes/index.ts
```

Add:

```typescript
import comment from "./comment";

export const schemaTypes = [
  post,
  author,
  category,
  comment,
];
```

Now Sanity Studio knows about the `comment` document type and can display, edit, and query it. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# Step 3 — Create the Comment Form

Create:

```text
components/CommentForm.tsx
```

Add:

```tsx
"use client";

export default function CommentForm({
  postId,
}: {
  postId: string;
}) {
  return (
    <form action="/api/comments">
      <input
        type="hidden"
        name="postId"
        value={postId}
      />

      <input
        name="author"
        placeholder="Name"
      />

      <input
        name="email"
        placeholder="Email"
      />

      <textarea
        name="content"
        placeholder="Comment"
      />

      <button>
        Submit
      </button>
    </form>
  );
}
```

This is a classic HTML-form flow: submit data to a server endpoint, let the server perform the mutation, then respond.

***

# Why Are Forms Still Important?

Many beginners think:

```text
React
   =
No HTML Forms
```

Actually:

```text
HTML Forms
        =
The Internet's
Universal Mutation Protocol
```

Diagram:

```text
Browser
     │
     ▼

Form Data
     │
     ▼

Server
     │
     ▼

Mutation
```

Forms are how the web has expressed “state changes” for decades; frameworks like Next.js simply modernize how we handle them.

***

# Step 4 — Create the Comments API Endpoint

Create:

```text
app/
  api/
    comments/
      route.ts
```

Add:

```typescript
import { writeClient } from "@/lib/sanity";

export async function POST(request: Request) {
  const data = await request.formData();

  await writeClient.create({
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

  return Response.json({
    success: true,
  });
}
```

This endpoint:

- Accepts form data.
- Writes a new `comment` document in Sanity.
- Flags it as `approved: false` for moderation. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# Why Use a Separate Client?

Reading content:

```text
Public
```

Writing content:

```text
Secret
```

Diagram:

```text
Read Client
        │
        ▼
Public API


Write Client
         │
         ▼
Secret Token
```

We must never expose:

```text
Write Tokens
```

to browsers.

***

# Step 5 — Create a Write Client

Open:

```text
lib/sanity.ts
```

Add:

```typescript
export const writeClient = createClient({
  projectId,
  dataset,
  apiVersion,
  token: process.env.SANITY_API_TOKEN,
  useCdn: false,
});
```

- The read client can use the CDN and public configuration.
- The write client uses a secret token and bypasses the CDN because writes must go directly to the origin. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

Mutations are inherently more dangerous than queries, so they use different credentials, networks, and guardrails.

***

# Why Mutation Is Different

Reading:

```text
Safe
```

Writing:

```text
Dangerous
```

Because mutations create:

```text
Permanent Changes
```

A bug in a query shows the wrong data; a bug in a mutation corrupts the data itself.

***

# Adding Likes

Suppose an article has:

```text
42 likes
```

User clicks:

```text
❤️
```

The system performs:

```text
42
 │
 ▼

+1

 │
 ▼

43
```

Likes are another small state machine: a numeric counter that changes over time with user actions.

***

# Step 6 — Add Like Count to the Schema

Update your post schema:

```typescript
defineField({
  name: "likes",
  type: "number",
  initialValue: 0,
})
```

Now each post can track its like count as a simple integer field. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# Create the Likes Endpoint

Create:

```text
app/
  api/
    likes/
      route.ts
```

Add:

```typescript
import { writeClient } from "@/lib/sanity";

export async function POST(request: Request) {
  const body = await request.json();

  await writeClient
    .patch(body.id)
    .inc({ likes: 1 })
    .commit();

  return Response.json({
    success: true,
  });
}
```

Sanity’s `patch().inc()` performs an atomic increment on the `likes` field. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# Why Not Just Do `likes = likes + 1`?

Suppose:

```text
User A
User B
```

both click simultaneously.

Naive flow:

```text
42

A reads 42
B reads 42

A writes 43
B writes 43
```

Result:

```text
43
```

Wrong.

We lost a like because two updates raced against each other.

***

# Atomic Operations

With atomic increments:

```text
42

Increment
Increment

44
```

Diagram:

```text
Database

     │

     ▼

Atomic Operation

     │

     ▼

Correct Result
```

Atomic operations let the database handle concurrency; multiple clients can safely update the same value without stepping on each other.

***

# This Is Called a Race Condition

Diagram:

```text
User A ────┐
           │
           ▼

        Database

           ▲
           │

User B ────┘
```

Multiple actors compete to change state at the same time.

Race conditions are not bugs in a single function; they are bugs in the **timing** of interactions between functions.

***

# Optimistic Updates

Suppose liking an article takes:

```text
500ms
```

Traditional UI:

```text
Click
   │
Wait
   │
Update
```

Feels slow.

Instead:

```text
Click
   │
Update Immediately
   │
Server Confirms Later
```

The UI behaves as if the operation succeeded, and only corrects itself if the server later disagrees. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

***

# Example of an Optimistic Like

```tsx
const handleLike = async () => {
  setLikes(likes + 1);

  const response = await fetch("/api/likes", {
    method: "POST",
    body: JSON.stringify({ id: postId }),
  });

  if (!response.ok) {
    // Roll back if the server failed
    setLikes(likes);
  }
};
```

This pattern trades short-term accuracy for responsiveness; the UI feels instant, even over slow networks.

***

# What If the Server Fails?

Then:

```text
Optimistic Reality

≠

Actual Reality
```

Diagram:

```text
Browser:
43

Server:
42
```

Now we must:

```text
Rollback
```

or reconcile later, accepting that client and server may temporarily disagree.

***

# This Is Eventual Consistency Again

We’ve already seen:

```text
Draft vs Published

Cache vs Database
```

Now we add:

```text
Client vs Server
```

Temporary disagreement is normal; the important property is that the system converges to a consistent state eventually. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

***

# Transactions

Suppose a single user action should cause:

```text
Create Comment
Send Email
Update Counter
```

What if step two fails?

Without transactions:

```text
Comment Created

Email Failed

Counter Wrong
```

The system ends up in a partially updated, inconsistent state.

***

# Transactions Guarantee:

```text
Everything

or

Nothing
```

Diagram:

```text
Transaction

      │

      ├── Success
      │
      └── Rollback
```

Transactions ensure that related mutations either all succeed together or all fail together.

***

# Event-Driven Architecture

Suppose someone submits a comment:

```text
Comment Created
```

This event can trigger:

```text
Send Email

Update Analytics

Notify Author

Revalidate Cache
```

Diagram:

```text
Comment

    │

    ├── Email
    ├── Analytics
    ├── Notification
    └── Cache
```

Instead of doing everything synchronously in a single request, we emit events and let downstream systems react.

***

# Modern Systems Are Event Systems

Most beginners think:

```text
Request
     ↓
Response
```

Modern architectures often behave like:

```text
Event
    │
    ├── Action
    ├── Action
    ├── Action
    └── Action
```

APIs, queues, webhooks, and background workers form an ecosystem driven by events, not just individual HTTP requests.

***

# The Hidden Architecture of a Comment

When a user submits a comment:

```text
Browser
    │
    ▼

Form Submission
    │
    ▼

API Route
    │
    ▼

Validation
    │
    ▼

Mutation
    │
    ▼

Database
    │
    ▼

State Change
    │
    ▼

Event
    │
    ▼

UI Update
```

What looks like “I typed a comment and hit submit” is actually a pipeline of state transitions and events.

***

# State Trees

We’ve already seen:

```text
React Trees

Failure Trees

Reality Trees

Trust Trees
```

Now we discover:

```text
State Trees
```

because software systems fundamentally manage:

```text
State
through
time.
```

Different branches represent different possible futures as mutations are applied or rolled back.

***

# The Deep Secret of Software Engineering

Beginners think:

```text
Software
       =
Functions
```

Professional engineers think:

```text
Software
       =
State
       +
Transitions
```

Key questions:

```text
What state exists?

Who changes it?

When?

What if two people change it?

What if the change fails?

Can it be reversed?
```

Architecting systems is largely about answering these questions consistently.

***

# Mental Model To Remember Forever

Beginners think:

```text
Databases
         =
Storage
```

Professional engineers think:

```text
Databases
         =
State
         Machines
```

Or more generally:

```text
Software Systems
                =
Machines
                For
                Transforming
                State
                Through
                Time
```

Once you understand this, concepts like CRUD, events, transactions, messaging systems, distributed systems, and AI agent workflows all become manifestations of the same fundamental principle. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

***

# Up Next

In **Part 22**, we’ll implement image uploads, optimization, and CDN delivery while exploring:

- binary data,
- object storage,
- CDNs,
- image transformation pipelines,
- caching hierarchies,

and why the internet is fundamentally a giant distributed content delivery system.
