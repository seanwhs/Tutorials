# GreyMatter Journal

# Part 16 — Building Search and Filtering: Understanding Queries, Search Parameters, and Information Retrieval

> **Goal of this lesson:** Build search and filtering for GreyMatter Journal while learning how query languages work, how URL search parameters function, why databases perform filtering operations, and how modern search systems retrieve information.

---

# Our Blog Has A New Problem

Suppose GreyMatter Journal grows.

Today:

```text id="sq9w7k"
3 articles
```

Tomorrow:

```text id="5qq0s8"
30 articles
```

Eventually:

```text id="8iyby4"
300 articles
```

Or:

```text id="xmnvpf"
3000 articles
```

At that point, this becomes useless:

```text id="rqkrhj"
Latest Articles

Article
Article
Article
Article
Article
Article
...
```

Users need:

```text id="kwjqeq"
✓ Search
✓ Filtering
✓ Categories
✓ Navigation
```

---

# How Beginners Think Search Works

Most beginners imagine:

```text id="gnlggo"
Database
      ↓
Find Stuff
```

But search is actually a form of:

# Querying

A query simply means:

> Describe the information you want.

---

# Everyday Queries

Suppose I ask:

```text id="7q7f3j"
Find all books by Tolkien.
```

This is a query.

Suppose I ask:

```text id="7pwfif"
Find all articles about React.
```

Also a query.

Suppose I ask:

```text id="c7wd2d"
Find all posts written this year.
```

Again:

```text id="l9k1lj"
Query.
```

---

# Search Is Filtering

Suppose our database contains:

```text id="yo9t2d"
Post
Post
Post
Post
Post
```

Search performs:

```text id="g77j72"
Input Rule
      ↓
Filter
      ↓
Results
```

Diagram:

```text id="2i0s2w"
All Posts

      │
      ▼

Apply Rule

      │
      ▼

Matching Posts
```

---

# Step 1 — Create A Search Page

Create:

```text id="zjlwm1"
app/

search/

page.tsx
```

Add:

```tsx id="zjlwm2"
export default function
SearchPage() {
  return (
    <h1>
      Search
    </h1>
  );
}
```

Visit:

```text id="zjlwm3"
/search
```

---

# Step 2 — Add Search To Navigation

Open:

```text id="zjlwm4"
components/Navbar.tsx
```

Add:

```tsx id="zjlwm5"
<Link href="/search">
  Search
</Link>
```

---

# Building The Search Interface

Update:

```tsx id="zjlwm6"
export default function
SearchPage() {
  return (
    <>
      <h1>
        Search
      </h1>

      <form>
        <input
          type="text"
          name="q"
          placeholder="Search articles..."
        />

        <button>
          Search
        </button>
      </form>
    </>
  );
}
```

---

# Wait...

Why Did We Use `name="q"`?

Because HTML forms work by producing:

```text id="zjlwm7"
Key
   ↓
Value
```

Example:

```html id="zjlwm8"
<input
  name="q"
  value="react"
/>
```

becomes:

```text id="zjlwm9"
?q=react
```

---

# Understanding Query Strings

Suppose you search:

```text id="zjlwm10"
react
```

Your URL becomes:

```text id="zjlwm11"
/search?q=react
```

Diagram:

```text id="zjlwm12"
URL

/search?q=react

        │
        ▼

Route:
search

Parameter:
q=react
```

---

# Wait...

What Is The `?`

URLs contain multiple parts.

Example:

```text id="zjlwm13"
/search?q=react&page=2
```

Breakdown:

```text id="zjlwm14"
Path:
/search

Query Parameters:
q=react
page=2
```

---

# Why Put Search In The URL?

Bad approach:

```text id="zjlwm15"
Search State
       ↓
Browser Memory
```

Good approach:

```text id="zjlwm16"
Search State
       ↓
URL
```

Benefits:

```text id="zjlwm17"
✓ Bookmarkable
✓ Shareable
✓ Refresh-safe
✓ Browser history
```

---

# Step 3 — Reading Search Parameters

Update:

```tsx id="zjlwm18"
type Props = {
  searchParams: {
    q?: string;
  };
};

export default function
SearchPage({
  searchParams,
}: Props) {
  return (
    <pre>
      {JSON.stringify(
        searchParams,
        null,
        2
      )}
    </pre>
  );
}
```

Visit:

```text id="zjlwm19"
/search?q=react
```

You'll see:

```json id="zjlwm20"
{
  "q": "react"
}
```

---

# Wait...

Where Did This Come From?

Just like:

```text id="zjlwm21"
/posts/react
```

produced:

```json id="zjlwm22"
{
  "slug":
    "react"
}
```

query strings produce:

```json id="zjlwm23"
{
  "q":
    "react"
}
```

Diagram:

```text id="zjlwm24"
URL

        │

        ├── Path Params
        │
        └── Search Params
```

---

# Step 4 — Create The Search Query

Open:

```text id="zjlwm25"
lib/queries.ts
```

Add:

```typescript id="zjlwm26"
export const SEARCH_QUERY = `
  *[
    _type == "post" &&
    title match $search
  ]{
    _id,

    title,

    slug,

    excerpt,

    author->{
      name
    }
  }
`;
```

---

# Understanding `match`

Suppose:

```text id="zjlwm27"
React Server Components
```

Search:

```groq id="zjlwm28"
title match "React*"
```

matches:

```text id="zjlwm29"
✓ React Server Components
✓ React Hooks
✓ React Context
```

Diagram:

```text id="zjlwm30"
Database

      │
      ▼

Apply Pattern

      │
      ▼

Matches
```

---

# Step 5 — Execute The Search

Update:

```tsx id="zjlwm31"
import { client }
  from "@/lib/sanity";

import {
  SEARCH_QUERY,
} from "@/lib/queries";

type Props = {
  searchParams: {
    q?: string;
  };
};

export default async function
SearchPage({
  searchParams,
}: Props) {
  const query =
    searchParams.q ?? "";

  const posts =
    query
      ? await client.fetch(
          SEARCH_QUERY,
          {
            search:
              `${query}*`,
          }
        )
      : [];

  return (
    <>
      <h1>
        Search
      </h1>

      <form>
        <input
          name="q"
          defaultValue={query}
        />

        <button>
          Search
        </button>
      </form>

      <hr />

      {posts.map(post => (
        <article
          key={post._id}
        >
          {post.title}
        </article>
      ))}
    </>
  );
}
```

---

# Wait...

What Is This?

```typescript id="zjlwm32"
query
  ? resultA
  : resultB
```

This is the:

# Ternary Operator

Equivalent to:

```typescript id="zjlwm33"
if (query) {
  return resultA;
}

return resultB;
```

Think:

```text id="zjlwm34"
Condition
     ↓

True ?
     ↓

A : B
```

---

# Search Is Pattern Matching

Suppose:

```text id="zjlwm35"
React
```

Database:

```text id="zjlwm36"
React Server Components
React Hooks
Next.js
Node.js
```

Search performs:

```text id="zjlwm37"
Compare

Compare

Compare

Compare
```

Diagram:

```text id="zjlwm38"
Query
    │
    ▼

Pattern Matcher
    │
    ▼

Results
```

---

# Building Category Filtering

Suppose users want:

```text id="zjlwm39"
Show only:

Architecture
```

Create:

```text id="zjlwm40"
/articles?category=Architecture
```

---

# Add Another Query

Open:

```text id="zjlwm41"
lib/queries.ts
```

Add:

```typescript id="zjlwm42"
export const CATEGORY_QUERY = `
  *[
    _type == "post" &&
    $category in
      categories[]->title
  ]{
    title,
    slug
  }
`;
```

---

# Wait...

What Does `in` Mean?

Suppose:

```text id="zjlwm43"
Categories

Architecture
React
Next.js
```

Query:

```text id="zjlwm44"
Architecture
```

The database asks:

```text id="zjlwm45"
Is Architecture
inside this list?
```

Diagram:

```text id="zjlwm46"
List

A
B
C

      ▲

Find B
```

---

# What Is A Database Actually Doing?

Most beginners imagine:

```text id="zjlwm47"
Magic Search
```

But databases really perform:

```text id="zjlwm48"
Traversal

Filtering

Comparison

Projection

Sorting
```

Diagram:

```text id="zjlwm49"
Data

     │

     ▼

Filter

     │

     ▼

Sort

     │

     ▼

Project

     │

     ▼

Return
```

---

# Search Engines Work Similarly

Google performs:

```text id="zjlwm50"
Documents
      │
      ▼
Index
      │
      ▼
Search
      │
      ▼
Rank
      │
      ▼
Results
```

Sanity performs:

```text id="zjlwm51"
Documents
      │
      ▼
GROQ
      │
      ▼
Filter
      │
      ▼
Results
```

---

# The Hidden Architecture

Suppose a user searches:

```text id="zjlwm52"
react
```

The full pipeline becomes:

```text id="zjlwm53"
Browser
    │
    ▼

URL

/search?q=react

    │
    ▼

searchParams

    │
    ▼

GROQ Query

    │
    ▼

Sanity

    │
    ▼

Matching Documents

    │
    ▼

React Components

    │
    ▼

HTML
```

---

# Wait...

Does This Look Familiar?

We've already seen:

```text id="zjlwm54"
Route Tree

Portable Text Tree

React Tree

Layout Tree
```

Now we have:

```text id="zjlwm55"
Query Tree
```

Because every query is really:

```text id="zjlwm56"
Operations
      on
      structures
```

---

# Mental Model To Remember Forever

Beginners think:

```text id="zjlwm57"
Search
      =
Find Stuff
```

Modern systems think:

```text id="zjlwm58"
Search
      =
Describe
      +
Filter
      +
Transform
      +
Rank
```

Or even more generally:

```text id="zjlwm59"
Databases
        =
Machines
        For
        Traversing
        Data Structures
```

Understanding this principle unlocks databases, search engines, compilers, AI retrieval systems, and modern software architecture.

---

# Up Next

In **Part 17**, we'll add TypeScript properly to our data layer and learn:

* why `any` is dangerous,
* how to model content with interfaces,
* what type contracts actually are,
* how generics work,
* how TypeScript creates executable mental models,
* and why software engineering is fundamentally about constructing reliable abstractions.
