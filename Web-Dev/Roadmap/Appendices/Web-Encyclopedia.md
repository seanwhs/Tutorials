# Appendix B: The Web Encyclopedia

Quick-reference glossary. Each term links back conceptually to the Part where it was first taught in depth.

## B.1 Core Networking

| Term | Definition | See Part |
|---|---|---|
| **IP (Internet Protocol)** | Addressing/routing protocol that gets packets from one machine to another across networks, using numeric addresses (IPv4/IPv6) | Part 1.2 |
| **DNS (Domain Name System)** | The distributed "phonebook" that resolves human-readable domain names to IP addresses via a hierarchy of resolvers (recursive -> root -> TLD -> authoritative) | Part 1.2 |
| **TCP/IP** | The two-layer combo: IP handles addressing/routing of packets; TCP sits on top and guarantees reliable, ordered, error-checked delivery via a handshake (`SYN`/`SYN-ACK`/`ACK`) | Part 1.3 |
| **TLS (Transport Layer Security)** | Encryption handshake layered on top of TCP that makes HTTP into HTTPS; negotiates keys so subsequent traffic is unreadable to eavesdroppers | Part 1.3 |
| **HTTP** | Application-layer protocol defining how a client requests a resource and a server responds — stateless, request/response based | Part 1.4 |

## B.2 HTTP Status Codes

| Range | Meaning | Common codes |
|---|---|---|
| **2xx — Success** | The request was received, understood, and accepted | `200 OK`, `201 Created`, `204 No Content` |
| **3xx — Redirection** | The client must take additional action to complete the request | `301 Moved Permanently`, `302 Found`, `304 Not Modified` |
| **4xx — Client Error** | The request has bad syntax or cannot be fulfilled due to something on the requester's side | `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `429 Too Many Requests` |
| **5xx — Server Error** | The server failed to fulfill a valid request | `500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable` |

Individual codes worth memorizing cold:

| Code | Name | Typical meaning |
|---|---|---|
| `200` | OK | Standard success |
| `201` | Created | A `POST` successfully created a new resource |
| `204` | No Content | Success, but no body to return (common on `DELETE`) |
| `301` | Moved Permanently | Resource has a new permanent URL |
| `304` | Not Modified | Cached version is still valid — no body sent |
| `400` | Bad Request | Malformed request (e.g., invalid JSON body) |
| `401` | Unauthorized | Missing or invalid authentication |
| `403` | Forbidden | Authenticated, but not permitted |
| `404` | Not Found | Resource doesn't exist at this URL |
| `429` | Too Many Requests | Rate limit exceeded |
| `500` | Internal Server Error | Unhandled exception on the server |
| `503` | Service Unavailable | Server temporarily overloaded/down for maintenance |

## B.3 Rendering & Rehydration Concepts

| Term | Definition | See Part |
|---|---|---|
| **SSR (Server-Side Rendering)** | HTML is generated on the server *per request*, then sent to the browser already populated with content | Part 5.1 |
| **SSG (Static Site Generation)** | HTML is generated once, at *build time*, and served identically to every visitor (fastest possible response, since no per-request server work happens) | Part 5.1 |
| **Hydration** | The process where React attaches event listeners and internal state to server-rendered HTML already in the DOM, making it interactive, without re-creating the DOM from scratch | Part 5.4 |
| **Server Component** | A React component that renders exclusively on the server, sends zero JS to the browser, and can safely use server-only resources (DB, secrets) | Part 5.2 |
| **Client Component** | A React component (marked `"use client"`) that renders once on the server for initial HTML, then hydrates and runs interactively in the browser | Part 5.2–5.4 |
| **Route Handler** | A Next.js file (`route.ts`) exporting functions named after HTTP verbs (`GET`, `POST`, etc.), serving a URL path directly — the App Router's equivalent of a traditional REST endpoint | Part 5.7 |
| **Server Action** | A server-only function (`"use server"`) callable directly from client code/forms, which Next.js wires into a `POST` request automatically | Part 6.1 |

## B.4 JavaScript Runtime Concepts

| Term | Definition | See Part |
|---|---|---|
| **Call stack** | The structure tracking currently-executing synchronous function calls; JS runs everything on the stack to completion before touching queued async work | Part 4.3 |
| **Microtask queue** | Holds Promise `.then()`/`async` continuations; fully drained before the next macrotask runs | Part 4.3 |
| **Macrotask queue** | Holds `setTimeout`, I/O callbacks, UI events; one is processed per event loop tick, after microtasks are drained | Part 4.3 |
| **Closure** | A function that retains access to variables from its enclosing scope even after that scope has returned | Part 4.6 |
| **Idempotent** | An operation that produces the same server state no matter how many times it's repeated (`GET`, `PUT`, `DELETE` are idempotent by spec; `POST` is not) | Part 1.6 |

---
*See also: `Roadmap Tutorial - Appendix A: Codebase Reference`, `Roadmap Tutorial - Appendix C: Deployment Checklist`*
