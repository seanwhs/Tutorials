# Threat Modeling Masterclass

# Part 9 – Threat Modeling Templates, Checklists & Professional Toolkit

## Enterprise Templates, Worksheets, Governance Documents, and Consulting Artifacts

> **Module Duration:** 8–10 Hours (Professional Toolkit Workshop)
>
> **Difficulty:** Expert
>
> **Audience:** Security Architects, Enterprise Architects, Security Consultants, DevSecOps Engineers, Technical Leads, CISOs, Architecture Review Boards
>
> **Objective:** Build a complete set of reusable, enterprise-grade threat modeling templates and checklists suitable for consulting engagements, architecture reviews, compliance audits, and secure software development lifecycle (SSDLC) programs.

---

# Learning Objectives

By the end of this module, participants will be able to:

* Produce standardized threat modeling documentation.
* Conduct structured architecture review interviews.
* Use repeatable worksheets for STRIDE, DREAD, and risk assessment.
* Create professional reports for technical and executive audiences.
* Establish governance around threat modeling.
* Build a reusable toolkit that scales across multiple projects and teams.

---

# Module Overview

```text
Part 9
│
├── Threat Modeling Engagement Template
├── Project Intake Questionnaire
├── Architecture Review Checklist
├── Data Flow Diagram Templates
├── Asset Inventory Worksheet
├── Trust Boundary Worksheet
├── Attack Surface Assessment
├── STRIDE Analysis Worksheet
├── DREAD Risk Assessment
├── Threat Register Template
├── Security Control Matrix
├── Residual Risk Register
├── Architecture Decision Record (ADR)
├── Executive Summary Template
├── Governance Checklists
├── DevSecOps Integration Checklist
├── Security Review Report
├── Architecture Review Board Package
└── Consulting Deliverables
```

---

# Chapter 1 – Threat Modeling Engagement Template

Every engagement should begin with a standardized project definition.

## Project Information

| Field              | Description                              |
| ------------------ | ---------------------------------------- |
| Project Name       | Name of the application or initiative    |
| Business Sponsor   | Executive owner                          |
| Technical Owner    | Lead architect or engineering manager    |
| Security Architect | Threat modeling facilitator              |
| Version            | Document version                         |
| Assessment Date    | Review date                              |
| Review Type        | New system, enhancement, migration, etc. |

---

## Engagement Scope

### Objectives

* Identify architectural threats.
* Recommend security controls.
* Prioritize remediation.
* Document residual risks.

### In Scope

* Applications
* APIs
* Infrastructure
* Cloud services
* Third-party integrations

### Out of Scope

* Legacy systems
* Physical security
* Non-production prototypes (unless specified)

---

# Chapter 2 – Project Intake Questionnaire

This questionnaire helps the facilitator understand the system before conducting the workshop.

## Business Questions

* What business problem does the application solve?
* Who are the users?
* What are the critical business processes?
* What regulations apply?
* What is the acceptable downtime?

---

## Technical Questions

* Is the application cloud-native?
* Is it deployed on Kubernetes?
* Which databases are used?
* What authentication mechanisms are implemented?
* Which third-party services are integrated?

---

## Security Questions

* Has a previous threat model been completed?
* Is MFA implemented?
* Are secrets centrally managed?
* Is encryption used?
* Are security logs monitored?

---

# Workshop Tip

Distribute the questionnaire before the workshop to maximize productive discussion time.

---

# Chapter 3 – Architecture Review Checklist

## Architecture

* Business context documented
* Architecture diagrams available
* Deployment model understood
* Network topology documented
* Technology stack identified

---

## Security Architecture

* Authentication defined
* Authorization model documented
* Encryption strategy documented
* Key management reviewed
* Logging strategy defined

---

## Infrastructure

* Cloud provider identified
* Kubernetes security reviewed
* CI/CD pipeline documented
* Backup strategy reviewed
* Disaster recovery documented

---

## Third-Party Dependencies

* External APIs documented
* Vendor risk assessed
* Service level agreements reviewed
* Trust relationships identified

---

# Chapter 4 – Data Flow Diagram (DFD) Templates

## Level 0 Template

```text
External User
      │
      ▼
System
      │
      ▼
External Service
```

---

## Level 1 Template

```text
User
 │
 ▼
Web Application
 │
 ├── Authentication
 ├── Business Logic
 ├── Notification
 └── Reporting
 │
 ▼
Database
```

---

## Level 2 Template

```text
Checkout API
      │
      ▼
Validation
      │
      ▼
Payment Processor
      │
      ▼
Fraud Detection
      │
      ▼
Payment Gateway
```

---

## DFD Review Checklist

* External entities identified
* Processes labeled
* Data stores documented
* Data flows named
* Trust boundaries highlighted
* Security zones defined

---

# Chapter 5 – Asset Inventory Worksheet

| Asset ID | Asset             | Owner         | Classification | CIA Priority | Notes                |
| -------- | ----------------- | ------------- | -------------- | ------------ | -------------------- |
| A001     | Customer Database | DBA           | Restricted     | C, I, A      | PII                  |
| A002     | Payment API       | Payments Team | Confidential   | C, I         | External integration |
| A003     | Object Storage    | Platform Team | Internal       | A            | Images and documents |

---

## Asset Classification

| Level        | Description          |
| ------------ | -------------------- |
| Public       | No restrictions      |
| Internal     | Employees only       |
| Confidential | Limited business use |
| Restricted   | Highest sensitivity  |

---

# Chapter 6 – Trust Boundary Worksheet

| Boundary ID | Source      | Destination   | Data Crossing | Authentication | Encryption | Notes                 |
| ----------- | ----------- | ------------- | ------------- | -------------- | ---------- | --------------------- |
| TB01        | Internet    | API Gateway   | HTTPS         | OAuth          | TLS        | Public entry point    |
| TB02        | API Gateway | Microservices | JSON          | mTLS           | TLS        | Internal service mesh |

---

## Trust Boundary Checklist

* Is identity verified?
* Is authorization enforced?
* Is encryption applied?
* Are requests validated?
* Are logs generated?

---

# Chapter 7 – Attack Surface Assessment

## External Attack Surface

* Public websites
* APIs
* DNS
* Email
* Mobile applications
* VPN gateways

---

## Internal Attack Surface

* Admin portals
* CI/CD systems
* Databases
* Monitoring platforms
* Kubernetes API
* Identity providers

---

## Cloud Attack Surface

* Object storage
* IAM roles
* Serverless functions
* Managed databases
* Load balancers

---

# Attack Surface Worksheet

| Component      | Exposure | Threats              | Controls           |
| -------------- | -------- | -------------------- | ------------------ |
| API Gateway    | Public   | DoS, Injection       | WAF, Rate limiting |
| Kubernetes API | Internal | Privilege escalation | RBAC, Audit logs   |

---

# Chapter 8 – STRIDE Analysis Worksheet

| Component   | S | T | R | I | D | E | Notes            |
| ----------- | - | - | - | - | - | - | ---------------- |
| API Gateway | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | High exposure    |
| Database    | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | Critical asset   |
| Payment API | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | Financial impact |

---

## Threat Documentation

| Field              | Example                                       |
| ------------------ | --------------------------------------------- |
| Threat ID          | T001                                          |
| STRIDE Category    | Information Disclosure                        |
| Description        | Sensitive data exposed via verbose API errors |
| Affected Component | API Gateway                                   |
| Impact             | Customer data leakage                         |
| Likelihood         | Medium                                        |
| Initial Risk       | High                                          |

---

# Chapter 9 – DREAD Worksheet

| Threat        | Damage | Reproducibility | Exploitability | Affected Users | Discoverability | Average |
| ------------- | -----: | --------------: | -------------: | -------------: | --------------: | ------: |
| SQL Injection |     10 |               9 |              9 |             10 |               8 |     9.2 |
| XSS           |      6 |               7 |              7 |              5 |               8 |     6.6 |

---

## DREAD Interpretation

| Score | Priority |
| ----- | -------- |
| 9–10  | Critical |
| 7–8.9 | High     |
| 4–6.9 | Medium   |
| 0–3.9 | Low      |

---

# Chapter 10 – Threat Register Template

| ID   | Component   | Threat        | STRIDE    | Likelihood | Impact   | Risk     | Owner       | Status      |
| ---- | ----------- | ------------- | --------- | ---------- | -------- | -------- | ----------- | ----------- |
| T001 | API Gateway | JWT Forgery   | Spoofing  | High       | High     | Critical | IAM Team    | Open        |
| T002 | Database    | SQL Injection | Tampering | High       | Critical | Critical | Development | In Progress |

---

## Recommended Additional Fields

* Detection Method
* Control Owner
* Target Completion Date
* Residual Risk
* Validation Status
* Evidence

---

# Chapter 11 – Security Control Matrix

| Threat              | Preventive            | Detective               | Corrective          |
| ------------------- | --------------------- | ----------------------- | ------------------- |
| SQL Injection       | Parameterized queries | Database monitoring     | Restore from backup |
| Credential Stuffing | MFA                   | Login anomaly detection | Password reset      |
| XSS                 | Output encoding       | WAF                     | Patch deployment    |

---

# Chapter 12 – Residual Risk Register

| Threat        | Initial Risk | Controls         | Residual Risk | Accepted By | Review Date |
| ------------- | ------------ | ---------------- | ------------- | ----------- | ----------- |
| SQL Injection | Critical     | ORM, WAF         | Low           | CISO        | Annual      |
| DDoS          | High         | CDN, Autoscaling | Medium        | CTO         | Quarterly   |

---

## Residual Risk Checklist

* Is residual risk documented?
* Has a business owner approved acceptance?
* Is there a review date?
* Are monitoring controls in place?

---

# Chapter 13 – Architecture Decision Record (ADR)

## Template

### ADR Number

ADR-001

### Title

Adopt Mutual TLS for Service-to-Service Communication

### Status

Approved

### Context

Microservices communicate across a service mesh.

### Decision

All inter-service communication will use mutual TLS.

### Consequences

**Positive**

* Improved authentication
* Encrypted traffic
* Reduced spoofing risk

**Negative**

* Increased certificate management complexity

### Alternatives Considered

* Network segmentation only
* API key authentication

### Review Date

12 months

---

# Chapter 14 – Executive Summary Template

## Executive Overview

### Assessment Scope

Brief summary of the reviewed system.

### Key Findings

* Number of threats identified
* High-risk issues
* Regulatory concerns

### Business Impact

* Financial
* Operational
* Reputational

### Recommendations

* Immediate actions
* Medium-term improvements
* Strategic initiatives

---

# Executive Dashboard Example

| Metric              | Value |
| ------------------- | ----: |
| Critical Threats    |     5 |
| High Threats        |    11 |
| Medium Threats      |    24 |
| Low Threats         |    18 |
| Mitigation Complete |   72% |
| Residual High Risks |     2 |

---

# Chapter 15 – Governance Checklists

## Architecture Review Board (ARB)

* Scope approved
* Architecture reviewed
* Threat model completed
* Controls validated
* Risks accepted
* ADRs documented

---

## Security Review Board

* Threat register reviewed
* High-risk items addressed
* Residual risk approved
* Monitoring strategy confirmed

---

## Compliance Review

* Regulatory requirements mapped
* Audit evidence collected
* Security controls documented
* Exceptions recorded

---

# Chapter 16 – DevSecOps Integration Checklist

## Design

* Threat model created
* Security requirements documented

---

## Development

* Secure coding standards followed
* Code reviews completed

---

## Build

* SAST executed
* Dependency scanning completed
* Secrets scanning completed

---

## Test

* DAST executed
* Penetration testing completed
* Security unit tests passed

---

## Deploy

* Infrastructure as Code validated
* Policy-as-code checks passed
* Container images signed

---

## Operate

* SIEM monitoring enabled
* Alerting configured
* Incident response playbooks available

---

# Chapter 17 – Security Review Report Template

## Sections

1. Executive Summary
2. Scope
3. Methodology
4. Architecture Overview
5. Data Flow Diagrams
6. Threat Analysis
7. Risk Assessment
8. Security Controls
9. Residual Risk
10. Recommendations
11. Appendices

---

# Chapter 18 – Architecture Review Board Package

A complete package for presentation should include:

* Executive Summary
* Architecture diagrams
* Threat model
* Risk heat map
* Threat Register
* Residual Risk Register
* ADRs
* Security roadmap
* Decision requests
* Supporting evidence

---

# Professional Consultant Deliverables

A consulting engagement should typically produce:

| Deliverable                      | Audience               |
| -------------------------------- | ---------------------- |
| Threat Modeling Report           | Security Team          |
| Executive Risk Summary           | Executive Leadership   |
| Architecture Review Presentation | ARB                    |
| Threat Register                  | Development & Security |
| Security Roadmap                 | Program Management     |
| Residual Risk Register           | Risk Committee         |
| ADR Collection                   | Engineering Teams      |
| Compliance Evidence Package      | Auditors               |

---

# Workshop Exercise

## Scenario

A financial institution is preparing for an Architecture Review Board meeting.

### Tasks

1. Complete the Project Intake Questionnaire.
2. Develop Level 0–2 DFDs.
3. Populate the Asset Inventory.
4. Document trust boundaries.
5. Complete the STRIDE worksheet.
6. Create the Threat Register.
7. Score threats using DREAD.
8. Develop the Security Control Matrix.
9. Complete the Residual Risk Register.
10. Prepare an Executive Summary and ARB presentation.

Participants should present their deliverables as if conducting a real consulting engagement.

---

# Best Practices

* Standardize templates across the organization.
* Store threat models in version control alongside architecture documentation.
* Reuse checklists to improve consistency without discouraging critical thinking.
* Tailor executive summaries to business outcomes rather than technical details.
* Review and update templates periodically to reflect evolving architectures and threat landscapes.

---

# Common Pitfalls

| Pitfall                                        | Consequence               |
| ---------------------------------------------- | ------------------------- |
| Overly complex templates                       | Reduced adoption by teams |
| Inconsistent terminology                       | Confusion across projects |
| Missing ownership fields                       | Unclear accountability    |
| Static documentation                           | Outdated threat models    |
| Treating templates as substitutes for analysis | Superficial assessments   |

---

## Pro Tip

**A mature threat modeling program is built on repeatability.** Well-designed templates reduce administrative overhead, improve consistency across teams, and allow architects to focus their expertise on identifying meaningful threats rather than recreating documentation from scratch.

---

# Deliverables

By the end of Part 9, participants will have assembled a complete professional toolkit containing:

| Deliverable               | Purpose                                           |
| ------------------------- | ------------------------------------------------- |
| Engagement Templates      | Standardize project initiation                    |
| Questionnaires            | Gather business and technical context             |
| DFD Stencils              | Model system architecture                         |
| STRIDE & DREAD Worksheets | Guide threat identification and prioritization    |
| Threat & Risk Registers   | Track analysis and remediation                    |
| Security Control Matrix   | Map threats to controls                           |
| ADR Templates             | Record security design decisions                  |
| Executive Reports         | Communicate with leadership                       |
| Governance Checklists     | Support Architecture Review Boards and compliance |
| DevSecOps Checklists      | Integrate threat modeling into delivery pipelines |

---

# End of Part 9

In **Part 10 – Enterprise Capstone: End-to-End Threat Modeling Engagement**, participants will conduct a full consulting-style assessment of a large-scale financial services platform. They will apply every technique covered throughout the masterclass—from scoping and DFD creation to STRIDE analysis, risk scoring, mitigation planning, executive reporting, and Architecture Review Board presentation—producing a complete set of enterprise deliverables.
