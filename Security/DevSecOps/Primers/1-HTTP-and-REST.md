# Primer 1: HTTP & REST — The Language Your API Speaks

**Feeds into:** Phase 1 (the Express server) and Phase 2 (the notes & auth routes).
**You'll be ready when:** you can look at `POST /notes` returning `201` and know exactly what each part means.

---

## Why this matters first

Our entire application, `securenotes`, is an **API** — and that API does exactly one thing: it *speaks HTTP*. Every `curl` command you'll run, every route you'll write, every security header Helmet sets, every status code a scanner checks — all of it is HTTP.

Here's the honest truth: most security bugs in web apps aren't exotic. They're a misunderstanding of *how requests and responses actually work* — trusting input that shouldn't be trusted, returning data that shouldn't be returned, or using the wrong method for the wrong job. So before we secure the conversation, you need to understand the conversation.

Let's learn the language.

---

## 1. The core idea: request → response

At its heart, HTTP (**HyperText Transfer Protocol** — the rules computers use to talk over the web) is astonishingly simple. It's a **conversation between two parties** where one always speaks first:

- The **client** (a browser, a mobile app, or your `curl` command) sends a **request**.
- The **server** (our `securenotes` app) sends back a **response**.

That's it. One request, one response. The server never speaks unprompted — it only ever *answers*.

> **The restaurant analogy (we'll reuse this all series):**
> - The **client** is a *customer* placing an order.
> - The **request** is the *order slip* ("I'll have the salmon, no onions").
> - The **server** is the *kitchen*.
> - The **response** is the *plate that comes back* (or an apology: "we're out of salmon").
>
> The kitchen never sends you food you didn't order. You ask; it answers. Every single time.

This "you ask, it answers" model is called **stateless** — a word that will matter enormously in Phase 2.

> **Definition — Stateless:** The server remembers *nothing* about you between requests. Each request must carry *everything* the server needs to understand it. The kitchen doesn't remember you were here yesterday, or even 10 seconds ago — every order slip must be complete on its own.
>
> This is *why* we'll need JWTs (Primer 2): since the server forgets you instantly, you must prove who you are on *every* request by attaching a token. Statelessness isn't a limitation to work around — it's the design, and security controls are built to fit it.

---

## 2. Anatomy of a request

Every HTTP request has up to four parts. Let's dissect a real one from Phase 2 — creating a note:

```http
POST /notes HTTP/1.1
Host: localhost:3000
Authorization: Bearer eyJhbGciOiJIUzI1Ni…
Content-Type: application/json

{"title":"My first note","body":"hello"}
```

Breaking it down piece by piece:

### (a) The method — *what do you want to do?*
`POST` is the **method** (also called the "verb"). It's the *intent* of the request. Think of it as the *type of action* on the order slip: are you placing a new order, checking on one, changing one, or cancelling one?

The main methods, with their real meaning:

| Method | Restaurant meaning | In `securenotes` |
|---|---|---|
| **GET** | "Show me the menu / my order" | `GET /notes` → list my notes |
| **POST** | "I'd like to place a new order" | `POST /notes` → create a note |
| **PUT / PATCH** | "Change my existing order" | update a note |
| **DELETE** | "Cancel my order" | `DELETE /notes/:id` → delete a note |

> **The security-critical rule — safe vs unsafe methods:**
> `GET` is meant to be **safe** — it should only *read*, never *change* anything. A `GET` request that deletes data is a classic vulnerability (an attacker can trigger it just by tricking you into loading an image URL). This is why in Phase 2 we use `DELETE` for deletion and `GET` only for reading. The method isn't decoration — it's a security contract.

### (b) The path — *which resource?*
`/notes` is the **path** — *what* you're acting on. In REST, paths name *things* (resources), like folders in a filing cabinet:

- `/notes` → the collection of all (my) notes
- `/notes/abc-123` → one specific note, identified by its ID
- `/auth/login` → the login action

Notice paths are **nouns**, not verbs. You don't write `/getNotes` or `/deleteNote`. You write the *noun* (`/notes`) and let the **method** supply the *verb*. `GET /notes` (get the notes) vs `DELETE /notes/123` (delete note 123). This noun-based, method-driven design *is* what "REST" means (more on that in section 5).

### (c) Headers — *the metadata / the fine print*
```http
Host: localhost:3000
Authorization: Bearer eyJhbGciOiJIUzI1Ni…
Content-Type: application/json
```

**Headers** are key–value pairs of *metadata* — information *about* the request, not the request's actual content. On our order slip, headers are the fine print at the top: table number, dietary notes, "who's paying."

Headers you'll meet constantly in this series:

| Header | What it says | Where it appears |
|---|---|---|
| `Content-Type: application/json` | "The body I'm sending is JSON" | Phase 1 body parser |
| `Authorization: Bearer <token>` | "Here's my ID badge" (the JWT) | Phase 2 auth |
| `X-Content-Type-Options: nosniff` | "Browser, don't guess file types" | Phase 1 Helmet |
| `Retry-After: 60` | "You're rate-limited; wait 60s" | Phase 5 brute-force guard |

> **Why headers matter for security:** headers are *untrusted input just like everything else*. A header saying `Authorization: Bearer …` is a *claim*, not proof — the server must **verify** that token (Phase 2), never just believe it. Meanwhile, the *response* headers Helmet adds (Phase 1) are instructions telling the browser to behave defensively. Headers flow both ways and both directions matter.

### (d) The body — *the actual payload*
```json
{"title":"My first note","body":"hello"}
```

The **body** is the actual content — the data you're sending. `GET` and `DELETE` requests usually have *no* body (you're just asking or cancelling). `POST`, `PUT`, and `PATCH` carry a body (the new/changed data).

Our bodies are **JSON** (**JavaScript Object Notation** — a simple text format of `{"key": "value"}` pairs that both humans and machines read easily). It's the universal language of modern APIs.

> **The single most important security lesson in this primer:** *the body is 100% attacker-controlled.* Anyone can send any bytes they want in a request body. This is precisely why Phase 2 validates every body with Zod before trusting a single field of it (golden rule #3: "all input is validated at the edge"). The body is a stranger handing you a note — you read it carefully; you never act on it blindly.

---

## 3. Anatomy of a response

The server answers with a response that mirrors the request's structure:

```http
HTTP/1.1 201 Created
Content-Type: application/json
X-Content-Type-Options: nosniff

{"id":"abc-123","title":"My first note","body":"hello","createdAt":"2024-…"}
```

It has three parts:

### (a) The status code — *how did it go?*
`201 Created` is the **status code** — a three-digit number summarizing the outcome. This is the *first* thing you check, and the thing scanners and tests check constantly.

Status codes come in ranges, and the range tells you the *category* at a glance:

| Range | Meaning | Restaurant analogy | Examples you'll use |
|---|---|---|---|
| **2xx** | ✅ Success | "Here's your food" | `200 OK`, `201 Created`, `204 No Content` |
| **3xx** | ↪️ Redirect | "That's served at the bar next door" | `301`, `302` |
| **4xx** | 🙅 *Your* fault (client error) | "We can't make that order" | `400`, `401`, `403`, `404`, `429` |
| **5xx** | 💥 *Our* fault (server error) | "The kitchen caught fire" | `500` |

The ones that carry security meaning in this series:

| Code | Name | When we use it |
|---|---|---|
| `200` | OK | Successful GET/read |
| `201` | Created | Successful POST (a note was created) |
| `204` | No Content | Successful DELETE (nothing to return) |
| `400` | Bad Request | Input failed Zod validation |
| `401` | Unauthorized | Missing/invalid token — *"who are you?"* |
| `403` | Forbidden | Valid token, but not allowed — *"I know you, and no."* |
| `404` | Not Found | Resource doesn't exist (or you don't own it) |
| `429` | Too Many Requests | Rate limit / brute-force lockout hit |
| `500` | Internal Server Error | Something broke on our side |

> **The 401 vs 403 distinction is a real security decision.** `401` means *"I don't know who you are"* (no valid ID badge). `403` means *"I know who you are, but you can't do this"* (valid badge, wrong clearance). Using them precisely matters — and note in Phase 2 we sometimes deliberately return `404` instead of `403` when a user asks for a note they don't own. Why? Returning `403` would *confirm the note exists*, leaking information. `404` reveals nothing. That's the STRIDE "Information Disclosure" threat, defended with a well-chosen status code.

### (b) Response headers
Same idea as request headers, but flowing back. This is where Phase 1's Helmet does its work — every response carries protective headers (`X-Content-Type-Options`, `X-Frame-Options`, etc.) instructing the browser to behave safely.

### (c) Response body
The data you asked for (the created note, the list of notes), or a safe error message. Note Phase 1's error handler *never* puts a raw stack trace here — a leaked stack trace is Information Disclosure, so the body only ever says `{"error":"Internal server error"}` to the outside world while the real detail goes to the logs.

---

## 4. A full round trip, annotated

Let's watch one complete conversation — logging in — and label every part you now know:

```bash
curl -X POST http://localhost:3000/auth/login \    # METHOD + full URL
  -H "Content-Type: application/json" \             # a request HEADER
  -d '{"email":"a@x.com","password":"secret12345"}' # the request BODY
```

What happens, step by step:

1. **Client sends** a `POST` request to the path `/auth/login`, with a header declaring JSON and a body containing credentials.
2. **Server receives** it. Because it's *stateless*, it knows nothing about this client — it must judge the request entirely on its contents.
3. **Server validates** the body (Phase 2's Zod schema). Bad input → `400`.
4. **Server checks** the credentials (bcrypt compare, Phase 2). Wrong → `401`.
5. **Server responds.** Success → `200` with a body `{"token":"eyJ…"}`.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{"token":"eyJhbGciOiJIUzI1NiIs…"}
```

That token in the response body is your **ID badge** for all future requests. Because the server is stateless and won't remember you, *your next request must carry it*:

```bash
curl http://localhost:3000/notes \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs…"   # present the badge every time
```

And there's the whole loop: **you ask (with proof), it answers.** Statelessness → carry your token → the server verifies it fresh each time. This exact rhythm is what Primer 2 (Auth) explains in depth.

---

## 5. What "REST" actually means

You'll see "REST API" everywhere. Now that you know the pieces, the definition is easy:

> **Definition — REST (Representational State Transfer):** A style of building APIs where you model your app as **resources** (nouns, addressed by paths like `/notes`) and act on them using **HTTP methods** (verbs like `GET`/`POST`/`DELETE`), returning appropriate **status codes**.

That's genuinely all it is. A "RESTful" API is one that plays by these conventions:

| Instead of… | REST says… |
|---|---|
| `POST /createNote` | `POST /notes` |
| `GET /getNoteById?id=123` | `GET /notes/123` |
| `POST /deleteNote?id=123` | `DELETE /notes/123` |

The payoff is **predictability**: any developer (or scanner, or tool) can look at `DELETE /notes/123` and instantly know what it does, without reading your code. Predictability is a security asset — surprising, undocumented endpoints are where vulnerabilities hide. Our entire Phase 2 API is built exactly this way, which is why it maps so cleanly onto scanners and tests later.

---

## 6. The five things to carry into the series

If you remember nothing else, remember these — each one directly produces a security control later:

1. **HTTP is request → response, and nothing else.** You ask; the server answers.
2. **The server is stateless** — it forgets you instantly, so every request must carry its own proof (→ JWTs, Phase 2).
3. **The method is a contract:** `GET` reads, `POST` creates, `DELETE` removes. Don't mix them (→ safe-method security).
4. **The request body is attacker-controlled input.** Validate it before trusting it (→ Zod validation, golden rule #3).
5. **Status codes carry security meaning.** `401` vs `403` vs `404` are deliberate choices that can leak — or protect — information.

---

## ✅ Self-check (prove you're ready)

Answer these in your head; if all five are easy, you're ready for Phase 1:

1. A request comes in as `DELETE /notes/abc-123`. What is the *method*, what is the *resource*, and what should happen?
2. Why can't the server just "remember" that you logged in a minute ago?
3. You send a `POST` with a body, but forget the `Content-Type: application/json` header. Why might the server fail to read your body?
4. A user requests a note they don't own. Why might returning `404` be *more secure* than returning `403`?
5. The server hits an unexpected crash. Why should the response body say `"Internal server error"` instead of the actual error details?
