This documentation completes the Security Hardening Layer. By implementing these controls, you move from a functional application to a production-grade system that actively defends against tampering, automated abuse, and concurrency issues.

---

# Documentation: Security Hardening Layer

> *"Security is not about preventing every request. It is about ensuring that every request proves it deserves to succeed."*

---

## 10.1 The Hardened Pipeline

Every incoming request must traverse the security boundary before touching your core business services. This is structured as a series of **Gatekeepers**:

1. **Identity:** Clerk authentication.
2. **Integrity:** Signed QR token validation.
3. **Throttling:** Redis-based rate limiting (preventing DoS/Spam).
4. **Spatial:** Optional Geofence radius validation.
5. **Concurrency:** Idempotency checks to prevent duplicate state.

---

## 10.2 QR Token Security (Tamper Proofing)

Instead of a static URL, the QR code contains an HMAC-signed payload.

* **The Problem:** Static links can be screenshotted and shared.
* **The Solution:** You sign the `eventId` and `expiresAt` with a server-side secret (`SANITY_API_TOKEN`).
* **Result:** Even if an attacker tries to change the `eventId` in the QR, the signature validation will fail. If they try to reuse the code later, the `expiresAt` timestamp will trigger a rejection.

---

## 10.3 Concurrency & Idempotency

Distributed systems are prone to "double-click" issues where a single user sends two requests simultaneously due to network lag or UI state latency.

* **Implementation:** Before creating an attendance record, we use Redis to set a "processing" flag for that specific `eventId` + `userId` pair.
* **Constraint:** If another request arrives for the same user/event before the flag expires, it is rejected immediately. This guarantees the **One User + One Event = One Record** business rule.

---

## 10.4 Rate Limiting (Abuse Prevention)

Public-facing check-in pages are targets for automated abuse.

* **Strategy:** We use `Upstash/Ratelimit` to track attempts per `userId`.
* **Why:** By limiting by `userId` rather than `IP Address`, you ensure that users behind large office or university firewalls (who all share one external IP) are not incorrectly blocked, while still preventing a single malicious account from brute-forcing the check-in endpoint.

---

## 10.5 Geofencing (Spatial Validation)

While geofencing is an "Additional Signal" and not a replacement for authentication, it adds a critical layer of friction for malicious actors.

* **Distance Calculation:** We implement the **Haversine formula** to calculate the distance between the user’s reported coordinates and the venue's stored coordinates.
* **Business Impact:** This prevents remote users from "checking in" to a physical conference session they aren't physically present at.

---

## 10.6 Defensive Input Validation (Zod)

Never trust user-provided input.

* **Strategy:** Every Server Action or API route begins with a `Zod` schema definition. If the payload is malformed (e.g., missing fields or incorrect types), the system throws a validation error before the domain layer is even invoked.
* **Security Mindset:** Treat everything as untrusted—URLs, headers, cookies, and especially QR payloads.

---

## Summary of the Security Boundary

Your architecture now provides multi-layered protection:

| Layer | Threat Mitigated |
| --- | --- |
| **QR Signing** | Tampering and reuse of check-in links. |
| **Rate Limiting** | Bot-driven brute force and endpoint flooding. |
| **Idempotency** | Duplicate records from network retries. |
| **Geofencing** | Remote "spoofed" check-ins. |
| **Zod Validation** | Injection and malformed request attacks. |

---

## Next: Real-Time Attendance Dashboard

The architecture is now fully secured. The final layer focuses on operational visibility: **Real-Time Attendance Monitoring**. You will implement:

* **Live Metrics:** Real-time event counter updates.
* **Operational Visibility:** Providing organizers with a live view of the conference check-in status.
* **Real-time Patterns:** Utilizing Pusher or similar pub/sub patterns to push updates to the organizer's dashboard as soon as the `attendance.checked_in` event is processed.

This completes the platform, turning it into a truly **proactive** system.
