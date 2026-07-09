## AI SaaS Tutorial - Part 14: Polish — Loading, Error & Empty States

*Next.js 16 note: `loading.tsx` and `error.tsx` use standard App Router file conventions, unaffected by the async dynamic API changes (they don't receive params directly in this series' usage). No version-specific concerns in this part.*

### Goal
Round out the app with proper loading skeletons, error boundaries, and empty states so it feels like a real product rather than a tutorial demo.

### 1. Route-level loading states
Next.js App Router automatically shows `loading.tsx` while a route segment's data is being fetched.

`src/app/(dashboard)/workspaces/[workspaceId]/documents/loading.tsx`:
```tsx
export default function Loading() {
  return (
    <div className="animate-pulse space-y-3">
      <div className="h-8 w-48 rounded bg-gray-200" />
      <div className="h-32 w-full rounded bg-gray-200" />
      <div className="h-12 w-full rounded bg-gray-100" />
      <div className="h-12 w-full rounded bg-gray-100" />
    </div>
  );
}
```
Duplicate this pattern (adjust shapes) for `chat/loading.tsx` and `billing/loading.tsx`.

### 2. Route-level error boundaries
`src/app/(dashboard)/workspaces/[workspaceId]/error.tsx`:
```tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="rounded-lg border border-red-200 bg-red-50 p-6 text-center">
      <h2 className="font-semibold text-red-800">Something went wrong</h2>
      <p className="mt-1 text-sm text-red-600">{error.message}</p>
      <button
        onClick={reset}
        className="mt-4 rounded bg-red-600 px-4 py-2 text-sm text-white"
      >
        Try again
      </button>
    </div>
  );
}
```

### 3. Empty states
Documents page (Part 5) — add an empty state when `documents.length === 0`:
```tsx
{documents.length === 0 && (
  <div className="mt-6 rounded-lg border-2 border-dashed p-8 text-center text-gray-400">
    <p>No documents yet.</p>
    <p className="text-sm">Upload your first document above to start chatting with it.</p>
  </div>
)}
```

Chat page — also handle the case where there are zero READY documents:
```tsx
const readyDocCount = await db.document.count({ where: { workspaceId, status: "READY" } });

{readyDocCount === 0 && (
  <div className="mb-4 rounded border border-yellow-200 bg-yellow-50 p-3 text-sm text-yellow-800">
    You haven't uploaded any documents yet. Upload one first so the assistant has something to answer from.
  </div>
)}
```

### 4. Toast-style feedback for uploads
`src/app/(dashboard)/workspaces/[workspaceId]/documents/uploader.tsx` (updated):
```tsx
"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { UploadDropzone } from "@/lib/uploadthing";

export function DocumentUploader({ workspaceId }: { workspaceId: string }) {
  const router = useRouter();
  const [message, setMessage] = useState<string | null>(null);

  return (
    <div>
      <UploadDropzone
        endpoint="documentUploader"
        onClientUploadComplete={() => {
          setMessage("Upload complete - processing your document...");
          router.refresh();
          setTimeout(() => setMessage(null), 4000);
        }}
        onUploadError={(error) => setMessage(`Upload failed: ${error.message}`)}
      />
      {message && <p className="mt-2 text-sm text-gray-600">{message}</p>}
    </div>
  );
}
```

### 5. Global 404 page
`src/app/not-found.tsx`:
```tsx
import Link from "next/link";

export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center text-center">
      <h1 className="text-3xl font-bold">404</h1>
      <p className="mt-2 text-gray-600">This page doesn't exist or you don't have access to it.</p>
      <Link href="/workspaces" className="mt-4 text-blue-600 underline">
        Back to workspaces
      </Link>
    </div>
  );
}
```

### 6. Document status polling (nice-to-have)
```tsx
"use client";
import { useEffect } from "react";
import { useRouter } from "next/navigation";

export function AutoRefreshWhileProcessing({ hasProcessing }: { hasProcessing: boolean }) {
  const router = useRouter();
  useEffect(() => {
    if (!hasProcessing) return;
    const interval = setInterval(() => router.refresh(), 3000);
    return () => clearInterval(interval);
  }, [hasProcessing, router]);
  return null;
}
```
Render it in the documents page: `<AutoRefreshWhileProcessing hasProcessing={documents.some(d => d.status === "PROCESSING")} />`.

**Checkpoint:** Navigate around the app — slow network (throttle in DevTools) shows skeletons, a thrown error shows the retry box instead of a blank crash, empty workspaces show helpful guidance instead of blank space, and the documents list auto-updates from PROCESSING to READY without a manual refresh.

**Next:** Part 15 — Deployment to Vercel (Free Tier).
