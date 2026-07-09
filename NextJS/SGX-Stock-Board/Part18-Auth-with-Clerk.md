# Part 18: Auth & Watchlists (Clerk)

## Concept

Up to now every feature has worked without login. Now we add Clerk for authentication so users can save a personal watchlist of SGX tickers (with optional target alert prices, used in Part 19). Clerk handles sign-up/sign-in UI, sessions, and gives us a `userId` we attach to our `WatchlistItem` and `Alert` models from Part 3.

## Step 1: Create a free Clerk application

1. Go to clerk.com, sign up free, create a new application.
2. Choose your sign-in options (Email + Google is a good default for a portfolio demo).
3. Copy the Publishable Key and Secret Key into `.env.local`:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_xxxx"
CLERK_SECRET_KEY="sk_test_xxxx"
```

## Step 2: Wrap the app with ClerkProvider

Update `src/app/layout.tsx`:

```tsx
// src/app/layout.tsx
import { ClerkProvider, SignInButton, SignedIn, SignedOut, UserButton } from "@clerk/nextjs";
import { Toaster } from "@/components/ui/sonner";
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en" className="dark">
        <body>
          <header className="flex items-center justify-between p-4 border-b">
            <a href="/" className="font-bold text-lg">SGX Dashboard</a>
            <nav className="flex items-center gap-4">
              <a href="/reits" className="text-sm text-muted-foreground">REITs</a>
              <a href="/simulator" className="text-sm text-muted-foreground">CPF/SRS Simulator</a>
              <a href="/watchlist" className="text-sm text-muted-foreground">Watchlist</a>
              <SignedOut>
                <SignInButton mode="modal" />
              </SignedOut>
              <SignedIn>
                <UserButton />
              </SignedIn>
            </nav>
          </header>
          <main>{children}</main>
          <Toaster />
        </body>
      </html>
    </ClerkProvider>
  );
}
```

## Step 3: Middleware to protect watchlist routes

Create `src/middleware.ts`:

```typescript
// src/middleware.ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher([
  "/watchlist(.*)",
  "/api/watchlist(.*)",
  "/api/alerts(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: ["/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)", "/(api|trpc)(.*)"],
};
```

This ensures unauthenticated users are redirected to sign in when visiting `/watchlist` or calling watchlist/alert API routes, while all our stock data pages stay public. Note the current Clerk API: `await auth.protect()` inside `clerkMiddleware`.

## Step 4: Watchlist API routes

Create `src/app/api/watchlist/route.ts` (this route has no dynamic segment, so no `params` handling is needed here):

```typescript
// src/app/api/watchlist/route.ts
import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { resolveStock } from "@/lib/stock-service";
import { normalizeTicker } from "@/lib/tickers";

const AddSchema = z.object({
  ticker: z.string(),
  alertPrice: z.number().optional(),
});

export async function GET() {
  const { userId } = await auth();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const items = await prisma.watchlistItem.findMany({
    where: { userId },
    include: { stock: true },
    orderBy: { createdAt: "desc" },
  });

  return NextResponse.json({ items });
}

export async function POST(req: NextRequest) {
  const { userId } = await auth();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const body = AddSchema.parse(await req.json());
  const ticker = normalizeTicker(body.ticker);
  await resolveStock(ticker);

  const item = await prisma.watchlistItem.upsert({
    where: { userId_ticker: { userId, ticker } },
    update: { alertPrice: body.alertPrice },
    create: { userId, ticker, alertPrice: body.alertPrice },
  });

  return NextResponse.json({ item });
}
```

> **Next.js 16 note:** The removal route below *does* have a dynamic `[ticker]` segment, so — as with every dynamic route in this series (see Part 7) — its `params` is `Promise`-based and must be awaited.

Create `src/app/api/watchlist/[ticker]/route.ts` for removal:

```typescript
// src/app/api/watchlist/[ticker]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";
import { normalizeTicker } from "@/lib/tickers";

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  const { userId } = await auth();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { ticker: rawTicker } = await params;
  const ticker = normalizeTicker(rawTicker);

  await prisma.watchlistItem.delete({
    where: { userId_ticker: { userId, ticker } },
  }).catch(() => null);

  return NextResponse.json({ success: true });
}
```

Note: this requires `@@unique([userId, ticker])` on `WatchlistItem`, which we already defined back in Part 3.

## Step 5: The Watchlist UI

Create `src/app/(dashboard)/watchlist/page.tsx` as a server component that checks `auth()` server-side and renders a `WatchlistTable` client component. This page has no dynamic route segment, so it needs no `params` handling. The `WatchlistTable`:
- Fetches `/api/watchlist` on mount
- Renders a table (shadcn `Table`) with columns: Ticker, Name, Current Price (fetched per-row via `useQuote` from Part 9), Day Change, Alert Price (editable inline), Remove button
- An "Add to Watchlist" search box (reusing the `/api/stocks/search` route from Part 7) with an inline alert price input

Also add a small "Add to Watchlist" button/star icon on the stock detail page that calls the same POST endpoint, using Clerk's `<SignedIn>`/`<SignedOut>` components to prompt sign-in if the user isn't authenticated yet. Since that page already resolves `ticker` from its awaited `params` (Part 8), just pass it down as a prop.

## Step 6: Test the flow

1. Visit any page while signed out — confirm public stock pages still work.
2. Click Sign In, complete Clerk's modal sign-up flow.
3. Visit `/watchlist` — should now load (previously would redirect to sign-in).
4. Add a ticker with a target alert price, confirm it appears in the table.
5. Confirm removing an item works and confirm data persists across a page refresh (it's in Postgres, not just local state).

## Checkpoint

- [ ] Clerk keys added, `ClerkProvider` wraps the app, header shows Sign In / UserButton correctly
- [ ] Middleware protects `/watchlist` and watchlist/alert API routes only
- [ ] Watchlist API routes (GET/POST/DELETE) work correctly, scoped per authenticated `userId`, with the DELETE route correctly awaiting its `Promise`-based `params`
- [ ] Watchlist UI lets you add, view, and remove tracked tickers with optional alert prices
- [ ] Data persists across sessions (stored in Postgres via Prisma)

Next: **Part 19 — Price Alerts (Vercel Cron + Email)**, where we build the background job that checks watchlist alert prices and emails users when triggered.
