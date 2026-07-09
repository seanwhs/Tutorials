# Part 3 Code Appendix — Full Snippets

Companion code for **EntNext16 - Part 3: Component Composition**.

---

## Slot Pattern

### `components/ui/interactive-card.tsx` (Client — layout/interactivity only)

```tsx
"use client";

import { useState, type ReactNode } from "react";

interface InteractiveCardProps {
  header: ReactNode;
  children: ReactNode;
  defaultExpanded?: boolean;
}

export function InteractiveCard({
  header,
  children,
  defaultExpanded = false,
}: InteractiveCardProps) {
  const [isExpanded, setIsExpanded] = useState(defaultExpanded);

  return (
    <div className="rounded-lg border border-gray-200 p-4">
      <div className="flex items-center justify-between">
        <div>{header}</div>
        <button
          onClick={() => setIsExpanded((v) => !v)}
          aria-expanded={isExpanded}
        >
          {isExpanded ? "Collapse" : "Expand"}
        </button>
      </div>
      {isExpanded && <div className="mt-3">{children}</div>}
    </div>
  );
}
```

### `components/project-stats.tsx` (Server Component — heavy data, zero client cost)

```tsx
import { projectRepository } from "@/lib/repositories/project-repository";

interface ProjectStatsProps {
  projectId: string;
}

export async function ProjectStats({ projectId }: ProjectStatsProps) {
  const project = await projectRepository.getById(projectId);
  if (!project) return null;

  return (
    <dl className="grid grid-cols-2 gap-2 text-sm">
      <dt className="text-gray-500">Status</dt>
      <dd>{project.status}</dd>
      <dt className="text-gray-500">Last updated</dt>
      <dd>{new Date(project.updatedAt).toLocaleDateString()}</dd>
    </dl>
  );
}
```

### `app/dashboard/projects/[id]/page.tsx` (Server Component parent — composes both)

```tsx
import { InteractiveCard } from "@/components/ui/interactive-card";
import { ProjectStats } from "@/components/project-stats";
import { projectRepository } from "@/lib/repositories/project-repository";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function ProjectDetailPage({ params }: PageProps) {
  const { id } = await params;
  const project = await projectRepository.getById(id);
  if (!project) return <p>Project not found.</p>;

  return (
    <InteractiveCard header={<h2 className="font-semibold">{project.name}</h2>}>
      {/* Server Component passed as children — stays server-rendered */}
      <ProjectStats projectId={id} />
    </InteractiveCard>
  );
}
```

`ProjectStats` runs its `await projectRepository.getById(...)` on the server. `InteractiveCard` (client) never imports or re-executes it — React resolves the server tree once and passes the finished element down.

---

## Compound Components

### `components/ui/tabs.tsx` (Client — shared context shell)

```tsx
"use client";

import {
  createContext,
  useContext,
  useState,
  type ComponentPropsWithoutRef,
  type ReactNode,
} from "react";

interface TabsContextValue {
  activeId: string;
  setActiveId: (id: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function useTabsContext(): TabsContextValue {
  const ctx = useContext(TabsContext);
  if (!ctx) {
    throw new Error("Tabs.* components must be rendered inside <Tabs>.");
  }
  return ctx;
}

interface TabsProps {
  defaultActiveId: string;
  children: ReactNode;
}

export function Tabs({ defaultActiveId, children }: TabsProps) {
  const [activeId, setActiveId] = useState(defaultActiveId);
  return (
    <TabsContext.Provider value={{ activeId, setActiveId }}>
      <div className="w-full">{children}</div>
    </TabsContext.Provider>
  );
}

interface TabsListProps extends ComponentPropsWithoutRef<"div"> {}

Tabs.List = function TabsList({ children, ...rest }: TabsListProps) {
  return (
    <div role="tablist" className="flex gap-2 border-b" {...rest}>
      {children}
    </div>
  );
};

interface TabsTriggerProps extends ComponentPropsWithoutRef<"button"> {
  id: string;
}

Tabs.Trigger = function TabsTrigger({ id, children, ...rest }: TabsTriggerProps) {
  const { activeId, setActiveId } = useTabsContext();
  const isActive = activeId === id;

  return (
    <button
      role="tab"
      aria-selected={isActive}
      onClick={() => setActiveId(id)}
      className={isActive ? "font-semibold border-b-2 border-black" : "text-gray-500"}
      {...rest}
    >
      {children}
    </button>
  );
};

interface TabsContentProps extends ComponentPropsWithoutRef<"div"> {
  id: string;
}

Tabs.Content = function TabsContent({ id, children, ...rest }: TabsContentProps) {
  const { activeId } = useTabsContext();
  if (activeId !== id) return null;

  return (
    <div role="tabpanel" className="pt-4" {...rest}>
      {children}
    </div>
  );
};
```

### `app/dashboard/projects/[id]/page.tsx` (usage — Server Component still owns data)

```tsx
import { Tabs } from "@/components/ui/tabs";
import { ProjectStats } from "@/components/project-stats";
import { ProjectActivityLog } from "@/components/project-activity-log";

export default async function ProjectDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  return (
    <Tabs defaultActiveId="stats">
      <Tabs.List>
        <Tabs.Trigger id="stats">Stats</Tabs.Trigger>
        <Tabs.Trigger id="activity">Activity</Tabs.Trigger>
      </Tabs.List>

      <Tabs.Content id="stats">
        {/* Server Component, rendered server-side, passed as children */}
        <ProjectStats projectId={id} />
      </Tabs.Content>

      <Tabs.Content id="activity">
        <ProjectActivityLog projectId={id} />
      </Tabs.Content>
    </Tabs>
  );
}
```

Only `Tabs`, `Tabs.List`, `Tabs.Trigger`, and `Tabs.Content`'s *shell* (the `role`/click logic) are client code. `ProjectStats` and `ProjectActivityLog` remain Server Components that fetch their own data independently and stream in as resolved children.

---

## Anti-pattern reference (for contrast, do not copy)

```tsx
// BAD — prop drilling + forces whole subtree to "use client"
"use client";

interface CardProps {
  title: string;
  description: string;
  icon?: ReactNode;
  showBadge?: boolean;
  badgeColor?: string;
  footerText?: string;
  onFooterAction?: () => void;
}

export function Card({
  title,
  description,
  icon,
  showBadge,
  badgeColor,
  footerText,
  onFooterAction,
}: CardProps) {
  // ...every new use case adds more optional props here
  return <div>{/* ... */}</div>;
}
```
