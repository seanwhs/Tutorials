# Next.js 16 for Absolute Beginners

# Part 44 — Deployment, Infrastructure, Containers, CI/CD, and Production Architecture

> **Goal of this lesson:** Learn how professional engineers deploy, operate, scale, and continuously deliver Next.js 16 applications using containers, CI/CD pipelines, cloud infrastructure, Kubernetes, and production deployment strategies.

---

# The Sixth Biggest Lie in Software Engineering

The first lie:

> Users wait.

The second lie:

> Everything happens immediately.

The third lie:

> Users refresh pages.

The fourth lie:

> Tests passing means production works.

The fifth lie:

> Testing is about finding bugs.

The sixth lie:

> If it runs on my machine, it's done.

Unfortunately:

```text
Works On Laptop
       ≠
Works In Production
```

---

# What Is Deployment?

Beginners think deployment means:

```bash
npm run build
```

Professional engineers think deployment means:

> Moving software safely from development into production.

---

# The Real System

Your application isn't:

```text
Next.js
```

Your application is:

```text
Application
      +
Database
      +
Cache
      +
Storage
      +
Queue
      +
Workers
      +
Monitoring
      +
CI/CD
      +
Infrastructure
```

---

# What We're Building

By the end of this chapter, we'll understand:

```text
✓ Production builds
✓ Environment variables
✓ Docker
✓ Containers
✓ CI/CD pipelines
✓ Vercel deployment
✓ Cloud deployment
✓ Kubernetes
✓ Scaling
✓ Production architectures
✓ Zero-downtime deployment
✓ Disaster recovery
```

---

# Part 1 — Production Builds

Development:

```bash
npm run dev
```

Production:

```bash
npm run build
npm run start
```

---

# What Happens During Build?

```text
Source Code
      |
Compilation
      |
Optimization
      |
Bundling
      |
Server Build
      |
Client Build
      |
Artifacts
```

---

# Example Output

```bash
.next/

server/

static/

cache/

chunks/
```

---

# Why Build?

Development optimizes:

```text
Developer speed
```

Production optimizes:

```text
User speed
```

---

# Part 2 — Environment Variables

Never do this:

```ts
const password =
  "super-secret";
```

---

Use:

```env
DATABASE_URL=

JWT_SECRET=

REDIS_URL=

API_KEY=
```

---

# Access

```ts
process.env
  .DATABASE_URL
```

---

# Why?

Because:

```text
Code
    ≠
Configuration
```

---

# Example

Development:

```env
DATABASE_URL=localhost
```

Production:

```env
DATABASE_URL=postgres
```

---

# Part 3 — Docker

Problem:

```text
Works on my laptop.
```

---

Solution:

```text
Containerize.
```

---

# What Is Docker?

Docker packages:

```text
Application
     +
Dependencies
     +
Operating System
```

into:

```text
Container
```

---

# Visualizing

```text
Application
      |
Docker Image
      |
Docker Container
```

---

# Create Dockerfile

```dockerfile
FROM node:22

WORKDIR /app

COPY . .

RUN npm install

RUN npm run build

CMD ["npm","start"]
```

---

# Build

```bash
docker build -t app .
```

---

# Run

```bash
docker run app
```

---

# Why Containers?

Because:

```text
My laptop
```

becomes:

```text
Every laptop.
```

---

# Part 4 — Multi-Stage Builds

Bad:

```dockerfile
FROM node

COPY .

RUN npm install

RUN npm build
```

Large image.

---

Better:

```dockerfile
FROM node:22 AS builder

COPY .

RUN npm install

RUN npm run build
```

---

Then:

```dockerfile
FROM node:22

COPY --from=builder

CMD ["npm","start"]
```

---

# Benefits

```text
✓ Smaller
✓ Faster
✓ More secure
```

---

# Part 5 — CI/CD

CI means:

```text
Continuous Integration
```

CD means:

```text
Continuous Delivery
```

---

# Visualizing

```text
Git Push
    |
Tests
    |
Build
    |
Deploy
```

---

# Example Pipeline

```yaml
name: deploy

on: push

jobs:

  test:

    steps:

      - run:
          npm test

      - run:
          npm run build
```

---

# Why CI/CD?

Humans:

```text
Forget.
```

Pipelines:

```text
Never forget.
```

---

# Part 6 — Deploying to Vercel

Next.js's natural home is:

Vercel

---

# Deployment

```bash
npm install -g vercel

vercel
```

---

# Visualizing

```text
GitHub
    |
Vercel
    |
Production
```

---

# Features

```text
✓ CDN

✓ Edge

✓ Serverless

✓ Caching

✓ Rollbacks

✓ Analytics
```

---

# Part 7 — Production Database

Never deploy:

```text
SQLite
```

to production.

---

Use:

```text
PostgreSQL

MySQL

Cloud SQL
```

---

# Architecture

```text
Next.js
    |
Database
```

---

# Why?

Because production requires:

```text
✓ Backups

✓ Replication

✓ Recovery
```

---

# Part 8 — Redis

Production systems use:

```text
Redis
```

for:

```text
Caching

Sessions

Queues

Pub/Sub
```

---

# Architecture

```text
Browser
   |
Next.js
   |
Redis
```

---

# Part 9 — Object Storage

Never store uploads:

```text
Inside the container.
```

---

Use:

```text
S3

R2

GCS

Azure Blob
```

---

# Architecture

```text
User
   |
Storage
   |
Next.js
```

---

# Why?

Containers are:

```text
Temporary.
```

---

# Part 10 — Horizontal Scaling

One server:

```text
Users
   |
Server
```

---

Multiple servers:

```text
Users
   |
Load Balancer
   |
+---- Server 1
|
+---- Server 2
|
+---- Server 3
```

---

# Why?

Because eventually:

```text
One server dies.
```

---

# Part 11 — Load Balancers

Load balancers:

```text
Receive
Request
Distribute
```

---

Example:

```text
User
   |
Load Balancer
   |
App Servers
```

---

# Benefits

```text
✓ Availability

✓ Scaling

✓ Failover
```

---

# Part 12 — Kubernetes

Eventually containers become:

```text
Hundreds.
```

---

Use:

```text
Kubernetes
```

---

# Kubernetes manages:

```text
✓ Containers

✓ Networking

✓ Scaling

✓ Recovery

✓ Deployments
```

---

# Visualizing

```text
Kubernetes
       |
       +--- Pod
       |
       +--- Pod
       |
       +--- Pod
```

---

# Example Deployment

```yaml
replicas: 3

containers:

  - image:
      nextjs-app
```

---

# Result

```text
3 copies
of your app.
```

---

# Part 13 — Auto Scaling

Suppose:

```text
100 users
```

becomes:

```text
100,000 users.
```

---

Autoscaling:

```text
CPU > 80%
        |
Create Server
```

---

# Visualizing

```text
Traffic
   |
Increase
   |
More Servers
```

---

# Part 14 — Blue-Green Deployment

Bad:

```text
Replace
Production
```

---

Good:

```text
Blue
Production

Green
New Version
```

---

# Visualizing

```text
Traffic

    |

Blue
v1

Green
v2
```

---

# Switch

```text
Traffic
    |
Green
```

---

# Benefits

```text
✓ Zero downtime

✓ Easy rollback
```

---

# Part 15 — Canary Deployment

Instead of:

```text
100%
```

deploy:

```text
5%
```

---

Then:

```text
5%
25%
50%
100%
```

---

# Why?

Because:

```text
Explosions
should be small.
```

---

# Part 16 — Rollbacks

Every deployment must support:

```text
Undo.
```

---

Example:

```text
Version 44
fails
```

Rollback:

```text
Version 43
```

---

# Visualizing

```text
v41

v42

v43

v44
 |
fail
 |
rollback
```

---

# Part 17 — Backups

Back up:

```text
✓ Database

✓ Storage

✓ Configuration

✓ Secrets
```

---

# Rule

```text
No backup

=
No data.
```

---

# Part 18 — Disaster Recovery

Question:

```text
What if AWS dies?
```

---

Plan:

```text
Primary

Secondary

Recovery
```

---

# Visualizing

```text
Region A
    |
FAIL
    |
Region B
```

---

# Part 19 — Production Architecture

Small startup:

```text
Browser
    |
Next.js
    |
Postgres
```

---

Growing company:

```text
Browser
    |
Load Balancer
    |
Next.js Cluster
    |
Redis
    |
Postgres
```

---

Enterprise:

```text
Browser
    |
CDN
    |
Load Balancer
    |
Kubernetes
    |
Services
    |
Queues
    |
Databases
    |
Caches
```

---

# Part 20 — Full Production Architecture

```text
                    Browser
                        |
                        V
                      CDN
                        |
                        V
                 Load Balancer
                        |
          +-------------+-------------+
          |             |             |
          V             V             V
      Next.js       Next.js       Next.js
          |             |             |
          +------+------+-------------+
                 |
                 V
              Redis
                 |
                 V
            PostgreSQL
                 |
                 V
              Workers
                 |
                 V
             Storage
```

---

# Deployment Checklist

Always verify:

```text
✓ Tests

✓ Build

✓ Environment variables

✓ Database migrations

✓ Caching

✓ Monitoring

✓ Logging

✓ Alerts

✓ Backups

✓ Rollback
```

---

# What We've Built

```text
✓ Production builds

✓ Docker

✓ Containers

✓ CI/CD

✓ Vercel

✓ Scaling

✓ Kubernetes

✓ Blue-green deploys

✓ Canary deploys

✓ Disaster recovery
```

---

# Deployment Philosophy

Beginners think:

```text
Deploying
=
Uploading files.
```

Professional engineers think:

```text
Deploying
=
Managing risk.
```

Because deployments don't fail due to technology.

They fail due to uncertainty.

---

# Exercises

## Exercise 1

Create:

```text
Dockerfile
```

for your app.

---

## Exercise 2

Build:

```text
GitHub Actions
pipeline.
```

---

## Exercise 3

Implement:

```text
Blue-green deployment.
```

---

## Exercise 4

Design:

```text
100,000 user
architecture.
```

---

# Mental Model

Beginners build:

```text
Applications.
```

Professional engineers build:

```text
Systems
that survive reality.
```

Because software engineering ends not when code works.

It ends when operations work.

---

# Part 45 Preview

In the next chapter we'll build:

# Software Architecture, Engineering Judgment, and Thinking Like a Staff Engineer

Including:

```text
✓ Monoliths
✓ Microservices
✓ Event-driven systems
✓ Distributed systems
✓ Tradeoffs
✓ Architectural decisions
✓ Scalability
✓ Complexity
✓ Engineering judgment
✓ Thinking in systems
```

This is where Next.js stops being a framework and becomes a vehicle for learning software engineering itself.
