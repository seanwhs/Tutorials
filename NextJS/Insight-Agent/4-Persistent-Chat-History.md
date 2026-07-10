# Phase 4: Persistent Chat History 

<Step number="4.1" title="The Full Drizzle Schema: Conversations, Messages, Tool Events">
<Explanation>
This replaces the Phase 1 placeholder `healthCheck` table with the real schema powering persistence. Three tables: `conversations` (one row per research session, owned by a Clerk `userId`, storing the last-used model so resuming a session pre-selects the right `ModelSelector` value), `messages` (one row per user/assistant turn, storing the AI SDK's `parts` array as JSON so we can losslessly reconstruct `ThoughtDashboard` tool activity and `ReportView` text on reload), and `toolEvents` (a denormalized, queryable log of every tool call — useful for a future "usage/analytics" feature and for Phase 5 integration test assertions, even though `messages.parts` alone is sufficient to re-render the UI). We use `jsonb` for `parts` and tool input/output because their shape is defined by the AI SDK, not by us, and will evolve across SDK versions — modeling it as rigid relational columns would create constant migration churn.
</Explanation>

<Code language="typescript" title="src/db/schema.ts">
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
  // Full AI SDK UIMessage.parts array (text parts + tool-call/tool-result parts).
  // Stored as-is so the UI can be reconstructed pixel-for-pixel on reload.
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

<Explanation>
After replacing `schema.ts`, run `npm run db:generate` to produce a new migration (Drizzle will detect the dropped `health_check` table and the three new tables) and `npm run db:migrate` to apply it to Neon. `onDelete: "cascade"` on both foreign keys means deleting a conversation automatically cleans up its messages and tool events — no orphaned rows, no manual cascade logic in application code. Note `conversations.userId` is a plain `text` column, not a foreign key — Clerk user IDs live outside our database entirely, so we just store the string and always filter by it in every query (Step 4.3) to enforce per-user data isolation at the query level.
</Explanation>
</Step>

---

**Step 4.2: Updating the API Route: Save-on-Stream-Finish**.

---

<Step number="4.2" title="Updating the API Route: Save-on-Stream-Finish">
<Explanation>
Persistence must not block or slow down streaming — the user should see the same instant, live-updating experience from Phase 3 while saving happens transparently in the background. The Vercel AI SDK's `streamText` exposes an `onFinish` callback that fires once the entire agent run (all steps, all tool calls, final text) completes, receiving the full list of response messages in AI SDK message format. We hook persistence there: save the user's message immediately (before starting the stream, since we already have it), then save the assistant's message (with full `parts`, preserving tool calls for `ThoughtDashboard` reconstruction) and its extracted `toolEvents` inside `onFinish`. The route now also accepts an optional `conversationId` — if omitted, a new conversation is created and its id is returned to the client via a custom stream header so the client can start tracking it.
</Explanation>

<Code language="typescript" title="src/lib/agent/agent-loop.ts">
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

<Code language="typescript" title="src/app/api/chat/route.ts">
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

  // Resolve or create the conversation this run belongs to.
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

  // Persist the user's message immediately — we already have it in full.
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

<Explanation>
`buildAssistantParts` here is a simplified reconstruction sufficient to store tool activity; Step 4.4 refines this further when we add a "load a past conversation" endpoint and confirms the exact shape expected by `ThoughtDashboard`. The `X-Conversation-Id` response header is how a brand-new conversation's generated id gets back to the client — read in Step 4.5's updated `dashboard/page.tsx` so subsequent messages in the same session reuse the same `conversationId` instead of creating a new conversation per message.
</Explanation>
</Step>

---

**Step 4.3: The `/api/conversations` Endpoints**.

---

<Step number="4.3" title="The /api/conversations Endpoints">
<Explanation>
Two Route Handlers back the history sidebar: a list endpoint returning all of the current user's conversations (most recent first, for the sidebar) and a get-by-id endpoint returning one conversation's full message history (for resuming a session). Both handlers independently call `auth()` and filter every query by the resulting `userId` — this is the per-user data isolation enforcement mentioned in Step 4.1. Because `conversations.userId` is just a plain text column with no database-level row security, this application-level filtering in every single query is the entire security boundary, so it is applied consistently and defensively in both endpoints, never trusting a conversation id alone to prove ownership.
</Explanation>

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

<Explanation>
Notice the `and(eq(conversations.id, conversationId), eq(conversations.userId, userId))` compound condition in the get-by-id route — this single line is what prevents User A from ever loading User B's conversation simply by guessing or being handed a UUID; a mismatched `userId` makes the query return no rows at all, indistinguishable from a nonexistent conversation, which correctly returns a generic 404 rather than a revealing 403. The dynamic route folder `[conversationId]` follows the same Next.js 16 async `params` pattern used throughout this series — always a `Promise`, always awaited.
</Explanation>
</Step>

---

**Step 4.4: The ConversationSidebar Component**.

---

<Step number="4.4" title="The ConversationSidebar Component">
<Explanation>
This component lists the current user's past research sessions (fetched from `/api/conversations`, Step 4.3) and lets them start a new conversation or click into a past one. It manages its own fetch/loading state internally via a simple `useEffect` — no extra state library needed for a single list view. Selecting a conversation calls the `onSelectConversation` callback with its id; the parent `dashboard/page.tsx` (Step 4.5) is responsible for actually loading that conversation's messages and feeding them into `useChat`. The "New Research" button clears the active conversation, which the parent interprets as "the next sent message should create a fresh conversation" (matching the `conversationId`-omitted branch in the API route from Step 4.2).
</Explanation>

<Code language="typescript" title="src/components/ConversationSidebar.tsx">
"use client";

import { useEffect, useState } from "react";
import { Plus, MessageSquare, Loader2 } from "lucide-react";
import clsx from "clsx";

interface ConversationSummary {
  id: string;
  title: string;
  lastModelValue: string;
  updatedAt: string;
}

interface ConversationSidebarProps {
  activeConversationId: string | null;
  onSelectConversation: (id: string | null) => void;
  /** Bumped by the parent whenever a new conversation is created, to trigger a refetch. */
  refreshKey: number;
}

export function ConversationSidebar({
  activeConversationId,
  onSelectConversation,
  refreshKey,
}: ConversationSidebarProps) {
  const [conversations, setConversations] = useState<ConversationSummary[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isCancelled = false;

    async function loadConversations() {
      setIsLoading(true);
      try {
        const res = await fetch("/api/conversations");
        if (!res.ok) return;
        const data = await res.json();
        if (!isCancelled) setConversations(data.conversations);
      } finally {
        if (!isCancelled) setIsLoading(false);
      }
    }

    loadConversations();

    return () => {
      isCancelled = true;
    };
  }, [refreshKey]);

  return (
    <aside className="flex w-64 shrink-0 flex-col gap-2 border-r border-surface-100 bg-surface-0 p-3">
      <button
        onClick={() => onSelectConversation(null)}
        className="flex items-center gap-2 rounded-lg border border-brand-600 px-3 py-2 text-sm font-medium text-brand-600 hover:bg-brand-50"
      >
        <Plus size={15} />
        New Research
      </button>

      <div className="mt-2 flex flex-col gap-1 overflow-y-auto scrollbar-thin">
        {isLoading && (
          <div className="flex items-center justify-center py-6 text-surface-900/40">
            <Loader2 size={16} className="animate-spin" />
          </div>
        )}

        {!isLoading && conversations.length === 0 && (
          <p className="px-2 py-4 text-center text-xs text-surface-900/40">
            No past sessions yet.
          </p>
        )}

        {conversations.map((conversation) => (
          <button
            key={conversation.id}
            onClick={() => onSelectConversation(conversation.id)}
            className={clsx(
              "flex items-start gap-2 rounded-lg px-3 py-2 text-left text-sm transition",
              activeConversationId === conversation.id
                ? "bg-brand-50 text-brand-700"
                : "text-surface-900/80 hover:bg-surface-50"
            )}
          >
            <MessageSquare size={14} className="mt-0.5 shrink-0" />
            <span className="line-clamp-2">{conversation.title}</span>
          </button>
        ))}
      </div>
    </aside>
  );
}
</Code>

<Explanation>
The `refreshKey` prop is a deliberately simple cache-invalidation mechanism: rather than wiring up a full client-side data-fetching library (React Query, SWR, etc. — extra dependencies with no free-tier cost implication but real complexity cost for a tutorial-scale app), the parent just increments a counter whenever a new conversation is created, and this `useEffect`'s dependency array re-triggers the fetch. This keeps the sidebar's data model intentionally simple and easy to reason about, at the cost of not being real-time multi-tab-aware — an acceptable tradeoff called out explicitly here rather than left as a silent limitation.
</Explanation>
</Step>

---
**Step 4.5: Updating the Dashboard Page: Sidebar, conversationId Tracking, Resuming Sessions**.

---

<Step number="4.5" title="Updating the Dashboard Page: Sidebar, conversationId Tracking, Resuming Sessions">
<Explanation>
This revises the Phase 3 `dashboard/page.tsx` to close the persistence loop end-to-end. Three additions: (1) `activeConversationId` state, sent as part of the request body alongside `modelValue` so the server (Step 4.2) knows whether to reuse or create a conversation; (2) reading the `X-Conversation-Id` response header after the first message of a brand-new conversation so subsequent messages in the same session correctly reuse it — done via `useChat`'s `onResponse` callback; (3) a `loadConversation` function that fetches a past session's full message history from `/api/conversations/[conversationId]` (Step 4.3) and calls `useChat`'s `setMessages` to hydrate the UI, plus restores the correct `modelValue` from the loaded conversation so `ModelSelector` reflects what was actually used last time.
</Explanation>

<Code language="typescript" title="src/app/dashboard/page.tsx">
"use client";

import { useState, useCallback } from "react";
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import { UserButton } from "@clerk/nextjs";
import { ModelSelector } from "@/components/ModelSelector";
import { ChatInput } from "@/components/ChatInput";
import { ThoughtDashboard } from "@/components/ThoughtDashboard";
import { ReportView } from "@/components/ReportView";
import { ConversationSidebar } from "@/components/ConversationSidebar";
import { getDefaultModelValue } from "@/lib/agent/models";
import { Sparkles } from "lucide-react";

export default function DashboardPage() {
  const [modelValue, setModelValue] = useState(getDefaultModelValue());
  const [activeConversationId, setActiveConversationId] = useState<string | null>(null);
  const [sidebarRefreshKey, setSidebarRefreshKey] = useState(0);

  const { messages, sendMessage, setMessages, status } = useChat({
    transport: new DefaultChatTransport({
      api: "/api/chat",
      body: () => ({ modelValue, conversationId: activeConversationId }),
    }),
    onResponse: (response) => {
      const newConversationId = response.headers.get("X-Conversation-Id");
      if (newConversationId && newConversationId !== activeConversationId) {
        setActiveConversationId(newConversationId);
        setSidebarRefreshKey((k) => k + 1);
      }
    },
  });

  const isBusy = status === "submitted" || status === "streaming";

  const handleSubmit = (text: string) => {
    sendMessage({ text });
  };

  const handleSelectConversation = useCallback(
    async (conversationId: string | null) => {
      if (conversationId === null) {
        setActiveConversationId(null);
        setMessages([]);
        setModelValue(getDefaultModelValue());
        return;
      }

      const res = await fetch(`/api/conversations/${conversationId}`);
      if (!res.ok) return;

      const data = await res.json();
      setActiveConversationId(conversationId);
      setModelValue(data.conversation.lastModelValue);
      setMessages(
        data.messages.map((m: any) => ({
          id: m.id,
          role: m.role,
          parts: m.parts,
        }))
      );
    },
    [setMessages]
  );

  return (
    <div className="flex h-screen bg-surface-50">
      <ConversationSidebar
        activeConversationId={activeConversationId}
        onSelectConversation={handleSelectConversation}
        refreshKey={sidebarRefreshKey}
      />

      <div className="flex flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-surface-100 bg-surface-0 px-5 py-3">
          <div className="flex items-center gap-2">
            <Sparkles size={18} className="text-brand-600" />
            <span className="font-semibold text-surface-900">InsightAgent</span>
          </div>
          <UserButton afterSignOutUrl="/" />
        </header>

        <div className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-4 overflow-hidden px-5 py-4">
          <ModelSelector value={modelValue} onChange={setModelValue} disabled={isBusy} />

          <div className="flex-1 overflow-y-auto scrollbar-thin">
            <div className="flex flex-col gap-4">
              {messages.length === 0 && (
                <p className="mt-10 text-center text-sm text-surface-900/40">
                  Ask a research question to get started.
                </p>
              )}

              {messages.map((message) => {
                const textParts = message.parts.filter((p: any) => p.type === "text");
                const fullText = textParts.map((p: any) => p.text).join("");

                return (
                  <div
                    key={message.id}
                    className={
                      message.role === "user"
                        ? "self-end rounded-xl bg-brand-600 px-4 py-2.5 text-sm text-white"
                        : "self-start w-full"
                    }
                  >
                    {message.role === "assistant" ? (
                      <div className="flex w-full flex-col gap-2">
                        <ThoughtDashboard message={message} />
                        {fullText && (
                          <div className="rounded-xl border border-surface-100 bg-surface-0 p-4">
                            <ReportView text={fullText} />
                          </div>
                        )}
                      </div>
                    ) : (
                      fullText
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          <ChatInput onSubmit={handleSubmit} isBusy={isBusy} />
        </div>
      </div>
    </div>
  );
}
</Code>

<Explanation>
The `onResponse` callback fires as soon as HTTP headers are available — before the body has finished streaming — which is exactly when we need to capture `X-Conversation-Id`; waiting for `onFinish` instead would work too but delays sidebar refresh until the entire agent run completes, feeling sluggish. Note that `handleSelectConversation(null)` resets `modelValue` back to `getDefaultModelValue()` rather than leaving whatever model was last selected — starting a "New Research" session should always begin from the app's sensible default, not an artifact of whatever was previously loaded.
</Explanation>
</Step>

---
**Step 4.6: Phase 4 Wrap-up**

---

<Step number="4.6" title="Phase 4 Wrap-up">
<Explanation>
It's worth tracing the full persistence lifecycle now that all pieces exist. A brand-new session: user sends a message with `conversationId: null` → the route creates a `conversations` row, saves the user's `messages` row, streams the agent's response while running `onFinish` in the background to save the assistant's `messages` row plus its `toolEvents`, and returns `X-Conversation-Id` in the response headers → the client captures that header via `onResponse`, stores it as `activeConversationId`, and bumps `sidebarRefreshKey` so `ConversationSidebar` refetches and the new session appears in the list immediately. Every subsequent message in that same browser session now includes the real `conversationId`, so the route's update branch runs instead of the insert branch — all messages land in the same conversation. Resuming later: clicking a sidebar entry calls `/api/conversations/[conversationId]`, which is authorization-checked against the Clerk `userId`, and the returned `messages` array (each row's stored `parts` JSON) is handed directly to `useChat`'s `setMessages` — because we saved the *exact* AI SDK parts shape (text parts and tool-call parts alike), `ThoughtDashboard` and `ReportView` render identically whether the message just streamed in live or was loaded from Postgres days later.

This symmetry — same `parts` shape in, same `parts` shape out — is the single most important design decision in this phase. It means Phase 3's UI components needed zero special-casing for "live" vs. "historical" messages; they only ever consume an AI SDK `UIMessage`, regardless of its origin.
</Explanation>

<Explanation>
**Phase 4 is now complete.** InsightAgent is a fully persistent, multi-session research tool: conversations, messages (with full tool-call fidelity), and a queryable tool-event log are all saved to Neon Postgres via Drizzle, users can browse and resume any past session from the sidebar, and per-user data isolation is enforced at every query. The application is now feature-complete from a product standpoint. Phase 5 shifts focus to engineering rigor: writing deterministic, offline Vitest tests for the Tavily and Firecrawl tools and a full integration test for the agent loop itself using `MockLanguageModelV2` — so the entire agentic core can be verified in CI without spending a single real API call or dollar.
</Explanation>
</Step>

---

