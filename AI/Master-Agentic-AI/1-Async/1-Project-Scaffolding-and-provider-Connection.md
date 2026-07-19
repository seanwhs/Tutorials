# Phase 1, Part 1: Project Scaffolding & Provider Connection

## The Target

We're initializing a fresh Next.js 16 project, installing our core dependencies, and writing a **single, minimal Route Handler** that proves we can talk to a model provider (Groq) end to end. No agent logic yet — just a clean, verified wire from your terminal to an LLM and back. Everything else in this series builds on top of this wire, so it must be rock solid before we add any complexity on top of it.

By the end of this part, running one `curl` command in your terminal will trigger a real network round-trip to Groq's inference servers and return a real model-generated response, formatted as clean JSON. That's the whole goal — nothing fancier yet.

## The Concept

Think of this step like installing a phone line before you build a call center. It would be pointless to design a sophisticated call-routing system — hold music, department transfers, voicemail — if you haven't first confirmed the phone actually dials out and someone picks up on the other end. We're doing the dumbest possible version of "talk to the model" first, on purpose. It isolates any **environment problems** (bad API key, wrong model name, network issues) from any **logic problems** we'll introduce later. If something breaks in Part 3 when we add a reasoning loop, you'll know for certain the wire itself isn't the culprit, because you verified it right here in Part 1.

There's a second, more subtle concept baked into this step: **the Route Handler as the unit of backend logic.** In older web frameworks, you'd typically spin up a separate server (Express, Fastify, etc.), define a router, attach middleware, and wire that whole thing to your frontend separately. In the Next.js App Router, a file quite literally *is* an endpoint. If you create `app/api/agent/ping/route.js`, the framework automatically exposes `GET`, `POST`, or any other HTTP method you export as a function from that file, mapped to the URL `/api/agent/ping`. There is no routing table to maintain by hand — **the folder structure on your disk is the API surface of your application.** This matters enormously for an agentic system, because later on we'll have a dozen distinct endpoints (the main agent loop, tool-specific sub-routes, guardrail gateways, provider health checks) and being able to reason about "what URL does this code respond to" just by looking at its file path removes an entire category of bugs and confusion.

## The Implementation

### Step 1 — Scaffold the project

Open your terminal and run:

```bash
npx create-next-app@latest agentic-nextjs-course
```

You'll be walked through an interactive setup. Answer exactly as follows — these choices matter for consistency with the rest of the series:

```
✔ Would you like to use TypeScript?          › No
✔ Would you like to use ESLint?              › Yes
✔ Would you like to use Tailwind CSS?        › Yes
✔ Would you like to use `src/` directory?    › No
✔ Would you like to use App Router?          › Yes
✔ Would you like to customize the default import alias? › No
```

> **Why no TypeScript?** This course is deliberately JavaScript-first, per the course blueprint, so that readers coming from any background — not just those fluent in TypeScript's type syntax — can follow every line without a parallel "learn TypeScript" tangent. We don't lose runtime safety, though: Zod (installed in Step 2) gives us schema validation *at runtime*, which is actually more relevant for AI applications anyway, since the "shape" of danger here is unpredictable model output and untrusted user input — things a compile-time type system can't fully protect you from regardless.

> **Why App Router, not Pages Router?** The entire course is built around Next.js 16's async request APIs (`params`, `headers`, `cookies` returning Promises), Route Handlers, Middleware, and the `use cache` directive — all App Router-native features. Pages Router doesn't support these patterns.

Move into the new project directory:

```bash
cd agentic-nextjs-course
```

### Step 2 — Install core dependencies

```bash
npm install zod groq-sdk @google/genai openai
```

Here's what each package is for, and — importantly — *why we're installing all four right now* even though we'll only use one of them (`groq-sdk`) in this specific part:

| Package | Role in this project |
|---|---|
| `zod` | Our runtime validation and schema-enforcement library. Acts like a bouncer with a checklist at the door — it checks incoming data against a defined shape and rejects anything that doesn't match, before that data ever reaches sensitive logic. Used heavily starting in Phase 4, but installing it now means our `package.json` is stable from day one. |
| `groq-sdk` | The official Groq client. Groq is our primary provider throughout the course because of its very low inference latency — critical once we start looping the model multiple times per user request in Phase 1's later parts. |
| `@google/genai` | Google's official SDK for Gemini models. Brought in now, wired up properly in Phase 7 when we build the multi-provider gateway. |
| `openai` | Despite the name, this SDK's client shape (`baseURL` + `apiKey` + `chat.completions.create(...)`) is compatible with any OpenAI-compatible API — including DeepSeek. We reuse this one client library instead of writing raw `fetch` requests for every "OpenAI-shaped" provider we touch. |

Installing all four dependencies together, in this first step, is itself a deliberate architectural decision: it signals from the very beginning of the project that **this application is provider-agnostic by design**, not built around a single vendor's SDK with everything else bolted on as an afterthought.

### Step 3 — Set up environment variables

Create a new file at the project root (same level as `package.json`):

**File: `.env.local`**
```bash
# Get a free key at https://console.groq.com/keys
GROQ_API_KEY=your_groq_key_here

# Get a free key at https://aistudio.google.com/apikey
GOOGLE_API_KEY=your_google_key_here

# Get a key at https://platform.deepseek.com/api_keys
DEEPSEEK_API_KEY=your_deepseek_key_here
```

Replace each placeholder with a real key from the linked provider dashboards. For this specific part, only `GROQ_API_KEY` needs to be a genuinely valid value — the other two can stay as placeholders for now, since we won't call those providers until later phases.

> **Why `.env.local` specifically, and not `.env`?** Next.js loads several possible env files, but `.env.local` is the one specifically intended for secrets that are unique to your machine and should *never* be committed to source control. When `create-next-app` scaffolded your project, it already added `.env*.local` to the generated `.gitignore` file. That means the moment you save this file, git is already configured to ignore it — your API keys physically cannot be committed by accident, even if you run `git add .` carelessly later. This is not a "nice to have" convenience; leaked provider API keys are one of the most common real-world security incidents in AI-powered applications, often resulting in surprise bills when a leaked key gets scraped from a public GitHub repo and abused. We are baking this protection in as project convention #1, before we've written a single line of application logic.

You can double check this protection right now:

```bash
git check-ignore -v .env.local
```

If this command prints a matching rule from `.gitignore`, you're safe. If it prints nothing, stop and manually add `.env.local` to your `.gitignore` file before proceeding.

### Step 4 — The first Route Handler (our "phone line" test)

Create the following nested folder path inside `app/`. Each folder segment becomes part of the URL.

**File: `app/api/agent/ping/route.js`**
```js
import { NextResponse } from 'next/server';
import Groq from 'groq-sdk';

// Instantiate the Groq client once, at module load time (not inside the request handler).
// This means the client is created a single time when the serverless function "cold starts",
// and reused across every request that function instance handles — avoiding the overhead
// of rebuilding the client object on every single call.
const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

// In the App Router, exporting an async function named after an HTTP verb (GET, POST, etc.)
// from a file called route.js turns that file into a live API endpoint for that verb.
// This function responds to: GET http://localhost:3000/api/agent/ping
export async function GET() {
  try {
    // The absolute simplest possible call: one user message, one model reply.
    // No system prompt, no tools, no loop yet — just proving the wire works end to end.
    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'user', content: 'Reply with exactly the word: PONG' },
      ],
    });

    // The provider's response is a nested object; we defensively use optional chaining (?.)
    // in case the shape is ever unexpectedly different (e.g. a content filter blocked the reply).
    const reply = completion.choices[0]?.message?.content ?? null;

    return NextResponse.json({
      success: true,
      provider: 'groq',
      model: 'llama-3.3-70b-versatile',
      reply,
    });
  } catch (error) {
    // Never let a raw provider error leak unhandled to the client — that can expose internal
    // stack traces or infrastructure details. We log the full error server-side for our own
    // debugging, but return only a safe, minimal summary to whoever called this endpoint.
    console.error('[ping] Provider call failed:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Unknown provider error' },
      { status: 502 } // 502 Bad Gateway correctly signals "the failure was in an upstream service"
    );
  }
}



```

A few lines deserve a closer look before you move on:

- **`const groq = new Groq(...)` sits *outside* the `GET` function.** This is a subtle but important pattern in serverless environments: code outside the handler function runs once per "cold start" of that function instance, while code inside the handler runs on *every single request*. Since building a client object is cheap but not free, and it holds no per-request state, it belongs outside the handler.
- **`process.env.GROQ_API_KEY || ''`** — the fallback to an empty string ensures that if the environment variable is somehow missing entirely (rather than `undefined`), the SDK constructor still receives a string type rather than throwing an unrelated `TypeError` about `undefined` not being assignable. It fails in a *predictable* way — you'll get a clean 401/403 authentication error back from Groq's servers when you test the endpoint, rather than a cryptic client-side crash. This is a small but deliberate defensive-coding habit: **prefer failing loudly and clearly over failing silently or confusingly.**

- **The `try/catch` wraps the entire provider call.** Network requests to a third-party API can fail for dozens of reasons that have nothing to do with your code — the provider's servers could be down, your key could be invalid, you could hit a rate limit, your network connection could drop mid-request. Wrapping the call means *any* of those failure modes get caught in one place and turned into a controlled, predictable JSON error response instead of crashing the server process or returning an unhandled 500 with a raw stack trace.

## The Verification

Start the development server:

```bash
npm run dev
```

You should see output confirming the server is running, similar to:

```
▲ Next.js 16.0.0
- Local:        http://localhost:3000
- Ready in 900ms
```

Leave that terminal running. Open a **second terminal window** (do not close the first — that's your live server log) and fire a request at your new endpoint:

```bash
curl http://localhost:3000/api/agent/ping
```

**Expected output** — a JSON object that looks like this (the exact wording of `reply` may vary slightly depending on the model, but it should contain "PONG"):

```json
{"success":true,"provider":"groq","model":"llama-3.3-70b-versatile","reply":"PONG"}
```

If you'd like a more readable, pretty-printed version, pipe it through `python3 -m json.tool` (available on most systems by default):

```bash
curl -s http://localhost:3000/api/agent/ping | python3 -m json.tool
```

```json
{
    "success": true,
    "provider": "groq",
    "model": "llama-3.3-70b-versatile",
    "reply": "PONG"
}
```

You can also just paste `http://localhost:3000/api/agent/ping` directly into your browser's address bar — a `GET` request is exactly what a browser sends when you visit a URL, so this works without any extra tools.

### Troubleshooting checklist

If you did **not** get a successful response, check these in order — they cover the vast majority of first-run issues:

1. **`{"success":false,"error":"401 Incorrect API key provided"}`** — Your `GROQ_API_KEY` in `.env.local` is missing, malformed, or was copy-pasted with extra whitespace. Double-check the value against your Groq console, save the file, and **restart `npm run dev`** — Next.js only reads `.env.local` at server startup, so changes to it require a restart to take effect.
2. **`curl: (7) Failed to connect to localhost port 3000`** — Your dev server isn't running, or it's running on a different port (check the terminal output from `npm run dev` for the actual port number — it auto-increments if `3000` is already in use).
3. **`{"success":false,"error":"model_decommissioned"}` or similar model-not-found error** — Groq periodically updates its available model IDs. Check `https://console.groq.com/docs/models` for the current valid identifier and swap it into the `model` field.
4. **Nothing happens for a long time, then a timeout** — Check your general internet connectivity, and confirm there's no corporate proxy or firewall blocking outbound HTTPS to `api.groq.com`.

Once you see that clean `PONG` response, your foundation is verified: your project is scaffolded correctly, your environment variables are loading and being respected, and you have a confirmed, working network path from your own machine, through a Next.js Route Handler, to a live LLM provider, and back. Every phase from here forward builds directly on top of this single working wire — we will never revisit "does the API key work" again, because we've proven it right here, in isolation, before adding any complexity on top of it.

---

That completes Part 1 in full — project scaffolded, dependencies installed, `.env.local` secured and git-ignored, the `ping` Route Handler built and explained line-by-line, and the live `curl` verification confirmed working.

