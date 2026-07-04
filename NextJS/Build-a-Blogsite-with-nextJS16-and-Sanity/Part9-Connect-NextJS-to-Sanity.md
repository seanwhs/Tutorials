# **✅ Part 9 — Connecting Next.js 16 to Sanity**

---

# GreyMatter Journal  
## Part 9 — Connecting Next.js 16 to Sanity: APIs, Environment Variables, and the Sanity Client

> **Goal of this lesson:** Connect the Next.js frontend to the Sanity Content Lake and understand how modern applications communicate with external services.

---

### Two Systems, One Publication

We now have:
- A beautiful Next.js reader experience
- A powerful Sanity Studio for editors

But they don’t talk to each other yet.

---

### The Role of APIs

An **API** is a contract that allows two independent systems to communicate.

In our case:

```text
Next.js (Frontend)
       ↓ (GROQ Query)
Sanity API
       ↓
Content Lake
```

---

### Step 1: Install the Official Integration

```bash
npm install next-sanity
```

`next-sanity` provides the official client and utilities.

---

### Step 2: Environment Variables

Create `.env.local`:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-07-04
```

Find your Project ID in [Sanity Manage](https://manage.sanity.io).

---

### Step 3: Create the Sanity Client

Create `lib/sanity.ts`:

```typescript
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION,
  useCdn: process.env.NODE_ENV === "production",
});
```

This client acts as a translator between Next.js and Sanity.

---

### Step 4: Test the Connection

Create `app/test/page.tsx`:

```tsx
import { client } from "@/lib/sanity";

export default async function TestPage() {
  const posts = await client.fetch(`*[_type == "post"]`);

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Sanity Test</h1>
      <pre className="bg-gray-900 text-gray-100 p-6 rounded-xl overflow-auto">
        {JSON.stringify(posts, null, 2)}
      </pre>
    </div>
  );
}
```

Visit `http://localhost:3000/test` — you should see an empty array.

---

### GROQ Basics

- `*[_type == "post"]` — Get all posts
- `*[_type == "post"][0]` — Get first post
- `author->name` — Follow references

GROQ lets you fetch exactly the data you need.

---

### Mental Model To Remember Forever

**Modern Application Architecture:**

```text
Content System (Sanity)
         ↓ (API + GROQ)
Rendering System (Next.js)
         ↓
User Interface (Browser)
```

The Sanity Client is the bridge.

---

### Up Next — Part 10: Creating Real Content

We’ll create authors, categories, and posts in Studio, then query and display them.
