# Appendix A — ESM vs. CommonJS, in Depth

Node.js originally shipped with **CommonJS** (`require()`/`module.exports`), a module system Node invented in 2009, before JavaScript had one of its own. In 2015, JavaScript standardized **ES Modules** (`import`/`export`) as part of the language itself — now the default in browsers, Deno, Bun, and every actively maintained framework.

## Why This Distinction Matters Practically

**Static analysis.** `import`/`export` statements must appear at the top level with literal string paths, which lets tools (bundlers, tree-shakers, type checkers) analyze your dependency graph *without executing your code*. CommonJS's `require()` can be called conditionally or with a dynamic variable (`require(someVariable)`), which makes static analysis much harder — a tool genuinely cannot know what you're requiring until the code actually runs.

**Top-level `await`.** ESM permits `await` outside an `async function`, at module scope. This is why several verification snippets throughout this series (e.g., `await ingestCodebase(...)` directly inside a `-e` one-liner) worked without wrapping boilerplate — CommonJS doesn't allow this at all; you'd need an immediately-invoked async function wrapper every time.

**The `.js` extension quirk.** With `"moduleResolution": "NodeNext"` (set in Part 0's `tsconfig.json`), relative imports must include an explicit file extension, and that extension refers to the *compiled output*, not the source file you're editing. So `src/config.ts` is imported elsewhere as `./config.js`, even though the file on disk right now ends in `.ts`. This trips up nearly every developer the first time they see it. The underlying reason: Node's native ESM resolver (not TypeScript) is what actually resolves the import path at runtime, and by the time code runs, Node only ever sees the compiled `.js` files sitting in `dist/` — TypeScript is aware of this convention and deliberately does not rewrite the extension for you during compilation.

## Common Pitfalls and Their Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `ERR_REQUIRE_ESM` | A CommonJS `require()` call trying to load an ESM-only package | Convert the calling file to ESM (`import` instead of `require`), or use dynamic `import()` |
| `SyntaxError: Cannot use import statement outside a module` | `.js` file using `import` syntax without `"type": "module"` set in `package.json` | Confirm `package.json` has `"type": "module"` (Part 0, Step 2) |
| `ERR_MODULE_NOT_FOUND` | Relative import missing the `.js` extension, or `module`/`moduleResolution` mismatched in `tsconfig.json` | Always add `.js` to relative imports; keep `module` and `moduleResolution` both set to `NodeNext` (Part 0, Step 3) |
| A dependency only ships CommonJS but your project is ESM | Some older npm packages never migrated | Use `import pkg from "old-package"; const { thing } = pkg;` — ESM can still import CJS packages via a default-import interop, just not named exports directly |

## Why We Chose ESM for This Series

- It's the direction the entire JavaScript ecosystem has converged on since roughly 2020.
- Every dependency we installed across the series (`openai`, `zod`, `fast-glob`, `execa`, `typescript`) ships native ESM support.
- Top-level `await` made our verification one-liners throughout the series dramatically shorter and more copy-pasteable — a direct, practical payoff of the choice, not just a theoretical one.

The trade-off — that one extension quirk — is a small, one-time cost for a project that otherwise behaves consistently with modern JavaScript tooling for its entire lifetime.
