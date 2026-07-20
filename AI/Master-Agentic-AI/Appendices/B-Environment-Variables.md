# Appendix B: Master Environment Variables Reference

Across the seven phases, environment variables were introduced piecemeal — one or two at a time, exactly when a new capability needed them. That's the right way to *learn* them, but it makes for a scattered reference when you're setting up a fresh copy of the project or auditing a deployment. This appendix consolidates every single environment variable used anywhere in the series into one place.

## The Complete `.env.local` File

Here is what your final, complete `.env.local` should contain, with every variable from all seven phases present at once:

**File: `.env.local`**
```bash
# ─────────────────────────────────────────────────────────────
# AI PROVIDER KEYS (Phase 1, Part 1 — expanded in Phase 7, Part 3)
# ─────────────────────────────────────────────────────────────

# Groq — primary/preferred provider (fastest inference, first in the
# Phase 7 provider gateway chain). Get a free key at:
# https://console.groq.com/keys
GROQ_API_KEY=your_groq_key_here

# Google AI Studio — second provider in the failover chain (Phase 7).
# Used by lib/agent/providers/geminiAdapter.js. Get a free key at:
# https://aistudio.google.com/apikey
GOOGLE_API_KEY=your_google_key_here

# DeepSeek — third/final provider in the failover chain (Phase 7).
# Used by lib/agent/providers/deepseekAdapter.js. Get a key at:
# https://platform.deepseek.com/api_keys
DEEPSEEK_API_KEY=your_deepseek_key_here


# ─────────────────────────────────────────────────────────────
# APPLICATION SECURITY (Phase 5, Part 3)
# ─────────────────────────────────────────────────────────────

# Shared secret required in the "x-api-key" header on every request to
# /api/agent/*. Enforced globally by middleware.js BEFORE any route
# handler runs. Change this to a genuinely random, long secret before
# any real deployment — the placeholder value below is for local
# development only and appears throughout this course's curl examples.
AGENT_API_KEY=demo-secret-key-change-me-in-production


# ─────────────────────────────────────────────────────────────
# TOOL REGISTRY CONFIGURATION (Phase 5, Part 2)
# ─────────────────────────────────────────────────────────────

# Set to "true" to disable registration of write-action tools (currently:
# cancelOrder) at server startup. When disabled, the tool is fully absent
# from the registry — it won't appear in the system prompt and cannot be
# invoked, rather than merely being blocked at execution time. Useful for
# gating destructive actions out of certain environments (e.g. a public
# demo deployment) without touching any application code.
DISABLE_WRITE_TOOLS=false
```

## Reference Table: Every Variable, Where It's Used, and What Breaks Without It

| Variable | Introduced in | Consumed by | Failure mode if missing/invalid |
|---|---|---|---|
| `GROQ_API_KEY` | Phase 1, Part 1 | `lib/agent/providers/groqAdapter.js` | Groq calls fail with a `401`; Phase 7's gateway automatically fails over to Gemini/DeepSeek. Before Phase 7, this was a hard failure with no fallback. |
| `GOOGLE_API_KEY` | Phase 7, Part 3 (though referenced as a placeholder from Phase 1) | `lib/agent/providers/geminiAdapter.js` | Gemini calls fail; the gateway skips to DeepSeek. If this is the *only* working key and Groq/DeepSeek are also down, the whole gateway throws `"All configured providers failed..."` |
| `DEEPSEEK_API_KEY` | Phase 7, Part 3 (placeholder from Phase 1) | `lib/agent/providers/deepseekAdapter.js` | Same failure pattern as above — this is the last provider in the chain, so if this fails too, the entire request falls through to the fallback-answer path with an honest failure. |
| `AGENT_API_KEY` | Phase 5, Part 3 | `middleware.js` | If unset entirely: **every single request is blocked** with a `500` server-misconfiguration error (fail-closed by design — see Phase 5's Reference Section). If set but the client sends the wrong value: `401 Unauthorized`. |
| `DISABLE_WRITE_TOOLS` | Phase 5, Part 2 | `lib/agent/mcp/registry.js` | If unset, defaults to falsy (`process.env.DISABLE_WRITE_TOOLS === 'true'` evaluates `false` for `undefined`), meaning write tools are **enabled by default** unless explicitly set to `"true"`. Worth double-checking this default matches your intended deployment posture. |

## Two Important Behavioral Notes

**1. `.env.local` changes require a server restart.** This was flagged back in Phase 1's troubleshooting checklist and is worth restating here since it applies to *every* variable in this table: Next.js reads environment files at server startup, not on every request. If you edit any value in `.env.local` — rotating a key, flipping `DISABLE_WRITE_TOOLS`, changing `AGENT_API_KEY` — you must stop and restart `npm run dev` (or redeploy, in production) before the change takes effect. This is the single most common "why isn't my change working" issue across the whole series.

**2. Every variable here is read server-side only.** None of these are prefixed with `NEXT_PUBLIC_`, which is the Next.js convention for exposing an environment variable to browser-side JavaScript. This is entirely intentional — every one of these values (API keys, the internal auth secret) is a genuine secret that must never reach the client bundle. If you ever find yourself tempted to add `NEXT_PUBLIC_` to any variable in this table, stop and reconsider the design — none of them have a legitimate reason to be visible in a browser.

## Verifying Your Environment Is Correctly Configured

A quick end-to-end check that all five variables are wired up correctly, run in order:

```bash
# 1. Confirm .env.local is git-ignored (Phase 1)
git check-ignore -v .env.local

# 2. Confirm the server boots without the AGENT_API_KEY fail-closed error (Phase 5)
npm run dev
# — watch the terminal for "[middleware] AGENT_API_KEY is not configured" — should NOT appear

# 3. Confirm Groq connectivity (Phase 1)
curl -s -H "x-api-key: demo-secret-key-change-me-in-production" \
  http://localhost:3000/api/agent/ping | python3 -m json.tool

# 4. Confirm the full provider chain is healthy (Phase 7)
curl -s -H "x-api-key: demo-secret-key-change-me-in-production" \
  http://localhost:3000/api/agent/gateway-status | python3 -m json.tool
# — expect an empty or all-"isOpen": false circuitStatus object on a fresh server start

# 5. Confirm write-action tool gating matches your intent (Phase 5)
curl -s -H "x-api-key: demo-secret-key-change-me-in-production" \
  http://localhost:3000/api/agent/registry-test | python3 -m json.tool
# — check whether "cancelOrder" appears in allTools, matching your DISABLE_WRITE_TOOLS setting
```

If all five checks pass, every environment variable introduced across the entire series is correctly configured and actively being used by the system exactly as intended.
