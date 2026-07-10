# Part 1: The Invisible Web

## 1.1 Concept: Internet vs. Web

Two different things, constantly confused:

- **The Internet** is the physical/logical network: cables, routers, satellites, and the protocols (IP, TCP) that let any two machines exchange packets of data anywhere on Earth.
- **The Web** is one application built on top of the Internet: a system of linked documents (pages) transferred using HTTP and rendered by browsers.

Email, video calls, and multiplayer games also run on the Internet but are not "the Web." The Web is the Internet plus three specific technologies: HTTP, HTML, and URLs.

## 1.2 How a Domain Becomes an IP Address: DNS

Computers route traffic using numeric IP addresses (e.g. `76.76.21.21`), not names like `vercel.com`. DNS (Domain Name System) is the phonebook that converts names to addresses.

When you type `https://example.com` and hit Enter:

1. Browser checks its own cache for a recent lookup of `example.com`.
2. If not cached, it asks the OS resolver, which asks a **recursive resolver** (usually run by your ISP or a public one like `1.1.1.1`).
3. That resolver walks the DNS hierarchy: Root server -> TLD server (`.com`) -> Authoritative name server for `example.com`.
4. The authoritative server returns an `A` record (IPv4) or `AAAA` record (IPv6) — the actual IP address.
5. The browser caches this result (respecting a TTL) and finally has an address to connect to.

This entire round trip typically happens in single-digit-to-low-double-digit milliseconds, and is why the very first request to a brand-new domain feels slightly slower than subsequent ones.

## 1.3 Establishing a Connection: TCP and TLS

Once the browser has an IP, it can't just start sending HTML requests. It first needs a reliable channel:

1. **TCP three-way handshake:** `SYN` -> `SYN-ACK` -> `ACK`. This establishes a reliable, ordered, error-checked connection between your machine and the server.
2. **TLS handshake (for HTTPS):** the client and server negotiate encryption keys so all further traffic is encrypted. This is why HTTPS connections are slightly slower to establish than plain HTTP — you're paying a fixed latency cost for security.

Only after both handshakes complete can the actual HTTP request be sent.

## 1.4 The Request-Response Cycle

This is the single most important mental model in this entire series. Everything in Next.js exists to manage this cycle well.

```
CLIENT (Browser)                          SERVER
      |                                       |
      |------- HTTP Request ---------------->|
      |  GET /dashboard HTTP/1.1              |
      |  Host: example.com                    |
      |  Accept: text/html                     |
      |  Cookie: session=abc123                |
      |                                        |
      |                                (server does work:
      |                                 reads DB, renders
      |                                 HTML, etc.)
      |                                        |
      |<------ HTTP Response -----------------|
      |  HTTP/1.1 200 OK                       |
      |  Content-Type: text/html               |
      |  Content-Length: 1523                   |
      |                                        |
      |  <html>...</html>                      |
```

Two properties of this cycle define everything downstream:

- **Statelessness:** Each HTTP request is independent. The server does not inherently "remember" you between requests — that's why cookies/sessions exist as a bolted-on mechanism.
- **It's a cycle, not a stream:** The client waits, the server responds once (in classic HTTP), the connection cycle repeats for every new resource (CSS, JS, images, fonts, XHR/fetch calls).

**Why this matters for Next.js:** A Server Component runs *during* this response phase, on the server, before any HTML reaches the browser. A Client Component's interactive code only runs *after* the response has arrived and the browser has parsed and executed the JavaScript. Every "why is this a Server Component vs Client Component" question later in this series is really a question about *which side of this diagram the code needs to run on.*

## 1.5 Anatomy of an HTTP Request

```
GET /api/tasks?boardId=42 HTTP/1.1
Host: devboard.example.com
User-Agent: Mozilla/5.0 (...)
Accept: application/json
Authorization: Bearer eyJhbGciOi...
```

- **Method (verb):** what kind of action (see 1.6)
- **Path + query string:** which resource, with optional parameters
- **Headers:** metadata (content type, auth, caching hints)
- **Body:** (optional, common on POST/PUT/PATCH) the actual payload, often JSON

## 1.6 HTTP Verbs (Methods)

| Verb | Purpose | Idempotent? | Has body? | Example in DevBoard |
|---|---|---|---|---|
| `GET` | Retrieve a resource | Yes | No | Fetch all cards on a board |
| `POST` | Create a new resource | No | Yes | Create a new card |
| `PUT` | Replace a resource entirely | Yes | Yes | Replace a card's full data |
| `PATCH` | Partially update a resource | No | Yes | Move a card to a new column |
| `DELETE` | Remove a resource | Yes | No | Delete a card |

**Idempotent** means calling it multiple times has the same effect as calling it once. `GET /cards/5` always returns card 5 regardless of how many times you call it. `POST /cards` called 3 times creates 3 cards — not idempotent.

## 1.7 Anatomy of an HTTP Response

```
HTTP/1.1 200 OK
Content-Type: application/json
Cache-Control: max-age=60
Set-Cookie: session=abc123; HttpOnly; Secure

{"id": 42, "title": "Fix login bug", "column": "todo"}
```

- **Status line:** protocol version + status code + short text reason
- **Headers:** metadata about the response (content type, caching rules, cookies to set)
- **Body:** the actual payload — HTML, JSON, an image, etc.

## 1.8 Status Codes at a Glance

Full reference lives in Appendix B, but the categories you must internalize now:

- **2xx** — success (`200 OK`, `201 Created`, `204 No Content`)
- **3xx** — redirection (`301 Moved Permanently`, `302 Found`, `304 Not Modified`)
- **4xx** — client error, you (the requester) did something wrong (`400 Bad Request`, `401 Unauthorized`, `404 Not Found`)
- **5xx** — server error, the server broke while handling a valid request (`500 Internal Server Error`, `503 Service Unavailable`)

Professional habit: when debugging, the *first* thing to check is the status code in the Network tab, before reading a single line of response body.

## 1.9 Under the Hood: Where Does Next.js Fit?

A traditional static HTML site: server sends a finished file, browser paints it, done. A traditional client-side React app (pre-SSR): server sends a nearly-empty HTML shell plus a big JS bundle; the browser must download, parse, and execute that JS *before* anything meaningful appears — a real user-facing cost.

Next.js's App Router exists to give you a dial between those two extremes on a per-component basis:

- **Server Components** run during the response-generation phase on the server (section 1.4), producing HTML/RSC payload directly — no client JS shipped for that component's logic.
- **Client Components** ship JS that runs after the response arrives, enabling interactivity (`useState`, event handlers, browser APIs).

You'll return to this exact diagram in Part 5 when Server vs. Client Components stop being an abstract rule and become a concrete architectural decision.

## Exercise Challenge

Using your browser's DevTools (Network tab):

1. Open any website, open DevTools -> Network tab, and reload the page.
2. Click the very first request (the HTML document request).
3. Identify: the request method, the response status code, at least 3 request headers, and at least 3 response headers.
4. Find one request on the page that is a `POST` and explain, in one sentence, why a `POST` was necessary instead of a `GET`.

## Solution & Explanation

- The first request is almost always `GET` for the document itself, with status `200` (or `304 Not Modified` if cached).
- Common request headers: `User-Agent`, `Accept`, `Accept-Language`, `Cookie`.
- Common response headers: `Content-Type`, `Cache-Control`, `Set-Cookie`, `Server`.
- `POST` requests typically appear for analytics beacons, login forms, or search-as-you-type submissions — anything that *creates or mutates* something server-side, since `GET` requests should never have side effects (this is the same idempotency principle from 1.6, and it's why Next.js Server Actions are implemented as `POST` requests under the hood).

---
*Next: `Roadmap Tutorial - Part 2: The Developer Environment`*
