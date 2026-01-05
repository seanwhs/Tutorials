# Blamesless Post Mortem Template

In an ecosystem of **50+ applications**, failures are inevitable. The goal of a **Post-Mortem** is not to assign blame to an individual, but to identify the systemic weaknesses in our **Enterprise Architecture** that allowed the failure to occur. This document is a "feedback loop" that strengthens the **Golden Path** for all other teams.

---

# Blameless Post-Mortem: [Incident Title]

**Date:** [YYYY-MM-DD]

**Incident Commander:** [Name]

**Severity:** (SEV-0 / SEV-1 / SEV-2)

**Services Impacted:** [e.g., Payment-v2, Checkout-v1]

---

## 1. Executive Summary

A 2-3 sentence overview of what happened, the duration of the impact, and the final resolution.

---

## 2. Impact Analysis

* **User Impact:** (e.g., "5,000 users received 500 errors during checkout.")
* **Revenue Impact:** (e.g., "Estimated $50k in lost transactions.")
* **Internal Impact:** (e.g., "On-call engineer required 4 hours to stabilize.")

---

## 3. Timeline

*Detailed log of events leading up to and during the incident.*

| Time (UTC) | Action/Event |
| --- | --- |
| **14:00** | Deployment of `payment-v2` initiated. |
| **14:05** | First 5xx errors detected by Gateway. |
| **14:10** | **Alert Triggered:** PagerDuty notifies on-call. |
| **14:15** | Incident Commander identifies DB connection exhaustion. |
| **14:30** | Rollback completed. Service stabilized. |

---

## 4. The "Five Whys" (Root Cause Analysis)

*Identify the systemic failure, not the human error.*

1. **Why was the service down?** The database connection pool was exhausted.
2. **Why was it exhausted?** The new deployment increased the connection count beyond the DB limit.
3. **Why did the limit exist?** It was a legacy setting from when we had only 10 apps.
4. **Why wasn't this caught in staging?** Staging does not mirror production traffic volume.
5. **Why don't we have automated pool management?** **(Root Cause):** Our "Golden Path" Postgres template lacks dynamic connection scaling (e.g., PgBouncer).
<img width="2840" height="3343" alt="image" src="https://github.com/user-attachments/assets/5adc4a99-e38e-4272-aeb8-c3c46adc9fcf" />

---

## 5. Corrective Actions (Preventing Recurrence)

*Categorize tasks into immediate fixes and long-term architectural improvements.*

| Task | Priority | Owner |
| --- | --- | --- |
| Update DB connection limits for `payment-v2`. | High (Done) | DBA Team |
| **EA Update:** Integrate PgBouncer into the "Golden Path" Template. | Medium | Platform Team |
| Implement "Load Shedding" in the API Gateway. | Low | Architecture |

---

## 6. Lessons Learned

* **What went well?** (e.g., "Automated rollback was fast and successful.")
* **Where did we get lucky?** (e.g., "Incident happened during a low-traffic window.")
* **What needs improvement?** (e.g., "The Runbook was missing the DB scaling command.")

---

## 7. Compliance & Archival

* [ ] Has this report been shared with the **Architecture Review Board (ARB)**?
* [ ] Have the "Corrective Actions" been turned into Jira tickets?
* [ ] Is this report linked in the **Incident Log** for future reference?

---

### Recommended Learning

**The Anatomy of a Blameless Post-Mortem**
Learn how to foster a culture of transparency and continuous improvement:
[https://www.youtube.com/watch?v=RP6P_pX06pI](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3DRP6P_pX06pI)

---

