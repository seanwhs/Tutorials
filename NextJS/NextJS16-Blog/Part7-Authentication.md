## Blog Tutorial — Part 7: Authentication with Clerk

In this part, we integrate Clerk to manage user identity. This enables gated access for features like the comments system and members-only content.

### Step 1: CLI Initialization

Use the Clerk CLI to connect your local development environment to your application dashboard:

```bash
# 1. Install & Authenticate
npm install -g clerk
clerk auth login

# 2. Link your app & sync environment variables
clerk init --app [your-unique-clerk-project-id]
clerk env pull

```

### Step 2: Configure the Proxy

In Next.js 16, standard practice is to use `src/proxy.ts` (or `middleware.ts`) to manage request protection. This ensures all non-public routes require authentication:

```typescript
// src/proxy.ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher(["/", "/sign-in(.*)", "/sign-up(.*)"]);

export default clerkMiddleware(async (auth, request) => {
  if (!isPublicRoute(request)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
    "/__clerk/:path*", 
  ],
};

```

### Step 3: Updated Header UI (Clerk v7+)

The updated Header uses the `<Show/>` component to toggle authentication UI states. Update `src/components/Header.tsx`:

```tsx
import { Show, SignInButton, UserButton } from "@clerk/nextjs";
import Link from "next/link";
import { client } from "@/sanity/lib/client";
import { CATEGORIES_QUERY } from "@/sanity/lib/queries";
import type { Category } from "@/sanity/lib/types";

export default async function Header() {
  const categories = await client.fetch<Category[]>(CATEGORIES_QUERY);

  return (
    <header className="border-b px-4 py-4">
      <nav className="mx-auto flex max-w-5xl items-center justify-between">
        <Link href="/" className="text-lg font-bold">Greymatter Journal</Link>
        <div className="flex items-center gap-6">
          <div className="flex gap-4 text-sm">
            {categories.map((cat) => (
              <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`}>{cat.title}</Link>
            ))}
          </div>
          
          <div className="border-l pl-4">
            <Show when="signed-out">
              <SignInButton mode="modal">
                <button className="text-sm font-medium">Sign In</button>
              </SignInButton>
            </Show>
            <Show when="signed-in">
              <UserButton />
            </Show>
          </div>
        </div>
      </nav>
    </header>
  );
}

```

---

### Checkpoint ✅

* [ ] **CLI Sync:** Clerk project is linked and `.env` variables are active.
* [ ] **Proxy Config:** `src/proxy.ts` is handling protected routes correctly.
* [ ] **UI:** Header displays appropriate auth controls based on user session state.

