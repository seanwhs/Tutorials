# Sanity Mastery - Part 9: Auth, Tokens, CORS & Roles

## Token Types & When to Use Each

| Token Role | Can Read Published? | Can Read Drafts? | Can Write? | Use Case |
|---|---|---|---|---|
| (none — public CDN client) | Yes | No | No | Public site rendering (Part 4) |
| **Viewer** | Yes | Yes | No | Draft preview (Part 7), read-only scripts |
| **Editor** | Yes | Yes | Yes (not schema/settings) | Content migration scripts, custom write UIs |
| **Administrator** | Yes | Yes | Yes (incl. project settings) | CI/CD schema deploys, full admin scripts — never expose client-side |

Create tokens at **sanity.io/manage → project → API → Tokens**. Every token is a secret — store as an unprefixed env var (`SANITY_...`, never `NEXT_PUBLIC_SANITY_...`).

```bash
# .env.local — full picture across the series
NEXT_PUBLIC_SANITY_PROJECT_ID=abc123xy      # not secret — public identifier
NEXT_PUBLIC_SANITY_DATASET=production        # not secret
NEXT_PUBLIC_SANITY_API_VERSION=2025-01-01     # not secret
SANITY_API_READ_TOKEN=sk...                   # Viewer token — Part 7 preview
SANITY_REVALIDATE_SECRET=...                  # webhook shared secret — Part 8
SANITY_PREVIEW_SECRET=...                     # preview route shared secret — Part 7
SANITY_WRITE_TOKEN=sk...                      # Editor token — only if you build write features (below)
```

## CORS Origins

Sanity's API rejects browser requests from origins not on an allowlist (this matters for Studio and any client-side `client.fetch` calls, e.g. from `@sanity/vision` or a client component).

**sanity.io/manage → project → API → CORS Origins → Add CORS origin:**

| Environment | Origin | Allow credentials? |
|---|---|---|
| Local dev | `http://localhost:3000` | Yes |
| Preview deployments | `https://*.vercel.app` (or exact preview domain pattern) | Yes |
| Production | `https://yourapp.com` | Yes |

> "Allow credentials" must be checked for the embedded Studio to authenticate correctly — it uses cookies for the editor's login session.

## Roles & Project Members

Sanity project roles (assigned per-member at **manage → project → Members**) control **Studio access**, separate from API tokens:

| Role | Studio Access |
|---|---|
| **Administrator** | Full — manage members, schema deploys, datasets, billing |
| **Editor** | Create/edit/publish/delete any document |
| **Contributor** (custom role, paid tiers) | Create/edit but not publish — useful for external writers |
| **Viewer** | Read-only Studio access |

> On the free tier you get 3 total project members — plan who needs Studio login access accordingly. Anyone consuming the *public* website needs **no** Sanity account at all — that's the entire point of decoupling read access (CDN, public) from write access (Studio, authenticated).

## Securing a Custom Write Operation (e.g. a "like" counter or contact form saved to Sanity)

```ts
// src/sanity/writeClient.ts
import { createClient } from "next-sanity";

// Separate from both `client` and `previewClient` — this one can write,
// so its token must NEVER be exposed to the browser. Only import this
// file from Server Actions or Route Handlers.
export const writeClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2025-01-01",
  useCdn: false,
  token: process.env.SANITY_WRITE_TOKEN, // Editor-role token
});
```

```ts
// src/app/actions/incrementLikes.ts
"use server"; // Server Action — code here never ships to the client bundle

import { writeClient } from "@/sanity/writeClient";
import { revalidateTag } from "next/cache";

export async function incrementLikes(postId: string) {
  // .patch().inc() is an atomic increment — safe under concurrent requests,
  // unlike "read current value, add 1, write back" which can race.
  await writeClient.patch(postId).inc({ likes: 1 }).commit();
  revalidateTag(`post:${postId}`);
}
```

```tsx
// src/components/LikeButton.tsx
"use client";

import { incrementLikes } from "@/app/actions/incrementLikes";
import { useTransition } from "react";

export function LikeButton({ postId }: { postId: string }) {
  const [isPending, startTransition] = useTransition();

  return (
    <button
      disabled={isPending}
      onClick={() => startTransition(() => incrementLikes(postId))}
      className="rounded-full border px-3 py-1 text-sm hover:bg-gray-50 disabled:opacity-50"
    >
      👍 Like
    </button>
  );
}
```

## Securing Studio's `/studio` Route from Non-Editors (Optional)

If your app also uses an auth provider (e.g. Clerk, NextAuth) for the rest of the site, you generally **don't** need to protect `/studio` yourself — Sanity's own login handles authorization to the Content Lake. But if you want to hide the route entirely from the public:

```ts
// src/middleware.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith("/studio")) {
    // Example: gate by a simple allowlist cookie/header set by your own auth.
    // Replace with real session validation from your auth provider.
    const isTeamMember = request.cookies.get("team_member")?.value === "true";
    if (!isTeamMember) {
      return NextResponse.redirect(new URL("/", request.url));
    }
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/studio/:path*"],
};
```

> Remember from Part 1: Sanity's own auth is independent of this. This middleware is an *extra* layer, not a replacement — Studio still requires a real Sanity login underneath regardless.

## Checkpoint ✅
- [ ] You understand the 3 token roles and never expose Editor/Admin tokens client-side
- [ ] CORS origins configured for localhost, preview, and production domains
- [ ] Project members' Studio roles reviewed and minimized
- [ ] (If applicable) a write Server Action created using `writeClient`, never a client-exposed token

**Next: Part 10 — Advanced Patterns**
