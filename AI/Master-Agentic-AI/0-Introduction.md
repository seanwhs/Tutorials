# Part 0: Introduction — Welcome to the Agentic Engineering Track

## 0.1 The Problem With "Just Call the API"

Picture a vending machine. You put in a coin, press B4, and a bag of chips falls out. That's a **request-response** system — and it's exactly what 90% of "AI chatbot" tutorials teach you to build: send a prompt string, get a text string back, print it on a screen. It works great in a demo. It falls apart the moment someone asks a real question like *"Check my last three orders, compare them against the refund policy, and tell me if I qualify — but don't leak my email address into your logs while you do it."*

That single sentence requires:

- **Multiple steps of reasoning**, not one lookup (a *loop*, not a single call)
- **Memory** of what happened in step 1 when you get to step 3
- **Tools** to actually go fetch the orders and the policy (the model can't do that alone — it can only generate text)
- **Judgment** about whether the retrieved information is actually good enough to answer with, or whether it needs to try again
- **Security filtering** so the user's email doesn't get logged or forwarded somewhere it shouldn't
- **Resilience**, because if the AI provider's servers hiccup mid-request, the whole interaction shouldn't just die

None of that is "call the API and print the string." That is **software engineering built around a reasoning engine** — and that's what this entire series is about. We are going to build every one of those capabilities, piece by piece, by hand, in plain JavaScript, so that by the end you understand *exactly* what's happening under the hood of every "AI agent" framework you'll ever encounter professionally.

## 0.2 What This Series Actually Is

This is a **7-phase, code-first build course**. Each phase is a distinct engineering milestone. Each part inside a phase follows the exact same rhythm so you always know where you are:

1. **The Target** — the exact file or feature we're building this step
2. **The Concept** — a plain-English analogy explaining *why* this pattern exists, before you see a single line of code
3. **The Implementation** — the complete, runnable file. No `// TODO`, no `...rest of your code here`. If it's in the tutorial, you can paste it into your project and it will run.
4. **The Verification** — a terminal command, a `curl` request, or a browser check that *proves* the step works before you move forward

Deep-dive conceptual material (full library API surfaces, protocol theory, RFC-style detail) is **not** jammed into the middle of the build — it's collected into a **Reference Section** at the end of each phase, so the hands-on momentum never stalls.

By the very last part of Phase 7, you will have a single, running Next.js 16 application that is simultaneously:

- A **self-correcting reasoning agent** (Phase 1)
- With **persistent, budget-aware memory** across requests (Phase 2)
- That can **decide how and where to search** for information, including non-vector sources (Phase 3)
- That **sanitizes every input and validates every output** like an enterprise system should (Phase 4)
- Built on a **swappable, decoupled tool registry** instead of hardcoded API calls (Phase 5)
- Capable of **fanning work out to multiple specialist agents in parallel** (Phase 6)
- And wrapped in a **production-grade resilience layer** that survives rate limits, timeouts, and provider outages (Phase 7)

## 0.3 The Target Architecture — What You're Building Toward

Here is the system in its final form. Don't worry about understanding every box right now — treat this like the picture on the box of a jigsaw puzzle. You'll refer back to this diagram at the start of every phase to see exactly which piece you're placing.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         CLIENT (browser / curl / app)                    │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 │ HTTPS request
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  NEXT.JS 16 MIDDLEWARE (Phase 5)                                          │
│  - API key checks, rate-limit headers, request logging                   │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  GUARDRAIL GATEWAY  (Phase 4)                                             │
│  - Zod schema validation on the incoming body                            │
│  - PII regex redaction (emails, phones, IDs)                             │
│  - Jailbreak / prompt-injection pattern blocking                         │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  PROVIDER GATEWAY  (Phase 7)                                              │
│  - Tries Groq → falls back to Gemini → falls back to DeepSeek            │
│  - AbortController timeouts + exponential backoff retries                 │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  THE REACT AGENT LOOP  (Phase 1 core, upgraded every phase after)         │
│                                                                            │
│   ┌────────────┐   ┌───────────────┐   ┌────────────────┐               │
│   │  THINK      │──▶│  ACT (tool)   │──▶│  OBSERVE        │──┐           │
│   │ (reasoning) │   │  via MCP-style│   │ (tool result)   │  │           │
│   └────────────┘   │  registry     │   └────────────────┘  │           │
│         ▲            (Phase 5)                              │           │
│         └──────────────────────────────────────────────────-┘           │
│                     loops until goal met or max steps hit (Phase 1)      │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  STATE & MEMORY LAYER  (Phase 2)                                          │
│  - `use cache` for expensive static system prompts                       │
│  - Token-budget-aware history trimming                                   │
│  - Cross-request session state (serverless-safe)                         │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  RETRIEVAL LAYER  (Phase 3)                                               │
│  - Agentic RAG: rewrite → search → judge → retry                         │
│  - Vectorless search over JSON/KV/API sources                            │
│  - Vector search where it actually makes sense                          │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  MULTI-AGENT CASCADE  (Phase 6, invoked when a task fans out)             │
│   Architect Agent ─┐                                                     │
│   Security Agent ──┼── Promise.all() ──▶ Aggregator / Event Bus          │
│   Docs Agent ───────┘                                                    │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 ▼
                        FINAL VALIDATED JSON RESPONSE
                       (checked against a Zod schema)
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          CLIENT receives clean output                    │
└──────────────────────────────────────────────────────────────────────────┘
```

Notice the shape: **request flows down through layers of increasing trust and specialization, and every layer has one job.** That single idea — *small, single-responsibility layers wrapped around a reasoning core* — is the entire philosophy of agentic software engineering. Frameworks like LangChain, LlamaIndex, and various "agent SDKs" are just pre-built versions of the boxes in this diagram. You're going to build the boxes yourself first, so that later, if you ever adopt one of those frameworks, you'll know precisely what it's doing for you — and precisely what it's hiding from you.

## 0.4 Who This Course Is For (and Who It Isn't For)

**This course assumes you can:**
- Write basic JavaScript: functions, `async`/`await`, array methods (`.map`, `.filter`), destructuring
- Run terminal commands like `npm install` and `npm run dev`
- Read a JSON object and understand nested keys

**This course does *not* assume you know:**
- Any AI/ML background — every model concept (tokens, embeddings, temperature, context windows) is defined in plain English the first time it's used, with an analogy
- Next.js — we treat App Router, Route Handlers, Middleware, and the new async request APIs as brand new, and build up from first principles
- Any agent framework — we write the ReAct loop, the tool registry, and the memory system as raw JavaScript, no black boxes

**This is *not* the course for you if** you're looking for a "paste your OpenAI key and ship a SaaS in 20 minutes" tutorial. We are going the slow, structural route on purpose — because that structure is what survives contact with real users, real rate limits, and real security audits.

## 0.5 A Note on "Free-Tier Friendly" Engineering

A deliberate constraint of this course: **every provider we use has a genuinely usable free tier — **Groq** (extremely fast inference on `llama-3.3-70b`, great for tight ReAct loops where latency compounds with every reasoning step), **Google AI Studio** (`gemini-2.5-flash` via the `@google/genai` SDK, strong at structured JSON output), and **DeepSeek** (`deepseek-v4-flash`, OpenAI-SDK compatible, a good cost-effective fallback).

Here's the engineering reason this matters, beyond just "it's cheap": **a system designed to survive on a rate-limited free tier is, by definition, forced to handle failure gracefully.** If you build assuming infinite quota and a paid enterprise key, you'll never write retry logic, backoff, or provider failover — because you'll never *need* to, in development. Then it breaks in production the first time you hit a 429 (rate limit) response at 2 AM. By building against real free-tier limits from day one, resilience isn't an afterthought bolted on in Phase 7 — it's a forcing function baked into the architecture from the start. Phase 7 formalizes this into a proper **Unified Provider Gateway**, but you'll feel the *need* for it much earlier, and that's intentional.

## 0.6 Technical Stack — What's In the Toolbox and Why

| Layer | Choice | Why (in plain terms) |
|---|---|---|
| Framework | **Next.js 16 (App Router)** | Gives us serverless Route Handlers (an API endpoint is just a file), the new async `params`/`headers`/`cookies` APIs, Middleware, and the `use cache` directive — all in one project, no separate backend needed. |
| Runtime | **Node.js 22+** | Required for Next.js 16 and for native `fetch`/`AbortController` support without extra polyfills. |
| Validation | **Zod** | Think of Zod as a bouncer with a checklist at the door of a club — it checks that data has exactly the shape you expect *before* letting it into your system, and rejects anything malformed. We use it for both incoming request validation and for forcing the LLM's output into a predictable JSON shape. |
| AI Providers | **Groq SDK, `@google/genai`, OpenAI-compatible client for DeepSeek** | Three different vendors, three different SDKs, unified later behind one gateway interface — this is deliberate, so you learn to abstract over vendor differences instead of hard-coding to one company's API forever. |
| Everything else | **Plain JavaScript** | No LangChain, no LlamaIndex, no agent framework. You are building the framework. |

## 0.7 How to Use This Course (Read This Before You Start Coding)

Every phase in this series builds a **runnable increment** of the same single project — you are never asked to throw away code from a previous phase. Think of it like constructing a house: Phase 1 pours the foundation (the reasoning loop), Phase 2 puts in plumbing and wiring (state/memory), Phase 3 builds out the kitchen (retrieval), and so on. You could technically stop after any phase and have a working, demoable application — it just gets more capable and more production-hardened with each one.

A few ground rules that will save you frustration:

1. **Type the code, don't just read it.** Muscle memory matters more than it seems like it should when you're learning a new architectural pattern.
2. **Run every Verification step.** They exist specifically to catch the one typo that would otherwise cost you 40 minutes of confused debugging three steps later.
3. **Keep a `.env.local` file from the very first phase.** We will never hardcode an API key in a source file — not once, in seven phases. If you see a key typed directly into code anywhere in this series, something has gone wrong.
4. **Reference sections are optional on first pass.** If you're eager to keep building momentum, skip the end-of-phase Reference Section and come back to it later. Nothing in the main build strictly requires reading it first — it exists to deepen understanding, not gate progress.

## 0.8 Prerequisite Environment Check

Before we write a single file, let's confirm your machine is ready. Open your terminal.

**Verification — Node.js version:**
```bash
node -v
```
You need `v22.x.x` or higher. If you see something older (or a "command not found" error), install the latest LTS from [nodejs.org](https://nodejs.org) or via a version manager like `nvm` before continuing.

**Verification — npm version:**
```bash
npm -v
```
Anything `10.x` or higher is fine.

With that confirmed, we have a solid floor to build on.
