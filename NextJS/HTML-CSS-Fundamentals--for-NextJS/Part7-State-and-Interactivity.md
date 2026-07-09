# Part 7: State & Interactivity

## 1. Browser Reality — Native Stateful Elements
`<details>`/`<summary>` and `<input type="checkbox">` already track their own state with zero JavaScript — the browser owns `open`/`checked`, exposes it to CSS (`:checked`, `[open]`) and assistive tech automatically.

## 2. Browser Reality — Manual DOM Mutation
A hand-rolled counter with `let count = 0` + `addEventListener` + manual `textContent` updates — showing the core problem: state and UI are two separate things you must sync by hand.

## 3. React Translation — `useState`
Collapses "the value" and "what's on screen" into one declarative relationship. Mapped line-by-line: `useState` ↔ plain variable, JSX re-render ↔ manual `textContent`, `onClick` ↔ `addEventListener`.

## 4. Why `'use client'` Exists
The server/client boundary explained as a direct consequence of Part 5/6's client-server split: interactivity requires a browser event loop, which doesn't exist on the server.

## 5. Controlled vs. Uncontrolled Inputs
Native `<input>` already tracks its own value; React's controlled pattern deliberately re-implements that only when the value needs to drive other UI.

**Exercise + Solution:** Build `Toggle.tsx` with `useState`/`aria-expanded`, explain the client/server boundary, then build the zero-JS `<details>` equivalent — with explicit guidance on when to reach for each.
