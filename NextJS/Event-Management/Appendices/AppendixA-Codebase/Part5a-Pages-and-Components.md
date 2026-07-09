# **Appendix A Part 5a: Pages and Components**:

---

# Appendix A Part 5: Pages and Components

Client components below receive plain props, never route `params` directly — no async-params handling needed here (that applies to Server Component pages in 5b/5c/5d).

## src/components/site-header.tsx
```tsx
import Link from "next/link";
import { SignedIn, SignedOut, SignInButton, SignUpButton, UserButton } from "@clerk/nextjs";

export function SiteHeader() {
  return (
    <header className="border-b border-gray-200">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-xl font-bold text-gray-900">EventHub</Link>
        <nav className="flex items-center gap-4 text-sm">
          <Link href="/events" className="text-gray-700 hover:text-gray-900">Browse Events</Link>
          <SignedIn>
            <Link href="/dashboard" className="text-gray-700 hover:text-gray-900">My Dashboard</Link>
            <Link href="/my-rsvps" className="text-gray-700 hover:text-gray-900">My RSVPs</Link>
            <UserButton afterSignOutUrl="/" />
          </SignedIn>
          <SignedOut>
            <SignInButton mode="modal"><button className="rounded-md px-3 py-1.5 text-gray-700 hover:bg-gray-100">Sign in</button></SignInButton>
            <SignUpButton mode="modal"><button className="rounded-md bg-gray-900 px-3 py-1.5 text-white hover:bg-gray-700">Sign up</button></SignUpButton>
          </SignedOut>
        </nav>
      </div>
    </header>
  );
}
```

## src/components/rsvp-form.tsx
```tsx
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

## src/components/checkin-scanner.tsx
```tsx
"use client";
import { useEffect, useRef, useState } from "react";
import { checkInByCode } from "@/lib/actions/checkin";

export function CheckInScanner({ eventId }: { eventId: string }) {
  const [manualCode, setManualCode] = useState("");
  const [status, setStatus] = useState<{ type: "success" | "error"; message: string } | null>(null);
  const [scannerActive, setScannerActive] = useState(false);
  const scannerRef = useRef<any>(null);

  async function handleResult(rawText: string) {
    const result = await checkInByCode(rawText, eventId);
    if (result.ok) setStatus({ type: "success", message: `Checked in ${result.attendeeName} for ${result.eventTitle}!` });
    else setStatus({ type: "error", message: result.message });
  }

  async function startScanner() {
    const { Html5Qrcode } = await import("html5-qrcode");
    const scanner = new Html5Qrcode("qr-reader");
    scannerRef.current = scanner;
    setScannerActive(true);
    await scanner.start({ facingMode: "environment" }, { fps: 10, qrbox: 250 },
      async (decodedText: string) => { await handleResult(decodedText); await scanner.pause(true); setTimeout(() => scanner.resume(), 2000); },
      () => {}
    );
  }

  async function stopScanner() {
    if (scannerRef.current) { await scannerRef.current.stop(); scannerRef.current.clear(); }
    setScannerActive(false);
  }

  useEffect(() => { return () => { if (scannerRef.current) scannerRef.current.stop().catch(() => {}); }; }, []);

  return (
    <div className="mt-6 space-y-6">
      <div>
        {!scannerActive ? (
          <button onClick={startScanner} className="rounded-md bg-gray-900 px-4 py-2 text-white hover:bg-gray-700">Start camera scanner</button>
        ) : (
          <button onClick={stopScanner} className="rounded-md border border-gray-300 px-4 py-2 hover:bg-gray-50">Stop scanner</button>
        )}
        <div id="qr-reader" className="mt-4 w-full max-w-sm" />
      </div>
      <form onSubmit={async (e) => { e.preventDefault(); if (!manualCode.trim()) return; await handleResult(manualCode.trim()); setManualCode(""); }} className="flex gap-2">
        <input value={manualCode} onChange={(e) => setManualCode(e.target.value)} placeholder="Or type ticket code manually" className="flex-1 rounded-md border border-gray-300 px-3 py-2 font-mono text-sm" />
        <button type="submit" className="rounded-md bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-700">Check in</button>
      </form>
      {status && <div className={`rounded-md p-4 text-sm ${status.type === "success" ? "bg-green-50 text-green-800" : "bg-red-50 text-red-800"}`}>{status.message}</div>}
    </div>
  );
}
```

## src/components/attendee-list.tsx
```tsx
"use client";
import { useEffect, useState } from "react";
import { getEventAttendeeStats } from "@/lib/actions/checkin";

type Stats = Awaited<ReturnType<typeof getEventAttendeeStats>>;

export function AttendeeList({ eventId, initialStats }: { eventId: string; initialStats: Stats }) {
  const [stats, setStats] = useState<Stats>(initialStats);

  useEffect(() => {
    const interval = setInterval(async () => {
      try { setStats(await getEventAttendeeStats(eventId)); } catch { /* ignore, next poll retries */ }
    }, 4000);
    return () => clearInterval(interval);
  }, [eventId]);

  const percent = stats.totalConfirmed === 0 ? 0 : Math.round((stats.totalCheckedIn / stats.totalConfirmed) * 100);

  return (
    <div>
      <div className="rounded-lg border border-gray-200 p-4">
        <p className="text-3xl font-bold text-gray-900">{stats.totalCheckedIn} / {stats.totalConfirmed}</p>
        <p className="text-sm text-gray-600">checked in ({percent}%)</p>
        <div className="mt-2 h-2 w-full rounded-full bg-gray-100"><div className="h-2 rounded-full bg-green-600 transition-all" style={{ width: `${percent}%` }} /></div>
      </div>
      <ul className="mt-4 max-h-96 divide-y divide-gray-200 overflow-y-auto rounded-lg border border-gray-200">
        {stats.attendees.map((a) => (
          <li key={a.id} className="flex items-center justify-between px-4 py-2 text-sm">
            <span className="text-gray-900">{a.user.name}</span>
            {a.checkIn ? <span className="rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-800">Checked in</span>
              : <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">Not yet</span>}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

**Next: Appendix A Part 5b (Pages continued)**
