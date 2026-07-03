# Appendix F — Server Actions Deep Dive: Remote Function Calls, Mutations, and the Future of Web Applications

> **Goal of this appendix:** Understand Next.js Server Actions at a deep level while learning how modern web applications execute server-side mutations, why Server Actions represent a major architectural shift, and how they change the relationship between browsers, servers, APIs, and distributed systems.

---

# Introduction

One of the most confusing features in Next.js is:

```typescript id="4nmqod"
"use server";
```

Many developers see this and think:

> "This is just another API."

This is understandable.

Unfortunately, it is also wrong.

Server Actions are not simply APIs.

They represent a fundamental shift in how web applications are built.

---

# The Traditional Model

For nearly twenty years, web applications looked like this:

```text id="jgoj2q"
Browser
    │
    ▼

HTTP Request
    │
    ▼

REST API
    │
    ▼

Business Logic
    │
    ▼

Database
```

Example:

```typescript id="fvyz8h"
await fetch(
  "/api/comments",
  {
    method: "POST",
    body: JSON.stringify(
      data
    ),
  }
);
```

---

# The Problems

Traditional APIs require:

```text id="kqg7u1"
Route Creation

Validation

Serialization

Deserialization

Authentication

Error Handling

Response Parsing
```

Example:

```text id="jlwmfa"
Client
    │
    ▼

JSON.stringify()

    │
    ▼

HTTP

    │
    ▼

JSON.parse()

    │
    ▼

Business Logic
```

Lots of plumbing.

---

# The Next.js Idea

Suppose we could simply write:

```typescript id="jlwmfb"
await createComment(
  data
);
```

without:

```text id="jlwmfc"
fetch()

API routes

JSON

HTTP handlers
```

This is the fundamental idea behind Server Actions.

---

# Your First Server Action

Create:

```text id="jlwmfd"
actions/comments.ts
```

```typescript id="jlwmfe"
"use server";

export async function
createComment(
  formData:
    FormData
) {
  console.log(
    formData.get(
      "comment"
    )
  );
}
```

---

# Using The Action

```tsx id="jlwmff"
import {
  createComment,
} from "@/actions/comments";

export default function
CommentForm() {

  return (
    <form
      action={
        createComment
      }
    >

      <textarea
        name="comment"
      />

      <button>
        Submit
      </button>

    </form>
  );
}
```

---

# Wait...

Where Is:

```text id="jlwmfg"
fetch()?

axios?

API route?

JSON?
```

There isn't any.

---

# What Actually Happens?

When the user clicks:

```text id="jlwmfh"
Submit
```

Next.js performs:

```text id="jlwmfi"
Serialize Form
        │
        ▼

Create RPC Request
        │
        ▼

Send To Server
        │
        ▼

Execute Action
        │
        ▼

Return Result
```

---

# Server Actions Are RPC

RPC means:

```text id="jlwmfj"
Remote
Procedure
Call
```

The idea:

```text id="jlwmfk"
Call remote functions
like local functions.
```

Example:

```typescript id="jlwmfl"
await createComment();
```

appears local but executes:

```text id="jlwmfm"
On Another Computer.
```

---

# Haven't We Seen This Before?

Traditional:

```text id="jlwmfn"
REST
```

Modern:

```text id="jlwmfo"
RPC
```

Examples:

```text id="jlwmfp"
gRPC

GraphQL Mutations

Server Actions

tRPC
```

all attempt to solve:

```text id="jlwmfq"
Remote execution.
```

---

# Why Is RPC Difficult?

Suppose:

```typescript id="jlwmfr"
add(2,3)
```

Local execution:

```text id="jlwmfs"
Instant.
```

Remote execution:

```text id="jlwmft"
Serialize
    │
    ▼

Network
    │
    ▼

Deserialize
    │
    ▼

Execute
    │
    ▼

Return
```

The complexity becomes hidden.

---

# FormData

Server Actions receive:

```typescript id="jlwmfu"
FormData
```

Example:

```typescript id="jlwmfv"
export async function
createComment(
  data:
    FormData
) {

  const author =
    data.get(
      "author"
    );

  const comment =
    data.get(
      "comment"
    );
}
```

---

# Why FormData?

Because browsers have always understood:

```text id="jlwmfw"
HTML Forms
```

Since:

```text id="jlwmfx"
1995.
```

Next.js modernizes:

```text id="jlwmfy"
Old HTML forms
```

rather than replacing them.

---

# Validation

Install:

```bash id="jlwmfz"
npm install zod
```

Create:

```typescript id="jlwmga"
import { z } from "zod";

const schema = z.object({

  author:
    z.string(),

  comment:
    z.string()
      .min(10),
});
```

---

# Validate Input

```typescript id="jlwmgb"
"use server";

export async function
createComment(
  data:
    FormData
) {

  const parsed =
    schema.parse({

      author:
        data.get(
          "author"
        ),

      comment:
        data.get(
          "comment"
        ),
    });
}
```

---

# Wait...

Why Validate?

Remember:

```text id="jlwmgc"
Browser
      =
Untrusted
```

Attackers can submit:

```text id="jlwmgd"
Anything.
```

Examples:

```text id="jlwmge"
Empty strings

JavaScript

HTML

SQL

Garbage data
```

---

# Authentication

Server Actions execute on:

```text id="jlwmgf"
The Server
```

Therefore:

```typescript id="jlwmgg"
import {
  auth,
} from
"@clerk/nextjs/server";

export async function
createComment() {

  const {
    userId,
  } = await auth();

  if (!userId)
    throw Error();
}
```

---

# Database Mutations

Example:

```typescript id="jlwmgh"
await client.create({

  _type:
    "comment",

  author,

  content,

  approved:
    false,
});
```

---

# Revalidation

Suppose we create:

```text id="jlwmgi"
Comment #101
```

The page cache still contains:

```text id="jlwmgj"
100 comments.
```

Therefore:

```typescript id="jlwmgk"
import {
  revalidatePath,
} from
"next/cache";

revalidatePath(
  `/posts/${slug}`
);
```

---

# Mutation Flow

```text id="jlwmgl"
Browser
    │
    ▼

Server Action
    │
    ▼

Database
    │
    ▼

Revalidate
    │
    ▼

Refresh UI
```

---

# Returning Errors

Example:

```typescript id="jlwmgm"
return {
  success: false,

  error:
    "Invalid input",
};
```

Client:

```tsx id="jlwmgn"
if (!result.success) {
  setError(
    result.error
  );
}
```

---

# Returning Success

```typescript id="jlwmgo"
return {
  success: true,
};
```

---

# Redirecting

```typescript id="jlwmgp"
import {
  redirect,
} from
"next/navigation";

redirect(
  "/posts"
);
```

---

# Not Found

```typescript id="jlwmgq"
import {
  notFound,
} from
"next/navigation";

notFound();
```

---

# Throwing Errors

```typescript id="jlwmgr"
throw new Error(
  "Failed"
);
```

The nearest:

```text id="jlwmgs"
error.tsx
```

boundary catches it.

---

# File Uploads

Server Actions support:

```tsx id="jlwmgt"
<input
  type="file"
  name="image"
/>
```

Server:

```typescript id="jlwmgu"
const file =
  data.get(
    "image"
  ) as File;
```

---

# Optimistic UI

Suppose the database takes:

```text id="jlwmgv"
2 seconds.
```

Instead of:

```text id="jlwmgw"
Wait
```

we can:

```text id="jlwmgx"
Pretend Success
```

Example:

```typescript id="jlwmgy"
addOptimistic(
  comment
);
```

Then:

```text id="jlwmgz"
Server confirms
later.
```

---

# useActionState

```tsx id="jlwmh0"
const [
  state,
  action,
] =
useActionState(
  createComment,
  null
);
```

This provides:

```text id="jlwmh1"
Pending

Success

Error
```

state management automatically.

---

# useFormStatus

```tsx id="jlwmh2"
const {
  pending,
} =
useFormStatus();
```

Example:

```tsx id="jlwmh3"
<button
  disabled={
    pending
  }
>
  Submit
</button>
```

---

# Wait...

What Happened To APIs?

Interesting question.

For:

```text id="jlwmh4"
Browser Mutations
```

Server Actions often replace APIs.

For:

```text id="jlwmh5"
Mobile Apps

External Clients

Third Parties
```

we still need:

```text id="jlwmh6"
Route Handlers.
```

---

# Modern Architecture

Traditional:

```text id="jlwmh7"
Browser
    │
    ▼

REST API
    │
    ▼

Database
```

Next.js:

```text id="jlwmh8"
Browser
    │
    ▼

Server Action
    │
    ▼

Database
```

---

# The Hidden Reality

Even though we write:

```typescript id="’winih9"
await createComment();
```

Next.js secretly performs:

```text id="jlwmha"
Serialize Arguments
        │
        ▼

Create Endpoint
        │
        ▼

Send Request
        │
        ▼

Execute Action
        │
        ▼

Serialize Result
        │
        ▼

Return Response
```

Server Actions hide complexity.

They do not eliminate it.

---

# Wait...

Does This Look Familiar?

We've discovered:

```text id="jlwmhb"
State Trees

Failure Trees

Trust Trees

Cache Trees

Identity Trees

Complexity Trees
```

Server Actions introduce:

```text id="jlwmhc"
Execution Trees
```

because every function call eventually becomes:

```text id="jlwmhd"
A tree
of dependent
computations.
```

---

# The Deep Secret Of Server Actions

Most beginners think:

```text id="jlwmhe"
Server Actions
              =
Forms
```

Professional engineers think:

```text id="jlwmhf"
Server Actions
              =
Remote
              Function
              Execution
```

---

# The Deep Secret Of Modern Web Development

For decades we built:

```text id="jlwmhg"
User Interface

and

API
```

as separate systems.

Server Actions reunify:

```text id="jlwmhh"
User Interface

and

Business Logic
```

into:

```text id="jlwmhi"
One
execution
model.
```

---

# Mental Model To Remember Forever

Beginners think:

```text id="jlwmhj"
Function Calls
              =
Local Execution
```

Professional engineers think:

```text id="jlwmhk"
Function Calls
              =
Requests
              For
              Computation
```

Server Actions expose one of the deepest truths in computer science:

```text id="jlwmhl"
Most of software engineering
is ultimately about
moving computation
through space,
time,
and trust boundaries.
```
