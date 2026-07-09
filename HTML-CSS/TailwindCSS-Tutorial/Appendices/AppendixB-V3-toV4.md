# Appendix B: Tailwind CSS v3 → v4 Migration Guide

## B.1 Automated Migration (Try This First)

```bash
npx @tailwindcss/upgrade
```

This official codemod handles most mechanical changes automatically: rewrites `@tailwind` directives to `@import`, converts a JS `tailwind.config.js` into an equivalent `@theme` block where possible, and updates deprecated utility names. **Always run it on a clean git branch and diff the results** — it does not catch everything, especially custom plugins.

## B.2 Config File Changes

| v3 | v4 |
|---|---|
| `tailwind.config.js` with `content: []`, `theme: {}`, `plugins: []` | CSS-first: `@theme { ... }` block inside your main CSS file |
| `content: ["./src/**/*.{ts,tsx}"]` | Automatic detection — usually delete entirely; use `@source` only for edge cases (Part 9) |
| `theme: { extend: { colors: {...} } }` | `@theme { --color-*: ...; }` |
| `plugins: [require('@tailwindcss/typography')]` | `@plugin "@tailwindcss/typography";` inside CSS (official plugins still supported this way) |
| `darkMode: 'class'` | `@custom-variant dark (&:where(.dark, .dark *));` |
| `important: true` | `@import "tailwindcss" important;` |
| `prefix: 'tw-'` | `@import "tailwindcss" prefix(tw);` (usage becomes `tw:flex`, not `tw-flex`) |

## B.3 CSS Entry File Changes

```css
/* v3 */
@tailwind base;
@tailwind components;
@tailwind utilities;
```
```css
/* v4 */
@import "tailwindcss";
```

## B.4 Package Changes

```bash
# v3
npm uninstall tailwindcss autoprefixer postcss-import

# v4 (Next.js/PostCSS path)
npm install tailwindcss @tailwindcss/postcss postcss

# v4 (Vite path)
npm install tailwindcss @tailwindcss/vite
```

```js
// v3 postcss.config.js
module.exports = {
  plugins: {
    "postcss-import": {},
    "tailwindcss/nesting": {},
    tailwindcss: {},
    autoprefixer: {},
  },
};
```
```js
// v4 postcss.config.mjs — one plugin replaces all four above
export default {
  plugins: { "@tailwindcss/postcss": {} },
};
```

## B.5 Renamed / Changed Utilities

| v3 utility | v4 equivalent | Note |
|---|---|---|
| `bg-opacity-50` | `bg-black/50` (opacity modifier syntax) | Standalone opacity utilities removed; use `/` modifier everywhere |
| `text-opacity-50` | `text-black/50` | Same pattern |
| `flex-shrink-0` | `shrink-0` | Shorthand renamed |
| `flex-grow` | `grow` | Shorthand renamed |
| `overflow-ellipsis` | `text-ellipsis` | Renamed for clarity |
| `decoration-slice` | `box-decoration-slice` | Renamed |
| `outline-none` (old meaning) | `outline-hidden` for true `outline: 2px solid transparent` fallback pattern; `outline-none` now literally means `outline-style: none` | Subtle but important a11y-related change |
| `ring` (default 3px, blue) | `ring` (default now 1px, uses `currentColor`) | Default ring width/color changed — audit any bare `ring` usage |

## B.6 Breaking Behavioral Changes to Audit

1. **Border color default:** v3 defaulted borders to `gray-200`; v4 defaults to `currentColor` (matching plain CSS behavior). Any code relying on an implicit gray border (`<div class="border">` with no explicit border color) will now render differently — add `border-slate-200` (or your equivalent) explicitly.
2. **Default ring width/color:** as above — `ring` alone likely needs `ring-2 ring-brand-500` explicitly now.
3. **Space-between selector:** `space-y-*`/`space-x-*` internally now use a different selector (`:not(:last-child)` margin approach vs. adjacent-sibling `> * + *`) for better performance with `display: contents` children — visually identical in the vast majority of cases, but worth spot-checking complex nested layouts.
4. **Preflight (base reset) changes:** placeholder color, button cursor defaults, and a few other base-layer resets shifted slightly toward matching browser-native defaults more closely. Diff your rendered forms/buttons after upgrading.

## B.7 Custom Plugins (JS) → `@utility`/`@custom-variant`

```js
// v3 custom plugin (tailwind.config.js)
const plugin = require("tailwindcss/plugin");

module.exports = {
  plugins: [
    plugin(function ({ addUtilities }) {
      addUtilities({
        ".text-shadow": {
          "text-shadow": "0 2px 4px rgba(0,0,0,0.3)",
        },
      });
    }),
  ],
};
```

```css
/* v4 equivalent — no JS plugin file needed at all */
@utility text-shadow {
  text-shadow: 0 2px 4px rgb(0 0 0 / 0.3);
}
```

Full custom utility/variant coverage is in **Part 9**.

## B.8 Migration Checklist

- [ ] Run `npx @tailwindcss/upgrade` on a clean branch
- [ ] Delete `tailwind.config.js`/`.ts` once its contents are fully ported to `@theme`
- [ ] Replace `postcss.config.js` plugin list with just `@tailwindcss/postcss` (or switch to `@tailwindcss/vite`)
- [ ] Replace `@tailwind base/components/utilities` with `@import "tailwindcss";`
- [ ] Audit every bare `border` and `ring` usage for the new default color/width behavior (B.6)
- [ ] Convert any `darkMode: 'class'` config to `@custom-variant dark`
- [ ] Convert custom JS plugins to `@utility`/`@custom-variant` (B.7)
- [ ] Re-run visual regression / manually spot-check forms, buttons, and dividers
- [ ] Confirm minimum browser support (Safari 16.4+/Chrome 111+/Firefox 128+) matches your audience (Part 1.4)
- [ ] Update editor tooling: point `tailwindCSS.experimental.configFile` at your CSS file (Part 10.2)

---

*Next: Tailwind v4 Mastery - Appendix C: Utility Class Quick Reference Tables*
