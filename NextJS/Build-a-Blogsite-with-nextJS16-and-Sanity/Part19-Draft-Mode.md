# GreyMatter Journal

# Part 19 — Draft Mode, Live Preview, and the Architecture of Multiple Realities

> **Goal of this lesson:** Build draft mode and live preview for GreyMatter Journal while learning how modern content systems manage published versus unpublished content, how caching works, and why distributed systems often maintain multiple versions of reality simultaneously.

---

# Our Blog Has A Serious Problem

Suppose you're writing an article:

```text
"The Architecture of React Server Components"
```

Current workflow:

```text
Write Article
      ↓
Publish
      ↓
Open Website
      ↓
Check Result
```

Problem:

```text
Everyone
can now
see your draft.
```

This is not how professional content systems work.

Professional CMS platforms provide:

```text
✓ Draft Content
✓ Published Content
✓ Preview Mode
✓ Live Updates
```

---

# One Article, Two Realities

Suppose you're writing:

```text
The Future of AI Engineering
```

Internally, Sanity stores:

```text
Draft Version
        +
Published Version
```

Diagram:

```text
Article

       │

       ├── Draft
       │
       └── Published
```

This means:

```text
Editors see:

Version A

Readers see:

Version B
```

Both realities exist simultaneously.

---

# Wait...

How Does Sanity Store Drafts?

Suppose your article ID is:

```text
article123
```

Published:

```text
article123
```

Draft:

```text
drafts.article123
```

Diagram:

```text
Published
──────────
article123


Draft
─────
drafts.article123
```

This simple idea powers most enterprise CMS systems.

---

# How Our Blog Currently Works

Today:

```text
Browser
    │
    ▼

Next.js
    │
    ▼

Sanity

Published Only
```

Diagram:

```text
Request
    │
    ▼
Published Content
    │
    ▼
HTML
```

---

# What We Want

Editors:

```text
Editor
    │
    ▼
Draft Content
```

Visitors:

```text
Visitor
     │
     ▼
Published Content
```

Diagram:

```text
                User

                  │

         ┌────────┴────────┐
         │                 │

      Editor            Visitor
         │                 │

         ▼                 ▼

      Draft          Published
```

---

# Step 1 — Enable Draft Mode

Next.js provides:

```text
Draft Mode
```

which temporarily disables caching.

Create:

```text
app/

api/

draft/

route.ts
```

Add:

```typescript
import {
  draftMode,
} from "next/headers";

import {
  redirect,
} from "next/navigation";

export async function GET(
  request: Request
) {
  const draft =
    await draftMode();

  draft.enable();

  const url =
    new URL(request.url);

  const slug =
    url.searchParams.get(
      "slug"
    );

  redirect(
    `/posts/${slug}`
  );
}
```

---

# Wait...

What Is An API Route?

Most beginners think:

```text
Website
```

But Next.js applications contain:

```text
Pages
+
APIs
```

Diagram:

```text
Next.js

     │

     ├── UI Routes
     │
     └── API Routes
```

Example:

```text
/posts/react

renders HTML
```

while:

```text
/api/draft

runs code
```

---

# What Does `draft.enable()` Do?

Normally:

```text
Request
    │
    ▼
Cache
    │
    ▼
Response
```

Draft mode changes this:

```text
Request
    │
    ▼
Disable Cache
    │
    ▼
Fetch Fresh Data
```

Diagram:

```text
Published

Cache
   │
   ▼
Response


Draft

No Cache
    │
    ▼
Fresh Data
```

---

# Step 2 — Detect Draft Mode

Open:

```text
app/posts/[slug]/page.tsx
```

Import:

```typescript
import {
  draftMode,
} from "next/headers";
```

Then:

```typescript
const {
  isEnabled,
} = await draftMode();
```

---

# Wait...

Why Is This Async?

In Next.js 16:

```typescript
draftMode()
```

returns:

```typescript
Promise<DraftMode>
```

because modern rendering pipelines are asynchronous.

Example:

```typescript
const {
  isEnabled,
} = await draftMode();
```

---

# Step 3 — Change The Query

Update:

```typescript
const post =
  await client.fetch(
    POST_QUERY,
    {
      slug:
        params.slug,
    },
    {
      perspective:
        isEnabled
          ? "previewDrafts"
          : "published",
    }
  );
```

---

# What Is A Perspective?

Think of:

```text
Perspective
```

as:

```text
Reality Filter
```

Diagram:

```text
Database

      │

      ├── Published View
      │
      └── Draft View
```

Example:

```text
Editor View

        ▼

Draft Reality


Visitor View

        ▼

Published Reality
```

---

# Let's Test It

Open Sanity Studio.

Edit an article:

```text
Change Title
```

but do NOT publish.

Example:

```text
Old:
"React Architecture"

New:
"Advanced React Architecture"
```

Normal users still see:

```text
React Architecture
```

Editors in preview mode see:

```text
Advanced React Architecture
```

---

# Wait...

How Can Two Users See Different Data?

Most beginners think:

```text
Database
      =
One Truth
```

Modern systems think:

```text
Database
      =
Multiple Views
```

Examples:

```text
Draft View

Published View

Admin View

User View

Analytics View
```

---

# Step 4 — Create Preview Links

Open:

```text
studio/schemaTypes/post.ts
```

Add:

```typescript
preview: {
  select: {
    title: "title",
  },
},
```

Later, editors can click:

```text
Open Preview
```

which calls:

```text
/api/draft?slug=my-post
```

---

# Understanding Preview Mode

Without preview:

```text
Editor

     │

     ▼

Publish

     │

     ▼

View Result
```

With preview:

```text
Editor

     │

     ▼

Save Draft

     │

     ▼

Preview Draft

     │

     ▼

Publish Later
```

---

# Wait...

Why Does Draft Mode Disable Caching?

Remember our architecture:

```text
Request
     │
     ▼

Cache
     │
     ▼

Sanity
```

Suppose we cache:

```text
React Article
```

for:

```text
1 hour
```

Editors would never see updates.

Therefore:

```text
Preview Mode
        ↓
Disable Cache
```

---

# What Is A Cache?

Most beginners think:

```text
Cache
      =
Magic Speed
```

Actually:

```text
Cache
      =
Temporary Copy
```

Diagram:

```text
Database

     │

     ▼

Copy

     │

     ▼

Future Requests
```

---

# Why Caching Is Hard

Suppose:

```text
Article Cached
```

Then:

```text
Author edits article
```

Question:

```text
Is cache correct?
```

This question is called:

# Cache Invalidation

---

# The Famous Quote

Computer science contains two famously difficult problems:

```text
1. Cache invalidation

2. Naming things

3. Off-by-one errors
```

The joke exists because:

```text
Keeping copies
synchronized
is incredibly hard.
```

---

# Live Preview

Professional editors expect:

```text
Type
   ↓
See Changes Immediately
```

Diagram:

```text
Editor
   │
   ▼
Save
   │
   ▼
CMS
   │
   ▼
Website
   │
   ▼
Update UI
```

This requires:

```text
Real-Time Systems
```

---

# What Is Real-Time?

Traditional systems:

```text
Request
    │
    ▼
Response
```

Real-time systems:

```text
Connection
      │
      ▼
Updates
      ▼
Updates
      ▼
Updates
```

Diagram:

```text
Client

    │

════Connection════

    │

Server

    │

Update
Update
Update
```

---

# Eventual Consistency

Suppose:

```text
Singapore Server
```

updates first.

Then:

```text
London Server
```

updates later.

For a brief moment:

```text
Singapore:
Version B

London:
Version A
```

Both are temporarily correct.

This is called:

# Eventual Consistency

---

# Wait...

Does This Mean There Is No Single Truth?

Exactly.

Modern distributed systems often maintain:

```text
Multiple
temporarily valid
truths.
```

Examples:

```text
Draft vs Published

Cache vs Database

Client vs Server

Replica A vs Replica B
```

---

# The Hidden Architecture

When an editor previews content:

```text
Browser
    │
    ▼

Draft Cookie
    │
    ▼

Next.js
    │
    ▼

Draft Mode
    │
    ▼

Disable Cache
    │
    ▼

Sanity Preview
    │
    ▼

Draft Document
    │
    ▼

React
    │
    ▼

UI
```

---

# Wait...

Does This Look Familiar?

We've already seen:

```text
Route Trees

React Trees

Portable Text Trees

Failure Trees
```

Now we discover:

```text
Reality Trees
```

because software systems often maintain:

```text
Multiple versions
of reality
simultaneously.
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Database
       =
Truth
```

Professional engineers think:

```text
Database
       =
One possible
representation
of truth
```

Or more generally:

```text
Distributed Systems
                  =
Managing
                  Multiple
                  Realities
```

Once you understand this, concepts like drafts, caching, replication, eventual consistency, and real-time systems become variations of the same fundamental idea.

---

# Up Next

In **Part 20**, we'll implement authentication and an admin area while learning:

* identity and authorization,
* sessions versus tokens,
* cookies and cryptography,
* trust boundaries,
* zero-trust architecture,
* and why security engineering is fundamentally about deciding who is allowed to believe what.
