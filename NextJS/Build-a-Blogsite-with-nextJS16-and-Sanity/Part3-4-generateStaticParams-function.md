# **✅ Part 3-4 — Understanding `generateStaticParams()`**

# GreyMatter Journal

## Part 3-4 — Understanding `generateStaticParams()`: Static Generation, Build Time, and Trading Computation for Speed

> **Goal of this lesson:** Understand what `generateStaticParams()` does, learn why modern frameworks generate pages before users visit them, and discover how software systems continuously trade computation, storage, and time to improve performance.

---

# Another Strange Function

Eventually, when building dynamic routes, you'll encounter another mysterious function:

```tsx
export async function generateStaticParams() {
  return [];
}
```

This immediately raises new questions:

* What exactly is being generated?
* Why do we generate parameters?
* When does this function run?
* Why isn't it part of the page?
* How does this improve performance?
* Why do static websites still need dynamic routes?

To answer these questions, we must first understand a fundamental problem of software systems:

> Computing things repeatedly is expensive.

---

# The Cost of Computing

Imagine our blog contains one article:

```text
/posts/react-server-components
```

When a user visits:

```text
https://greymatter.com/posts/react-server-components
```

the server must:

```text
Request
    ↓

Database Query
    ↓

Build React Tree
    ↓

Generate HTML
    ↓

Return Response
```

This happens every time.

For one user:

```text
1 request
```

For one million users:

```text
1,000,000 requests
```

This creates a question:

> What if we computed the page once?

---

# The Idea Behind Static Generation

Suppose our article rarely changes.

Instead of:

```text
User Request
      ↓

Generate Page
      ↓

Return Page
```

we could do:

```text
Build Time
      ↓

Generate Page
      ↓

Save HTML
      ↓

Serve HTML Forever
```

This approach is called:

```text
Static Site Generation
```

or:

```text
SSG
```

---

# Static Generation Is Caching

Most beginners think:

```text
Static Site
```

means:

```text
Simple Website
```

Professional engineers think:

```text
Static Site
```

means:

```text
Precomputed Cache
```

In other words:

```text
Compute Once
      ↓
Store Result
      ↓
Reuse Forever
```

---

# The Dynamic Route Problem

Now consider our application:

```text
app/

posts/
    [slug]/
        page.tsx
```

At build time, Next.js sees:

```text
[slug]
```

and asks:

> Which slugs exist?

Because:

```text
[slug]
```

could represent:

```text
/posts/react
/posts/nextjs
/posts/typescript
/posts/server-actions
```

The framework cannot guess.

We must tell it.

---

# Introducing `generateStaticParams()`

This is precisely why:

```tsx
export async function generateStaticParams()
```

exists.

Example:

```tsx
import { client } from "@/lib/sanity";

export async function
generateStaticParams() {
  const posts =
    await client.fetch(`
      *[_type=="post"]{
        "slug":slug.current
      }
    `);

  return posts;
}
```

Suppose Sanity contains:

```text
React

Next.js

TypeScript
```

The function returns:

```tsx
[
  {
    slug: "react",
  },
  {
    slug: "nextjs",
  },
  {
    slug: "typescript",
  },
];
```

---

# What Happens Next?

Next.js now knows:

```text
/posts/react

/posts/nextjs

/posts/typescript
```

exist.

During the build process:

```text
Build
    ↓

generateStaticParams()
    ↓

Get Routes
    ↓

Render Pages
    ↓

Store HTML
```

Result:

```text
.next/

posts/
    react.html

    nextjs.html

    typescript.html
```

Conceptually, the pages already exist before users arrive.

---

# Visualizing the Build Process

Without static generation:

```text
User
   ↓

Server
   ↓

Database
   ↓

React
   ↓

HTML
```

With static generation:

```text
Build
   ↓

Database
   ↓

React
   ↓

HTML Cache
   ↓

User
```

Notice what disappeared:

```text
Database

React Rendering

Computation
```

during the request.

---

# Example: GreyMatter Journal

Our future implementation might look like:

```tsx
import { client }
  from "@/lib/sanity";

export async function
generateStaticParams() {

  const posts =
    await client.fetch(`
      *[_type=="post"]{
        "slug":
          slug.current
      }
    `);

  return posts;
}

export default async function
PostPage({
  params,
}: {
  params: Promise<{
    slug:string;
  }>;
}) {

  const { slug } =
    await params;

  const post =
    await client.fetch(
      POST_QUERY,
      { slug }
    );

  return (
    <article>
      <h1>
        {post.title}
      </h1>
    </article>
  );
}
```

Notice:

```text
generateStaticParams()
```

does not render pages.

It generates instructions for rendering pages.

---

# Why Is This So Fast?

Suppose our page requires:

```text
Database:
    50ms

Rendering:
    75ms

Network:
    25ms

Total:
    150ms
```

Static generation moves:

```text
125ms
```

to build time.

The user experiences:

```text
Network:
    25ms
```

This is one of the oldest optimization techniques in computer science:

> Perform expensive work before it is needed.

---

# But What About New Posts?

Suppose we deploy:

```text
React
Next.js
TypeScript
```

Then later publish:

```text
Server Actions
```

The page:

```text
/posts/server-actions
```

did not exist during build.

What happens?

This introduces one of the most important concepts in Next.js:

```text
Static
        +
Dynamic
        +
Revalidation
```

Modern systems continuously move between these states.

---

# Static Generation Is a Tradeoff

Nothing is free.

Static generation trades:

```text
More Build Time
```

for:

```text
Faster Requests
```

Visualized:

```text
Build Cost
        ↑

Request Cost
        ↓
```

Professional engineers constantly make these tradeoffs.

---

# The Real Mental Model

Beginners think:

```text
generateStaticParams()
```

means:

```text
Generate Routes
```

This is partially correct.

Professional engineers think:

```text
generateStaticParams()
```

means:

```text
Discover Data
        ↓

Generate Cache Keys
        ↓

Precompute Results
        ↓

Optimize Future Requests
```

---

# Understanding Build-Time Reality

A modern Next.js application exists in multiple timelines:

```text
Build Time
      ↓

Request Time
      ↓

Cache Time
      ↓

Revalidation Time
```

Each timeline has different costs and benefits.

---

# Static Generation as Systems Engineering

Consider what actually happens:

```text
Sanity CMS
      ↓

generateStaticParams()
      ↓

Build System
      ↓

React Renderer
      ↓

Static Assets
      ↓

CDN
      ↓

Browser
```

Notice:

```text
Database
```

has disappeared from the request path.

This is why static websites can be extraordinarily fast.

---

# The Correct Mental Model

Beginners think:

```text
Page
      ↓
User
```

Professional engineers think:

```text
Data
     ↓

Build System
     ↓

Cache
     ↓

CDN
     ↓

User
```

Or even more accurately:

```text
Future User Requests
            ↓

Predict
            ↓

Precompute
            ↓

Cache
            ↓

Serve
```

---

# The Most Important Idea To Remember

`generateStaticParams()` does not generate pages.

It generates knowledge about future pages.

More fundamentally:

> Performance engineering is often the art of moving computation through time.

Instead of asking:

```text
How do I compute faster?
```

professional engineers often ask:

```text
Can I compute earlier?
```

That question powers:

* Static Site Generation
* Caching
* CDNs
* Incremental Static Regeneration
* Edge Computing
* Modern web architecture itself
