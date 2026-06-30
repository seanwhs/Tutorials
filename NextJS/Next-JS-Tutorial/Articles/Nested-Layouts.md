# Nested layouts are powerful

One of the nicest features in the Next.js App Router is nested layouts. A nested layout is simply a `layout.tsx` file inside a folder, and it applies only to the pages inside that folder. This makes it perfect for parts of your app like `/admin`, `/dashboard`, or `/settings`, where you want a shared sidebar, header, or navigation bar. [nextjs]

For example, if you create `app/admin/layout.tsx`, every page inside `app/admin` will automatically use that same layout. That means you can build the admin shell once and reuse it across all admin pages instead of repeating the same UI everywhere. [nextjs]

## A collapsible sidebar layout

A very practical use case is an admin sidebar that can collapse and expand. You can make the layout a client component so it can use browser-only features like `useState`, `useEffect`, and `usePathname()`. That lets you add interactivity while still keeping the layout shared across all child pages. [nextjs]

```tsx
// app/admin/layout.tsx
"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const STORAGE_KEY = "admin-sidebar-collapsed";

const navLinks = [
  { href: "/admin", label: "Dashboard" },
  { href: "/admin/users", label: "Users" },
  { href: "/admin/settings", label: "Settings" },
];

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const saved = window.localStorage.getItem(STORAGE_KEY);
    if (saved !== null) {
      setCollapsed(saved === "true");
    }
  }, []);

  useEffect(() => {
    if (!mounted) return;
    window.localStorage.setItem(STORAGE_KEY, String(collapsed));
  }, [collapsed, mounted]);

  return (
    <div className="flex min-h-screen bg-gray-50">
      <aside
        className={`border-r bg-white transition-all duration-300 ${
          collapsed ? "w-20" : "w-64"
        }`}
      >
        <div className="flex items-center justify-between border-b p-4">
          <span className={`font-semibold ${collapsed ? "hidden" : "block"}`}>
            Admin
          </span>

          <button
            type="button"
            onClick={() => setCollapsed((prev) => !prev)}
            className="rounded px-3 py-2 text-sm hover:bg-gray-100"
          >
            {collapsed ? "→" : "←"}
          </button>
        </div>

        <nav className="p-3">
          <ul className="space-y-2">
            {navLinks.map((link) => {
              const isActive =
                link.href === "/admin"
                  ? pathname === "/admin"
                  : pathname.startsWith(link.href);

              return (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className={`block rounded px-3 py-2 text-sm transition-colors ${
                      isActive
                        ? "bg-blue-600 text-white"
                        : "text-gray-700 hover:bg-gray-100"
                    } ${collapsed ? "text-center" : ""}`}
                  >
                    {collapsed ? link.label.slice(0, 1) : link.label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </aside>

      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}
```

## Why `localStorage` works well here

The sidebar state is stored in `localStorage`, so when the user refreshes the page, the layout remembers whether the sidebar was open or collapsed. That makes the interface feel more polished and less frustrating to use. [nextjs]

The key detail is that `localStorage` is only accessed inside `useEffect`, which runs in the browser after the component mounts. That avoids issues during server rendering, where browser APIs like `window` do not exist. [nextjs]

## Highlighting the active link

`usePathname()` is helpful because it tells you the current route. You can compare that route against each sidebar link and highlight the one that matches. This gives users a clear visual cue about where they are in the app. [nextjs]

```tsx
const isActive = (href: string, pathname: string) => {
  if (href === "/admin") return pathname === "/admin";
  return pathname.startsWith(href);
};
```

That small helper is useful because it prevents the wrong links from appearing active, especially when one route is nested inside another. [nextjs]

## Sharing layout state with child pages

Sometimes child pages need access to layout state too. For example, a page might want to know whether the sidebar is collapsed so it can adjust spacing or trigger its own behavior. In that case, React context is a clean way to share the data from the layout down to the pages inside it. [nextjs]

```tsx
// app/admin/sidebar-context.tsx
"use client";

import { createContext, useContext } from "react";

type SidebarContextValue = {
  collapsed: boolean;
  toggleSidebar: () => void;
};

const SidebarContext = createContext<SidebarContextValue | null>(null);

export function SidebarProvider({
  value,
  children,
}: {
  value: SidebarContextValue;
  children: React.ReactNode;
}) {
  return (
    <SidebarContext.Provider value={value}>
      {children}
    </SidebarContext.Provider>
  );
}

export function useSidebar() {
  const ctx = useContext(SidebarContext);
  if (!ctx) throw new Error("useSidebar must be used inside SidebarProvider");
  return ctx;
}
```

Then you wrap the layout with the provider:

```tsx
// app/admin/layout.tsx
"use client";

import { useEffect, useState } from "react";
import { SidebarProvider } from "./sidebar-context";

const STORAGE_KEY = "admin-sidebar-collapsed";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [collapsed, setCollapsed] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const saved = window.localStorage.getItem(STORAGE_KEY);
    if (saved !== null) setCollapsed(saved === "true");
  }, []);

  useEffect(() => {
    if (mounted) {
      window.localStorage.setItem(STORAGE_KEY, String(collapsed));
    }
  }, [collapsed, mounted]);

  return (
    <SidebarProvider
      value={{
        collapsed,
        toggleSidebar: () => setCollapsed((prev) => !prev),
      }}
    >
      <div className="min-h-screen">{children}</div>
    </SidebarProvider>
  );
}
```

And a child page can consume it like this:

```tsx
// app/admin/users/page.tsx
"use client";

import { useSidebar } from "../sidebar-context";

export default function UsersPage() {
  const { collapsed, toggleSidebar } = useSidebar();

  return (
    <section>
      <button onClick={toggleSidebar}>Toggle sidebar</button>
      <p>The sidebar is {collapsed ? "collapsed" : "expanded"}.</p>
    </section>
  );
}
```

## Layouts vs templates

It helps to remember the difference between `layout.tsx` and `template.tsx`. A layout stays mounted as you navigate, so it preserves state and shared UI. A template remounts on every navigation, which is useful when you want a fresh render for animations, loaders, or similar effects. [nextjs]

For most app shells, dashboards, and admin areas, `layout.tsx` is the better choice. If the UI should remember something, use a layout. If it should restart every time, use a template. [nextjs]

## Why this pattern is worth using

This approach keeps your app organized, your sidebar reusable, and your navigation consistent. It also gives you a clean place to manage shared state without pushing everything into every page. For most real-world Next.js apps, especially dashboards and admin panels, this is one of the most useful patterns you can learn. [nextjs]

