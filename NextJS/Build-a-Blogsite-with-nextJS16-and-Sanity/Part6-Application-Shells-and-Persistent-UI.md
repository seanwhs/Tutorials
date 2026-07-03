# **✅ Part 6 — Building Our First Real Layout**

---

# GreyMatter Journal  
## Part 6 — Building Our First Real Layout: Application Shells and Persistent UI

> **Goal of this lesson:** Implement a clean, persistent application shell for GreyMatter Journal and understand why modern web apps are built around **layouts** rather than individual pages.

---

### The Shift from Pages to Shells

Our current homepage is just raw content. But real applications have a consistent **Application Shell** that stays visible across all pages.

Examples from daily tools:
- **YouTube**: Header + Sidebar stay while videos change
- **GitHub**: Top nav + repo header persist during navigation
- **Notion**: Sidebar workspace stays while pages change

This persistent structure is what makes apps feel fast and cohesive.

---

### Designing GreyMatter Journal’s Shell

Following the minimal, readable philosophy from **Appendix B**, our shell will include:

- Clean Header with branding and navigation
- Main content area
- Simple Footer

---

### Update the Root Layout

Open `app/layout.tsx` and replace its content with:

```tsx
import type { Metadata } from "next";
import "./globals.css";
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";

export const metadata: Metadata = {
  title: "GreyMatter Journal",
  description: "Exploring software engineering, systems thinking, and architecture.",
  icons: {
    icon: "/favicon.ico",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-white text-gray-900 antialiased">
        <Header />
        
        <main className="min-h-[calc(100vh-200px)]">
          {children}
        </main>

        <Footer />
      </body>
    </html>
  );
}
```

---

### Create the Header Component

Create the folder structure:

```bash
mkdir -p components/layout
```

Then create `components/layout/Header.tsx`:

```tsx
import Link from "next/link";

export default function Header() {
  return (
    <header className="border-b border-gray-200 bg-white">
      <div className="mx-auto max-w-6xl px-6 py-6 flex items-center justify-between">
        <Link href="/" className="text-3xl font-bold tracking-tight">
          GreyMatter Journal
        </Link>

        <nav className="flex items-center gap-8 text-sm font-medium">
          <Link href="/" className="hover:text-gray-600 transition-colors">
            Home
          </Link>
          <Link href="/posts" className="hover:text-gray-600 transition-colors">
            Posts
          </Link>
          <Link href="/about" className="hover:text-gray-600 transition-colors">
            About
          </Link>
        </nav>
      </div>
    </header>
  );
}
```

---

### Create the Footer Component

Create `components/layout/Footer.tsx`:

```tsx
export default function Footer() {
  return (
    <footer className="border-t border-gray-200 mt-20">
      <div className="mx-auto max-w-6xl px-6 py-12 text-center text-sm text-gray-500">
        © {new Date().getFullYear()} GreyMatter Journal. 
        Built with Next.js and Sanity.
      </div>
    </footer>
  );
}
```

---

### Update the Homepage

Update `app/page.tsx`:

```tsx
export default function HomePage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16 text-center">
      <h1 className="text-6xl font-bold tracking-tight">
        GreyMatter Journal
      </h1>
      <p className="mt-6 text-xl text-gray-600">
        Thoughts on software engineering, 
        systems architecture, and building lasting digital systems.
      </p>
    </div>
  );
}
```

---

### Test Navigation

1. Run `npm run dev`
2. Visit `http://localhost:3000`
3. Create `app/about/page.tsx` with simple content
4. Navigate between `/` and `/about`

Notice how the **Header** and **Footer** remain stable. This is the power of layouts.

---

### Why `Link` Instead of `<a>`?

| Feature               | `<a href="">`               | `next/link`                     |
|-----------------------|-----------------------------|---------------------------------|
| Navigation            | Full page reload            | Client-side (fast)              |
| Layout Behavior       | Destroys everything         | Preserves layout                |
| Performance           | Slower                      | Faster + prefetching            |

---

### Mental Model To Remember Forever

**Old way:**
```text
Website = Collection of Pages
```

**New way:**
```text
Application = Persistent Shell + Dynamic Content
```

Or more precisely:

```text
RootLayout
   ├── Header
   ├── Navigation
   ├── {children} ← changes per route
   └── Footer
```

**Layouts are the architecture. Pages are the content.**

This pattern scales beautifully as we add posts, authors, categories, and more — exactly as planned in **Appendix B**.

---

### Up Next — Part 7: Introducing Sanity

We’ll bring in the **content layer**:

- What a Headless CMS really is
- Why Next.js shouldn’t store blog posts
- Initializing Sanity Studio
- Understanding the Content Lake
- Separating concerns between content and presentation

This is where GreyMatter Journal becomes a true modern publication system.
