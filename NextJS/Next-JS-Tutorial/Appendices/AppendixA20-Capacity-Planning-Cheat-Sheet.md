# Appendix A20 — Next.js 16 Performance Engineering, Scalability & Capacity Planning Cheat Sheet

## The Complete Guide to Making Systems Fast Before Making Them Bigger

> **Purpose:** This appendix is the definitive reference for performance engineering and scalability in Next.js 16 applications. Performance problems are rarely solved by adding more servers. They are usually solved by understanding where time is being spent.

---

# Introduction

The biggest misconception beginners have is:

```text
Performance
=
Fast computers.
```

Professional engineers understand:

```text
Performance
=
Efficient systems.
```

Because every system is ultimately constrained by:

```text
CPU

Memory

Network

Storage

Latency
```

---

# The Golden Rule

Never ask:

```text
How do I
make this faster?
```

Ask:

```text
What is
actually slow?
```

---

# Performance Engineering Workflow

```text
Measure

   |

Identify

   |

Optimize

   |

Measure Again
```

---

# Wrong Workflow

```text
Guess

   |

Optimize

   |

Hope
```

---

# Why?

Because:

```text
Premature
optimization
is expensive.
```

---

# The Three Types of Performance

```text
Frontend

Backend

Infrastructure
```

---

# Frontend Performance

Measures:

```text
Loading

Rendering

Interactivity
```

---

# Backend Performance

Measures:

```text
Latency

Throughput

Concurrency
```

---

# Infrastructure Performance

Measures:

```text
CPU

Memory

Disk

Network
```

---

# Latency vs Throughput

Latency:

```text
How long?
```

---

Throughput:

```text
How many?
```

---

Example:

```text
Latency:
100ms/request

Throughput:
1000 requests/sec
```

---

# Response Time Equation

```text
Response Time

=

Network

+

Application

+

Database

+

Cache
```

---

# Example

```text
Network:
20ms

Application:
30ms

Database:
200ms

Cache:
0ms

Total:
250ms
```

---

# Amdahl's Law

Question:

```text
What component
dominates?
```

---

Example:

```text
Database

90%

Application

10%
```

---

Optimization:

```text
Optimize
the database.
```

---

Not:

```text
Rewrite
the application.
```

---

# Performance Pyramid

```text
Architecture

      |

Algorithms

      |

Queries

      |

Code
```

---

# Rule

Optimize:

```text
Architecture

before

Algorithms

before

Code.
```

---

# Big O Matters

Examples:

```text
O(1)

O(log n)

O(n)

O(n²)
```

---

Example

Bad:

```ts
for (a of users)
  for (b of users)
```

---

Good:

```ts
const map =
  new Map();
```

---

# Next.js Performance Hierarchy

```text
Static

↓

Cache Components

↓

Server Components

↓

Client Components
```

---

# Static Generation

Fastest:

```text
HTML already exists.
```

---

Example:

```ts
export const
dynamic =
  "force-static";
```

---

# Cache Components

Second fastest:

```text
Request

   |

Cache

   |

Response
```

---

Example:

```ts
"use cache";
```

---

# Server Components

Benefits:

```text
No hydration

No bundle

Server execution
```

---

# Client Components

Cost:

```text
JavaScript

Hydration

Memory
```

---

# Professional Rule

Prefer:

```text
Server Components.
```

Use client components only when:

```text
Interactivity
requires them.
```

---

# Measuring Frontend Performance

Track:

```text
LCP

INP

CLS

FCP

TTFB
```

---

# Largest Contentful Paint

Question:

```text
When does
the page
appear?
```

---

Goal:

```text
< 2.5 seconds
```

---

# Interaction to Next Paint

Question:

```text
How responsive
is interaction?
```

---

Goal:

```text
< 200ms
```

---

# Cumulative Layout Shift

Question:

```text
Does content
move around?
```

---

Goal:

```text
Near zero.
```

---

# JavaScript Budget

Question:

```text
How much JS
did we ship?
```

---

Bad:

```text
2 MB
bundle
```

---

Better:

```text
100 KB
bundle
```

---

# Bundle Splitting

Use:

```text
Dynamic imports.
```

---

Example:

```ts
const Editor =
  dynamic(
    () => import()
  );
```

---

# Image Optimization

Always:

```text
Resize

Compress

Lazy load
```

---

Example:

```tsx
<Image
  fill
  priority
/>
```

---

# Database Performance

Most bottlenecks are:

```text
Database bottlenecks.
```

---

Questions:

```text
How many queries?

How large?

How often?
```

---

# N+1 Queries

Bad:

```text
Users

   |

100 queries

   |

Posts
```

---

Better:

```text
JOIN

or

Batch query
```

---

# Indexes

Without index:

```text
Table scan.
```

---

With index:

```text
Direct lookup.
```

---

Example:

```sql
CREATE INDEX
idx_email
ON users(email);
```

---

# Query Performance

Measure:

```text
Execution time

Rows scanned

Rows returned
```

---

# Pagination

Never:

```sql
SELECT *
FROM posts;
```

---

Use:

```sql
LIMIT 20
OFFSET 0;
```

---

Or:

```text
Cursor pagination.
```

---

# Caching Strategy

Cache:

```text
Expensive

Frequent

Stable
```

---

Do not cache:

```text
Cheap

Rare

Volatile
```

---

# Cache Levels

```text
Browser

↓

CDN

↓

Application

↓

Database
```

---

# Browser Cache

Example:

```text
Static assets
```

---

# CDN Cache

Example:

```text
Images

JavaScript

CSS
```

---

# Application Cache

Example:

```text
Products

Users

Articles
```

---

# Database Cache

Example:

```text
Query results
```

---

# Cache Hit Rate

Formula:

```text
Hits

/

Total Requests
```

---

Goal:

```text
> 90%
```

---

# Network Performance

Latency is expensive.

Example:

```text
1 request:
50ms

10 requests:
500ms
```

---

# Solution

Reduce:

```text
Round trips.
```

---

# Parallelism

Bad:

```ts
await a();
await b();
await c();
```

---

Better:

```ts
await Promise.all([
  a(),
  b(),
  c(),
]);
```

---

# Streaming

Instead of:

```text
Wait

Wait

Wait

Render
```

---

Use:

```text
Render

Then stream.
```

---

Example:

```tsx
<Suspense>
```

---

# Capacity Planning

Question:

```text
How much load
can we handle?
```

---

Formula:

```text
Capacity

=

Requests/sec

×

Users
```

---

# Example

```text
1000 users

×

5 requests

=

5000 requests/sec
```

---

# Vertical Scaling

Add:

```text
More CPU

More RAM
```

---

Benefits:

```text
Simple.
```

---

Costs:

```text
Expensive.
```

---

# Horizontal Scaling

Add:

```text
More servers.
```

---

Benefits:

```text
Scalable.
```

---

Costs:

```text
Complex.
```

---

# Load Balancing

Visualizing:

```text
Users

   |

Load Balancer

   |

Server A

Server B

Server C
```

---

# Stateless Systems

Requirement:

```text
Any server
can process
any request.
```

---

# State Storage

Store state in:

```text
Database

Redis

Storage
```

---

Not:

```text
Server memory.
```

---

# Queue Scaling

Visualizing:

```text
Jobs

  |

Queue

  |

Workers
```

---

Scale:

```text
Workers.
```

---

# Backpressure

Question:

```text
What happens
when load
exceeds capacity?
```

---

Options:

```text
Queue

Reject

Throttle
```

---

# Rate Limiting

Example:

```text
100 requests
per minute
```

---

Purpose:

```text
Protect
capacity.
```

---

# Load Testing

Questions:

```text
How much?

How long?

How often?
```

---

Types:

```text
Load

Stress

Spike

Soak
```

---

# Load Test

Measures:

```text
Normal traffic.
```

---

# Stress Test

Measures:

```text
Failure point.
```

---

# Spike Test

Measures:

```text
Sudden traffic.
```

---

# Soak Test

Measures:

```text
Long duration.
```

---

# Bottleneck Identification

Look for:

```text
High CPU

High memory

Slow queries

Network delays

Lock contention
```

---

# The Performance Checklist

Verify:

```text
✓ Server Components

✓ Cache Components

✓ Database indexes

✓ No N+1 queries

✓ Image optimization

✓ Bundle splitting

✓ Streaming

✓ Parallel fetching

✓ Caching

✓ Load testing
```

---

# Common Beginner Mistakes

---

## Mistake 1

Optimizing before measuring.

---

## Mistake 2

Using client components everywhere.

---

## Mistake 3

Ignoring database performance.

---

## Mistake 4

Ignoring network latency.

---

## Mistake 5

No caching.

---

## Mistake 6

Premature microservices.

---

## Mistake 7

Assuming localhost performance equals production performance.

---

# Performance Decision Tree

Question:

```text
Is it slow?
```

If:

```text
No
```

Then:

```text
Do nothing.
```

---

Question:

```text
Can you
measure it?
```

If:

```text
No
```

Then:

```text
Add metrics.
```

---

Question:

```text
What is
the bottleneck?
```

Then:

```text
Optimize only
that bottleneck.
```

---

# The Complete Performance Pipeline

```text
Measure
    |
Profile
    |
Identify
    |
Optimize
    |
Benchmark
    |
Deploy
    |
Monitor
```

---

# Mental Model

Beginners think:

```text
Performance
=
Writing
fast code.
```

Professional engineers think:

```text
Performance
=
Eliminating
unnecessary work.
```

Because the fastest computation is not the optimized computation.

It is the computation that never had to happen.
