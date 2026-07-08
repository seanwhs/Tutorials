# Part 3: Tailwind CSS Setup & Base Layout

`create-next-app` already installed and configured **Tailwind CSS v4** for us in Part 2. In this part we'll understand how that configuration works, add a font, and build the shared layout (container, navbar, footer) that every page will use.

## Step 1: Understand Tailwind v4's Setup

Tailwind CSS v4 simplified its configuration a lot compared to v3. Open `app/globals.css` — you should see something like:

```css
/* File: app/globals.css */
@import "tailwindcss";
```

That single line is all you need to pull in Tailwind's base styles, components, and utilities — there's no separate `tailwind.config.js` required for basic usage anymore (v4 auto-detects your content). We will still add a small config block directly in CSS for custom theme values, shown below.

## Step 2: Add Custom Theme Tokens

Let's define some reusable design tokens (colors, fonts) using Tailwind v4's CSS-based `@theme` directive. Replace `app/globals.css` with:

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

This gives us a `brand` color palette we can use anywhere as `bg-brand-600`, `text-brand-500`, etc., plus a custom font variable we'll wire up next. We've also enabled `dark:` variants on the body since we'll add dark mode support in Part 13.

## Step 3: Add a Google Font (Free, Self-Hosted via next/font)

Next.js has a built-in, free, privacy-friendly way to self-host Google Fonts with zero layout shift — no external requests to Google at runtime.

Update `app/layout.tsx`:

```tsx
// File: app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "My Portfolio",
  description: "Personal portfolio site built with Next.js, Tailwind CSS, and Sanity.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="antialiased font-sans">{children}</body>
    </html>
  );
}
```

This loads the Inter font, exposes it as a CSS variable, and our `@theme` block from Step 2 wires `--font-sans` to use it. The `font-sans` utility class now renders Inter everywhere.

## Step 4: Plan the Folder Structure

Let's set up folders now so future parts slot in cleanly:

```txt
my-portfolio/
├── app/
│   ├── (site)/            ← route group for public-facing pages
│   ├── about/
│   ├── blog/
│   │   └── [slug]/
│   ├── contact/
│   ├── projects/
│   │   └── [slug]/
│   ├── studio/             ← Sanity Studio embed (Part 5)
│   ├── layout.tsx
│   ├── page.tsx
│   └── globals.css
├── components/
│   ├── layout/
│   │   ├── Navbar.tsx
│   │   └── Footer.tsx
│   └── ui/
├── lib/
├── sanity/
├── public/
└── ...
```

Create these folders now (empty is fine, we'll fill them in as we go):

```bash
mkdir -p components/layout components/ui lib sanity
```

## Step 5: Build a Reusable Container Component

Create `components/ui/Container.tsx`:

```tsx
// File: components/ui/Container.tsx
import { ReactNode } from "react";

export default function Container({ children }: { children: ReactNode }) {
  return (
    <div className="mx-auto w-full max-w-5xl px-4 sm:px-6 lg:px-8">
      {children}
    </div>
  );
}
```

We'll use this on every page to keep consistent horizontal margins and a max width.

## Step 6: Build the Navbar

Create `components/layout/Navbar.tsx`:

```tsx
// File: components/layout/Navbar.tsx
import Link from "next/link";
import Container from "@/components/ui/Container";

const links = [
  { href: "/", label: "Home" },
  { href: "/projects", label: "Projects" },
  { href: "/blog", label: "Blog" },
  { href: "/about", label: "About" },
  { href: "/contact", label: "Contact" },
];

export default function Navbar() {
  return (
    <header className="sticky top-0 z-40 border-b border-gray-200 bg-white/80 backdrop-blur dark:border-gray-800 dark:bg-gray-950/80">
      <Container>
        <nav className="flex h-16 items-center justify-between">
          <Link href="/" className="text-lg font-bold tracking-tight">
            Your Name
          </Link>
          <ul className="flex items-center gap-6 text-sm font-medium">
            {links.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  className="text-gray-600 transition-colors hover:text-brand-600 dark:text-gray-300 dark:hover:text-brand-500"
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
      </Container>
    </header>
  );
}
```

## Step 7: Build the Footer

Create `components/layout/Footer.tsx`:

```tsx
// File: components/layout/Footer.tsx
import Container from "@/components/ui/Container";

export default function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="mt-24 border-t border-gray-200 py-10 dark:border-gray-800">
      <Container>
        <p className="text-center text-sm text-gray-500 dark:text-gray-400">
          © {year} Your Name. Built with Next.js, Tailwind CSS & Sanity.
        </p>
      </Container>
    </footer>
  );
}
```

## Step 8: Wire Navbar & Footer into the Root Layout

Update `app/layout.tsx`:

```tsx
// File: app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "My Portfolio",
  description: "Personal portfolio site built with Next.js, Tailwind CSS, and Sanity.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="flex min-h-screen flex-col antialiased font-sans">
        <Navbar />
        <div className="flex-1">{children}</div>
        <Footer />
      </body>
    </html>
  );
}
```

## Step 9: Update the Homepage to Test Everything

```tsx
// File: app/page.tsx
import Container from "@/components/ui/Container";

export default function Home() {
  return (
    <main className="py-20">
      <Container>
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          Hi, I'm{" "}
          <span className="text-brand-600 dark:text-brand-500">Your Name</span>.
        </h1>
        <p className="mt-4 max-w-xl text-lg text-gray-600 dark:text-gray-300">
          I build things for the web. This is my portfolio — placeholder content
          for now, wired up to Sanity in the next parts.
        </p>
      </Container>
    </main>
  );
}
```

Save everything and check http://localhost:3000 — you should see a sticky navbar with links, your hero text styled with the brand color, and a footer at the bottom with the current year.

## Checkpoint ✅

You now have:
- Tailwind v4 configured with a custom `brand` color palette and the Inter font
- A reusable `Container` component
- A shared `Navbar` and `Footer` wired into the root layout
- A working, styled placeholder homepage

Commit your progress:

```bash
git add .
git commit -m "Add Tailwind theme, fonts, navbar, footer, container"
```

Next up: **Part 4: Creating a Free Sanity Project & Core Concepts**, where we'll sign up for Sanity and understand datasets, documents, and the Studio.

---

Ready for Part 4?
