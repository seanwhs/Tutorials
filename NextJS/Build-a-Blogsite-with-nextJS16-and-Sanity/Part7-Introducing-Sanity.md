# **✅ Part 7 — Introducing Sanity**

---

# GreyMatter Journal  
## Part 7 — Introducing Sanity: Why Next.js Doesn't Store Your Blog Posts

> **Goal of this lesson:** Understand why content and presentation should be separated, what a Headless CMS is, and how Sanity fits into the modern stack.

---

### We Have a Website — But No Content System

Our site has layouts and navigation, but publishing articles is still manual and unsustainable.

---

### Next.js Is a Rendering Engine

**Key Insight:**

> Next.js excels at **displaying** content.  
> It is not designed to **store and manage** content.

Its responsibilities:
- Fetch data efficiently
- Render UI with Server Components
- Optimize performance and SEO
- Handle routing and caching

---

### Traditional CMS vs Headless CMS

**Traditional CMS (e.g. WordPress):**
One monolithic system with editor, database, themes, and frontend.

**Headless CMS:**
Specializes in content creation and storage, then exposes it via APIs.

**Benefits:**
- Freedom to use any frontend
- Better developer experience
- Scalable and future-proof

---

### Introducing Sanity

Sanity is a modern Headless CMS built around the **Content Lake** — a real-time, document-oriented content platform.

**Core pieces:**
- **Sanity Studio** → Editor for writers
- **Content Lake** → Flexible storage with relationships
- **GROQ** → Powerful query language
- **API Layer** → Real-time delivery

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
Next.js 16
        ↓
Browser
```

**Clear separation:**
- Sanity → Content creation & storage
- Next.js → Rendering & user experience

---

### Initialize Sanity

In your project root:

```bash
npx sanity@latest init
```

**Recommended choices:**
- Project name: `GreyMatter Journal`
- Create new project → Yes
- Dataset: `production`
- Output path: `studio`
- TypeScript: Yes

This creates a `studio/` folder alongside your `app/`.

---

### What We Now Have

```text
greymatter-journal/
├── app/           ← Reader-facing Next.js app
├── studio/        ← Editor-facing Sanity Studio
├── components/
├── lib/
└── ...
```

This separation is a foundational architectural decision.

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

Sanity owns content. Next.js owns presentation.

---

### Up Next — Part 8: Exploring the Sanity Studio

We’ll dive into schemas, content modeling, and how editors and developers think differently.
