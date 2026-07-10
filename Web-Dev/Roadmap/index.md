# From Zero to Deployed: The Professional Web Developer's Roadmap

**Status:** ✅ Complete — 8 Parts + 3 Appendices. Each Part is its own note (prefix `Roadmap Tutorial - `).

## Philosophy of this series

Most tutorials teach frameworks first and protocols never. That produces developers who can write `<Suspense>` but can't explain why it exists. This series inverts that: we start at the wire (bits over a network), climb through the browser's rendering pipeline, then arrive at Next.js 16 — and at every layer we ask **"what problem is this abstraction actually solving?"**

Every abstraction you'll use professionally (SSR, hydration, Server Actions, `fetch` caching) is a *direct answer* to a constraint imposed by HTTP being stateless and request/response being synchronous-feeling but network-bound. Understand the constraint, and the framework feature becomes obvious instead of magic.

## The Running Project: **DevBoard**

Instead of 8 disconnected demos, you build **one project** that evolves across every part:

> **DevBoard** — a minimal Kanban-style task board (`Todo` / `In Progress` / `Done`) with boards, columns, and cards.

- Part 3: DevBoard as static semantic HTML/CSS (no interactivity)
- Part 4: DevBoard's card-adding logic in vanilla JS (DOM + events + `fetch`)
- Part 5: DevBoard rebuilt in Next.js 16 App Router (Server + Client Components)
- Part 6: DevBoard cards created/moved via Server Actions + `useOptimistic`
- Part 7: DevBoard restyled with Tailwind v4 + shadcn/ui
- Part 8: DevBoard persisted in Postgres (Neon free tier) via Prisma, deployed to Vercel

By Part 8 you have a real, deployed, database-backed, professionally styled app — and you understand *why* every line is written the way it is, down to the TCP handshake.

## Stack (100% free/open-source tier)

- **Runtime:** Node.js 22 LTS
- **Editor:** VS Code
- **Framework:** Next.js 16 (App Router, Turbopack default)
- **Language:** TypeScript
- **Styling:** Tailwind CSS v4 (CSS-first config) + shadcn/ui
- **Database:** Postgres via Neon (free tier) + Prisma 6+
- **Version control:** Git + GitHub
- **Deployment:** Vercel (Hobby/free tier)

## Series Structure

| Part | Title | Core Question Answered |
|---|---|---|
| 1 | The Invisible Web | What actually happens between clicking a link and seeing a page? |
| 2 | The Developer Environment | How do professionals actually work day-to-day (terminal, Git, GitHub)? |
| 3 | The Semantic Web (HTML/CSS) | How do you build layouts that are accessible and responsive by default? |
| 4 | JavaScript Fundamentals | How does async code *really* execute in a single-threaded language? |
| 5 | The Next.js Leap | What is a Server Component, and why does it change everything? |
| 6 | Data Orchestration | How do you mutate server data from a form without an API layer? |
| 7 | Styling & Polish | How do professional teams style fast without writing custom CSS files? |
| 8 | Launch & Iterate | How does DevBoard go from `localhost` to a public URL with a real database? |
| A | Codebase Reference | Full file tree + `package.json` for the final DevBoard app |
| B | The Web Encyclopedia | Quick-reference glossary table |
| C | Deployment Checklist | Step-by-step GitHub → Vercel production checklist |

## Notes on how to read this series

- Every Part has: **Concept**, **Under the Hood**, **Implementation (step-by-step)**, **Exercise Challenge**, **Solution**.
- Code blocks are copy-pastable. Terminal commands are shown in fenced `bash` blocks.
- Parts 1–2 are lighter on code (foundations). Parts 3–8 are code-heavy and build DevBoard incrementally — do them in order, since each Part explicitly builds on artifacts from the one before it.
- Every Part cross-references earlier Parts by number (e.g., "recall Part 1.4") so you can trace *why* a later abstraction exists back to the underlying protocol/language concept.

---
*Next: `Roadmap Tutorial - Part 1: The Invisible Web`*

