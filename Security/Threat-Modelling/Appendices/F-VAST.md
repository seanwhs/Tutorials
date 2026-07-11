# Appendix F – VAST (Visual, Agile, and Simple Threat Modeling)

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix F**
> **Purpose:** This appendix provides a comprehensive guide to the **VAST (Visual, Agile, and Simple Threat Modeling)** methodology. VAST is an **enterprise-scale threat modeling framework** designed to support Agile development, DevSecOps, cloud-native architectures, and large organizations with hundreds or thousands of applications. Unlike traditional methodologies that struggle to scale, VAST emphasizes automation, continuous integration, and organizational adoption.

> **Best suited for:** Large enterprises, cloud-native organizations, Agile teams, DevSecOps environments, microservices, SaaS providers, and organizations practicing continuous delivery.

---

# Table of Contents

1. Introduction to VAST
2. History and Philosophy
3. Why VAST Was Developed
4. VAST vs STRIDE vs PASTA vs Trike
5. Core Principles
6. The VAST Architecture
7. Application Threat Models (ATM)
8. Operational Threat Models (OTM)
9. Threat Modeling Lifecycle
10. Integrating VAST with Agile
11. Integrating VAST with DevSecOps
12. Scaling Threat Modeling Across the Enterprise
13. Automation
14. Deliverables
15. Strengths and Limitations
16. Enterprise Case Study
17. VAST Quick Reference

---

# 1. Introduction to VAST

**VAST** stands for:

* **Visual**
* **Agile**
* **Simple**
* **Threat Modeling**

It was created to address a common problem:

> Traditional threat modeling methods work well for a few applications but become difficult to manage across hundreds or thousands of systems.

VAST provides a scalable approach that integrates directly into modern software engineering practices.

---

## Primary Goals

* Scale threat modeling across the enterprise.
* Support Agile and DevSecOps workflows.
* Encourage developer participation.
* Enable continuous threat modeling.
* Reduce manual effort through automation.

---

# 2. History and Philosophy

VAST was developed by **ThreatModeler Software** to overcome challenges organizations faced when attempting to adopt threat modeling at scale.

The methodology is based on three ideas:

1. **Threat modeling should be easy to understand.**
2. **Threat modeling should be integrated into daily development.**
3. **Threat modeling should scale with organizational growth.**

Unlike traditional methods that focus on one application at a time, VAST treats threat modeling as an enterprise capability.

---

# 3. Why VAST Was Developed

Large organizations often face challenges such as:

* Hundreds of development teams.
* Thousands of applications and APIs.
* Frequent software releases.
* Cloud-native architectures.
* Continuous deployment.
* Multiple technology stacks.

Traditional manual workshops cannot keep pace.

VAST addresses these challenges through:

* Standardization.
* Automation.
* Reusable threat libraries.
* Continuous updates.
* Integration with CI/CD.

---

# 4. VAST vs STRIDE vs PASTA vs Trike

| Characteristic | STRIDE            | PASTA               | Trike      | VAST                   |
| -------------- | ----------------- | ------------------- | ---------- | ---------------------- |
| Primary Focus  | Threat categories | Business risk       | Governance | Enterprise scalability |
| Starting Point | Architecture      | Business objectives | Assets     | Development lifecycle  |
| Best For       | Applications      | Enterprise risk     | Compliance | Large organizations    |
| Automation     | Limited           | Limited             | Limited    | Extensive              |
| Agile Support  | Moderate          | Moderate            | Low        | Excellent              |
| DevSecOps      | Moderate          | Moderate            | Low        | Excellent              |

---

# 5. Core Principles

VAST is built on five guiding principles.

### 1. Visual

Use clear, standardized diagrams to improve collaboration and understanding.

### 2. Agile

Embed threat modeling into sprint planning and development workflows.

### 3. Simple

Provide lightweight processes that developers can apply consistently.

### 4. Scalable

Support thousands of applications through standardization and automation.

### 5. Continuous

Treat threat modeling as an ongoing activity rather than a one-time exercise.

---

# 6. The VAST Architecture

VAST separates threat modeling into two complementary perspectives:

1. **Application Threat Models (ATM)**
2. **Operational Threat Models (OTM)**

```text id="vast-architecture"
          Enterprise Threat Modeling
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
Application Threat Model   Operational Threat Model
        │                     │
        ▼                     ▼
Software Design         Infrastructure & Operations
```

This separation allows different stakeholders to focus on areas most relevant to their responsibilities.

---

# 7. Application Threat Models (ATM)

ATM focuses on **how applications are designed and developed**.

### Scope

* Web applications
* Mobile applications
* APIs
* Microservices
* Serverless functions
* Identity services

### Questions

* How does data flow through the application?
* What are the trust boundaries?
* Which components are exposed?
* What threats apply?
* What controls are required?

### Typical Participants

* Developers
* Software architects
* Product owners
* Security engineers

### Deliverables

* Data Flow Diagrams.
* Threat register.
* Secure design recommendations.
* Security requirements.

---

# 8. Operational Threat Models (OTM)

OTM focuses on **how systems are deployed and operated**.

### Scope

* Cloud environments.
* Kubernetes clusters.
* Networks.
* Identity infrastructure.
* Monitoring systems.
* CI/CD pipelines.
* Third-party services.

### Questions

* How is the infrastructure protected?
* Where are administrative boundaries?
* How are secrets managed?
* What operational risks exist?
* How are incidents detected?

### Typical Participants

* Infrastructure engineers.
* Cloud architects.
* DevOps engineers.
* SOC analysts.
* Security operations.

### Deliverables

* Infrastructure diagrams.
* Operational risk assessments.
* Security control recommendations.
* Monitoring requirements.

---

# 9. Threat Modeling Lifecycle

VAST aligns threat modeling with the software lifecycle.

```text id="vast-lifecycle"
Business Requirements
        │
        ▼
Architecture
        │
        ▼
Threat Model
        │
        ▼
Development
        │
        ▼
Testing
        │
        ▼
Deployment
        │
        ▼
Monitoring
        │
        ▼
Continuous Improvement
```

Threat models are updated whenever significant changes occur.

---

# 10. Integrating VAST with Agile

Threat modeling should become a standard Agile activity.

### Sprint Planning

* Review architectural changes.
* Identify new assets.
* Update threat model.

### During Development

* Apply secure coding practices.
* Implement required controls.
* Document assumptions.

### Sprint Review

* Validate mitigations.
* Confirm threat model updates.
* Record residual risks.

### Retrospective

* Discuss security lessons learned.
* Improve threat modeling practices.

---

# 11. Integrating VAST with DevSecOps

VAST encourages automation wherever possible.

### CI/CD Integration

Threat modeling should influence:

* Build pipelines.
* Security testing.
* Infrastructure as Code (IaC).
* Deployment approvals.

### Automated Activities

* Static Application Security Testing (SAST).
* Software Composition Analysis (SCA).
* Secrets scanning.
* Infrastructure scanning.
* Container image scanning.
* Dependency checks.
* Policy-as-Code validation.

### Feedback Loop

```text id="devsecops-loop"
Developer
    │
    ▼
Commit Code
    │
    ▼
CI Pipeline
    │
    ▼
Security Tests
    │
    ▼
Threat Model Updated
    │
    ▼
Deploy
```

---

# 12. Scaling Threat Modeling Across the Enterprise

VAST promotes consistency through reusable standards.

### Standard Components

* Approved architecture patterns.
* Threat libraries.
* Control libraries.
* Risk scoring models.
* Diagram templates.
* Security checklists.

### Governance

Enterprise Architecture teams maintain:

* Standard threat catalogs.
* Approved mitigations.
* Secure design patterns.
* Reusable threat models.

Development teams adapt these artifacts to their projects rather than starting from scratch.

---

# 13. Automation

Automation is a defining feature of VAST.

### Opportunities for Automation

* Generate Data Flow Diagrams from architecture metadata.
* Suggest threats based on known patterns.
* Recommend controls automatically.
* Track remediation status.
* Detect architectural changes.
* Trigger threat model reviews.

### Tool Integration

Examples include:

* Architecture repositories.
* CI/CD platforms.
* Ticketing systems (e.g., Jira).
* Infrastructure as Code repositories.
* Cloud security posture management tools.
* Threat modeling platforms.

Automation reduces manual effort while improving consistency and coverage.

---

# 14. Deliverables

A VAST implementation typically produces:

* Application Threat Models (ATM).
* Operational Threat Models (OTM).
* Standard architecture diagrams.
* Threat libraries.
* Security control libraries.
* Risk registers.
* Remediation tracking dashboards.
* Governance reports.
* Executive metrics.

---

# 15. Strengths and Limitations

## Strengths

* Designed for enterprise scale.
* Excellent fit for Agile and DevSecOps.
* Supports continuous delivery.
* Encourages automation.
* Separates application and operational concerns.
* Improves collaboration across teams.

## Limitations

* Requires organizational maturity.
* Benefits most from supporting tooling.
* Initial setup can be resource-intensive.
* Less suitable for very small projects where lightweight methods may be sufficient.

---

# 16. Enterprise Case Study

## Scenario

A global SaaS provider operates:

* 250 development teams.
* 1,500 microservices.
* Multi-cloud infrastructure.
* Daily production deployments.

### Challenge

Traditional threat modeling workshops cannot keep pace with the rate of change.

### VAST Implementation

* Standard architecture patterns created.
* Threat libraries developed.
* Threat modeling integrated into sprint planning.
* Automated checks added to CI/CD.
* Security dashboards introduced.

### Results

* Faster threat model creation.
* Consistent security controls across teams.
* Reduced review effort.
* Improved visibility of enterprise risk.
* Greater developer engagement.

---

# 17. VAST Quick Reference

## Core Concepts

* Visual diagrams improve collaboration.
* Agile integration keeps threat models current.
* Simplicity encourages adoption.
* Scalability supports enterprise growth.
* Continuous updates maintain relevance.

---

## Two Model Types

| Model | Focus                              |
| ----- | ---------------------------------- |
| ATM   | Application design and development |
| OTM   | Infrastructure and operations      |

---

## Key Questions

* What has changed since the last release?
* Does the change introduce new assets or trust boundaries?
* Are existing controls still effective?
* Can any part of the review be automated?
* Has the threat model been updated to reflect operational reality?

---

## VAST Assessment Checklist

* Architecture documented.
* Application Threat Model completed.
* Operational Threat Model completed.
* Threat library consulted.
* Security controls mapped.
* Automation integrated into CI/CD.
* Risks tracked.
* Residual risks documented.
* Metrics reported to governance teams.

---

# Key Takeaways

* **VAST is an enterprise-scale threat modeling methodology** designed to make threat modeling practical, repeatable, and sustainable across large organizations.
* By separating **Application Threat Models (ATM)** from **Operational Threat Models (OTM)**, VAST enables development, infrastructure, and security teams to collaborate using perspectives tailored to their responsibilities.
* Its emphasis on **automation, reusable patterns, and continuous integration** makes it particularly well suited for Agile, DevSecOps, cloud-native architectures, and organizations managing hundreds or thousands of applications.
* Rather than replacing frameworks like STRIDE or PASTA, VAST provides the operational model that allows those techniques to be applied consistently and efficiently at enterprise scale.
