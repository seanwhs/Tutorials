# Appendix G: PptxGenJS

## Purpose of This Appendix
A full, standalone reference for `pptxgenjs` — the library behind every PPTX export since Part 7 — covering slide/master/layout concepts beyond what our converter used, the coordinate-based positioning model in full detail, text auto-fit behavior, and the complete image/table API surface.

---

## Slides, Masters, and Layouts — The Full Concept Hierarchy

Our converter (Part 7B) used `pptx.defineLayout()` to set overall slide dimensions, and `slide.background` to set a per-slide color. The full PowerPoint conceptual model has three distinct levels, worth understanding even though our converter only used the simplest one:

1. **Layout** — the physical dimensions of every slide in the presentation (width × height, in inches by default). Set once via `pptx.defineLayout({ name, width, height })` and `pptx.layout = name`, exactly as Part 7B did. Every slide in a single presentation shares the same layout.

2. **Slide Master** — a *reusable template* defining common visual elements (a logo in the corner, a consistent footer, placeholder text styling) that many individual slides can inherit from, via `pptx.defineSlideMaster({...})`. Our converter never used this — instead, Part 7B's `renderTitleSlide`/`renderContentSlide` functions manually re-applied consistent styling (colors, fonts) to *every* individual slide via our shared `theme` object. Using a real Slide Master would be the more "PowerPoint-native" way to achieve the same visual consistency, and is a worthwhile refactor if you extend this converter: define one master with your title styling, one with your content styling, and reference them via `slide.masterName` instead of manually repeating style values on every `addText()` call.

3. **Individual Slide** — created via `pptx.addSlide()`, optionally referencing a master. Everything our converter actually built.

**Why our converter used the simpler, manual-repetition approach rather than Slide Masters:** it kept the direct mapping from `mdast` section → generated slide easier to follow for tutorial purposes, and our `theme.ts` constants object (Part 7B) already provided the "single source of truth" benefit a Slide Master would otherwise uniquely offer. For a larger, more visually elaborate presentation generator, Slide Masters would be the more scalable, PowerPoint-idiomatic choice.

---

## The Coordinate Model, In Full Detail

Part 7B's Step 4 introduced the core idea: absolute `x`/`y`/`w`/`h` positioning, with no automatic flow or collision avoidance. Here's the complete picture:

### Units

`pptxgenjs` supports three interchangeable unit systems for position/size values:

- **Inches** (the default, and what our `theme.ts` used throughout) — e.g., `x: 0.6`.
- **Points** — e.g., `x: "43pt"` (a string with a `"pt"` suffix).
- **Percentage** — e.g., `x: "10%"` (relative to the slide's total width/height) — genuinely useful for layouts meant to adapt if you ever change `theme.slideWidth`/`slideHeight`, since percentage-based values automatically rescale, unlike our converter's fixed-inch values.

### The `x`/`y`/`w`/`h` Model

Every positioned element (`addText`, `addImage`, `addTable`, `addShape`) accepts:
- `x`, `y` — the position of the element's **top-left corner**, measured from the slide's own top-left corner (`x: 0, y: 0`).
- `w`, `h` — the element's width and height.

There is no concept of "flow" the way a document has — placing two elements with overlapping `x`/`y`/`w`/`h` ranges will produce genuinely overlapping visual output, which is exactly why Part 7C's `renderContentSlide` had to manually track a running `currentY` value, incrementing it after placing each element, rather than relying on any automatic stacking behavior.

### Rotation and Z-Order

Elements also support a `rotate` property (in degrees) and are stacked in **the order you add them** — an element added later in your code will visually appear *on top of* an element added earlier, if their positions overlap. Our converter never needed to rely on this ordering behavior deliberately (all our elements were placed at non-overlapping Y positions), but it's worth knowing if you build overlapping visual designs (e.g., a text label deliberately placed on top of a background image).

---

## Text Auto-Fit Behavior

`addText()` supports a `fit` option controlling what happens when text content doesn't naturally fit within its given `w`/`h` box:

- **`"none"`** (the default, and what our converter implicitly used throughout Part 7B/7C, since we never set this option) — text simply overflows the box's visual boundaries if it's too long; PowerPoint will still display all the text, just potentially extending beyond where you specified.
- **`"shrink"`** — PowerPoint automatically reduces the font size until the text fits within the given box — the same behavior you get when manually typing too much text into a text box in PowerPoint's own UI and watching it auto-shrink.
- **`"resize"`** — the text box itself grows to accommodate the content, rather than the font shrinking.

**A direct, honest connection to Part 7C's implementation:** our `renderContentSlide`'s manual height-estimation logic (`Math.max(0.5, element.lines.length * 0.35)`, and the `console.warn` overflow guard) exists specifically because we relied on the default `"none"` behavior, requiring us to estimate heights ourselves to avoid overlapping elements. Using `fit: "shrink"` on our body-content text boxes would be a genuine, worthwhile alternative approach — trading our manual height-estimation arithmetic for PowerPoint's own automatic font-shrinking, at the cost of potentially producing inconsistently-sized body text across different slides (a slide with very little content would keep a larger font than a slide crammed with content). This is a real design trade-off worth making deliberately, not a strictly "better" option in every case.

---

## The Complete Image API

**`addImage(options)`** accepts:
- `data` — a base64 data URL (what our converter used in Part 7C) or `path` — a local file path or remote URL that `pptxgenjs` will fetch itself internally (an alternative to our own manual `fetch()`-based pre-fetching approach from Part 7C — using `path` directly would let `pptxgenjs` handle the network request itself, though our manual approach gave us the specific graceful-fallback control described in that step, which `path`'s built-in fetching does not expose in the same way).
- `x`, `y`, `w`, `h` — position and size, exactly as covered above.
- `rounding` — `true` to render the image with rounded corners/clipped to a circle.
- `sizing` — an object like `{ type: "contain" | "cover" | "crop", w, h }` for more sophisticated aspect-ratio handling than simply stretching to fixed dimensions (our Part 7C implementation used fixed `w`/`h` without this option, meaning images could appear stretched if their natural aspect ratio didn't match our hardcoded `w: 4, h: 2.5` values — a worthwhile refinement using `sizing: { type: "contain", w: 4, h: 2.5 }` to preserve aspect ratio instead).

## The Complete Table API

**`addTable(rows, options)`** — the `rows` argument is the 2D array we built in Part 7C. Beyond the per-cell `text`/`options` shape we used, individual cells also support `colspan`/`rowspan` for merged cells, and the overall `options` argument (beyond `x`/`y`/`w`/`h`/`border` used in Part 7C) supports `autoPage` (automatically splitting a table that's too tall across multiple slides — a more sophisticated alternative to our Part 7C overflow-warning approach, worth investigating if you commonly generate presentations with very large tables) and `colW` (an array of explicit per-column widths, versus our converter's implicit equal-width columns).

---

**Official documentation:** [gitbrent.github.io/PptxGenJS](https://gitbrent.github.io/PptxGenJS/) — the API reference documents every option object exhaustively, including `addChart()` (native chart generation — not used in our converter, but a natural fit for rendering GFM tables containing purely numeric data as an actual chart instead of a plain table, a genuinely interesting extension idea beyond even Part 10's list).
