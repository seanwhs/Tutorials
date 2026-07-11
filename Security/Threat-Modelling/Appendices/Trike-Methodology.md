# Appendix E – Trike Threat Modeling Methodology

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix E**
> **Purpose:** This appendix provides a comprehensive reference for the **Trike Threat Modeling Methodology**, a **risk-centric and requirements-driven** approach to threat modeling. Unlike STRIDE, which begins with threat categories, or PASTA, which begins with business objectives, **Trike starts with defining acceptable levels of risk and security requirements** for each asset before identifying threats.

> **Best suited for:** Financial institutions, government agencies, regulated industries, enterprise governance, compliance-focused organizations, and environments where formal risk management is required.

---

# Table of Contents

1. Introduction to Trike
2. History and Philosophy
3. Trike vs STRIDE vs PASTA
4. Core Principles
5. Trike Methodology Overview
6. Stage 1 – Define Assets
7. Stage 2 – Define Actors
8. Stage 3 – Define Security Requirements
9. Stage 4 – Build the Risk Model
10. Stage 5 – Threat Identification
11. Stage 6 – Risk Assessment
12. Stage 7 – Mitigation Planning
13. Trike Workflow Example
14. Risk Matrix
15. Deliverables
16. Strengths and Limitations
17. Integrating Trike into Governance
18. Trike Quick Reference

---

# 1. Introduction to Trike

**Trike** is an **asset-centric threat modeling methodology** that emphasizes **acceptable risk** rather than simply identifying threats.

Instead of asking:

> "What threats exist?"

Trike asks:

> **"What level of risk is acceptable for each asset?"**

Only after defining acceptable risk does the team identify threats that exceed those limits.

---

## Core Objective

Ensure that every security control can be traced back to a business requirement and an acceptable level of risk.

This creates a clear connection between:

* Business objectives
* Security requirements
* Risk acceptance
* Security controls

---

# 2. History and Philosophy

Trike was developed as an **open-source threat modeling methodology** with a strong focus on:

* Risk management
* Security requirements engineering
* Formal modeling
* Least privilege
* Compliance

Unlike frameworks that focus primarily on attacker behavior, Trike is concerned with **ensuring that every asset receives protection proportional to its value**.

---

# 3. Trike vs STRIDE vs PASTA

| Characteristic | STRIDE               | PASTA                   | Trike                     |
| -------------- | -------------------- | ----------------------- | ------------------------- |
| Starting Point | System architecture  | Business objectives     | Assets and risk           |
| Primary Focus  | Threat categories    | Attack scenarios        | Acceptable risk           |
| Perspective    | Technical            | Business + Attacker     | Business + Governance     |
| Risk Analysis  | Separate activity    | Integrated              | Central to methodology    |
| Best For       | Software development | Enterprise architecture | Governance and compliance |

---

# 4. Core Principles

Trike is based on several key principles:

### 1. Asset-Centric

Security decisions begin with identifying and valuing assets.

### 2. Requirements-Driven

Security requirements are defined before identifying threats.

### 3. Risk-Based

Risk is measured against predefined acceptance criteria.

### 4. Least Privilege

Users and systems receive only the permissions required to perform their functions.

### 5. Traceability

Every identified threat should map to:

* A security requirement
* A business objective
* A risk owner
* A mitigation strategy

---

# 5. Trike Methodology Overview

The Trike process can be summarized as follows:

```text id="trike-flow"
Identify Assets
        │
        ▼
Identify Actors
        │
        ▼
Define Security Requirements
        │
        ▼
Build Risk Model
        │
        ▼
Identify Threats
        │
        ▼
Assess Risk
        │
        ▼
Select Controls
        │
        ▼
Accept or Mitigate Risk
```

---

# 6. Stage 1 – Define Assets

The first step is to identify and classify everything that has value to the organization.

## Types of Assets

### Information Assets

* Customer records
* Financial transactions
* Medical records
* Intellectual property
* Source code

### Technical Assets

* Servers
* APIs
* Databases
* Cloud storage
* Identity providers

### Business Assets

* Brand reputation
* Revenue streams
* Regulatory compliance
* Customer trust
* Business continuity

---

## Asset Classification Example

| Asset                  | Classification | Business Value |
| ---------------------- | -------------- | -------------- |
| Customer Database      | Confidential   | Critical       |
| Public Website         | Public         | Medium         |
| Payment Gateway        | Confidential   | Critical       |
| HR Portal              | Internal       | High           |
| Source Code Repository | Restricted     | Critical       |

---

# 7. Stage 2 – Define Actors

Actors represent entities that interact with the system.

## Types of Actors

### Internal

* Employees
* Administrators
* Developers
* Security Analysts
* System Operators

### External

* Customers
* Business Partners
* Third-Party Vendors
* Cloud Providers
* External APIs

### Threat Actors

* Cybercriminals
* Nation-state actors
* Hacktivists
* Malicious insiders
* Competitors
* Automated bots

---

## Example Actor Matrix

| Actor          | Trust Level | Typical Permissions   |
| -------------- | ----------- | --------------------- |
| Customer       | Low         | View own account      |
| Employee       | Medium      | Business operations   |
| Administrator  | High        | System management     |
| API Partner    | Medium      | Limited integration   |
| Anonymous User | None        | Public resources only |

---

# 8. Stage 3 – Define Security Requirements

This is the defining characteristic of Trike.

Before identifying threats, determine the required level of protection for each asset.

### Security Properties

* Confidentiality
* Integrity
* Availability
* Accountability
* Privacy
* Compliance

---

## Example Requirements

| Asset             | Requirement                    |
| ----------------- | ------------------------------ |
| Customer Database | Encrypt at rest and in transit |
| Payment API       | MFA for administrative access  |
| Source Code       | Restricted repository access   |
| Audit Logs        | Immutable storage              |
| IAM System        | Role-based access control      |

---

## Security Requirement Matrix

| Asset             | C      | I      | A    | Accountability |
| ----------------- | ------ | ------ | ---- | -------------- |
| Customer Records  | High   | High   | High | High           |
| Marketing Website | Low    | Medium | High | Medium         |
| Payment System    | High   | High   | High | High           |
| Logging Platform  | Medium | High   | High | Critical       |

---

# 9. Stage 4 – Build the Risk Model

A risk model defines the organization's tolerance for risk.

### Risk Components

* Asset value
* Threat likelihood
* Vulnerability severity
* Business impact
* Existing controls

---

## Example Risk Formula

```text id="risk-formula"
Risk =

Asset Value

×

Threat Likelihood

×

Vulnerability Severity
```

Organizations may customize this model based on governance requirements.

---

## Example Risk Matrix

| Asset                   | Asset Value | Risk Tolerance |
| ----------------------- | ----------- | -------------- |
| Customer Data           | Critical    | Very Low       |
| Marketing Website       | Medium      | Moderate       |
| Development Environment | High        | Low            |
| Test Environment        | Medium      | Moderate       |

---

# 10. Stage 5 – Threat Identification

Once acceptable risk levels are defined, identify threats that could exceed those limits.

### Example Threats

| Asset              | Threat                  |
| ------------------ | ----------------------- |
| Customer Database  | SQL Injection           |
| API Gateway        | Credential stuffing     |
| Kubernetes Cluster | Privilege escalation    |
| Cloud Storage      | Public bucket exposure  |
| CI/CD Pipeline     | Supply chain compromise |

---

### Mapping Threats to Assets

```text id="asset-threat-map"
Customer Database
        │
        ├── SQL Injection
        ├── Insider Abuse
        ├── Data Exfiltration
        └── Backup Theft
```

---

# 11. Stage 6 – Risk Assessment

Evaluate each threat against the predefined risk model.

### Example

| Threat             | Likelihood | Impact   | Overall Risk |
| ------------------ | ---------- | -------- | ------------ |
| SQL Injection      | High       | Critical | Critical     |
| Brute Force Login  | Medium     | High     | High         |
| Insider Data Theft | Low        | Critical | High         |
| DDoS               | Medium     | Medium   | Medium       |

---

## Risk Treatment Options

* Mitigate
* Transfer
* Avoid
* Accept

Document the chosen treatment and assign a risk owner.

---

# 12. Stage 7 – Mitigation Planning

Select security controls that reduce risk to an acceptable level.

### Control Categories

#### Preventive

* MFA
* Encryption
* RBAC
* Network segmentation
* Secure coding

#### Detective

* SIEM
* Audit logging
* IDS/IPS
* Continuous monitoring

#### Corrective

* Backups
* Disaster recovery
* Incident response
* Automated rollback

---

## Example Control Matrix

| Threat                | Control                     | Residual Risk |
| --------------------- | --------------------------- | ------------- |
| SQL Injection         | Parameterized queries + WAF | Low           |
| Credential Stuffing   | MFA + Rate limiting         | Low           |
| Public Storage Bucket | IAM policies + CSPM         | Very Low      |

---

# 13. Trike Workflow Example

## Scenario: Online Healthcare Portal

### Asset

Electronic Medical Records (EMR)

### Security Requirement

* Confidentiality: High
* Integrity: High
* Availability: High

### Threat

Unauthorized access through stolen credentials.

### Risk

High.

### Mitigation

* MFA
* Adaptive authentication
* Device trust verification
* Audit logging

### Residual Risk

Medium.

Accepted by:

Chief Information Security Officer (CISO).

---

# 14. Deliverables

A Trike assessment typically produces:

* Asset inventory.
* Asset classification matrix.
* Actor inventory.
* Security requirements specification.
* Risk model.
* Threat register.
* Risk register.
* Security control matrix.
* Residual risk register.
* Governance report.
* Executive summary.

---

# 15. Strengths and Limitations

## Strengths

* Strong alignment with governance.
* Clear traceability from business requirements to controls.
* Well suited for compliance and audit.
* Encourages formal documentation.
* Supports enterprise risk management.

## Limitations

* More documentation than lightweight methods.
* Requires clear governance processes.
* Less intuitive for development teams unfamiliar with risk management.
* Can be time-consuming for small projects.

---

# 16. Integrating Trike into Governance

Trike fits naturally into enterprise governance processes.

### Architecture Review Board (ARB)

* Validate asset inventory.
* Review security requirements.
* Approve architecture decisions.

### Risk Committee

* Review high-risk findings.
* Approve risk acceptance.
* Monitor residual risks.

### Compliance Team

* Map controls to regulations.
* Validate evidence.
* Support audits.

### DevSecOps

* Implement approved controls.
* Automate compliance checks.
* Monitor control effectiveness.

---

# 17. Trike Quick Reference

## Seven Steps

1. Identify assets.
2. Identify actors.
3. Define security requirements.
4. Build the risk model.
5. Identify threats.
6. Assess risk.
7. Select controls and manage residual risk.

---

## Key Questions

* What assets are we protecting?
* How valuable are they?
* Who interacts with them?
* What level of protection is required?
* What threats exceed our acceptable risk?
* Which controls reduce risk to an acceptable level?
* Who owns the remaining residual risk?

---

## Trike Assessment Checklist

* Assets identified and classified.
* Actors documented.
* Security requirements approved.
* Risk model defined.
* Threats mapped to assets.
* Risks assessed.
* Controls selected.
* Residual risks documented.
* Risk owners assigned.
* Governance approvals completed.

---

# Key Takeaways

* **Trike is a governance-oriented, risk-centric methodology** that begins with understanding asset value and defining acceptable levels of risk before identifying threats.
* It provides strong traceability between business objectives, security requirements, identified threats, and implemented controls, making it particularly valuable in regulated and compliance-driven environments.
* Compared with STRIDE and PASTA, Trike places greater emphasis on formal risk management, documentation, and accountability, making it well suited for enterprise governance, audit preparation, and long-term security program maturity.
* Organizations that adopt Trike effectively integrate threat modeling with risk management, architecture governance, and compliance processes, ensuring that security investments remain aligned with business priorities and risk tolerance.
