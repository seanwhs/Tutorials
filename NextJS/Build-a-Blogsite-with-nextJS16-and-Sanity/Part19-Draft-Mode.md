# GreyMatter Journal

# Part 19 — Draft Mode, Live Preview, and the Architecture of Multiple Realities

## Why Modern Software Systems Maintain Multiple Valid Truths

> **Goal of this lesson:** Implement Draft Mode and Live Preview while learning one of the deepest ideas in software architecture: large systems rarely operate with a single universal truth. Instead, they maintain multiple valid realities simultaneously.

---

# Our Publishing Workflow Has A Problem

So far, our publishing process looks straightforward:

```text
Editor writes article
         ↓
Editor publishes article
         ↓
Reader views article
```

At first glance, this seems perfectly reasonable.

Until an editor asks:

```text
What if I want to check the article first?

What if the images are broken?

What if the layout is wrong?

What if I accidentally publish unfinished content?

What if I want feedback before publishing?
```

Our current architecture forces editors into an uncomfortable position:

> The only way to see the article is to make it public.

Professional publishing systems never work this way.

Instead, they separate:

```text
Editing Reality

and

Publishing Reality
```

---

# The Myth Of A Single Truth

Beginners often imagine software systems like this:

```text
Database
     ↓
Truth
```

This feels intuitive.

There is one database.

Therefore there must be one truth.

Professional systems rarely work this way.

Instead:

```text
Database
     ↓

Draft Reality

Published Reality

Cached Reality

Replica Reality

Admin Reality

User Reality
```

All of these realities can coexist simultaneously.

---

# Multiple Realities Exist Everywhere

Once you begin looking for them, you discover multiple realities throughout software engineering.

### Google Docs

```text
My Draft
      ↓
Shared Document
```

---

### Git

```text
Working Directory
        ↓
Staging Area
        ↓
Commit History
```

---

### Figma

```text
Draft Design
        ↓
Published Design System
```

---

### Feature Flags

```text
Old Experience
        ↓
New Experience
```

---

### Databases

```text
Primary Database
        ↓
Read Replica
```

---

### Caches

```text
Cached Data
        ↓
Source Data
```

Professional software is largely the management of competing realities.

---

# How Sanity Stores Drafts

Suppose we create an article:

```text
understanding-nextjs
```

When published, Sanity stores:

```text
post-abc123
```

When editing begins, Sanity creates:

```text
drafts.post-abc123
```

Notice what happened.

We did not modify the existing document.

We created another reality.

```text
Published
     ↓
post-abc123

Draft
     ↓
drafts.post-abc123
```

Visually:

```text
                Content Lake

                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼

Published Reality        Draft Reality

post-abc123          drafts.post-abc123
```

Both versions exist simultaneously.

---

# Reality Depends On Perspective

This introduces one of the deepest ideas in software architecture:

```text
Reality
     =
Data
     +
Perspective
```

Consider:

```text
Editor
      ↓
Draft Article

Reader
      ↓
Published Article
```

The article itself never changed.

Only the observer changed.

---

# How Draft Mode Works In Next.js

Next.js provides a mechanism called:

```text
Draft Mode
```

Draft mode is built from three ideas:

```text
Cookies
      +
Server Rendering
      +
Conditional Data Fetching
```

Conceptually:

```text
Browser Cookie
        ↓
Server Detects Cookie
        ↓
Select Perspective
        ↓
Render Reality
```

---

# Step 1 — Create The Draft Route

Create:

```text
app/api/draft/route.ts
```

```typescript
import { draftMode }
  from "next/headers";

import { redirect }
  from "next/navigation";

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

  if (slug) {
    redirect(
      `/posts/${slug}`
    );
  }

  redirect("/");
}
```

This route performs three operations:

```text
Enable Draft State
         ↓
Determine Destination
         ↓
Redirect User
```

---

# What Actually Happens?

Suppose the editor visits:

```text
/api/draft?slug=my-article
```

Internally:

```text
Browser Request
         ↓

Enable Draft Cookie
         ↓

Store Cookie
         ↓

Redirect User
         ↓

Request Article
         ↓

Detect Draft State
         ↓

Load Draft Reality
```

This is an example of:

```text
State Transfer
via HTTP
```

---

# Why Use Cookies?

A common question is:

> Why not use a URL?

For example:

```text
/posts/my-post?draft=true
```

The answer is:

```text
URLs are public.

Cookies are private.
```

URLs can:

```text
Be shared

Be indexed

Be cached

Be bookmarked
```

Cookies provide:

```text
Per User

Per Session

Secure

Invisible
```

state management.

---

# Detecting Which Reality We Are In

Inside our page:

```tsx
import { draftMode }
  from "next/headers";

const {
  isEnabled,
} = await draftMode();
```

The server now knows:

```text
Editor Reality
```

or:

```text
Reader Reality
```

---

# Selecting A Perspective

Now we select which version of reality to use.

```tsx
const post =
  await client.fetch(
    POST_QUERY,
    { slug },
    {
      perspective:
        isEnabled
          ? "previewDrafts"
          : "published",
    }
  );
```

This creates two parallel worlds:

```text
Reader
      ↓
Published Article

Editor
      ↓
Draft Article
```

Notice something remarkable:

```text
Same URL

Same Component

Same Query

Different Reality
```

---

# Perspective Is An Architectural Pattern

Draft mode introduces an architectural pattern used throughout software systems.

Examples:

### Authorization

```text
Guest
      ↓
Limited View

Admin
      ↓
Full View
```

---

### Feature Flags

```text
User A
      ↓
Old Feature

User B
      ↓
New Feature
```

---

### Localization

```text
User
      ↓
English

User
      ↓
Japanese
```

---

### Multi-Tenant Systems

```text
Company A
      ↓
Their Data

Company B
      ↓
Their Data
```

The underlying system remains identical.

Only the perspective changes.

---

# Showing The User Their Reality

A common UX pattern is displaying the active perspective.

For example:

```tsx
{
  isEnabled && (
    <div
      className="
        border-b
        border-amber-300
        bg-amber-100
        px-4
        py-3
        text-center
        text-sm
      "
    >
      Preview Mode Enabled
    </div>
  );
}
```

This prevents confusion between:

```text
Draft Reality

and

Published Reality
```

---

# Leaving Preview Mode

Create:

```text
app/api/disable-draft/route.ts
```

```typescript
import { draftMode }
  from "next/headers";

import { redirect }
  from "next/navigation";

export async function GET() {
  const draft =
    await draftMode();

  draft.disable();

  redirect("/");
}
```

This removes the draft perspective and returns the user to:

```text
Published Reality
```

---

# The Deep Distributed Systems Idea

Draft mode introduces one of the deepest ideas in distributed systems:

> There is often no single universal truth.

Instead:

```text
Truth
      =
State
      +
Observer
      +
Perspective
      +
Time
```

Consider:

```text
Cache
      ↓
Old Truth

Database
      ↓
Current Truth

Replica
      ↓
Eventually Consistent Truth
```

All of these realities can be simultaneously valid.

---

# Mental Model To Remember Forever

Beginners think:

```text
System
      ↓
One Truth
```

Professional engineers think:

```text
System
      ↓
Multiple Valid Truths
```

Distributed systems engineers think:

```text
Reality
      =
Data
      +
Perspective
      +
Time
```

Or, even more fundamentally:

```text
Software Architecture
          =
Managing Multiple Realities
```

Draft Mode is not merely a CMS feature.

It is your first encounter with one of the most profound ideas in computing:

> The same system can legitimately present different realities to different observers at the same time.

---

# Up Next — Part 20: Authentication, Identity, and the Engineering of Trust

Next we'll explore:

* Authentication
* Authorization
* Sessions
* Cookies
* User Identity
* Protected Routes
* Trust Boundaries
* Access Control

And discover perhaps the deepest idea in software architecture:

> Every software system is ultimately a system for deciding who and what to trust.
