# Primer 3: Terminal & `curl` Literacy for API Testing

*Optional pre-reading. If you're already comfortable running `curl` commands and reading HTTP status codes, skip straight to Part 0 of the main course.*

## Why This Primer Exists

Every single "Verification" step in this entire course asks you to run a `curl` command in your terminal and inspect the result. If you've never used `curl` before, the syntax can look like a wall of cryptic flags. This primer breaks down exactly what each piece means, so you're reading these commands with real understanding rather than just copy-pasting them and hoping for the best.

## What `curl` Actually Is

`curl` is a command-line tool that sends an HTTP request to a URL and shows you what comes back — it's doing exactly what your browser does when you type a URL and hit enter, just without any visual webpage rendering, and with far more control over the exact request being sent. This makes it perfect for testing an API directly, without needing to build any frontend at all.

## Anatomy of a Basic Request

```bash
curl http://localhost:3000/api/agent/ping
```

This alone sends a `GET` request (the default method `curl` uses when no other method is specified) to that URL, and prints whatever the server sends back directly into your terminal.

## Adding Headers with `-H`

An HTTP **header** is a small piece of metadata attached to a request, separate from its main content — like the address label and postage stamp on an envelope, separate from the letter inside. Throughout the course, we use headers for two things:

```bash
curl -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"message": "Hello"}'
```

- `-H "Content-Type: application/json"` tells the server "the data I'm sending you in this request's body is formatted as JSON" — without this, the server might not know how to correctly parse the body you're sending.
- `-H "x-api-key: ..."` is our own custom header (Phase 5), carrying the authentication secret our middleware checks before allowing the request through.
- `-X POST` explicitly tells `curl` to send this as a `POST` request rather than the default `GET` — required any time you're sending data, not just retrieving it.

## Sending a Request Body with `-d`

The `-d` flag stands for "data," and it's how you attach a request body — the actual payload of information you're sending, as opposed to metadata in a header:

```bash
-d '{"message": "What is 12 times 12?"}'
```

This is a JSON string, wrapped in single quotes so your terminal treats the whole thing as one piece of text rather than trying to interpret the curly braces or quotes inside it as terminal syntax. This is exactly what a route handler's `await request.json()` call (used throughout the course) reads and parses.

## Reading the Response: Piping to `python3 -m json.tool`

Raw JSON printed directly to a terminal is often one long, hard-to-read line. The course consistently pipes `curl`'s output through a small Python utility to pretty-print it:

```bash
curl -s http://localhost:3000/api/agent/ping | python3 -m json.tool
```

The `|` symbol (called a "pipe") takes the output of the command on its left and feeds it as input into the command on its right — so here, `curl`'s raw JSON output becomes the input to `python3 -m json.tool`, which reformats it with proper indentation and line breaks before displaying it. The `-s` flag on `curl` (short for "silent") suppresses `curl`'s own progress-meter output, so only the actual server response gets piped through — without `-s`, you'd see extra noise mixed in with your JSON.

## Understanding HTTP Status Codes (Crucial for This Course)

Every HTTP response includes a **status code** — a three-digit number communicating, at a glance, what kind of outcome occurred. This course uses status codes very deliberately and consistently, and understanding the difference between them is genuinely important for following the guardrail phases (4 and 5):

| Code | Category | Meaning in this course |
|---|---|---|
| `200` | Success | The request was understood and handled successfully |
| `400` | Client error | The request body itself was malformed or failed Zod validation — the caller's fault |
| `401` | Client error | Missing or invalid API key — you're not authenticated at all |
| `403` | Client error | You *are* authenticated, but the request was refused on policy grounds (e.g., a detected jailbreak attempt) |
| `500` | Server error | Something broke on our own server's side — a bug, or a misconfiguration (e.g., a missing environment variable) |
| `502` | Server error | Our server is fine, but an *upstream* service we depend on (the AI provider) failed |

Notice `401` vs `403` specifically, since the course draws this distinction carefully: `401` means "I don't know who you are" (missing/wrong API key), while `403` means "I know who you are, but I'm refusing this specific request anyway" (a detected security violation). Mixing these up is a common beginner mistake worth avoiding.

To actually *see* the status code in your terminal (since `curl`'s default output doesn't show it), the course uses this pattern:

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}\n" http://localhost:3000/api/agent/whoami
```

The `-w "\nHTTP_STATUS:%{http_code}\n"` flag ("write-out") appends the actual numeric status code to the end of the printed output, so you can confirm not just *what* the server said, but *what kind of outcome* it was officially reporting.

## Handling Cookies Across Multiple Requests (`-c` and `-b`)

Phase 2 introduces session cookies, and testing them requires `curl` to behave like a real browser — remembering a cookie it received from one request, and sending it back on the next one:

```bash
# First request: -c cookies.txt SAVES any cookies the server sends into a local file
curl -s -c cookies.txt -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "My favorite number is 27."}'

# Second request: -b cookies.txt SENDS BACK whatever cookies were saved,
# simulating the same browser/visitor making a follow-up request
curl -s -b cookies.txt -c cookies.txt -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is my favorite number?"}'
```

Without `-b cookies.txt` on the second call, the server would have no way of knowing this is the "same" visitor as the first request — it would look like a brand new session with no memory at all, which is exactly the failure mode Phase 2's verification steps are designed to catch you out on if you forget this flag.

## A Quick Mental Checklist Before Phase 1

If the following make sense, you're fully ready for every Verification step in this course:

1. `-X POST` sends a POST request; without it, `curl` defaults to `GET`.
2. `-H` attaches a header (metadata); `-d` attaches a body (the actual payload).
3. Piping into `python3 -m json.tool` just makes JSON output readable — it doesn't change the actual response.
4. `401` = "I don't know who you are," `403` = "I know who you are, but no," `500` = "our fault," `502` = "an upstream provider's fault."
5. `-c cookies.txt` saves cookies; `-b cookies.txt` sends them back — you need both together to simulate a real returning visitor across separate requests.
