# **Appendix A Part 5d: My-RSVPs and Admin Pages** (final piece of Appendix A):

---

# Appendix A Part 5d: My-RSVPs and Admin Pages

`/my-rsvps/[id]` types `params` as `Promise<{ id: string }>`, awaited. `/my-rsvps` and `/admin` are static — no params.

## src/app/my-rsvps/page.tsx
```tsx
import Link from "next/link";
import { db } from "@/db";
import { rsvps } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { eq, and, ne } from "drizzle-orm";

export default async function MyRsvpsPage() {
  const user = await getOrCreateCurrentUser();
  if (!user) return null;

  const myRsvps = await db.query.rsvps.findMany({
    where: and(eq(rsvps.userId, user.id), ne(rsvps.status, "cancelled")),
    with: { event: true },
  });
  myRsvps.sort((a, b) => new Date(a.event.startsAt).getTime() - new Date(b.event.startsAt).getTime());

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-900">My RSVPs</h1>
      {myRsvps.length === 0 ? (
        <p className="mt-8 text-gray-600">You haven&apos;t RSVPed to any events yet. <Link href="/events" className="underline">Browse events</Link>.</p>
      ) : (
        <ul className="mt-8 divide-y divide-gray-200">
          {myRsvps.map((rsvp) => (
            <li key={rsvp.id} className="py-4">
              <div className="flex items-center justify-between">
                <div>
                  <Link href={`/events/${rsvp.event.id}`} className="text-lg font-medium text-gray-900 hover:underline">{rsvp.event.title}</Link>
                  <p className="text-sm text-gray-600">{new Date(rsvp.event.startsAt).toLocaleString()} · {rsvp.event.location}</p>
                  <p className="mt-1 text-xs font-mono text-gray-500">Ticket: {rsvp.ticketCode}</p>
                </div>
                <Link href={`/my-rsvps/${rsvp.id}`} className="rounded-md border border-gray-300 px-3 py-1.5 text-sm hover:bg-gray-50">View ticket</Link>
              </div>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
```

## src/app/my-rsvps/[id]/page.tsx (final, real QR code)
```tsx
import { db } from "@/db";
import { rsvps } from "@/db/schema";
import { eq } from "drizzle-orm";
import { notFound } from "next/navigation";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { generateTicketQrDataUrl } from "@/lib/qrcode";

export default async function TicketPage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getOrCreateCurrentUser();
  if (!user) return null;

  const rsvp = await db.query.rsvps.findFirst({ where: eq(rsvps.id, id), with: { event: true, checkIn: true } });

  if (!rsvp) notFound();
  if (rsvp.userId !== user.id) {
    return <main className="mx-auto max-w-2xl px-4 py-12"><p className="text-red-600">This ticket does not belong to you.</p></main>;
  }

  const qrDataUrl = await generateTicketQrDataUrl({ rsvpId: rsvp.id, code: rsvp.ticketCode });

  return (
    <main className="mx-auto max-w-md px-4 py-12">
      <h1 className="text-xl font-bold text-gray-900">{rsvp.event.title}</h1>
      <p className="mt-1 text-sm text-gray-600">{new Date(rsvp.event.startsAt).toLocaleString()}</p>
      <p className="text-sm text-gray-600">{rsvp.event.location}</p>
      <div className="mt-6 rounded-lg border border-gray-200 p-6 text-center">
        {rsvp.status === "cancelled" ? (
          <p className="text-red-600">This RSVP has been cancelled.</p>
        ) : rsvp.checkIn ? (
          <div>
            <p className="font-medium text-green-700">Checked in at {new Date(rsvp.checkIn.checkedInAt).toLocaleString()}</p>
            <img src={qrDataUrl} alt="Ticket QR code" className="mx-auto mt-4 w-64 opacity-40" />
          </div>
        ) : (
          <div>
            <p className="text-sm text-gray-500">Show this QR code at check-in</p>
            <img src={qrDataUrl} alt="Ticket QR code" className="mx-auto mt-4 w-64" />
          </div>
        )}
        <p className="mt-4 font-mono text-sm text-gray-500">{rsvp.ticketCode}</p>
      </div>
    </main>
  );
}
```

## src/app/admin/page.tsx (static, no params)
```tsx
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

## src/lib/rsvp-rules.test.ts
```ts
import { describe, it, expect } from "vitest";
import { decideRsvpStatus } from "./rsvp-rules";

describe("decideRsvpStatus", () => {
  it("confirms when there is room", () => expect(decideRsvpStatus(5, 10)).toBe("confirmed"));
  it("waitlists when at exact capacity", () => expect(decideRsvpStatus(10, 10)).toBe("waitlisted"));
  it("waitlists when over capacity", () => expect(decideRsvpStatus(15, 10)).toBe("waitlisted"));
  it("confirms the very first RSVP", () => expect(decideRsvpStatus(0, 1)).toBe("confirmed"));
});
```

**This concludes Appendix A** — every file in the finished project, validated against Next.js 16 and Tailwind v4.

**Next: Appendix B — Environment Variables Reference.**
