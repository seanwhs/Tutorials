# **✅ Part 6 — Building Our First Real Layout**

---

# GreyMatter Journal  
## Part 6 — Building Our First Real Layout: Route Groups, Application Shells, and Persistent UI

> **Goal of this lesson:** Create a clean application shell using route groups and understand why modern applications are built from persistent layouts rather than isolated pages.

---

### From Simple Pages to Application Shells

Our current structure is minimal. Real applications need a consistent shell.

---

### Step 1: Introduce Route Groups

Create:

```text
app/
├── layout.tsx
├── globals.css
└── (site)/
    └── page.tsx
```

Move your homepage into `app/(site)/page.tsx`.

Route groups (folders in parentheses) **do not affect URLs** — they are for organization.

---

### Step 2: Create the Site Layout

Create `app/(site)/layout.tsx`:

```tsx
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";

export default function SiteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Header />
      <main className="mx-auto max-w-6xl px-6 py-12">
        {children}
      </main>
      <Footer />
    </>
  );
}
```

---

### Step 3: Create Header and Footer

**Header** (`components/layout/Header.tsx`):

```tsx
import Link from "next/link";

export default function Header() {
  return (
    <header className="border-b border-gray-200">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-6">
        <Link href="/" className="text-3xl font-bold tracking-tight">
          GreyMatter Journal
        </Link>

        <nav className="flex gap-8 text-sm font-medium">
          <Link href="/" className="hover:text-gray-600 transition-colors">Home</Link>
          <Link href="/posts" className="hover:text-gray-600 transition-colors">Posts</Link>
          <Link href="/about" className="hover:text-gray-600 transition-colors">About</Link>
        </nav>
      </div>
    </header>
  );
}
```

**Footer** (`components/layout/Footer.tsx`):

```tsx
export default function Footer() {
  return (
    <footer className="border-t mt-24 py-12 bg-gray-50">
      <div className="max-w-6xl mx-auto px-6 text-center text-sm text-gray-500">
        © {new Date().getFullYear()} GreyMatter Journal
      </div>
    </footer>
  );
}
```

---

### Mental Model To Remember Forever

**Modern Application = Persistent Shell + Dynamic Content**

The layout is the **architecture**.  
The page is the **content**.

This pattern enables fast navigation, preserved state, and scalable UI.

---

### Up Next — Part 7: Introducing Sanity

We’ll add the content layer and understand why content and presentation should be separated.
