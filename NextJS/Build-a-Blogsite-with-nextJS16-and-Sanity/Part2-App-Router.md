**✅ Part 2 — Understanding the App Router**

---

# GreyMatter Journal  
## Part 2 — Understanding the App Router: Why Modern Web Applications Are Not Collections of Pages

> **Goal of this lesson:** Master the **Next.js App Router**, understand why folders become routes, the power of `page.tsx` and `layout.tsx`, and why modern applications are built as **persistent UI trees** instead of isolated pages.

---

### The Biggest Mental Shift in Next.js

Traditional web development taught us to think in **static pages**:

```text
home.html
about.html
blog.html
contact.html
```

Clicking a link meant:
- Destroy the current page completely
- Load the entire new page from scratch

Modern applications (Gmail, Notion, GitHub, Linear, etc.) don’t work this way. They feel continuous.

**What stays:**
- Navigation bar
- Sidebar
- Footer
- Theme / user state

**What changes:**
- Only the main content area

This is the core idea behind the **App Router**.

---

### Traditional Pages vs Modern Applications

| Aspect                  | Traditional Pages               | Modern Applications (App Router)     |
|-------------------------|----------------------------------|--------------------------------------|
| Navigation              | Full page reload                 | Partial update                       |
| Layouts                 | Duplicated across files          | Persistent & nested                  |
| State                   | Lost on navigation               | Preserved                            |
| Performance             | Slower                           | Faster (less re-rendering)           |
| User Experience         | Disjointed                       | Smooth & app-like                    |

---

### The App Router Philosophy

The App Router changes the fundamental question from:

> “Which page should I show?”

to:

> “Which **parts** of the UI tree need to change?”

It uses the **file system** as the router — a concept called **file-system routing**.

---

### Folders = Routes

In the `app/` directory:

| File / Folder Structure                    | Resulting URL          |
|-------------------------------------------|------------------------|
| `app/page.tsx`                            | `/` (homepage)         |
| `app/about/page.tsx`                      | `/about`               |
| `app/posts/page.tsx`                      | `/posts`               |
| `app/posts/[slug]/page.tsx`               | `/posts/my-first-post` |
| `app/admin/(dashboard)/page.tsx`          | `/admin` (route group) |

**Route groups** (folders wrapped in parentheses) like `(site)` do **not** affect the URL — they are used for organization (as shown in **Appendix B**).

---

### Core Building Blocks

#### 1. `page.tsx` — The Content

Every route needs a `page.tsx` file to define what is rendered at that URL.

```tsx
// app/page.tsx
export default function HomePage() {
  return (
    <div>
      <h1 className="text-4xl font-bold">GreyMatter Journal</h1>
      <p>Exploring software engineering and systems thinking.</p>
    </div>
  );
}
```

#### 2. `layout.tsx` — The Persistent UI

Layouts wrap pages and persist across navigation.

```tsx
// app/layout.tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <nav>Persistent Navigation</nav>
        {children}        {/* ← Page content goes here */}
        <footer>Persistent Footer</footer>
      </body>
    </html>
  );
}
```

**Key insight:** The `children` prop represents the content of the current page (or nested layout).

---

### Nested Layouts — The Real Power

You can create layouts at any level:

```text
app/
├── layout.tsx                 ← Root Layout (applies everywhere)
├── page.tsx
├── posts/
│   ├── layout.tsx             ← Posts-specific layout (sidebar, etc.)
│   ├── page.tsx               ← /posts
│   └── [slug]/
│       └── page.tsx           ← /posts/my-post
```

**Visual Tree:**

```text
Root Layout
   ├── Navbar
   ├── Posts Layout          ← Only active under /posts
   │     ├── Sidebar
   │     └── {children}
   └── Footer
```

When navigating between posts, the **Root Layout** and **Posts Layout** stay mounted. Only the innermost page changes.

**Benefits:**
- Preserved component state
- Reduced JavaScript execution
- Better performance
- Smoother user experience

---

### The GreyMatter Journal Structure (Preview)

As defined in **Appendix B**, our final routing will look like this:

```text
app/
├── (site)/                    ← Route group (no URL impact)
│   ├── page.tsx               ← Homepage
│   ├── posts/
│   │   ├── page.tsx
│   │   └── [slug]/
│   │       └── page.tsx
│   └── about/
│       └── page.tsx
├── globals.css
└── layout.tsx                 ← Root layout
```

This organization keeps the project clean and scalable.

---

### Mental Model To Remember Forever

**Wrong mental model:**
```text
Next.js = Collection of Pages
```

**Correct mental model:**
```text
Next.js = UI Tree
      ↓
Root Layout
      ↓
Nested Layouts
      ↓
Page Component
      ↓
Child Components
```

Modern web applications are **composable user interfaces** where stable parts stay and dynamic parts update efficiently.

---

### Up Next — Part 3: Deep Dive into `app/layout.tsx`

We’ll examine the root layout in detail and learn:
- Why every Next.js app needs a root layout
- How to structure HTML document (`<html>`, `<body>`)
- What `React.ReactNode` really means
- How to add global styles, fonts, and providers
- Best practices for the GreyMatter Journal design
