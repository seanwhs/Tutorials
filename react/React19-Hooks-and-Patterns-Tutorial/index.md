# Mastering React 19: Hooks, Patterns, and Modern Architecture

A code-heavy, beginner-friendly tutorial series for building a **React 19 Proof-of-Concept** repository. Built with **Next.js 16** (App Router) as the delivery framework because it ships first-class support for React Server Components, Server Actions, and React 19's new hooks — but every pattern taught here is pure React 19 and portable to any RSC-capable framework.

## Series Map

| Note | Title | Covers |
|---|---|---|
| This note | INDEX (Start Here) | Repo setup, package.json, folder structure |
| Module 1 | The New Lifecycle | `useActionState`, migrating from `useState`+`onSubmit` to Actions |
| Module 2 | Async Mastery | The `use` hook, Suspense, streaming, reading Context with `use` |
| Module 3 | Form Orchestration | `useFormStatus`, `useActionState`, optimistic UI with `useOptimistic` |
| Module 4 | Composition Patterns | Composition over prop-drilling, Locality of Behavior, slot patterns |
| Module 5 | The Final Boss | Integrated Dashboard combining every concept |

## Prerequisites
- Node.js 20.9+ or 22 LTS
- Basic React familiarity (no prior RSC/Actions experience needed)

## 1. Initialize the Repository
```bash
npx create-next-app@latest react19-poc --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
cd react19-poc
```
Verify: `npm ls react` → should print `react@19.x.x`

## 2. package.json Dependencies
```bash
npm install zod
npm install lucide-react
npm install clsx
```
**Why zod?** Server Actions receive raw `FormData` — zod validates/parses it into typed objects before touching business logic.

## 3. Folder Structure
```
react19-poc/
├── src/
│   ├── app/ (layout.tsx, page.tsx, module-1-actions/, module-2-use-hook/, module-3-forms/, module-4-composition/, dashboard/)
│   ├── actions/ (tasks.ts, profile.ts, notifications.ts, team.ts)
│   ├── components/
│   │   ├── ui/ (Card.tsx, Button.tsx, SubmitButton.tsx, Panel.tsx)
│   │   ├── forms/ (TaskForm.tsx, ProfileForm.tsx)
│   │   └── dashboard/ (DashboardShell.tsx, TaskList.tsx, NotificationsFeed.tsx, UserContext.tsx)
│   ├── lib/ (db.ts, schemas.ts, delay.ts)
│   └── types/
├── package.json / tsconfig.json / next.config.ts
```
- `src/actions/` — grouped by domain (Locality of Behavior)
- `src/components/ui/` — zero business logic, pure composition
- `src/lib/db.ts` — fake in-memory DB with artificial latency (zero external services)

## 4. Fake Database Pattern
A shared `db.ts` module with a module-level array + async functions simulating network latency (`getTasks`, `addTask`, `toggleTask`, `deleteTask`), used across every module.

## 5. Root Layout
Includes full `layout.tsx` (dark theme shell) and `page.tsx` (landing page linking to all 5 module demos).

## Terminology Cheat Sheet
- **Server Component (RSC)**, **Client Component**, **Server Action**, **Action**, **Locality of Behavior** — each defined plainly for beginners.
