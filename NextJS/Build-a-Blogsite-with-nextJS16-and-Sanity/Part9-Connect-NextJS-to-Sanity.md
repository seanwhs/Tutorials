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

From the project root:

```bash
npm install next-sanity
```

`next-sanity` provides helpful utilities and the official client for connecting Next.js and Sanity.

---

### Step 2: Environment Variables

Create a file called `.env.local` in the root:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id_here
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-07-04
```

**Where to find your Project ID:**
1. Go to [manage.sanity.io](https://manage.sanity.io)
2. Select your project
3. Go to **API** section

> Variables starting with `NEXT_PUBLIC_` are exposed to the browser. Others stay server-only.

---

### Step 3: Create the Sanity Client

Create the folder and file:

```bash
mkdir -p lib
touch lib/sanity.ts
```

Add this code to `lib/sanity.ts`:

```typescript
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION,
  useCdn: process.env.NODE_ENV === "production", // Use CDN in production
});
```

This client acts as a **translator** between Next.js and Sanity.

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
      <pre className="bg-gray-100 p-6 overflow-auto">
        {JSON.stringify(posts, null, 2)}
      </pre>
    </div>
  );
}
```

Visit `http://localhost:3000/test`. If everything is set up correctly, you’ll see an empty array (since we haven’t added content yet).

---

### Understanding GROQ Basics

GROQ is Sanity’s query language. Examples:

- `*[_type == "post"]` → Get all posts
- `*[_type == "post"][0]` → Get the first post
- `*[_type == "author"]` → Get all authors

It’s designed to fetch exactly the data you need — very efficiently.

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

The **Sanity Client** is the bridge. Environment variables keep configuration clean and secure.

---

### Up Next — Part 10: Creating Real Content

We’ll:
- Create authors and categories in Sanity Studio
- Write our first blog post with rich text and images
- Query and display that content in Next.js
- See the full content flow from editor to reader

This is where GreyMatter Journal comes alive.
