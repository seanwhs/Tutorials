## Part 4: Styling & UI Components

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Use Tailwind CSS v4 and shadcn/ui to build a responsive, professional dashboard shell for Orbit.

---

### 1. Concept Explanation

Next.js 16 scaffolds Tailwind v4 by default, which is CSS-first: there is no `tailwind.config.ts`, theme tokens are defined directly in CSS via `@theme`, and plugins are loaded via `@plugin` in the CSS file itself. This is a deliberate simplification versus v3 — fewer moving parts, no JS config to keep in sync with the CSS.

shadcn/ui is not a component library you install as a dependency — it's a CLI that *copies* component source into your own `components/ui` folder. This matters architecturally: you own and can modify every component's code directly, there's no black-box abstraction layer, and it composes naturally with our `lib/` ownership principle from Part 1 — UI primitives live in `components/ui`, domain-specific composites (e.g. a `ProjectCard`) live in `components/dashboard`.

The dashboard shell we build here is intentionally content-agnostic — it renders whatever Prisma/Sanity data Part 5 onwards will provide, but the shell itself (sidebar, header, role-aware nav) is pure UI, wired to Clerk only for showing the current user and role.

---

### 2. Implementation

#### 2.1 Verify Tailwind v4 CSS-first setup

```css
/* src/app/globals.css */
@import "tailwindcss";

@theme {
  --color-brand-50: oklch(0.98 0.01 250);
  --color-brand-500: oklch(0.6 0.18 250);
  --color-brand-900: oklch(0.3 0.12 250);
  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
}

@layer base {
  body {
    @apply bg-background text-foreground;
  }
}
```

If your `globals.css` still has `@tailwind base; @tailwind components; @tailwind utilities;`, you're on the v3 template — replace with the single `@import "tailwindcss";` line above.

#### 2.2 Install shadcn/ui

```bash
pnpm dlx shadcn@latest init
```

Accept defaults (Next.js preset, CSS variables enabled, base color "Neutral" or your preference). This writes `components.json` and confirms the `@/lib/utils` cn() helper.

```bash
pnpm dlx shadcn@latest add button card avatar dropdown-menu separator sheet skeleton badge input label textarea select
```

This populates `src/components/ui/*.tsx` with the requested primitives, each fully editable.

#### 2.3 The cn() helper (confirm it exists)

```ts
// src/lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

(`shadcn init` installs `clsx` and `tailwind-merge` and generates this file automatically if missing.)

#### 2.4 Dashboard shell layout

```tsx
// src/app/(dashboard)/layout.tsx
import { UserButton } from "@clerk/nextjs";
import { getUserRole } from "@/lib/clerk/roles";
import { Sidebar } from "@/components/dashboard/sidebar";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const role = await getUserRole();

  return (
    <div className="flex min-h-screen">
      <Sidebar role={role} />
      <div className="flex-1">
        <header className="flex h-14 items-center justify-between border-b px-6">
          <span className="text-sm font-medium text-muted-foreground">
            Signed in as {role}
          </span>
          <UserButton afterSignOutUrl="/" />
        </header>
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
```

#### 2.5 Role-aware sidebar

```tsx
// src/components/dashboard/sidebar.tsx
import Link from "next/link";
import { LayoutDashboard, FolderKanban, Settings, BookOpen } from "lucide-react";
import type { OrbitRole } from "@/lib/clerk/roles";
import { cn } from "@/lib/utils";

const NAV_ITEMS: { href: string; label: string; icon: React.ElementType; roles: OrbitRole[] }[] = [
  { href: "/dashboard", label: "Overview", icon: LayoutDashboard, roles: ["ADMIN", "MEMBER", "CLIENT"] },
  { href: "/dashboard/projects", label: "Projects", icon: FolderKanban, roles: ["ADMIN", "MEMBER", "CLIENT"] },
  { href: "/dashboard/articles", label: "Knowledge Base", icon: BookOpen, roles: ["ADMIN", "MEMBER", "CLIENT"] },
  { href: "/dashboard/settings", label: "Settings", icon: Settings, roles: ["ADMIN", "MEMBER"] },
];

export function Sidebar({ role }: { role: OrbitRole }) {
  const items = NAV_ITEMS.filter((item) => item.roles.includes(role));

  return (
    <nav className="w-60 border-r p-4">
      <div className="mb-6 px-2 text-lg font-bold">Orbit</div>
      <ul className="space-y-1">
        {items.map(({ href, label, icon: Icon }) => (
          <li key={href}>
            <Link
              href={href}
              className={cn(
                "flex items-center gap-2 rounded-md px-3 py-2 text-sm font-medium",
                "hover:bg-muted transition-colors"
              )}
            >
              <Icon className="h-4 w-4" />
              {label}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
```

```bash
pnpm add lucide-react
```

#### 2.6 Project card composite (uses shadcn Card + Badge)

```tsx
// src/components/dashboard/project-card.tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

const STATUS_VARIANT: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
  REQUESTED: "outline",
  ACTIVE: "default",
  ON_HOLD: "secondary",
  COMPLETED: "secondary",
  CANCELLED: "destructive",
};

export function ProjectCard({
  name,
  status,
  taskCount,
}: {
  name: string;
  status: string;
  taskCount: number;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">{name}</CardTitle>
        <Badge variant={STATUS_VARIANT[status] ?? "outline"}>{status}</Badge>
      </CardHeader>
      <CardContent>
        <p className="text-sm text-muted-foreground">{taskCount} tasks</p>
      </CardContent>
    </Card>
  );
}
```

#### 2.7 Skeleton loading state (used with Suspense from Part 7 onward)

```tsx
// src/components/dashboard/project-card-skeleton.tsx
import { Skeleton } from "@/components/ui/skeleton";

export function ProjectCardSkeleton() {
  return (
    <div className="rounded-lg border p-4 space-y-3">
      <Skeleton className="h-5 w-2/3" />
      <Skeleton className="h-4 w-1/3" />
    </div>
  );
}
```

#### 2.8 Wiring a placeholder dashboard page

```tsx
// src/app/(dashboard)/dashboard/page.tsx
import { ProjectCard } from "@/components/dashboard/project-card";

// Placeholder data — Part 5 replaces this with a real db.project.findMany() call
const placeholderProjects = [
  { id: "1", name: "Website Redesign", status: "ACTIVE", taskCount: 4 },
  { id: "2", name: "SEO Audit", status: "REQUESTED", taskCount: 0 },
];

export default function DashboardOverviewPage() {
  return (
    <div>
      <h1 className="mb-4 text-2xl font-bold">Projects</h1>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {placeholderProjects.map((p) => (
          <ProjectCard key={p.id} name={p.name} status={p.status} taskCount={p.taskCount} />
        ))}
      </div>
    </div>
  );
}
```

---

### 3. Checkpoint

- ✅ `globals.css` uses the single `@import "tailwindcss";` v4 syntax.
- ✅ `components.json` exists; `src/components/ui/` populated with button, card, avatar, dropdown-menu, separator, sheet, skeleton, badge, input, label, textarea, select.
- ✅ `/dashboard` renders the sidebar (filtered by role), header with `UserButton`, and placeholder project cards.
- ✅ Signing in as a `CLIENT`-role user hides the "Settings" nav item; signing in as `ADMIN` shows it.

---

### 4. Troubleshooting

- **shadcn CLI complains about missing `tsconfig.json` paths** — confirm `@/*` alias from Part 1's `create-next-app --import-alias "@/*"` is intact in `tsconfig.json`'s `compilerOptions.paths`.
- **Tailwind classes not applying to shadcn components** — ensure `globals.css` is imported once in the root `layout.tsx` (Part 2, section 2.3) and not duplicated in nested layouts.
- **`@theme` custom colors not available as `bg-brand-500` etc.** — Tailwind v4 requires the CSS variable name pattern `--color-<name>`; double-check the dash placement matches exactly.

---

Next: **"Ecosystem Tutorial - Part 5: Server-Side Orchestration"**

---

Say "next" for Part 5 — this is the architectural centerpiece of the whole series.
