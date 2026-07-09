# Part 5: Installing Clerk in Next.js 16 (ClerkProvider + Middleware)

Now we wire Clerk into our actual Next.js 16 project.

## 1. Install the SDK

In your project folder:

```bash
npm install @clerk/nextjs
```

`@clerk/nextjs` tracks current Next.js releases closely and is fully compatible with Next.js 16, including Turbopack and the async dynamic APIs we'll use throughout this series.

## 2. Add your environment variables

Create a file named `.env.local` in the project root (same level as `package.json`):

```bash
# .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_key_here
CLERK_SECRET_KEY=sk_test_your_key_here
```

Paste in the actual values from your Clerk Dashboard (Configure → API Keys) from Part 4.

Also add optional redirect URL env vars, which tell Clerk where to send users after auth actions (used by the prebuilt components in Part 6):

```bash
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=/dashboard
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=/dashboard
```

**Important:** `.env.local` should never be committed to Git. Check your `.gitignore` (created automatically by `create-next-app`) already includes:

```
.env*.local
```

Verify with:
```bash
cat .gitignore
```

## 3. Wrap your app in `<ClerkProvider>`

Open `src/app/layout.tsx` and update it:

```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "Acme Boards",
  description: "A Next.js + Clerk + Tailwind demo app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

`ClerkProvider` makes auth state available to every component in your app via React context — it must wrap everything.

## 4. Add middleware to protect routes later

Create `src/middleware.ts` (note: at `src/`, sibling to `app/`, not inside `app/`):

```ts
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: [
    // Skip Next.js internals and all static files, unless found in search params
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip)).*)",
    // Always run for API routes
    "/(api|trpc)(.*)",
  ],
};
```

This is Clerk's recommended default matcher — it makes sure the middleware runs on every page and API route except static assets. Right now, `clerkMiddleware()` with no arguments doesn't block anything yet — it just makes auth state available. We'll add actual route protection in Part 7.

**Next.js 16 note:** middleware continues to work exactly as shown here. Under the hood, Next.js has been expanding middleware runtime support (beyond the historical Edge-only runtime), but `clerkMiddleware()`'s public API and this file's shape are unaffected — you don't need to configure a runtime explicitly for this tutorial.

## 5. Test that Clerk is wired up

Run your dev server:

```bash
npm run dev
```

Visit http://localhost:3000. The page should load exactly as before — no visible change yet, but if there's a misconfiguration (like a missing key), you'll see an error in the terminal or browser console. If it loads cleanly, Clerk is successfully installed and initialized.

## 6. Commit your progress

```bash
git add .
git commit -m "Install and initialize Clerk"
```

(`.env.local` will NOT be committed, which is correct — it should never go into Git.)

## Checkpoint

- [ ] `@clerk/nextjs` installed
- [ ] `.env.local` created with your publishable and secret keys (and NOT committed to Git)
- [ ] `RootLayout` wrapped in `<ClerkProvider>`
- [ ] `src/middleware.ts` created with `clerkMiddleware()`
- [ ] App still loads fine at localhost:3000 with no errors

## Troubleshooting

**Error: "Missing publishableKey" or similar.**
Your `.env.local` isn't being picked up. Check: (1) the file is named exactly `.env.local` (not `.env.local.txt`), (2) it's in the project root, (3) you restarted `npm run dev` after creating/editing it — Next.js only reads env files at server start.

**Error mentioning `clerkMiddleware` is not a function / import error.**
Make sure you're importing from `@clerk/nextjs/server` (not `@clerk/nextjs`) in `middleware.ts` — this is a common typo since most other Clerk imports come from `@clerk/nextjs` directly.

**Middleware file not being picked up at all.**
It must be named `middleware.ts` and live at `src/middleware.ts` if you're using a `src/` directory (or at the project root `middleware.ts` if not). Check which structure `create-next-app` gave you and place it at the same level as your `app/` folder.

**I see a warning about `CLERK_SECRET_KEY` being used in a client component.**
You haven't done anything wrong yet if you followed the steps exactly — this warning shows up if the secret key ever gets imported into client-side code. Just make sure you never import `CLERK_SECRET_KEY` directly in a file marked `"use client"`.

**Keys aren't working / "Invalid publishable key" error.**
Double check you copied the *entire* key (they're long) and that there's no extra whitespace or quote characters pasted in from the dashboard. Also confirm you copied keys from the correct application if you created more than one in Part 4.

**Something in the terminal mentions Turbopack while starting up — is that a problem?**
No — that's expected in Next.js 16, since Turbopack is now the default dev/build bundler. It doesn't change anything about how Clerk is configured.

Next up: Part 6, where we add sign-in and sign-up pages using Clerk's prebuilt components.
