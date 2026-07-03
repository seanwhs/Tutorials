# Appendix H — Production Folder Structures and Architecture Patterns

> **Goal of this appendix:** Learn how to organize a production-grade Next.js application so that it remains understandable, maintainable, and scalable as features, developers, and project complexity increase over time.

---

## 1. The Core Philosophy: Conway's Law

One of the most important laws in software engineering, **Conway's Law**, states: *Organizations design systems that mirror their own communication structures.*

When you build a folder structure, you aren't just storing files; you are defining the boundaries of your team's knowledge. A chaotic folder structure leads to a chaotic team, while a structured, logical architecture allows developers to "own" specific areas of the business logic without stepping on each other's toes.

---

## 2. The Evolution of Folder Structures

### Stage 1: The "Tutorial" Structure

*Best for: 1 developer, 1–2 months of work.*

```text
app/
components/
lib/

```

* **The Trap:** As the app grows, `components/` becomes a "junk drawer" containing everything from shared buttons to complex business-logic forms.

### Stage 2: The "Small Production" Structure

*Best for: 1–3 developers.*

```text
app/
components/
actions/
lib/
types/

```

* **The Benefit:** You have separated concerns (actions vs. components), but you still lack a clear link between a UI component and the logic that drives it.

### Stage 3: Feature-Based Architecture (Vertical Slices)

*Best for: Scaling teams and long-term maintainability.*
Instead of grouping by file type (horizontal), you group by feature (vertical).

```text
features/
  comments/
    components/
    actions/
    hooks/
    types/
    validation/

```

* **The Insight:** Humans think in terms of **problems**, not file extensions. When you need to update "Comments," you shouldn't have to search through four different root folders.

---

## 3. The GreyMatter Journal Production Architecture

Our production-grade layout balances the App Router's requirements with feature-based encapsulation.

```text
greymatter-journal/
├── app/              # Routes and layouts (The "Entry" layer)
├── features/         # Business logic encapsulated by domain (The "Domain" layer)
├── components/       # Truly shared, stateless UI (The "Presentation" layer)
├── lib/              # Infrastructure wrappers (The "Infrastructure" layer)
├── actions/          # Global Server Actions (RPC layer)
├── studio/           # Sanity configuration
└── types/            # Global shared types

```

---

## 4. Deep Architectural Layers

Large systems are organized into layers to manage dependencies. A change in the "Infrastructure" layer should rarely require a change in the "Presentation" layer.

1. **Presentation (app/ & components/):** Pure UI. Stateless buttons, cards, and page wrappers.
2. **Application (actions/):** Orchestration. Handling flow, auth, and state changes.
3. **Domain (features/):** Business logic. The "heart" of your app (e.g., how a comment is validated).
4. **Infrastructure (lib/):** The "pipes." Database clients, loggers, and third-party SDKs.

---

## 5. Next.js Specific Patterns

### Route Groups `(folder-name)`

Use these to organize your app into "different applications within one application."

* `(marketing)`: Landing pages, about us, pricing.
* `(auth)`: Sign-in, sign-up, password reset.
* `(admin)`: Protected dashboards, analytics.

### The "Lib" Folder: Infrastructure Only

The `lib/` folder is the most "abused" folder in software. To keep it clean, follow the **Infrastructure Only** rule: if it contains business logic, it belongs in a `feature/`. If it wraps a 3rd party SDK (like `sanity.ts` or `auth.ts`), it belongs in `lib/`.

---

## 6. The Monorepo Strategy (Scaling Further)

When your project outgrows a single repository, move to a **Monorepo** (e.g., Turborepo). This allows you to treat your UI library as an internal package, independent of the main app.

```text
packages/
  ui/          # Shared Design System
  auth/        # Shared Auth logic
  database/    # Shared DB schemas
apps/
  website/
  admin/

```

---

## 7. The Design System: Scaling UI Consistency

To decouple your design language from your application logic, build a shared `packages/ui` library. This ensures that a button in your "Admin Dashboard" is identical to a button on your "Marketing Landing Page."

### The Three Pillars of UI Consistency

* **Tokens:** The primitive values (colors, spacing, typography).
* **Components:** The building blocks (Buttons, Inputs, Cards).
* **Patterns:** The assembly rules (How a form relates to a validation message).

### Building a Shared `packages/ui`

By moving your UI into a workspace package, you treat your internal components exactly like you would an external library.

```text
packages/
  ui/
    src/
      components/
        button.tsx
        card.tsx
      index.ts      # The "Public API"

```

* **The "Public API" Principle:** Your `index.ts` file acts as the gateway. Never allow internal components to be imported directly; only expose what is stable.
* **The Power of Composition:** Never build components that do "everything." Build components that are **stateless primitives** (e.g., `<Button variant="destructive" />` is purely visual).

---

## 8. GreyMatter System Design Document: Master Index

| Domain | Technology | Key Pattern |
| --- | --- | --- |
| **Identity** | Clerk | Middleware-based Auth Guards |
| **Data** | Sanity.io | Tag-based Content Lakes |
| **Mutations** | Next.js Server Actions | Secure RPC Layers |
| **Performance** | Next.js Cache/CDN | ISR & Webhook Revalidation |
| **Architecture** | Feature Slices | Vertical Feature Organization |
| **Design System** | `packages/ui` | Stateless Component Primitives |

### Final Reflection

A folder structure is not just an implementation detail; it is a **Map of Understanding**. When you organize your project vertically by feature, you create an architecture where new team members learn the codebase by simply exploring the feature folders. Software architecture is ultimately the discipline of managing human complexity, communication, and time.
