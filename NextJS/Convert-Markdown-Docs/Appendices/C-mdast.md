# Appendix C: The unified / remark / mdast Ecosystem

## Purpose of This Appendix
A full, standalone reference for the parsing layer this entire series is built on — the "unified collective" philosophy, how plugins compose, and a complete `mdast` node type table (expanded beyond Part 3A's tutorial-paced version to include every node type the ecosystem defines, not just the ones our converters happened to need).

---

## The "Unified Collective" Philosophy

`unified` is not itself a Markdown parser — it's a **generic, pluggable text-processing engine**. This is worth restating precisely, since it's easy to conflate `unified` with `remark` (the Markdown-specific plugin) after using them together throughout this series.

> **Analogy — A Universal Assembly Line, With Swappable Stations.** `unified` is the conveyor belt and the rules for how stations attach to it. `remark-parse` is one specific station you bolt onto that belt, one that happens to know how to read Markdown. If you bolted on a *different* first station — say, `rehype-parse` — the exact same belt (`unified`) would instead process HTML. This is why the ecosystem is organized into three parallel families, all sharing the same underlying engine:

| Family | Processes | Example plugins |
|---|---|---|
| **remark** | Markdown | `remark-parse`, `remark-gfm`, `remark-math` |
| **rehype** | HTML | `rehype-stringify`, `rehype-sanitize`, `rehype-highlight` |
| **retext** | Natural language / prose | `retext-spell`, `retext-readability` |

`react-markdown` (Part 2B) actually uses **both** `remark` and `rehype` internally, chained together: `remark-parse` turns Markdown into an `mdast` tree, a bridging plugin (`remark-rehype`) converts that `mdast` tree into a **`hast`** tree (HTML's equivalent AST), and `rehype`'s machinery turns *that* into real React elements. Our own `lib/parseMarkdown.ts`, by contrast, deliberately stops at the `mdast` stage — we never needed the `hast`/HTML conversion step, since our three converters (Parts 5–7) each walk the `mdast` tree directly.

---

## The Plugin Architecture: `.use()`, Explained Precisely

Every call to `.use(somePlugin)` in a `unified()` chain adds that plugin to one of three possible processing phases:

1. **Parser plugins** (like `remark-parse`) — transform raw text into a tree. There can only be one parser in a chain.
2. **Transformer plugins** (like `remark-gfm`) — receive the already-parsed tree and modify it (adding new node types, restructuring existing ones) before handing it to the next plugin in the chain. Multiple transformers can be chained in sequence.
3. **Compiler plugins** (like `rehype-stringify`) — transform a tree back into a final output format (a string, typically). There can only be one compiler in a chain.

Our own `lib/parseMarkdown.ts` (Part 3A) uses exactly two of these three phases:

```typescript
const processor = unified().use(remarkParse).use(remarkGfm);
const ast = processor.parse(markdown);
```

`remarkParse` is the parser. `remarkGfm` is a transformer — technically, `remark-gfm` works by registering *additional micromark syntax extensions* that `remark-parse` itself consults during parsing, which is why calling `.parse()` alone (without a separate `.run()` step) is sufficient to get GFM features recognized; this is a slightly special case among transformer plugins, most of which operate via a distinct `.run()` step after parsing. We deliberately never added a compiler plugin, because we only ever needed the tree itself (`ast`), never a re-serialized string output — our three converters *are*, in effect, our own custom "compiler" stage, just operating outside `unified`'s own compiler-plugin mechanism.

---

## The Complete `mdast` Node Type Reference

Part 3A's Step 2 covered the node types our converters actually needed. Here is the **complete** table, including types that exist in the `mdast` specification but weren't used by GreyMatter MConvert — included here for completeness, since you may encounter them if you extend the parser (e.g., via `remark-math`, mentioned in Part 10's extension ideas).

### Root & Structural

| `type` | Meaning | Key fields |
|---|---|---|
| `root` | The whole document | `children` |
| `paragraph` | A block of normal text | `children` |
| `thematicBreak` | `---` horizontal rule | (leaf, no fields) |
| `blockquote` | `> quoted text` | `children` |

### Headings & Lists

| `type` | Meaning | Key fields |
|---|---|---|
| `heading` | `#` through `######` | `depth` (1–6), `children` |
| `list` | A `-`/`*`/`1.` list | `ordered`, `start`, `spread`, `children` |
| `listItem` | One entry in a list | `checked` (GFM), `spread`, `children` |

### Text & Inline Formatting

| `type` | Meaning | Key fields |
|---|---|---|
| `text` | Plain text content | `value` (leaf) |
| `strong` | `**bold**` | `children` |
| `emphasis` | `*italic*` | `children` |
| `delete` | `~~strikethrough~~` (GFM) | `children` |
| `inlineCode` | `` `code` `` | `value` (leaf) |
| `break` | Hard line break (two trailing spaces + newline) | (leaf, no fields) |

### Links & Media

| `type` | Meaning | Key fields |
|---|---|---|
| `link` | `[text](url)` | `url`, `title`, `children` |
| `linkReference` | `[text][ref]` (reference-style link) | `identifier`, `referenceType`, `children` |
| `definition` | `[ref]: url "title"` (the target a `linkReference` points to) | `identifier`, `url`, `title` (leaf) |
| `image` | `![alt](url)` | `url`, `alt`, `title` (leaf) |
| `imageReference` | `![alt][ref]` (reference-style image) | `identifier`, `referenceType`, `alt` (leaf) |

### Code

| `type` | Meaning | Key fields |
|---|---|---|
| `code` | Fenced/indented code block | `value`, `lang`, `meta` (leaf) |

### GFM Tables (require `remark-gfm`)

| `type` | Meaning | Key fields |
|---|---|---|
| `table` | The whole table | `align` (array of `"left" \| "right" \| "center" \| null`), `children` |
| `tableRow` | One row | `children` |
| `tableCell` | One cell | `children` |

### Frontmatter (requires an additional plugin, e.g. `remark-frontmatter`)

| `type` | Meaning | Key fields |
|---|---|---|
| `yaml` | A `---`-delimited YAML metadata block | `value` (leaf) |

### HTML Passthrough

| `type` | Meaning | Key fields |
|---|---|---|
| `html` | Raw HTML embedded directly in Markdown source | `value` (leaf) |

A note directly relevant to our project's security posture: our converters (Parts 5–7) never encountered `html` nodes needing special handling in our test documents, but it's worth knowing this node type exists — if a user pastes Markdown containing raw HTML tags, `remark-parse` will happily produce an `html` node containing that raw string verbatim. Since none of our three converters' `default` cases specifically handle `type === "html"`, it currently falls through to our existing graceful "warn and skip" fallback (Parts 5–8) — meaning raw embedded HTML is safely ignored in our exports, never accidentally executed or rendered as-is. This is a good, concrete example of Part 8's defensive design paying off in a scenario we didn't even explicitly design for.

---

## How `remark-gfm` Extends the Syntax, Specifically

`remark-gfm` (installed in Part 1B, used throughout) is itself a bundle of four smaller, more focused micromark extensions:

1. **Tables** — the `| col |` pipe syntax, producing `table`/`tableRow`/`tableCell` nodes.
2. **Strikethrough** — `~~text~~`, producing `delete` nodes.
3. **Task lists** — `- [x]`/`- [ ]`, adding the `checked` field to `listItem` nodes (this is the *only* GFM feature that modifies an *existing* node type's fields rather than introducing an entirely new node type).
4. **Autolinks** — bare URLs and email addresses (e.g., typing `https://example.com` directly, with no `[]()` wrapper) automatically becoming `link` nodes.

---

**Official documentation:** [unifiedjs.com](https://unifiedjs.com) is the ecosystem's central hub; the specific `mdast` specification (every node type's exact required/optional fields) lives at [github.com/syntax-tree/mdast](https://github.com/syntax-tree/mdast).
