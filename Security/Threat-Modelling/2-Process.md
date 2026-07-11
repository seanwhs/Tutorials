# Threat Modeling Course

# Part 2 – The Practical Process

## From Architecture to Actionable Threat Models

> **Module Duration:** 4–5 Hours (Lecture + Hands-on Workshop)
>
> **Objective:** Learn how to systematically decompose a software system, identify critical assets, map attack surfaces, define trust boundaries, and produce a professional threat model that can be used by developers, architects, and security teams.

---

# Learning Objectives

By the end of this module, learners will be able to:

* Define the scope of a threat modeling exercise.
* Identify business-critical assets and supporting assets.
* Recognize different types of actors and threat agents.
* Enumerate entry points and attack surfaces.
* Identify trust boundaries within complex architectures.
* Decompose large systems into manageable components.
* Produce a complete Data Flow Diagram (DFD).
* Prepare a system for formal threat analysis using STRIDE (covered in Part 3).

---

# Module Overview

```text
Part 2
│
├── Scoping the Exercise
├── Identifying Assets
├── Identifying Actors
├── Threat Agents
├── Identifying Entry Points
├── Understanding Attack Surfaces
├── Identifying Trust Boundaries
├── System Decomposition
├── Building a Complete DFD
├── Practical Web Application Example
├── Common Mistakes
├── Hands-on Workshop
└── Deliverables
```

---

# Chapter 1 – Defining the Scope

One of the most common mistakes in threat modeling is attempting to model **everything**.

Large enterprise systems may contain:

* Hundreds of APIs
* Thousands of servers
* Dozens of cloud services
* Multiple databases
* Legacy applications
* Third-party integrations

Attempting to analyze the entire enterprise at once is impractical.

Instead, define a clear scope.

---

## What is Scope?

The scope defines:

* What is included
* What is excluded
* System boundaries
* Business objectives
* Assumptions
* Constraints

Without a defined scope, the threat model becomes unfocused and difficult to maintain.

---

## Example Scope

**System**

Customer Online Banking Portal

Included

* Customer login
* Account management
* Fund transfers
* Transaction history
* Mobile application API
* Authentication service

Excluded

* ATM network
* Internal banking systems
* HR systems
* Corporate intranet

---

## Questions to Define Scope

Ask the following before beginning:

### Business Questions

* What problem does the system solve?
* What data is most valuable?
* What regulations apply?
* What would happen if the system failed?

### Technical Questions

* What technologies are used?
* Where is the application hosted?
* What third parties are involved?
* What communication protocols exist?

### Security Questions

* What authentication methods exist?
* Who are the users?
* What security controls already exist?

---

# Chapter 2 – Identifying Assets

Threat modeling starts with understanding **what you are protecting**.

If there are no valuable assets, there is no reason for attackers to target the system.

---

## What is an Asset?

An asset is anything that has value to the organization.

Assets are not limited to databases.

They include:

* Information
* Systems
* Infrastructure
* Credentials
* Intellectual property
* Services
* Reputation

---

# Types of Assets

## Information Assets

Examples:

* Customer records
* Password hashes
* Medical records
* Credit card data
* Financial transactions
* Source code
* API documentation

---

## Technical Assets

Examples:

* Authentication server
* Kubernetes cluster
* Database server
* Identity Provider
* Message queue
* API Gateway
* Load balancer

---

## Business Assets

Examples:

* Company reputation
* Brand trust
* Revenue
* Intellectual property
* Customer confidence

---

## Security Assets

Examples:

* Encryption keys
* Certificates
* API secrets
* OAuth tokens
* JWT signing keys
* SSH private keys

---

# Asset Classification

Not every asset is equally valuable.

Organizations usually classify assets.

Example:

| Classification | Description                    | Example           |
| -------------- | ------------------------------ | ----------------- |
| Public         | No restrictions                | Marketing website |
| Internal       | Employees only                 | Internal wiki     |
| Confidential   | Sensitive business information | Customer database |
| Restricted     | Critical business information  | Encryption keys   |

---

# Asset Inventory Example

| Asset                 | Owner          | Value    | CIA Priority |
| --------------------- | -------------- | -------- | ------------ |
| Customer Database     | DBA            | Critical | C, I         |
| Authentication Server | Infrastructure | Critical | C, I, A      |
| Payment API           | Finance        | High     | I, A         |
| Source Code           | Engineering    | High     | C            |
| Audit Logs            | Security       | High     | I            |

---

# CIA Triad Review

Each asset should be evaluated according to the CIA Triad.

## Confidentiality

Prevent unauthorized disclosure.

Examples

* Medical records
* Password hashes
* Personal information

---

## Integrity

Prevent unauthorized modification.

Examples

* Financial transactions
* Purchase orders
* Source code
* Audit logs

---

## Availability

Ensure systems remain accessible.

Examples

* Banking portals
* Emergency services
* Online shopping
* Cloud infrastructure

---

# Asset Prioritization

Ask:

> Which assets would attackers target first?

Example ranking

| Asset              | Priority |
| ------------------ | -------- |
| Encryption Keys    | Critical |
| Customer Data      | Critical |
| Password Database  | Critical |
| Payment Processing | High     |
| Audit Logs         | High     |
| Product Images     | Low      |

---

# Pro Tip

Do not focus only on databases.

Attackers often seek:

* Session tokens
* API keys
* Cloud credentials
* OAuth refresh tokens
* Administrative interfaces

These assets can be more valuable than customer data.

---

# Chapter 3 – Identifying Actors

Actors interact with the system.

Not every actor is malicious.

Understanding actors helps identify permissions and potential misuse.

---

## Internal Actors

Examples

* Administrator
* Customer Support
* Finance Officer
* Developer
* Auditor

---

## External Actors

Examples

* Customer
* Supplier
* Payment Gateway
* Identity Provider
* Government Service
* Partner API

---

# Actor Matrix

| Actor            | Authenticated | Privileged |
| ---------------- | ------------- | ---------- |
| Customer         | Yes           | No         |
| Guest            | No            | No         |
| Administrator    | Yes           | Yes        |
| Payment Gateway  | Yes           | Limited    |
| Security Auditor | Yes           | Read Only  |

---

# Chapter 4 – Identifying Threat Agents

Actors use the system.

Threat agents attempt to abuse it.

Examples include:

* Cybercriminals
* Insider threats
* Nation-state actors
* Hacktivists
* Competitors
* Automated bots
* Script kiddies
* Disgruntled employees

---

## Threat Agent Motivations

| Threat Agent  | Motivation            |
| ------------- | --------------------- |
| Cybercriminal | Financial gain        |
| Insider       | Revenge               |
| Nation State  | Espionage             |
| Competitor    | Intellectual property |
| Bot           | Automation            |
| Hacktivist    | Political statement   |

Understanding motivation helps predict likely attack scenarios.

---

# Chapter 5 – Identifying Entry Points

Every entry point represents an opportunity for interaction—and potentially exploitation.

---

## Typical Entry Points

### Web

* Login page
* Registration page
* Password reset
* Contact forms

---

### APIs

* REST endpoints
* GraphQL
* SOAP
* Webhooks

---

### Infrastructure

* VPN
* SSH
* Remote Desktop
* Kubernetes Dashboard

---

### File Operations

* Upload
* Download
* Image processing

---

### Administrative

* Admin Portal
* Monitoring Dashboard
* Management Console

---

# Entry Point Checklist

Ask:

* Can data enter here?
* Is input validated?
* Is authentication required?
* Is authorization enforced?
* Are requests logged?
* Is rate limiting enabled?

---

# Example Entry Point Inventory

| Entry Point  | Auth Required | Risk     |
| ------------ | ------------- | -------- |
| Login        | No            | High     |
| Registration | No            | Medium   |
| Checkout API | Yes           | High     |
| File Upload  | Yes           | Critical |
| Admin Portal | Yes           | Critical |

---

# Chapter 6 – Understanding Attack Surfaces

The attack surface is the sum of all points where an attacker can interact with the system.

Attack surfaces include:

## External

* Public APIs
* Web applications
* Mobile applications
* DNS
* Email gateways

---

## Internal

* Admin panels
* Databases
* Message queues
* Internal APIs
* Monitoring dashboards

---

## Physical

* USB ports
* Laptops
* Data centers
* Badge readers

---

## Cloud

* Object storage
* IAM roles
* Serverless functions
* Kubernetes API
* Cloud consoles

---

# Attack Surface Reduction

Good architects minimize unnecessary exposure.

Examples include:

* Disable unused services.
* Remove default accounts.
* Close unused ports.
* Restrict administrative interfaces.
* Remove legacy APIs.
* Segment networks.

A smaller attack surface generally means fewer opportunities for attackers.

---

# Chapter 7 – Identifying Trust Boundaries

Trust boundaries are among the most important concepts in threat modeling.

A trust boundary exists whenever data crosses from one trust level to another.

---

## Examples

Internet

↓

Corporate Firewall

↓

DMZ

↓

Application Server

↓

Database

Each transition is a trust boundary.

---

## Cloud Example

```text
Customer Browser
       │
Internet
       │
Cloud Load Balancer
       │
Kubernetes Cluster
       │
Pod
       │
Database
```

There are multiple trust boundaries:

* Internet → Cloud
* Cloud → Cluster
* Cluster → Database

Each requires appropriate controls such as TLS, authentication, network policies, and least-privilege access.

---

# Chapter 8 – System Decomposition

Complex systems must be broken into smaller, understandable components.

---

## Why Decompose?

Without decomposition:

```text
Online Banking Platform
```

There is too much complexity.

Instead:

```text
Online Banking

├── Authentication
├── Customer Profile
├── Payments
├── Transaction Engine
├── Notifications
├── Audit Logging
├── Fraud Detection
├── Reporting
└── Mobile API
```

Each subsystem can be analyzed independently.

---

# Benefits

System decomposition helps teams:

* Reduce complexity
* Assign ownership
* Improve documentation
* Discover hidden dependencies
* Focus on high-risk components

---

# Component Inventory

| Component            | Function             |
| -------------------- | -------------------- |
| Authentication       | User login           |
| API Gateway          | Routing              |
| Payment Service      | Financial processing |
| Notification Service | Email/SMS            |
| Database             | Persistent storage   |
| Logging              | Audit trail          |
| Monitoring           | Metrics              |

---

# Component Dependencies

Understanding dependencies is essential.

Example:

```text
Customer

↓

Frontend

↓

API Gateway

↓

Authentication

↓

Payment Service

↓

Database
```

A compromise in Authentication can affect every downstream component.

---

# Chapter 9 – Building a Complete DFD

We now combine everything learned.

---

## Example Architecture

```text
                 Customer
                     │
                 HTTPS
                     │
             Web Application
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
Authentication   Product API   Payment API
      │              │              │
      └──────────────┼──────────────┘
                     │
                Database
                     │
                 Audit Logs
```

---

# Identifying DFD Components

| Component       | DFD Type        |
| --------------- | --------------- |
| Customer        | External Entity |
| Web Application | Process         |
| Authentication  | Process         |
| Product API     | Process         |
| Payment API     | Process         |
| Database        | Data Store      |
| Audit Logs      | Data Store      |

---

# Mapping Data Flows

Document every significant data exchange.

| Source         | Destination    | Data               |
| -------------- | -------------- | ------------------ |
| Browser        | Web App        | Login Request      |
| Web App        | Authentication | Credentials        |
| Authentication | Database       | User Lookup        |
| Payment API    | Database       | Transaction Record |
| Web App        | Audit Logs     | Security Event     |

---

# Questions to Ask for Every Data Flow

* Is the communication encrypted?
* Who initiated the request?
* Can the request be modified?
* Is authentication required?
* Is authorization checked?
* Is the request logged?
* Can an attacker replay the request?
* Is sensitive data exposed?

---

# Practical Walkthrough

Imagine a customer logging into an online store.

### Step 1

The browser sends credentials.

Questions:

* Is HTTPS enforced?
* Is TLS configured correctly?
* Are passwords transmitted securely?

---

### Step 2

Authentication checks credentials.

Questions:

* Are passwords hashed?
* Is MFA available?
* Is brute-force protection enabled?

---

### Step 3

Authentication queries the database.

Questions:

* Are parameterized queries used?
* Does the service use least-privilege database credentials?
* Is the database encrypted at rest?

---

### Step 4

A session token is returned.

Questions:

* Is the token signed?
* Does it expire?
* Is it protected from theft?
* Can it be revoked?

This sequence forms the basis for identifying threats in the next phase.

---

# Common Mistakes During Decomposition

Avoid these common errors:

* Ignoring third-party services (payment gateways, identity providers, cloud storage).
* Treating internal networks as fully trusted.
* Forgetting background jobs, scheduled tasks, and message queues.
* Omitting logging, monitoring, and administrative systems.
* Failing to identify data stores outside the primary database (caches, object storage, backups).

---

# Hands-on Workshop

**Scenario:** Document Management System

Your task is to create a threat model for an application that allows employees to upload, store, and share documents.

### Step 1

Identify the assets.

Examples:

* Employee documents
* User credentials
* Audit logs
* Encryption keys

### Step 2

Identify the actors.

Examples:

* Employee
* Manager
* Administrator
* External contractor

### Step 3

List the entry points.

Examples:

* Login
* File upload
* File download
* Search API
* Admin console

### Step 4

Identify trust boundaries.

Examples:

* Internet → Web Application
* Web Application → File Storage
* Application → Identity Provider
* Application → Database

### Step 5

Create a DFD showing:

* External entities
* Processes
* Data stores
* Data flows
* Trust boundaries

This completed DFD becomes the primary input for the threat identification process.

---

# Deliverables for Part 2

At the conclusion of this phase, you should have:

| Deliverable             | Description                             |
| ----------------------- | --------------------------------------- |
| Scope Statement         | Defines what is included and excluded   |
| Asset Inventory         | Catalog of valuable assets              |
| Actor Inventory         | Internal and external users and systems |
| Threat Agent List       | Potential attackers and motivations     |
| Entry Point Inventory   | All interfaces exposed by the system    |
| Attack Surface Analysis | Summary of exposed components           |
| Trust Boundary Map      | Security zones and transitions          |
| Component Inventory     | Decomposed architecture                 |
| Data Flow Diagram (DFD) | Visual representation of the system     |

These artifacts form the foundation for the next stage of the methodology.

---

## Pro Tip

**Resist the temptation to overcomplicate the first DFD.** Start with a high-level diagram that captures the major components, data flows, and trust boundaries. As the threat modeling exercise progresses, create more detailed DFDs for individual subsystems such as authentication, payments, or file processing. Layered models are easier to review, maintain, and update than a single, highly detailed diagram.

---

# End of Part 2

In **Part 3 – Identifying and Scoring Threats**, we will take the completed DFD and apply the **STRIDE** methodology to every process, data flow, data store, and external entity. We will also learn how to document threats, build a professional threat register, construct a risk matrix, and prioritize remediation using DREAD and CVSS scoring techniques.
