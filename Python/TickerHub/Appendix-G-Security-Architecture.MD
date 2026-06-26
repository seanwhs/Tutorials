# APPENDIX G — SECURITY ARCHITECTURE & THREAT MODEL

# TickerHub Zero-Trust Security Reference

> *"The first assumption of security engineering is that the system is already compromised."*

---

# Purpose

This appendix defines the security architecture and threat model for TickerHub.

The goals are to:

* identify assets
* identify threat actors
* identify attack surfaces
* define trust boundaries
* establish security controls
* define incident response
* establish zero-trust principles

---

# Security Philosophy

TickerHub adopts:

```text id="sec001"
ZERO TRUST
```

Assumptions:

```text id="sec002"
Networks are compromised.

Users are compromised.

Services are compromised.

Dependencies are compromised.

Cloud providers may fail.

AI systems hallucinate.
```

---

# Security Objectives

TickerHub protects:

```text id="sec003"
Confidentiality

Integrity

Availability

Authenticity

Auditability

Non-repudiation
```

---

# Critical Assets

---

## Tier 0

### Catastrophic Loss

```text id="sec004"
Private keys

JWT signing keys

Database encryption keys

Secrets

MFA seeds
```

---

## Tier 1

### Critical Business Assets

```text id="sec005"
Orders

Trades

Portfolios

Risk models

Positions
```

---

## Tier 2

### Sensitive Assets

```text id="sec006"
User data

Research

Analytics

Workspaces

Reports
```

---

## Tier 3

### Operational Assets

```text id="sec007"
Logs

Metrics

Configuration

Dashboards
```

---

# Threat Actors

---

## External Attacker

Capabilities:

```text id="sec008"
Internet access

Credential stuffing

Bot attacks

Reconnaissance

Exploitation
```

---

## Malicious Insider

Capabilities:

```text id="sec009"
Valid credentials

System knowledge

Escalation attempts
```

---

## Compromised Developer

Capabilities:

```text id="sec010"
Repository access

CI/CD access

Infrastructure knowledge
```

---

## Supply Chain Attacker

Capabilities:

```text id="sec011"
Dependency poisoning

Container poisoning

Package compromise
```

---

## Nation State

Capabilities:

```text id="sec012"
Advanced persistent threats

Long-term infiltration

Infrastructure compromise
```

---

## Malicious AI Agent

Capabilities:

```text id="sec013"
Prompt injection

Data exfiltration

Tool abuse

Hallucination
```

---

# Trust Boundaries

---

## Boundary 1

```text id="sec014"
Internet

↓

Cloudflare
```

---

## Boundary 2

```text id="sec015"
Cloudflare

↓

API Gateway
```

---

## Boundary 3

```text id="sec016"
API Gateway

↓

Services
```

---

## Boundary 4

```text id="sec017"
Services

↓

Databases
```

---

## Boundary 5

```text id="sec018"
LLM

↓

Enterprise Data
```

---

# System Threat Model

```text id="sec019"
                     INTERNET
                          |
                    [UNTRUSTED]
                          |
                          V
                     Cloudflare
                          |
                    [BOUNDARY]
                          |
                          V
                     API Gateway
                          |
                    [BOUNDARY]
                          |
        -----------------------------------
        |              |                 |
        V              V                 V

     Services      Databases        AI Systems

        |              |                 |

        -----------------------------------
                          |
                    [CRITICAL]
```

---

# STRIDE Analysis

---

# Spoofing

---

## Threat

Attacker impersonates users.

Examples:

```text id="sec020"
JWT theft

Session hijacking

Credential theft

OAuth abuse
```

---

## Controls

```text id="sec021"
OAuth2

JWT expiration

MFA

Session rotation

Device binding
```

---

# Tampering

---

## Threat

Attackers modify data.

Examples:

```text id="sec022"
Trade modification

Order manipulation

Portfolio corruption
```

---

## Controls

```text id="sec023"
Immutable events

Checksums

Digital signatures

Audit logs
```

---

# Repudiation

---

## Threat

User denies action.

Examples:

```text id="sec024"
"I didn't place this trade."
```

---

## Controls

```text id="sec025"
Audit logs

Immutable events

Digital signatures

Trace IDs
```

---

# Information Disclosure

---

## Threat

Sensitive data leakage.

Examples:

```text id="sec026"
Portfolio theft

Research leakage

Credential exposure
```

---

## Controls

```text id="sec027"
Encryption

RBAC

ABAC

Data masking
```

---

# Denial of Service

---

## Threat

Resource exhaustion.

Examples:

```text id="sec028"
DDoS

Kafka flood

API abuse

Worker starvation
```

---

## Controls

```text id="sec029"
Cloudflare

Rate limiting

Circuit breakers

Backpressure
```

---

# Elevation of Privilege

---

## Threat

Privilege escalation.

Examples:

```text id="sec030"
JWT manipulation

RBAC bypass

Admin escalation
```

---

## Controls

```text id="sec031"
Least privilege

RBAC

ABAC

Short-lived credentials
```

---

# Authentication Architecture

---

## Flow

```text id="sec032"
User

   |

OAuth2

   |

Identity Provider

   |

JWT

   |

Panel Session
```

---

## Token Lifetime

| Token   | Duration   |
| ------- | ---------- |
| Access  | 15 minutes |
| Refresh | 7 days     |
| Session | 8 hours    |

---

## MFA

Methods:

```text id="sec033"
TOTP

Passkey

WebAuthn
```

---

# Authorization Architecture

---

## RBAC

Roles:

```text id="sec034"
Trader

Analyst

Researcher

Admin

RiskOfficer
```

---

## ABAC

Example:

```text id="sec035"
Role == Trader

AND

PortfolioOwner == User

AND

MarketOpen == TRUE
```

---

# Secret Management

---

## Secrets Never Stored In

```text id="sec036"
Git

Dockerfile

Source Code

Logs
```

---

## Secrets Stored In

```text id="sec037"
Vault

Kubernetes Secrets

Cloud Secret Managers
```

---

# Database Security

---

## Encryption

```text id="sec038"
AES-256
```

---

## Connection Security

```text id="sec039"
TLS 1.3
```

---

## Access Pattern

```text id="sec040"
Service

↓

Database Role

↓

Database
```

---

# Kafka Security

---

## Controls

```text id="sec041"
TLS

SASL

ACL

Topic isolation
```

---

## Topic Permissions

Example:

```text id="sec042"
MarketService

WRITE market-events

READ portfolio-events
```

---

# Redis Security

---

## Controls

```text id="sec043"
TLS

Authentication

Private networking
```

---

# Container Security

---

## Controls

```text id="sec044"
Read-only FS

Non-root users

Image scanning

Capability dropping
```

---

# Kubernetes Security

---

## Controls

```text id="sec045"
Namespaces

Pod security

Network policies

RBAC

Admission control
```

---

# API Security

---

## Controls

```text id="sec046"
JWT

Rate limit

Schema validation

CORS

CSRF protection
```

---

## Limits

```text id="sec047"
100 req/min
```

---

# Event Security

---

## Events Must Contain

```text id="sec048"
correlation_id

causation_id

signature

timestamp
```

---

## Event Signing

```text id="sec049"
Producer

↓

Hash

↓

Signature

↓

Kafka
```

---

# Audit Architecture

---

## Everything Is Audited

```text id="sec050"
Login

Logout

Orders

Trades

Risk

Admin

AI
```

---

## Audit Properties

```text id="sec051"
Immutable

Append-only

Versioned
```

---

# Supply Chain Security

---

## Dependency Scanning

Tools:

```text id="sec052"
Trivy

Dependabot

Snyk
```

---

## Container Scanning

```text id="sec053"
Trivy

Grype
```

---

## SBOM

```text id="sec054"
CycloneDX

SPDX
```

---

# AI Security

---

## Threats

```text id="sec055"
Prompt injection

Data leakage

Tool abuse

Hallucination

Model poisoning
```

---

## Controls

```text id="sec056"
Input validation

Output filtering

Sandboxing

RAG isolation

Human approval
```

---

# Network Security

---

## Architecture

```text id="sec057"
Internet

   |

Cloudflare

   |

DMZ

   |

API

   |

Service Mesh

   |

Database Network
```

---

# Disaster Recovery Security

---

## Backups

Must be:

```text id="sec058"
Encrypted

Immutable

Versioned

Offsite
```

---

# Incident Response

---

## Phase 1

```text id="sec059"
Detect
```

---

## Phase 2

```text id="sec060"
Contain
```

---

## Phase 3

```text id="sec061"
Eradicate
```

---

## Phase 4

```text id="sec062"
Recover
```

---

## Phase 5

```text id="sec063"
Lessons Learned
```

---

# Security Monitoring

---

## Metrics

```text id="sec064"
Failed logins

JWT failures

API abuse

Kafka failures

RBAC violations

Prompt injections
```

---

# Security Logging

Every log entry includes:

```json id="sec065"
{
  "timestamp": "...",
  "user_id": "...",
  "session_id": "...",
  "trace_id": "...",
  "action": "...",
  "result": "..."
}
```

---

# Security Principles

TickerHub security follows:

```text id="sec066"
Zero Trust

+

Defense in Depth

+

Least Privilege

+

Immutable Audit

+

Assume Breach

+

Fail Secure
```

---

# Final Principle

```text id="sec067"
The purpose of security is not
to prevent compromise.

The purpose of security is
to survive compromise.
```

And therefore:

```text id="sec068"
Every component of TickerHub
is designed under the assumption
that every other component
may already be hostile.
```
