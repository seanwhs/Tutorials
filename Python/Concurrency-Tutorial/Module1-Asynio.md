# Module 1: Mastering Asyncio (`async`/`await`)

**Prerequisite:** Read the INDEX note first for the Concurrency vs. Parallelism and GIL concepts.

## 1.1 Core Vocabulary
- **Coroutine:** An `async def` function. Calling it doesn't run the body — it returns a coroutine object that must be `await`-ed.
- **`await`:** Pauses the current coroutine without blocking the rest of the program; control returns to the event loop.
- **Event Loop:** The single-threaded scheduler ("the chef") that runs coroutines. `asyncio.run(main())` creates it, runs `main()`, then closes it.
- **Task:** A coroutine scheduled to run concurrently (`asyncio.create_task()` or via `asyncio.gather()`).

## 1.2 Your First Coroutine
```python
import asyncio
import time


async def say_hello(name: str, delay: float) -> None:
    """A simple coroutine that pretends to do I/O work."""
    print(f"[{time.strftime('%X')}] Starting greeting for {name}")
    await asyncio.sleep(delay)  # non-blocking "wait" — releases control to the event loop
    print(f"[{time.strftime('%X')}] Hello, {name}!")


async def main() -> None:
    await say_hello("Alice", 2)
    await say_hello("Bob", 2)


if __name__ == "__main__":
    start = time.perf_counter()
    asyncio.run(main())
    print(f"Total time: {time.perf_counter() - start:.2f}s")
```
**Notice:** takes ~4s (2+2) — awaiting sequentially doesn't give concurrency, just non-blocking waits.

## 1.3 Real Concurrency with `asyncio.gather`
```python
import asyncio
import time


async def say_hello(name: str, delay: float) -> str:
    print(f"[{time.strftime('%X')}] Starting greeting for {name}")
    await asyncio.sleep(delay)
    print(f"[{time.strftime('%X')}] Hello, {name}!")
    return f"Greeted {name}"


async def main() -> None:
    results = await asyncio.gather(
        say_hello("Alice", 2),
        say_hello("Bob", 2),
        say_hello("Charlie", 1),
    )
    print("Results:", results)


if __name__ == "__main__":
    start = time.perf_counter()
    asyncio.run(main())
    print(f"Total time: {time.perf_counter() - start:.2f}s")
```
**Notice:** now ~2s, not 5. All three overlap. `gather()` returns results in input order.

## 1.4 Realistic Example: Fetching Many URLs Concurrently
```python
import asyncio
import time
import aiohttp  # pip install aiohttp

URLS = [
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/2",
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/3",
    "https://httpbin.org/delay/1",
]


async def fetch(session: aiohttp.ClientSession, url: str) -> int:
    async with session.get(url) as response:
        await response.text()
        print(f"Fetched {url} -> status {response.status}")
        return response.status


async def main() -> None:
    async with aiohttp.ClientSession() as session:
        tasks = [fetch(session, url) for url in URLS]
        statuses = await asyncio.gather(*tasks)
    print("All statuses:", statuses)


if __name__ == "__main__":
    start = time.perf_counter()
    asyncio.run(main())
    print(f"Total time: {time.perf_counter() - start:.2f}s")
```
5 requests (delays 1,2,1,3,1s) → sequentially 8s, concurrently ~3s (bounded by the slowest request).

## 1.5 `create_task` vs. `gather`
```python
import asyncio


async def background_job(name: str, delay: float) -> None:
    await asyncio.sleep(delay)
    print(f"{name} finished")


async def main() -> None:
    task1 = asyncio.create_task(background_job("Job A", 2))
    task2 = asyncio.create_task(background_job("Job B", 1))

    print("Both jobs scheduled, doing other work now...")
    await asyncio.sleep(0.5)
    print("Other work done, now waiting for jobs to finish...")

    await task1
    await task2


if __name__ == "__main__":
    asyncio.run(main())
```

## 🧪 Learning Lab 1: Broken → Fixed

### ❌ Broken: Blocking the Event Loop
```python
# broken_asyncio.py
import asyncio
import time


async def broken_task(name: str, delay: float) -> None:
    print(f"Starting {name}")
    time.sleep(delay)  # ❌ BLOCKING call — freezes the ENTIRE event loop
    print(f"Finished {name}")


async def main() -> None:
    await asyncio.gather(
        broken_task("Task A", 2),
        broken_task("Task B", 2),
        broken_task("Task C", 2),
    )


if __name__ == "__main__":
    start = time.perf_counter()
    asyncio.run(main())
    print(f"Total time: {time.perf_counter() - start:.2f}s")
```
Takes ~6s, not 2 — `time.sleep()` blocks the whole thread the loop runs on.

### ✅ Fixed
```python
# fixed_asyncio.py
import asyncio
import time


async def fixed_task(name: str, delay: float) -> None:
    print(f"Starting {name}")
    await asyncio.sleep(delay)  # ✅ non-blocking — yields control back to the event loop
    print(f"Finished {name}")


async def main() -> None:
    await asyncio.gather(
        fixed_task("Task A", 2),
        fixed_task("Task B", 2),
        fixed_task("Task C", 2),
    )


if __name__ == "__main__":
    start = time.perf_counter()
    asyncio.run(main())
    print(f"Total time: {time.perf_counter() - start:.2f}s")
```
Back to ~2s. Same rule applies to any blocking library call — always use async-native equivalents, or offload to a thread pool executor.

## 1.6 Key Takeaways
- Calling `async def` returns a coroutine object — must `await`/`create_task`/`gather` it.
- `await` alone ≠ concurrency; use `gather`/`create_task` for real overlap.
- Never call blocking functions inside `async def`.
- Asyncio shines with many I/O-bound ops on a single thread.

**Next up:** Module 2: Threading.
