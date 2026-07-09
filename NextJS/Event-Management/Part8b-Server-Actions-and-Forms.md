# Part 8b: Event Creation UI (Server Actions and Forms)

Server Actions work identically to prior Next.js versions — nothing here touches route `params`, so no new async considerations.

## 2. Server action to create an event

`src/lib/actions/events.ts`:
```ts
"use server";

import { db } from "@/db";
import { events } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";

export async function createEvent(formData: FormData) {
  const user = await getOrCreateCurrentUser();
  if (!user) throw new Error("You must be signed in to create an event.");

  const title = String(formData.get("title") ?? "").trim();
  const description = String(formData.get("description") ?? "").trim();
  const location = String(formData.get("location") ?? "").trim();
  const startsAtRaw = String(formData.get("startsAt") ?? "");
  const endsAtRaw = String(formData.get("endsAt") ?? "");
  const capacityRaw = String(formData.get("capacity") ?? "100");

  if (!title || !location || !startsAtRaw || !endsAtRaw) {
    throw new Error("Title, location, start time, and end time are required.");
  }

  const startsAt = new Date(startsAtRaw);
  const endsAt = new Date(endsAtRaw);
  const capacity = Math.max(1, parseInt(capacityRaw, 10) || 100);

  if (isNaN(startsAt.getTime()) || isNaN(endsAt.getTime())) throw new Error("Invalid date provided.");
  if (endsAt <= startsAt) throw new Error("End time must be after start time.");

  const [created] = await db
    .insert(events)
    .values({ organizerId: user.id, title, description, location, startsAt, endsAt, capacity })
    .returning();

  revalidatePath("/dashboard");
  revalidatePath("/events");
  redirect(`/dashboard/${created.id}`);
}
```
Key points: `"use server"` makes every export a Server Action; reads plain `FormData` (no client JS needed for `<form action={createEvent}>`); `redirect()` throws internally (expected); `revalidatePath` refreshes cached data.

## 3. The "create event" page

`src/app/dashboard/new/page.tsx` — a form with `title`, `description` (textarea), `location`, `startsAt`/`endsAt` (`datetime-local` inputs), `capacity` (number, default 100), submitting via `action={createEvent}`. Uses Tailwind utility classes for styling (`rounded-md border border-gray-300 px-3 py-2` etc.), submit button styled `bg-gray-900 text-white`.

Note: `datetime-local` inputs are interpreted in the browser's local timezone; `new Date(...)` in the server action converts to UTC before storing — consistent with Part 6's "store everything in UTC" decision.

This part continues directly in **Part 8c: Organizer Dashboard List and Detail Pages** 
