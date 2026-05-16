# 🔷 Next-SOLID

## Architectural Patterns for Production-Grade Next.js Systems

Applying SOLID principles to Next.js requires a structural translation, not a literal port.

SOLID was designed for object-oriented backend systems (Java, C#, NestJS-style architectures). Next.js is not that.

Modern Next.js is a **hybrid execution system**, composed of:

* React Server Components (RSC)
* Client Components
* Server Actions
* Route Handlers
* Edge/Node runtimes
* Streaming boundaries
* Functional composition layers

So SOLID does not map to “classes” anymore.

It maps to **boundaries, ownership, and dependency direction**.

---

# 🧠 Core Thesis

In Next.js:

> SOLID is not about object design.
> It is about controlling execution boundaries and dependency flow across runtimes.

This course reframes SOLID as:

* UI isolation discipline
* domain execution purity
* infrastructure inversion
* compositional extensibility
* testable architecture design

---

# 📘 Course Overview

**Next-SOLID** is an advanced architecture course for building scalable, maintainable, and infrastructure-agnostic Next.js applications using TypeScript and App Router.

This is not a React fundamentals course.

It is a **system design course for frontend-led distributed applications**.

---

# 🎯 Learning Outcomes

By the end of this course, engineers will be able to:

* Design layered Next.js architectures using SOLID principles
* Separate UI, domain logic, and infrastructure cleanly
* Build extensible systems without modifying core logic (OCP)
* Eliminate vendor lock-in via dependency inversion (DIP)
* Structure Server Actions as orchestration boundaries
* Build deterministic in-memory testing systems
* Design composable, plugin-style feature systems
* Enforce runtime-safe dependency graphs across Edge/Node

---

# 👥 Target Audience

* Senior React / Next.js engineers
* Frontend platform engineers
* Full-stack TypeScript developers
* Tech leads designing long-lived systems

---

# 📦 Prerequisites

* Next.js App Router (RSC + Server Actions)
* TypeScript (advanced usage)
* Async React patterns
* Basic system design experience

---

# 🧱 Architectural Model (Core Mental Model)

Next.js applications must be decomposed into **four layers of responsibility**:

```text
UI Layer (React Components)
        ↓
Orchestration Layer (Server Actions)
        ↓
Domain Layer (Services / Use Cases)
        ↓
Infrastructure Layer (Adapters)
```

Everything in this course enforces strict directionality:

> UI depends on domain
> Domain depends on abstractions
> Infrastructure implements abstractions
> Nothing depends on vendors directly

---

# 🧩 Module 1 — Single Responsibility Principle (SRP)

## Principle

> A module should have exactly one reason to change.

---

## Next.js Reality

SRP violations in Next.js appear as:

* “God Components”
* Server Actions doing business logic + validation + persistence
* Hooks managing domain rules
* UI mixed with infrastructure calls

This produces **untestable, tightly coupled render graphs**.

---

## Correct Decomposition

| Concern        | Layer           |
| -------------- | --------------- |
| Rendering      | UI Components   |
| State          | Hooks           |
| Orchestration  | Server Actions  |
| Business Logic | Domain Services |
| Persistence    | Repositories    |

---

## Pattern

```tsx
// Domain boundary (Server Action)
export async function submitOrderAction(formData: FormData) {
  return orderService.submit(Object.fromEntries(formData));
}
```

```tsx
// UI boundary (pure rendering)
'use client';

export function OrderForm({ onSubmit }: { onSubmit: (d: FormData) => void }) {
  return (
    <form action={onSubmit}>
      <input name="itemId" />
      <Submit />
    </form>
  );
}
```

---

# 🧩 Module 2 — Open/Closed Principle (OCP)

## Principle

> Software should be extendable without modifying existing logic.

---

## Next.js Failure Mode

* switch-case rendering trees
* boolean prop explosion
* role-based UI branching
* feature flags embedded in components

---

## Correct Model: Composition over Mutation

Instead of modifying core components, extend via composition:

```tsx
export function DashboardCard({
  title,
  children,
  renderFooter,
}: {
  title: string;
  children: React.ReactNode;
  renderFooter?: () => React.ReactNode;
}) {
  return (
    <section>
      <h3>{title}</h3>
      <div>{children}</div>
      {renderFooter?.()}
    </section>
  );
}
```

---

## Key Insight

> OCP in React is not inheritance. It is **component injection via composition slots**.

---

# 🧩 Module 3 — Liskov Substitution Principle (LSP)

## Principle

> Subtypes must remain substitutable for their base types without breaking correctness.

---

## Next.js Interpretation

LSP in frontend systems = **contract preservation of DOM primitives**

If you wrap a native element:

* button
* input
* link
* form

you must preserve:

* behavior
* accessibility
* ref forwarding
* prop compatibility

---

## Pattern

```tsx
interface ButtonProps
  extends React.ComponentPropsWithoutRef<'button'> {
  variant?: 'primary' | 'secondary';
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant, ...props }, ref) => (
    <button ref={ref} {...props} />
  )
);
```

---

## Key Insight

> Breaking LSP in UI systems produces silent accessibility and runtime failures.

---

# 🧩 Module 4 — Interface Segregation Principle (ISP)

## Principle

> Clients should not depend on interfaces they do not use.

---

## Next.js Failure Mode

```tsx
<Avatar user={fullUserObjectFromPrisma} />
```

This couples:

* UI
* database schema
* backend evolution
* ORM structure

---

## Correct Model: View Contracts

```tsx
interface AvatarProps {
  src: string;
  alt: string;
}
```

---

## Key Insight

> UI components should depend on **view models**, not domain entities.

---

# 🧩 Module 5 — Dependency Inversion Principle (DIP)

## Principle

> High-level modules must depend on abstractions, not concrete implementations.

---

## Next.js Problem

Direct coupling to:

* Prisma
* Clerk
* Stripe
* Analytics SDKs
* HTTP clients

inside Server Components or Actions.

---

## Correct Architecture

### Core Contracts

```ts
export interface IUserRepository {
  getProfileById(id: string): Promise<UserProfile | null>;
}
```

---

### Infrastructure

```ts
export class PrismaUserRepository implements IUserRepository {
  async getProfileById(id: string) {
    return prisma.user.findUnique({ where: { id } });
  }
}
```

---

### Composition Root

```ts
export const makeUserRepository = () =>
  new PrismaUserRepository();
```

---

## Key Insight

> DIP in Next.js is not abstraction for its own sake — it is **vendor isolation at scale**.

---

# 🧪 Module 6 — Testing via Dependency Inversion

## Principle

> If architecture is correct, testing becomes a composition problem, not a mocking problem.

---

## Strategy

Replace:

* network mocks
* SDK mocks
* database mocks

with:

* in-memory adapters
* deterministic services
* fake gateways

---

## Key Insight

> The goal is not to mock reality — it is to replace infrastructure with behaviorally equivalent systems.

---

# ⚙️ Server Action Architecture Rule (Critical)

Server Actions are:

> orchestration boundaries, not business logic containers.

They must:

* validate input
* resolve dependencies
* invoke domain services
* return or redirect

They must NOT:

* contain business rules
* embed infrastructure logic
* mix telemetry + domain decisions

---

# 🧠 Final Architecture Model

```text
Client UI
   ↓
Server Action (Orchestrator)
   ↓
Domain Service (CheckoutService)
   ↓
Interface Contracts
   ↓
Infrastructure Adapters
   ↓
External Systems
```

---

# 🏁 Final Outcome

After applying Next-SOLID correctly, your Next.js codebase becomes:

* structurally testable
* infrastructure-independent
* composition-driven
* extension-safe
* runtime-aware (Edge/Node compatible)
* long-term maintainable

---

# 🔷 Closing Principle

> React is not a UI framework anymore.
> Next.js is not a frontend framework anymore.

It is a **distributed application composition runtime**.

SOLID is what prevents it from collapsing under its own flexibility.
