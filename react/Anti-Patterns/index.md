# Breaking Bad Habits: The React 19 Anti-Patterns Guide

A 4-part, code-heavy tutorial series for developers transitioning from legacy React (18 and below) patterns to modern React 19 practices. Every part shows an **Anti-Pattern** (what you probably wrote in 2023) next to the **Modern React 19 Solution** (what you should write now), with an explanation of *why* the old way hurts you.

## Who this is for
Intermediate developers who know React basics (JSX, props, state, hooks) but learned them in the React 16-18 era and haven't updated their mental model for React 19 and the React Compiler.

## Prerequisites
- Node.js 20.9+ or 22 LTS (Node 18 is EOL, don't use it)
- A React 19 project (Next.js 15/16 App Router recommended for Parts 2-4, but Part 1 works in any React 19 setup — Vite, CRA-replacement, etc.)
- TypeScript 5+
- Basic familiarity with hooks (`useState`, `useEffect`)

## Series Structure

### Part 1: The Memoization Trap
Stop manually sprinkling `useMemo`, `useCallback`, and `React.memo` everywhere.
- Why manual memoization became a habit (and why it was mostly cargo-culting)
- How the React Compiler works and what it auto-memoizes
- Installing and configuring `babel-plugin-react-compiler` / `eslint-plugin-react-hooks` v5
- Before/After: a cluttered dashboard component vs. the compiler-optimized version
- When you STILL need manual memoization (the rare cases)

### Part 2: The Data Fetching & Form Muddle
Stop using `useEffect` for data fetching and hand-rolling `isLoading`/`error` state machines.
- Why `useEffect` data fetching causes waterfalls, race conditions, and double-fetches in Strict Mode
- The modern "Actions" pattern: Server Actions + `useActionState`
- `useFormStatus` for reusable submit buttons that "just know" the pending state
- `useOptimistic` for instant UI feedback without manual state juggling
- Before/After: a login form with manual `useState` spaghetti vs. the Actions-based form

### Part 3: The Component Bloat
Stop using `forwardRef` and prop-drilling through 5 layers of components.
- "Ref as a Prop" — why `forwardRef` is no longer necessary in React 19
- The `use` API for reading Context conditionally and unwrapping Promises
- Proper Client vs. Server component splitting with `"use client"` / `"use server"`
- Before/After: a `forwardRef`-wrapped input + prop-drilled theme context vs. the React 19 version

### Part 4: The Performance & Hydration Killers
Fix the silent killers: index-as-key, unnecessary Context re-renders, missing Suspense boundaries.
- Why `key={index}` causes state bugs and hydration mismatches
- Why wrapping your whole app in one giant Context re-renders everything
- Proper Suspense boundary placement for streaming SSR
- **Bonus: How to Deploy** — shipping to Vercel and Netlify free tiers
- Why these patterns collectively shrink your client-side JS bundle

## How to use this series
Read Parts 1-4 in order — each builds conceptually on the last (compiler mental model → data patterns → component architecture → performance/shipping). Every lesson follows the same shape:
1. **The Anti-Pattern** (code + why it feels right but isn't)
2. **The Problem** (concrete, beginner-friendly explanation — re-renders, race conditions, hydration errors, bundle size)
3. **The Modern React 19 Solution** (full code)
4. **Migration Steps** (numbered, step-by-step)
5. **Quick Checklist** (scan-and-fix reference)

---
*Notes in this series are titled with the "Breaking Bad Habits - " prefix.*
