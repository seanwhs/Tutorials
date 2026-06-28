# Next.js 16 for Absolute Beginners

# Part 42 — Observability, Logging, Monitoring, Tracing, and Production Operations

> **Goal of this lesson:** Learn how to operate a production-grade Next.js 16 application using structured logging, metrics, monitoring, distributed tracing, health checks, alerting, and observability engineering.

---

# The Fourth Biggest Lie in Software

The first lie:

> Users wait.

The second lie:

> Everything happens immediately.

The third lie:

> Users refresh pages.

The fourth lie:

> If the tests pass, the application works.

Unfortunately:

```text
Production
    !=
Development
```

---

# The Production Question

Beginners ask:

```text
Does it work?
```

Professional engineers ask:

```text
How do I know
if it stops working?
```

---

# What Is Observability?

Observability means:

> Understanding what your system is doing from the outside.

---

# The Three Pillars

Modern observability consists of:

```text
Observability

    |
    +---- Logs

    |
    +---- Metrics

    |
    +---- Traces
```

---

# Visualizing Observability

```text
                Request
                    |
                    V
             Application
                    |
        +-----------+-----------+
        |           |           |
        V           V           V
      Logs       Metrics      Traces
```

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ Structured logging
✓ Request tracing
✓ Error monitoring
✓ Metrics
✓ Health checks
✓ OpenTelemetry
✓ Dashboards
✓ Alerting
✓ SLOs
✓ Production debugging
```

---

# Part 1 — Logging

---

# Beginner Logging

```ts
console.log(
  "User created"
);
```

---

# Problems

```text
❌ No timestamp
❌ No request ID
❌ No user ID
❌ No severity
❌ No context
```

---

# Professional Logging

Instead:

```json
{
  "level": "info",

  "timestamp":
    "2026-06-29",

  "requestId":
    "req_123",

  "userId":
    "user_456",

  "message":
    "User created"
}
```

---

# Why JSON Logs?

Because humans read:

```text
Console
```

but systems read:

```text
JSON
```

---

# Step 1 — Create Logger

```text
lib/logger.ts
```

---

```ts
export function
log(

  level: string,

  message: string,

  metadata = {}

) {

  console.log(

    JSON.stringify({

      timestamp:
        new Date(),

      level,

      message,

      ...metadata,

    })

  );

}
```

---

# Usage

```ts
log(

  "info",

  "User registered",

  {

    userId:
      user.id,

  }

);
```

---

# Example Output

```json
{
  "level": "info",

  "message":
    "User registered",

  "userId":
    "123"
}
```

---

# Log Levels

```text
TRACE

DEBUG

INFO

WARN

ERROR

FATAL
```

---

# Visualizing Severity

```text
INFO
  |
WARN
  |
ERROR
  |
FATAL
```

---

# Part 2 — Request IDs

---

# Problem

Suppose:

```text
100,000 requests
```

occur.

Which log belongs to which request?

---

# Solution

Generate:

```text
requestId
```

---

Example:

```ts
const requestId =

  crypto.randomUUID();
```

---

# Log Everything

```ts
log(

  "info",

  "Page loaded",

  {

    requestId,

  }

);
```

---

# Visualizing

```text
Request

   |
requestId

   |
All Logs
```

---

# Example

```text
req123
   |
   +--- login
   |
   +--- db
   |
   +--- cache
   |
   +--- render
```

---

# Part 3 — Error Logging

Bad:

```ts
catch(error) {

  console.log(
    error
  );

}
```

---

Better:

```ts
catch(error) {

  log(

    "error",

    error.message,

    {

      stack:
        error.stack,

    }

  );

}
```

---

# Capture

```text
✓ Message
✓ Stack trace
✓ Request ID
✓ User ID
✓ Route
✓ Timestamp
```

---

# Part 4 — Health Checks

Create:

```text
app/api/health/route.ts
```

---

```ts
export async function
GET() {

  return Response
    .json({

      status:
        "healthy",

    });

}
```

---

# Why?

Load balancers ask:

```text
Are you alive?
```

---

# Example

```text
GET

/api/health
```

returns:

```json
{
  "status":
    "healthy"
}
```

---

# Advanced Health Checks

```ts
export async function
GET() {

  await db.$queryRaw`
    SELECT 1
  `;

  return Response
    .json({

      database:
        "ok",

      cache:
        "ok",

    });

}
```

---

# Visualizing

```text
Health Check

     |
     +---- Database

     |
     +---- Cache

     |
     +---- Storage
```

---

# Part 5 — Metrics

Logs tell us:

```text
What happened?
```

Metrics tell us:

```text
How often?
```

---

# Examples

```text
Requests/sec

Latency

Errors/sec

Memory

CPU

Cache hits
```

---

# Example Counter

```ts
let requests = 0;

requests++;
```

---

# Example Metrics

```text
requests_total

errors_total

cache_hits

cache_misses
```

---

# Visualizing Metrics

```text
Requests

200
300
500
700
```

---

# Part 6 — Latency Measurement

Measure:

```ts
const start =

  performance.now();
```

---

Later:

```ts
const duration =

  performance.now()
  - start;
```

---

Log:

```ts
log(

  "info",

  "Request",

  {

    duration,

  }

);
```

---

# Why?

Users experience:

```text
Latency
```

not:

```text
Code quality.
```

---

# Part 7 — Distributed Tracing

Suppose:

```text
Browser
   |
API
   |
Database
   |
Redis
   |
Queue
```

fails.

Where?

---

# Solution

Tracing.

---

# Visualizing Trace

```text
Request

   |
   +---- API
   |
   +---- Database
   |
   +---- Cache
   |
   +---- Queue
```

---

# Example Trace

```json
{
  "traceId":
    "abc",

  "span":
    "database",

  "duration":
    14
}
```

---

# What Is A Span?

A span represents:

```text
One operation.
```

Example:

```text
HTTP request

Database query

Cache lookup

Queue processing
```

---

# Visualizing

```text
Trace

    |
    +---- Span

    |
    +---- Span

    |
    +---- Span
```

---

# Part 8 — OpenTelemetry

Modern systems use:

OpenTelemetry

---

# Install

```bash
npm install @opentelemetry/api
```

---

# Example

```ts
const span =

  tracer.startSpan(
    "database"
  );

await db.post.findMany();

span.end();
```

---

# Visualizing

```text
Request
   |
Trace
   |
Spans
```

---

# Part 9 — Error Monitoring

Production systems use:

```text
Sentry

Bugsnag

Datadog

New Relic
```

---

# Example

```ts
try {

  dangerous();

}

catch(error) {

  captureException(
    error
  );

}
```

---

# Why?

Because users rarely report bugs.

---

# Part 10 — Dashboards

Raw metrics are useless.

Create dashboards.

---

# Example Dashboard

```text
Requests/sec: 3200

Latency: 112ms

Error rate: 0.4%

CPU: 54%

Memory: 67%
```

---

# Visualizing

```text
Dashboard

     |
     +---- Traffic

     |
     +---- Errors

     |
     +---- Latency
```

---

# Part 11 — Alerting

Suppose:

```text
Error rate:
40%
```

---

You want:

```text
ALERT
```

not:

```text
Customer complaint.
```

---

# Examples

Alert if:

```text
Latency > 500ms

Error rate > 5%

CPU > 90%

Memory > 95%
```

---

# Part 12 — SLIs

SLI means:

```text
Service Level Indicator
```

Examples:

```text
Latency

Availability

Error rate
```

---

# Example

```text
Availability

99.95%
```

---

# Part 13 — SLOs

SLO means:

```text
Service Level Objective
```

Example:

```text
99.9% uptime
```

---

# Visualizing

```text
Reality:
99.95%

Target:
99.9%
```

Success.

---

# Part 14 — Error Budgets

If your SLO:

```text
99.9%
```

fails:

```text
0.1%
```

of the time.

---

This means:

```text
43 minutes/month
```

of downtime.

---

# Why Error Budgets?

Because:

```text
100%
uptime
```

is fantasy.

---

# Part 15 — Production Incident Example

Alert:

```text
Latency:
2000ms
```

---

Investigate:

```text
Dashboard
     |
Trace
     |
Database
     |
Slow Query
```

---

Fix:

```sql
CREATE INDEX
```

---

# Incident Flow

```text
Alert
   |
Investigate
   |
Trace
   |
Fix
   |
Verify
```

---

# Part 16 — Observability Architecture

```text
                 Browser
                     |
                  Next.js
                     |
        +------------+------------+
        |            |            |
        V            V            V
      Logs       Metrics      Traces
        |            |            |
        +------------+------------+
                     |
                     V
              Monitoring
```

---

# Production Stack

Typical stack:

```text
Logs:
ELK / Loki

Metrics:
Prometheus

Dashboards:
Grafana

Tracing:
OpenTelemetry

Errors:
Sentry
```

---

# Part 17 — Next.js Production Checklist

Always monitor:

```text
✓ Request latency

✓ Error rate

✓ Cache hit ratio

✓ Database latency

✓ Queue depth

✓ Worker failures

✓ CPU

✓ Memory

✓ Disk

✓ Network
```

---

# What We've Built

```text
✓ Structured logging

✓ Request IDs

✓ Error monitoring

✓ Health checks

✓ Metrics

✓ Tracing

✓ OpenTelemetry

✓ Dashboards

✓ Alerts

✓ SLOs
```

---

# Observability Philosophy

Beginners build:

```text
Applications.
```

Professional engineers build:

```text
Applications they can debug.
```

Because the question isn't:

```text
Will production fail?
```

The question is:

```text
How quickly can we
understand why?
```

---

# Exercises

## Exercise 1

Build:

```text
Request ID middleware.
```

---

## Exercise 2

Measure:

```text
Database latency.
```

---

## Exercise 3

Create:

```text
Health dashboard.
```

---

## Exercise 4

Implement:

```text
Error alerts.
```

---

# Mental Model

Beginners think:

```text
Software
     =
Code
```

Professional engineers think:

```text
Software
     =
Code
     +
Visibility
```

Because invisible systems cannot be operated.

---

# Part 43 Preview

In the next chapter we'll build:

# Testing, Quality Assurance, and Engineering Confidence

Including:

```text
✓ Unit testing
✓ Integration testing
✓ E2E testing
✓ Mocking
✓ Test doubles
✓ Contract testing
✓ Performance testing
✓ Security testing
✓ CI pipelines
✓ Engineering confidence
```

This is where Next.js becomes an engineering discipline rather than merely a framework.
