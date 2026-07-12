## Blog Tutorial - Part 7: Authentication (Clerk Setup, Sign In/Up, Header UI)

### What we're doing

We'll add user sign-up/sign-in with Clerk to enable gated features (like comments and members-only content) in upcoming steps.

### ⚠️ Next.js 16 Note: Async Auth

Clerk’s `auth()` helper is now asynchronous. While we are only setting up the UI in this part, remember for future implementation that anywhere you previously wrote `const { userId } = auth();`, you must now use `const { userId } = await auth();`.

---

### Step 1: Clerk Setup

1. Go to [Clerk](https://clerk.com) and create an application named "Greymatter Journal".
2. Enable **Email** or **Google** sign-in providers.
3. Copy your **Publishable Key** and **Secret Key**.

### Step 2: Environment Variables

Add these to your `.env.local`:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxx

NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up

```

### Step 3: Wrap the App

Update `src/app/layout.tsx`:

```tsx
import { ClerkProvider } from "@clerk/nextjs";
import Header from "@/components/Header";
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>
          <Header />
          {children}
        </body>
      </html>
    </ClerkProvider>
  );
}

```

### Step 4: Add Middleware

Create `src/middleware.ts`. This protects your routes and ensures Sanity Studio remains accessible.

```ts
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: ["/((?!_next|studio|.*\\..*).*)", "/(api|trpc)(.*)"],
};

```

### Step 5: Auth Pages

Create `src/app/sign-in/[[...sign-in]]/page.tsx` and `src/app/sign-up/[[...sign-up]]/page.tsx`:

```tsx
// Inside both files, replace import with either SignIn or SignUp
import { SignIn } from "@clerk/nextjs";

export default function AuthPage() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center">
      <SignIn />
    </main>
  );
}

```

### Step 6: Update Header UI

Update `src/components/Header.tsx` to include auth controls:

```tsx
import Link from "next/link";
import { SignedIn, SignedOut, SignInButton, UserButton } from "@clerk/nextjs";
import { client } from "@/sanity/lib/client";
import { CATEGORIES_QUERY } from "@/sanity/lib/queries";
import type { Category } from "@/sanity/lib/types";

export default async function Header() {
  const categories = await client.fetch<Category[]>(CATEGORIES_QUERY);

  return (
    <header className="border-b border-gray-200 dark:border-gray-800">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-bold">Greymatter Journal</Link>
        <div className="flex items-center gap-4">
          <nav className="flex gap-4 text-sm">
            {categories.map((cat) => (
              <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`} className="text-gray-600 hover:text-gray-900">
                {cat.title}
              </Link>
            ))}
          </nav>
          <SignedOut>
            <SignInButton mode="modal">
              <button className="rounded-full bg-black px-4 py-1.5 text-sm font-medium text-white dark:bg-white dark:text-black">
                Sign In
              </button>
            </SignInButton>
          </SignedOut>
          <SignedIn>
            <UserButton />
          </SignedIn>
        </div>
      </div>
    </header>
  );
}

```

---

**Checkpoint ✅**

* [ ] `.env.local` configured.
* [ ] Auth modal opens via Header.
* [ ] User authentication persists and shows avatar.
* [ ] Sanity Studio remains accessible.

**Are you ready to proceed to Part 8: Comments System (Clerk-gated, stored in Sanity)?**
