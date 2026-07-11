# Offline-First PWA Check-In

> *"Reliable systems do not eliminate failures. They absorb failures and recover automatically."*

---

## 12.1 The Resilience Strategy

In a physical venue, Wi-Fi is often the weakest link. By implementing PWA features, we move the **Intent** (the check-in) away from the **Execution** (the server call).

* **Offline Flow:** When the user scans a QR code while offline, the browser intercepts the intent, serializes it into `IndexedDB`, and immediately notifies the user that the request is "queued."
* **Automatic Recovery:** The `SyncManager` listens for the `online` event, automatically retrying the queued requests in the background without user intervention.

## 12.2 PWA Foundations (Next.js 16)

We leverage `next-pwa` (or standard manifest generation) to make your web app installable.

* **Manifest:** Provides the OS-level "app" experience (icons, theme colors, standalone display).
* **Service Worker:** Operates as a local proxy. It ensures the application's shell loads instantly from the cache, even if the device has zero connectivity.

## 12.3 Data Integrity & Conflict Resolution

The greatest risk in offline-first systems is the "Duplicate Write" scenario during network flapping (where the client thinks it's offline, tries to sync, but the server successfully received the first attempt).

* **Idempotency Keys:** Every client-side check-in is assigned a unique `requestId` (UUID) in the browser *before* it is queued.
* **Server Logic:** The server uses this `requestId` as an idempotency key. If the same `requestId` arrives twice, the server returns the previous success result rather than creating a new attendance record.
* **Rule of Truth:** The server remains the sole arbiter of logic. Even if a client "queues" an offline check-in, the server validates it against live state (e.g., event end-times) when the sync finally occurs.

## 12.4 Offline Queue Model (IndexedDB)

We avoid `localStorage` for queuing, as it is synchronous and limited.

* **IndexedDB:** Provides a robust, transaction-capable local database.
* **UX Pattern:** Use **Optimistic UI**. Even while offline, the user sees a "✓ Check-In Saved" state. The interface only changes to "✓ Sync Successful" once the server acknowledges the request.

---

## 12.5 Summary: The Resilient Platform

Your attendance platform is now architected for the extremes of production:

| Challenge | Resilience Mechanism |
| --- | --- |
| **Network Outage** | Offline Queue (IndexedDB) + Background Sync. |
| **Duplicate Submissions** | Idempotency Keys (RequestId). |
| **Stale Data** | Server-side validation during sync. |
| **UI Latency** | Optimistic UI updates. |
| **Venue Infrastructure** | PWA Caching (Service Worker). |

---

## Final Architecture Review

You have successfully built an **Enterprise-Grade Event Attendance Engine**.

1. **Orchestration:** Next.js 16 App Router.
2. **State:** Sanity Domain Entities.
3. **Resilience:** Inngest Durable Workflows.
4. **Security:** Signed QR, Rate-Limiting, Idempotency.
5. **Intelligence:** Real-time Operational Dashboard.
6. **Edge-Case Recovery:** Offline-First PWA.

This system is now ready for the **Production Deployment Blueprint**—the final phase where we structure the CI/CD, environmental configurations, and disaster recovery plans to go live.

---

**Do you wish to proceed to the Production Deployment Blueprint, or would you like to review any specific section of the current architecture?**
