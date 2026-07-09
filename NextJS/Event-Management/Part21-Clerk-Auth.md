# **Part 21: Authorization and Roles with Clerk**:

---

# Part 21: Authorization and Roles with Clerk

Centralizes the scattered `event.organizerId !== user.id` checks and adds a lightweight admin role. Touches `/dashboard/[id]` and `/dashboard/[id]/checkin` (unchanged `params` handling) plus a new static `/admin` route (no params).

## 1. Centralize ownership checks
```ts
// src/lib/authz.ts
import { db } from "@/db";
import { events } from "@/db/schema";
import { eq } from "drizzle-orm";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";

export class AuthorizationError extends Error {}

export async function requireEventOwner(eventId: string) {
  const user = await getOrCreateCurrentUser();
  if (!user) throw new AuthorizationError("You must be signed in.");

  const [event] = await db.select().from(events).where(eq(events.id, eventId)).limit(1);
  if (!event) throw new AuthorizationError("Event not found.");

  if (event.organizerId !== user.id && !user.isAdmin) {
    throw new AuthorizationError("You do not manage this event.");
  }

  return { event, user };
}
```

## 2. Add isAdmin field
```ts
// src/db/schema.ts — add to users, add `boolean` to the import
isAdmin: boolean("is_admin").notNull().default(false),
```
```bash
pnpm db:generate
pnpm db:migrate
```
Toggle manually via Drizzle Studio for testing (no self-service UI, by design).

## 3. Use requireEventOwner everywhere
`src/app/dashboard/[id]/page.tsx` (still `Promise<{ id: string }>` params, unchanged):
```tsx
import { requireEventOwner, AuthorizationError } from "@/lib/authz";
import { notFound } from "next/navigation";

export default async function ManageEventPage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let event;
  try {
    ({ event } = await requireEventOwner(id));
  } catch (err) {
    if (err instanceof AuthorizationError) {
      return <main className="mx-auto max-w-2xl px-4 py-12"><p className="text-red-600">{err.message}</p></main>;
    }
    notFound();
  }
  // ...rest unchanged from Part 8c
}
```
Apply the same replacement to `dashboard/[id]/checkin/page.tsx` and `checkInByCode`/`getEventAttendeeStats` in `src/lib/actions/checkin.ts` (e.g. `getEventAttendeeStats` now starts with `const { event } = await requireEventOwner(eventId);`).

## 4. Admin-only route (static, no params)
```tsx
// src/app/admin/page.tsx
import { db } from "@/db";
import { events } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { desc } from "drizzle-orm";

export default async function AdminPage() {
  const user = await getOrCreateCurrentUser();
  if (!user || !user.isAdmin) {
    return <main className="mx-auto max-w-2xl px-4 py-12"><p className="text-red-600">Admins only.</p></main>;
  }
  const allEvents = await db.select().from(events).orderBy(desc(events.createdAt));
  return (
    <main className="mx-auto max-w-4xl px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-900">All events (admin)</h1>
      <ul className="mt-6 divide-y divide-gray-200">
        {allEvents.map((event) => (
          <li key={event.id} className="py-3 text-sm">
            <span className="font-medium text-gray-900">{event.title}</span>{" "}
            <span className="text-gray-500">— {new Date(event.startsAt).toLocaleString()}</span>
          </li>
        ))}
      </ul>
    </main>
  );
}
```
Add `/admin(.*)` to `src/middleware.ts`'s protected matcher — middleware just gates "logged in," the real `isAdmin` check lives in the page.

## 5. Try it out
Non-admin → `/admin` shows "Admins only" → flip `isAdmin` true in Drizzle Studio → refresh → see all events.

## Checkpoint
- [ ] `requireEventOwner` used consistently instead of ad hoc checks
- [ ] `isAdmin` field exists, defaults false, manually toggleable
- [ ] `/admin` correctly gates non-admins/admins

**Next: Part 22 — Testing and Error Handling Best Practices**
