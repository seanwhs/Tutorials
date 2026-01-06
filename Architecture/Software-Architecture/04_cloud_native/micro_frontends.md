# Micro-Frontends (Vertical Slice Architecture)

Micro-frontends extend the philosophy of microservices to the browser. Instead of a "Frontend Monolith" that requires a full rebuild for every change, the UI is decomposed into semi-autonomous fragments composed at runtime.

### 🎯 Core Objectives

* **Independent Deployments:** The "Cart" team can push a hotfix without triggering a build for the "Search" or "Profile" modules.
* **Vertical Ownership:** Aligns perfectly with **Domain-Driven Design (DDD)**. A single team owns the feature from the database to the CSS.
* **Incremental Modernization:** Allows you to "strangle" a legacy monolith by injecting new React components into an old JSP or PHP shell.

### 🏗 Composition Strategy

The most common 2026 standard for micro-frontends is **Module Federation**, which allows separate builds to share code and resources at runtime without the overhead of iframes.

```text
            [ HOST SHELL ] (Shared Router / Auth / Global State)
           /              |               \
   [ Header ]        [ Checkout ]       [ Inventory ]
   (Next.js)          (React)            (Vue/Svelte)
       |                  |                   |
   Service A <----->  Service B <----->   Service C

```

---

## ⚡ Serverless & FaaS

In a cloud-native execution model, we treat compute as a commodity.

* **Zero-Scale:** Functions only exist when triggered, eliminating "idle cost."
* **Event-Driven:** Ideal for processing background tasks like AI embeddings, image optimization, or webhook handling.

---

## 🛡 Service Mesh (Istio / Linkerd)

As your micro-frontend fragments and backend services multiply, the network becomes the bottleneck. A **Service Mesh** offloads communication concerns to a dedicated infrastructure layer.

* **Security:** Automatic mTLS (Mutual TLS) between all services.
* **Traffic Control:** Canary releases and A/B testing via the infrastructure layer, not the application code.
* **Resilience:** Centralized retries and circuit breakers for every network hop.

---

## 📂 Directory Contents

* `/serverless-functions`: Examples of AWS Lambda/Vercel functions with local emulation.
* `/module-federation-shell`: A Webpack 5/Vite "Host" app example.
* `/istio-networking`: Kubernetes manifests for Canary traffic shifting.

---

## 🚀 Architectural Decision Matrix

| Metric | Monolithic Frontend | Micro-Frontend |
| --- | --- | --- |
| **Team Size** | 1-2 Teams | 3+ Autonomous Teams |
| **Code Sharing** | Simple (Local) | Complex (Module Federation) |
| **Deployment** | All-or-Nothing | Independent / Gradual |
| **Performance** | Optimized (One Bundle) | Risk of "Payload Bloat" |

---

