# Threat Modeling Course

# Part 6 – Enterprise Threat Modeling Workshop: STRIDE in Practice

## Complete Threat Analysis of an Enterprise Cloud-Native Application

> **Module Duration:** 6–8 Hours (Advanced Workshop)
>
> **Difficulty:** Advanced
>
> **Target Audience:** Security Architects, Enterprise Architects, DevSecOps Engineers, Security Consultants, Senior Developers
>
> **Workshop Objective:** Apply the STRIDE methodology to a realistic enterprise architecture, identify more than 100 potential threats, prioritize them using DREAD and risk matrices, and produce a professional Threat Register suitable for architecture review boards and governance committees.

---

# Module Overview

```text
Part 6
│
├── Reviewing the Architecture
├── STRIDE Review Process
├── Threat Brainstorming Techniques
├── Threat Analysis by Component
│      ├── External Entities
│      ├── API Gateway
│      ├── Authentication Service
│      ├── Product Service
│      ├── Order Service
│      ├── Payment Service
│      ├── Notification Service
│      ├── Database
│      ├── Object Storage
│      ├── Message Queue
│      ├── Kubernetes Cluster
│      ├── CI/CD Pipeline
│      └── Cloud Management Plane
├── Building the Threat Register
├── Prioritization
├── Architecture Review
└── Deliverables
```

---

# Workshop Scenario Recap

The organization is deploying a cloud-native e-commerce platform with the following architecture:

```text
                Internet
                     │
                 CDN / WAF
                     │
                Load Balancer
                     │
                 API Gateway
                     │
      ┌──────────────┼──────────────┐
      │              │              │
 Authentication   Product API   Order API
      │              │              │
      ├──────────────┼──────────────┤
      │              │              │
 Payment API   Inventory API   Notification
      │              │              │
      └──────────────┼──────────────┘
                     │
              PostgreSQL Database
                     │
              Object Storage
                     │
                Kubernetes
                     │
                CI/CD Pipeline
```

Our task is to identify threats against every component.

---

# Chapter 1 – The STRIDE Analysis Process

Threat modeling is **systematic**, not random.

For each component, follow the same sequence:

```text
Select Component
        │
        ▼
Identify Assets
        │
        ▼
Review Data Flows
        │
        ▼
Apply STRIDE
        │
        ▼
Identify Threats
        │
        ▼
Assess Risk
        │
        ▼
Recommend Controls
```

Consistency is key. Every process, data flow, and trust boundary should be evaluated using the same methodology.

---

# STRIDE Question Checklist

For every component, ask:

### Spoofing

* Can identities be impersonated?
* Can authentication be bypassed?
* Are credentials protected?

---

### Tampering

* Can requests be modified?
* Can data be altered in transit?
* Can configuration files be changed?

---

### Repudiation

* Can users deny performing actions?
* Are audit logs complete?
* Are logs tamper-resistant?

---

### Information Disclosure

* Could confidential data leak?
* Are secrets protected?
* Is encryption used appropriately?

---

### Denial of Service

* Can resources be exhausted?
* Can APIs be flooded?
* Can queues overflow?

---

### Elevation of Privilege

* Can users gain additional permissions?
* Can administrative functions be abused?
* Are authorization checks consistently enforced?

---

# Chapter 2 – External Entity Analysis

## Component

Customer Browser

---

## Assets

* User credentials
* Session cookies
* JWT tokens
* Personal information

---

## STRIDE Analysis

### Spoofing

Threats:

* Credential stuffing
* Phishing
* Session hijacking
* Token theft
* Browser impersonation

---

### Tampering

Threats:

* Modified HTTP requests
* Cookie manipulation
* Parameter tampering
* Hidden field modification

---

### Repudiation

Threats:

* Customer denies placing an order
* User disputes account changes

---

### Information Disclosure

Threats:

* Browser cache exposure
* Sensitive data in URLs
* Session token leakage
* Auto-complete exposing credentials

---

### Denial of Service

Threats:

* Automated login attempts
* Browser automation attacks
* Resource exhaustion through repeated requests

---

### Elevation of Privilege

Threats:

* Manipulating client-side authorization logic
* Exploiting insecure local storage

---

# Chapter 3 – API Gateway Analysis

The API Gateway is the primary entry point into the platform.

Compromise here affects every downstream service.

---

## Assets

* API routing rules
* Authentication tokens
* Rate-limiting configuration
* API keys
* Request logs

---

## STRIDE Analysis

### Spoofing

Threats

* Fake JWT tokens
* Forged API keys
* Impersonated service accounts
* Stolen OAuth tokens

---

### Tampering

Threats

* Header manipulation
* JWT payload modification
* Query string manipulation
* Request replay

---

### Repudiation

Threats

* Missing API audit logs
* Incomplete request tracing

---

### Information Disclosure

Threats

* Sensitive headers exposed
* Verbose error messages
* API documentation leakage
* Internal endpoint enumeration

---

### Denial of Service

Threats

* API flooding
* Slowloris attacks
* Oversized payloads
* Resource exhaustion

---

### Elevation of Privilege

Threats

* Authorization bypass
* Broken access control
* Administrative API exposure

---

# Chapter 4 – Authentication Service Analysis

The Authentication Service is one of the highest-value targets in any architecture.

---

## Assets

* User credentials
* Password hashes
* MFA secrets
* OAuth tokens
* Refresh tokens
* Identity database

---

## Example Threats

### Spoofing

* Password spraying
* Credential stuffing
* MFA bypass
* Token forgery

---

### Tampering

* Login request modification
* Token manipulation
* Password reset abuse

---

### Repudiation

* User disputes password reset
* Missing login audit trail

---

### Information Disclosure

* Password hash leakage
* Session token exposure
* OAuth secret disclosure

---

### Denial of Service

* Login endpoint flooding
* Authentication service exhaustion
* Account lockout abuse

---

### Elevation of Privilege

* Role escalation
* Administrator account takeover
* Token privilege escalation

---

# Chapter 5 – Payment Service Analysis

The Payment Service processes financial transactions and therefore requires particularly strong security controls.

---

## Assets

* Payment tokens
* Transaction records
* Customer billing information
* Fraud detection rules
* Payment gateway credentials

---

## STRIDE Examples

### Spoofing

* Fake payment gateway
* Impersonated merchant

---

### Tampering

* Modify transaction amount
* Alter payment status
* Replay payment requests

---

### Repudiation

* Customer disputes payment
* Merchant denies transaction

---

### Information Disclosure

* Credit card token leakage
* Payment API secrets exposed

---

### Denial of Service

* Payment API flooding
* Queue saturation

---

### Elevation of Privilege

* Unauthorized refund approval
* Fraud rule bypass

---

# Chapter 6 – Database Analysis

The database stores many of the organization's most valuable assets.

---

## Assets

* Customer data
* Orders
* Payment records
* Audit logs
* User profiles

---

## STRIDE Analysis

### Spoofing

* Stolen database credentials
* Fake database clients

---

### Tampering

* SQL Injection
* Unauthorized record modification
* Trigger manipulation

---

### Repudiation

* Missing audit trails
* Log deletion

---

### Information Disclosure

* Database dumps
* Backup theft
* Unauthorized SELECT queries

---

### Denial of Service

* Query exhaustion
* Lock contention
* Storage exhaustion

---

### Elevation of Privilege

* Database administrator escalation
* Misconfigured roles

---

# Chapter 7 – Kubernetes Cluster Analysis

Cloud-native deployments introduce additional attack surfaces.

---

## Assets

* Pods
* Secrets
* ConfigMaps
* Service Accounts
* RBAC policies
* Cluster API

---

## Example Threats

### Spoofing

* Compromised service account tokens
* Fake nodes joining the cluster

---

### Tampering

* Container image replacement
* Manifest modification
* ConfigMap manipulation

---

### Repudiation

* Missing Kubernetes audit logs
* Pod deletion without traceability

---

### Information Disclosure

* Secrets exposed through environment variables
* Public etcd access
* Metadata service abuse

---

### Denial of Service

* Resource exhaustion
* Pod explosion
* API server overload

---

### Elevation of Privilege

* Privileged container escape
* RBAC misconfiguration
* Host namespace access

---

# Chapter 8 – CI/CD Pipeline Analysis

The software supply chain is now a major attack target.

---

## Assets

* Source code
* Build server
* Build artifacts
* Signing keys
* Deployment credentials

---

## Example Threats

### Spoofing

* Fake developer identity
* Compromised Git credentials

---

### Tampering

* Malicious code commits
* Pipeline modification
* Dependency poisoning

---

### Repudiation

* Untraceable deployments
* Missing code review records

---

### Information Disclosure

* Secrets in repositories
* Build log leakage
* Artifact exposure

---

### Denial of Service

* Build queue exhaustion
* CI runner attacks

---

### Elevation of Privilege

* Pipeline privilege escalation
* Unauthorized production deployment

---

# Chapter 9 – Building the Threat Register

Each identified threat should be documented in a consistent format.

## Example Threat Register

| ID    | Component       | STRIDE                 | Threat                          | Likelihood | Impact   | Risk     | Owner         |
| ----- | --------------- | ---------------------- | ------------------------------- | ---------- | -------- | -------- | ------------- |
| T-001 | API Gateway     | Spoofing               | Forged JWT                      | High       | High     | Critical | IAM Team      |
| T-002 | Payment Service | Tampering              | Modified payment request        | Medium     | Critical | High     | Payments Team |
| T-003 | Database        | Information Disclosure | Backup theft                    | Medium     | Critical | High     | DBA Team      |
| T-004 | Kubernetes      | Elevation of Privilege | Privileged container escape     | Medium     | High     | High     | Platform Team |
| T-005 | CI/CD           | Tampering              | Malicious pipeline modification | Medium     | Critical | High     | DevOps Team   |

---

# Chapter 10 – Threat Prioritization

Not every identified threat requires immediate remediation.

Use business context to prioritize.

### Priority Levels

| Priority | Description                     |
| -------- | ------------------------------- |
| Critical | Immediate action required       |
| High     | Address before production       |
| Medium   | Schedule in upcoming releases   |
| Low      | Monitor and review periodically |

Factors influencing priority include:

* Business impact
* Ease of exploitation
* Exposure
* Existing controls
* Regulatory obligations

---

# Workshop Exercise

## Objective

Working in teams:

1. Select one application component (e.g., Authentication, Payment Service, Kubernetes).
2. Apply the full STRIDE checklist.
3. Identify at least **15 distinct threats**.
4. Document each threat in the Threat Register.
5. Assign likelihood, impact, and priority.
6. Present the findings to the class and justify the prioritization.

This exercise reinforces the structured thinking required for consistent threat identification.

---

# Deliverables

By the end of Part 6, participants should have:

| Deliverable                 | Description                               |
| --------------------------- | ----------------------------------------- |
| Component STRIDE Worksheets | Threat analysis for each DFD element      |
| Threat Register             | Centralized catalog of identified threats |
| Prioritized Threat List     | Ranked by business risk                   |
| Initial Risk Assessment     | Likelihood and impact for each threat     |
| Threat Analysis Report      | Narrative summary of key findings         |

These deliverables provide the foundation for selecting security controls and developing mitigation strategies.

---

## Pro Tip

**Avoid the "checklist trap."** STRIDE is not merely a list of categories to tick off—it is a structured way of thinking. The most valuable threat models emerge when architects combine STRIDE with deep knowledge of the system, business processes, attacker motivations, and real-world attack techniques. Encourage discussion, challenge assumptions, and revisit the model as the architecture evolves.

---

# End of Part 6

In **Part 7 – Threat Mitigation Workshop**, we will map each identified threat to specific preventive, detective, and corrective controls, evaluate defense-in-depth strategies, calculate residual risk, and produce a complete Security Architecture Decision Record (ADR) and enterprise mitigation roadmap suitable for implementation by development and operations teams.
