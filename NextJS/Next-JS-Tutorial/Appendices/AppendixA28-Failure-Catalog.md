# Appendix A28 — The Complete Failure Catalog

## A Field Guide to How Real Software Systems Actually Break

> **Purpose:** Beginners study successful systems. Professional engineers study failed systems. This appendix catalogs the most common failures encountered in modern web applications, distributed systems, cloud platforms, and AI-native systems.

---

# Introduction

The biggest misconception in software engineering is:

```text id="r9tkzr"
Systems fail
because of bugs.
```

Professional engineers understand:

```text id="fd3d6o"
Systems fail
because of
interactions.
```

Most outages are not caused by:

```text id="4bhslg"
One thing.
```

They are caused by:

```text id="w63zgv"
Several individually
reasonable things

interacting
unexpectedly.
```

---

# The Universal Failure Model

```text id="5imfth"
Assumption

      |

Violation

      |

Unexpected State

      |

Failure

      |

Cascade

      |

Outage
```

---

# Failure Classification

Most failures belong to one of:

```text id="yd1gpr"
Hardware

Software

Network

Data

Human

Process

Security

AI
```

---

# Category 1

# Database Failures

---

## Failure A1

## Database Connection Exhaustion

Symptoms:

```text id="3d6b7d"
Slow requests

Timeouts

500 errors
```

---

Cause:

```text id="n8l7mx"
Too many
open connections.
```

---

Example:

```ts id="nqj7pj"
for (let i=0; i<10000; i++) {
    await db.connect();
}
```

---

Detection:

```text id="y5ln0v"
Connection pool
metrics.
```

---

Mitigation:

```text id="4v8prn"
Pooling

Limits

Backpressure
```

---

Recovery:

```text id="p4l5y9"
Restart workers.

Reduce load.
```

---

Prevention:

```text id="c3s7ri"
Connection pooling.
```

---

## Failure A2

## Slow Query Explosion

Symptoms:

```text id="2y57aq"
CPU spikes

Latency spikes

Database lockups
```

---

Cause:

```sql id="2rk6cx"
SELECT *
FROM huge_table
```

---

Detection:

```text id="r88slm"
Slow query logs.
```

---

Mitigation:

```text id="1xtod8"
Indexes

Pagination

Caching
```

---

## Failure A3

## Migration Failure

Symptoms:

```text id="6dl64u"
Deployment succeeds

Application fails
```

---

Cause:

```sql id="3w70x6"
DROP COLUMN
```

before:

```text id="x4jdl0"
Application update.
```

---

Prevention:

```text id="dujlwm"
Expand

Migrate

Contract
```

---

# Category 2

# Cache Failures

---

## Failure B1

## Cache Stampede

Pattern:

```text id="h3z4g5"
Cache expires

      |

10000 requests

      |

Database collapse
```

---

Symptoms:

```text id="7gxtnl"
Traffic spike

Database spike

Outage
```

---

Mitigation:

```text id="qkw5kl"
Locking

Jitter

Prewarming
```

---

## Failure B2

## Stale Cache

Symptoms:

```text id="t7u7dt"
Wrong data

Inconsistent UI
```

---

Cause:

```text id="bnttqz"
Cache invalidation.
```

---

There are only two hard problems:

```text id="i8qxlo"
Cache invalidation

Naming things
```

---

## Failure B3

## Redis Failure

Symptoms:

```text id="8d58d5"
Sessions lost

Queues fail

Rate limiting fails
```

---

Question:

```text id="x6rqly"
What happens
if Redis dies?
```

---

If answer:

```text id="hfh0gm"
Everything.
```

Then:

```text id="wy1mnv"
Architecture problem.
```

---

# Category 3

# Network Failures

---

## Failure C1

## DNS Failure

Symptoms:

```text id="czhzma"
Everything breaks.
```

---

Cause:

```text id="c4qhgv"
DNS outage.
```

---

Reality:

```text id="kn6lxn"
Everything
depends on DNS.
```

---

## Failure C2

## Timeout Cascade

Pattern:

```text id="c0sk6q"
Service A

waits

Service B

waits

Service C

waits

Failure
```

---

Symptoms:

```text id="c97c8m"
CPU spikes

Thread exhaustion

Outage
```

---

Mitigation:

```text id="dhgzjz"
Timeouts

Circuit breakers
```

---

## Failure C3

## Network Partition

Pattern:

```text id="rsk2l0"
Cluster A

 X

Cluster B
```

---

Question:

```text id="ghzkn3"
Who is right?
```

---

Answer:

```text id="5a7i6n"
Nobody knows.
```

---

# Category 4

# Application Failures

---

## Failure D1

## Memory Leak

Symptoms:

```text id="f97h0n"
Memory grows

Eventually crashes
```

---

Example:

```javascript id="61p5lm"
global.array.push(data);
```

---

Detection:

```text id="lzwqff"
Heap profiles.
```

---

## Failure D2

## Infinite Loop

Example:

```javascript id="ehdd8u"
while(true){}
```

---

Symptoms:

```text id="rr8rnm"
100% CPU.
```

---

Mitigation:

```text id="1vt32a"
Resource limits.
```

---

## Failure D3

## Race Condition

Pattern:

```text id="0dddrz"
Read

Read

Write

Write
```

---

Result:

```text id="7s3wuq"
Lost update.
```

---

Prevention:

```text id="hf4yng"
Transactions

Locks

Idempotency
```

---

# Category 5

# Distributed Systems Failures

---

## Failure E1

## Split Brain

Pattern:

```text id="x54twq"
Node A:
"I am leader"

Node B:
"I am leader"
```

---

Result:

```text id="vpl3m6"
Corruption.
```

---

## Failure E2

## Retry Storm

Pattern:

```text id="jlwm71"
Failure

↓

Retry

↓

More load

↓

More failure

↓

More retry
```

---

Mitigation:

```text id="jlwm72"
Backoff

Jitter

Circuit breakers
```

---

## Failure E3

## Thundering Herd

Pattern:

```text id="jlwm73"
10000 clients

↓

Reconnect

↓

Collapse
```

---

# Category 6

# Deployment Failures

---

## Failure F1

## Bad Release

Symptoms:

```text id="jlwm74"
Deployment succeeds.

Users fail.
```

---

Mitigation:

```text id="jlwm75"
Rollback.
```

---

## Failure F2

## Configuration Drift

Example:

```text id="jlwm76"
Production

≠

Staging
```

---

Result:

```text id="jlwm77"
Unexpected behavior.
```

---

## Failure F3

## Secret Rotation Failure

Symptoms:

```text id="jlwm78"
Authentication fails.
```

---

Cause:

```text id="jlwm79"
Expired secret.
```

---

# Category 7

# Security Failures

---

## Failure G1

## Authentication Bypass

Cause:

```text id="jlwm80"
Trusted input.
```

---

Prevention:

```text id="jlwm81"
Never trust input.
```

---

## Failure G2

## Authorization Failure

Question:

```text id="jlwm82"
Who should NOT
access this?
```

---

Usually forgotten.

---

## Failure G3

## Credential Leak

Examples:

```text id="jlwm83"
Git

Logs

Screenshots

Chat
```

---

# Category 8

# Human Failures

---

## Failure H1

## Wrong Environment

Example:

```bash id="jlwm84"
DROP DATABASE
```

Executed on:

```text id="jlwm85"
Production.
```

---

## Failure H2

## Wrong Assumption

Example:

```text id="jlwm86"
"This will
never happen."
```

---

Reality:

```text id="jlwm87"
It happened.
```

---

## Failure H3

## Missing Rollback

Question:

```text id="jlwm88"
How do we
undo this?
```

---

Answer:

```text id="jlwm89"
We can't.
```

---

Problem:

```text id="jlwm90"
Deployment unsafe.
```

---

# Category 9

# Cloud Failures

---

## Failure I1

## Region Failure

Symptoms:

```text id="jlwm91"
Entire application
offline.
```

---

Question:

```text id="jlwm92"
Do you have
another region?
```

---

## Failure I2

## Service Dependency Failure

Example:

```text id="jlwm93"
AWS fails.

Everything fails.
```

---

## Failure I3

## Billing Failure

Example:

```text id="jlwm94"
Credit card expired.
```

---

Result:

```text id="jlwm95"
Infrastructure disabled.
```

---

# Category 10

# AI Failures

---

## Failure J1

## Hallucination

Pattern:

```text id="jlwm96"
Confidently

wrong.
```

---

Mitigation:

```text id="jlwm97"
Verification.
```

---

## Failure J2

## Prompt Injection

Example:

```text id="jlwm98"
Ignore all
previous instructions.
```

---

Mitigation:

```text id="jlwm99"
Never trust prompts.
```

---

## Failure J3

## Agent Runaway Loop

Pattern:

```text id="jlwm100"
Think

Act

Observe

Repeat

Forever
```

---

Mitigation:

```text id="jlwm101"
Limits

Timeouts

Budgets
```

---

## Failure J4

## Context Poisoning

Pattern:

```text id="jlwm102"
Bad memory

↓

Bad reasoning

↓

Bad decisions
```

---

# Category 11

# Observability Failures

---

## Failure K1

## No Logs

Problem:

```text id="jlwm103"
Cannot debug.
```

---

## Failure K2

## No Metrics

Problem:

```text id="jlwm104"
Cannot detect.
```

---

## Failure K3

## No Traces

Problem:

```text id="jlwm105"
Cannot explain.
```

---

# The Failure Pyramid

```text id="jlwm106"
Human

   |

Process

   |

Architecture

   |

Implementation
```

---

Most failures originate at:

```text id="jlwm107"
Human

and

Process.
```

Not:

```text id="jlwm108"
Code.
```

---

# The Failure Investigation Framework

When systems fail ask:

---

## Question 1

```text id="jlwm109"
What changed?
```

---

## Question 2

```text id="jlwm110"
What assumptions
were violated?
```

---

## Question 3

```text id="jlwm111"
What dependencies
failed?
```

---

## Question 4

```text id="jlwm112"
Why was this
not detected?
```

---

## Question 5

```text id="jlwm113"
How do we
prevent recurrence?
```

---

# The Professional Engineering Rule

Beginners study:

```text id="jlwm114"
Successes.
```

Professionals study:

```text id="jlwm115"
Failures.
```

Because successful systems teach you:

```text id="jlwm116"
What worked.
```

Failed systems teach you:

```text id="jlwm117"
Reality.
```

---

# Final Mental Model

Software engineering is not:

```text id="jlwm118"
Building systems
that work.
```

Software engineering is:

```text id="jlwm119"
Building systems
that continue
to work

after

everything
that can go wrong

eventually
does.
```
