# Service Level Objective (SLO) Policy

This policy defines how we measure and manage the reliability of our services. In an ecosystem of 50+ applications, we use SLOs to balance the need for **velocity** (new features) with **stability** (reliability).

## 1. The Core Metrics (SLIs)
Every service on the "Golden Path" must track the **Four Golden Signals**:
* **Latency:** Time taken to service a request.
* **Traffic:** Demand placed on the system (e.g., HTTP requests/sec).
* **Errors:** The rate of requests that fail explicitly or implicitly.
* **Saturation:** How "full" your service is (e.g., CPU/Memory utilization).

## 2. Service Tiering
Not all services require 99.99% uptime. Reliability targets are based on business impact:

| Tier | Description | Target Availability | Managed By |
| :--- | :--- | :--- | :--- |
| **Tier 0** | Critical Path (Payments, Auth, Gateway) | 99.99% | SRE + Dev |
| **Tier 1** | Core Business (Search, Checkout, Profile) | 99.9% | Dev Team |
| **Tier 2** | Internal/Supporting (Internal Tools, Admin) | 99% | Dev Team |
| **Tier 3** | Experimental/Alpha | Best Effort | Dev Team |

## 3. The Error Budget Policy
The Error Budget is `1 - SLO`. (e.g., a 99.9% SLO allows for 43 minutes of downtime per month).

* **Positive Budget:** If the budget is healthy, the team may prioritize feature velocity.
* **Exhausted Budget:** If the error budget is spent, **feature work stops.** The team must pivot 100% of resources to reliability engineering, bug fixes, and performance tuning until the budget is restored.

## 4. Reporting & Alerts
* **A-Alerts:** Triggered when the *burn rate* of the error budget indicates the SLO will be violated within 24 hours.
* **B-Alerts:** Low-priority notifications for long-term trends.
