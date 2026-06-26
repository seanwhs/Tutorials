## Python for JavaScript Developers — Part 7: File I/O and Context Managers (`with` ↔ try/finally)

By Part 6, your readers can write, structure, and test Python in a way that feels comfortably “Node-like”. A natural next step is **working with files and external resources**, since that’s a staple in both backend and tooling workflows.

In JS, the mental model is:

- Use `fs` (or `fs/promises`) to read/write files  
- Remember to close file handles or rely on high-level helpers  
- Sometimes wrap resource usage in `try/finally` for cleanup  

Python has a very opinionated, ergonomic way to handle this: **context managers** with the `with` statement. That pattern shows up not only for files, but also for DB connections, HTTP clients, locks, and more—so it’s high leverage.

***

### Reading Files ↔ `fs.readFile` / `fs/promises.readFile`

Start with the basics: “just get the contents of a file”.

#### Python

```python
# simple read
with open("data.txt", "r", encoding="utf-8") as f:
    contents = f.read()
    print(contents)
```

#### JavaScript (Node, promise-based)

```javascript
import { readFile } from "node:fs/promises";

const contents = await readFile("data.txt", "utf-8");
console.log(contents);
```

Mapping:

- `open(path, mode)` returns a file object.  
- `with ... as f:` ensures the file is automatically closed when the block exits.  
- `f.read()` ≈ `await readFile(...)`.  

You can call out explicitly that Python’s `with` here is “like a built-in `try/finally` wrapper to guarantee cleanup” for JS devs.

***

### Writing and Appending Files

Cover the equivalent of `writeFile` / `appendFile` patterns.

#### Python: write and append

```python
# overwrite / create
with open("output.txt", "w", encoding="utf-8") as f:
    f.write("Hello from Python!\n")

# append
with open("output.txt", "a", encoding="utf-8") as f:
    f.write("Another line.\n")
```

#### JavaScript

```javascript
import { writeFile, appendFile } from "node:fs/promises";

await writeFile("output.txt", "Hello from JavaScript!\n");
await appendFile("output.txt", "Another line.\n");
```

Mental model:

- Mode `"w"` ≈ “write/overwrite”; `"a"` ≈ “append”.  
- Same idea as Node’s `flags`, but much simpler at the call site.  

Highlight that the `with` block is idiomatic Python; opening a file without `with` is possible but discouraged for everyday use.

***

### Context Managers ↔ try/finally Cleanup

This is the core conceptual bridge: **context managers** are Python’s way of encapsulating “acquire + release” logic.

JS devs usually write something like:

```javascript
async function useResource() {
  const resource = await acquire();
  try {
    // use resource
  } finally {
    await resource.close();
  }
}
```

Python wraps that pattern into a reusable protocol: `__enter__` and `__exit__`, surfaced as `with`.

#### Python (custom context manager)

```python
class Resource:
    def __enter__(self):
        print("acquire")
        return self

    def __exit__(self, exc_type, exc, tb):
        print("release")

    def use(self):
        print("using resource")

with Resource() as r:
    r.use()
```

You don’t need readers to implement their own immediately, but showing this once makes it clear that:

- `with` is not “file magic”—it’s a general pattern.  
- Many libraries implement context managers for safe resource handling (HTTP sessions, DB connections, locks).

Framing: “Think of context managers as reusable `try/finally` blocks with a nice syntax.”

***

### Common Real-World Context Manager Patterns

Show patterns JS devs are likely to care about.

1. **HTTP client sessions** (similar to keeping an Axios instance, but with automatic cleanup):

   ```python
   import aiohttp

   async def fetch(url):
       async with aiohttp.ClientSession() as session:
           async with session.get(url) as resp:
               return await resp.text()
   ```

2. **Database connections / transactions** (similar to a pooled connection with `try/finally` around commit/rollback):

   ```python
   import sqlite3

   with sqlite3.connect("app.db") as conn:
       cursor = conn.cursor()
       cursor.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT)")
       conn.commit()
   ```

3. **Locks for concurrency** (like `mutex.lock()` / `finally unlock()`):

   ```python
   import threading

   lock = threading.Lock()

   def critical_section():
       with lock:
           # safely modify shared state
           ...
   ```

Each of these is “acquire → use → release”, just like JS patterns, but expressed through `with`.

***

### Streaming / Line-by-Line Reading

JS devs working with logs or large files will appreciate the “iterate over lines” pattern.

#### Python

```python
with open("data.txt", "r", encoding="utf-8") as f:
    for line in f:
        print(line.strip())
```

#### JavaScript (rough equivalent with streams)

```javascript
import { createReadStream } from "node:fs";
import readline from "node:readline";

const rl = readline.createInterface({
  input: createReadStream("data.txt"),
});

for await (const line of rl) {
  console.log(line.trim());
}
```

Mapping:

- Python’s file object is iterable; `for line in f` gives you lines one by one.  
- This is conceptually similar to a readable stream you iterate over in Node.  

You can position this as “Python hides the streaming complexity for common line-by-line cases; you just loop over the file.”

***

### Error Handling with File I/O

Bring back the `try/except` mapping from earlier parts and show it around files.

#### Python

```python
try:
    with open("config.json", "r", encoding="utf-8") as f:
        config_data = f.read()
except FileNotFoundError:
    config_data = "{}"  # default
```

#### JavaScript

```javascript
import { readFile } from "node:fs/promises";

let configData;
try {
  configData = await readFile("config.json", "utf-8");
} catch (err) {
  if (err.code === "ENOENT") {
    configData = "{}";
  } else {
    throw err;
  }
}
```

Parallel:

- `FileNotFoundError` ≈ `ENOENT` errors.  
- Again, exceptions/`try/except` are the normal way to handle failures in Python APIs.

***

### What you have achieved?

After this part, you should be comfortable with:

- Reading and writing files in Python with idiomatic `with open(...)` blocks.  
- Understanding context managers as “Python’s ergonomic `try/finally` for resources”.  
- Recognizing the pattern in HTTP clients, DB connections, locks, and other resource-heavy APIs.  
- Handling file-related errors cleanly with `try/except`.

