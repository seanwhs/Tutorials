# Service Mesh Policy

In a 50+ application ecosystem, the network is fundamentally unreliable. Rather than hard-coding retry logic and timeout constants into every service, we offload **Traffic Resilience** to the **Service Mesh (Istio/Linkerd)**. This ensures a consistent operational posture across all languages and frameworks (Java, Go, Python).

---

## 1. The Sidecar Architecture

Every service pod includes a transparent proxy (Sidecar). All "East-West" traffic (service-to-service) is intercepted by this proxy, which applies our global traffic policies without the application being aware.

---

## 2. Resilience Policies

### A. Automated Retries

To handle transient network glitches or pod restarts, the mesh automatically retries failed requests.

* **Standard:** Max 3 retries with exponential backoff.
* **Condition:** Only retry on **Idempotent** methods (GET, PUT, DELETE) or specific status codes (503, 504).
* **Precaution:** Never retry a POST request unless the service is verified as idempotent.

### B. Timeout Management

Every service-to-service call must have a defined timeout to prevent "Thread Exhaustion."

* **Global Default:** 5 seconds.
* **Service-Specific:** Can be overridden in the `VirtualService` configuration based on the SLO of the target.

### C. Outlier Detection (Passive Circuit Breaking)

If a specific pod of a service begins returning errors (e.g., 5xx), the mesh will "eject" that pod from the load-balancing pool for a set duration (e.g., 30 seconds).

---

## 3. Traffic Shifting & Routing

The Service Mesh is the primary engine for our **Zero-Downtime Deployment** strategy.

* **Canary Routing:** Use `VirtualService` weights to send 5% of traffic to a new version based on headers (e.g., `user-group: beta`) or simple percentage.
* **Mirroring (Dark Launching):** Send a copy of live traffic to a new version of a service without affecting the response sent to the user. This allows for testing performance under real load.

---

## 4. Fault Injection (Chaos Engineering)

To verify our **Disaster Recovery** and **Resiliency** patterns, we use the mesh to inject artificial failures.

* **Abort:** Force a percentage of requests to return a `403` or `500` error.
* **Delay:** Add artificial latency (e.g., 2 seconds) to requests to ensure the calling service's timeouts work as expected.

---

## 5. Security: Mutual TLS (mTLS)

The mesh automatically encrypts all traffic between services.

* **Identity:** Each pod is issued an X.509 certificate.
* **Policy:** `STRICT` mode is enforced. Any request not using mTLS is rejected, preventing "Man-in-the-Middle" attacks within the cluster.

---

## 6. Compliance Checklist

* [ ] Is the service injected with a mesh sidecar?
* [ ] Are retries limited to idempotent operations?
* [ ] Is the `timeout` value aligned with the downstream service's SLO?
* [ ] Has the service been tested against **Delay Fault Injection**?
* [ ] Is mTLS enabled and verified for all East-West traffic?

---

### Recommended Learning

**Istio Traffic Management Deep Dive**
Learn how to configure VirtualServices and DestinationRules for complex environments:
[https://www.youtube.com/watch?v=6zDrLv3R9pE](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3D6zDrLv3R9pE)

---

