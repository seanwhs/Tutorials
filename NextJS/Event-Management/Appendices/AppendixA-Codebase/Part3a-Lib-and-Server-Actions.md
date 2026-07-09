# Appendix A Part 3: Lib and Server Actions

`getOrCreateCurrentUser` calls Clerk's `auth()`/`currentUser()`, both async in Next.js 16, awaited accordingly.

## src/lib/get-current-user.ts
```ts
import { auth, currentUser } from "@clerk/nextjs/server";
import { db } from "@/db";
import { users } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function getOrCreateCurrentUser() {
  const { userId: clerkId } = await auth();
  if (!clerkId) return null;

  const existing = await db.select().from(users).where(eq(users.clerkId, clerkId)).limit(1);
  if (existing.length > 0) return existing[0];

  const clerkUser = await currentUser();
  if (!clerkUser) return null;

  const email = clerkUser.emailAddresses[0]?.emailAddress ?? "unknown@example.com";
  const name = [clerkUser.firstName, clerkUser.lastName].filter(Boolean).join(" ").trim() || "Anonymous";

  const [inserted] = await db.insert(users).values({ clerkId, email, name, imageUrl: clerkUser.imageUrl ?? null }).returning();
  return inserted;
}
```

## src/lib/authz.ts
```ts
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

## src/lib/ticket-code.ts
```ts
import { randomBytes } from "crypto";
export function generateTicketCode(): string {
  return randomBytes(8).toString("hex");
}
```

## src/lib/rsvp-rules.ts
```ts
export function decideRsvpStatus(confirmedCount: number, capacity: number): "confirmed" | "waitlisted" {
  return confirmedCount >= capacity ? "waitlisted" : "confirmed";
}
```

## src/lib/qrcode.ts
```ts
import QRCode from "qrcode";
export type TicketPayload = { rsvpId: string; code: string };

export async function generateTicketQrDataUrl(payload: TicketPayload): Promise<string> {
  const text = JSON.stringify(payload);
  return QRCode.toDataURL(text, { errorCorrectionLevel: "M", margin: 2, width: 320 });
}
```

## src/lib/email.ts (final, with idempotency key)
```ts
import { Resend } from "resend";

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM_ADDRESS = "EventHub <onboarding@resend.dev>";

export async function sendEmail(options: {
  to: string; subject: string; html: string;
  attachments?: { filename: string; content: string }[];
  idempotencyKey?: string;
}) {
  const result = await resend.emails.send(
    { from: FROM_ADDRESS, to: options.to, subject: options.subject, html: options.html, attachments: options.attachments },
    options.idempotencyKey ? { idempotencyKey: options.idempotencyKey } : undefined
  );
  if (result.error) throw new Error(`Failed to send email: ${result.error.message}`);
  return result;
}
```

**Next: Appendix A Part 3b (Server Actions continued)**
