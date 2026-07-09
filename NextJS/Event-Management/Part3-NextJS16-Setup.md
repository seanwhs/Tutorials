# Part 3: Next.js 16 Project Setup and Structure

## 1. Scaffold the project
```bash
pnpm create next-app@latest eventhub
```
Choose: TypeScript Yes, ESLint Yes, Tailwind CSS Yes, `src/` directory Yes, App Router Yes, import alias `@/*` Yes.
```bash
cd eventhub
code .
```

## 2. Run it
```bash
pnpm dev
```
Turbopack is used automatically for `next dev` in Next.js 16 — no flags needed. Visit http://localhost:3000.

## 3. App Router structure
Folders = routes. `src/app/events/page.tsx` → `/events`; `src/app/events/[id]/page.tsx` → `/events/123`.
- `page.tsx` = UI for a route
- `layout.tsx` = shared wrapper
- `route.ts` = API endpoint
- `"use server"` = Server Actions

## 4. The most important Next.js 16 rule: dynamic APIs are async

`params` and `searchParams` are **Promises**, not plain objects — always await:
```tsx
export default async function EventPage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params; // required, not optional
}
```
Same for Clerk: `const { userId } = await auth();` / `const user = await currentUser();`
TypeScript will catch a missing `await` at compile time since `params` is typed as a Promise.

## 5. Tailwind CSS v4: CSS-first config

No `tailwind.config.ts`. Replace `src/app/globals.css`:
```css
@import "tailwindcss";

:root {
  --background: #ffffff;
  --foreground: #171717;
}

body {
  background: var(--background);
  color: var(--foreground);
}
```
Extensions (plugins, theme, dark mode) go directly in this CSS file via `@plugin`, `@theme`, `@custom-variant` — never a separate config file.

## 6. Clean up starter template

Replace `src/app/page.tsx`:
```tsx
export default function HomePage() {
  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight text-gray-900">EventHub</h1>
      <p className="mt-4 text-lg text-gray-600">
        Discover events, RSVP for free, and manage check-ins — all in one place.
      </p>
    </main>
  );
}
```

## 7. Target project structure (map for later parts)
```
eventhub/
  src/
    app/ (layout.tsx, page.tsx, globals.css, events/, dashboard/, api/, sign-in/, sign-up/)
    db/ (index.ts, schema.ts)
    inngest/ (client.ts, functions/)
    lib/ (actions/, email.ts, qrcode.ts)
    middleware.ts
  drizzle.config.ts
  .env.local
```
(No `tailwind.config.ts` — that's correct for v4, not an omission.)

## 8. Install all packages up front
```bash
pnpm add drizzle-orm @neondatabase/serverless
pnpm add -D drizzle-kit
pnpm add @clerk/nextjs
pnpm add inngest
pnpm add resend
pnpm add qrcode
pnpm add -D @types/qrcode
```

## Checkpoint
- [ ] `pnpm dev` runs via Turbopack, shows placeholder home page
- [ ] `globals.css` has `@import "tailwindcss";`, no `tailwind.config.ts` anywhere
- [ ] All packages installed
- [ ] You understand: routes=folders, `page.tsx`/`route.ts`/`"use server"`, and `params`/`searchParams` must always be awaited

Commit:
```bash
git init
git add .
git commit -m "Initial Next.js 16 scaffold for EventHub"
```

**Next: Part 4 — Clerk Authentication Integration**
