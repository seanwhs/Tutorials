# Next.js 16 for Absolute Beginners

# Part 22 — Observability and Production Debugging: How Professional Engineers Understand Their Systems

> **Goal of this lesson:** Learn how to observe, monitor, debug, and understand production Next.js 16 applications using logging, metrics, tracing, error monitoring, performance profiling, and cache observability.

---

# The Biggest Beginner Mistake

Beginners think:

```text
Build
   |
Deploy
   |
Done
```

Professional engineers think:

```text
Build
   |
Deploy
   |
Observe
   |
Debug
   |
Improve
```

Because the hardest bugs only appear in production.

---

# What Is Observability?

Observability answers one question:

> "What is my system doing right now?"

---

# Example

Suppose a user reports:

```text
The dashboard is slow.
```

Questions immediately appear:

```text
Which page?
Which user?
Which API?
Which database query?
Which server?
Which cache?
```

Without observability:

```text
Guessing
```

With observability:

```text
Evidence
```

---

# The Three Pillars of Observability

Professional systems use:

```text
Logs

Metrics

Traces
```

---

# Visualizing Observability

```text
                Observability
                       |
         +-------------+-------------+
         |             |             |
         V             V             V
       Logs         Metrics       Traces
```

---

# Pillar 1 — Logs

Logs answer:

```text
What happened?
```

---

# Example

```ts
console.log(
    "User logged in"
);
```

This is a log.

---

# Better Logging

Instead of:

```ts
console.log(
    "error"
);
```

write:

```ts
console.error({

    event:
        "login_failed",

    user:
        email,

    reason:
        "invalid_password",

    timestamp:
        new Date(),

});
```

---

# Visualizing Logs

```text
Request
    |
Event
    |
Log Entry
    |
Storage
```

---

# Example Log Output

```json
{
  "event": "post_published",
  "userId": 42,
  "postId": 15,
  "timestamp": "2026-06-28T12:00:00"
}
```

---

# What Should You Log?

Always log:

```text
Authentication

Authorization failures

Payments

Uploads

Database failures

Cache invalidation

Critical business events
```

---

# What Should You NOT Log?

Never log:

```text
Passwords

Access tokens

Secrets

Credit card numbers

Session cookies
```

---

# Logging Architecture

```text
Browser
    |
Server Action
    |
Log Event
    |
Storage
```

---

# Example Server Action

```tsx
"use server";

export async function publishPost(
    id: number
) {

    await db.post.update({

        where: { id },

        data: {
            published: true,
        },

    });

    console.log({

        event:
            "post_published",

        postId:
            id,

    });

}
```

---

# Pillar 2 — Metrics

Metrics answer:

```text
How much?
How often?
How fast?
```

---

# Examples

```text
Requests per second

Error rate

Response time

Cache hit rate

Memory usage

Database latency
```

---

# Visualizing Metrics

```text
Requests
    |
Measure
    |
Store
    |
Graph
```

---

# Example Metrics Dashboard

```text
Requests/sec:       850
Errors/min:           2
Average latency:   120ms
Cache hit rate:     94%
```

---

# Why Metrics Matter

Suppose:

```text
Yesterday:
100ms
```

Today:

```text
3000ms
```

You immediately know:

```text
Something broke.
```

---

# Pillar 3 — Tracing

Tracing answers:

```text
Where did time go?
```

---

# Example Request

```text
Open Dashboard
```

---

# Trace Output

```text
Dashboard Request

    Authentication
         30 ms

    Database
         120 ms

    Cache
         5 ms

    Analytics
         500 ms

Total
         655 ms
```

---

# Visualizing Traces

```text
Request
    |
    +--- Auth
    |
    +--- Database
    |
    +--- Cache
    |
    +--- API
```

---

# Why Tracing Matters

Without tracing:

```text
Dashboard slow.
```

With tracing:

```text
Analytics query is slow.
```

Huge difference.

---

# Error Monitoring

Eventually you'll see:

```text
TypeError

Database timeout

Network failure

Memory exhaustion
```

You need centralized error tracking.

---

# Example Error

```ts
throw new Error(
    "Database offline"
);
```

---

# Error Report

```text
Error:
    Database offline

User:
    42

Route:
    /dashboard

Timestamp:
    12:03 PM

Stack trace:
    ...
```

---

# Visualizing Error Tracking

```text
Application
      |
Exception
      |
Error Service
      |
Dashboard
```

---

# Monitoring Server Actions

Example:

```tsx
"use server";

export async function createPost() {

    const start =
        Date.now();

    await db.post.create();

    console.log({

        action:
            "create_post",

        duration:
            Date.now() - start,

    });

}
```

---

# Monitoring Database Queries

Suppose:

```text
Page loads in:

5000ms
```

Question:

```text
Database?
Cache?
Network?
```

---

# Example

```text
Query:
    SELECT posts

Duration:
    3200ms
```

Problem found.

---

# Monitoring Cache Performance

Metrics:

```text
Cache hits

Cache misses

Invalidations

Rebuild times
```

---

# Visualizing Cache Behavior

Good:

```text
Request
    |
Cache Hit
    |
5ms
```

Bad:

```text
Request
    |
Cache Miss
    |
Database
    |
800ms
```

---

# Cache Hit Ratio

Formula:

```text
Hits
--------
Hits+Misses
```

---

Example:

```text
950 hits

50 misses
```

Ratio:

```text
95%
```

Excellent.

---

# Monitoring Server Components

Track:

```text
Render duration

Streaming duration

Suspense waits

Cache lookups
```

---

# Example Trace

```text
Homepage

Header:
    5ms

Posts:
    40ms

Comments:
    500ms

Notifications:
    1200ms
```

Problem:

```text
Notifications
```

---

# Monitoring Server Actions

Track:

```text
Execution time

Failures

Retries

Database writes
```

---

# Example

```text
createPost

Average:
    25ms

95th percentile:
    70ms

Failures:
    0.2%
```

---

# Performance Profiling

Ask:

```text
Why is this slow?
```

---

# Example

Bad:

```ts
for (const user of users) {

    await db.posts.findMany();

}
```

---

# Visualizing N+1 Queries

```text
Users
   |
   +--- Query
   |
   +--- Query
   |
   +--- Query
```

---

# Better

```ts
await db.user.findMany({

    include: {
        posts: true,
    },

});
```

---

# Memory Monitoring

Track:

```text
Heap usage

Garbage collection

Memory leaks
```

---

# Example

Normal:

```text
500MB
```

After one hour:

```text
3GB
```

You probably have:

```text
Memory leak.
```

---

# Authentication Monitoring

Track:

```text
Successful logins

Failed logins

Permission failures

Session creation
```

---

# Example Dashboard

```text
Successful logins:
    950

Failed logins:
    35

Permission failures:
    8
```

---

# Upload Monitoring

Track:

```text
Upload size

Upload time

Upload failures

Storage usage
```

---

# Search Monitoring

Track:

```text
Searches

Latency

No-result queries

Popular searches
```

---

# Notification Monitoring

Track:

```text
Sent

Failed

Delayed

Queued
```

---

# Production Debugging Workflow

Suppose:

```text
Dashboard slow.
```

Workflow:

```text
Check logs
      |
Check metrics
      |
Check traces
      |
Find bottleneck
      |
Fix
```

---

# Example Investigation

Problem:

```text
Dashboard:
4 seconds
```

---

Metrics:

```text
Database:
3.5 seconds
```

---

Tracing:

```text
Analytics query:
3.4 seconds
```

---

Fix:

```ts
"use cache";

cacheLife(
    "minutes"
);
```

Problem solved.

---

# Health Checks

Every application should expose:

```text
/health
```

---

Example:

```ts
export async function GET() {

    return Response.json({

        status:
            "healthy",

    });

}
```

---

# Readiness Checks

Example:

```text
Can database connect?

Can cache connect?

Can storage connect?
```

---

# Production Dashboard

Monitor:

```text
CPU

Memory

Errors

Requests

Latency

Database

Cache

Uploads

Authentication
```

---

# Alerts

Example:

```text
Error rate > 5%

Latency > 1000ms

Cache hit < 80%

Memory > 90%
```

Send:

```text
Email

Slack

Pager
```

---

# Folder Structure

```text
lib/

    logging/

    metrics/

    tracing/

    monitoring/
```

---

# Example

```text
logging/

    auth.ts

    uploads.ts

    posts.ts
```

---

# Observability Architecture

```text
Browser
    |
Application
    |
Logs
Metrics
Traces
    |
Dashboards
    |
Alerts
```

---

# The Professional Rule

Never ask:

```text
Why did it fail?
```

Ask:

```text
How will I know
why it failed?
```

---

# Exercises

## Exercise 1

Design logging for:

```text
User Login
```

---

## Exercise 2

Design metrics for:

```text
Dashboard
```

---

## Exercise 3

Design traces for:

```text
Publish Post
```

---

## Exercise 4

Design alerts for:

```text
Database Failure
```

---

# What You've Learned

You now understand:

✅ logs

✅ metrics

✅ traces

✅ error monitoring

✅ performance profiling

✅ cache monitoring

✅ authentication monitoring

✅ production debugging

✅ alerts

---

# Mental Model

Beginners think:

```text
Code
```

Professionals think:

```text
Systems
     |
Observability
     |
Evidence
     |
Engineering
```

Because you can't fix what you can't see.

---

# Part 23 Preview

In the next chapter we'll learn:

# Security Engineering for Next.js Applications

Including:

* authentication security
* authorization security
* cookies
* sessions
* CSRF
* XSS
* SQL injection
* SSRF
* file upload security
* secrets management
* rate limiting
* production hardening

This is where developers start becoming security-conscious engineers.
