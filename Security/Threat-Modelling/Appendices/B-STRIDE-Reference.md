# Appendix B – STRIDE Reference Guide

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
>
> **Appendix B**
>
> **Purpose:** This appendix is a comprehensive practitioner reference for the **STRIDE Threat Modeling Framework**, originally developed by Microsoft. It provides detailed explanations, examples, attack scenarios, architectural considerations, mitigation strategies, and mapping to industry frameworks such as MITRE ATT&CK, OWASP Top 10, OWASP API Security Top 10, and NIST Cybersecurity Framework.

---

# Table of Contents

1. Introduction to STRIDE
2. History and Evolution
3. STRIDE Methodology
4. Applying STRIDE to Data Flow Diagrams
5. STRIDE Decision Matrix
6. STRIDE Mapping to DFD Elements
7. STRIDE Threat Categories Overview
8. Spoofing
9. Tampering
10. Repudiation
11. Information Disclosure
12. Denial of Service
13. Elevation of Privilege
14. STRIDE vs Other Frameworks
15. STRIDE Mapping to MITRE ATT&CK
16. STRIDE Mapping to OWASP
17. STRIDE for Cloud-Native Applications
18. STRIDE for APIs
19. STRIDE for Kubernetes
20. STRIDE for AI/LLM Systems
21. STRIDE Checklist
22. Common Mistakes
23. Best Practices
24. STRIDE Quick Reference

---

# 1. Introduction to STRIDE

**STRIDE** is one of the most widely used threat modeling methodologies. It provides a structured way to identify security threats during the design of software systems by examining how attackers might compromise different aspects of a system.

The acronym represents six categories of threats:

| Letter | Category               | Security Property at Risk |
| ------ | ---------------------- | ------------------------- |
| S      | Spoofing               | Authentication            |
| T      | Tampering              | Integrity                 |
| R      | Repudiation            | Accountability            |
| I      | Information Disclosure | Confidentiality           |
| D      | Denial of Service      | Availability              |
| E      | Elevation of Privilege | Authorization             |

The framework is designed to answer the question:

> **"What could go wrong at each component of the system?"**

---

# 2. History and Evolution

STRIDE was introduced by **Microsoft** as part of its Secure Development Lifecycle (SDL) to improve the security of Windows and enterprise software products.

### Evolution Timeline

| Year        | Milestone                                                                 |
| ----------- | ------------------------------------------------------------------------- |
| Early 2000s | STRIDE introduced by Microsoft                                            |
| Mid-2000s   | Integrated into Microsoft SDL                                             |
| 2010s       | Adopted across enterprise architecture practices                          |
| Present     | Widely used in DevSecOps, cloud-native systems, APIs, and AI applications |

Today, STRIDE is supported by tools such as:

* Microsoft Threat Modeling Tool
* OWASP Threat Dragon
* IriusRisk
* ThreatModeler
* draw.io (manual modeling)

---

# 3. STRIDE Methodology

The STRIDE process typically follows these steps:

1. Define the scope.
2. Create or review the Data Flow Diagram (DFD).
3. Identify assets and trust boundaries.
4. Apply STRIDE to each DFD element.
5. Document threats.
6. Assess risk.
7. Recommend mitigations.
8. Track residual risk.

```text
System Scope
      │
      ▼
Create DFD
      │
      ▼
Identify Components
      │
      ▼
Apply STRIDE
      │
      ▼
Document Threats
      │
      ▼
Assess Risk
      │
      ▼
Mitigation
      │
      ▼
Review
```

---

# 4. Applying STRIDE to Data Flow Diagrams

Each element in a DFD is analyzed for relevant STRIDE threats.

### DFD Elements

| Element         | Description                              |
| --------------- | ---------------------------------------- |
| External Entity | User or external system                  |
| Process         | Business logic or service                |
| Data Flow       | Communication between components         |
| Data Store      | Database or storage                      |
| Trust Boundary  | Transition between different trust zones |

For each element, ask:

* Can identity be spoofed?
* Can data be altered?
* Can actions be denied?
* Can sensitive information be exposed?
* Can availability be disrupted?
* Can privileges be escalated?

---

# 5. STRIDE Decision Matrix

| DFD Element     |  S  |  T  |  R  |  I  |  D  |  E  |
| --------------- | :-: | :-: | :-: | :-: | :-: | :-: |
| External Entity |  ✔  |     |  ✔  |     |     |     |
| Process         |  ✔  |  ✔  |  ✔  |  ✔  |  ✔  |  ✔  |
| Data Flow       |  ✔  |  ✔  |     |  ✔  |  ✔  |     |
| Data Store      |     |  ✔  |  ✔  |  ✔  |  ✔  |     |
| Trust Boundary  |  ✔  |  ✔  |  ✔  |  ✔  |  ✔  |  ✔  |

This matrix helps ensure consistent analysis across system components.

---

# 6. STRIDE Mapping to Security Properties

| STRIDE                 | Primary Security Property |
| ---------------------- | ------------------------- |
| Spoofing               | Authentication            |
| Tampering              | Integrity                 |
| Repudiation            | Accountability            |
| Information Disclosure | Confidentiality           |
| Denial of Service      | Availability              |
| Elevation of Privilege | Authorization             |

---

# 7. STRIDE Threat Categories Overview

| Category               | Typical Goal of Attacker     |
| ---------------------- | ---------------------------- |
| Spoofing               | Pretend to be someone else   |
| Tampering              | Modify data or code          |
| Repudiation            | Deny performing an action    |
| Information Disclosure | Access sensitive information |
| Denial of Service      | Prevent legitimate use       |
| Elevation of Privilege | Gain higher permissions      |

---

# 8. Spoofing

## Definition

Spoofing occurs when an attacker successfully impersonates a legitimate user, system, service, or device.

### Objective

Bypass authentication.

### Common Targets

* User accounts
* Service accounts
* API clients
* Certificates
* Devices
* Cloud identities

---

## Typical Attack Scenarios

* Credential stuffing
* Password spraying
* Session hijacking
* OAuth token theft
* JWT forgery
* API key theft
* DNS spoofing
* ARP spoofing
* Fake microservice identity
* Service account compromise

---

## Example

A stolen OAuth access token is used to access customer banking records.

The attacker never knows the user's password but successfully impersonates them.

---

## Indicators

* Impossible travel
* Multiple failed logins
* Token reuse
* Unexpected device changes
* Duplicate sessions

---

## Mitigations

* Multi-factor authentication
* Mutual TLS
* Hardware-backed credentials
* OAuth best practices
* Short-lived tokens
* Secure session management
* Device identity verification

---

## MITRE ATT&CK Mapping

* Valid Accounts (T1078)
* Steal or Forge Authentication Certificates (T1649)
* Session Hijacking

---

## OWASP Mapping

* Broken Authentication
* Broken Access Control

---

# 9. Tampering

## Definition

Unauthorized modification of data, code, configurations, or communications.

---

## Examples

* SQL Injection
* API payload modification
* Malware insertion
* Configuration changes
* Container image modification
* CI/CD pipeline manipulation
* Supply chain attacks

---

## Example

An attacker intercepts an API request and changes the transfer amount from:

```
$100
```

to

```
$10,000
```

before it reaches the payment service.

---

## Indicators

* File hash changes
* Configuration drift
* Unexpected code deployments
* Database inconsistencies

---

## Mitigations

* Digital signatures
* Checksums
* Input validation
* Parameterized queries
* Immutable infrastructure
* Artifact signing

---

## MITRE ATT&CK

* Data Manipulation
* Modify Authentication Process
* Software Supply Chain Compromise

---

## OWASP

* Injection
* Software Integrity Failures

---

# 10. Repudiation

## Definition

Repudiation occurs when users can deny performing an action because there is insufficient evidence to prove it.

---

## Examples

* Missing audit logs
* Log deletion
* Shared administrator accounts
* Unsigned transactions
* Missing timestamps

---

## Example

A system administrator deletes customer records but later denies responsibility because multiple people share the same privileged account.

---

## Mitigations

* Centralized logging
* Immutable audit trails
* Time synchronization
* Digital signatures
* Individual accounts
* Secure log retention

---

## MITRE ATT&CK

* Clear Windows Event Logs
* Indicator Removal

---

## OWASP

* Security Logging and Monitoring Failures

---

# 11. Information Disclosure

## Definition

Exposure of sensitive information to unauthorized parties.

---

## Examples

* Public cloud storage
* API overexposure
* Debug messages
* Database dumps
* Secrets in source code
* Misconfigured permissions

---

## Example

A cloud storage bucket containing customer passport images is accidentally configured for public access.

---

## Sensitive Data

* PII
* PHI
* Credentials
* Encryption keys
* Financial records
* Intellectual property

---

## Mitigations

* Encryption
* Data classification
* Least privilege
* Data masking
* Secure secrets management
* Access reviews

---

## MITRE ATT&CK

* Data from Information Repositories
* Exfiltration

---

## OWASP

* Cryptographic Failures
* Security Misconfiguration

---

# 12. Denial of Service

## Definition

Preventing legitimate users from accessing systems or services.

---

## Examples

* DDoS attacks
* API flooding
* Resource exhaustion
* Recursive serverless invocations
* Database locking
* Kubernetes resource starvation

---

## Indicators

* High CPU usage
* Memory exhaustion
* Increased latency
* Queue backlogs
* Service crashes

---

## Mitigations

* Rate limiting
* Autoscaling
* Caching
* Load balancing
* Circuit breakers
* Capacity planning

---

## MITRE ATT&CK

* Endpoint Denial of Service
* Network Denial of Service

---

## OWASP

* Unrestricted Resource Consumption
* API Resource Exhaustion

---

# 13. Elevation of Privilege

## Definition

An attacker gains permissions beyond those originally granted.

---

## Examples

* RBAC bypass
* Privileged container escape
* IAM privilege escalation
* Broken object-level authorization
* Kubernetes cluster-admin abuse

---

## Example

A standard employee exploits a vulnerable API endpoint to grant themselves administrator privileges.

---

## Mitigations

* Least privilege
* RBAC/ABAC
* Privileged Access Management (PAM)
* Segregation of duties
* Continuous authorization reviews

---

## MITRE ATT&CK

* Abuse Elevation Control Mechanism
* Exploitation for Privilege Escalation

---

## OWASP

* Broken Access Control

---

# 14. STRIDE vs Other Frameworks

| Framework | Purpose                   |
| --------- | ------------------------- |
| STRIDE    | Identify threats          |
| DREAD     | Prioritize threats        |
| PASTA     | Business risk analysis    |
| Trike     | Risk management           |
| VAST      | Enterprise-scale modeling |

Use STRIDE to identify threats, then combine it with a risk assessment method such as DREAD or CVSS to prioritize remediation.

---

# 15. STRIDE in Modern Architectures

### Cloud

* IAM spoofing
* Public storage
* Serverless abuse

### APIs

* JWT forgery
* Parameter tampering
* Broken authorization

### Kubernetes

* Service account theft
* Pod escape
* RBAC abuse

### AI/LLM

* Prompt injection
* Data leakage
* Tool misuse
* Unauthorized model access

---

# 16. STRIDE Checklist

For every component, ask:

### Spoofing

* Can identities be impersonated?
* Is MFA required?
* Are credentials protected?

### Tampering

* Can requests be modified?
* Are integrity checks used?
* Are updates signed?

### Repudiation

* Are actions logged?
* Are logs protected?
* Can events be traced to an individual identity?

### Information Disclosure

* Is sensitive data encrypted?
* Are secrets managed securely?
* Is access restricted?

### Denial of Service

* Can the component be overwhelmed?
* Are rate limits in place?
* Is there redundancy?

### Elevation of Privilege

* Are permissions minimal?
* Are administrative functions isolated?
* Are authorization checks enforced consistently?

---

# 17. Common Mistakes

* Treating STRIDE as a checklist without understanding the architecture.
* Ignoring trust boundaries.
* Focusing only on external attackers.
* Missing insider threats.
* Documenting threats without assigning owners.
* Failing to revisit the model after architectural changes.

---

# 18. Best Practices

* Apply STRIDE to every DFD element systematically.
* Involve developers, architects, and operations teams in workshops.
* Record assumptions and constraints explicitly.
* Validate identified threats against real attack patterns.
* Map threats to concrete security controls.
* Review threat models regularly as systems evolve.

---

# 19. STRIDE Quick Reference

| Category               | Goal                    | Typical Controls                     |
| ---------------------- | ----------------------- | ------------------------------------ |
| Spoofing               | Protect identity        | MFA, OAuth, mTLS                     |
| Tampering              | Protect integrity       | Digital signatures, Input validation |
| Repudiation            | Ensure accountability   | Audit logging, Immutable logs        |
| Information Disclosure | Protect confidentiality | Encryption, Access control           |
| Denial of Service      | Maintain availability   | Rate limiting, Autoscaling           |
| Elevation of Privilege | Enforce authorization   | RBAC, Least privilege, PAM           |

---

# Key Takeaways

* STRIDE is a structured framework for identifying threats during system design.
* It aligns each threat category with a fundamental security property.
* Effective use of STRIDE depends on a well-defined Data Flow Diagram and a clear understanding of assets and trust boundaries.
* STRIDE is most powerful when combined with risk scoring, mitigation planning, and continuous review as part of a secure development lifecycle.

> **Practitioner Tip:** Treat STRIDE as a thinking framework, not merely a checklist. The quality of your threat model depends on your understanding of the architecture, the business context, and the realistic attack paths that matter most to your organization.
