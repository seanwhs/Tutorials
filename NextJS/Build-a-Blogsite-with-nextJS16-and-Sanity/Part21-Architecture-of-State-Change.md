# GreyMatter Journal

# Part 21 — Comments, Likes, Mutations, and the Architecture of State Change

> **Goal of this lesson:** Add comments and likes to GreyMatter Journal while learning how mutations work, what state transitions are, why optimistic updates exist, how transactions guarantee consistency, and why software systems are fundamentally machines for transforming state over time.

---

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

This is because we've only built:

# Queries

---

# The Other Half Of Software

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

---

# What Is A Mutation?

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

A mutation transforms one state into another.

---

# Software Is Really About State

Most beginners think:

```text
Programming
        =
Writing Logic
```

But computers spend most of their lives doing:

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

---

# Building Comments

We'll create:

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

---

# Step 1 — Create The Comment Schema

Create:

```text
studio/schemaTypes/comment.ts
```

Add:

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

      to: [
        {
          type: "post",
        },
      ],
    }),
  ],
});
```

---

# Wait...

Why Add Approval?

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

Instead:

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

---

# This Is A State Machine

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

A state machine simply means:

> A system with valid states and legal transitions.

---

# Step 2 — Register The Schema

Open:

```text
studio/schemaTypes/index.ts
```

Add:

```typescript
import comment
  from "./comment";

export const schemaTypes = [
  post,
  author,
  category,
  comment,
];
```

---

# Step 3 — Create The Form

Create:

```text
components/

CommentForm.tsx
```

Add:

```tsx
"use client";

export default function
CommentForm({
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

---

# Wait...

Why Are Forms Still Important?

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

---

# Step 4 — Create API Endpoint

Create:

```text
app/

api/

comments/

route.ts
```

Add:

```typescript
import {
  writeClient,
} from "@/lib/sanity";

export async function POST(
  request: Request
) {
  const data =
    await request.formData();

  await writeClient.create({
    _type: "comment",

    author:
      data.get(
        "author"
      ),

    email:
      data.get(
        "email"
      ),

    content:
      data.get(
        "content"
      ),

    approved: false,

    post: {
      _type:
        "reference",

      _ref:
        data.get(
          "postId"
        ),
    },
  });

  return Response.json({
    success: true,
  });
}
```

---

# Wait...

Why Use A Separate Client?

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

Never expose:

```text
Write Tokens
```

to browsers.

---

# Step 5 — Create A Write Client

Open:

```text
lib/sanity.ts
```

Add:

```typescript
export const
writeClient =
  createClient({
    projectId,

    dataset,

    apiVersion,

    token:
      process.env
        .SANITY_API_TOKEN,

    useCdn: false,
  });
```

---

# Why Is Mutation Different?

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

---

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

---

# Step 6 — Add Like Count

Update:

```typescript
defineField({
  name: "likes",

  type: "number",

  initialValue: 0,
})
```

---

# Create Like Endpoint

Create:

```text
app/

api/

likes/

route.ts
```

Add:

```typescript
export async function POST(
  request: Request
) {
  const body =
    await request.json();

  await writeClient
    .patch(
      body.id
    )
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

# Wait...

Why Not Do This?

```typescript
likes = likes + 1;
```

Suppose:

```text
User A
User B
```

both click simultaneously.

Without atomic operations:

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

---

# Atomic Operations

Instead:

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

---

# This Is Called A Race Condition

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

Multiple actors compete to change state.

---

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

---

# Example

```tsx
const handleLike =
  async () => {

    setLikes(
      likes + 1
    );

    await fetch(
      "/api/likes",
      {
        method: "POST",
      }
    );
  };
```

---

# Wait...

What If The Server Fails?

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

---

# This Is Eventual Consistency Again

We've seen:

```text
Draft vs Published

Cache vs Database
```

Now:

```text
Client vs Server
```

Temporary disagreement is normal.

---

# Transactions

Suppose:

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

Bad.

---

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

---

# Event-Driven Architecture

Suppose someone comments:

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

---

# Modern Systems Are Event Systems

Most beginners think:

```text
Request
     ↓
Response
```

Modern architectures often work as:

```text
Event
    │
    ├── Action
    ├── Action
    ├── Action
    └── Action
```

---

# The Hidden Architecture

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

---

# Wait...

Does This Look Familiar?

We've already seen:

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

---

# The Deep Secret Of Software Engineering

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

Questions become:

```text
What state exists?

Who changes it?

When?

What if two people change it?

What if the change fails?

Can it be reversed?
```

---

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

Once you understand this, concepts like CRUD, events, transactions, messaging systems, distributed systems, and AI agent workflows become manifestations of the same fundamental principle.

---

# Up Next

In **Part 22**, we'll implement image uploads, optimization, and CDN delivery while learning:

* binary data,
* object storage,
* CDNs,
* image transformation pipelines,
* caching hierarchies,
* and why the internet is fundamentally a giant distributed content delivery system.
