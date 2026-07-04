# **✅ Part 19 — Draft Mode, Live Preview, and Multiple Realities**

---

# GreyMatter Journal  
## Part 19 — Draft Mode, Live Preview, and the Architecture of Multiple Realities

> **Goal of this lesson:** Implement draft/preview mode so editors can safely see unpublished content while readers always see the published version.

---

### The Editorial Workflow Problem

Currently, editors must publish to preview. This is risky and slow.

Professional systems separate **draft** from **published** content.

---

### How Sanity Handles Drafts

Sanity stores drafts with a `drafts.` prefix (e.g., `drafts.article123`). Published content uses the plain ID.

**Two realities coexist** in the same dataset.

---

### Step 1: Enable Draft Mode in Next.js

Create `app/api/draft/route.ts`:

```typescript
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";

export async function GET(request: Request) {
  const draft = await draftMode();
  draft.enable();

  const url = new URL(request.url);
  const slug = url.searchParams.get("slug");

  if (slug) {
    redirect(`/posts/${slug}`);
  }

  redirect("/");
}
```

This sets a special cookie and redirects to the article.

---

### Step 2: Use Draft Mode in Article Pages

Update `app/posts/[slug]/page.tsx`:

```tsx
import { draftMode } from "next/headers";

const { isEnabled } = await draftMode();

const post = await client.fetch(
  POST_QUERY,
  { slug: params.slug },
  { 
    perspective: isEnabled ? "previewDrafts" : "published" 
  }
);
```

- `published` → Only live content
- `previewDrafts` → Shows latest draft if it exists

---

### Step 3: Add Preview Button in Studio (Optional)

You can later add a custom action in Sanity Studio that opens `/api/draft?slug=...`

---

### Mental Model To Remember Forever

Modern content systems often maintain **multiple realities**:

- Draft vs Published
- Cached vs Fresh
- User-specific views

Draft Mode is a **reality switch** controlled by cookies and query perspectives.

---

### Up Next — Part 20: Authentication and Admin Areas

We’ll explore identity, authorization, sessions, and secure access patterns.
