# **✅ Part 15 — Layouts, Navigation, and Persistent UI**

---

# GreyMatter Journal  
## Part 15 — Layouts, Navigation, and the Architecture of Persistent User Interfaces

> **Goal of this lesson:** Implement a clean navigation system and deeply understand why modern web applications are built as **persistent UI trees**.

---

### From Static Pages to Persistent Applications

Our blog now has real content, but it still lacks the consistent shell that makes great websites feel cohesive.

---

### Create the Navigation

Create `components/layout/Navbar.tsx`:

```tsx
import Link from "next/link";

export default function Navbar() {
  return (
    <nav className="border-b bg-white sticky top-0 z-50">
      <div className="max-w-6xl mx-auto px-6 py-5 flex items-center justify-between">
        <Link href="/" className="text-2xl font-bold tracking-tight">
          GreyMatter Journal
        </Link>

        <div className="flex items-center gap-8 text-sm font-medium">
          <Link href="/" className="hover:text-gray-600 transition-colors">
            Home
          </Link>
          <Link href="/posts" className="hover:text-gray-600 transition-colors">
            Posts
          </Link>
          <Link href="/about" className="hover:text-gray-600 transition-colors">
            About
          </Link>
        </div>
      </div>
    </nav>
  );
}
```

---

### Create the Footer

Create `components/layout/Footer.tsx`:

```tsx
export default function Footer() {
  return (
    <footer className="border-t mt-24 py-12 bg-gray-50">
      <div className="max-w-6xl mx-auto px-6 text-center text-sm text-gray-500">
        © {new Date().getFullYear()} GreyMatter Journal. 
        Built with Next.js 16 and Sanity.
      </div>
    </footer>
  );
}
```

---

### Update Root Layout (`app/layout.tsx`)

```tsx
import type { Metadata } from "next";
import "./globals.css";
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";

export const metadata: Metadata = {
  title: "GreyMatter Journal",
  description: "Exploring software engineering, systems thinking, and architecture.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-white text-gray-900 antialiased">
        <Navbar />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
```

---

### Understanding Persistent UI

When navigating between pages:

- **Root Layout** stays mounted
- **Navbar** and **Footer** remain
- Only `children` (the current page) changes

This is the power of the App Router and layouts.

**Benefits:**
- Preserved state (search input, theme, etc.)
- Faster navigation
- Smoother user experience
- Reduced re-rendering

---

### Create Supporting Pages

- `app/about/page.tsx`
- `app/posts/page.tsx` (list view)

These pages benefit from the shared layout automatically.

---

### Mental Model To Remember Forever

**Old web:**
```text
Separate Pages
```

**Modern web:**
```text
Persistent Shell + Dynamic Content
```

Or more deeply:

```text
Application
   = Tree of Trees
   (Layout Tree + Route Tree + Component Tree)
```

Next.js applications are **composable trees** — one of the most powerful ideas in modern frontend architecture.

---

### Up Next — Part 16: Search & Filtering

We’ll implement search and category filtering, exploring GROQ queries, URL parameters, and server-side data operations.
