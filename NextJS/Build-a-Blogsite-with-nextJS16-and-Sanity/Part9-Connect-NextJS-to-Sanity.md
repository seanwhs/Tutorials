# **✅ Part 9 — Connecting Next.js 16 to Sanity**

<img width="800" height="471" alt="image" src="https://github.com/user-attachments/assets/ed889401-4083-4e01-9061-3d89f0494e7b" />

# GreyMatter Journal

## Part 9 — Connecting Next.js 16 to Sanity: APIs, Environment Variables, and the Sanity Client

> **Goal of this lesson:** Connect our Next.js frontend to the Sanity Content Lake, understand how modern applications communicate with external systems, and learn why infrastructure code is fundamentally about building reliable boundaries.

---

# We Now Have Two Separate Systems

At this point, GreyMatter Journal consists of two independent applications:

```text
greymatter-journal/

├── app/
│      ↓
│   Reader Experience
│
└── studio/
       ↓
    Editor Experience
```

Our editors can create content.

Our readers can view pages.

But there is one major problem:

```text
The two systems do not communicate.
```

This reveals another important truth about modern software:

> Modern applications are usually collections of cooperating systems, not a single monolithic application.

---

# Two Applications, One Product

Although we think of GreyMatter Journal as:

```text
One Blog
```

our architecture now looks like this:

```text
Editors
       ↓

Sanity Studio
       ↓

Content Lake
       ↓

API
       ↓

Next.js
       ↓

Browser
```

This separation provides enormous advantages:

```text
✓ Independent deployment
✓ Independent scaling
✓ Independent development
✓ Independent ownership
✓ Better maintainability
```

But separation creates a new problem:

```text
Communication
```

---

# How Do Independent Systems Communicate?

Consider two systems:

```text
System A

System B
```

How do they exchange information?

The answer is:

```text
API
```

---

# What Is An API?

Many beginners think:

```text
API
     =
Complicated Technology
```

A better definition is:

> An API is simply a contract between systems.

For example:

```text
Restaurant
        ↓

Menu
        ↓

Kitchen
```

The menu is the contract.

Similarly:

```text
Next.js
       ↓

API
       ↓

Sanity
```

The API defines:

```text
What can be requested

What can be returned

How communication occurs
```

---

# The GreyMatter Journal Architecture

Our system now becomes:

```text
Reader
      ↓

Browser
      ↓

Next.js
      ↓

Sanity Client
      ↓

Sanity API
      ↓

Content Lake
      ↓

Documents
```

Visually:

```text
Frontend
       ↓
API Client
       ↓
External Service
       ↓
Database
```

This pattern appears everywhere:

```text
Frontend
       ↓
Backend API
       ↓
Database
```

or:

```text
Frontend
       ↓
Stripe API
       ↓
Payments
```

or:

```text
Frontend
       ↓
GitHub API
       ↓
Repositories
```

The pattern never changes.

---

# Installing The Official Sanity Integration

Sanity provides an official package called:

```text
next-sanity
```

Install it:

```bash
npm install next-sanity
```

This package provides:

```text
✓ API client
✓ GROQ integration
✓ TypeScript support
✓ Next.js caching support
✓ Revalidation support
✓ Image helpers
```

Think of it as:

```text
Translator
```

between:

```text
Next.js

and

Sanity
```

---

# Configuration Is Infrastructure

Before our application can communicate with Sanity, it must know:

```text
Which project?

Which dataset?

Which API version?
```

This information belongs to:

```text
Configuration
```

not:

```text
Business Logic
```

---

# Introducing Environment Variables

Create:

```text
.env.local
```

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id

NEXT_PUBLIC_SANITY_DATASET=production

NEXT_PUBLIC_SANITY_API_VERSION=2026-07-04
```

You can find your project ID inside:

```text
manage.sanity.io
```

---

# Why Use Environment Variables?

Beginners often ask:

> Why not just hardcode everything?

For example:

```typescript
const projectId =
  "abc123";
```

This works.

But professional systems rarely do this.

Because configuration changes:

```text
Development

Staging

Production
```

Each environment may have:

```text
Different databases

Different APIs

Different credentials
```

Environment variables separate:

```text
Code
       from
Configuration
```

---

# Understanding `NEXT_PUBLIC`

Notice:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID
```

contains:

```text
NEXT_PUBLIC
```

This prefix tells Next.js:

> This value is safe to expose to browser code.

Examples:

```text
Project IDs
Datasets
API versions
Feature flags
```

Notice what should never be public:

```text
API secrets
Tokens
Passwords
Private keys
```

Those remain server-only.

---

# Building The Sanity Client

Create:

```text
lib/sanity.ts
```

```typescript
import {
  createClient,
} from "next-sanity";

export const client =
  createClient({
    projectId:
      process.env
        .NEXT_PUBLIC_SANITY_PROJECT_ID,

    dataset:
      process.env
        .NEXT_PUBLIC_SANITY_DATASET,

    apiVersion:
      process.env
        .NEXT_PUBLIC_SANITY_API_VERSION,

    useCdn:
      process.env
        .NODE_ENV ===
          "production",

    perspective:
      "published",
  });
```

---

# Understanding The Client

Many beginners think:

```text
Client
     =
Database
```

Actually:

```text
Client
     =
Translator
```

Its job is to:

```text
Receive requests
        ↓

Construct API calls
        ↓

Talk to Sanity
        ↓

Return data
```

Visually:

```text
React Component
         ↓

Sanity Client
         ↓

HTTP Request
         ↓

Sanity API
         ↓

Content Lake
```

---

# Understanding `useCdn`

This line often confuses developers:

```typescript
useCdn:
  process.env.NODE_ENV ===
    "production"
```

The CDN is a global cache.

Development:

```text
Browser
      ↓
Sanity Database
```

Production:

```text
Browser
      ↓
Global CDN
      ↓
Sanity Database
```

Benefits:

```text
✓ Faster pages
✓ Lower latency
✓ Reduced cost
✓ Better scalability
```

---

# Understanding `perspective`

This option:

```typescript
perspective:
  "published"
```

tells Sanity:

> Only return published content.

Other perspectives include:

```text
published

drafts

previewDrafts
```

This enables:

```text
Editors
       ↓
Preview Drafts

Readers
       ↓
Published Content
```

---

# Testing The Connection

Create:

```text
app/(site)/test/page.tsx
```

```tsx
import {
  client,
} from "@/lib/sanity";

export default async function
TestPage() {

  const posts =
    await client.fetch(
      `*[_type=="post"]`
    );

  return (
    <div
      className="
        p-8
      "
    >
      <h1
        className="
          mb-6
          text-2xl
          font-bold
        "
      >
        Sanity Test
      </h1>

      <pre
        className="
          overflow-auto
          rounded-xl
          bg-black
          p-6
          text-white
        "
      >
        {JSON.stringify(
          posts,
          null,
          2
        )}
      </pre>
    </div>
  );
}
```

Visit:

```text
http://localhost:3000/test
```

If everything is configured correctly, you'll see:

```json
[]
```

This may look disappointing.

In reality, it means:

```text
✓ Next.js works
✓ Sanity works
✓ Authentication works
✓ Networking works
✓ API communication works
```

An empty array is actually a successful integration test.

---

# Introducing GROQ

Sanity uses a query language called:

```text
GROQ
```

which stands for:

```text
Graph-Relational Object Queries
```

Think of GROQ as:

```text
SQL

for content
```

---

# Your First GROQ Query

Fetch all posts:

```groq
*[_type=="post"]
```

Read this as:

> Give me all documents where the type is post.

---

# Fetching One Post

```groq
*[_type=="post"][0]
```

Read this as:

> Give me the first post.

---

# Selecting Fields

```groq
*[_type=="post"]{
  title,
  slug
}
```

returns:

```json
[
  {
    "title": "...",
    "slug": {}
  }
]
```

GROQ only returns what you request.

---

# Following Relationships

Suppose a post references an author:

```text
Post
      ↓
Author
```

We can follow the relationship:

```groq
*[_type=="post"]{
  title,

  author->{
    name
  }
}
```

The arrow:

```text
->
```

means:

```text
Follow the reference
```

This is one of GROQ's most powerful features.

---

# The Complete Data Flow

Our application now works like this:

```text
Editor
      ↓

Sanity Studio
      ↓

Content Lake
      ↓

Sanity API
      ↓

Sanity Client
      ↓

Next.js
      ↓

React Components
      ↓

Browser
```

Or, even more simply:

```text
Content
      ↓

API
      ↓

Data
      ↓

UI
```

---

# The Correct Mental Model

Beginners think:

```text
Database
       ↓
Website
```

Professional engineers think:

```text
Content System
         ↓

API Contract
         ↓

Application
         ↓

User Interface
```

Or:

```text
Sanity
       =
Business Data

Next.js
       =
Presentation Engine
```

---

# The Most Important Idea To Remember

The Sanity client is not business logic.

It is infrastructure.

Its responsibility is not:

```text
Understanding posts
```

Its responsibility is:

```text
Moving information safely
between systems.
```

Modern software architecture is largely the art of designing good boundaries.

And APIs are the boundaries that make independent systems possible.

---

# Up Next — Part 10: Creating Real Content

<img width="816" height="1440" alt="image" src="https://github.com/user-attachments/assets/f748f538-e865-42b4-933c-54a0d3595f59" />


Next, we'll finally create:

* Authors
* Categories
* Posts
* References
* Slugs
* Rich text content

And for the first time, we'll watch real content travel through our entire architecture:

```text
Editor
      ↓

Sanity Studio
      ↓

Content Lake
      ↓

GROQ Query
      ↓

Next.js
      ↓

React
      ↓

Browser
```
