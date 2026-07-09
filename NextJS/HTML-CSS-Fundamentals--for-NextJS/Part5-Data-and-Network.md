# Part 5: Data & the Network

## 1. Browser Reality — HTTP Request/Response
Raw HTTP: a `GET`/`POST` request with headers, a response with a status code and `Cache-Control` header. This is the entire contract underlying every fetch, form, and API call on the web.

## 2. Browser Reality — Forms Without JavaScript
A plain `<form action="/subscribe" method="POST">` triggers a full-page navigation with zero JS — the original "data mutation" mechanism.

## 3. Next.js Translation — Server Actions
`'use server'` functions called directly from `action={subscribe}` — no API route, `FormData` handled natively, progressively enhanced (works with JS off, upgrades with JS on).

## 4–5. Fetching Data
Client-side `fetch()` in a `<script>` vs. Server Components `await fetch()` during render — `params` as a `Promise`, `next: { revalidate }` mapped directly to `Cache-Control: max-age`.

## 6. Why the Data Cache Beats Hand-Rolled Caching
One-line `revalidate` vs. manually implementing HTTP caching semantics yourself.

**Exercise + Solution:** A `ContactForm` built with `useActionState`, proving the no-JS fallback still works because `<Link>`/form actions render real HTML elements underneath.

---

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

