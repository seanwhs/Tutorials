# GreyMatter Journal

# Part 9 — Connecting Next.js 16 to Sanity: Understanding APIs, Environment Variables, and the Sanity Client

> **Goal of this lesson:** Connect our Next.js application to Sanity and understand what APIs, environment variables, clients, and external services actually are.

---

# We Have Built Two Separate Systems

At this point, our architecture looks like this:

```text id="zj9nrf"
Next.js Application

        and

Sanity Studio
```

We have:

```text id="e8gkhi"
✓ Website
✓ CMS
✓ Content Model
```

But we still have a problem.

Our website cannot see our content.

---

# Why Can't Next.js See Sanity?

Many beginners imagine:

```text id="cajqxp"
Next.js
     ↓
reads
     ↓
studio/
```

But this isn't how Sanity works.

Remember:

```text id="d3agis"
Sanity Studio
        ↓
Editor Application
```

The actual content lives elsewhere.

Diagram:

```text id="m53ep6"
Editor
    │
    ▼
Sanity Studio
    │
    ▼
Content Lake
```

Meanwhile:

```text id="m8drpz"
Browser
    │
    ▼
Next.js
```

These systems don't know about each other yet.

---

# The Missing Piece: APIs

To communicate, applications use:

# APIs

(API = Application Programming Interface)

---

# Think About Restaurants

Imagine eating at a restaurant.

You do not walk into the kitchen and cook.

Instead:

```text id="xztwsd"
Customer
    ↓
Waiter
    ↓
Kitchen
    ↓
Food
```

The waiter is the interface.

Similarly:

```text id="yz44zl"
Next.js
    ↓
API
    ↓
Sanity
    ↓
Content
```

The API is the waiter.

---

# What Is An API Really?

Most tutorials define APIs like this:

> "An API allows applications to communicate."

While technically true, this isn't very helpful.

A better definition:

> An API is a contract that describes how one system requests services from another system.

Diagram:

```text id="ecjlwm"
Application A
       │
       ▼
Request

{
  "give me posts"
}

       │
       ▼

Application B

       │
       ▼

Response

{
  "posts": [...]
}
```

---

# Our Future Architecture

Soon our application will work like this:

```text id="3sh5zo"
Browser
    │
    ▼
Next.js
    │
    ▼
Sanity API
    │
    ▼
Content Lake
```

This is the architecture of many modern applications.

---

# Installing The Sanity Client

Return to the root project folder:

```bash id="vyxy7j"
cd greymatter-journal
```

Install the official integration package:

```bash id="qoqjxw"
npm install next-sanity
```

---

# What Is `next-sanity`?

Many beginners think:

```text id="8xdufe"
next-sanity
       ↓
contains
       ↓
Sanity
```

Not exactly.

Instead:

```text id="rm4o0o"
next-sanity
       ↓
helps
       ↓
Next.js communicate with Sanity
```

Think of it as:

```text id="y0yvfo"
Translator
```

Diagram:

```text id="qjlwm8"
Next.js
    │
    ▼
next-sanity
    │
    ▼
Sanity API
```

---

# The Problem With Hardcoding Information

Suppose we wrote:

```typescript id="t6tkgs"
const projectId = "abc123xyz";
```

This works.

Until:

* another developer joins,
* production uses another project,
* credentials change,
* datasets change.

Hardcoding configuration is dangerous.

---

# Enter Environment Variables

Create:

```text id="c38zn0"
.env.local
```

in the project root.

Add:

```bash id="2g0fqs"
NEXT_PUBLIC_SANITY_PROJECT_ID="your-project-id"

NEXT_PUBLIC_SANITY_DATASET="production"

NEXT_PUBLIC_SANITY_API_VERSION="2026-07-03"
```

---

# Where Do We Find The Project ID?

Open Sanity Manage:

```text id="fob3jk"
https://manage.sanity.io
```

Navigate to:

```text id="x7vw5h"
Project
      ↓
API
```

You'll find:

```text id="gm5mqa"
Project ID
Dataset
```

Example:

```bash id="1o17im"
NEXT_PUBLIC_SANITY_PROJECT_ID="k8wxyz12"

NEXT_PUBLIC_SANITY_DATASET="production"
```

---

# What Is An Environment Variable?

Think of environment variables as:

```text id="udsvyo"
Configuration
      kept
outside code
```

Instead of:

```typescript id="w7a0i7"
const database =
  "production-server";
```

we write:

```typescript id="zqqg5g"
const database =
  process.env.DATABASE_URL;
```

Benefits:

```text id="dpp0a1"
✓ Security
✓ Flexibility
✓ Deployment
✓ Team Collaboration
```

---

# Why Does It Start With `NEXT_PUBLIC`?

This confuses every beginner.

Consider:

```bash id="1jzyne"
DATABASE_PASSWORD
```

Should browsers see this?

Absolutely not.

But:

```bash id="o7uc7l"
NEXT_PUBLIC_SANITY_PROJECT_ID
```

is safe to expose.

Next.js uses this rule:

```text id="6hzgpu"
NEXT_PUBLIC_*
        ↓
visible in browser

everything else
        ↓
server only
```

Diagram:

```text id="4xsgyb"
Environment Variable

          │
          ▼

Starts with NEXT_PUBLIC?

      YES         NO
       │           │
       ▼           ▼

 Browser      Server Only
```

---

# Creating Our Library Folder

Create:

```text id="jlwmq2"
src/
```

Wait.

Didn't we say:

```text id="a4f20v"
Don't use src/
```

Yes.

But many teams create a small internal library folder.

Instead, let's use:

```text id="nkm9hh"
lib/
```

Create:

```text id="jyjlwm"
lib/

sanity.ts
```

---

# What Is A Client?

This is one of the most important concepts in software.

Suppose you're using a bank.

You don't communicate with the bank's database.

Instead:

```text id="ecat37"
You
 ↓
Bank App
 ↓
Bank Server
```

The bank app is a client.

Similarly:

```text id="8zft54"
Next.js
    ↓
Sanity Client
    ↓
Sanity API
```

---

# Creating The Sanity Client

Create:

```text id="dah9lx"
lib/sanity.ts
```

Add:

```typescript id="upv5mk"
import { createClient } from "next-sanity";

export const client = createClient({
  projectId:
    process.env
      .NEXT_PUBLIC_SANITY_PROJECT_ID,

  dataset:
    process.env
      .NEXT_PUBLIC_SANITY_DATASET,

  apiVersion:
    process.env
      .NEXT_PUBLIC_SANITY_API_VERSION,

  useCdn: false,
});
```

---

# Let's Read This In English

This:

```typescript id="vpd0d0"
createClient({
  ...
})
```

means:

> Create an object capable of talking to Sanity.

Diagram:

```text id="lh9nyd"
Client

├── Project
├── Dataset
├── API Version
└── Communication Logic
```

---

# What Does `useCdn` Mean?

Sanity offers two ways to fetch data.

### Direct Database

```text id="k9ejwo"
Next.js
    ↓
Content Lake
```

Always fresh.

---

### CDN Cache

```text id="1rlq76"
Next.js
    ↓
CDN
    ↓
Content Lake
```

Faster.

Possibly slightly stale.

---

For development:

```typescript id="55v5wl"
useCdn: false
```

For production:

```typescript id="uc9nme"
useCdn: true
```

is often preferred.

---

# Testing The Connection

Create:

```text id="djlwm8"
app/test/page.tsx
```

Add:

```typescript id="ogup2a"
import { client } from "@/lib/sanity";

export default async function TestPage() {
  const result =
    await client.fetch(
      `*[_type == "post"]`
    );

  return (
    <pre>
      {JSON.stringify(
        result,
        null,
        2
      )}
    </pre>
  );
}
```

---

# Wait... Why Is The Component `async`?

This is one of the biggest innovations in Next.js.

Traditional React:

```text id="g2fdj0"
Render
    ↓
Fetch
    ↓
Re-render
```

Next.js Server Components:

```text id="q3mg5j"
Fetch
    ↓
Render
    ↓
Send HTML
```

Diagram:

```text id="qarf80"
Server Component

      │
      ▼

await data

      │
      ▼

render page
```

We'll explore this deeply later.

---

# Our First GROQ Query

We already saw:

```groq id="hmxpt5"
*[_type == "post"]
```

Let's decode it.

---

### `*`

Means:

```text id="au7g4z"
everything
```

---

### `_type == "post"`

Means:

```text id="s87z3g"
only documents
whose type is post
```

Diagram:

```text id="uqtlgb"
Content Lake

Post
Post
Post
Author
Category

       ↓

Post
Post
Post
```

---

# Why This Is Powerful

Suppose we need:

```text id="1qsp9r"
title
slug
author
```

We can ask for only those fields:

```groq id="llwhst"
*[_type == "post"]{
  title,
  slug,
  author
}
```

Unlike REST APIs:

```text id="6gv19q"
fetch everything
        ↓
throw away most data
```

GROQ allows:

```text id="rz91gi"
fetch exactly
what you need
```

---

# Our Architecture Is Now Complete

We now have:

```text id="b1a4w9"
Editor
    │
    ▼
Sanity Studio
    │
    ▼
Content Lake
    │
    ▼
GROQ
    │
    ▼
Sanity Client
    │
    ▼
Next.js Server Components
    │
    ▼
Browser
```

This is the architecture used by countless modern content platforms.

---

# Mental Model To Remember Forever

Many beginners think:

```text id="ceqbhz"
Database
      ↓
Website
```

Modern applications think:

```text id="fwwjlwm"
Content System
       ↓
API Contract
       ↓
Application
       ↓
User Interface
```

And the glue that connects these systems is:

```text id="kqcyvb"
The Client
```

The client is simply a translator between two independent systems.

---

# Up Next

In **Part 10**, we'll create our first real content:

* creating authors,
* creating categories,
* creating blog posts,
* understanding references,
* understanding rich text,
* and seeing our first Sanity content rendered inside Next.js 16.
