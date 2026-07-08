## Blog Tutorial - Part 11: Styling Polish — Dark Mode Toggle

## What we're doing
Back in Part 1 we set up Tailwind v4's CSS-first config in `globals.css`, including a `@custom-variant dark (&:where(.dark, .dark *));` rule that makes `dark:` utility classes respond to a `.dark` class placed on `<html>` (Tailwind v4's replacement for Tailwind v3's `darkMode: "class"` config option). Now we'll add a working toggle button that switches that class on `<html>` and persists the choice.

## Step 1: Install next-themes

This tiny, free, open-source library handles theme switching, localStorage persistence, and avoiding flash-of-wrong-theme, correctly with Next.js App Router (including Next.js 16):

```bash
npm install next-themes
```

## Step 2: Create a ThemeProvider wrapper

Create src/components/ThemeProvider.tsx:

```tsx
"use client";

import { ThemeProvider as NextThemesProvider } from "next-themes";
import type { ThemeProviderProps } from "next-themes/dist/types";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
```

## Step 3: Wire it into the root layout

Update src/app/layout.tsx — wrap the body contents with ThemeProvider, inside ClerkProvider:

```tsx
import { ThemeProvider } from "@/components/ThemeProvider";
```

```tsx
<ClerkProvider>
  <html lang="en" suppressHydrationWarning>
    <body className={inter.className}>
      <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
        <Header />
        {children}
      </ThemeProvider>
    </body>
  </html>
</ClerkProvider>
```

`attribute="class"` tells next-themes to toggle a `class="dark"` on `<html>`, which is exactly what our `@custom-variant dark` rule from Part 1's `globals.css` is watching for.

`suppressHydrationWarning` on `<html>` is required because next-themes sets the class attribute before React hydrates, which would otherwise cause a harmless warning.

## Step 4: Build a theme toggle button

Create src/components/ThemeToggle.tsx:

```tsx
"use client";

import { useEffect, useState } from "react";
import { useTheme } from "next-themes";

export default function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  if (!mounted) {
    return <div className="h-8 w-8" />;
  }

  return (
    <button
      onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
      aria-label="Toggle dark mode"
      className="flex h-8 w-8 items-center justify-center rounded-full border border-gray-300 text-sm dark:border-gray-700"
    >
      {theme === "dark" ? "☀️" : "🌙"}
    </button>
  );
}
```

The `mounted` check avoids a hydration mismatch since the actual theme isn't known until the client reads localStorage.

## Step 5: Add the toggle to the Header

Update src/components/Header.tsx — import and place it next to the sign in/out UI:

```tsx
import ThemeToggle from "./ThemeToggle";
```

```tsx
<div className="flex items-center gap-4">
  <nav className="flex gap-4 text-sm">
    {categories.map((cat) => (
      <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`} className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white">
        {cat.title}
      </Link>
    ))}
  </nav>
  <ThemeToggle />
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
```

## Step 6: Confirm globals.css already handles theme-aware body styling

No new CSS is needed here — back in Part 1 we already set up `src/app/globals.css` with:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";

@custom-variant dark (&:where(.dark, .dark *));

body {
  @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100;
}
```

If you're missing the `@custom-variant dark` line or the `body` rule, add them now — this is the Tailwind v4 equivalent of the old `darkMode: "class"` config option plus base body styling, and is required for the toggle button in this Part to visibly change anything.

## Step 7: Final polish touches (optional but recommended)

Add a simple footer. Create src/components/Footer.tsx:

```tsx
export default function Footer() {
  return (
    <footer className="mt-24 border-t border-gray-200 py-8 text-center text-sm text-gray-500 dark:border-gray-800 dark:text-gray-400">
      <p>
        Built with Next.js, Tailwind CSS, Sanity, and Clerk. &copy;{" "}
        {new Date().getFullYear()} My Blog.
      </p>
    </footer>
  );
}
```

Add it under {children} in layout.tsx, inside ThemeProvider:

```tsx
<ThemeProvider attribute="class" defaultTheme="system" enableSystem>
  <Header />
  {children}
  <Footer />
</ThemeProvider>
```

## Step 8: Test it

Run the dev server. Click the sun/moon toggle — the whole site should switch between light and dark styling instantly, including Studio-independent pages (post cards, post detail, category/author pages, comments). Refresh the page — your choice should persist (next-themes stores it in localStorage). Try "system" behavior by checking your OS dark mode setting.

## Checkpoint ✅
- [ ] Toggle switches between light/dark instantly
- [ ] Theme persists across page refreshes
- [ ] No flash-of-incorrect-theme on load
- [ ] All pages (home, post, category, author) look correct in both themes
- [ ] `globals.css` contains the `@custom-variant dark (&:where(.dark, .dark *));` line (Tailwind v4's CSS-first equivalent of `darkMode: "class"`)

Next: **Part 12 — Deployment: Shipping to Vercel for Free**
