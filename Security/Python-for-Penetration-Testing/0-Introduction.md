# Python for Penetration Testing
### A Complete FOSS-Only Tutorial Series for Building Your Own Security Toolkit

---

## ⚠️ Before We Begin: Read This First

This is not boilerplate — it's the foundation the entire series stands on.

> **Legal & Ethical Notice:** Everything in this series is intended **exclusively** for educational purposes, authorized penetration testing engagements, and use inside controlled lab environments that **you own or have explicit written permission to test**. Scanning, exploiting, or manipulating traffic on networks/systems you don't own or lack authorization for is illegal in most jurisdictions (e.g., the U.S. Computer Fraud and Abuse Act, the U.K. Computer Misuse Act, the EU's NIS2/GDPR-adjacent computer crime statutes). Every script we build will be tested against **local, isolated, intentionally-vulnerable machines** (like Metasploitable2 or OWASP Juice Shop) that we spin up ourselves. Think of this like a locksmithing course: we're learning how locks work by taking apart locks we bought, in our own workshop — not by picking our neighbor's front door.

If you take one thing away from this entire series before writing a single line of code, it's this: **capability without authorization is a crime, not a skill demonstration.**

---

## The Full Course Blueprint (Your Roadmap)

Think of this series like building a house. Part 0 pours the foundation (tools, lab, mindset). Part 1's modules are the framing, plumbing, and electrical — each layer depends on the one before it. Part 2's appendices are the "building codes" reference binder you keep on the shelf and flip back to whenever a term or protocol confuses you.

| Part | Section | What You'll Build | Core FOSS Tools |
|---|---|---|---|
| **Part 0** | Introduction & Lab Setup | Isolated pentest lab, Python environment, sanity-check scripts | `venv`, `pip`, VirtualBox/Docker, Metasploitable2, OWASP Juice Shop |
| **Part 1** | Module 1: Low-Level Network Ops | Raw TCP/UDP port scanner, banner grabber, service fingerprinter | `socket`, `concurrent.futures` |
| **Part 1** | Module 2: Advanced Packet Manipulation | Custom packet injector, ARP spoofer, ICMP sweep tool, packet sniffer | `Scapy` |
| **Part 1** | Module 3: Web Application Assessment | Directory brute-forcer, sub-domain enumerator, form-based SQLi/XSS fuzzer | `requests`, `BeautifulSoup4`, `threading` |
| **Part 1** | Module 4: Post-Exploitation & Automation | Interactive reverse shell, basic C2 listener, log parser/analyzer | `socket`, `subprocess`, `re` |
| **Part 2** | Appendix A: Core Network Concepts | Reference only | OSI model, TCP handshake, UDP, kernel sockets |
| **Part 2** | Appendix B: Web & HTTP Mechanics | Reference only | HTTP lifecycle, cookies, OWASP Top 10 |
| **Part 2** | Appendix C: FOSS Tool Interop | Reference only | Nmap, Wireshark, Metasploit ↔ Python |

Each module in Part 1 will follow the exact same rhythm: **Target → Concept → Implementation → Verification**, so you always know what you're building, why it works, what the code is, and how to prove it worked before moving on.

---

# Part 0: Introduction — Building Your Pentesting Lab

### What This Part Covers

Before we scan a single port, we need three things, in this order:

1. A **legal and ethical operating framework** (the rules we play by).
2. A **safe playground** — an isolated network with intentionally vulnerable machines we're allowed to attack.
3. A **clean Python workspace** so our scripts are reproducible, don't pollute your system, and behave the same on your machine as everyone else's.

Skipping any of these three is like a chemistry student mixing reagents on the kitchen table instead of in a fume hood — it might "work" once, but it's reckless, and it's exactly how things go wrong.

---

## Step 1: Establish the Rules of Engagement (RoE)

### The Target
A written, explicit scope document defining what you're allowed to test — even in a personal lab.

### The Concept
A **Rules of Engagement (RoE)** document is like a permission slip for a school field trip — it says exactly *where* you're allowed to go, *what* you're allowed to touch, and *when*. Professional penetration testers never touch a system without one signed by the client. Since you're both the "client" and the "tester" in this lab, you're writing it for yourself — a habit that will make you employable and keep you out of legal trouble the moment you touch a real client's network.

### The Implementation

Create a project folder and drop this file in immediately — before any code exists.

**File: `pentest-lab/ROE.md`**
```markdown
# Rules of Engagement — Personal Lab

**Authorized Tester:** [Your Name]
**Scope (IN):**
  - 192.168.56.0/24  (VirtualBox Host-Only Network — isolated lab segment)
  - Metasploitable2 VM  (192.168.56.101)
  - OWASP Juice Shop container (192.168.56.102, port 3000)

**Out of Scope (DO NOT TOUCH):**
  - Any device on my home Wi-Fi (192.168.1.0/24)
  - Any public IP address or domain I do not own
  - My ISP's infrastructure

**Authorized Techniques:** Port scanning, banner grabbing, packet sniffing,
ARP spoofing, web fuzzing, exploitation — LAB SEGMENT ONLY.

**Start Date:** [today]
**End Date:** [ongoing — personal lab]
**Signed:** [Your Name], Authorizer and Tester
```

### The Verification

Open the file and confirm two things by eye:
1. The IP ranges listed match your actual VirtualBox/Docker network (we'll create this in Step 3 — you'll come back and fill this in).
2. You can say out loud, without hesitation, "I own or am authorized to test every IP in this file." If you can't, stop and fix the scope before continuing.

---

## Step 2: Install Python and Verify Your Interpreter

### The Target
A working Python 3.10+ installation, confirmed from the terminal.

### The Concept
Python is the "engine" for every tool we build in this series. But just like two mechanics might have different engine models on their workbenches, different Python versions can behave subtly differently (especially with `Scapy`'s C-level bindings later on). We pin down a version early so nothing "works on my machine but not yours."

### The Implementation

**On Linux (Debian/Ubuntu-based, recommended — most FOSS security tooling assumes Linux):**
```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip
```

**On Windows (via official python.org installer):** Download Python 3.11+ from python.org, and during installation, **check the box "Add Python to PATH"** — this is the single most common beginner mistake; without it, your terminal won't know the `python` command exists.

**On macOS (via Homebrew):**
```bash
brew install python3
```

### The Verification

Run this in your terminal (Linux/macOS use `python3`, Windows can use `python`):

```bash
python3 --version
```

**Expected output:**
```
Python 3.11.4
```

Any `3.10.x` or higher is fine for this entire series. If you get `command not found`, your PATH isn't set correctly — this is worth fixing now, because every single script from here forward depends on this command working.

---

## Step 3: Build the Isolated Vulnerable Lab

### The Target
Two intentionally-vulnerable, FOSS-licensed target machines, reachable only from an isolated virtual network — never exposed to the internet or your home LAN.

### The Concept
Think of this like a **crash-test facility for cars**. You don't test airbags on your own family sedan in traffic — you build a closed track with dummies. Our "closed track" is a **host-only virtual network**: a virtual network switch that only your host machine and your VMs can see. Nothing on this network can reach your home router, and nothing on the internet can reach it either.

We'll use two well-known, purpose-built FOSS vulnerable targets:

| Target | What It Simulates | License | Why We Use It |
|---|---|---|---|
| **Metasploitable2** | An intentionally vulnerable Linux server (FTP, SSH, Samba, MySQL, etc.) | GPL/FOSS-distributed by Rapid7 for education | Perfect for Module 1 (port scanning) & Module 2 (packet sniffing) |
| **OWASP Juice Shop** | A deliberately insecure modern web app (SQLi, XSS, broken auth, etc.) | MIT License | Perfect for Module 3 (web assessment) |

### The Implementation

**3a. Install VirtualBox (FOSS virtualization hypervisor)**

```bash
# Debian/Ubuntu
sudo apt install -y virtualbox
```

**3b. Create the isolated Host-Only network**

```bash
# Creates a virtual network adapter that ONLY your VMs and host can see
VBoxManage hostonlyif create
# Assign it a private subnet — this matches the RoE.md scope from Step 1
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
```

**3c. Download and import Metasploitable2**

Metasploitable2 is distributed as a pre-built VM image (`.zip` containing a `.vmdk` disk). Download it from the official SourceForge mirror (Rapid7-endorsed): `https://sourceforge.net/projects/metasploitable/`.

```bash
unzip Metasploitable2-Linux.zip -d ./metasploitable2
```

In VirtualBox: **New VM → Type: Linux → Version: Ubuntu (64-bit) → Use an existing virtual hard disk → select the extracted `.vmdk`.** Then, **critically**, go to **Settings → Network → Attached to: Host-only Adapter → vboxnet0**. This one setting is what keeps this vulnerable box off your real network.

Boot the VM. Default credentials (intentionally weak — that's the point): `msfadmin` / `msfadmin`.

**3d. Deploy OWASP Juice Shop via Docker (FOSS containerization)**

Docker is faster than a full VM for a single web app. Install Docker:

```bash
sudo apt install -y docker.io
sudo systemctl enable --now docker
```

Run Juice Shop, bound only to your host-only interface:

**File: `pentest-lab/docker-compose.yml`**
```yaml
version: "3.8"
services:
  juice-shop:
    image: bkimminich/juice-shop   # Official OWASP Juice Shop image, MIT licensed
    container_name: juice-shop
    ports:
      # Binding to 192.168.56.1 (our host-only IP) instead of 0.0.0.0
      # prevents this vulnerable app from being reachable on your home LAN
      - "192.168.56.1:3000:3000"
    restart: unless-stopped
```

```bash
cd pentest-lab
docker compose up -d
```

### The Verification

From your host terminal, confirm both targets are alive **and isolated**:

```bash
# Metasploitable2 should respond on its host-only IP
ping -c 3 192.168.56.101

# Juice Shop should respond over HTTP
curl -I http://192.168.56.1:3000
```

**Expected output for Juice Shop:**
```
HTTP/1.1 200 OK
X-Powered-By: Express
...
```

Then confirm isolation by checking that neither target is reachable from your **phone** connected to the same home Wi-Fi — it shouldn't be, because host-only networks aren't bridged to your physical LAN.

Now go back to `ROE.md` from Step 1 and fill in the real IPs you just confirmed (`192.168.56.101`, `192.168.56.1:3000`).

---

## Step 4: Create an Isolated Python Virtual Environment

### The Target
A self-contained Python environment (`venv`) dedicated to this course, isolated from your system-wide Python packages.

### The Concept
A **virtual environment** is like a dedicated tackle box for fishing gear — separate from your everyday household toolbox. If you install a specific version of a library for this course, you don't want it conflicting with some other Python project on your machine (or worse, breaking a system tool that depends on system Python). `venv` creates a folder with its own private copy of the Python interpreter and package list.

### The Implementation

```bash
mkdir -p pentest-lab/scripts
cd pentest-lab

# Creates the isolated environment in a folder named .venv
python3 -m venv .venv

# Activate it — your terminal prompt will change to show (.venv)
source .venv/bin/activate        # Linux/macOS
# .venv\Scripts\activate         # Windows (run in PowerShell or cmd)
```

### The Verification

```bash
which python3
```

**Expected output** (path lives *inside* your project, not `/usr/bin`):
```
/home/youruser/pentest-lab/.venv/bin/python3
```

If it still points to `/usr/bin/python3`, the environment wasn't activated — re-run the `source` command. This check matters because **every** `pip install` from this point forward, in every module of this series, assumes you're inside this activated environment.

---

## Step 5: Install and Pin Core FOSS Libraries

### The Target
A `requirements.txt` file listing every third-party library we'll use across the entire series, installed and version-locked.

### The Concept
`requirements.txt` is like a recipe's ingredient list with exact measurements — "flour" isn't enough, you need "2 cups." Pinning exact versions (`==`) means that six months from now, when a library releases a breaking update, your scripts from Module 2 still run exactly as documented here.

### The Implementation

**File: `pentest-lab/requirements.txt`**
```text
requests==2.31.0
beautifulsoup4==4.12.3
scapy==2.5.0
```

```bash
# Still inside the activated .venv
pip install --upgrade pip
pip install -r requirements.txt
```

> **Note on `socket`:** We don't list `socket` here because it's part of Python's **standard library** — it ships with Python itself, no installation needed. We'll rely on it heavily in Module 1.

### The Verification

**File: `pentest-lab/scripts/check_env.py`**
```python
"""
check_env.py
Sanity-check script: confirms the venv is active and every required
library for this course imports cleanly before we write real tools.
"""

import sys
import importlib

# Libraries we expect to be installed inside the .venv
REQUIRED_LIBS = ["requests", "bs4", "scapy"]


def check_python_version() -> None:
    """Fail fast if running on an unsupported Python version."""
    major, minor = sys.version_info[:2]
    if (major, minor) < (3, 10):
        # We raise instead of silently continuing — later modules use
        # syntax (like structural pattern matching) that requires 3.10+
        raise RuntimeError(
            f"Python 3.10+ required, found {major}.{minor}. "
            "Reinstall Python and recreate your venv."
        )
    print(f"[OK] Python version: {major}.{minor}")


def check_libraries() -> None:
    """Attempt to import each required library, reporting failures clearly."""
    for lib_name in REQUIRED_LIBS:
        try:
            module = importlib.import_module(lib_name)
            version = getattr(module, "__version__", "unknown")
            print(f"[OK] {lib_name} imported successfully (version: {version})")
        except ImportError as err:
            # Don't let one missing library crash the whole check —
            # report every problem in a single pass instead of one at a time
            print(f"[FAIL] Could not import '{lib_name}': {err}")


if __name__ == "__main__":
    check_python_version()
    check_libraries()
```

Run it:
```bash
python3 scripts/check_env.py
```

**Expected output:**
```
[OK] Python version: 3.11
[OK] requests imported successfully (version: 2.31.0)
[OK] bs4 imported successfully (version: 4.12.3)
[OK] scapy imported successfully (version: 2.5.0)
```

If anything says `[FAIL]`, re-run `pip install -r requirements.txt` and confirm your `.venv` is still activated (Step 4's verification command).

---

## Step 6: The "Hello Recon" End-to-End Sanity Check

### The Target
One small script that touches **both** of our lab targets — a raw socket connection to Metasploitable2 and an HTTP request to Juice Shop — proving the entire pipeline (lab network → Python → libraries) works together before Module 1 begins.

### The Concept
This is your **dress rehearsal**. A theater doesn't wait until opening night to test if the lights turn on — they run a full technical rehearsal first. This script is that rehearsal: it doesn't hack anything, it just proves connectivity end-to-end.

### The Implementation

**File: `pentest-lab/scripts/hello_recon.py`**
```python
"""
hello_recon.py
End-to-end environment check: verifies raw TCP connectivity to
Metasploitable2 and HTTP connectivity to Juice Shop.

This is intentionally non-invasive — it opens a connection and reads
a banner/response, nothing more. This is the baseline every future
module's tools will build on top of.
"""

import socket
import sys

import requests

# Pulled from ROE.md — the only two hosts we are authorized to touch
METASPLOITABLE_IP = "192.168.56.101"
METASPLOITABLE_PORT = 21          # FTP — Metasploitable2 exposes an insecure banner here
JUICE_SHOP_URL = "http://192.168.56.1:3000"

SOCKET_TIMEOUT_SECONDS = 5        # Prevents the script from hanging forever
                                    # if the host is down or firewalled


def check_tcp_target() -> None:
    """Open a raw TCP socket to Metasploitable2 and read its FTP banner."""
    try:
        # AF_INET = IPv4, SOCK_STREAM = TCP (we cover this fully in Module 1)
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(SOCKET_TIMEOUT_SECONDS)
            sock.connect((METASPLOITABLE_IP, METASPLOITABLE_PORT))

            # Servers often send a greeting immediately on connect —
            # this is the "banner" we'll rely on heavily in Module 1
            banner = sock.recv(1024).decode(errors="ignore").strip()
            print(f"[OK] TCP connection to {METASPLOITABLE_IP}:{METASPLOITABLE_PORT}")
            print(f"     Banner received: {banner}")

    except socket.timeout:
        print(f"[FAIL] Connection to {METASPLOITABLE_IP}:{METASPLOITABLE_PORT} timed out. "
              "Is the Metasploitable2 VM powered on?")
    except ConnectionRefusedError:
        print(f"[FAIL] Port {METASPLOITABLE_PORT} refused connection. "
              "The service on that port may not be running.")
    except OSError as err:
        # Catches broader network errors (e.g., no route to host)
        print(f"[FAIL] Network error reaching {METASPLOITABLE_IP}: {err}")


def check_http_target() -> None:
    """Send an HTTP GET request to OWASP Juice Shop and confirm a response."""
    try:
        response = requests.get(JUICE_SHOP_URL, timeout=SOCKET_TIMEOUT_SECONDS)
        response.raise_for_status()  # Raises an exception on 4xx/5xx status codes
        print(f"[OK] HTTP {response.status_code} from {JUICE_SHOP_URL}")
        print(f"     Server header: {response.headers.get('X-Powered-By', 'N/A')}")

    except requests.exceptions.ConnectionError:
        print(f"[FAIL] Could not connect to {JUICE_SHOP_URL}. "
              "Is the Docker container running? Try: docker ps")
    except requests.exceptions.Timeout:
        print(f"[FAIL] Request to {JUICE_SHOP_URL} timed out.")
    except requests.exceptions.HTTPError as err:
        print(f"[FAIL] HTTP error from Juice Shop: {err}")


if __name__ == "__main__":
    print("--- Running Hello Recon: Environment Verification ---")
    check_tcp_target()
    check_http_target()
    print("--- Done. If both checks show [OK], your lab is ready. ---")
    sys.exit(0)
```

### The Verification

```bash
python3 scripts/hello_recon.py
```

**Expected output:**
```
--- Running Hello Recon: Environment Verification ---
[OK] TCP connection to 192.168.56.101:21
     Banner received: 220 (vsFTPd 2.3.4)
[OK] HTTP 200 from http://192.168.56.1:3000
     Server header: Express
--- Done. If both checks show [OK], your lab is ready. ---
```

If you see both `[OK]` lines, **every dependency for the rest of this series is confirmed working**: your VMs, your host-only network, your `venv`, and your installed libraries. If either check fails, the printed error message tells you exactly which layer to fix (network, VM power state, or Docker container) — resist the urge to move to Module 1 until this passes cleanly.

---

# Standalone Reference Section — Appendix 0

*(Isolated here so the walkthrough above stays fast-paced. Come back to this section anytime a term above felt unfamiliar.)*

## A0.1 — `venv` vs `virtualenv` vs `conda`

| Tool | Ships With Python? | Best For | Notes |
|---|---|---|---|
| `venv` | Yes (3.3+) | This course, general scripting | Lightweight, standard library, zero extra install |
| `virtualenv` | No (pip install) | Legacy Python 2 support, advanced use | Faster environment creation, more config options |
| `conda` | No (Anaconda/Miniconda) | Data science stacks with compiled deps | Overkill for pentesting scripts; heavier footprint |

We use `venv` throughout this series because it requires zero extra installation and is the officially blessed standard-library solution — one less dependency to manage.

## A0.2 — Why Host-Only Networking Specifically (not NAT or Bridged)

| VirtualBox Network Mode | VM Can Reach Internet? | VM Can Reach Your Home LAN? | Host Can Reach VM? | Used For |
|---|---|---|---|---|
| **NAT** | Yes | No | No (without port forwarding) | General internet-connected VM use |
| **Bridged** | Yes | **Yes — dangerous for vulnerable VMs** | Yes | Not recommended for this course |
| **Host-Only** (our choice) | No | No | Yes | Isolated, safe pentesting labs |

Host-Only is the only mode that guarantees Metasploitable2 and Juice Shop — both riddled with intentional vulnerabilities — can never be reached by anything outside your own machine.

## A0.3 — Core Libraries Used Across This Entire Series

| Library | License | Used In | Purpose |
|---|---|---|---|
| `socket` | PSF (stdlib) | Module 1, 4 | Raw TCP/UDP connections, the foundation of all network tools |
| `concurrent.futures` | PSF (stdlib) | Module 1 | Thread pooling for fast port scans |
| `scapy` | GPLv2 | Module 2 | Crafting/sniffing raw packets at Layer 2/3 |
| `requests` | Apache 2.0 | Module 3 | HTTP client for web assessment tools |
| `beautifulsoup4` | MIT | Module 3 | HTML parsing for scraping/form discovery |
| `subprocess` | PSF (stdlib) | Module 4 | Spawning shell commands from reverse shell payloads |
| `re` | PSF (stdlib) | Module 4 | Pattern matching in log parsing |

## A0.4 — Legal Frameworks Cheat Sheet (Non-Exhaustive — Consult Local Law)

| Jurisdiction | Relevant Law | Key Point |
|---|---|---|
| United States | Computer Fraud and Abuse Act (CFAA) | Criminalizes "unauthorized access" — even scanning without permission can qualify |
| United Kingdom | Computer Misuse Act 1990 | Criminalizes unauthorized access *and* unauthorized modification |
| European Union | Directive on Attacks against Information Systems (2013/40/EU) + national implementations | Harmonized criminal penalties across member states |
| Generally | — | Written authorization (an RoE, like `ROE.md` above) is your legal shield in every jurisdiction |

## A0.5 — Metasploitable2 & Juice Shop Quick-Reference

| Target | Default Credentials | Key Ports for Later Modules | Purpose in This Course |
|---|---|---|---|
| Metasploitable2 | `msfadmin` / `msfadmin` | 21 (FTP), 22 (SSH), 80 (HTTP), 445 (Samba), 3306 (MySQL) | Module 1 (scanning), Module 2 (sniffing/ARP) |
| OWASP Juice Shop | N/A (register your own account in-app) | 3000 (HTTP) | Module 3 (web assessment: SQLi, XSS, brute-force) |

---

## What's Next

With your RoE signed, your lab isolated, your Python environment pinned, and `hello_recon.py` printing clean `[OK]` lines, you have a fully reproducible foundation. **Module 1** builds directly on top of the `socket` import you just verified — we'll extend that single TCP connection into a full multi-threaded TCP/UDP port scanner with banner grabbing and basic service fingerprinting, tested entirely against the Metasploitable2 box you just stood up.

Say the word when you're ready to proceed to **Module 1: Low-Level Network Operations**.
