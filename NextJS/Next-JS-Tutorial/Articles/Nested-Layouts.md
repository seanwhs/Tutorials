# **Client Components & Nested Layouts in Next.js App Router**

### Client Components (`"use client"`)
By default, all components in the Next.js **App Router** are **Server Components**. This is excellent for performance — they run on the server, support direct data fetching, and have zero client-side JavaScript by default.

However, you need a **Client Component** when you require:
- State (`useState`, `useReducer`)
- Effects (`useEffect`)
- Event handlers (`onClick`, `onSubmit`)
- Browser APIs (`localStorage`, `window`, `document`)
- Hooks like `usePathname()`, `useSearchParams()`

Add `"use client";` at the very top of the file to opt into the client runtime.

```tsx
"use client";
```

> **Best Practice**: Keep `"use client"` as high as needed but as low as possible. Prefer Server Components for data fetching and layouts when you can.

---

### Nested Layouts — A Superpower

**Nested layouts** are one of the most powerful features of the App Router. A `layout.tsx` file in a folder applies to **all pages and subfolders** inside it.

Perfect for:
- Admin panels (`/admin`)
- Dashboards (`/dashboard`)
- Settings areas (`/settings`)
- Shared navigation, sidebars, headers

Example structure:
```
app/
├── admin/
│   ├── layout.tsx          ← Shared admin shell
│   ├── page.tsx            ← /admin
│   ├── users/
│   │   └── page.tsx        ← /admin/users
│   └── settings/
│       └── page.tsx
```

---

### Complete Collapsible Sidebar Example (Best Practice)

```tsx
// app/admin/layout.tsx
"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const STORAGE_KEY = "admin-sidebar-collapsed";

const navLinks = [
  { href: "/admin", label: "Dashboard", icon: "📊" },
  { href: "/admin/users", label: "Users", icon: "👥" },
  { href: "/admin/settings", label: "Settings", icon: "⚙️" },
];

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);
  const [mounted, setMounted] = useState(false);

  // Load preference on mount
  useEffect(() => {
    setMounted(true);
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved !== null) {
      setCollapsed(saved === "true");
    }
  }, []);

  // Persist preference
  useEffect(() => {
    if (mounted) {
      localStorage.setItem(STORAGE_KEY, String(collapsed));
    }
  }, [collapsed, mounted]);

  const toggleSidebar = () => setCollapsed((prev) => !prev);

  return (
    <div className="flex min-h-screen bg-gray-50">
      {/* Sidebar */}
      <aside
        className={`border-r bg-white transition-all duration-300 flex-shrink-0 ${
          collapsed ? "w-20" : "w-64"
        }`}
      >
        <div className="flex items-center justify-between border-b p-4">
          <span
            className={`font-bold text-xl tracking-tight ${
              collapsed ? "hidden" : "block"
            }`}
          >
            Admin
          </span>
          <button
            onClick={toggleSidebar}
            className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            {collapsed ? "→" : "←"}
          </button>
        </div>

        <nav className="p-3">
          <ul className="space-y-1">
            {navLinks.map((link) => {
              const isActive =
                link.href === "/admin"
                  ? pathname === "/admin"
                  : pathname.startsWith(link.href);

              return (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition-all ${
                      isActive
                        ? "bg-blue-600 text-white shadow-sm"
                        : "text-gray-700 hover:bg-gray-100"
                    } ${collapsed ? "justify-center" : ""}`}
                  >
                    <span>{link.icon}</span>
                    {!collapsed && <span>{link.label}</span>}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto">{children}</main>
    </div>
  );
}
```

---

### Sharing Layout State with Child Pages (Context)

Child pages often need to know the sidebar state (e.g., to adjust padding or show extra controls).

#### 1. Create Context (`app/admin/sidebar-context.tsx`)

```tsx
"use client";

import { createContext, useContext } from "react";

type SidebarContextValue = {
  collapsed: boolean;
  toggleSidebar: () => void;
};

const SidebarContext = createContext<SidebarContextValue | null>(null);

export function SidebarProvider({
  children,
  value,
}: {
  children: React.ReactNode;
  value: SidebarContextValue;
}) {
  return (
    <SidebarContext.Provider value={value}>
      {children}
    </SidebarContext.Provider>
  );
}

export function useSidebar() {
  const context = useContext(SidebarContext);
  if (!context) {
    throw new Error("useSidebar must be used within a SidebarProvider");
  }
  return context;
}
```

#### 2. Updated Layout with Provider

```tsx
// app/admin/layout.tsx
"use client";

import { useEffect, useState } from "react";
import { SidebarProvider } from "./sidebar-context";
// ... navLinks and other imports

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [collapsed, setCollapsed] = useState(false);
  const [mounted, setMounted] = useState(false);

  // ... same useEffect logic for localStorage

  const toggleSidebar = () => setCollapsed((prev) => !prev);

  return (
    <SidebarProvider value={{ collapsed, toggleSidebar }}>
      <div className="flex min-h-screen bg-gray-50">
        {/* Sidebar markup (same as above) */}
        <aside className={`...`}> {/* ... */} </aside>

        <main className="flex-1 overflow-auto p-6">{children}</main>
      </div>
    </SidebarProvider>
  );
}
```

#### 3. Using the Context in a Page

```tsx
// app/admin/users/page.tsx
"use client";

import { useSidebar } from "../sidebar-context";

export default function UsersPage() {
  const { collapsed, toggleSidebar } = useSidebar();

  return (
    <div className={`transition-all ${collapsed ? "pl-4" : "pl-8"}`}>
      <button
        onClick={toggleSidebar}
        className="mb-6 rounded-lg bg-white px-4 py-2 shadow hover:shadow-md"
      >
        Toggle Sidebar
      </button>
      <h1 className="text-3xl font-bold">Users Management</h1>
      <p>Sidebar is currently {collapsed ? "collapsed" : "expanded"}</p>
    </div>
  );
}
```

---

### `layout.tsx` vs `template.tsx`

| Feature              | `layout.tsx`                          | `template.tsx`                        |
|----------------------|---------------------------------------|---------------------------------------|
| Mounting behavior    | Persists across navigation            | Remounts on every route change        |
| State preservation   | Yes (great for sidebars, modals)      | No                                    |
| Use case             | Persistent UI (nav, sidebar)          | Animations, per-page entry effects    |
| Recommendation       | **Most admin/dashboard shells**       | Specific animation needs              |

---

### Why This Pattern Rocks

- **DRY** — Build your admin shell once.
- **Persistent UI** — Sidebar state survives navigation and refreshes.
- **Clean Architecture** — Shared state via Context without prop drilling.
- **Great UX** — Active link highlighting, collapsible navigation, responsive behavior.
- **Scalable** — Easily extend with more shared state (theme, user info, etc.).

This is the industry-standard pattern used in production Next.js dashboards (Supabase, Vercel, Linear-style interfaces).

**Pro Tips**:
- Consider moving complex sidebar logic into a custom hook (`useAdminSidebar`).
- For very large apps, explore **Zustand** or **Jotai** instead of Context.
- Add keyboard shortcuts (`[` / `]`) for toggling.
- Use `next-themes` for dark mode integration.

