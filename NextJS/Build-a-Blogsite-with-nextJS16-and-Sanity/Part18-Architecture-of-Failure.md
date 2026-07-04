# GreyMatter Journal

# Part 18 — Loading States, Error Boundaries, Suspense, and the Architecture of Failure

## Why Reliable Software Is Built Around Uncertainty

> **Goal of this lesson:** Build professional loading states, error handling, recovery mechanisms, and develop one of the most important engineering mindsets: robust systems are designed around uncertainty rather than success.

---

# So Far, Everything Has Worked

Up to this point, our application appears wonderfully simple.

```text
User Request
      ↓
Database Query
      ↓
Data Returned
      ↓
Render UI
      ↓
Success
```

This creates a dangerous illusion:

> Software is mostly about making things work.

Unfortunately, real software rarely behaves this way.

In reality:

```text
Network latency increases

Database connections fail

APIs timeout

Servers restart

Caches become stale

Users disconnect

Content disappears

Developers introduce bugs
```

Professional software engineering begins when we stop asking:

> How do I make this work?

and start asking:

> What happens when it doesn't?

---

# Software Is Mostly Waiting

One of the deepest truths in computing is:

```text
Programs spend very little time computing.

Programs spend most of their time waiting.
```

Waiting for:

```text
Disk

Network

Database

API

Cache

User

Browser
```

For example:

```text
Request Article
        ↓

Wait for DNS
        ↓

Wait for network
        ↓

Wait for server
        ↓

Wait for database
        ↓

Wait for rendering
        ↓

Display result
```

Modern web applications are fundamentally systems that manage waiting.

---

# Every Feature Has Four States

Regardless of technology stack, every feature eventually exists in one of four states:

```text
Loading

Success

Not Found

Failure
```

Consider opening a blog post:

```text
Request Post
        ↓

Is it loading?
        ↓

Did it succeed?
        ↓

Does it exist?
        ↓

Did something fail?
```

Professional applications explicitly design for all four.

---

# The Old React Approach

Historically, React developers managed these states manually.

```tsx
function PostPage() {
  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState(null);

  const [post, setPost] =
    useState(null);

  useEffect(() => {
    fetchPost();
  }, []);
}
```

This quickly became:

```text
Loading logic
      +
Error logic
      +
Retry logic
      +
Empty state logic
      +
Success logic
      +
Cleanup logic
```

The complexity exploded.

---

# The Next.js Philosophy

The App Router moves uncertainty into architecture itself.

Instead of:

```text
Component
      +
Flags
      +
Conditionals
```

we create:

```text
loading.tsx

page.tsx

not-found.tsx

error.tsx
```

Each file represents a different reality.

---

# Understanding the Four Realities

Think of every page as existing in a state machine:

```text
                 Loading
                     |
                     v

              Data Retrieved?
               /         \
             yes          no
             /              \
            v                v

       Success         Error

            |
            v

      Resource Exists?
           /     \
         yes      no
         /          \
        v            v

   Render UI     Not Found
```

The App Router transforms these realities into first-class architectural concepts.

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

Next.js automatically renders this component while:

```text
Server Component
        ↓
Fetching Data
        ↓
Waiting
```

No additional code is required.

---

# Why Skeleton Screens Feel Faster

Suppose our page requires:

```text
800 ms
```

to load.

A spinner displays:

```text
Loading...
```

The user perceives:

```text
Nothing exists.
```

A skeleton displays:

```text
████████████

██████

████████████
```

The user perceives:

```text
The page already exists.
It is simply arriving.
```

The actual loading time is identical.

The perceived loading time changes dramatically.

This illustrates an important principle:

```text
Performance
      ≠
Speed

Performance
      =
Perception
```

---

# Success State

The success state is simply:

```text
page.tsx
```

For example:

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
Data Exists
       +
Rendering Succeeds
```

Success is merely one possible reality.

---

# Not Found Is Not Failure

Suppose a user visits:

```text
/posts/this-does-not-exist
```

Our query returns:

```typescript
null
```

This is not an error.

It is a legitimate outcome.

We handle it explicitly:

```tsx
import {
  notFound,
} from "next/navigation";

if (!post) {
  notFound();
}
```

Internally, Next.js throws a special exception:

```text
NEXT_NOT_FOUND
```

which automatically renders:

```text
not-found.tsx
```

---

# Creating a Not Found Experience

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
        The requested page
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

# Unexpected Failures

Some failures are not valid outcomes.

Examples include:

```text
Database unavailable

API timeout

Serialization failure

Programming bug

Unexpected exception
```

For these cases, Next.js provides:

```text
error.tsx
```

---

# Creating an Error Boundary

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

# Why Must `error.tsx` Be A Client Component?

Notice:

```tsx
"use client";
```

This is required because:

```tsx
<button onClick={reset}>
```

contains:

```text
User Interaction
```

Server Components cannot:

```text
Handle events

Maintain browser state

Perform client-side recovery
```

Error recovery is fundamentally an interactive operation.

---

# Failure Isolation

One of React's deepest architectural ideas is:

> Failure should remain local.

Without boundaries:

```text
Article crashes
       ↓
Entire application crashes
```

With boundaries:

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

Only the article page fails.

Everything else survives.

This principle is called:

```text
Failure Isolation
```

---

# Suspense: Making Waiting A First-Class Concept

Underneath `loading.tsx` lies one of React's most important innovations:

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

> If this component cannot render yet, render something else temporarily.

This transforms waiting from:

```text
Problem
```

into:

```text
Supported State
```

---

# Reliability Engineering

Traditional programming assumes:

```text
Success
```

Reliability engineering assumes:

```text
Failure
```

Instead of asking:

> How do I make this work?

we ask:

> How do I make this fail safely?

Examples:

```text
Network failure

Database failure

Cache failure

API failure

Developer failure

User failure
```

Professional systems expect all of them.

---

# The Architecture Of Failure

The App Router creates a layered reliability model:

```text
loading.tsx
       ↓
page.tsx
       ↓
not-found.tsx
       ↓
error.tsx
```

More abstractly:

```text
Waiting

Success

Absence

Failure

Recovery
```

This is not merely UI architecture.

It is reliability architecture.

---

# The Deep Idea

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

Reliability engineers think:

```text
Software
       =
Managing Uncertainty
```

Or even more fundamentally:

```text
Computing
      =
Transforming Uncertainty
      Into Predictable Behavior
```

---

# Mental Model To Remember Forever

Traditional thinking:

```text
Application
       =
Features
```

Professional engineering thinking:

```text
Application
       =
Features
       +
Failure Handling
```

Reliability engineering thinking:

```text
Reliable Systems
          =
Graceful Failure
          +
Recovery
          +
Isolation
```

The true measure of a system is not how it behaves when everything works.

It is how it behaves when everything doesn't.

---

# Up Next — Part 19: Draft Mode, Preview, and Parallel Realities

Next we'll explore:

* Draft Mode
* Preview Cookies
* Live Preview
* Published vs Draft Content
* Real-time Editing
* Content Versioning

And discover one of the strangest ideas in modern publishing systems:

> Two different users can look at the same URL and see two different realities.
