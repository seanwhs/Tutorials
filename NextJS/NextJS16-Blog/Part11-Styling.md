## Blog Tutorial - Part 11: Styling Polish — Dark Mode Toggle

## What we're doing

In Part 1, we set up Tailwind v4's CSS-first config in `globals.css`. By adding a `@custom-variant dark (&:where(.dark, .dark *));` rule, we enabled `dark:` utility classes to respond to a `.dark` class placed on the `<html>` element. In this part, we implement a persistent theme toggle that manages this class automatically. We also ensure our architecture remains clean by properly nesting providers and respecting the Server/Client boundary.

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

Update `src/app/layout.tsx`. To avoid hydration errors caused by `next-themes` injecting classes before React hydrates, we add `suppressHydrationWarning` to the `<html>` tag and use the `Inter` font class on the `<body>`.

*Note: Ensure you have deleted any redundant `layout.tsx` files (e.g., inside `src/app/(main)`) to avoid double-rendering your Header and Footer.*

```tsx
import { ClerkProvider } from "@clerk/nextjs";
import { ThemeProvider } from "@/components/ThemeProvider";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import "@/app/globals.css";
import { Inter } from "next/font/google";

const inter = Inter({ subsets: ["latin"] });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en" suppressHydrationWarning>
        <body className={inter.className}>
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

Create `src/components/ThemeToggle.tsx`. The `mounted` check is vital to ensure the button only renders after hydration, preventing mismatches between server and client themes.

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

To keep `Header.tsx` (a Server Component) clean, we delegate all interactive authentication and theme logic to a new Client Component: `HeaderAuth.tsx`.

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
// ... imports

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

Ensure your base styles handle the theme transition smoothly using `transition-colors`.

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";

@custom-variant dark (&:where(.dark, .dark *));

body {
  @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100 transition-colors;
}

```

## Checkpoint ✅

* [ ] Toggle switches between light/dark instantly
* [ ] Theme persists across page refreshes
* [ ] No hydration mismatch (Fixed via `suppressHydrationWarning`)
* [ ] Single layout (Fixed by removing redundant `layout.tsx`)
* [ ] Server/Client boundaries respected (Header vs. HeaderAuth)
