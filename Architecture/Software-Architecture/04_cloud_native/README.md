# Part IV — Cloud-Native Execution Models

Cloud-native architecture is a shift from "managing servers" to **"managing intent."** By offloading networking, scaling, and execution concerns to the infrastructure layer, developers can focus exclusively on business logic.

---

## 1. Serverless / FaaS (Function as a Service)

Serverless allows you to execute code in response to events without provisioning or managing servers. It is the ultimate expression of **Factor 9 (Disposability)**.

* **Best for:** Spiky workloads, event-driven processing (e.g., image resizing, webhooks), and AI model inference.
* **2026 Shift:** "Cold starts" are largely mitigated by "Pre-warmed" snapshots or WASM-based runtimes.
* **Trade-off:** Loss of fine-grained control over the runtime environment and potential vendor lock-in.

---

## 2. Service Mesh (Istio, Linkerd)

As microservice counts grow, the "network" between them becomes a liability. A Service Mesh moves communication logic into a **Sidecar Proxy**, decoupling networking from application code.

### Key Capabilities:

* **Zero-Trust Security:** Automatic mTLS (Mutual TLS) between all services.
* **Traffic Shaping:** Canary deployments, Blue/Green switches, and A/B testing without code changes.
* **Observability:** Automatic generation of "Golden Signals" (Latency, Errors, Traffic, Saturation).
* **Resilience:** Centralized management of retries, timeouts, and circuit breakers.

---

## 3. Micro-Frontends

Extending microservice boundaries to the browser. Instead of a single monolithic frontend, the UI is composed of independent, domain-owned fragments.

### Composition Patterns:

* **Build-time:** npm packages (Tight coupling, slow).
* **Run-time:** Module Federation or Web Components (Flexible, independent deploys).
* **Server-side:** Edge-side includes (Fastest initial load).

---

## 🔄 Execution Logic Flow

```text
User Request
     |
[ API Gateway / Load Balancer ]
     |
[ Service Mesh Control Plane ] <--- (Auth, Routing, Rate Limiting)
     |
     +-------> [ Microservice A ] (Long-running Container)
     |               |
     +-------> [ Microservice B ] (Serverless Function)
     |
[ Micro-Frontend Fragment ] <--- (Injected via Module Federation)

```

---

## ⚠ Architectural Decision: When to Mesh?

| Scale | Recommendation |
| --- | --- |
| **< 10 Services** | Avoid Service Mesh; use simple internal Load Balancers. |
| **10 - 50 Services** | Evaluate Linkerd for low-overhead mTLS and observability. |
| **50+ Services** | Istio or Cilium become mandatory for governance and security. |

---

### 📂 Directory Contents

* `/serverless-webhooks`: AWS Lambda / Google Cloud Function example using local emulation.
* `/istio-configuration`: Manifests for mTLS, Canary releases, and VirtualServices.
* `/micro-frontend-federation`: A Webpack 5 / Vite "Module Federation" demo.

