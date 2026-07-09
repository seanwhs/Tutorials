# Appendix A: Full Codebase Reference (5 of 8)

This note covers: root layout, globals.css, metadata defaults, and the site route group's layout + homepage.

## app/layout.tsx (root)

```tsx
// File: app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import ThemeProvider from "@/components/providers/ThemeProvider";
import { defaultMetadata } from "@/lib/metadata";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = defaultMetadata;

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

## lib/metadata.ts

```ts
// File: lib/metadata.ts
import type { Metadata } from "next";

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

export const defaultMetadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "My Portfolio",
    template: "%s | My Portfolio",
  },
  description:
    "Personal portfolio site built with Next.js, Tailwind CSS, and Sanity.",
  openGraph: {
    type: "website",
    siteName: "My Portfolio",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
  },
};
```

## app/globals.css

```css
/* File: app/globals.css */
@import "tailwindcss";

@theme {
  --font-sans: var(--font-inter), ui-sans-serif, system-ui, sans-serif;
  --color-brand-50: #eff6ff;
  --color-brand-100: #dbeafe;
  --color-brand-500: #3b82f6;
  --color-brand-600: #2563eb;
  --color-brand-700: #1d4ed8;
}

html {
  scroll-behavior: smooth;
}

body {
  @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100;
}
```

## app/(site)/layout.tsx

```tsx
// File: app/(site)/layout.tsx
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";

export default function SiteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen flex-col">
      <Navbar />
      <div className="flex-1">{children}</div>
      <Footer />
    </div>
  );
}
```

## app/(site)/page.tsx (homepage)

```tsx
// File: app/(site)/page.tsx
import Hero from "@/components/home/Hero";
import FeaturedProjects from "@/components/home/FeaturedProjects";
import AboutSnippet from "@/components/home/AboutSnippet";
import { sanityFetch } from "@/sanity/fetch";
import {
  siteSettingsQuery,
  featuredProjectsQuery,
  authorQuery,
} from "@/sanity/queries";
import type { SiteSettings, Project, Author } from "@/sanity/types";

export default async function Home() {
  const [settings, projects, author] = await Promise.all([
    sanityFetch<SiteSettings | null>({
      query: siteSettingsQuery,
      tags: ["siteSettings"],
    }),
    sanityFetch<Project[]>({
      query: featuredProjectsQuery,
      tags: ["project"],
    }),
    sanityFetch<Author | null>({
      query: authorQuery,
      tags: ["author"],
    }),
  ]);

  return (
    <main>
      <Hero settings={settings} />
      <FeaturedProjects projects={projects} />
      <AboutSnippet author={author} />
    </main>
  );
}
```

Continue to **Appendix A (6 of 8)** for the projects, blog, about, contact pages, plus API routes, sitemap, robots.txt, and OG image routes.
