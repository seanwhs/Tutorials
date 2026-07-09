# Part 4: Clerk Authentication Integration

Clerk's Next.js SDK is fully compatible with Next.js 16; its server helpers (`auth()`, `currentUser()`) are async and must be awaited.

## 1. Get your Clerk API keys
Clerk dashboard → **API Keys** → copy Publishable key + Secret key.

## 2. Environment variables
Create `.env.local`:
```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxx

NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=/dashboard
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=/dashboard
```
(Confirm `.env.local` is in `.gitignore`.)

## 3. Wrap app in ClerkProvider
```tsx
// src/app/layout.tsx
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en"><body>{children}</body></html>
    </ClerkProvider>
  );
}
```

## 4. Middleware to protect routes
```ts
// src/middleware.ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher(["/dashboard(.*)", "/my-rsvps(.*)"]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
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
`/dashboard` and `/my-rsvps` require login; everything else stays public. Note `clerkMiddleware`'s callback is async and `auth.protect()` is awaited.

## 5. Sign-in/sign-up pages
```tsx
// src/app/sign-in/[[...sign-in]]/page.tsx
import { SignIn } from "@clerk/nextjs";
export default function Page() {
  return <div className="flex min-h-screen items-center justify-center"><SignIn /></div>;
}
```
Same pattern for `src/app/sign-up/[[...sign-up]]/page.tsx` with `<SignUp />`.

## 6. Auth-aware header
Create `src/components/site-header.tsx` using `<SignedIn>`/`<SignedOut>`/`<SignInButton>`/`<SignUpButton>`/`<UserButton>` from `@clerk/nextjs` — shows "Browse Events" always, plus "My Dashboard"/"My RSVPs"/UserButton when signed in, or Sign in/Sign up buttons when signed out. Then wire it into `layout.tsx` above `{children}`.

## 7. Reading the logged-in user server-side (async)
```ts
import { auth, currentUser } from "@clerk/nextjs/server";

const { userId } = await auth();        // fast, ID only
const user = await currentUser();        // full profile
```
Both must always be awaited — no sync version exists. `userId` (e.g. `user_2abc123...`) is what we store as the owner of events/RSVPs.

## 8. Try it out
```bash
pnpm dev
```
Sign up a test account — should redirect to `/dashboard` (404 expected, built in Part 8). Confirm `<UserButton>` appears.

## Checkpoint
- [ ] Sign up flow works (404 at `/dashboard` is fine)
- [ ] Sign out/in works
- [ ] `/events` doesn't require login; `/dashboard`/`/my-rsvps` do (verify later once built)

**Next: Part 5 — Neon Postgres Setup and Drizzle ORM**
