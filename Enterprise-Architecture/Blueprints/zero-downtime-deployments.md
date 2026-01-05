# Zero Downtime Deployment

In an ecosystem of **50+ applications**, deployments happen dozens of times per day. Without a coordinated strategy, the mismatch between new application code and existing infrastructure (Databases, Proxies, and Caches) leads to intermittent failures. This guide ensures that deployments are invisible to the end user.

---

## 1. The Deployment Coordination Triangle

Zero-downtime is only achieved when three layers are synchronized:

1. **Traffic Layer:** The Service Mesh or Load Balancer gracefully shifts requests.
2. **Application Layer:** The code supports "N-1" compatibility (handling old and new logic).
3. **Data Layer:** The database schema follows the **Expand and Contract** pattern.

---

## 2. Kubernetes Rolling Updates

We utilize the **RollingUpdate** strategy as our default. This replaces pods incrementally to ensure a minimum number of pods are always available to serve traffic.

### Mandatory Configuration:

* **Readiness Probes:** Kubernetes must not send traffic to a new pod until it has finished its "warm-up" (e.g., establishing DB connections).
* **Liveness Probes:** Kubernetes must automatically restart a pod if it enters a "deadlock" state.
* **Termination Grace Period:** Pods must be given time (e.g., 30s) to finish processing existing requests before the process is killed.

---

## 3. Deployment Strategies

### A. Blue-Green Deployment

We use Blue-Green for high-risk, "Tier 0" services.

* **Mechanism:** Two identical environments exist. Traffic is flipped 100% from Blue (Old) to Green (New) at the Load Balancer level.
* **Benefit:** Instant rollback by flipping the switch back.

### B. Canary Releases

We use Canary for testing new features or high-volume services.

* **Mechanism:** A small percentage of traffic (e.g., 5%) is routed to the "Canary" version. If health metrics (Latency/Errors) remain stable, the percentage is increased.
* **Benefit:** Limits the **blast radius** of a potential bug.

---

## 4. Handling Persistent Connections

For services using **WebSockets** or long-lived **gRPC** streams:

1. **Drain Mode:** When a pod is marked for termination, it must stop accepting new connections but keep existing ones open.
2. **Maximum Connection Age:** Enforce a maximum lifespan for connections to ensure they eventually re-balance to the new version of the service.

---

## 5. The Rollback Safety Net

Every deployment must be "Reversible."

* **Automated Rollbacks:** If the "Four Golden Signals" (Errors/Latency) spike beyond a threshold during a Canary or Rolling update, the CI/CD pipeline (ArgoCD/Flux) must automatically revert to the previous stable version.
* **No-Go Zone:** If a database "Contract" phase (dropping a column) has already occurred, an automated code rollback is impossible. Therefore, the **Contract Phase** must always happen 24+ hours *after* a successful code deployment.

---

## 6. Compliance Checklist

* [ ] Have **Readiness** and **Liveness** probes been verified?
* [ ] Is the database migration currently in the **Expand** or **Migrate** phase? (Not Contract).
* [ ] Does the deployment pipeline include an automated **Smoke Test** in the new environment?
* [ ] Is the **Error Budget** sufficient to allow for a potential minor disruption?

---

### Recommended Learning

**Continuous Delivery and Deployment Patterns**
A deep dive into Canary, Blue-Green, and A/B testing:
[https://www.youtube.com/watch?v=skS957v2U80](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3DskS957v2U80)

---

