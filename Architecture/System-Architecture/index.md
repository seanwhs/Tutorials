# Architecting Modern Systems: Patterns, Principles, and Practice

**A Principal-Architect-level tutorial series on System Design, Scalability, and Maintainability.**

> "Code tells you *how*. Architecture tells you *why it still works in three years.*"

This series teaches the difference between **tactical programming** (writing a function that works today) and **strategic architecture** (designing a system that survives requirement changes, team growth, and scale, for years). Every pattern taught is justified through the lens of **Cost of Change** — how expensive is it to alter this decision six months from now?

## Tooling Philosophy (Strict Constraint)

Everything in this series uses **free, open-source tools only**:
- **C4 Model** (context/container/component/code diagrams) — free notation, no license
- **Structurizr Lite** or **PlantUML** or **Mermaid** — free diagram-as-code
- **Excalidraw** — free whiteboarding for informal sketches
- **Next.js 16 (App Router) + React 19 + TypeScript** — the practical demonstration stack (framework-agnostic principles, framework-concrete code)
- **In-memory / SQLite fake DB pattern** — zero external services required to run examples (same PoC pattern used in the React 19 Mastery series)

No paid SaaS, no proprietary modeling tools, no cloud vendor lock-in examples. Every diagram and pattern shown can be reproduced by a solo developer with a text editor.

## Prerequisites

- Comfortable with TypeScript and React fundamentals (see "Mastering React 19" series if needed)
- Basic familiarity with Next.js App Router (see "Enterprise-Grade Patterns for Next.js 16" series for deployment-grade patterns)
- No prior system design experience required — this series starts from first principles

## Series Structure

| Part | Title | Core Question Answered |
|---|---|---|
| 1 | The Architect's Mindset | What separates a senior engineer's code from an architect's design? |
| 2 | Designing the Core | How do we model the business domain before writing UI code? |
| 3 | Decoupling Components | How do we keep business logic alive even if we delete Next.js tomorrow? |
| 4 | Data Orchestration | How does data stay consistent when it's owned by multiple services? |
| 5 | Resilience & Scalability | How does the system behave gracefully when a dependency fails? |
| 6 | API Evolution | How do we change a public contract without breaking every client? |
| 7 | Architectural Decision Records | How do we preserve institutional memory about *why* we chose X over Y? |
| 8 | The Full System | How does everything compose into one coherent, running architecture? |

Each part includes:
1. **Concept Explanation** — the principle, its trade-offs, and its Cost of Change profile
2. **Diagram** — C4-style or PlantUML/Mermaid representation of the concept
3. **Implementation** — step-by-step code in TypeScript/Next.js
4. **Design Exercise** — a hands-on challenge ("Step 1: Define the bounded contexts for...")
5. **Solution & Discussion** — worked solution with architectural reasoning

## The Running Case Study: "Northwind Orders" Platform

Across all 8 parts we incrementally design and build **one coherent system** — an order-management platform ("Northwind Orders") with these capabilities:
- Customers browse a catalog and place orders (Catalog + Ordering contexts)
- Orders trigger inventory reservation and payment processing (Inventory + Payments contexts)
- Customers get notified of order status (Notifications context)
- All of it observable, resilient, versioned, and documented via ADRs

By Part 8, these pieces are assembled into a single **Modular Monolith** deployed as a Next.js application, with clear seams where it *could* be split into microservices later — without ever having paid that complexity tax prematurely.

## Notes in This Series

- Architecting Modern Systems - INDEX (Start Here) *(this note)*
- Architecting Modern Systems - Part 1 (The Architect's Mindset)
- Architecting Modern Systems - Part 2 (Designing the Core)
- Architecting Modern Systems - Part 3 (Decoupling Components)
- Architecting Modern Systems - Part 4 (Data Orchestration)
- Architecting Modern Systems - Part 5 (Resilience & Scalability)
- Architecting Modern Systems - Part 6 (API Evolution)
- Architecting Modern Systems - Part 7 (Architectural Decision Records)
- Architecting Modern Systems - Part 8 (The Full System)
- Architecting Modern Systems - Appendix A (The Architect's Toolkit)
- Architecting Modern Systems - Appendix B (Decision Record Template)
- Architecting Modern Systems - Appendix C (Architectural Pattern Matrix)

## Recommended Reading Order

Linear, Part 1 → Part 8. Each part's code builds on the folder structure introduced in Part 1 and extended in Part 3. Appendices are reference material — read them whenever they're linked from the main parts (A is linked from Part 1, B from Part 7, C from Part 8).
