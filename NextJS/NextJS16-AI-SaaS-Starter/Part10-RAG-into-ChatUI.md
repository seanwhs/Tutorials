## AI SaaS Tutorial - Part 10: Wiring RAG into Chat End-to-End

*Next.js 16 note: the chat page uses Promise-based params, consistent with the rest of the series. The API route uses plain Request/Response — no version-specific concerns there.*

### Goal
Update `/api/chat` to retrieve relevant document chunks (Part 8) for the workspace and inject them into the system prompt before calling the model — completing the full RAG loop. Also persist messages to the DB and enforce workspace access.

### 1. Updated chat route with retrieval + persistence
`src/app/api/chat/route.ts`:
```ts
import { streamText, convertToModelMessages, type UIMessage } from "ai";
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve";
import { getCurrentWorkspaceAndRole } from "@/lib/workspace";
import { db } from "@/lib/db";

const provider = createOpenAICompatible({
  name: "free-provider",
  baseURL: process.env.CHAT_BASE_URL!,
  apiKey: process.env.CHAT_API_KEY!,
});

export async function POST(req: Request) {
  const { messages, workspaceId }: { messages: UIMessage[]; workspaceId: string } = await req.json();

  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) {
    return new Response("Unauthorized", { status: 401 });
  }

  const lastUserMessage = messages[messages.length - 1];
  const question = lastUserMessage.parts
    .filter((p) => p.type === "text")
    .map((p) => p.text)
    .join(" ");

  await db.message.create({
    data: {
      workspaceId,
      userId: ctx.user.id,
      role: "USER",
      content: question,
    },
  });

  const relevantChunks = await retrieveRelevantChunks(workspaceId, question);

  const contextBlock = relevantChunks.length
    ? relevantChunks
        .map((c, i) => `[Source ${i + 1}: ${c.documentName}]\n${c.content}`)
        .join("\n\n")
    : "No relevant document content was found for this question.";

  const systemPrompt = `You are a helpful assistant that answers questions using ONLY the document excerpts provided below. If the excerpts don't contain the answer, say you don't know based on the uploaded documents - do not make things up.

DOCUMENT EXCERPTS:
${contextBlock}`;

  const result = streamText({
    model: provider(process.env.CHAT_MODEL!),
    system: systemPrompt,
    messages: convertToModelMessages(messages),
    onFinish: async ({ text }) => {
      await db.message.create({
        data: {
          workspaceId,
          role: "ASSISTANT",
          content: text,
        },
      });
    },
  });

  return result.toUIMessageStreamResponse();
}
```

### 2. Why we ground the model with a strict system prompt
This is the core of RAG: instead of relying on the model's general knowledge, we force it to answer only from the retrieved chunks. This reduces hallucination, keeps answers scoped to the workspace's own documents (workspace A never sees workspace B's content, enforced both by the SQL `WHERE d."workspaceId" = $2` in Part 8 and the auth check above), and gives a natural place to cite sources.

### 3. Load chat history on page load (Promise-based params — Next.js 16)
`src/app/(dashboard)/workspaces/[workspaceId]/chat/page.tsx` (updated):
```tsx
import { notFound } from "next/navigation";
import { getCurrentWorkspaceAndRole } from "@/lib/workspace";
import { db } from "@/lib/db";
import { ChatUI } from "./chat-ui";

export default async function ChatPage({
  params,
}: {
  params: Promise<{ workspaceId: string }>;
}) {
  const { workspaceId } = await params;
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) notFound();

  const history = await db.message.findMany({
    where: { workspaceId },
    orderBy: { createdAt: "asc" },
    take: 50,
  });

  const initialMessages = history.map((m) => ({
    id: m.id,
    role: m.role === "USER" ? ("user" as const) : ("assistant" as const),
    parts: [{ type: "text" as const, text: m.content }],
  }));

  return (
    <div>
      <h1 className="mb-4 text-2xl font-bold">Chat</h1>
      <ChatUI workspaceId={workspaceId} initialMessages={initialMessages} />
    </div>
  );
}
```

Update `ChatUI` to accept and pass through `initialMessages`:
```tsx
export function ChatUI({
  workspaceId,
  initialMessages = [],
}: {
  workspaceId: string;
  initialMessages?: any[];
}) {
  const [input, setInput] = useState("");
  const { messages, sendMessage, status } = useChat({ messages: initialMessages });
  // ...rest unchanged
}
```

**Checkpoint:** Upload a document with distinctive content (e.g. a fake FAQ with a made-up product name), then ask the chat about it. The answer should reference facts only found in your document. Ask an unrelated question ("What's the capital of France?") and confirm it says it doesn't know based on the uploaded documents.

**Next:** Part 11 — Free/Open LLM Provider Abstraction (model list in code).
