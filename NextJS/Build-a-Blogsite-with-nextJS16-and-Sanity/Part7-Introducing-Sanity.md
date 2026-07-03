# GreyMatter Journal

# Part 7 — Introducing Sanity: Why Next.js Doesn't Store Your Blog Posts

> **Goal of this lesson:** Understand what a Headless CMS actually is, what the Sanity Content Lake is, why Next.js doesn't manage content, and what `npx sanity@latest init` actually creates.

---

# We Have A Website But We Have A Problem

At this point, GreyMatter Journal works.

We have:

```text
Next.js
    +
Layouts
    +
Pages
    +
Navigation
```

But imagine you want to publish an article.

Where do you put it?

Perhaps you think:

```tsx
export default function ArticlePage() {
  return (
    <>
      <h1>Understanding React</h1>

      <p>
        React is a JavaScript library...
      </p>
    </>
  );
}
```

This works.

Until you need:

* 10 articles,
* 100 articles,
* 1000 articles,
* multiple authors,
* editors,
* categories,
* draft previews,
* scheduled publishing.

Then this approach becomes impossible.

---

# The First Mistake Beginners Make

Most beginners imagine:

```text
Next.js
      ↓
stores
      ↓
blog posts
```

But Next.js doesn't store anything.

Next.js is:

```text
Rendering Engine
```

Its job is:

```text
Fetch data
       ↓
Render UI
       ↓
Send HTML
```

That's all.

---

# Think About Netflix

Suppose someone asks:

> Does Netflix store movies in the user interface?

Of course not.

Instead:

```text
Movie Database
        ↓
Netflix Application
        ↓
Television
```

Similarly:

```text
Content Storage
        ↓
Next.js
        ↓
Browser
```

The frontend doesn't own the content.

It merely displays the content.

---

# Traditional CMS Thinking

Historically, systems like WordPress looked like this:

```text
WordPress

├── Editor
├── Database
├── Themes
├── Plugins
└── Website
```

Diagram:

```text
            User
              │
              ▼
        ┌────────────┐
        │ WordPress  │
        ├────────────┤
        │ Database   │
        │ Editor     │
        │ Frontend   │
        └────────────┘
```

Everything lived inside one application.

---

# Why This Became A Problem

Suppose your editor writes:

```text
How Server Components Work
```

Now suppose you want to publish this content to:

* website,
* mobile app,
* newsletter,
* RSS feed,
* API,
* smart TV app.

Traditional CMS systems assume:

```text
Content
      ↓
HTML Website
```

But modern businesses require:

```text
Content
      ↓
Everywhere
```

---

# The Idea That Changed Everything

Eventually developers realized:

> Content management and content presentation are different problems.

Instead of:

```text
CMS

├── Content
├── Database
└── Website
```

we can separate them:

```text
CMS
     ↓
API
     ↓
Frontend
```

This became known as:

# Headless CMS

---

# Why Is It Called "Headless"?

Imagine a restaurant.

Traditional restaurant:

```text
Kitchen
Dining Room
Waiters
Menu
Cashier
```

Everything is connected.

A headless restaurant would provide only:

```text
Kitchen
```

Someone else decides:

* how food is delivered,
* where food is displayed,
* how customers consume it.

A Headless CMS works the same way.

---

# What Does A Headless CMS Actually Do?

A Headless CMS performs three jobs:

```text
Create content
        ↓
Store content
        ↓
Expose content via API
```

That's all.

It does not care about:

* React,
* Next.js,
* Vue,
* mobile apps,
* websites.

---

# Enter Sanity

Sanity is a modern Headless CMS.

Its job is:

```text
Editor
      ↓
Content
      ↓
API
```

Diagram:

```text
          Writers
              │
              ▼
      ┌──────────────┐
      │ Sanity Studio│
      └──────┬───────┘
             │
             ▼
      ┌──────────────┐
      │ Content Lake │
      └──────┬───────┘
             │
             ▼
            API
```

---

# What Is Sanity Studio?

Sanity Studio is simply an application for editors.

Example:

```text
New Article

Title:
Understanding Server Components

Author:
Sean Wong

Category:
Architecture

Body:
...
```

Editors use Studio.

Readers never see Studio.

---

# Where Does The Data Go?

This is where Sanity becomes interesting.

Traditional databases store tables:

```text
posts

id
title
body
author_id
```

Sanity stores documents.

Example:

```json
{
  "_type": "post",
  "title": "Understanding Server Components",
  "slug": "understanding-server-components",
  "author": {
    "_ref": "author123"
  }
}
```

Another document:

```json
{
  "_type": "author",
  "name": "Sean Wong"
}
```

---

# What Is The Content Lake?

Sanity calls its database:

# Content Lake

Think of it as:

```text
Database
      +
Document Store
      +
Search Engine
      +
Relationship Engine
      +
API
```

Diagram:

```text
             Content Lake

        ┌───────────────┐
        │ Posts         │
        │ Authors       │
        │ Categories    │
        │ Images        │
        │ References    │
        └───────────────┘
```

---

# Why Not Use PostgreSQL?

You absolutely can.

But then you must build:

```text
Database Schema
        +
Admin Dashboard
        +
Editor Experience
        +
Authentication
        +
Media Upload
        +
Relationships
        +
Search
        +
API
        +
Preview System
```

Sanity already provides these.

---

# So What Does Next.js Actually Do?

Our architecture now becomes:

```text
Sanity
      ↓
API
      ↓
Next.js
      ↓
Browser
```

Or more specifically:

```text
Editor
      ↓
Sanity Studio
      ↓
Content Lake
      ↓
GROQ API
      ↓
Next.js
      ↓
React
      ↓
Browser
```

---

# What Is GROQ?

Sanity provides its own query language called:

```text
GROQ
```

(GRaph-ORiented Query Language)

Suppose we want all posts.

We write:

```groq
*[_type == "post"]
```

Suppose we want one post:

```groq
*[
  _type == "post" &&
  slug.current == $slug
][0]
```

Suppose we want all authors:

```groq
*[_type == "author"]
```

Think of GROQ as:

```text
SQL
     ↓
for documents
```

---

# Our Future Architecture

By the end of this series, GreyMatter Journal will look like this:

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
                   GROQ
                     │
                     ▼
             ┌────────────────┐
             │ Next.js 16     │
             │ Server Comp.   │
             └───────┬────────┘
                     │
                     ▼
                 Browser
```

Notice something important:

```text
Next.js never stores content.

Sanity never renders content.
```

Each system has one responsibility.

---

# Finally, Let's Install Sanity

Open a new terminal.

Make sure you're inside:

```bash
greymatter-journal
```

Then execute:

```bash
npx sanity@latest init
```

---

# What Does This Command Actually Do?

Many tutorials simply tell you:

```bash
npx sanity@latest init
```

without explaining anything.

Internally, Sanity performs:

```text
Create/Select Project
           ↓
Create Dataset
           ↓
Create Content Lake
           ↓
Generate Studio
           ↓
Generate Schemas
           ↓
Configure TypeScript
           ↓
Install Dependencies
```

Diagram:

```text
npx sanity@latest init

            │
            ▼

     Create Project
            │
            ▼

     Create Dataset
            │
            ▼

      Create Studio
            │
            ▼

   Connect Content Lake
```

---

# Recommended Installation Choices

When prompted, select:

```text
Project Name:
GreyMatter Journal
```

---

```text
Use existing project?
```

Select:

```text
No
```

---

```text
Dataset?
```

Select:

```text
production
```

---

```text
Output path?
```

Enter:

```text
studio
```

This creates:

```text
greymatter-journal/

app/
public/
studio/
```

---

```text
Use TypeScript?
```

Select:

```text
Yes
```

---

# What Did We Just Create?

We now have:

```text
greymatter-journal/

app/
     ↓
Reader Application

studio/
       ↓
Writer Application
```

This is one of the biggest architectural ideas in modern web development:

```text
Content Management
            ≠
Content Presentation
```

---

# Mental Model To Remember Forever

Most beginners think:

```text
Blog
    ↓
Website
```

Modern systems think:

```text
Content System
        +
Rendering System
```

For GreyMatter Journal:

```text
Sanity
      +
Next.js
```

Or more precisely:

```text
Sanity creates content.

Next.js presents content.
```

---

# Up Next

In **Part 8**, we'll explore what `npx sanity@latest init` actually created and learn:

* what the `studio` folder is,
* what schemas are,
* why content modeling matters,
* how editors think differently from developers,
* and why designing your content model is actually designing your business model.
