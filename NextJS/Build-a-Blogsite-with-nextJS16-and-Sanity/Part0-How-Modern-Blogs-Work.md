# GreyMatter Journal

# Part 0 — Understanding Modern Blog Architecture, Content Systems, and Why Software Is Really About Managing Complexity

> **Series Goal:** Build a production-grade content platform using Next.js 16 and Sanity while learning the deeper principles that govern modern software systems.
>
> **Part 0 Goal:** Before writing any code, understand what we're actually building, why modern web architectures evolved the way they did, and why software engineering is fundamentally the discipline of managing complexity.

---

# Welcome to GreyMatter Journal

If you've searched for:

```text
"Next.js + Sanity blog tutorial"
```

you've probably encountered tutorials that look something like this:

```bash
npx create-next-app@latest my-blog

npx sanity@latest init

npm install

npm run dev
```

Thirty minutes later, you have a functioning blog.

But an important question remains:

> What exactly did you build?

You created files.

You copied code.

You started servers.

But you probably didn't develop a mental model of the system itself.

This series takes a different approach.

Before we write code, we will first understand the architecture, the tradeoffs, and the ideas behind modern software systems.

Because professional engineers do not merely write code.

They build mental models.

---

# The Biggest Misconception About Blogs

Many beginners imagine a blog like this:

```text
Website
    ↓
Articles
```

But modern content platforms actually look more like this:

```text
People
    ↓
Content System
    ↓
Storage System
    ↓
Query System
    ↓
Rendering System
    ↓
Caching System
    ↓
Delivery System
    ↓
Browser
```

A modern blog is not really a website.

It is a distributed information system.

---

# What Are We Actually Building?

Throughout this series, we will build:

```text
GreyMatter Journal
```

At first glance, it appears to be:

```text
A Blog
```

In reality, it is:

```text
A Content Platform
```

consisting of multiple specialized systems:

```text
Content Creation
         ↓

Content Storage
         ↓

Content Querying
         ↓

Rendering
         ↓

Caching
         ↓

Delivery
         ↓

Observation
```

Each layer solves a different problem.

---

# The GreyMatter Architecture

Our architecture will eventually look like this:

```text
Writers & Editors
         ↓

Sanity Studio
         ↓

Sanity Content Lake
         ↓

GROQ API
         ↓

Next.js 16
         ↓

React Server Components
         ↓

Caching Layer
         ↓

CDN
         ↓

Browser
```

Each component has a single responsibility.

---

# Why Modern Software Is Built This Way

Historically, applications looked like this:

```text
Browser
    ↓
Application
    ↓
Database
```

Everything lived inside one system.

Examples:

* WordPress
* Drupal
* Joomla
* Rails applications
* PHP applications

Visually:

```text
┌──────────────────┐
│      CMS         │
│                  │
│ Editor           │
│ Database         │
│ Themes           │
│ Rendering        │
│ Authentication   │
│ Plugins          │
└──────────────────┘
```

This architecture worked.

Until it didn't.

---

# The Problem of Growing Complexity

As systems become larger, several problems emerge:

```text
More features
       ↓

More dependencies
       ↓

More coupling
       ↓

More complexity
       ↓

Less understanding
```

Eventually, changing one part of the system risks breaking everything else.

Examples include:

* changing themes breaks plugins
* database migrations break pages
* frontend redesigns break content
* upgrades break integrations

The real problem isn't technology.

The real problem is:

```text
Complexity
```

---

# The Great Separation

Modern architectures solve complexity by separating concerns.

Instead of:

```text
One giant system
```

we build:

```text
Specialized systems
```

For example:

```text
Content System
       +
Rendering System
       +
Delivery System
```

This architectural style is called:

```text
Headless Architecture
```

---

# What Does "Headless" Mean?

<img width="1920" height="816" alt="image" src="https://github.com/user-attachments/assets/461291f7-7b69-4536-9dee-4da4a2cede88" />


Traditional systems combine:

```text
Content
      +
Presentation
```

Headless systems separate them.

Instead of:

```text
CMS
 ├── Editor
 ├── Database
 ├── Frontend
 └── Templates
```

we build:

```text
Content System
        ↓
API
        ↓
Presentation System
```

The content system no longer cares:

* how content is displayed
* where content is displayed
* who consumes the content

Its only responsibility becomes:

```text
Managing Information
```

---

# Why We Chose Sanity

<img width="3388" height="2946" alt="image" src="https://github.com/user-attachments/assets/0319a025-f096-46cf-9171-00ed5d10657c" />


Sanity is not merely a CMS.

It is a:

```text
Content Platform
```

built around an idea called:

```text
The Content Lake
```

Traditional databases store:

```text
Rows
   +
Columns
```

The Content Lake stores:

```text
Documents
        +
Relationships
        +
Metadata
        +
History
```

For example:

```text
Post
    ↓
Author
    ↓
Categories
    ↓
Images
    ↓
Drafts
```

All of these remain connected.

---

# Why We Chose Next.js 16

<img width="780" height="496" alt="image" src="https://github.com/user-attachments/assets/0cc7bd83-0f71-4460-b102-62f0e1e69ab9" />


If Sanity manages information:

```text
Next.js manages experience.
```

Its responsibilities include:

* rendering
* routing
* caching
* optimization
* streaming
* metadata
* image delivery
* server execution

In other words:

```text
Sanity
      =
Truth

Next.js
      =
Presentation
```

---

# The Three Jobs of Every Content Platform

No matter how sophisticated a system becomes, it ultimately performs three jobs:

```text
Store Information

Organize Information

Present Information
```

Consider a single article:

```text
Post
 ├── Title
 ├── Slug
 ├── Author
 ├── Categories
 ├── Hero Image
 ├── Body
 ├── Metadata
 ├── SEO
 └── Relationships
```

When a user visits:

```text
/posts/why-nextjs-matters
```

the system must:

```text
Locate Data
        ↓
Resolve Relationships
        ↓
Transform Data
        ↓
Render Interface
        ↓
Deliver Experience
```

Everything else builds on top of this.

---

# The Hidden Architecture of Every Request

Suppose a reader opens an article.

What actually happens?

```text
Browser
      ↓
CDN
      ↓
Next.js
      ↓
Cache
      ↓
Sanity API
      ↓
Content Lake
      ↓
Response
      ↓
Rendering
      ↓
Browser
```

Even a simple blog post involves:

* networking
* caching
* rendering
* databases
* APIs
* distributed systems

Modern software is much larger than the UI we see.

---

# Before We Write Code

In Part 1, we'll run:

```bash
npx create-next-app@latest greymatter-journal
```

This command generates:

```text
app/
public/

package.json
tsconfig.json
next.config.ts
eslint.config.ts
```

Many beginners immediately ask:

> What does every file do?

Professional engineers ask a different question:

> What problem was this file created to solve?

We will learn each file only when we encounter the problem it exists to address.

This is how real software engineering works.

---

# The Final Architecture

By the end of this series, GreyMatter Journal will resemble:

```text
                    Writers
                        │
                        ▼
               ┌────────────────┐
               │ Sanity Studio  │
               └───────┬────────┘
                       │
                       ▼
               ┌────────────────┐
               │ Content Lake   │
               └───────┬────────┘
                       │
                 GROQ Queries
                       │
                       ▼
               ┌────────────────┐
               │ Next.js 16     │
               │ App Router     │
               │ RSC            │
               │ Caching        │
               │ Streaming      │
               └───────┬────────┘
                       │
                       ▼
                    CDN
                       │
                       ▼
                   Browser
```

---

# What We'll Build

Throughout this series we'll implement:

* content modeling
* routing
* layouts
* React Server Components
* caching
* metadata
* image delivery
* authentication
* comments
* likes
* draft mode
* preview systems
* deployment
* observability
* production architecture

But these topics are not the true curriculum.

---

# The Real Curriculum

What you'll actually learn is:

```text
State

Trees

Boundaries

Caching

Failure

Trust

Observation

Complexity
```

Because software engineering is ultimately not about frameworks.

It is about understanding systems.

---

# Mental Model To Remember Forever

Beginners think:

```text
Code
     =
Application
```

Professional engineers think:

```text
Information
        +
Systems
        +
Constraints
        +
Understanding
        =
Application
```

More fundamentally:

```text
Software Engineering
            =
The Discipline
Of Managing
Complexity
```

And GreyMatter Journal is where we'll learn how.

---

# Up Next — Part 1: Project Initialization

We'll create our Next.js 16 project, initialize Sanity Studio, examine the files generated by the framework, and begin constructing the architectural foundation for everything that follows.

The code starts next.

The engineering starts now.
