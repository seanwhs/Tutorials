## Part 8: Internationalization and Accessibility Patterns (Bonus)

**Anti-Pattern:** Hardcoded English strings in JSX, a client-fetched translation dictionary causing a flash-of-wrong-language, and ARIA attributes pasted on last-minute to pass an automated scanner rather than built into component design.

**Next.js 16 Pattern:**
- **Server-resolved i18n** — `app/[locale]/...` route segment + `generateStaticParams`, `cache()`-memoized `getMessages()` loading per-locale JSON with zero client waterfall.
- **Locale-aware `middleware.ts`** — detects `Accept-Language`/cookie, redirects once.
- **Accessibility built into the shell, not bolted on** — rebuilt Part 3's `Tabs` compound component with roving `tabIndex`, Arrow/Home/End keyboard nav implemented once in `Tabs.List`, proper `aria-controls`/`aria-labelledby` pairing.
- **Explicit focus management** — after client-side navigations (Part 2's `FilterBar`) and Suspense-streamed content, since browsers silently drop focus to `<body>` by default.

**Type-Safe Implementation:** a generated `Messages` interface with a dot-path `MessageKey` type (referencing a nonexistent translation key is a compile error), `Locale` as a string union driving both the route param and `generateStaticParams`.

**Architect's Note:** hand-rolled i18n vs a full library (`next-intl`), URL-segment locale vs cookie-only, accessibility-built-in vs retrofitted, and why explicit focus management is one of the few a11y trade-offs with no real argument for skipping it.

**Code Appendices** (split into two notes for length):
- **Part 8 Code Appendix** — i18n: types, JSON messages, `get-translations.ts`, locale layout/page, locale middleware, `LocaleLink`.
- **Part 8 Code Appendix (Accessibility)** — the fully accessible `Tabs` rebuild, focus-managing `FilterBar`, and an anti-pattern contrast.

