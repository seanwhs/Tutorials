# Appendix F: docx (npm library)

## Purpose of This Appendix
A full, standalone reference for the `docx` library — the engine behind every DOCX export since Part 6 — covering what OOXML actually is in plain terms, the complete object model beyond what our converter used, styling/numbering quirks worth knowing, and known limitations to plan around.

---

## OOXML in Plain Terms

A `.docx` file is not a single, monolithic binary blob the way you might imagine an old `.doc` file to be — it's a **ZIP archive** (this is exactly why Part 8C's structural tests checked for the `504b` "PK" ZIP file signature) containing a folder structure of plain **XML files**, each describing a different aspect of the document. This overall format — a ZIP of XML files, used by modern Word, Excel, and PowerPoint files alike — is called **OOXML (Office Open XML)**, an open, published ISO standard.

> **Analogy — A Labeled Filing Cabinet, Not a Single Sealed Envelope.** Unzip any real `.docx` file (try it yourself: rename a copy to `.zip` and extract it) and you'll find folders like `word/document.xml` (the actual text content and formatting), `word/numbering.xml` (the numbered-list definitions — exactly what Part 6B's `ORDERED_LIST_REFERENCE` configuration ultimately gets written into), `word/media/` (any embedded images, exactly what our `ImageRun` calls from Part 6C populate), and `[Content_Types].xml` (a manifest describing what's inside). The `docx` npm library's entire job is to correctly generate all of these interconnected XML files and zip them together correctly — which is precisely why `Packer.toBuffer()` (used throughout Part 6) is doing meaningfully more work than it might appear: it's assembling an entire miniature file system, not writing one simple document.

This is worth knowing because it explains *why* `docx`'s API is shaped the way it is: every JavaScript object you construct (`Paragraph`, `TextRun`, `Table`) has a fairly direct, traceable correspondence to a specific XML element that will eventually be written into `word/document.xml`. Understanding this mapping makes the library's sometimes-particular requirements (like the numbering-definition registration from Part 6B) feel like sensible reflections of the underlying format, rather than arbitrary API quirks.

---

## The Complete Object Model Reference

Beyond the four primitives Part 6A introduced (`Document`, `Paragraph`, `TextRun`, `HeadingLevel`), here is the fuller picture:

### Document Structure
- **`Document`** — the top-level container. Accepts `sections` (an array — most documents, including ours, use exactly one, but multiple sections support different page setups within one file, e.g., a landscape section followed by a portrait one), plus document-wide `numbering` and `styles` configuration.
- **`Section`** — one logical part of the document, with its own `children` (Paragraphs/Tables), page size, margins, and headers/footers.
- **`Header` / `Footer`** — content repeated on every page of a section (page numbers, document titles) — not used in our converter, but a natural extension.

### Text Content
- **`Paragraph`** — one block-level unit, as covered in Part 6A. Accepts `heading` (a `HeadingLevel`), `alignment`, `spacing`, `indent`, `bullet`, `numbering`, and `border` — all of which our converter used across Parts 6A–6C.
- **`TextRun`** — one formatted span of text, as covered in Part 6A/6B. Beyond `bold`/`italics`/`font`/`color`/`shading` (used in our converter), it also supports `underline`, `strike` (strikethrough — a natural mapping for `mdast`'s `delete` node type, not implemented in our converter but a straightforward extension following the exact same pattern as `bold`/`italics`), `subScript`/`superScript`, and `size` (font size, in half-points).
- **`ExternalHyperlink`** — a genuinely clickable link, referenced in Part 6B's `link` case as a worthwhile extension beyond our simplified "just render the text" approach.

### Tables
- **`Table`**, **`TableRow`**, **`TableCell`** — covered fully in Part 6C. `TableCell` additionally supports `columnSpan`/`rowSpan` for merged cells, `verticalAlign`, and its own nested `borders` configuration per-cell (distinct from the table-wide border settings).

### Images
- **`ImageRun`** — covered in Part 6C. Beyond the `type`/`data`/`transformation` fields we used, it also supports `floating` (for text-wrapping behavior around an image, similar to CSS `float`) — not used in our converter, since every image we embedded was placed on its own dedicated paragraph, never wrapped by surrounding text.

### Lists & Numbering
- **`numbering.config`** — covered in Part 6B. Beyond simple decimal numbering (`LevelFormat.DECIMAL`), it also supports `LOWER_ROMAN`, `UPPER_ROMAN`, `LOWER_LETTER`, `UPPER_LETTER`, and `BULLET` (a way to define custom bullet *characters*, beyond the built-in default bullet our converter used via the simpler `bullet: { level }` shorthand).

---

## Styling & Numbering Quirks

A few specific, non-obvious behaviors worth knowing, several of which we encountered directly while building Part 6:

1. **`TextRun` is write-only** — this is the mistake we made and corrected live in Part 6A. There is no supported way to read back the options a `TextRun` was constructed with. Any code that needs to *compose* or *modify* formatting must work with plain intermediate objects (our `RunProps` interface) until the final construction step — a pattern worth remembering for any similarly "write-only" object-construction library you encounter in the future.

2. **Numbering definitions are referenced by name, not embedded per-paragraph** — as built in Part 6B, every `Paragraph` using `numbering: { reference, level }` points at a shared definition registered once on the `Document` itself. This is *why* Word's live renumbering behavior (verified in Part 6B's test — deleting item 2 and watching item 3 renumber) works correctly: all paragraphs sharing one reference are understood by Word to be part of the same logical numbered sequence.

3. **A single `TextRun`'s `text` field does not respect embedded newline characters.** Part 6B's code block rendering worked around this explicitly, splitting on `"\n"` and inserting `new TextRun({ break: 1 })` between resulting lines — a quirk worth remembering any time you're rendering genuinely multi-line text into a single run.

4. **Bullet levels and numbering levels are zero-indexed**, matching how our `renderList`/`renderListItem` functions (Part 6B) tracked `depth` starting at `0` for top-level items.

---

## Known Limitations

Stated honestly, for planning purposes if you extend this converter further:

- **No genuinely arbitrary nested-table support.** While `TableCell` can technically contain another `Table` as one of its `children`, deeply nested tables (a table inside a cell inside a table inside a cell) are known to render inconsistently across different Word versions and viewers — this is a limitation of how Word itself handles deeply nested tables at the OOXML level, not specifically a `docx` library bug. Our converter never needed nested tables (GFM Markdown tables themselves have no concept of table-in-table nesting to begin with), so this limitation never surfaced in our implementation.
- **Limited support for advanced Word features** — track changes, comments, footnotes/endnotes, and complex field codes (like auto-updating page number references) are either unsupported or require significantly more manual XML-level configuration than the high-level object model covered here.
- **Image format detection is manual** — as noted in Part 6C's implementation, `ImageRun`'s `type` field must be explicitly specified (`"png"`, `"jpg"`, etc.) rather than auto-detected from the actual image bytes; our converter defaulted to `"png"` for simplicity, which works correctly for the common case but would need real format-sniffing logic for a fully general-purpose image pipeline.

---

**Official documentation:** [docx.js.org](https://docx.js.org) — the API reference documents every class's full constructor options exhaustively; the "Usage" guide covers several additional patterns (headers/footers, sections with different page orientations) beyond what our converter needed.
