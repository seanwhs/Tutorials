# Threat Modeling Course

# Part 5 – Enterprise Threat Modeling Workshop

## Complete End-to-End Practical Exercise

> **Module Duration:** 1–2 Days (Instructor-Led Workshop + Group Exercise)
>
> **Difficulty:** Intermediate to Advanced
>
> **Audience:** Software Architects, Enterprise Architects, Security Architects, DevSecOps Engineers, Security Consultants, Technical Leads
>
> **Workshop Goal:** Guide participants through a complete enterprise threat modeling engagement using a realistic cloud-native application. By the end of the workshop, participants will have produced the same deliverables expected in a professional architecture review or security assessment.

---

# Workshop Overview

Unlike the previous modules, which focused on methodology and concepts, this workshop is **hands-on**. Participants will work through every phase of a threat modeling engagement—from understanding business requirements to presenting risks and mitigations to an Architecture Review Board.

The workshop simulates the lifecycle of a real consulting engagement, where participants act as security architects responsible for evaluating the design of a mission-critical system.

---

# Learning Objectives

By the end of this workshop, participants will be able to:

* Analyze business and technical requirements from a security perspective.
* Create multiple levels of Data Flow Diagrams (DFDs).
* Identify assets, actors, trust boundaries, and attack surfaces.
* Decompose a complex cloud-native application into manageable components.
* Apply STRIDE systematically across the architecture.
* Build and maintain a Threat Register.
* Assess and prioritize risks using DREAD and risk matrices.
* Recommend layered security controls.
* Communicate findings to both technical teams and executive stakeholders.
* Produce professional documentation suitable for governance and compliance.

---

# Workshop Scenario

## Business Context

**Acme Retail Group** is a multinational e-commerce company expanding into digital financial services. The organization plans to launch a cloud-native online marketplace that serves millions of customers across multiple regions.

The platform supports:

* Customer registration and authentication
* Product browsing and search
* Shopping cart and checkout
* Payment processing
* Order management
* Inventory synchronization
* Customer support
* Promotional campaigns
* Mobile applications
* Third-party payment gateways
* External logistics providers

The application will be deployed on a Kubernetes platform hosted in a public cloud environment.

---

# Business Objectives

The system must:

* Provide a highly available online shopping experience.
* Support millions of concurrent users.
* Protect customer and payment data.
* Comply with PCI DSS and privacy regulations.
* Scale automatically during seasonal traffic spikes.
* Integrate securely with external business partners.
* Detect and respond to fraud in near real time.

---

# Non-Functional Requirements

| Requirement       | Description                                 |
| ----------------- | ------------------------------------------- |
| Availability      | 99.99% uptime                               |
| Scalability       | Auto-scale to millions of users             |
| Performance       | Page load under 2 seconds                   |
| Security          | Zero Trust architecture                     |
| Compliance        | PCI DSS, GDPR, ISO 27001                    |
| Auditability      | Full audit trail for financial transactions |
| Disaster Recovery | RPO < 15 minutes, RTO < 1 hour              |

---

# High-Level Architecture

```text
                    Internet
                        │
                  Content Delivery Network
                        │
                 Web Application Firewall
                        │
                  Global Load Balancer
                        │
                 API Gateway / Ingress
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
 Authentication   Product Service   Order Service
        │               │                │
        ├───────────────┼────────────────┤
        │               │                │
        ▼               ▼                ▼
 Inventory       Payment Service   Notification
        │               │                │
        └───────────────┼────────────────┘
                        │
                 Message Queue
                        │
              Analytics & Reporting
                        │
        ┌───────────────┼────────────────┐
        ▼               ▼                ▼
   PostgreSQL      Object Storage    SIEM Platform
```

---

# Workshop Deliverables

By the end of the workshop, participants will produce:

* Project Scope Statement
* Architecture Overview
* Data Flow Diagrams (Level 0, 1, and 2)
* Asset Inventory
* Actor Inventory
* Trust Boundary Map
* Attack Surface Analysis
* STRIDE Analysis
* Threat Register
* Risk Matrix
* DREAD Scores
* Security Control Matrix
* Residual Risk Register
* Executive Summary
* Architecture Review Presentation

---

# Phase 1 – Define the Scope

## Objective

Clearly define the boundaries of the assessment.

---

## Included Components

* Customer Web Portal
* Mobile API
* Authentication Service
* Product Catalog
* Shopping Cart
* Checkout
* Payment Gateway Integration
* Inventory Service
* Order Service
* Notification Service
* PostgreSQL Database
* Object Storage
* Kubernetes Cluster
* CI/CD Pipeline

---

## Excluded Components

* Corporate HR systems
* Legacy ERP
* Office productivity tools
* Physical retail point-of-sale systems
* Internal finance applications

---

## Assumptions

* All services communicate over TLS.
* Kubernetes is the orchestration platform.
* Authentication uses OAuth 2.0 and OpenID Connect.
* Customer data is encrypted at rest.
* Infrastructure is provisioned using Infrastructure as Code (IaC).

---

# Workshop Exercise 1

**Task:** Review the project scope and identify any missing assumptions that could affect the threat model.

### Discussion Questions

1. Should third-party logistics providers be included?
2. Are administrator workstations within scope?
3. Should backup systems be modeled?
4. What about cloud management consoles?

---

# Phase 2 – Identify Business Assets

## Objective

Determine what is valuable to the organization and therefore attractive to attackers.

---

## Business Assets

| Asset                | Business Value |
| -------------------- | -------------- |
| Customer Accounts    | Critical       |
| Payment Transactions | Critical       |
| Order History        | High           |
| Product Catalog      | Medium         |
| Company Reputation   | Critical       |
| Revenue Stream       | Critical       |
| Customer Trust       | Critical       |

---

## Technical Assets

| Asset               | Importance |
| ------------------- | ---------- |
| PostgreSQL Database | Critical   |
| Kubernetes Cluster  | Critical   |
| Object Storage      | High       |
| API Gateway         | High       |
| OAuth Server        | Critical   |
| Secrets Manager     | Critical   |
| Message Queue       | High       |
| CI/CD Pipeline      | High       |

---

## Information Assets

* Personally Identifiable Information (PII)
* Payment Tokens
* JWT Access Tokens
* Refresh Tokens
* Session Cookies
* Encryption Keys
* Audit Logs
* API Keys
* Configuration Files
* Source Code

---

# Workshop Exercise 2

For each asset:

* Identify the owner.
* Assign a classification (Public, Internal, Confidential, Restricted).
* Identify the required CIA properties (Confidentiality, Integrity, Availability).

---

# Phase 3 – Identify Actors

## Internal Actors

| Actor                  | Responsibilities        |
| ---------------------- | ----------------------- |
| Customer Support       | View customer accounts  |
| Administrator          | Manage platform         |
| DevOps Engineer        | Deploy services         |
| Database Administrator | Manage databases        |
| Security Analyst       | Monitor security events |

---

## External Actors

| Actor              | Responsibilities   |
| ------------------ | ------------------ |
| Customer           | Purchase products  |
| Payment Provider   | Process payments   |
| Shipping Partner   | Fulfill orders     |
| Identity Provider  | Authenticate users |
| Marketing Platform | Deliver campaigns  |

---

## Threat Agents

Potential adversaries include:

* Cybercriminal organizations
* Nation-state actors
* Insider threats
* Competitors
* Automated botnets
* Ransomware groups
* Supply chain attackers
* Fraudsters

---

# Workshop Exercise 3

Create attacker personas for:

* Financially motivated cybercriminal
* Disgruntled employee
* Nation-state intelligence agency
* Competitor seeking intellectual property
* Automated credential-stuffing bot

For each persona, define:

* Motivation
* Capabilities
* Resources
* Preferred attack techniques
* Target assets

---

# Phase 4 – Build the Data Flow Diagram (DFD)

## Level 0 DFD

At this level, treat the application as a single process interacting with external entities.

```text
Customer
    │
    ▼
E-Commerce Platform
    │
    ├── Payment Provider
    ├── Shipping Partner
    └── Identity Provider
```

**Objective:** Understand the system's external interactions.

---

## Level 1 DFD

Break the platform into major functional processes.

```text
Customer
   │
   ▼
Web Application
   │
   ├── Authentication Service
   ├── Product Service
   ├── Order Service
   ├── Payment Service
   └── Notification Service
```

**Objective:** Identify major components and their interactions.

---

## Level 2 DFD

Further decompose a critical subsystem, such as the Payment Service.

```text
Checkout API
     │
     ▼
Payment Validation
     │
     ▼
Fraud Detection
     │
     ▼
Payment Gateway Adapter
     │
     ▼
Payment Provider
```

**Objective:** Reveal detailed data flows and trust boundaries.

---

# Workshop Exercise 4

Participants will create:

* Level 0 DFD
* Level 1 DFD
* Level 2 DFD (Payment Service)

Each diagram should include:

* External entities
* Processes
* Data stores
* Data flows
* Trust boundaries

---

# Phase 5 – Identify Trust Boundaries

## Example Trust Boundaries

1. Internet ↔ CDN
2. CDN ↔ WAF
3. WAF ↔ API Gateway
4. API Gateway ↔ Kubernetes Cluster
5. Cluster ↔ Database
6. Cluster ↔ Payment Provider
7. Cluster ↔ Object Storage

Each boundary represents a transition between different levels of trust and should be analyzed carefully.

---

# Workshop Exercise 5

For each trust boundary:

* Describe the data crossing it.
* Identify the authentication mechanism.
* Determine whether encryption is used.
* List potential attack vectors.
* Recommend security controls.

---

# Phase 6 – System Decomposition

Break the application into logical domains.

| Domain     | Components                            |
| ---------- | ------------------------------------- |
| Identity   | OAuth Server, MFA, Session Management |
| Commerce   | Product Catalog, Cart, Checkout       |
| Payments   | Payment API, Fraud Detection          |
| Inventory  | Stock Service                         |
| Messaging  | Email, SMS, Push Notifications        |
| Analytics  | Reporting, BI Dashboards              |
| Operations | Monitoring, Logging, Alerting         |

This decomposition makes subsequent STRIDE analysis more manageable.

---

# Workshop Exercise 6

Assign each team one domain.

Each team should:

1. Identify assets.
2. Identify entry points.
3. List trust boundaries.
4. Document assumptions.
5. Present findings to the class.

---

# Phase 7 – Preparing for Threat Identification

At the conclusion of this workshop phase, participants should have assembled all prerequisite artifacts needed for a comprehensive threat analysis.

## Required Outputs

| Deliverable              | Status   |
| ------------------------ | -------- |
| Scope Statement          | Complete |
| Business Objectives      | Complete |
| Architecture Overview    | Complete |
| Level 0 DFD              | Complete |
| Level 1 DFD              | Complete |
| Level 2 DFD              | Complete |
| Asset Inventory          | Complete |
| Actor Inventory          | Complete |
| Trust Boundary Map       | Complete |
| Attack Surface Inventory | Complete |
| Component Decomposition  | Complete |

These outputs become the primary inputs for the STRIDE analysis performed in the next workshop stage.

---

# Common Mistakes in Enterprise Workshops

* Defining a scope that is too broad to analyze effectively.
* Omitting third-party integrations from the DFD.
* Ignoring operational components such as logging, monitoring, or CI/CD pipelines.
* Treating internal services as inherently trustworthy.
* Failing to identify cloud-native resources (e.g., object storage, IAM roles, managed services).
* Producing DFDs that are either too abstract or excessively detailed.

---

## Pro Tip

**Facilitate the workshop as a collaborative architecture review—not a security interrogation.** Encourage developers, architects, operations engineers, and product owners to contribute. Different perspectives often reveal hidden assumptions, undocumented data flows, and overlooked trust boundaries. The quality of a threat model depends as much on cross-functional collaboration as it does on technical expertise.

---

# End of Part 5 (Workshop Foundation)

In **Part 6 – Enterprise Threat Modeling Workshop: STRIDE in Practice**, we will use the artifacts created in this workshop to perform a comprehensive STRIDE analysis, generate a detailed Threat Register with over 100 example threats, score each threat using DREAD, and develop prioritized mitigation strategies suitable for enterprise-scale systems. This module will closely resemble the methodology used by professional security consultants and architecture review boards.
