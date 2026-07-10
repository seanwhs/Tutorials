# Appendix A: The Architect's Toolkit (Free & Open-Source Reference)

This appendix consolidates every free tool referenced across the series into one reference, with setup notes and when to reach for each.

## 1. Diagramming — C4 Model & Architecture Visualization

| Tool | License | Best for | Setup |
|---|---|---|---|
| **Mermaid** (mermaid.js.org) | MIT | C4 diagrams, sequence diagrams, ERDs — renders natively in GitHub, GitLab, VS Code, Obsidian | No install needed for viewing; `npm install -g @mermaid-js/mermaid-cli` for CLI rendering to PNG/SVG |
| **PlantUML** (plantuml.com) | GPL/free | More mature C4 support via `C4-PlantUML` include library; sequence/component/deployment diagrams | Requires Java + Graphviz locally, or use the free public rendering server |
| **Structurizr Lite** (structurizr.com) | Free (self-hosted, Docker) | Purpose-built C4 modeling tool by Simon Brown (C4 creator); Structurizr DSL is the most expressive free C4 language | `docker run -p 8080:8080 -v /path/to/workspace:/usr/local/structurizr structurizr/lite` |
| **Excalidraw** (excalidraw.com) | MIT, OSS | Informal whiteboard-style sketches, brainstorming before formalizing into C4 | Runs in-browser, free, no account required; self-hostable |
| **draw.io / diagrams.net** | Apache 2.0 | General-purpose diagramming, flowcharts, ER diagrams | Free web app or Desktop app, no account required |

**Recommended workflow used throughout this series:** sketch informally in Excalidraw during initial design discussions → formalize as Mermaid C4 diagrams committed to `docs/c4-diagrams/` once the design stabilizes → optionally upgrade to Structurizr DSL if the model grows complex enough to need multiple views (context/container/component) generated from one source model.

### Example Structurizr DSL (for reference — more expressive than Mermaid for large systems)

```
workspace {
  model {
    customer = person "Customer"
    northwind = softwareSystem "Northwind Orders Platform" {
      webapp = container "Web Application" "Next.js 16"
      db = container "Database" "SQLite/Postgres"
    }
    paymentGw = softwareSystem "Payment Gateway" "External"

    customer -> webapp "Places orders via"
    webapp -> db "Reads/writes"
    webapp -> paymentGw "Charges cards via API"
  }

  views {
    systemContext northwind {
      include *
      autoLayout
    }
    container northwind {
      include *
      autoLayout
    }
  }
}
```

## 2. ADR Tooling

| Tool | License | What it does |
|---|---|---|
| **adr-tools** (npmjs.com/package/adr-tools or the original Bash version) | MIT | `adr new "Title"` scaffolds a sequentially-numbered ADR file from a template automatically |
| **log4brains** (github.com/thomvaill/log4brains) | MIT | Generates a browsable, searchable static site from `docs/adr/`, deployable free on GitHub Pages; also has a `log4brains new` interactive CLI |
| **Plain Markdown + grep/ripgrep** | Free (built-in) | Zero-dependency fallback — always works, use full text search or `git log --follow` on ADR files to trace history |

## 3. API Documentation & Contract Tooling

| Tool | License | Use |
|---|---|---|
| **OpenAPI/Swagger** (spec + swagger-ui, both OSS) | Apache 2.0 | Documenting REST endpoints (Part 6); `swagger-ui` renders interactive docs for free, self-hosted |
| **Zod** (already used in this series' Next.js/React tutorials) | MIT | Runtime schema validation that doubles as living documentation for DTOs |
| **tRPC** (trpc.io) | MIT | Free, OSS alternative to REST for internal RPC-style APIs with full TypeScript inference end-to-end |

## 4. Testing & Quality Tooling (Free Tier Applicable to This Series)

| Tool | License | Use |
|---|---|---|
| **Vitest** | MIT | Fast unit testing for `core/` domain and application layers — since core has zero framework dependencies, tests run instantly with no DOM/browser needed |
| **Playwright** | Apache 2.0 | Free E2E testing across the full Next.js stack |
| **madge** (npmjs.com/package/madge) | MIT | Generates a dependency graph of your actual codebase — use it to *verify* the Dependency Rule from Part 1 is actually being respected (no accidental `core/` → `infrastructure/` imports) |

```bash
# Verify the Dependency Rule programmatically — run in CI
npx madge --circular --extensions ts,tsx ./core
npx madge --image core-deps.svg ./core
```

## 5. Rate Limiting & Cross-Cutting Concerns (Free/OSS, No Paid SaaS)

- **In-memory token bucket** (as sketched in Part 6) — zero dependencies, fine for single-instance or Modular Monolith deployments
- **Upstash Redis free tier** or **self-hosted Redis** — for multi-instance rate limiting once horizontally scaled
- **jose** (npmjs.com/package/jose, MIT) — free JWT verification library, avoids needing a paid auth SaaS for the PoC-level auth check shown in Part 6's middleware

## 6. Summary Decision Table: Which Tool When

| Task | Reach for |
|---|---|
| Quick sketch during a design meeting | Excalidraw |
| Committed diagram-as-code in the repo | Mermaid (simple) or PlantUML/C4-PlantUML (richer) |
| Multi-view model of a growing system | Structurizr Lite + DSL |
| Recording a significant decision | Markdown ADR + adr-tools or log4brains |
| Verifying architecture boundaries are respected | madge dependency graph in CI |
| Documenting a public REST contract | OpenAPI/Swagger |
| Internal, strongly-typed action API | tRPC or plain Server Actions (per Part 6) |

Every tool listed here is free for the usage patterns described in this series — no paid tier is required to complete any exercise.

---

