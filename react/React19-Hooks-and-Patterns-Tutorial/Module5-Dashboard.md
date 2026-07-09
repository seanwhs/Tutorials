# **Module 5: The Integrated Dashboard** 

---

## Concept Explanation

Combines every prior pattern into one cohesive Dashboard: tasks, profile settings, notifications feed, team panel. Uses RSC for data reads (Module 2), Server Actions + `useActionState` for mutations (Module 1), `useFormStatus` + `useOptimistic` for forms (Module 3), Composition for the shell (Module 4).

**Architecture rules:** only interactive leaves get `"use client"`; Server Actions grouped by domain in `src/actions/`; dumb UI primitives in `src/components/ui/` know nothing about business domains; pages fetch data and compose everything.

## Implementation (9 steps)

1. **UserContext + UserProvider** — Client Components; `UserInfo = { name, plan: "free"|"pro" }`.
2. **Dashboard layout** — Server Component wraps children in `UserProvider` with a stand-in `currentUser`, renders nav (Overview/Settings links).
3. **Main dashboard page** — async Server Component: awaits `getTasks()`/`getTeamMembers()`, starts (doesn't await) `getNotifications()`. Renders 3 Cards: Tasks (`TaskPanel`), Notifications (`NotificationsFeed` in `<Suspense>`), Team (`TeamPanel`) — Notifications streams in later while others render immediately.
4. **db.ts additions** — `TeamMember` type, `getTeamMembers()` (400ms delay), `inviteTeamMember(email)` (600ms delay), same fake-latency style as before.
5. **TaskPanel** — combines Module 1 (`useActionState` + `createDashboardTaskAction` with zod validation) and Module 3 (`useOptimistic` for instant task appearance, shared `SubmitButton`).
6. **NotificationsFeed** — Module 2's `use(notificationsPromise)` to read streamed data.
7. **PlanGate** — combines Module 2 (`use(UserContext)`, conditional read after early-return) and Module 4 (wraps arbitrary `children`, fully decoupled from what it's gating) — shows "Upgrade to Pro" if not on pro plan.
8. **TeamPanel** — mirrors TaskPanel exactly: `useActionState(inviteTeamMemberAction)` + `useOptimistic` for instant "(inviting...)" rows, form wrapped in `PlanGate` so only pro users can invite.
9. **Settings page** — Server Component reusing Module 3's `ProfileForm` **completely unmodified**, plus a Pro Features card gated by `PlanGate`.

## Exercise: Challenge
Add a "Recent Activity" panel (1200ms delay) that streams independently of Notifications via its own sibling `<Suspense>`, built with an `ActivityFeed` component using `use()`. Bonus: gate it with `PlanGate` and explain why that's fine despite the data being server-fetched.

## Solution
`getRecentActivity()` added to db.ts; `activityPromise` started in parallel with `notificationsPromise` (neither awaited); a 4th Card wraps `ActivityFeed` in its own `<Suspense>`, itself wrapped in `PlanGate`.

**Explanation:** `PlanGate` only inspects `UserContext` to decide whether to render `children` — it has zero awareness of *how* those children's data was fetched. The Suspense-wrapped `ActivityFeed` element tree was already fully constructed by the Server Component page before `PlanGate` runs; `PlanGate` just chooses whether to display that pre-built tree or a fallback. Gating (permissions) and data-fetching (promises) are orthogonal, decoupled concerns — the same composition principle from Module 4.

## Wrap-Up
Recaps all 5 modules' techniques and notes that swapping the fake `db.ts` for a real database is a one-file change, since business logic was never leaked into the UI layer.

---

That's the complete series. 
