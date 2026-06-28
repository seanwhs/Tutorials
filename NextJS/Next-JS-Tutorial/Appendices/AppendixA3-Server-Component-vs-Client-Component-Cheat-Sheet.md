# Appendix A3 — Server Components vs Client Components Cheat Sheet

## The Complete Mental Model for React Server Components in Next.js 16

> **Purpose:** This appendix is the single most important reference for understanding modern React and Next.js. If you understand this appendix, you understand the foundation of Next.js 16.

---

# Introduction

The biggest mistake beginners make when learning Next.js 16 is believing:

```text
Server Components
=
SSR
```

This is incorrect.

---

# Traditional React

Before React Server Components, React worked like this:

```text
Browser
    |
Download JavaScript
    |
Execute JavaScript
    |
Render UI
```

---

# React Server Components

React Server Components work like this:

```text
Server
    |
Execute React
    |
Produce UI Tree
    |
Send Result
    |
Browser
```

---

# The Biggest Mental Shift

Old React:

```text
JavaScript
      |
HTML
```

Server Components:

```text
Data
     |
React
     |
UI
```

---

# What Is A Server Component?

A Server Component is:

> A React component that executes on the server.

Example:

```tsx
export default async function Home() {

  const posts =
    await db.post.findMany();

  return (
    <div>
      {posts.length}
    </div>
  );
}
```

---

# What Is A Client Component?

A Client Component is:

> A React component that executes in the browser.

Example:

```tsx
"use client";

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

---

# Visualizing Execution

Server Component:

```text
Browser
    |
Request
    |
Server
    |
React executes
    |
HTML
    |
Browser
```

---

Client Component:

```text
Browser
    |
Download JS
    |
Execute JS
    |
Render
```

---

# The Golden Rule

Server Components are:

```text
Backend code
written
using React syntax.
```

---

# Comparison Table

| Feature                | Server Component | Client Component |
| ---------------------- | ---------------- | ---------------- |
| Runs on server         | ✓                | ✗                |
| Runs in browser        | ✗                | ✓                |
| Uses hooks             | ✗                | ✓                |
| Uses state             | ✗                | ✓                |
| Uses effects           | ✗                | ✓                |
| Uses browser APIs      | ✗                | ✓                |
| Database access        | ✓                | ✗                |
| Environment variables  | ✓                | ✗                |
| Event handlers         | ✗                | ✓                |
| Bundle sent to browser | No               | Yes              |
| Async component        | ✓                | ✗                |

---

# Server Components Can Do

```text
✓ Database queries

✓ File access

✓ Secrets

✓ APIs

✓ Fetch

✓ Caching

✓ Async execution

✓ Authentication
```

---

# Example

```tsx
export default async function Posts() {

  const posts =
    await prisma.post.findMany();

  return (
    <>
      {posts.map(post => (
        <div key={post.id}>
          {post.title}
        </div>
      ))}
    </>
  );

}
```

---

# Client Components Can Do

```text
✓ State

✓ Effects

✓ Browser APIs

✓ Event handlers

✓ DOM APIs

✓ User interaction
```

---

# Example

```tsx
"use client";

export default function Search() {

  const [query, setQuery] =
    useState("");

  return (
    <input
      value={query}
      onChange={e =>
        setQuery(e.target.value)
      }
    />
  );

}
```

---

# Server Components Cannot Use

```text
useState

useEffect

useReducer

useContext

useRef

useLayoutEffect
```

---

# Example

This fails:

```tsx
export default function Page() {

  const [count, setCount] =
    useState(0);

}
```

Error:

```text
useState cannot be used
inside Server Components
```

---

# Client Components Cannot Access

```text
Database

Filesystem

Secrets

Private APIs

Server cache
```

---

# Example

This is dangerous:

```tsx
"use client";

console.log(
  process.env.API_KEY
);
```

---

# Why?

Because:

```text
Client
=
Public internet.
```

---

# Async Components

Server Components support:

```tsx
export default async function
Page() {

  const posts =
    await getPosts();

  return (
    <div>
      {posts.length}
    </div>
  );

}
```

---

# Client Components Cannot

This fails:

```tsx
"use client";

export default async function
Page() {}
```

---

# Why?

Because browsers do not execute React this way.

---

# Database Access

Server:

```tsx
export default async function
Page() {

  const users =
    await db.user.findMany();

  return (
    <div />
  );

}
```

---

Client:

```tsx
"use client";

await db.user.findMany();
```

Result:

```text
💥
```

---

# Environment Variables

Server:

```tsx
process.env.DATABASE_URL
```

Works.

---

Client:

```tsx
process.env.DATABASE_URL
```

Fails.

---

Unless:

```tsx
process.env
  .NEXT_PUBLIC_API_URL
```

---

# Why?

Because:

```text
Server
=
Private

Client
=
Public
```

---

# Event Handlers

Server:

```tsx
<button
  onClick={save}
/>
```

Invalid.

---

Client:

```tsx
"use client";

<button
  onClick={save}
/>
```

Valid.

---

# Browser APIs

Server:

```tsx
window
document
localStorage
navigator
```

Do not exist.

---

Client:

```tsx
"use client";

localStorage
window
document
```

Exist.

---

# Example

Bad:

```tsx
export default function
Page() {

  localStorage
    .getItem("theme");

}
```

---

Good:

```tsx
"use client";

export default function
Page() {

  useEffect(() => {

    localStorage
      .getItem("theme");

  }, []);

}
```

---

# Bundle Size

Server Components:

```text
0 KB
```

sent to browser.

---

Client Components:

```text
JavaScript bundle
```

sent to browser.

---

# Visualizing

Server:

```text
Server
   |
HTML
```

---

Client:

```text
Server
   |
HTML
   |
JavaScript
   |
Browser
```

---

# Why Server Components Are Fast

Because browsers avoid:

```text
Downloading

Parsing

Executing

Hydrating
```

JavaScript.

---

# The Component Tree

Example:

```tsx
export default function Page() {

  return (
    <>
      <Header />

      <SearchBox />

      <Posts />
    </>
  );

}
```

---

Suppose:

```text
Header
```

is server.

```text
SearchBox
```

is client.

```text
Posts
```

is server.

---

Tree:

```text
Server

   |
   +--- Header

   |
   +--- Client Boundary

   |         |
   |      SearchBox

   |
   +--- Posts
```

---

# Client Boundaries

```tsx
"use client";
```

creates:

```text
A boundary.
```

---

Everything imported below becomes:

```text
Client code.
```

---

Example

```tsx
"use client";

import Button
  from "./Button";
```

Now:

```text
Button
```

is also client.

---

# Important Rule

Client components infect downward.

---

Visualizing

```text
Server

    |
    +--- Client

             |
             +--- Client

             |
             +--- Client
```

---

# But Not Upward

```text
Server

   |
Client

   |
Server
```

is impossible.

---

# Composition Pattern

Correct:

```tsx
export default function
Page() {

  return (
    <>
      <PostList />

      <Search />
    </>
  );

}
```

---

Incorrect:

```tsx
"use client";

export default function
Page() {

  const posts =
    await getPosts();

}
```

---

# Fetching Data

Preferred:

```tsx
async function
getPosts() {

  return db.posts
    .findMany();

}

export default async function
Page() {

  const posts =
    await getPosts();

}
```

---

Avoid:

```tsx
"use client";

useEffect(() => {

  fetch("/api");

}, []);
```

unless interaction requires it.

---

# Server Actions Bridge The Gap

Server:

```ts
"use server";

export async function
savePost() {}
```

---

Client:

```tsx
"use client";

<button
  action={savePost}
/>
```

---

Visualizing

```text
Client
    |
Server Action
    |
Server
```

---

# Common Beginner Mistakes

---

## Mistake 1

```tsx
"use client";

export default async function
Page() {}
```

---

## Mistake 2

```tsx
export default function
Page() {

  useState();

}
```

---

## Mistake 3

```tsx
export default function
Page() {

  localStorage
    .getItem();

}
```

---

## Mistake 4

```tsx
"use client";

await db.query();
```

---

## Mistake 5

Making everything:

```text
"use client"
```

---

# Decision Tree

Need:

```text
Database?
```

Use:

```text
Server
```

---

Need:

```text
Secret?
```

Use:

```text
Server
```

---

Need:

```text
State?
```

Use:

```text
Client
```

---

Need:

```text
Effects?
```

Use:

```text
Client
```

---

Need:

```text
Button click?
```

Use:

```text
Client
```

---

Need:

```text
Fast rendering?
```

Prefer:

```text
Server
```

---

# The 90/10 Rule

Professional Next.js applications are often:

```text
90%
Server Components

10%
Client Components
```

---

# Architecture Example

```text
Server

├── Layout
├── Header
├── Sidebar
├── Dashboard
├── Data Tables
├── Analytics
│
└── Client
       ├── Search
       ├── Modal
       ├── Form
       └── Dropdown
```

---

# React Server Components Pipeline

```text
Database
     |
Server Component
     |
React Tree
     |
RSC Payload
     |
Browser
     |
Hydration
     |
Interactive UI
```

---

# Mental Model

Beginners think:

```text
Server Components
=
Server-side rendering.
```

Professional engineers think:

```text
Server Components
=
Backend code
written
using React.
```

Because the most important feature of React Server Components is not that they render on the server.

It's that they allow you to stop sending unnecessary JavaScript to the browser.
