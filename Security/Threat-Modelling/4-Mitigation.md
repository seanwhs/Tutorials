# Threat Modeling Masterclass

# Part 4 – Mitigation and Strategy

## Designing Security Controls, Managing Residual Risk, and Integrating Threat Modeling into DevSecOps

> **Module Duration:** 6–7 Hours (Lecture + Architecture Workshop + Case Study)
>
> **Objective:** Learn how to transform identified threats into practical security controls, evaluate residual risk, communicate security decisions to stakeholders, and integrate threat modeling into Agile, DevSecOps, and CI/CD pipelines.

---

# Learning Objectives

By the end of this module, learners will be able to:

* Select appropriate security controls based on identified threats.
* Understand the hierarchy of security controls.
* Apply defense-in-depth principles.
* Develop mitigation strategies for common attack scenarios.
* Understand risk treatment options.
* Evaluate and document residual risk.
* Communicate security risks effectively to both technical and non-technical stakeholders.
* Integrate threat modeling into Agile and DevSecOps practices.
* Automate security validation throughout the CI/CD pipeline.
* Establish threat modeling as a continuous engineering practice.

---

# Module Overview

```text
Part 4
│
├── Threat Mitigation Fundamentals
├── Security Control Categories
├── Defense in Depth
├── Mapping Threats to Controls
├── Secure Design Principles
├── Risk Treatment Strategies
├── Residual Risk
├── Risk Acceptance
├── Security Documentation
├── Agile Integration
├── DevSecOps Integration
├── CI/CD Security Gates
├── Continuous Threat Modeling
├── Enterprise Governance
├── Real-World Case Study
├── Workshop
└── Best Practices
```

---

# Chapter 1 – From Threats to Controls

Threat identification is only valuable if it leads to action.

The primary goal of threat modeling is **not** to produce documentation.

The goal is to improve the security of the system.

Every identified threat should result in one of the following:

* A preventive control
* A detective control
* A corrective control
* A conscious risk acceptance

If a threat is identified but no action is taken, the threat model has failed to provide business value.

---

# The Threat Modeling Process Revisited

```text
Business Requirements

↓

Architecture Design

↓

Threat Model

↓

Threat Identification

↓

Risk Assessment

↓

Security Controls

↓

Secure Development

↓

Testing

↓

Deployment

↓

Continuous Monitoring
```

Notice that threat modeling sits at the center of secure architecture.

---

# Chapter 2 – What Are Security Controls?

A **security control** is any safeguard that reduces the likelihood or impact of a threat.

Controls may be:

* Technical
* Administrative
* Physical

Threat modeling primarily recommends **technical controls**, but organizational and operational controls are equally important.

---

# Categories of Security Controls

## Preventive Controls

Prevent attacks from succeeding.

Examples:

* Authentication
* Authorization
* Encryption
* Input validation
* Network segmentation
* Firewalls
* Multi-Factor Authentication (MFA)

---

## Detective Controls

Identify attacks that are occurring or have already occurred.

Examples:

* Security Information and Event Management (SIEM)
* Intrusion Detection Systems (IDS)
* Audit logging
* Security monitoring
* Endpoint Detection and Response (EDR)

---

## Corrective Controls

Reduce damage after an incident.

Examples:

* Backups
* Disaster recovery
* Incident response
* Automated rollback
* Patch management
* Business continuity plans

---

# Security Control Matrix

| Threat              | Preventive            | Detective                    | Corrective       |
| ------------------- | --------------------- | ---------------------------- | ---------------- |
| SQL Injection       | Parameterized Queries | Database Activity Monitoring | Database Restore |
| XSS                 | Output Encoding       | Web Logs                     | Code Patch       |
| Credential Stuffing | MFA, Rate Limiting    | Login Monitoring             | Password Reset   |
| Malware Upload      | File Validation       | Antivirus Scan               | File Removal     |
| DoS                 | WAF, CDN              | Traffic Monitoring           | Autoscaling      |

---

# Chapter 3 – Defense in Depth

One of the most important security principles is **Defense in Depth**.

Never rely on a single security control.

Instead, use multiple independent layers.

---

# Example

A banking application should not rely solely on passwords.

Instead:

```text
Customer

↓

Password

↓

MFA

↓

Device Verification

↓

Risk-Based Authentication

↓

Session Monitoring

↓

Fraud Detection
```

If one layer fails, another continues to protect the system.

---

# Network Defense in Depth

```text
Internet

↓

Firewall

↓

Web Application Firewall

↓

Load Balancer

↓

API Gateway

↓

Application Server

↓

Database Firewall

↓

Database Encryption
```

Every layer increases the difficulty for attackers.

---

# Application Defense in Depth

```text
Input Validation

↓

Authentication

↓

Authorization

↓

Business Rules

↓

Encryption

↓

Audit Logging

↓

Monitoring

↓

Backup
```

Notice that security exists throughout the application—not just at the perimeter.

---

# Chapter 4 – Mapping Threats to Controls

The threat register should evolve into a mitigation plan.

Each threat should have:

* An identified owner
* Recommended controls
* Priority
* Target completion date
* Validation method

---

# Example Mapping

| Threat                | Security Control              |
| --------------------- | ----------------------------- |
| SQL Injection         | ORM, Parameterized Queries    |
| XSS                   | Context-Aware Output Encoding |
| CSRF                  | Anti-CSRF Tokens              |
| Session Hijacking     | Secure Cookies, MFA           |
| Broken Authentication | Strong Password Policy        |
| Broken Authorization  | RBAC, ABAC                    |
| Credential Stuffing   | MFA, CAPTCHA, Rate Limiting   |
| File Upload Abuse     | Antivirus, Content Validation |
| SSRF                  | Outbound Network Filtering    |
| Ransomware            | Immutable Backups             |

---

# Chapter 5 – Secure Design Principles

Threat modeling is guided by established secure design principles.

---

## Least Privilege

Users, services, and applications should have only the permissions necessary to perform their functions.

Example:

A reporting service should not have permission to modify payroll records.

---

## Fail Securely

If an application encounters an error, it should fail in a secure state.

Poor example:

```text
Authentication Error

↓

Grant Access
```

Correct behavior:

```text
Authentication Error

↓

Deny Access
```

---

## Secure by Default

Security should require no additional configuration.

Example:

* HTTPS enabled by default
* MFA enabled
* Logging enabled
* Secure cookie flags enabled

---

## Complete Mediation

Every request should be authorized.

Never assume previous authorization remains valid.

---

## Minimize Attack Surface

Disable:

* Unused services
* Test APIs
* Debug endpoints
* Sample applications
* Default accounts

---

## Separation of Duties

Critical operations should require multiple approvals.

Examples:

* Financial transfers
* Production deployments
* Root certificate changes

---

# Chapter 6 – Risk Treatment Strategies

Not every risk is handled the same way.

Organizations generally choose one of four strategies.

---

## 1. Avoid

Eliminate the activity entirely.

Example:

Disable an unnecessary public API.

---

## 2. Mitigate

Reduce risk using security controls.

Example:

Implement MFA and rate limiting.

---

## 3. Transfer

Shift financial responsibility to another party.

Examples:

* Cyber insurance
* Managed security services
* Cloud provider contracts

---

## 4. Accept

Consciously accept the remaining risk.

Acceptance should always be:

* Documented
* Approved
* Periodically reviewed

---

# Risk Treatment Matrix

| Risk                 | Treatment |
| -------------------- | --------- |
| SQL Injection        | Mitigate  |
| Legacy System        | Accept    |
| Unsupported Protocol | Avoid     |
| Cloud Outage         | Transfer  |

---

# Chapter 7 – Residual Risk

## Definition

Residual Risk is the risk that remains **after** security controls have been implemented.

No system is completely secure.

The objective is to reduce risk to an acceptable level—not to eliminate all risk, which is rarely practical.

---

# Example

Initial Threat

SQL Injection

Likelihood

High

Impact

Critical

Overall Risk

Critical

---

Mitigation

* Parameterized queries
* ORM
* Input validation
* Least privilege database accounts
* Web Application Firewall
* Secure coding review
* Automated SAST

Residual Risk

Low

Although significantly reduced, some residual risk remains due to potential coding errors or new attack techniques.

---

# Residual Risk Register

| Threat              | Initial Risk | Controls       | Residual Risk | Accepted By      |
| ------------------- | ------------ | -------------- | ------------- | ---------------- |
| SQL Injection       | Critical     | ORM + WAF      | Low           | CISO             |
| Credential Stuffing | High         | MFA            | Medium        | Product Owner    |
| Insider Abuse       | High         | RBAC + Logging | Medium        | Security Manager |

---

# Risk Acceptance

Risk acceptance is a business decision—not solely a technical one.

Typical stakeholders include:

* Chief Information Security Officer (CISO)
* Chief Technology Officer (CTO)
* Product Owner
* Business Owner
* Risk Committee

A formal acceptance should include:

* Risk description
* Business justification
* Existing controls
* Residual risk rating
* Expiration or review date
* Approver

---

# Chapter 8 – Communicating Risk

Different audiences require different levels of detail.

## Developers

Need:

* Technical details
* Root cause
* Code examples
* Mitigation guidance

---

## Architects

Need:

* Architectural implications
* Trust boundary impacts
* Design recommendations

---

## Executives

Need:

* Business impact
* Financial implications
* Compliance considerations
* Risk trends
* Residual risk

---

# Executive Risk Summary Example

| Risk                   | Business Impact        | Status       |
| ---------------------- | ---------------------- | ------------ |
| SQL Injection          | Customer data exposure | Mitigated    |
| Credential Stuffing    | Account takeover       | Monitoring   |
| DDoS                   | Service disruption     | WAF deployed |
| Cloud Misconfiguration | Regulatory fines       | Remediating  |

---

# Chapter 9 – Integrating Threat Modeling into Agile

Threat modeling should become part of every sprint—not an annual exercise.

---

## Agile Workflow

```text
Product Backlog

↓

Sprint Planning

↓

Architecture Discussion

↓

Threat Modeling

↓

Development

↓

Security Testing

↓

Sprint Review

↓

Retrospective
```

---

## During Sprint Planning

For every new feature, ask:

* What assets are introduced?
* What new entry points exist?
* Are new trust boundaries created?
* Does this change authentication or authorization?
* Does it process sensitive data?

These questions encourage security-focused design discussions before coding begins.

---

# Definition of Ready (DoR)

A user story is ready for development only if:

* Architecture is understood.
* Security requirements are identified.
* Threat model updated (if necessary).
* Acceptance criteria include security considerations.

---

# Definition of Done (DoD)

A feature is complete only if:

* Security controls are implemented.
* Threats have been reviewed.
* Static analysis passes.
* Security tests pass.
* Documentation is updated.

---

# Chapter 10 – DevSecOps Integration

DevSecOps embeds security throughout the software delivery lifecycle.

Threat modeling provides the design-time perspective, while automated tools continuously validate implementation.

---

# DevSecOps Pipeline

```text
Developer Commit

↓

Static Application Security Testing (SAST)

↓

Software Composition Analysis (SCA)

↓

Secrets Detection

↓

Container Image Scan

↓

Infrastructure-as-Code Scan

↓

Threat Model Validation

↓

Dynamic Application Security Testing (DAST)

↓

Penetration Testing

↓

Production Deployment

↓

Continuous Monitoring
```

---

# Recommended Security Automation

## Source Code

* Static code analysis
* Secret detection
* Dependency scanning

---

## Containers

* Base image scanning
* Vulnerability assessment
* Configuration validation

---

## Infrastructure

* Infrastructure-as-Code scanning
* Cloud security posture management
* Policy-as-code

---

## Runtime

* Runtime application self-protection
* Security monitoring
* SIEM integration
* Behavioral analytics

---

# Threat Modeling as Code

Modern organizations increasingly manage threat models as version-controlled artifacts.

Benefits include:

* Traceability
* Peer review
* Collaboration
* Integration with pull requests
* Automated validation
* Historical tracking

Threat models should evolve alongside application code.

---

# Chapter 11 – Continuous Threat Modeling

Threat modeling is not a one-time deliverable.

It should be revisited whenever:

* New features are added.
* Third-party integrations change.
* Infrastructure changes.
* Authentication mechanisms change.
* Regulations change.
* Security incidents occur.
* Significant vulnerabilities are disclosed.

---

# Continuous Improvement Cycle

```text
Design

↓

Threat Model

↓

Develop

↓

Deploy

↓

Monitor

↓

Incident Review

↓

Update Threat Model

↓

Improve Architecture
```

This feedback loop ensures that the threat model remains relevant as the system evolves.

---

# Chapter 12 – Enterprise Governance

Large organizations benefit from standardized governance around threat modeling.

Typical practices include:

* Mandatory threat modeling for high-risk projects.
* Architecture review boards.
* Security champion programs.
* Centralized threat model repositories.
* Periodic threat model audits.
* Integration with enterprise risk management.

Governance provides consistency while allowing individual teams flexibility in implementation.

---

# Real-World Case Study

## Scenario

An e-commerce company introduces a new "Buy Now, Pay Later" feature.

### During Threat Modeling

The team identifies several new risks:

* Fraudulent account creation.
* Abuse of credit approval APIs.
* Exposure of financial information.
* Replay attacks against payment requests.
* Insider access to credit decisions.

### Mitigations Implemented

* Multi-factor authentication for account changes.
* Rate limiting on credit requests.
* Signed transaction tokens.
* Immutable audit logs.
* Role-based access control for financial data.
* Behavioral fraud detection.

### Outcome

The feature launches with significantly stronger security controls, fewer design defects, and improved confidence from compliance and business stakeholders.

---

# Workshop Exercise

## Scenario

A cloud-native healthcare application stores patient records, schedules appointments, and integrates with external laboratory systems.

### Task 1

Review the Threat Register developed in Part 3.

### Task 2

For each threat:

* Recommend preventive controls.
* Recommend detective controls.
* Recommend corrective controls.

### Task 3

Determine the most appropriate risk treatment strategy:

* Avoid
* Mitigate
* Transfer
* Accept

### Task 4

Estimate residual risk after implementing the proposed controls.

### Task 5

Prepare:

* A technical summary for developers.
* An executive summary for senior management.
* A risk acceptance recommendation for the governance committee.

---

# Best Practices

* Begin threat modeling during architecture design—not after coding starts.
* Keep Data Flow Diagrams current as the system evolves.
* Involve cross-functional teams, including developers, architects, operations, and security specialists.
* Focus first on high-value assets and high-risk trust boundaries.
* Record assumptions, decisions, and accepted risks.
* Integrate threat modeling into sprint planning and architecture reviews.
* Use automation to enforce security controls, but complement it with human review.
* Revisit threat models after major releases, infrastructure changes, or security incidents.

---

# Common Pitfalls

| Pitfall                                             | Consequence                         |
| --------------------------------------------------- | ----------------------------------- |
| Treating threat modeling as a compliance exercise   | Limited security value              |
| Producing threat registers without assigning owners | Mitigations remain incomplete       |
| Ignoring residual risk                              | Stakeholders underestimate exposure |
| Relying solely on automated tools                   | Architectural flaws go undetected   |
| Failing to update the threat model                  | Documentation becomes outdated      |
| Overengineering low-risk features                   | Wasted effort and delayed delivery  |

---

# Security-First Culture

Technology alone cannot create secure systems—people and processes are equally important.

Organizations that consistently deliver secure software share several characteristics:

* Developers understand common attack patterns and secure coding practices.
* Architects routinely evaluate trust boundaries and attack surfaces during design.
* Product Owners include security requirements in backlog prioritization.
* Security champions are embedded within engineering teams.
* Threat modeling is viewed as a collaborative design activity rather than a compliance checklist.
* Lessons learned from incidents and penetration tests are fed back into future threat models.
* Success is measured not only by the number of vulnerabilities found, but by the number of architectural weaknesses prevented.

A mature engineering organization treats **security as a quality attribute**, just like performance, scalability, and reliability. Threat modeling becomes a continuous discipline that guides architectural decisions, supports DevSecOps automation, and helps teams build resilient systems capable of withstanding evolving cyber threats.

---

# Course Deliverables

Upon completing all four parts of this Threat Modeling Masterclass, participants should be able to produce a complete threat modeling package, including:

| Deliverable                     | Description                                                                       |
| ------------------------------- | --------------------------------------------------------------------------------- |
| Scope Statement                 | Defines the system boundaries and objectives                                      |
| Architecture Overview           | High-level description of the application                                         |
| Data Flow Diagram (DFD)         | Visual representation of processes, data stores, data flows, and trust boundaries |
| Asset Inventory                 | Catalog of critical business and technical assets                                 |
| Actor & Threat Agent Inventory  | Internal users, external systems, and potential adversaries                       |
| STRIDE Analysis                 | Systematic threat identification for each DFD component                           |
| Threat Register                 | Documented threats with owners and statuses                                       |
| Risk Assessment                 | Likelihood, impact, and prioritization                                            |
| DREAD/CVSS Scores               | Severity assessments for design risks and vulnerabilities                         |
| Mitigation Plan                 | Recommended preventive, detective, and corrective controls                        |
| Residual Risk Register          | Risks remaining after mitigation and governance decisions                         |
| Executive Risk Summary          | Business-focused communication for leadership                                     |
| Continuous Threat Modeling Plan | Integration into Agile, DevSecOps, and ongoing architecture governance            |

---

# Final Takeaway

Threat modeling is not merely a security exercise—it is an architectural design discipline. By identifying threats before implementation, mapping them to effective controls, and continuously updating models throughout the software lifecycle, organizations can reduce development costs, improve resilience, meet regulatory obligations, and foster a culture where secure design becomes an integral part of delivering high-quality software.
