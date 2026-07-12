Here is the newly updated **Part 7**. I have completely rewritten the setup steps to utilize the modern **Clerk CLI workflow** you just provided. This replaces the manual dashboard configuration and lets the CLI do the heavy lifting of wrapping your layout, generating routes, and pulling environment variables.

*(Note: Never paste a whole document of text into PowerShell again! Run only the commands inside the code blocks below one by one.)*

---

## Blog Tutorial - Part 7: Authentication (Clerk Setup via CLI, Sign In/Up, Header UI)

### What we're doing

We'll add user sign-up/sign-in with Clerk to enable gated features (like comments and members-only content) in upcoming parts. We will use the Clerk CLI to automatically scaffold the necessary files and connect to your specific Clerk application.

### ⚠️ Next.js 16 Note: Async Auth

Clerk’s `auth()` helper is now asynchronous. While we are only setting up the UI in this part, remember for future implementation that anywhere you previously wrote `const { userId } = auth();`, you must now use `const { userId } = await auth();`.

---

### Step 1: Install & Authenticate the Clerk CLI

Instead of manually copying API keys, we'll use Clerk's command-line tool. Run these commands one by one in your project terminal:

```bash
# 1. Install the CLI globally
npm install -g clerk

# 2. Authenticate your account (This opens a browser window)
clerk auth login

```

*Wait until the terminal confirms you are logged in before proceeding.*

### Step 2: Initialize Clerk in Your Project

Run the following command to link your local codebase to your specific Clerk application. The CLI will automatically detect Next.js and modify your `layout.tsx`, scaffold auth pages, and create a proxy/middleware.

```bash
clerk init --app [clerk-unique-application-id]

```

*Press "Yes" when it asks to proceed with writing files.*

### Step 3: Pull Environment Variables

Sync your `.env.local` file with your Clerk dashboard automatically:

```bash
clerk env pull

```

### Step 4: Verify Middleware (Next.js 16)

The CLI should have created or updated `src/middleware.ts` (or `src/proxy.ts`). Open `src/middleware.ts` and verify that the `matcher` array includes the `/__clerk/:path*` route. It should look like this:

```ts
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: [
    "/((?!_next|studio|.*\\..*).*)",
    "/(api|trpc)(.*)",
    "/__clerk/:path*", // The CLI requires this for proxying
  ],
};

```

### Step 5: Verify the Setup

Run Clerk's doctor command to ensure there are no missing dependencies or conflicts:

```bash
clerk doctor

```

### Step 6: Update Header UI

The CLI wrapped our app in a `<ClerkProvider>`, but we still need to add the actual login buttons to our navigation bar. Update your `src/components/Header.tsx`:

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
          
          {/* Clerk Auth Controls */}
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

### Step 7: Create Your First User!

Start your development server:

```bash
npm run dev

```

Open `http://localhost:3000`. Click the **Sign In / Sign Up** button in your header and create your first test account. Once you see your profile icon appear, you are officially authenticated!

---

**Checkpoint ✅**

* [ ] CLI installed, authenticated, and initialized.
* [ ] `clerk env pull` successfully grabbed API keys.
* [ ] `clerk doctor` reports no errors.
* [ ] Successfully created a test user and can see the `<UserButton/>`.

**Are you ready to proceed to Part 8: Comments System (Clerk-gated, stored in Sanity)?**
