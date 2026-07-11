# Complete Source Code Reference Map

> *"Good architecture is visible in the codebase. A developer should understand the system by exploring the repository structure."*

---

## 1. The Architectural GPS (Data Flow)

The most critical takeaway for any engineering team is the path a request takes. You have standardized this flow, ensuring consistency across all features:

**User Action → Server Action → Domain Service → Repository Layer → Storage/Events**

This strict separation ensures that your business logic remains untainted by the UI, allowing you to swap out Sanity for a SQL database, or Next.js for a different framework, without requiring a complete rewrite of the system.

## 2. Key Architectural Components

* **The Middleware Layer:** Centralizes security and authorization, acting as a gatekeeper that verifies identity and permissions before a single line of application code is executed.
* **Feature-Based Modules:** By grouping logic inside `features/attendance/`, `features/events/`, etc., you have effectively created "micro-services" within your monorepo. This allows teams to iterate on one module without stepping on the toes of another.
* **The Inngest Workflow Engine:** By offloading business-critical tasks (notifications, analytics, broadcast) to asynchronous workflows, you keep your web application fast, responsive, and resilient to failures in third-party APIs.

---

## 3. The "Standardized Feature" Blueprint

Every new capability you add to this platform should mirror the attendance module's structure:

| Folder | Responsibility |
| --- | --- |
| `actions/` | The bridge between UI and Domain. |
| `services/` | The "Brain"—contains the pure business logic. |
| `repositories/` | The "Hands"—handles the interaction with the database. |
| `schemas/` | The "Contract"—defines data shapes and validation. |

---

## 4. Engineering Lifecycle Finalization

You have now fully documented the "Modern Web Quartet" (React, Next.js, TanStack, AI) as a production-grade architecture. From the high-level strategy to the specific file paths, your system is ready for the **Quality Engineering** phase.

### Your System Summary

You have built:

1. **A Scalable Architecture:** Decoupled, event-driven, and multi-tenant.
2. **A Secure Environment:** Zero Trust, RBAC, and middleware-enforced auth.
3. **An Operational Platform:** Observability, SRE runbooks, and async workflows.
4. **A Maintainable Repository:** Modularized code with a clear developer onboarding path.

---

**You have successfully completed the core architectural documentation for your Singapore Field Operations platform.**

We have reached the end of the foundational architectural sequence. You now possess a "Master Manual" that covers every stage of the professional engineering lifecycle.
