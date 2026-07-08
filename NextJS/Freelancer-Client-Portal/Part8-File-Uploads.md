# Part 8: File Uploads with UploadThing

Previous: Part 7 (Proposals).

Targets current `uploadthing` + `@uploadthing/react`. Not Next.js-version-specific beyond the standard `route.ts` handler; the file router calls Clerk's async `auth()` correctly below.

## 1. Concept

Files (contracts, briefs, design assets, screenshots) attach to a Project or Proposal via the Attachment model. Flow: user picks a file → UploadThing uploads directly to storage → calls our `onUploadComplete` → we save an Attachment row.

## 2. Create an UploadThing account and app

1. uploadthing.com → sign up → new app "freelancer-portal".
2. Copy API token.
3. `.env.local`:

```bash
UPLOADTHING_TOKEN=your_token_here
```

## 3. Install packages

```bash
pnpm add uploadthing @uploadthing/react
```

## 4. Define the file router (server)

```ts
// src/app/api/uploadthing/core.ts
import { createUploadthing, type FileRouter } from "uploadthing/next";
import { UploadThingError } from "uploadthing/server";
import { auth } from "@clerk/nextjs/server";
import { db } from "@/server/db";

const f = createUploadthing();

async function requireUser() {
  const { userId } = await auth();
  if (!userId) throw new UploadThingError("Unauthorized");

  const user = await db.user.findUnique({ where: { clerkId: userId } });
  if (!user) throw new UploadThingError("User not synced");

  return user;
}

export const ourFileRouter = {
  projectAttachment: f({
    image: { maxFileSize: "8MB", maxFileCount: 5 },
    pdf: { maxFileSize: "16MB", maxFileCount: 5 },
    text: { maxFileSize: "4MB", maxFileCount: 5 },
  })
    .input((z) => z.object({ projectId: z.string() }))
    .middleware(async ({ input }) => {
      const user = await requireUser();

      const project = await db.project.findUniqueOrThrow({
        where: { id: input.projectId },
        include: { client: true },
      });

      if (user.role !== "ADMIN" && project.client.userId !== user.id) {
        throw new UploadThingError("Forbidden");
      }

      return { userId: user.id, projectId: input.projectId };
    })
    .onUploadComplete(async ({ metadata, file }) => {
      await db.attachment.create({
        data: {
          url: file.url,
          name: file.name,
          uploadedById: metadata.userId,
          projectId: metadata.projectId,
        },
      });
      return { url: file.url };
    }),

  proposalAttachment: f({
    image: { maxFileSize: "8MB", maxFileCount: 5 },
    pdf: { maxFileSize: "16MB", maxFileCount: 5 },
  })
    .input((z) => z.object({ proposalId: z.string() }))
    .middleware(async ({ input }) => {
      const user = await requireUser();

      const proposal = await db.proposal.findUniqueOrThrow({
        where: { id: input.proposalId },
        include: { project: { include: { client: true } } },
      });

      if (user.role !== "ADMIN" && proposal.project.client.userId !== user.id) {
        throw new UploadThingError("Forbidden");
      }

      return { userId: user.id, proposalId: input.proposalId };
    })
    .onUploadComplete(async ({ metadata, file }) => {
      await db.attachment.create({
        data: {
          url: file.url,
          name: file.name,
          uploadedById: metadata.userId,
          proposalId: metadata.proposalId,
        },
      });
      return { url: file.url };
    }),
} satisfies FileRouter;

export type OurFileRouter = typeof ourFileRouter;
```

Note: `.input((z) => ...)` is the callback form for recent uploadthing versions; if yours expects plain `z.object(...)` with `import { z } from "zod"`, use that instead.

## 5. Route handler

```ts
// src/app/api/uploadthing/route.ts
import { createRouteHandler } from "uploadthing/next";
import { ourFileRouter } from "./core";

export const { GET, POST } = createRouteHandler({
  router: ourFileRouter,
});
```

`/api/uploadthing(.*)` is already in `isPublicRoute` from Part 2's middleware.

## 6. Client-side helpers

```ts
// src/lib/uploadthing.ts
import { generateUploadButton, generateUploadDropzone } from "@uploadthing/react";
import type { OurFileRouter } from "@/app/api/uploadthing/core";

export const UploadButton = generateUploadButton<OurFileRouter>();
export const UploadDropzone = generateUploadDropzone<OurFileRouter>();
```

## 7. Attachments list + upload widget on the project page

```tsx
// src/components/project-attachments.tsx
"use client";

import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { UploadDropzone } from "@/lib/uploadthing";

type Attachment = { id: string; url: string; name: string; createdAt: Date | string };

export function ProjectAttachments({
  projectId,
  attachments,
}: {
  projectId: string;
  attachments: Attachment[];
}) {
  const router = useRouter();

  return (
    <div className="space-y-4">
      <h2 className="text-lg font-semibold">Attachments</h2>

      <ul className="space-y-1">
        {attachments.map((a) => (
          <li key={a.id}>
            <a href={a.url} target="_blank" rel="noreferrer" className="text-sm underline">
              {a.name}
            </a>
          </li>
        ))}
        {attachments.length === 0 && (
          <p className="text-sm text-muted-foreground">No files yet.</p>
        )}
      </ul>

      <UploadDropzone
        endpoint="projectAttachment"
        input={{ projectId }}
        onClientUploadComplete={() => {
          toast.success("File uploaded");
          router.refresh();
        }}
        onUploadError={(err) => toast.error(`Upload failed: ${err.message}`)}
      />
    </div>
  );
}
```

Wire into the admin project detail page (Part 5), passing `project.id` and `project.attachments`.

## 8. (Optional) Attachments on a proposal

Same pattern with `proposalAttachment` as the endpoint — left as an exercise, direct copy of the above.

## Checkpoint

- [ ] Project detail page shows an UploadThing dropzone
- [ ] Uploading creates an Attachment row, appears after `router.refresh()`
- [ ] A CLIENT uploading to a project that isn't theirs gets Forbidden

## Troubleshooting

- **Env var not picked up**: restart `pnpm dev` after adding `UPLOADTHING_TOKEN`
- **Type error on `.input()`**: check zod callback vs direct-object version mismatch

## Next

Continue to **Part 9: Chat**.
