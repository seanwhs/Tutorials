# Threat Modeling Masterclass

# Part 3 – Identifying and Scoring Threats

## Applying STRIDE, Building a Threat Register, and Prioritizing Risk

> **Module Duration:** 5–6 Hours (Lecture + Guided Workshop + Group Exercise)
>
> **Objective:** Learn how to systematically identify threats using STRIDE, document them in a professional threat register, analyze likelihood and impact, and prioritize remediation using DREAD, CVSS, and risk matrices.

---

# Learning Objectives

By the end of this module, learners will be able to:

* Apply STRIDE to any software architecture.
* Identify threats affecting processes, data flows, data stores, and external entities.
* Distinguish between vulnerabilities, threats, and risks.
* Build a professional Threat Register.
* Evaluate likelihood and business impact.
* Use DREAD scoring to prioritize design-stage risks.
* Understand CVSS scoring for implementation-stage vulnerabilities.
* Produce actionable outputs for developers, architects, and management.

---

# Module Overview

```text
Part 3
│
├── Understanding Threats
├── Threat vs Vulnerability vs Risk
├── STRIDE Deep Dive
│      ├── Spoofing
│      ├── Tampering
│      ├── Repudiation
│      ├── Information Disclosure
│      ├── Denial of Service
│      └── Elevation of Privilege
├── Applying STRIDE to DFDs
├── Building Threat Statements
├── Creating a Threat Register
├── Risk Assessment
├── DREAD Scoring
├── CVSS Overview
├── Risk Matrix
├── Threat Prioritization
├── End-to-End Example
└── Workshop Exercise
```

---

# Chapter 1 – Understanding Threats

Before identifying threats, we must distinguish between several terms that are frequently confused.

---

## What is a Threat?

A **threat** is anything capable of exploiting a weakness and causing harm to an asset.

Examples include:

* Credential theft
* SQL Injection
* Cross-Site Scripting (XSS)
* Insider abuse
* Data theft
* Denial of Service
* Session hijacking

A threat is **the possibility of an attack**.

---

## What is a Vulnerability?

A vulnerability is a weakness that allows a threat to succeed.

Examples:

* Weak passwords
* Missing input validation
* Misconfigured cloud storage
* Unpatched software
* Insecure API authentication
* Default administrator credentials

---

## What is Risk?

Risk is the combination of:

* The likelihood that a threat will exploit a vulnerability
* The impact if that exploitation occurs

A common expression is:

```text
Risk = Likelihood × Impact
```

A vulnerability without an exploitable threat may present little immediate risk, while a modest vulnerability in a highly exposed system can represent significant risk.

---

# Threat vs Vulnerability vs Risk

| Item          | Definition          | Example               |
| ------------- | ------------------- | --------------------- |
| Asset         | Something valuable  | Customer Database     |
| Threat        | Potential attack    | SQL Injection         |
| Vulnerability | Weakness            | Unsanitized SQL query |
| Exploit       | Method used         | Crafted SQL payload   |
| Impact        | Result              | Customer data stolen  |
| Risk          | Likelihood × Impact | High                  |

---

# Example

Customer Database

↓

Threat

SQL Injection

↓

Vulnerability

Dynamic SQL Query

↓

Impact

Database Compromise

↓

Risk

Critical

---

# Chapter 2 – The STRIDE Methodology

Microsoft developed STRIDE to systematically identify common threat categories in software systems.

Instead of brainstorming randomly, architects ask six structured questions for every component in the Data Flow Diagram.

---

# STRIDE Overview

| Letter | Threat                 | Security Property Violated |
| ------ | ---------------------- | -------------------------- |
| S      | Spoofing               | Authentication             |
| T      | Tampering              | Integrity                  |
| R      | Repudiation            | Accountability             |
| I      | Information Disclosure | Confidentiality            |
| D      | Denial of Service      | Availability               |
| E      | Elevation of Privilege | Authorization              |

This structure ensures that important classes of attacks are not overlooked.

---

# Applying STRIDE to DFD Components

Microsoft recommends applying STRIDE differently depending on the DFD element.

| DFD Element     | Applicable Threats                     |
| --------------- | -------------------------------------- |
| External Entity | Spoofing, Repudiation                  |
| Process         | All STRIDE categories                  |
| Data Flow       | Tampering, Information Disclosure, DoS |
| Data Store      | Tampering, Information Disclosure, DoS |

Although these mappings are useful, experienced practitioners often consider all relevant categories where appropriate.

---

# STRIDE Workflow

```text
Data Flow Diagram

↓

Select Component

↓

Apply STRIDE Questions

↓

Identify Threats

↓

Document Threats

↓

Assess Risk

↓

Recommend Controls
```

---

# Chapter 3 – Spoofing

## Definition

Spoofing occurs when an attacker successfully pretends to be another user, device, or service.

Authentication mechanisms are the primary defense.

---

## Common Examples

* Credential theft
* Session hijacking
* Fake JWT tokens
* Stolen API keys
* Fake OAuth tokens
* DNS spoofing
* IP spoofing
* ARP spoofing
* Phishing

---

## Example

A user logs into an application.

The attacker steals the session cookie.

The server believes the attacker is the legitimate customer.

Result:

Unauthorized account access.

---

## Questions to Ask

* Can identities be forged?
* Are passwords sufficiently protected?
* Is MFA available?
* Are tokens signed?
* Are certificates validated?
* Can sessions be hijacked?
* Is mutual authentication required?

---

## Security Controls

* Multi-factor authentication
* Strong password policies
* Secure session management
* Mutual TLS
* Certificate validation
* Hardware security keys
* OAuth/OpenID Connect
* Device authentication

---

# Chapter 4 – Tampering

## Definition

Tampering involves unauthorized modification of data.

Integrity is compromised.

---

## Examples

* Modify HTTP requests
* Alter cookies
* Manipulate JWT payloads
* Modify files
* Change database records
* Change API requests
* Modify configuration files

---

## Real Example

Customer submits:

```text
Amount = $100
```

Attacker intercepts request.

Changes:

```text
Amount = $1
```

Server processes the modified request.

Financial fraud occurs.

---

## Questions

* Can requests be modified?
* Is data digitally signed?
* Are integrity checks performed?
* Is database access restricted?
* Are logs tamper-resistant?

---

## Security Controls

* Digital signatures
* HMAC
* Input validation
* Parameterized queries
* Secure APIs
* Hashing
* Immutable logging
* Database integrity constraints

---

# Chapter 5 – Repudiation

## Definition

Repudiation occurs when users deny performing an action.

Without evidence, accountability is lost.

---

## Examples

* Customer denies making payment.
* Administrator denies deleting data.
* Employee denies changing configuration.
* User denies downloading confidential files.

---

## Questions

* Are activities logged?
* Are timestamps synchronized?
* Are logs protected?
* Are audit trails complete?
* Can logs be modified?

---

## Security Controls

* Audit logs
* Immutable logging
* Digital signatures
* Centralized logging
* Time synchronization (NTP)
* Security Information and Event Management (SIEM)

---

# Chapter 6 – Information Disclosure

## Definition

Sensitive information becomes available to unauthorized users.

---

## Examples

* Database leakage
* Directory listing
* Stack traces
* Source code exposure
* Cloud bucket misconfiguration
* Sensitive API responses
* Passwords stored in plaintext
* Leaked environment variables

---

## Questions

* Is data encrypted?
* Is TLS enforced?
* Are backups encrypted?
* Are secrets stored securely?
* Are error messages sanitized?

---

## Security Controls

* Encryption at rest
* TLS
* Secrets management
* Data masking
* Role-based access control
* Secure error handling
* Data classification

---

# Chapter 7 – Denial of Service

## Definition

An attacker prevents legitimate users from accessing the system.

Availability is compromised.

---

## Examples

* HTTP flooding
* API abuse
* Resource exhaustion
* Infinite loop attacks
* Large file uploads
* Database exhaustion
* Cloud cost exhaustion
* Distributed Denial of Service (DDoS)

---

## Questions

* Can requests be rate-limited?
* Are APIs protected?
* Can queues overflow?
* Is autoscaling configured?
* Are timeouts enforced?

---

## Security Controls

* Rate limiting
* WAF
* CDN
* Load balancing
* Autoscaling
* Circuit breakers
* Queue throttling

---

# Chapter 8 – Elevation of Privilege

## Definition

An attacker gains permissions they were never intended to have.

---

## Examples

* Normal user becomes administrator
* Bypass authorization checks
* Kubernetes privilege escalation
* Local privilege escalation
* IAM misconfiguration
* Broken access control

---

## Questions

* Is authorization enforced?
* Are roles validated?
* Is least privilege implemented?
* Are administrative actions protected?
* Are APIs checking ownership?

---

## Security Controls

* RBAC
* ABAC
* Least privilege
* Segregation of duties
* Policy enforcement
* Secure authorization middleware

---

# Chapter 9 – Applying STRIDE to a Web Application

Consider the following architecture.

```text
Customer
     │
 HTTPS
     │
     ▼
Web Application
     │
     ▼
Authentication Service
     │
     ▼
Customer Database
```

---

## Step 1 – External Entity (Customer)

Potential Threats

| STRIDE      | Example                |
| ----------- | ---------------------- |
| Spoofing    | Fake customer identity |
| Repudiation | Deny purchase          |

---

## Step 2 – Data Flow

Browser → Server

Potential Threats

| STRIDE                 | Example         |
| ---------------------- | --------------- |
| Tampering              | Modify requests |
| Information Disclosure | Packet sniffing |
| DoS                    | HTTP flood      |

---

## Step 3 – Authentication Service

| STRIDE                 | Example                    |
| ---------------------- | -------------------------- |
| Spoofing               | Fake authentication token  |
| Tampering              | Modify login request       |
| Repudiation            | Deny login                 |
| Information Disclosure | Password exposure          |
| DoS                    | Credential stuffing        |
| Elevation              | Admin privilege escalation |

---

## Step 4 – Database

Potential Threats

| STRIDE                 | Example             |
| ---------------------- | ------------------- |
| Tampering              | Modify records      |
| Information Disclosure | Data leakage        |
| DoS                    | Database exhaustion |

---

# Chapter 10 – Writing Threat Statements

A good threat statement clearly describes:

* The asset
* The threat
* The vulnerability
* The impact

### Weak Statement

"SQL Injection exists."

### Better Statement

"An attacker could exploit unsanitized input in the login API to execute arbitrary SQL commands, resulting in unauthorized disclosure and modification of customer account data."

The second statement provides context that helps developers understand both the cause and the consequence.

---

# Threat Statement Template

```text
Threat:
_____________________________________

Affected Asset:
_____________________________________

Threat Agent:
_____________________________________

Attack Scenario:
_____________________________________

Potential Impact:
_____________________________________

Recommended Control:
_____________________________________
```

---

# Chapter 11 – Building a Threat Register

A Threat Register is the primary deliverable from a threat modeling exercise.

It tracks identified threats, their severity, and planned mitigations.

---

## Threat Register Example

| ID    | Component    | Threat               | Impact   | Likelihood | Risk     | Owner       | Status     |
| ----- | ------------ | -------------------- | -------- | ---------- | -------- | ----------- | ---------- |
| T-001 | Login API    | Credential Stuffing  | High     | High       | Critical | Security    | Open       |
| T-002 | Database     | SQL Injection        | Critical | High       | Critical | Development | Open       |
| T-003 | File Upload  | Malware Upload       | High     | Medium     | High     | Platform    | Mitigating |
| T-004 | Admin Portal | Privilege Escalation | Critical | Medium     | High     | IAM Team    | Planned    |

---

# Chapter 12 – Risk Assessment

Risk assessment combines the probability of an event with its business impact.

### Likelihood Factors

* Ease of exploitation
* Exposure
* Existing controls
* Public exploit availability
* Attacker capability

### Impact Factors

* Financial loss
* Operational disruption
* Regulatory penalties
* Reputational damage
* Customer trust
* Safety implications

---

# Risk Matrix

| Impact ↓ / Likelihood → | Low    | Medium | High     |
| ----------------------- | ------ | ------ | -------- |
| Low                     | Low    | Low    | Medium   |
| Medium                  | Low    | Medium | High     |
| High                    | Medium | High   | Critical |

This matrix provides a quick visual method for prioritizing remediation efforts.

---

# Chapter 13 – DREAD Scoring

DREAD is commonly used during design to estimate the relative severity of identified threats.

Each category is scored from **0 to 10**.

| Category        | Meaning                            |
| --------------- | ---------------------------------- |
| Damage          | How severe is the impact?          |
| Reproducibility | Can the attack be repeated easily? |
| Exploitability  | How difficult is the attack?       |
| Affected Users  | How many users are impacted?       |
| Discoverability | How easy is the issue to find?     |

---

## Example: SQL Injection

| Factor          |              Score |
| --------------- | -----------------: |
| Damage          |                 10 |
| Reproducibility |                  9 |
| Exploitability  |                  9 |
| Affected Users  |                 10 |
| Discoverability |                  8 |
| **Average**     | **9.2 (Critical)** |

---

## Example: Reflected XSS

| Factor          |            Score |
| --------------- | ---------------: |
| Damage          |                6 |
| Reproducibility |                7 |
| Exploitability  |                7 |
| Affected Users  |                5 |
| Discoverability |                8 |
| **Average**     | **6.6 (Medium)** |

DREAD is especially useful when comparing multiple design risks before implementation.

---

# Chapter 14 – CVSS Overview

The **Common Vulnerability Scoring System (CVSS)** is the industry standard for assessing the severity of known vulnerabilities.

Unlike DREAD, CVSS is typically applied after a vulnerability has been identified in software.

---

## CVSS Base Metrics

| Metric              | Description                        |
| ------------------- | ---------------------------------- |
| Attack Vector       | Network, adjacent, local, physical |
| Attack Complexity   | Low or high complexity             |
| Privileges Required | None, low, high                    |
| User Interaction    | Required or not required           |
| Scope               | Changed or unchanged               |
| Confidentiality     | Impact on confidentiality          |
| Integrity           | Impact on integrity                |
| Availability        | Impact on availability             |

---

## CVSS Severity Ratings

| Score    | Severity |
| -------- | -------- |
| 0.0      | None     |
| 0.1–3.9  | Low      |
| 4.0–6.9  | Medium   |
| 7.0–8.9  | High     |
| 9.0–10.0 | Critical |

CVSS provides consistency across organizations and is widely used in vulnerability management programs.

---

# Chapter 15 – End-to-End Example

**Scenario:** Online Shopping Application

### Assets

* Customer accounts
* Payment information
* Product catalog
* Order history

### Threat

An attacker attempts SQL Injection against the login API.

### Vulnerability

The application concatenates user input directly into SQL queries.

### STRIDE Category

* Tampering
* Information Disclosure
* Elevation of Privilege

### DREAD Score

9.2 (Critical)

### Risk Matrix

* Likelihood: High
* Impact: High
* Overall Risk: Critical

### Recommended Controls

* Parameterized queries
* ORM usage
* Input validation
* Least-privilege database accounts
* Web Application Firewall
* Continuous security testing

---

# Chapter 16 – Workshop Exercise

## Scenario

You are assessing a cloud-based Human Resources Management System (HRMS).

The system includes:

* Employee Portal
* HR Administration Portal
* Authentication Service
* Payroll Service
* Database
* Object Storage for documents
* Third-party Payroll API

### Task 1

For each component:

* Apply STRIDE.
* Identify at least two potential threats.

### Task 2

Document each threat using the threat statement template.

### Task 3

Create a Threat Register.

### Task 4

Assign:

* Likelihood
* Impact
* DREAD score
* Overall priority

### Task 5

Present the top five risks to the development team with recommended mitigations.

This exercise mirrors the collaborative process used in many enterprise architecture reviews.

---

# Common Mistakes During Threat Identification

* Confusing vulnerabilities with threats.
* Listing generic threats without relating them to specific assets.
* Ignoring business impact.
* Assigning every issue the same priority.
* Failing to identify threat owners.
* Treating the threat register as static documentation rather than a living artifact.

---

## Pro Tip

**Think like the attacker, but prioritize like the business.** A technically sophisticated attack may receive less attention than a simpler attack if the latter targets a business-critical asset or is significantly more likely to occur. Effective threat modeling balances technical analysis with business context.

---

# Deliverables from Part 3

By the end of this phase, you should have:

| Deliverable                         | Purpose                                      |
| ----------------------------------- | -------------------------------------------- |
| STRIDE Analysis                     | Threat identification for each DFD component |
| Threat Statements                   | Clear descriptions of attack scenarios       |
| Threat Register                     | Central record of identified threats         |
| Risk Matrix                         | Visual prioritization of risks               |
| DREAD Scores                        | Relative severity ranking                    |
| CVSS Assessments (where applicable) | Standardized vulnerability severity          |
| Prioritized Remediation List        | Input for engineering and security teams     |

These deliverables provide the bridge between identifying threats and selecting effective security controls.

---

# End of Part 3

In **Part 4 – Mitigation and Strategy**, we will transform identified threats into concrete security requirements. We will map threats to preventive, detective, and corrective controls, explore the concept of **Residual Risk**, develop risk treatment strategies, and integrate threat modeling into Agile and DevSecOps pipelines using automation, CI/CD gates, and continuous architectural reviews.
