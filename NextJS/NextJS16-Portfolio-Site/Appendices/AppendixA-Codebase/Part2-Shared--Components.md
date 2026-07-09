# Appendix A: Full Codebase Reference (2 of 8)

This note covers shared components: layout (Navbar, Footer, ThemeToggle), theme provider.

## components/providers/ThemeProvider.tsx

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

## components/layout/ThemeToggle.tsx

```tsx
// File: components/layout/ThemeToggle.tsx
"use client";

import { useEffect, useState } from "react";
import { useTheme } from "next-themes";

export default function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

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

## components/layout/Navbar.tsx

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

## components/layout/Footer.tsx

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
            (c) {year} {settings?.title ?? "Your Name"}. Built with Next.js,
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

Continue to **Appendix A (3 of 8)** for the remaining UI components (Container, ProjectCard, BlogCard, SkillBadge, RichText, ExperienceItem).

---

Want me to continue to Appendix A (3 of 8)?
