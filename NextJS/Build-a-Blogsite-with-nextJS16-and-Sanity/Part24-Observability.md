# GreyMatter Journal

# Part 24 — Observability, Logging, Monitoring, and the Architecture of Seeing Invisible Systems

> **Goal of this lesson:** Add analytics, logging, monitoring, and observability to GreyMatter Journal while learning why software engineering eventually becomes the discipline of understanding invisible systems operating at planetary scale.

***

# Congratulations

GreyMatter Journal is now:

```text
✓ Deployed
✓ Public
✓ Secure
✓ Cached
✓ Distributed
✓ Interactive
```

Unfortunately, we now have a terrifying new problem:

> We have absolutely no idea what our software is doing.

If something breaks at 3:14 AM, you currently learn about it the same way your users do: by suffering.

***

# The Beginner Mental Model

Most beginners think:

```text
Write Code
    ↓
Deploy
    ↓
Done
```

Professional engineers know:

```text
Write Code
    ↓
Deploy
    ↓
Observe
    ↓
Debug
    ↓
Fix
    ↓
Observe Again
```

Shipping is not the end of the process; it is the beginning of a new feedback loop.

***

# Imagine This Scenario

At:

```text
3:14 AM
```

your phone alerts:

```text
ERROR RATE:
500%
```

Immediate questions:

```text
What broke?

When?

Where?

Who is affected?

Why?

Is it still happening?
```

If you cannot answer these questions, then:

```text
You do not control
your software.
```

You are operating a black box.

***

# Software Is Invisible

Suppose you're a mechanic.

You can inspect:

```text
Engine
Tires
Brakes
Fuel
```

Suppose you're a surgeon.

You can inspect:

```text
Heart
Blood
Organs
```

But software?

```text
Request
    ↓
Memory
    ↓
Network
    ↓
CPU
    ↓
Database
    ↓
Cache
```

All invisible.

There are no physical parts to stare at; only behavior to infer.

***

# This Is Why Observability Exists

Observability answers:

> What is happening inside a system we cannot directly see?

We instrument the system so its internal state can be inferred from the signals it emits.

***

# The Three Pillars of Observability

Modern observability is commonly described as three pillars:

```text
Metrics

Logs

Traces
```

Diagram:

```text
Observability

       │

       ├── Metrics
       │
       ├── Logs
       │
       └── Traces
```

Each pillar answers a different kind of question about the system.

***

# Pillar 1 — Metrics

Metrics answer:

```text
How much?
```

Examples:

```text
Users:
500

Errors:
12

CPU:
40%

Requests:
50/sec
```

Metrics are aggregated, numeric signals over time: they show trends, outliers, and thresholds.

***

# Metrics Are Measurements

Real-world measurements:

```text
Temperature:
35°C

Heart Rate:
72 bpm

Speed:
80 km/h
```

Software metrics work the same way:

```text
Latency:
120ms

Memory:
512MB

Errors:
3%
```

They compress complex behavior into time series you can chart, alert on, and reason about.

***

# Adding Analytics

We’ll start with a simple form of metrics: page analytics.

We’ll use:

```text
Vercel Analytics
```

Install:

```bash
npm install @vercel/analytics
```

This library automatically collects high-level metrics such as page views and performance without you wiring up every event manually.

***

# Hooking Analytics into the Root Layout

Open:

```text
app/layout.tsx
```

Add:

```typescript
import { Analytics } from "@vercel/analytics/react";
```

Then:

```tsx
<body>
  {children}
  <Analytics />
</body>
```

With this single component, your app starts emitting basic metrics about traffic and performance.

***

# Wait…

That's It?

Yes.

Because:

```text
Analytics
       =
Instrumentation
```

You are not changing behavior; you are adding measurement.

***

# What Is Instrumentation?

Suppose you install a:

```text
Speedometer
```

in a car.

You didn’t change:

```text
Engine
```

You added:

```text
Measurement
```

Diagram:

```text
System

   │

   ▼

Observe

   │

   ▼

Measure
```

Instrumentation is about attaching sensors, not changing how the machine works.

***

# Pillar 2 — Logs

Metrics tell us:

```text
Something broke.
```

Logs tell us:

```text
What broke.
```

They capture discrete events and contextual details that metrics alone cannot express.

***

# Adding Logs

Create:

```text
lib/logger.ts
```

Add:

```typescript
export function log(
  message: string,
  metadata?: unknown
) {
  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      message,
      metadata,
    })
  );
}
```

We’re wrapping `console.log` with structure so logs are machine-readable, not just human-readable.

***

# Why Structured Logs?

Bad log:

```text
Something happened
```

Good log:

```json
{
  "timestamp": "2026-07-03T12:34:56.789Z",
  "event": "comment_created",
  "user": "123",
  "post": "456"
}
```

Structured logs are:

- easier to search,
- easier to filter,
- easier to aggregate.

They turn log streams into queryable data.

***

# Logging Comments

Open:

```text
app/api/comments/route.ts
```

Add:

```typescript
import { log } from "@/lib/logger";
```

Then:

```typescript
log("comment_created", {
  author: data.get("author"),
  post: data.get("postId"),
});
```

Now every comment creation records a structured event in your logs.

***

# Logs Are History

Most beginners think:

```text
Logs
    =
Debugging
```

Actually:

```text
Logs
    =
Historical Record
```

They tell you:

```text
What happened?

In what order?

With what data?

Under what conditions?
```

They are the system’s diary.

***

# Pillar 3 — Traces

Suppose a page loads slowly.

Question:

```text
Where?
```

Was it:

```text
Browser?

Next.js?

Sanity?

Database?

CDN?
```

Metrics say “something is slow”; logs say “some things happened”; traces tell you **where** the time was spent across services.

***

# What Is a Trace?

A trace records the:

```text
Request Journey
```

Diagram:

```text
Browser
    │
    ▼

Next.js
    │
    ▼

Sanity
    │
    ▼

Database
    │
    ▼

Response
```

Each step is a “span” with timing and metadata; together they form a timeline.

***

# Example Trace

```text
Request

   │

   ▼

Middleware
    3ms

   ▼

Authentication
    10ms

   ▼

Sanity
    400ms

   ▼

Rendering
    50ms
```

Immediately we see:

```text
Sanity
     =
Bottleneck
```

Traces turn “the app is slow” into “this specific dependency is slow”.

***

# Distributed Tracing

Modern systems are distributed by default.

Example:

```text
Browser
    │
    ▼

API
    │
    ▼

Database
    │
    ▼

Email Service
    │
    ▼

Analytics
```

Diagram:

```text
Request

   │

   ├── API
   │
   ├── Database
   │
   ├── Email
   │
   └── Analytics
```

A trace reconstructs the **entire system execution** across these components.

***

# How Traces Stay Connected

Each request receives a:

```text
Trace ID
```

Example:

```text
trace:
abc123
```

Then:

```text
Browser:
abc123

API:
abc123

Database:
abc123

Email:
abc123
```

Everything related to that request carries the same ID, so you can stitch the story together end-to-end.

***

# Metrics + Logs + Traces Together

Suppose:

```text
Error Rate:
25%
```

Metrics tell us:

```text
There is a problem.
```

Logs tell us:

```text
The database timed out.
```

Traces tell us:

```text
Exactly where
the timeout happened
in the call chain.
```

The three pillars form a multi-angle view of the same reality.

***

# Monitoring

Monitoring asks:

```text
Is the system healthy?
```

Examples:

```text
CPU usage

Memory usage

Latency

Error rates

Traffic volume
```

Monitoring is observability on a schedule with thresholds and alerts.

***

# Service Level Indicators (SLIs)

Professional systems measure:

```text
Availability

Latency

Reliability
```

Example:

```text
Availability:
99.9%
```

This means:

```text
0.1% of requests
are allowed to fail
or be unavailable.
```

SLIs quantify what “good enough” means.

***

# 99.9% Sounds Great… Or Does It?

```text
99.9%
```

still allows:

```text
~43 minutes
of downtime
per month.
```

Meanwhile:

```text
99.999%
```

(“five nines”) allows:

```text
~26 seconds
of downtime
per month.
```

Small percentages hide big consequences at scale.

***

# Error Budgets

Suppose your SLO is:

```text
99.9%
```

Then your:

```text
Error Budget:
0.1%
```

Diagram:

```text
Reliability Budget

        │

        ├── Success
        │
        └── Failure
```

You can “spend” this error budget on:

```text
New features
Risky changes
Infrastructure experiments
```

If you exhaust it, you pause risky work and stabilize.

***

# Alerting

Suppose:

```text
Error Rate > 5%
```

Then:

```text
Alert Engineer
```

Diagram:

```text
Metric
   │
   ▼

Threshold
   │
   ▼

Alert
```

Alerts turn metric thresholds into human attention.

***

# The Problem with Bad Alerts

Bad alerts:

```text
Everything broke!!!
```

Good alerts:

```text
Service:
comments-api

Symptom:
Database timeout

Scope:
25% of requests

Started:
03:14 UTC
```

Good alerts are actionable; they tell you **where to look** and **how urgent** it is.

***

# Dashboards

Professional systems build dashboards showing:

```text
Requests per second

Latency distributions

Error rates

Active users

Revenue or business KPIs
```

Diagram:

```text
Traffic:
██████

Errors:
██

Latency:
████
```

Dashboards give teams a shared visual language for system health.

***

# Why Observability Is Hard

Suppose:

```text
1 million requests/day
```

Each request generates:

```text
10 logs
20 metrics
1 trace
```

Result:

```text
10 million logs
20 million metric points
1 million traces
```

Observability itself becomes a big-data problem.

***

# Observability Systems Observe Themselves

Ironically:

```text
Monitoring
        │
        ▼

Needs Monitoring
```

Diagram:

```text
Application
      │
      ▼

Monitoring
      │
      ▼

Monitoring Monitor
```

If your monitoring fails silently, you are blind again.

***

# The Hidden Architecture of a Single Request

When a user opens an article:

```text
Browser
    │
    ▼

Analytics Event
    │
    ▼

Middleware Log
    │
    ▼

Authentication Trace
    │
    ▼

Sanity Query
    │
    ▼

Database Metrics
    │
    ▼

Response
```

Simultaneously, your system is emitting:

```text
Metrics
Logs
Traces
```

for this single request.

***

# Observation Trees

We’ve already discovered:

```text
React Trees

Failure Trees

Reality Trees

Trust Trees

State Trees

Cache Trees

Deployment Trees
```

Now we discover:

```text
Observation Trees
```

because every complex system eventually requires:

```text
Systems
for observing
systems.
```

Each “tree” stacks on top of the others; observability is how you navigate the forest.

***

# The Deep Secret of Production Engineering

Most beginners think:

```text
Software
       =
Writing Code
```

Professional engineers think:

```text
Software
       =
Understanding
       Running Systems
```

Key questions:

```text
What happened?

Why?

Where?

How often?

How bad?

Can it happen again?

Can we detect it sooner next time?
```

Production engineering is as much about **explanation** as it is about **execution**.

***

# Mental Model To Remember Forever

Beginners think:

```text
Debugging
         =
Fixing Bugs
```

Professional engineers think:

```text
Debugging
         =
Building
         Explanations
```

Or more generally:

```text
Observability
             =
The Science
             Of Making
             Invisible
             Systems
             Visible
```

Once you understand this, monitoring, analytics, telemetry, tracing, logging, debugging, and even AI observability all become manifestations of the same fundamental discipline.

***

# Up Next

In **Part 25**, we'll refactor GreyMatter Journal into a production-grade architecture while exploring:

- software architecture,
- modularity,
- separation of concerns,
- dependency inversion,
- system boundaries,

and why software engineering is ultimately the discipline of managing complexity.
