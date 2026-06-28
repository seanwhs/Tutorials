# Appendix A8 — Next.js 16 Route Handlers Cheat Sheet

## The Complete Guide to Building APIs, Webhooks, and Backend Services with the App Router

> **Purpose:** This appendix is the definitive reference for Route Handlers in Next.js 16. Route Handlers replace traditional API routes and serve as the HTTP boundary between your application and the outside world.

---

# Introduction

One of the biggest misunderstandings about Next.js 16 is:

```text
Server Actions
replace
APIs.
```

They do not.

Server Actions replace:

```text
Internal
frontend-to-backend
communication.
```

Route Handlers remain essential for:

```text
Public APIs

Webhooks

Mobile apps

Third-party integrations

File uploads

Authentication callbacks
```

---

# The Big Picture

Modern Next.js applications contain two execution paths:

```text
Browser
    |
    +----- Server Action
    |
    +----- Route Handler
```

---

# Server Actions

Used for:

```text
Your React app
      |
Mutations
```

---

# Route Handlers

Used for:

```text
External systems
       |
HTTP
       |
Your app
```

---

# Visualizing

```text
Internal traffic

React
   |
Server Action
   |
Database
```

---

```text
External traffic

Mobile App
        |
HTTP
        |
Route Handler
        |
Database
```

---

# Creating A Route Handler

File:

```text
app/api/users/route.ts
```

---

Example:

```ts
export async function GET() {

  return Response.json({
    message: "hello",
  });

}
```

---

URL:

```text
/api/users
```

---

# Visualizing

```text
Request
    |
route.ts
    |
Response
```

---

# Supported HTTP Methods

```text
GET

POST

PUT

PATCH

DELETE

HEAD

OPTIONS
```

---

# GET Example

```ts
export async function GET() {

  const users =
    await db.user
      .findMany();

  return Response
    .json(users);

}
```

---

# POST Example

```ts
export async function POST(
  request: Request
) {

  const body =
    await request.json();

  return Response.json(
    body
  );

}
```

---

# PUT Example

```ts
export async function PUT(
  request: Request
) {

}
```

---

# DELETE Example

```ts
export async function DELETE(
  request: Request
) {

}
```

---

# Visualizing

```text
HTTP
   |
Method
   |
Handler
   |
Response
```

---

# Reading JSON

Example:

```ts
export async function POST(
  request: Request
) {

  const body =
    await request.json();

}
```

---

Request:

```json
{
  "name": "John",
  "email": "john@test.com"
}
```

---

# Reading Form Data

```ts
export async function POST(
  request: Request
) {

  const form =
    await request.formData();

}
```

---

# Reading Text

```ts
const text =
  await request.text();
```

---

# Reading Headers

```ts
const token =
  request.headers.get(
    "authorization"
  );
```

---

# Reading Query Parameters

Example:

```text
/api/posts?page=2
```

---

Code:

```ts
export async function GET(
  request: Request
) {

  const url =
    new URL(
      request.url
    );

  const page =
    url.searchParams
      .get("page");

}
```

---

# Returning JSON

```ts
return Response
  .json({

    success: true,

  });
```

---

# Returning Text

```ts
return new Response(
  "hello"
);
```

---

# Returning HTML

```ts
return new Response(
  "<h1>Hello</h1>",

  {
    headers: {
      "content-type":
        "text/html",
    },
  }
);
```

---

# Setting Status Codes

Example:

```ts
return Response
  .json(

    {
      error:
        "Not found",
    },

    {
      status: 404,
    }

  );
```

---

# Common Status Codes

```text
200 OK

201 Created

400 Bad Request

401 Unauthorized

403 Forbidden

404 Not Found

500 Server Error
```

---

# Dynamic Route Handlers

Example:

```text
app/api/posts/[id]/route.ts
```

---

Code:

```ts
export async function GET(
  request: Request,

  {
    params,
  }: {
    params: {
      id: string;
    };
  }
) {

  return Response
    .json(params);

}
```

---

# Visualizing

```text
/api/posts/123
           |
           123
```

---

# Authentication

Example:

```ts
export async function GET() {

  const session =
    await auth();

  if (!session) {

    return Response
      .json(

        {
          error:
            "Unauthorized",
        },

        {
          status: 401,
        }

      );

  }

}
```

---

# Authorization

```ts
if (
  session.role !==
  "admin"
) {

  return Response
    .json(

      {
        error:
          "Forbidden",
      },

      {
        status: 403,
      }

    );

}
```

---

# Database Example

```ts
export async function GET() {

  const posts =
    await db.post
      .findMany();

  return Response
    .json(posts);

}
```

---

# CRUD Example

## Create

```ts
POST
```

---

## Read

```ts
GET
```

---

## Update

```ts
PUT
PATCH
```

---

## Delete

```ts
DELETE
```

---

# File Uploads

Example:

```ts
export async function POST(
  request: Request
) {

  const data =
    await request
      .formData();

  const file =
    data.get(
      "file"
    );

}
```

---

# Visualizing

```text
Browser
     |
Multipart
     |
Route Handler
     |
Storage
```

---

# Webhooks

One of the most important use cases.

---

Example:

```text
CMS
   |
Webhook
   |
Route Handler
   |
revalidateTag()
```

---

Code:

```ts
import {
  revalidateTag,
} from "next/cache";

export async function POST() {

  revalidateTag(
    "posts"
  );

  return Response
    .json({

      success: true,

    });

}
```

---

# Stripe Webhooks

Example:

```text
Stripe
    |
Webhook
    |
Route Handler
```

---

Code:

```ts
export async function POST(
  request: Request
) {

  const body =
    await request.text();

}
```

---

# GitHub Webhooks

Example:

```text
GitHub
    |
Webhook
    |
Route Handler
```

---

# Slack Webhooks

Example:

```text
Slack
   |
Webhook
   |
Route Handler
```

---

# API Keys

Example:

```ts
const key =
  request.headers.get(
    "x-api-key"
  );
```

---

Validation:

```ts
if (
  key !==
  process.env.API_KEY
) {

  return Response
    .json(

      {
        error:
          "Forbidden",
      },

      {
        status: 403,
      }

    );

}
```

---

# Cookies

Reading:

```ts
import {
  cookies,
} from
"next/headers";

const store =
  await cookies();
```

---

Writing:

```ts
store.set(

  "token",

  "abc"

);
```

---

# Redirects

Example:

```ts
return Response
  .redirect(
    "https://google.com"
  );
```

---

# Streaming Responses

Example:

```ts
const stream =
  new ReadableStream();
```

---

Visualizing:

```text
Server
   |
Chunk
   |
Chunk
   |
Chunk
```

---

# CORS

Example:

```ts
return Response
  .json(

    {},

    {
      headers: {

        "Access-Control-Allow-Origin":
          "*",

      },
    }

  );
```

---

# Error Handling

Example:

```ts
try {

  await db.save();

} catch {

  return Response
    .json(

      {
        error:
          "Failed",
      },

      {
        status: 500,
      }

    );

}
```

---

# Validation

Example:

```ts
import {
  z,
} from "zod";
```

---

Schema:

```ts
const schema =
  z.object({

    name:
      z.string(),

  });
```

---

Parse:

```ts
const body =
  await request
    .json();

const data =
  schema.parse(
    body
  );
```

---

# Route Handlers vs Server Actions

| Feature           | Route Handler | Server Action |
| ----------------- | ------------- | ------------- |
| HTTP              | ✓             | Hidden        |
| Forms             | ✓             | ✓             |
| Mobile apps       | ✓             | ✗             |
| External APIs     | ✓             | ✗             |
| React integration | ✗             | ✓             |
| Webhooks          | ✓             | ✗             |
| CRUD              | ✓             | ✓             |

---

# Route Handlers vs Server Components

| Feature          | Route Handler | Server Component |
| ---------------- | ------------- | ---------------- |
| HTTP endpoint    | ✓             | ✗                |
| HTML rendering   | ✗             | ✓                |
| API access       | ✓             | ✗                |
| External clients | ✓             | ✗                |

---

# Folder Structure

```text
app/

  api/

    auth/

      route.ts

    posts/

      route.ts

    webhooks/

      route.ts

    uploads/

      route.ts
```

---

# Enterprise Structure

```text
app/

  api/

    auth/

    billing/

    cms/

    github/

    stripe/

    uploads/

    webhooks/
```

---

# Execution Pipeline

```text
Request
    |
Middleware
    |
Route Handler
    |
Validation
    |
Authentication
    |
Authorization
    |
Business Logic
    |
Database
    |
Response
```

---

# Common Mistakes

---

## Mistake 1

Creating APIs for:

```text
Your own frontend.
```

Use:

```text
Server Actions.
```

---

## Mistake 2

Skipping validation.

---

## Mistake 3

Skipping authorization.

---

## Mistake 4

Returning internal errors.

---

## Mistake 5

Not verifying webhook signatures.

---

## Mistake 6

Performing heavy processing synchronously.

---

# Decision Tree

Need:

```text
Public API?
```

Use:

```text
Route Handler
```

---

Need:

```text
Webhook?
```

Use:

```text
Route Handler
```

---

Need:

```text
Mobile app backend?
```

Use:

```text
Route Handler
```

---

Need:

```text
React form submission?
```

Use:

```text
Server Action
```

---

Need:

```text
External service integration?
```

Use:

```text
Route Handler
```

---

# The Complete Architecture

```text
                    Browser
                        |
                        |
                Server Actions
                        |
                        |
Database <--------------+
                        |
                        |
                Route Handlers
                        |
        +---------------+---------------+
        |               |               |
     Stripe         GitHub         Mobile App
```

---

# Mental Model

Beginners think:

```text
Route Handlers
=
API routes.
```

Professional engineers think:

```text
Route Handlers
=
The HTTP boundary
of the system.
```

Because Server Actions are for:

```text
Internal RPC.
```

And Route Handlers are for:

```text
External communication.
```

A mature Next.js application almost always contains both.
