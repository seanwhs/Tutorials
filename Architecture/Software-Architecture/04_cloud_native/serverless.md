# Serverless (Function-as-a-Service)

Serverless architecture is the ultimate abstraction of infrastructure. It allows developers to deploy code as independent **functions** that execute in ephemeral, stateless environments managed entirely by the cloud provider.

### ⚡ Core Characteristics

* **Event-Driven Execution:** Functions only run when triggered by specific events (HTTP requests, file uploads, database changes, or cron jobs).
* **Ephemeral & Stateless:** Every execution is independent. State must be externalized to "attached resources" like Redis or S3.
* **Pay-per-Use:** Costs are tied strictly to execution time and memory usage, eliminating "idle cost."

### 🔄 Logical Flow

```text
Event Source  ----->  Trigger  ----->  Function Instance  ----->  Backing Service
(e.g., S3 Bucket)   (New File)       (Logic / Processing)         (DB / AI Model)

```

---

## ⚖ The Architectural Trade-offs

| Factor | Challenge | Modern Mitigation (2026) |
| --- | --- | --- |
| **Cold Starts** | Latency during the initial boot of a function instance. | **SnapStart** (VM Snapshots) or moving logic to **Wasm-based** edge workers. |
| **Observability** | Traditional monitoring agents can't run on ephemeral compute. | **Distributed Tracing** (OpenTelemetry) and structured cloud-native log aggregation. |
| **Vendor Lock-in** | APIs for triggers vary between AWS, Azure, and GCP. | **Serverless Framework** or **Knative** to maintain an abstraction layer. |

---

## 📂 Summary of 04_cloud_native

This directory provides the infrastructure blueprints for a scalable, self-healing system:

1. **Serverless:** For cost-effective, event-driven compute.
2. **Service Mesh:** For networking, security, and observability at scale.
3. **Micro-Frontends:** For vertical team autonomy from database to UI.

---

