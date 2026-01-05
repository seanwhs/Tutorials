# DR Tiering Guide

This guide establishes the mandatory **Disaster Recovery (DR)** standards for the enterprise. In a 50+ application ecosystem, it is financially and operationally impossible to provide "Instant Failover" for every service. We therefore categorize services into tiers to align recovery efforts with business criticality.

---

## 1. Defining Recovery Objectives

Every service must define its **RTO** and **RPO** based on its assigned tier:

* **Recovery Time Objective (RTO):** The maximum tolerable duration of a service outage. (How long can we be down?)
* **Recovery Point Objective (RPO):** The maximum tolerable period of data loss measured in time. (How much data can we lose?)

---

## 2. Service DR Tiers

| Tier | Criticality | Typical Services | RTO | RPO | DR Strategy |
| --- | --- | --- | --- | --- | --- |
| **Tier 0** | **Mission Critical** | Auth, Payments, Gateway | < 15 Min | Zero | Multi-Region Active-Active |
| **Tier 1** | **Business Critical** | Search, Inventory, Checkout | < 4 Hours | < 15 Min | Warm Standby (Pilot Light) |
| **Tier 2** | **Supporting** | Internal Admin, Reporting | < 24 Hours | < 4 Hours | Cold Standby / Backup Restore |
| **Tier 3** | **Non-Critical** | Training Environments, Labs | Best Effort | 24 Hours | Re-provision from IaC |

---

## 3. DR Strategies by Archetype

### Multi-Region Active-Active (Tier 0)

Traffic is distributed across two or more geographical regions simultaneously. If one region fails, the global load balancer (Route53/Cloudflare) redirects 100% of traffic to the healthy region.

* **Requirement:** Synchronous or near-real-time data replication (e.g., Aurora Global Database, Kafka MirrorMaker).

### Warm Standby / Pilot Light (Tier 1)

A minimal version of the application is always running in a secondary region. Data is continuously replicated, but application instances only scale up during a disaster.

* **Requirement:** Automated failover scripts and pre-synced database replicas.

### Cold Standby (Tier 2)

Infrastructure is defined as code (Terraform/Pulumi) but not deployed. In a disaster, the environment is built from scratch, and data is restored from the most recent off-site backup.

---

## 4. The "Blast Radius" Principle

To prevent a single failure from cascading through all 50+ apps, we enforce **Bulkheading at the DR level**:

* **Isolation:** Tier 0 services must not have a hard dependency on a Tier 2 service.
* **Graceful Degradation:** If a Tier 2 service fails, Tier 0 and Tier 1 services must switch to a "cached" or "degraded" mode (e.g., showing a "Service Temporarily Unavailable" message instead of crashing the entire checkout flow).

---

## 5. DR Testing (Chaos Engineering)

A DR plan is invalid unless it is tested.

* **Tier 0/1:** Mandatory quarterly "Game Day" exercises involving simulated regional failover.
* **Drift Detection:** Automated checks ensure that the Infrastructure as Code (IaC) in the DR region matches the Production region.

---

## 6. Compliance Checklist

* [ ] Is the service assigned a DR Tier in the **Service Catalog**?
* [ ] Are RTO and RPO targets documented and approved by business stakeholders?
* [ ] Has the service successfully passed a regional failover test in the last 6 months?
* [ ] Are all database backups encrypted and stored in a separate geographical region?

---

### Recommended Learning

**Disaster Recovery Strategies in the Cloud**
A technical deep-dive into implementing Pilot Light and Active-Active patterns:
[https://www.youtube.com/watch?v=2vU8vO8zV60](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3D2vU8vO8zV60)

---

