# Appendix A19 — Next.js 16 Security Engineering & Threat Modeling Cheat Sheet

## The Complete Guide to Building Secure Applications in the AI Era

> **Purpose:** This appendix is the definitive reference for security engineering in Next.js 16 applications. Security is not a feature that gets added at the end. Security is a property that emerges from every engineering decision.

---

# Introduction

The biggest misconception beginners have is:

```text
Security
=
Authentication.
```

Professional engineers understand:

```text
Security
=
Managing trust
boundaries.
```

Because every application is fundamentally:

```text
User Input

        |

Trust Boundary

        |

Your System
```

And every security vulnerability is essentially:

```text
Trusting something
that should not
have been trusted.
```

---

# The Golden Rule

Never ask:

```text
How do I
secure this?
```

Ask:

```text
What assumptions
am I making?
```

---

# Security Mindset

Assume:

```text
Users lie.

Networks fail.

Servers get compromised.

Tokens leak.

Humans make mistakes.
```

---

# Security Layers

```text
User
   |
Browser
   |
Network
   |
Application
   |
Database
   |
Infrastructure
```

---

# Defense In Depth

Never rely on:

```text
One defense.
```

Instead:

```text
Layer defenses.
```

---

# Example

```text
Authentication

      +

Authorization

      +

Validation

      +

Logging

      +

Monitoring
```

---

# The CIA Triad

Security protects:

```text
Confidentiality

Integrity

Availability
```

---

# Confidentiality

Question:

```text
Who can
see this?
```

---

# Integrity

Question:

```text
Who can
change this?
```

---

# Availability

Question:

```text
Can users
access this?
```

---

# Threat Modeling

Always ask:

```text
What are
we protecting?

From whom?

How?

Why?
```

---

# Assets

Examples:

```text
Passwords

User data

Payments

Secrets

Source code
```

---

# Threat Actors

Examples:

```text
Users

Hackers

Bots

Employees

AI agents
```

---

# Attack Surface

Question:

```text
Where can
someone interact
with the system?
```

---

Examples:

```text
Forms

APIs

Uploads

Cookies

Authentication

Webhooks
```

---

# Trust Boundaries

Visualizing:

```text
Browser
    |
TRUST BOUNDARY
    |
Server
```

---

Another:

```text
Application
      |
TRUST BOUNDARY
      |
Database
```

---

# Authentication

Question:

```text
Who are you?
```

---

# Authorization

Question:

```text
What are you
allowed to do?
```

---

# Never Confuse Them

Bad:

```text
Logged in
=
Administrator
```

---

Correct:

```text
Identity

+

Permissions
```

---

# Password Storage

Never:

```text
Store passwords.
```

---

Store:

```text
Password hashes.
```

---

Example:

```ts
await bcrypt.hash(
  password,
  12
);
```

---

# Session Security

Use:

```text
HttpOnly cookies.
```

---

Example:

```ts
cookies().set({

  httpOnly: true,

  secure: true,

  sameSite:
    "strict",

});
```

---

# Why?

Protect against:

```text
XSS.
```

---

# JWT Security

Never trust:

```text
Decoded tokens.
```

---

Always:

```text
Verify signatures.
```

---

Example:

```ts
jwt.verify(
  token,
  secret
);
```

---

# Authorization Models

Common models:

```text
RBAC

ABAC

ACL
```

---

# RBAC

Example:

```text
Admin

Editor

User
```

---

# ABAC

Example:

```text
User owns resource.
```

---

# Principle of Least Privilege

Give:

```text
Minimum permissions.
```

---

Not:

```text
Maximum convenience.
```

---

# Input Validation

Assume:

```text
All input
is malicious.
```

---

Example:

```ts
const schema =
  z.object({

    email:
      z.email(),

  });
```

---

# SQL Injection

Bad:

```ts
db.query(

  "SELECT * FROM users
   WHERE id=" + id

);
```

---

Good:

```ts
db.query(

  "SELECT * FROM users
   WHERE id=?",

  [id]

);
```

---

# Cross Site Scripting (XSS)

Bad:

```tsx
<div
  dangerouslySetInnerHTML={
    html
  }
/>
```

---

Good:

```tsx
<div>
  {content}
</div>
```

---

# Stored XSS

Example:

```text
Attacker stores:

<script>
...
</script>
```

---

Victim loads:

```text
Application compromised.
```

---

# Reflected XSS

Example:

```text
Search query

      |

Response HTML

      |

JavaScript execution
```

---

# DOM XSS

Example:

```js
element.innerHTML =
  userInput;
```

---

# CSRF

Attack:

```text
Victim logged in

       |

Attacker submits
request

       |

Victim account changed
```

---

# Prevention

Use:

```text
SameSite cookies

CSRF tokens
```

---

# SSRF

Attack:

```text
User URL

   |

Server request

   |

Internal network
```

---

Example:

```text
http://localhost
```

---

Mitigation:

```text
Allowlists.
```

---

# Command Injection

Bad:

```ts
exec(

  userInput

);
```

---

Never:

```text
Execute
user input.
```

---

# Path Traversal

Bad:

```ts
readFile(

  userPath

);
```

---

Attack:

```text
../../../etc/passwd
```

---

# File Upload Security

Validate:

```text
Extension

Mime type

Size

Content
```

---

Never trust:

```text
Filename.
```

---

# Secrets Management

Never store:

```text
API keys

Passwords

Tokens
```

In:

```text
Git.
```

---

Use:

```text
Environment variables

Secret managers
```

---

# API Security

Verify:

```text
Authentication

Authorization

Rate limits

Validation
```

---

# Rate Limiting

Purpose:

```text
Prevent abuse.
```

---

Example:

```text
100 requests
per minute
```

---

# Brute Force Protection

Example:

```text
5 attempts

      |

Lock account
```

---

# CAPTCHA

Use when:

```text
Bots exist.
```

---

# Security Headers

Use:

```text
CSP

HSTS

X-Frame-Options

X-Content-Type
```

---

# Content Security Policy

Purpose:

```text
Restrict
JavaScript execution.
```

---

Example:

```text
script-src
'self'
```

---

# Clickjacking

Prevent:

```text
iframe
embedding.
```

---

Example:

```text
X-Frame-Options:
DENY
```

---

# HTTPS

Always:

```text
Encrypt traffic.
```

---

Never:

```text
HTTP in production.
```

---

# Dependency Security

Monitor:

```text
Packages

Versions

Vulnerabilities
```

---

Example:

```bash
npm audit
```

---

# Supply Chain Attacks

Question:

```text
Can I trust
this package?
```

---

Verify:

```text
Popularity

Maintenance

Security history
```

---

# AI-Generated Code Security

Assume:

```text
AI code
is insecure.
```

Until proven:

```text
Otherwise.
```

---

Review:

```text
Authentication

Authorization

Validation

Secrets

Permissions
```

---

# Database Security

Apply:

```text
Least privilege.
```

---

Bad:

```text
Database admin
everywhere.
```

---

Good:

```text
Read-only

Read-write

Admin
```

---

# Encryption

Encrypt:

```text
Passwords

Tokens

Sensitive data
```

---

# Logging Security

Never log:

```text
Passwords

Tokens

Secrets

Credit cards
```

---

Bad:

```ts
logger.info({

  password,

});
```

---

# Monitoring Security

Monitor:

```text
Failed logins

Permission failures

Rate limits

Suspicious activity
```

---

# Security Testing

Test:

```text
Authentication

Authorization

Validation

Permissions
```

---

# Security Checklist

Verify:

```text
✓ Authentication

✓ Authorization

✓ Validation

✓ Encryption

✓ Logging

✓ Monitoring

✓ Rate limiting

✓ Secrets

✓ HTTPS

✓ Dependencies
```

---

# The OWASP Top Risks

Know:

```text
Broken Access Control

Cryptographic Failures

Injection

Insecure Design

Security Misconfiguration

Authentication Failures

Integrity Failures

Logging Failures

SSRF
```

---

# Common Beginner Mistakes

---

## Mistake 1

Trusting user input.

---

## Mistake 2

Using localStorage for auth.

---

## Mistake 3

Logging secrets.

---

## Mistake 4

Skipping authorization.

---

## Mistake 5

Using admin database users.

---

## Mistake 6

Ignoring dependencies.

---

## Mistake 7

Assuming AI-generated code is secure.

---

# Security Decision Tree

Question:

```text
Can users
control this?
```

If:

```text
Yes
```

Then:

```text
Validate.
```

---

Question:

```text
Can users
access this?
```

Then:

```text
Authorize.
```

---

Question:

```text
Can users
modify this?
```

Then:

```text
Authenticate.
```

---

Question:

```text
Can this fail?
```

Then:

```text
Log it.
```

---

# The Complete Security Pipeline

```text
User
   |
Validate
   |
Authenticate
   |
Authorize
   |
Execute
   |
Log
   |
Monitor
   |
Alert
```

---

# Mental Model

Beginners think:

```text
Security
=
Protecting
the application.
```

Professional engineers think:

```text
Security
=
Protecting
trust boundaries.
```

Because every security vulnerability is ultimately the same mistake:

```text
Trusting
something
you should
have verified.
```
