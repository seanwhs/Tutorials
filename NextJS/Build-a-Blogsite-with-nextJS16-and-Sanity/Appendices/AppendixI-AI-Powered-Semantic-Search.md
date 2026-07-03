# Appendix I — Building AI-Powered Semantic Search for GreyMatter Journal: Embeddings, Vector Databases, and Meaning Retrieval

> **Goal of this appendix:** Build an AI-powered semantic search system for GreyMatter Journal while learning how embeddings, vector search, retrieval systems, and modern AI information architectures work.

---

# Introduction

Traditional search engines answer the question:

> "What words did you type?"

AI-powered search engines answer a different question:

> "What did you mean?"

This distinction may appear subtle.

It is not.

In fact, it represents one of the largest paradigm shifts in information retrieval since the invention of search engines.

---

# Traditional Search

Suppose a user searches:

```text id="a8q3m1"
nextjs caching
```

Traditional search engines perform:

```text id="b4v7k2"
Find documents
containing:

nextjs

and

caching
```

Example:

```text id="c9m2q5"
Article:
"Next.js Cache
Architecture"
```

Success.

---

# The Problem

Suppose the user searches:

```text id="d6v1k9"
why doesn't my page update
```

But our article title is:

```text id="e3m8q4"
Understanding
Revalidation
in Next.js
```

Traditional search:

```text id="f7k2v6"
No match.
```

Even though:

```text id="g4m9q1"
The meanings
are identical.
```

---

# Semantic Search

Semantic search asks:

```text id="h1v5k8"
What idea
does this represent?
```

instead of:

```text id="i8m2q3"
What words
does this contain?
```

---

# The Fundamental Idea

Suppose we convert text into numbers.

Example:

```text id="j5k7v4"
React Hooks
```

becomes:

```text id="k2m9q6"
[
  0.18,
  -0.44,
  0.91,
  ...
]
```

Similarly:

```text id="l7v4k2"
useEffect tutorial
```

becomes:

```text id="m4q8v9"
[
  0.19,
  -0.42,
  0.93,
  ...
]
```

Notice:

```text id="n1k6m3"
The vectors
are similar.
```

---

# What Is An Embedding?

An embedding is:

```text id="o8v2q5"
A numerical
representation
of meaning.
```

Diagram:

```text id="p4m7k9"
Text
   │
   ▼

AI Model
   │
   ▼

Vector
```

---

# Example

Sentence:

```text id="q9v1m4"
How caching works
in Next.js
```

Embedding:

```text id="r6k3q8"
[
  0.132,
  -0.847,
  0.291,
  ...
]
```

---

# Why Does This Work?

Because AI models learn:

```text id="s2m5v7"
Statistical
relationships
between ideas.
```

Example:

```text id="t8k4q1"
React

JavaScript

Components
```

appear together frequently.

Therefore:

```text id="u5v9m2"
Their vectors
become nearby.
```

---

# The Semantic Space

Imagine:

```text id="v1k7q4"
React
```

exists here:

```text id="w8m2v6"
(x,y,z)
```

and:

```text id="x4q9k1"
Next.js
```

exists nearby.

Diagram:

```text id="y7v3m5"
          React

             •

                 •

            Next.js

      Vue

          •

Angular
```

Nearby means:

```text id="z2k8q7"
Similar meaning.
```

---

# Our Architecture

GreyMatter Journal will use:

```text id="a6m1v9"
Sanity
   │
   ▼

Articles
   │
   ▼

Embedding Model
   │
   ▼

Vectors
   │
   ▼

Vector Database
   │
   ▼

Semantic Search
```

---

# Choosing A Vector Database

Popular options:

```text id="b3k7q2"
Pinecone

Upstash Vector

Weaviate

Qdrant

pgvector
```

For GreyMatter Journal, we'll use:

```text id="c8m4v5"
Upstash Vector
```

because it integrates well with:

```text id="d5q9k8"
Next.js
and
Vercel.
```

---

# Install Dependencies

```bash id="e1v6m3"
npm install
@upstash/vector
openai
```

---

# Create Vector Index

Create:

```text id="f7k2q9"
lib/vector.ts
```

```typescript id="g4m8v1"
import {
  Index,
} from
"@upstash/vector";

export const vector =
  new Index({

    url:
      process.env
      .UPSTASH_URL!,

    token:
      process.env
      .UPSTASH_TOKEN!,
  });
```

---

# Generate Embeddings

Create:

```text id="h9q3k6"
lib/embedding.ts
```

```typescript id="i6v1m8"
import OpenAI
from "openai";

const client =
  new OpenAI({
    apiKey:
      process.env
      .OPENAI_API_KEY,
  });
```

---

# Create Embedding Function

```typescript id="j2m7q4"
export async function
createEmbedding(
  text: string
) {

  const response =
    await client
      .embeddings
      .create({

        model:
          "text-embedding-3-small",

        input:
          text,
      });

  return response
    .data[0]
    .embedding;
}
```

---

# Wait...

What Is Happening?

We transform:

```text id="k8v5m2"
Human Meaning
```

into:

```text id="l4q1k7"
Mathematical Space.
```

---

# Create Search Index

Suppose we have:

```text id="m1v9q3"
Title

Excerpt

Body
```

Combine:

```typescript id="n7m4v8"
const text = `
${post.title}

${post.excerpt}

${post.body}
`;
```

Generate:

```typescript id="o3q8k5"
const embedding =
  await createEmbedding(
    text
  );
```

---

# Store Vector

```typescript id="p9v2m1"
await vector.upsert({

  id:
    post._id,

  vector:
    embedding,

  metadata: {

    title:
      post.title,

    slug:
      post.slug
        .current,
  },
});
```

---

# Similarity Search

User enters:

```text id="q5k7v4"
why won't
my cache refresh
```

Create embedding:

```typescript id="r2m8q6"
const query =
  await createEmbedding(
    search
  );
```

Search:

```typescript id="s8v1k3"
const results =
  await vector.query({

    vector:
      query,

    topK: 10,
  });
```

---

# What Happens?

Diagram:

```text id="t4q9m7"
Query Vector
      │
      ▼

Compare
against
all vectors
      │
      ▼

Find nearest
neighbors
      │
      ▼

Return results
```

---

# Distance Metrics

Vector databases compare using:

```text id="u1v5k2"
Cosine Similarity

Euclidean Distance

Dot Product
```

Most semantic systems use:

```text id="v7m3q9"
Cosine Similarity.
```

---

# Cosine Similarity

Imagine:

```text id="w3k8v1"
Two arrows.
```

Diagram:

```text id="x9m2q4"
      /

     /

    /

---/
```

Smaller angle:

```text id="y6v4k8"
More similar.
```

---

# Semantic Search API

Create:

```text id="z2m7q5"
app/api/search/route.ts
```

```typescript id="a8v1m9"
export async function
POST(
  request:
    Request
) {

  const {
    query,
  } =
    await request.json();

  const embedding =
    await createEmbedding(
      query
    );

  const results =
    await vector.query({

      vector:
        embedding,

      topK: 10,
    });

  return Response
    .json(
      results
    );
}
```

---

# Search Component

```tsx id="b5m4q2"
"use client";

export default function
Search() {

  async function
  handleSearch(
    query:
      string
  ) {

    const response =
      await fetch(
        "/api/search",
        {
          method:
            "POST",

          body:
            JSON.stringify({
              query,
            }),
        }
      );

    return response
      .json();
  }
}
```

---

# Hybrid Search

Professional search engines combine:

```text id="c1v8k7"
Keyword Search

+

Semantic Search
```

Example:

```text id="d7m2q3"
React Suspense
```

Results:

```text id="e4v9k5"
50%
keyword

50%
semantic
```

---

# Why?

Keyword search finds:

```text id="f9q4m1"
Exact matches.
```

Semantic search finds:

```text id="g6v1k8"
Meaning matches.
```

Together:

```text id="h2m7q4"
Better results.
```

---

# Retrieval Augmented Generation

Once we have semantic search:

```text id="i8v5k9"
Search
```

becomes:

```text id="j4q2m6"
Retrieval.
```

And retrieval enables:

```text id="k1m8v3"
RAG.
```

---

# Example

User asks:

```text id="l7q4k5"
Explain
Next.js caching.
```

System:

```text id="m3v9k2"
Find Articles
       │
       ▼

Retrieve Content
       │
       ▼

Provide Context
       │
       ▼

Generate Answer
```

---

# Suddenly...

GreyMatter Journal becomes:

```text id="n9m1q8"
An AI
knowledge system.
```

---

# The Hidden Architecture

When a user searches:

```text id="o5v7k4"
why does my
page not update
```

the system becomes:

```text id="p2m4q9"
Browser
    │
    ▼

Search API
    │
    ▼

Embedding Model
    │
    ▼

Vector Database
    │
    ▼

Nearest Neighbor
Search
    │
    ▼

Articles
    │
    ▼

Results
```

---

# Wait...

Does This Look Familiar?

We've discovered:

```text id="q8v1k6"
State Trees

Trust Trees

Identity Trees

Failure Trees

Execution Trees

Cache Trees

Knowledge Trees

Time Trees
```

Semantic search introduces:

```text id="r4m7q2"
Meaning Trees
```

because every search engine ultimately asks:

```text id="s1v9k5"
Which ideas
are related
to other ideas?
```

---

# The Deep Secret Of Search

Most beginners think:

```text id="t7m2q8"
Search
      =
Finding Words
```

Professional engineers think:

```text id="u3v8k4"
Search
      =
Finding Meaning
```

---

# The Deep Secret Of AI

Modern AI systems do not truly understand:

```text id="v9q5m1"
Reality.
```

Instead, they construct:

```text id="w6m1k7"
Mathematical
representations
of meaning.
```

---

# Mental Model To Remember Forever

Beginners think:

```text id="x2v7q3"
Knowledge
         =
Documents
```

Professional engineers think:

```text id="y8m4k9"
Knowledge
         =
Relationships
         between
         ideas
```

Semantic search reveals one of the deepest truths in computer science:

```text id="z4q1m6"
Intelligence
is not merely
storing information.

Intelligence
is discovering
which pieces
of information
belong together.
```
