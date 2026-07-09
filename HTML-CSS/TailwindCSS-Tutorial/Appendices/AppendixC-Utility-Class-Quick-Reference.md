# Appendix C: Utility Class Quick Reference Tables

## C.1 Spacing Scale (Default)

| Class suffix | rem | px (at 16px root) |
|---|---|---|
| `0` | 0 | 0 |
| `px` | 1px | 1px |
| `0.5` | 0.125rem | 2px |
| `1` | 0.25rem | 4px |
| `2` | 0.5rem | 8px |
| `3` | 0.75rem | 12px |
| `4` | 1rem | 16px |
| `6` | 1.5rem | 24px |
| `8` | 2rem | 32px |
| `12` | 3rem | 48px |
| `16` | 4rem | 64px |
| `24` | 6rem | 96px |
| `32` | 8rem | 128px |

Applies to `p-*`, `m-*`, `gap-*`, `w-*`, `h-*`, `top-*`/`left-*`/etc., `space-x-*`/`space-y-*`.

## C.2 Layout & Display

| Class | CSS |
|---|---|
| `block` / `inline-block` / `inline` | `display: block/inline-block/inline` |
| `flex` / `inline-flex` | `display: flex/inline-flex` |
| `grid` / `inline-grid` | `display: grid/inline-grid` |
| `hidden` | `display: none` |
| `contents` | `display: contents` |
| `sr-only` | Visually hidden but accessible to screen readers |

## C.3 Flexbox

| Class | CSS |
|---|---|
| `flex-row` / `flex-col` | `flex-direction` |
| `flex-wrap` / `flex-nowrap` | `flex-wrap` |
| `items-start/center/end/stretch` | `align-items` |
| `justify-start/center/end/between/around/evenly` | `justify-content` |
| `flex-1` | `flex: 1 1 0%` |
| `flex-auto` | `flex: 1 1 auto` |
| `shrink-0` | `flex-shrink: 0` |
| `grow` | `flex-grow: 1` |

## C.4 Grid

| Class | CSS |
|---|---|
| `grid-cols-{1-12}` | `grid-template-columns: repeat(N, minmax(0, 1fr))` |
| `col-span-{1-12}` | `grid-column: span N / span N` |
| `grid-rows-{1-6}` | `grid-template-rows: repeat(N, minmax(0, 1fr))` |
| `row-span-{1-6}` | `grid-row: span N / span N` |
| `gap-*` / `gap-x-*` / `gap-y-*` | `gap` |
| `grid-cols-[repeat(auto-fit,minmax(200px,1fr))]` | Arbitrary value (Part 9) |

## C.5 Typography

| Class | CSS |
|---|---|
| `text-xs` … `text-9xl` | `font-size` + paired `line-height` |
| `font-thin` … `font-black` | `font-weight` (100–900) |
| `italic` / `not-italic` | `font-style` |
| `underline` / `line-through` / `no-underline` | `text-decoration-line` |
| `uppercase` / `lowercase` / `capitalize` | `text-transform` |
| `truncate` | `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` |
| `line-clamp-{1-6}` | Multi-line clamp with ellipsis |
| `tracking-tighter` … `tracking-widest` | `letter-spacing` |
| `leading-none` … `leading-loose` | `line-height` |

## C.6 Colors & Backgrounds

| Class pattern | Applies to |
|---|---|
| `bg-{color}-{shade}` | `background-color` |
| `text-{color}-{shade}` | `color` |
| `border-{color}-{shade}` | `border-color` |
| `bg-{color}-{shade}/{opacity}` | Same, with alpha via `color-mix()` |
| `bg-gradient-to-{t,tr,r,br,b,bl,l,tl}` | Gradient direction |
| `from-*` / `via-*` / `to-*` | Gradient color stops |

Default color palette shades: `50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950`.

## C.7 Borders, Radius, Rings, Shadows

| Class | CSS |
|---|---|
| `border` / `border-{2,4,8}` | `border-width` |
| `border-t/r/b/l` | Per-side border width |
| `rounded` … `rounded-full` | `border-radius` |
| `rounded-t/r/b/l-*` | Per-side/corner radius |
| `shadow-sm` … `shadow-2xl` | `box-shadow` |
| `ring-{1,2,4,8}` | `box-shadow`-based outline ring |
| `ring-offset-*` | Ring offset (creates a "gap" effect) |

## C.8 Sizing

| Class | CSS |
|---|---|
| `w-full` / `h-full` | 100% |
| `w-screen` / `h-screen` | 100vw / 100vh |
| `w-fit` / `h-fit` | `fit-content` |
| `w-min` / `h-min` | `min-content` |
| `max-w-{xs,sm,md,lg,xl,2xl...7xl}` | Common max-width breakpoints for content columns |
| `size-*` | Shorthand for equal `w-*` and `h-*` |
| `aspect-square` / `aspect-video` | `aspect-ratio: 1/1` / `16/9` |

## C.9 Responsive Breakpoints (Default)

| Prefix | Min-width |
|---|---|
| `sm:` | 640px |
| `md:` | 768px |
| `lg:` | 1024px |
| `xl:` | 1280px |
| `2xl:` | 1536px |

## C.10 Container Query Variants

| Prefix | Meaning |
|---|---|
| `@container` | Marks element as a query container |
| `@sm:` … `@7xl:` | Same size scale as breakpoints, but relative to nearest `@container` ancestor |
| `@container/name` + `@sm/name:` | Named container targeting a specific ancestor |
| `@min-[500px]:` / `@max-[500px]:` | Arbitrary container size thresholds |

## C.11 State Variant Quick Reference

| Variant | Trigger |
|---|---|
| `hover:` `focus:` `active:` `disabled:` `visited:` | Standard pseudo-classes |
| `focus-visible:` `focus-within:` | Keyboard-focus / any-descendant-focus |
| `first:` `last:` `odd:` `even:` `only:` | Structural pseudo-classes |
| `not-first:` `not-last:` `not-*:` | Negation (v4) |
| `group-hover:` `group-focus:` `group-[state]/name:` | Parent-driven state |
| `peer-checked:` `peer-invalid:` `peer-[state]/name:` | Sibling-driven state |
| `has-[selector]:` | Descendant-driven state (v4, no marker class needed) |
| `in-[selector]:` | Ancestor-context-driven state (v4) |
| `aria-checked:` `aria-expanded:` `aria-[attr=value]:` | ARIA attribute-driven |
| `data-[state=open]:` | Data attribute-driven |
| `dark:` | Dark mode (media or class, Part 5) |
| `motion-safe:` `motion-reduce:` | `prefers-reduced-motion` |
| `starting:` | Native entry-transition styles (v4) |
| `print:` | `@media print` |
| `rtl:` `ltr:` | Text direction |

## C.12 Transitions & Animation Quick Reference

| Class | Purpose |
|---|---|
| `transition` / `transition-colors` / `transition-transform` / `transition-opacity` / `transition-all` | Property scope |
| `duration-{75,100,150,200,300,500,700,1000}` | Duration in ms |
| `delay-{75...1000}` | Delay in ms |
| `ease-linear` `ease-in` `ease-out` `ease-in-out` | Timing function |
| `animate-spin` `animate-ping` `animate-pulse` `animate-bounce` | Built-in keyframe animations |
| `scale-*` `rotate-*` `translate-x/y-*` `skew-*` | Transform utilities |

---

*Next: Tailwind v4 Mastery - Appendix D: Troubleshooting Guide*
