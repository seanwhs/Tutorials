# Part 8: Images & Performance

## 1–3. Native `<img>` Fundamentals
Plain `<img>` behavior: `alt` for accessibility/fallback, `width`/`height` reserving layout space to prevent Cumulative Layout Shift (CLS), `srcset`/`sizes` for browser-native responsive image selection, and `loading="lazy"` for native deferred loading.

## 4. `next/image` Translation
Every native mechanism mapped directly: required `alt`/`width`/`height` props, automatic `srcset`/format generation (WebP/AVIF) at request time, default lazy-loading, and `priority` as the explicit opt-out for above-the-fold images.

## 5–6. Script Loading
Render-blocking `<script>` vs. `defer`/`async` natively, then `next/script`'s `strategy` prop (`beforeInteractive`/`afterInteractive`/`lazyOnload`) mapped to those same native timing behaviors.

## 7–8. Font Loading
`@font-face` + `font-display: swap` causing FOIT/FOUT, then `next/font` self-hosting fonts at build time and auto-computing fallback metrics to minimize shift.

**Exercise + Solution:** Convert a raw below-the-fold `<img>` to `next/image` (correctly omitting `priority`), explain why missing `width`/`height` causes identical CLS in both raw HTML and Next.js (traced back to Part 1's box model), and add a chat widget via `next/script` with a justified `strategy="lazyOnload"`.

