# Threat Modeling Masterclass

# Part 10 – Enterprise Capstone

# Complete End-to-End Threat Modeling Engagement

## A Professional Consulting Simulation

> **Duration:** 2–3 Days (16–24 Hours)
>
> **Difficulty:** Expert / Consulting Level
>
> **Audience:** Senior Security Architects, Enterprise Architects, DevSecOps Engineers, Security Consultants, Principal Engineers, Security Managers, CISOs
>
> **Capstone Objective:** Conduct a complete enterprise threat modeling engagement for a modern digital bank. Participants will perform the same activities expected of professional security consultants—from project kickoff through executive presentation—producing a comprehensive set of deliverables suitable for Architecture Review Boards (ARBs), Risk Committees, and executive stakeholders.

---

# Table of Contents

1. Capstone Overview
2. Business Scenario
3. Architecture Overview
4. Engagement Planning
5. Discovery Phase
6. Architecture Review
7. Asset Inventory
8. Trust Boundary Identification
9. DFD Development
10. Attack Surface Analysis
11. STRIDE Analysis
12. DREAD Risk Scoring
13. Threat Register
14. Security Control Selection
15. Residual Risk Assessment
16. Security Roadmap
17. Executive Reporting
18. Architecture Review Board Simulation
19. Final Deliverables
20. Lessons Learned

---

# Chapter 1 – Capstone Overview

## Background

**NovaBank Digital** is launching a cloud-native banking platform that supports:

* Retail banking
* Mobile banking
* Business banking
* Instant payments
* Digital wallets
* Open Banking APIs
* AI-powered fraud detection
* Customer support chatbot
* Investment portfolio management
* Third-party fintech integrations

The organization has engaged your consulting team to conduct a comprehensive threat modeling assessment before production deployment.

---

# Project Goals

Your consulting team must:

* Review the architecture.
* Identify critical assets.
* Model data flows.
* Analyze trust boundaries.
* Identify threats.
* Prioritize risks.
* Recommend security controls.
* Evaluate residual risk.
* Present recommendations to the Architecture Review Board.

---

# Success Criteria

The engagement will be considered successful if:

* All critical components are assessed.
* High-risk threats have documented mitigations.
* Residual risks are identified and assigned.
* Security recommendations are actionable.
* Stakeholders approve the security architecture.

---

# Chapter 2 – Business Context

## Business Drivers

* Launch within six months.
* Meet regulatory requirements.
* Enable secure Open Banking.
* Achieve 99.99% availability.
* Support millions of customers.
* Protect customer trust.

---

## Regulatory Requirements

The system must comply with:

* PCI DSS
* GDPR
* PSD2/Open Banking (where applicable)
* ISO/IEC 27001
* NIST Cybersecurity Framework
* Local financial sector regulations

---

## Business Objectives

| Objective               | Priority |
| ----------------------- | -------- |
| Customer Trust          | Critical |
| Regulatory Compliance   | Critical |
| Continuous Availability | Critical |
| Fraud Prevention        | High     |
| Rapid Feature Delivery  | High     |

---

# Chapter 3 – Architecture Overview

## High-Level Architecture

```text
                 Internet
                     │
          CDN / DDoS Protection
                     │
               Web Application Firewall
                     │
               Global Load Balancer
                     │
                 API Gateway
                     │
      ┌──────────────┼──────────────┐
      │              │              │
 Authentication  Banking API  Mobile API
      │              │              │
      ├──────────────┼──────────────┤
      │              │              │
 Payment Engine  Fraud Engine  Notification
      │              │              │
      ├──────────────┼──────────────┤
      │              │              │
 AI Services     Kafka Cluster   Reporting
      │              │              │
      └──────────────┼──────────────┘
                     │
             PostgreSQL Cluster
                     │
             Object Storage
                     │
            Kubernetes Platform
                     │
             CI/CD Pipeline
```

---

# Technology Stack

| Layer              | Technology           |
| ------------------ | -------------------- |
| Frontend           | React                |
| Mobile             | Flutter              |
| Backend            | Java + Spring Boot   |
| APIs               | REST + GraphQL       |
| Authentication     | OAuth2 + OIDC        |
| Container Platform | Kubernetes           |
| Messaging          | Kafka                |
| Database           | PostgreSQL           |
| Cache              | Redis                |
| Monitoring         | Prometheus + Grafana |
| Logging            | Elastic Stack        |
| SIEM               | Microsoft Sentinel   |

---

# Chapter 4 – Project Kickoff

## Stakeholders

| Role                 | Responsibility              |
| -------------------- | --------------------------- |
| CIO                  | Executive Sponsor           |
| CISO                 | Security Sponsor            |
| Enterprise Architect | Architecture Owner          |
| Product Owner        | Business Requirements       |
| DevOps Lead          | Platform                    |
| Development Lead     | Applications                |
| Security Architect   | Threat Modeling Facilitator |

---

## Kickoff Agenda

1. Introductions
2. Business Objectives
3. Scope Confirmation
4. Architecture Walkthrough
5. Success Criteria
6. Deliverables
7. Timeline
8. Risks
9. Next Steps

---

# Workshop Exercise 1

Prepare a kickoff presentation that:

* Defines engagement objectives.
* Identifies stakeholders.
* Establishes communication channels.
* Documents assumptions.
* Confirms scope.

---

# Chapter 5 – Discovery Phase

## Information Gathering

Collect:

* Architecture diagrams
* Deployment diagrams
* API specifications
* IAM documentation
* Network diagrams
* Data classification
* Compliance requirements
* Existing risk assessments
* Penetration test reports
* Incident history

---

## Interview Questions

### Business

* Which services are mission-critical?
* What are the recovery objectives?
* What is the risk appetite?

### Technical

* How are secrets managed?
* What cloud services are used?
* How are deployments approved?

### Security

* Is Zero Trust implemented?
* How are privileged accounts managed?
* How is logging centralized?

---

# Deliverable

Produce a Discovery Summary highlighting:

* Assumptions
* Constraints
* Open questions
* Initial observations

---

# Chapter 6 – Asset Inventory

## Business Assets

* Customer accounts
* Payment transactions
* Loan records
* Investment portfolios
* Banking reputation
* Brand value

---

## Technical Assets

* Identity provider
* API gateway
* Kubernetes cluster
* PostgreSQL database
* Kafka brokers
* AI fraud models
* Secrets manager
* Container registry
* CI/CD pipeline

---

## Information Assets

* Personally Identifiable Information (PII)
* Financial records
* Authentication tokens
* API keys
* Encryption keys
* Audit logs
* AI training data

---

# Workshop Exercise 2

Classify each asset and identify:

* Owner
* Confidentiality requirement
* Integrity requirement
* Availability requirement
* Regulatory implications

---

# Chapter 7 – Data Flow Diagram Development

Participants will create:

### Level 0 DFD

System context.

### Level 1 DFD

Major services and external entities.

### Level 2 DFD

Detailed decomposition of:

* Payment Engine
* Authentication Service
* Fraud Detection

---

# Review Checklist

* External entities
* Processes
* Data stores
* Trust boundaries
* Data flows
* Security zones

---

# Chapter 8 – Attack Surface Analysis

## External

* Public APIs
* Mobile applications
* Customer portal
* DNS
* Email

---

## Internal

* Kubernetes API
* Admin portal
* Databases
* Message brokers
* Monitoring systems

---

## Third-Party

* Payment processors
* Credit bureaus
* Fintech APIs
* Cloud providers
* Identity federation

---

# Deliverable

Produce an Attack Surface Register documenting:

* Exposure
* Threat vectors
* Existing controls
* Recommended improvements

---

# Chapter 9 – STRIDE Analysis

Participants systematically analyze:

* API Gateway
* Authentication
* Banking APIs
* Payment Engine
* AI Services
* Kafka
* Database
* Kubernetes
* CI/CD
* Cloud Management

For each component:

* Spoofing
* Tampering
* Repudiation
* Information Disclosure
* Denial of Service
* Elevation of Privilege

Document threats in the Threat Register.

---

# Chapter 10 – DREAD Risk Scoring

For every identified threat:

* Damage
* Reproducibility
* Exploitability
* Affected Users
* Discoverability

Calculate average score and assign:

* Critical
* High
* Medium
* Low

---

# Deliverable

A prioritized Threat Register with risk ratings and recommended treatment.

---

# Chapter 11 – Security Control Selection

For each critical threat, identify:

### Preventive Controls

* MFA
* WAF
* RBAC
* Encryption
* Input validation

### Detective Controls

* SIEM
* UEBA
* Runtime monitoring
* Database activity monitoring

### Corrective Controls

* Incident response
* Backup restoration
* Credential rotation
* Disaster recovery

---

# Chapter 12 – Residual Risk Assessment

Reassess risks after proposed controls.

Document:

* Remaining exposure
* Business impact
* Risk owner
* Acceptance decision
* Review schedule

---

# Deliverable

Residual Risk Register approved by business owners.

---

# Chapter 13 – Security Roadmap

## Phase 1 (0–3 Months)

* Harden IAM.
* Enable MFA.
* Deploy WAF.
* Implement centralized logging.

---

## Phase 2 (3–6 Months)

* Introduce service mesh.
* Sign container images.
* Integrate SAST/DAST into CI/CD.
* Improve runtime monitoring.

---

## Phase 3 (6–12 Months)

* Implement Zero Trust.
* Expand SOAR automation.
* Conduct purple-team exercises.
* Mature AI security controls.

---

# Chapter 14 – Executive Reporting

Prepare an Executive Summary including:

* Scope
* Key findings
* Top risks
* Regulatory considerations
* Recommended investments
* Roadmap
* Residual risks

Focus on business impact rather than technical detail.

---

# Chapter 15 – Architecture Review Board (ARB) Simulation

## Participants

* CIO
* CISO
* Enterprise Architect
* Risk Manager
* Development Lead
* Operations Lead
* Security Architect (Presenter)

---

## Presentation Agenda

1. Business Context
2. Architecture Overview
3. Methodology
4. Threat Landscape
5. Top 10 Risks
6. Mitigation Strategy
7. Residual Risks
8. Roadmap
9. Decisions Required
10. Q&A

---

## Sample ARB Questions

* Which threats pose the greatest business risk?
* What assumptions were made?
* How were risks prioritized?
* Which risks are accepted?
* What controls are deferred?
* How will the threat model be maintained?

Participants should prepare concise, evidence-based responses.

---

# Chapter 16 – Final Deliverables

By the end of the engagement, the consulting team should provide:

| Deliverable             | Audience                  |
| ----------------------- | ------------------------- |
| Project Charter         | Sponsor                   |
| Discovery Summary       | Project Team              |
| Architecture Diagrams   | Engineering               |
| Data Flow Diagrams      | Architecture Team         |
| Asset Inventory         | Security Team             |
| Attack Surface Register | Security Team             |
| STRIDE Analysis         | Engineering & Security    |
| DREAD Assessment        | Risk Committee            |
| Threat Register         | Development & Security    |
| Security Control Matrix | Engineering               |
| Residual Risk Register  | Risk Owners               |
| Security Roadmap        | Leadership                |
| ADR Collection          | Architecture Team         |
| Executive Summary       | Executives                |
| ARB Presentation        | Architecture Review Board |

---

# Chapter 17 – Lessons Learned

At project completion, conduct a retrospective.

Discuss:

* What worked well?
* What assumptions changed?
* Which threats were unexpected?
* Were the right stakeholders involved?
* How can future threat modeling sessions be improved?

Document improvements to refine the organization's threat modeling practice.

---

# Capstone Assessment

To successfully complete the masterclass, participants should demonstrate the ability to:

1. Define the scope of an engagement.
2. Build Level 0–2 Data Flow Diagrams.
3. Identify assets, trust boundaries, and attack surfaces.
4. Apply STRIDE consistently across all components.
5. Prioritize threats using DREAD or another agreed risk methodology.
6. Recommend layered preventive, detective, and corrective controls.
7. Evaluate and document residual risk.
8. Produce professional documentation suitable for governance and audit.
9. Present findings clearly to both technical teams and executive stakeholders.
10. Integrate threat modeling into an ongoing secure development lifecycle.

---

# Masterclass Summary

Across the ten parts of this series, you have progressed from foundational concepts to a complete enterprise consulting engagement:

| Part    | Focus                                                |
| ------- | ---------------------------------------------------- |
| Part 1  | Foundations and Threat Modeling Methodologies        |
| Part 2  | Practical Threat Modeling Process                    |
| Part 3  | Threat Identification and Risk Scoring               |
| Part 4  | Mitigation, Residual Risk, and DevSecOps Integration |
| Part 5  | Enterprise Threat Modeling Workshop                  |
| Part 6  | STRIDE in Practice                                   |
| Part 7  | Security Control Design and Architecture             |
| Part 8  | Advanced Threat Modeling for Modern Architectures    |
| Part 9  | Professional Templates and Governance Toolkit        |
| Part 10 | End-to-End Enterprise Capstone Engagement            |

---

# Final Pro Tip

**The most effective threat models are living artifacts—not one-time documents.** Integrate them into architecture reviews, backlog refinement, design discussions, and CI/CD pipelines. Review them whenever the system, dependencies, or business context changes. Organizations that embed threat modeling into everyday engineering practices are better equipped to reduce risk proactively, accelerate secure delivery, and build resilient systems.

---

# Congratulations

You have completed the **Threat Modeling Masterclass**. The methodologies, templates, and practices covered throughout this series provide a practical framework for conducting enterprise-grade threat modeling engagements, supporting secure architecture design, meeting governance and compliance expectations, and enabling a sustainable **security-first engineering culture**.
