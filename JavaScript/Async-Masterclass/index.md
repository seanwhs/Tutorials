## Async JS Masterclass — INDEX (Start Here)

A 4-phase, code-heavy tutorial series taking an intermediate JS developer from "I know sync JS" to "I can design a production retry/abort orchestration layer."

### How this series is organized

| Note Title | Covers |
|---|---|
| `Async JS Masterclass - Phase 1 (Foundations)` | Single-threaded JS, Call Stack vs Heap, Event Loop mechanics, Libuv phases, Exercise + Solution |
| `Async JS Masterclass - Phase 2 (Evolution of Patterns)` | Callback Hell, Promise anatomy (pending/fulfilled/rejected), Async/Await + try/catch, Exercise + Solution |
| `Async JS Masterclass - Phase 3 (Advanced Execution)` | Microtasks vs Macrotasks (process.nextTick vs setTimeout), Promise.all/race/allSettled/any, Async Iterators/Generators, AbortController, Exercise + Solution |
| `Async JS Masterclass - Phase 4 (Practical Architecture)` | Anti-patterns, Chrome DevTools debugging, State management (React hooks + the D-H-A state-shape pattern), the "Final Boss" retry/abort orchestration layer |
| `Async JS Masterclass - Appendix (Full Codebase Reference)` | The complete, consolidated Final Boss codebase in one place, file by file |

### Pedagogical conventions used throughout

- `##` = Phase headings, `###` = sub-topics
- Every concept is immediately followed by a **"Learning Lab"** runnable code block
- `>` blockquotes are **Pro-Tips**
- Each phase ends with an **Exercise** followed immediately by its **Solution**
- ASCII diagrams are used for the Call Stack, Event Loop, and Libuv phases
- All code is ES6+, Node.js-oriented but browser-portable unless stated otherwise

### Target audience

Intermediate developers who know JS syntax but haven't internalized *when* code actually executes — this series builds that mental model from the ground up, then applies it to real orchestration problems.
