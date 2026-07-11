# Threat Modeling Masterclass

# Comprehensive Presentation Slide Outline

## Enterprise Threat Modeling from Fundamentals to Advanced Practice

> **Course Duration:** 3–5 Days (Instructor-Led) or 25–40 Hours (Self-Paced)
>
> **Estimated Slides:** **280–350 Slides**
>
> **Target Audience:** Developers, Software Architects, Enterprise Architects, Security Architects, DevSecOps Engineers, Security Consultants, Technical Leads

---

# SECTION 1 — Course Introduction (8–10 Slides)

### Slide 1

Course Title

* Threat Modeling Masterclass
* Building Secure Systems by Design
* Instructor Introduction

---

### Slide 2

Course Objectives

* Why threat modeling matters
* Learning outcomes
* Expected deliverables

---

### Slide 3

Who Should Attend

* Developers
* Architects
* DevSecOps
* Security Engineers
* Technical Leads

---

### Slide 4

Course Roadmap

Visual roadmap showing all modules

---

### Slide 5

Prerequisites

* Software Architecture
* Networking
* SDLC
* Basic Security

---

### Slide 6

Workshop Format

* Lectures
* Group discussions
* Labs
* Case studies
* Capstone

---

### Slide 7

Tools Used

* Microsoft Threat Modeling Tool
* OWASP Threat Dragon
* draw.io
* Visio
* Miro
* Lucidchart

---

### Slide 8

Course Deliverables

* Threat Register
* DFD
* Risk Matrix
* Security Controls
* Executive Report

---

# SECTION 2 — Threat Modeling Fundamentals (25 Slides)

---

### Why Threat Modeling?

* What is threat modeling?
* Security by Design
* Shift Left Security
* Secure SDLC

---

### Evolution of Threat Modeling

* Traditional Security
* Modern DevSecOps
* Cloud-native
* AI Era

---

### Benefits

* Reduced vulnerabilities
* Lower remediation costs
* Better compliance
* Improved architecture

---

### Threat Modeling Lifecycle

Diagram

Requirements

↓

Architecture

↓

DFD

↓

Threat Analysis

↓

Risk Assessment

↓

Mitigation

↓

Review

---

### Security Design Principles

* Least Privilege
* Defense in Depth
* Fail Securely
* Zero Trust
* Complete Mediation

---

### Common Misconceptions

* Only for security teams
* Done once
* Only for large systems

---

### Real-world Security Breaches

Case Studies

* Equifax
* SolarWinds
* Capital One
* Uber
* MOVEit

Lessons learned

---

### Interactive Exercise

Identify assets in a banking application

---

# SECTION 3 — Threat Modeling Frameworks (30 Slides)

---

## STRIDE

History

Purpose

Categories

Mnemonic

---

### STRIDE Deep Dive

Separate slides

Spoofing

Tampering

Repudiation

Information Disclosure

Denial of Service

Elevation of Privilege

Each includes

Definition

Examples

Common attacks

Mitigations

---

## DREAD

Purpose

Formula

Scoring

Examples

Limitations

---

## PASTA

Stages

Business Risk

Threat Analysis

Simulation

---

## Trike

Risk-centric approach

---

## OCTAVE

Organizational Risk

---

## VAST

Enterprise Scale

---

## Comparison Matrix

| Framework | Strength | Weakness | Best Use |

---

## Choosing a Framework

Decision Tree

---

# SECTION 4 — Understanding Architecture (20 Slides)

---

### Security Architecture Basics

---

### Architecture Views

* Logical
* Physical
* Deployment
* Cloud

---

### Components

Processes

Services

Users

Databases

Queues

APIs

---

### Trust Boundaries

Examples

Internal

External

Cloud

Hybrid

---

### Security Zones

DMZ

Corporate

Cloud

Internet

Production

Development

---

### Data Classification

Public

Internal

Confidential

Restricted

---

### Exercise

Identify trust boundaries

---

# SECTION 5 — Data Flow Diagrams (35 Slides)

---

### What is a DFD?

---

### Why DFD Matters

---

### DFD Symbols

Process

Data Store

External Entity

Data Flow

Trust Boundary

---

### Levels

Context

Level 0

Level 1

Level 2

Level 3

---

### Example

Online Shopping System

---

### Example

Banking Platform

---

### Example

Healthcare

---

### Example

Cloud-native

---

### Common Mistakes

---

### Hands-on Exercise

Create Level 0

---

### Hands-on Exercise

Create Level 1

---

### Hands-on Exercise

Create Level 2

---

# SECTION 6 — System Decomposition (20 Slides)

---

Purpose

---

Component Identification

---

Service Mapping

---

Microservices

---

Containers

---

Serverless

---

Third-party Services

---

Attack Surface Identification

---

Asset Identification

---

Exercise

---

# SECTION 7 — STRIDE Workshop (45 Slides)

One complete chapter for each STRIDE category.

Each chapter includes

Definition

Examples

Attack Trees

MITRE ATT&CK Mapping

OWASP Mapping

Cloud Examples

Container Examples

Mitigation

Case Study

Exercise

---

Spoofing

7 slides

---

Tampering

7 slides

---

Repudiation

6 slides

---

Information Disclosure

7 slides

---

Denial of Service

8 slides

---

Elevation of Privilege

8 slides

---

STRIDE Summary

---

# SECTION 8 — Risk Assessment (25 Slides)

---

Risk Fundamentals

---

Likelihood

---

Impact

---

Risk Matrix

---

DREAD

Detailed Calculation

---

CVSS

Overview

---

Risk Prioritization

---

Residual Risk

---

Risk Acceptance

---

Workshop

---

# SECTION 9 — Threat Register (18 Slides)

---

Threat Documentation

---

Threat Register Fields

---

Examples

---

Ownership

---

Tracking

---

Reporting

---

Integration with Jira

---

Exercise

---

# SECTION 10 — Security Controls (35 Slides)

---

Defense in Depth

---

Preventive Controls

---

Detective Controls

---

Corrective Controls

---

Identity Controls

---

Authentication

---

Authorization

---

RBAC

---

ABAC

---

PAM

---

Encryption

---

Key Management

---

Logging

---

Monitoring

---

SIEM

---

SOAR

---

Security Testing

---

Exercise

---

# SECTION 11 — Cloud Threat Modeling (35 Slides)

---

Cloud Security

---

Shared Responsibility

---

AWS

---

Azure

---

Google Cloud

---

Identity

---

Networking

---

Storage

---

Serverless

---

Containers

---

Kubernetes

---

Service Mesh

---

Secrets

---

IaC

---

Supply Chain

---

Exercise

---

# SECTION 12 — API Security (20 Slides)

---

REST

---

GraphQL

---

Authentication

---

Authorization

---

Rate Limiting

---

OWASP API Top 10

---

Threat Examples

---

Exercise

---

# SECTION 13 — Kubernetes Threat Modeling (25 Slides)

---

Architecture

---

Pods

---

Nodes

---

Namespaces

---

Secrets

---

RBAC

---

Admission Controllers

---

Network Policies

---

Container Escape

---

Exercise

---

# SECTION 14 — AI Threat Modeling (25 Slides)

---

LLM Architecture

---

Prompt Injection

---

Model Theft

---

Data Poisoning

---

Vector Databases

---

Agents

---

RAG

---

OWASP LLM Top 10

---

Mitigations

---

Workshop

---

# SECTION 15 — Secure SDLC & DevSecOps (20 Slides)

---

Threat Modeling in SDLC

---

Sprint Planning

---

Architecture Review

---

Code Review

---

CI/CD

---

Security Gates

---

Continuous Threat Modeling

---

Automation

---

Exercise

---

# SECTION 16 — Enterprise Governance (20 Slides)

---

Architecture Review Board

---

Security Review Board

---

Risk Committee

---

ADRs

---

Security Policies

---

Compliance

---

Evidence

---

Reporting

---

# SECTION 17 — Professional Templates (25 Slides)

---

Project Charter

---

Questionnaire

---

DFD Templates

---

Threat Register

---

Risk Matrix

---

Security Controls

---

Residual Risk

---

Executive Report

---

Architecture Review Package

---

# SECTION 18 — Enterprise Case Study (40 Slides)

## Complete Banking Platform

---

Business Requirements

---

Architecture

---

DFD

---

Trust Boundaries

---

Assets

---

Threat Analysis

---

STRIDE

---

DREAD

---

Controls

---

Residual Risk

---

Roadmap

---

Executive Presentation

---

Lessons Learned

---

# SECTION 19 — Hands-on Workshop (25 Slides)

Students perform

* Architecture Review
* DFD
* STRIDE
* Threat Register
* Risk Matrix
* Controls
* Executive Report

Instructor review

---

# SECTION 20 — Capstone Project (20 Slides)

Large Enterprise System

Groups produce

* DFD
* STRIDE
* Threat Register
* Controls
* ADR
* Executive Presentation

---

# SECTION 21 — Summary (10 Slides)

Key Takeaways

---

Threat Modeling Checklist

---

Security by Design

---

Continuous Threat Modeling

---

Career Roadmap

---

Further Reading

---

Q&A

---

# APPENDICES (Optional – 40 to 60 Slides)

## Appendix A

OWASP Top 10

---

## Appendix B

OWASP API Top 10

---

## Appendix C

OWASP LLM Top 10

---

## Appendix D

MITRE ATT&CK Overview

---

## Appendix E

NIST Secure Software Development Framework (SSDF)

---

## Appendix F

NIST Cybersecurity Framework (CSF)

---

## Appendix G

ISO/IEC 27001 Controls Mapping

---

## Appendix H

PCI DSS Threat Modeling Requirements

---

## Appendix I

Microsoft Threat Modeling Tool Walkthrough

---

## Appendix J

OWASP Threat Dragon Tutorial

---

## Appendix K

draw.io Tutorial

---

## Appendix L

Threat Modeling Interview Questions

---

## Appendix M

Threat Modeling Checklists

---

## Appendix N

Sample Threat Register (100+ Threats)

---

## Appendix O

Security Architecture Decision Record (ADR) Examples

---

## Appendix P

Glossary of Security Terms

---

# Suggested Slide Distribution

| Section                 | Approx. Slides |
| ----------------------- | -------------: |
| Introduction            |           8–10 |
| Fundamentals            |             25 |
| Frameworks              |             30 |
| Architecture            |             20 |
| Data Flow Diagrams      |             35 |
| System Decomposition    |             20 |
| STRIDE Workshop         |             45 |
| Risk Assessment         |             25 |
| Threat Register         |             18 |
| Security Controls       |             35 |
| Cloud Threat Modeling   |             35 |
| API Security            |             20 |
| Kubernetes              |             25 |
| AI Threat Modeling      |             25 |
| Secure SDLC & DevSecOps |             20 |
| Enterprise Governance   |             20 |
| Professional Templates  |             25 |
| Enterprise Case Study   |             40 |
| Hands-on Workshop       |             25 |
| Capstone                |             20 |
| Summary                 |             10 |
| Appendices              |          40–60 |

## **Total Estimated Slides:** **~580–650**

This structure provides a comprehensive, instructor-ready deck that combines theory, architecture diagrams, real-world case studies, hands-on exercises, governance guidance, and reusable templates suitable for a multi-day professional training program or an enterprise architecture bootcamp.
