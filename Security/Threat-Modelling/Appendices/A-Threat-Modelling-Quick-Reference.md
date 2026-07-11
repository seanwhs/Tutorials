# Appendix A – Threat Modeling Quick Reference Guide

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
>
> **Appendix A**
>
> **Purpose:** This appendix serves as a concise, practical reference guide for threat modeling practitioners. It summarizes the essential concepts, workflows, checklists, and best practices that architects and developers can refer to during design reviews, sprint planning, architecture governance, and security assessments.

---

# Table of Contents

1. What is Threat Modeling?
2. Why Threat Modeling Matters
3. Threat Modeling Lifecycle
4. Threat Modeling Process Overview
5. Security Design Principles
6. Core Terminology
7. Roles and Responsibilities
8. Threat Modeling Frameworks at a Glance
9. Threat Modeling Workflow
10. Data Flow Diagram (DFD) Quick Reference
11. Trust Boundaries
12. Asset Identification
13. Attack Surface Checklist
14. STRIDE Summary
15. Risk Assessment Summary
16. Security Control Categories
17. Common Deliverables
18. Best Practices
19. Common Pitfalls
20. Threat Modeling Checklist
21. Quick Decision Trees
22. Threat Modeling Cheat Sheet

---

# 1. What is Threat Modeling?

Threat modeling is a **structured process** used to identify, evaluate, and address security threats before software is deployed. Rather than reacting to vulnerabilities after release, teams systematically analyze how a system could be attacked during the design phase and select appropriate security controls.

Threat modeling answers four fundamental questions:

1. **What are we building?**
2. **What can go wrong?**
3. **What should we do about it?**
4. **Did we do an adequate job?**

These four questions form the foundation of nearly every threat modeling methodology.

---

# 2. Why Threat Modeling Matters

Threat modeling enables organizations to:

* Identify design weaknesses before implementation.
* Reduce the cost of fixing security issues.
* Improve communication between architects, developers, and security teams.
* Meet regulatory and compliance requirements.
* Prioritize security investments based on business risk.
* Build security into the Software Development Lifecycle (SDLC).

### Benefits

| Benefit              | Business Value               |
| -------------------- | ---------------------------- |
| Early Detection      | Lower remediation costs      |
| Better Architecture  | Reduced technical debt       |
| Improved Compliance  | Easier audits                |
| Stronger Security    | Fewer exploitable weaknesses |
| Better Collaboration | Shared understanding of risk |

---

# 3. Threat Modeling Lifecycle

Threat modeling is not a one-time exercise. It should evolve with the system.

```text
Business Requirements
        │
        ▼
Architecture Design
        │
        ▼
Data Flow Diagram (DFD)
        │
        ▼
Asset Identification
        │
        ▼
Threat Identification
        │
        ▼
Risk Assessment
        │
        ▼
Mitigation Planning
        │
        ▼
Implementation
        │
        ▼
Validation & Testing
        │
        ▼
Continuous Review
```

### Continuous Threat Modeling

Threat models should be reviewed whenever:

* New features are added.
* Architecture changes.
* Cloud services are introduced.
* Third-party dependencies change.
* New regulations apply.
* Significant security incidents occur.

---

# 4. Threat Modeling Process Overview

A repeatable threat modeling process generally consists of the following steps:

| Step | Activity                  | Output                  |
| ---- | ------------------------- | ----------------------- |
| 1    | Define Scope              | Project Charter         |
| 2    | Understand Architecture   | Architecture Diagrams   |
| 3    | Create DFD                | Data Flow Diagram       |
| 4    | Identify Assets           | Asset Inventory         |
| 5    | Identify Trust Boundaries | Trust Boundary Map      |
| 6    | Enumerate Threats         | Threat Register         |
| 7    | Assess Risk               | Risk Matrix             |
| 8    | Recommend Controls        | Security Control Matrix |
| 9    | Document Residual Risk    | Residual Risk Register  |
| 10   | Review                    | Updated Threat Model    |

---

# 5. Security Design Principles

Threat modeling should reinforce secure design principles.

| Principle               | Description                                       |
| ----------------------- | ------------------------------------------------- |
| Least Privilege         | Grant only the minimum permissions required.      |
| Defense in Depth        | Use multiple layers of security controls.         |
| Fail Securely           | Default to a secure state on failure.             |
| Complete Mediation      | Verify authorization for every request.           |
| Separation of Duties    | Distribute sensitive tasks among different roles. |
| Economy of Mechanism    | Keep designs as simple as possible.               |
| Minimize Attack Surface | Reduce exposed services and interfaces.           |
| Zero Trust              | Never assume trust based on network location.     |

---

# 6. Core Terminology

| Term           | Definition                                 |
| -------------- | ------------------------------------------ |
| Asset          | Anything of value that requires protection |
| Threat         | A potential cause of harm                  |
| Vulnerability  | A weakness that can be exploited           |
| Attack Surface | All possible entry points into a system    |
| Trust Boundary | A point where trust assumptions change     |
| Risk           | The combination of likelihood and impact   |
| Mitigation     | A control that reduces risk                |
| Residual Risk  | Risk remaining after controls are applied  |

---

# 7. Roles and Responsibilities

Successful threat modeling requires collaboration.

| Role                    | Responsibilities                                    |
| ----------------------- | --------------------------------------------------- |
| Product Owner           | Defines business objectives and priorities          |
| Enterprise Architect    | Provides architectural context                      |
| Security Architect      | Facilitates threat modeling                         |
| Developers              | Explain implementation details and validate threats |
| DevSecOps Engineer      | Integrates controls into CI/CD                      |
| Infrastructure Engineer | Reviews platform and network architecture           |
| Compliance Officer      | Maps controls to regulatory requirements            |
| Risk Owner              | Accepts or mitigates residual risks                 |

---

# 8. Threat Modeling Frameworks at a Glance

| Framework | Primary Focus                | Best Used For                  |
| --------- | ---------------------------- | ------------------------------ |
| STRIDE    | Threat identification        | Software architecture          |
| DREAD     | Risk scoring                 | Prioritization                 |
| PASTA     | Risk-centric analysis        | Enterprise applications        |
| Trike     | Asset and risk modeling      | Compliance-driven environments |
| VAST      | Scalable enterprise modeling | Large organizations            |
| OCTAVE    | Organizational risk          | Governance and strategy        |

---

# 9. Threat Modeling Workflow

```text
Scope
   │
Architecture
   │
DFD
   │
Assets
   │
Trust Boundaries
   │
Threat Identification
   │
Risk Analysis
   │
Controls
   │
Residual Risk
   │
Review
```

---

# 10. Data Flow Diagram (DFD) Quick Reference

### DFD Elements

| Symbol          | Represents                              |
| --------------- | --------------------------------------- |
| External Entity | User or external system                 |
| Process         | Business logic or application component |
| Data Store      | Database or storage                     |
| Data Flow       | Information moving between components   |
| Trust Boundary  | A change in trust level                 |

### DFD Levels

| Level   | Purpose                          |
| ------- | -------------------------------- |
| Context | Entire system in one view        |
| Level 0 | Major processes                  |
| Level 1 | Decomposition of major processes |
| Level 2 | Detailed subsystem interactions  |

---

# 11. Trust Boundaries

Trust boundaries exist where assumptions about identity, authorization, or control change.

### Common Trust Boundaries

* Internet → DMZ
* Client → API Gateway
* API Gateway → Internal Services
* Microservice → Database
* Cloud → Third-Party SaaS
* CI/CD Pipeline → Production Environment

### Questions to Ask

* Is identity verified?
* Is traffic encrypted?
* Is authorization enforced?
* Is activity logged?
* Is input validated?

---

# 12. Asset Identification

Assets include:

### Information Assets

* Customer records
* Payment information
* Personal data
* Intellectual property

### Technical Assets

* APIs
* Databases
* Authentication systems
* Cloud resources
* Source code

### Business Assets

* Brand reputation
* Revenue streams
* Customer trust
* Regulatory compliance

---

# 13. Attack Surface Checklist

Review the following areas:

### External

* Public websites
* Mobile applications
* APIs
* DNS
* Email gateways

### Internal

* Administrative interfaces
* Databases
* Monitoring platforms
* CI/CD systems
* Internal APIs

### Cloud

* IAM roles
* Object storage
* Serverless functions
* Kubernetes API
* Managed databases

---

# 14. STRIDE Summary

| Category               | Key Question                                      |
| ---------------------- | ------------------------------------------------- |
| Spoofing               | Can someone pretend to be another user or system? |
| Tampering              | Can data or code be modified?                     |
| Repudiation            | Can actions be denied without evidence?           |
| Information Disclosure | Can sensitive data be exposed?                    |
| Denial of Service      | Can availability be disrupted?                    |
| Elevation of Privilege | Can an attacker gain unauthorized permissions?    |

---

# 15. Risk Assessment Summary

A simple qualitative risk matrix:

| Likelihood | Impact | Risk     |
| ---------- | ------ | -------- |
| High       | High   | Critical |
| High       | Medium | High     |
| Medium     | Medium | Medium   |
| Low        | Low    | Low      |

Risk treatment options:

* Mitigate
* Transfer
* Avoid
* Accept

---

# 16. Security Control Categories

| Control Type | Purpose                                         | Examples                                  |
| ------------ | ----------------------------------------------- | ----------------------------------------- |
| Preventive   | Stop attacks                                    | MFA, RBAC, Input validation               |
| Detective    | Identify attacks                                | SIEM, IDS, Audit logging                  |
| Corrective   | Recover from attacks                            | Backups, Incident response                |
| Compensating | Reduce risk when ideal controls are impractical | Network segmentation, Enhanced monitoring |

---

# 17. Common Deliverables

A mature threat modeling exercise typically produces:

* Project Scope
* Architecture Diagrams
* Data Flow Diagrams
* Asset Inventory
* Trust Boundary Map
* Threat Register
* Risk Matrix
* Security Control Matrix
* Residual Risk Register
* Executive Summary
* Architecture Decision Records (ADRs)

---

# 18. Best Practices

* Start threat modeling early in the design phase.
* Involve cross-functional stakeholders.
* Keep diagrams simple and accurate.
* Focus on realistic attack scenarios.
* Document assumptions explicitly.
* Prioritize risks based on business impact.
* Update threat models as systems evolve.
* Store threat models in version control.

---

# 19. Common Pitfalls

| Pitfall                                           | Consequence                   |
| ------------------------------------------------- | ----------------------------- |
| Treating threat modeling as a compliance exercise | Superficial analysis          |
| Overcomplicating diagrams                         | Reduced usability             |
| Ignoring business context                         | Misaligned priorities         |
| Focusing only on technical threats                | Missed business risks         |
| Failing to update models                          | Outdated security assumptions |

---

# 20. Threat Modeling Checklist

Before completing a review, verify that:

* Scope is defined.
* Architecture diagrams are current.
* Data Flow Diagrams are complete.
* Assets are classified.
* Trust boundaries are identified.
* Threats are documented.
* Risks are prioritized.
* Controls are recommended.
* Residual risks are assigned.
* Findings are communicated to stakeholders.

---

# 21. Quick Decision Trees

### When Should Threat Modeling Be Performed?

```text
New System?
     │
     ├── Yes → Perform Threat Model
     │
     └── No
            │
Major Architectural Change?
            │
            ├── Yes → Update Threat Model
            │
            └── No
                    │
New External Dependency?
                    │
                    ├── Yes → Review Threat Model
                    │
                    └── Continue Monitoring
```

### Should a Threat Be Documented?

```text
Could it impact:
- Confidentiality?
- Integrity?
- Availability?
- Compliance?
- Business operations?

If "Yes" to any → Document the threat and assess risk.
```

---

# 22. Threat Modeling Cheat Sheet

## Four Core Questions

1. What are we building?
2. What can go wrong?
3. What are we going to do about it?
4. Did we do a good enough job?

## Five Essential Artifacts

* Architecture Diagram
* Data Flow Diagram
* Asset Inventory
* Threat Register
* Risk Matrix

## Six STRIDE Categories

* Spoofing
* Tampering
* Repudiation
* Information Disclosure
* Denial of Service
* Elevation of Privilege

## Four Risk Treatment Options

* Mitigate
* Transfer
* Avoid
* Accept

## Key Reminder

> **Threat modeling is a continuous engineering practice—not a one-time documentation exercise.** The most valuable threat models are reviewed regularly, maintained alongside system architecture, and used to guide design decisions throughout the software lifecycle.

---

## Appendix A Summary

This quick reference provides a compact but comprehensive overview of the threat modeling process. It is intended to be used as a desk-side guide during design reviews, sprint planning, architecture workshops, and security assessments, helping teams consistently apply secure-by-design principles across projects.
