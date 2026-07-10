---

title: Appendix F – Part 3
subtitle: Facilitator's Inject Cookbook – Cloud, SaaS & Supply Chain Incidents
description: A reusable library of tabletop exercise injects covering cloud platforms, SaaS applications, identity federation, CI/CD pipelines, APIs, software supply chains, and third-party service providers.
type: appendix
category: facilitator
version: 1.0
tags:
- ttx
- cloud
- saas
- supply-chain
- devsecops
- zero-trust

---

# Appendix F — Facilitator's Inject Cookbook

# Part 3 — Cloud, SaaS & Supply Chain Incidents

> *Modern organizations rarely operate within a single security boundary. Business services increasingly depend on cloud platforms, SaaS providers, identity federation, managed service providers, APIs, open-source software, and interconnected supply chains. As a result, incident response now extends beyond the enterprise network.*

This section introduces injects that reflect the realities of cloud-native architectures and digitally connected ecosystems. These scenarios are designed to test cross-functional coordination, third-party governance, cloud security practices, and decision-making when critical services lie outside the organization's direct control.

---

# Learning Objectives

These injects evaluate an organization's ability to:

* Respond to cloud security incidents.
* Investigate SaaS account compromise.
* Coordinate with cloud service providers.
* Manage software supply chain risks.
* Secure CI/CD pipelines.
* Protect API credentials.
* Assess third-party operational dependencies.
* Balance shared responsibility with organizational accountability.

---

# Category 9 — Cloud Identity & IAM

Cloud identities often become the primary attack surface.

---

# Inject CL-01 — Privileged Cloud Login

## Objective

Evaluate cloud identity governance.

### Difficulty

L2

### Timing

T+40

### Delivery

Cloud security alert

### Scenario

A cloud administrator account successfully authenticates from a country never previously associated with the organization.

Additional observations:

* New browser fingerprint
* API activity immediately follows login
* Multiple IAM policy changes initiated

### Discussion

* Is emergency access appropriate?
* Should credentials be revoked?
* What cloud logs should be collected?

---

# Inject CL-02 — Emergency Administrator Created

## Objective

Assess IAM governance.

### Scenario

An emergency administrator account appears in the cloud tenant.

No change approval exists.

### Facilitator Notes

Participants should distinguish between legitimate break-glass procedures and unauthorized privilege creation.

---

# Inject CL-03 — IAM Policy Modification

## Objective

Exercise cloud authorization controls.

### Scenario

A privileged policy is modified to grant broader access to object storage across multiple business units.

### Discussion

* Business justification?
* Scope of exposure?
* Rollback considerations?

---

# Category 10 — Cloud Storage & Data Exposure

---

# Inject CS-01 — Public Storage Bucket

## Objective

Evaluate cloud data governance.

### Scenario

A security assessment identifies a storage bucket configured for public read access.

Unknown whether sensitive information is present.

### Discussion

* Immediate remediation?
* Business owner consultation?
* Customer impact?

---

# Inject CS-02 — Sensitive Data Discovery

## Objective

Assess data classification processes.

### Scenario

Automated scanning identifies regulated information stored in an unauthorized cloud location.

### Facilitator Questions

* Who owns the data?
* Was encryption applied?
* Does this trigger notification obligations?

---

# Inject CS-03 — Unexpected Data Replication

## Objective

Exercise cloud monitoring.

### Scenario

Large datasets are replicated to a previously unseen geographic region.

### Discussion

Participants should determine whether replication is expected or suspicious.

---

# Category 11 — SaaS Applications

---

# Inject SA-01 — Corporate Email Takeover

## Objective

Evaluate SaaS identity response.

### Scenario

Security monitoring identifies mailbox forwarding rules directing executive email to an external account.

### Discussion

* How should forwarding rules be investigated?
* Should mailboxes be isolated?
* Is executive notification required?

---

# Inject SA-02 — OAuth Application Consent

## Objective

Exercise SaaS governance.

### Scenario

A user authorizes a third-party application requesting broad access to corporate email and documents.

### Discussion

* Legitimate productivity tool?
* Malicious OAuth application?
* Consent revocation procedures?

---

# Inject SA-03 — File Sharing Anomaly

## Objective

Evaluate SaaS collaboration controls.

### Scenario

Hundreds of internal documents are shared externally within a short period.

### Facilitator Notes

Encourage participants to distinguish between authorized collaboration and excessive exposure.

---

# Category 12 — Kubernetes & Containers

---

# Inject KC-01 — Privileged Container

## Objective

Assess container security governance.

### Scenario

Runtime monitoring identifies a privileged container executing in production.

### Discussion

* Expected administrative workload?
* Misconfiguration?
* Compromise?

---

# Inject KC-02 — Kubernetes Secret Access

## Objective

Exercise secret management.

### Scenario

An application service account retrieves multiple Kubernetes Secrets unrelated to its normal workload.

### Discussion

* Misconfigured permissions?
* Credential harvesting?
* Application defect?

---

# Inject KC-03 — Image Registry Alert

## Objective

Evaluate software supply chain controls.

### Scenario

A production deployment references a container image that is not present in the organization's approved registry.

---

# Category 13 — DevSecOps & CI/CD

---

# Inject DV-01 — Build Pipeline Modification

## Objective

Exercise pipeline governance.

### Scenario

Source control identifies an unauthorized modification to a production deployment pipeline.

### Discussion

* Change approval?
* Credential compromise?
* Build integrity?

---

# Inject DV-02 — Secret Found in Repository

## Objective

Evaluate secure development practices.

### Scenario

Automated scanning identifies a production API key committed to source control.

### Discussion

* Immediate key rotation?
* Repository history?
* Exposure assessment?

---

# Inject DV-03 — Build Server Authentication

## Objective

Assess CI/CD monitoring.

### Scenario

A build server authenticates to production systems outside normal deployment windows.

---

# Category 14 — APIs & Integration

---

# Inject API-01 — Unexpected API Usage

## Objective

Evaluate API monitoring.

### Scenario

An external client begins invoking privileged APIs at ten times the normal transaction volume.

### Discussion

* Denial-of-service?
* Credential misuse?
* Legitimate business activity?

---

# Inject API-02 — API Token Leak

## Objective

Assess credential management.

### Scenario

Threat intelligence reports an organization-owned API token appearing in a public repository.

### Discussion

Participants should discuss:

* Token rotation
* Dependency analysis
* Impact assessment

---

# Category 15 — Supply Chain

---

# Inject SC-01 — Vendor Security Notification

## Objective

Exercise third-party incident management.

### Scenario

A strategic supplier reports unauthorized access to its support environment.

### Discussion

* Shared services affected?
* Vendor access suspension?
* Executive notification?

---

# Inject SC-02 — Managed Service Provider Incident

## Objective

Assess dependency management.

### Scenario

The organization's managed security service provider reports service degradation following a security event.

### Discussion

* Alternate monitoring?
* Internal capabilities?
* Escalation?

---

# Inject SC-03 — Compromised Software Update

## Objective

Exercise software supply chain governance.

### Scenario

Threat intelligence identifies malicious code embedded in a recently installed software update.

### Discussion

* Immediate rollback?
* System inventory?
* Vendor coordination?

---

# Inject SC-04 — Open-Source Dependency

## Objective

Evaluate software composition management.

### Scenario

A widely used open-source library receives a critical security advisory.

### Discussion

* Affected applications?
* Temporary mitigation?
* Patch prioritization?

---

# Optional Advanced Inject — AI Service Misuse

## Objective

Exercise governance around emerging technologies.

### Scenario

Employees begin uploading confidential documents into an external generative AI service that has not been approved by the organization.

### Discussion

* Policy enforcement
* Data protection
* User education
* Approved alternatives

---

# Facilitator Guidance

Cloud incidents often create uncertainty because responsibilities are shared across multiple organizations.

Participants should distinguish between:

* customer responsibilities,
* cloud provider responsibilities,
* SaaS provider responsibilities,
* managed service responsibilities,
* contractual obligations.

Avoid encouraging assumptions that cloud providers automatically resolve security incidents on behalf of customers.

---

# Escalation Path Example

```text id="cloud-chain"
Cloud Login
      │
      ▼
IAM Changes
      │
      ▼
Storage Access
      │
      ▼
API Activity
      │
      ▼
CI/CD Pipeline
      │
      ▼
Vendor Notification
```

This progression demonstrates how seemingly independent cloud events may represent a single coordinated attack.

---

# Discussion Prompts

### Cloud Operations

* Which cloud logs are available?
* Who owns this subscription?
* Are break-glass accounts documented?

---

### Identity

* Has federation been affected?
* Should privileged credentials be rotated?
* Are service principals impacted?

---

### DevSecOps

* Can pipeline integrity be verified?
* Should deployments pause?
* How are secrets managed?

---

### Vendor Management

* Which suppliers require notification?
* Which contractual obligations apply?
* How should evidence be shared?

---

# Difficulty Scaling

| Level  | Example Adaptation                                                                                                                           |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **L1** | Single cloud account misconfiguration with clear ownership.                                                                                  |
| **L2** | Multiple cloud services requiring coordination across teams.                                                                                 |
| **L3** | Combined SaaS compromise, API abuse, and third-party dependency.                                                                             |
| **L4** | Simultaneous cloud identity compromise, software supply chain attack, and managed service provider outage affecting multiple business units. |

---

# Design Principles

Cloud and supply chain scenarios should emphasize governance, visibility, and shared responsibility rather than platform-specific technical details. The objective is to evaluate how effectively participants coordinate across internal teams and external partners when organizational boundaries become blurred.

Well-designed cloud injects encourage participants to ask not only *"What happened?"* but also *"Who owns this responsibility?"*, *"Which evidence is available?"*, and *"How do we coordinate recovery across multiple providers?"*

This concludes **Part 3 – Cloud, SaaS & Supply Chain Incidents** of the Facilitator's Inject Cookbook.

The next section escalates the exercise into enterprise crisis conditions with ransomware, confirmed data exfiltration, operational disruption, executive decision-making, and business continuity challenges that require coordinated action across the entire organization.
