# Appendix A11 — Next.js 16 Security Cheat Sheet

## The Complete Guide to Building Secure Next.js Applications

> **Purpose:** This appendix is the definitive reference for security in Next.js 16 applications. Security is not a feature you add at the end of development. Security is a property of the architecture.

---

# Introduction

The biggest misconception beginners have is:

```text id="k4m8ha"
Hackers attack
code.
```

In reality:

```text id="h0y34t"
Hackers attack
assumptions.
```

They exploit assumptions like:

```text id="xphkdd"
Users are honest.

Requests are valid.

Input is safe.

Secrets stay secret.

Clients can be trusted.
```

Professional engineers assume:

```text id="oqxnlw"
Everything
is hostile.
```

---

# The Security Pyramid

```text id="bn9g3l"
Application Security

         |

Authorization

         |

Authentication

         |

Validation

         |

Infrastructure
```

---

# The Golden Rule

Never trust:

```text id="4zwjlwm"
The browser.
```

---

# Why?

Because users can modify:

```text id="iq0u7o"
HTML

JavaScript

Requests

Cookies

Headers

Forms
```

---

# Visualizing

```text id="ch3iir"
Browser

   |

UNTRUSTED

   |

Server
```

---

# Authentication

Authentication answers:

```text id="07hucg"
Who are you?
```

---

# Authorization

Authorization answers:

```text id="mnix0u"
What can you do?
```

---

# Example

User:

```text id="whtvzw"
Sean
```

Authentication:

```text id="7bs4lg"
✓ Logged in
```

Authorization:

```text id="z8u88w"
✓ Admin
```

---

# Session Validation

Example:

```ts id="m5i2ma"
const session =
  await auth();

if (!session) {

  redirect(
    "/login"
  );

}
```

---

# Never Trust Client State

Bad:

```tsx id="m8h7j2"
if (user.isAdmin) {

  deleteUser();

}
```

---

Good:

```ts id="bdifq0"
if (
  session.role !==
  "admin"
) {

  throw Error();
}
```

---

# Input Validation

Every input must be validated.

---

Bad:

```ts id="4ew7tq"
await createUser(
  request.body
);
```

---

Good:

```ts id="b2ylb7"
const data =
  schema.parse(
    body
  );
```

---

# Zod Example

```ts id="cb6jzg"
const schema =
  z.object({

    email:
      z.email(),

    age:
      z.number(),

  });
```

---

# SQL Injection

Bad:

```ts id="xt5rzw"
const sql =
  `
    SELECT *
    FROM users
    WHERE id =
    ${id}
  `;
```

---

Attack:

```sql id="hhzj8m"
1 OR 1=1
```

---

Good:

```ts id="uhh73a"
await db.user
  .findUnique({

    where: {
      id,
    },

  });
```

---

# XSS (Cross Site Scripting)

Attack:

```html id="jagcqs"
<script>
alert()
</script>
```

---

Bad:

```tsx id="7yq0g2"
<div
  dangerouslySetInnerHTML
/>
```

---

Good:

```tsx id="jq74wy"
<div>
  {content}
</div>
```

---

# CSRF

Attack:

```text id="o6yoxs"
Another website

        |

Submits request

        |

Your user session
```

---

Protection:

```text id="cddr5x"
CSRF token
```

---

# Example

```ts id="r8dxod"
if (
  token !==
  csrfToken
) {

  throw Error();

}
```

---

# Password Storage

Never:

```text id="1i6nnc"
Store passwords.
```

---

Always store:

```text id="9t7m5r"
Password hashes.
```

---

Bad:

```ts id="e8q6zy"
password:
  "123456"
```

---

Good:

```ts id="slpj97"
password:
  "$2a$10..."
```

---

# Environment Variables

Never:

```ts id="vhlc0v"
const secret =
  "abc123";
```

---

Use:

```ts id="3rjlwm"
process.env
```

---

Example:

```ts id="z0gvgu"
const secret =
  process.env
    .JWT_SECRET;
```

---

# Public Environment Variables

Safe:

```text id="5b3e6u"
NEXT_PUBLIC_
```

---

Example:

```text id="mkaw3d"
NEXT_PUBLIC_API
```

---

Private:

```text id="rfjgmf"
DATABASE_URL
```

---

# Secret Leakage

Bad:

```tsx id="0gx9fw"
export default function
Page() {

  return (
    process.env
      .DATABASE_URL
  );

}
```

---

# Authorization

Always check:

```text id="tnj8cm"
Ownership.
```

---

Bad:

```ts id="bvvf1d"
deletePost(id);
```

---

Good:

```ts id="7kks4k"
if (
  post.userId !==
  session.user.id
) {

  throw Error();

}
```

---

# File Upload Validation

Never trust:

```text id="n62pbh"
File extension.
```

---

Bad:

```text id="nsbrsx"
virus.jpg
```

---

Actually:

```text id="wvshhf"
virus.exe
```

---

Validate:

```text id="q0bq5w"
Size

Type

Content
```

---

# Example

```ts id="0t5eq2"
if (
  file.size >
  MAX_SIZE
) {

  throw Error();

}
```

---

# Rate Limiting

Protect:

```text id="x9lkgh"
Login

Signup

API

Search
```

---

Example:

```text id="hzrvag"
5 requests
per minute
```

---

# Visualizing

```text id="a06p4z"
Request

    |

Counter

    |

Allow?
```

---

# API Keys

Never:

```text id="d1drpr"
Trust clients.
```

---

Validate:

```ts id="rq0a4k"
if (
  apiKey !==
  expected
) {

  return 403;

}
```

---

# Secure Cookies

Example:

```ts id="hbyrrq"
cookies().set({

  secure: true,

  httpOnly: true,

  sameSite:
    "strict",

});
```

---

# Why?

```text id="e9mm1c"
secure
```

means:

```text id="80z9uj"
HTTPS only
```

---

```text id="2ml5rz"
httpOnly
```

means:

```text id="xv5w73"
No JavaScript access
```

---

```text id="qmdkde"
sameSite
```

means:

```text id="zbfv22"
CSRF protection
```

---

# JWT Validation

Never:

```text id="psvxks"
Decode only.
```

---

Always:

```text id="pyq8u0"
Verify signature.
```

---

Bad:

```ts id="nh0k8n"
jwt.decode()
```

---

Good:

```ts id="ayfmrq"
jwt.verify()
```

---

# Content Security Policy

Example:

```text id="zt2s7n"
default-src 'self'
```

---

Purpose:

```text id="e84f1k"
Prevent XSS.
```

---

# Security Headers

Important headers:

```text id="ctmmtc"
CSP

HSTS

X-Frame-Options

X-Content-Type-Options
```

---

# Example

```ts id="w09w3l"
headers.set(
  "X-Frame-Options",
  "DENY"
);
```

---

# Clickjacking

Attack:

```text id="ttlrwi"
Invisible iframe.
```

---

Protection:

```text id="nqj4pr"
X-Frame-Options
```

---

# SSRF

Attack:

```text id="l5y58d"
User controls URL.
```

---

Bad:

```ts id="hhlxrb"
fetch(userUrl);
```

---

Good:

```ts id="3gbhgb"
validateURL(
  userUrl
);
```

---

# Open Redirect

Bad:

```ts id="x3qhjj"
redirect(
  url
);
```

---

Attack:

```text id="br71db"
evil.com
```

---

Good:

```ts id="nce7es"
allowlist
```

---

# Webhook Verification

Never:

```text id="7u1w5q"
Trust webhooks.
```

---

Example:

```ts id="wibcjq"
verifySignature(
  request
);
```

---

# Logging Secrets

Bad:

```ts id="g2pnzr"
console.log(
  process.env
);
```

---

Bad:

```ts id="pc4wev"
logger.info({
  password,
});
```

---

# Error Messages

Bad:

```text id="2h9x0h"
Password incorrect.
```

---

Good:

```text id="x0o8n7"
Invalid credentials.
```

---

# Security Through Obscurity

Bad:

```text id="r0kr0e"
Hidden endpoint.
```

---

Good:

```text id="v7jlwm"
Real security.
```

---

# Middleware Security

Example:

```ts id="d5yv3r"
export function
middleware() {

  authenticate();

}
```

---

# Route Handler Security

Example:

```ts id="4xagze"
export async function
POST() {

  authorize();

}
```

---

# Server Action Security

Example:

```ts id="8vjlwm"
"use server";

export async function
deleteUser() {

  authorize();

}
```

---

# Security Layers

```text id="1aqqoc"
Browser

   |

Middleware

   |

Route

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
```

---

# OWASP Top Risks

Be aware of:

```text id="uvngq5"
Broken access control

Cryptographic failures

Injection

Insecure design

Misconfiguration

Authentication failures

Integrity failures

Logging failures

SSRF
```

---

# Security Checklist

Always verify:

```text id="d32vfe"
✓ Authentication

✓ Authorization

✓ Validation

✓ Sanitization

✓ Rate limiting

✓ File uploads

✓ Secrets

✓ Logging

✓ Headers

✓ Webhooks
```

---

# Common Beginner Mistakes

---

## Mistake 1

Trusting the browser.

---

## Mistake 2

Skipping authorization.

---

## Mistake 3

Not validating input.

---

## Mistake 4

Logging secrets.

---

## Mistake 5

Storing plaintext passwords.

---

## Mistake 6

Trusting webhooks.

---

## Mistake 7

Exposing environment variables.

---

# Security Decision Tree

Need:

```text id="m3t9h6"
Who are you?
```

Use:

```text id="nq2v87"
Authentication
```

---

Need:

```text id="w7u3b1"
Can you do this?
```

Use:

```text id="r3yt81"
Authorization
```

---

Need:

```text id="o5ma8x"
Is this valid?
```

Use:

```text id="yz7rm5"
Validation
```

---

Need:

```text id="q7elx0"
Can this be trusted?
```

Assume:

```text id="zgo4yi"
No.
```

---

# The Complete Security Pipeline

```text id="8mnjk7"
Request
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

# Mental Model

Beginners think:

```text id="vr8t0q"
Security
=
Adding passwords.
```

Professional engineers think:

```text id="txk1qy"
Security
=
Eliminating trust.
```

Because secure systems are not built by trusting good users.

They are built by surviving bad ones.
