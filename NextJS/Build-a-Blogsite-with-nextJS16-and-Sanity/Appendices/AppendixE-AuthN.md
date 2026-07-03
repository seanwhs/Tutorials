# Appendix E — Complete Authentication with Clerk, Identity, Sessions, and Trust Boundaries

> **Goal of this appendix:** Add production-grade authentication to GreyMatter Journal using Clerk while learning the deeper concepts of identity, authentication, authorization, sessions, trust boundaries, and modern web security architecture.

---

# Introduction

One of the first questions developers ask when building applications is:

> "How do I add login?"

This seems like a simple question.

Unfortunately, authentication is one of the most difficult problems in software engineering.

Because the real question isn't:

```text id="pjlwm3"
How do users log in?
```

The real question is:

```text id="y7oqcz"
How do computers establish trust?
```

---

# Authentication Versus Authorization

Most beginners confuse these concepts.

Authentication asks:

```text id="zr6v80"
Who are you?
```

Authorization asks:

```text id="w09akv"
What are you allowed to do?
```

Diagram:

```text id="mgpnj1"
Authentication
       │
       ▼

Identity

       │
       ▼

Authorization

       │
       ▼

Permissions
```

---

# Example

Suppose someone arrives at an airport.

First:

```text id="1e8g7a"
Passport Check
```

This is:

```text id="kp40mg"
Authentication.
```

Then:

```text id="fhrv3q"
Can enter country?
```

This is:

```text id="btjcjk"
Authorization.
```

---

# Why Authentication Is Difficult

Suppose we implement:

```typescript id="efuy4n"
if (
  username === "admin" &&
  password === "123"
)
```

Problems:

```text id="8tk1bh"
Password Storage

Password Reset

Session Management

Social Login

Email Verification

Security

Multi-Factor Authentication

Bot Detection
```

Authentication quickly becomes:

```text id="gmjlwm"
A security engineering problem.
```

---

# Why Clerk?

We could build authentication ourselves.

However:

> Never build security infrastructure unless security infrastructure is your business.

Clerk provides:

```text id="8cc6u4"
✓ Authentication
✓ Sessions
✓ JWTs
✓ OAuth
✓ Passkeys
✓ MFA
✓ Organizations
✓ User Management
✓ Session Security
✓ Webhooks
```

---

# Create A Clerk Account

Visit:

```text id="v3r0jl"
https://clerk.com
```

Create a new application:

```text id="9zqdxh"
GreyMatter Journal
```

Choose:

```text id="djlwmn"
Email

Google

GitHub
```

authentication providers.

---

# Install Clerk

Inside your Next.js application:

```bash id="kqzh6e"
npm install @clerk/nextjs
```

---

# Add Environment Variables

Create:

```bash id="gl0ss5"
.env.local
```

Add:

```bash id="vylqtz"
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
pk_*****

CLERK_SECRET_KEY=
sk_*****
```

---

# Wait...

Why Two Keys?

Public:

```text id="nyyjwv"
Browser Safe
```

Private:

```text id="9vjlwm"
Server Only
```

Diagram:

```text id="0oxvx7"
Browser
    │
    ▼

Public Key

Server
    │
    ▼

Secret Key
```

---

# Add Middleware

Create:

```text id="jlwmou"
middleware.ts
```

```typescript id="lr4rgh"
import {
  clerkMiddleware,
} from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: [
    "/((?!_next).*)",
  ],
};
```

---

# What Is Middleware?

Middleware executes:

```text id="31vntn"
Before Your Application
```

Diagram:

```text id="i1pz4r"
Request
    │
    ▼

Middleware
    │
    ▼

Authentication
    │
    ▼

Application
```

---

# Add Clerk Provider

Open:

```text id="8klcc8"
app/layout.tsx
```

```tsx id="hf2zqe"
import {
  ClerkProvider,
} from "@clerk/nextjs";

export default function
RootLayout({
  children,
}: {
  children:
    React.ReactNode;
}) {
  return (
    <ClerkProvider>

      <html>
        <body>
          {children}
        </body>
      </html>

    </ClerkProvider>
  );
}
```

---

# Add Sign In

Create:

```text id="gjnl26"
app/sign-in/[[...sign-in]]/page.tsx
```

```tsx id="4jlwmn"
import {
  SignIn,
} from "@clerk/nextjs";

export default function
Page() {
  return (
    <div className="
      flex
      justify-center
      py-20
    ">
      <SignIn />
    </div>
  );
}
```

---

# Add Sign Up

Create:

```text id="xkq02f"
app/sign-up/[[...sign-up]]/page.tsx
```

```tsx id="zjlwmw"
import {
  SignUp,
} from "@clerk/nextjs";

export default function
Page() {
  return (
    <div className="
      flex
      justify-center
      py-20
    ">
      <SignUp />
    </div>
  );
}
```

---

# Add User Button

Open:

```text id="l4m5d7"
components/layout/Header.tsx
```

```tsx id="mjlwm9"
import {
  UserButton,
  SignedIn,
  SignedOut,
  SignInButton,
} from "@clerk/nextjs";
```

Then:

```tsx id="bjlwm3"
<nav>

  <SignedOut>

    <SignInButton />

  </SignedOut>

  <SignedIn>

    <UserButton />

  </SignedIn>

</nav>
```

---

# That's It?

Amazingly:

```text id="jlwmc4"
Yes.
```

Because Clerk implements:

```text id="jlwmf5"
Identity

Sessions

Cookies

Security

Encryption

OAuth

Verification
```

for us.

---

# Understanding Sessions

Suppose a user logs in.

Question:

```text id="jlwmz6"
How does the server
remember them?
```

Answer:

```text id="7wjlwm"
Sessions.
```

---

# Session Diagram

```text id="jlwmc7"
Login
   │
   ▼

Server Creates Session
   │
   ▼

Session ID
   │
   ▼

Browser Cookie
   │
   ▼

Future Requests
```

---

# Example

Browser stores:

```text id="jlwmv8"
session=
abc123
```

Request:

```http id="jlwmp9"
GET /posts

Cookie:
session=abc123
```

Server checks:

```text id="jlwmw0"
abc123
```

and identifies:

```text id="jlwmx1"
Sean
```

---

# Wait...

Why Not Store Username?

Bad:

```text id="jlwmy2"
username=admin
```

Because users can modify:

```text id="jlwmz3"
Anything
in the browser.
```

---

# Trust Boundaries

This introduces one of the most important concepts in engineering:

```text id="jlwm04"
Trust Boundaries
```

Diagram:

```text id="jlwm15"
Browser
   │
   ▼

UNTRUSTED

   │
   ▼

Server

   │
   ▼

TRUSTED
```

Rule:

> Never trust the browser.

---

# Getting The Current User

Server Component:

```typescript id="jlwm26"
import {
  auth,
} from
"@clerk/nextjs/server";

export default
async function
Page() {

  const {
    userId,
  } = await auth();

  return (
    <div>
      {userId}
    </div>
  );
}
```

---

# Protecting Routes

Suppose only admins can enter:

```text id="jlwm37"
/admin
```

Create:

```typescript id="jlwm48"
import {
  auth,
} from
"@clerk/nextjs/server";

import {
  redirect,
} from
"next/navigation";

export default
async function
AdminPage() {

  const {
    userId,
  } = await auth();

  if (!userId) {
    redirect(
      "/sign-in"
    );
  }

  return (
    <div>
      Admin
    </div>
  );
}
```

---

# Authentication In Server Actions

```typescript id="jlwm59"
"use server";

import {
  auth,
} from
"@clerk/nextjs/server";

export async function
createComment() {

  const {
    userId,
  } = await auth();

  if (!userId) {
    throw new Error(
      "Unauthorized"
    );
  }

  // save comment
}
```

---

# Why Check Again?

Suppose:

```text id="jlwm60"
Button Hidden
```

in the UI.

Can attackers still call:

```text id="jlwm71"
POST /api/comments
```

Yes.

Therefore:

```text id="jlwm82"
Client Security
      =
No Security
```

---

# Role-Based Access Control

Example:

```typescript id="jlwm93"
if (
  user.role !==
  "admin"
) {
  throw new Error(
    "Forbidden"
  );
}
```

Roles:

```text id="jlwm04a"
Reader

Author

Editor

Admin
```

---

# Authentication Flow

```text id="jlwm15a"
User
   │
   ▼

Login
   │
   ▼

Clerk
   │
   ▼

Session
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

# OAuth Login

Suppose user clicks:

```text id="jlwm26a"
Continue
with Google
```

Flow:

```text id="jlwm37a"
Browser
   │
   ▼

Google
   │
   ▼

Authorization
   │
   ▼

Clerk
   │
   ▼

Session
```

This is called:

```text id="jlwm48a"
Federated Identity.
```

---

# Multi-Factor Authentication

Traditional authentication:

```text id="jlwm59a"
Something You Know
```

MFA adds:

```text id="jlwm60a"
Something You Have
```

Examples:

```text id="jlwm71a"
Phone

Authenticator

Passkey

Hardware Token
```

---

# Modern Authentication

Today's authentication increasingly uses:

```text id="jlwm82a"
Passkeys
```

Instead of:

```text id="jlwm93a"
Passwords
```

because humans are poor at:

```text id="jlwm04b"
Remembering secrets.
```

---

# The Hidden Architecture

When a user logs in:

```text id="jlwm15b"
Browser
    │
    ▼

Clerk Frontend
    │
    ▼

Identity Provider
    │
    ▼

Session Creation
    │
    ▼

Cookie
    │
    ▼

Next.js
    │
    ▼

Server Actions
    │
    ▼

Protected Data
```

---

# Wait...

Does This Look Familiar?

We've discovered:

```text id="jlwm26b"
State Trees

Failure Trees

Trust Trees

Cache Trees

Observation Trees

Complexity Trees
```

Authentication introduces:

```text id="jlwm37b"
Identity Trees
```

because every secure system ultimately asks:

```text id="jlwm48b"
Who are you?

Who trusts you?

Who trusted them?
```

---

# The Deep Secret Of Authentication

Most beginners think:

```text id="jlwm59b"
Authentication
              =
Login Pages
```

Professional engineers think:

```text id="jlwm60b"
Authentication
              =
Establishing
              Trust
              Between
              Distrusting
              Systems
```

---

# Mental Model To Remember Forever

Beginners think:

```text id="jlwm71b"
Security
        =
Passwords
```

Professional engineers think:

```text id="jlwm82b"
Security
        =
Managing
        Trust
        Boundaries
```

Authentication is not really about users.

It is about answering one of the deepest questions in computer science:

```text id="jlwm93b"
How can one system
trust another system
when neither system
can directly observe
the truth?
```
