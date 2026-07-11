# Appendix D – PASTA (Process for Attack Simulation and Threat Analysis)

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix D**
> **Purpose:** This appendix provides a comprehensive practitioner guide to the **PASTA (Process for Attack Simulation and Threat Analysis)** framework. PASTA is a **risk-centric, attacker-focused threat modeling methodology** that emphasizes business objectives, realistic attack scenarios, and risk-driven security decisions. Unlike STRIDE, which categorizes threats, PASTA models how real attackers could compromise business-critical assets.

> **Best suited for:** Enterprise systems, critical infrastructure, regulated industries, cloud-native platforms, financial services, healthcare, government systems, and high-value applications.

---

# Table of Contents

1. Introduction to PASTA
2. History and Philosophy
3. PASTA vs STRIDE
4. Benefits of PASTA
5. The Seven Stages of PASTA
6. Stage 1 – Define Business Objectives
7. Stage 2 – Define Technical Scope
8. Stage 3 – Application Decomposition
9. Stage 4 – Threat Analysis
10. Stage 5 – Weakness & Vulnerability Analysis
11. Stage 6 – Attack Modeling & Simulation
12. Stage 7 – Risk Analysis & Countermeasures
13. Example: Online Banking Platform
14. Deliverables
15. Strengths and Limitations
16. Integrating PASTA into SDLC & DevSecOps
17. PASTA Quick Reference

---

# 1. Introduction to PASTA

**PASTA** stands for **Process for Attack Simulation and Threat Analysis**.

Unlike framework-centric methods that begin by listing threat categories, PASTA starts with **business objectives** and asks:

* What are we trying to protect?
* Who might attack us?
* Why would they attack?
* How would they attack?
* What is the business impact if they succeed?

The methodology is designed to model **realistic attack paths** rather than simply identifying isolated technical threats.

---

## Core Philosophy

PASTA assumes that effective security decisions require understanding three perspectives:

1. **Business**
2. **Technology**
3. **Attacker**

These perspectives intersect to produce meaningful, risk-based security recommendations.

```text
           Business Goals
                 ▲
                 │
                 │
Technology ◄─────┼─────► Threat Actors
                 │
                 ▼
            Business Risk
```

---

# 2. History and Philosophy

PASTA was developed by **Tony UcedaVélez** and is documented in the book *Risk Centric Threat Modeling*.

The framework was designed to address limitations in purely technical threat modeling approaches by integrating:

* Business risk management
* Enterprise architecture
* Threat intelligence
* Attack simulation
* Security engineering

Today, PASTA is commonly used in:

* Financial institutions
* Healthcare providers
* Critical infrastructure
* Government agencies
* Large cloud platforms
* Enterprise security architecture programs

---

# 3. PASTA vs STRIDE

| Characteristic   | STRIDE                | PASTA                   |
| ---------------- | --------------------- | ----------------------- |
| Primary Goal     | Identify threats      | Analyze business risk   |
| Starting Point   | System architecture   | Business objectives     |
| Focus            | Threat categories     | Attack scenarios        |
| Risk Analysis    | External (DREAD/CVSS) | Built into process      |
| Complexity       | Moderate              | High                    |
| Best For         | Development teams     | Enterprise architecture |
| Typical Duration | Hours                 | Days to weeks           |

### When to Use STRIDE

* Sprint-level reviews
* Application design
* Microservices
* API development
* Agile projects

### When to Use PASTA

* Enterprise platforms
* Mission-critical systems
* Regulatory environments
* Digital transformation initiatives
* Strategic architecture reviews

---

# 4. Benefits of PASTA

PASTA provides several advantages:

* Aligns security with business priorities.
* Focuses on realistic attacker behavior.
* Supports executive decision-making.
* Encourages collaboration across business and technical teams.
* Produces traceable, risk-based security requirements.

### Key Outcomes

* Clear understanding of business-critical assets.
* Prioritized attack scenarios.
* Actionable mitigation plans.
* Executive-ready risk reports.

---

# 5. The Seven Stages of PASTA

PASTA consists of seven sequential stages.

```text
Stage 1
Business Objectives
        │
        ▼
Stage 2
Technical Scope
        │
        ▼
Stage 3
Application Decomposition
        │
        ▼
Stage 4
Threat Analysis
        │
        ▼
Stage 5
Weakness Analysis
        │
        ▼
Stage 6
Attack Simulation
        │
        ▼
Stage 7
Risk Analysis
```

Each stage builds on the previous one, ensuring that technical findings remain connected to business objectives.

---

# 6. Stage 1 – Define Business Objectives

The first stage identifies **why the system exists** and what business value it provides.

### Questions to Ask

* What business problem does the application solve?
* What are the organization's strategic objectives?
* Which processes generate revenue?
* Which services are mission critical?
* What regulatory obligations apply?

### Example

**Online Banking Platform**

Business objectives:

* Enable secure online banking.
* Protect customer trust.
* Comply with financial regulations.
* Support 24/7 service availability.
* Prevent financial fraud.

### Deliverables

* Business objectives document.
* High-level business process map.
* Critical success factors.
* Regulatory requirements list.

---

# 7. Stage 2 – Define Technical Scope

This stage documents the system architecture and defines the boundaries of the assessment.

### Components to Identify

* Users
* Web applications
* Mobile applications
* APIs
* Databases
* Identity providers
* Third-party integrations
* Cloud services
* Networks

### Example Architecture

```text
Customer
    │
    ▼
Web Browser
    │
    ▼
API Gateway
    │
 ┌──┴──────────┐
 ▼             ▼
Account API   Payment API
      │
      ▼
Customer Database
```

### Deliverables

* Architecture diagrams.
* Technology inventory.
* Data Flow Diagrams (DFDs).
* Trust boundaries.
* Asset inventory.

---

# 8. Stage 3 – Application Decomposition

The objective is to understand **how the application works internally**.

### Break the System into Components

* Presentation layer
* Authentication service
* Business logic
* APIs
* Databases
* Message queues
* Cloud storage
* Monitoring systems

### Identify

* Data flows.
* External entities.
* Processes.
* Data stores.
* Trust boundaries.

### Example

| Component            | Purpose              |
| -------------------- | -------------------- |
| Login Service        | Authenticate users   |
| Payment API          | Process transactions |
| Notification Service | Send alerts          |
| Customer Database    | Store account data   |

### Deliverables

* DFDs (Level 0–2)
* Component inventory.
* Trust boundary map.

---

# 9. Stage 4 – Threat Analysis

This stage identifies **who might attack the system and why**.

### Threat Actors

| Threat Actor   | Motivation                     |
| -------------- | ------------------------------ |
| Cybercriminal  | Financial gain                 |
| Insider        | Abuse of access                |
| Nation-state   | Espionage                      |
| Competitor     | Intellectual property theft    |
| Hacktivist     | Political or social objectives |
| Automated Bots | Credential stuffing, scraping  |

### Threat Sources

* External attackers.
* Malicious insiders.
* Third-party vendors.
* Compromised software dependencies.
* Cloud provider misconfigurations.

### Threat Intelligence Inputs

* MITRE ATT&CK
* CAPEC
* OWASP Top 10
* Industry ISACs
* Historical incidents

---

# 10. Stage 5 – Weakness & Vulnerability Analysis

Once threats are known, identify weaknesses that could enable those threats.

### Sources of Weaknesses

* Secure code reviews.
* Architecture reviews.
* Vulnerability scans.
* Penetration tests.
* Configuration reviews.
* Dependency analysis.

### Example Weaknesses

| Weakness                  | Potential Threat      |
| ------------------------- | --------------------- |
| Weak passwords            | Credential compromise |
| Unencrypted storage       | Data disclosure       |
| Missing input validation  | Injection attacks     |
| Excessive IAM permissions | Privilege escalation  |
| Public cloud bucket       | Data exposure         |

### Deliverables

* Vulnerability inventory.
* Weakness register.
* Security gaps.

---

# 11. Stage 6 – Attack Modeling & Simulation

This stage models **how an attacker could realistically compromise the system**.

### Techniques

* Attack trees.
* Attack graphs.
* Kill chain analysis.
* MITRE ATT&CK mapping.
* Red team scenarios.
* Purple team exercises.

### Example Attack Tree

```text
Compromise Customer Accounts
        │
 ┌──────┴────────┐
 ▼               ▼
Steal Credentials  Exploit API
        │               │
        ▼               ▼
Account Takeover   Unauthorized Transfers
```

### Questions

* What attack path is most likely?
* What is the easiest path?
* What causes the greatest business damage?
* Which controls interrupt the attack chain?

### Deliverables

* Attack trees.
* Attack paths.
* Attack simulations.
* Control gap analysis.

---

# 12. Stage 7 – Risk Analysis & Countermeasures

The final stage combines all previous findings to prioritize remediation.

### Evaluate

* Likelihood.
* Business impact.
* Technical impact.
* Regulatory impact.
* Existing controls.
* Residual risk.

### Example Risk Matrix

| Threat              | Likelihood | Impact   | Priority  |
| ------------------- | ---------- | -------- | --------- |
| SQL Injection       | High       | Critical | Immediate |
| Credential Stuffing | High       | High     | Immediate |
| Insider Data Theft  | Medium     | Critical | High      |
| DDoS                | Medium     | High     | High      |
| Configuration Error | Low        | Medium   | Medium    |

### Countermeasure Examples

* Multi-factor authentication.
* Web Application Firewall (WAF).
* Database encryption.
* Least privilege IAM.
* Rate limiting.
* Security monitoring.
* Secure SDLC practices.

### Deliverables

* Risk register.
* Mitigation roadmap.
* Executive summary.
* Residual risk register.

---

# 13. Example – Online Banking Platform

### Business Objective

Provide secure digital banking.

### Technical Scope

* Web application.
* Mobile app.
* REST APIs.
* Payment processing.
* Customer database.

### Threat Actor

Cybercriminal seeking financial gain.

### Weakness

Weak session management.

### Attack Simulation

1. Phishing attack.
2. Credential theft.
3. Session hijacking.
4. Unauthorized fund transfer.

### Risk

* High likelihood.
* Critical impact.

### Countermeasures

* MFA.
* Session timeout.
* Device fingerprinting.
* Transaction signing.
* Fraud detection analytics.

---

# 14. Typical PASTA Deliverables

A completed PASTA assessment typically includes:

* Business objectives.
* Architecture diagrams.
* Data Flow Diagrams.
* Asset inventory.
* Trust boundary map.
* Threat actor profiles.
* Attack trees.
* Threat catalog.
* Weakness register.
* Risk register.
* Mitigation plan.
* Residual risk report.
* Executive presentation.

---

# 15. Strengths and Limitations

## Strengths

* Strong alignment with business objectives.
* Realistic attacker perspective.
* Comprehensive and structured.
* Supports executive communication.
* Integrates threat intelligence.

## Limitations

* Time-intensive.
* Requires experienced facilitators.
* More documentation than lightweight methods.
* May be excessive for small applications.

---

# 16. Integrating PASTA into SDLC & DevSecOps

PASTA is most effective when embedded throughout the software lifecycle.

| SDLC Phase   | PASTA Activity                                  |
| ------------ | ----------------------------------------------- |
| Requirements | Define business objectives.                     |
| Architecture | Scope and decomposition.                        |
| Design       | Threat analysis.                                |
| Development  | Address identified weaknesses.                  |
| Testing      | Validate attack scenarios.                      |
| Deployment   | Verify mitigations.                             |
| Operations   | Monitor residual risk and update threat models. |

### Continuous Improvement

Revisit the PASTA model when:

* New features are introduced.
* Architecture changes significantly.
* New threat intelligence becomes available.
* Major incidents occur.
* Regulatory requirements evolve.

---

# 17. PASTA Quick Reference

## Seven Stages

1. Define Business Objectives.
2. Define Technical Scope.
3. Decompose the Application.
4. Analyze Threats.
5. Analyze Weaknesses.
6. Simulate Attacks.
7. Assess Risk and Select Countermeasures.

---

## Key Questions

* What are we protecting?
* Why is it valuable?
* Who wants to attack it?
* How would they attack?
* Which weaknesses enable the attack?
* What is the business impact?
* What controls reduce the risk?

---

## PASTA Assessment Checklist

* Business objectives documented.
* Architecture reviewed.
* DFD completed.
* Assets identified.
* Threat actors profiled.
* Weaknesses documented.
* Attack paths modeled.
* Risks prioritized.
* Countermeasures selected.
* Residual risks communicated.

---

# Key Takeaways

* **PASTA is a business-driven, attacker-focused methodology** that connects technical architecture to organizational risk.
* By progressing through seven structured stages, it ensures that security recommendations are based on realistic attack scenarios and business priorities rather than isolated technical findings.
* PASTA complements frameworks such as STRIDE by providing a deeper analysis of attack paths, threat actors, and business impact, making it particularly well suited for enterprise and mission-critical environments.
* The most effective PASTA assessments are collaborative, involving business stakeholders, architects, developers, security teams, and operations personnel to produce actionable, risk-informed security decisions.
