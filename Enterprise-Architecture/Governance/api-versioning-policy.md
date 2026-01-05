# API Versioning Policy

In an enterprise with **50+ applications**, a single breaking change in a "Core" service (e.g., Identity or Payments) can cause a catastrophic failure across the entire ecosystem. This policy enforces **Contract Stability** and defines how we evolve APIs without breaking downstream consumers.

---

## 1. The "Never Break" Principle

Directly modifying an existing API contract is **strictly forbidden**. Every change must be either:

1. **Backward Compatible:** Adding optional fields or new endpoints.
2. **Versioned:** Introducing a new contract side-by-side with the old one.

---

## 2. Versioning Strategy

We standardize on **URL Path Versioning** for RESTful services to ensure clarity in logs, caches, and gateway routing.

* **Format:** `https://api.enterprise.com/{service}/{version}/{resource}`
* **Example:** `https://api.enterprise.com/orders/v2/payments`

### Semantic Versioning (SemVer)

While the URL uses the Major version (`v1`, `v2`), we track full SemVer in the `OpenAPI` specification:

* **MAJOR:** Incompatible API changes (New URL path required).
* **MINOR:** Functionality added in a backward-compatible manner.
* **PATCH:** Backward-compatible bug fixes.

---

## 3. Evolutionary Patterns (Expand & Contract)

To migrate from `v1` to `v2`, all teams must follow the **Expand and Contract** pattern to avoid synchronized deployments (which are impossible at this scale).

1. **Expand:** Deploy `v2` alongside `v1`. The service supports both.
2. **Migrate:** Downstream teams move to `v2` at their own pace.
3. **Monitor:** Use **Distributed Tracing (OTel)** to verify that `v1` traffic has dropped to zero.
4. **Contract:** Decommission `v1`.

---

## 4. Deprecation Policy

We maintain a strict timeline to prevent "Legacy Bloat":

| Stage | Duration | Action |
| --- | --- | --- |
| **Active** | Current | Fully supported, primary target for new features. |
| **Deprecated** | 6 Months | Supported for bug fixes only. Header `Sunset` added to responses. |
| **End of Life** | Permanent | API endpoint returns `410 Gone`. Code is removed. |

---

## 5. Breaking Change Criteria

The following are considered **Major (Breaking)** changes:

* Removing or renaming an endpoint.
* Changing a field name or data type (e.g., `String` to `Integer`).
* Removing a required field from a request.
* Changing the default value of a field.
* Adding a new required field to a request.

---

## 6. Contract Enforcement (Schema Registry)

For **Event-Driven Architecture (EDA)**, we use the **Kafka Schema Registry** to enforce these rules at the message level.

* **Compatibility Mode:** `BACKWARD` (Ensures new consumers can read old data).
* **Validation:** CI/CD pipelines must run a "Schema Check" against the registry before merging any changes to Kafka Producers.

---

## 7. Compliance Checklist

* [ ] Does the new version exist side-by-side with the previous version?
* [ ] Has the `v1` version been marked as `Deprecated` in the **Service Catalog**?
* [ ] Have all downstream consumers been notified via the **Architecture Review Board (ARB)**?
* [ ] Does the API Gateway have routing rules defined for both versions?

---

### Recommended Learning

**Designing Evolvable Web APIs**
Strategies for managing long-term API health in distributed systems:
[https://www.youtube.com/watch?v=3S_vS9mP_2A](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3D3S_vS9mP_2A)

---

**Next high-value step:** Would you like me to draft a **"Cross-Cutting Concerns Library Specification"**? This would define what should go into a shared library (like a `common-lib`) versus what should remain in the service mesh, to prevent the "Shared Library Hell" that often plagues large architectures.
