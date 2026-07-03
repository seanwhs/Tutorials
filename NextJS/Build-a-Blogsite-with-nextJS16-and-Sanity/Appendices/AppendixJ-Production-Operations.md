# Appendix J — Observability, Logging, Monitoring, and Production Operations: Learning to See Distributed Systems

> **Goal of this appendix:** Transform GreyMatter Journal from a hobby project into a production-grade system by learning observability, logging, monitoring, tracing, alerting, and the operational principles that professional engineers use to understand systems they cannot directly observe.

---

# Introduction

One of the biggest differences between junior and senior engineers is this:

Junior engineers ask:

> "How do I build the system?"

Senior engineers ask:

> "How will I know when the system breaks?"

This distinction sounds small.

It is not.

Because once software enters production, programming becomes less about writing code and more about:

```text
Understanding reality.
```

---

# The Great Lie Of Development

When developing locally:

```text
npm run dev
```

everything appears simple:

```text
Browser
    │
    ▼

Next.js
    │
    ▼

Database
```

But production systems actually look like:

```text
Browser
    │
    ▼

CDN
    │
    ▼

Load Balancer
    │
    ▼

Edge Cache
    │
    ▼

Application
    │
    ▼

Server Actions
    │
    ▼

Sanity CDN
    │
    ▼

Sanity Content Lake
    │
    ▼

Authentication
    │
    ▼

Analytics
```

---

# The Fundamental Problem

Suppose a user says:

> "Your website is broken."

Question:

```text
Which part?
```

Answer:

```text
Nobody knows.
```

This is why observability exists.

---

# What Is Observability?

Many people think observability means:

```text
Logging.
```

This is incorrect.

Observability is:

```text
The ability to understand
the internal state
of a system
by observing
its external outputs.
```

---

# The Three Pillars

Modern observability consists of:

```text
Logs

Metrics

Traces
```

Diagram:

```text
        Observability

         /    |    \

        /     |     \

     Logs  Metrics  Traces
```

---

# Pillar 1 — Logs

Logs answer:

```text
What happened?
```

Example:

```typescript
console.log(
  "User created comment"
);
```

---

# Why console.log Is Bad

Suppose:

```text
1000 users
```

use your application.

You might generate:

```text
10 million
log entries.
```

Example:

```text
Hello

Hello

Hello

Hello

Error

Hello

Hello
```

Useful?

```text
No.
```

---

# Structured Logging

Instead:

```typescript
logger.info({

  event:
    "comment_created",

  userId:
    user.id,

  postId:
    post.id,

  timestamp:
    Date.now(),
});
```

Output:

```json
{
  "event":"comment_created",
  "userId":"123",
  "postId":"456"
}
```

---

# Install Pino

```bash
npm install pino
```

Create:

```text
lib/logger.ts
```

```typescript
import pino
from "pino";

export const logger =
  pino();
```

---

# Example Usage

```typescript
logger.info({

  event:
    "post_viewed",

  slug:
    post.slug,

  user:
    userId,
});
```

---

# Log Levels

Professional logging uses levels:

```text
TRACE

DEBUG

INFO

WARN

ERROR

FATAL
```

---

# Example

```typescript
logger.info(
  "Application started"
);

logger.warn(
  "Cache miss"
);

logger.error(
  error
);

logger.fatal(
  "Database unavailable"
);
```

---

# Pillar 2 — Metrics

Logs answer:

```text
What happened?
```

Metrics answer:

```text
How often?
```

Examples:

```text
Page Views

Requests

Errors

Latency

Memory

CPU
```

---

# Example Metrics

```text
Requests:
100,000/day

Errors:
42/day

Latency:
150ms
```

---

# Why Metrics Matter

Suppose:

```text
Error:
Database timeout
```

appears:

```text
1 time.
```

Problem?

```text
Probably not.
```

Suppose:

```text
10,000 times.
```

Problem?

```text
Definitely.
```

---

# Pillar 3 — Traces

Logs explain:

```text
Events.
```

Metrics explain:

```text
Numbers.
```

Traces explain:

```text
Journeys.
```

---

# Example Request

```text
User Request
      │
      ▼

Authentication
      │
      ▼

Server Action
      │
      ▼

Sanity
      │
      ▼

Cache
      │
      ▼

Response
```

A trace records:

```text
Everything.
```

---

# Example Trace

```text
GET /posts/react

├── auth()
│    15ms
│
├── sanity()
│    120ms
│
├── cache()
│    5ms
│
└── render()
     30ms
```

---

# Suddenly We Discover

The problem isn't:

```text
Next.js.
```

The problem is:

```text
Sanity latency.
```

---

# OpenTelemetry

Modern observability standards use:

```text
OpenTelemetry
```

Install:

```bash
npm install @opentelemetry/api
```

---

# Creating A Span

```typescript
import {
  trace,
} from
"@opentelemetry/api";

const tracer =
  trace.getTracer(
    "greymatter"
  );
```

---

# Example Trace

```typescript
await tracer
  .startActiveSpan(

    "get-post",

    async span => {

      await getPost();

      span.end();
    }
  );
```

---

# Error Tracking

Errors deserve special treatment.

Install:

```bash
npm install @sentry/nextjs
```

---

# Configure Sentry

```bash
npx @sentry/wizard@latest
```

This automatically adds:

```text
Error Tracking

Performance

Tracing

Session Replay
```

---

# Example Error

```typescript
try {

  await save();

} catch (error) {

  Sentry.captureException(
    error
  );
}
```

---

# Alerting

Observability without alerting is:

```text
Archaeology.
```

Alerts answer:

```text
Wake me up
when reality changes.
```

---

# Example Alerts

```text
CPU > 90%

Error Rate > 5%

Latency > 1 sec

Database Down
```

---

# Service Level Indicators

SLI:

```text
What we measure.
```

Example:

```text
99.95%
successful requests.
```

---

# Service Level Objectives

SLO:

```text
What we promise.
```

Example:

```text
99.9% uptime.
```

---

# Error Budgets

Suppose:

```text
99.9%
uptime
```

Allowed downtime:

```text
8.76 hours/year
```

This becomes:

```text
Your error budget.
```

---

# Golden Signals

Google SRE recommends monitoring:

```text
Latency

Traffic

Errors

Saturation
```

---

# Latency

Question:

```text
How long
does work take?
```

Example:

```text
Homepage:
120ms

Posts:
300ms

Search:
500ms
```

---

# Traffic

Question:

```text
How much work
exists?
```

Example:

```text
50,000 requests/hour
```

---

# Errors

Question:

```text
How often
do we fail?
```

Example:

```text
2%
error rate
```

---

# Saturation

Question:

```text
How close
are we
to breaking?
```

Example:

```text
CPU:
95%

Memory:
98%
```

---

# Health Checks

Create:

```text
app/api/health/route.ts
```

```typescript
export async function
GET() {

  return Response
    .json({

      status:
        "healthy",

      timestamp:
        Date.now(),
    });
}
```

---

# Readiness Checks

Example:

```typescript
const sanity =
  await client.fetch(
    "*[_type=='post'][0]"
  );

return Response
  .json({

    healthy:
      !!sanity,
  });
```

---

# Incident Response

Production systems fail.

The question is never:

```text
Will failure happen?
```

The question is:

```text
How quickly
can we understand it?
```

---

# Example Incident Timeline

```text
09:00
Deploy

09:02
Errors increase

09:03
Alert fires

09:05
Engineer notified

09:10
Rollback

09:15
System recovered
```

---

# Postmortems

Professional engineers ask:

```text
How did the
system fail?
```

They do not ask:

```text
Who failed?
```

---

# Example Postmortem

```text
Incident:
Comments unavailable

Root Cause:
Sanity token expired

Contributing Factors:
No monitoring

Action Items:
Add monitoring
Add alerts
Rotate tokens
```

---

# Dashboards

A production dashboard might display:

```text
Requests/sec

Response Time

Error Rate

Cache Hit Rate

Memory Usage

CPU Usage

Database Latency

Sanity Latency
```

---

# The GreyMatter Dashboard

```text
Users
   │
   ▼

Requests
   │
   ▼

Authentication
   │
   ▼

Server Actions
   │
   ▼

Sanity
   │
   ▼

Caching
   │
   ▼

Search
```

---

# The Hidden Architecture

When someone loads GreyMatter Journal:

```text
Browser
    │
    ▼

CDN
    │
    ▼

Next.js
    │
    ▼

Server Components
    │
    ▼

Server Actions
    │
    ▼

Clerk
    │
    ▼

Sanity
    │
    ▼

Cache
    │
    ▼

Analytics
```

Observability attempts to reconstruct:

```text
Reality
```

from:

```text
Evidence.
```

---

# Wait...

Does This Look Familiar?

We've discovered:

```text
State Trees

Trust Trees

Identity Trees

Failure Trees

Execution Trees

Cache Trees

Knowledge Trees

Time Trees

Meaning Trees
```

Observability introduces:

```text
Reality Trees
```

because every production system ultimately asks:

```text
What actually happened?
```

---

# The Deep Secret Of Observability

Most beginners think:

```text
Observability
             =
Logging
```

Professional engineers think:

```text
Observability
             =
Understanding
             Systems
             That
             Cannot
             Be
             Directly
             Observed
```

---

# The Deep Secret Of Operations

Programming builds:

```text
Potential.
```

Operations discovers:

```text
Reality.
```

---

# Mental Model To Remember Forever

Beginners think:

```text
The system
          =
The code.
```

Professional engineers think:

```text
The system
          =
Code

          +
Infrastructure

          +
Humans

          +
Networks

          +
Time

          +
Failure
```

Observability reveals one of the deepest truths in software engineering:

```text
We never directly
observe systems.

We only observe
evidence

and attempt to
reconstruct reality.
```
