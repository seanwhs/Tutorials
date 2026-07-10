# Type-Safe Horizons: Mastering TypeScript in the Next.js Ecosystem

**Audience:** React/Next.js engineers moving from "any-driven development" to a type-safe architecture.
**Stack validated against:** Next.js 16 (App Router), React 19, TypeScript 5.x with `strict: true`.

## Philosophy

Every lesson in this series follows the same loop:

1. **Safety Check** — a real anti-pattern (usually `any`, a loose `interface`, or an untyped boundary) and the runtime bug it silently allows.
2. **Type Logic** — *why* the correct type shape works, explained before any implementation code.
3. **Refactored Solution** — the idiomatic, copy-paste-ready fix, wired into a Next.js 16 App Router example.
4. **Exercise Challenge** — a small task to extend the pattern yourself.
5. **Solution** — worked answer with explanation.
6. **TypeScript Tip** — one time-saving trick per part.

## Required `tsconfig.json` baseline

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "ES2022"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "moduleResolution": "bundler",
    "module": "esnext",
    "esModuleInterop": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

`noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` aren't defaults under `strict: true` — turn them on explicitly.

## Curriculum

**Part 1: Beyond Basics** — Interfaces vs. `type`, discriminated unions for `Loading | Success | Error` state, and `Pick`/`Omit`/`Partial` applied to React props. Introduces the `Task` type and `FormState`/`RequestState` union used throughout the series.

**Part 2: The Component Layer** — `React.ReactNode` vs `JSX.Element` vs `React.ReactElement`, typing `forwardRef` (and React 19's plain `ref`-as-prop alternative), and `React.ComponentPropsWithoutRef<'element'>` to inherit native HTML attributes.

**Part 3: The Data Boundary** — Typing Server Components and Server Actions end-to-end. Deriving UI types from Prisma/Drizzle models, typed `searchParams`/`params` (Promise-based in Next.js 16), and threading server-inferred (Zod) types into client forms.

**Part 4: Advanced Architectural Safety** — Generics for reusable UI (`DataTable<T>`, `Select<T>`), and Brand/Nominal typing to make `UserId` and `PostId` structurally incompatible even though both are `string` at runtime.

## Running example across all 4 parts

```ts
// types/task.ts
export interface Task {
  id: string;
  title: string;
  status: "todo" | "in-progress" | "done";
  priority: "low" | "medium" | "high";
  assigneeId: string | null;
  dueDate: Date | null;
}
```

By Part 4 this evolves into a fully generic, brand-typed, database-derived model.
