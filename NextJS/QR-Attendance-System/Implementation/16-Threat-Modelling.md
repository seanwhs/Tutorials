# Threat Model & Security Review

> *"A secure system is not one that has no vulnerabilities. A secure system is one where threats are understood, mitigated, monitored, and recoverable."*

---

## 1. STRIDE Threat Analysis

Applying the **STRIDE** methodology allows us to systematically address every potential vector for compromise:

| Threat | System Mitigation |
| --- | --- |
| **Spoofing** | Clerk-based OIDC identity verification; server-side user derivation. |
| **Tampering** | HMAC-signed QR tokens; Zod schema validation; repository-level constraints. |
| **Repudiation** | Comprehensive audit logging for all check-in/write events. |
| **Info Disclosure** | Data minimization (storing only `userId`, `eventId`, `timestamp`). |
| **DoS** | Multi-layer rate limiting (Vercel Firewall + Upstash Sliding Window). |
| **Elevation** | Strict RBAC (Role-Based Access Control) enforced in Server Actions. |

## 2. Core Security Boundaries

The architecture is designed with a **"Trust Nothing"** philosophy.

* **The Untrusted Zone (Internet):** All incoming data is treated as malicious until validated.
* **The Validation Pipeline:** Every request must pass a standardized funnel: `Schema Check → Auth Check → Rate Check → Domain Rule Check`.
* **Decoupled Trust:** By using Inngest, the workflow processes (Email/Analytics) are isolated from the main request loop, preventing a compromise in a third-party service from impacting the integrity of your core database (Sanity).

## 3. QR Integrity & Replay Defense

Your QR system is now shielded against the most common "physical event" attacks:

* **Tampering:** Payload integrity is cryptographically verified via HMAC signature.
* **Replay:** Tokens have a short "time-to-live" (TTL) and use a server-side `nonce` validation, ensuring that a valid QR token from 10:00 AM cannot be reused at 10:15 AM, nor intercepted and presented by a different device.

## 4. Privacy & Data Integrity

We move beyond simple compliance to **Privacy by Design**:

* **Auditability:** Every successful or failed check-in leaves an immutable trail, which is essential for forensic analysis if an event experiences a security anomaly.
* **Data Minimization:** By intentionally stripping non-essential fields (like device metadata or personal addresses) from the attendance record, you lower the impact of a potential breach.

---

## Final Security Readiness Checklist

| Category | Verification |
| --- | --- |
| **Authentication** | Are session tokens validated on every request? |
| **Integrity** | Is the QR payload signed and non-replayable? |
| **Authorization** | Is user identity derived server-side (not via client body)? |
| **Abuse** | Are rate-limits effectively blocking bot-speed submissions? |
| **Audit** | Is there a traceable log of every check-in event? |

---

# Architecture Milestone Achieved

Your "Singapore Field Operations" platform is now architected for the realities of production at scale:

1. **Resilient:** Event-driven architecture with self-healing workflows (Inngest).
2. **Hardened:** Multi-layer security including signing, rate-limiting, and idempotency.
3. **Observational:** Real-time metrics and audit logs providing total system visibility.
4. **Available:** Offline-first PWA design for unreliable venue network environments.

You have built a platform that treats security, performance, and reliability as fundamental requirements of the business logic.

---

**As this section concludes the formal threat review, we are now ready for the final frontier: Performance Engineering. Would you like to analyze the "Locust/k6" load testing strategy to ensure the system handles the 5,000-attendee rush, or are you ready to synthesize all these architectural notes into a final project summary?**
