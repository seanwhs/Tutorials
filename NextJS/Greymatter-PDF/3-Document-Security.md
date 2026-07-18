# Part 3: Document Security and Stream Isolation with proxy.ts

*(Phase 1 — Core Architecture and High-Performance Rendering)*

## Why this part exists

At the end of Part 2, our `PdfViewer` worked by fetching a file directly from a hardcoded path in `public/test-pdfs/`. That folder is served by Next.js as-is, to anyone, with no login check, no permission check — literally anyone who guesses or discovers the URL can download the raw file. For a real document product where users upload contracts, medical records, or financial statements, this is completely unacceptable.

Analogy: think of `public/` like a bulletin board in the lobby of an office building — anyone walking by can read whatever is pinned there. What we actually want is more like a bank's safe deposit box room: a teller (our server) checks your ID (session token) before retrieving your specific box (PDF file) from the vault (object storage), and even then, hands it to you piece by piece under supervision rather than letting you walk into the vault yourself.

In this part we build that "teller" as a Next.js route file conventionally named `proxy.ts`, running on the Node.js runtime (not the lighter, more restricted Edge runtime, because we need full Node.js APIs to talk to storage SDKs and streams). This route will:

1. Check that the requesting user has a valid session and permission to view the specific document.
2. Look up where the real file lives in object storage (not in `public/`, and not even reachable directly from the browser).
3. Stream the file's bytes back in chunks, rather than loading the whole file into server memory and sending it in one giant blob.
4. Use short-lived signed URLs/credentials to talk to storage, so no permanent secret ever needs to be embedded in client-reachable code.

---

## 3.1 Choosing and setting up object storage

**The Target:** provision an S3-compatible object storage bucket for real PDF files.

**The Concept:** object storage is a service purpose-built for storing files ("objects") at scale, distinct from a database (structured records) or a plain server filesystem (doesn't scale well or survive redeploys cleanly). Think of it as a specialized warehouse: you hand it a labeled box (a file with a unique key/name) and it hands you a receipt (a URL or reference) — the warehouse handles all the shelving, security, and retrieval logistics.

We use an S3-compatible provider so the exact same code works whether you deploy against real AWS S3 or a cheaper alternative like Cloudflare R2 or a local MinIO instance for development. For this tutorial we use **MinIO** running locally in Docker — no signup, no billing, behaves identically to production S3.

**The Implementation:**

### `docker-compose.yml` (project root)

```yaml
# This Docker Compose file defines a local MinIO instance -- an
# S3-compatible object storage server we run entirely on our own machine
# for development, so we never need real cloud credentials until deploying
# to production.
services:
  minio:
    image: minio/minio:RELEASE.2024-10-13T13-34-11Z
    container_name: greymatter-minio
    ports:
      - "9000:9000" # S3 API port -- our app talks to this
      - "9001:9001" # Web console port -- for us to browse files visually
    environment:
      MINIO_ROOT_USER: greymatter-dev
      MINIO_ROOT_PASSWORD: greymatter-dev-secret
    volumes:
      - minio-data:/data
    command: server /data --console-address ":9001"

volumes:
  minio-data:
```

**The Verification:**

```bash
docker compose up -d
docker compose ps
```

Expected output: a table showing the `greymatter-minio` container with status "Up" or "running".

Next, open http://localhost:9001 in your browser and log in with username `greymatter-dev` and password `greymatter-dev-secret`. Confirm the console loads. Click "Buckets" → "Create Bucket" and create a bucket named `greymatter-documents`.

---

## 3.2 Installing the storage SDK and configuring credentials

**The Target:** install the AWS SDK for S3 (works against any S3-compatible service, including MinIO) and wire up environment variables.

**The Concept:** rather than writing raw HTTP requests to talk to object storage, we use an official SDK — a pre-built library that handles the complex parts (request signing, retries, streaming) for us. Like using a translated phrasebook instead of learning an entire foreign language just to order a coffee.

**The Implementation:**

```bash
npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
```

### `greymatter-pdf/.env.local` (add these lines to the existing file)

```bash
GREYMATTER_ENV=development

# Storage configuration -- these point at our local MinIO instance for now.
# In production, these same variable names would point at real AWS S3 or
# Cloudflare R2 credentials, and no code changes would be required.
STORAGE_ENDPOINT=http://localhost:9000
STORAGE_REGION=us-east-1
STORAGE_ACCESS_KEY_ID=greymatter-dev
STORAGE_SECRET_ACCESS_KEY=greymatter-dev-secret
STORAGE_BUCKET_NAME=greymatter-documents
```

Why these are server-only: none of these variable names start with `NEXT_PUBLIC_`. In Next.js, only environment variables explicitly prefixed with `NEXT_PUBLIC_` are ever bundled into client-side JavaScript — everything else stays server-only by default, matching the Server/Client Component boundary from Part 1.

**The Verification:**

```bash
cat .env.local
```

Confirm all five `STORAGE_` variables are present, and re-run `git status` to confirm this file never appears staged.

---

## 3.3 Building the storage client module

**The Target:** `src/lib/storage/s3-client.ts`

**The Concept:** rather than every file needing storage access creating its own S3 client with its own copy of credentials, we create one shared, configured client instance and export helper functions around it — a "single source of truth," like a single reception desk everyone checks in through.

**The Implementation:**

### `src/lib/storage/s3-client.ts`

```typescript
import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
} from "@aws-sdk/client-s3";

// This file must never be imported from a Client Component or a Web Worker
// -- it reads server-only environment variables (no NEXT_PUBLIC_ prefix)
// and would throw at runtime if bundled into browser code. Every file that
// imports this one (proxy.ts, future Server Actions) must itself only run
// on the server.
function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${name}. Check your .env.local file.`
    );
  }
  return value;
}

// We construct the S3 client once, at module load time, and reuse it for
// every request -- creating a new client per-request would waste time
// re-establishing connection pools.
const s3Client = new S3Client({
  region: requireEnv("STORAGE_REGION"),
  endpoint: requireEnv("STORAGE_ENDPOINT"),
  credentials: {
    accessKeyId: requireEnv("STORAGE_ACCESS_KEY_ID"),
    secretAccessKey: requireEnv("STORAGE_SECRET_ACCESS_KEY"),
  },
  // MinIO (and some other S3-compatible providers) require "path style"
  // addressing (http://host/bucket/key) rather than AWS's default
  // "virtual hosted style" (http://bucket.host/key). Real AWS S3 also
  // accepts path style, so this setting is safe to keep even in
  // production against real AWS.
  forcePathStyle: true,
});

const BUCKET_NAME = requireEnv("STORAGE_BUCKET_NAME");

/**
 * Retrieves a readable stream for an object stored at the given key.
 * The caller is responsible for piping this stream to its destination --
 * we deliberately do NOT load the whole file into memory here, because
 * PDF files can be tens of megabytes and a busy server handling many
 * concurrent requests would run out of memory if it buffered every file
 * fully before sending it onward.
 */
export async function getObjectStream(key: string) {
  const command = new GetObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
  });
  const response = await s3Client.send(command);

  if (!response.Body) {
    throw new Error(`Object not found in storage for key: ${key}`);
  }

  // response.Body is a web-standard ReadableStream when running in the
  // Node.js runtime with a modern AWS SDK version -- exactly what we need
  // to stream chunks onward in proxy.ts without buffering.
  return {
    stream: response.Body as unknown as ReadableStream<Uint8Array>,
    contentType: response.ContentType ?? "application/pdf",
    contentLength: response.ContentLength,
  };
}

/**
 * Uploads a file's bytes to storage at the given key. Used later (Part 6
 * onward) whenever the server produces a new PDF -- e.g. after merging
 * pages -- and needs to persist the result.
 */
export async function putObjectBytes(
  key: string,
  bytes: Uint8Array,
  contentType: string = "application/pdf"
) {
  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
    Body: bytes,
    ContentType: contentType,
  });
  await s3Client.send(command);
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors. If you see an error about missing types for `@aws-sdk` packages, run `npm install` again.

---

## 3.4 A minimal document lookup and session check

**The Target:** `src/lib/db/documents.ts` (temporary in-memory version) and `src/lib/auth/session.ts`

**The Concept:** `proxy.ts` needs to answer two questions before streaming any bytes: "who is asking?" (authentication) and "are they allowed to see this specific document?" (authorization). A real production app answers both using a database of users, sessions, and document ownership records — which we build properly with Prisma in Part 5. For now, we build a minimal, honest stand-in: an in-memory map of `documentId` → `ownerId`, and a simple cookie-based session check. Part 5 swaps these for real database queries with **zero changes to `proxy.ts`'s logic**.

**The Implementation:**

### `src/lib/auth/session.ts`

```typescript
import { cookies } from "next/headers";

// A minimal stand-in for a real authentication system. In production this
// would validate a signed JWT or look up a session record in a database.
// For this Part, we simply trust a plain cookie named "greymatter_user_id"
// -- this is intentionally simplified so we can focus on the proxy.ts
// streaming pattern. Treat this as a placeholder to be replaced by a real
// auth provider (e.g. NextAuth, Clerk, or a custom Prisma-backed session
// table) before shipping to real users.
export async function getCurrentUserId(): Promise<string | null> {
  const cookieStore = await cookies();
  const userId = cookieStore.get("greymatter_user_id")?.value;
  return userId ?? null;
}
```

### `src/lib/db/documents.ts`

```typescript
// A temporary in-memory "database" of documents, mapping a documentId to
// the user who owns it and the storage key where its bytes live. This
// exists only so Part 3 can demonstrate a real authorization check without
// requiring Part 5's Prisma setup first. Part 5 replaces this Map with an
// actual PostgreSQL table and Prisma queries
// ... the function signatures below are written to match what the real
// database version will look like, so upgrading later requires no
// changes to proxy.ts.
interface DocumentRecord {
  id: string;
  ownerId: string;
  storageKey: string;
}

const documents = new Map<string, DocumentRecord>([
  [
    "sample",
    {
      id: "sample",
      ownerId: "demo-user-1",
      storageKey: "documents/sample.pdf",
    },
  ],
]);

export async function findDocumentById(
  documentId: string
): Promise<DocumentRecord | null> {
  return documents.get(documentId) ?? null;
}

export async function userCanAccessDocument(
  userId: string,
  documentId: string
): Promise<boolean> {
  const doc = documents.get(documentId);
  if (!doc) return false;
  return doc.ownerId === userId;
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## 3.5 Upload the test PDF into MinIO at the expected key

**The Target:** get an actual PDF file into storage at `documents/sample.pdf` so our lookup above resolves to something real.

**The Concept:** our `documents.ts` stand-in claims a file exists at storage key `documents/sample.pdf` — we now need to actually put a file there, otherwise `proxy.ts` will correctly authenticate the user but then fail when it tries to fetch bytes that don't exist.

**The Implementation:** open the MinIO console at http://localhost:9001, navigate into the `greymatter-documents` bucket, click "Create new path" (or "Upload") and create a folder named `documents`, then upload any sample PDF file into it, renaming it to `sample.pdf` so the final object path is `documents/sample.pdf`.

Alternatively, from the command line using the AWS CLI configured against MinIO (optional, if you have the AWS CLI installed):

```bash
aws s3api put-object \
  --endpoint-url http://localhost:9000 \
  --bucket greymatter-documents \
  --key documents/sample.pdf \
  --body ./public/test-pdfs/sample.pdf
```

**The Verification:** in the MinIO console, confirm you can see and preview `documents/sample.pdf` inside the `greymatter-documents` bucket, with a non-zero file size.

---

## 3.6 Building the proxy.ts route itself

**The Target:** `src/app/api/documents/[documentId]/route.ts`

**The Concept:** this is the "teller" from our earlier analogy, brought to life as a Next.js Route Handler — a file that responds to raw HTTP requests (unlike a Server Action, which is called like a function from React code). We place it under a dynamic route segment (`[documentId]`) so the URL itself encodes which document is being requested, e.g. `/api/documents/sample`. Route Handlers in Next.js are named `route.ts` by convention when using the App Router; we explicitly declare the Node.js runtime because streaming to/from an S3 SDK requires full Node.js APIs unavailable in the lighter Edge runtime.

**The Implementation:**

### `src/app/api/documents/[documentId]/route.ts`

```typescript
import { NextRequest, NextResponse } from "next/server";
import { getCurrentUserId } from "@/lib/auth/session";
import { findDocumentById, userCanAccessDocument } from "@/lib/db/documents";
import { getObjectStream } from "@/lib/storage/s3-client";

// Explicitly pin this route to the Node.js runtime (as opposed to the
// Edge runtime, which is the default for some Next.js deployment targets).
// The AWS S3 SDK and Node's stream APIs are not guaranteed to work under
// Edge -- Node gives us the full, unrestricted runtime we need here.
export const runtime = "nodejs";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ documentId: string }> }
) {
  const { documentId } = await params;

  // Step 1: authenticate. Who is making this request at all?
  const userId = await getCurrentUserId();
  if (!userId) {
    return NextResponse.json(
      { error: "You must be signed in to view this document." },
      { status: 401 }
    );
  }

  // Step 2: authorize. Does this specific user have permission to view
  // this specific document? This is the check that a raw public/ file
  // path could never perform -- it is the entire reason this route exists.
  const canAccess = await userCanAccessDocument(userId, documentId);
  if (!canAccess) {
    // We deliberately return the same generic error whether the document
    // does not exist or the user simply lacks permission -- returning a
    // different message for "not found" vs "forbidden" would leak
    // information about which document IDs exist to an attacker probing
    // random IDs.
    return NextResponse.json(
      { error: "Document not found or access denied." },
      { status: 404 }
    );
  }

  const document = await findDocumentById(documentId);
  if (!document) {
    return NextResponse.json(
      { error: "Document not found or access denied." },
      { status: 404 }
    );
  }

  try {
    // Step 3: fetch a stream (not the full bytes) from storage.
    const { stream, contentType, contentLength } = await getObjectStream(
      document.storageKey
    );

    // Step 4: hand that stream directly back to the browser as the
    // response body. Next.js's Response/NextResponse constructors accept a
    // ReadableStream directly, so bytes flow: MinIO -> our server -> the
    // browser's PdfViewer, in chunks, without ever being fully buffered in
    // our server's memory at once. This is the core of "stream isolation"
    // from this Part's title -- the client never gets a direct pipe to
    // storage, only to our permission-checked relay.
    return new NextResponse(stream, {
      status: 200,
      headers: {
        "Content-Type": contentType,
        ...(contentLength
          ? { "Content-Length": String(contentLength) }
          : {}),
        // Cache-Control: private ensures browsers/CDNs do not cache this
        // response in a way that could be shared between different users
        // -- each request must be re-authenticated.
        "Cache-Control": "private, no-store",
      },
    });
  } catch (error) {
    console.error(`Failed to stream document ${documentId}:`, error);
    return NextResponse.json(
      { error: "Failed to load document." },
      { status: 500 }
    );
  }
}
```

---

## 3.7 A minimal sign-in stand-in to set the session cookie

**The Target:** `src/app/dev-sign-in/route.ts`

**The Concept:** our `session.ts` reads a cookie named `greymatter_user_id`, but nothing has set that cookie yet. In a real app, a proper sign-in form and auth provider would set this after verifying a password or OAuth flow. For this Part only, we create a tiny helper route that sets the cookie directly, purely so we can test `proxy.ts` end-to-end without building a full authentication system before it is needed. This route is explicitly temporary — a real login system replaces it well before production.

**The Implementation:**

### `src/app/dev-sign-in/route.ts`

```typescript
import { NextResponse } from "next/server";

// DEVELOPMENT-ONLY convenience route. This sets a session cookie directly,
// bypassing any real credential check, purely so we can test proxy.ts's
// authorization logic in this tutorial Part before real authentication is
// built. Delete or protect this route before deploying anywhere public.
export const runtime = "nodejs";

export async function GET() {
  const response = NextResponse.redirect(
    new URL("/viewer/sample", "http://localhost:3000")
  );

  // This matches the ownerId "demo-user-1" set in src/lib/db/documents.ts's
  // in-memory record for the "sample" document, so this user will pass
  // the userCanAccessDocument() check in proxy.ts.
  response.cookies.set("greymatter_user_id", "demo-user-1", {
    httpOnly: true, // not readable by client-side JavaScript -- reduces
                    // exposure to cross-site scripting (XSS) attacks
    sameSite: "lax",
    path: "/",
  });

  return response;
}
```

**The Verification:** with `npm run dev` running, visit http://localhost:3000/dev-sign-in in your browser. You should be redirected to `/viewer/sample`. Open DevTools, go to the Application tab (Chrome) or Storage tab (Firefox), find Cookies, and confirm a cookie named `greymatter_user_id` with value `demo-user-1` is now present.

---

## 3.8 Updating PdfViewer to use the secure route

**The Target:** update `src/app/viewer/[documentId]/page.tsx` from Part 2

**The Concept:** recall from Part 2's summary that the hardcoded `/test-pdfs/${documentId}.pdf` path was explicitly marked temporary. We now replace it with our new authenticated route.

**The Implementation:**

### `src/app/viewer/[documentId]/page.tsx` (replaces the Part 2 version)

```typescript
import { PdfViewer } from "@/components/viewer/PdfViewer";

export default async function ViewerPage({
  params,
}: {
  params: Promise<{ documentId: string }>;
}) {
  const { documentId } = await params;

  // This now points at our authenticated, streaming proxy route instead of
  // a raw public/ file path. The browser's fetch() call inside PdfViewer
  // (built in Part 2) requires no changes at all -- it already just calls
  // fetch(fileUrl) and reads the response as an ArrayBuffer, so swapping
  // the URL underneath it is enough. This is a direct payoff of the clean
  // separation of concerns we set up in Part 1 and Part 2.
  const fileUrl = `/api/documents/${documentId}`;

  return (
    <main className="h-screen w-screen bg-gray-50">
      <PdfViewer fileUrl={fileUrl} />
    </main>
  );
}
```

No changes are required to `PdfViewer.tsx`, `PdfPageCanvas.tsx`, `use-pdf-worker.ts`, or the Web Worker itself — all of Part 2's rendering pipeline is completely agnostic to where the bytes came from, exactly as the hybrid architecture from Part 1 intended.

---

## 3.9 Full end-to-end verification

**The Target:** prove the entire authenticated streaming pipeline works, and prove that unauthorized access is correctly rejected.

**Step 1** — confirm MinIO is running:

```bash
docker compose ps
```

Expected: `greymatter-minio` shows as running.

**Step 2** — confirm the dev server is running:

```bash
npm run dev
```

**Step 3** — test the happy path (authenticated, authorized user):

Visit http://localhost:3000/dev-sign-in in your browser. This sets the session cookie and redirects you to `/viewer/sample`. Confirm the PDF renders exactly as it did at the end of Part 2 — multiple pages, sharp text, responsive scrolling.

**Step 4** — test the unauthenticated path (no cookie at all):

Open a new Incognito/Private browsing window (which starts with no cookies), and navigate directly to:

```
http://localhost:3000/api/documents/sample
```

Expected result: a JSON response `{"error":"You must be signed in to view this document."}` with HTTP status **401**.

**Step 5** — test the unauthorized path (authenticated, but wrong document):

While still signed in from Step 3, visit:

```
http://localhost:3000/api/documents/some-other-document-id
```

Expected result: a JSON response `{"error":"Document not found or access denied."}` with HTTP status **404**, since "some-other-document-id" does not exist in our `documents.ts` stand-in map.

**Step 6** — confirm streaming, not full buffering (optional but recommended):

Open DevTools' Network tab, reload `/viewer/sample`, and click the request to `/api/documents/sample`. Inspect the Response Headers — confirm `Cache-Control: private, no-store` is present, and `Content-Type` is `application/pdf` (or similar). This confirms the response is being treated as a private, non-cacheable, streamed document rather than a static public asset.

---

## Part 3 Summary

By this point you have: a local S3-compatible object storage service (MinIO) running in Docker, holding real PDF files outside of Next.js's `public/` directory; a shared, server-only storage client module (`s3-client.ts`) that streams bytes rather than buffering whole files; a minimal but honest authentication/authorization stand-in (`session.ts` and `documents.ts`) that will be upgraded to real Prisma-backed logic in Part 5 without requiring any changes to `proxy.ts`; and the `proxy.ts` Route Handler itself, which checks identity, checks permission, and streams bytes through a private, non-cacheable response — exactly the "bank teller" pattern from this Part's introduction.

Critically, your `PdfViewer` component from Part 2 required **zero code changes** to work with this new, secure delivery mechanism — proof that the layered architecture from Part 1 (clean separation between rendering and data delivery) pays off exactly as designed.

Part 4 begins Phase 2 of the series: building the interactive annotation engine, starting with a coordinate-accurate overlay canvas layered on top of the `PdfPageCanvas` elements we already have.
