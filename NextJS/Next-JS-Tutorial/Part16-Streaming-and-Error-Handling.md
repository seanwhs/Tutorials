# Next.js 16 for Absolute Beginners

# Part 16 — Loading UI, Error Handling, and Streaming: Making Applications Feel Fast and Reliable

> **Goal of this lesson:** Learn how Next.js 16 handles loading states, errors, missing pages, and streaming UI so your applications feel fast, responsive, and professional.

---

# Users Don't Care How Fast Your Server Is

This sounds strange.

Suppose:

```text
Server Response Time:
1000 ms
```

versus:

```text
Server Response Time:
300 ms
```

Which feels faster?

Surprisingly:

```text
The one that provides feedback immediately.
```

Users care about:

* responsiveness
* feedback
* progress
* predictability

More than raw speed.

---

# The Three Things Every Application Must Handle

Every page eventually encounters:

```text
Loading
Success
Failure
```

---

# Visualizing Application States

```text
Request
    |
    +--- Loading
    |
    +--- Success
    |
    +--- Error
```

Professional applications handle all three.

---

# Loading States in Traditional React

Before Suspense:

```tsx
"use client";

export default function Page() {

    const [loading, setLoading] =
        useState(true);

    const [data, setData] =
        useState([]);

    useEffect(() => {

        fetch("/api/posts")
            .then(r => r.json())
            .then(data => {

                setData(data);
                setLoading(false);

            });

    }, []);

    if (loading) {

        return <p>Loading...</p>;

    }

    return (
        <div>
            {data.length}
        </div>
    );
}
```

Problems:

* lots of state
* lots of effects
* boilerplate
* poor user experience

---

# The Next.js Way

Create:

```text
app/posts/loading.tsx
```

---

```tsx
export default function Loading() {

    return (

        <h1>
            Loading posts...
        </h1>

    );

}
```

That's it.

---

# Visualizing loading.tsx

```text
Request
    |
    V

Show loading.tsx
    |
    V

Page finishes
    |
    V

Replace loading UI
```

---

# Example

Structure:

```text
app/

    posts/

        page.tsx
        loading.tsx
```

---

## page.tsx

```tsx
export default async function Page() {

    await new Promise(
        resolve =>
            setTimeout(
                resolve,
                3000
            )
    );

    return (
        <h1>
            Posts
        </h1>
    );

}
```

---

## loading.tsx

```tsx
export default function Loading() {

    return (
        <p>
            Loading...
        </p>
    );

}
```

---

# What Happens?

```text
Navigate
     |
loading.tsx
     |
Wait
     |
Page appears
```

No state management required.

---

# Skeleton Screens

Professional apps rarely use:

```text
Loading...
```

Instead:

```text
████████
████████
████████
```

called:

# Skeleton Loading

---

# Example

```tsx
export default function Loading() {

    return (

        <div>

            <div className="h-10 w-64" />

            <div className="h-6 w-full" />

            <div className="h-6 w-full" />

            <div className="h-6 w-full" />

        </div>

    );

}
```

---

# Visualizing Skeletons

Instead of:

```text
Loading...
```

Show:

```text
████████████

████████████

████████████
```

This feels dramatically faster.

---

# Error Handling

Eventually:

```text
Database fails
API fails
User input fails
Network fails
```

Failures are normal.

---

# The Old Way

```tsx
try {

    await fetch();

} catch {

    return (
        <Error />
    );

}
```

This becomes repetitive.

---

# Next.js Error Boundaries

Create:

```text
app/posts/error.tsx
```

---

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

        <div>

            <h2>
                Something failed
            </h2>

            <button
                onClick={() =>
                    reset()
                }
            >
                Retry
            </button>

        </div>

    );

}
```

---

# Visualizing error.tsx

```text
Page
   |
Throws Error
   |
error.tsx
   |
Retry
```

---

# Example Failure

```tsx
export default async function Page() {

    throw new Error(
        "Database failed"
    );

}
```

Instead of:

```text
Application Crash
```

users see:

```text
Friendly Error Screen
```

---

# What Does reset() Do?

Suppose:

```text
Database offline
```

Later:

```text
Database restored
```

User clicks:

```text
Retry
```

Next.js rerenders everything.

---

# Visualizing Retry

```text
Error
   |
User clicks Retry
   |
Render Again
   |
Success
```

---

# not-found.tsx

Sometimes pages don't exist.

Examples:

```text
/blog/999999
/product/abc
/user/404
```

---

Create:

```text
app/not-found.tsx
```

---

```tsx
export default function NotFound() {

    return (

        <div>

            <h1>
                Not Found
            </h1>

        </div>

    );

}
```

---

# Triggering 404

Import:

```tsx
import {
    notFound
} from
    "next/navigation";
```

---

Example:

```tsx
if (!post) {

    notFound();

}
```

---

# Visualizing notFound()

```text
Find Record
      |
      +--- Found
      |
      +--- Missing
               |
               V
            notFound()
```

---

# React Suspense

Suspense is one of the most important ideas in modern React.

Instead of:

```text
Wait for everything
```

React allows:

```text
Show parts immediately
```

---

# Traditional Rendering

```text
Header
Sidebar
Content
Comments
```

All wait:

```text
██████████
```

---

# Suspense Rendering

```text
Header
    ✓

Sidebar
    ✓

Content
    loading...

Comments
    loading...
```

---

# Example

```tsx
import {
    Suspense
} from "react";
```

---

```tsx
<Suspense
    fallback={
        <p>
            Loading...
        </p>
    }
>

    <Comments />

</Suspense>
```

---

# Visualizing Suspense

```text
Page
   |
   +--- Header
   |
   +--- Sidebar
   |
   +--- Suspense Boundary
               |
               +--- Loading
               +--- Content
```

---

# Streaming

Suspense enables:

# Streaming

---

# Traditional Server Rendering

```text
Server
    |
Generate Entire Page
    |
Send Entire Page
```

---

# Streaming Rendering

```text
Server
    |
Header Ready
    |
Send Header
    |
Sidebar Ready
    |
Send Sidebar
    |
Comments Ready
    |
Send Comments
```

---

# Visualizing Streaming

```text
Time

Header
    ✓

Sidebar
    ✓

Content
        ✓

Comments
            ✓
```

Users see progress immediately.

---

# Example

```tsx
export default function Page() {

    return (

        <div>

            <Header />

            <Suspense
                fallback={
                    <Loading />
                }
            >

                <Posts />

            </Suspense>

        </div>

    );

}
```

---

# Nested Suspense

You can stream multiple sections.

```tsx
<Suspense
    fallback={<PostsLoading />}
>
    <Posts />
</Suspense>

<Suspense
    fallback={<UsersLoading />}
>
    <Users />
</Suspense>
```

---

# Visualizing Nested Streaming

```text
Page
   |
   +--- Posts
   |
   +--- Users
   |
   +--- Comments
```

Each streams independently.

---

# Parallel Routes + Streaming

Modern applications often load:

```text
Dashboard
    |
    +--- Analytics
    +--- Notifications
    +--- Activity
```

Each panel streams separately.

---

# Error Boundaries + Suspense

Example:

```tsx
<ErrorBoundary>

    <Suspense>

        <Comments />

    </Suspense>

</ErrorBoundary>
```

Visualized:

```text
Component
      |
      +--- Success
      |
      +--- Loading
      |
      +--- Error
```

---

# Route Groups

Example:

```text
app/

    (marketing)/

    (dashboard)/
```

Each can have:

```text
loading.tsx
error.tsx
not-found.tsx
```

independently.

---

# Combining Everything

Suppose:

```text
Dashboard
```

contains:

```text
Header
Analytics
Users
Posts
Comments
```

Architecture:

```text
Dashboard
      |
      +--- Suspense
      |
      +--- Error
      |
      +--- Loading
      |
      +--- Streaming
```

---

# Professional Folder Structure

```text
app/

    dashboard/

        page.tsx

        loading.tsx

        error.tsx

        not-found.tsx
```

---

# The Professional Rule

Never show:

```text
Blank Screen
```

Always show:

```text
Progress
```

---

# Production Checklist

Every route should consider:

```text
✓ Loading state
✓ Error state
✓ Empty state
✓ Missing state
✓ Retry state
✓ Streaming state
```

---

# Example Empty State

```tsx
if (!posts.length) {

    return (

        <div>

            No posts found

        </div>

    );

}
```

---

# Visualizing UI States

```text
Loading
    ↓
Success
    ↓
Empty
    ↓
Error
    ↓
Retry
```

---

# Exercises

## Exercise 1

Create:

```text
loading.tsx
```

for:

```text
/blog
```

---

## Exercise 2

Create:

```text
error.tsx
```

with:

```text
Retry button
```

---

## Exercise 3

Create:

```text
not-found.tsx
```

for:

```text
/blog/[slug]
```

---

## Exercise 4

Wrap:

```tsx
<Comments />
```

inside:

```tsx
<Suspense>
```

---

# What You've Learned

You now understand:

✅ loading.tsx

✅ error.tsx

✅ not-found.tsx

✅ React Suspense

✅ streaming

✅ skeleton screens

✅ retries

✅ graceful failures

✅ production resilience

---

# Mental Model

Don't think:

```text
Render Page
```

Think:

```text
Render Progressively
        |
        +--- Loading
        |
        +--- Success
        |
        +--- Error
        |
        +--- Retry
```

The best applications don't avoid failures.

They recover from failures gracefully.

---

# Part 17 Preview

In the next chapter we'll learn:

# Routing Deep Dive

Including:

* App Router internals
* nested layouts
* route groups
* dynamic routes
* catch-all routes
* parallel routes
* intercepting routes
* route handlers
* building complex application navigation

This is where we'll fully understand why the App Router is one of the most powerful features of Next.js 16.
