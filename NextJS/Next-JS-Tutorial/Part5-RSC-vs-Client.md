# Next.js 16 for Absolute Beginners

# Part 5 — React Server Components vs Client Components: The Biggest Idea in Modern Next.js

> **Goal of this lesson:** Understand the most important architectural concept in Next.js 16: why some components run on the server and some run in the browser.

---

# This Is the Chapter That Changes Everything

If you've used React before, you've probably written code like this:

```jsx
import { useEffect, useState } from "react";

export default function Posts() {
    const [posts, setPosts] = useState([]);

    useEffect(() => {
        fetch("/api/posts")
            .then(response => response.json())
            .then(setPosts);
    }, []);

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

For years, this was considered normal React.

But modern Next.js asks a different question:

> **Why is the browser fetching data at all?**

This simple question led to one of the biggest changes in React history:

# React Server Components (RSC)

---

# Traditional React Architecture

Traditional React applications look like this:

```text
Browser
    |
Download JS
    |
Execute JS
    |
Fetch API
    |
Wait
    |
Render UI
```

Example:

```jsx
function UserProfile() {
    const [user, setUser] = useState(null);

    useEffect(() => {
        fetch("/api/user")
            .then(r => r.json())
            .then(setUser);
    }, []);

    if (!user)
        return <p>Loading...</p>;

    return (
        <h1>
            {user.name}
        </h1>
    );
}
```

Problems:

* browser downloads JavaScript
* browser executes JavaScript
* browser makes API calls
* browser waits for data
* browser renders UI

This creates a lot of unnecessary work.

---

# The React Team Asked

Suppose the server already knows the data.

Why do this?

```text
Server
   ↓
Send JavaScript
   ↓
Browser
   ↓
Fetch Data Again
   ↓
Render
```

Instead, why not do this?

```text
Server
   ↓
Fetch Data
   ↓
Render UI
   ↓
Send Result
```

This idea became:

# React Server Components

---

# The Two Types of Components

Modern React now has two kinds of components.

```text
React Components
        |
        |
   +----+----+
   |         |
Server    Client
```

---

# Server Components

Server Components execute on the server.

Example:

```tsx
export default async function HomePage() {

    const response =
        await fetch(
            "https://jsonplaceholder.typicode.com/posts"
        );

    const posts =
        await response.json();

    return (
        <main>

            {posts
                .slice(0, 5)
                .map(post => (
                    <h2 key={post.id}>
                        {post.title}
                    </h2>
            ))}

        </main>
    );
}
```

Notice:

* no `useEffect`
* no `useState`
* no loading spinner
* no browser fetch

The server does all the work.

---

# Client Components

Client Components execute in the browser.

Example:

```tsx
"use client";

import { useState } from "react";

export default function Counter() {

    const [count, setCount] =
        useState(0);

    return (
        <button
            onClick={() =>
                setCount(count + 1)
            }
        >
            {count}
        </button>
    );
}
```

Client Components are necessary when we need:

* user interaction
* browser APIs
* state
* effects
* event handlers

---

# The Biggest Mistake Beginners Make

Many beginners assume:

```text
Next.js
     =
Everything runs
in the browser
```

This is wrong.

In modern Next.js:

```text
Everything runs
on the server

UNLESS

you explicitly say:

"use client"
```

---

# Visualizing Execution

## Server Component

```text
Browser
    |
Request Page
    |
    V
Next.js Server
    |
Fetch Data
    |
Create HTML
    |
Send Result
    |
Browser Displays
```

---

## Client Component

```text
Browser
    |
Download JS
    |
Execute JS
    |
React Runs
    |
Update UI
```

---

# Let's Build Our First Server Component

Create:

```text
app/posts/page.tsx
```

```tsx
export default async function PostsPage() {

    const response =
        await fetch(
            "https://jsonplaceholder.typicode.com/posts"
        );

    const posts =
        await response.json();

    return (
        <main>

            <h1>
                Posts
            </h1>

            {posts
                .slice(0,5)
                .map(post => (

                <article
                    key={post.id}
                >
                    <h2>
                        {post.title}
                    </h2>

                    <p>
                        {post.body}
                    </p>
                </article>

            ))}

        </main>
    );
}
```

---

# Wait. Where Is useEffect?

There isn't one.

That's the point.

Instead of:

```jsx
useEffect(() => {
    fetch(...)
}, []);
```

you simply write:

```tsx
const response =
    await fetch(...);
```

The server fetches first.

---

# What Actually Happens?

Suppose a user visits:

```text
/posts
```

Next.js does:

```text
1. User requests page

2. Server executes component

3. Server fetches API

4. Server builds UI

5. Browser receives result
```

The browser never fetches the data itself.

---

# Building Our First Client Component

Create:

```text
components/Counter.tsx
```

```tsx
"use client";

import { useState } from "react";

export default function Counter() {

    const [count, setCount] =
        useState(0);

    return (
        <div>

            <h2>
                Counter
            </h2>

            <button
                onClick={() =>
                    setCount(count + 1)
                }
            >
                Count:
                {count}
            </button>

        </div>
    );
}
```

---

Use it:

```tsx
import Counter
    from "@/components/Counter";

export default function HomePage() {

    return (
        <main>

            <h1>
                Home
            </h1>

            <Counter />

        </main>
    );
}
```

---

# Mixing Server and Client Components

This is the real superpower.

```text
Server Component
        |
        |
        +------ Client Component
        |
        +------ Client Component
        |
        +------ Client Component
```

Example:

```tsx
import Counter from
    "@/components/Counter";

export default async function Dashboard() {

    const response =
        await fetch(
            "https://jsonplaceholder.typicode.com/users"
        );

    const users =
        await response.json();

    return (
        <div>

            <h1>
                Dashboard
            </h1>

            <Counter />

            {users.map(user => (
                <p key={user.id}>
                    {user.name}
                </p>
            ))}

        </div>
    );
}
```

The page itself executes on the server.

Only the counter executes in the browser.

---

# What Happens If We Forget "use client"?

Suppose we write:

```tsx
import { useState }
    from "react";

export default function Counter() {

    const [count, setCount]
        = useState(0);

    return <div>{count}</div>;
}
```

Next.js throws:

```text
You're importing a component
that needs useState.

Mark it with:

"use client"
```

This error exists because:

```text
useState
     ↓
requires browser
     ↓
requires Client Component
```

---

# Server Components Cannot Use

```text
useState
useEffect
useReducer
useRef
window
document
localStorage
sessionStorage
event handlers
```

Examples:

```tsx
window.location
```

❌

---

```tsx
useEffect()
```

❌

---

```tsx
localStorage.getItem()
```

❌

---

# Client Components Can Use

```text
useState
useEffect
useReducer
useRef
window
document
events
browser APIs
```

Examples:

```tsx
useState()
```

✅

---

```tsx
window.location
```

✅

---

```tsx
onClick
```

✅

---

# Why Server Components Are Faster

Suppose we have:

```text
100 KB JS
```

Traditional React:

```text
Browser downloads
100 KB JS
```

Modern Next.js:

```text
Server executes component
Browser downloads
0 KB JS
```

The browser only downloads JavaScript for interactive components.

---

# Example

Traditional React:

```jsx
function Article() {
    return (
        <article>
            Hello World
        </article>
    );
}
```

Browser downloads JS.

---

Next.js Server Component:

```tsx
export default function Article() {
    return (
        <article>
            Hello World
        </article>
    );
}
```

Browser downloads no JavaScript at all.

---

# The Mental Model

Ask yourself:

### Does this component need interaction?

```text
NO
    ↓
Server Component
```

Examples:

* article
* blog post
* profile page
* product page
* dashboard data
* tables
* reports

---

### Does this component need browser features?

```text
YES
    ↓
Client Component
```

Examples:

* buttons
* forms
* modals
* dropdowns
* tabs
* counters
* animations

---

# Rule of Thumb

Start with:

```text
Server Component
```

Only add:

```tsx
"use client"
```

when absolutely necessary.

This is the exact opposite of traditional React.

---

# Exercises

## Exercise 1

Create a server component:

```text
/posts
```

that fetches:

```text
https://jsonplaceholder.typicode.com/users
```

---

## Exercise 2

Create a client component:

```tsx
LikeButton
```

with:

```text
👍 0
```

that increments when clicked.

---

## Exercise 3

Create:

```text
Dashboard Page
```

containing:

* server-fetched users
* client-side counter
* client-side theme switcher

---

# What You've Learned

You now understand:

✅ React Server Components

✅ Client Components

✅ `"use client"`

✅ server execution

✅ browser execution

✅ why `useEffect` is often unnecessary

✅ why modern Next.js is faster

✅ how server and client components work together

---

# New Mental Model

Forget this:

```text
React
    ↓
Browser
```

Think:

```text
Next.js
        |
        |
   +----+----+
   |         |
Server    Browser
```

Modern Next.js is not a frontend framework.

It is a **distributed execution environment** where React components can execute in different places.

---

# Part 6 Preview

In the next chapter we'll learn:

# Data Fetching in Next.js

Including:

* `fetch()`
* async components
* parallel fetching
* sequential fetching
* loading states
* error handling
* Suspense
* streaming
* why `useEffect` fetching is usually obsolete

This is where Next.js starts becoming truly magical.
