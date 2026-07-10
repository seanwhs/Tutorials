# Phase 3: UI & Streaming 

<Step number="3.1" title="The Model Selector Component">
<Explanation>
This is the client-side embodiment of the "model agility" pillar: a plain, dependency-light dropdown driven entirely by the same `MODEL_REGISTRY` array defined server-side in Phase 2 (Step 2.1). Because it's a Client Component that imports directly from `@/lib/agent/models`, the dropdown options and the server-side validation logic can never drift out of sync — there is exactly one source of truth for "which free models exist." The component is fully controlled: it owns no internal state beyond what's passed in, so the parent `dashboard/page.tsx` (Step 3.5) can persist the selected model across messages in a single conversation.
</Explanation>

<Code language="typescript" title="src/components/ModelSelector.tsx">
"use client";

import { MODEL_REGISTRY } from "@/lib/agent/models";
import { ChevronDown, Cpu } from "lucide-react";

interface ModelSelectorProps {
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
}

export function ModelSelector({ value, onChange, disabled }: ModelSelectorProps) {
  const selected = MODEL_REGISTRY.find((m) => m.value === value);

  return (
    <div className="flex flex-col gap-1">
      <label
        htmlFor="model-selector"
        className="flex items-center gap-1.5 text-xs font-medium text-surface-900/60"
      >
        <Cpu size={13} />
        AI Model (free tier)
      </label>
      <div className="relative">
        <select
          id="model-selector"
          value={value}
          disabled={disabled}
          onChange={(e) => onChange(e.target.value)}
          className="w-full appearance-none rounded-lg border border-surface-100 bg-surface-0 px-3 py-2 pr-9 text-sm font-medium text-surface-900 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {MODEL_REGISTRY.map((model) => (
            <option key={model.value} value={model.value}>
              {model.label}
            </option>
          ))}
        </select>
        <ChevronDown
          size={16}
          className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-surface-900/40"
        />
      </div>
      {selected && (
        <p className="text-xs text-surface-900/50">{selected.description}</p>
      )}
    </div>
  );
}
</Code>

<Explanation>
Using a native `<select>` rather than a custom listbox is intentional: it's accessible by default, works without JavaScript hydration edge cases, and needs zero extra dependencies — consistent with the zero-cost, minimal-dependency ethos of the whole stack. The description line beneath the dropdown (sourced from `ModelOption.description`) gives users just enough context to make an informed choice between speed and quality tradeoffs across free providers, directly supporting the "Model Agility" requirement that switching must be trivial and transparent.
</Explanation>
</Step>

---

**Step 3.2: The Chat Input Component**.

---

<Step number="3.2" title="The Chat Input Component">
<Explanation>
A small, controlled textarea + submit button component. It intentionally holds no knowledge of streaming state, message history, or the AI SDK at all — it only knows how to collect a string and call `onSubmit`. This separation means `ChatInput` is trivially reusable (e.g. if a "quick ask" widget were added elsewhere) and keeps the more complex streaming logic isolated to `dashboard/page.tsx` (Step 3.5). Submission is disabled while `isBusy` is true (i.e. the agent is currently mid-run), which prevents a user from firing overlapping requests against the same conversation — important given each free-tier provider enforces its own rate limits.
</Explanation>

<Code language="typescript" title="src/components/ChatInput.tsx">
"use client";

import { useState, type FormEvent, type KeyboardEvent } from "react";
import { SendHorizontal } from "lucide-react";

interface ChatInputProps {
  onSubmit: (value: string) => void;
  isBusy: boolean;
}

export function ChatInput({ onSubmit, isBusy }: ChatInputProps) {
  const [value, setValue] = useState("");

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const trimmed = value.trim();
    if (!trimmed || isBusy) return;
    onSubmit(trimmed);
    setValue("");
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="flex items-end gap-2 rounded-xl border border-surface-100 bg-surface-0 p-2 shadow-sm"
    >
      <textarea
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onKeyDown={handleKeyDown}
        disabled={isBusy}
        placeholder="Ask a research question… e.g. 'What are the latest developments in solid-state batteries?'"
        rows={2}
        className="flex-1 resize-none bg-transparent px-2 py-1.5 text-sm text-surface-900 outline-none placeholder:text-surface-900/40 disabled:opacity-60"
      />
      <button
        type="submit"
        disabled={isBusy || !value.trim()}
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-brand-600 text-white transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-40"
        aria-label="Send message"
      >
        <SendHorizontal size={16} />
      </button>
    </form>
  );
}
</Code>

<Explanation>
The Enter-to-submit / Shift+Enter-for-newline pattern matches user expectations from every mainstream chat product, so no additional onboarding UI is needed to explain it. Note `onSubmit` receives a plain trimmed string, not an event — this keeps the parent free to decide exactly how to turn that string into an AI SDK message (Step 3.5 shows this wiring against `useChat`'s `sendMessage`).
</Explanation>
</Step>

---
**Step 3.3: The ThoughtDashboard Component**.

---

<Step number="3.3" title="The ThoughtDashboard Component (Live Tool-Call Visualization)">
<Explanation>
This is InsightAgent's signature UX feature: rather than a black-box spinner while the agent works, `ThoughtDashboard` renders each tool call and its result live, as the AI SDK streams `tool-call` and `tool-result` message parts. This builds user trust (you can see exactly what the agent searched for and scraped) and doubles as a debugging surface during development. It reads directly from the AI SDK v5 UIMessage `parts` array — specifically parts whose `type` starts with `"tool-"` — and renders a distinct row per tool invocation, showing a spinner while a call is in-flight (state `"input-streaming"` or `"input-available"`) and a compact result summary once the state becomes `"output-available"`.
</Explanation>

<Code language="typescript" title="src/components/ThoughtDashboard.tsx">
"use client";

import type { UIMessage } from "ai";
import { Search, FileSearch, Loader2, CheckCircle2, XCircle } from "lucide-react";

interface ThoughtDashboardProps {
  message: UIMessage;
}

interface ToolPartLike {
  type: string;
  toolCallId: string;
  state: "input-streaming" | "input-available" | "output-available" | "output-error";
  input?: any;
  output?: any;
  errorText?: string;
}

function isToolPart(part: UIMessage["parts"][number]): part is ToolPartLike & { type: string } {
  return typeof part.type === "string" && part.type.startsWith("tool-");
}

function toolLabel(type: string): { label: string; Icon: typeof Search } {
  if (type === "tool-webSearch") return { label: "Web Search", Icon: Search };
  if (type === "tool-scrapeUrl") return { label: "Scrape Page", Icon: FileSearch };
  return { label: type.replace("tool-", ""), Icon: Search };
}

function ToolRow({ part }: { part: ToolPartLike }) {
  const { label, Icon } = toolLabel(part.type);
  const isPending = part.state === "input-streaming" || part.state === "input-available";
  const isError = part.state === "output-error";

  return (
    <div className="flex items-start gap-2.5 rounded-lg border border-surface-100 bg-surface-0 px-3 py-2">
      <div className="mt-0.5 shrink-0 text-brand-600">
        <Icon size={15} />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <span className="text-xs font-semibold text-surface-900">{label}</span>
          {isPending && <Loader2 size={13} className="animate-spin text-surface-900/40" />}
          {part.state === "output-available" && (
            <CheckCircle2 size={13} className="text-green-600" />
          )}
          {isError && <XCircle size={13} className="text-red-600" />}
        </div>

        {part.input && (
          <p className="mt-0.5 truncate text-xs text-surface-900/60">
            {part.input.query ? `"${part.input.query}"` : part.input.url}
          </p>
        )}

        {part.state === "output-available" && part.output && (
          <p className="mt-1 line-clamp-2 text-xs text-surface-900/50">
            {Array.isArray(part.output.results)
              ? `Found ${part.output.results.length} result(s)`
              : part.output.markdown
                ? `Scraped ${part.output.markdown.length.toLocaleString()} chars`
                : "Done"}
          </p>
        )}

        {isError && (
          <p className="mt-1 text-xs text-red-600">{part.errorText ?? "Tool call failed"}</p>
        )}
      </div>
    </div>
  );
}

export function ThoughtDashboard({ message }: ThoughtDashboardProps) {
  const toolParts = message.parts.filter(isToolPart);

  if (toolParts.length === 0) return null;

  return (
    <div className="mb-2 flex flex-col gap-1.5">
      <p className="text-xs font-medium uppercase tracking-wide text-surface-900/40">
        Agent Activity
      </p>
      {toolParts.map((part) => (
        <ToolRow key={part.toolCallId} part={part} />
      ))}
    </div>
  );
}
</Code>

<Explanation>
The component deliberately renders nothing (`return null`) when there are no tool parts yet, so it never flashes an empty "Agent Activity" header before the first tool call arrives. Truncating input queries/URLs and result summaries to short one-line previews (rather than dumping full JSON) keeps the dashboard scannable even across a full 8-step agent run; the full scraped Markdown or search result list is intentionally never shown here — only in the final synthesized report, which is what `ReportView` (Step 3.4) renders.
</Explanation>
</Step>

---
**Step 3.4: The ReportView Component**.

---

<Step number="3.4" title="The ReportView Component">
<Explanation>
`ReportView` renders the agent's final text answer, which by contract (enforced by the system prompt in Step 2.4) follows a "## Key Findings" / "## Sources" Markdown structure. Rather than pulling in a full Markdown rendering library (unnecessary dependency weight for a fairly constrained, predictable output format), we do light, targeted parsing: split the raw text on the two known headings, render the intro paragraph normally, turn "Key Findings" bullet lines into a styled list, and turn "Sources" lines into clickable links. If the agent's output doesn't match the expected shape (e.g. mid-stream, before the headings have arrived), we gracefully fall back to rendering the raw text as-is — this component must never throw or blank out while text is still streaming in.
</Explanation>

<Code language="typescript" title="src/components/ReportView.tsx">
"use client";

import { ExternalLink } from "lucide-react";

interface ReportViewProps {
  text: string;
}

function extractSection(text: string, heading: string, nextHeading?: string): string | null {
  const startIdx = text.indexOf(heading);
  if (startIdx === -1) return null;

  const afterHeading = startIdx + heading.length;
  const endIdx = nextHeading ? text.indexOf(nextHeading, afterHeading) : text.length;

  return text.slice(afterHeading, endIdx === -1 ? text.length : endIdx).trim();
}

function parseBulletLines(section: string): string[] {
  return section
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.startsWith("-") || line.startsWith("*"))
    .map((line) => line.replace(/^[-*]\s*/, ""));
}

function parseSourceLinks(section: string): { label: string; url: string }[] {
  const lines = parseBulletLines(section).length > 0 ? parseBulletLines(section) : section.split("\n");

  return lines
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .map((line) => {
      const urlMatch = line.match(/https?:\/\/[^\s)]+/);
      const url = urlMatch ? urlMatch[0] : "";
      return { label: line, url };
    })
    .filter((item) => item.url.length > 0);
}

export function ReportView({ text }: ReportViewProps) {
  const keyFindingsSection = extractSection(text, "## Key Findings", "## Sources");
  const sourcesSection = extractSection(text, "## Sources");
  const intro = extractSection(text, "", "## Key Findings") ?? text;

  const hasStructuredOutput = keyFindingsSection !== null;

  if (!hasStructuredOutput) {
    return <p className="whitespace-pre-wrap text-sm text-surface-900">{text}</p>;
  }

  const findings = parseBulletLines(keyFindingsSection);
  const sources = sourcesSection ? parseSourceLinks(sourcesSection) : [];

  return (
    <div className="flex flex-col gap-3">
      {intro.trim() && (
        <p className="whitespace-pre-wrap text-sm text-surface-900">{intro.trim()}</p>
      )}

      {findings.length > 0 && (
        <div>
          <p className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-surface-900/50">
            Key Findings
          </p>
          <ul className="flex flex-col gap-1.5">
            {findings.map((finding, i) => (
              <li key={i} className="flex gap-2 text-sm text-surface-900">
                <span className="mt-1.5 h-1 w-1 shrink-0 rounded-full bg-brand-600" />
                <span>{finding}</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {sources.length > 0 && (
        <div>
          <p className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-surface-900/50">
            Sources
          </p>
          <ul className="flex flex-col gap-1">
            {sources.map((source, i) => (
              <li key={i}>
                <a
                  href={source.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 text-xs text-brand-600 hover:underline"
                >
                  <ExternalLink size={11} />
                  {source.url}
                </a>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
</Code>

<Explanation>
`extractSection(text, "", "## Key Findings")` is a small trick to grab everything before the first heading as the "intro" — passing an empty string as the heading means `startIdx` is always `0`. The fallback path (`!hasStructuredOutput`) is what's actually shown for the first several hundred milliseconds of every streamed response, since the model emits the intro sentence before it has streamed as far as "## Key Findings" — this is why the fallback must render cleanly as plain text rather than looking broken or empty.
</Explanation>
</Step>

---

**Step 3.5: The Dashboard Page (Wiring `useChat` to Everything)**.

---

<Step number="3.5" title="The Dashboard Page (Wiring useChat to Everything)">
<Explanation>
This is the client-side integration point where every Phase 3 component and the Phase 2 API route meet. `useChat` from `@ai-sdk/react` manages the entire message list, streaming state, and part-by-part updates automatically — we don't hand-roll any fetch/streaming logic ourselves. Key details: (1) the selected model value is tracked in local state and sent as part of the request body on every message via `useChat`'s `body` option, so the server always knows which free provider/model to route to; (2) `sendMessage` (rather than a raw `fetch`) is what `ChatInput`'s `onSubmit` calls, keeping the AI SDK's message-shape contract intact; (3) for each assistant message we render `ThoughtDashboard` (tool activity) above `ReportView` (final text), and a role check distinguishes user bubbles from assistant bubbles.
</Explanation>

<Code language="typescript" title="src/app/dashboard/page.tsx">
"use client";

import { useState } from "react";
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import { UserButton } from "@clerk/nextjs";
import { ModelSelector } from "@/components/ModelSelector";
import { ChatInput } from "@/components/ChatInput";
import { ThoughtDashboard } from "@/components/ThoughtDashboard";
import { ReportView } from "@/components/ReportView";
import { getDefaultModelValue } from "@/lib/agent/models";
import { Sparkles } from "lucide-react";

export default function DashboardPage() {
  const [modelValue, setModelValue] = useState(getDefaultModelValue());

  const { messages, sendMessage, status } = useChat({
    transport: new DefaultChatTransport({
      api: "/api/chat",
      body: () => ({ modelValue }),
    }),
  });

  const isBusy = status === "submitted" || status === "streaming";

  const handleSubmit = (text: string) => {
    sendMessage({ text });
  };

  return (
    <div className="flex h-screen flex-col bg-surface-50">
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
              const textParts = message.parts.filter((p) => p.type === "text");
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
  );
}
</Code>

<Explanation>
Passing `body` as a function (`() => ({ modelValue })`) rather than a static object is important: it ensures every request reads the *current* `modelValue` state at send-time, so switching models mid-conversation takes effect on the very next message rather than being stuck at whatever value existed when `useChat` first initialized. The `status` values (`"submitted"`, `"streaming"`, `"ready"`, `"error"`) come directly from the AI SDK and are the canonical way to derive `isBusy` — no manual loading-state bookkeeping needed.
</Explanation>
</Step>

---

Saved. **Part 6 of 6 — Step 3.6: Streaming Architecture Recap & Phase 3 Wrap-up**. This completes Phase 3.

---

<Step number="3.6" title="Streaming Architecture Recap & Phase 3 Wrap-up">
<Explanation>
It's worth explicitly tracing the full data path now that all pieces exist, since streaming systems are easy to misunderstand as "black boxes." When a user submits a question: (1) `ChatInput` calls `onSubmit`, which calls `sendMessage({ text })` from `useChat`; (2) the AI SDK POSTs to `/api/chat` with the full message history plus `{ modelValue }` injected via the transport's `body` function; (3) the route handler (Step 2.6) authenticates, validates `modelValue` against `MODEL_REGISTRY`, and calls `runAgentLoop` (Step 2.5); (4) `runAgentLoop`'s `streamText` call begins emitting a stream of parts — text deltas, tool-call-start, tool-call-input-deltas, tool-result — as soon as the model produces them, without waiting for the entire multi-step run to finish; (5) `toUIMessageStreamResponse()` serializes this into the AI SDK's wire protocol; (6) back on the client, `useChat` incrementally patches the `messages` array in place, causing React to re-render `ThoughtDashboard` (Step 3.3) with each new tool part and `ReportView` (Step 3.4) with each new text delta — all before the agent's full run has completed.

This is why the two-tool "search then scrape" system prompt design (Step 2.4) pairs so well with this UI: a user watching the dashboard sees "Web Search: 'solid-state battery breakthroughs 2025'" appear within a second or two of hitting send, then "Scrape Page" rows appear as the agent reads specific sources, and only then does the final structured report begin streaming in below — genuine transparency into agent reasoning, not a fake progress bar.
</Explanation>

<Explanation>
**Phase 3 is now complete.** You have a fully working end-to-end product: a signed-in user can select any of the three free-tier models, ask a research question, and watch the agent search the web, scrape pages, and stream back a structured, cited report — all rendered live via `ThoughtDashboard` and `ReportView`. At this point the app is fully usable locally but has one significant gap: nothing persists. Refreshing the page loses the entire conversation. Phase 4 closes that gap by introducing the full Drizzle schema for conversations, messages, and tool events, wiring up save-on-stream-finish, and adding a history sidebar so users can revisit and resume past research sessions.
</Explanation>
</Step>


