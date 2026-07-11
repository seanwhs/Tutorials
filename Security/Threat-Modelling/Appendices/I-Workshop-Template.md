# Appendix I – Comprehensive Threat Modeling Workshop Templates & Worksheets

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix I**
>
> **Purpose:** This appendix contains a complete collection of **professional templates, worksheets, canvases, checklists, facilitation forms, and documentation examples** used during real-world threat modeling workshops.
>
> These templates are suitable for:
>
> * Architecture Review Boards (ARB)
> * Secure Design Reviews
> * DevSecOps Teams
> * Software Development Teams
> * Cloud Architecture Reviews
> * Zero Trust Assessments
> * Security Design Workshops
> * Compliance Reviews
> * Cybersecurity Tabletop Exercises

---

# Table of Contents

1. Threat Modeling Workshop Agenda
2. Workshop Preparation Checklist
3. Stakeholder Register
4. System Overview Template
5. Asset Inventory Worksheet
6. Data Classification Worksheet
7. External Dependency Register
8. Data Flow Diagram (DFD) Worksheet
9. Trust Boundary Worksheet
10. STRIDE Analysis Worksheet
11. Threat Register
12. DREAD Risk Assessment Worksheet
13. Risk Register
14. Mitigation Plan
15. Security Control Matrix
16. Residual Risk Register
17. Security Requirements Traceability Matrix
18. Threat Modeling Report Template
19. Executive Summary Template
20. Workshop Checklist

---

# 1. Threat Modeling Workshop Agenda

## Duration

Half-Day Workshop (4 Hours)

| Time  | Activity                 |
| ----- | ------------------------ |
| 09:00 | Introductions            |
| 09:15 | Business Overview        |
| 09:45 | Architecture Walkthrough |
| 10:30 | Break                    |
| 10:45 | Data Flow Diagram Review |
| 11:15 | STRIDE Analysis          |
| 12:00 | Risk Assessment          |
| 12:30 | Mitigation Planning      |
| 01:00 | Close                    |

---

## Full-Day Workshop

| Time  | Activity              |
| ----- | --------------------- |
| 09:00 | Introduction          |
| 09:30 | Business Objectives   |
| 10:00 | Architecture Review   |
| 11:00 | DFD Creation          |
| 12:00 | Lunch                 |
| 01:00 | Threat Identification |
| 02:30 | Risk Assessment       |
| 03:15 | Mitigation Planning   |
| 04:15 | Executive Summary     |
| 05:00 | Wrap-up               |

---

# 2. Workshop Preparation Checklist

## Documentation

☐ Architecture Diagram

☐ Network Diagram

☐ DFD

☐ API Specifications

☐ Cloud Architecture

☐ IAM Design

☐ Data Classification

☐ Security Policies

☐ Existing Risk Register

☐ Compliance Requirements

---

## Participants

☐ Product Owner

☐ Business Owner

☐ Solution Architect

☐ Security Architect

☐ Lead Developer

☐ DevOps Engineer

☐ Infrastructure Engineer

☐ Database Administrator

☐ SOC Representative

☐ Compliance Officer

---

# 3. Stakeholder Register

| Role                   | Name | Responsibilities |
| ---------------------- | ---- | ---------------- |
| Business Owner         |      |                  |
| Product Owner          |      |                  |
| Security Architect     |      |                  |
| Solution Architect     |      |                  |
| Lead Developer         |      |                  |
| Cloud Engineer         |      |                  |
| DevOps Engineer        |      |                  |
| Database Administrator |      |                  |
| Risk Manager           |      |                  |
| Compliance Officer     |      |                  |

---

# 4. System Overview Template

## System Name

---

---

## Business Purpose

---

---

## Business Owner

---

---

## Technical Owner

---

---

## Description

---

---

---

---

## Regulatory Requirements

☐ GDPR

☐ PCI DSS

☐ HIPAA

☐ ISO 27001

☐ SOC 2

☐ NIST

☐ Other

---

# 5. Asset Inventory Worksheet

| ID   | Asset | Owner | Classification | Criticality |
| ---- | ----- | ----- | -------------- | ----------- |
| A001 |       |       |                |             |
| A002 |       |       |                |             |
| A003 |       |       |                |             |
| A004 |       |       |                |             |

---

## Asset Categories

* Customer Data
* Financial Data
* Source Code
* APIs
* Servers
* Databases
* Cloud Storage
* Encryption Keys
* Identity Systems
* Business Processes

---

# 6. Data Classification Worksheet

| Data Type       | Classification | Encryption Required | Retention |
| --------------- | -------------- | ------------------- | --------- |
| Customer Data   |                |                     |           |
| Financial Data  |                |                     |           |
| Medical Records |                |                     |           |
| Source Code     |                |                     |           |
| Audit Logs      |                |                     |           |

---

# 7. External Dependency Register

| Dependency        | Owner | Trust Level | Risk |
| ----------------- | ----- | ----------- | ---- |
| Payment Gateway   |       |             |      |
| Identity Provider |       |             |      |
| Cloud Provider    |       |             |      |
| Email Service     |       |             |      |
| CDN               |       |             |      |

---

## Questions

* Is MFA available?
* Is encryption enforced?
* Are SLAs documented?
* Is monitoring implemented?
* Is vendor risk assessed?

---

# 8. Data Flow Diagram Worksheet

## External Entities

---

---

## Processes

---

---

## Data Stores

---

---

## Data Flows

---

---

## Trust Boundaries

---

---

## Notes

---

---

# 9. Trust Boundary Worksheet

| Boundary         | Components | Authentication | Encryption |
| ---------------- | ---------- | -------------- | ---------- |
| Internet → Web   |            |                |            |
| Web → API        |            |                |            |
| API → Database   |            |                |            |
| Internal → Cloud |            |                |            |

---

# 10. STRIDE Analysis Worksheet

| Component              | S | T | R | I | D | E |
| ---------------------- | - | - | - | - | - | - |
| Web Server             |   |   |   |   |   |   |
| API Gateway            |   |   |   |   |   |   |
| Authentication Service |   |   |   |   |   |   |
| Database               |   |   |   |   |   |   |
| Message Queue          |   |   |   |   |   |   |

---

## Threat Description

Threat ID:

---

Threat:

---

Affected Component:

---

STRIDE Category:

---

---

# 11. Threat Register

| ID   | Threat | Component | Likelihood | Impact | Status |
| ---- | ------ | --------- | ---------- | ------ | ------ |
| T001 |        |           |            |        |        |
| T002 |        |           |            |        |        |
| T003 |        |           |            |        |        |

---

## Threat Description Template

Threat ID

---

Description

---

Attack Scenario

---

Potential Impact

---

---

# 12. DREAD Risk Assessment Worksheet

| Category        | Score | Notes |
| --------------- | ----: | ----- |
| Damage          |       |       |
| Reproducibility |       |       |
| Exploitability  |       |       |
| Affected Users  |       |       |
| Discoverability |       |       |

---

Overall Score

---

Priority

---

Owner

---

---

# 13. Risk Register

| Risk ID | Description | Likelihood | Impact | Rating | Owner |
| ------- | ----------- | ---------- | ------ | ------ | ----- |
| R001    |             |            |        |        |       |
| R002    |             |            |        |        |       |
| R003    |             |            |        |        |       |

---

## Risk Treatment

☐ Mitigate

☐ Transfer

☐ Accept

☐ Avoid

---

# 14. Mitigation Plan

| Threat           | Control               | Owner | Due Date | Status |
| ---------------- | --------------------- | ----- | -------- | ------ |
| SQL Injection    | Parameterized Queries |       |          |        |
| XSS              | Output Encoding       |       |          |        |
| Credential Theft | MFA                   |       |          |        |

---

## Validation

☐ Code Review

☐ SAST

☐ DAST

☐ Penetration Test

☐ Security Testing

---

# 15. Security Control Matrix

| Threat           | Preventive | Detective | Corrective |
| ---------------- | ---------- | --------- | ---------- |
| SQL Injection    |            |           |            |
| XSS              |            |           |            |
| Credential Theft |            |           |            |
| DDoS             |            |           |            |

---

## Control Categories

### Preventive

* MFA
* RBAC
* Encryption
* WAF
* Secure Coding

### Detective

* SIEM
* IDS
* EDR
* Audit Logs
* CSPM

### Corrective

* Backup
* Recovery
* IR Plan
* Failover
* Disaster Recovery

---

# 16. Residual Risk Register

| Risk | Remaining Risk | Accepted By | Review Date |
| ---- | -------------- | ----------- | ----------- |
|      |                |             |             |
|      |                |             |             |
|      |                |             |             |

---

## Acceptance Statement

Risk

---

Reason Accepted

---

Compensating Controls

---

Review Date

---

---

# 17. Security Requirements Traceability Matrix

| Requirement    | Threat      | Control | Test Case           |
| -------------- | ----------- | ------- | ------------------- |
| Authentication | Spoofing    | MFA     | Authentication Test |
| Encryption     | Disclosure  | AES-256 | Crypto Review       |
| Logging        | Repudiation | SIEM    | Log Validation      |
| Authorization  | Elevation   | RBAC    | Access Test         |

---

# 18. Threat Modeling Report Template

## Executive Summary

---

---

## Scope

---

---

## Architecture Reviewed

---

---

## Threat Modeling Method

☐ STRIDE

☐ PASTA

☐ Trike

☐ VAST

---

## Assets Reviewed

---

---

## Key Threats

---

---

## Risk Summary

| Critical | High | Medium | Low |
| -------- | ---- | ------ | --- |
|          |      |        |     |

---

## Recommended Controls

---

---

## Residual Risks

---

---

## Next Review Date

---

---

# 19. Executive Summary Template

## Business Objective

---

---

## Assessment Scope

---

---

## Major Risks

1.

2.

3.

---

## Immediate Actions

1.

2.

3.

---

## Strategic Recommendations

* Improve IAM
* Enhance Monitoring
* Secure APIs
* Increase Automation
* Improve Secure SDLC

---

## Executive Dashboard

| Metric                | Value |
| --------------------- | ----- |
| Applications Reviewed |       |
| Assets Identified     |       |
| Threats Identified    |       |
| Critical Risks        |       |
| High Risks            |       |
| Mitigations Planned   |       |
| Residual Risks        |       |

---

# 20. Threat Modeling Workshop Checklist

## Before the Workshop

* ☐ Define workshop scope.
* ☐ Identify stakeholders.
* ☐ Gather architecture documentation.
* ☐ Prepare DFDs.
* ☐ Review regulatory requirements.
* ☐ Prepare collaboration tools (whiteboard, diagramming software).

---

## During the Workshop

* ☐ Confirm business objectives.
* ☐ Validate architecture.
* ☐ Identify assets.
* ☐ Define trust boundaries.
* ☐ Apply threat modeling methodology (e.g., STRIDE).
* ☐ Document threats.
* ☐ Assess risk.
* ☐ Agree on mitigations.
* ☐ Assign owners.
* ☐ Record assumptions and decisions.

---

## After the Workshop

* ☐ Publish the threat model.
* ☐ Update the risk register.
* ☐ Create remediation tickets.
* ☐ Track mitigation progress.
* ☐ Communicate residual risks.
* ☐ Schedule follow-up reviews.
* ☐ Integrate findings into the SDLC and CI/CD pipeline.

---

# Appendix I Summary

This appendix serves as a **practical toolkit** for conducting professional threat modeling workshops. By using standardized templates and worksheets, organizations can ensure consistency, traceability, and repeatability across projects.

These artifacts help teams move from architecture discussions to actionable security outcomes by:

* Capturing system context and business objectives.
* Identifying and classifying critical assets.
* Documenting data flows and trust boundaries.
* Recording threats, risks, mitigations, and residual risks.
* Providing clear traceability from security requirements to implemented controls.
* Producing executive-ready reports that support governance, compliance, and informed risk decisions.

These templates can be adapted for Agile sprint reviews, Architecture Review Boards (ARBs), DevSecOps pipelines, or enterprise security governance processes, making them a reusable foundation for a mature threat modeling program.
