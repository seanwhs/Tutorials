# Service Mesh (Infrastructure-Layer Communication)

As microservices multiply, managing the network between them becomes a liability. A **Service Mesh** moves networking, security, and reliability logic out of the application code and into a dedicated infrastructure layer.

### ⚙️ How it Works: The Sidecar Pattern

Instead of your application code handling retries or encryption, every service is paired with a lightweight **Sidecar Proxy** (e.g., Envoy). All inbound and outbound traffic is intercepted by this proxy.

```text
[ Service A ] <-> [ Sidecar A ] <----( Network )----> [ Sidecar B ] <-> [ Service B ]
      |                 |                                   |                 |
      +--- Logic Only --+                                   +--- Logic Only --+

```

### 🛡️ Key Capabilities

* **Zero-Trust Security (mTLS):** The mesh automatically encrypts traffic between services and verifies identities using mutual TLS, regardless of the underlying network's security.
* **Resilience via Proxy:** Retries, timeouts, and **Circuit Breaking** are handled by the sidecar. Your service code remains "lean" and focused on business logic.
* **Traffic Shaping:** Allows for advanced deployment strategies like **Canary Releases** (shifting 5% of traffic to a new version) or **Shadow Traffic** (mirroring production traffic to a test service).
* **Observability:** Provides "Golden Signals" (latency, error rates, and throughput) across the entire cluster without requiring developers to instrument every service manually.

---

## 📂 Summary of 04_cloud_native

This directory demonstrates how to offload operational complexity:

1. **Serverless:** Ephemeral, event-driven compute to minimize "idle" costs.
2. **Service Mesh:** Decoupling networking and security from business logic.
3. **Micro-Frontends:** Enabling vertical team autonomy from database to UI.

---

