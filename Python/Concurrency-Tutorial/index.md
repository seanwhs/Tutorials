# Concurrency in Python

**Series:** Concurrency in Python: Asyncio, Threading, and Multiprocessing
**Audience:** Python developers who understand functions, loops, and basic OOP, but are new to concurrent/parallel programming.
**Goal:** By the end of this series, you will confidently choose between `asyncio`, `threading`, and `multiprocessing` for any real-world task, and be able to write correct, non-blocking, production-quality concurrent code.

## How this series is organized

1. **INDEX (this note)** — Conceptual foundations, the GIL, and the Decision Matrix.
2. **Module 1: Asyncio** — `async`/`await`, coroutines, the event loop, `asyncio.gather`, plus a Broken → Fixed lab.
3. **Module 2: Threading** — `ThreadPoolExecutor`, blocking I/O, shared state, plus a Broken → Fixed lab.
4. **Module 3: Multiprocessing** — `ProcessPoolExecutor`, CPU-bound work, process-safety, plus a Broken → Fixed lab.
5. **Best Practices & Summary** — Common pitfalls recap, decision cheat sheet, and the final comparison table.

## 1. Concurrency vs. Parallelism

- **Concurrency** = *dealing with* multiple tasks at once (overlapping in time).
- **Parallelism** = *doing* multiple tasks at the literal same instant (multiple CPU cores).

**Restaurant Kitchen Analogy:** Synchronous = one chef finishes one burger before starting the next. Asynchronous = the chef puts a burger on the grill and chops onions while it cooks (the chef = the Event Loop). Parallel = two chefs, two grills, truly simultaneous.

## 2. Why Python needs special handling: the GIL

CPython's **Global Interpreter Lock** ensures only one thread executes Python bytecode at a time, even on multi-core machines. I/O-bound work releases the GIL while waiting (so `threading`/`asyncio` help there); CPU-bound work holds the GIL (so `threading` gives no real speedup — you need `multiprocessing` for true parallelism).

| Bottleneck | GIL impact | Best tool |
|---|---|---|
| I/O-bound | GIL released while waiting | `asyncio` or `threading` |
| CPU-bound | GIL blocks true parallel execution | `multiprocessing` |

## 3. The Decision Matrix

- **`asyncio`** → I/O-bound, very high concurrency (thousands of API calls, WebSockets), async-native libraries available.
- **`threading`** → I/O-bound but stuck with blocking/legacy libraries (`requests`, old DB drivers).
- **`multiprocessing`** → CPU-bound (data processing, ML, number crunching) — needs true multi-core parallelism.

## 4. What's next

Head to **Module 1: Asyncio**.
