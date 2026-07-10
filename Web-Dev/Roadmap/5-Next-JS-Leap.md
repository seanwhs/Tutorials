# Part 5: The Next.js Leap

## 5.1 Concept: What Problem Does Next.js Actually Solve?

Recall Part 1's Request-Response cycle and Part 4's single-threaded JS. A pure client-side React app sends the browser a nearly empty HTML shell plus a JS bundle; the *entire* app — including data fetching — happens after that JS downloads, parses, and executes. That's a lot of round trips stacked serially on the client, all visible to the user as blank-screen time.

Next.js's App Router restructures this: components can render **on the server**, during the original response-generation step, so the HTML that arrives already contains real content — no waiting for client JS to fetch data that the server already had available. This is the entire reason Server Components exist. They're not "a new syntax to learn" — they're a way of writing UI code that runs on the server side of the Part 1 diagram instead of the client side.

## 5.2 Server Components vs. Client Components

| | Server Component (default) | Client Component (`"use client"`) |
|---|---|---|
| Runs on | Server only | Server (initial HTML) + browser (hydration + interactivity) |
| Can use `useState`/`useEffect`/event handlers | No | Yes |
| Can directly `await` a database call / secret API key | Yes, safely | No — would leak secrets to the browser |
| Ships JS to the browser | No (zero JS cost) | Yes |
| Default in App Router | Yes | No — must opt in |

```tsx
// app/board/page.tsx — a Server Component (no directive needed, this is the default)
async function getBoard() {
  // In a real app this would be `await db.board.findFirst(...)`.
  // Because this runs on the server, it can safely use secrets, direct DB
  // access, etc. — none of this code or its dependencies reach the browser.
  return {
    id: "1",
    name: "DevBoard",
    columns: [
      { id: "todo", name: "Todo", cards: [{ id: "c1", title: "Fix login bug" }] },
      { id: "in-progress", name: "In Progress", cards: [] },
      { id: "done", name: "Done", cards: [] },
    ],
  };
}

export default async function BoardPage() {
  const board = await getBoard();

  return (
    <main className="board">
      {board.columns.map((column) => (
        <section key={column.id}>
          <h2>{column.name}</h2>
          <ul>
            {column.cards.map((card) => (
              <li key={card.id}>{card.title}</li>
            ))}
          </ul>
        </section>
      ))}
    </main>
  );
}
```

Notice: `async function BoardPage()` — a React component that is also an `async` function, directly `await`-ing data in its body. This is only legal because it's a Server Component; it's exactly the `async`/`await` mechanics from Part 4, just running server-side.

## 5.3 Adding Interactivity: The Client Component Boundary

The moment you need `useState`, `onClick`, or any browser API, you need a Client Component — a deliberate, explicit opt-in:

```tsx
// app/components/AddCardButton.tsx
"use client";

import { useState } from "react";

export function AddCardButton({ columnId }: { columnId: string }) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div>
      <button type="button" onClick={() => setIsOpen(true)}>
        + Add card
      </button>
      {isOpen && (
        <form onSubmit={(e) => { e.preventDefault(); /* Part 6 handles this properly */ }}>
          <input name="title" placeholder="Card title" autoFocus />
          <button type="submit">Save</button>
        </form>
      )}
    </div>
  );
}
```

`"use client"` is a boundary marker — everything *imported into* this file also runs on the client from this point down the tree. It does not mean "this file only runs in the browser"; Client Components still render once on the server for the initial HTML (this is what makes SSR + hydration work — see Appendix B), then "take over" in the browser for interactivity.

## 5.4 Hydration, Concretely

1. Server renders `BoardPage` (and any Client Components inside it) to HTML and sends it — the user sees content immediately, before any JS has run.
2. The browser downloads the JS bundle for the Client Components only (Server Components ship *zero* JS).
3. React "hydrates": it attaches event listeners to the existing DOM nodes, without re-creating them, so `onClick`, `useState`, etc. become live.

This is why Next.js apps feel fast on first load (real HTML immediately) *and* interactive afterward (hydration attaches behavior) — it's genuinely the best of both eras from 5.1, not a compromise.

## 5.5 Composition: Server Components Rendering Client Components (and vice versa)

```tsx
// app/board/page.tsx (Server Component)
import { AddCardButton } from "@/app/components/AddCardButton";

export default async function BoardPage() {
  const board = await getBoard();
  return (
    <main className="board">
      {board.columns.map((column) => (
        <section key={column.id}>
          <h2>{column.name}</h2>
          <ul>
            {column.cards.map((card) => <li key={card.id}>{card.title}</li>)}
          </ul>
          {/* A Server Component can render a Client Component directly */}
          <AddCardButton columnId={column.id} />
        </section>
      ))}
    </main>
  );
}
```

The rule that trips up beginners: a Client Component **cannot** `import` a Server Component directly (Server Components often use server-only APIs that can't exist in a browser bundle). But a Server Component **can** pass a Server Component as `children` *into* a Client Component — the Client Component never needs to know what's inside `children`, so no server-only code crosses the boundary. This pattern is covered in depth in the companion React 19 series (Module 4) — worth cross-referencing once you're comfortable here.

## 5.6 Implementation: File-Based Routing in the App Router

```
app/
  layout.tsx          -> wraps every page (shared <html>, <body>, nav)
  page.tsx            -> route: /
  globals.css
  board/
    page.tsx          -> route: /board
    [boardId]/
      page.tsx        -> route: /board/123  (dynamic segment)
  api/
    cards/
      route.ts        -> route: /api/cards (a Route Handler, not a page)
```

```tsx
// app/layout.tsx
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header>
          <h1>DevBoard</h1>
        </header>
        {children}
      </body>
    </html>
  );
}
```

```tsx
// app/board/[boardId]/page.tsx
// Next.js 16: dynamic route params are Promise-based — this is a breaking
// change from Next.js 14 and earlier that trips up a lot of tutorials online.
export default async function BoardDetailPage({
  params,
}: {
  params: Promise<{ boardId: string }>;
}) {
  const { boardId } = await params;
  const board = await getBoard(boardId);

  return <h2>Board: {board.name}</h2>;
}
```

## 5.7 Route Handlers: The Modern Replacement for a Separate Backend

Recall Part 1's HTTP verbs. A Route Handler is literally a function per verb, living at a URL path:

```typescript
// app/api/cards/route.ts
import { NextRequest, NextResponse } from "next/server";

// Fake in-memory "database" for this Part — replaced with Postgres in Part 8
let cards = [{ id: "c1", title: "Fix login bug", columnId: "todo" }];

export async function GET() {
  return NextResponse.json(cards);
}

export async function POST(request: NextRequest) {
  const body = await request.json();

  if (!body.title || typeof body.title !== "string") {
    return NextResponse.json({ error: "Title is required" }, { status: 400 });
  }

  const newCard = { id: crypto.randomUUID(), title: body.title, columnId: body.columnId };
  cards.push(newCard);

  return NextResponse.json(newCard, { status: 201 });
}
```

This `POST` handler is the direct, professional equivalent of the vanilla `fetch("/api/cards", { method: "POST" })` call from Part 4.6 — same HTTP contract, now served by Next.js instead of a hand-rolled Node server.

## Exercise Challenge

1. Add a `DELETE` handler to `app/api/cards/route.ts` that removes a card by `id` (sent as a query parameter), returning `204 No Content` on success and `404 Not Found` if the id doesn't exist.
2. Convert `BoardPage` to fetch from `/api/cards` (via `fetch` inside the Server Component) instead of the hardcoded `getBoard()` function, and explain in one sentence why this `fetch` call, made from a Server Component, never touches the browser's network tab.

## Solution & Explanation

```typescript
export async function DELETE(request: NextRequest) {
  const id = request.nextUrl.searchParams.get("id");
  const index = cards.findIndex((c) => c.id === id);

  if (index === -1) {
    return NextResponse.json({ error: "Card not found" }, { status: 404 });
  }

  cards.splice(index, 1);
  return new NextResponse(null, { status: 204 });
}
```

Because the `fetch` call inside a Server Component executes on the server during the original request-response cycle (Part 1), the browser's DevTools Network tab — which only observes traffic between *browser and server* — never sees it; it's a server-to-server (or server-to-itself) call that resolves before any HTML is sent to the client at all.

---
*Next: `Roadmap Tutorial - Part 6: Data Orchestration`*
