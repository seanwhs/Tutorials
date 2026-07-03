# GreyMatter Journal

# Part 19 — Draft Mode, Live Preview, and the Architecture of Multiple Realities

> **Goal of this lesson:** Build draft mode and live preview for GreyMatter Journal while learning how modern content systems manage published versus unpublished content, how caching works, and why distributed systems often maintain multiple versions of reality simultaneously. [nextjs](https://nextjs.org/docs/app/guides/draft-mode)

***

# Our Blog Has A Serious Problem

Suppose you're writing an article:

```text
"The Architecture of React Server Components"
```

Your current workflow looks like this:

```text
Write Article
      ↓
Publish
      ↓
Open Website
      ↓
Check Result
```

The problem:

```text
Everyone
can now
see your draft.
```

You are publishing just to see if the layout, typography, and content feel right.

This is not how professional content systems work. [nextjs](https://nextjs.org/docs/app/guides/draft-mode)

Production CMS platforms provide:

```text
✓ Draft Content
✓ Published Content
✓ Preview Mode
✓ Live Updates
```

Editors can iterate safely; readers only ever see stable, reviewed content.

***

# One Article, Two Realities

Suppose you're writing:

```text
The Future of AI Engineering
```

Internally, Sanity stores this as two documents:

```text
Draft Version
        +
Published Version
```

Conceptually:

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

Both realities exist simultaneously, and which one you see depends on your perspective (draft vs published). [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# How Sanity Stores Drafts

Suppose your article ID is:

```text
article123
```

Sanity stores:

```text
Published:
article123

Draft:
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

This simple naming convention powers draft workflows across many enterprise CMS platforms: drafts live alongside published documents with a `drafts.` prefix, but are invisible to normal “published” queries. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# How Our Blog Currently Works

Today, GreyMatter Journal is effectively a “published-only” system:

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

Every request flows like this:

```text
Request
    │
    ▼
Published Content
    │
    ▼
HTML
```

If you change a draft in Sanity but don’t publish, the site never sees it.

***

# What We Want Instead

We want different realities for different users:

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

The same URL now has multiple possible answers; the system chooses the right one depending on context (cookies, session, and query perspective). [shahin](https://shahin.page/article/nextjs-draftmode-fetch-cache-forbidden-auth-server-components)

***

# Step 1 — Enable Draft Mode

Next.js provides **Draft Mode**, an editorial preview feature that temporarily changes how caching and rendering behave for a given browser session. [nextjs](https://nextjs.org/docs/app/api-reference/functions/draft-mode)

Create a route handler:

```text
app/
  api/
    draft/
      route.ts
```

Add:

```typescript
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";

export async function GET(request: Request) {
  const draft = await draftMode();
  draft.enable();

  const url = new URL(request.url);
  const slug = url.searchParams.get("slug");

  redirect(`/posts/${slug}`);
}
```

What this does:

- Sets a special **draft-mode cookie** in the user’s browser.
- Redirects them to the article they want to preview.
- Marks all subsequent requests from this browser as “preview session” until the cookie is cleared. [nextjsjp](https://nextjsjp.org/docs/app/api-reference/functions/draft-mode)

***

# What Is an API Route?

Most beginners think:

```text
Website
```

But a Next.js application is really:

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
     │   (render HTML)
     │
     └── API Routes
         (run code)
```

For example:

```text
/posts/react

→ renders HTML for the article
```

while:

```text
/api/draft

→ runs server code and sets cookies
```

The preview entry point is “just another route”, but instead of returning HTML directly, it configures the session and redirects.

***

# What Does `draft.enable()` Actually Do?

In a normal request:

```text
Request
    │
    ▼
Cache
    │
    ▼
Response
```

Draft Mode changes the story:

```text
Request
    │
    ▼
Disable Cache
    │
    ▼
Fetch Fresh Data
```

Conceptually:

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

Next.js uses a special cookie to signal that this session should **bypass the static cache and edge cache** and always fetch fresh data, so editors immediately see their latest drafts. [shahin](https://shahin.page/article/nextjs-draftmode-fetch-cache-forbidden-auth-server-components)

***

# Step 2 — Detect Draft Mode in the Post Page

Open:

```text
app/posts/[slug]/page.tsx
```

Import:

```typescript
import { draftMode } from "next/headers";
```

Then, in your page component:

```typescript
const { isEnabled } = await draftMode();
```

In Next.js 16, `draftMode()` is asynchronous and returns a `Promise<DraftMode>`, so you must `await` it or use React’s `use()` helper. [nextjs](https://nextjs.org/docs/app/api-reference/functions/draft-mode)

Example:

```typescript
export default async function PostPage({
  params,
}: {
  params: { slug: string };
}) {
  const { isEnabled } = await draftMode();

  // ...
}
```

***

# Why Is `draftMode()` Async?

In earlier versions, `draftMode()` was synchronous. [ru.nextjs](https://ru.nextjs.im/docs/app/api-reference/functions/draft-mode)

In modern Next.js, rendering is built around asynchronous pipelines:

- Data fetching,
- Streaming,
- Caching,
- And server components all rely on async operations. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

So `draftMode()` became an async API too:

```typescript
const { isEnabled } = await draftMode();
```

This keeps Draft Mode compatible with streaming and Partial Prerendering, where multiple async data sources feed a single page. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

***

# Step 3 — Change the Query Perspective

Now wire draft mode into your Sanity query.

Update:

```typescript
const post = await client.fetch(
  POST_QUERY,
  {
    slug: params.slug,
  },
  {
    perspective: isEnabled ? "previewDrafts" : "published",
  }
);
```

Here:

- `perspective: "published"` means “only see documents without the `drafts.` prefix”.  
- `perspective: "previewDrafts"` means “merge `drafts.*` with their published counterparts”, so you see drafts when they exist and fall back to published when they don’t. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

This is your **reality filter**.

***

# What Is a Perspective?

Think of a **perspective** as a:

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

Examples:

```text
Editor View

        ▼

Draft Reality


Visitor View

        ▼

Published Reality
```

Same underlying documents, different *view* depending on which perspective you ask for. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# Let’s Test It

Open Sanity Studio.

Edit an article’s title:

```text
Change Title
```

but do **not** publish.

Example:

```text
Old:
"React Architecture"

New:
"Advanced React Architecture"
```

- Normal users (no draft cookie) still see:

  ```text
  React Architecture
  ```

- Editors in preview mode (draft cookie set, `perspective: "previewDrafts"`) see:

  ```text
  Advanced React Architecture
  ```

Two people, same URL, different realities.

***

# How Can Two Users See Different Data?

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

Each view has its own rules, filters, and access controls; Draft Mode is simply one of those views wired to a cookie. [autoheinz](https://autoheinz.com/blog/instant-cms-previews-nextjs-draftmode-edge-caches)

***

# Step 4 — Create Preview Links from Studio

Open:

```text
studio/schemaTypes/post.ts
```

Add a simple preview configuration:

```typescript
preview: {
  select: {
    title: "title",
  },
},
```

Later, you can enhance this with a custom “Open Preview” action that hits:

```text
/api/draft?slug=my-post
```

Workflow:

- Editor clicks “Open Preview” in Sanity.
- Sanity opens `/api/draft?slug=my-post` in a new tab.
- Next.js sets Draft Mode for that browser and redirects to `/posts/my-post`.
- The post page uses `perspective: "previewDrafts"` when `isEnabled` is true. [youtube](https://www.youtube.com/watch?v=MedyNgyYE-Q)

***

# Understanding Preview Mode as a Workflow

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

Preview mode decouples “see what it looks like” from “make this public”, which is essential for safe editorial workflows. [nextjs](https://nextjs.org/docs/app/guides/draft-mode)

***

# Why Draft Mode Disables Caching

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

If the editor updates the draft, but the cache still holds the old HTML, they will never see their changes during that hour.

Therefore:

```text
Preview Mode
        ↓
Disable Cache
```

In Next.js, Draft Mode tells the framework to bypass static and edge caches and fetch fresh data on every request for that session. [shahin](https://shahin.page/article/nextjs-draftmode-fetch-cache-forbidden-auth-server-components)

***

# What Is a Cache, Really?

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

You trade correctness-for-all-users for speed-for-most-users by serving copies instead of always going back to the origin.

***

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

This is the core of:

# Cache Invalidation

The famous joke:

```text
Computer science has two hard problems:

1. Cache invalidation

2. Naming things

3. Off-by-one errors
```

exists because:

```text
Keeping copies
synchronized
is incredibly hard.
```

Preview mode sidesteps this problem for editors by **opting them out** of the cache entirely. [nextjs](https://nextjs.org/docs/pages/guides/self-hosting)

***

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

where the CMS pushes updates or the site pulls them frequently enough that it *feels* instant (via webhooks, SSE, WebSockets, polling, or incremental revalidation). [autoheinz](https://autoheinz.com/blog/instant-cms-previews-nextjs-draftmode-edge-caches)

***

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

Instead of individual request–response cycles, you maintain a long-lived connection or frequent checks that feed a stream of updates into the UI. [autoheinz](https://autoheinz.com/blog/instant-cms-previews-nextjs-draftmode-edge-caches)

***

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

Both are temporarily “correct” given what each server has seen so far.

This is called:

# Eventual Consistency

The system guarantees that all replicas *eventually* converge to the same state, but not that they are always identical at any given instant. [autoheinz](https://autoheinz.com/blog/instant-cms-previews-nextjs-draftmode-edge-caches)

***

# Is There Still a Single Truth?

In practice, no.

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

Each represents a slightly different “now”, and the system’s job is to manage those differences and converge when it can. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

***

# The Hidden Architecture of Preview

When an editor previews content, the real architecture looks like this:

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

A single click in the CMS triggers cookies, caching rules, database perspectives, and React rendering pipelines—all working together to produce one editor’s “private reality”. [nextjs](https://nextjs.org/docs/app/api-reference/functions/draft-mode)

***

# Reality Trees

So far in GreyMatter Journal, you’ve seen:

```text
Route Trees

React Trees

Portable Text Trees

Failure Trees
```

Now we add:

```text
Reality Trees
```

because software systems often maintain:

```text
Multiple versions
of reality
simultaneously
```

connected by cookies, cache layers, and perspectives.

Each branch of the tree is a different view of the same underlying content.

***

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

Once you see the world this way, concepts like:

- drafts vs published,
- caching and invalidation,
- replication and failover,
- eventual consistency,
- and real-time previews

all become variations of the same fundamental idea: choosing which reality to show to which user, at which moment. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

***

# Up Next

In **Part 20**, we’ll implement authentication and an admin area while exploring:

- identity and authorization,
- sessions versus tokens,
- cookies and cryptography,
- trust boundaries,
- zero-trust architecture,

and why security engineering is fundamentally about deciding **who is allowed to believe what** in a distributed system.
