# Appendix A13 — Next.js 16 Deployment, Infrastructure, and Production Operations Cheat Sheet

## The Complete Guide to Running Next.js Applications in the Real World

> **Purpose:** This appendix is the definitive reference for deploying, operating, and maintaining production Next.js 16 applications. Building an application is only half the job. Keeping it running is the other half.

---

# Introduction

The biggest misconception beginners have is:

```text id="w2mk9p"
Deployment
=
Uploading files.
```

Professional engineers understand:

```text id="dnjlwm"
Deployment
=
Operating
a distributed system.
```

Because when users arrive, your application becomes:

```text id="5yv19k"
Servers

Caches

Databases

Networks

Queues

Storage

Monitoring

Security
```

---

# The Production Stack

A typical Next.js application contains:

```text id="mkazcx"
Browser
    |
CDN
    |
Load Balancer
    |
Next.js
    |
Database
    |
Cache
    |
Storage
```

---

# Visualizing

```text id="ljlwm1"
Users
   |
CDN
   |
Application
   |
Database
```

---

# Development vs Production

Development:

```text id="3g1baf"
Laptop
```

---

Production:

```text id="u7jlwm"
Multiple machines.
```

---

# Deployment Targets

Next.js can deploy to:

```text id="jlwmv3"
Vercel

Docker

Kubernetes

AWS

Azure

GCP

Self-hosted
```

---

# Vercel

Best for:

```text id="jlwm18"
Most applications.
```

---

Advantages:

```text id="jlwmz9"
✓ Easy

✓ Fast

✓ CDN

✓ Caching

✓ Observability
```

---

# Docker

Best for:

```text id="jlwmw5"
Portability.
```

---

Visualizing:

```text id="jlwmsf"
Code
   |
Container
   |
Server
```

---

# Kubernetes

Best for:

```text id="jlwmce"
Large systems.
```

---

Visualizing:

```text id="jlwm77"
Pods
  |
Nodes
  |
Cluster
```

---

# Build Pipeline

```text id="jlwmrz"
Git Push
     |
CI
     |
Tests
     |
Build
     |
Deploy
```

---

# The Build Step

Example:

```bash id="jlwma1"
npm run build
```

This performs:

```text id="jlwm6m"
Compile

Bundle

Optimize

Pre-render

Analyze
```

---

# The Output

```text id="jlwmm7"
.next/
```

contains:

```text id="jọlm12"
Server code

Client code

Static assets

Caches
```

---

# Environment Variables

Development:

```text id="jlwmu7"
.env.local
```

---

Production:

```text id="jlwmwr"
Secrets manager
```

---

# Never Commit

```text id="jlwm4o"
.env
```

---

Bad:

```bash id="jlwmpd"
git add .env
```

---

Good:

```bash id="jlwm2z"
.gitignore
```

---

# Example Variables

```env id="jlwmft"
DATABASE_URL=

JWT_SECRET=

REDIS_URL=

STRIPE_SECRET=
```

---

# Database Deployment

Production database:

```text id="jlwm83"
Separate service.
```

---

Visualizing:

```text id="jlwm71"
Application
      |
Database
```

---

Never:

```text id="jlwm6f"
Store SQLite
on server disk.
```

---

# Database Migrations

Example:

```bash id="jlwmjk"
npx prisma migrate deploy
```

---

Pipeline:

```text id="jlwmh3"
Deploy
   |
Migration
   |
Application
```

---

# Cache Layer

Example:

```text id="jlwmz1"
Redis
```

---

Visualizing:

```text id="jlwmu9"
Application
      |
Redis
      |
Database
```

---

# Storage Layer

Use:

```text id="jlwm1d"
S3

R2

Blob storage
```

---

Never:

```text id="jlwmmj"
Server filesystem.
```

---

# CDN

Purpose:

```text id="jlwmf2"
Serve static assets.
```

---

Visualizing:

```text id="jlwm5q"
User
   |
CDN
   |
Server
```

---

# Benefits

```text id="jlwmxh"
✓ Faster

✓ Cheaper

✓ More scalable
```

---

# Horizontal Scaling

Bad:

```text id="jlwm5g"
1 server
```

---

Better:

```text id="jlwm02"
10 servers
```

---

Visualizing:

```text id="jlwmze"
Load Balancer
       |
  +----+----+
  |    |    |
App  App  App
```

---

# Stateless Servers

Servers should store:

```text id="jlwm38"
Nothing.
```

---

Bad:

```text id="jlwm3v"
User sessions
in memory.
```

---

Good:

```text id="jlwmzs"
Redis

Database
```

---

# Session Storage

Example:

```text id="jlwmst"
Browser
    |
Cookie
    |
Redis
```

---

# HTTPS

Always use:

```text id="jlwmf0"
TLS.
```

---

Visualizing:

```text id="jlwm8v"
HTTP
   X

HTTPS
   ✓
```

---

# Health Checks

Example:

```text id="jlwm0m"
/api/health
```

---

Response:

```json id="jlwmkn"
{
  "status": "ok"
}
```

---

# Readiness Checks

Question:

```text id="jlwm7g"
Can I serve traffic?
```

---

# Liveness Checks

Question:

```text id="jlwmr5"
Am I alive?
```

---

# Deployment Strategies

Types:

```text id="jlwm8a"
Rolling

Blue-Green

Canary
```

---

# Rolling Deployment

```text id="jlwma9"
Old
Old
New
New
```

---

# Blue-Green

```text id="jlwmg3"
Blue

Green
```

Switch traffic.

---

# Canary

```text id="jlwmwe"
95%

5%
```

Test safely.

---

# Rollbacks

Always support:

```text id="jlwm7u"
Immediate rollback.
```

---

Visualizing:

```text id="jlwmv6"
Deploy
   |
Failure
   |
Rollback
```

---

# Logging Infrastructure

```text id="jlwmti"
Application
     |
Logs
     |
Aggregation
```

---

# Monitoring Infrastructure

```text id="jlwmi7"
Application
     |
Metrics
     |
Dashboard
```

---

# Alerting Infrastructure

Example:

```text id="jlwmw0"
CPU

Memory

Errors

Latency
```

---

# Database Backups

Always backup:

```text id="jlwm7t"
Daily
```

---

And test:

```text id="jlwmh9"
Restoration.
```

---

# Disaster Recovery

Ask:

```text id="jlwm34"
What happens
if everything dies?
```

---

# Queues

Use for:

```text id="jlwmdb"
Emails

Webhooks

AI jobs

Reports
```

---

Visualizing:

```text id="jlwm2n"
Request
    |
Queue
    |
Worker
```

---

# Cron Jobs

Example:

```text id="jlwmzm"
Cleanup

Reports

Backups
```

---

# Edge Deployment

Benefits:

```text id="jlwmn1"
Low latency.
```

---

Limitations:

```text id="jlwm9f"
Limited runtime.
```

---

# Multi-Region

Visualizing:

```text id="jlwmgo"
US

EU

ASIA
```

---

Benefits:

```text id="jlwm0r"
Lower latency

High availability
```

---

# Production Checklist

Verify:

```text id="jlwma0"
✓ HTTPS

✓ Environment variables

✓ Database migrations

✓ Backups

✓ Logging

✓ Monitoring

✓ Alerts

✓ Health checks

✓ Rollbacks

✓ Security
```

---

# Infrastructure Costs

Track:

```text id="jlwm4n"
Compute

Database

Storage

Bandwidth

Cache
```

---

# Capacity Planning

Questions:

```text id="jlwmre"
Users?

Requests?

Storage?

Growth?
```

---

# Incident Response

Pipeline:

```text id="jlwmqt"
Alert
   |
Investigate
   |
Mitigate
   |
Fix
   |
Review
```

---

# Production Architecture

Small app:

```text id="jlwm1f"
User
 |
CDN
 |
Next.js
 |
Database
```

---

Medium app:

```text id="jlwmrr"
User
 |
CDN
 |
Load Balancer
 |
Next.js
 |
Redis
 |
Database
```

---

Large app:

```text id="jlwmvn"
User
 |
CDN
 |
Edge
 |
Load Balancer
 |
Next.js Cluster
 |
Redis
 |
Queue
 |
Workers
 |
Database
 |
Storage
```

---

# Common Beginner Mistakes

---

## Mistake 1

Using local files.

---

## Mistake 2

No backups.

---

## Mistake 3

No monitoring.

---

## Mistake 4

No rollback strategy.

---

## Mistake 5

Stateful servers.

---

## Mistake 6

No health checks.

---

## Mistake 7

Deploying directly to production.

---

# Deployment Decision Tree

Need:

```text id="jlwm8o"
Fast deployment?
```

Use:

```text id="jlwmxt"
Vercel
```

---

Need:

```text id="jlwm4y"
Portability?
```

Use:

```text id="jlwm2v"
Docker
```

---

Need:

```text id="jlwm3u"
Massive scale?
```

Use:

```text id="jlwm5z"
Kubernetes
```

---

Need:

```text id="jlwm14"
Background jobs?
```

Use:

```text id="jlwmv1"
Queues
```

---

Need:

```text id="jlwmad"
High availability?
```

Use:

```text id="jlwmg0"
Multi-region
```

---

# The Complete Production Pipeline

```text id="jlwmsm"
Developer
     |
Git
     |
CI/CD
     |
Build
     |
Deploy
     |
Monitor
     |
Alert
     |
Operate
```

---

# Mental Model

Beginners think:

```text id="jlwm0b"
Deployment
=
The end.
```

Professional engineers think:

```text id="jlwm6u"
Deployment
=
The beginning.
```

Because software engineering does not end when users start using the system.

That is when the real engineering begins.
