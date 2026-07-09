# Module 4: Best Practices & Summary

**Prerequisite:** Completes the INDEX + Modules 1–3. This is your practical cheat sheet.

## 1. Never Block the Event Loop in Async Code

- ❌ `time.sleep()`, `requests.get()`, sync DB drivers, or CPU-heavy loops inside `async def` freeze the **entire** event loop.
- ✅ Use async-native libraries: `aiohttp`/`httpx` instead of `requests`; `asyncpg`/`motor`/async ORM modes instead of blocking DB drivers; `aiofiles` instead of blocking `open()`; `asyncio.sleep()` instead of `time.sleep()`.

### If stuck with a blocking library
Offload it to a thread pool via `loop.run_in_executor` so it doesn't block the event loop:
```python
import asyncio
import requests  # blocking library, no async version available


def blocking_fetch(url: str) -> int:
    response = requests.get(url, timeout=10)
    return response.status_code


async def main() -> None:
    loop = asyncio.get_running_loop()
    urls = [
        "https://httpbin.org/delay/1",
        "https://httpbin.org/delay/2",
        "https://httpbin.org/delay/1",
    ]
    tasks = [loop.run_in_executor(None, blocking_fetch, url) for url in urls]
    results = await asyncio.gather(*tasks)
    print("Statuses:", results)


if __name__ == "__main__":
    asyncio.run(main())
```
Asyncio for orchestration, thread pool for the one unavoidable blocking dependency.

## 2. Don't Forget `await`
```python
async def get_price(symbol: str) -> float:
    await asyncio.sleep(0.5)
    return 123.45


async def main() -> None:
    result = get_price("AAPL")       # ❌ BUG: forgot 'await'
    print(result)                     # prints "<coroutine object get_price at 0x...>"
    print(await get_price("AAPL"))    # ✅ correctly prints 123.45
```
Watch for `RuntimeWarning: coroutine 'xyz' was never awaited`.

## 3. Manage Shared State Carefully

| Model | Shared memory by default? | Protection |
|---|---|---|
| **Asyncio** | Yes (single thread) — races rare but possible across `await` points | `asyncio.Lock()` |
| **Threading** | Yes — all threads share process memory | `threading.Lock()`/`RLock`/`Semaphore`/`queue.Queue` |
| **Multiprocessing** | **No** — separate memory per process | `multiprocessing.Value`/`Array`/`Manager` + `Lock`, or better, just pass data in/out |

**General rule:** avoid shared mutable state entirely when possible — pass data in, get results out.

## 4. Match the Tool to the Bottleneck

- Waiting + need thousands of concurrent ops → **`asyncio`**
- Waiting + stuck with blocking/legacy libraries → **`threading`**
- Computing (CPU-bound) → **`multiprocessing`**

You can combine them: e.g., an asyncio server using `run_in_executor` for blocking calls and dispatching CPU-heavy work to a `ProcessPoolExecutor`.

## 5. Final Summary Table

| Approach | Concurrency Model | True Parallelism? | Best For | Key API | Typical Scale | Watch Out For |
|---|---|---|---|---|---|---|
| **Asyncio** | Single-threaded event loop | No | I/O-bound, very high concurrency (API calls, scraping, WebSockets, web servers) | `asyncio`, `async`/`await`, `asyncio.gather` | Thousands of tasks | Blocking calls freeze the loop; forgetting `await`; mixing sync libraries |
| **Threading** | Multiple OS threads, GIL-limited | No (CPU); yes (I/O overlap) | I/O-bound with blocking/legacy libraries | `concurrent.futures.ThreadPoolExecutor` | Tens–low hundreds | Race conditions; forgetting `.result()` |
| **Multiprocessing** | Multiple OS processes, separate interpreters | **Yes** | CPU-bound work (data processing, ML) | `concurrent.futures.ProcessPoolExecutor` | Bounded by CPU cores | Memory/startup overhead; picklability; no shared memory |

## 6. Where to Go From Here
- Re-run Module 3's `benchmark_cpu_bound.py` yourself.
- Re-break and re-fix the labs from Modules 1–3 as a self-test.
- Stretch goal: combine an asyncio app with `ProcessPoolExecutor` offloading via `run_in_executor`.

*This concludes the series. Return to the INDEX anytime for the full table of contents.*
