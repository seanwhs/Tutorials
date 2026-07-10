# Part 2: The Tool Use Pattern

**Series:** Building Agentic Workflows: Mastering the Anthropic Suite
**Prerequisite:** Part 1 (client singleton, model registry, basic Route Handler).

## Concept Explanation

Tool Use ("function calling") is what turns Claude from a text generator into an **orchestrator**. You describe available functions as JSON Schemas; Claude decides, based on the conversation, whether to call one, which one, and with what arguments. Claude never executes code itself — your server executes the tool and returns the result, and Claude incorporates it into the next turn.

This is a **loop**, not a single call:

1. Send messages + tool definitions to Claude.
2. If `stop_reason === "tool_use"`, extract the tool call(s) from `response.content`.
3. Execute the corresponding function(s) in your own code.
4. Append a `tool_result` message with the output.
5. Send the updated message list back to Claude.
6. Repeat until `stop_reason === "end_turn"`.

### Architecture implications

- **Latency compounds.** Each loop iteration is a full round trip. A 3-tool-call workflow is at minimum 4 sequential API calls unless you use **parallel tool calls** (Claude can request multiple tools in one turn — execute them concurrently with `Promise.all`).
- **Trust boundary.** Claude's tool *arguments* are model output, not user input, but they still originate from an LLM — always validate them (Zod, Part 3) before touching a database or external API. Never string-interpolate them into raw SQL.
- **Tool descriptions ARE prompts.** The `description` field on each tool is prompt-engineering surface area. Vague descriptions cause wrong or missed tool calls. Be as precise as you would in a system prompt.

## Implementation

### Step 1 — Define the tool schemas (JSON Schema, hand-written for now; Part 3 shows Zod-generated schemas)

`src/lib/anthropic/tools/registry.ts`

```ts
import type Anthropic from "@anthropic-ai/sdk";

export const getUserByEmailTool: Anthropic.Tool = {
  name: "get_user_by_email",
  description:
    "Look up a single user account by their exact email address in the application database. " +
    "Use this when the user refers to 'my account', 'this user', or provides an email directly. " +
    "Returns null if no user is found — do not guess or fabricate a user.",
  input_schema: {
    type: "object",
    properties: {
      email: {
        type: "string",
        description: "The exact email address to search for, e.g. 'jane@acme.com'.",
      },
    },
    required: ["email"],
  },
};

export const getWeatherTool: Anthropic.Tool = {
  name: "get_current_weather",
  description:
    "Fetch the current weather conditions for a named city using an external weather API. " +
    "Use this only when the user explicitly asks about current weather, temperature, or forecast.",
  input_schema: {
    type: "object",
    properties: {
      city: { type: "string", description: "City name, e.g. 'Austin' or 'Berlin'." },
      units: {
        type: "string",
        enum: ["metric", "imperial"],
        description: "Temperature unit system. Default to 'metric' if the user does not specify.",
      },
    },
    required: ["city"],
  },
};

export const TOOLS: Anthropic.Tool[] = [getUserByEmailTool, getWeatherTool];
```

### Step 2 — Implement the tool functions

`src/lib/anthropic/tools/db-tools.ts`

```ts
import { neon } from "@neondatabase/serverless";

const sql = neon(process.env.DATABASE_URL!);

export async function getUserByEmail(email: string) {
  // Parameterized query — never interpolate tool-provided strings directly.
  const rows = await sql`
    SELECT id, name, email, plan
    FROM users
    WHERE email = ${email}
    LIMIT 1
  `;
  return rows[0] ?? null;
}
```

`src/lib/anthropic/tools/weather-tool.ts`

```ts
export async function getCurrentWeather(city: string, units: "metric" | "imperial" = "metric") {
  const apiKey = process.env.OPENWEATHER_API_KEY;
  if (!apiKey) {
    // Fail with a structured error the model can reason about, not a thrown exception.
    return { error: "Weather service is not configured." };
  }

  const url = `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(
    city
  )}&units=${units}&appid=${apiKey}`;

  const res = await fetch(url, { signal: AbortSignal.timeout(8_000) });
  if (!res.ok) {
    return { error: `Weather API returned ${res.status} for city '${city}'.` };
  }

  const data = await res.json();
  return {
    city: data.name,
    temperature: data.main?.temp,
    conditions: data.weather?.[0]?.description,
    units,
  };
}
```

### Step 3 — The tool dispatcher

`src/lib/anthropic/tools/dispatch.ts`

```ts
import { getUserByEmail } from "./db-tools";
import { getCurrentWeather } from "./weather-tool";

/**
 * Maps a tool name (as requested by Claude) to its executor. Centralizing
 * this avoids scattering if/else tool-name checks across route handlers.
 */
export async function executeTool(name: string, input: Record<string, unknown>) {
  switch (name) {
    case "get_user_by_email":
      return getUserByEmail(input.email as string);
    case "get_current_weather":
      return getCurrentWeather(
        input.city as string,
        (input.units as "metric" | "imperial") ?? "metric"
      );
    default:
      // Returned to Claude as a tool_result error, not thrown — keeps the loop alive.
      return { error: `Unknown tool '${name}'.` };
  }
}
```

### Step 4 — The tool-use loop Route Handler

`src/app/api/agent/tool-loop/route.ts`

```ts
import { NextRequest, NextResponse } from "next/server";
import Anthropic from "@anthropic-ai/sdk";
import { anthropic } from "@/lib/anthropic/client";
import { MODELS } from "@/lib/anthropic/models";
import { TOOLS } from "@/lib/anthropic/tools/registry";
import { executeTool } from "@/lib/anthropic/tools/dispatch";

const MAX_ITERATIONS = 6; // guardrail against runaway tool loops

export async function POST(req: NextRequest) {
  const { message } = await req.json();

  const messages: Anthropic.MessageParam[] = [{ role: "user", content: message }];

  for (let i = 0; i < MAX_ITERATIONS; i++) {
    const response = await anthropic.messages.create({
      model: MODELS.sonnet,
      max_tokens: 1024,
      system:
        "You are an internal support assistant. Use the provided tools to look up real data " +
        "before answering factual questions about users or weather. Never fabricate data.",
      tools: TOOLS,
      messages,
    });

    // Always append the assistant turn verbatim before doing anything else —
    // Anthropic requires the full content block array (text + tool_use) preserved.
    messages.push({ role: "assistant", content: response.content });

    if (response.stop_reason !== "tool_use") {
      const textBlock = response.content.find((b) => b.type === "text");
      return NextResponse.json({
        reply: textBlock?.type === "text" ? textBlock.text : null,
        iterations: i + 1,
      });
    }

    // Claude may request multiple tool calls in a single turn — run them concurrently.
    const toolUseBlocks = response.content.filter((b) => b.type === "tool_use");

    const toolResults = await Promise.all(
      toolUseBlocks.map(async (block) => {
        const result = await executeTool(
          block.name,
          block.input as Record<string, unknown>
        );
        return {
          type: "tool_result" as const,
          tool_use_id: block.id,
          content: JSON.stringify(result),
        };
      })
    );

    messages.push({ role: "user", content: toolResults });
  }

  return NextResponse.json(
    { error: `Exceeded max tool-loop iterations (${MAX_ITERATIONS}).` },
    { status: 500 }
  );
}
```

### Why the `MAX_ITERATIONS` guardrail is non-negotiable

Without a hard ceiling, a model that keeps requesting tools (e.g., retrying a failing lookup) will loop indefinitely, burning tokens and credits on every iteration. Six is a reasonable default for simple workflows; Part 5's multi-step agent uses a similar ceiling with a more structured stopping condition.

## Exercise Challenge

Add a third tool, `list_users_by_plan(plan: "free" | "pro" | "enterprise")`, that queries the `users` table for all accounts on a given plan tier, and wire it into the registry and dispatcher. Ensure:

1. The tool description is precise enough that Claude won't call it for single-user lookups (that's `get_user_by_email`'s job).
2. The dispatcher validates `plan` is one of the three allowed values before hitting the database, returning a tool-result error otherwise.

## Solution

`registry.ts` addition:

```ts
export const listUsersByPlanTool: Anthropic.Tool = {
  name: "list_users_by_plan",
  description:
    "List all user accounts on a specific subscription plan tier. Use this for aggregate " +
    "or 'how many/which users are on X plan' questions — NOT for looking up a single known user " +
    "(use get_user_by_email for that instead).",
  input_schema: {
    type: "object",
    properties: {
      plan: {
        type: "string",
        enum: ["free", "pro", "enterprise"],
        description: "The subscription plan tier to filter by.",
      },
    },
    required: ["plan"],
  },
};

export const TOOLS: Anthropic.Tool[] = [getUserByEmailTool, getWeatherTool, listUsersByPlanTool];
```

`db-tools.ts` addition:

```ts
const VALID_PLANS = ["free", "pro", "enterprise"] as const;
type Plan = (typeof VALID_PLANS)[number];

export async function listUsersByPlan(plan: string) {
  if (!VALID_PLANS.includes(plan as Plan)) {
    return { error: `Invalid plan '${plan}'. Must be one of: ${VALID_PLANS.join(", ")}` };
  }
  const rows = await sql`
    SELECT id, name, email FROM users WHERE plan = ${plan}
  `;
  return { plan, count: rows.length, users: rows };
}
```

`dispatch.ts` update:

```ts
case "list_users_by_plan":
  return listUsersByPlan(input.plan as string);
```

**Why validate inside the tool, not just in the schema's `enum`:** the JSON Schema `enum` is a strong hint to Claude, but it is not a runtime guarantee — always treat tool input as untrusted and re-validate server-side, exactly as you would validate a public API request body.

**Next:** Part 3 replaces hand-written JSON Schemas with **Zod-generated schemas** and shows how to force Claude into deterministic structured JSON output using `tool_choice`.
