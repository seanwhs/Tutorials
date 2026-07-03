# GreyMatter Journal

# Part 24 — Observability, Logging, Monitoring, and the Architecture of Seeing Invisible Systems

> **Goal of this lesson:** Add analytics, logging, monitoring, and observability to GreyMatter Journal while learning why software engineering eventually becomes the discipline of understanding invisible systems operating at planetary scale.

---

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

---

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

---

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

Questions immediately appear:

```text
What broke?

When?

Where?

Who is affected?

Why?

Is it still happening?
```

If you cannot answer these questions:

```text
You do not control
your software.
```

---

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

---

# This Is Why Observability Exists

Observability answers:

> What is happening inside a system we cannot directly see?

---

# Three Pillars Of Observability

Modern observability consists of:

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

---

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

---

# Metrics Are Measurements

Example:

```text
Temperature:
35°C

Heart Rate:
72 bpm

Speed:
80 km/h
```

Software metrics work identically:

```text
Latency:
120ms

Memory:
512MB

Errors:
3%
```

---

# Adding Analytics

We'll use:

Vercel Analytics.

Install:

```bash
npm install @vercel/analytics
```

---

# Open Root Layout

Open:

```text
app/layout.tsx
```

Add:

```typescript
import {
  Analytics,
} from "@vercel/analytics/react";
```

Then:

```tsx
<body>
  {children}

  <Analytics />
</body>
```

---

# Wait...

That's It?

Yes.

Because:

```text
Analytics
       =
Instrumentation
```

---

# What Is Instrumentation?

Suppose you install:

```text
Speedometer
```

in a car.

You didn't change:

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

---

# Pillar 2 — Logs

Metrics tell us:

```text
Something broke.
```

Logs tell us:

```text
What broke.
```

---

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
      timestamp:
        new Date()
          .toISOString(),

      message,

      metadata,
    })
  );
}
```

---

# Why Structured Logs?

Bad:

```text
Something happened
```

Good:

```json
{
  "timestamp":
    "2026-07-03",

  "event":
    "comment_created",

  "user":
    "123",

  "post":
    "456"
}
```

---

# Wait...

Why JSON?

Because computers read:

```text
Structure
```

better than:

```text
English
```

Diagram:

```text
Human Logs
      │
      ▼

Hard To Search


Structured Logs
        │
        ▼

Easy To Search
```

---

# Logging Comments

Open:

```text
app/api/comments/route.ts
```

Add:

```typescript
import {
  log,
} from "@/lib/logger";
```

Then:

```typescript
log(
  "comment_created",
  {
    author:
      data.get(
        "author"
      ),

    post:
      data.get(
        "postId"
      ),
  }
);
```

---

# Now Imagine Production

You receive:

```json
{
  "event":
    "comment_created",

  "author":
    "Alice",

  "post":
    "react-architecture"
}
```

Then:

```json
{
  "event":
    "comment_created",

  "author":
    "Bob",

  "post":
    "nextjs-guide"
}
```

Eventually:

```text
Millions of events.
```

---

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

---

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

Metrics cannot answer.

Logs cannot answer.

Traces can.

---

# What Is A Trace?

A trace records:

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

---

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

---

# Distributed Tracing

Modern systems are distributed.

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

A trace reconstructs:

```text
Entire System Execution
```

---

# Wait...

How Is This Possible?

Every request receives:

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

Everything becomes connected.

---

# Metrics + Logs + Traces

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
the timeout happened.
```

---

# Monitoring

Monitoring asks:

```text
Is the system healthy?
```

Examples:

```text
CPU

Memory

Latency

Errors

Traffic
```

---

# Service Level Indicators

Professional systems measure:

```text
Availability

Latency

Reliability
```

Example:

```text
99.9% uptime
```

This means:

```text
0.1% failure
```

---

# Wait...

99.9% Sounds Great

Actually:

```text
99.9%
```

still allows:

```text
43 minutes
of downtime
per month.
```

Meanwhile:

```text
99.999%
```

allows:

```text
26 seconds
per month.
```

---

# Error Budgets

Suppose your SLA is:

```text
99.9%
```

Then:

```text
Failure Budget:
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

You can spend:

```text
Failure
```

carefully.

---

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

---

# The Problem With Alerts

Bad alerts:

```text
Everything broke!!!
```

Good alerts:

```text
Comments API

Error:
Database timeout

Started:
03:14 UTC

Users affected:
25%
```

---

# Dashboards

Professional systems build dashboards showing:

```text
Requests

Latency

Errors

Users

Revenue
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

---

# Why Observability Is Difficult

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

20 million metrics

1 million traces
```

---

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

---

# The Hidden Architecture

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

Meanwhile:

```text
Metrics
Logs
Traces
```

are all being collected simultaneously.

---

# Wait...

Does This Look Familiar?

We've already discovered:

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

---

# The Deep Secret Of Production Engineering

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

Questions become:

```text
What happened?

Why?

Where?

How often?

How bad?

Can it happen again?
```

---

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

Once you understand this, monitoring, analytics, telemetry, tracing, debugging, logging, and AI observability become manifestations of the same fundamental discipline.

---

# Up Next

In **Part 25**, we'll refactor GreyMatter Journal into a production-grade architecture while learning:

* software architecture,
* modularity,
* separation of concerns,
* dependency inversion,
* system boundaries,
* and why software engineering is ultimately the discipline of managing complexity.
