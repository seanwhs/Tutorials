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

### Step 2: Configure the Middleware

In Next.js, `src/middleware.ts` (or `src/proxy.ts` depending on your setup) manages request protection. This ensures non-public routes require authentication:

```typescript
// src/middleware.ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher(["/", "/sign-in(.*)", "/sign-up(.*)", "/categories(.*)", "/posts(.*)"]);

export default clerkMiddleware(async (auth, request) => {
  if (!isPublicRoute(request)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};

```

### Step 3: Orchestrated Header Components

To maintain clean architecture, we separate the server-side `Header` from the client-side authentication logic.

**`src/components/HeaderAuth.tsx`**
This Client Component handles the interactive state.

```tsx
"use client";

import { Show, SignInButton, UserButton } from "@clerk/nextjs";
import ThemeToggle from "./ThemeToggle";

export const HeaderAuth = () => {
  return (
    <div className="flex items-center gap-4 border-l pl-6 dark:border-gray-700">
      <ThemeToggle />
      <Show when="signed-out">
        <SignInButton mode="modal">
          <button className="rounded-full bg-black px-4 py-1.5 text-sm font-medium text-white dark:bg-white dark:text-black">
            Sign In
          </button>
        </SignInButton>
      </Show>
      <Show when="signed-in">
        <UserButton />
      </Show>
    </div>
  );
};

```

**`src/components/Header.tsx`**
The Server Component fetches data and orchestrates the layout.

```tsx
import Link from "next/link";
import { client } from "@/sanity/lib/client";
import { CATEGORIES_QUERY } from "@/sanity/lib/queries";
import type { Category } from "@/sanity/lib/types";
import { HeaderAuth } from "./HeaderAuth";

export default async function Header() {
  const categories = await client.fetch<Category[]>(CATEGORIES_QUERY);

  return (
    <header className="border-b border-gray-200 dark:border-gray-800">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-bold">Greymatter Journal</Link>
        <div className="flex items-center gap-6">
          <nav className="flex gap-4 text-sm">
            {categories.map((cat) => (
              <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`} className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white">
                {cat.title}
              </Link>
            ))}
          </nav>
          <HeaderAuth />
        </div>
      </div>
    </header>
  );
}

```

### Step 4: Add the Footer

Maintain consistent branding and navigation links at the base of every page.

**`src/components/Footer.tsx`**

```tsx
import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t border-gray-200 dark:border-gray-800">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-8 text-sm text-gray-500 dark:text-gray-400">
        <p>&copy; {new Date().getFullYear()} Greymatter Journal. All rights reserved.</p>
        <div className="flex gap-6">
          <Link href="/privacy" className="hover:text-gray-900 dark:hover:text-white">Privacy</Link>
          <Link href="/terms" className="hover:text-gray-900 dark:hover:text-white">Terms</Link>
        </div>
      </div>
    </footer>
  );
}

```

---

### Checkpoint ✅

* [ ] **CLI Sync:** Clerk project is linked and `.env` variables are active.
* [ ] **Middleware:** Routes are correctly protected/public.
* [ ] **UI:** Header and Footer are unified and properly orchestrate client/server components.
