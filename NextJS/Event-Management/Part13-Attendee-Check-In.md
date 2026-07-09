# **Part 12: QR Code Ticket Generation**:

---

# Part 12: QR Code Ticket Generation

Generate real, scannable QR codes entirely server-side using the `qrcode` package — no external API, no cost. Continues editing the same `/my-rsvps/[id]` route from Part 11.

## 1. What the QR code encodes
A small JSON payload: the RSVP's `id` and `ticketCode`. At check-in (Part 13), we parse it, look up the RSVP by id, verify `ticketCode` matches — a lightweight tamper-check.
```json
{ "rsvpId": "b3f1...", "code": "a1b2c3d4e5f6a7b8" }
```

## 2. QR code helper
```ts
// src/lib/qrcode.ts
import QRCode from "qrcode";

export type TicketPayload = { rsvpId: string; code: string };

export async function generateTicketQrDataUrl(payload: TicketPayload): Promise<string> {
  const text = JSON.stringify(payload);
  const dataUrl = await QRCode.toDataURL(text, {
    errorCorrectionLevel: "M",
    margin: 2,
    width: 320,
  });
  return dataUrl;
}
```
`toDataURL` renders a PNG and base64-encodes it in memory — nothing written to disk, no cost.

## 3. Update ticket page to render the real QR code

`src/app/my-rsvps/[id]/page.tsx` (same file, same `Promise<{ id: string }>` params):
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

  const rsvp = await db.query.rsvps.findFirst({
    where: eq(rsvps.id, id),
    with: { event: true, checkIn: true },
  });

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
Uses plain `<img>` (not `next/image` — its optimizer doesn't suit base64 data URLs well for a tiny, freshly-generated image). Also fetches `checkIn: true` ahead of time (via Part 7's relation) so this file won't need revisiting once Part 13/14 add real check-ins.

## 4. Try it out
`/my-rsvps` → "View ticket" → real scannable QR code + fallback text code. Scanning with a phone shows raw JSON (expected — Part 13 makes it functional).

## Checkpoint
- [ ] Real QR code renders
- [ ] Scanning shows the expected JSON payload
- [ ] Cancelled RSVPs show "cancelled" message instead of a QR code

**Next: Part 13 — Attendee Check-In Flow**
