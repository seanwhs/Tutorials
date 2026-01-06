# Network Connectivity Standard

In an ecosystem of **50+ applications**, the network is the "Enterprise Nervous System." We no longer rely on perimeter security; instead, we move toward a **Zero Trust** model where the network layer handles security and resiliency, allowing developers to focus on business logic.

---

## 1. Zero Trust Connectivity (mTLS)

Every communication between assets must be authenticated and encrypted, regardless of whether it is "Internal" or "External."

* **Identity over IP:** We do not trust IP addresses. Services must use **SPIFFE/Spire** or similar identity standards to prove who they are.
* **Mutual TLS (mTLS):** All East-West traffic (service-to-service) must be encrypted via mTLS, managed automatically by the Service Mesh sidecar.

---

## 2. Traffic Management & Routing

To support our **Zero-Downtime Blueprint**, the network fabric must support advanced routing:

* **Circuit Breaking:** If an asset (e.g., Service B) starts failing, the network fabric must automatically "trip" the circuit to prevent the failure from cascading to Service A.
* **Retries & Timeouts:** These are infrastructure concerns. Retries should be handled by the proxy with exponential backoff to avoid "Retry Storms."
* **Weighted Routing:** Essential for **Canary Releases**, allowing the network to shift 1%, 5%, or 100% of traffic between versions.

---

## 3. The Edge Gateway vs. Service Mesh

We distinguish between traffic entering the enterprise and traffic moving within it:

* **North-South (Edge Gateway):** Handles TLS termination, OAuth2/OIDC validation, and Rate Limiting for external consumers.
* **East-West (Service Mesh):** Handles service discovery, mTLS, and observability for the 50+ internal apps.

---

## 4. Regionality & Data Sovereignty

To comply with the **EA Lifecycle's** data residency requirements:

* **Cell-Based Routing:** The network fabric must ensure that a request for a "European User" is routed to the "European Cell" to keep PII within legal boundaries.
* **Failover Policy:** Cross-region failover is permitted for the **Scaler** archetype but must be restricted for **Defensive** assets containing sensitive data.

---

## 5. EA Lifecycle Alignment

| Phase | Connectivity Requirement |
| --- | --- |
| **Strategic Planning** | Define if the service is "Internet Facing" (North-South) or "Internal Only" (East-West). |
| **Initiative Delivery** | Configure sidecar proxies and define `ServiceEntry` resources for external dependencies. |
| **Asset Management** | Monitor network latency and circuit-breaker trip rates in the Service Mesh dashboard. |
| **Asset Harvesting** | Remove firewall rules and gateway entries to prevent "Shadow APIs" from remaining active. |

---

### Recommended Learning

**Service Mesh Patterns**
Understand how to decouple networking from application code:
[https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/intro/goals](https://www.google.com/search?q=https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/intro/goals)

---

