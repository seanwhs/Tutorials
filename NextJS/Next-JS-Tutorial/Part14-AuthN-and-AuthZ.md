# Next.js 16 for Absolute Beginners

# Part 14 — Authentication and Authorization: Building Multi-User Applications

> **Goal of this lesson:** Learn how authentication and authorization work, understand sessions and cookies, protect pages and APIs, and build a complete login system in Next.js 16.

---

# Authentication vs Authorization

These two terms sound similar.

But they solve different problems.

---

# Authentication

Authentication answers:

> Who are you?

Examples:

```text
Username + Password
Google Login
GitHub Login
Passkeys
Magic Links
```

---

# Authorization

Authorization answers:

> What are you allowed to do?

Examples:

```text
Admin
Editor
User
Guest
```

---

# Visualizing the Difference

```text
Authentication
        |
        V

Who are you?

        |
        V

Authorization

What can you do?
```

---

# Example

Suppose John logs in.

Authentication:

```text
John
    ✓ Verified
```

Authorization:

```text
John
    ✓ Can read posts
    ✓ Can create comments
    ✗ Cannot delete users
```

---

# How Websites Remember Users

Suppose you log into a website.

How does it remember you?

The answer is:

# Cookies

---

# What Is a Cookie?

A cookie is simply:

```text
A small piece
of data stored
by the browser.
```

Example:

```text
session=abc123xyz
```

---

# Visualizing Cookies

```text
Browser
    |
Stores:
session=abc123
    |
Sends cookie
with every request
```

---

# Login Without Cookies

```text
Request
    |
Who are you?

Request
    |
Who are you?

Request
    |
Who are you?
```

Very annoying.

---

# Login With Cookies

```text
Login
    |
Cookie Created
    |
Browser Saves Cookie
    |
Future Requests
    |
User Recognized
```

---

# Building a Fake Login System

Create:

```text
lib/auth.ts
```

---

```tsx
export async function login(
    email: string,
    password: string,
) {

    if (
        email ===
            "admin@test.com" &&
        password ===
            "password"
    ) {

        return {
            id: 1,
            role: "admin",
        };

    }

    return null;
}
```

---

# Server Action Login

```tsx
"use server";

import { login }
    from "@/lib/auth";

export async function loginAction(
    formData: FormData
) {

    const email =
        String(
            formData.get(
                "email"
            )
        );

    const password =
        String(
            formData.get(
                "password"
            )
        );

    const user =
        await login(
            email,
            password
        );

    if (!user) {

        return {
            error:
                "Invalid credentials",
        };

    }

}
```

---

# But We Have a Problem

After login:

```text
User authenticated
```

Then:

```text
Next request
```

We forget everything.

We need:

```text
Persistence
```

---

# Using Cookies in Next.js

Import:

```tsx
import {
    cookies
} from "next/headers";
```

---

# Creating a Session Cookie

```tsx
"use server";

import {
    cookies
} from "next/headers";

export async function loginAction(
    formData: FormData
) {

    const cookieStore =
        await cookies();

    cookieStore.set(
        "session",
        "abc123"
    );

}
```

---

# Visualizing Session Creation

```text
Login
   |
Create Session
   |
Set Cookie
   |
Browser Stores Cookie
```

---

# Reading Cookies

```tsx
import {
    cookies
} from "next/headers";

export async function getSession() {

    const cookieStore =
        await cookies();

    return cookieStore.get(
        "session"
    );

}
```

---

# Visualizing Requests

```text
Browser
    |
session=abc123
    |
Request
    |
Server
    |
User Found
```

---

# Creating a Real Session

Create:

```text
lib/session.ts
```

---

```tsx
export async function createSession(
    userId: number
) {

    const sessionId =
        crypto.randomUUID();

    await database.session.create({

        data: {

            id:
                sessionId,

            userId,

        },

    });

    return sessionId;
}
```

---

# Database Session Table

```prisma
model Session {

    id String
        @id

    userId Int

    expiresAt DateTime

}
```

---

# Login Flow

```text
User Login
      |
Verify Password
      |
Create Session
      |
Store Session
      |
Set Cookie
      |
Redirect
```

---

# Logout

Logout simply means:

```text
Delete Session
Delete Cookie
```

---

# Example Logout

```tsx
"use server";

import {
    cookies
} from "next/headers";

export async function logout() {

    const cookieStore =
        await cookies();

    cookieStore.delete(
        "session"
    );

}
```

---

# Protecting Pages

Suppose:

```text
/dashboard
```

should require login.

---

```tsx
import {
    redirect
} from "next/navigation";

export default async function Dashboard() {

    const session =
        await getSession();

    if (!session) {

        redirect(
            "/login"
        );

    }

    return (
        <h1>
            Dashboard
        </h1>
    );
}
```

---

# Visualizing Route Protection

```text
Request
    |
Check Session
    |
    +--- Valid
    |       |
    |       V
    |    Dashboard
    |
    +--- Invalid
            |
            V
         Login
```

---

# Building an Auth Helper

Create:

```text
lib/auth.ts
```

---

```tsx
export async function requireUser() {

    const session =
        await getSession();

    if (!session) {

        redirect(
            "/login"
        );

    }

    return session;
}
```

---

Then:

```tsx
export default async function Page() {

    const user =
        await requireUser();

    return (
        <h1>
            Hello
        </h1>
    );
}
```

---

# Authorization

Suppose we have:

```text
Admin
Editor
User
```

roles.

---

# Database Model

```prisma
model User {

    id Int
        @id
        @default(autoincrement())

    email String
        @unique

    role String
        @default("user")

}
```

---

# Example Roles

```text
Admin
    |
    +--- Everything

Editor
    |
    +--- Publish Posts

User
    |
    +--- Read Posts
```

---

# Role Checking

```tsx
export async function requireAdmin() {

    const user =
        await requireUser();

    if (
        user.role !==
        "admin"
    ) {

        throw new Error(
            "Unauthorized"
        );

    }

    return user;
}
```

---

# Protecting Admin Pages

```tsx
export default async function AdminPage() {

    await requireAdmin();

    return (
        <div>
            Admin Panel
        </div>
    );
}
```

---

# Visualizing Authorization

```text
User
   |
Check Role
   |
   +--- Admin
   |       |
   |       V
   |    Access
   |
   +--- User
           |
           V
        Denied
```

---

# Middleware

Sometimes we want to protect many routes.

Create:

```text
middleware.ts
```

---

```tsx
import {
    NextResponse
} from "next/server";

import type {
    NextRequest
} from "next/server";

export function middleware(
    request: NextRequest
) {

    const session =
        request.cookies.get(
            "session"
        );

    if (
        !session &&
        request.nextUrl.pathname.startsWith(
            "/dashboard"
        )
    ) {

        return NextResponse.redirect(
            new URL(
                "/login",
                request.url
            )
        );

    }

    return NextResponse.next();
}
```

---

# Visualizing Middleware

```text
Request
    |
Middleware
    |
    +--- Allowed
    |
    +--- Blocked
```

---

# Password Storage

Never do this:

```text
password123
```

inside the database.

Instead:

```text
Hash(password)
```

---

# Example

Install:

```bash
npm install bcrypt
```

---

# Hashing Passwords

```tsx
import bcrypt
    from "bcrypt";

const hashed =
    await bcrypt.hash(
        password,
        10
    );
```

Store:

```text
$2b$10$....
```

not:

```text
mypassword
```

---

# Verifying Passwords

```tsx
const valid =
    await bcrypt.compare(
        password,
        hashedPassword
    );
```

---

# Visualizing Password Hashing

```text
Password
    |
Hash Function
    |
Encrypted Hash
    |
Database
```

---

# Session-Based Authentication vs JWT

There are two common approaches.

---

## Session Authentication

```text
Cookie
    |
Session ID
    |
Database
```

Advantages:

* secure
* easy logout
* server-controlled

---

## JWT Authentication

```text
Cookie
    |
JWT Token
    |
Self-contained
```

Advantages:

* stateless
* scalable
* API friendly

---

# Which Should Beginners Use?

For Next.js applications:

```text
Use Sessions
```

because:

* simpler
* safer
* easier to revoke
* works naturally with Server Actions

---

# Complete Login Flow

```text
Login Form
      |
Server Action
      |
Validate Password
      |
Create Session
      |
Store Session
      |
Set Cookie
      |
Redirect
      |
Protected Pages
```

---

# Folder Structure

```text
app/

    login/
    dashboard/

    actions/
        auth.ts

lib/

    auth.ts
    session.ts
    db.ts

middleware.ts
```

---

# Professional Rule

Never trust:

```text
Client State
```

Always trust:

```text
Server Session
```

---

# Exercises

## Exercise 1

Create:

```prisma
User
```

with:

```text
email
passwordHash
role
```

---

## Exercise 2

Build:

```text
loginAction()
```

that:

* validates password
* creates session
* sets cookie

---

## Exercise 3

Create:

```text
requireAdmin()
```

that protects:

```text
/admin
```

---

## Exercise 4

Add:

```text
middleware.ts
```

that protects:

```text
/dashboard
```

---

# What You've Learned

You now understand:

✅ authentication

✅ authorization

✅ sessions

✅ cookies

✅ password hashing

✅ protected routes

✅ middleware

✅ role-based access control

✅ multi-user applications

---

# Mental Model

Don't think:

```text
User logs in
```

Think:

```text
User
    |
Authenticate
    |
Create Session
    |
Authorize
    |
Access Resources
```

Authentication proves identity.

Authorization controls permissions.

Together, they form the security foundation of every serious web application.

---

# Part 15 Preview

In the next chapter we'll learn:

# File Uploads, Images, and Media

Including:

* file uploads
* multipart forms
* server-side file handling
* image optimization
* the `Image` component
* storage providers
* drag-and-drop uploads
* media pipelines
* building a complete image gallery system

This is where our applications begin handling real-world user content.
