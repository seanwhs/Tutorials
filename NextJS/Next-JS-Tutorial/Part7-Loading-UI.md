# Next.js 16 for Absolute Beginners

# Part 7 — Loading UI, Error UI, Streaming, and Suspense

> **Goal of this lesson:** Learn how Next.js handles loading states, errors, missing pages, and streaming content to users before all data has finished loading.

---

# The Problem With Waiting

Suppose your page fetches data from an API.

```tsx
export default async function Page() {
    const response = await fetch(
        "https://jsonplaceholder.typicode.com/posts"
    );

    const posts = await response.json();

    return (
        <div>
            {posts.map(post => (
                <h2 key={post.id}>
                    {post.title}
                </h2>
            ))}
        </div>
    );
}
```

This works.

But what if the API takes 5 seconds?

```text
User requests page
        ↓
Server waits 5 seconds
        ↓
Server sends page
        ↓
User sees content
```

For 5 seconds the user sees nothing.

---

# Traditional React Solution

Traditionally we'd do:

```jsx
"use client";

function Page() {
    const [loading, setLoading] =
        useState(true);

    const [posts, setPosts] =
        useState([]);

    useEffect(() => {
        fetch("/api/posts")
            .then(r => r.json())
            .then(data => {
                setPosts(data);
                setLoading(false);
            });
    }, []);

    if (loading) {
        return <p>Loading...</p>;
    }

    return <Posts />;
}
```

This works, but creates a lot of boilerplate.

---

# Next.js Introduces Loading UI

Instead of writing loading logic inside components, create:

```text
app/
    posts/
        page.tsx
        loading.tsx
```

---

# Creating Our First Loading Screen

## app/posts/loading.tsx

```tsx
export default function Loading() {
    return (
        <div>

            <h1>
                Loading Posts...
            </h1>

            <p>
                Please wait...
            </p>

        </div>
    );
}
```

---

## app/posts/page.tsx

```tsx
export default async function PostsPage() {

    await new Promise(
        resolve =>
            setTimeout(resolve, 5000)
    );

    return (
        <main>

            <h1>
                Posts Loaded
            </h1>

        </main>
    );
}
```

Visit:

```text
/posts
```

You'll see:

```text
Loading Posts...
```

followed by:

```text
Posts Loaded
```

---

# How Does This Work?

Next.js automatically detects:

```text
loading.tsx
```

and creates a loading boundary.

Internally:

```text
Request Page
      ↓
Show loading.tsx
      ↓
Wait for page.tsx
      ↓
Replace loading UI
```

---

# Visualizing Loading UI

```text
User
  |
Request
  |
  V

loading.tsx

  |
wait
  |
  V

page.tsx
```

---

# Nested Loading UI

Suppose:

```text
dashboard/

    loading.tsx

    page.tsx

    users/
        loading.tsx
        page.tsx
```

Visiting:

```text
/dashboard/users
```

uses:

```text
Users Loading
```

instead of:

```text
Dashboard Loading
```

The closest loading boundary wins.

---

# Building Skeleton Screens

Instead of:

```tsx
Loading...
```

we usually build skeleton UIs.

Example:

```tsx
export default function Loading() {
    return (
        <div>

            <div>
                ███████████████
            </div>

            <div>
                ███████████
            </div>

            <div>
                ████████████████
            </div>

        </div>
    );
}
```

Or with Tailwind:

```tsx
export default function Loading() {
    return (
        <div className="space-y-4">

            <div className="h-6 bg-gray-200 rounded" />

            <div className="h-6 bg-gray-200 rounded" />

            <div className="h-6 bg-gray-200 rounded" />

        </div>
    );
}
```

---

# What Happens When Something Breaks?

Suppose:

```tsx
export default async function Page() {

    throw new Error(
        "Database exploded"
    );

}
```

Without handling, users would see a crash.

---

# Error Boundaries

Create:

```text
app/
    posts/
        error.tsx
```

---

## error.tsx

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

            <h1>
                Something went wrong
            </h1>

            <p>
                {error.message}
            </p>

            <button
                onClick={() => reset()}
            >
                Try Again
            </button>

        </div>
    );
}
```

---

# Why Does error.tsx Need "use client"?

Because:

```tsx
<button
    onClick={reset}
/>
```

requires browser interaction.

Remember:

```text
Events
    ↓
Browser
    ↓
Client Component
```

---

# Visualizing Error Boundaries

```text
page.tsx
      |
      |
throws Error
      |
      V
error.tsx
```

---

# Resetting Errors

Suppose the API server comes back online.

The user clicks:

```text
Try Again
```

Next.js reruns:

```text
page.tsx
```

without refreshing the browser.

---

# Handling Missing Pages

Suppose:

```text
/blog/react
```

exists.

But:

```text
/blog/unknown-post
```

does not.

---

# notFound()

Next.js provides:

```tsx
import { notFound }
    from "next/navigation";
```

Example:

```tsx
import { notFound }
    from "next/navigation";

export default async function BlogPost() {

    const post = null;

    if (!post) {
        notFound();
    }

    return (
        <article>
            Hello
        </article>
    );
}
```

---

# Creating a Custom 404

Create:

```text
app/not-found.tsx
```

```tsx
export default function NotFound() {
    return (
        <div>

            <h1>
                404
            </h1>

            <p>
                Page not found
            </p>

        </div>
    );
}
```

---

# What Is Streaming?

This is one of the biggest features of modern React.

Suppose we need:

* user profile
* analytics
* notifications

Traditional rendering:

```text
Wait for everything
        ↓
Render everything
```

Example:

```text
1 sec
+
3 sec
+
5 sec
=
9 sec
```

User waits:

```text
9 seconds
```

---

# Streaming Rendering

Instead:

```text
Render completed parts
immediately
```

Example:

```text
Profile -------+
               |
Analytics -----+--> stream
               |
Notifications -+
```

---

# Visualizing Streaming

Traditional:

```text
Wait
Wait
Wait
Render
```

Streaming:

```text
Render
Render
Render
Render
```

---

# React Suspense

React provides:

```tsx
<Suspense>
```

Example:

```tsx
import { Suspense }
    from "react";

export default function Dashboard() {

    return (
        <main>

            <h1>
                Dashboard
            </h1>

            <Suspense
                fallback={
                    <p>
                        Loading users...
                    </p>
                }
            >
                <Users />
            </Suspense>

        </main>
    );
}
```

---

# Async Child Components

Example:

```tsx
async function Users() {

    await new Promise(
        r => setTimeout(r, 3000)
    );

    return (
        <div>
            Users loaded
        </div>
    );
}
```

Result:

```text
Dashboard

Loading users...

Users loaded
```

---

# Multiple Suspense Boundaries

```tsx
export default function Dashboard() {

    return (
        <main>

            <Suspense
                fallback={<p>Users...</p>}
            >
                <Users />
            </Suspense>

            <Suspense
                fallback={<p>Posts...</p>}
            >
                <Posts />
            </Suspense>

            <Suspense
                fallback={<p>Comments...</p>}
            >
                <Comments />
            </Suspense>

        </main>
    );
}
```

---

# Visualizing Suspense

```text
Dashboard

Users ............ loaded

Posts ............ loading

Comments ......... loaded
```

Each section loads independently.

---

# Why This Is Revolutionary

Old React:

```text
One giant page
       ↓
One giant wait
```

Modern React:

```text
Many components
       ↓
Many streams
```

This is why websites built with modern Next.js feel significantly faster.

---

# Building a Real Example

Create:

```text
app/dashboard/page.tsx
```

```tsx
import { Suspense }
    from "react";

async function Statistics() {

    await new Promise(
        r => setTimeout(r, 3000)
    );

    return (
        <div>
            Statistics Loaded
        </div>
    );
}

async function News() {

    await new Promise(
        r => setTimeout(r, 5000)
    );

    return (
        <div>
            News Loaded
        </div>
    );
}

export default function Dashboard() {

    return (
        <main>

            <h1>
                Dashboard
            </h1>

            <Suspense
                fallback={
                    <p>
                        Loading statistics...
                    </p>
                }
            >
                <Statistics />
            </Suspense>

            <Suspense
                fallback={
                    <p>
                        Loading news...
                    </p>
                }
            >
                <News />
            </Suspense>

        </main>
    );
}
```

Notice how content appears progressively.

---

# Mental Model

Think of modern Next.js rendering as:

```text
Page
   |
   +-- Section A
   |
   +-- Section B
   |
   +-- Section C
```

instead of:

```text
Page
   |
Everything
or
Nothing
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

that displays:

```text
Something failed
Try Again
```

---

## Exercise 3

Build:

```text
Dashboard
```

with three Suspense boundaries:

* users
* posts
* comments

each with different delays.

---

# What You've Learned

You now understand:

✅ `loading.tsx`

✅ `error.tsx`

✅ `not-found.tsx`

✅ `notFound()`

✅ Suspense

✅ streaming

✅ fallback UI

✅ progressive rendering

---

# New Mental Model

Forget:

```text
Wait
for
everything
```

Think:

```text
Render
what
you
have
now
```

This is the foundation that enables many of the advanced rendering and caching capabilities introduced in Next.js 16.

---

# Part 8 Preview

In the next chapter, we'll learn:

# Components and Composition

Including:

* reusable components
* props
* children
* composition
* component trees
* server component composition
* client component composition
* component architecture

This is where we'll begin building applications that scale beyond a few pages.
