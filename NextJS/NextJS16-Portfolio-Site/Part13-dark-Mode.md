# Part 13: Dark Mode, Navigation, Footer & UI Polish

Our components already use `dark:` Tailwind variants throughout. Now we add an actual dark mode toggle, improve the navbar (active links, mobile menu), and polish the footer with dynamic social links.

## Step 1: Install a Theme Library

We'll use `next-themes`, the standard, free, open-source solution for dark mode in Next.js — it handles system preference detection, persistence, and avoids flash-of-wrong-theme issues.

```bash
npm install next-themes
```

## Step 2: Create a Theme Provider

```tsx
// File: components/providers/ThemeProvider.tsx
"use client";

import { ThemeProvider as NextThemesProvider } from "next-themes";
import type { ReactNode } from "react";

export default function ThemeProvider({ children }: { children: ReactNode }) {
  return (
    <NextThemesProvider attribute="class" defaultTheme="system" enableSystem>
      {children}
    </NextThemesProvider>
  );
}
```

`attribute="class"` tells `next-themes` to toggle a `dark` class on `<html>`, which is exactly what Tailwind's `dark:` variant looks for by default.

## Step 3: Wire the Provider into the Root Layout

```tsx
// File: app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import ThemeProvider from "@/components/providers/ThemeProvider";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "My Portfolio",
  description:
    "Personal portfolio site built with Next.js, Tailwind CSS, and Sanity.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable} suppressHydrationWarning>
      <body className="antialiased font-sans">
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
```

`suppressHydrationWarning` on `<html>` is required with `next-themes` — it prevents a harmless warning because the theme class is set client-side after hydration.

## Step 4: Build a Theme Toggle Button

```tsx
// File: components/layout/ThemeToggle.tsx
"use client";

import { useEffect, useState } from "react";
import { useTheme } from "next-themes";

export default function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  // Avoid rendering theme-dependent UI until mounted client-side
  useEffect(() => setMounted(true), []);

  if (!mounted) {
    return <div className="h-9 w-9" />;
  }

  const isDark = theme === "dark";

  return (
    <button
      type="button"
      onClick={() => setTheme(isDark ? "light" : "dark")}
      aria-label="Toggle dark mode"
      className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-300 text-gray-600 transition-colors hover:border-brand-500 hover:text-brand-600 dark:border-gray-700 dark:text-gray-300 dark:hover:text-brand-500"
    >
      {isDark ? "🌙" : "☀️"}
    </button>
  );
}
```

## Step 5: Upgrade the Navbar (Active Links + Mobile Menu + Theme Toggle)

```tsx
// File: components/layout/Navbar.tsx
"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import Container from "@/components/ui/Container";
import ThemeToggle from "@/components/layout/ThemeToggle";

const links = [
  { href: "/", label: "Home" },
  { href: "/projects", label: "Projects" },
  { href: "/blog", label: "Blog" },
  { href: "/about", label: "About" },
  { href: "/contact", label: "Contact" },
];

export default function Navbar() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-40 border-b border-gray-200 bg-white/80 backdrop-blur dark:border-gray-800 dark:bg-gray-950/80">
      <Container>
        <nav className="flex h-16 items-center justify-between">
          <Link href="/" className="text-lg font-bold tracking-tight">
            Your Name
          </Link>

          {/* Desktop links */}
          <ul className="hidden items-center gap-6 text-sm font-medium sm:flex">
            {links.map((link) => {
              const active =
                link.href === "/"
                  ? pathname === "/"
                  : pathname.startsWith(link.href);
              return (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className={
                      active
                        ? "text-brand-600 dark:text-brand-500"
                        : "text-gray-600 transition-colors hover:text-brand-600 dark:text-gray-300 dark:hover:text-brand-500"
                    }
                  >
                    {link.label}
                  </Link>
                </li>
              );
            })}
          </ul>

          <div className="flex items-center gap-3">
            <ThemeToggle />
            {/* Mobile menu button */}
            <button
              type="button"
              onClick={() => setOpen((v) => !v)}
              aria-label="Toggle menu"
              className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-300 sm:hidden dark:border-gray-700"
            >
              {open ? "✕" : "☰"}
            </button>
          </div>
        </nav>

        {/* Mobile menu panel */}
        {open && (
          <ul className="flex flex-col gap-1 pb-4 text-sm font-medium sm:hidden">
            {links.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  onClick={() => setOpen(false)}
                  className="block rounded-lg px-3 py-2 text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-900"
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Container>
    </header>
  );
}
```

Note: this component now uses `usePathname()` and `useState`, so it must remain (or become) a Client Component — it already needs `"use client"` at the top.

## Step 6: Upgrade the Footer with Dynamic Social Links

```tsx
// File: components/layout/Footer.tsx
import Container from "@/components/ui/Container";
import { sanityFetch } from "@/sanity/fetch";
import { siteSettingsQuery } from "@/sanity/queries";
import type { SiteSettings } from "@/sanity/types";

export default async function Footer() {
  const settings = await sanityFetch<SiteSettings | null>({
    query: siteSettingsQuery,
    tags: ["siteSettings"],
  });
  const year = new Date().getFullYear();

  return (
    <footer className="mt-24 border-t border-gray-200 py-10 dark:border-gray-800">
      <Container>
        <div className="flex flex-col items-center gap-4 sm:flex-row sm:justify-between">
          <p className="text-sm text-gray-500 dark:text-gray-400">
            © {year} {settings?.title ?? "Your Name"}. Built with Next.js,
            Tailwind CSS &amp; Sanity.
          </p>
          {settings?.socialLinks && settings.socialLinks.length > 0 && (
            <ul className="flex gap-4">
              {settings.socialLinks.map((link) => (
                <li key={link.platform}>
                  <a
                    href={link.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm font-medium text-gray-600 hover:text-brand-600 dark:text-gray-300 dark:hover:text-brand-500"
                  >
                    {link.platform}
                  </a>
                </li>
              ))}
            </ul>
          )}
        </div>
      </Container>
    </footer>
  );
}
```

The `Footer` is now an `async` Server Component that fetches its own data — this is fine, and even encouraged, in the App Router: colocate data needs with the component that uses them rather than prop-drilling through layouts.

## Step 7: Test It

```bash
npm run dev
```

Visit http://localhost:3000:
- Click the sun/moon button in the navbar — the whole site should switch between light/dark themes instantly, and persist on reload.
- Resize your browser to mobile width — the desktop nav links should hide and the hamburger menu (☰) should appear and toggle a dropdown.
- Navigate between pages — the active page's nav link should be highlighted in the brand color.
- Scroll to the footer — your social links (added in Part 12) should appear alongside the copyright line.

## Checkpoint ✅

You now have:
- A working dark/light/system theme toggle via `next-themes`, persisted across reloads
- A responsive navbar with active-link highlighting and a mobile hamburger menu
- A footer that dynamically renders social links from Sanity

Commit your progress:

```bash
git add .
git commit -m "Add dark mode, responsive nav, and dynamic footer"
```

Next up: **Part 14: SEO, Metadata, Sitemap & OG Images**, where we make the site discoverable and share-friendly.
