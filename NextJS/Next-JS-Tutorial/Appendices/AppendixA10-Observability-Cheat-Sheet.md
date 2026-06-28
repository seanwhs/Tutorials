# Appendix A10 — Next.js 16 Observability, Logging, and Monitoring Cheat Sheet

## The Complete Guide to Understanding What Your Application Is Actually Doing

> **Purpose:** This appendix is the definitive reference for observability in Next.js 16 applications. Production systems do not fail because developers lack features. They fail because developers cannot see what the system is doing.

---

# Introduction

The biggest misconception beginners have is:

```text
My application works.
```

Professional engineers ask:

```text
How do I know
it works?
```

Because software engineering is not merely:

```text
Building systems.
```

It is also:

```text
Observing systems.
```

---

# The Three Pillars of Observability

Modern observability consists of:

```text
1. Logs

2. Metrics

3. Traces
```

---

# Visualizing

```text
                Observability

                      |

      +---------------+---------------+

      |               |               |

     Logs          Metrics         Traces
```

---

# Logs

Logs answer:

```text
What happened?
```

Example:

```text
User logged in.

Payment failed.

Cache invalidated.

Database timeout.
```

---

# Metrics

Metrics answer:

```text
How much?
```

Example:

```text
CPU usage

Memory usage

Response times

Request counts

Error rates
```

---

# Traces

Traces answer:

```text
Where?
```

Example:

```text
Browser
    |
Server
    |
Database
    |
Cache
```

---

# Why Observability Matters

Without observability:

```text
Application
      |
Something broke
      |
Panic
```

---

With observability:

```text
Application
      |
Alert
      |
Trace
      |
Root Cause
      |
Fix
```

---

# Development Logging

Simplest logging:

```ts
console.log(
  "Hello"
);
```

---

# Problem

This produces:

```text
Unstructured noise.
```

---

# Better

```ts
console.log({

  event:
    "user-login",

  userId:
    user.id,

});
```

---

# Best

```ts
logger.info({

  event:
    "user-login",

  userId:
    user.id,

  timestamp:
    Date.now(),

});
```

---

# Structured Logging

Bad:

```ts
console.log(
  "User logged in"
);
```

---

Good:

```ts
console.log({

  event:
    "login",

  userId:
    123,

  success:
    true,

});
```

---

# Why Structured Logs?

Because machines can search:

```json
{
  "event": "login",
  "userId": 123,
  "success": true
}
```

---

But not:

```text
"Bob maybe logged in"
```

---

# Log Levels

Most systems use:

```text
DEBUG

INFO

WARN

ERROR

FATAL
```

---

# DEBUG

Use for:

```text
Developer debugging.
```

Example:

```ts
logger.debug({

  query:
    sql,

});
```

---

# INFO

Use for:

```text
Expected events.
```

Example:

```ts
logger.info({

  event:
    "order-created",

});
```

---

# WARN

Use for:

```text
Recoverable problems.
```

Example:

```ts
logger.warn({

  cache:
    "miss",

});
```

---

# ERROR

Use for:

```text
Failures.
```

Example:

```ts
logger.error({

  error:
    err.message,

});
```

---

# FATAL

Use for:

```text
Application crashes.
```

---

# Example Logger

```ts
export const logger = {

  info(data: unknown) {
    console.log(data);
  },

  warn(data: unknown) {
    console.warn(data);
  },

  error(data: unknown) {
    console.error(data);
  },

};
```

---

# Logging Server Actions

Example:

```ts
"use server";

export async function
createPost() {

  logger.info({

    event:
      "create-post",

  });

}
```

---

# Logging Route Handlers

Example:

```ts
export async function
POST() {

  logger.info({

    route:
      "/api/posts",

  });

}
```

---

# Logging Database Calls

Example:

```ts
const start =
  Date.now();

await db.post
  .findMany();

logger.info({

  duration:
    Date.now() - start,

});
```

---

# Visualizing

```text
Request
    |
Database
    |
57ms
```

---

# Request IDs

Generate unique IDs:

```ts
const requestId =
  crypto.randomUUID();
```

---

Attach:

```ts
logger.info({

  requestId,

});
```

---

# Visualizing

```text
Request

   |

Request ID

   |

Everything
```

---

# Correlation IDs

Example:

```text
request-123

    |

API

    |

Database

    |

Cache
```

---

# Error Logging

Example:

```ts
try {

  await save();

} catch (error) {

  logger.error({

    error,

  });

}
```

---

# Stack Traces

Example:

```ts
logger.error({

  stack:
    error.stack,

});
```

---

# Performance Monitoring

Track:

```text
Response time

Database time

Cache hits

Cache misses
```

---

# Measuring Duration

Example:

```ts
const start =
  performance.now();

await operation();

const duration =
  performance.now()
  - start;
```

---

# Example

```ts
logger.info({

  operation:
    "database",

  duration,

});
```

---

# Cache Metrics

Track:

```text
Cache hits

Cache misses

Invalidations

Revalidations
```

---

# Example

```ts
logger.info({

  cache:
    "hit",

  tag:
    "posts",

});
```

---

# Database Metrics

Track:

```text
Query count

Duration

Errors

Connections
```

---

# API Metrics

Track:

```text
Requests

Latency

Errors

Status codes
```

---

# Example

```ts
logger.info({

  route:
    "/api/posts",

  status:
    200,

  duration:
    32,

});
```

---

# User Metrics

Track:

```text
Signups

Logins

Purchases

Searches
```

---

# Business Metrics

Track:

```text
Revenue

Orders

Conversions

Retention
```

---

# Health Checks

Create:

```text
/api/health
```

---

Example:

```ts
export async function
GET() {

  return Response
    .json({

      status:
        "ok",

    });

}
```

---

# Better Health Check

```ts
export async function
GET() {

  try {

    await db.$queryRaw`
      SELECT 1
    `;

    return Response
      .json({

        status:
          "healthy",

      });

  } catch {

    return Response
      .json(

        {
          status:
            "failed",
        },

        {
          status: 500,
        }

      );

  }

}
```

---

# Visualizing

```text
Health Check
       |
Database
       |
Response
```

---

# Tracing

Tracing tracks:

```text
Request
     |
Service
     |
Database
     |
Cache
```

---

# Example Trace

```text
Request
    |
    +--- Auth
    |
    +--- Database
    |
    +--- Cache
    |
    +--- Response
```

---

# Slow Query Detection

Example:

```ts
if (duration > 1000) {

  logger.warn({

    slowQuery:
      true,

  });

}
```

---

# Monitoring Server Actions

Track:

```text
Execution time

Success rate

Failure rate
```

---

Example:

```ts
logger.info({

  action:
    "create-post",

  duration,

});
```

---

# Monitoring Cache

Track:

```text
cacheTag()

cacheLife()

revalidateTag()

updateTag()
```

---

Example:

```ts
logger.info({

  cache:
    "revalidated",

  tag:
    "posts",

});
```

---

# Monitoring Route Handlers

Example:

```ts
logger.info({

  route:
    "/api/webhook",

  duration,

  status:
    200,

});
```

---

# Alerting

Examples:

```text
500 errors

High latency

Database failures

Memory exhaustion
```

---

# Error Thresholds

Example:

```text
> 5% failures
```

Trigger:

```text
Alert.
```

---

# Latency Thresholds

Example:

```text
> 1000ms
```

Trigger:

```text
Warning.
```

---

# Logging Architecture

```text
Application
      |
Structured Logs
      |
Log Aggregation
      |
Search
      |
Dashboard
```

---

# Metrics Architecture

```text
Application
      |
Metrics
      |
Aggregation
      |
Dashboard
      |
Alerts
```

---

# Trace Architecture

```text
Request
     |
Span
     |
Span
     |
Span
     |
Visualization
```

---

# Production Checklist

Monitor:

```text
✓ Requests

✓ Errors

✓ Latency

✓ Database

✓ Cache

✓ Memory

✓ CPU

✓ Disk

✓ Queue

✓ Revenue
```

---

# Common Beginner Mistakes

---

## Mistake 1

Using only:

```ts
console.log();
```

---

## Mistake 2

Logging secrets.

---

## Mistake 3

Not logging failures.

---

## Mistake 4

Not measuring performance.

---

## Mistake 5

Not creating health checks.

---

## Mistake 6

Ignoring cache metrics.

---

## Mistake 7

Waiting until production to add monitoring.

---

# Observability Decision Tree

Need:

```text
What happened?
```

Use:

```text
Logs
```

---

Need:

```text
How much?
```

Use:

```text
Metrics
```

---

Need:

```text
Where?
```

Use:

```text
Traces
```

---

Need:

```text
Is system alive?
```

Use:

```text
Health checks
```

---

# The Complete Observability Pipeline

```text
User
    |
Request
    |
Application
    |
Logs
    |
Metrics
    |
Traces
    |
Alerts
    |
Engineers
```

---

# Mental Model

Beginners think:

```text
Monitoring
=
Debugging.
```

Professional engineers think:

```text
Monitoring
=
The ability
to explain
every decision
your system
has ever made.
```

Because in production:

```text
If you cannot
observe it,

you cannot
operate it.
```
