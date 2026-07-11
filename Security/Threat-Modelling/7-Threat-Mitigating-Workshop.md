# Threat Modeling Course

# Part 7 – Threat Mitigation Workshop

## Engineering Security Controls, Security Architecture Decisions, and Enterprise Risk Treatment

> **Module Duration:** 7–8 Hours (Advanced Workshop + Architecture Design Lab)
>
> **Difficulty:** Advanced
>
> **Target Audience:** Enterprise Architects, Security Architects, Cloud Architects, DevSecOps Engineers, Security Consultants, Technical Leads
>
> **Workshop Objective:** Transform the Threat Register created in Part 6 into a comprehensive Security Architecture. Participants will learn how to design layered security controls, develop Security Architecture Decision Records (SADRs/ADRs), calculate residual risk, and build an enterprise security roadmap.

---

# Module Overview

```text
Part 7
│
├── Security Control Selection
├── Defense-in-Depth Design
├── Mapping Threats to Controls
├── Security Architecture Patterns
├── Identity & Access Management
├── Network Security
├── Application Security
├── Data Security
├── Infrastructure Security
├── Kubernetes Security
├── Cloud Security Controls
├── Monitoring & Detection
├── Incident Response Integration
├── Security Architecture Decision Records (ADR)
├── Residual Risk Analysis
├── Security Roadmap
├── Executive Reporting
└── Capstone Workshop
```

---

# Learning Objectives

After completing this workshop, participants will be able to:

* Select appropriate controls based on threat analysis.
* Apply layered (Defense-in-Depth) security architectures.
* Design Zero Trust security models.
* Build enterprise security architectures.
* Develop Security Architecture Decision Records (ADR).
* Evaluate residual risk.
* Create implementation roadmaps.
* Present architectural recommendations to executives.

---

# Chapter 1 – From Threat Register to Security Architecture

Threat identification is only half the journey.

A mature threat model ultimately answers three questions:

1. **What can go wrong?**
2. **What are we going to do about it?**
3. **Is the remaining risk acceptable?**

The Threat Register therefore becomes the primary input into security architecture design.

---

# Threat-to-Control Workflow

```text
Threat Register
        │
        ▼
Prioritize Risks
        │
        ▼
Select Controls
        │
        ▼
Design Architecture
        │
        ▼
Validate Controls
        │
        ▼
Measure Residual Risk
        │
        ▼
Risk Acceptance
```

---

# Chapter 2 – Security Control Categories

Security controls can be grouped into six major domains.

| Domain         | Examples                               |
| -------------- | -------------------------------------- |
| Identity       | MFA, OAuth, IAM, RBAC                  |
| Network        | Firewalls, WAF, Network Policies       |
| Application    | Input Validation, Secure Coding        |
| Data           | Encryption, Tokenization, DLP          |
| Infrastructure | Hardening, Patch Management            |
| Operations     | Logging, Monitoring, Incident Response |

Each identified threat should map to one or more control domains.

---

# Chapter 3 – Defense-in-Depth

No individual security control is perfect.

Enterprise systems rely on **multiple independent layers** of protection.

## Example

A payment API should not depend solely on authentication.

Instead, implement:

```text
Internet
     │
WAF
     │
API Gateway
     │
OAuth Authentication
     │
Authorization (RBAC/ABAC)
     │
Input Validation
     │
Business Rule Validation
     │
Fraud Detection
     │
Audit Logging
     │
SIEM Monitoring
```

Even if one layer is bypassed, others continue to reduce risk.

---

# Chapter 4 – Threat-to-Control Mapping

## Example 1 – SQL Injection

### Threat

Attacker injects SQL commands into the login API.

### Preventive Controls

* Parameterized queries
* ORM
* Input validation
* Stored procedures
* Least-privilege database accounts

### Detective Controls

* Database activity monitoring
* WAF SQL injection signatures
* SIEM alerts

### Corrective Controls

* Database restore
* Incident response
* Emergency patch deployment

---

## Example 2 – Credential Stuffing

### Threat

Automated bots attempt to reuse stolen passwords.

### Preventive Controls

* MFA
* Rate limiting
* CAPTCHA
* Passwordless authentication
* Adaptive authentication

### Detective Controls

* Login anomaly detection
* Geo-location monitoring
* Impossible travel detection

### Corrective Controls

* Force password reset
* Session revocation
* Customer notification

---

## Example 3 – Kubernetes Privilege Escalation

### Threat

Attacker compromises a privileged container.

### Preventive Controls

* Pod Security Standards
* RBAC
* Admission controllers
* Network policies
* Rootless containers

### Detective Controls

* Kubernetes audit logs
* Runtime threat detection
* Falco-style behavioral monitoring

### Corrective Controls

* Node isolation
* Pod eviction
* Credential rotation

---

# Chapter 5 – Security Architecture Patterns

## Identity-Centric Architecture

```text
User
 │
 ▼
Identity Provider
 │
 ▼
Multi-Factor Authentication
 │
 ▼
OAuth / OIDC
 │
 ▼
API Gateway
 │
 ▼
Microservices
```

### Benefits

* Centralized identity.
* Strong authentication.
* Token-based authorization.
* Federation support.

---

## Zero Trust Architecture

Principles:

* Never trust.
* Always verify.
* Assume breach.
* Continuously validate.
* Enforce least privilege.

```text
User
 │
 ▼
Device Verification
 │
 ▼
Identity Verification
 │
 ▼
Context Evaluation
 │
 ▼
Policy Decision
 │
 ▼
Access Granted
```

---

## Secure Microservices Pattern

```text
Ingress
 │
 ▼
API Gateway
 │
 ▼
Service Mesh
 │
 ▼
Mutual TLS
 │
 ▼
Microservices
 │
 ▼
Encrypted Database
```

Security features:

* Mutual TLS (mTLS)
* Service identity
* Traffic encryption
* Fine-grained authorization
* Observability

---

# Chapter 6 – Identity and Access Management (IAM)

Identity is often the primary control against Spoofing and Elevation of Privilege.

### Recommended Practices

* Multi-Factor Authentication (MFA)
* Single Sign-On (SSO)
* OAuth 2.0 / OpenID Connect
* Role-Based Access Control (RBAC)
* Attribute-Based Access Control (ABAC)
* Least privilege
* Just-In-Time (JIT) privileged access
* Periodic access reviews

---

# Chapter 7 – Network Security Controls

| Threat            | Recommended Controls                             |
| ----------------- | ------------------------------------------------ |
| Port scanning     | Firewalls, Network ACLs                          |
| DDoS              | CDN, WAF, Rate limiting                          |
| Lateral movement  | Network segmentation                             |
| Rogue services    | Mutual TLS                                       |
| DNS attacks       | DNSSEC, Secure resolvers                         |
| Man-in-the-Middle | TLS 1.3, Certificate pinning (where appropriate) |

---

# Network Security Layers

```text
Internet
     │
CDN
     │
Web Application Firewall
     │
Load Balancer
     │
API Gateway
     │
Kubernetes Ingress
     │
Service Mesh
     │
Microservices
```

---

# Chapter 8 – Application Security Controls

### Secure Coding

Implement:

* Input validation
* Output encoding
* Parameterized queries
* Strong authentication
* Authorization checks
* Error handling
* Secure session management

### Security Testing

* Static Application Security Testing (SAST)
* Dynamic Application Security Testing (DAST)
* Interactive Application Security Testing (IAST)
* Fuzz testing
* Penetration testing

---

# Chapter 9 – Data Security

Protect data throughout its lifecycle.

## Data at Rest

* AES-256 encryption
* Transparent Data Encryption (TDE)
* Encrypted backups
* Hardware Security Modules (HSMs)

## Data in Transit

* TLS 1.3
* Mutual TLS
* Secure VPNs

## Data in Use

* Memory protection
* Trusted execution environments (where appropriate)
* Data masking in non-production environments

---

# Data Classification

| Classification | Example             | Protection Level |
| -------------- | ------------------- | ---------------- |
| Public         | Marketing brochure  | Low              |
| Internal       | Internal wiki       | Medium           |
| Confidential   | Customer records    | High             |
| Restricted     | Payment credentials | Very High        |

Controls should align with classification.

---

# Chapter 10 – Kubernetes Security

## Control Areas

### Cluster Security

* RBAC
* Admission controllers
* API server hardening
* Audit logging

### Pod Security

* Non-root containers
* Read-only file systems
* Resource limits
* Security contexts

### Network Security

* Network Policies
* Service Mesh
* Mutual TLS

### Supply Chain

* Image signing
* Vulnerability scanning
* Software Bill of Materials (SBOM)

---

# Chapter 11 – Monitoring and Detection

Threat mitigation is incomplete without visibility.

### Logging Sources

* API Gateway
* Authentication service
* Kubernetes audit logs
* Database activity
* WAF
* Cloud audit logs
* CI/CD pipeline events

### Detection Capabilities

* SIEM correlation
* User and Entity Behavior Analytics (UEBA)
* Threat intelligence integration
* Security orchestration and automated response (SOAR)

---

# Example Detection Flow

```text
Application Log
        │
        ▼
Central Log Platform
        │
        ▼
SIEM Correlation
        │
        ▼
Alert
        │
        ▼
SOC Investigation
        │
        ▼
Incident Response
```

---

# Chapter 12 – Security Architecture Decision Records (ADR)

Every significant security decision should be documented.

## ADR Template

### Title

Enforce Multi-Factor Authentication for Administrative Accounts

### Status

Approved

### Context

Administrative accounts are high-value targets.

### Decision

Require phishing-resistant MFA for all privileged users.

### Consequences

#### Positive

* Reduced account takeover risk.
* Improved compliance.
* Stronger identity assurance.

#### Negative

* Additional implementation effort.
* User onboarding changes.

### Review Date

Every 12 months or after significant architectural changes.

---

# Chapter 13 – Residual Risk Analysis

Even after implementing controls, some risk remains.

## Example

| Threat              | Initial Risk | Control             | Residual Risk |
| ------------------- | ------------ | ------------------- | ------------- |
| SQL Injection       | Critical     | ORM + WAF           | Low           |
| Credential Stuffing | High         | MFA + Rate Limiting | Medium        |
| Insider Threat      | High         | RBAC + Logging      | Medium        |
| DDoS                | High         | CDN + Autoscaling   | Medium        |

Residual risk should be reviewed by governance stakeholders.

---

# Chapter 14 – Security Roadmap

Prioritize implementation based on business value and risk reduction.

## Phase 1 (0–3 Months)

* Implement MFA.
* Enable centralized logging.
* Deploy WAF.
* Harden Kubernetes RBAC.

## Phase 2 (3–6 Months)

* Introduce service mesh.
* Encrypt backups.
* Implement runtime threat detection.
* Integrate SAST into CI/CD.

## Phase 3 (6–12 Months)

* Deploy Zero Trust architecture.
* Implement ABAC.
* Expand SOAR automation.
* Conduct enterprise red-team exercises.

---

# Chapter 15 – Executive Reporting

Technical findings must be translated into business language.

## Executive Dashboard Example

| Metric                        | Status |
| ----------------------------- | ------ |
| Critical Threats              | 5      |
| High Threats                  | 12     |
| Medium Threats                | 21     |
| Mitigated                     | 24     |
| Residual High Risks           | 3      |
| Security Controls Implemented | 78%    |

Include trends over time to show improvement and support investment decisions.

---

# Capstone Workshop

## Scenario

Your team has completed the threat analysis of the cloud-native e-commerce platform.

### Tasks

1. Review the Threat Register.
2. Select controls for each critical and high-risk threat.
3. Document Security Architecture Decision Records (ADRs).
4. Update the architecture diagram to reflect new controls.
5. Estimate residual risk.
6. Develop a 12-month implementation roadmap.
7. Present recommendations to a mock Architecture Review Board.

---

# Common Pitfalls

* Selecting controls without understanding the business context.
* Implementing overlapping controls that add complexity without meaningful risk reduction.
* Ignoring operational controls such as monitoring and incident response.
* Failing to assign ownership for mitigation activities.
* Treating residual risk as "zero" after implementing controls.
* Neglecting to revisit architectural decisions as systems evolve.

---

## Pro Tip

**Design controls as an integrated architecture, not isolated technologies.** For example, MFA, RBAC, audit logging, SIEM monitoring, and incident response together provide significantly greater protection than any single control alone. Well-designed security architectures emphasize complementary layers that collectively reduce the likelihood and impact of successful attacks.

---

# Deliverables

By the end of Part 7, participants will have produced:

| Deliverable                                   | Purpose                                      |
| --------------------------------------------- | -------------------------------------------- |
| Threat-to-Control Matrix                      | Maps identified threats to security controls |
| Security Architecture Decision Records (ADRs) | Documents major security design decisions    |
| Updated Secure Architecture Diagram           | Reflects implemented controls                |
| Residual Risk Register                        | Records remaining accepted risks             |
| Security Roadmap                              | Prioritized implementation plan              |
| Executive Risk Dashboard                      | Communicates status to leadership            |
| Architecture Review Presentation              | Supports governance and approval             |

---

# End of Part 7

In **Part 8 – Advanced Threat Modeling for Modern Architectures**, we will extend these concepts to specialized environments, including **microservices, Kubernetes, serverless, APIs, event-driven systems, cloud-native platforms, AI/LLM applications, IoT, mobile, and multi-cloud architectures**, highlighting the unique threat patterns and mitigation strategies for each.
