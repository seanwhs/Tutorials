# Real-Time Attendance Dashboard

> *"The same event that records attendance should also power operational intelligence. Observability should be a natural consequence of good architecture, not an afterthought."*

---

## 11.1 The Operational Loop

The dashboard is not an isolated feature; it is a consumer of the existing event-driven architecture. By hooking into the `attendance.checked_in` event, we create a **Live Pipeline**:

* **Source:** The `Inngest` workflow that already processes emails and analytics.
* **Sink:** A `RealtimePublisher` (e.g., Pusher) that pushes updates directly to the Organizer's screen.

---

## 11.2 Metrics vs. Reality

To keep the dashboard fast, we strictly separate **Metrics** (Aggregates) from **Attendance Records** (Transactional data).

* **Small Events:** Using Sanity’s `count()` is perfectly acceptable and performant.
* **Large Events:** For massive conferences (e.g., 50,000+ attendees), querying the database for a count is an anti-pattern. Here, we transition to an **Aggregate Model**, where Inngest increments a Redis-based counter (`attendance_counter`) on every check-in event.

---

## 11.3 Real-Time Infrastructure (Abstraction)

The dashboard uses the **Adapter Pattern** for real-time broadcasting. By defining a `RealtimePublisher` interface, the system is agnostic to the underlying technology:

* **Today:** You might use Pusher.
* **Tomorrow:** You might switch to AWS AppSync, Ably, or Socket.IO.
* **Application Impact:** Because the `attendanceWorkflow` only interacts with the `RealtimePublisher` interface, you can swap the technology stack without changing a single line of business logic.

---

## 11.4 Scaling & Performance

### Polling vs. Push

While `useEffect` polling is simple for development, it does not scale to thousands of users. We implement the **Push-to-Client** pattern:

1. Inngest completes the `record-analytics` step.
2. Inngest hits the `broadcast-attendance` step.
3. The `RealtimePublisher` pushes the update over a WebSocket.
4. The dashboard component listens for the event and performs an atomic state update.

---

## 11.5 Operational Monitoring

A production-grade dashboard provides **Event Health** metrics, not just attendance counts. Organizers need to see:

* **System Health:** Workflow success rates and average check-in latency (ms).
* **Flow Health:** Expected vs. Current attendance and arrival rates (attendees/min).
* **Error Visibility:** Number of failed notifications or stuck workflows, allowing organizers to take manual action if a specific attendee doesn't receive their confirmation.

---

## Summary of the Production Platform

The platform is now a cohesive, multi-layered system:

| Layer | Purpose |
| --- | --- |
| **Domain** | Rules and Invariants. |
| **Infrustructure** | Persistence (Sanity) and Background Work (Inngest). |
| **Security** | Hardened boundary (QR, Rate-Limit, Idempotency). |
| **Dashoard** | Operational Intelligence (Push-based metrics). |

---

## Next: Offline-First PWA Check-In

The final layer of resilience. Event venues are notorious for "dead zones" and poor Wi-Fi. We will implement **Offline-First PWA** capabilities:

* **Service Workers:** Ensuring the check-in app loads even when the network is down.
* **Offline Queue:** Storing check-ins in `IndexedDB` when offline.
* **Sync Manager:** Automatically pushing queued check-ins to the server the moment connectivity is restored.

This ensures that your door-entry system never fails, regardless of venue infrastructure.
