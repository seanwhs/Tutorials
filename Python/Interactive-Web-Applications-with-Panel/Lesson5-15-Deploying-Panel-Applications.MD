# Part V — Working with Live SGX Market Data

# Lesson 5.15 — Deploying Panel Applications: Serving, Packaging, Authentication, Cloud Deployment, and Production Architecture

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what deployment means.
> * Learn how Panel applications are served.
> * Understand the client-server architecture of Panel.
> * Deploy applications locally.
> * Package Panel applications for production.
> * Configure authentication.
> * Deploy using Docker.
> * Deploy to cloud platforms.
> * Understand reverse proxies and production architecture.
> * Think like a production systems engineer.

---

# Introduction

Our SGX Market Workstation now contains:

* live market data
* technical analysis
* watchlists
* portfolios
* alerts
* market intelligence
* real-time dashboards

Currently, it runs like this:

```bash
panel serve app.py
```

on our laptop.

This is excellent for development.

It is terrible for production.

---

# What Is Deployment?

Deployment means:

> Making software available for real users.

---

# Development vs Production

## Development

```text
You

↓

Your Computer

↓

Application
```

---

## Production

```text
Users

↓

Internet

↓

Servers

↓

Application

↓

Database

↓

External APIs
```

---

# Why Deployment Is Difficult

When building software, beginners think:

> Writing code is the hard part.

Professional engineers know:

> Running software is the hard part.

---

# What Happens When We Run Panel?

Suppose we execute:

```bash
panel serve dashboard.py
```

Panel starts:

```text
HTTP Server

+

WebSocket Server

+

Python Runtime

+

Session Manager
```

---

# Understanding Panel Architecture

Internally:

```text
Browser

↓

HTTP Request

↓

Panel Server

↓

Python Code

↓

Panel Components

↓

Browser
```

---

# Why Is This Important?

Because Panel is not:

```text
HTML

+

CSS

+

JavaScript
```

Instead:

```text
Python

↓

Server

↓

Browser
```

---

# Traditional Website Architecture

```text
Browser

↓

Web Server

↓

Static HTML
```

---

# Panel Architecture

```text
Browser

↓

WebSocket

↓

Python Server

↓

Live Objects
```

---

# What Is A WebSocket?

A WebSocket is:

> A permanent connection between browser and server.

---

# Traditional HTTP

```text
Request

↓

Response

↓

Connection Closed
```

---

# WebSocket

```text
Connection Open

↓

Message

↓

Message

↓

Message

↓

Message
```

---

# Why Does Panel Need WebSockets?

Suppose DBS updates:

```text
41.35

↓

41.50
```

Panel immediately sends:

```text
Update Price Widget
```

to the browser.

No page refresh required.

---

# Running A Local Server

The simplest deployment:

```bash
panel serve app.py
```

---

# What Happens?

Panel starts:

```text
localhost:5006
```

---

# Visual Architecture

```text
Browser

↓

localhost:5006

↓

Panel Server
```

---

# Opening Multiple Applications

Suppose we have:

```text
dashboard.py

portfolio.py

analytics.py
```

We can serve:

```bash
panel serve *.py
```

---

# Result

```text
localhost:5006/dashboard

localhost:5006/portfolio

localhost:5006/analytics
```

---

# Understanding Sessions

Suppose:

```text
User A

User B
```

open the application.

Panel creates:

```text
Session A

Session B
```

independently.

---

# Why Sessions Matter

Without sessions:

```text
User A

Changes Dashboard

↓

User B Sees Changes
```

which would be disastrous.

---

# Session Architecture

```text
User

↓

Browser Session

↓

Panel Session

↓

Python Objects
```

---

# Understanding Session State

Example:

```python
watchlist = []
```

might exist separately for:

```text
User A

and

User B
```

---

# Running Production Servers

Development:

```bash
panel serve app.py
```

Production:

```bash
panel serve app.py \
    --address 0.0.0.0 \
    --port 80
```

---

# Understanding IP Addresses

Development:

```text
localhost
```

means:

```text
Only Me
```

Production:

```text
0.0.0.0
```

means:

```text
Everybody
```

---

# Configuring Static Assets

Suppose we have:

```text
images/

css/

js/
```

Panel supports:

```bash
--static-dirs
```

---

# Example

```bash
panel serve app.py \
    --static-dirs assets=./assets
```

---

# Why Static Assets Matter

Applications often require:

* logos
* charts
* icons
* CSS
* JavaScript
* images

---

# Authentication

Real applications require:

```text
Who Are You?
```

---

# Authentication Examples

```text
Username

Password

SSO

OAuth

LDAP

Active Directory
```

---

# Why Authentication Matters

Suppose our portfolio dashboard contains:

```text
My Investments
```

Should everyone see them?

Obviously not.

---

# Simple Authentication

Example:

```python
user = authenticate(
    username,
    password
)
```

---

# Authorization vs Authentication

These concepts are often confused.

---

# Authentication

Answers:

```text
Who Are You?
```

---

# Authorization

Answers:

```text
What Are You Allowed To Do?
```

---

# Example

```text
Sean

↓

Authenticated

↓

Can View Portfolio

↓

Cannot Delete Database
```

---

# Environment Variables

Never do this:

```python
API_KEY = "abc123"
```

---

# Why?

Because:

```text
GitHub

↓

Public Repository

↓

API Key Leaked
```

---

# Correct Approach

Use:

```python
import os

API_KEY = os.getenv(
    "API_KEY"
)
```

---

# Example Environment File

```text
.env

API_KEY=xxxxx
SECRET_KEY=xxxxx
DATABASE_URL=xxxxx
```

---

# What Is Docker?

Docker packages applications into:

> Containers.

---

# Why Containers?

Without Docker:

```text
Works On My Machine
```

becomes:

```text
Fails Everywhere Else
```

---

# Container Architecture

```text
Application

+

Python

+

Libraries

+

Dependencies

↓

Container
```

---

# Example Dockerfile

```dockerfile
FROM python:3.12

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt

CMD [
    "panel",
    "serve",
    "app.py"
]
```

---

# Understanding Dockerfile Commands

---

## FROM

```dockerfile
FROM python:3.12
```

defines:

```text
Base Operating System
```

---

## WORKDIR

```dockerfile
WORKDIR /app
```

defines:

```text
Current Folder
```

---

## COPY

```dockerfile
COPY . .
```

copies:

```text
Project Files
```

---

## RUN

```dockerfile
RUN pip install
```

installs:

```text
Dependencies
```

---

## CMD

```dockerfile
CMD
```

defines:

```text
How To Start
```

---

# Building Containers

```bash
docker build -t sgx-dashboard .
```

---

# Running Containers

```bash
docker run -p 5006:5006 sgx-dashboard
```

---

# Visualizing Container Deployment

```text
Browser

↓

Docker Container

↓

Panel Server

↓

Market APIs
```

---

# Reverse Proxies

Production systems rarely expose:

```text
Panel Server

Directly
```

---

# Instead

```text
Internet

↓

Nginx

↓

Panel Server
```

---

# What Is Nginx?

Nginx is:

> A reverse proxy and web server.

---

# Why Use Reverse Proxies?

They provide:

* security
* HTTPS
* load balancing
* caching
* routing
* compression

---

# Reverse Proxy Architecture

```text
Users

↓

Nginx

↓

Panel

↓

Application
```

---

# HTTPS

Suppose users connect:

```text
http://
```

Traffic is unencrypted.

---

# Instead:

```text
https://
```

provides:

```text
Encryption
```

---

# Why Encryption Matters

Without HTTPS:

```text
Password

↓

Network

↓

Attackers
```

---

# Cloud Deployment

Eventually applications move to:

* AWS
* Azure
* Google Cloud
* DigitalOcean
* Render
* Railway

---

# Cloud Architecture

```text
Users

↓

Internet

↓

Cloud Load Balancer

↓

Container

↓

Panel Application

↓

External APIs
```

---

# Why Cloud?

Benefits include:

* scalability
* reliability
* backups
* monitoring
* global access

---

# Scaling Applications

Suppose:

```text
10 Users
```

becomes:

```text
10,000 Users
```

One server becomes insufficient.

---

# Horizontal Scaling

Instead of:

```text
One Big Server
```

we deploy:

```text
Many Small Servers
```

---

# Visualizing Scaling

```text
Load Balancer

↓

Server 1

Server 2

Server 3
```

---

# Monitoring Production Systems

Professional deployments monitor:

* CPU
* memory
* network
* errors
* response time
* API usage
* user sessions

---

# Example Dashboard Metrics

```text
Users:

142

CPU:

32%

Memory:

65%

API Errors:

0.2%
```

---

# Logging

Suppose something fails.

Without logs:

```text
Mystery
```

With logs:

```text
Timestamp

User

Action

Error
```

---

# Example Logging

```python
import logging

logging.info(
    "Portfolio loaded"
)
```

---

# Error Handling

Production systems assume:

```text
Everything Eventually Fails
```

Examples:

* APIs fail
* networks fail
* disks fail
* users fail
* developers fail

---

# Production Architecture For Our SGX Dashboard

```text
Users

↓

HTTPS

↓

Nginx

↓

Docker Container

↓

Panel Server

↓

Market Service

↓

Financial APIs

↓

Caching Layer

↓

Monitoring
```

---

# Understanding Operational Excellence

Beginners think:

> Software engineering ends when code compiles.

Professionals know:

> Software engineering begins when users arrive.

---

# Thinking Like A Production Engineer

Beginners ask:

> How do I run my app?

Professionals ask:

> How do I keep my app running for five years?

This question changes:

* architecture
* deployment
* monitoring
* authentication
* logging
* scalability
* operations

---

# Teacher's Notes

> One of the most important realizations in software engineering is that development and operations are fundamentally different disciplines. Writing a successful application requires one skill set; operating a successful application requires another.
>
> Another important lesson is that production architecture is largely about managing failure. Every design decision in production systems ultimately revolves around reliability, observability, security, and recovery.

---

# Common Mistakes

## ❌ Mistake 1

Hardcoding API keys.

---

## ❌ Mistake 2

Deploying without HTTPS.

---

## ❌ Mistake 3

Ignoring logging.

---

## ❌ Mistake 4

Running production directly from development settings.

---

## ❌ Mistake 5

Assuming servers never fail.

---

# Summary

In this lesson, you learned:

* Deployment makes applications available to users.
* Panel applications operate as server-based applications.
* WebSockets enable live updates.
* Sessions isolate users.
* Environment variables protect secrets.
* Docker packages applications.
* Reverse proxies secure deployments.
* Cloud platforms provide scalability.
* Monitoring and logging are essential.
* Production engineering focuses on reliability.

Congratulations.

You have now completed the journey from:

```text
print("Hello World")
```

to:

```text
Professional Real-Time Financial Analytics Platform
```

built using:

* Python
* Panel
* Pandas
* Real-time APIs
* Financial analytics
* Dashboard engineering
* Production deployment

---

# Exercises

## Exercise 1 — Architecture Diagram

Draw the production architecture for:

```text
User

↓

Internet

↓

???

↓

Panel Dashboard

↓

Financial API
```

Include all missing components.

---

## Exercise 2 — Security Review

Identify security problems in:

```python
API_KEY = "123456"

PASSWORD = "admin"

DEBUG = True
```

---

## Exercise 3 — Deployment Comparison

Compare:

* local deployment
* Docker deployment
* cloud deployment

Discuss:

* complexity
* scalability
* cost
* maintenance

---

# Coming Up Next

In **Part VI — Advanced Panel: Templates, Reactive Programming, Param, Custom Components, and Enterprise Dashboard Architecture**, we will move beyond simply building dashboards and begin learning how Panel itself works internally, including reactive programming, Param-based state management, templates, component architecture, extensibility, custom widgets, and enterprise-scale dashboard engineering.
