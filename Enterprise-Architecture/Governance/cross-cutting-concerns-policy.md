# Cross Cutting Concerns Policy

In an organization with **50+ applications**, teams often fall into the trap of creating a "Global Common Library" that eventually becomes a monolithic dependency. When this library is updated, all 50+ apps must be redeployed, creating an enterprise-wide bottleneck. This policy defines a **Decoupled Cross-Cutting Strategy** to prevent "Shared Library Hell."

---

## 1. The Strategy: Sidecar vs. Library

We categorize cross-cutting concerns into two buckets: **Infrastructure Concerns** (managed by the platform) and **Domain Concerns** (managed by code).

### A. Infrastructure Concerns (Sidecar/Mesh)

These should **never** be in your application code. They are handled by the **Service Mesh (Istio/Linkerd)** or **API Gateway**.

* **Retries & Timeouts:** Managed at the network layer.
* **Circuit Breaking:** Offloaded to the sidecar proxy.
* **mTLS / Encryption:** Handled by the mesh.
* **Rate Limiting:** Managed at the Gateway.

### B. Domain Concerns (Shared Libraries)

Only code that requires **Internal Language Context** should live in a library.

* **Enterprise Logging Format:** Standardized JSON structures for log aggregation.
* **Custom Identity Decorators:** Mapping JWT claims to internal user objects.
* **Standardized Error Wrappers:** Ensuring consistent `4xx` and `5xx` payloads.

---

## 2. Shared Library Rules (The "Rule of Three")

To prevent the proliferation of fragile shared libraries, we enforce the following:

1. **The Rule of Three:** Do not move code into a shared library until it is needed by at least **three** different services.
2. **Language Specificity:** Shared libraries must be language-specific (e.g., `enterprise-auth-go`, `enterprise-auth-java`). Never attempt to build a cross-language "universal" binary.
3. **Zero Transitive Dependencies:** A shared library must not depend on other shared libraries. It should be a "Leaf" in the dependency tree.
4. **No Business Logic:** If the code performs a business calculation (e.g., "Calculate Tax"), it should be a **Service**, not a library.

---

## 3. Implementation Patterns

### Standardized Logging (The Common Log Format)

All 50+ applications must produce logs in the **Enterprise Log Format** to ensure Correlated Observability.

```json
{
  "timestamp": "ISO8601",
  "level": "INFO",
  "service_id": "orders-v2",
  "trace_id": "abc-123", // Essential for Distributed Tracing
  "message": "Order processed successfully",
  "context": { "order_id": "9988" }
}

```

### Context Propagation

The shared library is responsible for extracting the `trace_id` from incoming headers and ensuring it is injected into all outgoing HTTP/Event requests.

---

## 4. Versioning & Lifecycle

* **Independent Versioning:** Shared libraries must use Semantic Versioning (SemVer).
* **Backward Compatibility:** Library maintainers must support the **last two major versions**.
* **Automated Updates:** Use tools like **Renovate** or **Dependabot** to automatically open PRs for library updates across all 50+ repositories.

---

## 5. Compliance Checklist

* [ ] Is the feature an infrastructure concern? If yes, move it to the **Service Mesh**.
* [ ] Does the shared library have zero transitive dependencies?
* [ ] Is the library code purely for cross-cutting concerns (Auth, Logging, Tracing) and free of business logic?
* [ ] Is there a Renovate/Dependabot configuration in the service repo to track library updates?

---

### Recommended Learning

**Microservice Shared Libraries: The Good, The Bad, and The Ugly**
A guide on when to share code and when to copy-paste to maintain decoupling:
[https://www.youtube.com/watch?v=5OjqD-ow8GE](https://www.youtube.com/watch?v=5OjqD-ow8GE)

---

**Next high-value step:** Would you like me to draft a **"Database Migration & Schema Evolution Blueprint"**? This would detail the "Expand and Contract" pattern for database changes to ensure zero-downtime deployments across your ecosystem.
