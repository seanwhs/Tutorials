# Part 3: Structured Outputs with Zod

**Series:** Building Agentic Workflows: Mastering the Anthropic Suite
**Prerequisite:** Part 2 (tool schemas, the tool-use loop, dispatcher pattern).

## Concept Explanation

Free-text LLM output is unreliable for anything your application logic depends on programmatically — state updates, database writes, form fills. String-parsing a model's prose ("the ticket status is now 'in progress'") is brittle: formatting drifts, the model adds caveats, and one day it wraps the answer in markdown you didn't expect.

The fix is to repurpose Tool Use as a **structured output mechanism**: define a single "tool" whose input schema IS the exact shape you want back, then force Claude to call it with `tool_choice`. Claude never actually executes this tool — you intercept the tool_use block and treat its `input` as validated data.

This works because:

1. Anthropic tool inputs are already constrained by JSON Schema at generation time — the model is far less likely to violate types/enums than in free text.
2. `tool_choice: { type: "tool", name: "..." }` forces Claude to invoke that specific tool on this turn, guaranteeing a parseable response instead of an optional one.
3. Zod gives you a **single source of truth**: one schema definition generates both the JSON Schema sent to Claude and the runtime validator you run on the result, eliminating schema drift between "what I told the model" and "what I actually check."

### Why Zod validation is still required even with forced tool_choice

JSON Schema constrains *shape*, but not all Zod semantics (`.email()`, `.refine()`, cross-field invariants, custom business rules) translate to JSON Schema keywords Claude reliably honors. Treat the forced tool call as "very likely well-formed," not "guaranteed valid" — always run the real Zod `.parse()`/`.safeParse()` afterward, and have a repair strategy for failures (shown below).

## Implementation

### Step 1 — Install the Zod-to-JSON-Schema bridge

```bash
npm install zod-to-json-schema
```

### Step 2 — Define the Zod schema (single source of truth)

`src/lib/anthropic/schemas/ticket-update.schema.ts`

```ts
import { z } from "zod";
import zodToJsonSchema from "zod-to-json-schema";

export const TicketUpdateSchema = z.object({
  ticketId: z.string().describe("The exact ticket ID referenced in the conversation, e.g. 'TCK-1042'."),
  newStatus: z
    .enum(["open", "in_progress", "blocked", "resolved", "closed"])
    .describe("The new status to set for the ticket, based on the user's message."),
  priority: z
    .enum(["low", "medium", "high", "urgent"])
    .describe("Inferred priority. Default to 'medium' if not stated or implied."),
  summary: z
    .string()
    .max(200)
    .describe("A one-sentence summary of what changed and why, for the audit log."),
  requiresHumanReview: z
    .boolean()
    .describe("True if the update involves an urgent/blocked status or ambiguous instructions."),
});

export type TicketUpdate = z.infer<typeof TicketUpdateSchema>;

/** JSON Schema view of the same definition, for the Anthropic tool input_schema. */
export const ticketUpdateJsonSchema = zodToJsonSchema(TicketUpdateSchema, "TicketUpdate");
```

### Step 3 — Build the forced-tool-call Route Handler

`src/app/api/agent/structured/route.ts`

```ts
import { NextRequest, NextResponse } from "next/server";
import Anthropic from "@anthropic-ai/sdk";
import { anthropic } from "@/lib/anthropic/client";
import { MODELS } from "@/lib/anthropic/models";
import { TicketUpdateSchema, ticketUpdateJsonSchema } from "@/lib/anthropic/schemas/ticket-update.schema";

const TOOL_NAME = "record_ticket_update";

function buildTool(): Anthropic.Tool {
  // zod-to-json-schema wraps the shape under `definitions.TicketUpdate` —
  // unwrap it to get a bare input_schema Anthropic expects.
  const { definitions } = ticketUpdateJsonSchema as any;
  const schema = definitions.TicketUpdate;
  delete schema.$schema;

  return {
    name: TOOL_NAME,
    description:
      "Record a structured update to a support ticket based on the conversation. " +
      "This is the ONLY way to communicate a ticket change — always call this tool, never describe the update in prose.",
    input_schema: schema,
  };
}

export async function POST(req: NextRequest) {
  const { message } = await req.json();

  const response = await anthropic.messages.create({
    model: MODELS.sonnet,
    max_tokens: 512,
    system:
      "You extract structured ticket updates from support conversation snippets. " +
      "You must always respond by calling the record_ticket_update tool — never respond in plain text.",
    tools: [buildTool()],
    tool_choice: { type: "tool", name: TOOL_NAME }, // forces this exact tool call
    messages: [{ role: "user", content: message }],
  });

  const toolUse = response.content.find(
    (b): b is Anthropic.ToolUseBlock => b.type === "tool_use"
  );

  if (!toolUse) {
    // Should be unreachable given tool_choice, but never trust that blindly.
    return NextResponse.json(
      { error: "Model did not return the expected tool call." },
      { status: 502 }
    );
  }

  const parsed = TicketUpdateSchema.safeParse(toolUse.input);

  if (!parsed.success) {
    return NextResponse.json(
      {
        error: "Structured output failed Zod validation.",
        issues: parsed.error.issues,
        raw: toolUse.input,
      },
      { status: 422 }
    );
  }

  // parsed.data is now a fully typed, validated TicketUpdate — safe to persist.
  return NextResponse.json({ update: parsed.data, usage: response.usage });
}
```

### Step 4 — The self-repair pattern for validation failures

Rather than surfacing a 422 to the end user, feed the Zod error back to Claude and ask it to correct itself — often resolves the issue in one extra round trip, still cheaper than failing the whole workflow.

`src/lib/anthropic/schemas/repair.ts`

```ts
import type { z } from "zod";
import Anthropic from "@anthropic-ai/sdk";
import { anthropic } from "@/lib/anthropic/client";
import { MODELS } from "@/lib/anthropic/models";

export async function repairStructuredOutput<T>(
  schema: z.ZodType<T>,
  tool: Anthropic.Tool,
  originalMessages: Anthropic.MessageParam[],
  badToolUse: Anthropic.ToolUseBlock,
  zodIssues: z.ZodIssue[]
): Promise<T> {
  const repairMessages: Anthropic.MessageParam[] = [
    ...originalMessages,
    { role: "assistant", content: [badToolUse] },
    {
      role: "user",
      content: [
        {
          type: "tool_result",
          tool_use_id: badToolUse.id,
          content: JSON.stringify({
            error: "Validation failed. Fix the fields listed and call the tool again.",
            issues: zodIssues.map((i) => ({ path: i.path.join("."), message: i.message })),
          }),
          is_error: true,
        },
      ],
    },
  ];

  const retry = await anthropic.messages.create({
    model: MODELS.sonnet,
    max_tokens: 512,
    tools: [tool],
    tool_choice: { type: "tool", name: tool.name },
    messages: repairMessages,
  });

  const retryToolUse = retry.content.find(
    (b): b is Anthropic.ToolUseBlock => b.type === "tool_use"
  );
  if (!retryToolUse) throw new Error("Repair attempt did not return a tool call.");

  return schema.parse(retryToolUse.input); // throws if still invalid — caller decides fallback
}
```

### Architecture note: `tool_choice` and latency/cost

Forcing `tool_choice` removes Claude's ability to ask a clarifying question or explain uncertainty in the same turn — you're trading conversational flexibility for determinism. For genuinely ambiguous inputs, prefer letting the model call a `request_clarification` tool as one of several allowed options (`tool_choice: { type: "auto" }` with that tool included) rather than always forcing a single schema.

## Exercise Challenge

Design a `MeetingNotesSchema` (Zod) with fields: `title` (string), `attendees` (array of strings), `actionItems` (array of `{ owner: string, task: string, dueDate: string | null }`), and `decisionsMade` (array of strings). Build the forced-tool-call Route Handler for it, and write the Zod refinement that rejects the payload if `actionItems` is non-empty but any `owner` is an empty string.

## Solution

```ts
import { z } from "zod";

const ActionItemSchema = z.object({
  owner: z.string().min(1, "owner cannot be empty"),
  task: z.string().min(1),
  dueDate: z.string().nullable(),
});

export const MeetingNotesSchema = z
  .object({
    title: z.string().describe("A short descriptive title for the meeting."),
    attendees: z.array(z.string()).describe("Names or emails of attendees mentioned."),
    actionItems: z.array(ActionItemSchema).describe("Concrete follow-up tasks with an owner."),
    decisionsMade: z.array(z.string()).describe("Explicit decisions reached during the meeting."),
  })
  .refine(
    (data) => data.actionItems.every((item) => item.owner.trim().length > 0),
    { message: "Every action item must have a non-empty owner.", path: ["actionItems"] }
  );

export type MeetingNotes = z.infer<typeof MeetingNotesSchema>;
```

The Route Handler mirrors the ticket-update example exactly: build `input_schema` via `zodToJsonSchema(MeetingNotesSchema, "MeetingNotes")`, force `tool_choice` to a `record_meeting_notes` tool, and call `MeetingNotesSchema.safeParse(toolUse.input)`. Note the `.refine()` invariant is enforced by Zod at parse time, not by the JSON Schema Claude sees — this is exactly why the safeParse step is mandatory even under forced tool_choice.

**Next:** Part 4 covers Prompt Caching and conversation history management — reducing the cost and latency of repeatedly sending large system prompts and tool definitions across turns.
