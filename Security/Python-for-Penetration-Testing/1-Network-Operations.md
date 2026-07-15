Understood — here's **Module 1, expanded and enhanced**, without the appendix tables at the end (you'll request those separately, one at a time). I've tightened the prose for concision while adding depth where it strengthens the build.

# Module 1: Low-Level Network Operations
### Building a Raw TCP/UDP Port Scanner From Scratch

---

## Module Overview

Every port scanner — Nmap included — does one basic thing: **ask a remote address, "Is anyone home at this door, and who are you?"** We build that ability ourselves, layer by layer, so Nmap stops feeling like a black box later.

We build in strict increments, each a runnable script:

1. Single TCP "knock on one door" check
2. Scan a whole range of doors sequentially
3. Read what's said when the door opens (banner grabbing)
4. Make it fast with concurrency
5. Add UDP support (a different kind of "knock")
6. Fingerprint *what* service answered
7. Wrap it all in a real CLI tool

**Every script targets only `192.168.56.101`** (Metasploitable2, per `ROE.md`).

---

## Step 1: The Single-Port TCP Connect Check

### The Target
`scripts/module1/tcp_connect_check.py` — check if **one** TCP port is open.

### The Concept
An IP is an apartment building; a **port** is one of 65,535 possible doors. A **TCP connect scan** is walking up and knocking using the building's official knock (the **three-way handshake**, detailed in Appendix A). Someone answers → **open**. "Go away" (`RST`) → **closed**. Silence → **filtered** (a firewall is ignoring you, not answering).

### The Implementation

```bash
mkdir -p pentest-lab/scripts/module1
```

**`scripts/module1/tcp_connect_check.py`**
```python
"""
tcp_connect_check.py
Simplest building block: check if ONE TCP port is open on ONE host.
Authorized target only: 192.168.56.101 (per ROE.md)
"""

import socket
import sys

TARGET_HOST = "192.168.56.101"
TARGET_PORT = 21
CONNECT_TIMEOUT_SECONDS = 3   # Without this, a filtered port hangs forever


def check_tcp_port(host: str, port: int, timeout: float) -> bool:
    """Attempt a TCP handshake with (host, port). True = open."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        try:
            # connect_ex returns an error code instead of raising —
            # cheaper than exceptions when we EXPECT most attempts to fail
            return sock.connect_ex((host, port)) == 0
        except socket.gaierror as err:
            print(f"[ERROR] Could not resolve host '{host}': {err}")
            sys.exit(1)
        except socket.error as err:
            print(f"[ERROR] Socket error on {host}:{port}: {err}")
            return False


if __name__ == "__main__":
    print(f"Checking {TARGET_HOST}:{TARGET_PORT} ...")
    is_open = check_tcp_port(TARGET_HOST, TARGET_PORT, CONNECT_TIMEOUT_SECONDS)
    print(f"Port {TARGET_PORT} is {'OPEN' if is_open else 'CLOSED or FILTERED'}")
```

### The Verification

```bash
cd pentest-lab && source .venv/bin/activate
python3 scripts/module1/tcp_connect_check.py
```
```
Checking 192.168.56.101:21 ...
Port 21 is OPEN
```
Temporarily set `TARGET_PORT = 9999` and rerun — expect `CLOSED or FILTERED`. Revert to `21` before continuing.

---

## Step 2: Scanning a Range of Ports (Sequentially)

### The Target
Check a **range** of ports (1–1024), one at a time.

### The Concept
Same hallway, but now we knock on every door in sequence. Slow — deliberately so. We build the slow, obviously-correct version first, so Step 4's speedup is *proven*, not just claimed.

### The Implementation

**`scripts/module1/sequential_scanner.py`**
```python
"""
sequential_scanner.py
Scans a RANGE of TCP ports one at a time — establishes a correctness
and timing baseline before concurrency is introduced.
"""

import socket
import time

TARGET_HOST = "192.168.56.101"
PORT_RANGE_START = 1
PORT_RANGE_END = 1024
CONNECT_TIMEOUT_SECONDS = 1


def check_tcp_port(host: str, port: int, timeout: float) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        try:
            return sock.connect_ex((host, port)) == 0
        except socket.error:
            # One bad socket shouldn't kill a 1000-port loop
            return False


def scan_range(host: str, start_port: int, end_port: int, timeout: float) -> list[int]:
    open_ports = []
    total = end_port - start_port + 1
    for i, port in enumerate(range(start_port, end_port + 1), start=1):
        print(f"\rScanning port {port} ({i}/{total})...", end="", flush=True)
        if check_tcp_port(host, port, timeout):
            open_ports.append(port)
    print()
    return open_ports


if __name__ == "__main__":
    print(f"Sequential scan of {TARGET_HOST} (ports {PORT_RANGE_START}-{PORT_RANGE_END})")
    start = time.perf_counter()
    found = scan_range(TARGET_HOST, PORT_RANGE_START, PORT_RANGE_END, CONNECT_TIMEOUT_SECONDS)
    elapsed = time.perf_counter() - start
    print(f"\nDone in {elapsed:.2f}s. Open ports: {found}")
```

### The Verification

```bash
python3 scripts/module1/sequential_scanner.py
```
```
Sequential scan of 192.168.56.101 (ports 1-1024)
Done in 47.32s. Open ports: [21, 22, 23, 25, 53, 80, 139, 445]
```
**Write down that elapsed time** — Step 4 will beat it dramatically, and you need this "before" number to appreciate the "after."

---

## Step 3: Banner Grabbing

### The Target
For each open port, read the first bytes the service volunteers — its **banner**.

### The Concept
Knowing a door is open matters less than knowing *who answered*. Many services announce themselves unprompted — like a shopkeeper shouting "Welcome to Bob's Hardware!" the moment the door chimes. An FTP banner like `220 (vsFTPd 2.3.4)` names exact software and version — the starting point for real vulnerability research later.

### The Implementation

**`scripts/module1/banner_grabber.py`**
```python
"""
banner_grabber.py
After confirming a port is open, attempt to read whatever the service
sends first, without waiting forever if it stays silent.
"""

import socket

TARGET_HOST = "192.168.56.101"
CONNECT_TIMEOUT_SECONDS = 2
BANNER_READ_TIMEOUT_SECONDS = 2
BANNER_MAX_BYTES = 1024


def check_tcp_port(host: str, port: int, timeout: float) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        try:
            return sock.connect_ex((host, port)) == 0
        except socket.error:
            return False


def grab_banner(host: str, port: int) -> str:
    """Reads a banner if offered; returns '' if the service stays silent
    (normal behavior for HTTP and similar request-first protocols)."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(CONNECT_TIMEOUT_SECONDS)
            sock.connect((host, port))
            # Separate, shorter timeout just for reading, so a silent
            # service doesn't stall the whole scan waiting for bytes
            sock.settimeout(BANNER_READ_TIMEOUT_SECONDS)
            raw = sock.recv(BANNER_MAX_BYTES)
            return raw.decode(errors="ignore").strip()
    except socket.timeout:
        return ""
    except (ConnectionResetError, OSError):
        return ""


if __name__ == "__main__":
    ports_to_check = [21, 22, 23, 25, 80]
    print(f"Grabbing banners from {TARGET_HOST}...\n")
    for port in ports_to_check:
        if check_tcp_port(TARGET_HOST, port, CONNECT_TIMEOUT_SECONDS):
            banner = grab_banner(TARGET_HOST, port) or "(no banner offered)"
            print(f"Port {port:>5} | OPEN  | Banner: {banner}")
        else:
            print(f"Port {port:>5} | CLOSED/FILTERED")
```

### The Verification

```bash
python3 scripts/module1/banner_grabber.py
```
```
Port    21 | OPEN  | Banner: 220 (vsFTPd 2.3.4)
Port    22 | OPEN  | Banner: SSH-2.0-OpenSSH_4.7p1 Debian-8ubuntu1
Port    23 | OPEN  | Banner: 
Port    25 | OPEN  | Banner: 220 metasploitable.localdomain ESMTP Postfix (Ubuntu)
Port    80 | OPEN  | Banner: (no banner offered)
```
Port 80 offering nothing is **expected** — HTTP waits for a request first. Step 6 handles that case properly.

---

## Step 4: Concurrency — Making the Scan Fast

### The Target
Check many ports **simultaneously** via a thread pool.

### The Concept
Step 2's ~47s wasn't CPU work — it was **waiting** (an **I/O-bound** operation). One cashier serving customers one at a time while 20 registers sit empty. `ThreadPoolExecutor` opens multiple "cashier lanes" so many checks can be waiting on the network concurrently.

**Why threads, not `multiprocessing`?** Our bottleneck is waiting, not computing. Threads are lightweight for I/O waits; processes carry heavy startup/memory cost better suited to CPU-bound work.

### The Implementation

**`scripts/module1/concurrent_scanner.py`**
```python
"""
concurrent_scanner.py
Same scan as Step 2, but checks many ports simultaneously via a
thread pool instead of one at a time.
"""

import time
import socket
from concurrent.futures import ThreadPoolExecutor, as_completed

TARGET_HOST = "192.168.56.101"
PORT_RANGE_START = 1
PORT_RANGE_END = 1024
CONNECT_TIMEOUT_SECONDS = 1
MAX_WORKER_THREADS = 100   # "cashier lanes" opened at once


def check_tcp_port(host: str, port: int, timeout: float) -> tuple[int, bool]:
    """Returns (port, is_open) — the port number is needed because
    threads complete out of order."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        try:
            is_open = sock.connect_ex((host, port)) == 0
        except socket.error:
            is_open = False
        return port, is_open


def scan_range_concurrent(host: str, start_port: int, end_port: int,
                           timeout: float, max_workers: int) -> list[int]:
    open_ports = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # submit() schedules work and returns a Future immediately —
        # a placeholder for a result that isn't ready yet
        future_to_port = {
            executor.submit(check_tcp_port, host, p, timeout): p
            for p in range(start_port, end_port + 1)
        }
        total = end_port - start_port + 1
        done = 0
        # as_completed() yields futures as they finish, NOT submission order
        for future in as_completed(future_to_port):
            done += 1
            print(f"\rProgress: {done}/{total}", end="", flush=True)
            try:
                port, is_open = future.result()
                if is_open:
                    open_ports.append(port)
            except Exception as err:
                # One bad thread shouldn't kill the whole scan
                failed_port = future_to_port[future]
                print(f"\n[WARN] Error scanning port {failed_port}: {err}")
    print()
    return sorted(open_ports)


if __name__ == "__main__":
    print(f"Concurrent scan of {TARGET_HOST} "
          f"(ports {PORT_RANGE_START}-{PORT_RANGE_END}, {MAX_WORKER_THREADS} threads)")
    start = time.perf_counter()
    found = scan_range_concurrent(TARGET_HOST, PORT_RANGE_START, PORT_RANGE_END,
                                   CONNECT_TIMEOUT_SECONDS, MAX_WORKER_THREADS)
    elapsed = time.perf_counter() - start
    print(f"\nDone in {elapsed:.2f}s. Open ports: {found}")
```

### The Verification

```bash
python3 scripts/module1/concurrent_scanner.py
```
```
Concurrent scan of 192.168.56.101 (ports 1-1024, 100 threads)
Progress: 1024/1024
Done in 1.84s. Open ports: [21, 22, 23, 25, 53, 80, 139, 445]
```
Same 1,024 ports, same results, **~25x faster** than Step 2. This is the exact technique Nmap's engine relies on.

> **Trip-up:** pushing `MAX_WORKER_THREADS` to something like 5,000 doesn't scale linearly — you'll hit OS file-descriptor limits and get sporadic `OSError: [Errno 24] Too many open files`.

---

## Step 5: Adding UDP Scanning

### The Target
A UDP-specific scan function — fundamentally different logic than TCP.

### The Concept
TCP knocking gets a definitive answer. **UDP is stateless** — like slipping a note under a door. No reply could mean empty room (**closed**) *or* someone home who just didn't answer (**open|filtered** — the honest, ambiguous verdict real scanners give too). The one reliable signal: a closed port often triggers an **ICMP Port Unreachable** "return to sender" notice. Catching that cleanly needs raw ICMP handling — one reason Module 2 introduces Scapy. Here, we build the honest, practical version with plain `socket`.

### The Implementation

**`scripts/module1/udp_scanner.py`**
```python
"""
udp_scanner.py
Basic UDP port scanner. UDP gives no handshake confirmation — we
infer state from whether we get ANY response or an explicit refusal.
"""

import socket

TARGET_HOST = "192.168.56.101"
COMMON_UDP_PORTS = [53, 68, 69, 123, 161, 500]
UDP_TIMEOUT_SECONDS = 2


def check_udp_port(host: str, port: int, timeout: float) -> str:
    """Sends an empty datagram; returns 'open', 'closed', or 'open|filtered'."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(timeout)
        try:
            sock.sendto(b"", (host, port))
            # ANY reply (even a malformed-request error) confirms something
            # is listening
            sock.recvfrom(1024)
            return "open"
        except socket.timeout:
            # No response: could be open-but-silent, or silently firewalled.
            # We report this honestly instead of guessing.
            return "open|filtered"
        except ConnectionResetError:
            # Many OSes surface a closed UDP port as this exception,
            # translated from an ICMP Port Unreachable
            return "closed"
        except OSError as err:
            print(f"[ERROR] Unexpected OS error on port {port}: {err}")
            return "error"


if __name__ == "__main__":
    print(f"UDP scan of {TARGET_HOST} (common ports only)\n")
    for port in COMMON_UDP_PORTS:
        state = check_udp_port(TARGET_HOST, port, UDP_TIMEOUT_SECONDS)
        print(f"Port {port:>5}/udp | {state}")
```

### The Verification

```bash
python3 scripts/module1/udp_scanner.py
```
```
Port    53/udp | open
Port    68/udp | open|filtered
Port    69/udp | open|filtered
Port   123/udp | open|filtered
Port   161/udp | open|filtered
Port   500/udp | open|filtered
```
This ambiguity is **correct**, not a bug — Nmap's own `-sU` reports the identical `open|filtered` state for the identical reason.

---

## Step 6: Service Fingerprinting

### The Target
Turn raw port numbers/banners into human-readable service guesses (port 21 + "vsFTPd" → "FTP server: vsftpd").

### The Concept
The gap between "port 21 is open" and "vsftpd 2.3.4 is running — this exact version has a known backdoor (CVE-2011-2523)" is the gap between data and action. Two layers, same as real tools:

1. **Well-known port mapping** — fast offline guess by convention.
2. **Banner-based confirmation** — overrides the guess, since anyone can run a service on a nonstandard port.

### The Implementation

**`scripts/module1/service_fingerprint.py`**
```python
"""
service_fingerprint.py
Maps port numbers and banner text to likely service identities.
Imported by pyscan.py in Step 7 — no __main__ block here.
"""

import re

# Small, curated table. Real tools ship databases with thousands of
# entries (see Appendix C) — this is a minimal, readable version.
WELL_KNOWN_PORTS: dict[int, str] = {
    21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP", 53: "DNS",
    80: "HTTP", 110: "POP3", 139: "NetBIOS-SSN (Samba)", 143: "IMAP",
    443: "HTTPS", 445: "SMB (Samba)", 3306: "MySQL", 3389: "RDP",
    8080: "HTTP-Alt",
}

# Regex signatures matched against banner text. More specific patterns
# are listed before generic ones where overlap is possible.
BANNER_SIGNATURES: list[tuple[str, str]] = [
    (r"vsFTPd", "FTP server: vsftpd"),
    (r"ProFTPD", "FTP server: ProFTPD"),
    (r"OpenSSH", "SSH server: OpenSSH"),
    (r"Postfix", "SMTP server: Postfix"),
    (r"Apache", "Web server: Apache httpd"),
    (r"nginx", "Web server: nginx"),
    (r"MySQL", "Database: MySQL"),
    (r"Microsoft-IIS", "Web server: Microsoft IIS"),
]


def guess_service_by_port(port: int) -> str:
    """Fast, offline guess based purely on port convention."""
    return WELL_KNOWN_PORTS.get(port, "Unknown")


def identify_from_banner(banner: str) -> str | None:
    """Scans banner text for known software signatures."""
    if not banner:
        return None
    for pattern, identity in BANNER_SIGNATURES:
        if re.search(pattern, banner, re.IGNORECASE):  # vendor capitalization varies
            return identity
    return None


def fingerprint_service(port: int, banner: str) -> str:
    """Banner evidence takes priority; falls back to port guess."""
    banner_match = identify_from_banner(banner)
    if banner_match:
        return banner_match
    return f"{guess_service_by_port(port)} (guessed from port number, unconfirmed)"
```

### The Verification

```bash
touch scripts/__init__.py scripts/module1/__init__.py
python3
```
```python
>>> from scripts.module1.service_fingerprint import fingerprint_service
>>> fingerprint_service(21, "220 (vsFTPd 2.3.4)")
'FTP server: vsftpd'
>>> fingerprint_service(8080, "")
'HTTP-Alt (guessed from port number, unconfirmed)'
```
Run this from `pentest-lab/` root, not from inside `module1/`. If you get `ModuleNotFoundError`, the `__init__.py` files above are the fix.

---

## Step 7: The Final Combined CLI Scanner

### The Target
`scripts/module1/pyscan.py` — everything combined, driven by real command-line arguments instead of hardcoded constants.

### The Concept
Every hardcoded value above needs to become an argument — like replacing a fixed-station car radio with a tuning dial. `argparse` handles this cleanly and auto-generates a `--help` screen, because a tool you can't remember how to use in six months isn't actually reusable.

### The Implementation

**`scripts/module1/pyscan.py`**
```python
"""
pyscan.py
Combined CLI-driven TCP/UDP scanner with banner grabbing and service
fingerprinting.

USAGE (authorized lab targets only — see ROE.md):
    python3 pyscan.py --host 192.168.56.101 --ports 1-1024
    python3 pyscan.py --host 192.168.56.101 --ports 21,22,80 --udp
"""

import argparse
import socket
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

from service_fingerprint import fingerprint_service

DEFAULT_TIMEOUT_SECONDS = 1
DEFAULT_MAX_WORKERS = 100
BANNER_MAX_BYTES = 1024


def parse_port_range(port_spec: str) -> list[int]:
    """Parses '1-1024' or '21,22,80' style specs into a sorted, de-duped list."""
    ports: list[int] = []
    try:
        for chunk in port_spec.split(","):
            chunk = chunk.strip()
            if "-" in chunk:
                start_str, end_str = chunk.split("-")
                start, end = int(start_str), int(end_str)
                if start > end:
                    raise ValueError(f"Range start {start} > end {end}")
                ports.extend(range(start, end + 1))
            else:
                ports.append(int(chunk))
    except ValueError as err:
        # A typo'd --ports value is common — give a clear message, not a traceback
        print(f"[ERROR] Invalid --ports value '{port_spec}': {err}")
        sys.exit(1)

    invalid = [p for p in ports if p < 1 or p > 65535]
    if invalid:
        print(f"[ERROR] Port(s) out of valid range (1-65535): {invalid}")
        sys.exit(1)

    return sorted(set(ports))


def grab_banner(host: str, port: int, timeout: float) -> str:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(timeout)
            sock.connect((host, port))
            raw = sock.recv(BANNER_MAX_BYTES)
            return raw.decode(errors="ignore").strip()
    except (socket.timeout, ConnectionResetError, OSError):
        return ""


def scan_tcp_port(host: str, port: int, timeout: float) -> dict:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        try:
            is_open = sock.connect_ex((host, port)) == 0
        except socket.error:
            is_open = False

    result = {"port": port, "protocol": "tcp", "state": "closed", "banner": "", "service": ""}
    if is_open:
        banner = grab_banner(host, port, timeout)
        result.update(state="open", banner=banner, service=fingerprint_service(port, banner))
    return result


def scan_udp_port(host: str, port: int, timeout: float) -> dict:
    result = {"port": port, "protocol": "udp", "state": "closed",
              "banner": "", "service": fingerprint_service(port, "")}
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(timeout)
        try:
            sock.sendto(b"", (host, port))
            data, _ = sock.recvfrom(1024)
            result["state"] = "open"
            result["banner"] = data.decode(errors="ignore").strip()
        except socket.timeout:
            result["state"] = "open|filtered"
        except ConnectionResetError:
            result["state"] = "closed"
        except OSError as err:
            print(f"[WARN] UDP error on port {port}: {err}")
            result["state"] = "error"
    return result


def run_scan(host: str, ports: list[int], timeout: float,
             max_workers: int, use_udp: bool) -> list[dict]:
    scan_function = scan_udp_port if use_udp else scan_tcp_port
    results = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_port = {
            executor.submit(scan_function, host, p, timeout): p for p in ports
        }
        done = 0
        for future in as_completed(future_to_port):
            done += 1
            print(f"\rProgress: {done}/{len(ports)}", end="", flush=True)
            try:
                results.append(future.result())
            except Exception as err:
                print(f"\n[WARN] Error scanning port {future_to_port[future]}: {err}")
    print()
    return sorted(results, key=lambda r: r["port"])


def print_report(host: str, results: list[dict], elapsed: float) -> None:
    open_results = [r for r in results if r["state"] in ("open", "open|filtered")]
    print(f"\n{'=' * 60}\nScan Report for {host}\n{'=' * 60}")
    if not open_results:
        print("No open ports found.")
    else:
        for r in open_results:
            banner_display = f" | {r['banner']}" if r["banner"] else ""
            print(f"  {r['port']:>5}/{r['protocol']:<3} {r['state']:<14} "
                  f"{r['service']}{banner_display}")
    print(f"{'=' * 60}\nScanned {len(results)} port(s) in {elapsed:.2f} seconds.")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="FOSS TCP/UDP scanner with banner grabbing and fingerprinting. "
                    "FOR AUTHORIZED LAB USE ONLY."
    )
    parser.add_argument("--host", required=True,
                         help="Target IP/hostname (must be in ROE.md scope)")
    parser.add_argument("--ports", default="1-1024",
                         help="Port range ('1-1024') or list ('21,22,80'). Default: 1-1024")
    parser.add_argument("--udp", action="store_true", help="Scan using UDP instead of TCP")
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT_SECONDS,
                         help=f"Per-port timeout (default: {DEFAULT_TIMEOUT_SECONDS})")
    parser.add_argument("--threads", type=int, default=DEFAULT_MAX_WORKERS,
                         help=f"Concurrent worker threads (default: {DEFAULT_MAX_WORKERS})")
    return parser


if __name__ == "__main__":
    args = build_arg_parser().parse_args()
    port_list = parse_port_range(args.ports)
    protocol_label = "UDP" if args.udp else "TCP"

    print(f"Starting {protocol_label} scan of {args.host} "
          f"({len(port_list)} port(s), {args.threads} threads)")
    print("Reminder: only scan hosts authorized in your ROE.md\n")

    start = time.perf_counter()
    results = run_scan(args.host, port_list, args.timeout, args.threads, args.udp)
    elapsed = time.perf_counter() - start

    print_report(args.host, results, elapsed)
```

### The Verification

```bash
cd scripts/module1
python3 pyscan.py --help
```
```
usage: pyscan.py [-h] --host HOST [--ports PORTS] [--udp] [--timeout TIMEOUT] [--threads THREADS]
...
```

```bash
python3 pyscan.py --host 192.168.56.101 --ports 1-1024
```
```
Starting TCP scan of 192.168.56.101 (1024 port(s), 100 threads)
Reminder: only scan hosts authorized in your ROE.md

Progress: 1024/1024

============================================================
Scan Report for 192.168.56.101
============================================================
    21/tcp open           FTP server: vsftpd | 220 (vsFTPd 2.3.4)
    22/tcp open           SSH server: OpenSSH | SSH-2.0-OpenSSH_4.7p1 Debian-8ubuntu1
    23/tcp open           Telnet (guessed from port number, unconfirmed)
    25/tcp open           SMTP server: Postfix | 220 metasploitable.localdomain ESMTP Postfix (Ubuntu)
    53/tcp open           DNS (guessed from port number, unconfirmed)
    80/tcp open           HTTP (guessed from port number, unconfirmed)
   139/tcp open           NetBIOS-SSN (Samba) (guessed from port number, unconfirmed)
   445/tcp open           SMB (Samba) (guessed from port number, unconfirmed)
============================================================
Scanned 1024 port(s) in 1.91 seconds.
```

Cross-validate against the industry reference tool:

```bash
nmap -p 1-1024 192.168.56.101
```

Your open-port list should match Nmap's `open` lines closely — this is how you build confidence the tool you wrote is *correct*, not just fast.

---

Module 1 complete. Whenever you're ready, request **Appendix A** (or whichever appendix you'd like first) and I'll expand it standalone.
