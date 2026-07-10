# Part 4: JavaScript Fundamentals

## 4.1 Concept: JavaScript is Single-Threaded

JavaScript executes on **one thread**. It cannot run two pieces of your code simultaneously. Yet websites fetch data, animate, and respond to clicks all while seemingly "waiting" for a network request — without freezing. The mechanism that makes this possible, the **Event Loop**, is the single most important JS concept for understanding why `async`/`await` looks the way it does, and why Next.js Server Components/Server Actions behave the way they do across the network boundary from Part 1.

## 4.2 ES6+ Syntax You Must Be Fluent In

```javascript
// 1. let/const instead of var — block-scoped, not function-scoped
const boardName = "DevBoard";   // reassignment forbidden
let cardCount = 0;               // reassignment allowed

// 2. Arrow functions — no own `this`, concise
const double = (n) => n * 2;
const addCard = (title) => ({ id: crypto.randomUUID(), title, done: false });

// 3. Template literals — no more string concatenation
const greeting = `Welcome to ${boardName}`;

// 4. Destructuring — pull values out of objects/arrays directly
const card = { id: 1, title: "Fix bug", column: "todo" };
const { title, column } = card;

const columns = ["todo", "in-progress", "done"];
const [first, ...rest] = columns;

// 5. Spread/rest — copy and combine
const newCard = { ...card, column: "in-progress" };  // immutable update
const allColumns = [...columns, "blocked"];

// 6. Optional chaining & nullish coalescing
const ownerName = card?.owner?.name ?? "Unassigned";

// 7. Array methods — the ones you'll use constantly
const todoCards = cardsList.filter((c) => c.column === "todo");
const titles = cardsList.map((c) => c.title);
const totalCards = cardsList.reduce((sum, c) => sum + 1, 0);
const hasBlocked = cardsList.some((c) => c.column === "blocked");

// 8. Modules — import/export
export function createCard(title) { /* ... */ }
import { createCard } from "./cards.js";
```

**Why this matters for Next.js:** every one of these patterns appears verbatim in Server Components, Server Actions, and React hooks in Part 5–6. Destructuring `{ params }`, spread-updating state immutably, `.map()` to render lists — this is the actual syntax of professional React code, not a separate topic from "JS fundamentals."

## 4.3 The Event Loop, Concretely

```javascript
console.log("1: sync start");

setTimeout(() => {
  console.log("4: timeout callback (macrotask)");
}, 0);

Promise.resolve().then(() => {
  console.log("3: promise callback (microtask)");
});

console.log("2: sync end");

// Output order:
// 1: sync start
// 2: sync end
// 3: promise callback (microtask)
// 4: timeout callback (macrotask)
```

The rule: the **call stack** runs all synchronous code first, top to bottom, uninterrupted. Once the stack is empty, the event loop drains the **microtask queue** (Promises, `async`/`await` continuations) completely, and *only then* processes one **macrotask** (`setTimeout`, I/O callbacks, UI events) before checking microtasks again. This is why a Promise callback always fires before a `setTimeout(fn, 0)` even though both are "asynchronous."

## 4.4 Callbacks -> Promises -> `async`/`await`

Three eras of the same problem (handling something that finishes later), each solving the previous era's readability problem:

```javascript
// Era 1: Callbacks (can nest into "callback hell")
fetchBoard(boardId, (board) => {
  fetchCards(board.id, (cards) => {
    renderCards(cards);
  });
});

// Era 2: Promises (chainable, but still nested .then())
fetchBoard(boardId)
  .then((board) => fetchCards(board.id))
  .then((cards) => renderCards(cards))
  .catch((err) => console.error(err));

// Era 3: async/await (reads like synchronous code, same mechanics underneath)
async function loadBoard(boardId) {
  try {
    const board = await fetchBoard(boardId);
    const cards = await fetchCards(board.id);
    renderCards(cards);
  } catch (err) {
    console.error(err);
  }
}
```

**Critical mental model:** `await` does not block the thread. It suspends the current `async` function and yields control back to the event loop, resuming only once the Promise settles. This is exactly the mechanism Next.js Server Components use to `await fetch()` or `await db.query()` directly in component bodies (Part 5) — an `async function Component()` is just a Promise-returning function like any other.

## 4.5 Implementation: DevBoard's Vanilla JS Interactivity

Before Next.js, this is how you'd add a card and persist it to a fake backend using the DOM APIs and `fetch` directly:

```html
<!-- inside <body>, after the board markup from Part 3 -->
<script src="app.js" defer></script>
```

```javascript
// app.js

// Delegated event listener: one listener handles all "+ Add card" buttons,
// even ones added dynamically later — this is the professional pattern,
// versus attaching a listener to every button individually.
document.querySelector(".board").addEventListener("click", async (event) => {
  const button = event.target.closest(".add-card-btn");
  if (!button) return;

  const column = button.closest(".column");
  const title = prompt("Card title:");
  if (!title) return;

  const newCardEl = renderCardSkeleton(title);
  column.querySelector(".card-list").appendChild(newCardEl);

  try {
    const saved = await createCardOnServer(title, column.id);
    newCardEl.dataset.id = saved.id;   // reconcile with server-assigned id
  } catch (err) {
    newCardEl.remove();               // rollback the optimistic UI on failure
    alert("Failed to save card. Please try again.");
  }
});

function renderCardSkeleton(title) {
  const li = document.createElement("li");
  li.className = "card";
  li.innerHTML = `<article><h3>${escapeHtml(title)}</h3></article>`;
  return li;
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}

async function createCardOnServer(title, columnId) {
  const response = await fetch("/api/cards", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title, columnId }),
  });

  if (!response.ok) {
    throw new Error(`Server responded ${response.status}`);
  }

  return response.json();
}
```

Walk through what's happening against Part 1's Request-Response diagram: clicking "+ Add card" triggers a `POST /api/cards` — the browser opens a new HTTP request-response cycle, the UI updates *optimistically* before the response even returns, and rolls back only if the server rejects it. This exact optimistic-update pattern reappears in Part 6 as React's `useOptimistic` hook — same idea, framework-managed instead of hand-rolled.

## 4.6 `this`, Closures, and Why Arrow Functions Matter for Event Handlers

```javascript
const boardController = {
  cardCount: 0,
  handleAdd() {
    // Regular function as a callback loses `this` binding when detached:
    document.querySelector(".add-card-btn").addEventListener("click", function () {
      this.cardCount++;   // BUG: `this` here is the button element, not boardController
    });

    // Arrow function preserves the lexical `this` from where it was defined:
    document.querySelector(".add-card-btn").addEventListener("click", () => {
      this.cardCount++;   // Correct: `this` is boardController
    });
  },
};
```

A **closure** is a function that remembers the variables from its enclosing scope even after that scope has finished executing:

```javascript
function createCardCounter() {
  let count = 0;
  return function () {
    count += 1;
    return count;
  };
}

const counter = createCardCounter();
counter(); // 1
counter(); // 2 — `count` persisted between calls via closure, with no global variable
```

## Exercise Challenge

1. Rewrite `createCardOnServer` to also handle a `401 Unauthorized` response distinctly from other errors (e.g., redirect to a login page instead of showing a generic alert).
2. Predict the console output order of this snippet, then run it to check yourself:

```javascript
console.log("A");
setTimeout(() => console.log("B"), 0);
Promise.resolve().then(() => console.log("C")).then(() => console.log("D"));
console.log("E");
```

## Solution & Explanation

```javascript
async function createCardOnServer(title, columnId) {
  const response = await fetch("/api/cards", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title, columnId }),
  });

  if (response.status === 401) {
    window.location.href = "/login";
    throw new Error("Unauthorized");
  }
  if (!response.ok) {
    throw new Error(`Server responded ${response.status}`);
  }
  return response.json();
}
```

Output order: `A`, `E`, `C`, `D`, `B`. All synchronous code (`A`, `E`) runs first. Then the microtask queue drains fully — both chained `.then()` callbacks (`C` then `D`) — before the event loop even looks at the macrotask queue where `B` (the `setTimeout`) is waiting.

---
*Next: `Roadmap Tutorial - Part 5: The Next.js Leap`*
