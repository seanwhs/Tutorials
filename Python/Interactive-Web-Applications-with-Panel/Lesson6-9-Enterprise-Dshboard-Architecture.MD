# Part VI — Advanced Panel: Templates, Reactive Programming, Param, Custom Components, and Enterprise Dashboard Architecture

# Lesson 6.8 — Deployment Architecture: Bokeh Server, Panel Serve, FastAPI Integration, Docker, Reverse Proxies, Authentication, and Production Panel Systems

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand how Panel applications run in production.
> * Learn the architecture of `panel serve`.
> * Understand Bokeh Server internals.
> * Integrate Panel with FastAPI.
> * Containerize Panel applications using Docker.
> * Configure reverse proxies.
> * Implement authentication and authorization.
> * Deploy scalable enterprise dashboard systems.
> * Understand cloud deployment patterns.
> * Think like a platform engineer rather than an application developer.

---

# Introduction

Throughout this tutorial, we've run Panel applications like this:

```bash
panel serve app.py
```

The browser opens.

Everything works.

Life is good.

---

# Then Reality Arrives

Management asks:

> Deploy the SGX Trading Dashboard for 500 traders.

Suddenly we need:

* authentication
* HTTPS
* load balancing
* containers
* monitoring
* scaling
* failover
* security
* reverse proxies
* cloud infrastructure

At this point:

```bash
panel serve app.py
```

is no longer enough.

---

# The First Misconception

Most beginners think:

```text
Panel

↓

Browser
```

---

# Reality

The architecture is:

```text
Browser

↓

WebSocket

↓

Bokeh Server

↓

Panel

↓

Python
```

---

# Visualizing The Architecture

```text
User

↓

Browser

↓

HTTP

↓

Bokeh Server

↓

Panel App

↓

Python State
```

---

# Why Bokeh Server Exists

Remember:

Panel applications are:

```text
Stateful Applications
```

Unlike:

```text
HTML Pages
```

---

# Example

Suppose:

```python
counter += 1
```

The server must remember:

```text
counter
```

for each user.

---

# Therefore

Panel applications require:

```text
Server-Side State
```

---

# Understanding `panel serve`

Example:

```bash
panel serve app.py
```

internally launches:

```text
Bokeh Server
```

---

# Visualizing

```text
panel serve

↓

Bokeh Server

↓

HTTP Server

↓

WebSocket Server
```

---

# Why WebSockets?

Traditional websites use:

```text
Request

↓

Response
```

---

# Panel uses:

```text
Bidirectional Communication
```

---

# Visualizing

```text
Browser

↕

WebSocket

↕

Python
```

---

# Example

User moves:

```text
Slider
```

---

# Message Flow

```text
Browser

↓

WebSocket

↓

Python

↓

Update State

↓

WebSocket

↓

Browser
```

---

# Why WebSockets Matter

Financial dashboards require:

* real-time updates
* live charts
* notifications
* streaming data

HTTP alone cannot efficiently provide this.

---

# Running Production Servers

Development:

```bash
panel serve app.py
```

---

# Production:

```bash
panel serve app.py \
    --address 0.0.0.0 \
    --port 5006 \
    --num-procs 4
```

---

# Understanding Processes

Suppose:

```text
500 Users
```

connect.

One process becomes:

```text
Bottleneck
```

---

# Multiple Processes

```text
User Requests

↓

Load Balancer

↓

Process 1

Process 2

Process 3

Process 4
```

---

# Understanding Session Architecture

Each user receives:

```text
Own Session
```

---

# Example

User A:

```text
Portfolio A
```

---

# User B:

```text
Portfolio B
```

---

# Visualizing

```text
Bokeh Server

├── Session A
├── Session B
├── Session C
└── Session D
```

---

# Why Sessions Matter

Suppose:

```python
portfolio = []
```

is global.

Then:

```text
All Users

Share Portfolio
```

which is:

```text
Very Bad
```

---

# Rule

Always prefer:

```text
Session State
```

over:

```text
Global State
```

---

# Understanding FastAPI Integration

Many enterprises already use:

* FastAPI
* Flask
* Django

---

# Example Architecture

```text
Browser

↓

FastAPI

↓

Authentication

↓

Panel
```

---

# Why Combine FastAPI And Panel?

Because:

| FastAPI        | Panel         |
| -------------- | ------------- |
| APIs           | Dashboards    |
| Authentication | Visualization |
| Business Logic | UI            |
| REST           | Reactivity    |

---

# Example

```python
from fastapi import FastAPI

app = FastAPI()
```

---

# Architecture

```text
FastAPI

├── /api
├── /login
├── /logout
└── /dashboard
```

---

# Visualizing

```text
User

↓

FastAPI

├── API
└── Panel App
```

---

# Example Enterprise Architecture

```text
Browser

↓

NGINX

↓

FastAPI

↓

Panel

↓

Redis

↓

Database
```

---

# Understanding Docker

Production applications should be:

```text
Portable
```

---

# Docker Provides

* isolation
* portability
* reproducibility
* deployment simplicity

---

# Example Dockerfile

```dockerfile
FROM python:3.12

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt

EXPOSE 5006

CMD [
    "panel",
    "serve",
    "app.py",
    "--address",
    "0.0.0.0"
]
```

---

# Visualizing

```text
Code

↓

Docker Image

↓

Docker Container

↓

Server
```

---

# Why Containers Matter

Without Docker:

```text
Works On My Machine
```

---

# With Docker:

```text
Works Everywhere
```

---

# Understanding Reverse Proxies

Users should never connect directly to:

```text
Bokeh Server
```

---

# Instead:

```text
User

↓

NGINX

↓

Panel
```

---

# Why Reverse Proxies Exist

Reverse proxies provide:

* HTTPS
* security
* compression
* routing
* caching
* load balancing

---

# Example Architecture

```text
Internet

↓

NGINX

↓

Panel Cluster
```

---

# NGINX Example

```nginx
location /dashboard {

    proxy_pass
        http://localhost:5006;

    proxy_set_header Upgrade
        $http_upgrade;

    proxy_set_header Connection
        "upgrade";
}
```

---

# Why Upgrade Headers?

Because Panel requires:

```text
WebSockets
```

and WebSockets require:

```text
HTTP Upgrade
```

---

# Load Balancing

Suppose:

```text
1000 Traders
```

connect.

---

# Architecture

```text
NGINX

├── Panel 1
├── Panel 2
├── Panel 3
└── Panel 4
```

---

# Benefits

Load balancing provides:

* scalability
* redundancy
* failover
* performance

---

# Authentication

Financial systems require:

* login
* permissions
* audit trails
* security

---

# Authentication Architecture

```text
User

↓

Login

↓

JWT Token

↓

Panel Dashboard
```

---

# Common Authentication Methods

| Method            | Usage      |
| ----------------- | ---------- |
| Username/password | Internal   |
| LDAP              | Enterprise |
| OAuth             | Cloud      |
| OpenID Connect    | Enterprise |
| SAML              | Corporate  |

---

# Example

```text
User

↓

Microsoft Login

↓

Azure AD

↓

Panel Dashboard
```

---

# Authorization

Authentication answers:

```text
Who Are You?
```

---

# Authorization answers:

```text
What Can You Access?
```

---

# Example

Trader:

```text
View Portfolio
```

---

# Administrator:

```text
View Everything
```

---

# Security Layers

```text
Internet

↓

Firewall

↓

Reverse Proxy

↓

Authentication

↓

Authorization

↓

Panel
```

---

# HTTPS

Never deploy financial dashboards using:

```text
HTTP
```

---

# Always use:

```text
HTTPS
```

---

# Why?

HTTPS provides:

* encryption
* authentication
* integrity

---

# Cloud Deployment

Popular cloud platforms:

* AWS
* Azure
* GCP

---

# Example Architecture

```text
Internet

↓

Cloud Load Balancer

↓

Kubernetes

↓

Panel Pods

↓

Redis

↓

Database
```

---

# Understanding Kubernetes

Kubernetes manages:

* containers
* scaling
* failover
* deployment
* orchestration

---

# Visualizing

```text
Cluster

├── Pod
├── Pod
├── Pod
└── Pod
```

---

# Why Kubernetes?

Suppose:

```text
Server Dies
```

---

# Kubernetes:

```text
Create New Server
```

automatically.

---

# Background Tasks

Suppose analytics require:

```text
30 Minutes
```

to calculate.

---

# Bad

```text
User Waits
```

---

# Better

```text
Background Worker

↓

Calculation

↓

Store Result

↓

Dashboard Update
```

---

# Example Architecture

```text
Panel

↓

Queue

↓

Worker

↓

Database
```

---

# Message Queues

Common queue systems:

* Redis
* RabbitMQ
* Kafka
* Celery

---

# Example

```text
Dashboard

↓

Redis Queue

↓

Worker Pool
```

---

# Caching Layer

Production systems often use:

```text
Redis
```

---

# Architecture

```text
Market Feed

↓

Redis Cache

↓

Analytics

↓

Panel
```

---

# Why Redis?

Redis provides:

* caching
* pub/sub
* sessions
* queues
* real-time messaging

---

# Monitoring

Production systems must monitor:

* CPU
* memory
* latency
* throughput
* errors
* sessions

---

# Example Stack

```text
Panel

↓

Prometheus

↓

Grafana
```

---

# Metrics Example

```text
Users:        523

CPU:          32%

Memory:       5.2 GB

Latency:      120 ms

WebSockets:   487
```

---

# Logging

Every enterprise application requires:

```text
Structured Logging
```

---

# Example

```text
Timestamp

User

Session

Action

Result
```

---

# Audit Trails

Financial systems require:

```text
User

↓

Action

↓

Timestamp

↓

Record
```

---

# Example

```text
Trader A

↓

Bought DBS

↓

10:15:23

↓

Stored
```

---

# High Availability

Professional systems avoid:

```text
Single Point Of Failure
```

---

# Example

Bad:

```text
1 Server
```

---

# Better:

```text
Load Balancer

├── Server A
├── Server B
└── Server C
```

---

# Disaster Recovery

Suppose:

```text
Data Center Fails
```

---

# Solution

```text
Primary Region

↓

Backup Region
```

---

# Enterprise Deployment Architecture

```text
Internet

↓

CDN

↓

Load Balancer

↓

NGINX

↓

Authentication

↓

FastAPI

↓

Panel Cluster

↓

Redis

↓

Workers

↓

Database
```

---

# SGX Professional Architecture

```text
Users

↓

Cloudflare

↓

NGINX

↓

Authentication

↓

FastAPI

↓

Panel

↓

Redis

↓

Kafka

↓

Market Feed
```

---

# Development vs Production

Development:

```bash
panel serve app.py
```

---

# Production:

```text
Cloud

↓

Containers

↓

Load Balancers

↓

Authentication

↓

Monitoring

↓

Scaling
```

---

# Thinking Like A Platform Engineer

Beginners ask:

> How do I run my dashboard?

Intermediate developers ask:

> How do I deploy my dashboard?

Platform engineers ask:

> How do I operate this dashboard reliably for 10,000 users?

Because deployment is not:

```text
Running Code
```

It is:

```text
Operating Systems
```

---

# The Hidden Secret

Most failures in production systems occur because of:

```text
Infrastructure
```

rather than:

```text
Application Code
```

---

# Teacher's Notes

> One of the biggest transitions from application engineering to platform engineering is realizing that software does not run in isolation. It runs inside networks, operating systems, containers, clouds, load balancers, and organizations.
>
> Another important lesson is that deployment architecture often becomes more complex than application architecture itself.

---

# Common Mistakes

## ❌ Mistake 1

Deploying with `panel serve app.py` directly to production.

---

## ❌ Mistake 2

Ignoring WebSocket requirements.

---

## ❌ Mistake 3

Using global state.

---

## ❌ Mistake 4

Skipping authentication.

---

## ❌ Mistake 5

Not monitoring production systems.

---

# Summary

In this lesson, you learned:

* Panel applications run on Bokeh Server.
* WebSockets provide real-time communication.
* Sessions isolate user state.
* FastAPI complements Panel.
* Docker enables portability.
* Reverse proxies provide security and scalability.
* Authentication and authorization are essential.
* Redis supports caching and messaging.
* Kubernetes enables orchestration and failover.
* Production engineering is fundamentally systems engineering.

You now understand how professional Panel applications are deployed and operated in enterprise environments.

---

# Exercises

## Exercise 1 — Design A Production Architecture

Design a deployment architecture for:

```text
SGX Professional Trading Platform
```

including:

* authentication
* caching
* monitoring
* deployment
* failover

---

## Exercise 2 — Build A Container Strategy

Design Docker containers for:

* Panel
* FastAPI
* Redis
* Worker services
* Database services

---

## Exercise 3 — Design A High Availability System

Create an architecture capable of supporting:

```text
10,000 Concurrent Traders
```

with:

* load balancing
* session management
* caching
* monitoring
* disaster recovery

---

# Coming Up Next

In **Lesson 6.9 — Enterprise Dashboard Architecture: State Management, Service Layers, Domain Models, Event-Driven Design, and Building Bloomberg-Scale Panel Applications**, we'll bring everything together and learn how professional organizations architect massive dashboard ecosystems using layered architecture, state management, domain-driven design, event buses, service layers, and component ecosystems.
