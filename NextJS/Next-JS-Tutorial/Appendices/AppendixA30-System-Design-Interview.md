# Appendix A30 — The Complete System Design Interview Handbook

## How to Think About Designing Systems at Scale

> **Purpose:** System design interviews are not tests of memorization. They are tests of engineering judgment. The interviewer is not asking whether you know how Twitter, Netflix, or ChatGPT work. They are evaluating how you reason under uncertainty, constraints, and tradeoffs.

---

# Introduction

The biggest mistake candidates make is:

```text id="sd001">
Trying to
remember
architectures.
```

Professional engineers understand:

```text id="sd002">
There are no
correct
architectures.
```

There are only:

```text id="sd003">
Tradeoffs.
```

---

# The Universal System Design Process

Every system design interview follows the same process:

```text id="sd004">
Requirements

      |

Constraints

      |

Capacity

      |

Architecture

      |

Bottlenecks

      |

Failure Modes

      |

Tradeoffs
```

---

# Step 1

# Clarify Requirements

Never start drawing boxes.

Start by asking:

---

## Functional Requirements

```text id="sd005">
What should
the system do?
```

Examples:

```text id="sd006">
Create posts

Search posts

Upload videos

Send messages

Generate AI responses
```

---

## Non-Functional Requirements

```text id="sd007">
How well
must it work?
```

Examples:

```text id="sd008">
Latency

Availability

Consistency

Scalability

Security

Cost
```

---

# Example

Question:

```text id="sd009">
Design Twitter.
```

Wrong:

```text id="sd010">
Microservices.
```

Correct:

```text id="sd011">
How many users?

Read/write ratio?

Latency target?

Availability target?

Global?
```

---

# Step 2

# Estimate Scale

Professional engineers always estimate.

---

## Example

Users:

```text id="sd012">
100 million
```

---

DAU:

```text id="sd013">
10 million
```

---

Posts/day:

```text id="sd014">
100 million
```

---

Storage/year:

```text id="sd015">
≈ 36 billion posts
```

---

Question:

```text id="sd016">
Can one database
handle this?
```

---

# Step 3

# Identify Constraints

Everything is constrained.

Examples:

```text id="sd017">
Money

Latency

Availability

Consistency

Team size

Operations
```

---

# CAP Theorem

Choose two:

```text id="sd018">
Consistency

Availability

Partition tolerance
```

---

# Example

Banking:

```text id="sd019">
Consistency.
```

---

Social media:

```text id="sd020">
Availability.
```

---

# Step 4

# Draw High-Level Architecture

Template:

```text id="sd021">
Users

   |

CDN

   |

Load Balancer

   |

Application

   |

Cache

   |

Database

   |

Storage

   |

Analytics
```

---

# Step 5

# Find Bottlenecks

Question:

```text id="sd022">
What breaks first?
```

---

Common answers:

```text id="sd023">
Database

Cache

Network

Storage

Queues
```

---

# Step 6

# Identify Failure Modes

Question:

```text id="sd024">
How does
this fail?
```

---

Examples:

```text id="sd025">
Database outage

Cache outage

Network partition

Cloud outage

Human error
```

---

# System Pattern Catalog

---

# Pattern 1

# CRUD System

Examples:

```text id="sd026">
CRM

HR system

ERP

Admin portal
```

---

Architecture:

```text id="sd027">
Frontend

↓

API

↓

Database
```

---

Optimize for:

```text id="sd028">
Simplicity.
```

---

# Pattern 2

# Read-Heavy System

Examples:

```text id="sd029">
Twitter

Reddit

News
```

---

Architecture:

```text id="sd030">
Database

↓

Cache

↓

CDN
```

---

Optimize for:

```text id="sd031">
Read latency.
```

---

# Pattern 3

# Write-Heavy System

Examples:

```text id="sd032">
IoT

Logging

Analytics
```

---

Architecture:

```text id="sd033">
Queue

↓

Stream

↓

Storage
```

---

Optimize for:

```text id="sd034">
Write throughput.
```

---

# Pattern 4

# Event-Driven System

Examples:

```text id="sd035">
Ecommerce

Payments

Notifications
```

---

Architecture:

```text id="sd036">
Producer

↓

Queue

↓

Consumers
```

---

Optimize for:

```text id="sd037">
Decoupling.
```

---

# Pattern 5

# Realtime System

Examples:

```text id="sd038">
Chat

Trading

Gaming
```

---

Architecture:

```text id="sd039">
WebSockets

↓

Pub/Sub

↓

State
```

---

Optimize for:

```text id="sd040">
Latency.
```

---

# Pattern 6

# Search System

Examples:

```text id="sd041">
Google

GitHub search

Ecommerce search
```

---

Architecture:

```text id="sd042">
Source DB

↓

Indexer

↓

Search Engine
```

---

Optimize for:

```text id="sd043">
Query speed.
```

---

# Pattern 7

# Video Platform

Examples:

```text id="sd044">
YouTube

Netflix
```

---

Architecture:

```text id="sd045">
Upload

↓

Transcode

↓

CDN

↓

Streaming
```

---

Optimize for:

```text id="sd046">
Bandwidth.
```

---

# Pattern 8

# AI Chat System

Examples:

```text id="sd047">
ChatGPT

Claude

Copilot
```

---

Architecture:

```text id="sd048">
User

↓

Gateway

↓

Orchestrator

↓

LLM

↓

Tools

↓

Validation
```

---

Optimize for:

```text id="sd049">
Correctness.
```

---

# Pattern 9

# RAG System

Architecture:

```text id="sd050">
Documents

↓

Embedding

↓

Vector DB

↓

Retrieval

↓

LLM
```

---

Optimize for:

```text id="sd051">
Context quality.
```

---

# Pattern 10

# Agentic System

Architecture:

```text id="sd052">
Goal

↓

Planner

↓

Executor

↓

Tools

↓

Verifier
```

---

Optimize for:

```text id="sd053">
Governance.
```

---

# Example

# Design URL Shortener

---

## Requirements

```text id="sd054">
Short URLs

Redirects

Analytics
```

---

## Scale

```text id="sd055">
100 million URLs
```

---

## Architecture

```text id="sd056">
API

↓

Cache

↓

Database
```

---

## Bottleneck

```text id="sd057">
Database reads.
```

---

## Solution

```text id="sd058">
Cache.
```

---

# Example

# Design WhatsApp

---

Requirements:

```text id="sd059">
Messaging

Presence

Delivery
```

---

Architecture:

```text id="sd060">
Client

↓

WebSocket

↓

Broker

↓

Storage
```

---

Challenge:

```text id="sd061">
Message ordering.
```

---

# Example

# Design YouTube

---

Requirements:

```text id="sd062">
Upload

Stream

Search
```

---

Architecture:

```text id="sd063">
Upload

↓

Object Storage

↓

Transcoding

↓

CDN
```

---

Challenge:

```text id="sd064">
Bandwidth.
```

---

# Example

# Design ChatGPT

---

Requirements:

```text id="sd065">
Conversation

Memory

Tools

Reasoning
```

---

Architecture:

```text id="sd066">
Gateway

↓

Context Builder

↓

LLM

↓

Tool Executor

↓

Validator
```

---

Challenge:

```text id="sd067">
Hallucinations.
```

---

# Example

# Design AI Agent Platform

---

Architecture:

```text id="sd068">
User

↓

Agent

↓

Planner

↓

Executor

↓

Verifier

↓

Human
```

---

Challenge:

```text id="sd069">
Trust.
```

---

# Common Interview Mistakes

---

## Mistake 1

```text id="sd070">
Jumping to technology.
```

---

## Mistake 2

```text id="sd071">
Ignoring constraints.
```

---

## Mistake 3

```text id="sd072">
Ignoring failures.
```

---

## Mistake 4

```text id="sd073">
Ignoring scale.
```

---

## Mistake 5

```text id="sd074">
Ignoring tradeoffs.
```

---

# The Universal Tradeoff Table

| Optimize For  | Sacrifice      |
| ------------- | -------------- |
| Consistency   | Availability   |
| Performance   | Simplicity     |
| Flexibility   | Complexity     |
| Reliability   | Cost           |
| Security      | Convenience    |
| Scale         | Operability    |
| AI Capability | Predictability |

---

# The Principal Engineer Questions

For every architecture ask:

---

## Question 1

```text id="sd075">
Why does
this exist?
```

---

## Question 2

```text id="sd076">
What problem
does it solve?
```

---

## Question 3

```text id="sd077">
What assumptions
does it make?
```

---

## Question 4

```text id="sd078">
How does
it fail?
```

---

## Question 5

```text id="sd079">
How does
it scale?
```

---

## Question 6

```text id="sd080">
How do we
operate it?
```

---

## Question 7

```text id="sd081">
How do we
remove it?
```

---

# The Ultimate System Design Formula

```text id="sd082">
Requirements

+

Constraints

+

Tradeoffs

+

Failures

+

Operations

=

Architecture
```

---

# Final Mental Model

Junior engineers ask:

```text id="sd083">
What technology
should we use?
```

---

Senior engineers ask:

```text id="sd084">
What problem
are we solving?
```

---

Staff engineers ask:

```text id="sd085">
What tradeoffs
are acceptable?
```

---

Principal engineers ask:

```text id="sd086">
What assumptions
will eventually
become wrong?
```

Because system design has never been about drawing boxes.

It has always been about managing uncertainty under constraints.
