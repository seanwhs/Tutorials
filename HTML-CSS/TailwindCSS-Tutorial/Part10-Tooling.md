# Part 10: Performance, Tooling & Editor Setup

## 10.1 Build Performance — Why v4 Is Fast

| Metric (Tailwind's own benchmarks, representative) | v3 | v4 |
|---|---|---|
| Full rebuild (large project) | ~960ms | ~100ms (≈5-10x) |
| Incremental rebuild (no new classes) | ~200ms | **~35 microseconds** (measured, not a typo) |
| Incremental rebuild (new classes added) | ~200ms | ~5ms |

This comes from the Rust/Oxide engine plus an incremental architecture that only re-parses files that actually changed, and caches which candidate class strings map to which generated CSS rules. **Practical implication:** on `next dev` with Turbopack, style edits reflect near-instantly; you should never need to manually restart the dev server for a Tailwind-only change (only for `postcss.config.mjs`/`vite.config.ts` edits, per Part 2).

## 10.2 VS Code: Tailwind CSS IntelliSense

```bash
# Install from the Extensions panel, or:
code --install-extension bradlc.vscode-tailwindcss
```

```jsonc
// .vscode/settings.json — recommended project settings
{
  // Enables autocomplete inside cva(), cn(), and clsx() calls, not just className=""
  "tailwindCSS.classFunctions": ["cva", "cn", "clsx", "twMerge"],

  // Points IntelliSense at your actual CSS entry file so it understands
  // custom @theme tokens (brand colors, custom spacing, etc.) for autocomplete
  "tailwindCSS.experimental.configFile": "src/app/globals.css",

  // Ensures files using className in template literals (rare but happens in .mdx) are covered
  "files.associations": {
    "*.css": "tailwindcss"
  },

  // Recommended: sort classes automatically on save (paired with the Prettier plugin below)
  "editor.formatOnSave": true
}
```

> **Important v4-specific note:** because there's no `tailwind.config.js` anymore, IntelliSense needs to be pointed at your CSS file (via `tailwindCSS.experimental.configFile`) to pick up custom `@theme` tokens for autocomplete — earlier IntelliSense versions only looked for a JS config file.

## 10.3 Automatic Class Sorting — `prettier-plugin-tailwindcss`

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

```json
// .prettierrc.json
{
  "semi": true,
  "singleQuote": false,
  "plugins": ["prettier-plugin-tailwindcss"],
  "tailwindStylesheet": "./src/app/globals.css"
}
```

```tsx
// BEFORE formatting (order is whatever the developer typed):
<div className="text-white p-4 flex bg-brand-500 hover:bg-brand-600 rounded-lg items-center" />

// AFTER prettier --write (auto-sorted into Tailwind's canonical, recommended order —
// layout > box model > typography > visual > misc > state variants last):
<div className="flex items-center rounded-lg bg-brand-500 p-4 text-white hover:bg-brand-600" />
```

`tailwindStylesheet` (new in v4-compatible plugin versions) lets the sorter understand your custom `@theme` utilities too, not just Tailwind's built-ins.

```bash
# Run across the whole project, or wire into a pre-commit hook (e.g. via husky/lint-staged)
npx prettier --write .
```

## 10.4 ESLint: Enforcing No-Unnecessary/Conflicting Classes

```bash
npm install -D eslint-plugin-tailwindcss
```

```js
// eslint.config.mjs (Next.js 16 flat config)
import tailwind from "eslint-plugin-tailwindcss";

export default [
  ...tailwind.configs["flat/recommended"],
  {
    rules: {
      // Catches genuinely conflicting utilities in the SAME string,
      // e.g. className="p-4 p-2" (which the cn() helper from Part 7 would fix
      // for dynamic strings, but this catches static mistakes at lint time)
      "tailwindcss/no-contradicting-classname": "error",
      "tailwindcss/classnames-order": "off", // handled by Prettier plugin instead — avoid double-sorting fights
    },
  },
];
```

## 10.5 Debunking "Purging" Myths in v4

There is no separate "purge" step or config in v4 (and hasn't been since v3.0's JIT engine became default). A common misconception carried over from very old Tailwind v1/v2 tutorials:

```js
// THIS DOES NOT EXIST IN v4 (also removed as a separate concept since early v3) — ignore any
// blog post telling you to configure a `purge: []` array.
module.exports = { purge: [...] }; // ❌ obsolete, will cause confusion, not an error but a no-op
```

Tailwind v4 generates **only** the CSS for classes it actually finds referenced in your source files (automatic content detection, Part 1) — there's nothing to "purge" because nothing unused was ever generated in the first place.

## 10.6 Inspecting Generated CSS Size (Sanity Check)

```bash
# Next.js 16 — after a production build, inspect the generated CSS chunk size
npm run build
ls -la .next/static/css/*.css
du -h .next/static/css/*.css
```

A typical mid-sized dashboard app's final Tailwind CSS output (all pages combined) should land somewhere in the 15-40kb gzipped range — if you see something in the multi-hundred-kb range, check for accidental `@source` inclusion of a vendor/generated directory (Part 9) or a stray safelist force-including huge swaths of unused utilities.

## 10.7 Common Editor/Tooling Gotchas Table

| Symptom | Cause | Fix |
|---|---|---|
| No autocomplete for custom brand colors | IntelliSense not pointed at your CSS file | Set `tailwindCSS.experimental.configFile` (10.2) |
| Classes not sorted on save | Prettier plugin missing/not in plugins array | Install + register `prettier-plugin-tailwindcss` (10.3) |
| Editor shows squiggly under `@theme`/`@utility`/`@custom-variant` | Old/non-Tailwind-aware CSS language server conflicting | Disable built-in CSS validation for the workspace or ensure Tailwind IntelliSense extension is active for `.css` |
| Autocomplete works in `.tsx` but not inside `cva()` calls | `classFunctions` setting missing `cva` | Add to `tailwindCSS.classFunctions` (10.2) |

## 10.8 Exercise Challenge

Set up `.vscode/settings.json` and `.prettierrc.json` in the `tw4-mastery` project from Part 2 so that saving any `.tsx` file both sorts Tailwind classes AND provides autocomplete for the `--color-brand-*` tokens defined in Part 3.

## 10.9 Solution

```jsonc
// .vscode/settings.json
{
  "tailwindCSS.classFunctions": ["cva", "cn", "clsx"],
  "tailwindCSS.experimental.configFile": "src/app/globals.css",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode"
}
```

```json
// .prettierrc.json
{
  "plugins": ["prettier-plugin-tailwindcss"],
  "tailwindStylesheet": "./src/app/globals.css"
}
```

```bash
npm install -D prettier prettier-plugin-tailwindcss
code --install-extension esbenp.prettier-vscode
code --install-extension bradlc.vscode-tailwindcss
```

Reload the VS Code window after adding these; typing `bg-brand-` in any `className` should now autocomplete `bg-brand-500`, `bg-brand-900`, etc., and saving a file with out-of-order classes should auto-sort them.

---

*Next: Tailwind v4 Mastery - Part 11: Capstone Project*
