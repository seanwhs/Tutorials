# **✅ Part 10 — Creating Our First Content**

<img width="1200" height="675" alt="image" src="https://github.com/user-attachments/assets/d7761981-266c-4de7-8daa-a15c636f639c" />


# GreyMatter Journal

## Part 10 — Creating Our First Content: Documents, References, and Portable Text in Sanity

> **Goal of this lesson:** Populate the Sanity Content Lake with real content, understand how documents and references work, and discover why modern content systems store structured data instead of HTML pages.

---

# The Moment of Truth

Up until now, we've built infrastructure.

We have:

```text
✓ Next.js application
✓ Application layouts
✓ Sanity Studio
✓ Content schemas
✓ API integration
✓ Sanity client
✓ GROQ queries
```

But we still have one major problem:

```text
No content.
```

Our architecture currently looks like this:

```text
Editor
      ↓

Sanity Studio
      ↓

Content Lake

      =

(empty)
```

Today, for the first time, we'll create real content and watch it travel through our entire system.

---

# Start the Studio

Open your Sanity Studio:

```bash
cd studio
npm run dev
```

Visit:

```text
http://localhost:3333
```

You should see something similar to:

```text
Content

├── Posts
├── Authors
└── Categories
```

Congratulations.

You now have your own content management system.

---

# Content Comes Before Pages

Many beginners think:

```text
Page
     ↓
Content
```

Professional content systems work in the opposite direction:

```text
Content
      ↓
Pages
```

Why?

Because content may eventually appear in:

```text
Website

Mobile App

RSS Feed

Email Newsletter

Search Results

AI Systems

Future Platforms
```

This is why modern CMS systems store:

```text
Structured Content
```

rather than:

```text
HTML Pages
```

---

# Step 1 — Create Your First Author

Open:

```text
Authors
```

Create:

```text
Name:
    Sean Wong

Bio:
    Software engineer,
    architect,
    educator,
    and systems thinker.

Image:
    Upload a profile photo
    (optional)
```

Then click:

```text
Publish
```

---

# What Did Sanity Actually Create?

Many beginners think:

```text
Author Page
```

was created.

It wasn't.

Sanity created a document:

```json
{
  "_type": "author",

  "name":
    "Sean Wong",

  "bio":
    "Software engineer...",
}
```

Think of it as:

```text
Database Record
```

rather than:

```text
Web Page
```

---

# Step 2 — Create Categories

Create several categories:

```text
Architecture
```

Description:

```text
Systems design and
software architecture
```

---

```text
Web Development
```

Description:

```text
Modern frontend
engineering
```

---

```text
AI Engineering
```

Description:

```text
Building systems
in the age of AI
```

After publishing, your Content Lake contains:

```text
Author
     ↓

Categories
```

---

# Understanding Documents

Sanity stores information as documents.

For example:

```text
Author
```

is a document.

```text
Category
```

is a document.

```text
Post
```

is a document.

Visually:

```text
Content Lake

    Author

    Category

    Category

    Category

    Post

    Post
```

Think of documents as:

```text
Objects
```

stored in a giant distributed database.

---

# Step 3 — Create Your First Post

Create:

```text
Title:
    Understanding
    React Server Components
```

Generate:

```text
Slug:
    understanding-react-server-components
```

Add:

```text
Excerpt:
    A beginner-friendly
    introduction to
    React Server Components.
```

Select:

```text
Author:
    Sean Wong
```

Select categories:

```text
Architecture

Web Development
```

Add:

```text
Published Date:
    Today
```

Upload:

```text
Hero Image
```

---

# The Most Important Field: Body

The body field is where something interesting happens.

Instead of writing:

```html
<h1>Hello</h1>

<p>World</p>
```

Sanity stores something called:

```text
Portable Text
```

---

# What Is Portable Text?

Many beginners think:

```text
Rich Text
      =
HTML
```

Professional systems think:

```text
Rich Text
      =
Structured Data
```

Suppose you write:

```markdown
# React Server Components

React Server Components
allow rendering on
the server.
```

Sanity stores something more like:

```json
[
  {
    "_type": "block",
    "style": "h1",
    "children": [
      {
        "text":
          "React Server Components"
      }
    ]
  },
  {
    "_type": "block",
    "style": "normal",
    "children": [
      {
        "text":
          "React Server Components allow rendering on the server."
      }
    ]
  }
]
```

Notice:

```text
No HTML
```

Instead, we have:

```text
Structured content
```

---

# Why Not Store HTML?

HTML describes:

```text
Presentation
```

Portable Text describes:

```text
Meaning
```

For example:

```text
Heading

Paragraph

List

Quote

Code Block
```

This means the same content can be rendered as:

```text
Website

Mobile App

RSS

PDF

Email

AI Context
```

without rewriting it.

---

# Understanding References

When you selected:

```text
Author:
    Sean Wong
```

did Sanity copy the author?

No.

Instead, it stored:

```json
{
  "_ref":
    "author-123"
}
```

Likewise:

```text
Categories
```

become:

```json
[
  {
    "_ref":
      "category-1"
  },
  {
    "_ref":
      "category-2"
  }
]
```

This is called:

```text
Normalization
```

---

# Visualizing References

Our data model now looks like:

```text
                Post
                  |
          ----------------
          |              |
          |              |
       Author       Categories
```

More specifically:

```text
Post
    ↓
Author

Post
    ↓
Category

Post
    ↓
Category
```

This gives us:

```text
✓ No duplication
✓ Better consistency
✓ Better scalability
✓ Better querying
```

---

# What Actually Exists In The Content Lake?

After publishing, Sanity contains something conceptually similar to:

```text
Document

    Author
        Sean Wong

Document

    Category
        Architecture

Document

    Category
        Web Development

Document

    Post
        Understanding
        React Server Components
```

Notice:

```text
No web pages exist.
```

Only documents.

---

# Querying The Content

Let's verify everything works.

Update:

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
    await client.fetch(`
      *[_type=="post"]{
        title,
        slug,
        excerpt,
        publishedAt,

        author->{
          name
        },

        categories[]->{
          title
        }
      }
    `);

  return (
    <div
      className="
        mx-auto
        max-w-4xl
        p-8
      "
    >
      <h1
        className="
          mb-8
          text-3xl
          font-bold
        "
      >
        Content Test
      </h1>

      <pre
        className="
          overflow-auto
          rounded-xl
          bg-gray-900
          p-6
          text-sm
          text-gray-100
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

You should now see real content.

---

# Understanding GROQ Projections

This query:

```groq
*[_type=="post"]{
    title,
    slug,

    author->{
        name
    },

    categories[]->{
        title
    }
}
```

does several things simultaneously:

```text
Find Posts
        ↓

Select Fields
        ↓

Follow Author
        ↓

Follow Categories
        ↓

Construct New Object
```

GROQ doesn't return database rows.

It returns exactly the shape your application needs.

---

# Visualizing The Entire System

Our architecture now finally works end-to-end:

```text
Writer
      ↓

Sanity Studio
      ↓

Post Document
      ↓

Content Lake
      ↓

GROQ Query
      ↓

Sanity API
      ↓

Next.js
      ↓

React Server Components
      ↓

Browser
```

For the first time:

```text
Content
      ↓

Data
      ↓

UI
```

is fully operational.

---

# The Correct Mental Model

Beginners think:

```text
Blog Post
        =
HTML Page
```

Professional engineers think:

```text
Blog Post
        =
Document
        +
Relationships
        +
Structured Content
        +
Metadata
```

Or even more fundamentally:

```text
Content
        ≠
Presentation
```

Instead:

```text
Content
        ↓

Transformation
        ↓

Presentation
```

---

# The Most Important Idea To Remember

When you publish a post in Sanity:

You are not creating:

```text
A webpage
```

You are creating:

```text
Structured knowledge
```

The frontend's responsibility is simply to transform that knowledge into user experiences.

Modern content systems are not page builders.

They are knowledge management systems.

---

# Up Next — Part 11: Building the Homepage

Next, we'll finally replace our placeholder homepage and build our first real feature:

```text
Content Lake
        ↓

GROQ Query
        ↓

Server Component
        ↓

Post Cards
        ↓

Homepage
```

We'll learn:

* Fetching data in Server Components
* Building reusable Post Cards
* Rendering lists
* Server-side data fetching
* Component composition
* Why React components are really UI functions
