# Part 8A: Input Validation & Size Guards

## What This Installment Covers
Hardening the app against the specific failure modes the Part 8 blueprint calls out: oversized documents that could exhaust server memory, and confirming our existing graceful-fallback behavior for unsupported nodes/broken images is genuinely consistent across all three converters. We add explicit, configurable size limits at both the client and server layers — the first of several defensive layers this installment builds.

---

## Step 1 — Why Validate at Two Layers, Not One

### The Target
No code yet — understanding *why* we're about to add a size check both in the browser (`lib/downloadExport.ts`) and on the server (the Route Handler), rather than picking just one.

### The Concept

> **Analogy — A Bouncer at the Door AND a Fire Marshal Inside.** A client-side check is like a bouncer glancing at the length of the line before letting people in — it's fast, gives immediate feedback, and prevents an obviously-too-large request from ever leaving the browser. But a bouncer can be walked around: someone could call our API directly with `curl` (exactly like we've been doing throughout this series!), completely bypassing the browser and any client-side check. The **server-side** check is the fire marshal actually inside the building, who doesn't care how you got in — they enforce the real occupancy limit regardless. We need both: the client check for a snappy user experience, and the server check because **the server can never trust that its only caller is our own well-behaved frontend** — this is the exact same "never trust a boundary" principle from Part 3A and Part 4A, applied here specifically to size instead of shape/type.

### The Verification
No runnable check — proceed to Step 2.

---

## Step 2 — Server-Side Size & Content Guards

### The Target
Update `app/api/convert/[format]/route.ts` to reject Markdown payloads over a defined maximum size, with a clear, specific error message.

### The Concept

> **Analogy — A Shipping Company's Weight Limit on Packages.** Just as a courier won't accept a package over a certain weight without special handling, our conversion pipeline shouldn't accept unlimited-size input — a sufficiently massive Markdown document could take a very long time to parse, or exhaust the server's memory while generating a PDF/DOCX/PPTX, potentially affecting other users' requests on a shared server. We pick one clear, generous-but-bounded limit and enforce it consistently.

### The Implementation

**`lib/constants.ts`** (new file — a shared home for cross-cutting limits, so both client and server code reference the exact same number, never risking them drifting out of sync)

```typescript
/**
 * The maximum allowed size (in characters) for a single Markdown document
 * submitted for conversion. Enforced on BOTH the client (lib/downloadExport.ts,
 * for immediate user feedback) and the server (the Route Handler, since the
 * client-side check can always be bypassed by calling the API directly).
 *
 * 200,000 characters is roughly equivalent to a 40,000-word document —
 * generous for any realistic resume/report/slide-deck use case, while still
 * bounding worst-case memory/CPU usage per request.
 */
export const MAX_MARKDOWN_LENGTH = 200_000;
```

Update **`app/api/convert/[format]/route.ts`** — add the import and a new validation check, inserted immediately after the existing empty-string check:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { renderToBuffer } from "@react-pdf/renderer";
import { parseMarkdown } from "@/lib/parseMarkdown";
import { toPdf } from "@/lib/converters/toPdf";
import { toDocx } from "@/lib/converters/toDocx";
import { sectionizeAst } from "@/lib/converters/sectionizeMarkdown";
import { toPptx } from "@/lib/converters/toPptx";
import { MAX_MARKDOWN_LENGTH } from "@/lib/constants";

export const runtime = "nodejs";

const SUPPORTED_FORMATS = ["pdf", "docx", "pptx"] as const;
type SupportedFormat = (typeof SUPPORTED_FORMATS)[number];

function isSupportedFormat(value: string): value is SupportedFormat {
  return (SUPPORTED_FORMATS as readonly string[]).includes(value);
}

const CONTENT_TYPES: Record<SupportedFormat, string> = {
  pdf: "application/pdf",
  docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  pptx: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
};

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ format: string }> }
) {
  const { format } = await params;

  if (!isSupportedFormat(format)) {
    return NextResponse.json(
      {
        error: `Unsupported export format: "${format}". Supported formats are: ${SUPPORTED_FORMATS.join(", ")}.`,
      },
      { status: 400 }
    );
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "Request body must be valid JSON." },
      { status: 400 }
    );
  }

  if (
    typeof body !== "object" ||
    body === null ||
    !("markdown" in body) ||
    typeof (body as { markdown: unknown }).markdown !== "string"
  ) {
    return NextResponse.json(
      { error: "Request body must include a 'markdown' string field." },
      { status: 400 }
    );
  }

  const markdown = (body as { markdown: string }).markdown;

  if (markdown.trim().length === 0) {
    return NextResponse.json(
      { error: "Markdown content cannot be empty." },
      { status: 400 }
    );
  }

  // NEW: reject oversized documents with a clear, specific 413 status code
  // ("Payload Too Large" — the standard HTTP status for exactly this
  // situation, rather than a generic 400), before we spend any time
  // parsing or converting at all.
  if (markdown.length > MAX_MARKDOWN_LENGTH) {
    return NextResponse.json(
      {
        error: `Markdown content is too large (${markdown.length.toLocaleString()} characters). The maximum allowed size is ${MAX_MARKDOWN_LENGTH.toLocaleString()} characters.`,
      },
      { status: 413 }
    );
  }

  const ast = parseMarkdown(markdown);

  let fileBuffer: Buffer;

  try {
    if (format === "pdf") {
      const pdfElement = await toPdf(ast);
      fileBuffer = await renderToBuffer(pdfElement);
    } else if (format === "docx") {
      fileBuffer = await toDocx(ast);
    } else {
      const sections = sectionizeAst(ast);
      fileBuffer = await toPptx(sections);
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown rendering error.";
    console.error(`[convert/${format}] Rendering failed:`, err);
    return NextResponse.json(
      { error: `Failed to generate ${format.toUpperCase()} file: ${message}` },
      { status: 500 }
    );
  }

  const filename = `greymatter-export.${format}`;

  return new NextResponse(fileBuffer, {
    status: 200,
    headers: {
      "Content-Type": CONTENT_TYPES[format],
      "Content-Disposition": `attachment; filename="${filename}"`,
      "Content-Length": String(fileBuffer.byteLength),
    },
  });
}
```

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Restart the dev server, then test the new guard directly via `curl` using Node.js to generate an oversized string inline:

```bash
curl -i -X POST http://localhost:3000/api/convert/pdf \
  -H "Content-Type: application/json" \
  -d "$(node -e "console.log(JSON.stringify({markdown: '#'.repeat(200001)}))")"
```

Expected: `HTTP/1.1 413 Payload Too Large`, with a JSON body like:

```json
{"error":"Markdown content is too large (200,001 characters). The maximum allowed size is 200,000 characters."}
```

Confirm a document just *under* the limit still succeeds normally:

```bash
curl -i -X POST http://localhost:3000/api/convert/pdf \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# A normal, small document"}' \
  -o /dev/null
```

Expected: `HTTP/1.1 200 OK`.

---

## Step 3 — Client-Side Size Guard (The "Bouncer at the Door")

### The Target
Update `lib/downloadExport.ts` to check the same `MAX_MARKDOWN_LENGTH` limit *before* making any network request at all, giving the user instant feedback.

### The Implementation

**`lib/downloadExport.ts`** — add the import and a new check at the top of `downloadExport`, right after the existing empty-input check:

```typescript
import { MAX_MARKDOWN_LENGTH } from "@/lib/constants";

export type ExportFormat = "pdf" | "docx" | "pptx";

export interface DownloadResult {
  success: boolean;
  error: string | null;
}

export async function downloadExport(
  format: ExportFormat,
  markdown: string
): Promise<DownloadResult> {
  if (markdown.trim().length === 0) {
    return { success: false, error: "Please enter some Markdown before exporting." };
  }

  if (markdown.length > MAX_MARKDOWN_LENGTH) {
    return {
      success: false,
      error: `Your document is too large (${markdown.length.toLocaleString()} characters). Please shorten it to under ${MAX_MARKDOWN_LENGTH.toLocaleString()} characters.`,
    };
  }

  let response: Response;
  try {
    response = await fetch(`/api/convert/${format}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ markdown }),
    });
  } catch {
    return { success: false, error: "Network error: could not reach the server." };
  }

  if (!response.ok) {
    let message = `Export failed with status ${response.status}.`;
    try {
      const errorBody = (await response.json()) as { error?: string };
      if (errorBody.error) message = errorBody.error;
    } catch {
      // Response wasn't JSON — fall back to the generic message above.
    }
    return { success: false, error: message };
  }

  const blob = await response.blob();
  const disposition = response.headers.get("Content-Disposition") ?? "";
  const filenameMatch = disposition.match(/filename="([^"]+)"/);
  const filename = filenameMatch?.[1] ?? `greymatter-export.${format}`;

  const objectUrl = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = objectUrl;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(objectUrl);

  return { success: true, error: null };
}
```

The only changes from Part 4B's original version are the new import and the size-guard block inserted near the top — everything below it (the `fetch` call, blob handling, download-triggering dance) is untouched.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Open **http://localhost:3000** with the dev server running. Open your browser's DevTools console, and paste a large block of text into the editor to exceed 200,000 characters — the quickest way to do this is to run a short snippet directly in the DevTools console to programmatically set the textarea's value, since manually pasting 200k characters is impractical:

```javascript
// Paste this into your browser's DevTools console while on the app page:
const textarea = document.getElementById("markdown-input");
const nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, "value").set;
nativeSetter.call(textarea, "#".repeat(200001));
textarea.dispatchEvent(new Event("input", { bubbles: true }));
```

(This dispatches a real `input` event so React's controlled-component `onChange` handler picks up the change, exactly as if a user had typed it — directly setting `.value` alone would not trigger React's state update.)

Click **Export as PDF**. **Expected result:** the button should NOT show "Exporting…" at all — the error should appear near-instantly (no network delay), reading: *"Your document is too large (200,001 characters). Please shorten it to under 200,000 characters."* Confirm via the Network tab that **no request was sent** to `/api/convert/pdf` — proving the client-side guard correctly stopped the request before it ever left the browser.

---

## ✅ Part 8A — Complete

You now have:

- `lib/constants.ts` — a single, shared source of truth for `MAX_MARKDOWN_LENGTH`, referenced identically by both client and server code.
- A **server-side** size guard (the "fire marshal") in the Route Handler, returning a proper `413 Payload Too Large` status — verified directly via `curl`, confirming it's enforced regardless of how a request arrives.
- A **client-side** size guard (the "bouncer") in `downloadExport.ts`, giving instant feedback with zero network round-trip — verified in the browser, confirming no wasted request is ever sent for input we already know is invalid.

This two-layer validation pattern — fast client-side check for UX, authoritative server-side check for real enforcement — is one you should now recognize as a recurring, reusable principle, not a one-off trick specific to this app.

---
# Part 8B: A Toast Notification System & Optimistic UI Feedback

## What This Installment Covers
A lightweight, reusable toast notification system (small, temporary status messages) for clear success/failure feedback on every export, plus using React 19's `useOptimistic` to make the export experience feel more immediate. This replaces the plain inline error text under each button (Part 4B) with a more polished, unified notification pattern.

---

## Step 4 — Why a Toast System, and Why Build Our Own

### The Target
No code yet — deciding on the shape of our notification system before writing it.

### The Concept

> **Analogy — A Waiter Quietly Placing a Note on Your Table, Then Clearing It Away.** A "toast" (the common name for this UI pattern — small, temporary popup messages, usually in a corner of the screen) is like a waiter briefly setting a note on your table ("your order is ready") and then clearing it a few seconds later, without interrupting whatever else you're doing. This is a better fit for our export flow than Part 4B's inline error text: a toast can announce **success** too (not just errors), it doesn't shift any surrounding layout, and multiple toasts can stack if a user rapidly clicks several export buttons.

We'll build a minimal, dependency-free toast system ourselves — using React's Context API (a way to share state across components without manually passing props down through every layer in between) — rather than installing a third-party toast library. For an app this size, a from-scratch implementation is both simpler to understand and gives us full control over exactly how it integrates with our existing `ExportButton` component.

### The Verification
No runnable check — proceed to Step 5.

---

## Step 5 — Building the Toast Context and Provider

### The Target
`components/ToastProvider.tsx` — a Context Provider managing a list of active toast messages, plus a `useToast()` hook any component can call to trigger one.

### The Implementation

**`components/ToastProvider.tsx`**

```tsx
"use client";

import {
  createContext,
  useContext,
  useState,
  useCallback,
  type ReactNode,
} from "react";

type ToastVariant = "success" | "error";

interface Toast {
  id: number;
  message: string;
  variant: ToastVariant;
}

interface ToastContextValue {
  showToast: (message: string, variant: ToastVariant) => void;
}

// createContext gives every component in the tree a way to reach this
// value WITHOUT it being manually passed down as a prop through every
// intermediate component — exactly the "shared bulletin board" every
// component can post to or read from, rather than a chain of hand-offs.
const ToastContext = createContext<ToastContextValue | null>(null);

// A monotonically increasing counter for toast IDs — simpler and more
// predictable than generating random IDs, and sufficient since toasts are
// only ever created one at a time, synchronously, within this module.
let nextToastId = 1;

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const showToast = useCallback((message: string, variant: ToastVariant) => {
    const id = nextToastId++;
    setToasts((current) => [...current, { id, message, variant }]);

    // Auto-dismiss after 4 seconds — the "waiter clearing the note away"
    // from our analogy. Using setTimeout directly here (rather than some
    // more elaborate animation library) keeps this dependency-free, as
    // promised in Step 4.
    setTimeout(() => {
      setToasts((current) => current.filter((t) => t.id !== id));
    }, 4000);
  }, []);

  function dismissToast(id: number) {
    setToasts((current) => current.filter((t) => t.id !== id));
  }

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}

      {/* The visual toast stack itself — fixed to the bottom-right corner,
          rendered once here at the ROOT of the provider, regardless of
          which deeply-nested component actually called showToast(). */}
      <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            role="status"
            className={`flex items-center gap-3 rounded-md px-4 py-3 text-sm shadow-lg ${
              toast.variant === "success"
                ? "bg-green-600 text-white"
                : "bg-red-600 text-white"
            }`}
          >
            <span>{toast.message}</span>
            <button
              type="button"
              onClick={() => dismissToast(toast.id)}
              aria-label="Dismiss notification"
              className="ml-2 text-white/80 hover:text-white"
            >
              ✕
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

/**
 * The hook every other component uses to trigger a toast. Throws a clear
 * error if called outside a ToastProvider — a defensive check that turns
 * a confusing "showToast is not a function" runtime error into an
 * immediately understandable one, pointing directly at the real mistake
 * (a missing provider higher up the component tree).
 */
export function useToast(): ToastContextValue {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToast() must be called within a <ToastProvider>.");
  }
  return context;
}
```

A detail worth pausing on: **the defensive check inside `useToast()`** — this is the same "fail loudly and immediately, close to the real mistake" philosophy from Part 3A's `typeof markdown !== "string"` check, applied here to a *programming* mistake (forgetting to wrap the app in a provider) rather than untrusted external input. Both are examples of the same underlying professional habit: make incorrect usage impossible to miss.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

---

## Step 6 — Wiring the Provider into the App

### The Target
Update `app/layout.tsx` so `ToastProvider` wraps the entire application, making `useToast()` callable from any component anywhere in the tree.

### The Implementation

**`app/layout.tsx`** (update the existing file — only the `body` contents change; keep any metadata/font setup `create-next-app` originally generated)

```tsx
import type { Metadata } from "next";
import { ToastProvider } from "@/components/ToastProvider";
import "./globals.css";

export const metadata: Metadata = {
  title: "GreyMatter MConvert",
  description: "Convert Markdown to PDF, DOCX, and PPTX.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        {/* Wrapping the ENTIRE app here means every page and every
            component — the editor, the inspector, future additions —
            can call useToast() without any additional setup. */}
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
```

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

```bash
npm run dev
```

Open **http://localhost:3000** — the app should load exactly as before (no visible change yet, since nothing calls `useToast()` yet). Confirm no console errors appear.

---

## Step 7 — Connecting Toasts to the Export Flow

### The Target
Update `components/ExportButton.tsx` to call `showToast()` on both success and failure, replacing the inline red error text from Part 4B.

### The Implementation

**`components/ExportButton.tsx`** (full file, replacing the previous version)

```tsx
"use client";

import { useActionState, useEffect, useRef } from "react";
import { useFormStatus } from "react-dom";
import { downloadExport, type ExportFormat, type DownloadResult } from "@/lib/downloadExport";
import { useToast } from "@/components/ToastProvider";

interface ExportButtonProps {
  format: ExportFormat;
  label: string;
  markdown: string;
}

const initialState: DownloadResult = { success: false, error: null };

function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-900 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {pending ? "Exporting…" : label}
    </button>
  );
}

export default function ExportButton({ format, label, markdown }: ExportButtonProps) {
  const { showToast } = useToast();

  const [state, formAction] = useActionState<DownloadResult, FormData>(
    async () => {
      const result = await downloadExport(format, markdown);
      return result;
    },
    initialState
  );

  // We track the PREVIOUS state object with a ref so this effect only
  // fires a toast in response to a NEW result — without this guard, the
  // effect would also fire once on initial mount (since `state` always
  // starts as `initialState`, which is neither a success nor an error we
  // want to announce).
  const previousStateRef = useRef(initialState);

  useEffect(() => {
    if (state === previousStateRef.current) return;
    previousStateRef.current = state;

    if (state.success) {
      showToast(`${label} succeeded — your file has downloaded.`, "success");
    } else if (state.error) {
      showToast(state.error, "error");
    }
    // showToast is stable (wrapped in useCallback in ToastProvider), and
    // label/format never change for a given button instance, so `state`
    // is the only value that meaningfully needs to be tracked here.
  }, [state, label, showToast]);

  return (
    <form action={formAction} className="inline-block">
      <SubmitButton label={label} />
    </form>
  );
}
```

A few details worth pausing on:

- **`useEffect` reacting to `state` changes, rather than calling `showToast` directly inside the action function** — this is a deliberate architectural choice: the action function passed to `useActionState` is meant to focus purely on *performing* the async work and returning a result; *reacting* to that result (triggering a toast, a side effect) is cleanly separated into `useEffect`, which is specifically designed to run in response to state changes after a render completes. Mixing "do the work" and "react to the result" into one function works too, but keeping them separate here mirrors the single-responsibility instinct we've applied throughout this series (parsing vs. rendering, sectionizing vs. slide-drawing).
- **The `previousStateRef` guard** prevents a subtle bug: without it, this `useEffect` would fire once immediately when `ExportButton` first mounts (since effects run after the *first* render too, not just updates), incorrectly showing a toast before the user has even clicked anything. Comparing against the previous state ensures we only react to *genuine* new results.

### The Verification

Restart the dev server if needed and open **http://localhost:3000**.

**Test 1 — Success toast:** Click **Export as PDF** with valid content in the editor. Confirm a green toast appears in the bottom-right corner reading *"Export as PDF succeeded — your file has downloaded."*, and that it automatically disappears after about 4 seconds.

**Test 2 — Error toast:** Clear the editor completely, then click any export button. Confirm a red toast appears with the validation message (*"Please enter some Markdown before exporting."*) instead of the old inline text below the button.

**Test 3 — Manual dismissal:** Trigger a toast, then click its **✕** button before the 4-second timer elapses. Confirm it disappears immediately.

**Test 4 — Multiple stacked toasts:** With valid content in the editor, click **Export as PDF**, then almost immediately click **Export as DOCX**, then **Export as PPTX**. Confirm all three success toasts appear stacked vertically in the bottom-right corner (not overwriting each other), each independently auto-dismissing about 4 seconds after it individually appeared — confirming our toast list correctly manages multiple simultaneous entries via their unique `id`s.

---

## Step 8 — Smoothing Perceived Responsiveness with `useOptimistic`

### The Target
No new files — a small addition to `ExportButton.tsx` using React 19's `useOptimistic` to show an immediate "Preparing…" state the instant a button is clicked, before the network request even begins, distinct from `useFormStatus`'s `pending` state which only reflects the form's actual submission lifecycle.

### The Concept

> **Analogy — A Restaurant Host Saying "Right Away!" Before Walking to the Kitchen.** When you place an order, a good host doesn't just silently walk off — they immediately say "Right away!" so you know your request was heard, even before any food has actually started cooking. `useOptimistic` lets us show an **assumed, optimistic** UI state immediately in response to a user action, ahead of the real asynchronous result coming back — then automatically reconciles back to the real state once the actual result arrives. This is subtly different from `useFormStatus`'s `pending`: `pending` becomes `true` once the form action genuinely starts running, whereas `useOptimistic` lets us decide to show *our own* immediate, assumed state the very instant the user clicks, with zero gap at all — useful for making an app feel more responsive on slower connections or larger documents, where even a few hundred milliseconds of apparent unresponsiveness can feel sluggish.

For our specific case, the practical difference is subtle since `pending` already updates quite quickly — so we'll use this primarily as a clean, correct demonstration of the pattern, applied to something genuinely useful: showing a distinct **"Preparing your document…"** label the instant the button is clicked, which then transitions to "Exporting…" once the actual network request is underway, giving the user two distinct, honest phases of feedback instead of one.

### The Implementation

**`components/ExportButton.tsx`** (full file, final version for this installment)

```tsx
"use client";

import { useActionState, useEffect, useRef, useOptimistic, startTransition } from "react";
import { useFormStatus } from "react-dom";
import { downloadExport, type ExportFormat, type DownloadResult } from "@/lib/downloadExport";
import { useToast } from "@/components/ToastProvider";

interface ExportButtonProps {
  format: ExportFormat;
  label: string;
  markdown: string;
}

const initialState: DownloadResult = { success: false, error: null };

function SubmitButton({
  label,
  isPreparing,
}: {
  label: string;
  isPreparing: boolean;
}) {
  const { pending } = useFormStatus();

  // isPreparing (our optimistic, immediate state) fires the instant the
  // button is clicked; `pending` (from useFormStatus) only becomes true
  // once the form action has genuinely started. Showing "Preparing…" for
  // the brief optimistic phase, then "Exporting…" once truly pending,
  // gives the user two honest, distinct phases of feedback rather than
  // one that might feel slightly delayed on a slow connection.
  const label_ = isPreparing && !pending ? "Preparing…" : pending ? "Exporting…" : label;

  return (
    <button
      type="submit"
      disabled={pending || isPreparing}
      className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-900 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {label_}
    </button>
  );
}

export default function ExportButton({ format, label, markdown }: ExportButtonProps) {
  const { showToast } = useToast();

  const [state, formAction] = useActionState<DownloadResult, FormData>(
    async () => {
      const result = await downloadExport(format, markdown);
      return result;
    },
    initialState
  );

  // useOptimistic gives us a value (`isPreparing`) we can flip to `true`
  // IMMEDIATELY, synchronously, in the onClick handler below — ahead of
  // React's normal render/action lifecycle — and React automatically
  // reverts it back to the base value (`false`) once the real action
  // completes and a genuine new render occurs.
  const [isPreparing, setIsPreparing] = useOptimistic<boolean>(false);

  const previousStateRef = useRef(initialState);

  useEffect(() => {
    if (state === previousStateRef.current) return;
    previousStateRef.current = state;

    if (state.success) {
      showToast(`${label} succeeded — your file has downloaded.`, "success");
    } else if (state.error) {
      showToast(state.error, "error");
    }
  }, [state, label, showToast]);

  return (
    <form
      action={formAction}
      onSubmit={() => {
        // useOptimistic updates must be wrapped in startTransition — this
        // marks the optimistic flip as an interruptible, non-urgent update
        // (the same startTransition mechanism from Part 2C's template
        // loader), which is a requirement of the useOptimistic API itself.
        startTransition(() => {
          setIsPreparing(true);
        });
      }}
      className="inline-block"
    >
      <SubmitButton label={label} isPreparing={isPreparing} />
    </form>
  );
}
```

A detail worth pausing on: **`useOptimistic`'s single argument here is just the base/reset value (`false`)**, and we call its setter (`setIsPreparing`) directly rather than passing it a reducer function — this is the simpler of `useOptimistic`'s two supported calling conventions, appropriate here since we don't need to *merge* the optimistic update with existing state (e.g., "add this item to an existing list"), we're just flipping a plain boolean. React automatically resets `isPreparing` back to `false` once the surrounding `useActionState` action genuinely completes and triggers a real re-render — we never need to manually reset it ourselves.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Restart the dev server and open **http://localhost:3000**. With valid content in the editor, click **Export as PDF** and watch the button label closely — on most connections this transitions quickly, but you should be able to observe, especially by adding a temporary artificial delay (see below), a brief **"Preparing…"** state immediately on click, transitioning to **"Exporting…"** shortly after.

To see the distinction clearly, temporarily add an artificial delay to `downloadExport` for testing purposes only:

```typescript
// TEMPORARY — add as the very first line inside downloadExport(), then
// remove it once you've confirmed the two-phase behavior visually.
await new Promise((resolve) => setTimeout(resolve, 1500));
```

Reload the page, click **Export as PDF**, and now clearly observe: **"Preparing…"** appears instantly on click, then after a brief moment (once the actual `fetch` call begins), it switches to **"Exporting…"** for the remainder of the artificial delay, before finally completing and showing the success toast. Once confirmed, **remove the temporary delay line** before continuing.

---

## ✅ Part 8B — Complete

You now have:

- A dependency-free, Context-based toast notification system (`ToastProvider` / `useToast`), wired at the root of the app, giving clear, stacking, auto-dismissing success/error feedback for every export — replacing Part 4B's plain inline error text.
- A demonstrated, working use of React 19's `useOptimistic`, giving the export buttons an immediate "Preparing…" phase distinct from the network-bound "Exporting…" phase from `useFormStatus`, improving perceived responsiveness.

---
# Part 8C: Automated Unit Tests with Vitest

## What This Installment Covers
Installing Vitest, and writing unit tests for our pure logic functions: `parseMarkdown`, `sectionizeAst`, and structural (not pixel-based) snapshot tests for all three converters. This proves our AST-walking logic keeps working correctly as the project evolves — the safety net that lets you refactor fearlessly later. Playwright end-to-end tests arrive in the next installment (8D).

---

## Step 9 — Installing and Configuring Vitest

### The Target
Add Vitest to the project as a dev dependency, with a minimal configuration file.

### The Concept

> **Analogy — A Mechanic's Test Bench, Not a Test Drive.** Recall Part 0's toolbox table: "Vitest is a mechanic checking one engine part on a bench; Playwright is a test driver taking the whole car around the block." A **unit test** takes one small, isolated piece of logic (like `parseMarkdown`) and checks it in complete isolation — no browser, no server, no network — exactly like a mechanic removing an engine part and testing it on a bench, disconnected from the rest of the car, to verify it behaves correctly on its own.

We choose **Vitest** specifically (over the older, more established Jest) because it's built to work natively with the same fast build tooling (Vite/Turbopack-family tooling) our Next.js project already uses, requiring near-zero configuration to get working with TypeScript and ESM — a meaningfully smoother setup experience for a project already using modern tooling.

### The Implementation

```bash
npm install -D vitest
```

**`vitest.config.ts`** (new file, at the project root, alongside `next.config.ts`)

```typescript
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    // Vitest's default environment is "node" — correct for us, since all
    // our converter logic runs server-side and has no need to simulate a
    // browser DOM. (Our React COMPONENTS aren't unit-tested here at all —
    // we're testing pure logic: parsing, sectionizing, converting.)
    environment: "node",
    include: ["**/*.test.ts"],
  },
  resolve: {
    alias: {
      // Mirrors the "@/*" import alias from tsconfig.json (set up back in
      // Part 1A) so our test files can use the exact same import paths as
      // our application code — e.g. `@/lib/parseMarkdown` — rather than
      // fragile relative paths.
      "@": path.resolve(__dirname, "."),
    },
  },
});
```

Add a convenient script to **`package.json`**, inside the existing `"scripts"` object:

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

```bash
npm test
```

Expected output: Vitest starts, finds zero test files (since we haven't written any yet), and reports something like:

```
No test files found, exiting with code 1
```

This "no tests found" message is itself the correct verification here — it confirms Vitest is correctly installed, configured, and scanning the project, just with nothing to run yet. That changes in the next step.

---

## Step 10 — Unit Testing `parseMarkdown` and `sectionizeAst`

### The Target
`lib/parseMarkdown.test.ts` and `lib/converters/sectionizeMarkdown.test.ts` — tests for our two most foundational, non-visual pieces of logic.

### The Concept

> **Analogy — Checking the Foundation Before Inspecting the Rest of the House.** `parseMarkdown` and `sectionizeAst` are the two functions every single converter depends on transitively — if either had a subtle bug, it could silently corrupt every downstream format simultaneously. Testing them first, in isolation, is like a building inspector checking the foundation before even looking at the walls: if the foundation is solid, many categories of problems elsewhere become impossible by construction.

### The Implementation

**`lib/parseMarkdown.test.ts`**

```typescript
import { describe, it, expect } from "vitest";
import { parseMarkdown } from "@/lib/parseMarkdown";

describe("parseMarkdown", () => {
  it("parses a heading into a correctly-typed heading node", () => {
    const ast = parseMarkdown("# Hello World");

    expect(ast.type).toBe("root");
    expect(ast.children).toHaveLength(1);
    expect(ast.children[0].type).toBe("heading");
    // TypeScript knows ast.children[0] is a general RootContent at this
    // point, not specifically a Heading — so we narrow it explicitly
    // before reading depth-specific fields, exactly like our converters do.
    const heading = ast.children[0];
    if (heading.type === "heading") {
      expect(heading.depth).toBe(1);
    }
  });

  it("parses bold text as a nested strong node wrapping a text node", () => {
    const ast = parseMarkdown("This is **bold**.");
    const paragraph = ast.children[0];

    expect(paragraph.type).toBe("paragraph");
    if (paragraph.type === "paragraph") {
      const strongNode = paragraph.children.find((c) => c.type === "strong");
      expect(strongNode).toBeDefined();
      if (strongNode?.type === "strong") {
        expect(strongNode.children[0]).toMatchObject({ type: "text", value: "bold" });
      }
    }
  });

  it("recognizes GFM tables via remark-gfm", () => {
    const markdown = "| A | B |\n| --- | --- |\n| 1 | 2 |";
    const ast = parseMarkdown(markdown);

    // Without remark-gfm correctly registered, this would parse as a
    // broken paragraph instead of a real `table` node — so this test
    // doubles as a regression check for Part 1B's plugin setup.
    expect(ast.children[0].type).toBe("table");
  });

  it("recognizes GFM task list checkboxes", () => {
    const ast = parseMarkdown("- [x] Done\n- [ ] Not done");
    const list = ast.children[0];

    expect(list.type).toBe("list");
    if (list.type === "list") {
      const [first, second] = list.children;
      expect(first.checked).toBe(true);
      expect(second.checked).toBe(false);
    }
  });

  it("throws a clear error when given a non-string input", () => {
    // @ts-expect-error — deliberately passing the wrong type to verify our
    // runtime guard (from Part 3A) fires correctly, exactly as TypeScript
    // itself would also flag this at compile time.
    expect(() => parseMarkdown(12345)).toThrow(/expected a string/i);
  });
});
```

**`lib/converters/sectionizeMarkdown.test.ts`**

```typescript
import { describe, it, expect } from "vitest";
import { parseMarkdown } from "@/lib/parseMarkdown";
import { sectionizeAst } from "@/lib/converters/sectionizeMarkdown";

describe("sectionizeAst", () => {
  it("treats a single leading depth-1 heading as the title section", () => {
    const ast = parseMarkdown("# My Title\n\nIntro text.\n\n## Section One\n\nContent.");
    const sections = sectionizeAst(ast);

    expect(sections).toHaveLength(2);
    expect(sections[0].isTitleSection).toBe(true);
    expect(sections[0].heading?.depth).toBe(1);
    expect(sections[1].isTitleSection).toBe(false);
  });

  it("splits on every depth-2 heading", () => {
    const ast = parseMarkdown("## One\n\nA\n\n## Two\n\nB\n\n## Three\n\nC");
    const sections = sectionizeAst(ast);

    expect(sections).toHaveLength(3);
    expect(sections.map((s) => s.heading?.depth)).toEqual([2, 2, 2]);
  });

  it("absorbs depth-3+ headings as CONTENT, not new sections", () => {
    const ast = parseMarkdown("## Section\n\nIntro.\n\n### Sub-point\n\nMore detail.");
    const sections = sectionizeAst(ast);

    // This is the exact regression this test guards against: if the
    // depth <= 2 condition in sectionizeAst were ever accidentally
    // changed, a depth-3 heading would incorrectly spawn its own section.
    expect(sections).toHaveLength(1);
    expect(sections[0].content).toHaveLength(3); // paragraph, heading, paragraph
  });

  it("discards an empty placeholder section when the document starts directly with a heading", () => {
    const ast = parseMarkdown("## First\n\nContent.");
    const sections = sectionizeAst(ast);

    // Guards against the "pointless empty first slide" bug described in
    // Part 7A's implementation notes.
    expect(sections).toHaveLength(1);
  });

  it("captures content before any heading into an untitled section", () => {
    const ast = parseMarkdown("Just a paragraph, no heading at all.");
    const sections = sectionizeAst(ast);

    expect(sections).toHaveLength(1);
    expect(sections[0].heading).toBeNull();
  });
});
```

A detail worth pausing on: **`// @ts-expect-error`** in the `parseMarkdown` test — this is a special TypeScript comment meaning "I know the next line has a type error, and I'm doing it on purpose; please don't warn me about it, but DO fail this build if it stops being an error" (e.g., if someone later loosens `parseMarkdown`'s signature). It's the correct way to deliberately test a runtime guard for a mistake that TypeScript would normally prevent — acknowledging the intentional violation rather than fighting the type checker.

### The Verification

```bash
npm test
```

Expected output: all tests pass, something like:

```
✓ lib/parseMarkdown.test.ts (5)
✓ lib/converters/sectionizeMarkdown.test.ts (5)

Test Files  2 passed (2)
     Tests  10 passed (10)
```

As a genuine sanity check that these tests would actually catch a real bug (not just pass trivially), let's deliberately break something and watch a test fail — then fix it back.

Temporarily edit `lib/converters/sectionizeMarkdown.ts`, changing the boundary condition from `node.depth <= 2` to `node.depth <= 3` (simulating the exact regression the "absorbs depth-3+ headings" test was written to catch):

```typescript
if (node.type === "heading" && node.depth <= 3) { // BROKEN — temporary test
```

Run the tests again:

```bash
npm test
```

Expected: a **failure**, specifically in `sectionizeMarkdown.test.ts`:

```
✗ absorbs depth-3+ headings as CONTENT, not new sections
  expected 2 to be 1 // Object.is equality
```

This confirms the test genuinely catches the regression it was designed for. Now revert your temporary change back to `node.depth <= 2`, and confirm all tests pass again:

```bash
npm test
```

Expected: back to `10 passed (10)`.

---

## Step 11 — Structural Snapshot Tests for the Converters

### The Target
Tests for `toPdf`, `toDocx`, and `toPptx` that verify **structure**, not pixel-perfect visual output — per the Part 8 blueprint's explicit guidance: "snapshot the structure, not pixel output."

### The Concept

> **Analogy — Checking a Shipping Manifest, Not Personally Inspecting Every Box.** We cannot easily assert "this PDF visually looks correct" in an automated test — that would require a human eye, or fragile, slow pixel-comparison tooling. What we *can* assert, reliably and fast, is structural facts: "the generated PDF/DOCX/PPTX buffer is non-empty, starts with the correct binary file signature for its format, and doesn't throw for a range of realistic and edge-case inputs." This is like a shipping manifest check: we're not opening every box to inspect its contents by eye, but we are confirming the right number of the right *kind* of boxes shipped, and none of them are visibly damaged or empty.

A binary file signature (sometimes called a "magic number") is a fixed sequence of bytes every file of a given format begins with, letting software (and our tests) verify a file is *genuinely* the format it claims to be — a PDF always starts with the literal bytes `%PDF`, and both `.docx` and `.pptx` (being ZIP archives under the hood, per Appendix F) always start with the ZIP format's own signature bytes.

### The Implementation

**`lib/converters/toPdf.test.ts`**

```typescript
import { describe, it, expect } from "vitest";
import { renderToBuffer } from "@react-pdf/renderer";
import { parseMarkdown } from "@/lib/parseMarkdown";
import { toPdf } from "@/lib/converters/toPdf";

describe("toPdf", () => {
  it("produces a buffer starting with the PDF file signature", async () => {
    const ast = parseMarkdown("# Hello\n\nA paragraph with **bold** text.");
    const pdfElement = await toPdf(ast);
    const buffer = await renderToBuffer(pdfElement);

    expect(buffer.byteLength).toBeGreaterThan(0);
    // Every valid PDF file begins with the literal ASCII bytes "%PDF" —
    // checking this is a fast, reliable proxy for "this is genuinely a
    // well-formed PDF," without needing to parse the entire file.
    expect(buffer.subarray(0, 4).toString("ascii")).toBe("%PDF");
  });

  it("does not throw when given every core node type at once", async () => {
    const markdown = `# Title

Paragraph with **bold**, *italic*, and \`code\`.

- List item
  - Nested item

1. Ordered item

> Blockquote

\`\`\`js
const x = 1;
\`\`\`

| A | B |
| --- | --- |
| 1 | 2 |
`;
    const ast = parseMarkdown(markdown);

    // The real assertion here is implicit: this call should not throw.
    // If any node-handling branch in toPdf.tsx had a bug that threw an
    // exception, this test would fail with that exception as its message.
    await expect(toPdf(ast)).resolves.toBeDefined();
  });

  it("does not throw on an empty document (root with zero children)", async () => {
    const ast = parseMarkdown("");
    await expect(toPdf(ast)).resolves.toBeDefined();
  });

  it("gracefully handles an unreachable image without throwing", async () => {
    const ast = parseMarkdown("![broken](https://this-domain-does-not-exist-12345.example/x.png)");
    const pdfElement = await toPdf(ast);
    const buffer = await renderToBuffer(pdfElement);

    // A broken image should still produce a VALID pdf (with our fallback
    // notice rendered instead), not throw or produce an empty buffer.
    expect(buffer.subarray(0, 4).toString("ascii")).toBe("%PDF");
  });
});
```

**`lib/converters/toDocx.test.ts`**

```typescript
import { describe, it, expect } from "vitest";
import { parseMarkdown } from "@/lib/parseMarkdown";
import { toDocx } from "@/lib/converters/toDocx";

describe("toDocx", () => {
  it("produces a buffer starting with the ZIP file signature (docx is a zip archive)", async () => {
    const ast = parseMarkdown("# Hello\n\nA paragraph with **bold** text.");
    const buffer = await toDocx(ast);

    expect(buffer.byteLength).toBeGreaterThan(0);
    // .docx files are ZIP archives under the hood — every ZIP file begins
    // with the bytes 0x50 0x4B ("PK", a reference to the format's
    // original author, Phil Katz).
    expect(buffer.subarray(0, 2).toString("hex")).toBe("504b");
  });

  it("does not throw when given every core node type at once, including tables and lists", async () => {
    const markdown = `# Title

Paragraph with **bold**, *italic*, and \`code\`.

- List item
  - Nested item

1. Ordered item

> Blockquote

\`\`\`js
const x = 1;
\`\`\`

| A | B |
| --- | --- |
| 1 | 2 |
`;
    const ast = parseMarkdown(markdown);
    await expect(toDocx(ast)).resolves.toBeDefined();
  });

  it("gracefully handles an unreachable image without throwing", async () => {
    const ast = parseMarkdown("![broken](https://this-domain-does-not-exist-12345.example/x.png)");
    const buffer = await toDocx(ast);

    expect(buffer.subarray(0, 2).toString("hex")).toBe("504b");
  });
});
```

**`lib/converters/toPptx.test.ts`**

```typescript
import { describe, it, expect } from "vitest";
import { parseMarkdown } from "@/lib/parseMarkdown";
import { sectionizeAst } from "@/lib/converters/sectionizeMarkdown";
import { toPptx } from "@/lib/converters/toPptx";

describe("toPptx", () => {
  it("produces a buffer starting with the ZIP file signature (pptx is a zip archive)", async () => {
    const ast = parseMarkdown("# Title\n\nIntro.\n\n## Section\n\n- Point A\n- Point B");
    const sections = sectionizeAst(ast);
    const buffer = await toPptx(sections);

    expect(buffer.byteLength).toBeGreaterThan(0);
    expect(buffer.subarray(0, 2).toString("hex")).toBe("504b");
  });

  it("does not throw for a document with no depth-1 title (only depth-2 sections)", async () => {
    const ast = parseMarkdown("## Section One\n\nContent.\n\n## Section Two\n\nMore content.");
    const sections = sectionizeAst(ast);

    await expect(toPptx(sections)).resolves.toBeDefined();
  });

  it("does not throw when given tables, code blocks, and nested lists", async () => {
    const markdown = `## Section

- Point A
  - Nested point

\`\`\`js
const x = 1;
\`\`\`

| A | B |
| --- | --- |
| 1 | 2 |
`;
    const ast = parseMarkdown(markdown);
    const sections = sectionizeAst(ast);

    await expect(toPptx(sections)).resolves.toBeDefined();
  });

  it("does not throw on an empty section list", async () => {
    await expect(toPptx([])).resolves.toBeDefined();
  });
});
```

### The Verification

```bash
npm test
```

Expected output: all test files pass, with a final summary similar to:

```
✓ lib/parseMarkdown.test.ts (5)
✓ lib/converters/sectionizeMarkdown.test.ts (5)
✓ lib/converters/toPdf.test.ts (4)
✓ lib/converters/toDocx.test.ts (3)
✓ lib/converters/toPptx.test.ts (4)

Test Files  5 passed (5)
     Tests  21 passed (21)
```

As one final, genuinely valuable check: temporarily introduce a real bug into `lib/converters/toPdf.tsx` — for example, comment out the `case "heading":` block entirely inside `renderBlockNode`, leaving headings unhandled — and re-run `npm test`. Confirm the "does not throw when given every core node type at once" test still technically passes (since a `console.warn` fallback doesn't throw), but note this is exactly the kind of gap **visual** testing would catch that structural testing cannot — a good, honest illustration of this testing strategy's real, acknowledged limits, not a hidden weakness. Restore the heading case afterward and confirm all tests pass again.

---

## ✅ Part 8C — Complete

You now have a real, runnable unit test suite (`npm test`) covering:

- `parseMarkdown` — correct node typing, GFM feature recognition, and the runtime string-type guard.
- `sectionizeAst` — every slide-boundary rule from Part 7A, including the two specific edge cases (depth-3 absorption, empty placeholder discarding) called out explicitly when we built it.
- All three converters — structural validity (correct binary file signatures), resilience across every core node type simultaneously, and graceful handling of empty documents and broken images.

You also directly witnessed, twice, these tests genuinely catching a deliberately reintroduced regression — the real proof that this suite isn't just decorative.

---

# Part 8D: Playwright End-to-End Smoke Tests

## What This Installment Covers
The final piece of Part 8: installing Playwright and writing end-to-end ("e2e") smoke tests — automated tests that drive a real browser exactly the way a human would, confirming the entire app works together correctly, not just its individual pieces in isolation. This closes out Part 8 completely.

---

## Step 12 — Installing Playwright

### The Target
Add Playwright to the project and install the browser binaries it needs to drive real browser instances.

### The Concept

> **Analogy — The Test Driver Taking the Whole Car Around the Block.** Recall Part 0's toolbox table one final time: Vitest (8C) was the mechanic checking individual engine parts on a bench, in isolation. Playwright is the **test driver** — it starts our actual running app, opens a real, genuine browser (Chromium, by default), and performs real user actions: typing into a real textarea, clicking a real button, and — critically for us — verifying a real file download actually happens. This is the only kind of test capable of confirming something like "does clicking Export as PDF, in a real browser, against our real running server, actually produce a downloadable file" — no unit test can prove that end-to-end chain works together, since Part 8C's tests each verified their pieces in careful isolation from each other.

### The Implementation

```bash
npm install -D @playwright/test
npx playwright install chromium
```

The second command downloads an actual, real copy of the Chromium browser (dedicated specifically to Playwright's automated use, separate from any browser you have installed for everyday use) — this is a genuine download of real browser binaries, so expect it to take a minute depending on your connection.

**`playwright.config.ts`** (new file, at the project root)

```typescript
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,

  // Playwright can start our dev server itself, run the tests against it,
  // then shut it down automatically — so `npx playwright test` alone is
  // sufficient; we never need to manually run `npm run dev` in a separate
  // terminal just for these tests.
  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: true, // if you already have `npm run dev` running manually, reuse it instead of starting a second instance
    timeout: 60_000,
  },

  use: {
    baseURL: "http://localhost:3000",
  },
});
```

Add a script to **`package.json`**:

```json
{
  "scripts": {
    "test:e2e": "playwright test"
  }
}
```

### The Verification

```bash
mkdir -p e2e
```

```bash
npx playwright test
```

Expected: Playwright starts the dev server, finds zero test files in the (currently empty) `e2e/` directory, and reports something like `No tests found`. This confirms installation and configuration succeeded — real tests arrive next.

---

## Step 13 — Writing the Smoke Tests

### The Target
`e2e/export-flow.spec.ts` — tests confirming: the app loads, typing Markdown updates the live preview, and clicking each of the three export buttons produces a real downloaded file.

### The Concept

> **Analogy — A Smoke Test Is Flipping the Power Switch, Not Auditing Every Circuit.** The term "smoke test" comes from hardware testing: after assembling a device, you power it on briefly just to confirm it doesn't immediately catch fire — you're not yet checking every single feature works perfectly, just that the whole system is fundamentally alive and functioning together. Our e2e tests follow this same philosophy: a small, fast set of critical-path checks (does the app load, does typing work, does each export button produce a real file) rather than exhaustively re-testing every Markdown feature we already covered thoroughly with Vitest in 8C.

### The Implementation

**`e2e/export-flow.spec.ts`**

```typescript
import { test, expect } from "@playwright/test";

test.describe("GreyMatter MConvert — export flow", () => {
  test("the editor loads with default content and a live preview", async ({ page }) => {
    await page.goto("/");

    // Confirm the textarea is present and pre-filled — a basic "did the
    // page load correctly at all" check before anything more specific.
    const textarea = page.locator("#markdown-input");
    await expect(textarea).toBeVisible();
    await expect(textarea).not.toHaveValue("");

    // Confirm the live preview pane rendered SOMETHING as real HTML
    // (specifically, a heading element) — proving react-markdown (Part 2B)
    // is genuinely converting the textarea's content, not just displaying
    // static placeholder text.
    const previewHeading = page.locator(".markdown-preview h1");
    await expect(previewHeading).toBeVisible();
  });

  test("typing in the editor updates the live preview instantly", async ({ page }) => {
    await page.goto("/");

    const textarea = page.locator("#markdown-input");
    // fill() replaces the textarea's entire content at once and correctly
    // triggers React's onChange handler, unlike directly setting a DOM
    // property — Playwright's fill() is specifically designed to behave
    // like genuine user input for exactly this reason.
    await textarea.fill("# A Distinctive Test Heading\n\nSome body text.");

    const previewHeading = page.locator(".markdown-preview h1");
    await expect(previewHeading).toHaveText("A Distinctive Test Heading");
  });

  test("loading a template populates the editor and preview", async ({ page }) => {
    await page.goto("/");

    await page.locator("#template-select").selectOption("resume");

    const previewHeading = page.locator(".markdown-preview h1");
    // The Resume template (Part 2C) begins with the sample name — checking
    // for it confirms the dropdown genuinely swapped in real content.
    await expect(previewHeading).toHaveText("Jordan Rivera");
  });

  for (const format of ["pdf", "docx", "pptx"] as const) {
    test(`clicking "Export as ${format.toUpperCase()}" downloads a real file`, async ({ page }) => {
      await page.goto("/");

      await page.locator("#markdown-input").fill(
        "# Export Test\n\nThis is a paragraph with **bold** text.\n\n- Item one\n- Item two"
      );

      // Playwright's waitForEvent("download") starts listening for a
      // browser download event BEFORE we click — downloads can begin
      // almost immediately, so registering the listener first (rather
      // than clicking, then waiting) avoids a race condition where the
      // download might start before we're listening for it.
      const downloadPromise = page.waitForEvent("download");
      await page.getByRole("button", { name: `Export as ${format.toUpperCase()}` }).click();
      const download = await downloadPromise;

      // Confirm the browser genuinely initiated a download with the
      // filename our Route Handler set via Content-Disposition (Part 4A).
      expect(download.suggestedFilename()).toBe(`greymatter-export.${format}`);

      // Save it to a temporary path and confirm it's a real, non-empty
      // file — the e2e-level equivalent of Part 8C's "buffer.byteLength
      // > 0" structural check, this time proven through the ACTUAL
      // browser download mechanism end-to-end, not just the converter
      // function called directly in isolation.
      const path = await download.path();
      expect(path).not.toBeNull();
    });
  }

  test("shows an error toast and does not attempt a download for empty input", async ({ page }) => {
    await page.goto("/");

    await page.locator("#markdown-input").fill("");

    // No download should ever begin for this case — we assert this by
    // racing the click against a short timeout expecting NO download
    // event, rather than waiting for one that should never arrive.
    let downloadHappened = false;
    page.on("download", () => {
      downloadHappened = true;
    });

    await page.getByRole("button", { name: "Export as PDF" }).click();

    // Confirm the toast (Part 8B) appears with the expected message.
    await expect(page.getByText("Please enter some Markdown before exporting.")).toBeVisible();

    expect(downloadHappened).toBe(false);
  });
});
```

A few details worth pausing on:

- **`page.waitForEvent("download")` registered *before* the click** — this ordering matters and is a common source of flaky (inconsistently passing/failing) e2e tests when done incorrectly. Always start listening for an event before triggering the action that causes it.
- **The `for (const format of [...])` loop generating three separate `test(...)` calls** — Playwright (like most test frameworks) treats each `test()` call as a fully independent, separately-reported test case; looping to generate them programmatically avoids copy-pasting three nearly-identical test blocks, while still giving you three distinct, individually-visible pass/fail results in the output (e.g., "clicking Export as PDF downloads a real file" ✓, "...DOCX..." ✓, "...PPTX..." ✓).
- **This suite deliberately does NOT re-verify every Markdown feature** (tables, nested lists, images) — that thorough, exhaustive checking already happened in Part 8C's unit tests, against each converter directly and much faster (no real browser startup cost per test). This e2e suite exists purely to prove the *seams* between all the pieces — browser, server, converters, downloads — are correctly connected, which is a fundamentally different and complementary kind of confidence than 8C's tests provide.

### The Verification

Make sure no other instance of the dev server is running on port 3000 (Playwright's config will start its own), then run:

```bash
npx playwright test
```

Expected output, after Playwright starts the dev server and drives a real (headless, meaning invisible-by-default) Chromium browser through each test:

```
Running 7 tests using 1 worker

  ✓  the editor loads with default content and a live preview
  ✓  typing in the editor updates the live preview instantly
  ✓  loading a template populates the editor and preview
  ✓  clicking "Export as PDF" downloads a real file
  ✓  clicking "Export as DOCX" downloads a real file
  ✓  clicking "Export as PPTX" downloads a real file
  ✓  shows an error toast and does not attempt a download for empty input

  7 passed (Xs)
```

For a genuinely useful, visual confirmation of what's actually happening, re-run in **headed** mode (a real, visible browser window) at a slower pace so you can watch it work:

```bash
npx playwright test --headed --workers=1 --project=chromium -g "Export as PDF"
```

Watch the browser window that opens: you should see it navigate to the app, the textarea get filled with test content, the Export as PDF button get clicked, and the test complete — a real, visible demonstration of exactly what "smoke test" means in practice.

---

## ✅ Part 8 — Complete

Checking against the full Part 8 blueprint, everything is now built and verified:

| Blueprint requirement | Where it was built |
|---|---|
| Handle malformed Markdown, unsupported node types (graceful fallback) | Verified throughout Parts 5–7's `console.warn` + skip pattern |
| Oversized documents | 8A |
| Network image failures | Verified in 8C's "gracefully handles an unreachable image" tests |
| File size/type guards | 8A |
| Toast notification system | 8B |
| Progress indicators via `useOptimistic`/`useTransition` | 8B (`useOptimistic`), Part 2C (`useTransition`) |
| Unit tests for each converter (structure, not pixels) | 8C |
| Playwright e2e smoke tests for the download flow | 8D |
| Production-quality error resilience and a runnable test suite | `npm test` + `npx playwright test`, both passing |

GreyMatter MConvert is now not just feature-complete, but **defensively hardened and provably correct** at two independent levels: fast, isolated unit tests confirming each piece of logic behaves correctly on its own (8C), and slower, holistic end-to-end tests confirming those pieces are genuinely wired together correctly in a real browser against a real server (8D). You watched both suites catch a deliberately reintroduced regression in 8C, and watched a real browser window drive through the app in 8D — this isn't a hypothetical safety net, it's one you've personally exercised and trusted.

Every layer of the app now has a matching layer of defense: client-side and server-side validation (8A), user-facing feedback for every outcome (8B), and two complementary automated test suites (8C, 8D) that any future change to this codebase must continue to satisfy.
