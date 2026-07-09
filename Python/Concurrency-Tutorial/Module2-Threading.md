# Module 2: Threading with `ThreadPoolExecutor`

**Prerequisite:** Read the INDEX note (Concurrency vs. Parallelism, the GIL) and ideally Module 1 (Asyncio) first.

## 2.1 Why Threading Still Matters in the Asyncio Era

The GIL means threads **do not** give parallel execution of CPU-bound Python code. But threads *do* release the GIL while waiting on I/O (network, disk, `time.sleep`, DB queries), so multiple threads genuinely overlap their *waiting* time.

Use threading instead of asyncio when:
- You must use a synchronous/blocking library with no async version (legacy SDKs, `requests`, some DB drivers, GUI toolkits).
- You don't need tens of thousands of concurrent ops — dozens to low hundreds is the sweet spot.

## 2.2 The Modern, Recommended API: `ThreadPoolExecutor`

```python
import time
import requests  # pip install requests
from concurrent.futures import ThreadPoolExecutor, as_completed

URLS = [
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/2",
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/3",
    "https://httpbin.org/delay/1",
]


def fetch(url: str) -> int:
    """A BLOCKING call using the synchronous `requests` library."""
    response = requests.get(url, timeout=10)
    print(f"Fetched {url} -> status {response.status_code}")
    return response.status_code


def main() -> None:
    start = time.perf_counter()
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(fetch, url): url for url in URLS}
        for future in as_completed(futures):
            url = futures[future]
            try:
                status = future.result()
            except Exception as exc:
                print(f"{url} raised an exception: {exc}")
    print(f"Total time: {time.perf_counter() - start:.2f}s")


if __name__ == "__main__":
    main()
```
5 requests (delays 1,2,1,3,1s) finish in ~3s instead of 8 — threads overlap their waiting time. Note: plain blocking `requests` is fine here, since each call runs in its own OS thread.

### The simpler `.map()` API
```python
import time
import requests
from concurrent.futures import ThreadPoolExecutor

URLS = [
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/2",
    "https://httpbin.org/delay/1",
]


def fetch(url: str) -> int:
    response = requests.get(url, timeout=10)
    return response.status_code


def main() -> None:
    start = time.perf_counter()
    with ThreadPoolExecutor(max_workers=5) as executor:
        results = list(executor.map(fetch, URLS))
    print("Statuses:", results)
    print(f"Total time: {time.perf_counter() - start:.2f}s")


if __name__ == "__main__":
    main()
```

## 2.3 Managing Shared State: Race Conditions and Locks

### The Problem: An Unsafe Counter
```python
import threading

counter = 0


def increment(times: int) -> None:
    global counter
    for _ in range(times):
        # This looks atomic, but it is NOT:
        # READ counter -> ADD 1 -> WRITE counter — three steps, interruptible mid-way.
        counter += 1


def main() -> None:
    threads = [threading.Thread(target=increment, args=(100_000,)) for _ in range(5)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    print(f"Expected: {5 * 100_000}, Actual: {counter}")


if __name__ == "__main__":
    main()
```
Run repeatedly — `Actual` often comes out lower than 500,000 due to a race condition.

### The Fix: `threading.Lock`
```python
import threading

counter = 0
counter_lock = threading.Lock()


def increment(times: int) -> None:
    global counter
    for _ in range(times):
        with counter_lock:  # only one thread can hold this lock at a time
            counter += 1


def main() -> None:
    threads = [threading.Thread(target=increment, args=(100_000,)) for _ in range(5)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    print(f"Expected: {5 * 100_000}, Actual: {counter}")


if __name__ == "__main__":
    main()
```
Now `Actual` reliably equals `500000`.

> 💡 **Rule of thumb:** protect any shared mutable object read/written by multiple threads with a `Lock` (or use a thread-safe structure like `queue.Queue`).

## 🧪 Learning Lab 2: Broken → Fixed

### ❌ Broken: Discarding Futures (Silently Swallowed Exceptions)
```python
# broken_threading.py
import time
from concurrent.futures import ThreadPoolExecutor


def risky_download(item_id: int) -> str:
    if item_id == 3:
        raise ValueError(f"Item {item_id} failed to download!")
    time.sleep(1)
    return f"Downloaded item {item_id}"


def main() -> None:
    with ThreadPoolExecutor(max_workers=5) as executor:
        for item_id in range(5):
            executor.submit(risky_download, item_id)  # ❌ future is discarded!
    print("All downloads 'done' (but did they actually succeed?)")


if __name__ == "__main__":
    main()
```
Item 3's `ValueError` is silently swallowed — a false sense of success.

### ✅ Fixed: Always Collect and Check Results
```python
# fixed_threading.py
import time
from concurrent.futures import ThreadPoolExecutor, as_completed


def risky_download(item_id: int) -> str:
    if item_id == 3:
        raise ValueError(f"Item {item_id} failed to download!")
    time.sleep(1)
    return f"Downloaded item {item_id}"


def main() -> None:
    successes = []
    failures = []

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {
            executor.submit(risky_download, item_id): item_id
            for item_id in range(5)
        }
        for future in as_completed(futures):
            item_id = futures[future]
            try:
                result = future.result()  # ✅ re-raises any exception from the thread
                successes.append(result)
            except ValueError as exc:
                failures.append((item_id, str(exc)))

    print("Successes:", successes)
    print("Failures:", failures)


if __name__ == "__main__":
    main()
```
`future.result()` waits for the task and re-raises any exception in the main thread where you can catch it.

## 2.4 Key Takeaways
- Prefer `ThreadPoolExecutor` over raw `threading.Thread`.
- Threading = I/O-bound + blocking libraries.
- Protect shared mutable state with a `Lock`.
- Always check `.result()` on futures.
- GIL means threading won't speed up CPU-bound work.

**Next up:** Module 3: Multiprocessing.
