# Next.js 16 for Absolute Beginners

# Part 37 — Authentication, Authorization, Sessions, and Security Architecture

> **Goal of this lesson:** Build a production-ready authentication and authorization system for Nexus CMS using Next.js 16, Server Actions, cookies, sessions, middleware, and role-based access control (RBAC).

---

# Security Is Not A Feature

Beginners think:

```text
Authentication
    =
Login page
```

Professional engineers think:

```text
Security
     |
     +---- Authentication
     |
     +---- Authorization
     |
     +---- Sessions
     |
     +---- Permissions
     |
     +---- Validation
     |
     +---- Auditing
```

Because logging in is easy.

Determining what someone is allowed to do is hard.

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ Login
✓ Logout
✓ Sessions
✓ Cookies
✓ Password hashing
✓ Authorization
✓ RBAC
✓ Middleware
✓ Protected layouts
✓ Permission checks
✓ Security architecture
```

---

# Authentication vs Authorization

Many beginners confuse these.

---

# Authentication

Authentication asks:

> Who are you?

Example:

```text
Username:
    sean

Password:
    ********
```

Result:

```text
You are Sean.
```

---

# Authorization

Authorization asks:

> What are you allowed to do?

Example:

```text
Sean

Can:
    ✓ Read
    ✓ Write
    ✗ Delete Users
```

---

# Visualizing Security

```text
User
   |
Authenticate
   |
Identity
   |
Authorize
   |
Permissions
```

---

# Step 1 — Create User Model

Open:

```text
prisma/schema.prisma
```

---

```prisma
model User {

  id String
     @id
     @default(uuid())

  email String
        @unique

  name String

  passwordHash String

  role Role
       @default(USER)

  createdAt DateTime
            @default(now())

}
```

---

# Create Roles

```prisma
enum Role {

  USER

  EDITOR

  ADMIN

}
```

---

# Why Roles?

Because not everyone should be able to do everything.

---

# Visualizing Roles

```text
ADMIN

   |
   +---- Everything

EDITOR

   |
   +---- Content

USER

   |
   +---- Reading
```

---

# Step 2 — Install Password Hashing

Install:

```bash
npm install bcryptjs
```

---

# Create Password Utilities

```text
lib/password.ts
```

---

```ts
import bcrypt
  from "bcryptjs";

export async function
hashPassword(
  password: string
) {

  return bcrypt.hash(
    password,
    12
  );

}

export async function
verifyPassword(

  password: string,

  hash: string,

) {

  return bcrypt.compare(

    password,

    hash

  );

}
```

---

# Why Hash Passwords?

Never store:

```text
hunter123
```

Store:

```text
$2b$12$A72...
```

---

# Visualizing Hashing

```text
Password
    |
Hash
    |
Database
```

---

# Step 3 — Create Register Action

```ts
"use server";

import {
  hashPassword
} from
  "@/lib/password";

export async function
register(

  formData:
    FormData

) {

  const email =

    formData.get(
      "email"
    );

  const password =

    formData.get(
      "password"
    );

  const passwordHash =

    await hashPassword(
      password
    );

  await db.user.create({

    data: {

      email,

      passwordHash,

      name: "",

    },

  });

}
```

---

# Registration Flow

```text
Form
   |
Validate
   |
Hash
   |
Database
```

---

# Step 4 — Create Login Action

```ts
"use server";

import {
  verifyPassword
} from
  "@/lib/password";

export async function
login(

  formData:
    FormData

) {

  const email =

    formData.get(
      "email"
    );

  const password =

    formData.get(
      "password"
    );

  const user =

    await db.user
      .findUnique({

      where: {

        email,

      },

    });

  if (!user)

    throw Error(
      "Invalid"
    );

  const valid =

    await verifyPassword(

      password,

      user.passwordHash

    );

  if (!valid)

    throw Error(
      "Invalid"
    );

}
```

---

# Visualizing Login

```text
Email
   |
Find User
   |
Check Password
   |
Success
```

---

# Step 5 — Create Session Token

After login:

```ts
const session =

  crypto.randomUUID();
```

---

Store:

```text
session
```

in database.

---

Example:

```prisma
model Session {

  id String
     @id

  userId String

  expiresAt DateTime

  user User
       @relation(
         fields:[userId],
         references:[id]
       )
}
```

---

# Why Sessions?

Because passwords should only be verified once.

---

# Visualizing Sessions

```text
Password
    |
Login
    |
Session
    |
Future Requests
```

---

# Step 6 — Set Cookie

```ts
import {
  cookies
} from
  "next/headers";

const store =
  await cookies();

store.set(

  "session",

  sessionId,

  {

    httpOnly:
      true,

    secure:
      true,

    sameSite:
      "lax",

  }

);
```

---

# Why Cookies?

Because browsers automatically send them.

---

# Visualizing Cookies

```text
Browser
   |
Cookie
   |
Server
```

---

# Step 7 — Get Current User

Create:

```text
lib/auth.ts
```

---

```ts
import {
  cookies
} from
  "next/headers";

export async function
getCurrentUser() {

  const store =
    await cookies();

  const session =

    store.get(
      "session"
    );

  if (!session)

    return null;

  return db.session
    .findUnique({

      where: {

        id:
          session.value,

      },

      include: {

        user: true,

      },

    });

}
```

---

# Authentication Flow

```text
Request
    |
Cookie
    |
Session
    |
User
```

---

# Step 8 — Protect Layouts

```tsx
import {
  redirect
} from
  "next/navigation";

export default async function
DashboardLayout({

  children,

}) {

  const session =

    await getCurrentUser();

  if (!session)

    redirect(
      "/login"
    );

  return children;

}
```

---

# Why Protect Layouts?

Bad:

```text
Protect
every page.
```

Good:

```text
Protect
once.
```

---

# Visualizing Layout Security

```text
Dashboard Layout
        |
Auth Check
        |
Pages
```

---

# Step 9 — Create RBAC

Create:

```text
lib/rbac.ts
```

---

```ts
export function
canEdit(
  role: string
) {

  return [

    "EDITOR",

    "ADMIN",

  ].includes(
    role
  );

}
```

---

# Example

```ts
if (

  !canEdit(
    user.role
  )

)

  throw Error(
    "Forbidden"
  );
```

---

# Visualizing Permissions

```text
ADMIN
    |
    +---- everything

EDITOR
    |
    +---- content

USER
    |
    +---- read
```

---

# Step 10 — Create Middleware

Create:

```text
middleware.ts
```

---

```ts
import {

  NextResponse,

} from
  "next/server";

export function
middleware(
  request
) {

  const session =

    request.cookies
      .get(
        "session"
      );

  if (

    !session &&

    request.nextUrl
      .pathname
      .startsWith(
        "/dashboard"
      )

  ) {

    return NextResponse
      .redirect(

        new URL(

          "/login",

          request.url

        )

      );

  }

}
```

---

# Middleware Runs Before Everything

```text
Request
   |
Middleware
   |
Route
```

---

# Step 11 — Logout

```ts
"use server";

import {
  cookies
} from
  "next/headers";

export async function
logout() {

  const store =
    await cookies();

  store.delete(
    "session"
  );

}
```

---

# Visualizing Logout

```text
Cookie
   |
Delete
   |
Anonymous
```

---

# Step 12 — CSRF Protection

CSRF means:

```text
Bad website
      |
Fake request
      |
Your application
```

---

Example attack:

```html
<form
 action=
 "bank.com/send">

<input
 value=
 "1000000">
```

---

# Protection

Use:

```text
SameSite=Lax
```

or:

```text
CSRF token
```

---

# Step 13 — Security Headers

Add:

```ts
headers: {

  "X-Frame-Options":
    "DENY",

  "X-Content-Type-Options":
    "nosniff",

}
```

---

# Why?

To prevent:

```text
Clickjacking

MIME attacks

Injection
```

---

# Step 14 — Audit Logging

Create:

```prisma
model AuditLog {

  id String
     @id
     @default(uuid())

  action String

  userId String

  createdAt DateTime
            @default(now())

}
```

---

# Example

```text
Sean

Published post

2026-06-28
```

---

# Why Audit?

Because eventually you'll ask:

```text
Who deleted production?
```

---

# Step 15 — Full Security Architecture

```text
                    Browser
                        |
                     Cookie
                        |
                        V
                    Middleware
                        |
                        V
                    Session
                        |
                        V
                 Authentication
                        |
                        V
                  Authorization
                        |
                        V
                    Permission
                        |
                        V
                     Database
```

---

# Security Philosophy

Beginners build:

```text
Login pages.
```

Professionals build:

```text
Trust systems.
```

Because security isn't:

```text
Can the user log in?
```

It's:

```text
Can the system trust
the user?
```

---

# What We've Built

```text
✓ Password hashing

✓ Registration

✓ Login

✓ Logout

✓ Sessions

✓ Cookies

✓ Middleware

✓ RBAC

✓ Authorization

✓ Permission checks

✓ Security headers

✓ Audit logs
```

---

# Exercises

## Exercise 1

Implement:

```text
Permission matrix.
```

Example:

```text
read_post

edit_post

publish_post

delete_post
```

---

## Exercise 2

Add:

```text
Session expiration.
```

---

## Exercise 3

Implement:

```text
Refresh sessions.
```

---

## Exercise 4

Add:

```text
Two-factor authentication.
```

---

# Mental Model

Beginners think:

```text
Security
   =
Login form
```

Professional engineers think:

```text
Security
   =
Identity
   +
Trust
   +
Authorization
   +
Auditing
```

Because authentication gets users into the system.

Authorization keeps the system safe.

---

# Part 38 Preview

In the next chapter we'll build:

# File Uploads, Storage, Images, and Asset Pipelines

Including:

```text
✓ File uploads
✓ Server Actions uploads
✓ Blob storage
✓ S3
✓ Image optimization
✓ Upload validation
✓ Media pipelines
✓ Asset management
✓ Metadata extraction
✓ CDN architecture
```

This is where Next.js becomes a distributed asset platform.
