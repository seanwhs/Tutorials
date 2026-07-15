# Appendix E: @react-pdf/renderer

## Purpose of This Appendix
A full, standalone reference for `@react-pdf/renderer` — the library behind every PDF export since Part 5 — covering its underlying layout engine, a comprehensive supported-style-properties reference (beyond the subset our `toPdf.tsx` actually used), font embedding internals, and honest performance limits worth knowing before you push this library toward much larger documents.

---

## The Layout Engine: Yoga, Explained

When you write `<View style={{ flexDirection: "row" }}>` in `@react-pdf/renderer`, something has to actually calculate the real pixel/point positions of every element on the page — that calculation is performed by **Yoga**, an open-source layout engine originally built by Meta (the same team behind React Native) specifically to implement the CSS Flexbox specification in non-browser environments.

> **Analogy — The Same Furniture-Arranging Rules, a Different Room.** A web browser has its own built-in layout engine (part of the browser itself) that interprets Flexbox CSS and arranges elements accordingly. A PDF file has no such built-in engine — a PDF, at its core binary format level, only understands "draw this exact glyph at this exact x/y coordinate." Yoga is what bridges that gap: it takes your Flexbox-style declarations (`flexDirection`, `justifyContent`, `flex: 1`, etc.) and *computes* the exact x/y/width/height coordinates each element needs, which `@react-pdf/renderer` then uses to actually draw text and shapes into the PDF's underlying coordinate system.

This is precisely why our `toPdf.tsx` code (Parts 5A–5D) could use familiar, web-like styling (`flexDirection: "row"` for table rows in Part 5C, `marginLeft` for list indentation in Part 5B) despite targeting a completely non-browser output format — Yoga is doing the same conceptual job a browser's rendering engine does, just outputting PDF drawing instructions instead of painted pixels on a screen.

---

## Complete Supported Style Properties Reference

Our `toPdf.tsx` styles (Parts 5A–5D) used a deliberately focused subset. Here is the fuller picture, organized by category, for when you extend the converter further:

### Flexbox Layout (Yoga-powered)
`flexDirection`, `flexWrap`, `justifyContent`, `alignItems`, `alignSelf`, `alignContent`, `flex`, `flexGrow`, `flexShrink`, `flexBasis`

### Dimensions & Spacing
`width`, `height`, `minWidth`, `minHeight`, `maxWidth`, `maxHeight`, `margin` (+ `marginTop`/`Right`/`Bottom`/`Left`), `padding` (+ directional variants)

### Position
`position` (`"relative"` | `"absolute"`), `top`, `right`, `bottom`, `left` — used for absolutely-positioned overlays (e.g., page numbers or watermarks) that shouldn't participate in normal Flexbox flow. Our converter never needed absolute positioning since every element (headings, lists, tables) flows naturally.

### Borders
`border`, `borderTop`/`Right`/`Bottom`/`Left` (shorthand strings like `"1pt solid #000000"`), or the more granular `borderWidth`/`borderColor`/`borderStyle` (+ directional variants) — our table styling in Part 5C used the granular form.

### Text-Specific (only valid on `<Text>`)
`fontFamily`, `fontSize`, `fontWeight`, `fontStyle`, `textAlign`, `textDecoration`, `lineHeight`, `letterSpacing`, `textIndent`

### Color & Background
`color` (text color), `backgroundColor`, `opacity`

### Object Fit (for `<Image>`)
`objectFit` (`"fill"` | `"contain"` | `"cover"` | `"none"` | `"scale-down"`) — controls how an image's aspect ratio is handled when its `style` dimensions don't match its natural aspect ratio. Our Part 5C image handling used fixed `style` dimensions without explicitly setting this, meaning the default (`"fill"`, stretching the image to exactly match the given width/height) applied — worth revisiting if you notice embedded images looking stretched or distorted in your own extensions.

**A sharp, important limitation, confirmed in practice throughout Parts 5A–5D:** unlike CSS in a browser, **most properties do not cascade/inherit** from parent to child. Setting `color` on a `<View>` does not automatically color `<Text>` elements inside it — this is why every one of our `renderInline`/`renderBlockNode` functions explicitly applied styling directly to each `<Text>` element, rather than relying on any inherited parent styling. `fontFamily` is a rare, notable exception — it *does* inherit, which is precisely why registering `"Inter"` once on `styles.page` in Part 5D correctly applied it to every nested `<Text>` throughout the document without us needing to repeat `fontFamily: "Inter"` on every single style object.

---

## Font Embedding: What `Font.register()` Actually Does

Part 5D's `Font.register()` call does meaningfully more work than it might appear to at a glance. A PDF file format has no concept of "the system has this font installed" the way a webpage can rely on a user's operating system fonts — **every font used in a PDF must be embedded directly into the PDF file's own binary data**, as actual font program bytes, so the PDF displays identically correctly on any device, regardless of what fonts that device happens to have installed.

When we called:

```typescript
Font.register({
  family: "Inter",
  fonts: [
    { src: "https://cdn.jsdelivr.net/fontsource/fonts/inter@latest/latin-400-normal.ttf", fontWeight: 400 },
    // ...
  ],
});
```

`@react-pdf/renderer` fetched those `.ttf` (TrueType Font) files, parsed their internal font program data, and — during the actual `renderToBuffer()` call in our Route Handler — embedded the relevant glyph data directly into the output PDF's bytes. This is *why* the resulting PDF displays the correct Inter typeface identically on any viewer, on any operating system, regardless of whether that specific machine has Inter installed at all — the font itself travels inside the file.

**The production caveat flagged in Part 5D, restated here in full:** fetching font files over the network on every cold-start or (depending on your hosting platform's caching behavior) potentially every request introduces both latency and an external dependency. For a genuinely production-hardened deployment, download the specific `.ttf` files you need once, commit them to `public/fonts/`, and reference them via a local file path instead:

```typescript
Font.register({
  family: "Inter",
  fonts: [
    { src: "./public/fonts/Inter-Regular.ttf", fontWeight: 400 },
    { src: "./public/fonts/Inter-Bold.ttf", fontWeight: 700 },
  ],
});
```

---

## Performance Limits for Large Documents

Two honest, practical limits worth knowing if you push this library significantly beyond what our test documents (Parts 5A–5D) exercised:

1. **Memory scales with document complexity, not just character count.** A document with many deeply nested lists, large tables, or numerous embedded images holds a correspondingly large in-memory React element tree *and* the Yoga layout engine's computed results simultaneously, before `renderToBuffer()` produces final bytes. This is exactly why Part 9A's `vercel.json` configuration and Part 9C's `MAX_IMAGES_PER_DOCUMENT` cap both exist — they're targeted mitigations for this specific, real constraint, not arbitrary numbers.
2. **Very deeply nested Flexbox layouts can slow Yoga's layout computation noticeably.** Our list-nesting implementation (Part 5B) is unlikely to realistically reach a problematic depth for genuine documents (Markdown lists rarely nest more than 3–4 levels deep in practice), but if you were to programmatically generate a document with, say, 50 levels of nesting, you would likely notice real, measurable slowdown — a good reminder that "the library supports arbitrary nesting" and "arbitrary nesting performs well" are two different claims.

---

**Official documentation:** [react-pdf.org](https://react-pdf.org) — the "Components" and "Styling" reference pages document every prop above exhaustively, including several advanced components (`<Svg>`, `<Canvas>`, `<Note>`) our converter never needed but which exist for more visually elaborate PDF generation.
