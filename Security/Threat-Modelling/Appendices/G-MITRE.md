# Appendix G – MITRE ATT&CK Framework Reference Guide

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix G**
> **Purpose:** This appendix provides a comprehensive practitioner reference for the **MITRE ATT&CK® Framework**, the industry-standard knowledge base of adversary tactics, techniques, and procedures (TTPs). It explains how ATT&CK complements threat modeling methodologies such as STRIDE, PASTA, Trike, and VAST by helping teams model **real attacker behavior** and validate security controls against known attack techniques.

> **Best suited for:** Security architects, SOC analysts, threat hunters, red teams, blue teams, DevSecOps engineers, incident responders, and enterprise security teams.

> **Important Note:** MITRE ATT&CK is **not a threat modeling framework**. Instead, it is a **threat intelligence framework** that catalogs how real-world adversaries operate. During threat modeling, ATT&CK helps validate attack scenarios, identify detection opportunities, and prioritize security controls.

---

# Table of Contents

1. Introduction to MITRE ATT&CK
2. History and Evolution
3. ATT&CK vs Threat Modeling Frameworks
4. ATT&CK Structure
5. ATT&CK Matrices
6. Tactics
7. Techniques
8. Sub-Techniques
9. Procedures (TTPs)
10. ATT&CK Lifecycle
11. Enterprise ATT&CK Tactics
12. Mapping STRIDE to ATT&CK
13. Mapping ATT&CK to the Cyber Kill Chain
14. ATT&CK in Threat Modeling
15. ATT&CK in Detection Engineering
16. ATT&CK in Purple Teaming
17. Enterprise Example
18. Best Practices
19. Quick Reference

---

# 1. Introduction to MITRE ATT&CK

The **MITRE ATT&CK Framework** is a globally recognized knowledge base of:

* Adversary tactics
* Attack techniques
* Sub-techniques
* Real-world procedures

It is based on observations from actual cyber incidents rather than theoretical attack models.

ATT&CK helps answer questions such as:

* How do attackers gain initial access?
* How do they maintain persistence?
* How do they move laterally?
* How do they steal data?
* Which security controls detect these activities?

---

## What Does ATT&CK Stand For?

**ATT&CK**

**A**dversarial

**T**actics

**T**echniques

**&**

**C**ommon

**K**nowledge

---

# 2. History and Evolution

MITRE developed ATT&CK in 2013 to document adversary behavior observed in real-world environments.

### Milestones

| Year    | Milestone                                                        |
| ------- | ---------------------------------------------------------------- |
| 2013    | ATT&CK project initiated                                         |
| 2015    | Public release                                                   |
| 2018    | Enterprise ATT&CK expansion                                      |
| 2019    | Cloud matrices introduced                                        |
| 2020    | Mobile ATT&CK integrated                                         |
| Present | Widely adopted by governments, enterprises, and security vendors |

Today, ATT&CK is used worldwide for:

* Threat modeling
* Threat hunting
* Detection engineering
* Security assessments
* Purple team exercises
* Security control validation

---

# 3. ATT&CK vs Threat Modeling Frameworks

| Framework    | Purpose                                    |
| ------------ | ------------------------------------------ |
| STRIDE       | Identify threat categories                 |
| PASTA        | Analyze business risk and attack scenarios |
| Trike        | Define acceptable risk                     |
| VAST         | Scale threat modeling                      |
| MITRE ATT&CK | Document attacker techniques               |

A practical workflow is:

```text id="attack-workflow"
Architecture
      │
      ▼
Threat Model
      │
      ▼
Identify Threats
      │
      ▼
Map to ATT&CK Techniques
      │
      ▼
Select Security Controls
      │
      ▼
Define Detection Rules
```

---

# 4. ATT&CK Structure

ATT&CK is organized into several layers.

```text id="attack-structure"
Tactic
   │
Technique
   │
Sub-Technique
   │
Procedure
```

### Definitions

| Component     | Description                                                |
| ------------- | ---------------------------------------------------------- |
| Tactic        | The attacker's objective                                   |
| Technique     | How the attacker achieves the objective                    |
| Sub-Technique | A more specific implementation of a technique              |
| Procedure     | A real-world example of a threat actor using the technique |

---

# 5. ATT&CK Matrices

MITRE maintains several matrices.

### Enterprise

Windows

Linux

macOS

Cloud

Containers

Network

### Mobile

Android

iOS

### ICS

Industrial Control Systems

---

# 6. ATT&CK Tactics

A **tactic** represents the attacker's immediate goal.

The Enterprise ATT&CK matrix currently includes the following major tactics:

| Tactic               | Objective                                |
| -------------------- | ---------------------------------------- |
| Reconnaissance       | Gather information about the target      |
| Resource Development | Prepare resources for the attack         |
| Initial Access       | Enter the environment                    |
| Execution            | Run malicious code                       |
| Persistence          | Maintain long-term access                |
| Privilege Escalation | Gain higher permissions                  |
| Defense Evasion      | Avoid detection                          |
| Credential Access    | Obtain credentials                       |
| Discovery            | Learn about the environment              |
| Lateral Movement     | Move to other systems                    |
| Collection           | Gather valuable data                     |
| Command and Control  | Communicate with attacker infrastructure |
| Exfiltration         | Steal data                               |
| Impact               | Disrupt or destroy systems               |

---

# 7. Techniques

A **technique** describes *how* an attacker accomplishes a tactic.

### Examples

| Tactic               | Technique                             |
| -------------------- | ------------------------------------- |
| Initial Access       | Phishing                              |
| Credential Access    | Credential Dumping                    |
| Privilege Escalation | Exploitation for Privilege Escalation |
| Discovery            | Network Service Scanning              |
| Exfiltration         | Exfiltration Over Web Services        |

Each technique has a unique ATT&CK identifier (for example, T1078 for Valid Accounts).

---

# 8. Sub-Techniques

Many techniques have more detailed sub-techniques.

### Example

Technique:

Credential Dumping

Sub-Techniques:

* LSASS Memory
* Security Account Manager (SAM)
* NTDS
* DCSync

Sub-techniques allow defenders to create more precise detections and mitigations.

---

# 9. Procedures (TTPs)

Procedures are real-world implementations of techniques by specific threat actors.

Example:

Technique:

Credential Dumping

Procedure:

A ransomware group uses an open-source credential dumping tool after compromising a domain controller.

Procedures change frequently, while tactics and techniques remain relatively stable.

---

# 10. ATT&CK Lifecycle

A simplified attacker workflow:

```text id="attack-lifecycle"
Reconnaissance
        │
        ▼
Initial Access
        │
        ▼
Execution
        │
        ▼
Persistence
        │
        ▼
Privilege Escalation
        │
        ▼
Credential Access
        │
        ▼
Discovery
        │
        ▼
Lateral Movement
        │
        ▼
Collection
        │
        ▼
Exfiltration
        │
        ▼
Impact
```

Threat modeling can identify where security controls interrupt this sequence.

---

# 11. Enterprise ATT&CK Tactics

Below are common examples of attacker objectives.

## Initial Access

Examples:

* Phishing emails.
* Exploiting public-facing applications.
* Stolen credentials.
* Supply chain compromise.

### Possible Controls

* MFA
* Email security
* Web Application Firewall
* Vulnerability management

---

## Persistence

Examples:

* Scheduled tasks.
* Startup folders.
* New service creation.
* Cloud IAM persistence.

Controls:

* Endpoint monitoring.
* IAM reviews.
* Baseline comparisons.

---

## Privilege Escalation

Examples:

* Kernel exploits.
* Misconfigured IAM roles.
* Token theft.
* RBAC abuse.

Controls:

* Least privilege.
* PAM.
* Continuous authorization reviews.

---

## Credential Access

Examples:

* Password spraying.
* Credential dumping.
* Keylogging.
* Browser credential theft.

Controls:

* MFA.
* Credential Guard.
* Passwordless authentication.
* Secrets management.

---

## Discovery

Examples:

* Network scanning.
* Account enumeration.
* Cloud resource discovery.
* API enumeration.

Controls:

* Logging.
* Network segmentation.
* Alerting on abnormal discovery behavior.

---

## Lateral Movement

Examples:

* Remote Desktop Protocol (RDP).
* SMB.
* SSH.
* Kubernetes API abuse.

Controls:

* Network segmentation.
* Zero Trust.
* Just-in-Time administration.

---

## Collection

Examples:

* Database exports.
* Cloud storage enumeration.
* Email collection.

Controls:

* Data classification.
* DLP.
* Audit logging.

---

## Exfiltration

Examples:

* HTTPS.
* Cloud storage.
* DNS tunneling.

Controls:

* DLP.
* Network monitoring.
* Proxy inspection.

---

## Impact

Examples:

* Ransomware.
* Data destruction.
* Service disruption.

Controls:

* Immutable backups.
* Incident response.
* Disaster recovery.
* Business continuity.

---

# 12. Mapping STRIDE to ATT&CK

| STRIDE                 | Example ATT&CK Activities                  |
| ---------------------- | ------------------------------------------ |
| Spoofing               | Valid Accounts, Stolen Tokens              |
| Tampering              | Data Manipulation, Supply Chain Compromise |
| Repudiation            | Log Clearing, Indicator Removal            |
| Information Disclosure | Data Collection, Exfiltration              |
| Denial of Service      | Impact techniques, Resource Exhaustion     |
| Elevation of Privilege | Privilege Escalation techniques            |

This mapping helps move from abstract threat categories to concrete attacker behaviors.

---

# 13. Mapping ATT&CK to the Cyber Kill Chain

| Kill Chain Phase      | ATT&CK Examples                  |
| --------------------- | -------------------------------- |
| Reconnaissance        | Reconnaissance                   |
| Weaponization         | Resource Development             |
| Delivery              | Initial Access                   |
| Exploitation          | Execution                        |
| Installation          | Persistence                      |
| Command & Control     | Command and Control              |
| Actions on Objectives | Collection, Exfiltration, Impact |

---

# 14. ATT&CK in Threat Modeling

ATT&CK strengthens threat models by providing realistic attack scenarios.

### Example

Threat identified through STRIDE:

**Elevation of Privilege**

Relevant ATT&CK techniques:

* Valid Accounts
* Exploitation for Privilege Escalation
* Abuse Elevation Control Mechanism

Mitigations:

* RBAC.
* PAM.
* MFA.
* Continuous monitoring.

---

# 15. ATT&CK in Detection Engineering

Threat modeling identifies what could happen.

ATT&CK helps determine **what should be detected**.

Example:

Threat:

Credential dumping.

Detection Opportunities:

* Unexpected access to LSASS.
* Privileged process creation.
* Memory access anomalies.
* Security event correlation.

Output:

* SIEM detection rules.
* Endpoint Detection and Response (EDR) alerts.
* Incident response playbooks.

---

# 16. ATT&CK in Purple Teaming

Purple teaming combines offensive and defensive testing.

Workflow:

```text id="purple-team"
Threat Model
      │
      ▼
Select ATT&CK Techniques
      │
      ▼
Red Team Simulation
      │
      ▼
Blue Team Detection
      │
      ▼
Improve Controls
```

Benefits:

* Validates mitigations.
* Improves detection coverage.
* Measures response effectiveness.

---

# 17. Enterprise Example

## Scenario

A cloud-hosted payment platform.

### Threat

Credential theft.

### ATT&CK Mapping

Tactic:

Credential Access.

Technique:

Password Spraying.

Follow-on Tactics:

* Initial Access.
* Privilege Escalation.
* Discovery.
* Collection.
* Exfiltration.

### Controls

* MFA.
* Conditional access.
* Password protection.
* SIEM alerts.
* UEBA (User and Entity Behavior Analytics).

### Detection

Alert on:

* Repeated authentication failures.
* Successful login after multiple failures.
* Login from unusual geography.
* Impossible travel events.

---

# 18. Best Practices

* Use ATT&CK to validate threat models with real attacker behaviors.
* Map identified threats to ATT&CK techniques where practical.
* Build detection rules alongside preventive controls.
* Keep ATT&CK mappings current as techniques evolve.
* Integrate ATT&CK into tabletop exercises and purple team engagements.
* Use ATT&CK coverage to identify gaps in monitoring and response capabilities.

---

# 19. ATT&CK Quick Reference

## Core Components

* Tactics
* Techniques
* Sub-Techniques
* Procedures

---

## Common Enterprise Tactics

* Initial Access
* Execution
* Persistence
* Privilege Escalation
* Defense Evasion
* Credential Access
* Discovery
* Lateral Movement
* Collection
* Exfiltration
* Impact

---

## Key Questions

* Which attacker objectives are relevant to this system?
* Which ATT&CK techniques align with the threats we identified?
* What preventive controls exist?
* What detective controls exist?
* Which techniques are not currently detectable?
* How will we validate our controls?

---

## ATT&CK Assessment Checklist

* Threats mapped to ATT&CK techniques.
* Security controls identified.
* Detection opportunities documented.
* SIEM use cases created.
* Incident response playbooks updated.
* Purple team scenarios planned.
* Coverage gaps reviewed.
* ATT&CK mappings maintained.

---

# Key Takeaways

* **MITRE ATT&CK provides a common language for describing adversary behavior**, making it an essential companion to threat modeling methodologies.
* Rather than replacing frameworks like STRIDE or PASTA, ATT&CK enriches them by connecting identified threats to **real-world tactics, techniques, and procedures (TTPs)** observed in actual attacks.
* Mapping threats to ATT&CK helps organizations design more effective preventive controls, build targeted detection rules, prioritize security monitoring, and validate defenses through red and purple team exercises.
* Mature security programs use ATT&CK not only for incident response but also throughout the secure development lifecycle, ensuring that architectural decisions account for how modern adversaries are most likely to attack.
