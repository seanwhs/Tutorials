# Module 3: Parallelism with `ProcessPoolExecutor`

**Prerequisite:** Read the INDEX note (GIL, Concurrency vs. Parallelism) first. Modules 1–2 are helpful context but not required.

## 3.1 Why Multiprocessing for CPU-Bound Work

CPU-bound tasks (heavy math, image/video transforms, data crunching, ML) spend time *computing*, not waiting. Threading can't parallelize this in CPython because the GIL only lets one thread run bytecode at a time. `multiprocessing` sidesteps this by launching **separate OS processes**, each with its own interpreter and GIL.

**Trade-offs:** higher memory usage, slower startup than threads, data must be **picklable**.

## 3.2 Proving the GIL Effect: CPU-bound Benchmark

```python
# benchmark_cpu_bound.py
import time
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor


def cpu_heavy(n: int) -> int:
    """A deliberately CPU-bound function: sum of squares up to n."""
    total = 0
    for i in range(n):
        total += i * i
    return total


NUMS = [20_000_000] * 4  # 4 chunks of heavy work


def run_sequential() -> None:
    start = time.perf_counter()
    results = [cpu_heavy(n) for n in NUMS]
    print(f"Sequential: {time.perf_counter() - start:.2f}s")


def run_threaded() -> None:
    start = time.perf_counter()
    with ThreadPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(cpu_heavy, NUMS))
    print(f"ThreadPoolExecutor: {time.perf_counter() - start:.2f}s")


def run_multiprocess() -> None:
    start = time.perf_counter()
    with ProcessPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(cpu_heavy, NUMS))
    print(f"ProcessPoolExecutor: {time.perf_counter() - start:.2f}s")


if __name__ == "__main__":
    run_sequential()
    run_threaded()
    run_multiprocess()
```

**Expected results (4-core machine, approximate):**
- Sequential: ~8s baseline
- ThreadPoolExecutor: ~same or slightly slower — GIL prevents true parallel speedup
- ProcessPoolExecutor: ~2–4x faster — separate GILs on separate cores

## 3.3 `ProcessPoolExecutor` in Practice

```python
# image_style_resize_example.py
import time
from concurrent.futures import ProcessPoolExecutor, as_completed


def process_data_chunk(chunk_id: int, size: int) -> dict:
    """Simulates a CPU-heavy data processing job (e.g., feature engineering)."""
    total = sum(i * i for i in range(size))
    return {"chunk_id": chunk_id, "result": total}


def main() -> None:
    chunks = [(i, 10_000_000) for i in range(8)]

    start = time.perf_counter()
    with ProcessPoolExecutor(max_workers=4) as executor:
        futures = {
            executor.submit(process_data_chunk, chunk_id, size): chunk_id
            for chunk_id, size in chunks
        }
        for future in as_completed(futures):
            result = future.result()
            print(f"Chunk {result['chunk_id']} done -> {result['result']}")

    print(f"Total time: {time.perf_counter() - start:.2f}s")


if __name__ == "__main__":
    main()
```

> ⚠️ **Critical rule:** always guard your entry point with `if __name__ == "__main__":` — on Windows/macOS "spawn," child processes re-import your main module; without this guard you'd recursively spawn infinite processes.

## 3.4 Data Must Be Picklable

```python
# This works fine — plain data
def process(record: dict) -> dict:
    record["processed"] = True
    return record

# This would FAIL to pickle if passed as an argument:
# def process(connection, record):  # ❌ a live DB connection object
#     ...
# Instead, open the connection *inside* the worker function itself.
```

## 🧪 Learning Lab 3: Broken → Fixed

### ❌ Broken: Sharing State Directly Like You Would with Threads
```python
# broken_multiprocessing.py
from multiprocessing import Process

counter = 0  # ❌ this will NOT be shared across processes


def increment_counter(amount: int) -> None:
    global counter
    for _ in range(amount):
        counter += 1
    print(f"Inside child process, counter = {counter}")


def main() -> None:
    processes = [Process(target=increment_counter, args=(100_000,)) for _ in range(4)]
    for p in processes:
        p.start()
    for p in processes:
        p.join()

    print(f"Final counter in main process: {counter}")


if __name__ == "__main__":
    main()
```
Each child prints `counter = 100000`, but the main process's `counter` stays `0` — processes don't share memory by default.

### ✅ Fixed: Using `multiprocessing.Value`
```python
# fixed_multiprocessing.py
from multiprocessing import Process, Value, Lock


def increment_counter(shared_counter, lock, amount: int) -> None:
    for _ in range(amount):
        with lock:  # protect against race conditions across processes too
            shared_counter.value += 1


def main() -> None:
    shared_counter = Value("i", 0)  # 'i' = C int, allocated in shared memory
    lock = Lock()

    processes = [
        Process(target=increment_counter, args=(shared_counter, lock, 100_000))
        for _ in range(4)
    ]
    for p in processes:
        p.start()
    for p in processes:
        p.join()

    print(f"Expected: {4 * 100_000}, Actual: {shared_counter.value}")


if __name__ == "__main__":
    main()
```
`multiprocessing.Value` allocates OS-backed shared memory; still need a `Lock`. Prefer passing data in/out over shared mutable state where possible — check out `multiprocessing.Manager()` for richer shared collections if needed.

## 3.5 Key Takeaways
- Only `multiprocessing` gets genuine parallel execution of CPU-bound code.
- Threads give no CPU-bound speedup — always benchmark.
- Guard entry point with `if __name__ == "__main__":`.
- Data must be picklable; open connections inside the worker.
- Globals aren't shared across processes — use `Value`/`Array`/`Manager` + locks only when necessary.

**Next up:** Best Practices & Summary.
