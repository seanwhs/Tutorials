# **✅ Part 7 — Introducing Sanity**

# GreyMatter Journal

## Part 7 — Introducing Sanity: Why Next.js Doesn't Store Your Blog Posts

> **Goal of this lesson:** Understand why content and presentation should be separated, learn what a Headless CMS actually is, and discover why modern applications increasingly treat content as a distributed system rather than a collection of files.

---

# We Built a Website — But We Didn't Build a Publishing System

At this point, GreyMatter Journal looks like a real application.

We have:

```text
✓ Root Layout
✓ Site Layout
✓ Header
✓ Footer
✓ Route Groups
✓ Pages
✓ Persistent UI
```

Our architecture now looks like this:

```text
Browser
      ↓

Next.js App Router
      ↓

React Components
      ↓

Rendered UI
```

But we're missing something fundamental.

Where do the articles come from?

---

# The Beginner Solution

Most beginners immediately think:

```text
app/

posts/

    page.tsx

    react-server-components.md

    nextjs-routing.md

    caching.md
```

Or perhaps:

```text
data/

    posts.json
```

Or:

```tsx
const posts = [
  {
    title:
      "React Server Components",
  },
];
```

Initially, this seems reasonable.

Until reality arrives.

---

# The First Content Problem

Imagine GreyMatter Journal becomes successful.

Suddenly you need:

```text
100 articles

500 articles

5000 articles
```

Now you need:

```text
Authors

Categories

Tags

Drafts

Publishing workflows

Scheduled publishing

SEO metadata

Images

Comments

Revision history
```

The question changes from:

> How do I display content?

to:

> How do I manage content?

These are completely different problems.

---

# Next.js Is Not A CMS

This is one of the most important lessons in modern web development.

Many beginners assume:

```text
Next.js
        =
Website Builder
```

Professional engineers think:

```text
Next.js
        =
Rendering Engine
```

Its primary responsibilities are:

```text
✓ Routing

✓ Rendering

✓ Caching

✓ Streaming

✓ SEO

✓ Server Components

✓ Server Actions

✓ Performance
```

Notice what is missing:

```text
✗ Content editing

✗ Publishing workflows

✗ Content storage

✗ Revision history

✗ Editorial interfaces

✗ Media management
```

Those problems belong elsewhere.

---

# The Historical Solution: Traditional CMS

Historically, websites used systems like:

* WordPress
* Drupal
* Joomla

Their architecture looked like this:

```text
Editor
      ↓

CMS
      ↓

Database
      ↓

Templates
      ↓

HTML
      ↓

Browser
```

Everything lived inside one system:

```text
Content

Database

Templates

Frontend

Backend

Administration
```

This architecture is called:

```text
Monolithic CMS
```

---

# Why Monolithic CMS Became A Problem

Monolithic CMS systems work well initially.

But they introduce coupling.

For example:

```text
Content
       depends on
Presentation

Presentation
       depends on
CMS

CMS
       depends on
Templates
```

Eventually:

```text
Changing one thing
            changes
everything else
```

This limits:

```text
Scalability

Flexibility

Performance

Developer Experience
```

The industry needed something else.

---

# Enter The Headless CMS

A Headless CMS removes the presentation layer entirely.

Instead of:

```text
CMS
      +
Templates
      +
Frontend
```

we split the system:

```text
Content System
            +
Presentation System
```

Visually:

```text
Editors
        ↓

Content Platform
        ↓

API
        ↓

Frontend
        ↓

Browser
```

The CMS becomes responsible for:

```text
Creating content

Managing content

Versioning content

Publishing content

Serving content
```

The frontend becomes responsible for:

```text
Rendering

User experience

Performance

SEO

Caching

Interaction
```

---

# Why Is It Called "Headless"?

Traditional CMS:

```text
Database
     ↓

CMS
     ↓

Frontend
```

Headless CMS:

```text
Database
     ↓

CMS
```

The "head" (the frontend) has been removed.

You provide the head yourself.

For example:

```text
Sanity
       ↓

Next.js
```

Or:

```text
Sanity
       ↓

React Native
```

Or:

```text
Sanity
       ↓

iOS App
```

Or:

```text
Sanity
       ↓

Digital Signage
```

The content becomes independent of presentation.

---

# Why We're Choosing Sanity

There are many Headless CMS systems:

* Contentful
* Strapi
* Hygraph
* Directus
* Payload
* Sanity

For GreyMatter Journal, we're choosing:

```text
Sanity
```

because it aligns with how modern software systems are designed.

---

# What Makes Sanity Different?

Most CMS systems think:

```text
Pages

Posts

Tables

Records
```

Sanity thinks:

```text
Documents

Relationships

Schemas

Content Models
```

At its core lies something called the:

```text
Content Lake
```

---

# Understanding The Content Lake

The Content Lake is not merely a database.

It is a real-time, distributed document system.

Visually:

```text
Authors
        ↓

Categories
        ↓

Posts
        ↓

Images
        ↓

References
        ↓

Relationships
```

All stored as interconnected documents.

For example:

```text
Author
    ↑
    │
Post
    │
    ↓
Category
```

This allows:

```text
Normalization

Relationships

Reuse

Scalability

Real-time collaboration
```

---

# The Four Major Pieces Of Sanity

Sanity consists of four major systems.

---

## 1. Sanity Studio

The editor interface.

```text
Writers
      ↓

Sanity Studio
```

This is where content creators work.

---

## 2. Content Lake

The storage layer.

```text
Documents
      ↓

Relationships
      ↓

Storage
```

This is where content lives.

---

## 3. GROQ

The query language.

For example:

```groq
*[_type=="post"]{
  title,
  author->{
    name
  }
}
```

GROQ allows us to query content relationships naturally.

---

## 4. API Layer

The delivery mechanism.

```text
Content Lake
        ↓

API
        ↓

Next.js
```

This is how our application receives data.

---

# Our New Architecture

Before Sanity:

```text
Next.js
       ↓

Hardcoded Data
       ↓

Browser
```

After Sanity:

```text
Authors
        ↓

Sanity Studio
        ↓

Content Lake
        ↓

GROQ API
        ↓

Next.js
        ↓

React Server Components
        ↓

Browser
```

Notice what happened.

Our application became distributed.

---

# Why This Is Actually A Distributed System

Many people look at blogs and see:

```text
Website
```

Professional engineers increasingly see:

```text
Distributed Information System
```

Because we now have:

```text
Content Producers
        ↓

Content Platform
        ↓

API Layer
        ↓

Rendering Engine
        ↓

Caching Layer
        ↓

Browser
```

Each subsystem has independent responsibilities.

---

# Installing Sanity

Inside the GreyMatter Journal project, run:

```bash
npx sanity@latest init
```

You'll be asked several questions.

Choose:

```text
Project Name:
    GreyMatter Journal

Create New Project:
    Yes

Dataset:
    production

Output Path:
    studio

TypeScript:
    Yes
```

---

# What Did We Just Create?

Our repository now becomes:

```text
greymatter-journal/

├── app/
│
├── components/
│
├── lib/
│
├── studio/
│
└── package.json
```

Or, more conceptually:

```text
Reader Application
            +
Editorial Application
```

Visually:

```text
Next.js
        =
Reader Experience

Sanity
        =
Author Experience
```

---

# Why The `studio/` Folder Lives Beside `app/`

Many beginners expect:

```text
app/

    cms/

    admin/
```

Instead, we create:

```text
app/

studio/
```

This separation is intentional.

Because these are not merely folders.

They are different applications.

```text
Reader Application
            ↓

Editorial Application
```

They serve different users.

They solve different problems.

They evolve independently.

---

# The Correct Mental Model

Beginners think:

```text
Blog
      =
Website
```

Professional engineers think:

```text
Blog
      =

Content System

      +

Rendering System

      +

Caching System

      +

Distribution System
```

Or, more specifically:

```text
Sanity
       +
Next.js
       +
Caching
       +
CDN
```

---

# The Most Important Idea To Remember

Next.js is not replacing a CMS.

Sanity is not replacing a frontend.

Instead:

```text
Sanity
        owns

Content
```

while:

```text
Next.js
        owns

Experience
```

This separation is one of the most important architectural patterns in modern software engineering.

---

# Up Next — Part 8: Exploring Sanity Studio

Next, we'll enter the Sanity Studio itself and discover how content architects think differently from frontend engineers.

We'll learn:

* Schemas
* Documents
* Relationships
* Content modeling
* References
* Why data modeling is actually software architecture
