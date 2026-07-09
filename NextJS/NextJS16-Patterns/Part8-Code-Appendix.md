# Part 8 Code Appendix — Full Snippets (i18n)

Companion code for **Part 8: Internationalization and Accessibility Patterns**.

---

## `lib/i18n/types.ts`

```ts
export type Locale = "en" | "es" | "fr";

export const SUPPORTED_LOCALES: readonly Locale[] = ["en", "es", "fr"];

export interface Messages {
  dashboard: {
    archiveButton: string;
    filterLabel: string;
    statsHeading: string;
  };
}
```

## `messages/en.json`

```json
{
  "dashboard": {
    "archiveButton": "Archive",
    "filterLabel": "Filter by status",
    "statsHeading": "Project stats"
  }
}
```

## `messages/es.json`

```json
{
  "dashboard": {
    "archiveButton": "Archivar",
    "filterLabel": "Filtrar por estado",
    "statsHeading": "Estadisticas del proyecto"
  }
}
```

## `lib/i18n/get-translations.ts`

```ts
import "server-only";
import { cache } from "react";
import type { Locale, Messages } from "./types";

const loaders: Record<Locale, () => Promise<Messages>> = {
  en: () => import("@/messages/en.json").then((m) => m.default as Messages),
  es: () => import("@/messages/es.json").then((m) => m.default as Messages),
  fr: () => import("@/messages/fr.json").then((m) => m.default as Messages),
};

export const getMessages = cache(async (locale: Locale): Promise<Messages> => {
  const load = loaders[locale] ?? loaders.en;
  return load();
});

type DotPath<T, Prefix extends string = ""> = {
  [K in keyof T & string]: T[K] extends string
    ? `${Prefix}${K}`
    : DotPath<T[K], `${Prefix}${K}.`>;
}[keyof T & string];

export type MessageKey = DotPath<Messages>;

export function createTranslator(messages: Messages) {
  return function t(key: MessageKey): string {
    const parts = key.split(".");
    let value: unknown = messages;
    for (const part of parts) {
      value = (value as Record<string, unknown>)?.[part];
    }
    return typeof value === "string" ? value : key;
  };
}
```

The `DotPath<T>` mapped/conditional type is what makes `t("dashboard.archiveButton")` type-check against the actual shape of `Messages` — `t("dashboard.nonexistentKey")` fails to compile rather than silently rendering the raw key string at runtime.

---

## `app/[locale]/layout.tsx` (validate locale, generate static params)

```tsx
import type { ReactNode } from "react";
import { SUPPORTED_LOCALES, type Locale } from "@/lib/i18n/types";

export function generateStaticParams() {
  return SUPPORTED_LOCALES.map((locale) => ({ locale }));
}

interface LayoutProps {
  children: ReactNode;
  params: Promise<{ locale: string }>;
}

export default async function LocaleLayout({ children, params }: LayoutProps) {
  const { locale } = await params;
  const validLocale: Locale = SUPPORTED_LOCALES.includes(locale as Locale)
    ? (locale as Locale)
    : "en";

  return (
    <html lang={validLocale}>
      <body>{children}</body>
    </html>
  );
}
```

## `app/[locale]/dashboard/projects/page.tsx` (server-resolved translations, zero client waterfall)

```tsx
import { getMessages, createTranslator } from "@/lib/i18n/get-translations";
import { SUPPORTED_LOCALES, type Locale } from "@/lib/i18n/types";
import { projectRepository } from "@/lib/repositories/project-repository";
import { requireUser } from "@/lib/auth/session";

interface PageProps {
  params: Promise<{ locale: string }>;
}

export default async function ProjectsPage({ params }: PageProps) {
  const { locale: rawLocale } = await params;
  const locale: Locale = SUPPORTED_LOCALES.includes(rawLocale as Locale)
    ? (rawLocale as Locale)
    : "en";

  const [messages, user] = await Promise.all([getMessages(locale), requireUser()]);
  const t = createTranslator(messages);

  const projects = await projectRepository.getAll({ orgId: user.orgId });

  return (
    <div>
      <h1>{t("dashboard.statsHeading")}</h1>
      <label htmlFor="status-filter">{t("dashboard.filterLabel")}</label>
      <ul>
        {projects.map((p) => (
          <li key={p.id}>
            {p.name}
            <button>{t("dashboard.archiveButton")}</button>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

Note how this ties everything together: `requireUser()` (Part 7) and `getMessages()` (Part 8) both run in parallel via `Promise.all`, both are `cache()`-memoized per-request, and `projectRepository.getAll({ orgId: user.orgId })` still enforces Part 7's rule that tenant scoping comes from the verified session, never the URL.

## `middleware.ts` (locale detection + redirect, composed with Part 7's auth middleware)

```ts
import { NextResponse, type NextRequest } from "next/server";
import { SUPPORTED_LOCALES, type Locale } from "@/lib/i18n/types";

const DEFAULT_LOCALE: Locale = "en";

function detectLocale(request: NextRequest): Locale {
  const cookieLocale = request.cookies.get("locale")?.value as Locale | undefined;
  if (cookieLocale && SUPPORTED_LOCALES.includes(cookieLocale)) return cookieLocale;

  const acceptLanguage = request.headers.get("accept-language") ?? "";
  const preferred = acceptLanguage.split(",")[0]?.split("-")[0] as Locale | undefined;
  if (preferred && SUPPORTED_LOCALES.includes(preferred)) return preferred;

  return DEFAULT_LOCALE;
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  const hasLocalePrefix = SUPPORTED_LOCALES.some(
    (locale) => pathname === `/${locale}` || pathname.startsWith(`/${locale}/`)
  );

  if (!hasLocalePrefix) {
    const locale = detectLocale(request);
    const url = new URL(`/${locale}${pathname}`, request.url);
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next|api|favicon.ico).*)"],
};
```

In a real app, this locale-detection middleware and Part 7's session-check middleware would be merged into a single `middleware.ts` (Next.js only runs one middleware file per app) — run the locale redirect first, then the auth check against the now-locale-prefixed path.

## `components/ui/locale-link.tsx` (client, prefixes the current locale automatically)

```tsx
"use client";

import Link, { type LinkProps } from "next/link";
import { useParams } from "next/navigation";
import type { ReactNode } from "react";

interface LocaleLinkProps extends LinkProps {
  children: ReactNode;
}

export function LocaleLink({ href, children, ...rest }: LocaleLinkProps) {
  const params = useParams<{ locale: string }>();
  const localizedHref =
    typeof href === "string" ? `/${params.locale}${href}` : href;

  return (
    <Link href={localizedHref} {...rest}>
      {children}
    </Link>
  );
}
```

---

# Part 8 Code Appendix (Accessibility) — Compound Components + Focus Management

Continuation of **EntNext16 - Part 8 Code Appendix**. Covers the accessible `Tabs` rebuild and focus management referenced in the main Part 8 note.

---

## `components/ui/tabs.tsx` (accessible rewrite of the Part 3 `Tabs` compound component)

```tsx
"use client";

import {
  createContext,
  useContext,
  useState,
  useRef,
  type ComponentPropsWithoutRef,
  type KeyboardEvent,
  type ReactNode,
} from "react";

interface TabsContextValue {
  activeId: string;
  setActiveId: (id: string) => void;
  registerTabId: (id: string) => void;
  tabIds: string[];
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
  const tabIdsRef = useRef<string[]>([]);

  function registerTabId(id: string) {
    if (!tabIdsRef.current.includes(id)) {
      tabIdsRef.current.push(id);
    }
  }

  return (
    <TabsContext.Provider
      value={{ activeId, setActiveId, registerTabId, tabIds: tabIdsRef.current }}
    >
      <div className="w-full">{children}</div>
    </TabsContext.Provider>
  );
}

Tabs.List = function TabsList({
  children,
  ...rest
}: ComponentPropsWithoutRef<"div">) {
  const { activeId, setActiveId, tabIds } = useTabsContext();

  function handleKeyDown(event: KeyboardEvent<HTMLDivElement>) {
    const currentIndex = tabIds.indexOf(activeId);
    let nextIndex = currentIndex;

    if (event.key === "ArrowRight") nextIndex = (currentIndex + 1) % tabIds.length;
    if (event.key === "ArrowLeft") nextIndex = (currentIndex - 1 + tabIds.length) % tabIds.length;
    if (event.key === "Home") nextIndex = 0;
    if (event.key === "End") nextIndex = tabIds.length - 1;

    if (nextIndex !== currentIndex) {
      event.preventDefault();
      const nextId = tabIds[nextIndex];
      setActiveId(nextId);
      document.getElementById(`tab-${nextId}`)?.focus();
    }
  }

  return (
    <div role="tablist" className="flex gap-2 border-b" onKeyDown={handleKeyDown} {...rest}>
      {children}
    </div>
  );
};

interface TabsTriggerProps extends ComponentPropsWithoutRef<"button"> {
  id: string;
}

Tabs.Trigger = function TabsTrigger({ id, children, ...rest }: TabsTriggerProps) {
  const { activeId, setActiveId, registerTabId } = useTabsContext();
  registerTabId(id);
  const isActive = activeId === id;

  return (
    <button
      id={`tab-${id}`}
      role="tab"
      aria-selected={isActive}
      aria-controls={`panel-${id}`}
      tabIndex={isActive ? 0 : -1}
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
    <div
      id={`panel-${id}`}
      role="tabpanel"
      aria-labelledby={`tab-${id}`}
      tabIndex={0}
      className="pt-4"
      {...rest}
    >
      {children}
    </div>
  );
};
```

Key accessibility details baked into the shell (not left to consumers):
- **Roving `tabIndex`** (`0` on the active tab, `-1` on the rest) so Tab key moves focus into the tab list once, then arrow keys move between tabs — the standard expected keyboard pattern for the ARIA `tablist` role.
- **`aria-controls` / `aria-labelledby` pairing** lets screen readers announce the relationship between a `Tabs.Trigger` and its `Tabs.Content` panel.
- **Arrow/Home/End key handling** lives once in `Tabs.List`, so every feature composing `Tabs` (Part 3's `ProjectDetailPage`, or any future usage) gets correct keyboard behavior automatically.

---

## Focus management after a client-side navigation (Part 2 tie-in)

```tsx
// app/dashboard/projects/filter-bar.tsx (accessible update to Part 2's version)
"use client";

import { useRouter, useSearchParams, usePathname } from "next/navigation";
import { useTransition, useRef, useEffect } from "react";

interface FilterBarProps {
  currentStatus: string;
  currentSort: string;
}

export function FilterBar({ currentStatus, currentSort }: FilterBarProps) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();
  const resultsHeadingRef = useRef<HTMLHeadingElement | null>(null);

  function updateParam(key: string, value: string) {
    const params = new URLSearchParams(searchParams.toString());
    params.set(key, value);

    startTransition(() => {
      router.push(`${pathname}?${params.toString()}`);
    });
  }

  useEffect(() => {
    // After a filter change re-renders the list, move focus to a heading
    // announcing updated results, instead of leaving focus on the <select>
    // (acceptable) or letting it silently drop to <body> on more complex swaps.
    if (!isPending) {
      resultsHeadingRef.current?.focus();
    }
  }, [isPending]);

  return (
    <div>
      <div className={isPending ? "opacity-60" : ""}>
        <select
          value={currentStatus}
          onChange={(e) => updateParam("status", e.target.value)}
        >
          <option value="all">All</option>
          <option value="active">Active</option>
          <option value="archived">Archived</option>
          <option value="draft">Draft</option>
        </select>

        <select
          value={currentSort}
          onChange={(e) => updateParam("sort", e.target.value)}
        >
          <option value="updatedAt">Last updated</option>
          <option value="name">Name</option>
        </select>
      </div>

      <h2 tabIndex={-1} ref={resultsHeadingRef} aria-live="polite">
        {isPending ? "Updating results…" : "Results updated"}
      </h2>
    </div>
  );
}
```

`aria-live="polite"` announces the update to screen reader users without an explicit focus jump feeling jarring, while `tabIndex={-1}` + `.focus()` lets the heading programmatically receive focus without becoming part of the normal Tab order.

---

## Anti-pattern reference (for contrast, do not copy)

```tsx
// BAD — hardcoded English string, no ARIA relationship between trigger and panel,
// no keyboard navigation, client-fetched translation dictionary bolted on later
"use client";

import { useEffect, useState } from "react";

export function Tabs() {
  const [active, setActive] = useState("stats");
  const [labels, setLabels] = useState<Record<string, string>>({});

  useEffect(() => {
    fetch("/api/translations").then((r) => r.json()).then(setLabels);
  }, []);

  return (
    <div>
      <div>
        <button onClick={() => setActive("stats")}>
          {labels.stats ?? "Stats"} {/* flashes "Stats" before dictionary loads */}
        </button>
        <button onClick={() => setActive("activity")}>
          {labels.activity ?? "Activity"}
        </button>
      </div>
      {/* no role="tablist"/"tab"/"tabpanel", no aria-selected, no keyboard support */}
      {active === "stats" && <div>Stats content</div>}
      {active === "activity" && <div>Activity content</div>}
    </div>
  );
}
```

---
