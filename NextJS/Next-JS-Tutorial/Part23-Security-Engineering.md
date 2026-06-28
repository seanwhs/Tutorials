# Next.js 16 for Absolute Beginners

# Part 23 — Security Engineering: How Professional Next.js Applications Protect Themselves

> **Goal of this lesson:** Learn how to secure Next.js 16 applications against common attacks and build production-grade security practices into your applications from the beginning.

---

# The Biggest Security Mistake

Beginners think:

```text
Build App
    |
Works
    |
Deploy
```

Professional engineers think:

```text
Build App
    |
Assume Attack
    |
Protect
    |
Observe
    |
Deploy
```

Because every public application is under attack.

Not someday.

Immediately.

---

# Security Is About Trust Boundaries

Every application has boundaries:

```text
Browser
    |
Internet
    |
Server
    |
Database
```

The question is:

> Which parts do we trust?

---

# Rule #1

Never trust:

```text
User input
```

Never trust:

```text
Browser state
```

Never trust:

```text
Query parameters
```

Never trust:

```text
Cookies
```

Never trust:

```text
HTTP requests
```

Always verify everything.

---

# The Security Layers

Professional applications use:

```text
Authentication

Authorization

Input Validation

Session Security

Data Protection

Infrastructure Security

Monitoring
```

---

# Visualizing Security

```text
                Security
                    |
       +------------+------------+
       |            |            |
       V            V            V
 Authentication Authorization Validation
```

---

# Authentication

Authentication answers:

> Who are you?

---

# Authorization

Authorization answers:

> What are you allowed to do?

---

# Beginners Often Confuse Them

Example:

```text
User logged in
```

This means:

```text
Authenticated
```

It does NOT mean:

```text
Administrator
```

---

# Example

Bad:

```tsx
export async function deleteUser(
    id: number
) {

    await db.user.delete({

        where: { id }

    });

}
```

---

Good:

```tsx
export async function deleteUser(
    id: number
) {

    const user =
        await requireUser();

    if (
        user.role !== "admin"
    ) {

        throw new Error(
            "Forbidden"
        );

    }

    await db.user.delete({

        where: { id }

    });

}
```

---

# Visualizing Authorization

```text
Request
    |
Session
    |
Permission Check
    |
Allow / Deny
```

---

# Password Security

Never store:

```text
password
```

Store:

```text
hashed password
```

---

# Bad

```ts
password:
    "password123"
```

---

# Good

```ts
password:
"$2b$10$K..."
```

---

# Why?

If your database leaks:

Bad:

```text
Everyone's passwords exposed.
```

Good:

```text
Passwords remain protected.
```

---

# Session Security

After login:

```text
User
    |
Session
    |
Cookie
```

---

# Cookie Example

```ts
cookies().set(

    "session",

    token,

    {

        httpOnly: true,

        secure: true,

        sameSite: "strict",

    }

);
```

---

# Why httpOnly?

Without:

```text
JavaScript
     |
Steal Cookie
```

With:

```text
Cookie protected.
```

---

# Why secure?

Without:

```text
HTTP traffic
     |
Stolen cookie
```

With:

```text
HTTPS only.
```

---

# Why sameSite?

Protects against:

```text
Cross-site attacks
```

---

# CSRF Attacks

CSRF means:

```text
Cross Site Request Forgery
```

---

# Attack Example

Victim logged into:

```text
bank.com
```

Attacker tricks victim into visiting:

```html
<img
 src="
 https://bank.com/
 transfer?amount=10000
 ">
```

The browser sends:

```text
Victim's cookies.
```

Money transferred.

---

# Defense

Use:

```text
sameSite cookies

CSRF tokens
```

---

# XSS Attacks

XSS means:

```text
Cross Site Scripting
```

---

# Attack Example

User enters:

```html
<script>

stealPasswords()

</script>
```

---

# Bad

```tsx
<div>

    {userInput}

</div>
```

if dangerous HTML is rendered.

---

# Better

Always sanitize HTML.

Example:

```text
User Input
      |
Sanitizer
      |
Safe HTML
```

---

# Visualizing XSS

```text
Attacker
    |
Malicious Script
    |
Victim Browser
    |
Stolen Data
```

---

# SQL Injection

Bad:

```ts
const query =

`
SELECT *
FROM users
WHERE email='${email}'
`;
```

---

Attacker enters:

```sql
' OR 1=1 --
```

Result:

```sql
SELECT *
FROM users
WHERE email=''
OR 1=1
```

Everything returned.

---

# Safe

Use ORM queries:

```ts
await db.user.findUnique({

    where: {
        email,
    },

});
```

---

# SSRF Attacks

SSRF means:

```text
Server Side Request Forgery
```

---

Example:

User submits:

```text
http://localhost:5432
```

Server fetches:

```text
Internal services.
```

Dangerous.

---

# Defense

Allow only:

```text
Approved domains.
```

---

# Input Validation

Bad:

```tsx
await createPost(

    formData.get(
        "title"
    )

);
```

---

Good:

```tsx
const title =
    String(
        formData.get(
            "title"
        )
    );

if (
    title.length < 3
) {

    throw Error(
        "Invalid title"
    );

}
```

---

# Better

Use schemas.

Example:

```ts
const schema = {

    title:

        {
            min: 3,
            max: 100,
        },

};
```

---

# Visualizing Validation

```text
Input
    |
Validate
    |
Accept/Reject
```

---

# File Upload Security

Beginners trust:

```text
filename
extension
mime type
```

Never do this.

---

# Bad

```text
virus.jpg
```

may actually be:

```text
virus.exe
```

---

# Always Verify

Check:

```text
File size

Mime type

Content signature
```

---

# Example

```ts
if (
    file.size >
    10_000_000
) {

    throw Error(
        "Too large"
    );

}
```

---

# File Upload Architecture

```text
Browser
    |
Validate
    |
Virus Scan
    |
Storage
```

---

# Rate Limiting

Suppose attacker does:

```text
1,000,000 logins
```

You need:

```text
Rate limits.
```

---

# Example

Allow:

```text
10 requests/minute
```

---

Visualized:

```text
Request
    |
Counter
    |
Allowed?
```

---

# Brute Force Protection

Bad:

```text
Unlimited login attempts.
```

Good:

```text
5 attempts
     |
Lock account
```

---

# Authorization Security

Never trust:

```text
URL
```

---

Bad:

```text
/users/1
/users/2
/users/3
```

---

Always verify ownership.

Example:

```ts
if (

    post.authorId !==
    session.user.id

) {

    throw Error(
        "Forbidden"
    );

}
```

---

# Environment Variables

Bad:

```ts
const key =
"my-secret-key";
```

---

Good:

```ts
const key =
process.env.API_KEY;
```

---

# Never Commit

```text
.env
```

to Git.

---

# Secret Rotation

Never assume:

```text
Secrets live forever.
```

Rotate:

```text
API keys

JWT secrets

Database passwords
```

---

# Logging Security Events

Log:

```text
Login failures

Permission failures

Rate limits

Suspicious uploads

Password resets
```

---

# Example

```ts
console.log({

    event:
        "permission_denied",

    user:
        user.id,

    action:
        "delete_post",

});
```

---

# Security Headers

Important headers:

```text
Content-Security-Policy

X-Frame-Options

X-Content-Type-Options

Strict-Transport-Security
```

---

# Example

```text
Browser
    |
Security Headers
    |
Protected Browser
```

---

# HTTPS

Never deploy:

```text
HTTP
```

Always deploy:

```text
HTTPS
```

---

# Protecting Server Actions

Bad:

```tsx
"use server";

export async function
deleteEverything() {

    ...
}
```

---

Good:

```tsx
"use server";

export async function
deleteEverything() {

    const user =
        await requireUser();

    if (
        user.role !==
        "admin"
    ) {

        throw Error(
            "Forbidden"
        );

    }

}
```

---

# Protecting Route Handlers

Example:

```tsx
export async function POST() {

    const session =
        await getSession();

    if (!session)
        return new Response(
            null,
            {
                status:401
            }
        );

}
```

---

# Database Security

Principles:

```text
Least privilege

Parameterized queries

Backups

Encryption
```

---

# Cache Security

Never cache:

```text
Passwords

Sessions

Private data
```

---

Bad:

```tsx
"use cache";

return session;
```

---

Good:

```tsx
return publicData;
```

---

# Production Security Checklist

```text
✓ HTTPS

✓ Secure cookies

✓ CSRF protection

✓ Input validation

✓ XSS protection

✓ SQL injection protection

✓ Rate limiting

✓ File validation

✓ Authorization checks

✓ Secrets management

✓ Logging

✓ Monitoring
```

---

# Security Mindset

Don't ask:

```text
Can users do this?
```

Ask:

```text
How could attackers abuse this?
```

---

# Example

Feature:

```text
Upload profile picture.
```

Questions:

```text
Upload virus?

Upload 10GB file?

Upload executable?

Upload script?

Upload 1 million files?
```

---

# The Security Pyramid

```text
            Monitoring
                  |
           Authorization
                  |
          Authentication
                  |
           Input Validation
                  |
              Transport
```

---

# What To Secure In Our Nexus CMS

```text
✓ Login

✓ Sessions

✓ Posts

✓ Comments

✓ Uploads

✓ Dashboard

✓ APIs

✓ Search

✓ Notifications

✓ Admin pages
```

---

# Exercises

## Exercise 1

Secure:

```text
Delete Post
```

---

## Exercise 2

Design:

```text
Upload Security
```

---

## Exercise 3

Design:

```text
Rate Limiting
```

for login.

---

## Exercise 4

Create a security checklist for:

```text
Comment submission
```

---

# What You've Learned

You now understand:

✅ authentication security

✅ authorization security

✅ password security

✅ cookies

✅ CSRF

✅ XSS

✅ SQL injection

✅ SSRF

✅ upload security

✅ secrets management

✅ rate limiting

---

# Mental Model

Beginners ask:

```text
How do I build it?
```

Professionals ask:

```text
How can it fail?

How can it be abused?

How do I defend it?
```

Because every feature is also an attack surface.

---

# Part 24 Preview

In the next chapter we'll learn:

# Deployment, CI/CD, and Production Operations

Including:

* Vercel deployment
* Docker
* PostgreSQL hosting
* CI/CD pipelines
* preview deployments
* migrations
* rollback strategies
* blue/green deployments
* backups
* disaster recovery
* production release engineering

This is where software projects become software products.
