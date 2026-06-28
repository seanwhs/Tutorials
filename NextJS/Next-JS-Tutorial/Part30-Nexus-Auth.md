# Next.js 16 for Absolute Beginners

# Part 30 — Authentication and Authorization: Building Secure Systems in Next.js 16

> **Goal of this lesson:** Implement a complete authentication and authorization system for Nexus CMS, including password hashing, sessions, cookies, middleware, role-based access control, and security hardening.

---

# Authentication vs Authorization

Beginners often confuse these concepts.

---

## Authentication

Authentication answers:

> **Who are you?**

Example:

```text
Email:
john@example.com

Password:
********
```

Result:

```text
You are John.
```

---

## Authorization

Authorization answers:

> **What are you allowed to do?**

Example:

```text
John
   |
Permissions
   |
Create Posts
Edit Posts
Delete Posts
Manage Users
```

---

# Visualizing Authentication

```text
Browser
    |
Login
    |
Server
    |
Session
    |
User
```

---

# Visualizing Authorization

```text
User
   |
Role
   |
Permissions
   |
Allowed Actions
```

---

# Our Authentication Strategy

We'll use:

```text
Email/password
      +
bcrypt hashing
      +
Database sessions
      +
HTTP-only cookies
      +
Role-based access control
```

---

# Why Not JWT?

For beginners and most applications:

```text
Database sessions
      >
JWT complexity
```

---

# Why?

JWT introduces:

```text
Expiration
Revocation
Refresh tokens
Key rotation
Distributed invalidation
```

Database sessions provide:

```text
Simple
Secure
Revocable
Understandable
```

---

# Step 1 — Install Dependencies

```bash
npm install bcryptjs zod cookie
```

---

# Create Authentication Folder

```text
auth/

    session.ts
    password.ts
    permissions.ts
    user.ts
```

---

# Step 2 — Password Hashing

Create:

```text
auth/password.ts
```

---

```ts
import bcrypt from "bcryptjs";

const ROUNDS = 12;

export async function hashPassword(
  password: string
) {

  return bcrypt.hash(
    password,
    ROUNDS
  );

}

export async function verifyPassword(
  password: string,
  hash: string
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
password123
```

Store:

```text
$2a$12$fhA8j...
```

---

# Visualizing Password Storage

Bad:

```text
User
   |
Password
   |
Database
```

---

Good:

```text
User
   |
Hash
   |
Database
```

---

# Step 3 — Session Helpers

Create:

```text
auth/session.ts
```

---

```ts
import { cookies }
  from "next/headers";

export async function
setSessionCookie(
  token: string
) {

  const store =
    await cookies();

  store.set(

    "session",

    token,

    {
      httpOnly: true,

      secure:
        process.env
          .NODE_ENV ===
          "production",

      sameSite:
        "lax",

      path: "/",
    }

  );

}
```

---

# Remove Session

```ts
export async function
removeSessionCookie() {

  const store =
    await cookies();

  store.delete(
    "session"
  );

}
```

---

# Why HTTP-only?

Bad:

```js
document.cookie
```

can steal sessions.

---

Good:

```text
JavaScript
    |
Cannot access
```

---

# Step 4 — Create Registration Schema

Create:

```text
auth/schema.ts
```

---

```ts
import { z }
  from "zod";

export const registerSchema =

  z.object({

    email:
      z.email(),

    password:
      z.string()
       .min(8),

    name:
      z.string()
       .min(2),

  });
```

---

# Why Validation?

Never trust:

```text
Browser input.
```

---

# Example Attack

User submits:

```html
<script>
alert(1)
</script>
```

Validation prevents dangerous input.

---

# Step 5 — Registration Action

Create:

```text
actions/auth/register.ts
```

---

```ts
"use server";

import { db }
  from "@/db/client";

import {
  hashPassword
} from "@/auth/password";

import {
  registerSchema
} from "@/auth/schema";

export async function
registerAction(
  formData: FormData
) {

  const parsed =
    registerSchema.parse({

      email:
        formData.get(
          "email"
        ),

      password:
        formData.get(
          "password"
        ),

      name:
        formData.get(
          "name"
        ),
    });

  const existing =
    await db.user.findUnique({

      where: {
        email:
          parsed.email,
      },
    });

  if (existing) {

    throw new Error(
      "User exists"
    );

  }

  const password =
    await hashPassword(
      parsed.password
    );

  await db.user.create({

    data: {

      email:
        parsed.email,

      password,

      name:
        parsed.name,
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
Hash Password
   |
Store User
```

---

# Step 6 — Login Action

```text
actions/auth/login.ts
```

---

```ts
"use server";

import crypto
  from "crypto";

export async function
loginAction(
  email: string,
  password: string
) {

  const user =
    await db.user.findUnique({

      where: { email },

    });

  if (!user) {

    throw new Error(
      "Invalid login"
    );

  }

  const valid =
    await verifyPassword(
      password,
      user.password
    );

  if (!valid) {

    throw new Error(
      "Invalid login"
    );

  }

  const token =
    crypto.randomUUID();

  await db.session.create({

    data: {

      token,

      userId:
        user.id,

      expiresAt:
        new Date(
          Date.now() +
          1000 *
          60 *
          60 *
          24 *
          7
        ),

    },

  });

  await setSessionCookie(
    token
  );

}
```

---

# Login Flow

```text
Email
   |
Find User
   |
Verify Password
   |
Create Session
   |
Set Cookie
```

---

# Step 7 — Get Current User

Create:

```text
auth/user.ts
```

---

```ts
import {
  cookies
} from "next/headers";

export async function
getCurrentUser() {

  const store =
    await cookies();

  const token =
    store.get(
      "session"
    )?.value;

  if (!token)
    return null;

  const session =
    await db.session.findUnique({

      where: {
        token,
      },

      include: {
        user: true,
      },
    });

  if (!session)
    return null;

  return session.user;

}
```

---

# Visualizing Session Lookup

```text
Cookie
   |
Session
   |
User
```

---

# Step 8 — Logout

```ts
"use server";

export async function
logoutAction() {

  const store =
    await cookies();

  const token =
    store.get(
      "session"
    )?.value;

  if (token) {

    await db.session.delete({

      where: {
        token,
      },

    });

  }

  await removeSessionCookie();

}
```

---

# Why Delete Sessions?

Because logout means:

```text
Session
    |
Destroyed
```

Not:

```text
Hope user logs out.
```

---

# Step 9 — Middleware Protection

Create:

```text
middleware.ts
```

---

```ts
import {
  NextResponse
} from "next/server";

export function middleware(
  request: Request
) {

  return NextResponse.next();

}

export const config = {

  matcher: [

    "/dashboard/:path*",

    "/admin/:path*",

  ],

};
```

---

# Why Middleware?

Without middleware:

```text
User
   |
Protected page
   |
Unauthorized access
```

---

# With middleware:

```text
User
   |
Check auth
   |
Allow or deny
```

---

# Step 10 — Role-Based Authorization

Create:

```text
auth/permissions.ts
```

---

```ts
export const permissions = {

  USER: [

    "read",

  ],

  AUTHOR: [

    "read",
    "create_post",

  ],

  EDITOR: [

    "read",
    "edit_post",
    "publish_post",

  ],

  ADMIN: [

    "*",

  ],

};
```

---

# Permission Helper

```ts
export function
hasPermission(

  role: string,

  permission:
    string

) {

  const perms =

    permissions[
      role as keyof
      typeof permissions
    ];

  return (

    perms.includes("*")

    ||

    perms.includes(
      permission
    )

  );

}
```

---

# Example

```ts
if (

  !hasPermission(

    user.role,

    "publish_post"

  )

) {

  throw new Error(
    "Forbidden"
  );

}
```

---

# Visualizing Permissions

```text
Admin
   |
Everything

Editor
   |
Publishing

Author
   |
Writing

User
   |
Reading
```

---

# Step 11 — Route Protection

Example:

```ts
export default async function
Dashboard() {

  const user =
    await getCurrentUser();

  if (!user) {

    redirect(
      "/login"
    );

  }

  return (

    <div>

      Welcome

    </div>

  );

}
```

---

# Step 12 — Admin Protection

```ts
if (

  user.role !==
  "ADMIN"

) {

  notFound();

}
```

---

# Why not Return 403?

Because:

```text
403
```

reveals:

```text
Page exists.
```

---

# Better:

```text
404
```

reveals:

```text
Nothing.
```

---

# Step 13 — Session Expiration

Before returning user:

```ts
if (

  session.expiresAt <
  new Date()

) {

  return null;

}
```

---

# Step 14 — Refresh Sessions

```ts
await db.session.update({

  where: {
    id:
      session.id,
  },

  data: {

    expiresAt:
      new Date(
        Date.now()
        +
        604800000
      ),

  },

});
```

---

# Step 15 — Security Headers

Add:

```ts
headers() {

  return [

    {

      source:
        "/(.*)",

      headers: [

        {
          key:
            "X-Frame-Options",

          value:
            "DENY",
        },

        {
          key:
            "X-Content-Type-Options",

          value:
            "nosniff",
        },

      ],
    },
  ];

}
```

---

# Authentication Architecture

```text
Browser
    |
Cookie
    |
Session
    |
User
    |
Role
    |
Permissions
```

---

# Security Checklist

```text
✓ Password hashing

✓ HTTP-only cookies

✓ Validation

✓ Session expiration

✓ Session revocation

✓ Authorization

✓ Permission checks

✓ Protected routes
```

---

# What Happens During Login?

```text
Email
   |
Password
   |
Hash verification
   |
Session creation
   |
Cookie creation
   |
Authenticated user
```

---

# What Happens During Request?

```text
Request
   |
Cookie
   |
Session
   |
User
   |
Permissions
   |
Authorized
```

---

# Authentication Philosophy

Beginners ask:

```text
How do I log users in?
```

Professionals ask:

```text
How do I prevent
unauthorized access?
```

Because authentication is not about logging users in.

It's about preventing everyone else from getting in.

---

# Exercises

## Exercise 1

Implement:

```text
Forgot password
```

flow.

---

## Exercise 2

Implement:

```text
Email verification
```

flow.

---

## Exercise 3

Implement:

```text
Two-factor authentication.
```

---

## Exercise 4

Implement:

```text
Account lockout
after failed logins.
```

---

# What You've Learned

You now understand:

✅ password hashing

✅ sessions

✅ cookies

✅ login

✅ logout

✅ authorization

✅ middleware

✅ permissions

✅ roles

✅ session management

✅ security hardening

---

# Mental Model

Beginners think:

```text
Authentication
     =
Login page
```

Professional engineers think:

```text
Authentication
      +
Authorization
      +
Sessions
      +
Permissions
      +
Security
      =
Identity System
```

Because security is not a feature.

Security is a property of the entire system.

---

# Part 31 Preview

In the next chapter we'll build the entire application shell, including:

```text
✓ Root layout
✓ Nested layouts
✓ Public site
✓ Dashboard
✓ Admin area
✓ Navigation
✓ Sidebars
✓ Headers
✓ Streaming layouts
✓ Loading states
✓ Error boundaries
```

This is where Next.js architecture becomes user experience architecture.
