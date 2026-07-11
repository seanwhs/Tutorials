# Appendix I.3.3 — Identity & Access Management Assessment Workbook

> *"In modern enterprises, identity has become the new security perimeter."*

---

# Purpose

Most significant cyber incidents no longer begin with malware exploiting technical vulnerabilities.

They begin with:

* Stolen credentials.
* Compromised privileged accounts.
* Weak authentication.
* Excessive access permissions.
* Mismanaged service accounts.
* Third-party identity abuse.

Cloud adoption, SaaS platforms, remote work, APIs, automation, and AI-driven systems have transformed identity into one of the most critical cyber resilience domains.

This workbook evaluates the organization's ability to:

* Govern identities.
* Control access.
* Protect privileged accounts.
* Secure machine identities.
* Detect identity abuse.
* Recover identity services after disruption.

---

# Assessment Scope

This assessment covers:

* Identity governance.
* Authentication.
* Authorization.
* Privileged access management.
* Service and machine identities.
* Third-party identities.
* Identity monitoring.
* Identity lifecycle management.
* Zero Trust alignment.
* Identity resilience and recovery.

---

# Capability Objectives

A mature identity capability ensures:

✓ Every identity is known and governed.

✓ Access is granted based on business need.

✓ Privileged access is tightly controlled.

✓ Identity abuse is rapidly detected.

✓ Identity systems can withstand and recover from compromise.

✓ Identity supports Zero Trust architecture.

---

# Capability Areas

| Section | Capability                           |
| ------- | ------------------------------------ |
| IAM1    | Identity Governance                  |
| IAM2    | Identity Lifecycle Management        |
| IAM3    | Authentication & Credential Security |
| IAM4    | Authorization & Access Control       |
| IAM5    | Privileged Access Management         |
| IAM6    | Machine & Service Identities         |
| IAM7    | Third-Party Identity Management      |
| IAM8    | Identity Monitoring & Detection      |
| IAM9    | Identity Resilience & Recovery       |
| IAM10   | Zero Trust Identity Maturity         |

---

# IAM1 — Identity Governance

## Objective

Assess whether identity management is governed consistently across the enterprise.

---

## Assessment Questions

Rate each statement from 0 (Not Implemented) to 5 (Adaptive).

| #       | Assessment Question                                                     | Score |
| ------- | ----------------------------------------------------------------------- | :---: |
| IAM1.1  | Identity governance policies are formally approved.                     |       |
| IAM1.2  | Identity ownership is assigned and documented.                          |       |
| IAM1.3  | Business owners approve access decisions.                               |       |
| IAM1.4  | Identity governance aligns with enterprise risk management.             |       |
| IAM1.5  | Identity metrics are reviewed by leadership.                            |       |
| IAM1.6  | Identity-related risks are tracked in the enterprise risk register.     |       |
| IAM1.7  | Identity governance responsibilities are periodically reviewed.         |       |
| IAM1.8  | Identity standards are applied consistently across business units.      |       |
| IAM1.9  | Cloud and on-premises identities are governed under a common framework. |       |
| IAM1.10 | Governance effectiveness is independently assessed.                     |       |

---

## Evidence Checklist

Examples:

* Identity governance policy.
* Access control standards.
* Identity steering committee records.
* Audit reports.
* Risk assessments.
* Governance dashboards.

---

## Common Weaknesses

Examples:

* Multiple identity systems with inconsistent controls.
* Undefined ownership.
* Limited executive visibility.
* Identity governance confined to IT.

---

# IAM2 — Identity Lifecycle Management

## Objective

Determine whether identities are created, modified, and removed in a controlled manner.

---

## Assessment Areas

Evaluate:

* Joiner processes.
* Mover processes.
* Leaver processes.
* Contractor onboarding.
* Temporary access management.
* Automated provisioning.
* Identity reconciliation.

---

## Sample Questions

| Question                                             | Score |
| ---------------------------------------------------- | :---: |
| User provisioning follows documented workflows.      |       |
| Access approvals are recorded.                       |       |
| Terminated accounts are removed within defined SLAs. |       |
| Dormant accounts are regularly reviewed.             |       |
| Identity records are synchronized across systems.    |       |

---

## Evidence

Examples:

* HR integration documentation.
* Provisioning workflows.
* Termination reports.
* Identity reconciliation logs.

---

# IAM3 — Authentication & Credential Security

## Objective

Assess the strength and resilience of authentication controls.

---

## Assessment Areas

Evaluate:

* Multi-factor authentication (MFA).
* Password policies.
* Passwordless authentication.
* Adaptive authentication.
* Credential storage.
* Credential rotation.
* Authentication assurance levels.

---

## Assessment Questions

| #       | Assessment Question                                              | Score |
| ------- | ---------------------------------------------------------------- | :---: |
| IAM3.1  | MFA is enforced for privileged accounts.                         |       |
| IAM3.2  | MFA is enforced for remote access.                               |       |
| IAM3.3  | MFA coverage extends to critical business applications.          |       |
| IAM3.4  | Password policies align with industry guidance.                  |       |
| IAM3.5  | Passwordless authentication is evaluated for critical use cases. |       |
| IAM3.6  | High-risk authentication attempts trigger additional controls.   |       |
| IAM3.7  | Authentication logs are centrally monitored.                     |       |
| IAM3.8  | Shared credentials are prohibited or tightly controlled.         |       |
| IAM3.9  | Credential compromise scenarios are exercised.                   |       |
| IAM3.10 | Authentication architecture supports resilience requirements.    |       |

---

# IAM4 — Authorization & Access Control

## Objective

Assess whether access is limited to what users need to perform their duties.

---

## Assessment Areas

Evaluate:

* Least privilege.
* Role-based access control (RBAC).
* Attribute-based access control (ABAC).
* Segregation of duties.
* Access reviews.
* Entitlement management.

---

## Sample Questions

| Question                                              | Score |
| ----------------------------------------------------- | :---: |
| Access rights are role-based.                         |       |
| Excessive privileges are identified and removed.      |       |
| Access reviews occur periodically.                    |       |
| Segregation-of-duty conflicts are monitored.          |       |
| Sensitive systems receive enhanced access governance. |       |

---

# IAM5 — Privileged Access Management (PAM)

## Objective

Evaluate control of administrative and high-risk accounts.

---

## Assessment Areas

Assess:

* Privileged account inventory.
* Vaulting.
* Session monitoring.
* Just-in-time access.
* Privileged access reviews.
* Emergency access accounts.
* Administrative workstation controls.

---

## Maturity Indicators

### Level 1

Shared administrator accounts widely used.

### Level 3

Privileged accounts individually assigned and reviewed.

### Level 5

Just-in-time privileged access with continuous monitoring and behavioral analytics.

---

## Evidence

Examples:

* PAM platform reports.
* Privileged account inventories.
* Session recordings.
* Access review records.

---

# IAM6 — Machine & Service Identities

## Objective

Assess governance of non-human identities.

---

## Assessment Areas

Evaluate:

* Service accounts.
* API identities.
* Certificates.
* Secrets management.
* Workload identities.
* Cloud service principals.
* Container identities.

---

## Sample Questions

| Question                                                  | Score |
| --------------------------------------------------------- | :---: |
| Service accounts are inventoried.                         |       |
| Service account ownership is documented.                  |       |
| Secrets are centrally managed.                            |       |
| Certificates are monitored for expiration.                |       |
| Machine identities follow lifecycle management processes. |       |

---

## Common Weaknesses

Examples:

* Unknown service accounts.
* Hardcoded credentials.
* Expired certificates.
* Excessive API permissions.

---

# IAM7 — Third-Party Identity Management

## Objective

Assess management of external identities.

---

## Assessment Areas

Evaluate:

* Vendor access.
* Contractor access.
* Federated identities.
* Supplier onboarding.
* Supplier offboarding.
* Third-party privileged access.

---

## Assessment Questions

| Question                                               | Score |
| ------------------------------------------------------ | :---: |
| Vendor identities are separately managed.              |       |
| Third-party access requires approval.                  |       |
| Supplier access is periodically reviewed.              |       |
| Vendor privileged access is monitored.                 |       |
| Third-party access is removed when no longer required. |       |

---

# IAM8 — Identity Monitoring & Detection

## Objective

Evaluate the organization's ability to detect identity abuse.

---

## Assessment Areas

Assess:

* Identity threat detection.
* User behavior analytics.
* Impossible travel detection.
* Privilege escalation monitoring.
* MFA bypass detection.
* Credential theft monitoring.

---

## Evidence Examples

* SIEM dashboards.
* Identity protection reports.
* Detection rules.
* Incident reports.

---

# IAM9 — Identity Resilience & Recovery

## Objective

Assess whether identity services can recover from disruption or compromise.

---

## Assessment Areas

Evaluate:

* Identity backups.
* Recovery procedures.
* Directory service resilience.
* Authentication service continuity.
* Identity disaster recovery.
* Recovery testing.

---

## Sample Questions

| Question                                          | Score |
| ------------------------------------------------- | :---: |
| Identity platforms are backed up.                 |       |
| Recovery procedures are documented.               |       |
| Recovery testing is performed regularly.          |       |
| Recovery objectives are defined.                  |       |
| Identity recovery is included in cyber exercises. |       |

---

# IAM10 — Zero Trust Identity Maturity

## Objective

Assess alignment with modern Zero Trust principles.

---

## Assessment Areas

Evaluate:

* Continuous verification.
* Context-aware access.
* Risk-based authentication.
* Device trust integration.
* Micro-segmentation support.
* Identity-centric architecture.

---

## Maturity Indicators

### Level 1

Trust based primarily on network location.

### Level 2

Basic MFA implemented.

### Level 3

Identity-centric access decisions.

### Level 4

Risk-adaptive access controls.

### Level 5

Continuous verification across users, devices, applications, and workloads.

---

# Domain Scoring Worksheet

| Capability Area                      | Score |
| ------------------------------------ | ----: |
| Identity Governance                  |       |
| Identity Lifecycle Management        |       |
| Authentication & Credential Security |       |
| Authorization & Access Control       |       |
| Privileged Access Management         |       |
| Machine & Service Identities         |       |
| Third-Party Identity Management      |       |
| Identity Monitoring & Detection      |       |
| Identity Resilience & Recovery       |       |
| Zero Trust Identity Maturity         |       |

**Overall Identity & Access Management Score:** ______ / 5

---

# Executive Interpretation

|   Score | Maturity Level | Interpretation                                                                                |
| ------: | -------------- | --------------------------------------------------------------------------------------------- |
| 0.0–0.9 | Initial        | Identity controls are fragmented and largely reactive.                                        |
| 1.0–1.9 | Developing     | Basic IAM capabilities exist but lack consistency.                                            |
| 2.0–2.9 | Defined        | Standardized identity governance and access controls implemented.                             |
| 3.0–3.9 | Managed        | Identity risk is actively monitored and measured.                                             |
| 4.0–5.0 | Adaptive       | Identity serves as the foundation of enterprise cyber resilience and Zero Trust architecture. |

---

# Improvement Planning Worksheet

| Priority | Improvement Action | Owner | Target Date | Status |
| -------- | ------------------ | ----- | ----------- | ------ |
| High     |                    |       |             |        |
| Medium   |                    |       |             |        |
| Low      |                    |       |             |        |

---

# Assessor Notes

Document:

* Significant identity risks.
* Privileged access concerns.
* Third-party identity issues.
* Identity recovery gaps.
* Recommended investments.
* Executive decisions required.

These observations should feed directly into enterprise cyber resilience planning and risk governance.

---

# End of Appendix I.3.3

## Next Workbook

**Appendix I.3.4 — Detection & Monitoring Assessment Workbook**

The next workbook examines enterprise visibility, security operations, threat detection engineering, SIEM/SOC maturity, threat intelligence integration, AI-assisted detection, and modern monitoring capabilities that enable rapid identification of cyber threats.
