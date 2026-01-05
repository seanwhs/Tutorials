# Service Runbook Template 

In an ecosystem of **50+ applications**, an on-call engineer cannot be an expert in every service. When a **Critical Alert** triggers at 3:00 AM, the **Service Runbook** is the most important document in the repository. It provides the "SOP" (Standard Operating Procedure) to restore service as quickly as possible.

---

# Service Runbook: [Service Name]

**Service ID:** `payment-v2`

**Criticality:** Tier 0 (Mission Critical)

**Primary Owner:** [Team Name / Slack Channel]

**Dashboard Link:** [Link to Grafana/Datadog]

---

## 1. Service Overview

* **What does this service do?** (e.g., "Processes credit card transactions via Stripe.")
* **Upstream Consumers:** (Who calls us? e.g., Web-Checkout, Mobile-App)
* **Downstream Dependencies:** (Who do we call? e.g., SQL-DB, Kafka, Stripe API)

---

## 2. Alert Response Procedures

*Link to specific alerts and the immediate action required.*

| Alert Name | Possible Cause | Troubleshooting Steps |
| --- | --- | --- |
| **High Error Rate (5xx)** | DB Connection Exhaustion | Check DB saturation metrics; scale up replicas. |
| **P99 Latency Spike** | Downstream Latency (Stripe) | Check Stripe Status page; toggle "Circuit Breaker" to fail fast. |
| **Kafka Consumer Lag** | Message Processing Hang | Check for "Poison Pill" messages in logs via `trace_id`. |

---

## 3. Diagnostic Commands

*Standard CLI snippets to investigate the health of the service.*

* **View Logs:** `kubectl logs -l app=payment-v2 --tail=100 -f`
* **Check Pod Status:** `kubectl get pods -l app=payment-v2`
* **Check DB Connectivity:** `kubectl exec [pod-name] -- nc -zv postgres-host 5432`

---

## 4. Remediation Actions (The "Panic" Buttons)

*Clear instructions on how to restore service.*

### A. Scaling the Service

If traffic is exceeding capacity:

```bash
kubectl scale deployment payment-v2 --replicas=10

```

### B. Rolling Back a Deployment

If a recent change caused the failure:

```bash
kubectl rollout undo deployment/payment-v2

```

### C. Clearing a Dead Letter Queue (DLQ)

If a specific message is blocking the Kafka partition:
*(Insert link to the "DLQ Management Tool" or specific CLI command)*

---

## 5. Escalation Path

If service is not restored within **30 minutes**:

1. **Notify Leadership:** Post to `#incident-management` Slack channel.
2. **Internal Stakeholders:** Notify the [Customer Support] team.
3. **Third-Party Support:** Open a ticket with [Vendor Name, e.g., AWS Support].

---

## 6. Post-Mortem Requirement

Every **Tier 0 or Tier 1** incident requires a formal **Blameless Post-Mortem** within 48 hours of resolution.

* **Goal:** Identify the root cause and update the "Governance" patterns to prevent recurrence.
* **Template Link:** [Link to Post-Mortem Template]

---

## 7. Compliance Checklist

* [ ] Is the Runbook linked in the **Alert Description**?
* [ ] Are all dashboard links verified and working?
* [ ] Are the scaling and rollback commands tested for this specific service?
* [ ] Is the escalation contact list up to date?

---

### Recommended Learning

**Incident Response and the Blameless Post-Mortem**
How to build a culture of learning from failures in large-scale systems:
[https://www.youtube.com/watch?v=P_VpS_GUE9U](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3DP_VpS_GUE9U)

---

**Next high-value step:** Would you like me to draft a **"Post-Mortem Template"**? This would ensure that when failures do happen, the "lessons learned" are systematically fed back into your **Enterprise Architecture** to make the other 50+ apps more resilient.
