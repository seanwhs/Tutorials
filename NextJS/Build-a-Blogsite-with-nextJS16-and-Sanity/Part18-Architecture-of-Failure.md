# **✅ Part 18 — Loading States, Error Boundaries, and the Architecture of Failure**

# GreyMatter Journal

## Part 18 — Loading States, Error Boundaries, Suspense, and Reliability Engineering

> **Goal of this lesson:** Build professional loading states, error handling, and recovery mechanisms while learning one of the deepest truths in software engineering: robust systems are designed around uncertainty.

---

# Software Is Mostly Waiting

So far, our application appears to work perfectly.

```text
Request
     ↓
Database
     ↓
Render
     ↓
Success
```

Unfortunately, this is not how real software behaves.

In reality:

```text
Network is slow

Database is unavailable

API returns invalid data

Content doesn't exist

Servers timeout

Users disconnect
```

Modern applications are fundamentally systems that manage uncertainty.

---

# The Four States of Every Feature

Every feature in every application eventually exists in one of four states:

```text
Loading

Success

Error

Not Found
```

Consider opening an article:

```text
Request Article
       ↓

Loading?
       ↓

Success?
       ↓

Error?
       ↓

Not Found?
```

Professional software handles all four.

---

# The Old Approach

Historically, React applications looked like this:

```tsx
function PostPage() {
  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState(null);

  const [post, setPost] =
    useState(null);

  useEffect(() => {
    ...
  }, []);
}
```

Developers manually managed:

* loading
* errors
* retries
* empty states
* recovery

This produced enormous complexity.

---

# The Next.js Approach

Next.js App Router moves these concerns into architecture.

Instead of:

```text
Logic
      +
Flags
      +
Conditionals
```

we create:

```text
loading.tsx

error.tsx

not-found.tsx

page.tsx
```

Each file represents a different reality.

---

# Loading States

Create:

```text
app/(site)/posts/[slug]/loading.tsx
```

```tsx
export default function Loading() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-12 animate-pulse">

      <div className="mb-8 h-12 w-3/4 rounded bg-gray-200" />

      <div className="mb-12 h-4 w-1/2 rounded bg-gray-200" />

      <div className="space-y-4">

        <div className="h-4 rounded bg-gray-200" />

        <div className="h-4 rounded bg-gray-200" />

        <div className="h-4 w-5/6 rounded bg-gray-200" />

        <div className="h-4 w-4/6 rounded bg-gray-200" />

      </div>

    </div>
  );
}
```

Next.js automatically displays this component while:

```text
Server Component
        ↓
Fetching Data
```

---

# Why Skeletons Feel Faster

Suppose loading takes:

```text
800 ms
```

Two approaches exist.

### Spinner

```text
Loading...
```

The user sees:

```text
Nothing exists.
```

### Skeleton

```text
██████████

██████

██████████
```

The user sees:

```text
The page is arriving.
```

The actual loading time is identical.

The perceived loading time is shorter.

---

# Success State

Our success state is simply:

```text
page.tsx
```

Example:

```tsx
export default async function PostPage() {
  const post =
    await client.fetch(...);

  return (
    <article>
      ...
    </article>
  );
}
```

This represents:

```text
Data exists
        +
Rendering succeeds
```

---

# Not Found State

Sometimes the requested resource does not exist.

Example:

```text
/posts/this-post-does-not-exist
```

This is not an error.

It is a valid outcome.

Inside:

```tsx
import { notFound }
  from "next/navigation";

if (!post) {
  notFound();
}
```

Next.js throws a special exception internally:

```text
RESOURCE_NOT_FOUND
```

which renders:

```text
not-found.tsx
```

---

# Create a Global Not Found Page

Create:

```text
app/not-found.tsx
```

```tsx
import Link from "next/link";

export default function NotFound() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-24 text-center">

      <h1 className="mb-6 text-6xl font-bold">
        404
      </h1>

      <p className="mb-8 text-gray-600">
        The page you requested
        could not be found.
      </p>

      <Link
        href="/"
        className="
          rounded-lg
          bg-black
          px-6
          py-3
          text-white
        "
      >
        Return Home
      </Link>

    </div>
  );
}
```

---

# Error Boundaries

Some failures are unexpected.

Examples:

```text
Database unavailable

API timeout

Parsing failure

Programming bug
```

For these situations, Next.js provides:

```text
error.tsx
```

Create:

```text
app/(site)/posts/[slug]/error.tsx
```

```tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error;

  reset: () => void;
}) {
  return (
    <div className="mx-auto max-w-md py-20 text-center">

      <h2 className="mb-4 text-3xl font-bold">
        Something went wrong
      </h2>

      <p className="mb-8 text-gray-600">
        {error.message}
      </p>

      <button
        onClick={reset}
        className="
          rounded-lg
          bg-black
          px-6
          py-3
          text-white
        "
      >
        Try Again
      </button>

    </div>
  );
}
```

---

# Why Is `error.tsx` a Client Component?

You may notice:

```tsx
"use client";
```

This is required because:

```tsx
<button
  onClick={reset}
>
```

contains:

```text
User Interaction
```

Server Components cannot:

* handle clicks
* maintain local state
* perform browser interactions

Error boundaries must execute in the browser.

---

# Failure Isolation

One of the deepest ideas in React and Next.js is:

```text
Failure should remain local.
```

Without error boundaries:

```text
Page crashes
       ↓
Entire application crashes
```

With boundaries:

```text
Page crashes
       ↓
Only page crashes
       ↓
Rest of application survives
```

Visually:

```text
Root Layout
       ↓
Site Layout
       ↓
Posts Layout
       ↓
Article Page
            X
```

Everything above remains functional.

---

# Suspense

Underneath loading.tsx exists one of React's most important ideas:

```text
Suspense
```

Conceptually:

```tsx
<Suspense
  fallback={<Loading />}
>
  <PostPage />
</Suspense>
```

means:

> If this component cannot render yet, show something else temporarily.

This allows React to treat:

```text
Waiting
```

as a first-class concept.

---

# Reliability Engineering

Traditional programming often assumes:

```text
Success
```

Reliability engineering assumes:

```text
Failure
```

The question changes from:

> How do I make this work?

to:

> How do I make this fail safely?

Examples:

```text
Network fails

Database fails

API fails

Cache fails

User fails

Developer fails
```

Robust systems expect all of these.

---

# The Architecture of Failure

Modern applications are built around layered failure handling:

```text
loading.tsx
        ↓
page.tsx
        ↓
not-found.tsx
        ↓
error.tsx
```

More broadly:

```text
Loading

Success

Not Found

Failure

Recovery
```

This is not merely UI.

This is reliability architecture.

---

# Mental Model To Remember Forever

Beginners think:

```text
Software
       =
Success Path
```

Professional engineers think:

```text
Software
       =
Success Path
       +
Failure Paths
```

More fundamentally:

```text
Reliable Software
          =
Managing Uncertainty
```

The most important feature of a system is often not how it behaves when everything works.

It is how it behaves when everything doesn't.

---

# Up Next — Part 19: Draft Mode and Live Preview

We'll implement:

* Draft Mode
* Live Preview
* Preview Cookies
* Published vs Draft Content
* Real-time Content Workflows

and discover how modern publishing systems separate editing reality from production reality.
