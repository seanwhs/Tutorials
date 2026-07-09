## AI SaaS Tutorial - Part 9: Chat UI with Vercel AI SDK (Streaming)

*Next.js 16 note: the chat page uses Promise-based params (`await params`), consistent with every dynamic page in this series. The API route and client component use standard, version-agnostic patterns.*

### Goal
Build a streaming chat interface using the Vercel AI SDK's React hooks, backed by a simple `/api/chat` route (RAG wiring comes in Part 10).

### 1. Package
`@ai-sdk/react` was already installed in Part 1, alongside `ai` and `@ai-sdk/openai-compatible`.

### 2. A minimal chat API route (no RAG yet)
`src/app/api/chat/route.ts`:
```ts
import { streamText, convertToModelMessages, type UIMessage } from "ai";
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";

const provider = createOpenAICompatible({
  name: "free-provider",
  baseURL: process.env.CHAT_BASE_URL!,
  apiKey: process.env.CHAT_API_KEY!,
});

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json();

  const result = streamText({
    model: provider(process.env.CHAT_MODEL!),
    messages: convertToModelMessages(messages),
  });

  return result.toUIMessageStreamResponse();
}
```

### 3. Environment variables (placeholder chat model — full free model list in Part 11)
```bash
CHAT_BASE_URL=http://localhost:11434/v1
CHAT_API_KEY=ollama
CHAT_MODEL=llama3.1
```
(If using Ollama, `ollama pull llama3.1` first.)

### 4. Chat UI component
`src/app/(dashboard)/workspaces/[workspaceId]/chat/chat-ui.tsx`:
```tsx
"use client";

import { useChat } from "@ai-sdk/react";
import { useState } from "react";

export function ChatUI({ workspaceId }: { workspaceId: string }) {
  const [input, setInput] = useState("");
  const { messages, sendMessage, status } = useChat();

  return (
    <div className="flex h-[70vh] flex-col rounded-lg border bg-white">
      <div className="flex-1 space-y-4 overflow-y-auto p-4">
        {messages.length === 0 && (
          <p className="text-center text-gray-400">Ask a question about your uploaded documents.</p>
        )}
        {messages.map((m) => (
          <div key={m.id} className={m.role === "user" ? "text-right" : "text-left"}>
            <div
              className={`inline-block max-w-[80%] rounded-lg px-4 py-2 ${
                m.role === "user" ? "bg-blue-600 text-white" : "bg-gray-100 text-gray-900"
              }`}
            >
              {m.parts.map((part, i) =>
                part.type === "text" ? <span key={i}>{part.text}</span> : null
              )}
            </div>
          </div>
        ))}
        {status === "streaming" && <p className="text-sm text-gray-400">Thinking...</p>}
      </div>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          if (!input.trim()) return;
          sendMessage(
            { text: input },
            { body: { workspaceId } }
          );
          setInput("");
        }}
        className="flex gap-2 border-t p-4"
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask about your documents..."
          className="flex-1 rounded border px-3 py-2"
        />
        <button
          type="submit"
          disabled={status === "streaming"}
          className="rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-50"
        >
          Send
        </button>
      </form>
    </div>
  );
}
```

### 5. Chat page (Promise-based params — Next.js 16)
`src/app/(dashboard)/workspaces/[workspaceId]/chat/page.tsx`:
```tsx
import { notFound } from "next/navigation";
import { getCurrentWorkspaceAndRole } from "@/lib/workspace";
import { ChatUI } from "./chat-ui";

export default async function ChatPage({
  params,
}: {
  params: Promise<{ workspaceId: string }>;
}) {
  const { workspaceId } = await params;
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) notFound();

  return (
    <div>
      <h1 className="mb-4 text-2xl font-bold">Chat</h1>
      <ChatUI workspaceId={workspaceId} />
    </div>
  );
}
```

**Checkpoint:** Go to `/workspaces/<id>/chat`, type a question, and see a streamed response from your local Ollama model (or whichever `CHAT_*` endpoint you configured). It won't know anything about your documents yet — that's Part 10.

**Next:** Part 10 — Wiring RAG into Chat End-to-End.
