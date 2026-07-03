# GreyMatter Journal

# Part 20 — Authentication, Sessions, Cookies, and the Architecture of Trust

> **Goal of this lesson:** Build authentication and a protected admin area for GreyMatter Journal while learning how identity, sessions, cookies, cryptography, and trust boundaries work in modern web applications.

---

# Our Blog Has Another Problem

Currently:

```text
https://greymatter.com
```

allows anyone to:

```text
Read Articles
```

which is good.

But suppose we want:

```text
Admin Dashboard
Draft Preview
Analytics
Editorial Tools
```

Question:

```text
How does the system know
who you are?
```

This turns out to be one of the deepest questions in software engineering.

---

# The Identity Problem

Suppose I visit:

```text
https://greymatter.com/admin
```

How does the server know:

```text
Sean
```

rather than:

```text
Alice
Bob
Anonymous User
```

The answer is:

```text
It doesn't.
```

---

# HTTP Has No Memory

Most beginners imagine:

```text
Browser
     │
     ▼
Server

Server remembers me.
```

Actually:

```text
Request #1

GET /

Request #2

GET /admin

Request #3

GET /posts
```

The server sees:

```text
Three unrelated requests.
```

Diagram:

```text
Browser

    │

Request A
Request B
Request C

    │

Server

"I don't know
who sent these."
```

---

# Authentication vs Authorization

These terms are frequently confused.

Authentication asks:

```text
Who are you?
```

Authorization asks:

```text
What can you do?
```

Example:

```text
Login
  ↓
Authentication

Admin Access
  ↓
Authorization
```

---

# Real World Example

Suppose you enter an airport.

Security checks:

```text
Passport
```

This is:

```text
Authentication
```

Then they determine:

```text
Passenger
Crew
Pilot
Security
```

This is:

```text
Authorization
```

---

# Choosing An Authentication Provider

Building authentication yourself is dangerous.

Instead, we'll use:

Clerk

because it provides:

```text
✓ Authentication
✓ Sessions
✓ Social Login
✓ Security
✓ User Management
✓ Middleware
```

---

# Step 1 — Install Clerk

Open your terminal:

```bash
npm install @clerk/nextjs
```

---

# Why Use A Library?

Beginners often think:

```text
Login Form
     ↓
Done
```

Reality:

```text
Passwords
Hashing
Sessions
Cookies
CSRF
OAuth
MFA
Rate Limits
Account Recovery
Email Verification
Bot Protection
```

Authentication systems are extraordinarily complex.

---

# Step 2 — Create A Clerk Account

Visit:

[Clerk Official Website](https://clerk.com?utm_source=chatgpt.com)

Create:

```text
GreyMatter Journal
```

application.

Enable:

```text
Email Authentication
Google Login (optional)
```

---

# Step 3 — Install Environment Variables

Create:

```text
.env.local
```

Add:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
CLERK_SECRET_KEY=sk_...
```

---

# Wait...

Why Two Keys?

Suppose we have:

```text
Browser
```

and:

```text
Server
```

They trust different things.

Diagram:

```text
Public Key
        │
        ▼
Browser


Secret Key
        │
        ▼
Server
```

Never expose:

```text
CLERK_SECRET_KEY
```

to browsers.

---

# Step 4 — Configure Middleware

Create:

```text
middleware.ts
```

Add:

```typescript
import {
  clerkMiddleware,
} from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: [
    "/((?!_next|.*\\..*).*)",
  ],
};
```

---

# Wait...

What Is Middleware?

Most beginners think:

```text
Browser
      ↓
Page
```

Actually:

```text
Browser
      ↓
Middleware
      ↓
Page
```

Diagram:

```text
Request

    │

    ▼

Middleware

    │

    ▼

Route
```

Middleware acts like airport security:

```text
Inspect

Allow

Block
```

---

# Step 5 — Wrap The Application

Open:

```text
app/layout.tsx
```

Import:

```typescript
import {
  ClerkProvider,
} from "@clerk/nextjs";
```

Update:

```tsx
export default function
RootLayout({
  children,
}: {
  children:
    React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>
          {children}
        </body>
      </html>
    </ClerkProvider>
  );
}
```

---

# What Is A Provider?

We've seen trees before:

```text
React Tree
```

Providers inject information into the tree.

Diagram:

```text
Provider

    │

    ├── Navbar
    │
    ├── Page
    │
    └── Footer
```

All descendants receive:

```text
Authentication Context
```

---

# Step 6 — Create Login Page

Create:

```text
app/

sign-in/

[[...sign-in]]/

page.tsx
```

Add:

```tsx
import {
  SignIn,
} from "@clerk/nextjs";

export default function
Page() {
  return <SignIn />;
}
```

---

# Wait...

That's It?

Yes.

This demonstrates a profound principle:

```text
Abstraction
```

What appears simple:

```tsx
<SignIn />
```

actually represents:

```text
Thousands of lines
of engineering.
```

---

# Step 7 — Add User Controls

Open:

```text
components/Navbar.tsx
```

Import:

```typescript
import {
  SignedIn,
  SignedOut,
  SignInButton,
  UserButton,
} from "@clerk/nextjs";
```

Add:

```tsx
<SignedOut>
  <SignInButton />
</SignedOut>

<SignedIn>
  <UserButton />
</SignedIn>
```

---

# What Happens Internally?

When users log in:

```text
Browser
     │
     ▼

Credentials
     │
     ▼

Authentication Server
     │
     ▼

Session Created
     │
     ▼

Cookie Issued
```

---

# Wait...

What Is A Session?

Suppose you enter a hotel.

The receptionist gives:

```text
Room Card #248
```

The card itself contains very little information.

Instead:

```text
Card Number
       │
       ▼
Hotel Database
       │
       ▼
Your Reservation
```

Sessions work similarly.

---

# What Is A Cookie?

A cookie is simply:

```text
Small data
stored by
the browser.
```

Example:

```http
Set-Cookie:
session=abc123
```

Later:

```http
Cookie:
session=abc123
```

Diagram:

```text
Server
   │
   ▼

Cookie

   │
   ▼

Browser

   │
   ▼

Future Requests
```

---

# Step 8 — Create Admin Route

Create:

```text
app/

admin/

page.tsx
```

Add:

```tsx
import {
  auth,
} from "@clerk/nextjs/server";

export default async function
AdminPage() {

  const { userId } =
    await auth();

  if (!userId) {
    return (
      <h1>
        Unauthorized
      </h1>
    );
  }

  return (
    <>
      <h1>
        Admin Dashboard
      </h1>

      <p>
        Welcome,
        editor.
      </p>
    </>
  );
}
```

---

# Wait...

What Is `auth()`?

Think:

```text
Request
      │
      ▼
Cookie
      │
      ▼
Session
      │
      ▼
User Identity
```

Diagram:

```text
Cookie

     │

     ▼

Session Lookup

     │

     ▼

Authenticated User
```

---

# But This Isn't Enough

Suppose:

```text
Alice
```

logs in.

Should Alice become:

```text
Administrator?
```

No.

We need:

```text
Authorization
```

---

# Step 9 — Add Roles

Suppose:

```text
User
Editor
Admin
```

Diagram:

```text
User

    │

    ├── Reader
    │
    ├── Editor
    │
    └── Admin
```

Then:

```typescript
if (
  user.role !==
  "admin"
) {
  return (
    <h1>
      Forbidden
    </h1>
  );
}
```

---

# Authentication Is About Trust

Every request asks:

```text
Can I trust
this user?
```

But modern systems ask:

```text
How much
can I trust
this user?
```

Examples:

```text
Anonymous

Authenticated

Verified

Admin
```

---

# Zero Trust Architecture

Old systems assumed:

```text
Inside Network
        =
Trusted
```

Modern systems assume:

```text
Trust Nobody
```

Diagram:

```text
Request

    │

    ▼

Verify

    │

    ▼

Authorize

    │

    ▼

Allow
```

Every request is verified.

---

# What About Passwords?

Professional systems never store:

```text
password123
```

Instead:

```text
password123
      │
      ▼
Hash Function
      │
      ▼
a8f4bc92...
```

Diagram:

```text
Password

    │

    ▼

Hash

    │

    ▼

Stored Value
```

---

# Wait...

What Is A Hash?

A hash function transforms:

```text
Input
```

into:

```text
Fixed Output
```

Example:

```text
hello
```

becomes:

```text
2cf24dba...
```

Properties:

```text
✓ Fast
✓ Deterministic
✓ One-way
✓ Collision-resistant
```

---

# The Hidden Architecture

When a user visits:

```text
/admin
```

the actual flow becomes:

```text
Browser
    │
    ▼

Cookie
    │
    ▼

Middleware
    │
    ▼

Session Validation
    │
    ▼

Authentication
    │
    ▼

Authorization
    │
    ▼

React
    │
    ▼

UI
```

---

# Wait...

Does This Look Familiar?

We've already seen:

```text
React Trees

Route Trees

Failure Trees

Reality Trees
```

Now we discover:

```text
Trust Trees
```

because systems continuously evaluate:

```text
Who can trust whom?
```

---

# The Deep Secret Of Security Engineering

Beginners think:

```text
Security
       =
Passwords
```

Professional engineers think:

```text
Security
       =
Trust Management
```

Questions include:

```text
Who are you?

How do I know?

What are you allowed to do?

How certain am I?

What happens if I'm wrong?
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Authentication
            =
Login
```

Professional engineers think:

```text
Authentication
            =
Identity Proof
```

And:

```text
Authorization
           =
Permission Proof
```

Or more generally:

```text
Security Engineering
                    =
Managing Trust
                    Under Uncertainty
```

This is why security is one of the deepest and most difficult disciplines in software engineering.

---

# Up Next

In **Part 21**, we'll implement comments, likes, and user-generated content while learning:

* mutations and state transitions,
* optimistic updates,
* consistency models,
* transactions,
* event-driven architecture,
* and why software systems are fundamentally machines for transforming state over time.
