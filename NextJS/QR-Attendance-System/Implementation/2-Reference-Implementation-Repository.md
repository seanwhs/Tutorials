# Reference Implementation Repository

> *"The purpose of a reference implementation is not to provide copy-and-paste code. It is to demonstrate how architectural decisions become executable software."*

---

## Purpose

This document details the production architecture for the QR Attendance Platform. This repository serves as an educational blueprint, demonstrating the integration of modern development practices with a scalable, modular design. The codebase prioritizes maintainability and architectural clarity over "clever" shortcuts.

## Repository Objectives

The implementation is built upon five core pillars:

1. **Architectural Clarity:** Folder structures communicate system boundaries.
2. **Production Patterns:** Implements layer separation, dependency inversion, and idempotent workflows.
3. **Framework Alignment:** Utilizes Next.js 16 (App Router, Server Components, Server Actions).
4. **Operational Readiness:** Includes environment management, telemetry, and error handling.
5. **Evolution Capability:** Designed for multi-tenant growth and enterprise extensibility.

---

## Technology Stack

| Area | Technology |
| --- | --- |
| **Framework** | Next.js 16 |
| **UI** | React |
| **Language** | TypeScript |
| **Authentication** | Clerk |
| **Data Store** | Sanity |
| **Workflows** | Inngest |
| **Rate Limiting** | Upstash Redis |
| **Email** | Resend |
| **Validation** | Zod |
| **Testing** | Vitest / Playwright |
| **Deployment** | Vercel |

---

## Implementation Roadmap

Development follows a bottom-up approach to enforce dependency direction, moving from foundation to presentation.

1. **Project Bootstrap:** Next.js 16 configuration, linting, and folder scaffolding.
2. **Environment Configuration:** Establishing `.env` templates for infrastructure secrets.
3. **Infrastructure Setup:** Creating abstract adapters to decouple the app from third-party SDKs.
4. **Domain Implementation:** Defining business entities, value objects, and domain errors.
5. **Persistence Layer:** Implementing repository interfaces for data mapping.
6. **Application Services:** Orchestrating business logic, policies, and command handling.
7. **Server Actions:** Connecting user intent to application services.
8. **Durable Workflows:** Implementing background processes (retries, fan-out, scheduling).
9. **Presentation Layer:** Developing the QR scanning and dashboard UI.
10. **Verification:** Executing linting, unit tests, E2E suites, and builds.

---

## Architectural Layering

### Domain Layer (`/domain`)

The core business language. It contains entities and business concepts. **Crucially: It remains agnostic of databases and frameworks.**

### Infrastructure Layer (`/infrastructure`)

Adapters for external services (Clerk, Sanity, etc.). All third-party interactions are mediated through these adapters, ensuring the rest of the application remains decoupled.

### Persistence Layer (`/repositories`)

Translates between Domain Objects and raw Sanity documents. The application layer depends on repository interfaces, not concrete implementations.

### Application Layer (`/application`)

The "Brain" of the operation. Services here coordinate repository calls, policy validation, and the triggering of domain events.

---

## Extending the Platform

The architecture is designed to embrace change without destabilization. When adding a feature, such as **Certificate Generation**, follow the established architectural thread:

**Domain (Entity) → Application (Service) → Repository (Persistence) → Workflow (Job) → Presentation (UI)**

By treating features as extensions rather than modifications to the core, the system remains stable as business requirements grow.

---

## Code Reading Strategy

To best understand the system, follow the **actual runtime path** rather than the folder structure:

1. **AttendanceService:** Understand the business orchestration.
2. **AttendanceRepository:** Understand the data mapping.
3. **AttendanceWorkflow:** Understand the asynchronous side effects.
4. **CheckIn Server Action:** Understand the request entry point.
5. **Check-In UI:** Understand the user interaction.

---

## Final Note

The repository is an executable expression of engineering principles. Frameworks evolve and libraries change; however, by decoupling business logic from the delivery mechanism, you ensure that the system can adapt to future requirements without requiring a complete rewrite. The implementation is not the destination—it is a concrete, reproducible demonstration of these architectural principles.
