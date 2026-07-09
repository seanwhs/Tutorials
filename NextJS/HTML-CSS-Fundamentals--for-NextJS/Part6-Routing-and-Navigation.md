# Part 6: Routing & Navigation

## 1. Browser Reality — URL Bar & Full-Page Navigation
Every `<a href>` click = full document reload, with native focus-reset and screen-reader title announcement built in for free.

## 2. Next.js Translation — File-System Routing
Folders = URLs, `page.tsx` = the route's output, `[slug]` = dynamic segments — replacing hand-maintained `.html` files per URL.

## 3–4. Client-Side Transitions
Why full navigation is slow, then `<Link>` intercepting clicks to swap only the changed segment while preserving shared layout — while still rendering a real `<a>` tag so middle-click/copy-link/crawlers keep working.

## 5–6. Nested Layouts
Raw HTML repeats the shell on every page; nested `layout.tsx` files compose automatically per folder depth, preserving mounted state (e.g., sidebar scroll position) across navigations.

**Exercise + Solution:** A `/products` + `/products/[id]` structure with a shared `ProductsLayout`, converting a raw `<a>` to `<Link>` with an explicit "preserved vs. enhanced" breakdown, and tying `params` being async back to Part 5's async-resolution theme.

