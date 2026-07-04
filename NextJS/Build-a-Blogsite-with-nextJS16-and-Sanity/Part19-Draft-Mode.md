# **✅ Part 19 — Draft Mode, Live Preview, and Multiple Realities**

# GreyMatter Journal

## Part 19 — Draft Mode, Live Preview, and the Architecture of Multiple Realities

> **Goal of this lesson:** Implement draft mode and live preview while learning one of the most important ideas in software architecture: systems often maintain multiple valid realities simultaneously.

---

# The Editorial Workflow Problem

Our publishing system currently works like this:

```text
Editor writes article
         ↓
Editor publishes article
         ↓
Editor checks article
```

This creates a serious problem.

What if:

```text
The article contains mistakes?

The layout is broken?

The images are incorrect?

The formatting is wrong?
```

The only way to verify content is to expose it publicly.

Professional publishing systems solve this by separating:

```text
Draft Reality

and

Published Reality
```

---

# One System, Multiple Realities

Most beginners imagine software systems like this:

```text
Database
     ↓
Truth
```

Real systems often look more like:

```text
Database
     ↓

Draft Truth

Published Truth

Cached Truth

User-Specific Truth
```

All of these realities can coexist simultaneously.

Examples include:

```text
Google Docs
    Draft vs Shared

Git
    Working Tree vs Commit

Figma
    Draft vs Published

CMS
    Draft vs Published

Feature Flags
    Enabled vs Disabled
```

Draft mode is our first encounter with this idea.

---

# How Sanity Stores Drafts

Suppose we create an article:

```text
understanding-nextjs
```

The published document might be:

```text
post-abc123
```

When an editor creates a draft, Sanity stores:

```text
drafts.post-abc123
```

Notice:

```text
Published:
post-abc123

Draft:
drafts.post-abc123
```

Both documents exist simultaneously.

Visually:

```text
Content Lake

    Published
         ↓
    post-abc123

    Draft
         ↓
    drafts.post-abc123
```

This allows editors to work safely without affecting readers.

---

# Draft Mode in Next.js

Next.js provides a mechanism called:

```text
Draft Mode
```

Draft mode is implemented using:

```text
Cookies
        +
Server Rendering
        +
Conditional Data Fetching
```

When enabled:

```text
Browser Cookie
         ↓
Server Detects Preview
         ↓
Different Data Source
         ↓
Different Reality
```

---

# Step 1 — Create the Draft Route

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
Enable Draft Cookie
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
Request
      ↓
Enable Cookie
      ↓
Browser Stores Cookie
      ↓
Redirect
      ↓
Request Article
      ↓
Server Detects Cookie
      ↓
Use Draft Reality
```

This is an example of:

```text
State Transfer
via HTTP
```

---

# Step 2 — Detect Draft Mode

Inside:

```text
app/(site)/posts/[slug]/page.tsx
```

we can detect the current reality.

```tsx
import { draftMode }
  from "next/headers";

const {
  isEnabled,
} = await draftMode();
```

The result becomes:

```text
true
```

or:

```text
false
```

depending on the browser cookie.

---

# Step 3 — Fetch Different Realities

Now we can select which reality we want.

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

This creates:

```text
Reader
      ↓
Published Reality

Editor
      ↓
Draft Reality
```

The component itself never changes.

Only the data source changes.

---

# The Architecture of Perspectives

One of the most important ideas in software architecture is:

```text
Reality
     =
Perspective
```

Examples:

```text
Guest User
      ↓
Limited Data

Admin User
      ↓
Full Data

Editor
      ↓
Draft Data

Reader
      ↓
Published Data
```

The underlying system remains identical.

Only the perspective changes.

---

# Why Use Cookies?

You might ask:

> Why not simply pass a query parameter?

For example:

```text
/posts/my-post?draft=true
```

Because:

```text
URLs are public.

Cookies are private.
```

Cookies allow:

```text
Per User

Per Session

Secure

Invisible
```

state management.

---

# A Preview Banner

A common pattern is showing editors which reality they're viewing.

Example:

```tsx
{
  isEnabled && (
    <div
      className="
        bg-amber-100
        border-b
        border-amber-300
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
Draft

and

Published
```

states.

---

# Exiting Draft Mode

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

This returns the user to:

```text
Published Reality
```

---

# Multiple Realities Exist Everywhere

Draft mode is not unusual.

In fact, modern systems constantly maintain multiple realities.

Examples:

```text
Git

Working Tree
      ↓
Committed State

React

Virtual DOM
      ↓
Real DOM

Database

Replica
      ↓
Primary

Cache

Cached Value
      ↓
Origin Value

Feature Flags

Old Experience
      ↓
New Experience
```

Modern software is largely the management of competing realities.

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

More generally:

```text
Reality
      =
Data
      +
Perspective
```

Draft Mode is not merely a CMS feature.

It is an introduction to one of the deepest ideas in distributed systems:

> The same underlying data can legitimately appear differently depending on who is looking at it.

---

# Up Next — Part 20: Authentication, Identity, and Trust

We'll explore:

* Authentication
* Authorization
* Sessions
* Cookies
* User identity
* Protected routes
* Trust boundaries

and discover that software architecture is ultimately the engineering of trust.
