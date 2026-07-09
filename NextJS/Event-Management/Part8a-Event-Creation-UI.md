# **Part 8a: Event Creation UI (Organizer Dashboard)**:

---

# Part 8: Event Creation UI (Organizer Dashboard)

Any signed-in user can create an event. Whoever creates it becomes its organizer, with a dashboard to manage it.

## 1. Shared helper: get or create the local user row

The Clerk webhook (Part 7) keeps `users` in sync, but webhooks can occasionally be delayed or missed. This defensive helper fetches the local user, creating it on the fly from Clerk's data if missing. Calls Clerk's `auth()`/`currentUser()` — both async, must be awaited.

Create `src/lib/get-current-user.ts`:
```ts
import { auth, currentUser } from "@clerk/nextjs/server";
import { db } from "@/db";
import { users } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function getOrCreateCurrentUser() {
  const { userId: clerkId } = await auth();
  if (!clerkId) return null;

  const existing = await db
    .select()
    .from(users)
    .where(eq(users.clerkId, clerkId))
    .limit(1);

  if (existing.length > 0) return existing[0];

  const clerkUser = await currentUser();
  if (!clerkUser) return null;

  const email = clerkUser.emailAddresses[0]?.emailAddress ?? "unknown@example.com";
  const name = [clerkUser.firstName, clerkUser.lastName].filter(Boolean).join(" ").trim() || "Anonymous";

  const [inserted] = await db
    .insert(users)
    .values({ clerkId, email, name, imageUrl: clerkUser.imageUrl ?? null })
    .returning();

  return inserted;
}
```

This part continues directly in **Part 8b: Event Creation UI (Server Actions and Forms)** 
