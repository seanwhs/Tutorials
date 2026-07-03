# Appendix K — SEO, Metadata, OpenGraph, RSS, and Discoverability: Teaching Computers What Your Website Means

> **Goal of this appendix:** Transform GreyMatter Journal from a website that humans can read into a website that computers can understand by mastering SEO, metadata, structured data, OpenGraph, RSS, sitemaps, and the deeper principles of discoverability.

---

# Introduction

Most beginners think:

> "I built a website."

Unfortunately, this is only partially true.

Because modern websites actually have:

```text id="a1k8m3"
Two audiences.
```

---

# Audience #1

```text id="b4v2q7"
Humans
```

Examples:

```text id="c9m5k1"
Readers

Authors

Editors

Visitors
```

---

# Audience #2

```text id="d7q3v8"
Machines
```

Examples:

```text id="e2m9k4"
Google

Bing

ChatGPT

Claude

Gemini

Facebook

Twitter

RSS Readers

Search Crawlers
```

---

# The Hidden Question

When Google visits your site, it cannot ask:

> "What does this page mean?"

Instead, you must explain:

```text id="f6v1k9"
Meaning
using
metadata.
```

---

# What Is Metadata?

Metadata means:

```text id="g3m7q2"
Data
about
data.
```

Example:

```text id="h8v4k5"
Article:
How Caching Works
```

Metadata:

```text id="i4m1q7"
Title

Description

Author

Keywords

Published Date
```

---

# The Mental Model

Think of metadata as:

```text id="j9k2v6"
A passport
for content.
```

Humans can read:

```text id="k5v8m1"
The article.
```

Computers read:

```text id="l2m4q9"
The passport.
```

---

# Metadata In Next.js

Create:

```typescript id="m7v1k3"
export const metadata = {

  title:
    "GreyMatter Journal",

  description:
    "Architecture,
     engineering,
     and AI.",

};
```

---

# Why Static Metadata?

This generates:

```html id="n3q8m5"
<title>
GreyMatter Journal
</title>

<meta
  name="description"
/>
```

which search engines understand.

---

# Dynamic Metadata

Blog posts require:

```text id="o8v2k1"
Dynamic metadata.
```

Example:

```typescript id="p4m9q6"
export async function
generateMetadata({

  params,
}) {

  const post =
    await getPost(
      params.slug
    );

  return {

    title:
      post.title,

    description:
      post.excerpt,
  };
}
```

---

# What Happens?

Request:

```text id="q9m4k7"
/posts/nextjs-cache
```

produces:

```html id="r5v1m3"
<title>
Understanding
Next.js Caching
</title>
```

automatically.

---

# OpenGraph

When you paste a link:

```text id="s1q8k4"
https://greymatter.dev
```

into:

```text id="t6v2m9"
WhatsApp

LinkedIn

Facebook

Discord
```

you see:

```text id="u3m7q1"
Image

Title

Description
```

This is:

```text id="v8k5m6"
OpenGraph.
```

---

# Example

```typescript id="w4v9q2"
export const metadata = {

  openGraph: {

    title:
      "GreyMatter Journal",

    description:
      "Engineering
       and AI",

    images: [
      "/og.png",
    ],
  },
};
```

---

# Generated HTML

```html id="x9m1k7"
<meta
  property="og:title"
/>

<meta
  property="og:description"
/>

<meta
  property="og:image"
/>
```

---

# Twitter Cards

Twitter (X) uses:

```typescript id="y5v4m8"
twitter: {

  card:
    "summary_large_image",

  title:
    "GreyMatter Journal",

}
```

Result:

```text id="z2q7m1"
Large preview card.
```

---

# Dynamic OpenGraph Images

Next.js can generate images:

```text id="a7m3k9"
At runtime.
```

Create:

```text id="b3v8q5"
app/opengraph-image.tsx
```

---

# Example

```tsx id="c8m2v4"
import {
  ImageResponse,
} from
"next/og";

export const size = {
  width: 1200,
  height: 630,
};

export default function
Image() {

  return new
    ImageResponse(

      <div>
        GreyMatter
        Journal
      </div>
  );
}
```

---

# Why?

Instead of:

```text id="d4q9m2"
One image
```

we can create:

```text id="e1v5k8"
One image
per article.
```

---

# Example

```text id="f7m4q3"
How Server
Actions Work
```

becomes:

```text id="g2v8k6"
Generated
social image.
```

---

# Canonical URLs

Suppose:

```text id="h9m1q4"
/posts/react

/posts/react/

?page=1
```

all exist.

Google sees:

```text id="i6v3k9"
Duplicate content.
```

---

# Solution

```typescript id="j3m7q5"
alternates: {

  canonical:
    "/posts/react",

}
```

---

# Robots

Create:

```text id="k8v2m1"
app/robots.ts
```

```typescript id="l4q9k7"
export default
function robots() {

  return {

    rules: {

      userAgent:
        "*",

      allow:
        "/",
    },

    sitemap:
      "/sitemap.xml",
  };
}
```

---

# Why?

Robots tell crawlers:

```text id="m1v6q3"
What can
be indexed.
```

---

# Sitemap

Create:

```text id="n7m2k8"
app/sitemap.ts
```

---

# Example

```typescript id="o4v9m5"
export default
async function
sitemap() {

  const posts =
    await getPosts();

  return posts.map(
    post => ({

      url:
        `https://
        greymatter.dev/
        posts/${
          post.slug
            .current
        }`,
    })
  );
}
```

---

# What Is A Sitemap?

Think of a sitemap as:

```text id="p9m1k4"
A map
for robots.
```

Without it:

```text id="q6v8k2"
Search engines
must guess.
```

---

# RSS Feeds

RSS stands for:

```text id="r2q5m9"
Really Simple
Syndication.
```

RSS allows:

```text id="s8v1k7"
Readers

News Apps

Aggregators

AI Agents
```

to subscribe.

---

# Example Feed

```xml id="t5m4q1"
<rss>

  <channel>

    <title>
      GreyMatter
      Journal
    </title>

  </channel>

</rss>
```

---

# Generate RSS

Install:

```bash id="u1v9k3"
npm install rss
```

---

# Example

```typescript id="v7m2q8"
import RSS
from "rss";

const feed =
  new RSS({

    title:
      "GreyMatter
       Journal",
});
```

---

# Add Posts

```typescript id="w3v8k5"
feed.item({

  title:
    post.title,

  url:
    post.url,
});
```

---

# Structured Data

Search engines increasingly prefer:

```text id="x9m4k1"
JSON-LD.
```

Example:

```html id="y5q7m6"
<script
type="application/ld+json">

{
 "@context":
 "https://schema.org",

 "@type":
 "BlogPosting"
}

</script>
```

---

# Why?

Humans see:

```text id="z2v1k8"
Article.
```

Machines see:

```text id="a8m3q4"
Structured
knowledge.
```

---

# BlogPosting Schema

Example:

```typescript id="b4v9k2"
const schema = {

  "@context":
    "https://schema.org",

  "@type":
    "BlogPosting",

  headline:
    post.title,

  author: {

    "@type":
      "Person",

    name:
      post.author,
  },
};
```

---

# Breadcrumbs

Google understands:

```text id="c1m6q7"
Home

Posts

React
```

using:

```text id="d7v2k9"
Breadcrumb
schema.
```

---

# Article Metadata

Every article should contain:

```text id="e3m8k5"
Title

Description

Author

Published Date

Updated Date

Image

Keywords

Canonical URL
```

---

# Favicons

Create:

```text id="f8v4m1"
app/favicon.ico
```

and optionally:

```text id="g5m9q2"
app/icon.png

app/apple-icon.png
```

---

# Manifest

Create:

```text id="h2v7k8"
app/manifest.ts
```

Example:

```typescript id="i9m1q4"
export default
function manifest() {

  return {

    name:
      "GreyMatter
       Journal",

    display:
      "standalone",
  };
}
```

---

# Why?

This allows:

```text id="j6v3k7"
Installable
web apps.
```

---

# AI Crawlers

Modern crawlers include:

```text id="k3m8q1"
ChatGPT

Claude

Gemini

Perplexity
```

These systems increasingly consume:

```text id="l8v5m4"
Structured
content.
```

---

# Therefore...

SEO is becoming:

```text id="m4q9k2"
Knowledge
Engineering.
```

---

# The Hidden Architecture

When Google visits GreyMatter Journal:

```text id="n1v6k8"
Crawler
    │
    ▼

HTML
    │
    ▼

Metadata
    │
    ▼

OpenGraph
    │
    ▼

JSON-LD
    │
    ▼

RSS
    │
    ▼

Sitemap
```

The crawler constructs:

```text id="o7m2q5"
Its own model
of your website.
```

---

# Wait...

Does This Look Familiar?

We've discovered:

```text id="p4v9k1"
State Trees

Trust Trees

Identity Trees

Failure Trees

Execution Trees

Cache Trees

Knowledge Trees

Time Trees

Meaning Trees

Reality Trees
```

SEO introduces:

```text id="q9m3k7"
Representation Trees
```

because every search engine ultimately asks:

```text id="r5v8k2"
How should
this information
be represented?
```

---

# The Deep Secret Of SEO

Most beginners think:

```text id="s2m4q9"
SEO
   =
Keywords
```

Professional engineers think:

```text id="t8v1k5"
SEO
   =
Teaching
Computers
What
Things
Mean
```

---

# The Deep Secret Of The Web

The web was never merely:

```text id="u4m7q3"
Documents.
```

The web is:

```text id="v1v9k8"
A giant
knowledge graph.
```

---

# Mental Model To Remember Forever

Beginners think:

```text id="w7m2k4"
A website
        =
Pages
```

Professional engineers think:

```text id="x3v8q6"
A website
        =
Knowledge

        +
Meaning

        +
Relationships

        +
Metadata
```

SEO reveals one of the deepest truths in computer science:

```text id="y9m4k1"
Computers cannot
understand reality.

They can only
understand
representations
of reality.

Engineering is the art
of creating
those representations.
```
