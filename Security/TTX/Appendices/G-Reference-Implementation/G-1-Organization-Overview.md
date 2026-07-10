```
title: Appendix G
section: G.1
subtitle: Organization Overview — ACME Manufacturing Group
description: >
  Business context, organizational profile, strategic priorities, 
  and enterprise overview for Operation Red Horizon.
```

# G.1 Organization Overview

> *"Cybersecurity incidents are business events first and technical events second. Understanding the organization is therefore the first step in designing a meaningful tabletop exercise."*

---

# Purpose of this Section

Every tabletop exercise should begin with a clear understanding of the organization it is designed to protect.

Threat actors do not attack technology in isolation—they target businesses, disrupt operations, steal intellectual property, extort executives, and exploit weaknesses in governance and supply chains. Consequently, an effective exercise must reflect the realities of the organization being simulated.

This section introduces **ACME Manufacturing Group**, the fictional enterprise used throughout Operation Red Horizon. Although fictional, ACME has been designed to resemble a modern multinational manufacturing company with globally distributed operations, hybrid cloud infrastructure, operational technology (OT), complex supply chains, and significant cybersecurity obligations.

The details presented here provide the business context for every subsequent planning document, scenario event, and executive decision.

---

# Company Profile

| Attribute            | Details                                                           |
| -------------------- | ----------------------------------------------------------------- |
| Company Name         | ACME Manufacturing Group                                          |
| Industry             | Advanced Industrial Manufacturing                                 |
| Headquarters         | Singapore                                                         |
| Regional Operations  | Asia-Pacific, Europe, North America                               |
| Employees            | ~9,500                                                            |
| Annual Revenue       | US$4.2 Billion                                                    |
| Manufacturing Sites  | 5                                                                 |
| Distribution Centres | 2                                                                 |
| Regional Offices     | 3                                                                 |
| Customers            | Global industrial, automotive, healthcare, and technology sectors |
| Suppliers            | Over 700 strategic suppliers across 20 countries                  |

---

# Business Overview

ACME Manufacturing Group designs, manufactures, and distributes high-precision industrial components used in critical infrastructure, automotive systems, medical devices, and advanced electronics.

The company's competitive advantage is built on three pillars:

* Highly automated manufacturing facilities.
* Integrated global supply chain operations.
* Proprietary engineering and product designs.

Its customers depend on predictable production schedules and just-in-time deliveries. Even relatively short operational disruptions can cascade across customer supply chains, resulting in contractual penalties, production delays, and reputational damage.

Cybersecurity therefore supports not only information protection but also operational continuity and commercial resilience.

---

# Strategic Business Objectives

The Board has identified six strategic priorities for the next five years:

### Operational Excellence

Maintain uninterrupted manufacturing operations while improving production efficiency through automation and predictive analytics.

---

### Digital Transformation

Expand the use of cloud-native services, industrial IoT, AI-assisted quality control, and data-driven decision-making across manufacturing plants.

---

### Supply Chain Resilience

Reduce dependency on individual suppliers, improve vendor risk management, and strengthen visibility across global logistics operations.

---

### Customer Trust

Maintain high availability of customer-facing services while protecting confidential customer information and intellectual property.

---

### Regulatory Compliance

Comply with international privacy, cybersecurity, export control, and industry-specific regulatory requirements across multiple jurisdictions.

---

### Sustainable Growth

Support business expansion through secure digital platforms that enable acquisitions, partnerships, and global collaboration.

---

# Business Operating Model

The organization operates through six major business functions.

## Manufacturing Operations

Responsible for production planning, factory operations, equipment maintenance, and manufacturing execution systems.

Availability Requirement:

**Very High**

Maximum Tolerable Outage:

**4 Hours**

---

## Supply Chain & Logistics

Coordinates procurement, warehouse operations, transportation, customs documentation, and supplier collaboration.

Availability Requirement:

**High**

Maximum Tolerable Outage:

**8 Hours**

---

## Research & Development

Develops proprietary product designs, manufacturing processes, and engineering specifications.

Availability Requirement:

**Medium**

Confidentiality Requirement:

**Very High**

---

## Sales & Customer Services

Manages customer orders, CRM platforms, product support, and online customer portals.

Availability Requirement:

**High**

---

## Corporate Services

Includes Finance, Human Resources, Procurement, Legal, and Corporate Communications.

Availability Requirement:

**Medium**

---

## Information Technology & Cybersecurity

Provides enterprise infrastructure, identity management, cloud services, cybersecurity operations, and technology governance.

Availability Requirement:

**Critical**

---

# Organizational Structure

The organization follows a matrix operating model combining global functional leadership with regional operational responsibility.

```text
Board of Directors
        │
Chief Executive Officer
        │
├── Chief Operating Officer
├── Chief Financial Officer
├── Chief Information Officer
├── Chief Information Security Officer
├── Chief Legal Officer
├── Chief Human Resources Officer
├── Chief Supply Chain Officer
└── Regional Managing Directors
```

Each executive retains responsibility for crisis management decisions within their area while participating in the Enterprise Crisis Management Team during significant incidents.

---

# Enterprise Risk Profile

Annual enterprise risk assessments consistently identify cybersecurity among the organization's highest strategic risks.

The Board Risk Committee monitors several key threat categories:

* Ransomware.
* Third-party compromise.
* Intellectual property theft.
* Business email compromise.
* Insider threats.
* Cloud service disruption.
* Industrial control system attacks.
* Supply chain attacks.

These risks form the basis for the organization's annual cybersecurity exercise program.

---

# Digital Transformation Journey

Over the past five years, ACME has invested heavily in modernizing its technology landscape.

Key initiatives include:

* Migration of enterprise applications to cloud platforms.
* Adoption of Microsoft 365 for collaboration.
* Expansion of industrial IoT across manufacturing plants.
* Implementation of Zero Trust identity principles.
* Deployment of a Security Operations Centre operating 24×7.
* Increased use of SaaS platforms for finance, HR, procurement, and customer relationship management.

While these initiatives improve agility and operational efficiency, they also increase dependence on identity services, cloud infrastructure, third-party vendors, and interconnected business processes.

---

# Cybersecurity Program

The cybersecurity program is led by the Chief Information Security Officer (CISO) and operates under the oversight of the Board Risk Committee.

Core capabilities include:

* Security Operations Centre (SOC).
* Incident Response Team (IRT).
* Vulnerability Management.
* Identity & Access Management.
* Threat Intelligence.
* Governance, Risk & Compliance.
* Security Architecture.
* Cloud Security.
* Third-Party Risk Management.

The organization performs annual penetration testing, quarterly phishing simulations, and regular vulnerability assessments.

Formal tabletop exercises are conducted twice each year, with larger enterprise-wide simulations every eighteen months.

Operation Red Horizon represents the organization's most comprehensive cross-functional exercise to date.

---

# Critical Success Factors

The exercise is designed around the organization's ability to protect five critical outcomes:

| Business Objective               | Why It Matters                                                       |
| -------------------------------- | -------------------------------------------------------------------- |
| Protect manufacturing operations | Prevent production disruption and contractual penalties.             |
| Preserve customer confidence     | Maintain trust and long-term commercial relationships.               |
| Protect intellectual property    | Safeguard competitive advantage and innovation.                      |
| Meet regulatory obligations      | Avoid legal, financial, and reputational consequences.               |
| Recover safely and efficiently   | Restore services while preventing reinfection or further compromise. |

These objectives influence every major decision made during the exercise.

---

# Assumptions for the Exercise

To maintain focus, the following assumptions apply:

* The organization has an approved Incident Response Plan.
* Business Continuity and Disaster Recovery plans exist.
* Crisis Management procedures have been documented.
* Participants are acting within their normal organizational roles.
* Technical systems described in the scenario are representative of a modern enterprise environment.
* All events occurring during the exercise are fictional unless the facilitator explicitly pauses the exercise.

These assumptions allow discussion to focus on decision-making rather than debating organizational fundamentals.

---

# Why ACME?

The fictional organization has been intentionally designed to reflect characteristics common to many medium-to-large enterprises:

* A hybrid cloud environment.
* Globally distributed operations.
* Complex supply chains.
* Heavy reliance on third-party vendors.
* Operational technology integrated with enterprise IT.
* Mature—but imperfect—cybersecurity capabilities.

Although the details are fictional, the challenges, decisions, and trade-offs presented throughout Operation Red Horizon closely resemble those encountered by real organizations responding to significant cyber incidents.

This balance of realism and abstraction allows the exercise to be adapted to a wide variety of industries without being tied to a specific organization.

---

# Transition to the Next Section

With the business context established, the next section examines the technology landscape that supports ACME Manufacturing Group.

Understanding the enterprise architecture, critical systems, identity infrastructure, cloud services, operational technology, and external dependencies provides the technical foundation for the attack scenario that unfolds throughout Operation Red Horizon.
