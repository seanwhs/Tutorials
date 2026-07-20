# Primer 2: Next.js App Router Orientation

*Optional pre-reading. If you've already built a Route Handler in Next.js's App Router before, skip straight to Part 0 of the main course.*

## Why This Primer Exists

Every single endpoint in this course is a Next.js **Route Handler** — but if your only prior web development experience is with something like Express, or an older Next.js "Pages Router" project, some of the conventions in Phase 1 might feel unfamiliar even though the underlying JavaScript is completely ordinary. This primer bridges that gap in about five minutes.

## The Big Idea: Your Folder Structure *Is* Your API

In a framework like Express, you typically write code like this to define an endpoint:

```js
// Express-style — you manually wire up a path to a function
const express = require('express');
const app = express();

app.get('/api/agent/ping', (req, res) => {
  res.json({ message: 'pong' });
});
```

There's a router object, and you explicitly tell it "when a GET request comes in for this exact path string, run this function." Next.js's App Router takes a fundamentally different approach: **the URL of an endpoint is determined entirely by where you physically put the file on disk.**

```
app/
└── api/
    └── agent/
        └── ping/
            └── route.js     ← this file IS the endpoint at /api/agent/ping
```

There is no router configuration file anywhere to maintain. If you create a folder path `app/api/agent/ping/`, and inside it a file named exactly `route.js`, that file automatically becomes a live API endpoint at the URL `/api/agent/ping`. Move the folder, and you move the URL. Delete the file, and the endpoint disappears. This is why, throughout the entire course, every "Target" section starts by stating an exact file path — that file path *is* the specification of what URL you're about to be able to call.

## How a Single File Handles Multiple HTTP Methods

Inside a `route.js` file, you export functions named after the HTTP method they should respond to:

```js
// app/api/agent/example/route.js

export async function GET(request) {
  // Runs when someone sends a GET request to /api/agent/example
  return Response.json({ method: 'GET' });
}

export async function POST(request) {
  // Runs when someone sends a POST request to the SAME URL
  return Response.json({ method: 'POST' });
}
```

Both functions live in the same file, at the same URL, but only the function matching the actual incoming request's method ever runs. Throughout this course, you'll notice most of our endpoints only ever export a `POST` function — that's a deliberate choice, since most of our actions (sending a chat message, running a design review) involve sending data *to* the server, which is what `POST` conventionally represents, as opposed to `GET`, which conventionally represents simply *retrieving* something without side effects.

## `NextResponse.json()` — Sending Structured Data Back

You'll see this constructor in nearly every route handler in the course:

```js
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({ success: true, message: 'Hello!' });
}
```

This does two things at once: it serializes your JavaScript object into a JSON string, and it automatically sets the correct `Content-Type: application/json` response header — so whatever's calling your endpoint (a browser, `curl`, a frontend app) knows to interpret the response body as JSON without you having to configure that yourself. You can also pass a second argument to control the HTTP status code:

```js
return NextResponse.json({ success: false, error: 'Not found' }, { status: 404 });
```

## The Big Next.js 16 Change: Some Things Are Now `async`

This is the single most important App Router concept for this specific course, and it trips up even experienced developers coming from older Next.js versions. In Next.js 16, several APIs that give you access to request-specific data — `cookies()`, `headers()`, and a dynamic route's `params` — return **Promises**, not the data directly. You must `await` them:

```js
import { cookies } from 'next/headers';

export async function GET() {
  const cookieStore = await cookies();       // MUST await — this is a Promise
  const sessionId = cookieStore.get('agent_session_id');
  return NextResponse.json({ sessionId });
}
```

If you forget the `await` here, you won't necessarily get an obvious crash — you might just get confusing, incorrect behavior, since you'd be trying to call `.get()` on a pending Promise rather than the actual resolved cookie store. The simple habit to build, which the course reinforces repeatedly: **any time you see `cookies`, `headers`, or a dynamic route's `params`, reach for `await` reflexively.**

## Middleware: The One File That Runs Before Everything Else

One more structural concept worth knowing up front: a file called `middleware.js`, placed at your project's root (outside the `app/` folder entirely), runs *before* the router even decides which Route Handler to invoke for a given request. Think of it as a checkpoint every matching request must pass through first — used in this course to enforce API key authentication globally, so no individual endpoint can be written in a way that accidentally skips that check.

```js
// middleware.js (project root)
export function middleware(request) {
  // runs before ANY matching route handler
  return NextResponse.next(); // "proceed to the actual route handler"
}

export const config = {
  matcher: '/api/agent/:path*', // only runs for URLs matching this pattern
};
```

## A Quick Mental Checklist Before Phase 1

If the following four sentences all make sense to you, you're ready for the main course:

1. A file at `app/api/foo/bar/route.js` becomes a live endpoint at `/api/foo/bar`.
2. Exporting an `async function POST(request)` from that file makes it respond to `POST` requests.
3. `NextResponse.json({...}, { status: 200 })` is how you send structured data back with a specific HTTP status code.
4. `cookies()`, `headers()`, and dynamic route `params` all need `await` in front of them in Next.js 16.
