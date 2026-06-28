# Appendix A21 — Next.js 16 Deployment, DevOps & Platform Engineering Cheat Sheet

## The Complete Guide to Getting Software Out of Your Laptop and Into the Real World

> **Purpose:** This appendix is the definitive reference for deployment engineering, DevOps, and platform operations in Next.js 16 applications. Software that works on your machine but cannot be reliably deployed is not finished software.

---

# Introduction

The biggest misconception beginners have is:

```text
Deployment
=
Uploading files.
```

Professional engineers understand:

```text
Deployment
=
Managing risk.
```

Because every deployment is fundamentally:

```text
Old system

      |

Change

      |

Unknown behavior
```

---

# The Golden Rule

Never ask:

```text
How do I
deploy this?
```

Ask:

```text
How do I
recover if
deployment fails?
```

---

# The Software Lifecycle

```text
Develop

   |

Test

   |

Build

   |

Deploy

   |

Monitor

   |

Improve
```

---

# Wrong Lifecycle

```text
Write code

    |

Deploy

    |

Pray
```

---

# Why Deployments Fail

Usually not because of:

```text
Code.
```

Usually because of:

```text
Configuration

Dependencies

Environment

Infrastructure
```

---

# Development Environments

Most systems have:

```text
Development

Staging

Production
```

---

# Development

Purpose:

```text
Build features.
```

---

# Staging

Purpose:

```text
Simulate production.
```

---

# Production

Purpose:

```text
Serve users.
```

---

# Rule

Never treat:

```text
Production
```

as:

```text
Testing.
```

---

# Infrastructure Layers

```text
Application

      |

Runtime

      |

Container

      |

Server

      |

Cloud
```

---

# The Twelve-Factor Mindset

Applications should be:

```text
Portable

Stateless

Configurable

Observable
```

---

# Build Pipeline

Modern software pipeline:

```text
Source

   |

Build

   |

Test

   |

Package

   |

Deploy
```

---

# Example

```text
Git Push

    |

CI

    |

Build

    |

Tests

    |

Deploy
```

---

# Continuous Integration

CI answers:

```text
Does the
software work?
```

---

# Continuous Deployment

CD answers:

```text
Can we
release safely?
```

---

# Build Artifacts

Never deploy:

```text
Source code.
```

Deploy:

```text
Artifacts.
```

---

# Examples

```text
Docker image

Bundle

Static assets

Compiled binaries
```

---

# Environment Variables

Configuration belongs in:

```text
Environment variables.
```

---

Bad:

```ts
const api =
  "production-api";
```

---

Good:

```ts
const api =
  process.env.API_URL;
```

---

# Secrets

Never store:

```text
Passwords

Tokens

API keys
```

Inside:

```text
Git repositories.
```

---

# Containerization

Containers package:

```text
Application

+

Dependencies

+

Runtime
```

---

# Benefits

```text
✓ Reproducible

✓ Portable

✓ Predictable
```

---

# Container Model

```text
Application

      |

Container

      |

Host OS
```

---

# Dockerfile Philosophy

Bad:

```dockerfile
COPY .
RUN npm install
```

---

Better:

```dockerfile
COPY package.json .
RUN npm install

COPY . .
```

---

# Multi-Stage Builds

Example:

```text
Build Stage

      |

Runtime Stage
```

---

# Benefits

```text
Smaller images

Better security

Faster deployment
```

---

# Immutable Infrastructure

Rule:

```text
Never modify
running servers.
```

Instead:

```text
Replace servers.
```

---

# Deployment Strategies

Common strategies:

```text
Rolling

Blue-Green

Canary

Feature Flags
```

---

# Rolling Deployment

Visualizing:

```text
Old Old Old

      |

New Old Old

      |

New New Old

      |

New New New
```

---

# Benefits

```text
Low cost.
```

---

# Risks

```text
Mixed versions.
```

---

# Blue-Green Deployment

Visualizing:

```text
Blue
(Current)

Green
(New)

      |

Switch traffic
```

---

# Benefits

```text
Fast rollback.
```

---

# Costs

```text
Double infrastructure.
```

---

# Canary Deployment

Visualizing:

```text
1%

10%

50%

100%
```

---

# Benefits

```text
Reduced risk.
```

---

# Feature Flags

Instead of:

```text
Deploying features.
```

Deploy:

```text
Disabled code.
```

Then:

```text
Enable gradually.
```

---

# Rollbacks

Question:

```text
Can we
undo this
in 30 seconds?
```

---

If not:

```text
Deployment
is unsafe.
```

---

# Database Migrations

Most dangerous deployment step.

---

Bad:

```sql
DROP COLUMN
```

---

Better:

```text
Add column

Migrate data

Deploy app

Remove old column
```

---

# Zero Downtime Migration

Process:

```text
Expand

   |

Migrate

   |

Contract
```

---

# Stateless Applications

Requirement:

```text
Any server
can handle
any request.
```

---

# Never Store

```text
Sessions

Files

State
```

In:

```text
Server memory.
```

---

# Health Checks

Every service should expose:

```text
/health
```

---

Example Response

```json
{
  "status": "healthy"
}
```

---

# Liveness Checks

Question:

```text
Is the
application alive?
```

---

# Readiness Checks

Question:

```text
Can the
application
serve traffic?
```

---

# Startup Checks

Question:

```text
Can the
application
start correctly?
```

---

# Scaling

Two strategies:

```text
Vertical

Horizontal
```

---

# Vertical Scaling

Add:

```text
CPU

RAM
```

---

Benefits:

```text
Simple.
```

---

Limitations:

```text
Finite.
```

---

# Horizontal Scaling

Add:

```text
Servers.
```

---

Benefits:

```text
Elastic.
```

---

Costs:

```text
Complexity.
```

---

# Load Balancers

Purpose:

```text
Distribute traffic.
```

---

Visualizing:

```text
Users

   |

Load Balancer

   |

Server A

Server B

Server C
```

---

# Auto Scaling

Question:

```text
When should
we add servers?
```

---

Metrics:

```text
CPU

Memory

Requests

Queue size
```

---

# Queues

Purpose:

```text
Handle spikes.
```

---

Visualizing:

```text
Traffic Spike

      |

Queue

      |

Workers
```

---

# Backpressure

Question:

```text
What happens
when demand
exceeds supply?
```

---

Options:

```text
Reject

Throttle

Queue
```

---

# Infrastructure as Code

Rule:

```text
Infrastructure
must be
version controlled.
```

---

Bad:

```text
Clicking buttons.
```

---

Good:

```text
Configuration files.
```

---

# Platform Engineering

Goal:

```text
Build systems

that build systems.
```

---

Developers should use:

```text
Self-service
platforms.
```

---

# Internal Developer Platform

Provides:

```text
Deployments

Monitoring

Secrets

Databases

CI/CD
```

---

# Platform Responsibilities

```text
Security

Observability

Deployment

Scaling

Recovery
```

---

# Application Responsibilities

```text
Business logic

Features

User experience
```

---

# SRE Principle

Question:

```text
Can humans
avoid doing this?
```

If:

```text
Yes
```

Then:

```text
Automate it.
```

---

# Deployment Metrics

Track:

```text
Deployment frequency

Lead time

Failure rate

Recovery time
```

---

# DORA Metrics

The four key metrics:

```text
Deployment Frequency

Lead Time

Change Failure Rate

MTTR
```

---

# Incident Response

Workflow:

```text
Detect

   |

Triage

   |

Mitigate

   |

Recover

   |

Learn
```

---

# Disaster Recovery

Always ask:

```text
What happens if:

Database dies?

Cloud fails?

Region fails?

People make mistakes?
```

---

# Recovery Metrics

RTO:

```text
How quickly
must we recover?
```

---

RPO:

```text
How much data
can we lose?
```

---

# Example

```text
RTO:
15 minutes

RPO:
5 minutes
```

---

# Backup Strategy

Apply:

```text
3

Copies

2

Media types

1

Offsite backup
```

---

# Cost Engineering

Question:

```text
Can we
afford to
operate this?
```

---

Monitor:

```text
Compute

Storage

Bandwidth

Databases

AI costs
```

---

# FinOps Principle

Optimize:

```text
Performance

Cost

Reliability
```

Together.

---

# Production Readiness Checklist

Verify:

```text
✓ CI/CD

✓ Rollback

✓ Health checks

✓ Monitoring

✓ Logging

✓ Alerts

✓ Backups

✓ Secrets

✓ Scaling

✓ Runbooks
```

---

# Common Beginner Mistakes

---

## Mistake 1

Deploying manually.

---

## Mistake 2

No rollback strategy.

---

## Mistake 3

Testing in production.

---

## Mistake 4

Storing secrets in Git.

---

## Mistake 5

Treating servers as pets.

---

## Mistake 6

Ignoring operational costs.

---

## Mistake 7

Assuming deployment equals delivery.

---

# Deployment Decision Tree

Question:

```text
Can we
roll back?
```

If:

```text
No
```

Then:

```text
Do not deploy.
```

---

Question:

```text
Can we
observe it?
```

If:

```text
No
```

Then:

```text
Do not deploy.
```

---

Question:

```text
Can we
recover?
```

If:

```text
No
```

Then:

```text
Do not deploy.
```

---

# The Complete Software Delivery Pipeline

```text
Plan
   |
Build
   |
Test
   |
Package
   |
Deploy
   |
Observe
   |
Recover
   |
Learn
```

---

# Mental Model

Beginners think:

```text
Deployment
=
Moving code
to servers.
```

Professional engineers think:

```text
Deployment
=
Managing change
under uncertainty.
```

Because software engineering does not end when the code compiles.

It ends when the system survives reality.
