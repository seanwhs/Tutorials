# **✅ Part 10 — Creating Our First Content**

---

# GreyMatter Journal  
## Part 10 — Creating Our First Content: Documents, References, and Rich Text in Sanity

> **Goal of this lesson:** Populate the Content Lake with real data and understand how documents, references, and Portable Text work together.

---

### The Moment of Truth

We now have a fully connected system. It’s time to add real content.

---

### Start the Studio

```bash
cd studio
npm run dev
```

Open `http://localhost:3333`

You’ll see **Posts**, **Authors**, and **Categories**.

---

### 1. Create an Author

- **Name**: Sean Wong
- **Biography**: Short bio
- **Avatar**: Upload image (optional)

**Publish**

---

### 2. Create Categories

- **Architecture** – Systems design
- **Web Development** – Modern frontend
- **AI Engineering** – Intelligent systems

---

### 3. Create Your First Post

- **Title**: Understanding React Server Components
- **Slug**: Auto-generated
- **Excerpt**: Beginner-friendly introduction...
- **Hero Image**: Upload one
- **Author**: Sean Wong
- **Categories**: Multiple
- **Published At**: Today

---

### Writing with Portable Text

In the **Body** field, use the rich text editor to add headings, paragraphs, lists, etc.

**Publish**

---

### What Sanity Actually Stores

Sanity stores **structured data**:

- Portable Text for rich content
- References for relationships

This allows the same content to be used across websites, apps, RSS, etc.

---

### Query the Content

Update `app/test/page.tsx`:

```tsx
import { client } from "@/lib/sanity";

export default async function TestPage() {
  const posts = await client.fetch(`
    *[_type == "post"]{
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
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold mb-8">Content Test</h1>
      <pre className="bg-gray-900 text-gray-100 p-6 rounded-xl overflow-auto text-sm">
        {JSON.stringify(posts, null, 2)}
      </pre>
    </div>
  );
}
```

---

### Key Concepts

- **Documents**: Individual pieces of content
- **References** (`_ref`): Links between documents (no duplication)
- **Portable Text**: Structured rich text (AST)
- **GROQ Projections**: Fetch exactly what you need

---

### Mental Model To Remember Forever

> A blog post is not an HTML page.  
> It is a **document** with **relationships** and **structured data**.

The frontend transforms that data into UI.

---

### Up Next — Part 11: Building the Homepage

We’ll create a list of posts, style cards, and prepare for dynamic routes.
