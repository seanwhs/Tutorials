# **Part 22: Testing and Error Handling Best Practices**:

---

# Part 22: Testing and Error Handling Best Practices

Graceful failures + a real automated test. No route params here — `error.tsx`/`not-found.tsx`/`useActionState` work identically under Next.js 16.

## 1. Global error boundary
```tsx
// src/app/error.tsx
"use client";
import { useEffect } from "react";

export default function GlobalError({
  error, reset,
}: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { console.error(error); }, [error]);
  return (
    <main className="mx-auto max-w-lg px-4 py-20 text-center">
      <h1 className="text-2xl font-bold text-gray-900">Something went wrong</h1>
      <p className="mt-2 text-gray-600">{error.message || "An unexpected error occurred."}</p>
      <button onClick={() => reset()} className="mt-6 rounded-md bg-gray-900 px-4 py-2 text-white hover:bg-gray-700">Try again</button>
    </main>
  );
}
```
Must be a Client Component — catches errors from any Server Component/Action beneath it in the tree.

## 2. Not-found page
```tsx
// src/app/not-found.tsx
import Link from "next/link";
export default function NotFound() {
  return (
    <main className="mx-auto max-w-lg px-4 py-20 text-center">
      <h1 className="text-2xl font-bold text-gray-900">Page not found</h1>
      <p className="mt-2 text-gray-600">The page you&apos;re looking for doesn&apos;t exist or may have been removed.</p>
      <Link href="/events" className="mt-6 inline-block rounded-md bg-gray-900 px-4 py-2 text-white hover:bg-gray-700">Browse events</Link>
    </main>
  );
}
```
Renders on `notFound()` calls throughout the app.

## 3. Inline form errors via useActionState
Change `rsvpToEvent` to return errors instead of throwing (except truly unexpected cases):
```ts
export async function rsvpToEvent(
  _prevState: { error: string | null },
  formData: FormData
): Promise<{ error: string | null }> {
  const user = await getOrCreateCurrentUser();
  if (!user) return { error: "You must be signed in to RSVP." };

  const eventId = String(formData.get("eventId") ?? "");
  const [event] = await db.select().from(events).where(eq(events.id, eventId)).limit(1);
  if (!event) return { error: "Event not found." };

  const [existing] = await db.select().from(rsvps)
    .where(and(eq(rsvps.eventId, eventId), eq(rsvps.userId, user.id))).limit(1);
  if (existing && existing.status !== "cancelled") return { error: "You have already RSVPed to this event." };

  // ...capacity check, insert/update, inngest.send, revalidatePath (as Part 19)...
  return { error: null };
}
```
New client wrapper:
```tsx
// src/components/rsvp-form.tsx
"use client";
import { useActionState } from "react";
import { rsvpToEvent } from "@/lib/actions/rsvps";

export function RsvpForm({ eventId, disabled }: { eventId: string; disabled?: boolean }) {
  const [state, formAction, isPending] = useActionState(rsvpToEvent, { error: null });
  return (
    <form action={formAction}>
      <input type="hidden" name="eventId" value={eventId} />
      <button type="submit" disabled={isPending} className="rounded-md bg-gray-900 px-5 py-2.5 text-white hover:bg-gray-700 disabled:opacity-50">
        {isPending ? "Submitting..." : disabled ? "Join waitlist" : "RSVP for free"}
      </button>
      {state.error && <p className="mt-2 text-sm text-red-600">{state.error}</p>}
    </form>
  );
}
```
In `src/app/events/[id]/page.tsx` (params handling unchanged since Part 9), replace the RSVP form block with `<RsvpForm eventId={event.id} disabled={spotsLeft <= 0} />`.

## 4. Automated test for RSVP/waitlist logic
```bash
pnpm add -D vitest
```
Add `"test": "vitest run"` to `package.json`. Extract pure logic:
```ts
// src/lib/rsvp-rules.ts
export function decideRsvpStatus(confirmedCount: number, capacity: number): "confirmed" | "waitlisted" {
  return confirmedCount >= capacity ? "waitlisted" : "confirmed";
}
```
Use it in `rsvpToEvent`. Test:
```ts
// src/lib/rsvp-rules.test.ts
import { describe, it, expect } from "vitest";
import { decideRsvpStatus } from "./rsvp-rules";

describe("decideRsvpStatus", () => {
  it("confirms when there is room", () => expect(decideRsvpStatus(5, 10)).toBe("confirmed"));
  it("waitlists when at exact capacity", () => expect(decideRsvpStatus(10, 10)).toBe("waitlisted"));
  it("waitlists when over capacity", () => expect(decideRsvpStatus(15, 10)).toBe("waitlisted"));
  it("confirms the very first RSVP", () => expect(decideRsvpStatus(0, 1)).toBe("confirmed"));
});
```
```bash
pnpm test
```

## Checkpoint
- [ ] Unexpected errors show friendly `error.tsx` UI, not a raw stack trace
- [ ] `notFound()` shows the friendly page
- [ ] Double-RSVP shows inline error, no crash
- [ ] `pnpm test` passes all 4 tests

**Next: Part 23 — Deploying to Vercel for Free**
