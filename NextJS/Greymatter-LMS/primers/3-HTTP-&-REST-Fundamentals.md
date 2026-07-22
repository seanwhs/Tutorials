# Primer 03 — HTTP & REST Fundamentals

## Why this primer exists

Every interaction in GreyMatter LMS — a browser loading a page, a Server Action submitting a quiz answer, Clerk delivering a webhook, Inngest invoking a function — is, underneath, an **HTTP request**. Part 1's health-check route, Part 6's webhook signature verification, Part 8's enrollment flow, and Part 13's certificate download all depend on specific HTTP concepts: methods, status codes, headers, and request/response bodies. If terms like "GET request," "status code," or "request body" feel fuzzy, this primer builds that foundation from first principles before you meet it woven into real application code.

**You can safely skip this primer if** you're already comfortable with: HTTP methods (GET/POST/etc.), status codes and what ranges mean, the difference between headers and a body, and roughly what "REST" refers to. If any of those feel uncertain, keep reading.

---

## The core idea: HTTP is a language for asking and answering

**HTTP** (HyperText Transfer Protocol) is simply an agreed-upon format for one computer to ask another computer for something, and for that second computer to answer back. Every time your browser loads a webpage, it's sending an HTTP **request** and receiving an HTTP **response** — the exact same mechanism, whether it's a human clicking a link or one server's code calling another server's API.

**Analogy:** think of HTTP like the standardized format of a business letter. A letter has a specific structure everyone agrees on — a return address, a date, a subject line, a body of text, a signature. You don't invent your own letter format every time you write one; you follow the convention, so the recipient (and the postal system in between) knows exactly how to read and route it. HTTP requests and responses have exactly this kind of agreed-upon structure — a method, a target, headers, and a body — so that browsers, servers, and every tool in between (webhooks, APIs, CDNs) can all interoperate without needing to understand each other's internal code.

```text
      Client (browser, or one server calling another)
                │
                │   HTTP REQUEST
                │   (a method, a URL, headers, maybe a body)
                ▼
              Server
                │
                │   HTTP RESPONSE
                │   (a status code, headers, maybe a body)
                ▼
      Client receives the response
```

---

## HTTP methods: what kind of action is this request asking for?

Every HTTP request declares a **method** — a verb describing the *intent* of the request. There are several, but five matter for this series:

| Method | Intent | Real example from GreyMatter |
|---|---|---|
| `GET` | "Give me this thing" — should never change any data as a side effect | Loading `/courses`, requesting `/api/health` |
| `POST` | "Here's some new data — create/process something with it" | Clerk sending a webhook to `/api/webhooks/clerk`; a form submission |
| `PUT` | "Register/replace this resource" | Inngest's `PUT /api/inngest` — registers the app's function list |
| `PATCH` | "Update part of this existing thing" | Not directly used by name in this series (Server Actions abstract this away), but conceptually what `enrollInCourse` or `updateNotificationPreferences` does |
| `DELETE` | "Remove this thing" | Not directly exposed as a raw route in this series, but conceptually what deleting a user (Part 6's `user.deleted` webhook) accomplishes |

**The single most important rule to internalize about `GET`:** a `GET` request should be *safe* — making it should never change anything on the server. This is why Part 1's `/api/health` endpoint only exports a `GET` function, and why visiting it repeatedly in your browser is harmless. Contrast this with Part 6's Clerk webhook, which is a `POST` — because receiving it genuinely *does* something (creates a user record), and `POST` is the conventional signal for "this request causes a real effect, not just a read."

### Seeing this directly in GreyMatter's own code

Recall Part 1's Route Handler:

```ts
// app/api/health/route.ts
export async function GET() {
  return NextResponse.json({ status: "ok" });
}
```

The function is literally *named* after the HTTP method it handles. If you sent a `POST` request to this exact same URL, Next.js would automatically respond with an error (a `405 Method Not Allowed` — see the status code section below), because this file never exported a `POST` function at all. This is precisely the mechanism Part 1 described: *"a POST to this same URL will automatically receive a 405 Method Not Allowed — we don't have to write that check ourselves."*

Compare this to Part 6's webhook handler, which exports only `POST`:

```ts
// app/api/webhooks/clerk/route.ts
export async function POST(request: Request) {
  // ... verify signature, process the event ...
}
```

Clerk always sends webhooks as `POST` requests, because delivering a webhook is fundamentally "here is new information, please process it" — never a passive "give me something."

---

## Status codes: how the server tells you what happened

Every HTTP response includes a three-digit **status code** summarizing the outcome. These aren't arbitrary — they're grouped into five ranges, and the *first digit* tells you the general category at a glance, even before you know the exact number.

```text
1xx  Informational   — rare in application code; you'll basically never touch this
2xx  Success         — "your request was received and handled successfully"
3xx  Redirection     — "go look somewhere else for this"
4xx  Client Error    — "YOU (the requester) did something wrong"
5xx  Server Error    — "WE (the server) messed up, not you"
```

### The specific codes that appear throughout GreyMatter LMS

| Code | Meaning | Where it appears in the series |
|---|---|---|
| `200 OK` | Success, with a body | The default for any Route Handler that doesn't specify otherwise — Part 1's health check, Part 13's PDF download |
| `400 Bad Request` | The request was malformed or failed validation | Part 6's webhook handler, when Svix headers are missing or a signature fails to verify |
| `404 Not Found` | The requested resource genuinely doesn't exist | Next.js's `notFound()` (Part 4), and Part 13's certificate download route when the certificate ID doesn't match the requesting user |
| `405 Method Not Allowed` | This URL exists, but not for the method you used | Automatic, whenever a Route Handler doesn't export a function for the attempted method |
| `500 Internal Server Error` | Something broke on the server's side, unrelated to what the client sent | The default when an unhandled exception escapes a Route Handler |

**A subtlety worth understanding precisely, because it directly shaped a real design decision in Part 6:** returning a `400` versus a `500` is a meaningful *choice*, not just picking whichever number feels right. Recall Part 6's webhook handler:

```ts
if (!svixId || !svixTimestamp || !svixSignature) {
  return NextResponse.json({ error: "Missing required Svix headers" }, { status: 400 });
}
```

This is `400`, not `500`, because the *problem* is with the incoming request itself (missing headers) — not a failure in our own server logic. The primer's earlier text made exactly this point: *"a 400 communicates 'your request was malformed/unauthorized,' which is the semantically correct status for a failed signature check, distinct from a 500 which would suggest our server is broken."* Getting this distinction right matters in practice — external services like Clerk often behave differently depending on which range they receive (e.g., retrying on a `5xx`, but not retrying on a `4xx`, since a `4xx` implies "sending this exact same request again won't help").

### Where status codes appear less visibly: `redirect()` and `notFound()`

You won't often write `new Response(..., { status: 302 })` directly in this series, because Next.js's own helper functions handle it for you, under the hood:

```ts
// Part 6/7 — redirect() sends a 3xx-range response telling the
// browser "go to this URL instead"
redirect("/sign-in");

// Part 4/7 — notFound() renders your not-found.tsx boundary AND
// ensures the actual HTTP response carries a genuine 404 status code
notFound();
```

This matters for reasons beyond the browser's behavior — search engines and monitoring tools read status codes directly. Part 4 emphasized this exact point: `notFound()` must produce a *real* `404`, "**not** a 200 response with a 'not found' message printed on the page" — because a search engine crawling a `200` response would assume the page is valid content worth indexing, even if the visible text says "not found."

---

## Headers: metadata traveling alongside the request or response

A **header** is a small piece of metadata attached to a request or response — information *about* the message, distinct from its actual content (the body, covered next). Headers are structured as simple key-value pairs.

```text
Content-Type: application/json
Authorization: Bearer abc123xyz
Content-Disposition: attachment; filename="certificate.pdf"
```

### Headers you'll directly encounter in GreyMatter's code

**`Content-Type`** — tells the receiver what *format* the body is in, so it knows how to parse it.

```ts
// Part 1 — NextResponse.json() automatically sets this header for you
return NextResponse.json({ status: "ok" }); // Content-Type: application/json, set automatically
```

```ts
// Part 13 — manually setting Content-Type because we're returning
// raw binary PDF bytes, not JSON, so the automatic helper doesn't apply
return new NextResponse(Buffer.from(pdfBytes), {
  status: 200,
  headers: {
    "Content-Type": "application/pdf",
    "Content-Disposition": `attachment; filename="${certificate.certificateNumber}.pdf"`,
  },
});
```

**`Content-Disposition: attachment; filename="..."`** — this specific header is what tells the browser "don't try to display this inline, offer it as a downloadable file with this suggested name" — exactly what makes clicking "Download PDF" in Part 13 actually trigger a file save dialog rather than navigating to a page showing raw binary gibberish.

**Custom, provider-specific headers** — Part 6's webhook signature verification reads three headers Clerk's delivery system (Svix) attaches to every webhook request:

```ts
const svixId = headerPayload.get("svix-id");
const svixTimestamp = headerPayload.get("svix-timestamp");
const svixSignature = headerPayload.get("svix-signature");
```

These aren't standard HTTP headers like `Content-Type` — they're headers Svix *invented* specifically for its own signature-verification scheme. This is completely normal and common: HTTP allows any header name, and providers frequently define their own custom ones (usually prefixed with something identifying, like `svix-` or `x-`) to carry provider-specific metadata.

---

## The request/response body: the actual content being sent

The **body** is the actual payload of a request or response — the substantive content, as opposed to headers' metadata *about* that content. Not every request has one (a simple `GET` usually doesn't), but `POST` requests almost always do, since their entire purpose is typically "here is data to process."

### Reading a body in a Route Handler — and why the *order* of operations matters

```ts
export async function POST(request: Request) {
  const rawBody = await request.text(); // reads the body as a raw string
  // ...
}
```

Recall Part 6's critical detail: the webhook handler reads the body with `request.text()` — **not** `request.json()` — and this is a deliberate, load-bearing choice, not a stylistic one:

> *"Signature verification is a cryptographic hash computed over the exact original bytes Clerk sent. Parsing to JSON first and later re-serializing it would almost certainly produce slightly different bytes... causing every single verification to fail even for genuinely legitimate requests."*

This is worth sitting with: `request.json()` is *convenient* (it parses the body into a JavaScript object for you automatically) but it's also *destructive* to the original exact byte sequence — and Svix's signature was computed over that *exact* sequence. Reading as raw text first, verifying the signature against those exact bytes, and *then* parsing to JSON afterward (which the `svix` library does internally, safely, after verification succeeds) is the only order that works correctly.

There's also a more basic, universal rule buried in this example: **a request's body can typically only be read once.** Whether you call `.text()` or `.json()`, once you've consumed the stream, attempting to read it again typically fails or returns empty. This is precisely why Part 6's "Common mistakes" section warns: *"Almost always caused by accidentally calling request.json() before request.text() somewhere, or a proxy/middleware layer that has already consumed the request body."*

### Sending a body — and why FormData appears in Server Actions

When a browser submits an HTML `<form>`, its data is traditionally packaged as `FormData` — a specific browser-native format distinct from a plain JavaScript object. This is exactly why Part 8's Server Action reads its input this way:

```ts
export async function enrollInCourse(
  _previousState: EnrollActionResult | null,
  formData: FormData
): Promise<EnrollActionResult> {
  const rawCourseId = formData.get("courseId"); // FormData uses .get(), not plain property access
  // ...
}
```

And the corresponding form:

```tsx
<form action={formAction}>
  <input type="hidden" name="courseId" value={courseId} />
  {/* ... */}
</form>
```

The `name="courseId"` attribute on the input is what becomes the key you retrieve with `formData.get("courseId")` — this pairing (an input's `name` attribute ↔ the key used in `FormData.get(...)`) is a fixed convention worth memorizing, since it appears in every form-driven Server Action in this series.

---

## Parameters: three different ways data travels in a URL/request, and where each appears

This is a genuinely useful distinction to have crisp, because the main series uses all three, and conflating them causes real confusion.

### 1. Path parameters — part of the URL's structure itself

```text
/dashboard/courses/introduction-to-databases/lessons/what-is-a-database
                    └──────────┬──────────┘         └────────┬───────┘
                          courseSlug                     lessonSlug
```

These are the dynamic route segments from Part 4 (`[courseSlug]`) — baked directly into the URL's path, identifying *which specific resource* you want.

### 2. Query parameters — appended after a `?`, as key-value pairs

```text
/instructor/courses/abc123/students?page=2
                                     └──┬──┘
                                     query param
```

Recall Part 15's pagination:

```tsx
<Link href={`?page=${page + 1}`}>
```

```ts
const { page: pageParam } = await searchParams; // Next.js's async searchParams API (Part 15)
```

Query parameters are conventionally used for *optional*, often non-identity-defining modifiers to a request — pagination, sorting, filtering — as opposed to path parameters, which typically identify *which resource* you mean in the first place.

### 3. Body data — the actual payload, for requests that carry one (mainly `POST`)

Covered above — `FormData` for form submissions, JSON for most API-style requests (like Sanity's GROQ query parameters, sent as part of the request body when using `client.fetch(query, params)`).

```text
┌─────────────────────────────────────────────────────────────────┐
│  Path parameter    │ "WHICH resource" — baked into the URL       │
│  Query parameter    │ "HOW to view/filter it" — optional, in ?...  │
│  Body               │ "WHAT to create/change" — the actual payload │
└─────────────────────────────────────────────────────────────────┘
```

---

## REST: a set of conventions, not a strict protocol

**REST** (Representational State Transfer) is a *style* of designing HTTP-based APIs — a set of widely-followed conventions, not a rigid specification enforced by any tool. The core idea: model your API around **resources** (nouns — a course, an enrollment, a certificate), and use HTTP methods as the **verbs** acting on them.

```text
GET    /courses             → "give me the list of courses"
GET    /courses/abc123      → "give me this ONE specific course"
POST   /courses              → "create a new course" (not used this way in GreyMatter —
                                 course creation happens in Sanity Studio instead)
DELETE /courses/abc123      → "delete this specific course"
```

**A genuinely important, easy-to-miss point:** GreyMatter LMS does **not** build a classic REST API for most of its functionality. Recall Part 8's reasoning: Server Actions let a Client Component call server-side logic *directly*, without you manually designing a REST endpoint, choosing a URL naming scheme, or writing client-side `fetch()` calls to consume it. The handful of genuine Route Handlers in this series (Appendix D, Section D.3) exist specifically because *something outside our own React tree* needs a real URL to call — an external webhook provider (Clerk), an external job runner (Inngest), or a browser-initiated file download (certificates, CSV export). Everything else — enrollment, quiz submission, preference updates — deliberately bypasses REST-style URL design entirely, in favor of Server Actions.

This is worth understanding precisely so you don't go looking for a `/api/enrollments` endpoint that was never built — Part 8's enrollment logic lives in `app/dashboard/courses/actions.ts`, called directly as a function, with no REST-style URL of its own at all.

---

## Idempotency, from the HTTP spec's own point of view

Primer 02 touched on idempotency in the context of database writes and background jobs. HTTP itself has a related, foundational concept worth stating precisely here: certain methods are *conventionally expected* to be idempotent — meaning making the same request multiple times has the same effect as making it once.

| Method | Conventionally idempotent? |
|---|---|
| `GET` | Yes — requesting the same thing repeatedly should never change anything |
| `PUT` | Yes — "replace this resource with X" repeated twice still just results in X |
| `DELETE` | Yes — deleting an already-deleted thing typically just results in "still deleted" |
| `POST` | **No** — by convention, POST is assumed to potentially create something NEW each time |

This is exactly why Part 6's webhook idempotency handling is necessary at the *application* level, not something HTTP gives you automatically: a webhook delivery is a `POST` request, and `POST` carries no inherent guarantee of idempotency from HTTP's perspective. If Clerk's infrastructure retries a webhook delivery (a real, documented possibility), nothing about HTTP itself prevents that from being processed twice — which is precisely why Part 5 built the `webhook_events` table and Part 6 built the check-before-process pattern around it. HTTP methods' idempotency is a *convention* API designers are expected to honor when they write their own server logic — it isn't automatically enforced by the protocol itself.

---

## Putting it all together: tracing one real request through every concept in this primer

Let's trace Part 6's Clerk webhook delivery, end to end, naming every concept from this primer as it appears:

```text
1. A user signs up. Clerk's servers construct an HTTP request:

   METHOD: POST                                    ← "this creates/processes something"
   URL: https://your-app.com/api/webhooks/clerk     ← the target Route Handler
   HEADERS:
     Content-Type: application/json                 ← body format
     svix-id: msg_abc123                             ← custom, provider-specific header
     svix-timestamp: 1700000000                      ← custom, provider-specific header
     svix-signature: v1,abc123...                     ← custom, provider-specific header
   BODY:
     { "type": "user.created", "data": { "id": "user_xyz", ... } }

2. Our Route Handler's exported POST function runs (matched by METHOD)

3. rawBody = await request.text()                   ← reads body as raw string,
                                                        preserving exact bytes

4. Signature verified against svix-id/timestamp/signature headers
   and the raw body bytes

5. If verification fails:
   return NextResponse.json({ error: "..." }, { status: 400 })
                                                      ← 4xx: "YOUR request was invalid"

6. If verification succeeds: process the event, write to the database

7. return NextResponse.json({ received: true })
                                                      ← 200 OK, default status,
                                                        Content-Type: application/json
                                                        set automatically
```

If every step of that trace makes sense — why it's `POST` not `GET`, why the raw body matters, why a `400` rather than a `500` is returned on bad signatures — you're ready for Part 1.

---

## You're ready for Part 1 if you can answer these

1. What's the practical difference between a `GET` request and a `POST` request, and why should a `GET` request never have side effects?
2. What do the five status code ranges (`1xx`–`5xx`) broadly mean, and specifically, why would a failed webhook signature check return `400` rather than `500`?
3. What's the difference between a header and a body, and can you name one header used in this series along with what it communicates?
4. What's the difference between a path parameter, a query parameter, and body data — and can you identify which one `courseSlug` is in `/courses/[courseSlug]`?
5. Why does GreyMatter LMS use Server Actions instead of building a classic REST API for enrollment and quiz submission, and what kinds of operations in this series *do* still need a real Route Handler?

If all five feel solid, you're ready to continue — either into Part 1 directly, or into Primer 04 (Relational Database Basics) if you're working through the primers in sequence.
