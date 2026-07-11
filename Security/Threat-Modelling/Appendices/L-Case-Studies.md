# Appendix L – Threat Modeling Case Studies & End-to-End Worked Examples

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix L**
>
> **Purpose:** This appendix presents **complete, real-world threat modeling case studies** that demonstrate how professional security architects conduct threat modeling from initial architecture review through risk assessment, mitigation planning, and executive reporting.
>
> Each case study follows the same structured methodology used in enterprise security reviews and Architecture Review Boards (ARBs), allowing learners to see how concepts from the course are applied in practice.
>
> **Audience:** Security Architects, Solution Architects, Developers, DevSecOps Engineers, Cloud Architects, Security Consultants, Enterprise Architects, Risk Managers, and Security Champions.

---

# Table of Contents

1. How to Use These Case Studies
2. Case Study Structure
3. Case Study 1 – Online Banking System
4. Case Study 2 – E-Commerce Platform
5. Case Study 3 – Healthcare Patient Portal
6. Case Study 4 – SaaS CRM Platform
7. Case Study 5 – Cloud-Native Microservices Platform
8. Case Study 6 – CI/CD Pipeline
9. Lessons Learned Across All Case Studies
10. Common Threat Patterns
11. Reusable Security Patterns
12. Executive Reporting Examples
13. Practitioner Tips

---

# 1. How to Use These Case Studies

Each case study demonstrates the complete lifecycle of a professional threat modeling exercise.

The workflow is:

```text
Business Context
        │
        ▼
Architecture Review
        │
        ▼
Identify Assets
        │
        ▼
Create DFD
        │
        ▼
Identify Trust Boundaries
        │
        ▼
Apply STRIDE
        │
        ▼
Assess Risk
        │
        ▼
Recommend Controls
        │
        ▼
Document Residual Risk
        │
        ▼
Executive Summary
```

Each example is intentionally simplified while preserving the techniques used in real enterprise engagements.

---

# 2. Standard Case Study Structure

Every case study contains the following sections:

1. Business Overview
2. Architecture Description
3. Key Assets
4. Data Flow Diagram (textual)
5. Trust Boundaries
6. Threat Analysis (STRIDE)
7. Risk Assessment
8. Recommended Controls
9. Residual Risk
10. Executive Summary

---

# 3. Case Study 1 – Online Banking System

## Business Overview

A retail bank provides customers with online banking services, including:

* Account management
* Funds transfer
* Bill payment
* Loan applications
* Investment management

The application is internet-facing and must comply with financial regulations.

---

## Architecture Overview

Components:

* Customer Browser
* Web Application Firewall (WAF)
* Web Front End
* API Gateway
* Authentication Service
* Transaction Service
* Customer Database
* Payment Gateway
* Logging/SIEM

---

## Key Assets

| Asset                 | Classification | Criticality |
| --------------------- | -------------- | ----------- |
| Customer PII          | Confidential   | Critical    |
| Account Balances      | Confidential   | Critical    |
| Transaction Records   | Confidential   | Critical    |
| Authentication Tokens | Restricted     | Critical    |
| Audit Logs            | Internal       | High        |

---

## Data Flow (Simplified)

```text
Customer Browser
      │ HTTPS
      ▼
Web Application
      │
      ▼
API Gateway
      │
 ┌────┴────┐
 ▼         ▼
Auth     Transaction
Service   Service
      │
      ▼
Customer Database
```

---

## Trust Boundaries

* Internet → WAF
* WAF → Web Tier
* Web Tier → API Layer
* API Layer → Database
* Bank → External Payment Gateway

---

## STRIDE Analysis

| Component    | Threat                 | Example                 |
| ------------ | ---------------------- | ----------------------- |
| Login        | Spoofing               | Credential stuffing     |
| API          | Tampering              | Parameter manipulation  |
| Logs         | Repudiation            | User denies transaction |
| Database     | Information Disclosure | SQL Injection           |
| API Gateway  | DoS                    | Flood of API requests   |
| Admin Portal | Elevation of Privilege | Misconfigured RBAC      |

---

## Risk Assessment

| Threat              | Likelihood | Impact   | Rating   |
| ------------------- | ---------- | -------- | -------- |
| Credential Stuffing | High       | High     | Critical |
| SQL Injection       | Medium     | Critical | High     |
| API DoS             | Medium     | High     | High     |
| Insider Abuse       | Low        | Critical | High     |

---

## Recommended Controls

* Multi-Factor Authentication (MFA)
* Adaptive authentication
* WAF with bot protection
* Parameterized SQL queries
* RBAC with least privilege
* Immutable audit logging
* API rate limiting
* Fraud analytics
* SIEM monitoring
* Transaction signing for high-risk transfers

---

## Residual Risk

After controls:

* Credential theft through phishing remains possible.
* Insider misuse cannot be completely eliminated.
* Third-party payment gateway outages remain a business dependency.

---

## Executive Summary

**Overall Risk:** High

Top Priorities:

1. Strengthen identity controls.
2. Improve API security.
3. Enhance fraud detection.
4. Expand monitoring coverage.

---

# 4. Case Study 2 – E-Commerce Platform

## Business Overview

A global retailer provides:

* Product catalog
* Shopping cart
* Online payments
* Order management
* Customer accounts

---

## Key Assets

* Customer PII
* Payment information
* Order history
* Product inventory
* Promotional codes

---

## Major Threats

* Credential stuffing
* Card fraud
* SQL Injection
* Cross-Site Scripting (XSS)
* Broken Access Control
* Inventory manipulation
* Coupon abuse
* Bot-driven scraping

---

## Recommended Controls

* MFA for customer accounts (optional/risk-based)
* Web Application Firewall
* CSP and output encoding for XSS prevention
* Parameterized queries
* PCI DSS-compliant payment processing
* Rate limiting and bot management
* Fraud detection and transaction monitoring

---

## Key Lesson

Business logic abuse (e.g., discount manipulation, cart tampering) can be as damaging as technical vulnerabilities and should be explicitly modeled.

---

# 5. Case Study 3 – Healthcare Patient Portal

## Business Overview

A healthcare provider offers patients access to:

* Medical records
* Appointment scheduling
* Prescription renewals
* Telemedicine sessions

---

## Sensitive Assets

* Electronic Health Records (EHR)
* Personal Identifiable Information (PII)
* Protected Health Information (PHI)
* Medical images
* Insurance information

---

## Key Threats

| STRIDE Category        | Example                           |
| ---------------------- | --------------------------------- |
| Spoofing               | Stolen patient credentials        |
| Tampering              | Modification of prescriptions     |
| Repudiation            | Denial of medical record access   |
| Information Disclosure | Exposure of PHI                   |
| DoS                    | Ransomware affecting availability |
| Elevation of Privilege | Unauthorized clinician access     |

---

## Recommended Controls

* Strong MFA
* Role-based access control
* Break-glass emergency access with auditing
* Encryption at rest and in transit
* Comprehensive audit trails
* Data Loss Prevention (DLP)
* Regular backup and recovery testing

---

## Key Lesson

Availability is a patient safety issue. Threat modeling must consider operational resilience alongside confidentiality.

---

# 6. Case Study 4 – SaaS CRM Platform

## Business Overview

A Software-as-a-Service (SaaS) provider delivers customer relationship management (CRM) capabilities to multiple organizations using a shared cloud platform.

---

## Architecture Characteristics

* Multi-tenant application
* REST APIs
* OAuth/OpenID Connect
* Cloud object storage
* Microservices
* CI/CD deployment pipeline

---

## Major Threats

* Tenant data isolation failure
* API authorization bypass
* Secrets leakage
* Supply chain compromise
* Cloud storage misconfiguration
* Session hijacking

---

## Recommended Controls

* Tenant-aware authorization
* Encryption with customer-managed keys (where applicable)
* Secrets management service
* Continuous configuration monitoring
* Secure SDLC with SAST/SCA
* Automated cloud posture management (CSPM)

---

## Key Lesson

In multi-tenant systems, tenant isolation is a core architectural security requirement and should be validated throughout the design.

---

# 7. Case Study 5 – Cloud-Native Microservices Platform

## Business Overview

An enterprise operates a cloud-native platform with dozens of microservices deployed on Kubernetes.

---

## Components

* API Gateway
* Service Mesh
* Kubernetes Cluster
* Container Registry
* Message Broker
* Identity Provider
* Observability Platform

---

## Key Threats

* Service impersonation
* Insecure service-to-service communication
* Container escape
* Compromised images
* Kubernetes API abuse
* Excessive IAM permissions

---

## Recommended Controls

* Mutual TLS (mTLS)
* Service mesh authorization policies
* Image signing and verification
* Admission controllers
* Runtime container security
* Least-privilege IAM roles
* Network policies

---

## Key Lesson

Threat modeling should extend beyond application code to include orchestration platforms, service meshes, and cloud infrastructure.

---

# 8. Case Study 6 – CI/CD Pipeline

## Business Overview

A software company deploys production changes multiple times per day using an automated CI/CD pipeline.

---

## Assets

* Source code
* Build servers
* Artifact repository
* Deployment credentials
* Signing keys
* Production infrastructure

---

## Threats

* Source code tampering
* Malicious pull requests
* Dependency poisoning
* Secret exposure
* Unauthorized deployments
* Artifact substitution

---

## Recommended Controls

* Branch protection rules
* Mandatory code reviews
* Signed commits
* Software Composition Analysis (SCA)
* Secrets scanning
* Artifact signing
* SBOM generation
* Deployment approvals for sensitive environments

---

## Key Lesson

The CI/CD pipeline is itself a critical asset and should be threat modeled with the same rigor as production applications.

---

# 9. Lessons Learned Across All Case Studies

Common themes include:

* Identity is a primary attack vector.
* APIs frequently represent the largest attack surface.
* Misconfigured cloud services introduce significant risk.
* Third-party integrations require explicit trust boundary analysis.
* Logging and monitoring are essential for detecting and responding to attacks.
* Business logic flaws often evade traditional vulnerability scanning.

---

# 10. Common Threat Patterns

| Pattern                | Typical Mitigation                                 |
| ---------------------- | -------------------------------------------------- |
| Credential Theft       | MFA, phishing-resistant authentication             |
| Injection              | Input validation, parameterized queries            |
| Broken Access Control  | Server-side authorization checks                   |
| Data Exposure          | Encryption, data minimization                      |
| Supply Chain Attack    | SCA, SBOM, signed artifacts                        |
| Cloud Misconfiguration | CSPM, IaC scanning                                 |
| Insider Threat         | Least privilege, monitoring, segregation of duties |
| API Abuse              | Rate limiting, API gateways, schema validation     |

---

# 11. Reusable Security Patterns

Across different architectures, several security patterns consistently reduce risk:

* Defense in Depth
* Zero Trust
* Secure by Default
* Least Privilege
* Centralized Identity
* Immutable Infrastructure
* Secrets Management
* Encryption Everywhere
* Continuous Monitoring
* Automated Security Testing

---

# 12. Executive Reporting Examples

### Executive Risk Summary

| Category       | Status |
| -------------- | ------ |
| Critical Risks | 2      |
| High Risks     | 5      |
| Medium Risks   | 11     |
| Low Risks      | 18     |

### Top Recommendations

1. Strengthen identity and access management.
2. Improve API security controls.
3. Increase visibility through centralized logging.
4. Integrate security testing into CI/CD.
5. Conduct recurring threat modeling for major architectural changes.

---

# 13. Practitioner Tips

* Start with business objectives before analyzing technology.
* Keep Data Flow Diagrams simple and focused.
* Reuse threat libraries and security patterns where possible.
* Involve developers, architects, operations, and business stakeholders in workshops.
* Update threat models whenever significant changes are introduced.
* Treat threat modeling as a living artifact, not a one-time compliance exercise.

---

# Appendix L Summary

These case studies demonstrate how threat modeling moves from **theory to practice**. By applying structured methodologies such as STRIDE to realistic architectures, organizations can identify meaningful risks, prioritize mitigations, and make informed security decisions.

The recurring patterns across banking, healthcare, e-commerce, SaaS, cloud-native platforms, and CI/CD pipelines show that while technologies evolve, the core principles of identifying assets, understanding trust boundaries, evaluating threats, and implementing layered controls remain consistent. Regularly revisiting these models as systems change is a hallmark of a mature and effective secure architecture program.
