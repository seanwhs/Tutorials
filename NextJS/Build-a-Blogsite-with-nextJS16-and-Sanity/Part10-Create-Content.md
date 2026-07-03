# GreyMatter Journal

# Part 10 — Creating Our First Content: Understanding Documents, References, and Rich Text in Sanity

> **Goal of this lesson:** Create our first authors, categories, and posts in Sanity, understand document relationships, learn how references work, and render our first real content in Next.js 16.

---

# We Finally Have A CMS

At this point, we have built:

```text
✓ Next.js Application
✓ Sanity Studio
✓ Content Models
✓ Sanity Client
✓ API Connection
```

But our application still has one major problem.

Our database contains:

```text
Nothing.
```

This is actually a wonderful moment.

Because we now get to experience the single most important concept in content management systems:

> Content is data.

Not pages.

Not components.

Not HTML.

Just data.

---

# Let's Think Like Editors

Suppose you're the editor of GreyMatter Journal.

You want to publish:

```text
Understanding React Server Components
```

Before writing the article, you need:

```text
Who wrote it?

Which category does it belong to?

When was it published?
```

This immediately tells us:

```text
Post
   │
   ├── Author
   │
   └── Category
```

Content systems are really systems of relationships.

---

# Step 1 — Start The Studio

Open a terminal:

```bash
cd studio

npm run dev
```

Open:

```text
http://localhost:3333
```

You should now see:

```text
Posts
Authors
Categories
```

---

# Step 2 — Create Our First Author

Select:

```text
Authors
```

Create:

```text
Name:
Sean Wong
```

```text
Biography:
Software architect, educator, and writer
exploring software engineering,
distributed systems, and AI-era
development.
```

Upload an avatar image if desired.

Click:

```text
Publish
```

Congratulations.

You have created your first document.

---

# What Did Sanity Actually Store?

You entered:

```text
Name:
Sean Wong
```

But internally, Sanity created something like:

```json
{
  "_id": "author-abc123",
  "_type": "author",
  "name": "Sean Wong",
  "slug": {
    "current": "sean-wong"
  },
  "bio": "Software architect..."
}
```

Notice:

```text
You never created HTML.

You created data.
```

---

# Step 3 — Create Categories

Create:

```text
Architecture
```

Description:

```text
Software architecture and systems design.
```

---

Create:

```text
Web Development
```

Description:

```text
Modern web frameworks and frontend engineering.
```

---

Create:

```text
AI Engineering
```

Description:

```text
Engineering systems in the age of AI.
```

---

Internally:

```text
Category

├── Architecture
├── Web Development
└── AI Engineering
```

---

# Step 4 — Create Our First Post

Open:

```text
Posts
```

Create:

```text
Title:
Understanding React Server Components
```

Generate the slug:

```text
understanding-react-server-components
```

---

Add an excerpt:

```text
A beginner-friendly introduction
to React Server Components and
modern rendering architecture.
```

---

Select the author:

```text
Sean Wong
```

---

Select categories:

```text
Architecture
Web Development
```

---

Set:

```text
Published Date:
Today
```

---

# Understanding References

When you selected:

```text
Sean Wong
```

Sanity did NOT copy the author.

Instead it stored:

```json
{
  "author": {
    "_ref": "author-abc123"
  }
}
```

Diagram:

```text
Post
   │
   │ reference
   ▼
Author
```

Similarly:

```json
{
  "categories": [
    {
      "_ref": "category1"
    },
    {
      "_ref": "category2"
    }
  ]
}
```

Diagram:

```text
              Category

                  ▲
                  │
                  │

Post ─────────────┼────────────► Category
```

---

# Why References Matter

Imagine Sean writes 500 articles.

Bad design:

```text
Article 1
Author: Sean Wong

Article 2
Author: Sean Wong

Article 3
Author: Sean Wong
```

Good design:

```text
Author
    ▲
    │
    │
500 Articles
```

Benefits:

```text
✓ Less duplication
✓ Easier updates
✓ Better consistency
✓ Smaller storage
```

---

# Step 5 — Writing Rich Text

Now let's edit the body.

Write:

```text
React Server Components represent
one of the biggest architectural
changes in React history.
```

Add another paragraph:

```text
Instead of rendering everything
in the browser, components can
execute on the server.
```

Create a heading:

```text
Why Server Components Matter
```

Add:

```text
They allow developers to reduce
bundle sizes and improve
performance.
```

Publish the post.

---

# Wait... Where Did The HTML Go?

Many beginners expect:

```html
<h2>
  Why Server Components Matter
</h2>

<p>
  They allow developers...
</p>
```

But Sanity stores something else.

---

# Introducing Portable Text

Sanity stores rich text as structured data.

Example:

```json
[
  {
    "_type": "block",
    "style": "normal",
    "children": [
      {
        "text":
          "React Server Components represent..."
      }
    ]
  },

  {
    "_type": "block",
    "style": "h2",
    "children": [
      {
        "text":
          "Why Server Components Matter"
      }
    ]
  }
]
```

Diagram:

```text
Document

├── Paragraph
├── Paragraph
├── Heading
└── Paragraph
```

---

# Why Not Store HTML?

Traditional CMS:

```html
<h2>Heading</h2>
<p>Text</p>
```

Problem:

```text
HTML
     ↓
Website only
```

Portable Text:

```json
{
  "style": "h2",
  "text": "Heading"
}
```

Benefits:

```text
Website
Mobile App
RSS
API
Newsletter
AI
```

One content format.

Many outputs.

---

# Let's Query Our Content

Create:

```text
app/test/page.tsx
```

Update:

```tsx
import { client } from "@/lib/sanity";

export default async function TestPage() {
  const posts =
    await client.fetch(`
      *[_type == "post"]{
        title,
        slug,
        excerpt,
        publishedAt
      }
    `);

  return (
    <pre>
      {JSON.stringify(
        posts,
        null,
        2
      )}
    </pre>
  );
}
```

Visit:

```text
http://localhost:3000/test
```

You should see:

```json
[
  {
    "title":
      "Understanding React Server Components",

    "slug": {
      "current":
        "understanding-react-server-components"
    },

    "excerpt":
      "A beginner-friendly introduction...",

    "publishedAt":
      "2026-07-03T..."
  }
]
```

---

# Understanding GROQ Projections

Consider:

```groq
*[_type == "post"]
```

This means:

```text
Give me everything.
```

But:

```groq
*[_type == "post"]{
  title,
  excerpt
}
```

means:

```text
Give me only these fields.
```

Diagram:

```text
Document

├── title
├── body
├── author
├── category
├── image
└── date

        ↓

Projection

├── title
└── date
```

---

# Resolving References

Our current query returns:

```json
{
  "author": {
    "_ref": "abc123"
  }
}
```

That's not very useful.

GROQ can follow references.

Example:

```groq
*[_type == "post"]{
  title,

  author->{
    name
  }
}
```

Notice:

```text
->
```

This means:

```text
Follow the reference.
```

Diagram:

```text
Post
   │
   ▼
Author Reference
   │
   ▼
Author Document
```

---

# Let's Fetch Real Data

Update:

```tsx
import { client } from "@/lib/sanity";

export default async function TestPage() {
  const posts =
    await client.fetch(`
      *[_type == "post"]{
        title,

        excerpt,

        author->{
          name
        },

        categories[]->{
          title
        }
      }
    `);

  return (
    <pre>
      {JSON.stringify(
        posts,
        null,
        2
      )}
    </pre>
  );
}
```

Now you'll see:

```json
[
  {
    "title":
      "Understanding React Server Components",

    "excerpt":
      "...",

    "author": {
      "name":
        "Sean Wong"
    },

    "categories": [
      {
        "title":
          "Architecture"
      },
      {
        "title":
          "Web Development"
      }
    ]
  }
]
```

---

# What Just Happened?

We traversed a graph.

Diagram:

```text
                 Category

                     ▲
                     │
                     │

Post ───────────────► Author
```

This is why GROQ stands for:

```text
Graph-Oriented Query Language
```

---

# Our System Is Finally Alive

We now have:

```text
Editor
   │
   ▼
Sanity Studio
   │
   ▼
Content Lake
   │
   ▼
GROQ
   │
   ▼
Next.js Server Component
   │
   ▼
Browser
```

And for the first time:

```text
Real Content
       ↓
Real Data
       ↓
Real Rendering
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Blog Post
      =
HTML Page
```

Modern systems think:

```text
Blog Post
      =
Document
      +
Relationships
      +
Metadata
```

Or more generally:

```text
Content
      =
Structured Data
```

Everything else is presentation.

---

# Up Next

In **Part 11**, we'll build our first real blog homepage and learn:

* how Server Components fetch data,
* why `await` works inside React components,
* how to render lists of posts,
* what the `key` prop actually does,
* and why React components are really functions that describe user interfaces.
