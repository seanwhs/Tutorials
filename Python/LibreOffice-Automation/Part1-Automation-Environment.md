# Part 1: The Automation Environment

## 1.1 Why Automation Needs a Bridge: The Process Model

LibreOffice is not a Python library you `pip install` — it is a full desktop application written primarily in C++, running as its own independent OS process (`soffice.bin`). Your Python code cannot reach into its memory space directly. Two separate processes, two separate memory spaces.

**UNO (Universal Network Objects)** is the IPC framework that bridges this gap. It defines a language-neutral object model (services, interfaces, structs) and provides bridges for Basic, Python, Java, and C++ to talk to that model over pipes or TCP sockets.

- **LibreOffice process** = server holding live document objects.
- **UNO bridge** = marshalling layer serializing calls/returns across the process boundary.
- **Your Python script** = client calling methods on *remote proxy objects*.

## 1.2 Two Ways to Run Python Against LibreOffice

1. **Internal (embedded) macros** — code runs *inside* the LibreOffice process via `XSCRIPTCONTEXT` (Part 6).
2. **External scripts over a socket bridge** — headless LibreOffice + a separate Python process connecting over TCP/URP. This is our primary mode (Parts 1, 3, 4, 5, 7) — ideal for cron, CI, and server-side automation.

## 1.3 Memory & Lifecycle Considerations

- Nothing is garbage collected across the bridge automatically — always `.close()` documents you open.
- A crashed/hung `soffice.bin` ("zombie") holds the socket open, blocking future launches (see Appendix C).
- Every call is a synchronous round trip — batch bulk operations (`getDataArray()`/`setDataArray()` in Part 3) instead of looping cell by cell.

## 1.4 Installing LibreOffice and Locating Its Bundled Python

On Debian/Ubuntu:

```bash
sudo apt update
sudo apt install libreoffice libreoffice-script-provider-python python3-uno
```

On Fedora:

```bash
sudo dnf install libreoffice libreoffice-pyuno
```

On macOS (Homebrew cask):

```bash
brew install --cask libreoffice
```

Locate LibreOffice's own bundled Python interpreter (it has the `uno` module pre-installed):

```bash
# Linux
ls /usr/lib/libreoffice/program/python*
/usr/lib/libreoffice/program/python3 --version

# macOS
ls /Applications/LibreOffice.app/Contents/Resources/python*
```

Verify the `uno` module is importable from that interpreter:

```bash
/usr/lib/libreoffice/program/python3 -c "import uno; print(uno.__file__)"
```

If you'd rather use your **system Python** (recommended for real projects, so you can `pip install` normal packages like `pandas`), install the `python3-uno` bindings package (Linux) so `import uno` works from your system interpreter/venv too. On macOS/Windows this is trickier — the pragmatic fallback is to set `PYTHONPATH` to point at LibreOffice's `program` directory, or simply run automation scripts with LibreOffice's bundled interpreter directly.

## 1.5 Setting Up VS Code

1. Install the **Python extension** (Microsoft) in VS Code.
2. Create a project folder and virtual environment:

```bash
mkdir office-automation-toolkit && cd office-automation-toolkit
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install --upgrade pip
```

3. Point VS Code's Python interpreter at `.venv`, but for scripts that need `uno` directly, add this to `.vscode/settings.json` so imports resolve for linting/autocomplete (adjust path for your OS):

```json
{
  "python.analysis.extraPaths": [
    "/usr/lib/libreoffice/program"
  ],
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
}
```

4. Create the initial project layout (full tree lives in Appendix A):

```bash
mkdir -p src tests templates output
touch src/__init__.py src/uno_bridge.py requirements.txt README.md
```

## 1.6 Launching LibreOffice Headless with a Listening Socket

This is the single most important terminal command in this entire series. It starts LibreOffice with no UI, and opens a UNO Remote Protocol (URP) listener on a TCP socket that external Python processes can connect to.

```bash
soffice --headless \
        --invisible \
        --nocrashreport \
        --nodefault \
        --norestore \
        --nologo \
        --nofirststartwizard \
        --accept="socket,host=localhost,port=2002;urp;StarOffice.ComponentContext"
```

Flag reference:

- `--headless` — no GUI window is created.
- `--invisible` — belt-and-suspenders, suppresses any UI surfaces.
- `--nocrashreport` / `--norestore` — prevents the crash-recovery dialog from ever blocking headless automation.
- `--nodefault` — don't open the Start Center document picker.
- `--accept="socket,host=localhost,port=2002;urp;"` — the actual bridge: bind a TCP listener on `localhost:2002` and speak URP (UNO Remote Protocol) over it.

Run this in its own terminal tab/pane (or background it with `&`, or better, manage it with a process supervisor in production — see Part 7). Leave it running; your Python scripts will connect to it repeatedly rather than starting a new `soffice` process per script run, which is far faster and avoids the multi-second LibreOffice startup cost on every invocation.

To confirm it's listening:

```bash
# Linux/macOS
lsof -i :2002
# or
ss -tlnp | grep 2002
```

## 1.7 Your First Connection Script

Create `src/uno_bridge.py`:

```python
"""
uno_bridge.py
Core connection utility: bridges an external Python process to a running,
headless LibreOffice instance over a UNO socket connection.
"""
import socket
import time
import uno
from com.sun.star.connection import NoConnectException


class LibreOfficeConnectionError(Exception):
    """Raised when we cannot establish a UNO bridge to LibreOffice."""


def wait_for_port(host: str, port: int, timeout: float = 15.0) -> None:
    """Block until a TCP port is accepting connections, or raise on timeout."""
    deadline = time.time() + timeout
    last_error = None
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=1.0):
                return
        except OSError as exc:
            last_error = exc
            time.sleep(0.5)
    raise LibreOfficeConnectionError(
        f"Port {port} on {host} never accepted a connection "
        f"within {timeout}s. Is LibreOffice running headless with "
        f"--accept=\"socket,host={host},port={port};urp;\"? "
        f"Last socket error: {last_error}"
    )


def connect(host: str = "localhost", port: int = 2002, retries: int = 3):
    """
    Connect to a running headless LibreOffice instance and return the
    Desktop service, the entry point for opening/creating documents.
    """
    wait_for_port(host, port, timeout=15.0)

    local_context = uno.getComponentContext()
    resolver = local_context.ServiceManager.createInstanceWithContext(
        "com.sun.star.bridge.UnoUrlResolver", local_context
    )
    uno_url = (
        f"uno:socket,host={host},port={port};"
        f"urp;StarOffice.ComponentContext"
    )

    last_exc = None
    for attempt in range(1, retries + 1):
        try:
            context = resolver.resolve(uno_url)
            smgr = context.ServiceManager
            desktop = smgr.createInstanceWithContext(
                "com.sun.star.frame.Desktop", context
            )
            return desktop, context
        except NoConnectException as exc:
            last_exc = exc
            time.sleep(1.0 * attempt)  # simple backoff

    raise LibreOfficeConnectionError(
        f"Failed to connect to LibreOffice at {host}:{port} after "
        f"{retries} attempts. Original error: {last_exc}"
    )


if __name__ == "__main__":
    desktop, ctx = connect()
    print("Connected successfully.")
    print("Desktop service:", desktop)
    print("ComponentContext:", ctx)
```

Run it using LibreOffice's *own* Python interpreter (this guarantees `import uno` succeeds without extra configuration):

```bash
/usr/lib/libreoffice/program/python3 src/uno_bridge.py
```

Expected output:

```text
Connected successfully.
Desktop service: pyuno object (com.sun.star.frame.Desktop)0x...
ComponentContext: pyuno object (com.sun.star.uno.XComponentContext)0x...
```

## 1.8 Common Connection Errors and What They Mean

| Error | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: No module named 'uno'` | Running with system Python that lacks PyUNO bindings | Use LibreOffice's bundled interpreter, or install `python3-uno` (Linux), or add LO's `program` dir to `PYTHONPATH` |
| `LibreOfficeConnectionError: Port 2002 ... never accepted a connection` | `soffice` isn't running, wrong port, or `--accept` flag missing/typo'd | Re-check Section 1.6's exact command; confirm with `ss -tlnp \| grep 2002` |
| `com.sun.star.connection.NoConnectException` after port is open | LibreOffice is still initializing (first launch can take several seconds) | The `retries`/backoff loop in `connect()` handles this; increase `retries` if your machine is slow |
| Script hangs forever, no error | A stale/zombie `soffice.bin` process is holding the port without actually listening on URP | Kill it: see Appendix C |

## Checkpoint

By the end of Part 1 you should have:

- [ ] LibreOffice installed and confirmed via `soffice --version`
- [ ] A `office-automation-toolkit/` project folder with `.venv`, `src/`, `tests/`, `templates/`, `output/`
- [ ] VS Code configured to resolve `import uno`
- [ ] LibreOffice running headless with a listening socket on port 2002
- [ ] `src/uno_bridge.py` successfully connecting and printing the Desktop service object

## What's Next

Part 2 dives into the UNO object model itself — services, interfaces, and how to *discover* what methods are available on any given UNO object — and then introduces **ScriptForge**, which wraps most of this in a far more pythonic API.
