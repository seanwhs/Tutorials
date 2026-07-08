## Blog Tutorial - Part 7: Authentication (Clerk Setup, Sign In/Up, Header UI)

## What we're doing
We'll add user sign-up/sign-in with Clerk (free tier, up to 10,000 monthly active users), protect nothing yet globally, but wire up the UI (sign in/out buttons, user avatar) so we can build gated features (comments, members-only posts) in the next parts.

## ⚠️ Next.js 16 change: auth() is now async

Clerk's server-side `auth()` helper (from `@clerk/nextjs/server`) now returns a `Promise` in versions compatible with Next.js 16, matching Next.js's own async dynamic APIs (`params`, `headers()`, `cookies()`). Anywhere we previously wrote `const { userId } = auth();` we now must write `const { userId } = await auth();`. We'll apply this in Part 9 when we gate members-only content.

## Step 1: Create a free Clerk account and application
1. Go to https://clerk.com and sign up (free, no credit card)
2. Click "Create Application", name it "my-blog"
3. Choose sign-in options: Email + Google (or whatever you prefer) — Email is simplest for following along
4. After creation, Clerk shows you API keys. Copy them.
5. Make sure you install a recent version of `@clerk/nextjs` (the one installed in Part 1) — recent releases explicitly support Next.js 16 and its async APIs.

## Step 2: Add Clerk environment variables

Add to `.env.local` (alongside your Sanity vars from Part 2):

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxx

NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/
```

(`@clerk/nextjs` was already installed back in Part 1.)

## Step 3: Wrap the app in ClerkProvider

Update `src/app/layout.tsx`:

```tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { ClerkProvider } from "@clerk/nextjs";
import Header from "@/components/Header";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "My Blog",
  description: "A blog built with Next.js, Tailwind CSS, Sanity, and Clerk",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className={inter.className}>
          <Header />
          {children}
        </body>
      </html>
    </ClerkProvider>
  );
}
```

## Step 4: Add Clerk middleware

Create `src/middleware.ts`:

```ts
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: [
    "/((?!_next|studio|.*\\..*).*)",
    "/(api|trpc)(.*)",
  ],
};
```

Important: notice we **exclude `/studio`** from the matcher pattern — Sanity Studio manages its own auth session and we don't want Clerk middleware interfering with it. This exclusion pattern is unchanged in Next.js 16.

## Step 5: Create sign-in and sign-up pages

Create `src/app/sign-in/[[...sign-in]]/page.tsx`:

```tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center">
      <SignIn />
    </main>
  );
}
```

Create `src/app/sign-up/[[...sign-up]]/page.tsx`:

```tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center">
      <SignUp />
    </main>
  );
}
```

Clerk's `<SignIn />` and `<SignUp />` components render a full, prebuilt, styled auth form — no custom form-building needed. Note: like Part 5/6's post/category/author routes, these catch-all routes (`[[...sign-in]]`, `[[...sign-up]]`) technically also receive a `params` Promise, but we never read `params` inside these files, so no `await` is needed here.

## Step 6: Add auth buttons to the Header

Update `src/components/Header.tsx`:

```tsx
import Link from "next/link";
import {
  SignedIn,
  SignedOut,
  SignInButton,
  UserButton,
} from "@clerk/nextjs";
import { client } from "@/sanity/lib/client";
import { CATEGORIES_QUERY } from "@/sanity/lib/queries";
import type { Category } from "@/sanity/lib/types";

export default async function Header() {
  const categories = await client.fetch<Category[]>(CATEGORIES_QUERY);

  return (
    <header className="border-b border-gray-200 dark:border-gray-800">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-bold">
          My Blog
        </Link>
        <div className="flex items-center gap-4">
          <nav className="flex gap-4 text-sm">
            {categories.map((cat) => (
              <Link
                key={cat.slug.current}
                href={`/categories/${cat.slug.current}`}
                className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white"
              >
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
            <UserButton afterSignOutUrl="/" />
          </SignedIn>
        </div>
      </div>
    </header>
  );
}
```

`<SignedIn>` / `<SignedOut>` conditionally render children based on auth state, with no flicker on the server since Clerk hydrates this correctly with Next.js App Router. These components don't call `auth()` directly themselves so no async change is visible here — the async change only affects code where *we* call `auth()` or `currentUser()` ourselves, which starts in Part 8.

## Step 7: Test it

```bash
npm run dev
```

- Click "Sign In" → a modal should appear with Clerk's sign-in form
- Create an account (use a real email you can access, or a "+alias" trick like `you+test@gmail.com`)
- After signing in, you should see your avatar (UserButton) in the header
- Click the avatar → "Sign out" → you should return to the signed-out state

## Checkpoint ✅
- [ ] `.env.local` has Clerk keys
- [ ] Sign In button opens a working modal
- [ ] You can create an account and see your avatar afterward
- [ ] Sign out works
- [ ] `/studio` still works and is unaffected by Clerk middleware

Next: **Part 8 — Comments System (Clerk-gated, stored in Sanity)**
