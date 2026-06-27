# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 14)

# Distributed Systems Failures: Partial Failure, Network Partitions, Sagas, CAP Theorem, and Why Distributed Computing Changed Everything

> *"In a single machine, failures are exceptions.*
>
> *In distributed systems, failures are assumptions."*

---

# Introduction

Consider a normal Python program:

```python
def transfer():

    debit()
    credit()
```

If:

```python
credit()
```

fails:

```text
raise Exception
```

Simple.

---

Now consider:

```text
Service A
     |
     V
Service B
     |
     V
Service C
```

Question:

What happens if:

```text
A succeeds
B times out
C never receives the request
```

?

Answer:

> Nobody knows.

Welcome to:

# Distributed Systems

The field where:

* messages disappear,
* machines crash,
* clocks lie,
* networks partition,
* retries duplicate work,
* and success itself becomes ambiguous.

---

# Chapter 183 — The First Distributed Systems Lesson

Question:

Which is harder?

```text
1 computer
```

or

```text
100 computers
```

Answer:

```text
100 computers
```

is not:

```text
100× harder
```

It is:

```text
qualitatively different
```

---

Single machine:

```text
CPU
Memory
Disk
```

Distributed machine:

```text
CPU
Memory
Disk
Network
Other Machines
Other Failures
Other Clocks
```

---

Visualization:

```text
Single Machine

A
|
B
|
C
```

vs

```text
Machine A
     |
Network
     |
Machine B
     |
Network
     |
Machine C
```

---

# Exercise 1

List five new failure modes introduced by networks.

---

# Chapter 184 — The Fallacies Of Distributed Computing

Engineers once assumed:

```text
The network is reliable.
```

False.

---

They assumed:

```text
Latency is zero.
```

False.

---

They assumed:

```text
Bandwidth is infinite.
```

False.

---

They assumed:

```text
The network is secure.
```

False.

---

These assumptions became known as:

# The Fallacies of Distributed Computing

---

The eight fallacies:

1. The network is reliable.
2. Latency is zero.
3. Bandwidth is infinite.
4. The network is secure.
5. Topology never changes.
6. There is one administrator.
7. Transport cost is zero.
8. The network is homogeneous.

---

# Exercise 2

Which fallacies exist inside your home WiFi?

---

# Chapter 185 — Partial Failure

Single machine:

```text
Success
OR
Failure
```

---

Distributed systems:

```text
Success
Failure
Maybe
```

---

Example:

```python
payment()
```

Network timeout.

Question:

Did payment succeed?

Possible answers:

```text
No
Yes
Unknown
```

---

Visualization:

```text
Request
    |
Network
    |
Timeout
    |
Unknown State
```

---

This is called:

# Partial Failure

---

# Exercise 3

Explain why:

```text
timeout != failure
```

---

# Chapter 186 — The Two Generals Problem

Suppose:

```text
General A
        |
    messenger
        |
General B
```

Need:

```text
Attack together
```

---

Question:

How can both know the message arrived?

Answer:

> They cannot.

---

Visualization:

```text
Send
 |
Ack
 |
Ack Ack
 |
Ack Ack Ack
```

Infinite.

---

This proves:

> Perfect agreement over unreliable networks is impossible.

---

# Exercise 4

Explain why TCP doesn't solve the Two Generals Problem.

---

# Chapter 187 — Distributed Transactions

Single machine:

```python
BEGIN

A()
B()

COMMIT
```

Easy.

---

Distributed:

```text
Service A
Service B
Service C
```

Question:

How do all commit together?

---

Solution:

# Two-Phase Commit (2PC)

---

Phase 1:

```text
Prepare?
```

Phase 2:

```text
Commit.
```

---

Visualization:

```text
Coordinator
     |
Prepare
     |
Ready
     |
Commit
```

---

Problem:

If coordinator dies:

```text
everyone waits forever
```

---

# Exercise 5

Simulate coordinator failure.

---

# Chapter 188 — Why Microservices Avoid Distributed Transactions

Example:

```text
Order
Payment
Inventory
Shipping
```

Traditional transaction:

```text
all succeed
or
all rollback
```

---

Reality:

```text
impossible
```

at scale.

---

Instead:

# Sagas

---

# Chapter 189 — The Saga Pattern

Example:

```text
Reserve Inventory
        |
Charge Payment
        |
Book Shipping
```

If shipping fails:

```text
Refund Payment
Release Inventory
```

---

Visualization:

```text
Forward Steps
      |
Failure
      |
Compensation
```

---

Example:

```python
try:

    reserve()

    charge()

    ship()

except:

    refund()

    unreserve()
```

---

# Exercise 6

Design a hotel booking saga.

---

# Chapter 190 — Idempotency

Suppose:

```text
Client
    |
Payment Request
```

Network fails.

Retry:

```text
Payment Request
```

Question:

One payment?

Or two?

---

Solution:

```text
Idempotency Key
```

Example:

```text
payment-id:
abc123
```

---

Visualization:

```text
Request
    |
Seen Before?
   /      \
Yes       No
```

---

# Exercise 7

Design an idempotent checkout API.

---

# Chapter 191 — Network Partitions

Suppose:

```text
A ------- B
```

Network breaks.

Now:

```text
A cannot see B
B cannot see A
```

Question:

Who owns the truth?

---

Visualization:

```text
A       X       B
```

---

This is called:

# Partition

---

# Exercise 8

Explain how WhatsApp behaves during network partitions.

---

# Chapter 192 — The CAP Theorem

A distributed system can provide:

```text
Consistency
Availability
Partition Tolerance
```

Pick:

```text
two
```

---

Visualization:

```text
        C
       / \
      /   \
     /     \
    A-------P
```

---

Definitions:

### Consistency

```text
Everyone sees same data
```

---

### Availability

```text
System always responds
```

---

### Partition Tolerance

```text
System survives network splits
```

---

# Exercise 9

Classify:

* banking
* DNS
* chat app
* social media

---

# Chapter 193 — Eventual Consistency

Example:

```text
Singapore DB
Tokyo DB
London DB
```

Update:

```text
Singapore
```

Question:

When do others update?

Answer:

```text
Eventually
```

---

Visualization:

```text
T0:
A=5
B=5

T1:
A=6
B=5

T2:
A=6
B=6
```

---

# Exercise 10

Describe eventual consistency in social media likes.

---

# Chapter 194 — Consensus

Suppose:

```text
5 servers
```

Need agreement.

Question:

Who decides?

Answer:

# Consensus Algorithms

Examples:

* Paxos
* Raft
* Zab

---

Visualization:

```text
Follower
    |
Leader
    |
Followers
```

---

Consensus solves:

```text
Who is right?
```

---

# Exercise 11

Elect a leader among five nodes.

---

# Chapter 195 — Split Brain

Suppose:

```text
Cluster A
```

believes:

```text
Leader=A
```

while:

```text
Cluster B
```

believes:

```text
Leader=B
```

---

Visualization:

```text
A <--X--> B
```

---

Now:

```text
two truths exist
```

---

This is:

# Split Brain

---

# Exercise 12

Why is split brain catastrophic for banking?

---

# Chapter 196 — Retries Create New Failures

Suppose:

```text
Request
   |
Timeout
   |
Retry
```

Question:

Did request fail?

Maybe not.

---

Example:

```text
Charge $100
Timeout
Retry
Charge $100 again
```

---

Visualization:

```text
Request
   |
Timeout
   |
Retry
   |
Duplicate
```

---

This is why:

```text
retry
```

is a distributed systems problem.

---

# Exercise 13

Design safe retries.

---

# Chapter 197 — Circuit Breakers In Distributed Systems

Suppose:

```text
Service B down
```

Without protection:

```text
A retries forever
```

Then:

```text
A dies
```

Then:

```text
everything dies
```

---

Visualization:

```text
A -> B X

A retry
A retry
A retry
A crash
```

---

Solution:

# Circuit Breakers

---

States:

```text
Closed
Open
Half-Open
```

---

# Exercise 14

Implement a circuit breaker state machine.

---

# Chapter 198 — Distributed Systems Are Failure Machines

Single machine:

```text
Errors
```

Distributed systems:

```text
Failures
```

Difference:

```text
Error:
something wrong

Failure:
something unavailable
```

---

Visualization:

```text
Code Error
     |
Exception


Network Failure
     |
System Behavior
```

---

# The Distributed Failure Model

```text
Request
     |
Network
     |
Partial Failure
     |
Retry
     |
Compensation
     |
Recovery
```

---

# The Distributed Recovery Pipeline

```text
Failure
    |
Detection
    |
Classification
    |
Retry
    |
Compensation
    |
Consistency
    |
Recovery
```

---

# The Most Important Diagram In Distributed Systems

```text
Machine
    |
Network
    |
Partial Failure
    |
Partition
    |
Retry
    |
Compensation
    |
Consistency
    |
Recovery
```

---

# Summary

In this article we learned:

✅ partial failure
✅ distributed transactions
✅ two-phase commit
✅ sagas
✅ idempotency
✅ network partitions
✅ CAP theorem
✅ eventual consistency
✅ consensus
✅ split brain
✅ retries
✅ circuit breakers

---

# Conclusion

Most developers think:

> Software failures are bugs.

Distributed systems engineers understand:

> **Most failures are not bugs. They are consequences of physics.**

Because once you distribute computation across machines, you inherit:

* unreliable networks,
* unreliable clocks,
* unreliable communication,
* unreliable agreement,
* unreliable truth itself.

And this changes the fundamental question from:

> "How do I prevent errors?"

to:

> **"How do I maintain correctness when agreement itself is impossible?"**

In **Part 15**, we'll move into **Site Reliability Engineering (SRE)**:

* SLIs,
* SLOs,
* SLAs,
* error budgets,
* incident response,
* chaos engineering,
* disaster recovery,
* fault injection,
* and why companies like Google treat failure as a measurable engineering discipline rather than an accident. 🚨
