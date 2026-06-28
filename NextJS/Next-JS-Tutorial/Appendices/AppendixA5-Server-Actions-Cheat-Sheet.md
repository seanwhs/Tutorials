# Appendix A5 — Next.js 16 Server Actions Cheat Sheet

## The Complete Guide to `"use server"` and Server-Side Mutations

> **Purpose:** This appendix is the definitive reference for Server Actions in Next.js 16. Server Actions fundamentally change how modern web applications perform mutations, handle forms, and coordinate client-server interactions.

---

# Introduction

Before Server Actions, web applications looked like this:

```text
Browser
    |
HTTP Request
    |
API Route
    |
Business Logic
    |
Database
```

With Server Actions:

```text
Browser
    |
Server Action
    |
Business Logic
    |
Database
```

The API layer often disappears.

---

# The Big Mental Shift

Traditional thinking:

```text
Frontend
      |
REST API
      |
Backend
```

Next.js 16 thinking:

```text
Client Component
        |
Server Action
        |
Database
```

---

# What Is A Server Action?

A Server Action is:

> A function that executes on the server but can be invoked directly from React components.

---

# Simplest Example

```ts
"use server";

export async function sayHello() {
  console.log("hello");
}
```

---

# Visualizing

```text
Browser
    |
Call function
    |
Server
    |
Execute
    |
Return
```

---

# Why Server Actions Exist

Without Server Actions:

```text
Form
   |
fetch()
   |
API Route
   |
Validation
   |
Database
```

With Server Actions:

```text
Form
   |
Server Action
   |
Validation
   |
Database
```

---

# Anatomy Of A Server Action

```ts
"use server";

export async function createPost() {

}
```

Requirements:

```text
✓ Server only

✓ Async

✓ Serializable arguments

✓ Serializable return values
```

---

# Example

```ts
"use server";

export async function createUser(
  name: string
) {

  await db.user.create({
    data: {
      name,
    },
  });

}
```

---

# Calling Server Actions From Forms

## The Simplest Pattern

Server:

```ts
"use server";

export async function createPost(
  formData: FormData
) {

  const title =
    formData.get("title");

  await db.post.create({
    data: {
      title,
    },
  });

}
```

---

Client:

```tsx
import {
  createPost,
} from "./actions";

export default function Page() {

  return (
    <form action={createPost}>
      <input
        name="title"
      />

      <button>
        Save
      </button>
    </form>
  );

}
```

---

# Visualizing

```text
Submit
    |
Server Action
    |
Validation
    |
Database
    |
Response
```

---

# Using Server Actions In Client Components

Example:

```tsx
"use client";

import {
  createPost,
} from "./actions";

export default function Button() {

  async function submit() {

    await createPost();

  }

  return (
    <button
      onClick={submit}
    >
      Save
    </button>
  );

}
```

---

# Visualizing

```text
Button Click
      |
Server Action
      |
Server
      |
Return
```

---

# Server Actions And Forms

This is the preferred pattern.

---

Server:

```ts
"use server";

export async function login(
  formData: FormData
) {

  const email =
    formData.get("email");

  const password =
    formData.get(
      "password"
    );

}
```

---

Client:

```tsx
<form action={login}>

  <input
    name="email"
  />

  <input
    name="password"
  />

  <button>
    Login
  </button>

</form>
```

---

# Why Forms?

Because forms provide:

```text
Accessibility

Progressive enhancement

Browser compatibility

Streaming support
```

---

# Accessing Form Data

```ts
export async function save(
  formData: FormData
) {

  const title =
    formData.get("title");

  const body =
    formData.get("body");

}
```

---

# Converting Values

Example:

```ts
const id =
  Number(
    formData.get("id")
  );
```

---

Boolean:

```ts
const active =
  formData.get(
    "active"
  ) === "on";
```

---

Arrays:

```ts
const tags =
  formData.getAll(
    "tags"
  );
```

---

# Validation

Never trust:

```text
Browser input.
```

---

Bad:

```ts
await db.user.create({
  data: {
    email:
      formData.get(
        "email"
      ),
  },
});
```

---

Good:

```ts
const email =
  String(
    formData.get(
      "email"
    )
  );

if (!email) {
  throw new Error(
    "Invalid"
  );
}
```

---

# Zod Validation

Example:

```ts
import { z }
  from "zod";

const schema = z.object({

  title:
    z.string(),

  body:
    z.string(),

});
```

---

```ts
const validated =
  schema.parse({

    title:
      formData.get(
        "title"
      ),

    body:
      formData.get(
        "body"
      ),

  });
```

---

# Database Example

```ts
"use server";

export async function
createPost(
  formData: FormData
) {

  const title =
    String(
      formData.get(
        "title"
      )
    );

  await db.post.create({
    data: {
      title,
    },
  });

}
```

---

# Redirecting

Example:

```ts
import {
  redirect,
} from
"next/navigation";

export async function
save() {

  redirect(
    "/dashboard"
  );

}
```

---

# Visualizing

```text
Save
   |
Redirect
   |
New page
```

---

# Revalidating Cache

Example:

```ts
"use server";

import {
  updateTag,
} from
"next/cache";

export async function
createPost() {

  await db.post
    .create();

  updateTag(
    "posts"
  );

}
```

---

# Visualizing

```text
Create
   |
Database
   |
updateTag
   |
Fresh UI
```

---

# Deleting Data

Example:

```ts
"use server";

export async function
deletePost(
  id: number
) {

  await db.post
    .delete({
      where: {
        id,
      },
    });

}
```

---

# Updating Data

```ts
"use server";

export async function
updatePost(
  id: number,
  title: string
) {

  await db.post
    .update({

      where: {
        id,
      },

      data: {
        title,
      },

    });

}
```

---

# File Uploads

Example:

```ts
"use server";

export async function
upload(
  formData: FormData
) {

  const file =
    formData.get(
      "file"
    );

}
```

---

HTML:

```tsx
<form action={upload}>

  <input
    type="file"
    name="file"
  />

</form>
```

---

# Error Handling

Example:

```ts
"use server";

export async function
save() {

  try {

    await db.save();

  } catch {

    throw new Error(
      "Failed"
    );

  }

}
```

---

# Returning Errors

```ts
"use server";

export async function
save() {

  return {

    success: false,

    message:
      "Failed",

  };

}
```

---

# Success Responses

```ts
return {

  success: true,

  id: 123,

};
```

---

# Authentication

Example:

```ts
"use server";

export async function
deletePost() {

  const user =
    await auth();

  if (!user) {

    throw new Error(
      "Unauthorized"
    );

  }

}
```

---

# Authorization

Example:

```ts
if (
  user.role !==
  "admin"
) {

  throw new Error(
    "Forbidden"
  );

}
```

---

# Transactions

Example:

```ts
await db.$transaction(

  async tx => {

    await tx.order
      .create();

    await tx.payment
      .create();

  }

);
```

---

# Optimistic Updates

Client:

```tsx
"use client";

const [posts, setPosts] =
  useState([]);

async function submit() {

  setPosts([
    ...posts,
    optimisticPost,
  ]);

  await createPost();

}
```

---

# Server Action Architecture

```text
Client
   |
Server Action
   |
Validation
   |
Authorization
   |
Business Logic
   |
Database
   |
Cache Update
```

---

# CRUD Pattern

```text
Create
     |
Validate
     |
Authorize
     |
Persist
     |
Update Cache
     |
Redirect
```

---

# Example Folder Structure

```text
actions/

    auth.ts

    posts.ts

    users.ts

    orders.ts
```

---

# Alternative Structure

```text
app/

    actions/

        auth.ts

        posts.ts
```

---

# Large Application Structure

```text
modules/

    posts/

        actions.ts

        queries.ts

        types.ts

        validators.ts
```

---

# Common Mistakes

---

## Mistake 1

```ts
"use server";

window.location;
```

---

## Mistake 2

```ts
"use server";

localStorage;
```

---

## Mistake 3

```ts
"use server";

document.querySelector();
```

---

## Mistake 4

Not validating input.

---

## Mistake 5

Not authorizing users.

---

## Mistake 6

Not updating cache.

---

## Mistake 7

Putting business logic inside components.

---

# Server Actions vs API Routes

| Feature           | Server Actions | API Routes |
| ----------------- | -------------- | ---------- |
| Forms             | ✓              | ✓          |
| React integration | ✓              | ✗          |
| External clients  | ✗              | ✓          |
| Mobile apps       | ✗              | ✓          |
| Browser fetch     | Optional       | Required   |
| Serialization     | Automatic      | Manual     |

---

# When To Use Server Actions

Use for:

```text
Forms

CRUD

Admin panels

Dashboards

Internal tools

CMS

Mutations
```

---

# When To Use API Routes

Use for:

```text
Public APIs

Webhooks

Mobile apps

Third-party clients

External integrations
```

---

# The Complete Execution Pipeline

```text
Browser
     |
React
     |
Server Action
     |
Validation
     |
Authorization
     |
Business Logic
     |
Database
     |
Cache Update
     |
Response
     |
UI Refresh
```

---

# Decision Tree

Need:

```text
User submits form?
```

Use:

```text
Server Action
```

---

Need:

```text
Public API?
```

Use:

```text
API Route
```

---

Need:

```text
Webhook endpoint?
```

Use:

```text
API Route
```

---

Need:

```text
Database mutation?
```

Use:

```text
Server Action
```

---

Need:

```text
External application access?
```

Use:

```text
API Route
```

---

# Mental Model

Beginners think:

```text
Server Actions
=
Better API routes.
```

Professional engineers think:

```text
Server Actions
=
RPC
built directly
into React.
```

Because Server Actions do not eliminate the backend.

They eliminate the need to manually build a large portion of your application's HTTP layer.
