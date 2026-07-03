# GreyMatter Journal

# Part 18 — Loading States, Error Boundaries, Suspense, and the Architecture of Failure

> **Goal of this lesson:** Learn how modern applications handle loading, errors, and failures. We'll build loading states, error pages, and not-found pages while understanding that software engineering is fundamentally about managing uncertainty.

---

# We've Been Living In A Fantasy World

Up until now, our application assumes:

```text
✓ Database always works
✓ Network always works
✓ Server always works
✓ Content always exists
✓ Users always wait patiently
```

Unfortunately, reality looks more like:

```text
✗ Database unavailable
✗ Network timeout
✗ Missing article
✗ Slow API
✗ Server crashes
✗ User closes tab
```

Professional software engineering is largely:

> Designing systems that continue functioning when reality disagrees with your assumptions.

---

# The Four States Of Every Application

Most beginners think:

```text
Data
   ↓
Display
```

Modern applications actually have:

```text
Loading
Success
Error
Not Found
```

Diagram:

```text
Request

   │

   ├── Loading
   │
   ├── Success
   │
   ├── Error
   │
   └── Not Found
```

---

# State 1 — Loading

Suppose your database needs:

```text
3 seconds
```

Should users see:

```text
Blank Screen
```

Of course not.

Instead:

```text
User
   │
   ▼

Loading State

   │
   ▼

Actual Content
```

---

# Next.js Makes Loading Special

Create:

```text
app/

posts/

[slug]/

loading.tsx
```

Add:

```tsx
export default function Loading() {
  return (
    <>
      <h1>
        Loading article...
      </h1>

      <p>
        Please wait.
      </p>
    </>
  );
}
```

---

# Wait...

That's all?

Yes.

Next.js automatically detects:

```text
loading.tsx
```

and uses it whenever:

```text
Server Component
       ↓
Still Fetching
```

Diagram:

```text
Request

    │

    ▼

Loading UI

    │

    ▼

Server Response

    │

    ▼

Final UI
```

---

# Let's Test It

Open:

```text
app/posts/[slug]/page.tsx
```

Temporarily add:

```typescript
await new Promise(
  resolve =>
    setTimeout(
      resolve,
      3000
    )
);
```

Example:

```tsx
export default async function
PostPage() {

  await new Promise(
    resolve =>
      setTimeout(
        resolve,
        3000
      )
  );

  ...
}
```

Visit an article.

You'll see:

```text
Loading article...
```

for three seconds.

---

# What Is Actually Happening?

Most beginners imagine:

```text
Wait
   ↓
Render
```

But Next.js performs:

```text
Request
    │
    ▼

Render Loading UI

    │
    ▼

Continue Rendering

    │
    ▼

Replace UI
```

This architecture is called:

# Progressive Rendering

---

# State 2 — Not Found

Suppose a user visits:

```text
/posts/i-do-not-exist
```

What should happen?

Bad:

```text
Crash
```

Good:

```text
404
```

---

# Next.js Provides A Helper

Open:

```text
app/posts/[slug]/page.tsx
```

Import:

```typescript
import {
  notFound,
} from "next/navigation";
```

Replace:

```typescript
if (!post) {
  return null;
}
```

with:

```typescript
if (!post) {
  notFound();
}
```

---

# Wait...

Why Is This Better?

Instead of:

```text
Nothing
```

Next.js performs:

```text
Throw Internal Signal
         │
         ▼
Render 404 Page
```

Diagram:

```text
Post Exists?

 YES           NO
  │             │
  ▼             ▼

Render       notFound()
                  │
                  ▼
               404 UI
```

---

# Creating The 404 Page

Create:

```text
app/

not-found.tsx
```

Add:

```tsx
import Link
  from "next/link";

export default function
NotFound() {
  return (
    <>
      <h1>
        Article Not Found
      </h1>

      <p>
        The article
        does not exist.
      </p>

      <Link href="/">
        Go Home
      </Link>
    </>
  );
}
```

Visit:

```text
/posts/abc123xyz
```

You now have a professional 404 page.

---

# State 3 — Errors

Suppose:

```text
Database Offline
```

or:

```text
API Timeout
```

or:

```text
Programming Bug
```

Should users see:

```text
Internal Server Error
```

No.

They should see:

```text
Friendly Error UI
```

---

# Create An Error Boundary

Create:

```text
app/

posts/

[slug]/

error.tsx
```

Add:

```tsx
"use client";

type Props = {
  error: Error;

  reset: () => void;
};

export default function
Error({
  error,
  reset,
}: Props) {
  return (
    <>
      <h1>
        Something went wrong
      </h1>

      <p>
        {error.message}
      </p>

      <button
        onClick={reset}
      >
        Try Again
      </button>
    </>
  );
}
```

---

# Wait...

Why Does This Need `"use client"`?

Remember:

```text
Server Components

cannot

handle browser events.
```

But:

```tsx
<button
  onClick={...}
/>
```

requires:

```text
JavaScript
```

Therefore:

```text
Error Boundary
        ↓
Client Component
```

---

# What Does `reset()` Do?

Suppose:

```text
Database Timeout
```

After five seconds:

```text
Database Returns
```

The user clicks:

```text
Try Again
```

Next.js performs:

```text
Discard Failed Render
          │
          ▼
Re-render Tree
```

Diagram:

```text
Error

   │

   ▼

Error Boundary

   │

   ▼

Reset

   │

   ▼

Retry Render
```

---

# Let's Simulate Failure

Temporarily add:

```typescript
throw new Error(
  "Database unavailable"
);
```

Example:

```tsx
export default async function
PostPage() {

  throw new Error(
    "Database unavailable"
  );

  ...
}
```

Visit an article.

You'll see your error page.

---

# What Is An Error Boundary?

Most beginners think:

```text
try/catch
```

But React thinks:

```text
Component Tree

        │

        ▼

Failure Boundary

        │

        ▼

Fallback UI
```

Diagram:

```text
Application

      │

      ├── Navbar
      │
      ├── Error Boundary
      │       │
      │       └── Post
      │
      └── Footer
```

---

# Notice Something Important

Suppose:

```text
Post crashes
```

Does:

```text
Navbar crash?
```

No.

Does:

```text
Footer crash?
```

No.

Only:

```text
Protected subtree
```

fails.

---

# This Is Fault Isolation

Example:

```text
Ship

├── Engine Room
├── Crew Quarters
└── Cargo Hold
```

If:

```text
Cargo floods
```

the entire ship doesn't sink.

Software works similarly.

---

# State 4 — Suspense

We've already been using Suspense.

We just didn't know it.

Remember:

```text
loading.tsx
```

This is actually:

```tsx
<Suspense>
```

behind the scenes.

---

# What Is Suspense?

Most beginners think:

```text
Wait
```

React thinks:

```text
Render Everything
        │
        ▼
Pause Missing Parts
        │
        ▼
Continue Later
```

Diagram:

```text
Page

   │

   ├── Ready
   │
   ├── Waiting
   │
   └── Ready
```

---

# Traditional Rendering

Old websites:

```text
Wait
   ↓
Wait
   ↓
Wait
   ↓
Render
```

Diagram:

```text
Data A
Data B
Data C

      │

      ▼

Render
```

---

# Suspense Rendering

Modern React:

```text
Render A

Loading B

Render C

Render B Later
```

Diagram:

```text
A

Loading...

C

Later:
B
```

---

# Why Does This Matter?

Suppose:

```text
Article:
100ms

Comments:
5000ms
```

Traditional:

```text
Wait 5 seconds.
```

Suspense:

```text
Show article immediately.

Load comments later.
```

This dramatically improves:

```text
Perceived Performance
```

---

# Reliability Engineering

Most beginners optimize:

```text
Success Case
```

Professional engineers optimize:

```text
Failure Case
```

Questions include:

```text
What if the API fails?

What if the network fails?

What if the user refreshes?

What if the database crashes?

What if the content is missing?
```

---

# The Hidden Architecture

When a user requests:

```text
/posts/react
```

The real execution path is:

```text
Request
    │
    ▼

Loading State
    │
    ▼

Fetch Data
    │
    ├── Success
    │       │
    │       ▼
    │     Render
    │
    ├── Missing
    │       │
    │       ▼
    │      404
    │
    └── Error
            │
            ▼
      Error Boundary
```

---

# Wait...

Does This Look Familiar?

We've already seen:

```text
React Trees

Route Trees

Layout Trees

Portable Text Trees
```

Now we have:

```text
Failure Trees
```

because software systems must model:

```text
Success
and
Failure
```

simultaneously.

---

# Mental Model To Remember Forever

Beginners think:

```text
Software
       =
Happy Path
```

Professional engineers think:

```text
Software
       =
Managing
       Uncertainty
```

Or more generally:

```text
Reliability
          =
Planning
          For
          Reality
```

The most important code you write is often the code that executes when everything goes wrong.

---

# Up Next

In **Part 19**, we'll implement draft mode and live preview while learning:

* how content staging systems work,
* published versus draft content,
* cache invalidation,
* real-time subscriptions,
* eventual consistency,
* and why modern systems are fundamentally about managing multiple versions of reality simultaneously.
