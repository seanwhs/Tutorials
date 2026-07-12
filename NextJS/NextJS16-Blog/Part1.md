## Blog Tutorial - Part 1: Project Setup (Next.js 16 + Tailwind CSS v4)

### What we're doing

We will scaffold a robust, production-ready Next.js 16 project. We’ll prioritize performance by setting up **Route Groups** from day one, ensuring our main application stays lightweight while isolating heavy providers (like Clerk) from admin/studio routes.

### Step 0: Verify Node.js

Next.js 16 requires **Node.js 20.9+** (Node 22 LTS recommended).

```bash
node -v

```

### Step 1: Initialize the Project

```bash
npx create-next-app@latest my-blog

```

**Select these settings:**

* TypeScript: **Yes** | ESLint: **Yes** | Tailwind CSS: **Yes** | `src/` dir: **Yes**
* App Router: **Yes** | Turbopack: **Yes** | Import alias: **Yes** (`@/*`)

### Step 2: Establish the Route Group Architecture

To prevent "provider bloat" (where your CMS Studio inherits heavy Auth logic), we use a **Route Group** pattern.

1. Create `src/app/(main)` directory.
2. Move `page.tsx` and `globals.css` into `src/app/(main)`.
3. Keep `layout.tsx` in `src/app/` (the Root Layout).

**Root Layout (`src/app/layout.tsx`):**
Handles the basic HTML structure for the entire application.

```tsx
import "./globals.css";
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

```

**Main Layout (`src/app/(main)/layout.tsx`):**
Houses your global UI and Authentication.

```tsx
import { ClerkProvider } from "@clerk/nextjs";
import { Suspense } from "react";
import Header from "@/components/Header";

export default function MainLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <Suspense fallback={<div className="h-16" />}>
        <Header />
      </Suspense>
      <main>{children}</main>
    </ClerkProvider>
  );
}

```

### Step 3: Components - Server vs. Client Split

To optimize performance, we keep data fetching on the server and interactivity on the client.

**`src/components/Header.tsx` (Server Component):**

```tsx
import Link from "next/link";
import { client } from "@/sanity/lib/client";
import { CATEGORIES_QUERY } from "@/sanity/lib/queries";
import { HeaderAuth } from "./HeaderAuth";

export default async function Header() {
  const categories = await client.fetch(CATEGORIES_QUERY);
  return (
    <header className="border-b border-gray-200 dark:border-gray-800">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-bold">Greymatter Journal</Link>
        <div className="flex items-center gap-6">
          <nav className="flex gap-4 text-sm">
            {categories.map((cat) => (
              <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`}>{cat.title}</Link>
            ))}
          </nav>
          <HeaderAuth />
        </div>
      </div>
    </header>
  );
}

```

**`src/components/HeaderAuth.tsx` (Client Component):**

```tsx
"use client";
import { Show, SignInButton, UserButton } from "@clerk/nextjs";

export function HeaderAuth() {
  return (
    <div className="flex items-center gap-2 border-l pl-4">
      <Show when="signed-out"><SignInButton mode="modal">Sign In</SignInButton></Show>
      <Show when="signed-in"><UserButton /></Show>
    </div>
  );
}

```

### Step 4: Configure Tailwind v4

Open `src/app/(main)/globals.css`:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";

@custom-variant dark (&:where(.dark, .dark *));

body {
  @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100;
}

```

### Step 5: Install Dependencies

```bash
npm install @sanity/client @sanity/image-url @portabletext/react next-sanity sanity groq @clerk/nextjs @tailwindcss/typography

```

### Checkpoint ✅

* [ ] **Architecture:** Route Group `(main)` separates CMS from Auth-heavy routes.
* [ ] **Split:** Header is a lean Server Component; `HeaderAuth` is an interactive Client Component.
* [ ] **Styling:** Tailwind v4 is fully functional.
* [ ] **Deployment:** Project is ready for `git push`.
