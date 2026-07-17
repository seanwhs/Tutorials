# Appendix E — The TypeScript Compiler API and AST Parsing, in Depth

Part 4 used the TypeScript Compiler API to chunk code along declaration boundaries, with a brief explanation of what an AST is. This appendix goes deeper into how that parsing actually works internally, and how to extend it for node types and languages beyond what we covered.

## What `ts.createSourceFile` Actually Does

When you call:

```typescript
const sourceFile = ts.createSourceFile(sourcePath, content, ts.ScriptTarget.Latest, true);
```

TypeScript runs its full **lexer and parser** — the exact same code path that runs every time you save a `.ts` file in VS Code and get instant error squiggles. The lexer first breaks the raw text into **tokens** (the smallest meaningful units — `import`, `{`, an identifier name, `;`, etc.), and the parser then assembles those tokens into a tree structure according to TypeScript's grammar rules, where each node knows its own type (`FunctionDeclaration`, `ImportDeclaration`, `VariableStatement`, etc.) and holds references to its child nodes.

The fourth argument, `setParentNodes: true`, matters specifically because it makes each node aware of its parent in the tree, which is required for `node.getFullText(sourceFile)` to work correctly — without it, some position-based text extraction methods either fail or require passing extra context manually.

## Why We Walked Only Top-Level Children

```typescript
ts.forEachChild(sourceFile, (node) => { ... });
```

`forEachChild` visits only the *direct* children of whatever node you call it on — for a `SourceFile`, that means only top-level statements (imports, top-level function/class/interface declarations, top-level consts), not anything nested inside them. This was a deliberate chunking granularity decision: we treat an entire function as one atomic chunk, regardless of how many nested `if` statements or inner arrow functions it contains. Had we recursively walked into every nested node instead, we'd fragment a single function into many tiny, less-useful chunks — reintroducing a milder version of Part 3's "cuts off mid-thought" problem, just at a different structural level.

## Extending `isChunkableNode` for Real Codebases

Our `isChunkableNode` function checked for five node kinds:

```typescript
ts.isFunctionDeclaration(node) ||
ts.isClassDeclaration(node) ||
ts.isInterfaceDeclaration(node) ||
ts.isTypeAliasDeclaration(node) ||
ts.isVariableStatement(node)
```

Real-world TypeScript/JavaScript codebases commonly use patterns this list doesn't yet cover. Extending it for production use would likely add:

| Node type check | Catches |
|---|---|
| `ts.isExportAssignment(node)` | `export default ...` statements |
| `ts.isEnumDeclaration(node)` | `enum` declarations |
| `ts.isModuleDeclaration(node)` | `namespace`/`module` blocks |
| Checking inside `VariableStatement` for `ArrowFunction` initializers | `const handler = async (req, res) => { ... }` — a very common pattern that our current check treats as one chunk correctly, but is worth testing explicitly since arrow functions assigned to consts are ubiquitous in modern codebases |

## Adapting This Pattern to Non-TypeScript Languages

The TypeScript Compiler API only parses TypeScript/JavaScript. For a multi-language codebase (Python, Go, Rust files alongside TS), the direct equivalent is **tree-sitter** — a parser-generator library with pre-built grammars for dozens of languages, widely used in editors like Neovim and in tools like GitHub's code search for exactly this kind of structural parsing. The conceptual pattern from Part 4 transfers directly: parse into a tree, walk top-level nodes, chunk along whole-declaration boundaries, and attach each file's import/dependency statements to every resulting chunk. Only the specific parsing library changes; the chunking *strategy* — the actual lesson of Part 4 — remains identical.

## Why Attaching Imports to Every Chunk Is a Deliberate Trade-off, Not a Free Win

Recall from Part 4's verification output that every chunk carried the full import block, even a one-line `const users: User[] = []` chunk that doesn't use any imported function directly. This has a real cost: it multiplies token usage per chunk by however many import lines the file has. For a file with 20 imports and 15 small functions, that's a meaningful overhead multiplied across every retrieved chunk.

A more refined version — worth considering for a real production system beyond what this series builds — would perform **import-usage analysis**: parse each chunk's identifiers, cross-reference them against the file's import bindings, and attach only the imports actually referenced within that specific chunk. This is a more precise fix than "attach everything," at the cost of noticeably more implementation complexity (you'd need to walk each chunk's own sub-tree looking for identifier references, then match them against import specifiers). We chose the simpler "attach everything" version deliberately for this series because it's honest, correct, and teachable in a single part — but it's worth knowing the more surgical alternative exists once token cost from import duplication becomes measurable in your own eval suite (Part 8) or billing dashboard.
