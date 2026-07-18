# Part 5: Standardized Annotation Mapping (JSON to XFDF)

*(Phase 2 — Building the Interactive Annotation Engine)*

## Why this part exists

Part 4 gave us working annotations, but with two honest limitations we flagged at the time: annotations live only in React state (a browser refresh loses everything), and our data model is entirely our own invention — if a user wanted to open their highlighted PDF in Adobe Acrobat, our JSON-based rect format would mean nothing to it.

This Part solves both problems. Analogy: think of our document space `[x, y, w, h]` format from Part 4 as a personal shorthand note-taking system — fast and convenient for us, but unreadable to anyone else. **XFDF** (XML Forms Data Format) is the "standard language" that enterprise PDF tools like Adobe Acrobat, Apryse, and Foxit all speak fluently. By translating our internal format into XFDF, we make Greymatter PDF's annotations portable — exportable to, and importable from, other professional PDF software — without changing how our own annotation drawing code works at all.

We also finally replace the temporary stand-ins from Part 3 (the in-memory `documents.ts` map and the cookie-only session check) with a real database, using **Prisma** as our ORM (Object-Relational Mapper, a library that lets us query a database using type-safe function calls instead of writing raw SQL strings by hand).

---

## 5.1 Designing the relational schema

**The Concept:** a relational database organizes data into tables (like spreadsheets) with defined relationships between them — e.g. "each annotation belongs to exactly one document, and each document belongs to exactly one user." This is different from the flat, in-memory `Map` we used in Part 3, which had no way to express such relationships or survive a server restart.

We need three tables for what we have built so far:
- **User**: a person using Greymatter PDF
- **Document**: a single PDF file, owned by a User, with a pointer to its bytes in object storage (replacing Part 3's in-memory documents Map)
- **Annotation**: a single highlight/rectangle/freehand mark, belonging to a Document, storing the exact document-space fields from Part 4's `Annotation` type

---

## 5.2 Installing PostgreSQL and Prisma

**The Target:** run a local PostgreSQL database in Docker, and install/configure Prisma.

**The Concept:** PostgreSQL is a mature, open-source relational database — the actual "filing cabinet" that will store our Users, Documents, and Annotations tables permanently on disk, surviving server restarts unlike Part 4's React state. We add it to the same `docker-compose.yml` file that already runs MinIO from Part 3.

**The Implementation:**

### `docker-compose.yml` (project root, replaces the Part 3 version)

```yaml
# This file now runs two local services: MinIO (object storage, Part 3)
# and PostgreSQL (relational database, this Part). Running `docker compose
# up -d` once starts both, matching our production topology where storage
# and database are separate managed services.
services:
  minio:
    image: minio/minio:RELEASE.2024-10-13T13-34-11Z
    container_name: greymatter-minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: greymatter-dev
      MINIO_ROOT_PASSWORD: greymatter-dev-secret
    volumes:
      - minio-data:/data
    command: server /data --console-address ":9001"

  postgres:
    image: postgres:16
    container_name: greymatter-postgres
    ports:
      - "5432:5432" # Postgres's standard port -- our app connects here
    environment:
      POSTGRES_USER: greymatter
      POSTGRES_PASSWORD: greymatter-dev-secret
      POSTGRES_DB: greymatter_pdf
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  minio-data:
  postgres-data:
```

**The Verification:**

```bash
docker compose up -d
docker compose ps
```

Expected output: both `greymatter-minio` and `greymatter-postgres` show as running.

Now install Prisma:

```bash
npm install prisma --save-dev
npm install @prisma/client
npx prisma init
```

Update `.env.local` (add this line, then remove the auto-generated `.env` file that `prisma init` created):

### `greymatter-pdf/.env.local` (add this line to the existing file)

```bash
DATABASE_URL="postgresql://greymatter:greymatter-dev-secret@localhost:5432/greymatter_pdf"
```

```bash
rm .env
```

---

## 5.3 Defining the Prisma schema

**The Target:** `prisma/schema.prisma`

**The Concept:** this file is a blueprint written in Prisma's own schema language — you describe your tables and their relationships once, and Prisma generates both the actual SQL to create those tables (via "migrations") and a fully-typed TypeScript client to query them, so a typo in a field name becomes a compile-time error rather than a runtime surprise.

**The Implementation:**

### `prisma/schema.prisma` (replaces the auto-generated starter file)

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Represents a person using Greymatter PDF. This replaces Part 3's
// cookie-only "trust whatever userId is in the cookie" approach -- we now
// have an actual table to validate that a user record exists.
model User {
  id        String     @id @default(cuid())
  email     String     @unique
  createdAt DateTime   @default(now())
  documents Document[] // one User can own many Documents
}

// Represents a single uploaded PDF file. This replaces Part 3's in-memory
// documents.ts Map -- storageKey plays the exact same role it did there.
model Document {
  id          String       @id @default(cuid())
  ownerId     String
  owner       User         @relation(fields: [ownerId], references: [id])
  storageKey  String       // where the actual PDF bytes live in MinIO/S3
  fileName    String
  createdAt   DateTime     @default(now())
  annotations Annotation[] // one Document can have many Annotations

  // An index on ownerId speeds up the exact query proxy.ts performs in
  // Part 3's userCanAccessDocument-equivalent logic: "find documents
  // belonging to this owner."
  @@index([ownerId])
}

// Represents a single annotation mark, storing the exact document-space
// fields from Part 4's Annotation TypeScript type. We store rect/points as
// JSON columns rather than separate x/y/w/h columns, because the shape
// differs by annotation kind (a rect for highlights/rectangles, a points
// array for freehand) -- Postgres's native JSON support lets us keep one
// flexible column instead of many mostly-empty ones.
model Annotation {
  id         String   @id @default(cuid())
  documentId String
  document   Document @relation(fields: [documentId], references: [id])
  pageNumber Int
  kind       String   // "highlight" | "rectangle" | "freehand", matching Part 4's AnnotationKind
  color      String
  strokeWidth Float?  // present for "rectangle" and "freehand", null for "highlight"
  rect       Json?    // { x, y, w, h } for "highlight"/"rectangle", null for "freehand"
  points     Json?    // [{ x, y }, ...] for "freehand", null otherwise
  createdAt  DateTime @default(now())

  // An index on documentId speeds up "load every annotation for this
  // document" -- the exact query our sync pipeline performs every time a
  // user opens the viewer.
  @@index([documentId])
}
```

Why nullable `rect` and `points` instead of two separate required tables: a simpler alternative would be one Annotation table for rects and a separate FreehandAnnotation table for point paths. We chose one shared table with nullable columns instead because every annotation kind shares most fields (documentId, pageNumber, color, createdAt), and our application code already has a single `Annotation` TypeScript union type from Part 4 — keeping one database table mirrors that union type directly.

**The Verification:**

```bash
npx prisma migrate dev --name init
```

Expected output: Prisma prints a series of steps creating the User, Document, and Annotation tables, ending with "Your database is now in sync with your schema" and confirmation that the Prisma Client was generated.

---

## Step 1: The shared Prisma client module

**The Target:** `src/lib/db/prisma.ts`

**The Concept:** similar to Part 3's shared `s3-client.ts`, we want exactly one Prisma Client instance shared across our whole app. This matters especially in Next.js development mode, where hot-reloading can otherwise accidentally create a new database connection pool on every file save, eventually exhausting Postgres's connection limit — the pattern below is Prisma's own officially recommended workaround.

**The Implementation:**

### `src/lib/db/prisma.ts`

```typescript
import { PrismaClient } from "@prisma/client";

// In Next.js development mode, hot-reloading re-executes this module on
// every file save. Without the caching trick below, that would create a
// brand new PrismaClient (and a new database connection pool) every time,
// eventually exhausting PostgreSQL's max_connections limit. We work around
// this by stashing the client on Node's global object, which survives
// module re-execution across hot reloads (this object does not exist in
// a production server process, where the module is only loaded once
// anyway, so this trick is safe in both environments).
const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 2: Replace Part 3's document lookup with real Prisma queries

**The Target:** replace `src/lib/db/documents.ts` (the in-memory Map from Part 3)

**The Concept:** recall Part 3 explicitly promised that this Map-based file would be replaced with real database queries "with zero changes to `proxy.ts`'s logic" — we now deliver on that promise. The exported function names and signatures stay identical; only their internal implementation changes.

**The Implementation:**

### `src/lib/db/documents.ts` (replaces the Part 3 version)

```typescript
import { prisma } from "@/lib/db/prisma";

export interface DocumentRecord {
  id: string;
  ownerId: string;
  storageKey: string;
  fileName: string;
}

// Signature-compatible with Part 3's version -- proxy.ts (src/app/api/
// documents/[documentId]/route.ts) calls this exact function name with
// the exact same arguments and requires no changes.
export async function findDocumentById(
  documentId: string
): Promise<DocumentRecord | null> {
  const document = await prisma.document.findUnique({
    where: { id: documentId },
  });
  return document;
}

// Also signature-compatible with Part 3. Internally, this now performs a
// real database query joining on ownerId instead of a Map lookup, but
// callers (proxy.ts) are completely unaffected by this change.
export async function userCanAccessDocument(
  userId: string,
  documentId: string
): Promise<boolean> {
  const document = await prisma.document.findUnique({
    where: { id: documentId },
  });
  if (!document) return false;
  return document.ownerId === userId;
}

// New in this Part: creates a Document record pointing at an already
// uploaded file's storage key. Used by a future upload flow (introduced
// alongside Part 6's file manipulation features) -- included now so the
// database layer is complete and ready for that Part without revisiting
// this file again.
export async function createDocument(params: {
  ownerId: string;
  storageKey: string;
  fileName: string;
}): Promise<DocumentRecord> {
  return prisma.document.create({ data: params });
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 3: Replace Part 3's cookie-only session with a real User lookup

**The Target:** update `src/lib/auth/session.ts`

**The Concept:** Part 3's `getCurrentUserId` trusted the cookie's value completely, with no check that a user record with that ID actually existed. We now validate the cookie's `userId` against the real Users table — if someone tampers with the cookie to contain a made-up ID, this now correctly fails instead of silently granting access to a phantom user.

**The Implementation:**

### `src/lib/auth/session.ts` (replaces the Part 3 version)

```typescript
import { cookies } from "next/headers";
import { prisma } from "@/lib/db/prisma";

// Still a simplified stand-in for a full auth system (a real login flow
// with password hashing or OAuth arrives outside the scope of this
// series), but it now validates against a real database table rather than
// blindly trusting the cookie's contents -- a meaningful security
// improvement over Part 3's version with an identical function signature,
// so no other file needs to change.
export async function getCurrentUserId(): Promise<string | null> {
  const cookieStore = await cookies();
  const userId = cookieStore.get("greymatter_user_id")?.value;
  if (!userId) return null;

  const user = await prisma.user.findUnique({ where: { id: userId } });
  return user ? user.id : null;
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 4: Seed the database with a demo user and document

**The Target:** `prisma/seed.ts`

**The Concept:** Part 3's in-memory Map came pre-populated with one demo user and one demo document, purely so our verification steps had something concrete to test against. Now that we have a real database, we need an equivalent "seed script" that inserts that same starting data, since a fresh PostgreSQL database starts completely empty.

**The Implementation:**

### `prisma/seed.ts`

```typescript
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  // Upsert (update-or-insert) rather than plain create, so re-running this
  // script multiple times during development does not fail with a
  // duplicate-key error.
  const user = await prisma.user.upsert({
    where: { id: "demo-user-1" },
    update: {},
    create: {
      id: "demo-user-1",
      email: "demo@greymatter-pdf.dev",
    },
  });

  await prisma.document.upsert({
    where: { id: "sample" },
    update: {},
    create: {
      id: "sample",
      ownerId: user.id,
      storageKey: "documents/sample.pdf",
      fileName: "sample.pdf",
    },
  });

  console.log("Seed complete: demo-user-1 and document 'sample' are ready.");
}

main()
  .catch((error) => {
    console.error("Seed failed:", error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

Register this script with Prisma. Add this to `package.json`:

### `greymatter-pdf/package.json` (add this top-level key, alongside "scripts")

```json
{
  "prisma": {
    "seed": "npx tsx prisma/seed.ts"
  }
}
```

Install `tsx` (a tool for running TypeScript files directly with Node) as a dev dependency:

```bash
npm install --save-dev tsx
```

**The Verification:**

```bash
npx prisma db seed
```

Expected output: "Seed complete: demo-user-1 and document 'sample' are ready." printed to the terminal.

---

## 5.4 Understanding the XFDF format

**The Concept:** XFDF (XML Forms Data Format) is an XML-based standard, published by Adobe and adopted industry-wide, for representing PDF annotations and form data outside of the PDF file itself. Every annotation is represented as an XML element inside an `<annots>` container, with attributes describing its position and appearance.

Critically, XFDF positions annotations using a `rect` attribute formatted as `"x1,y1,x2,y2"` — but unlike our document space fractions (0 to 1) from Part 4, XFDF's coordinates are in raw PDF points, measured from the **bottom-left corner** of the page (PDF's own native coordinate origin), not the top-left corner browsers use. This means our JSON-to-XFDF conversion function must do two things at once: convert from fractions back to points, AND flip the Y-axis. Below is a minimal example:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xfdf xmlns="http://ns.adobe.com/xfdf/">
  <annots>
    <highlight page="0" rect="72.00,650.00,300.00,680.00" color="#FFFF00" />
  </annots>
</xfdf>
```

Note that XFDF's `page` attribute is 0-indexed (page "0" is the first page), while our own `Annotation.pageNumber` from Part 4 is 1-indexed — another small but important conversion detail.

---

## 5.5 Building the XFDF conversion module

**The Target:** `src/lib/pdf/xfdf.ts`

**The Concept:** we need one function that converts an array of our `Annotation` objects (plus each page's actual point dimensions) into a complete XFDF XML string.

**The Implementation:**

### `src/lib/pdf/xfdf.ts`

```typescript
import type { Annotation } from "@/types/annotation";

// PDF pages are described in points at some base size (e.g. a US Letter
// page is 612 x 792 points). Since our Annotation objects only store
// fractions (0 to 1), converting to XFDF's point-based rect requires
// knowing each page's actual point dimensions -- pdf.js exposes this via
// page.getViewport({ scale: 1 }).width/height (scale 1 means "1 PDF point
// equals 1 unit", giving us the page's native, unscaled size). The caller
// is responsible for supplying this map; Part 6 shows where this data
// comes from when we work with pdf-lib on the server.
export type PageDimensionsMap = Record<
  number, // pageNumber, 1-indexed, matching Annotation.pageNumber
  { widthPoints: number; heightPoints: number }
>;

function escapeXml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// Converts our Annotation array into a complete XFDF XML document string.
export function annotationsToXfdf(
  annotations: Annotation[],
  pageDimensions: PageDimensionsMap
): string {
  const annotElements = annotations
    .map((annotation) => {
      const dimensions = pageDimensions[annotation.pageNumber];
      if (!dimensions) {
        // Skip annotations for pages we were not given dimensions for,
        // rather than crashing the whole export -- a defensive choice, so
        // one malformed page does not block exporting every other page's
        // annotations.
        return null;
      }

      // XFDF's page attribute is 0-indexed; our Annotation.pageNumber is
      // 1-indexed (matching pdf.js's own convention, see Part 2).
      const xfdfPage = annotation.pageNumber - 1;

      if (annotation.kind === "highlight" || annotation.kind === "rectangle") {
        const { rect } = annotation;

        // Convert fraction -> points (Section 4.3's formula, applied
        // here with point dimensions instead of CSS pixel dimensions).
        const x1Points = rect.x * dimensions.widthPoints;
        const wPoints = rect.w * dimensions.widthPoints;
        const x2Points = x1Points + wPoints;

        // Flip the Y-axis: our document space Y grows downward from the
        // top (matching screen/browser convention), but PDF/XFDF
        // coordinates grow upward from the bottom of the page. We convert
        // by subtracting from the page's total height.
        const hPoints = rect.h * dimensions.heightPoints;
        const y2Points = dimensions.heightPoints - rect.y * dimensions.heightPoints;
        const y1Points = y2Points - hPoints;

        const tagName = annotation.kind === "highlight" ? "highlight" : "square";

        return `    <${tagName} page="${xfdfPage}" rect="${x1Points.toFixed(2)},${y1Points.toFixed(2)},${x2Points.toFixed(2)},${y2Points.toFixed(2)}" color="${escapeXml(annotation.color)}" />`;
      }

      if (annotation.kind === "freehand") {
        // XFDF represents freehand drawings using an <ink> element
        // containing one or more <inklist><gesture> point lists, in the
        // same point-based, bottom-left-origin coordinate space as rects.
        const pointsAttr = annotation.points
          .map((point) => {
            const xPoints = point.x * dimensions.widthPoints;
            const yPoints =
              dimensions.heightPoints - point.y * dimensions.heightPoints;
            return `${xPoints.toFixed(2)},${yPoints.toFixed(2)}`;
          })
          .join(";");

        return `    <ink page="${xfdfPage}" color="${escapeXml(annotation.color)}">
      <inklist>
        <gesture>${pointsAttr}</gesture>
      </inklist>
    </ink>`;
      }

      return null;
    })
    .filter((element): element is string => element !== null);

  return `<?xml version="1.0" encoding="UTF-8"?>
<xfdf xmlns="http://ns.adobe.com/xfdf/">
  <annots>
${annotElements.join("\n")}
  </annots>
</xfdf>`;
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## 5.6 Building the Server Actions

**The Target:** `src/server-actions/annotations.ts`

**The Concept:** recall from Part 1 that a Server Action is an async function marked with `"use server"` that a Client Component can call directly, as though it were a local function, while it actually executes securely on the server. This is precisely the mechanism we use to push Part 4's local React state up into our new Prisma-backed database.

**The Implementation:**

### `src/server-actions/annotations.ts`

```typescript
"use server";

import { prisma } from "@/lib/db/prisma";
import { getCurrentUserId } from "@/lib/auth/session";
import { userCanAccessDocument } from "@/lib/db/documents";
import { annotationsToXfdf, type PageDimensionsMap } from "@/lib/pdf/xfdf";
import type { Annotation } from "@/types/annotation";

// Converts a Prisma Annotation row (with loosely-typed JSON columns) back
// into our strict, discriminated-union Annotation type from Part 4. This
// is the mirror image of how we insert data in saveAnnotation below.

function rowToAnnotation(row: {
  id: string;
  pageNumber: number;
  kind: string;
  color: string;
  strokeWidth: number | null;
  rect: unknown;
  points: unknown;
  createdAt: Date;
}): Annotation {
  const base = {
    id: row.id,
    pageNumber: row.pageNumber,
    color: row.color,
    createdAt: row.createdAt.getTime(),
  };

  if (row.kind === "highlight") {
    return {
      ...base,
      kind: "highlight",
      rect: row.rect as { x: number; y: number; w: number; h: number },
    } as Annotation;
  }
  if (row.kind === "rectangle") {
    return {
      ...base,
      kind: "rectangle",
      rect: row.rect as { x: number; y: number; w: number; h: number },
      strokeWidth: row.strokeWidth ?? 0.002,
    } as Annotation;
  }
  // "freehand"
  return {
    ...base,
    kind: "freehand",
    points: row.points as { x: number; y: number }[],
    strokeWidth: row.strokeWidth ?? 0.002,
  } as Annotation;
}

// Loads every annotation for a document, checking access first. Called
// once when the viewer opens a document, replacing Part 4's empty
// useAnnotations() initial state with real, persisted data.
export async function loadAnnotations(documentId: string): Promise<Annotation[]> {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const canAccess = await userCanAccessDocument(userId, documentId);
  if (!canAccess) throw new Error("Access denied.");

  const rows = await prisma.annotation.findMany({
    where: { documentId },
    orderBy: { createdAt: "asc" },
  });

  return rows.map(rowToAnnotation);
}

// Persists a single new annotation, called every time Part 4's
// addAnnotation fires in the browser. We deliberately save one annotation
// per call, immediately after creation, rather than batching -- this
// keeps the sync model simple (create locally, save immediately) and
// means a browser crash mid-session loses at most the single
// in-progress annotation, not the whole session's work.
export async function saveAnnotation(
  documentId: string,
  annotation: Omit<Annotation, "id" | "createdAt">
): Promise<Annotation> {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const canAccess = await userCanAccessDocument(userId, documentId);
  if (!canAccess) throw new Error("Access denied.");

  const row = await prisma.annotation.create({
    data: {
      documentId,
      pageNumber: annotation.pageNumber,
      kind: annotation.kind,
      color: annotation.color,
      strokeWidth:
        annotation.kind === "rectangle" || annotation.kind === "freehand"
          ? annotation.strokeWidth
          : null,
      rect:
        annotation.kind === "highlight" || annotation.kind === "rectangle"
          ? annotation.rect
          : undefined,
      points: annotation.kind === "freehand" ? annotation.points : undefined,
    },
  });

  return rowToAnnotation(row);
}

// Deletes a single annotation. Mirrors Part 4's removeAnnotation, now
// persisted.
export async function deleteAnnotationAction(
  documentId: string,
  annotationId: string
): Promise<void> {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const canAccess = await userCanAccessDocument(userId, documentId);
  if (!canAccess) throw new Error("Access denied.");

  await prisma.annotation.delete({
    where: { id: annotationId, documentId },
  });
}

// Exports every annotation for a document as a single XFDF XML string,
// ready for download or for opening in Adobe Acrobat/Apryse/Foxit. The
// caller supplies pageDimensions because only client-side pdf.js code
// (or, in a future Part, server-side pdf-lib) knows each page's actual
// point dimensions -- this Server Action focuses purely on data
// retrieval and format translation.
export async function exportAnnotationsAsXfdf(
  documentId: string,
  pageDimensions: PageDimensionsMap
): Promise<string> {
  const annotations = await loadAnnotations(documentId);
  return annotationsToXfdf(annotations, pageDimensions);
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 5: Update useAnnotations to sync with the server

**The Target:** update `src/lib/pdf/use-annotations.ts` from Part 4

**The Concept:** Part 4's version only updated local React state. We now make it load existing annotations from the server on mount, and push every new annotation to the server the moment it is created — an "optimistic update" pattern, where the UI updates instantly (so drawing still feels immediate) while the network request happens in the background.

**The Implementation:**

### `src/lib/pdf/use-annotations.ts` (replaces the Part 4 version)

```typescript
"use client";

import { useState, useCallback, useEffect } from "react";
import type { Annotation } from "@/types/annotation";
import {
  loadAnnotations,
  saveAnnotation,
  deleteAnnotationAction,
} from "@/server-actions/annotations";

export function useAnnotations(documentId: string) {
  const [annotations, setAnnotations] = useState<Annotation[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // On mount, load every previously-saved annotation for this document --
  // this is what makes annotations survive a page refresh, the exact gap
  // Part 4 flagged and this Part closes.
  useEffect(() => {
    let cancelled = false;

    async function load() {
      setIsLoading(true);
      try {
        const loaded = await loadAnnotations(documentId);
        if (!cancelled) setAnnotations(loaded);
      } catch (error) {
        console.error("Failed to load annotations:", error);
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [documentId]);

  // Optimistic update: we add a temporary, client-only annotation to
  // state IMMEDIATELY (so the user sees their highlight appear with zero
  // delay), then call the Server Action in the background. Once the
  // server responds with the real, persisted record (with its real
  // database-generated id), we replace the temporary entry with it. If
  // the save fails, we roll back by removing the temporary entry.
  const addAnnotation = useCallback(
    async (annotation: Omit<Annotation, "id" | "createdAt">) => {
      const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
      const optimisticAnnotation = {
        ...annotation,
        id: tempId,
        createdAt: Date.now(),
      } as Annotation;

      setAnnotations((current) => [...current, optimisticAnnotation]);

      try {
        const saved = await saveAnnotation(documentId, annotation);
        setAnnotations((current) =>
          current.map((a) => (a.id === tempId ? saved : a))
        );
        return saved;
      } catch (error) {
        console.error("Failed to save annotation:", error);
        // Roll back the optimistic update -- the user's drawing
        // disappears if the server rejected it (e.g. access was revoked
        // mid-session), rather than silently pretending it was saved.
        setAnnotations((current) => current.filter((a) => a.id !== tempId));
        throw error;
      }
    },
    [documentId]
  );

  const removeAnnotation = useCallback(
    async (id: string) => {
      const previous = annotations;
      setAnnotations((current) => current.filter((a) => a.id !== id));
      try {
        await deleteAnnotationAction(documentId, id);
      } catch (error) {
        console.error("Failed to delete annotation:", error);
        setAnnotations(previous); // roll back on failure
        throw error;
      }
    },
    [documentId, annotations]
  );

  const getAnnotationsForPage = useCallback(
    (pageNumber: number) => annotations.filter((a) => a.pageNumber === pageNumber),
    [annotations]
  );

  return {
    annotations,
    isLoading,
    addAnnotation,
    removeAnnotation,
    getAnnotationsForPage,
  };
}
```

Note the hook's signature changed from `useAnnotations(initialAnnotations?)` in Part 4 to `useAnnotations(documentId)` here.

---

## Step 6: Update PdfViewer to pass documentId through

**The Target:** update `src/components/viewer/PdfViewer.tsx`

**The Concept:** `PdfViewer` already receives `fileUrl`, from which we can extract `documentId` (they share the same value in our current routing scheme from Part 3). We pass `documentId` explicitly rather than parsing it back out of the URL.

**The Implementation:**

### `src/components/viewer/PdfViewer.tsx` (updated prop and hook call only — rest unchanged from Part 4)

```typescript
interface PdfViewerProps {
  fileUrl: string;
  documentId: string; // new in this Part
}

export function PdfViewer({ fileUrl, documentId }: PdfViewerProps) {
  // ... loadDocument, renderPage, numPages, loadError, scale state unchanged ...

  const { annotations, addAnnotation, getAnnotationsForPage } =
    useAnnotations(documentId); // updated call, was useAnnotations() in Part 4

  // ... rest of the component is identical to Part 4 ...
}
```

### `src/app/viewer/[documentId]/page.tsx` (updated to pass documentId)

```typescript
import { PdfViewer } from "@/components/viewer/PdfViewer";

export default async function ViewerPage({
  params,
}: {
  params: Promise<{ documentId: string }>;
}) {
  const { documentId } = await params;
  const fileUrl = `/api/documents/${documentId}`;

  return (
    <main className="h-screen w-screen bg-gray-50">
      <PdfViewer fileUrl={fileUrl} documentId={documentId} />
    </main>
  );
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 7: Full end-to-end verification

**Step 1** — start all services and seed the database:

```bash
docker compose up -d
npx prisma migrate dev
npx prisma db seed
npm run dev
```

**Step 2** — sign in and draw a highlight:

Visit http://localhost:3000/dev-sign-in. Enable drawing mode and draw a highlight, exactly as in Part 4's verification.

**Step 3** — the critical test: confirm persistence across a full page refresh.

Press F5 (or Cmd+R) to fully reload the browser tab — not just navigate away and back, but a genuine full page reload, which completely resets all React state. Confirm your highlight still appears, in the correct position. This proves annotations now survive exactly the scenario Part 4 explicitly could not handle.

**Step 4** — confirm data is really in PostgreSQL (not just browser-cached):

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_pdf -c "SELECT id, \"pageNumber\", kind, color FROM \"Annotation\";"
```

Expected output: a table listing your saved annotation(s), with real database-generated `cuid`-style IDs (not the `temp-` prefixed IDs used briefly during the optimistic update).

**Step 5** — confirm authorization still works correctly:

Open a fresh Incognito window and visit `/viewer/sample` without signing in first. You should see the same 401/404 behavior verified back in Part 3 — the Server Actions in this Part call the exact same `getCurrentUserId` and `userCanAccessDocument` functions, so this protection is inherited automatically, with zero duplicated security logic.

---

## Part 5 Summary

By this point you have: a real PostgreSQL database (via Docker) with a Prisma schema modeling Users, Documents, and Annotations; Part 3's temporary in-memory document lookup and cookie-trusting session check both upgraded to real, validated database queries with **zero changes to `proxy.ts`'s own logic**, exactly as promised back in Part 3; a JSON-to-XFDF conversion module correctly handling the coordinate flips (fraction-to-points, top-left-to-bottom-left origin) required to interoperate with enterprise tools like Adobe Acrobat and Apryse; a set of Server Actions providing load/save/delete/export operations, each enforcing the same authentication and authorization checks established in Part 3; and an updated `useAnnotations` hook using an optimistic-update pattern so the drawing experience from Part 4 still feels instant, while now persisting durably to a real database.

This completes **Phase 2** (the Annotation Engine) of Greymatter PDF. **Phase 3** begins in Part 6, where we shift focus to the Manipulation Engine: using `pdf-lib` on the server, inside Next.js Server Actions, to merge, split, extract, and reorder whole PDF documents — heavy binary operations that, per Part 1's founding architectural rule, must never run in the browser.
