# Appendix A12 — Next.js 16 Performance Optimization Cheat Sheet

## The Complete Guide to Building Fast, Efficient, and Scalable Applications

> **Purpose:** This appendix is the definitive reference for performance optimization in Next.js 16. Performance is not a feature. Performance is an architectural property that emerges from thousands of small decisions.

---

# Introduction

The biggest misconception beginners have is:

```text id="jj5kmn"
Performance
=
Making code faster.
```

Professional engineers think:

```text id="mjlwmx"
Performance
=
Doing less work.
```

The fastest code is:

```text id="jrvvzd"
Code that never runs.
```

---

# The Performance Pyramid

```text id="jz0jlwm"
Performance

      |

Caching

      |

Rendering

      |

Network

      |

JavaScript

      |

Algorithms
```

---

# The Golden Rule

Before optimizing:

```text id="g83ay2"
Measure.
```

Never optimize:

```text id="xb9z13"
Based on feelings.
```

---

# The User Experience Timeline

```text id="yfvryh"
Request
    |
HTML
    |
CSS
    |
JavaScript
    |
Hydration
    |
Interaction
```

---

# Performance Metrics

Modern web performance measures:

```text id="r0s9gx"
LCP

INP

CLS

TTFB

FCP
```

---

# LCP

Largest Contentful Paint

Measures:

```text id="3idvfq"
How quickly
users see
content.
```

---

# INP

Interaction to Next Paint

Measures:

```text id="wkh3r6"
How responsive
the UI feels.
```

---

# CLS

Cumulative Layout Shift

Measures:

```text id="04bny0"
Visual stability.
```

---

# TTFB

Time To First Byte

Measures:

```text id="fjlwmw"
Server speed.
```

---

# FCP

First Contentful Paint

Measures:

```text id="72koym"
Initial rendering.
```

---

# Performance Strategy

Optimize in this order:

```text id="t97b4x"
1. Architecture

2. Rendering

3. Caching

4. Network

5. JavaScript
```

---

# Server Components

Best optimization:

```text id="b2w1r6"
Remove JavaScript.
```

---

Bad:

```tsx id="yx67l0"
"use client";

export default function
Page() {

}
```

---

Good:

```tsx id="h2wnod"
export default async function
Page() {

}
```

---

# Visualizing

Client:

```text id="wpgjlwm"
Download JS
Execute JS
Hydrate
Render
```

---

Server:

```text id="1pq0ra"
Render
Send HTML
```

---

# Reduce Client Components

Bad:

```tsx id="qh7kz6"
"use client";

export default function
App() {

}
```

---

Good:

```tsx id="l3osn6"
export default function
App() {

  return (
    <>
      <ServerStuff />

      <ClientWidget />
    </>
  );

}
```

---

# Partial Prerendering

Use:

```text id="s96ycy"
Static shell

+

Dynamic islands
```

---

Visualizing:

```text id="qjlwmf"
Header
Hero
Footer
```

Static.

---

```text id="rk0mb1"
Dashboard

Notifications
```

Dynamic.

---

# Streaming

Bad:

```text id="vjbvbc"
Wait
Wait
Wait
Render
```

---

Good:

```text id="p1q0g0"
Render
Render
Render
```

---

# Example

```tsx id="mjjlwm"
<Suspense
  fallback={
    <Loading />
  }
>
  <Posts />
</Suspense>
```

---

# Parallel Fetching

Bad:

```ts id="jlwm0f"
const a =
  await getA();

const b =
  await getB();

const c =
  await getC();
```

---

Good:

```ts id="i8u3jz"
await Promise.all([

  getA(),

  getB(),

  getC(),

]);
```

---

# Visualizing

Sequential:

```text id="q9dcr1"
A
|
B
|
C
```

---

Parallel:

```text id="uw2vtl"
A \
B  ---> Done
C /
```

---

# Cache Components

Use:

```ts id="o7jlwm"
"use cache";
```

---

Example:

```ts id="zvr5mx"
export async function
getPosts() {

  "use cache";

}
```

---

# Cache Tags

Example:

```ts id="d7jlwm"
cacheTag(
  "posts"
);
```

---

# Cache Lifetime

Example:

```ts id="txw8e6"
cacheLife(
  "hours"
);
```

---

# Image Optimization

Never:

```html id="jlwm7a"
<img />
```

---

Use:

```tsx id="jlwm90"
import Image
from "next/image";
```

---

Example:

```tsx id="jlwmqp"
<Image

  src={url}

  alt=""

  width={400}

  height={300}

/>
```

---

# Why?

Next.js automatically provides:

```text id="jlwm1r"
Resize

Compress

Lazy load

Cache
```

---

# Lazy Loading

Bad:

```tsx id="jlwmod"
<HeavyEditor />
```

---

Good:

```tsx id="jlwm32"
const Editor =
  dynamic(
    () =>
      import(
        "./editor"
      )
  );
```

---

# Code Splitting

Automatic:

```text id="jlwm6h"
Route based.
```

---

Manual:

```tsx id="jlwm4u"
dynamic(() =>
  import(
    "./chart"
  )
);
```

---

# Bundle Size

Analyze:

```bash id="jlwm4p"
npm run analyze
```

---

Look for:

```text id="jlwmh0"
Large libraries

Duplicate packages

Unused code
```

---

# Tree Shaking

Bad:

```ts id="jwlm87"
import *
from "lodash";
```

---

Good:

```ts id="jlwmv9"
import debounce
from "lodash/debounce";
```

---

# Database Performance

Bad:

```ts id="jlwmz8"
for (
  const user
  of users
) {

  await db.post
    .findMany();

}
```

---

This creates:

```text id="jlwm8j"
N+1 queries.
```

---

Good:

```ts id="wjlm1b"
await db.user
  .findMany({

    include: {
      posts: true,
    },

  });
```

---

# Visualizing

Bad:

```text id="jlwmfs"
User
 |
Posts
 |
Posts
 |
Posts
```

---

Good:

```text id="jlwmxe"
Users + Posts
```

---

# Request Memoization

Next.js automatically deduplicates:

```ts id="jlwmtt"
await getPosts();

await getPosts();
```

---

Result:

```text id="jlwm3g"
One query.
```

---

# React cache()

Example:

```ts id="jlwmde"
import {
  cache,
} from "react";
```

---

```ts id="jlwm5x"
export const
getUser =
cache(
  async () => {}
);
```

---

# Avoid Waterfalls

Bad:

```ts id="jlwmwq"
const user =
  await getUser();

const posts =
  await getPosts(
    user.id
  );
```

---

Visualizing:

```text id="jlwm2s"
User
   |
Posts
```

---

# CDN Caching

Visualizing:

```text id="jlwmrz"
User

  |

CDN

  |

Server
```

---

Goal:

```text id="jlwm67"
Avoid servers.
```

---

# Font Optimization

Use:

```tsx id="jlwm0e"
import {
  Inter,
}
from
"next/font/google";
```

---

Example:

```tsx id="jlwmk8"
const inter =
  Inter({

    subsets:
      ["latin"],

  });
```

---

# Metadata Optimization

Example:

```ts id="jlwm3v"
export const
metadata = {

  title:
    "My Site",

};
```

---

# Static Generation

Prefer:

```text id="jlwmib"
Build time.
```

---

Over:

```text id="jlwmr2"
Request time.
```

---

# Route Segment Config

Example:

```ts id="jlwmc0"
export const
dynamic =
"force-static";
```

---

# Server Actions

Use instead of:

```text id="jlwmqe"
Internal APIs.
```

---

Bad:

```text id="jlwmh8"
Browser

   |

API

   |

Server
```

---

Good:

```text id="jlwmq4"
Browser

   |

Server Action
```

---

# Reduce Dependencies

Ask:

```text id="jlwmj2"
Do I really
need this?
```

---

# Third Party Scripts

Load lazily:

```tsx id="jlwm4r"
<Script

  strategy=
    "lazyOnload"

/>
```

---

# Web Vitals

Measure:

```tsx id="jlwm6o"
export function
reportWebVitals(
  metric
) {

}
```

---

# Memory Usage

Monitor:

```text id="jlwmal"
Heap

Objects

Leaks
```

---

# CPU Usage

Monitor:

```text id="jlwm5m"
Rendering

Database

Parsing
```

---

# Network Optimization

Reduce:

```text id="jlwm3d"
Requests

Payloads

Round trips
```

---

# Compression

Use:

```text id="jlwm01"
gzip

brotli
```

---

# Edge Runtime

Use for:

```text id="jlwmly"
Low latency.
```

---

Avoid for:

```text id="jlwm4k"
Heavy compute.
```

---

# Performance Budget

Example:

```text id="jlwmmt"
JavaScript:
200kb

LCP:
2.5 sec

TTFB:
200ms
```

---

# Common Beginner Mistakes

---

## Mistake 1

Everything is:

```tsx id="jlwmz0"
"use client";
```

---

## Mistake 2

No caching.

---

## Mistake 3

Sequential fetching.

---

## Mistake 4

Huge dependencies.

---

## Mistake 5

Ignoring images.

---

## Mistake 6

Ignoring bundle size.

---

## Mistake 7

Optimizing without measuring.

---

# Performance Decision Tree

Need:

```text id="jlwmta"
Less JavaScript?
```

Use:

```text id="jlwmn2"
Server Components
```

---

Need:

```text id="jlwmf1"
Less latency?
```

Use:

```text id="jlwmmz"
Caching
```

---

Need:

```text id="jlwmba"
Faster loading?
```

Use:

```text id="jlwm9h"
Streaming
```

---

Need:

```text id="jlwmjb"
Smaller bundles?
```

Use:

```text id="jlwm7u"
Code splitting
```

---

Need:

```text id="jlwmh7"
Fewer requests?
```

Use:

```text id="jlwmv5"
Server Actions
```

---

# The Complete Performance Pipeline

```text id="jlwmwv"
Request
     |
CDN
     |
Cache
     |
Server
     |
Streaming
     |
Browser
     |
Hydration
     |
Interaction
```

---

# Mental Model

Beginners think:

```text id="jlwm4m"
Performance
=
Speed.
```

Professional engineers think:

```text id="jlwmm4"
Performance
=
Eliminating
unnecessary work.
```

Because every millisecond of latency is usually caused by one of two things:

```text id="jlwm60"
Doing work
you didn't need

or

doing work
too late.
```
