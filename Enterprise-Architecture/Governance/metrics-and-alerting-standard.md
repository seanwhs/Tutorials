# Metrics and Alerting Standard

In an environment with **50+ applications**, "100% Uptime" is an impossible metric that leads to burnout. This standard moves the enterprise toward **SLO-based monitoring**, focusing on user impact rather than server health. We prioritize the "Four Golden Signals" to distinguish between minor glitches and critical failures.

---

## 1. The Four Golden Signals

Every service in the catalog must expose these four metrics via Prometheus/OpenTelemetry:

1. **Latency:** The time it takes to service a request. (Tracked as a distribution/percentile, e.g., p95, p99).
2. **Traffic:** The demand placed on the system (e.g., HTTP requests per second or Kafka messages per minute).
3. **Errors:** The rate of requests that fail, either explicitly (e.g., HTTP 500s) or implicitly (e.g., a "200 OK" that contains an error payload).
4. **Saturation:** How "full" your service is. (e.g., CPU usage, memory pressure, or thread pool exhaustion).

---

## 2. SLIs, SLOs, and Error Budgets

We define reliability through the lens of the user experience.

* **Service Level Indicator (SLI):** A specific metric (e.g., "HTTP 5xx error rate").
* **Service Level Objective (SLO):** The target value for an SLI (e.g., "99.9% of requests must be error-free over 30 days").
* **Error Budget:** The remaining "allowable" downtime (e.g., 0.1% or ~43 minutes per month).

> **Policy:** If a service exhausts its **Error Budget**, all feature development must stop, and the team must focus exclusively on reliability and technical debt until the budget is replenished.

---

## 3. Alerting Strategy: Reducing Pager Fatigue

Alerts should only be triggered if an action is required. We follow the **Symptom-Based Alerting** model.

| Alert Type | Threshold | Action |
| --- | --- | --- |
| **Critical (Page)** | SLO is being consumed at a rate that will exhaust the budget in < 24 hours. | Immediate On-Call response. |
| **Warning (Ticket)** | Slow burn rate. SLO will be exhausted in 1 week. | Create a Jira ticket for the next sprint. |
| **Notification** | Specific pod restart or minor latency spike. | Log event only. No human interruption. |

---

## 4. Standard Dashboard Layout

To enable cross-team support, every service dashboard in **Grafana** or **Datadog** must follow a standard layout:

* **Top Row:** SLO Status & Error Budget remaining.
* **Middle Row:** The Four Golden Signals (Latency, Traffic, Errors, Saturation).
* **Bottom Row:** Infrastructure Health (Pod restarts, DB connections, Disk I/O).

---

## 5. Alerting Anti-Patterns (What to Avoid)

* **Alerting on CPU:** Do not page someone for 90% CPU usage if Latency and Errors are normal. This is "Saturation," not a failure.
* **Alerting on Averages:** Always use **Percentiles (p99)**. Averages hide the "long tail" of users experiencing 10-second wait times.
* **Email Alerts:** High-priority alerts must go to a centralized paging system (PagerDuty/OpsGenie). Email is for reports, not emergencies.

---

## 6. Compliance Checklist

* [ ] Are the Four Golden Signals exposed via `/metrics` or OTLP?
* [ ] Is an **SLO** defined and visible on the service dashboard?
* [ ] Is the **Error Budget** calculated automatically by the monitoring tool?
* [ ] Are alerts routed to the correct on-call rotation defined in the **Service Catalog**?
* [ ] Does the alert description include a link to the **Service Runbook**?

---

### Recommended Learning

**Google SRE: Monitoring Distributed Systems**
The foundational philosophy behind the Four Golden Signals and SLOs:
[https://www.youtube.com/watch?v=uITOZ7S3_N4](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3DuITOZ7S3_N4)

---

