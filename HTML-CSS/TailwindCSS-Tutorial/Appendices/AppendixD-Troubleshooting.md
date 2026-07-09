# Appendix D: Troubleshooting Guide

## D.1 Styles Not Applying At All

| Symptom | Likely cause | Fix |
|---|---|---|
| Raw unstyled HTML, zero Tailwind classes work | `postcss.config.mjs` missing/misnamed, or `@tailwindcss/postcss` not installed | Verify file exists and matches Part 2.A.3; restart dev server (PostCSS config is not hot-reloaded) |
| Works in dev, breaks in production build | CSS file not imported in the root layout/entry, or a build step strips the `<style>`/`<link>` tag | Confirm `import "./globals.css"` exists in `src/app/layout.tsx` exactly once |
| Some classes work, custom `@theme` colors don't | Old cached build artifacts | Delete `.next` (Next.js) or `node_modules/.vite` (Vite) and restart |
| Works on `localhost` but not after deploy | Node version mismatch (Next.js 16 requires Node 20.9+/22 LTS) | Set the correct Node version in your deployment platform's settings |

## D.2 IntelliSense / Editor Issues

| Symptom | Cause | Fix |
|---|---|---|
| No autocomplete for `bg-brand-500` etc. | IntelliSense not pointed at your CSS file | Set `tailwindCSS.experimental.configFile` in `.vscode/settings.json` (Part 10.2) |
| No autocomplete inside `cn()`/`cva()` calls | Missing `classFunctions` config | Add `"tailwindCSS.classFunctions": ["cva", "cn", "clsx"]` |
| Classes not auto-sorted on save | Prettier plugin not registered, or `formatOnSave` off | Install `prettier-plugin-tailwindcss`, enable `editor.formatOnSave` (Part 10.3) |
| Red squiggles under `@theme`/`@utility`/`@custom-variant` | Non-Tailwind-aware CSS validator active | Ensure the official Tailwind CSS IntelliSense extension is installed and enabled for the workspace |

## D.3 Dark Mode Issues

| Symptom | Cause | Fix |
|---|---|---|
| `dark:` classes never apply, even with `.dark` on `<html>` | Missing `@custom-variant dark` declaration (v4 defaults to OS-preference-based dark mode, not class-based) | Add `@custom-variant dark (&:where(.dark, .dark *));` to your CSS entry file (Part 5.4.2) |
| Flash of light theme on page reload | Theme class applied via `useEffect` (runs after first paint) | Use a blocking inline `<script>` in `<head>` before hydration (Part 5.4.3) |
| Dark mode toggles but doesn't persist across reloads | Not writing to `localStorage`, or blocking script reads the wrong key | Ensure the toggle component and blocking script use the same `localStorage` key name |
| Hydration mismatch warning in console | Server renders without knowing client's stored theme preference | Add `suppressHydrationWarning` to the `<html>` tag (Part 5.4.3, 11.4) — this is a well-known, safe pattern specifically for theme-class flashing, not a general fix for other hydration issues |

## D.4 Container Query / Responsive Issues

| Symptom | Cause | Fix |
|---|---|---|
| `@sm:`/`@lg:` classes never trigger | Missing `@container` on the ancestor element | Add `className="@container"` to the direct parent wrapping the element using `@sm:`/etc. |
| Container query variant affects the wrong ancestor in deeply nested layouts | Using the unnamed `@container` when multiple nested containers exist | Use named containers: `@container/name` on the parent, `@sm/name:` on the descendant (Part 5.3) |
| Custom breakpoint (e.g. `3xl:`) not recognized | `--breakpoint-3xl` not defined in `@theme`, or typo in the variable name | Double check `@theme { --breakpoint-3xl: 1920px; }` syntax exactly (Part 3, 5.2) |

## D.5 Animation / Transition Issues

| Symptom | Cause | Fix |
|---|---|---|
| Custom `animate-*` class does nothing | `@keyframes` block missing, or defined incorrectly INSIDE `@theme` (keyframes must be a sibling, not nested) | Declare `@keyframes` outside the `@theme` block, only the `--animate-*` variable goes inside `@theme` (Part 8.4) |
| `starting:` variant has no effect | Browser too old (needs Chrome 117+/Safari 17.5+/Firefox 129+), or element wasn't freshly inserted into the DOM (already existed and just had `display` toggled) | Verify browser support; ensure the element is newly mounted (conditional rendering `{open && <X/>}`), not just visibility-toggled |
| Exit animation never shows (element just vanishes) | React unmounts immediately; CSS alone can't animate removal | Use a state-delayed unmount pattern with `setTimeout` before calling the actual removal callback (Part 8.6) |
| `motion-reduce:` not respected | OS-level reduced motion setting not actually enabled in the test environment | Verify via OS accessibility settings, not just DevTools emulation (emulation support varies by browser) |

## D.6 Component / React-Specific Issues

| Symptom | Cause | Fix |
|---|---|---|
| Conflicting classes render both (e.g. both `p-2` and `p-4` visibly fighting) | Using plain string concatenation instead of `cn()`/`twMerge` | Always merge dynamic classNames through `cn()` (Part 7.2) so conflicting utilities resolve correctly |
| Consumer's `className` override doesn't win | Base classes passed to `cn()` AFTER the consumer's `className`, or not using `twMerge` at all | Always pass `className` LAST in the `cn(...)` call (Part 7.2) |
| Component unexpectedly became a Client Component | Unrelated `useState`/`useEffect` added directly to a previously-Server Component, mistakenly believing Tailwind classes required it | Remember: Tailwind classNames NEVER require `"use client"` — only actual React hooks/interactivity do (Part 7.5) |
| CVA `variant` prop shows a TypeScript error for a seemingly valid value | Typo in the `cva()` config's `variants` object, or forgetting `defaultVariants` | Confirm the variant key names match exactly; `VariantProps<typeof x>` derives types directly from the config object (Part 7.3) |

## D.7 Build / Performance Issues

| Symptom | Cause | Fix |
|---|---|---|
| Final CSS bundle unexpectedly huge (100kb+) | Accidental `@source` inclusion of a vendor/generated/`node_modules`-like directory | Audit `@source` directives; add `@source not "path";` to exclude (Part 9.8) |
| Dev server rebuild feels slow despite v4's speed claims | Very large monorepo scanning too many files, or `@source` misconfigured to include enormous directories | Scope `@source` explicitly rather than relying purely on automatic detection in monorepos |
| `tailwind.config.ts` edits have no effect | Leftover v3 config file being silently ignored by v4's PostCSS plugin (not an error — just inert) | Delete the file entirely and migrate its contents to `@theme` (Appendix B) |

## D.8 Quick Diagnostic Commands

```bash
# Confirm installed Tailwind version
npm ls tailwindcss

# Confirm Node version meets Next.js 16's floor
node -v   # must be >= 20.9 or 22.x LTS

# Force a clean rebuild (Next.js)
rm -rf .next && npm run dev

# Force a clean rebuild (Vite)
rm -rf node_modules/.vite && npm run dev

# Inspect final generated CSS size after a production build
npm run build && du -h .next/static/css/*.css
```

---

*Next: Tailwind v4 Mastery - Appendix E: Quick-Start Cheat Sheet (React 19 & Next.js 16)*
