## AI SaaS Tutorial - Part 5: Document Upload Pipeline

*Next.js 16 note: the documents page uses Promise-based params (`await params`). The uploader is a client component and the route handlers use the standard Next.js 16 App Router conventions — no other async-API changes apply here.*

### Goal
Let workspace members upload PDF/TXT/MD files via UploadThing (free tier), and create a Document row in our DB for each one.

### 1. Create a free UploadThing account
1. Go to uploadthing.com and sign up (free tier).
2. Create an app, copy your `UPLOADTHING_TOKEN`.

### 2. Environment variables
```bash
UPLOADTHING_TOKEN=xxx
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 3. Define the file router
`src/app/api/uploadthing/core.ts`:
```ts
import { createUploadthing, type FileRouter } from "uploadthing/next";
import { getCurrentWorkspaceAndRole } from "@/lib/workspace";
import { db } from "@/lib/db";

const f = createUploadthing();

export const ourFileRouter = {
  documentUploader: f({
    pdf: { maxFileSize: "16MB", maxFileCount: 5 },
    text: { maxFileSize: "4MB", maxFileCount: 5 },
  })
    .middleware(async () => {
      const ctx = await getCurrentWorkspaceAndRole();
      if (!ctx) throw new Error("Unauthorized");
      return { workspaceId: ctx.workspace.id };
    })
    .onUploadComplete(async ({ metadata, file }) => {
      const doc = await db.document.create({
        data: {
          workspaceId: metadata.workspaceId,
          name: file.name,
          fileUrl: file.url,
          status: "PROCESSING",
        },
      });

      fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/documents/process`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ documentId: doc.id }),
      }).catch(() => {});

      return { documentId: doc.id };
    }),
} satisfies FileRouter;

export type OurFileRouter = typeof ourFileRouter;
```

### 4. Route handler
`src/app/api/uploadthing/route.ts`:
```ts
import { createRouteHandler } from "uploadthing/next";
import { ourFileRouter } from "./core";

export const { GET, POST } = createRouteHandler({
  router: ourFileRouter,
});
```

### 5. Client upload component
`src/lib/uploadthing.ts`:
```ts
import { generateUploadButton, generateUploadDropzone } from "@uploadthing/react";
import type { OurFileRouter } from "@/app/api/uploadthing/core";

export const UploadButton = generateUploadButton<OurFileRouter>();
export const UploadDropzone = generateUploadDropzone<OurFileRouter>();
```

### 6. Documents page (Promise-based params — Next.js 16)
`src/app/(dashboard)/workspaces/[workspaceId]/documents/page.tsx`:
```tsx
import { notFound } from "next/navigation";
import { getCurrentWorkspaceAndRole } from "@/lib/workspace";
import { db } from "@/lib/db";
import { DocumentUploader } from "./uploader";

export default async function DocumentsPage({
  params,
}: {
  params: Promise<{ workspaceId: string }>;
}) {
  const { workspaceId } = await params;
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) notFound();

  const documents = await db.document.findMany({
    where: { workspaceId },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div>
      <h1 className="text-2xl font-bold">Documents</h1>
      <div className="mt-4">
        <DocumentUploader workspaceId={workspaceId} />
      </div>
      <ul className="mt-6 space-y-2">
        {documents.map((doc) => (
          <li key={doc.id} className="flex items-center justify-between rounded border bg-white p-4">
            <span>{doc.name}</span>
            <span
              className={`rounded px-2 py-1 text-xs ${
                doc.status === "READY"
                  ? "bg-green-100 text-green-700"
                  : doc.status === "FAILED"
                  ? "bg-red-100 text-red-700"
                  : "bg-yellow-100 text-yellow-700"
              }`}
            >
              {doc.status}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### 7. Client uploader component (with refresh after upload)
`src/app/(dashboard)/workspaces/[workspaceId]/documents/uploader.tsx`:
```tsx
"use client";

import { useRouter } from "next/navigation";
import { UploadDropzone } from "@/lib/uploadthing";

export function DocumentUploader({ workspaceId }: { workspaceId: string }) {
  const router = useRouter();
  return (
    <UploadDropzone
      endpoint="documentUploader"
      onClientUploadComplete={() => router.refresh()}
      onUploadError={(error) => alert(`Upload failed: ${error.message}`)}
    />
  );
}
```

**Checkpoint:** Go to `/workspaces/<id>/documents`, upload a PDF or `.txt` file, and see it appear in the list with status "PROCESSING" (it'll fail to move to READY until Part 6-7 build the processing route — that's expected for now).

**Next:** Part 6 — Text Extraction & Chunking.
