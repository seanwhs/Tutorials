# Next.js 16 for Absolute Beginners

# Part 24 — Deployment, CI/CD, and Production Operations: Turning Projects into Products

> **Goal of this lesson:** Learn how professional Next.js applications are deployed, updated, monitored, rolled back, and operated in production environments.

---

# The Biggest Beginner Misconception

Beginners think:

```text
Write Code
    |
Run npm run build
    |
Deploy
    |
Finished
```

Professional engineers think:

```text
Write Code
    |
Test
    |
Build
    |
Deploy
    |
Monitor
    |
Rollback
    |
Improve
```

Because deployment is not the end of software engineering.

Deployment is the beginning of operations.

---

# What Is Production?

Production is simply:

> The version of your application that real users use.

Example:

```text
Laptop
    |
Development
```

```text
Server
    |
Production
```

---

# The Four Environments

Most professional systems have:

```text
Development

Testing

Staging

Production
```

---

# Visualizing Environments

```text
Developer
     |
Development
     |
Testing
     |
Staging
     |
Production
```

---

# Development Environment

Purpose:

```text
Write code

Break things

Experiment
```

Example:

```bash
npm run dev
```

---

# Testing Environment

Purpose:

```text
Run tests

Verify correctness
```

---

# Staging Environment

Purpose:

```text
Production replica
```

Example:

```text
Production
    |
Clone
    |
Staging
```

---

# Production Environment

Purpose:

```text
Serve real users.
```

---

# Why Multiple Environments?

Suppose you deploy directly:

```text
Code
   |
Production
```

Bug:

```text
Delete all users
```

Disaster.

---

# Modern Deployment Architecture

```text
Developer
      |
GitHub
      |
CI/CD
      |
Build
      |
Deploy
      |
Production
```

---

# What Is CI?

CI means:

# Continuous Integration

Every code change:

```text
Commit
    |
Test
    |
Build
    |
Validate
```

---

# What Is CD?

CD means:

# Continuous Delivery/Deployment

```text
Successful Build
        |
Deploy
        |
Production
```

---

# Visualizing CI/CD

```text
Push
   |
Tests
   |
Build
   |
Deploy
   |
Monitor
```

---

# Why CI/CD Matters

Without CI/CD:

```text
Human deployment
        |
Human mistakes
```

With CI/CD:

```text
Automation
        |
Consistency
```

---

# Our Deployment Stack

We'll use:

```text
Next.js 16
Vercel
PostgreSQL
GitHub
GitHub Actions
```

---

# Why Vercel?

Because Vercel provides:

```text
Hosting

CDN

Caching

Preview Deployments

Analytics

Observability
```

---

# Visualizing Vercel

```text
Browser
    |
CDN
    |
Vercel
    |
Next.js App
```

---

# First Production Build

Run:

```bash
npm run build
```

---

# What Happens?

```text
Source Code
       |
Compile
       |
Optimize
       |
Bundle
       |
Deployable Output
```

---

# Example Build Output

```bash
Route (app)

○ /
○ /blog
ƒ /blog/[slug]
ƒ /dashboard
```

---

# Static Routes

```text
○
```

means:

```text
Pre-rendered
```

---

# Dynamic Routes

```text
ƒ
```

means:

```text
Server rendered
```

---

# Environment Variables

Development:

```bash
.env.local
```

---

Production:

```bash
DATABASE_URL=

AUTH_SECRET=

API_KEY=
```

---

# Never Deploy Secrets

Bad:

```ts
const secret =
    "abc123";
```

---

Good:

```ts
const secret =
    process.env.AUTH_SECRET;
```

---

# Deployment Flow

```text
Git Push
     |
GitHub
     |
Vercel Build
     |
Deployment
     |
Production
```

---

# Preview Deployments

Suppose:

```text
feature/comments
```

branch exists.

Vercel creates:

```text
preview-comments.vercel.app
```

---

# Visualizing Preview Deployments

```text
Branch
    |
Deploy
    |
Temporary URL
```

---

# Why Preview Deployments Matter

Without:

```text
Merge
    |
Pray
```

With:

```text
Preview
    |
Review
    |
Merge
```

---

# Database Hosting

Popular choices:

```text
Neon

Supabase

PlanetScale

AWS RDS
```

---

# Visualizing Database Architecture

```text
Browser
     |
Next.js
     |
PostgreSQL
```

---

# Database Migrations

Suppose:

```prisma
model User {

    id Int

    email String
}
```

Later:

```prisma
model User {

    id Int

    email String

    role String
}
```

---

Migration:

```bash
npx prisma migrate deploy
```

---

# Why Migrations Matter

Without migrations:

```text
Application
      |
Database mismatch
      |
Crash
```

---

# Migration Workflow

```text
Schema Change
       |
Migration
       |
Review
       |
Deploy
```

---

# Backup Strategy

Every production system needs:

```text
Backups.
```

---

# Visualizing Backups

```text
Database
     |
Backup
     |
Storage
```

---

# Backup Schedule

Example:

```text
Hourly

Daily

Weekly
```

---

# Disaster Recovery

Question:

> What happens if production dies?

---

Example:

```text
Server failure
      |
Restore backup
      |
Redeploy
      |
Recover
```

---

# Rollback Strategy

Suppose:

```text
Deploy v2
```

Bug:

```text
Delete posts
```

Need:

```text
Rollback to v1
```

---

# Visualizing Rollback

```text
v1
 |
v2
 |
Failure
 |
Restore v1
```

---

# Blue/Green Deployment

Instead of:

```text
Old Server
     |
Replace
```

Use:

```text
Blue
 |
Green
```

---

Visualized:

```text
Users
   |
Blue v1

Green v2
```

Switch traffic only when safe.

---

# Canary Deployment

Example:

```text
1% users

10% users

50% users

100% users
```

---

# Why Canary?

Suppose:

```text
Bug affects 1%
```

instead of:

```text
Bug affects everyone
```

---

# Monitoring Deployments

Track:

```text
Errors

Latency

Memory

Database

Cache
```

---

# Example

Deployment:

```text
v2.1.4
```

Metrics:

```text
Errors:
    500%

Latency:
    3000ms
```

Immediate rollback.

---

# Production Logging

Always log:

```text
Deployments

Migrations

Failures

Restarts
```

---

# Health Checks

Create:

```text
/health
```

---

Example:

```ts
export async function GET() {

    return Response.json({

        status:
            "healthy",

    });

}
```

---

# Readiness Checks

Verify:

```text
Database

Cache

Storage

Authentication
```

---

# Production Monitoring Dashboard

Monitor:

```text
Requests/sec

Error rate

Latency

CPU

Memory

Cache hit rate

Database queries
```

---

# Rate of Change

Remember:

```text
Small deployments
```

are safer than:

```text
Massive deployments
```

---

# CI/CD Pipeline Example

```text
Push
   |
Lint
   |
Unit Tests
   |
Integration Tests
   |
Build
   |
Deploy Preview
   |
Approve
   |
Production
```

---

# GitHub Actions Example

```yaml
name: deploy

on:
  push:
    branches:
      - main

jobs:

  build:

    runs-on:
      ubuntu-latest

    steps:

      - uses:
          actions/checkout@v4

      - run:
          npm install

      - run:
          npm run test

      - run:
          npm run build
```

---

# Production Folder Structure

```text
.github/

    workflows/

docker/

scripts/

monitoring/

backups/
```

---

# Infrastructure Diagram

```text
                 Browser
                     |
                     V
                  CDN
                     |
                     V
                  Vercel
                     |
                     V
                Next.js App
                     |
            +--------+--------+
            |                 |
            V                 V
      PostgreSQL          Storage
            |
            V
         Backups
```

---

# Operational Checklist

Before every deployment:

```text
✓ Tests pass

✓ Build succeeds

✓ Migrations reviewed

✓ Backups exist

✓ Monitoring active

✓ Rollback prepared

✓ Health checks working
```

---

# Production Engineering Mindset

Don't ask:

```text
Can I deploy?
```

Ask:

```text
Can I recover?
```

Because deployment is easy.

Recovery is engineering.

---

# What We'll Deploy For Nexus CMS

```text
✓ Vercel

✓ PostgreSQL

✓ Storage

✓ Authentication

✓ Cache

✓ Monitoring

✓ CI/CD

✓ Preview Deployments

✓ Backups

✓ Recovery
```

---

# Exercises

## Exercise 1

Design a deployment pipeline for:

```text
Nexus CMS
```

---

## Exercise 2

Design a backup strategy for:

```text
PostgreSQL
```

---

## Exercise 3

Design a rollback strategy.

---

## Exercise 4

Create a production deployment checklist.

---

# What You've Learned

You now understand:

✅ deployment environments

✅ CI/CD

✅ preview deployments

✅ database migrations

✅ backups

✅ disaster recovery

✅ rollback strategies

✅ blue/green deployments

✅ canary deployments

✅ production operations

---

# Mental Model

Beginners think:

```text
Software
```

Professionals think:

```text
Software
      +
Operations
      +
Recovery
      +
Observability
      =
Production System
```

Because users don't care how elegant your code is.

They care whether the system works.

---

# Part 25 Preview

In the next chapter we'll learn:

# Scaling and System Design for Next.js Applications

Including:

* vertical scaling
* horizontal scaling
* caching layers
* CDN architecture
* database scaling
* read replicas
* queues
* background jobs
* distributed systems
* event-driven architecture
* designing internet-scale applications

This is where developers start becoming system architects.
