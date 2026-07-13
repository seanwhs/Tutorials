## Blog Tutorial - Part 11: Styling Polish — Dark Mode Toggle

## What we're doing

In Part 1, we set up Tailwind v4's CSS-first config in `globals.css`, including a `@custom-variant dark (&:where(.dark, .dark *));` rule. This makes `dark:` utility classes respond to a `.dark` class placed on `<html>`. Now, we will implement a persistent theme toggle that handles switching this class automatically.

## Step 1: Install next-themes

This library handles theme switching, `localStorage` persistence, and preventing the "flash-of-wrong-theme" in the Next.js App Router.

```bash
npm install next-themes

```

## Step 2: Create a ThemeProvider wrapper

Create `src/components/ThemeProvider.tsx`:

```tsx
"use client";

import { ThemeProvider as NextThemesProvider } from "next-themes";
import type { ThemeProviderProps } from "next-themes";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}

```

## Step 3: Wire it into the root layout

Update `src/app/layout.tsx` to wrap your content. We add `suppressHydrationWarning` to the `<html>` tag, as `next-themes` modifies the class attribute before hydration, which would otherwise trigger a harmless warning.

```tsx
import { ThemeProvider } from "@/components/ThemeProvider";
import { ClerkProvider } from "@clerk/nextjs";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en" suppressHydrationWarning>
        <body>
          <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
            <Header />
            <main>{children}</main>
            <Footer />
          </ThemeProvider>
        </body>
      </html>
    </ClerkProvider>
  );
}

```

## Step 4: Build a theme toggle button

Create `src/components/ThemeToggle.tsx`. Using `useSyncExternalStore` or a `mounted` check ensures the component only renders after hydration to prevent mismatches.

```tsx
"use client";

import { useTheme } from "next-themes";
import { useEffect, useState } from "react";

export default function ThemeToggle() {
  const { setTheme, resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  if (!mounted) return <div className="h-8 w-8" />;

  return (
    <button
      onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
      aria-label="Toggle dark mode"
      className="flex h-8 w-8 items-center justify-center rounded-full border border-gray-300 text-sm dark:border-gray-700"
    >
      {resolvedTheme === "dark" ? "☀️" : "🌙"}
    </button>
  );
}

```

## Step 5: Orchestrate via HeaderAuth

To keep your `Header.tsx` (Server Component) clean, we delegate all interactive elements (Auth + Theme) to `HeaderAuth.tsx` (Client Component).

**`src/components/HeaderAuth.tsx`**

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

```tsx
import Link from "next/link";
import { HeaderAuth } from "./HeaderAuth";
// ... (imports remain the same)

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

## Step 6: Verify `globals.css`

Ensure your base styles handle the theme transition:

```css
@custom-variant dark (&:where(.dark, .dark *));

body {
  @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100 transition-colors;
}

```

## Checkpoint ✅

* [ ] Toggle switches between light/dark instantly
* [ ] Theme persists across page refreshes
* [ ] No hydration mismatch
* [ ] Server/Client boundaries respected (Header vs. HeaderAuth)
