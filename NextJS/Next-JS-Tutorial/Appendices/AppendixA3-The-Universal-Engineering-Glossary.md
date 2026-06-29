# Appendix A34 — The Universal Engineering Glossary

## The Vocabulary of Modern Software Engineering

> **Purpose:** Software engineering is a language. Much confusion occurs because engineers use the same words to mean different things, or different words to describe the same ideas. This appendix defines the core concepts every engineer should understand.

---

# Introduction

The biggest mistake engineers make is:

```text id="gl001"
Memorizing
definitions.
```

Professional engineers understand:

```text id="gl002"
Definitions
are compressed
experience.
```

---

# A

## ACID

Properties of reliable database transactions:

```text id="gl003"
Atomicity

Consistency

Isolation

Durability
```

---

### Example

```sql id="gl004"
BEGIN;

UPDATE accounts
SET balance = balance - 100
WHERE id = 1;

UPDATE accounts
SET balance = balance + 100
WHERE id = 2;

COMMIT;
```

---

### Mental Model

```text id="gl005"
All

or

nothing.
```

---

## API

Application Programming Interface.

---

Mental model:

```text id="gl006"
A contract
between systems.
```

---

## Availability

The probability that a system is operational when requested.

---

Formula:

```text id="gl007"
Availability

=

Uptime

/

Total Time
```

---

Examples:

```text id="gl008"
99%

99.9%

99.99%

99.999%
```

---

# B

## Backpressure

A mechanism to slow producers when consumers cannot keep up.

---

Example:

```text id="gl009"
Producer

↓

Queue

↓

Consumer
```

---

When consumer slows:

```text id="gl010"
Producer
must slow.
```

---

## BASE

Alternative to ACID:

```text id="gl011"
Basically Available

Soft State

Eventually Consistent
```

---

Mental model:

```text id="gl012"
Availability
over
consistency.
```

---

# C

## Cache

Temporary storage used to improve performance.

---

Tradeoff:

```text id="gl013"
Speed

vs

Freshness
```

---

## CAP Theorem

Distributed systems can optimize for only two:

```text id="gl014"
Consistency

Availability

Partition Tolerance
```

---

Mental model:

```text id="gl015"
Distributed systems
are tradeoffs.
```

---

## Circuit Breaker

Stops repeated failures.

---

Pattern:

```text id="gl016"
Failure

↓

Open circuit

↓

Reject requests
```

---

## CQRS

Command Query Responsibility Segregation.

---

Separate:

```text id="gl017"
Writes

and

Reads.
```

---

# D

## Deadlock

Two or more processes waiting forever.

---

Example:

```text id="gl018"
A waits for B

B waits for A
```

---

## Distributed System

A system where:

```text id="gl019"
Failure of
one computer
can affect
another.
```

---

## Domain Driven Design (DDD)

Design software around business domains.

---

Mental model:

```text id="gl020"
Model reality.
```

---

# E

## Eventual Consistency

Guarantee:

```text id="gl021"
Data becomes
consistent
eventually.
```

---

No guarantee:

```text id="gl022"
When.
```

---

# F

## Fault Tolerance

Ability to continue operating after failure.

---

Mental model:

```text id="gl023"
Fail

and

continue.
```

---

# H

## Hallucination

AI generates:

```text id="gl024"
Confidently
incorrect
output.
```

---

## Horizontal Scaling

Add:

```text id="gl025"
More machines.
```

---

Instead of:

```text id="gl026"
Bigger machine.
```

---

# I

## Idempotency

Repeated execution produces the same result.

---

Example:

```http id="gl027"
POST /payment
```

with:

```text id="gl028"
Idempotency-Key.
```

---

## Infrastructure

Resources supporting applications.

---

Examples:

```text id="gl029"
Servers

Networks

Storage

Cloud

Context
```

---

# J

## Jitter

Random delay added to avoid synchronized retries.

---

Example:

```text id="gl030"
Retry:

1.2 sec

instead of

1 sec.
```

---

# K

## Kubernetes

Container orchestration platform.

---

Mental model:

```text id="gl031"
Operating system
for clusters.
```

---

# L

## Latency

Time required to complete an operation.

---

Examples:

```text id="gl032"
P50

P95

P99
```

---

## Load Balancer

Distributes traffic.

---

Example:

```text id="gl033"
Users

↓

Load Balancer

↓

Servers
```

---

# M

## MTBF

Mean Time Between Failures.

---

Measures:

```text id="gl034"
Reliability.
```

---

## MTTR

Mean Time To Recovery.

---

Measures:

```text id="gl035"
Recoverability.
```

---

# O

## Observability

Ability to understand internal state through outputs.

---

Three pillars:

```text id="gl036"
Logs

Metrics

Traces
```

---

## OODA Loop

Decision framework:

```text id="gl037"
Observe

Orient

Decide

Act
```

---

# P

## Partition

Network split.

---

Example:

```text id="gl038"
Cluster A

X

Cluster B
```

---

## P99

99th percentile latency.

---

Meaning:

```text id="gl039"
99%
of requests
complete faster.
```

---

## Prompt Injection

Attack that manipulates AI instructions.

---

Example:

```text id="gl040"
Ignore all
previous instructions.
```

---

# Q

## Queue

Temporary storage for asynchronous work.

---

Mental model:

```text id="gl041"
Wait here.
```

---

# R

## RAG

Retrieval-Augmented Generation.

---

Architecture:

```text id="gl042"
Search

↓

Retrieve

↓

Generate
```

---

## Rate Limiting

Restrict request frequency.

---

Example:

```text id="gl043"
100 requests
per minute.
```

---

## Replication

Copying data across systems.

---

Goal:

```text id="gl044"
Availability.
```

---

## Retry Storm

Failure causing excessive retries.

---

Pattern:

```text id="gl045"
Failure

↓

Retry

↓

More failure
```

---

# S

## SAGA

Distributed transaction pattern.

---

Pattern:

```text id="gl046"
Transaction

↓

Compensation
```

---

## Scalability

Ability to handle growth.

---

Question:

```text id="gl047"
What happens
at 10×?
```

---

## Service Level Agreement (SLA)

Contractual guarantee.

---

Example:

```text id="gl048"
99.9% uptime.
```

---

## Service Level Indicator (SLI)

Measured metric.

---

Examples:

```text id="gl049"
Latency

Availability

Errors
```

---

## Service Level Objective (SLO)

Target metric.

---

Example:

```text id="gl050"
99.95% availability.
```

---

## Split Brain

Multiple leaders in a distributed system.

---

Result:

```text id="gl051"
Corruption.
```

---

# T

## Throughput

Amount of work performed per unit time.

---

Examples:

```text id="gl052"
Requests/sec

Messages/sec

Transactions/sec
```

---

## Tracing

Following requests through systems.

---

Example:

```text id="gl053"
Frontend

↓

API

↓

Database
```

---

# V

## Vector Database

Stores embeddings for similarity search.

---

Examples:

```text id="gl054"
Embedding

↓

Vector DB

↓

Nearest Neighbor Search
```

---

## Vertical Scaling

Increase machine capacity.

---

Example:

```text id="gl055"
4 CPU

↓

64 CPU
```

---

# W

## Webhook

Event delivered via HTTP callback.

---

Pattern:

```text id="gl056"
Event

↓

POST request
```

---

# Y

## YAGNI

Principle:

```text id="gl057"
You Aren't
Gonna Need It.
```

---

Meaning:

```text id="gl058"
Do not build
future requirements.
```

---

# The Universal Engineering Dictionary

Every engineering term eventually maps to one of:

```text id="gl059"
Performance

Reliability

Scalability

Security

Complexity

Cost

Uncertainty
```

---

# The Principal Engineer Translation Table

When someone says:

---

## "Performance"

Ask:

```text id="gl060"
Compared
to what?
```

---

## "Scalable"

Ask:

```text id="gl061"
How much?
```

---

## "Reliable"

Ask:

```text id="gl062"
Under what
conditions?
```

---

## "Secure"

Ask:

```text id="gl063"
Against whom?
```

---

## "Simple"

Ask:

```text id="gl064"
For whom?
```

---

## "Fast"

Ask:

```text id="gl065"
At what cost?
```

---

## "Production Ready"

Ask:

```text id="gl066"
How do
you know?
```

---

# The Ultimate Glossary Entry

## Software Engineering

Definition:

```text id="gl067"
The practice
of making
decisions

under uncertainty

while managing
complexity

under constraints.
```

---

# Final Thought

Junior engineers learn:

```text id="gl068"
Definitions.
```

Senior engineers learn:

```text id="gl069"
Tradeoffs.
```

Principal engineers learn:

```text id="gl070"
That every
definition
is itself
a tradeoff.
```
