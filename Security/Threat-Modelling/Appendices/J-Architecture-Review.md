# Appendix J – Threat Modeling Interview Questions & Architecture Review Checklist

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix J**
>
> **Purpose:** This appendix contains a **comprehensive library of interview questions, architecture review questions, facilitator prompts, and design review checklists** used by professional security architects during threat modeling workshops.
>
> This appendix is particularly useful for:
>
> * Security Architects
> * Solution Architects
> * Enterprise Architects
> * Application Architects
> * Cloud Architects
> * Security Review Boards
> * DevSecOps Teams
> * Architecture Review Boards (ARB)
> * Penetration Test Scoping
> * Secure Design Reviews

---

# Table of Contents

1. General Architecture Questions
2. Business Questions
3. Data Questions
4. Authentication Questions
5. Authorization Questions
6. Session Management Questions
7. API Security Questions
8. Cloud Security Questions
9. Network Security Questions
10. Database Questions
11. Logging & Monitoring Questions
12. Infrastructure Questions
13. DevSecOps Questions
14. Third-Party Integration Questions
15. Incident Response Questions
16. Privacy Questions
17. Compliance Questions
18. Facilitator Question Bank
19. Executive Questions
20. Final Architecture Review Checklist

---

# 1. General Architecture Questions

Every threat modeling exercise should begin by understanding the system.

### Business Context

* What problem does this system solve?
* Why is this application being built?
* Who are the intended users?
* Which business processes depend on this application?
* What would happen if the application became unavailable?

---

### Architecture

* Is the application monolithic?
* Microservices?
* Event-driven?
* Serverless?
* Hybrid cloud?
* Multi-cloud?

---

### Technology Stack

* Programming languages
* Frameworks
* Databases
* Identity provider
* Cloud platform
* Messaging platform
* API gateway

---

### Deployment

* On-premises
* Cloud
* Hybrid
* Kubernetes
* Containers
* Virtual machines

---

# 2. Business Questions

Business risk drives security priorities.

### Criticality

* Is this mission critical?
* Does it generate revenue?
* Does it support customers?
* Does it process payments?
* Is it customer-facing?

---

### Impact

If compromised:

* Financial loss?
* Reputation damage?
* Regulatory penalties?
* Operational disruption?
* Customer trust?

---

### Recovery

* Maximum acceptable downtime?
* Recovery Time Objective (RTO)?
* Recovery Point Objective (RPO)?

---

# 3. Data Questions

Understanding data is fundamental.

### Data Inventory

* What data is collected?
* What data is generated?
* What data leaves the system?
* What data is retained?

---

### Classification

* Public
* Internal
* Confidential
* Restricted

---

### Sensitive Data

Does the application store:

* PII?
* PHI?
* PCI?
* Financial records?
* Intellectual property?
* Authentication secrets?
* Encryption keys?

---

### Protection

* Encryption at rest?
* Encryption in transit?
* Tokenization?
* Masking?
* Key management?

---

# 4. Authentication Questions

Identity is one of the most attacked areas.

### Identity

* Local authentication?
* SSO?
* OAuth?
* OpenID Connect?
* SAML?

---

### Credentials

* Password policy?
* MFA?
* Passwordless?
* Account lockout?
* Adaptive authentication?

---

### Questions

* Can credentials be brute forced?
* Can sessions be hijacked?
* Can tokens be replayed?
* Are service accounts protected?

---

# 5. Authorization Questions

Authentication answers **who**.

Authorization answers **what they can do**.

Questions:

* RBAC?
* ABAC?
* PBAC?
* Least privilege?
* Segregation of duties?

---

Can users:

* Access another user's records?
* Elevate privileges?
* Access administrative functions?
* Bypass authorization?

---

# 6. Session Management Questions

Questions:

* Session timeout?
* Idle timeout?
* Absolute timeout?
* Secure cookies?
* HttpOnly?
* SameSite?
* Token expiration?

---

Additional Questions

* Are refresh tokens rotated?
* Is logout enforced?
* Can sessions be revoked?
* Are concurrent sessions limited?

---

# 7. API Security Questions

Modern systems revolve around APIs.

Questions:

* REST?
* GraphQL?
* gRPC?
* SOAP?

---

Authentication

* API Keys?
* JWT?
* OAuth?
* mTLS?

---

Security

* Rate limiting?
* Input validation?
* Output validation?
* Schema validation?
* API Gateway?
* WAF?

---

Inventory

* Are all APIs documented?
* Shadow APIs?
* Deprecated APIs?
* Version management?

---

# 8. Cloud Security Questions

Cloud introduces new trust boundaries.

### Identity

* IAM roles?
* Service identities?
* Managed identities?

---

### Storage

* Public buckets?
* Encryption?
* Lifecycle policies?

---

### Networking

* Security groups?
* Firewalls?
* Private endpoints?
* VPN?
* Zero Trust?

---

### Compute

* Containers?
* Serverless?
* Virtual machines?

---

### Secrets

* Secret manager?
* Key vault?
* Rotation?
* HSM?

---

# 9. Network Security Questions

Questions

* Network segmentation?
* DMZ?
* East-West traffic inspection?
* VPN?
* Firewall rules?
* IDS/IPS?
* NAC?

---

Zero Trust

* Device verification?
* User verification?
* Continuous authentication?
* Conditional access?

---

# 10. Database Questions

Questions

* SQL?
* NoSQL?
* Graph?
* Time-series?

---

Security

* Encryption?
* Backups?
* Auditing?
* Row-level security?
* Database firewall?

---

Threats

* SQL Injection?
* Data exfiltration?
* Backup theft?
* Insider abuse?

---

# 11. Logging & Monitoring Questions

Questions

* SIEM?
* Central logging?
* Audit trails?
* Time synchronization?
* Immutable logs?

---

Detection

* Failed logins?
* Privilege escalation?
* API abuse?
* Data downloads?
* Configuration changes?

---

Monitoring

* Metrics?
* Tracing?
* Alerting?
* UEBA?
* SOAR?

---

# 12. Infrastructure Questions

Questions

* Infrastructure as Code?
* Immutable infrastructure?
* CIS benchmarks?
* Patch management?
* Vulnerability scanning?

---

Operations

* Configuration management?
* Drift detection?
* Asset inventory?
* Backup testing?

---

# 13. DevSecOps Questions

Questions

* Secure SDLC?
* Threat modeling?
* Code reviews?
* SAST?
* DAST?
* SCA?
* IaC scanning?
* Container scanning?

---

Pipeline

* Secrets scanning?
* Branch protection?
* Signed commits?
* SBOM?
* Deployment approvals?

---

# 14. Third-Party Integration Questions

Questions

* Vendor risk assessment?
* Data sharing agreements?
* API authentication?
* Encryption?
* Availability SLAs?

---

Security

* Least privilege?
* Contractual security requirements?
* Audit rights?
* Continuous monitoring?

---

# 15. Incident Response Questions

Questions

* IR plan?
* Playbooks?
* Runbooks?
* Contact lists?
* Escalation paths?

---

Preparedness

* Tabletop exercises?
* Red team?
* Purple team?
* Disaster recovery testing?

---

Recovery

* Backup restoration?
* Ransomware recovery?
* Crisis communications?

---

# 16. Privacy Questions

Questions

* Data minimization?
* Purpose limitation?
* Consent?
* Data subject rights?
* Right to deletion?

---

Retention

* Data retention?
* Secure disposal?
* Cross-border transfers?

---

Privacy by Design

* Privacy Impact Assessment?
* Data Protection Impact Assessment?

---

# 17. Compliance Questions

Questions

Which regulations apply?

* ISO 27001?
* PCI DSS?
* GDPR?
* HIPAA?
* SOC 2?
* NIST?
* Local regulations?

---

Evidence

* Audit logs?
* Policies?
* Procedures?
* Risk register?
* Security awareness?

---

# 18. Facilitator Question Bank

These prompts help uncover hidden assumptions and overlooked risks during workshops.

### Architecture

* What assumptions are we making?
* What could change in the next 12 months?
* Which components are most critical?
* What single failure would have the greatest impact?

### Trust Boundaries

* Where does data cross organizational boundaries?
* Which components communicate over untrusted networks?
* Which integrations rely on implicit trust?

### Threats

* What would a cybercriminal target first?
* What would an insider misuse?
* Which attack requires the least effort?
* Which attack would be hardest to detect?

### Operations

* How is this monitored?
* How are secrets rotated?
* How are incidents investigated?
* How often are backups tested?

### Future Changes

* Are new APIs planned?
* Will additional cloud providers be used?
* Will AI services be integrated?
* Is international expansion expected?

---

# 19. Executive Questions

Executives focus on business impact rather than technical details.

Questions include:

* What are the top five business risks?
* What is the likelihood of a significant incident?
* What is the potential financial impact?
* Which regulations are affected?
* What are the highest-priority mitigation actions?
* What residual risks remain?
* Who owns each residual risk?
* What investment is required?
* How will success be measured?

---

# 20. Final Architecture Review Checklist

## Business

* ☐ Business objectives documented.
* ☐ Critical business processes identified.
* ☐ Risk appetite understood.

---

## Architecture

* ☐ Architecture diagrams reviewed.
* ☐ DFD completed.
* ☐ Trust boundaries documented.
* ☐ External dependencies identified.

---

## Assets

* ☐ Critical assets inventoried.
* ☐ Data classified.
* ☐ Ownership assigned.

---

## Threat Modeling

* ☐ STRIDE (or selected methodology) completed.
* ☐ Threat register created.
* ☐ Risk assessment performed.
* ☐ Mitigations identified.

---

## Security Controls

* ☐ Authentication reviewed.
* ☐ Authorization reviewed.
* ☐ Encryption validated.
* ☐ Logging and monitoring assessed.
* ☐ Backup and recovery verified.

---

## DevSecOps

* ☐ SAST integrated.
* ☐ DAST integrated.
* ☐ Dependency scanning enabled.
* ☐ IaC scanning implemented.
* ☐ Container security validated.
* ☐ Secrets management reviewed.

---

## Governance

* ☐ Risk owners assigned.
* ☐ Residual risks documented.
* ☐ Compliance requirements mapped.
* ☐ Executive summary prepared.
* ☐ Review schedule established.

---

# Appendix J Summary

A successful threat modeling exercise depends as much on **asking the right questions** as it does on applying the right methodology. This appendix provides a structured question bank that helps architects, developers, security professionals, and business stakeholders uncover hidden assumptions, identify trust boundaries, validate security controls, and prioritize risks.

Used consistently, these interview questions and review checklists improve the quality of architecture discussions, ensure comprehensive coverage of business and technical concerns, and create a repeatable process for secure design reviews across projects and enterprise environments. Together with the templates in Appendix I, they form a practical toolkit for conducting professional, risk-driven threat modeling workshops.
