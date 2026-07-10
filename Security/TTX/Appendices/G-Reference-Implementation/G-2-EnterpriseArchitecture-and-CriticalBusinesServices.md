---

title: Appendix G
section: G.2
subtitle: Enterprise Architecture & Critical Business Services
description: Business capabilities, enterprise architecture, technology landscape, critical systems, trust boundaries, and recovery priorities for Operation Red Horizon.
---

# G.2 Enterprise Architecture & Critical Business Services

> *"Attackers compromise technology. Organizations suffer business consequences. Understanding the relationship between the two is essential to designing meaningful tabletop exercises."*

---

# Purpose of this Section

The previous section introduced ACME Manufacturing Group from a business perspective. This section examines the technology ecosystem that enables those business operations.

Rather than documenting every server, application, or network device, the objective is to identify the systems, services, dependencies, and trust relationships that are most relevant to the exercise. This architectural view provides the technical context required to understand how an attack originating from a trusted third-party vendor can propagate through the enterprise and affect critical business operations.

Throughout Operation Red Horizon, participants will repeatedly refer to these architectural relationships when making decisions about containment, eradication, business continuity, and recovery.

---

# Enterprise Technology Principles

ACME's technology strategy is guided by several architectural principles that influence both day-to-day operations and cybersecurity decision-making.

* Cloud-first for new business applications.
* Zero Trust identity as the foundation for secure access.
* Segmentation between enterprise IT and operational technology (OT).
* Standardized identity lifecycle management.
* Defense in depth across networks, endpoints, applications, and cloud services.
* Secure-by-design for all new digital initiatives.
* Automation wherever operationally appropriate.

Although these principles provide a strong foundation, they do not eliminate risk. Like many mature organizations, ACME must balance security with operational efficiency, legacy technology, and business continuity requirements.

---

# Business Capability Map

The organization delivers value through a collection of interconnected business capabilities.

```text
Corporate Governance
│
├── Finance
├── Human Resources
├── Legal
├── Procurement
│
Manufacturing
│
├── Production Planning
├── Manufacturing Execution
├── Quality Assurance
├── Maintenance
│
Supply Chain
│
├── Vendor Management
├── Warehousing
├── Logistics
├── Distribution
│
Commercial Services
│
├── Sales
├── Customer Portal
├── Technical Support
│
Digital Services
│
├── Identity Services
├── Enterprise Applications
├── Cloud Services
├── Cybersecurity
└── Data & Analytics
```

Every capability depends upon multiple technology services, creating both operational efficiencies and potential pathways for cyber attackers.

---

# Hybrid Enterprise Architecture

ACME operates a hybrid technology environment that combines on-premises infrastructure, public cloud services, Software-as-a-Service (SaaS) platforms, and operational technology.

At a high level, the architecture consists of five major domains:

1. Corporate IT
2. Cloud Services
3. Operational Technology
4. Third-Party Connectivity
5. Security Operations

Each domain has distinct responsibilities, trust relationships, and security controls.

---

# Corporate IT Environment

Corporate IT provides the core digital services used by employees across all regions.

Key components include:

* Enterprise Active Directory
* Microsoft Entra ID
* Microsoft 365
* Corporate email
* Endpoint management
* File services
* ERP platform
* Finance systems
* HR systems
* Corporate intranet
* Collaboration platforms

These services represent the operational backbone of the enterprise and are considered essential for normal business operations.

---

# Cloud Services

Business applications are distributed across multiple cloud environments.

### Software as a Service (SaaS)

* Microsoft 365
* CRM platform
* HR platform
* Procurement platform
* Service management platform

### Infrastructure as a Service (IaaS)

* Customer-facing applications
* API gateways
* Virtual machines
* Secure remote access infrastructure

### Platform as a Service (PaaS)

* Managed databases
* Application hosting
* Integration services
* Monitoring services

Cloud workloads are integrated with enterprise identity services through federated authentication.

---

# Operational Technology (OT)

Manufacturing facilities operate independently but maintain controlled connectivity with enterprise IT.

Each manufacturing plant contains:

* Manufacturing Execution Systems (MES)
* Supervisory Control and Data Acquisition (SCADA)
* Industrial historians
* Engineering workstations
* Programmable Logic Controllers (PLCs)
* Industrial IoT sensors
* Plant maintenance systems

To reduce operational risk, plant environments are separated from corporate IT through industrial demilitarized zones (IDMZs) and tightly controlled firewall policies.

Despite this segmentation, selected business systems require carefully managed communication between IT and OT environments.

---

# Identity Architecture

Identity forms the trust foundation for nearly every business process.

The enterprise identity ecosystem includes:

* Microsoft Active Directory
* Microsoft Entra ID
* Multi-Factor Authentication (MFA)
* Privileged Access Management (PAM)
* Single Sign-On (SSO)
* Conditional Access Policies
* Identity Governance
* Vendor identity federation

Because Operation Red Horizon begins with the compromise of a trusted vendor account, identity assurance becomes a central theme throughout the exercise.

Participants must determine whether unusual activity represents credential theft, session hijacking, insider misuse, or legitimate administrative work.

---

# Network Architecture

The enterprise network follows a layered security model.

```text
Internet
      │
Next-Generation Firewall
      │
DMZ
      │
Remote Access Gateway
      │
Corporate Network
      │
Identity Services
      │
Application Services
      │
Data Services
      │
Industrial DMZ
      │
Manufacturing Networks
```

Network segmentation reduces the likelihood of unrestricted lateral movement but does not eliminate it. Trusted administrative pathways, shared identity systems, and operational dependencies remain attractive targets for attackers.

---

# Security Architecture

Cybersecurity capabilities are deployed across multiple layers of the enterprise.

Preventive Controls:

* Multi-Factor Authentication
* Endpoint Protection
* Email Security
* Web Filtering
* Network Segmentation
* Secure Configuration Baselines

Detective Controls:

* Security Information and Event Management (SIEM)
* Endpoint Detection and Response (EDR)
* Network Detection and Response (NDR)
* Cloud Security Monitoring
* Threat Intelligence
* Identity Analytics

Responsive Controls:

* Incident Response Team
* Security Operations Centre
* Threat Hunting
* Digital Forensics
* Crisis Management
* Business Continuity

These controls provide multiple opportunities to detect and respond to malicious activity, although none can guarantee prevention.

---

# Critical Business Services

The following services are considered mission critical.

| Business Service         | Supporting Systems         | Business Impact if Unavailable         |
| ------------------------ | -------------------------- | -------------------------------------- |
| Manufacturing Operations | MES, SCADA, ERP            | Production stoppage                    |
| Enterprise Identity      | Active Directory, Entra ID | Enterprise-wide authentication failure |
| Customer Portal          | Cloud applications, APIs   | Customer service disruption            |
| Supply Chain             | ERP, Vendor Portal         | Procurement and logistics delays       |
| Corporate Communications | Email, Collaboration       | Crisis coordination impaired           |
| Finance                  | ERP, Banking Integration   | Payment processing delays              |

These services form the primary focus of incident response decision-making throughout the exercise.

---

# Crown Jewels

While every business system has value, several information assets are considered strategically critical.

### Intellectual Property

Engineering designs, manufacturing specifications, and research documentation.

### Manufacturing Systems

Production control environments that directly support factory operations.

### Enterprise Identity

Authentication infrastructure used across cloud and on-premises environments.

### Customer Information

Commercial contracts, pricing information, and customer support records.

### Financial Systems

Corporate financial reporting, treasury operations, and procurement data.

Protection of these assets becomes a recurring decision point during Operation Red Horizon.

---

# Third-Party Ecosystem

ACME relies extensively on trusted external partners.

Major categories include:

* Equipment manufacturers
* Industrial maintenance providers
* Cloud service providers
* Managed security providers
* Logistics partners
* Engineering consultants
* Software vendors

Many of these organizations require remote access to enterprise systems for operational support.

Although strong vendor governance exists, trusted external access inevitably increases organizational attack surface.

The compromise of one such trusted relationship forms the initial attack vector for Operation Red Horizon.

---

# Trust Boundaries

Understanding trust boundaries is critical to understanding cyber risk.

Key boundaries include:

* Internet ↔ Enterprise
* Enterprise ↔ Cloud
* Enterprise ↔ Operational Technology
* Employees ↔ Privileged Administrators
* ACME ↔ Third-Party Vendors
* Production ↔ Development
* Corporate Network ↔ Manufacturing Plants

Every transition across these boundaries involves identity validation, network controls, monitoring, and authorization.

Attackers seek to exploit weaknesses where trust has been established but insufficiently verified.

---

# Recovery Priorities

If significant disruption occurs, recovery follows predefined business priorities.

| Priority | Service                  |
| -------- | ------------------------ |
| 1        | Identity Services        |
| 2        | Manufacturing Operations |
| 3        | Enterprise Network       |
| 4        | ERP Platform             |
| 5        | Supply Chain Systems     |
| 6        | Customer Portal          |
| 7        | Collaboration Services   |

These priorities help guide executive discussions later in the exercise when business continuity and recovery decisions must be made under pressure.

---

# Architectural Strengths

The organization enters the exercise with several mature capabilities.

* Well-defined security governance.
* Hybrid cloud architecture.
* Strong identity controls.
* Segmented operational technology.
* Twenty-four-hour Security Operations Centre.
* Mature incident response procedures.
* Regular vulnerability management.
* Executive support for cybersecurity initiatives.

These strengths increase resilience but do not eliminate the possibility of compromise.

---

# Architectural Challenges

Like many large enterprises, ACME also faces ongoing challenges.

* Legacy manufacturing systems with limited security capabilities.
* Complex third-party connectivity.
* Operational pressure to maintain production availability.
* Hybrid identity dependencies.
* Growing cloud adoption.
* Increasing supply chain complexity.
* Limited maintenance windows for production environments.

These constraints create realistic tensions that participants must navigate throughout the exercise.

---

# Transition to the Next Section

With the organization and enterprise architecture now established, the next section introduces the threat intelligence that drives Operation Red Horizon.

Participants will examine the fictional adversary, understand its objectives and tactics, and explore how current intelligence, business context, and enterprise architecture combine to shape the attack scenario that unfolds during the exercise.
