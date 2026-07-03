# **✅ Part 7 — Introducing Sanity**

---

# GreyMatter Journal  
## Part 7 — Introducing Sanity: Why Next.js Doesn't Store Your Blog Posts

> **Goal of this lesson:** Understand why content and presentation should be separated, what a Headless CMS is, and how Sanity fits into the modern stack.

---

### We Have a Website — But No Real Content System

Right now, our site has layouts, navigation, and a homepage. But how do we actually publish articles?

Hardcoding content like this quickly becomes unsustainable:

```tsx
// app/posts/my-article/page.tsx
export default function ArticlePage() {
  return <h1>Understanding Server Components</h1>;
}
```

As the number of articles grows, you need authors, categories, drafts, images, SEO metadata, and editorial workflows. This is why we need a dedicated **content system**.

---

### Next.js Is a Rendering Engine, Not a Database

**Key Insight:**

> Next.js is excellent at **displaying** content.  
> It is not designed to **store and manage** content.

Its responsibilities:
- Fetch data efficiently
- Render UI (Server Components)
- Optimize performance and SEO
- Handle routing and caching

It should **consume** content — not own it.

---

### Traditional CMS vs Headless CMS

**Traditional (e.g. WordPress):**
One monolithic system containing editor, database, themes, and frontend.

**Headless CMS:**
Only handles content creation and storage, then exposes it via APIs.

**Benefits of headless:**
- Freedom to use any frontend (Next.js, mobile apps, etc.)
- Better developer experience
- Scalable architecture
- Future-proof content

---

### Introducing Sanity

**Sanity** is a modern, developer-friendly Headless CMS built around the **Content Lake**.

**Core components:**

1. **Sanity Studio** — Beautiful, customizable editor for writers and editors
2. **Content Lake** — Real-time, document-oriented storage
3. **GROQ** — Powerful query language for fetching content
4. **API Layer** — Real-time and highly flexible

---

### Content Lake vs Traditional Databases

| Aspect              | Traditional DB (PostgreSQL)     | Sanity Content Lake               |
|---------------------|----------------------------------|-----------------------------------|
| Data Model          | Tables & Rows                    | Flexible Documents                |
| Relationships       | Complex joins                    | Native references                 |
| Editor Experience   | Build yourself                   | First-class Studio                |
| Real-time           | Extra work                       | Built-in                          |
| Media & Assets      | Manual                           | Excellent built-in support        |

---

### Our New Architecture

```text
Writers & Editors
        ↓
Sanity Studio
        ↓
Content Lake
        ↓
GROQ Queries
        ↓
Next.js 16 (Server Components)
        ↓
Browser
```

**Clear separation of concerns:**
- **Sanity** → Creates and stores content
- **Next.js** → Fetches and renders content beautifully

---

### Initialize Sanity

In your project root (`greymatter-journal`), run:

```bash
npx sanity@latest init
```

**Recommended choices:**

- Project name: `GreyMatter Journal`
- Create new project → Yes
- Dataset: `production`
- Output path: `studio` (important for structure)
- TypeScript: Yes

This creates a `studio/` folder alongside your `app/` folder.

---

### What We Now Have

```text
greymatter-journal/
├── app/           ← Reader-facing Next.js application
├── studio/        ← Editor-facing Sanity Studio
├── components/
├── lib/
└── ...
```

This separation is one of the most important architectural decisions in modern content platforms.

---

### Mental Model To Remember Forever

**Beginner thinking:**
```text
Blog = One big website
```

**Professional thinking:**
```text
Blog = Content System + Rendering System
```

- **Sanity** owns the content and editorial experience
- **Next.js** owns the presentation, performance, and user experience

They communicate through clean APIs (GROQ).

---

### Up Next — Part 8: Exploring the Sanity Studio

We’ll dive into the `studio/` folder and learn:
- What Sanity schemas are
- How to model content (posts, authors, categories)
- Why content modeling is critical
- How to run the Studio locally
- The difference between how developers and editors think

This is where we start shaping the actual content architecture of GreyMatter Journal.
