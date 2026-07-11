# Threat Modeling Course

# Part 1 – Foundations and Methodology

## Building Secure Systems Before Writing Code

> **Module Duration:** 3–4 Hours (Lecture + Workshop)
>
> **Audience:** Software Developers, Software Architects, Cloud Engineers, DevSecOps Engineers, Security Architects, Technical Leads
>
> **Prerequisites:** Basic understanding of software architecture, networking, APIs, and web applications.

---

# Learning Objectives

Upon completing this module, learners will be able to:

* Understand why Threat Modeling is one of the highest-value security activities.
* Explain the difference between reactive and proactive cybersecurity.
* Identify when threat modeling should occur during the Software Development Life Cycle (SDLC).
* Understand the major threat modeling methodologies.
* Create professional Data Flow Diagrams (DFDs).
* Identify trust boundaries and attack surfaces.
* Prepare a system for formal threat analysis.

---

# Module Overview

```
Part 1
│
├── What is Threat Modeling?
├── Why Threat Modeling Matters
├── Security by Design
├── The Cost of Late Security
├── The Threat Modeling Lifecycle
├── Common Frameworks
│      ├── STRIDE
│      ├── PASTA
│      ├── Trike
│      ├── OCTAVE
│      └── Attack Trees
├── Understanding System Architecture
├── Data Flow Diagrams
├── Trust Boundaries
├── Assets
├── Actors
├── Attack Surfaces
├── Practical Example
└── Workshop Exercise
```

---

# Chapter 1 – Why Threat Modeling Exists

Imagine constructing a 50-story office building.

Would you:

* Build first and inspect later?

or

* Review the blueprints before construction begins?

Every engineer would choose the second option.

Software should be no different.

Unfortunately, many organizations still build applications first and think about security after deployment.

This approach creates expensive security problems that are much harder to fix.

Threat Modeling changes this mindset.

Instead of asking:

> "Is the application secure?"

we ask:

> **"How can an attacker compromise this system?"**

before any code is written.

This simple shift changes the entire security strategy.

---

# What Exactly is Threat Modeling?

Threat Modeling is a structured engineering practice used to:

* Understand a system
* Identify valuable assets
* Discover potential attackers
* Predict possible attacks
* Assess risks
* Design security controls

before implementation.

It is essentially:

> **Risk Analysis Applied to Software Architecture**

Unlike penetration testing, which validates implemented systems, threat modeling evaluates **design decisions**.

---

# Threat Modeling is NOT...

Many beginners misunderstand threat modeling.

Threat modeling is **not**:

* Vulnerability scanning
* Penetration testing
* Code review
* Static code analysis
* Dynamic testing
* Compliance auditing

Those activities happen later.

Threat modeling occurs during **design**.

---

# Security Timeline

Traditional Security

```
Requirements

↓

Design

↓

Development

↓

Testing

↓

Deployment

↓

Penetration Test

↓

Security Problems Found
```

Modern Secure Development

```
Requirements

↓

Threat Modeling

↓

Secure Architecture

↓

Development

↓

Testing

↓

Deployment
```

Notice the difference.

Security becomes part of architecture—not an afterthought.

---

# Why Threat Modeling Matters

IBM, Microsoft, Google, Amazon, and many government agencies require threat modeling because it consistently reduces security defects before they become vulnerabilities.

Industry studies have repeatedly shown that the cost of fixing a defect rises dramatically the later it is discovered in the development lifecycle. A design flaw identified during architecture review may take minutes or hours to address, whereas the same flaw discovered after deployment can require emergency patches, downtime, incident response, customer communication, and regulatory reporting.

Threat modeling reduces both technical risk and business cost.

---

# The Economics of Security

Consider the approximate relative cost of fixing the same security issue at different stages:

| Stage          |                   Relative Cost |
| -------------- | ------------------------------: |
| Requirements   |                              1× |
| Architecture   |                              2× |
| Development    |                              5× |
| Testing        |                             15× |
| Production     |                        30×–100× |
| After a Breach | Potentially millions of dollars |

This concept is often referred to as the **Cost of Change Curve**.

---

# Real-World Example

Imagine an online banking application.

During penetration testing, an ethical hacker discovers that transaction requests can be modified before reaching the server.

The root cause?

The application never validated transaction ownership.

The fix requires:

* Redesigning the authorization model
* Modifying backend APIs
* Updating database logic
* Rewriting automated tests
* Retesting every financial workflow
* Delaying the production release

Had the design been threat modeled, the missing authorization check would likely have been identified before implementation.

---

# Reactive vs Proactive Security

## Reactive Security

Reactive security addresses problems after they occur.

Examples include:

* Incident response
* Malware removal
* Breach investigation
* Emergency patching
* Digital forensics

Reactive security is necessary—but expensive.

---

## Proactive Security

Proactive security focuses on preventing problems.

Examples include:

* Secure architecture reviews
* Threat modeling
* Secure coding standards
* Security training
* Design reviews
* DevSecOps automation

Threat modeling is one of the most effective proactive practices because it influences design decisions before they become code.

---

# Security by Design

Threat modeling embodies the principle of **Security by Design**.

Rather than adding security features at the end of a project, security requirements are considered from the very beginning.

Key principles include:

* Least privilege
* Defense in depth
* Secure defaults
* Fail securely
* Complete mediation
* Separation of duties
* Minimize attack surface

Threat modeling helps architects apply these principles systematically.

---

# The Goals of Threat Modeling

A successful threat model should answer questions such as:

* What are we building?
* What assets need protection?
* Who might attack the system?
* What motivates them?
* How could they attack?
* What controls already exist?
* Which additional controls are needed?
* Which risks remain acceptable?

These questions provide the foundation for informed security decisions.

---

# When Should Threat Modeling Be Performed?

Threat modeling is not a one-time activity.

It should be performed whenever significant architectural changes occur.

Recommended checkpoints include:

| Project Phase          | Threat Modeling Activity                                 |
| ---------------------- | -------------------------------------------------------- |
| Requirements           | Identify high-value assets and business objectives       |
| Architecture Design    | Build the initial threat model and DFD                   |
| Sprint Planning        | Review new features for emerging threats                 |
| Before Major Releases  | Validate the threat model against implementation changes |
| Infrastructure Changes | Reassess trust boundaries and deployment risks           |
| Post-Incident          | Update the model with lessons learned                    |

Treat the threat model as a living document that evolves alongside the system.

---

# The Threat Modeling Lifecycle

A typical lifecycle consists of the following stages:

```
1. Define Scope
        │
        ▼
2. Understand Architecture
        │
        ▼
3. Create Data Flow Diagram
        │
        ▼
4. Identify Assets
        │
        ▼
5. Identify Threats
        │
        ▼
6. Assess Risks
        │
        ▼
7. Design Mitigations
        │
        ▼
8. Validate
        │
        ▼
9. Repeat
```

Each iteration improves the security posture of the system.

---

# Understanding Threat Modeling Frameworks

Several structured methodologies exist to guide threat modeling. Each emphasizes different aspects of risk analysis.

The most common frameworks include:

* STRIDE
* PASTA
* Trike
* OCTAVE
* Attack Trees

The choice depends on organizational goals, system complexity, and available resources.

---

# STRIDE Overview

Developed by Microsoft, STRIDE is one of the most widely adopted frameworks for software-centric threat modeling.

The acronym represents six categories of threats:

| Letter | Threat Category        | Primary Security Property |
| ------ | ---------------------- | ------------------------- |
| S      | Spoofing               | Authentication            |
| T      | Tampering              | Integrity                 |
| R      | Repudiation            | Non-repudiation           |
| I      | Information Disclosure | Confidentiality           |
| D      | Denial of Service      | Availability              |
| E      | Elevation of Privilege | Authorization             |

STRIDE maps naturally to Data Flow Diagram elements and is particularly effective for web applications, APIs, cloud services, and enterprise software.

*(In Part 3, we will apply STRIDE systematically to a complete application.)*

---

# PASTA Overview

**Process for Attack Simulation and Threat Analysis (PASTA)** is a seven-stage, risk-centric methodology.

Its stages include:

1. Define business objectives
2. Define technical scope
3. Application decomposition
4. Threat analysis
5. Vulnerability analysis
6. Attack simulation
7. Risk analysis

PASTA is well suited to large organizations that require close alignment between technical threats and business risk.

---

# Trike Overview

Trike focuses on managing acceptable risk.

Unlike STRIDE, which categorizes threats, Trike begins by defining acceptable risk levels for assets and then derives security requirements from those risk tolerances.

It is commonly used in environments with strong governance or compliance requirements.

---

# OCTAVE Overview

The **Operationally Critical Threat, Asset, and Vulnerability Evaluation (OCTAVE)** methodology emphasizes organizational risk rather than individual software components.

It incorporates:

* Business processes
* Operational risk
* Organizational assets
* Security policies
* Compliance considerations

---

# Attack Trees

Attack Trees represent possible attack paths in a hierarchical structure.

Example:

```
Compromise Customer Account
│
├── Steal Password
│
├── Phishing
│
├── Credential Stuffing
│
├── Password Reset Abuse
│
└── Session Hijacking
```

Attack Trees help teams visualize multiple ways an attacker could achieve a specific objective.

---

# Comparing Frameworks

| Framework    | Focus                   | Complexity | Best Used For                          |
| ------------ | ----------------------- | ---------- | -------------------------------------- |
| STRIDE       | Software threats        | Low        | Web applications, APIs, cloud services |
| PASTA        | Business risk           | High       | Enterprise systems                     |
| Trike        | Risk management         | Medium     | Compliance-driven environments         |
| OCTAVE       | Organizational security | High       | Enterprise governance                  |
| Attack Trees | Attack paths            | Medium     | Complex attack analysis                |

---

# Understanding System Architecture

Before identifying threats, architects must understand the system itself.

Ask questions such as:

* What components exist?
* How do they communicate?
* Where is sensitive data stored?
* Which systems are internal?
* Which systems are external?
* Which communications cross trust boundaries?

Without architectural understanding, threat identification becomes guesswork.

---

# Data Flow Diagrams (DFDs)

A **Data Flow Diagram (DFD)** is the foundational artifact for most threat modeling exercises.

A DFD visually represents:

* Processes
* External entities
* Data stores
* Data flows
* Trust boundaries

It answers the question:

> **How does information move through the system?**

Threats emerge wherever data moves, is processed, or is stored.

---

# Core DFD Elements

| Element         | Description                        | Example                     |
| --------------- | ---------------------------------- | --------------------------- |
| External Entity | Actor outside the system           | Customer, Payment Provider  |
| Process         | Software component performing work | Authentication Service      |
| Data Store      | Persistent storage                 | Customer Database           |
| Data Flow       | Information exchanged              | HTTPS Request               |
| Trust Boundary  | Security boundary                  | Internet ↔ Internal Network |

---

# Example: Online Retail Application

```
Customer Browser
       │
    HTTPS
       │
       ▼
 Load Balancer
       │
       ▼
 Web Application
       │
 ┌─────┴────────┐
 │              │
 ▼              ▼
Database    Payment API
```

Even this simple architecture already contains multiple trust boundaries and attack surfaces.

---

# Trust Boundaries

A trust boundary is any point where data crosses from one level of trust to another.

Common examples include:

* Internet → DMZ
* Browser → Web Server
* Web Server → Database
* Cloud → On-Premises Network
* Third-Party API → Internal Services
* Mobile Device → Backend API

Every trust boundary deserves special attention because attackers often exploit these transitions.

---

# Attack Surface

The **attack surface** is the total collection of points through which an attacker could interact with the system.

Examples include:

* Login forms
* REST APIs
* GraphQL endpoints
* File uploads
* Administrative portals
* Mobile APIs
* OAuth callbacks
* Webhooks
* SSH services
* Remote administration interfaces

Reducing the attack surface is a key security objective.

---

# Common Beginner Mistakes

Avoid these pitfalls when creating your first threat model:

* Jumping directly into identifying threats without understanding the architecture.
* Creating DFDs that omit external systems or third-party integrations.
* Ignoring trust boundaries because "everything is inside our network."
* Treating internal users as inherently trustworthy.
* Failing to update the threat model as the application evolves.

---

# Pro Tip

**Don't model the code—model the architecture.**

Threat modeling is most effective when it focuses on how components interact rather than on implementation details. A clean, high-level DFD usually uncovers more meaningful design risks than a detailed class diagram.

---

# Real-World Scenario

A software team integrated a cloud storage service for customer document uploads. Initially, the architecture diagram showed only the web application and its database. During a threat modeling workshop, the team realized that uploaded files were actually passing through a third-party object storage service and a serverless virus-scanning function before becoming available to users.

By updating the DFD to include these components and the associated trust boundaries, the team identified previously overlooked risks such as malicious file uploads, insecure object permissions, unauthorized access to temporary storage, and abuse of pre-signed URLs. Appropriate mitigations—including malware scanning, least-privilege access policies, and short-lived URLs—were incorporated before release.

---

# End of Part 1

In **Part 2 – The Practical Process**, we will move from theory to practice by learning how to decompose a system into manageable components, identify assets, actors, entry points, and trust boundaries, and build a complete threat model for a realistic web application step by step.
