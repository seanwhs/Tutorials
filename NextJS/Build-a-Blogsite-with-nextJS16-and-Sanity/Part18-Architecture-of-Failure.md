# **✅ Part 18 — Loading States, Error Boundaries, and the Architecture of Failure**

---

# GreyMatter Journal  
## Part 18 — Loading States, Error Boundaries, Suspense, and Reliability Engineering

> **Goal of this lesson:** Build professional loading states, error handling, and 404 pages while understanding that robust software is built around managing uncertainty.

---

### The Four States of Every Feature

Modern applications must handle:

1. **Loading** – Data is being fetched
2. **Success** – Data arrived
3. **Error** – Something went wrong
4. **Not Found** – Resource doesn't exist

---

### 1. Loading States with `loading.tsx`

Create `app/posts/[slug]/loading.tsx`:

```tsx
export default function Loading() {
  return (
    <div className="max-w-3xl mx-auto px-6 py-12 animate-pulse">
      <div className="h-12 bg-gray-200 rounded w-3/4 mb-6"></div>
      <div className="h-4 bg-gray-200 rounded w-1/2 mb-12"></div>
      
      <div className="space-y-6">
        <div className="h-4 bg-gray-200 rounded"></div>
        <div className="h-4 bg-gray-200 rounded"></div>
        <div className="h-4 bg-gray-200 rounded w-5/6"></div>
      </div>
    </div>
  );
}
```

Next.js automatically shows this while the Server Component is fetching data.

---

### 2. Not Found Pages

In `app/posts/[slug]/page.tsx`:

```tsx
import { notFound } from "next/navigation";

if (!post) {
  notFound();
}
```

Create `app/not-found.tsx` for a global 404 experience.

---

### 3. Error Boundaries

Create `app/posts/[slug]/error.tsx`:

```tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <div className="max-w-md mx-auto text-center py-20">
      <h2 className="text-2xl font-semibold mb-4">Something went wrong</h2>
      <p className="text-gray-600 mb-8">{error.message}</p>
      <button
        onClick={reset}
        className="px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800"
      >
        Try Again
      </button>
    </div>
  );
}
```

Error boundaries catch errors in their subtree and provide recovery.

---

### Mental Model To Remember Forever

**Great software doesn't just handle success.**  
It gracefully handles **all possible realities**.

Reliability is the art of **planning for failure**.

---

### Up Next — Part 19: Draft Mode and Live Preview

We’ll implement Sanity Draft Mode so editors can preview unpublished content — a critical feature for professional publications.
