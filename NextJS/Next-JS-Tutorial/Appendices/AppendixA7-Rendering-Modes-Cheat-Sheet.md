# Appendix A7 — Next.js 16 Rendering Modes Cheat Sheet

## The Complete Guide to Static Rendering, Dynamic Rendering, Streaming, and Partial Prerendering

> **Purpose:** This appendix is the definitive reference for understanding how Next.js 16 renders applications. If Server Components explain *where* code runs, rendering modes explain *when* code runs.

---

# Introduction

The biggest misconception beginners have is:

```text
Rendering
=
Creating HTML.
```

In reality:

```text
Rendering
=
A strategy for deciding:

Where

When

How often

At what cost

HTML gets created.
```

---

# The Four Rendering Modes

Next.js 16 applications primarily use:

```text
1. Static Rendering

2. Dynamic Rendering

3. Streaming

4. Partial Prerendering
```

---

# Visual Overview

```text
                 Request

                     |

         +-----------+-----------+

         |                       |

      Static                Dynamic

         |                       |

         +-----------+-----------+

                     |

                Streaming

                     |

           Partial Prerendering
```

---

# Traditional Web Rendering

Classic PHP:

```text
Request
   |
Server
   |
Database
   |
HTML
   |
Browser
```

Every request executes everything.

---

# Static Rendering

## Definition

HTML is generated:

```text
Before users arrive.
```

---

# Visualizing

```text
Build Time
      |
Generate HTML
      |
Store
      |
User Request
      |
Return HTML
```

---

# Example

```tsx
export default function About() {
  return (
    <h1>
      About Us
    </h1>
  );
}
```

---

Generated once:

```text
npm run build
```

---

Served forever:

```text
/about
```

---

# Advantages

```text
✓ Fast

✓ Cheap

✓ CDN friendly

✓ SEO friendly

✓ Scalable
```

---

# Disadvantages

```text
✗ Can become stale
```

---

# Examples

Good candidates:

```text
Landing pages

Blogs

Documentation

Marketing sites

FAQs
```

---

# Dynamic Rendering

## Definition

HTML is generated:

```text
For each request.
```

---

# Visualizing

```text
Request
    |
Server
    |
Database
    |
HTML
    |
Browser
```

---

# Example

```tsx
export default async function
Dashboard() {

  const user =
    await auth();

  return (
    <h1>
      {user.name}
    </h1>
  );

}
```

---

# Why Dynamic?

Because:

```text
Every user
is different.
```

---

# Advantages

```text
✓ Always fresh

✓ Personalized

✓ Secure

✓ Flexible
```

---

# Disadvantages

```text
✗ Slower

✗ More expensive

✗ Less cacheable
```

---

# Good Examples

```text
Dashboards

Admin panels

Shopping carts

User profiles

Analytics
```

---

# Static vs Dynamic

| Feature         | Static    | Dynamic   |
| --------------- | --------- | --------- |
| Generated       | Build     | Request   |
| Speed           | Fast      | Slower    |
| Cost            | Low       | Higher    |
| Personalization | No        | Yes       |
| SEO             | Excellent | Excellent |
| Cacheable       | Very      | Limited   |

---

# Route Configuration

Force static:

```ts
export const dynamic =
  "force-static";
```

---

Force dynamic:

```ts
export const dynamic =
  "force-dynamic";
```

---

Automatic:

```ts
export const dynamic =
  "auto";
```

---

# Visualizing

```text
auto
   |
Analyze route
   |
Choose strategy
```

---

# Streaming

## Definition

Send HTML:

```text
In pieces.
```

---

# Traditional Rendering

```text
Request
    |
Wait
    |
Wait
    |
Wait
    |
HTML
```

---

# Streaming Rendering

```text
Request
    |
Header
    |
Sidebar
    |
Loading UI
    |
Content
    |
Analytics
```

---

# Visualizing

Traditional:

```text
██████████
One response
```

---

Streaming:

```text
██
██
██
██
██
Multiple chunks
```

---

# Example

```tsx
import {
  Suspense,
} from "react";

export default function
Page() {

  return (
    <>

      <Header />

      <Suspense
        fallback={
          <Loading />
        }
      >
        <Posts />
      </Suspense>

    </>
  );

}
```

---

# Execution

```text
Header
    |
Send immediately

Posts
    |
Still loading

Posts complete
    |
Send later
```

---

# Benefits

```text
✓ Faster perception

✓ Better UX

✓ Reduced waiting

✓ Better concurrency
```

---

# Loading UI

Example:

```tsx
export default function
Loading() {

  return (
    <Spinner />
  );

}
```

---

# Visualizing

```text
Request
    |
Loading
    |
Real content
```

---

# Suspense Boundaries

Example:

```tsx
<Suspense>

  <Analytics />

</Suspense>
```

Creates:

```text
A streaming boundary.
```

---

# Example

```tsx
<>
  <Header />

  <Suspense>
    <Posts />
  </Suspense>

  <Suspense>
    <Comments />
  </Suspense>
</>
```

---

Visualizing:

```text
Header

Posts

Comments
```

all stream independently.

---

# Partial Prerendering (PPR)

## Definition

Combine:

```text
Static
     +
Dynamic
```

on the same page.

---

# Traditional Choices

Previously:

```text
Entire page static
```

or:

```text
Entire page dynamic
```

---

# Partial Prerendering

```text
Page

   |
   +---- Static

   |
   +---- Dynamic

   |
   +---- Dynamic

   |
   +---- Static
```

---

# Visual Example

Blog homepage:

```text
Header
Hero
Navigation
```

are static.

---

Meanwhile:

```text
Trending posts

Recommendations

Notifications
```

are dynamic.

---

# Visualizing

```text
Pre-rendered shell

         |

Dynamic holes

         |

Fill holes
```

---

# Example

```tsx
export default function
Page() {

  return (

    <>

      <Hero />

      <Suspense>

        <Trending />

      </Suspense>

    </>

  );

}
```

---

# Execution

Build:

```text
Hero
```

generated.

---

Request:

```text
Trending
```

generated.

---

# Benefits

```text
✓ Fast

✓ Dynamic

✓ SEO

✓ Personalized

✓ Cacheable
```

---

# Visual Comparison

Static:

```text
[STATIC]
```

---

Dynamic:

```text
[DYNAMIC]
```

---

PPR:

```text
[STATIC]

[DYNAMIC]

[STATIC]
```

---

# Cache Components And Rendering

Example:

```ts
async function
getPosts() {

  "use cache";

}
```

This enables:

```text
Partial prerendering.
```

---

# Example

```tsx
export default async function
Page() {

  const posts =
    await getPosts();

}
```

---

Visualizing:

```text
Request
    |
Cache hit?
    |
Yes
    |
Static response

No
    |
Dynamic response
```

---

# Static Generation

Example:

```ts
export async function
generateStaticParams() {

  return [

    {
      slug: "a",
    },

    {
      slug: "b",
    },

  ];

}
```

---

Visualizing:

```text
Build

   |

/blog/a

/blog/b

/blog/c
```

---

# Incremental Regeneration

Traditional:

```text
Build once
```

---

Regeneration:

```text
Build

  |

Cache

  |

Expire

  |

Rebuild
```

---

# Cache Lifetimes

Example:

```ts
cacheLife(
  "hours"
);
```

---

Visualizing:

```text
Request
    |
Generate
    |
Cache
    |
1 hour
    |
Regenerate
```

---

# Revalidation

Example:

```ts
revalidateTag(
  "posts"
);
```

---

Visualizing:

```text
Cache
   |
Invalidate
   |
Regenerate
```

---

# Dynamic Functions

These force dynamic rendering:

```text
cookies()

headers()

searchParams

auth()

draftMode()
```

---

Example:

```tsx
const cookieStore =
  await cookies();
```

---

Result:

```text
Dynamic route.
```

---

# Decision Matrix

| Situation       | Rendering Mode       |
| --------------- | -------------------- |
| Marketing page  | Static               |
| Blog            | Static               |
| Product catalog | Static + Cache       |
| Dashboard       | Dynamic              |
| User profile    | Dynamic              |
| Analytics       | Streaming            |
| News feed       | Streaming            |
| Mixed page      | Partial prerendering |

---

# Architecture Example

```text
Homepage

   |
   +--- Hero
           Static

   |
   +--- Features
           Static

   |
   +--- Trending
           Dynamic

   |
   +--- User
           Dynamic
```

---

# Performance Pyramid

```text
Static

    |

Partial prerendering

    |

Streaming

    |

Dynamic
```

---

# Common Beginner Mistakes

---

## Mistake 1

Making everything:

```text
force-dynamic
```

---

## Mistake 2

Making everything:

```text
force-static
```

---

## Mistake 3

Ignoring Suspense.

---

## Mistake 4

Using client-side fetching for static content.

---

## Mistake 5

Treating loading states as an afterthought.

---

# The Rendering Decision Tree

Need:

```text
Personalization?
```

Use:

```text
Dynamic
```

---

Need:

```text
Maximum speed?
```

Use:

```text
Static
```

---

Need:

```text
Both?
```

Use:

```text
Partial prerendering
```

---

Need:

```text
Fast perceived loading?
```

Use:

```text
Streaming
```

---

# The Next.js 16 Rendering Pipeline

```text
Request
     |
Router
     |
Cache
     |
Static?
     |
Dynamic?
     |
Streaming?
     |
Partial prerendering?
     |
HTML
     |
Browser
```

---

# Mental Model

Beginners think:

```text
Rendering
=
Generating HTML.
```

Professional engineers think:

```text
Rendering
=
A distributed systems
optimization problem.
```

Because rendering is fundamentally about balancing:

```text
Performance

Freshness

Cost

Personalization

Consistency
```

under real-world constraints.
