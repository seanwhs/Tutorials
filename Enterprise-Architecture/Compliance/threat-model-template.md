# Threat Modeling Template

**Version:** 1.0  
**Status:** Mandatory for Tier 0 & Tier 1 Services

This document must be completed during the **Design Phase** of any new service or major architectural change. It follows the **STRIDE** methodology.

## 1. System Overview
* **Service Name:**
* **Data Sensitivity:** (Public / Internal / Restricted / Highly Restricted)
* **Primary Actors:** (Users, Admins, External APIs, Cron Jobs)

## 2. Data Flow Diagram (DFD)
*Attach or link a diagram showing:*
1.  Trust boundaries (e.g., Public Internet vs. VPC).
2.  Entry and Exit points.
3.  Data persistence layers.

## 3. STRIDE Threat Analysis

| Threat Category | Potential Attack Vector | Mitigation Strategy |
| :--- | :--- | :--- |
| **S**poofing | Identity theft, illegal access | OIDC/JWT Validation, mTLS |
| **T**ampering | Modifying data in transit/rest | TLS 1.3, Database Encryption, HMAC |
| **R**epudiation | Denying an action took place | Audit Logging (Immutable logs) |
| **I**nformation Disclosure | Data leaks, exposed secrets | Secrets Management (Vault), RBAC |
| **D**enial of Service | Flooding, resource exhaustion | Rate Limiting, Circuit Breakers |
| **E**levation of Privilege | Normal user gaining admin rights | OPA Policy, Least Privilege Access |

## 4. Security Checklist
- [ ] Are secrets excluded from source code and environment variables?
- [ ] Is all PII encrypted at rest?
- [ ] Does the service use the centralized IAM for all authorization?
- [ ] Is the "Database per Service" principle enforced to prevent lateral movement?

## 5. Residual Risk
*Identify any known risks that are being accepted for this release and why.*
