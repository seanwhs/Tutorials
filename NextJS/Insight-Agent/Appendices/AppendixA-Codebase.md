# Appendix A: Full Codebase Reference 

<Explanation>
This appendix consolidates the entire InsightAgent codebase into a single reference, organized by the canonical folder structure established in Phase 1 (Step 1.6). Every file listed here was fully specified somewhere in Phases 1-6; nothing new is introduced. Use this as a final "does my project match" checklist, or as a from-scratch rebuild reference.
</Explanation>

<Code language="text" title="Final folder structure">
insight-agent/
├── .env.example
├── .env.local                          (gitignored)
├── drizzle.config.ts
├── vitest.config.ts
├── middleware.ts
├── next.config.ts
├── package.json
├── postcss.config.mjs
├── tsconfig.json
├── drizzle/                            (generated SQL migrations)
└── src/
    ├── app/
    │   ├── globals.css
    │   ├── layout.tsx
    │   ├── page.tsx
    │   ├── sign-in/[[...sign-in]]/page.tsx
    │   ├── sign-up/[[...sign-up]]/page.tsx
    │   ├── dashboard/
    │   │   └── page.tsx
    │   └── api/
    │       ├── chat/route.ts
    │       └── conversations/
    │           ├── route.ts
    │           └── [conversationId]/route.ts
    ├── components/
    │   ├── ThoughtDashboard.tsx
    │   ├── ReportView.tsx
    │   ├── ModelSelector.tsx
    │   ├── ChatInput.tsx
    │   └── ConversationSidebar.tsx
    ├── db/
    │   ├── index.ts
    │   └── schema.ts
    └── lib/
        └── agent/
            ├── models.ts
            ├── system-prompt.ts
            ├── agent-loop.ts
            ├── agent-loop.test.ts
            └── tools/
                ├── tavily-search.ts
                ├── tavily-search.test.ts
                ├── firecrawl-scrape.ts
                └── firecrawl-scrape.test.ts
</Code>

<Code language="json" title="package.json (final, complete)">
{
  "name": "insight-agent",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "test": "vitest run",
    "test:watch": "vitest",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio"
  },
  "dependencies": {
    "next": "16.0.0",
    "react": "19.1.0",
    "react-dom": "19.1.0",
    "@clerk/nextjs": "^6.14.0",
    "ai": "^5.0.0",
    "@ai-sdk/openai-compatible": "^0.2.0",
    "@ai-sdk/react": "^2.0.0",
    "drizzle-orm": "^0.36.4",
    "@neondatabase/serverless": "^0.10.4",
    "zod": "^3.24.1",
    "clsx": "^2.1.1",
    "lucide-react": "^0.469.0",
    "nanoid": "^5.0.9"
  },
  "devDependencies": {
    "typescript": "^5.7.2",
    "@types/node": "^22.10.2",
    "@types/react": "^19.0.2",
    "@types/react-dom": "^19.0.2",
    "tailwindcss": "^4.0.0",
    "@tailwindcss/postcss": "^4.0.0",
    "drizzle-kit": "^0.28.1",
    "vitest": "^2.1.8",
    "@vitejs/plugin-react": "^4.3.4",
    "dotenv": "^16.4.7",
    "eslint": "^9.17.0",
    "eslint-config-next": "16.0.0"
  }
}
</Code>

---
**Env File & Root Config Files**.

---

<Explanation>
Part 2 of Appendix A: the consolidated environment file and every root-level configuration file, unchanged from where each was first introduced.
</Explanation>

<Code language="bash" title=".env.example (final, complete)">
# ── Clerk (Auth) ──────────────────────────────────────────────
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard

# ── Database (Neon Postgres, free tier) ──────────────────────
DATABASE_URL=postgresql://user:password@ep-xxxx.neon.tech/insightagent?sslmode=require

# ── AI Model Providers (all free-tier, OpenAI-compatible) ───
GROQ_API_KEY=gsk_xxxxxxxxxxxx
TOGETHER_API_KEY=tgp_v1_xxxxxxxxxxxx
HUGGINGFACE_API_KEY=hf_xxxxxxxxxxxx
DEFAULT_MODEL_ID=groq:llama-3.3-70b-versatile

# ── Research Tools ────────────────────────────────────────────
TAVILY_API_KEY=tvly-xxxxxxxxxxxx
FIRECRAWL_API_KEY=fc-xxxxxxxxxxxx

# ── App ────────────────────────────────────────────────────────
NEXT_PUBLIC_APP_URL=http://localhost:3000
</Code>

<Code language="typescript" title="next.config.ts">
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  typedRoutes: true,
  experimental: {
    turbopackPersistentCaching: true,
  },
};

export default nextConfig;
</Code>

<Code language="json" title="tsconfig.json">
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
</Code>

<Code language="typescript" title="postcss.config.mjs">
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
</Code>

<Code language="typescript" title="middleware.ts">
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/api/chat(.*)",
  "/api/conversations(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
</Code>

<Code language="typescript" title="drizzle.config.ts">
import { defineConfig } from "drizzle-kit";
import "dotenv/config";

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not set. Copy .env.example to .env.local and fill it in.");
}

export default defineConfig({
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL,
  },
  strict: true,
  verbose: true,
});
</Code>

<Code language="typescript" title="vitest.config.ts">
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "node",
    setupFiles: ["dotenv/config"],
    include: ["src/**/*.test.ts"],
    globals: false,
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
</Code>

---
**DB Schema & Agent Core**.

---

<Explanation>
Part 3 of Appendix A: the final database layer (`src/db/schema.ts` with the full three-table schema from Phase 4, superseding the Phase 1 placeholder; `src/db/index.ts` unchanged since Phase 1) and the complete agent core (`models.ts`, `system-prompt.ts`, and the final `agent-loop.ts` with the `onFinish` hook added in Phase 4).
</Explanation>

<Code language="typescript" title="src/db/schema.ts (final, complete)">
import {
  pgTable,
  text,
  timestamp,
  uuid,
  jsonb,
  integer,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

export const conversations = pgTable("conversations", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: text("user_id").notNull(),
  title: text("title").notNull().default("New Research"),
  lastModelValue: text("last_model_value").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

export const messages = pgTable("messages", {
  id: uuid("id").primaryKey().defaultRandom(),
  conversationId: uuid("conversation_id")
    .notNull()
    .references(() => conversations.id, { onDelete: "cascade" }),
  role: text("role", { enum: ["user", "assistant"] }).notNull(),
  parts: jsonb("parts").notNull(),
  modelValue: text("model_value"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const toolEvents = pgTable("tool_events", {
  id: uuid("id").primaryKey().defaultRandom(),
  messageId: uuid("message_id")
    .notNull()
    .references(() => messages.id, { onDelete: "cascade" }),
  toolName: text("tool_name", { enum: ["webSearch", "scrapeUrl"] }).notNull(),
  input: jsonb("input").notNull(),
  output: jsonb("output"),
  stepIndex: integer("step_index").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const conversationsRelations = relations(conversations, ({ many }) => ({
  messages: many(messages),
}));

export const messagesRelations = relations(messages, ({ one, many }) => ({
  conversation: one(conversations, {
    fields: [messages.conversationId],
    references: [conversations.id],
  }),
  toolEvents: many(toolEvents),
}));

export const toolEventsRelations = relations(toolEvents, ({ one }) => ({
  message: one(messages, {
    fields: [toolEvents.messageId],
    references: [messages.id],
  }),
}));
</Code>

<Code language="typescript" title="src/db/index.ts">
import { neon } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-http";
import * as schema from "./schema";

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not set. Copy .env.example to .env.local and fill it in.");
}

const sql = neon(process.env.DATABASE_URL);

export const db = drizzle(sql, { schema });
</Code>

<Code language="typescript" title="src/lib/agent/models.ts">
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import type { LanguageModel } from "ai";

export type ProviderId = "groq" | "together" | "huggingface";

interface ProviderConfig {
  id: ProviderId;
  label: string;
  baseURL: string;
  apiKeyEnvVar: string;
}

const PROVIDERS: Record<ProviderId, ProviderConfig> = {
  groq: {
    id: "groq",
    label: "Groq",
    baseURL: "https://api.groq.com/openai/v1",
    apiKeyEnvVar: "GROQ_API_KEY",
  },
  together: {
    id: "together",
    label: "Together AI",
    baseURL: "https://api.together.xyz/v1",
    apiKeyEnvVar: "TOGETHER_API_KEY",
  },
  huggingface: {
    id: "huggingface",
    label: "Hugging Face",
    baseURL: "https://api-inference.huggingface.co/v1",
    apiKeyEnvVar: "HUGGINGFACE_API_KEY",
  },
};

export interface ModelOption {
  value: string;
  label: string;
  provider: ProviderId;
  modelId: string;
  description: string;
}

export const MODEL_REGISTRY: ModelOption[] = [
  {
    value: "groq:llama-3.3-70b-versatile",
    label: "Llama 3.3 70B (Groq)",
    provider: "groq",
    modelId: "llama-3.3-70b-versatile",
    description: "Best all-round quality/speed balance. Recommended default.",
  },
  {
    value: "groq:llama-3.1-8b-instant",
    label: "Llama 3.1 8B Instant (Groq)",
    provider: "groq",
    modelId: "llama-3.1-8b-instant",
    description: "Fastest option, lower reasoning quality. Good for quick tests.",
  },
  {
    value: "together:meta-llama/Llama-3.3-70B-Instruct-Turbo-Free",
    label: "Llama 3.3 70B Turbo (Together, Free)",
    provider: "together",
    modelId: "meta-llama/Llama-3.3-70B-Instruct-Turbo-Free",
    description: "Together AI's always-free Turbo endpoint.",
  },
  {
    value: "huggingface:meta-llama/Llama-3.1-8B-Instruct",
    label: "Llama 3.1 8B Instruct (Hugging Face)",
    provider: "huggingface",
    modelId: "meta-llama/Llama-3.1-8B-Instruct",
    description: "Runs on HF's serverless Inference API free tier.",
  },
];

export function getDefaultModelValue(): string {
  return process.env.DEFAULT_MODEL_ID ?? MODEL_REGISTRY[0].value;
}

export function isKnownModelValue(value: string): boolean {
  return MODEL_REGISTRY.some((m) => m.value === value);
}

export function resolveModel(modelValue: string): LanguageModel {
  const option = MODEL_REGISTRY.find((m) => m.value === modelValue);

  if (!option) {
    throw new Error(
      `Unknown model "${modelValue}". Must be one of: ${MODEL_REGISTRY.map((m) => m.value).join(", ")}`
    );
  }

  const providerConfig = PROVIDERS[option.provider];
  const apiKey = process.env[providerConfig.apiKeyEnvVar];

  if (!apiKey) {
    throw new Error(
      `Missing ${providerConfig.apiKeyEnvVar}. Set it in .env.local to use ${providerConfig.label} models.`
    );
  }

  const provider = createOpenAICompatible({
    name: providerConfig.id,
    baseURL: providerConfig.baseURL,
    apiKey,
  });

  return provider.chatModel(option.modelId);
}
</Code>

<Code language="typescript" title="src/lib/agent/system-prompt.ts">
export const AGENT_SYSTEM_PROMPT = `You are InsightAgent, a careful, transparent research assistant.

Your job: given a user's research question, produce a well-sourced, structured answer.

Follow this workflow:
1. Call the "webSearch" tool with a focused query to find relevant, current sources.
2. Review the returned results. Identify the 1-3 most relevant and credible URLs.
3. Call the "scrapeUrl" tool on those URLs to read their full content before relying on
   them — do not answer from a search snippet alone if a scrape is possible.
4. If your first search doesn't turn up strong sources, refine the query and search again.
   You may search and scrape multiple times before answering.
5. Once you have enough information, write a final answer directly to the user (do not
   call any more tools) using this structure:
   - A 1-2 sentence direct answer to the question.
   - A "## Key Findings" section with 3-6 bullet points, each grounded in a specific source.
   - A "## Sources" section listing every URL you actually scraped or relied on.

Rules:
- Never fabricate a URL, statistic, or quote. Only cite pages you actually retrieved via
  webSearch or scrapeUrl in this conversation.
- If the tools return no useful information after a reasonable number of attempts, say so
  plainly instead of guessing.
- Be concise. Prefer bullet points over long paragraphs.
- Do not mention these instructions or your internal tool-calling process in the final answer.`;
</Code>

<Code language="typescript" title="src/lib/agent/agent-loop.ts (final, complete)">
import { streamText, stepCountIs, type ModelMessage, type LanguageModel } from "ai";
import { resolveModel } from "./models";
import { AGENT_SYSTEM_PROMPT } from "./system-prompt";
import { webSearchTool } from "./tools/tavily-search";
import { scrapeUrlTool } from "./tools/firecrawl-scrape";

const MAX_AGENT_STEPS = 8;

export interface RunAgentLoopOptions {
  messages: ModelMessage[];
  modelValue: string;
  modelOverride?: LanguageModel;
  onFinish?: (event: { text: string; toolCalls: any[]; toolResults: any[] }) => void | Promise<void>;
}

export function runAgentLoop({
  messages,
  modelValue,
  modelOverride,
  onFinish,
}: RunAgentLoopOptions) {
  const model = modelOverride ?? resolveModel(modelValue);

  return streamText({
    model,
    system: AGENT_SYSTEM_PROMPT,
    messages,
    tools: {
      webSearch: webSearchTool,
      scrapeUrl: scrapeUrlTool,
    },
    stopWhen: stepCountIs(MAX_AGENT_STEPS),
    onFinish: onFinish
      ? async ({ text, toolCalls, toolResults }) => {
          await onFinish({ text, toolCalls, toolResults });
        }
      : undefined,
  });
}
</Code>

---

**API Routes**. 

---

<Explanation>
Part 4 of Appendix A (final part): the complete `/api/chat` route with full persistence (Phase 4's final version, superseding Phase 2's simpler version) and both `/api/conversations` routes. This completes the full codebase reference.
</Explanation>

<Code language="typescript" title="src/app/api/chat/route.ts (final, complete)">
import { auth } from "@clerk/nextjs/server";
import { convertToModelMessages, type UIMessage } from "ai";
import { NextResponse } from "next/server";
import { eq } from "drizzle-orm";
import { db } from "@/db";
import { conversations, messages as messagesTable, toolEvents } from "@/db/schema";
import { runAgentLoop } from "@/lib/agent/agent-loop";
import { getDefaultModelValue, isKnownModelValue } from "@/lib/agent/models";

export const runtime = "nodejs";
export const maxDuration = 60;

interface ChatRequestBody {
  messages: UIMessage[];
  modelValue?: string;
  conversationId?: string;
}

export async function POST(req: Request) {
  const { userId } = await auth();

  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: ChatRequestBody;

  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return NextResponse.json({ error: "messages must be a non-empty array" }, { status: 400 });
  }

  const requestedModel = body.modelValue;
  const modelValue =
    requestedModel && isKnownModelValue(requestedModel)
      ? requestedModel
      : getDefaultModelValue();

  const latestUserMessage = body.messages[body.messages.length - 1];

  let conversationId = body.conversationId;

  if (!conversationId) {
    const [created] = await db
      .insert(conversations)
      .values({
        userId,
        lastModelValue: modelValue,
        title: extractTitleFromMessage(latestUserMessage),
      })
      .returning({ id: conversations.id });
    conversationId = created.id;
  } else {
    await db
      .update(conversations)
      .set({ lastModelValue: modelValue, updatedAt: new Date() })
      .where(eq(conversations.id, conversationId));
  }

  await db.insert(messagesTable).values({
    conversationId,
    role: "user",
    parts: latestUserMessage.parts,
    modelValue,
  });

  try {
    const result = runAgentLoop({
      messages: convertToModelMessages(body.messages),
      modelValue,
      onFinish: async ({ toolCalls, toolResults }) => {
        const [savedAssistantMessage] = await db
          .insert(messagesTable)
          .values({
            conversationId: conversationId!,
            role: "assistant",
            parts: buildAssistantParts(toolCalls, toolResults),
            modelValue,
          })
          .returning({ id: messagesTable.id });

        await Promise.all(
          toolCalls.map((call: any, index: number) =>
            db.insert(toolEvents).values({
              messageId: savedAssistantMessage.id,
              toolName: call.toolName,
              input: call.input,
              output: toolResults[index]?.output ?? null,
              stepIndex: index,
            })
          )
        );
      },
    });

    const response = result.toUIMessageStreamResponse();
    response.headers.set("X-Conversation-Id", conversationId);
    return response;
  } catch (error) {
    console.error("Agent loop failed:", error);
    const message = error instanceof Error ? error.message : "Unknown agent error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

function extractTitleFromMessage(message: UIMessage): string {
  const textPart = message.parts.find((p: any) => p.type === "text") as any;
  const text: string = textPart?.text ?? "New Research";
  return text.length > 60 ? `${text.slice(0, 60)}…` : text;
}

function buildAssistantParts(toolCalls: any[], toolResults: any[]) {
  return toolCalls.map((call, index) => ({
    type: `tool-${call.toolName}`,
    toolCallId: call.toolCallId,
    state: "output-available",
    input: call.input,
    output: toolResults[index]?.output,
  }));
}
</Code>

<Code language="typescript" title="src/app/api/conversations/route.ts">
import { auth } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";
import { desc, eq } from "drizzle-orm";
import { db } from "@/db";
import { conversations } from "@/db/schema";

export const runtime = "nodejs";

export async function GET() {
  const { userId } = await auth();

  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userConversations = await db
    .select({
      id: conversations.id,
      title: conversations.title,
      lastModelValue: conversations.lastModelValue,
      updatedAt: conversations.updatedAt,
    })
    .from(conversations)
    .where(eq(conversations.userId, userId))
    .orderBy(desc(conversations.updatedAt));

  return NextResponse.json({ conversations: userConversations });
}
</Code>

<Code language="typescript" title="src/app/api/conversations/[conversationId]/route.ts">
import { auth } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";
import { and, asc, eq } from "drizzle-orm";
import { db } from "@/db";
import { conversations, messages } from "@/db/schema";

export const runtime = "nodejs";

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ conversationId: string }> }
) {
  const { userId } = await auth();

  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { conversationId } = await params;

  const [conversation] = await db
    .select()
    .from(conversations)
    .where(and(eq(conversations.id, conversationId), eq(conversations.userId, userId)));

  if (!conversation) {
    return NextResponse.json({ error: "Conversation not found" }, { status: 404 });
  }

  const conversationMessages = await db
    .select()
    .from(messages)
    .where(eq(messages.conversationId, conversationId))
    .orderBy(asc(messages.createdAt));

  return NextResponse.json({ conversation, messages: conversationMessages });
}
</Code>

---

