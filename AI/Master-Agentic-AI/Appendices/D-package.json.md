# Appendix D: Final `package.json`

This is the complete, final dependency manifest for the project as it stands after all seven phases. If you've followed the series from Part 1 through Phase 7 exactly as written, your own `package.json` should match this almost exactly — the only differences you should expect are patch-version bumps depending on exactly when you ran each `npm install`.

## The Complete File

**File: `package.json`**
```json
{
  "name": "agentic-nextjs-course",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint"
  },
  "dependencies": {
    "@google/genai": "^1.0.0",
    "groq-sdk": "^0.9.0",
    "next": "^16.0.0",
    "openai": "^4.70.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^16.0.0",
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0"
  }
}
```

> **A note on version pinning:** the versions shown above (`^16.0.0`, `^3.23.0`, etc.) reflect what was current at the time this course was written. Because every dependency uses a caret (`^`) range, running a fresh `npm install` today will likely pull in newer patch and minor versions automatically. This is generally safe for this project — nothing in the course relies on obscure, version-specific SDK behavior — but if you ever hit an unexpected breaking change, running `npm ls <package-name>` will show you exactly which version you have installed, which you can compare against that package's changelog.

## Dependency-by-Dependency Reference

| Package | Category | Introduced in | What it's used for |
|---|---|---|---|
| `next` | Framework | Phase 1, Part 1 | The entire application — App Router, Route Handlers, Middleware, `use cache`, async `cookies()`/`headers()` |
| `react`, `react-dom` | Framework peer deps | Phase 1, Part 1 | Required by Next.js itself; this course never actually builds any UI components, since every deliverable is an API route, but these are mandatory peer dependencies of any Next.js project |
| `zod` | Validation | Phase 1, Part 1 (installed) → first used Phase 4 | Runtime schema validation for request bodies and, critically, LLM-generated structured output (Phases 4, 6) |
| `groq-sdk` | AI Provider | Phase 1, Part 1 | Primary/preferred model provider client — powers `llama-3.3-70b-versatile` calls throughout the entire series until abstracted behind the Phase 7 gateway |
| `@google/genai` | AI Provider | Phase 1, Part 1 (installed) → first used Phase 7, Part 3 | Google Gemini client — the second provider in the Phase 7 failover chain, via `geminiAdapter.js` |
| `openai` | AI Provider | Phase 1, Part 1 (installed) → first used Phase 7, Part 3 | Reused (despite its name) as a generic OpenAI-compatible client for DeepSeek — the third/final provider in the failover chain |
| `eslint`, `eslint-config-next` | Dev tooling | Scaffolded by `create-next-app` | Code linting; not directly exercised by the tutorial content but present from initial project setup |
| `tailwindcss`, `postcss`, `autoprefixer` | Dev tooling | Scaffolded by `create-next-app` | Styling infrastructure; since this course never builds UI, these are present but effectively unused — see the note below |

## An Honest Note on Unused Dependencies

If you scaffolded your project exactly as instructed in Phase 1, Part 1, you answered "Yes" to Tailwind CSS during `create-next-app`'s setup prompts. Worth being upfront about this: **this entire course never actually builds a single page or UI component.** Every deliverable across all seven phases is a backend API route under `app/api/agent/`. This means Tailwind, PostCSS, and the default `app/page.js`/`app/layout.js` files that `create-next-app` generates are present in your project but genuinely untouched by anything in this series.

This was a deliberate scope decision, not an oversight — the course is about agentic *backend* architecture, and adding a frontend would have doubled the surface area without reinforcing any of the core lessons. If you want to actually interact with your finished system through a browser rather than `curl`, building a simple chat UI in `app/page.js` that calls `POST /api/agent/chat` is a natural, self-directed next step — and everything you need to build that call (the exact request/response shape) is fully documented in Appendix C.

## Reproducing This Environment From Scratch

If you ever need to rebuild this exact project on a new machine without walking through every phase's `npm install` step individually, the complete dependency set can be installed in one shot:

```bash
npx create-next-app@latest agentic-nextjs-course
# Answer the setup prompts exactly as specified in Phase 1, Part 1:
# TypeScript: No | ESLint: Yes | Tailwind: Yes | src/ dir: No | App Router: Yes | Import alias: No

cd agentic-nextjs-course
npm install zod groq-sdk @google/genai openai
```

That single `npm install` line is identical to the one run back in Phase 1, Part 1 — worth noting that **no additional npm packages were introduced at any point across the remaining six phases.** Every capability built from Phase 2 onward — caching, sessions, retrieval, guardrails, the tool registry, multi-agent orchestration, resilience patterns — was implemented using only these four packages plus native JavaScript and Web APIs (`fetch`, `AbortController`, `crypto.randomUUID()`) already built into Node.js 22+. This is worth sitting with for a moment: the entire, seven-phase, enterprise-grade agentic architecture in this course was built on a dependency footprint of exactly four third-party packages.

---

**[GENERATED: Appendix D — Final `package.json`]**

Ready for **Appendix E: Master Glossary** whenever you'd like it.
