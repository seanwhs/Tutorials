# Threat Modeling Masterclass

# Part 8 – Advanced Threat Modeling for Modern Architectures

## Threat Modeling Cloud-Native, Distributed, AI-Driven, and Emerging Systems

> **Module Duration:** 8–10 Hours (Advanced Architecture Course)
>
> **Difficulty:** Expert
>
> **Audience:** Enterprise Architects, Cloud Architects, Security Architects, DevSecOps Engineers, Platform Engineers, Solution Architects
>
> **Objective:** Master threat modeling techniques for modern distributed architectures—including microservices, Kubernetes, APIs, serverless, event-driven systems, cloud-native platforms, AI/LLM applications, mobile apps, IoT, and Zero Trust environments. Participants will learn architecture-specific attack patterns, trust boundaries, and mitigation strategies used in enterprise-scale systems.

---

# Learning Objectives

By the end of this module, participants will be able to:

* Apply threat modeling to distributed and cloud-native architectures.
* Identify architecture-specific trust boundaries and attack surfaces.
* Recognize common attack techniques for APIs, microservices, containers, serverless, AI, and IoT.
* Select appropriate security controls for modern platforms.
* Evaluate shared responsibility in cloud environments.
* Design secure-by-default architectures aligned with Zero Trust principles.

---

# Module Overview

```text id="advarch01"
Part 8
│
├── Modern Threat Landscape
├── Cloud-Native Threat Modeling
├── API Threat Modeling
├── Microservices
├── Service Mesh
├── Kubernetes
├── Containers
├── Serverless
├── Event-Driven Systems
├── Data Lakes & Big Data
├── AI & LLM Applications
├── Mobile Applications
├── Internet of Things (IoT)
├── Zero Trust Architecture
├── Multi-Cloud Architectures
├── Supply Chain Security
├── Enterprise Case Studies
└── Architecture Review Workshop
```

---

# Chapter 1 – The Evolution of Threat Modeling

Traditional threat modeling focused on:

* Monolithic applications
* Internal data centers
* Static infrastructure
* Trusted internal networks

Modern architectures introduce:

* Ephemeral infrastructure
* Distributed workloads
* Cloud-native services
* Managed platforms
* APIs everywhere
* Software supply chains
* AI-driven services
* Continuous deployment

As a result, the attack surface expands dramatically.

---

# Traditional vs Modern Architectures

| Traditional        | Modern                |
| ------------------ | --------------------- |
| Monolith           | Microservices         |
| Static servers     | Containers            |
| Internal network   | Zero Trust            |
| VPN                | Identity-first access |
| Manual deployment  | CI/CD                 |
| Perimeter security | Defense-in-depth      |
| Single data center | Multi-cloud           |

Threat modeling must evolve accordingly.

---

# Chapter 2 – Cloud-Native Threat Modeling

## Characteristics

Cloud-native systems typically include:

* Containers
* Kubernetes
* Managed databases
* Service meshes
* API gateways
* Object storage
* Autoscaling
* Infrastructure as Code (IaC)

### New Trust Boundaries

* Cloud account ↔ Managed service
* Cluster ↔ Control plane
* Service ↔ Service
* CI/CD ↔ Cloud
* Cloud ↔ Third-party SaaS

These boundaries often differ from traditional on-premises environments and require explicit security controls.

---

# Cloud-Native Architecture

```text id="cloud01"
Internet
      │
 CDN / WAF
      │
API Gateway
      │
Ingress Controller
      │
Service Mesh
      │
Microservices
      │
Managed Database
      │
Object Storage
      │
Cloud Management Plane
```

---

# Common Cloud Threats

| Category   | Examples                          |
| ---------- | --------------------------------- |
| Identity   | Stolen cloud credentials          |
| Storage    | Public object storage             |
| Network    | Overly permissive security groups |
| Compute    | Privileged containers             |
| Management | IAM privilege escalation          |
| Automation | Insecure Infrastructure as Code   |

---

# Pro Tip

Cloud providers secure the infrastructure **of** the cloud, while customers remain responsible for securing what they deploy **in** the cloud. Threat models should explicitly reflect this shared responsibility.

---

# Chapter 3 – API Threat Modeling

APIs are often the most exposed component of modern applications.

## Assets

* Endpoints
* Tokens
* API keys
* Customer data
* Business logic

---

# API Data Flow

```text id="api01"
Client
   │
   ▼
API Gateway
   │
   ▼
Authentication
   │
   ▼
Microservice
   │
   ▼
Database
```

---

# API Attack Surface

* Public endpoints
* Authentication
* Authorization
* Rate limiting
* Payload validation
* Error handling
* Logging
* Third-party integrations

---

# STRIDE Applied to APIs

| STRIDE                 | Example                           |
| ---------------------- | --------------------------------- |
| Spoofing               | Fake JWT                          |
| Tampering              | Modified JSON payload             |
| Repudiation            | Missing audit trail               |
| Information Disclosure | Excessive API response            |
| DoS                    | API flooding                      |
| Elevation              | Broken object-level authorization |

---

# API Security Controls

* OAuth 2.0 / OpenID Connect
* Mutual TLS (where appropriate)
* Schema validation
* Rate limiting
* API gateway policies
* Request signing
* Fine-grained authorization
* Secure error responses

---

# Chapter 4 – Microservices

Microservices increase agility but also increase complexity.

---

## Characteristics

* Independent deployment
* Distributed communication
* Multiple databases
* Service discovery
* Event messaging

---

# New Trust Boundaries

```text id="micro01"
User
 │
 ▼
Gateway
 │
 ▼
Service A
 │
 ▼
Service B
 │
 ▼
Database
```

Every service-to-service communication path should be treated as a trust boundary.

---

# Common Threats

* Service impersonation
* Unencrypted service traffic
* Secret leakage
* Insecure service discovery
* Cascading failures
* Inconsistent authorization

---

# Recommended Controls

* Service Mesh
* Mutual TLS
* Identity-aware proxies
* Circuit breakers
* Distributed tracing
* Policy enforcement

---

# Chapter 5 – Kubernetes

Kubernetes is both a platform and an attack surface.

---

## Critical Assets

* API Server
* etcd
* Nodes
* Pods
* Service Accounts
* Secrets
* Admission Controllers

---

# Typical Attack Paths

```text id="k8s01"
Compromised Pod
      │
      ▼
Service Account Token
      │
      ▼
API Server
      │
      ▼
RBAC Abuse
      │
      ▼
Cluster Administrator
```

---

# Kubernetes Threats

| Category      | Example                              |
| ------------- | ------------------------------------ |
| Identity      | Stolen service account token         |
| Configuration | Overly permissive RBAC               |
| Secrets       | Credentials in environment variables |
| Runtime       | Container escape                     |
| Networking    | Missing network policies             |

---

# Security Controls

* Pod Security Standards
* Network Policies
* Admission controllers
* Image signing
* Secret management
* Audit logging
* Runtime detection

---

# Chapter 6 – Serverless Architectures

Serverless platforms reduce infrastructure management but introduce new considerations.

---

## Assets

* Functions
* Event sources
* IAM roles
* Environment variables
* Temporary storage

---

# Threats

* Excessive IAM permissions
* Event injection
* Function abuse
* Secret exposure
* Recursive invocation
* Cost-based denial of service

---

# Controls

* Least-privilege IAM
* Input validation
* Reserved concurrency
* Secrets management
* Function logging
* Monitoring

---

# Chapter 7 – Event-Driven Systems

Examples:

* Kafka
* RabbitMQ
* Cloud messaging services

---

## Threats

* Message spoofing
* Message tampering
* Replay attacks
* Queue flooding
* Poison messages
* Unauthorized subscriptions

---

# Controls

* Message signing
* Encryption
* Dead-letter queues
* Consumer authentication
* Replay protection

---

# Chapter 8 – Data Lakes and Analytics

Modern organizations increasingly centralize data.

## Assets

* Data lake
* ETL pipelines
* Analytics platforms
* Machine learning datasets

---

# Threats

* Unauthorized data access
* Sensitive data aggregation
* Data poisoning
* Misconfigured permissions
* Excessive data retention

---

# Controls

* Data classification
* Encryption
* Fine-grained access control
* Data masking
* Governance policies

---

# Chapter 9 – AI and LLM Applications

AI systems introduce unique attack patterns not commonly found in traditional software.

---

## AI Components

* Prompt interface
* Model
* Embedding store
* Vector database
* Retrieval pipeline
* External tools
* Agent framework

---

# AI Data Flow

```text id="ai01"
User
 │
 ▼
Prompt
 │
 ▼
LLM
 │
 ▼
Retriever
 │
 ▼
Vector Database
 │
 ▼
Enterprise Data
```

---

# AI Threat Categories

| Threat                 | Description                                           |
| ---------------------- | ----------------------------------------------------- |
| Prompt Injection       | Malicious instructions manipulate model behavior      |
| Data Poisoning         | Training or retrieval data is intentionally corrupted |
| Model Theft            | Unauthorized extraction of model behavior or weights  |
| Sensitive Data Leakage | Model reveals confidential information                |
| Tool Abuse             | AI invokes external tools in unsafe ways              |
| Hallucination          | Incorrect outputs influence business decisions        |

---

# Security Controls

* Prompt validation
* Output filtering
* Context isolation
* Human approval for sensitive actions
* Retrieval filtering
* Monitoring and auditing
* Least-privilege tool access

---

# Chapter 10 – Mobile Applications

## Threats

* Reverse engineering
* Insecure local storage
* Certificate bypass
* API abuse
* Token theft
* Device compromise

---

# Controls

* Secure key storage
* Device integrity checks
* Certificate pinning (where appropriate)
* Code obfuscation
* Strong authentication

---

# Chapter 11 – Internet of Things (IoT)

IoT expands the attack surface beyond traditional IT.

---

## Assets

* Devices
* Sensors
* Gateways
* Firmware
* Cloud platform

---

# Threats

* Weak default credentials
* Unsigned firmware
* Physical tampering
* Device impersonation
* Insecure update mechanisms

---

# Controls

* Secure boot
* Signed firmware
* Hardware root of trust
* Mutual authentication
* Secure update processes

---

# Chapter 12 – Zero Trust Architecture

Zero Trust assumes that no network location is inherently trusted.

## Principles

* Verify explicitly.
* Enforce least privilege.
* Assume breach.
* Continuously evaluate context.

---

# Zero Trust Flow

```text id="zt01"
Identity
     │
Device
     │
Location
     │
Risk Score
     │
Policy Engine
     │
Decision
```

Every access request is evaluated based on identity and context rather than network location.

---

# Chapter 13 – Multi-Cloud Threat Modeling

Organizations often operate across multiple cloud providers.

## Additional Challenges

* Inconsistent IAM models
* Different networking constructs
* Cross-cloud trust
* Shared secrets
* Data residency
* Operational complexity

Threat models should account for cloud-specific controls while maintaining consistent security principles.

---

# Chapter 14 – Software Supply Chain

Modern software depends heavily on third-party components.

## Assets

* Source code
* Build pipeline
* Dependencies
* Container images
* Deployment artifacts

---

# Threats

* Dependency confusion
* Typosquatting
* Malicious packages
* Compromised build systems
* Artifact tampering

---

# Controls

* Software Bill of Materials (SBOM)
* Dependency scanning
* Artifact signing
* Build provenance
* Policy-as-code
* Reproducible builds

---

# Enterprise Case Study

## Scenario

A healthcare organization deploys an AI-powered clinical decision support platform using:

* Kubernetes
* Microservices
* REST APIs
* Event-driven messaging
* Object storage
* Large Language Models
* Mobile clinician applications

### Workshop Tasks

1. Identify all trust boundaries.
2. Create Level 0–2 DFDs.
3. Apply STRIDE to each component.
4. Highlight AI-specific threats.
5. Recommend layered security controls.
6. Assess residual risk.
7. Present findings to an Architecture Review Board.

---

# Best Practices

* Treat every service-to-service connection as a potential trust boundary.
* Apply least privilege consistently across identities, workloads, and infrastructure.
* Secure APIs as products with authentication, authorization, validation, and monitoring.
* Include managed cloud services in threat models; do not assume they are risk-free.
* Model AI pipelines end-to-end, including prompts, retrieval, tools, and outputs.
* Review threat models whenever architecture, dependencies, or deployment processes change.

---

# Common Pitfalls

| Pitfall                                                       | Impact                          |
| ------------------------------------------------------------- | ------------------------------- |
| Trusting internal network traffic                             | Increased lateral movement risk |
| Ignoring cloud control planes                                 | Administrative compromise       |
| Overlooking CI/CD pipelines                                   | Software supply chain attacks   |
| Treating AI models as "black boxes"                           | Unidentified AI-specific risks  |
| Failing to model third-party services                         | Hidden trust relationships      |
| Assuming managed services eliminate security responsibilities | Gaps in customer-owned controls |

---

## Pro Tip

**Modern architectures are dynamic.** Traditional threat models created once during design quickly become outdated in environments with continuous deployment, autoscaling, and frequent service changes. Treat threat models as living architectural artifacts, version-controlled alongside application code and updated whenever the system evolves.

---

# Deliverables

By the end of Part 8, participants should have:

| Deliverable                         | Purpose                                         |
| ----------------------------------- | ----------------------------------------------- |
| Architecture-Specific Threat Models | Threat analysis for cloud-native components     |
| Advanced DFDs                       | Distributed system data flow representations    |
| AI Threat Assessment                | Analysis of LLM- and AI-specific risks          |
| Cloud Security Control Matrix       | Mapping of threats to cloud-native controls     |
| Supply Chain Risk Assessment        | Evaluation of build and dependency risks        |
| Updated Threat Register             | Expanded to include modern architecture threats |
| Executive Architecture Review       | Recommendations for enterprise adoption         |

---

# End of Part 8

In **Part 9 – Threat Modeling Templates, Checklists, and Professional Toolkit**, we will build a complete practitioner toolkit containing reusable templates, worksheets, architecture review checklists, STRIDE and DREAD worksheets, threat register templates, Data Flow Diagram stencils, interview questionnaires, governance documents, and reporting formats that can be immediately used in consulting engagements, architecture reviews, and enterprise security assessments.
