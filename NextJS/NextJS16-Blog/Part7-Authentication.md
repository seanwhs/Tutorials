## Blog Tutorial - Part 7: Authentication (Clerk Setup via CLI, Sign In/Up, Header UI)

### What we're doing

We'll add user sign-up/sign-in with Clerk to enable gated features (like comments and members-only content). We will use the Clerk CLI to automatically scaffold the necessary files and connect to your specific Clerk application.

### ⚠️ Next.js 16 & Clerk v7 Note

Clerk’s `auth()` helper is now asynchronous. Additionally, Clerk v7 has updated its component library. We will use the latest patterns to ensure your project builds successfully.

---

### Step 1: Install & Authenticate the Clerk CLI

Run these commands in your project terminal:

```bash
# 1. Install the CLI globally
npm install -g clerk

# 2. Authenticate your account
clerk auth login

```

### Step 2: Initialize Clerk

Link your local codebase to your Clerk app using the ID found via `clerk apps list`:

```bash
clerk init --app [unique-clerk-project-id]

```

### Step 3: Pull Environment Variables

Sync your `.env.local` file automatically:

```bash
clerk env pull

```

### Step 4: Configure the Proxy

Next.js 16 prefers `proxy.ts` over `middleware.ts`. Create or update `src/proxy.ts` in your `src/` directory:

```ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

// Define public routes
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
    "/__clerk/:path*", // Required for proxying
  ],
};

```

### Step 5: Update Header UI (Clerk v7+ Syntax)

Update `src/components/Header.tsx`. Note the use of `<Show/>`, which replaces the deprecated `SignedIn`/`SignedOut` components in Clerk v7:

```tsx
import Link from "next/link";
import { Show, SignInButton, UserButton } from "@clerk/nextjs";
import { client } from "@/sanity/lib/client";
import { CATEGORIES_QUERY } from "@/sanity/lib/queries";
import type { Category } from "@/sanity/lib/types";

export default async function Header() {
  const categories = await client.fetch<Category[]>(CATEGORIES_QUERY);

  return (
    <header className="border-b border-gray-200 dark:border-gray-800">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-bold">Greymatter Journal</Link>
        <div className="flex items-center gap-6">
          <nav className="flex gap-4 text-sm">
            {categories.map((cat) => (
              <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`} className="text-gray-600 hover:text-gray-900">
                {cat.title}
              </Link>
            ))}
          </nav>
          
          {/* Clerk v7 Auth Controls */}
          <div className="flex items-center gap-2 border-l pl-4">
            <Show when="signed-out">
              <SignInButton mode="modal">
                <button className="text-sm font-medium hover:text-gray-900">Sign In</button>
              </SignInButton>
            </Show>
            <Show when="signed-in">
              <UserButton />
            </Show>
          </div>
        </div>
      </div>
    </header>
  );
}

```

### Step 6: Verify

Restart your server: `npm run dev`. Visit `http://localhost:3000` and click "Sign In."

---

**Checkpoint ✅**

* [ ] CLI initialized and linked.
* [ ] `src/proxy.ts` correctly configured.
* [ ] `Header.tsx` updated with `<Show/>` components.
* [ ] Sign-in modal functional and user state reflected.

**Are you ready to proceed to Part 8: Comments System (Clerk-gated, stored in Sanity)?**
