# Next.js 16 for Absolute Beginners

# Part 41 — Real-Time Systems, WebSockets, SSE, and Live Updates

> **Goal of this lesson:** Learn how to build production-grade real-time applications using Next.js 16, Server-Sent Events (SSE), WebSockets, event streams, notifications, presence systems, and scalable real-time architectures.

---

# The Third Biggest Lie in Web Development

The first lie:

> Users wait.

The second lie:

> Everything happens immediately.

The third lie:

> Users will refresh the page.

They won't.

Modern users expect:

```text
Instagram
Slack
Discord
WhatsApp
Google Docs
Trading platforms
```

Everything updates instantly.

---

# Beginners Build This

```text
User
  |
Refresh
  |
Refresh
  |
Refresh
```

Unfortunately:

```text
❌ Slow
❌ Expensive
❌ Wasteful
❌ Bad UX
```

---

# What Is Real-Time?

Real-time means:

```text
Server
    |
Push
    |
Browser
```

instead of:

```text
Browser
    |
Ask
    |
Server
```

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ Polling
✓ Long polling
✓ Server-Sent Events
✓ WebSockets
✓ Presence systems
✓ Notifications
✓ Live dashboards
✓ Chat systems
✓ Event streams
✓ Scalable realtime architectures
```

---

# Method 1 — Polling

The simplest approach:

```text
Browser
    |
Every 5 seconds
    |
Request
```

---

# Example

```tsx
useEffect(() => {

  const timer =
    setInterval(
      loadData,
      5000
    );

  return () =>
    clearInterval(
      timer
    );

}, []);
```

---

# Visualizing Polling

```text
Client
   |
GET
   |
Server

(wait)

Client
   |
GET
   |
Server
```

---

# Problems

```text
❌ High cost
❌ Duplicate data
❌ Slow updates
❌ Battery drain
```

---

# Method 2 — Long Polling

Instead of:

```text
Ask every 5 seconds
```

do:

```text
Ask once
Wait
Receive event
Ask again
```

---

# Visualizing Long Polling

```text
Browser
    |
Request
    |
Wait
    |
Server Event
    |
Response
```

---

# Better.

But still not ideal.

---

# Method 3 — Server-Sent Events (SSE)

SSE creates:

```text
Server
    |
Streaming
    |
Browser
```

connection.

---

# Advantages

```text
✓ Simple
✓ HTTP
✓ Lightweight
✓ Automatic reconnect
✓ Great for dashboards
```

---

# Create SSE Route

```text
app/api/events/route.ts
```

---

```ts
export async function
GET() {

  const stream =

    new ReadableStream({

      start(controller) {

        setInterval(() => {

          controller.enqueue(

            `data: ${
              Date.now()
            }\n\n`

          );

        }, 1000);

      },

    });

  return new Response(

    stream,

    {

      headers: {

        "Content-Type":
          "text/event-stream",

      },

    }

  );

}
```

---

# Client

```tsx
useEffect(() => {

  const events =

    new EventSource(
      "/api/events"
    );

  events.onmessage =

    event => {

      console.log(
        event.data
      );

    };

}, []);
```

---

# Visualizing SSE

```text
Server
   |
===========
Streaming
===========
   |
Browser
```

---

# Why SSE?

Perfect for:

```text
Notifications
Dashboards
Stock prices
Monitoring
Analytics
```

---

# Example Dashboard

```text
CPU: 23%

RAM: 62%

Users: 1523
```

updates instantly.

---

# Method 4 — WebSockets

WebSockets create:

```text
Bidirectional
communication.
```

---

# Visualizing

```text
Browser
    |
<---->
    |
Server
```

---

# Unlike SSE

SSE:

```text
Server
    |
Browser
```

WebSocket:

```text
Server
<---->
Browser
```

---

# Why?

Because chat requires:

```text
Client
     |
Message
     |
Server
     |
Message
     |
Other Client
```

---

# Install Socket.IO

```bash
npm install socket.io
```

---

# Server

```ts
io.on(

  "connection",

  socket => {

    socket.on(

      "message",

      msg => {

        io.emit(
          "message",
          msg
        );

      }

    );

  }

);
```

---

# Client

```tsx
socket.emit(

  "message",

  "Hello"

);
```

---

# Receive

```tsx
socket.on(

  "message",

  msg => {

    console.log(
      msg
    );

  }

);
```

---

# Visualizing Chat

```text
User A
   |
Server
   |
User B
```

---

# Step 5 — Build Notifications

Database:

```prisma
model Notification {

  id String
     @id

  userId String

  message String

  read Boolean
       @default(false)

}
```

---

# Notification Flow

```text
User Action
      |
Create Notification
      |
Push Event
      |
Browser Updates
```

---

# Example Event

```json
{
  "type":
    "notification",

  "message":
    "New comment"
}
```

---

# Step 6 — Presence Systems

Presence answers:

```text
Who is online?
```

---

Example:

```text
Sean   ●
Alice  ●
Bob    ○
```

---

# Store Presence

```text
user123

lastSeen:
10:30:45
```

---

# Update Every

```text
30 seconds
```

---

# Visualizing Presence

```text
User
   |
Heartbeat
   |
Server
```

---

# Heartbeat Example

```ts
setInterval(

  () => {

    socket.emit(

      "heartbeat"

    );

  },

  30000

);
```

---

# Server

```ts
socket.on(

  "heartbeat",

  () => {

    updatePresence();

  }

);
```

---

# Step 7 — Live Comments

User submits:

```text
Nice article!
```

---

Flow:

```text
Comment
    |
Database
    |
Event
    |
Subscribers
```

---

# Visualizing

```text
User A
    |
Comment
    |
Server
    |
Broadcast
    |
Users B,C,D
```

---

# Step 8 — Live Dashboards

Example:

```text
Orders:
523

Revenue:
$102,000

Users:
38,221
```

---

Update using:

```text
SSE
```

because:

```text
Server -> Browser
```

is sufficient.

---

# Step 9 — Event Streams

Instead of:

```ts
await sendEmail();

await analytics();

await notify();
```

create:

```json
{
  "event":
    "order.created"
}
```

---

Then:

```text
Order Event
      |
      +---- Email
      |
      +---- Analytics
      |
      +---- Notifications
```

---

# Why?

Benefits:

```text
✓ Decoupling
✓ Scalability
✓ Reliability
```

---

# Step 10 — Pub/Sub Architecture

One server:

```text
User
   |
Server
```

works.

Multiple servers:

```text
User
   |
Server A

User
   |
Server B
```

break.

---

# Solution

```text
Redis
Pub/Sub
```

---

# Visualizing

```text
          Redis

          /   \
         /     \

Server A      Server B
```

---

# Step 11 — Distributed Realtime

Example:

```text
Singapore
Tokyo
London
New York
```

servers.

---

Architecture:

```text
Users
   |
Regional Server
   |
Event Bus
   |
Global Broadcast
```

---

# Step 12 — Connection Management

Suppose:

```text
100,000 users
```

connect.

You need:

```text
100,000 sockets.
```

---

# Why This Matters

Memory:

```text
100 KB/socket
```

means:

```text
10 GB RAM
```

---

# Step 13 — Reconnection

Connections die.

Always implement:

```text
Reconnect
```

---

Example:

```ts
socket.on(

  "disconnect",

  reconnect

);
```

---

# Step 14 — Event Ordering

Problem:

```text
Message 3

Message 1

Message 2
```

Oops.

---

Solution:

```json
{
  "sequence": 15
}
```

---

# Step 15 — Delivery Guarantees

There are three models:

---

### At Most Once

```text
Send once.

May lose.
```

---

### At Least Once

```text
Retry.

May duplicate.
```

---

### Exactly Once

```text
Very expensive.
```

---

# Most Systems Use

```text
At least once.
```

---

# Step 16 — Real-Time + Next.js

Next.js handles:

```text
✓ Pages
✓ Server Actions
✓ APIs
✓ Caching
```

Realtime servers handle:

```text
✓ WebSockets
✓ Streams
✓ Presence
```

---

# Architecture

```text
Browser
     |
Next.js
     |
Database

Browser
     |
Realtime Server
     |
Redis
```

---

# Step 17 — Full Realtime Architecture

```text
                 Browser
                     |
          +----------+---------+
          |                    |
          V                    V
       Next.js          Realtime Server
          |                    |
          V                    V
      Database            Redis PubSub
                               |
                               V
                       Event Distribution
```

---

# When To Use What

| Technology   | Best For            |
| ------------ | ------------------- |
| Polling      | Simple apps         |
| Long Polling | Legacy              |
| SSE          | Dashboards          |
| WebSockets   | Chat                |
| Pub/Sub      | Distributed systems |

---

# What We've Built

```text
✓ Polling

✓ Long polling

✓ SSE

✓ WebSockets

✓ Notifications

✓ Presence

✓ Live comments

✓ Dashboards

✓ Pub/Sub

✓ Distributed realtime
```

---

# Realtime Philosophy

Beginners think:

```text
Refresh page.
```

Professional engineers think:

```text
Subscribe to events.
```

Because users don't want pages.

They want reality.

---

# Exercises

## Exercise 1

Build:

```text
Live notifications.
```

---

## Exercise 2

Build:

```text
Online presence.
```

---

## Exercise 3

Build:

```text
Live comments.
```

---

## Exercise 4

Build:

```text
Real-time analytics dashboard.
```

---

# Mental Model

Beginners build:

```text
Websites.
```

Professional engineers build:

```text
Event systems.
```

Because modern applications aren't collections of pages.

They're streams of events.

---

# Part 42 Preview

In the next chapter we'll build:

# Observability, Logging, Monitoring, Tracing, and Production Operations

Including:

```text
✓ Structured logging
✓ Error tracking
✓ Metrics
✓ Distributed tracing
✓ OpenTelemetry
✓ Health checks
✓ Dashboards
✓ Alerting
✓ SLOs and SLIs
✓ Production debugging
```

This is where Next.js becomes an operable production system.
