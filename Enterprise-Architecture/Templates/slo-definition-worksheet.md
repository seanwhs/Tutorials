# SLO Definition Worksheet 

In an ecosystem of **50+ apps**, "Uptime" is a vague term. One team’s "fast" is another team’s "unacceptably slow." This worksheet forces teams to define quantitative **Service Level Objectives (SLOs)** so that you can manage the fleet based on data, not feelings.

---

## 1. Service Level Indicators (SLIs)

What specific metrics are we measuring? (Align with the **Four Golden Signals**).

| Signal | Metric (SLI) | Measurement Source |
| --- | --- | --- |
| **Availability** | % of successful (non-5xx) HTTP requests. | Load Balancer Logs |
| **Latency** | Time taken to return a response (). | Service Mesh Proxy |
| **Throughput** | Requests per second (RPS). | Prometheus / Metric Store |
| **Integrity** | % of messages processed without manual intervention. | DLQ (Dead Letter Queue) count |

---

## 2. Setting the SLO (The Target)

The SLO is the "Goal." Remember: **100% is the wrong target** because it prevents innovation.

* **Availability Target:** [e.g., 99.9%]
* **Latency Target:** [e.g., 95% of requests < 300ms]
* **Error Budget:** [e.g., 0.1% per month]. Once this budget is exhausted, the team must stop feature work and focus on reliability.

---

## 3. Graceful Degradation (The "Safety Valve")

When the service is failing or saturated, how does it protect the rest of the **50-app ecosystem**?

* **Fallback Behavior:** If the "Recommendation Engine" is slow, does the "Checkout App" show a generic "Featured Items" list instead of crashing?
* **Circuit Breaker Threshold:** At what error rate does the service stop accepting traffic to prevent cascading failure?

---

## 4. Business Impact & Criticality

* **If this service is down, who loses money?** [e.g., External customers cannot complete checkout].
* **User Pain Point:** At what latency does the user experience become "unusable"? [e.g., > 2 seconds].

---

## 5. EA Lifecycle Accountability

| Phase | SLO Responsibility |
| --- | --- |
| **Initiative Delivery** | Define the SLIs and set the "Initial" SLOs in the dashboard. |
| **Asset Management** | Review SLO attainment during the **QAR**. If the Error Budget is consistently hit, trigger a "Refactor" initiative. |
| **Asset Harvesting** | As an asset is harvested, its SLOs are retired from the global dashboard. |

---

### Final Implementation Checklist

1. **Strategize** (Scenario/Archetype)
2. **Design** (HLSO/Blueprints)
3. **Deploy** (IaC/Golden Path)
4. **Secure** (Zero Trust/mTLS)
5. **Measure** (SLOs/Golden Signals)
6. **Review** (QARs/Tough Questions)
7. **Prune** (Harvesting/Modernization)

