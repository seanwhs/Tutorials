# Appendix H – OWASP Threat Modeling & Application Security Reference

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix H**
> **Purpose:** This appendix provides a comprehensive reference to the **OWASP (Open Worldwide Application Security Project)** resources most relevant to threat modeling. While frameworks such as STRIDE, PASTA, Trike, and VAST help identify threats, OWASP provides practical guidance on **common application vulnerabilities, secure design principles, security testing, and developer-focused mitigations**.

> **Best suited for:** Software developers, software architects, DevSecOps engineers, security champions, penetration testers, QA engineers, application security teams, and technical leads.

---

# Table of Contents

1. Introduction to OWASP
2. Why OWASP Matters in Threat Modeling
3. OWASP Projects Relevant to Threat Modeling
4. OWASP Top 10
5. OWASP ASVS
6. OWASP Proactive Controls
7. OWASP Secure Coding Practices
8. OWASP API Security Top 10
9. OWASP Mobile Top 10
10. OWASP Web Security Testing Guide (WSTG)
11. OWASP Cheat Sheet Series
12. Mapping STRIDE to OWASP
13. Secure Design Principles
14. Integrating OWASP into the SDLC
15. Example Threat Modeling Workflow Using OWASP
16. OWASP Resources Checklist
17. Quick Reference

---

# 1. Introduction to OWASP

The **Open Worldwide Application Security Project (OWASP)** is a global non-profit organization dedicated to improving software security through freely available standards, tools, documentation, and community projects.

OWASP is widely regarded as one of the most authoritative sources of guidance for secure application development and application security testing.

Unlike a threat modeling methodology, OWASP provides:

* Secure coding guidance.
* Vulnerability classifications.
* Security verification standards.
* Testing methodologies.
* Security design recommendations.
* Developer education.

---

# 2. Why OWASP Matters in Threat Modeling

Threat modeling identifies **what could go wrong**.

OWASP helps answer:

* How do we prevent it?
* How do we test for it?
* How do developers avoid introducing it?
* How do we verify that controls are working?

A typical workflow is:

```text id="owasp-workflow"
Architecture
      │
      ▼
Threat Modeling
      │
      ▼
Identify Threats
      │
      ▼
Map to OWASP Guidance
      │
      ▼
Implement Controls
      │
      ▼
Verify Security
```

---

# 3. OWASP Projects Relevant to Threat Modeling

OWASP maintains numerous projects. The following are especially valuable during architecture reviews and secure development.

| Project                           | Purpose                                      |
| --------------------------------- | -------------------------------------------- |
| OWASP Top 10                      | Most critical web application security risks |
| ASVS                              | Application Security Verification Standard   |
| Proactive Controls                | Secure coding guidance                       |
| API Security Top 10               | Risks specific to APIs                       |
| Mobile Top 10                     | Risks for mobile applications                |
| Web Security Testing Guide (WSTG) | Testing methodology                          |
| Cheat Sheet Series                | Practical implementation guidance            |
| Dependency-Check                  | Detect vulnerable software components        |
| CycloneDX                         | Software Bill of Materials (SBOM) standard   |
| DefectDojo                        | Vulnerability management platform            |

---

# 4. OWASP Top 10

The OWASP Top 10 identifies the most significant categories of web application security risk.

| Category                                 | Description                                       |
| ---------------------------------------- | ------------------------------------------------- |
| Broken Access Control                    | Users access resources beyond their authorization |
| Cryptographic Failures                   | Weak or missing encryption                        |
| Injection                                | SQL, NoSQL, OS, LDAP, and other injections        |
| Insecure Design                          | Missing or ineffective security design            |
| Security Misconfiguration                | Unsafe default settings or poor configuration     |
| Vulnerable Components                    | Outdated or insecure libraries                    |
| Identification & Authentication Failures | Weak authentication mechanisms                    |
| Software & Data Integrity Failures       | Supply chain and integrity issues                 |
| Security Logging & Monitoring Failures   | Insufficient detection and auditing               |
| Server-Side Request Forgery (SSRF)       | Server abused to access unintended resources      |

### Threat Modeling Use

Each identified threat should be checked against these categories to determine whether a known class of application vulnerability is involved.

---

# 5. OWASP Application Security Verification Standard (ASVS)

ASVS is a comprehensive framework for defining and verifying application security requirements.

### Verification Levels

| Level   | Intended Use                        |
| ------- | ----------------------------------- |
| Level 1 | Low assurance applications          |
| Level 2 | Most business applications          |
| Level 3 | High-value or critical applications |

### Major Control Areas

* Authentication
* Access control
* Session management
* Input validation
* Cryptography
* Error handling
* Logging
* File handling
* API security
* Configuration
* Data protection

### Threat Modeling Benefit

ASVS provides concrete security requirements that can be traced directly to threats identified during modeling.

---

# 6. OWASP Proactive Controls

The Proactive Controls project translates security requirements into developer-friendly practices.

Common controls include:

1. Define security requirements.
2. Leverage security frameworks and libraries.
3. Secure database access.
4. Encode and validate input.
5. Validate all inputs.
6. Implement digital identity.
7. Enforce access controls.
8. Protect data everywhere.
9. Implement logging and monitoring.
10. Handle errors securely.

Threat modeling outputs can be mapped directly to these controls.

---

# 7. OWASP Secure Coding Practices

Secure coding is the implementation layer of threat modeling.

### Key Practices

* Validate all inputs.
* Encode outputs.
* Use parameterized queries.
* Apply least privilege.
* Avoid hard-coded secrets.
* Store passwords using strong adaptive hashing algorithms.
* Encrypt sensitive data in transit and at rest.
* Use secure session management.
* Implement secure error handling.
* Log security-relevant events.

### Example

Threat:

SQL Injection.

Secure Coding Response:

* Parameterized queries.
* ORM frameworks.
* Input validation.
* Database least privilege.

---

# 8. OWASP API Security Top 10

Modern systems rely heavily on APIs.

Common API risks include:

| Risk                                            | Example                              |
| ----------------------------------------------- | ------------------------------------ |
| Broken Object Level Authorization               | Accessing another user's records     |
| Broken Authentication                           | Weak token validation                |
| Broken Object Property Level Authorization      | Overexposed object properties        |
| Unrestricted Resource Consumption               | API abuse causing denial of service  |
| Broken Function Level Authorization             | Calling privileged functions         |
| Unrestricted Access to Sensitive Business Flows | Automated abuse of business logic    |
| Server-Side Request Forgery                     | Backend systems accessed through API |
| Security Misconfiguration                       | Exposed management endpoints         |
| Improper Inventory Management                   | Forgotten APIs                       |
| Unsafe Consumption of APIs                      | Trusting insecure third-party APIs   |

Threat modeling should include every public and internal API.

---

# 9. OWASP Mobile Top 10

For mobile applications, consider additional threats such as:

* Insecure data storage.
* Insecure communication.
* Weak authentication.
* Code tampering.
* Reverse engineering.
* Insecure local storage.
* Insufficient cryptography.
* Client-side injection.
* Privacy leakage.
* Platform misuse.

Threat models should account for both the mobile client and backend services.

---

# 10. OWASP Web Security Testing Guide (WSTG)

The WSTG provides a structured methodology for validating security controls.

Testing areas include:

* Information gathering.
* Configuration testing.
* Identity management testing.
* Authentication testing.
* Authorization testing.
* Session management.
* Input validation.
* Error handling.
* Cryptography.
* Business logic.
* Client-side testing.
* API testing.

Threat modeling informs what should be tested; WSTG explains how to test it.

---

# 11. OWASP Cheat Sheet Series

The Cheat Sheet Series offers concise implementation guidance.

Popular cheat sheets include:

* Authentication.
* Authorization.
* Cross-Site Scripting (XSS) Prevention.
* SQL Injection Prevention.
* Session Management.
* Logging.
* Transport Layer Security.
* Password Storage.
* Secrets Management.
* Docker Security.
* Kubernetes Security.
* Microservices Security.
* REST Security.
* GraphQL Security.

These are practical references for developers implementing mitigations.

---

# 12. Mapping STRIDE to OWASP

| STRIDE Category        | OWASP Guidance                                   |
| ---------------------- | ------------------------------------------------ |
| Spoofing               | Authentication, MFA, Identity Management         |
| Tampering              | Integrity checks, Input Validation, Cryptography |
| Repudiation            | Logging, Audit Trails, Non-repudiation Controls  |
| Information Disclosure | Encryption, Access Control, Data Protection      |
| Denial of Service      | Rate Limiting, Resource Management, API Security |
| Elevation of Privilege | Authorization, Least Privilege, RBAC             |

This mapping helps bridge architecture-level threats with implementation-level controls.

---

# 13. Secure Design Principles

Threat modeling is most effective when paired with sound design principles.

### Core Principles

* Least Privilege
* Defense in Depth
* Fail Securely
* Secure by Default
* Separation of Duties
* Minimize Attack Surface
* Complete Mediation
* Economy of Mechanism
* Zero Trust
* Secure Supply Chain

These principles should guide architectural decisions before code is written.

---

# 14. Integrating OWASP into the SDLC

| SDLC Phase   | OWASP Activity                                 |
| ------------ | ---------------------------------------------- |
| Requirements | ASVS security requirements                     |
| Architecture | Threat modeling and secure design              |
| Development  | Proactive Controls and Secure Coding Practices |
| Testing      | WSTG, SAST, DAST, API testing                  |
| Deployment   | Secure configuration, secrets management       |
| Operations   | Logging, monitoring, dependency management     |

Threat modeling should be revisited whenever significant architectural changes occur.

---

# 15. Example Threat Modeling Workflow Using OWASP

## Scenario

A customer portal exposes REST APIs for account management.

### Threat Model Finding

Broken Object Level Authorization.

### Relevant OWASP Guidance

* API Security Top 10.
* ASVS Access Control requirements.
* Authorization Cheat Sheet.

### Recommended Controls

* Enforce server-side authorization checks.
* Use indirect object references where appropriate.
* Implement comprehensive authorization testing.
* Log unauthorized access attempts.

### Verification

* Automated API security tests.
* Manual penetration testing.
* Code review.
* Security regression testing.

---

# 16. OWASP Resources Checklist

Before releasing an application, verify that:

* Threat model has been completed.
* OWASP Top 10 risks have been considered.
* ASVS requirements have been mapped.
* Secure coding practices have been followed.
* API Security Top 10 has been reviewed.
* Dependencies have been scanned.
* Security testing has been performed.
* Logging and monitoring are configured.
* Secrets are managed securely.
* Residual risks are documented.

---

# 17. Quick Reference

## Most Important OWASP Projects

| Project             | Primary Purpose             |
| ------------------- | --------------------------- |
| Top 10              | Common application risks    |
| ASVS                | Security requirements       |
| WSTG                | Security testing            |
| API Security Top 10 | API-specific threats        |
| Proactive Controls  | Secure development guidance |
| Cheat Sheet Series  | Implementation reference    |

---

## Key Questions

* Does this threat align with a known OWASP risk category?
* Which ASVS requirements address it?
* What secure coding practices are required?
* How will the control be verified?
* What testing activities validate the mitigation?
* How will the application be monitored after deployment?

---

## OWASP Assessment Checklist

* Threats mapped to OWASP guidance.
* ASVS requirements identified.
* Secure coding controls implemented.
* API-specific risks assessed.
* Security testing completed.
* Vulnerability scans reviewed.
* Dependency management performed.
* Logging and monitoring validated.
* Documentation updated.
* Residual risks accepted or remediated.

---

# Key Takeaways

* **OWASP provides the practical implementation guidance that complements threat modeling methodologies**, helping development teams translate identified threats into concrete security requirements, secure coding practices, and verification activities.
* By leveraging resources such as the **OWASP Top 10, ASVS, API Security Top 10, WSTG, and Cheat Sheet Series**, organizations can build a consistent, developer-friendly approach to application security.
* Integrating OWASP guidance throughout the software development lifecycle ensures that security is addressed from architecture through deployment and operations, reducing the likelihood of introducing common vulnerabilities.
* When combined with frameworks such as STRIDE, PASTA, Trike, VAST, and MITRE ATT&CK, OWASP forms a critical part of a mature, risk-driven Secure Software Development Lifecycle (SSDLC).
