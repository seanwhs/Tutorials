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

Open: `http://localhost:3333`

You’ll see the three content types we defined: **Posts**, **Authors**, and **Categories**.

---

### 1. Create an Author

Go to **Authors** → **Create new**

- **Name**: Sean Wong
- **Slug**: (auto-generated)
- **Biography**: Write a short bio
- **Avatar**: Upload an image (optional)

**Publish**

---

### 2. Create Categories

Create a few categories:

- **Architecture** – Software design and systems thinking
- **Web Development** – Modern frontend and frameworks
- **AI Engineering** – Building intelligent systems

---

### 3. Create Your First Post

Go to **Posts** → **Create new**

Fill in:

- **Title**: Understanding React Server Components
- **Slug**: (generate from title)
- **Excerpt**: A clear, beginner-friendly introduction...
- **Cover Image**: Upload one
- **Author**: Select "Sean Wong"
- **Categories**: Select multiple
- **Published At**: Choose today's date

---

### Writing in Portable Text

In the **Body** field, write content using the rich text editor. You can add:

- Headings
- Paragraphs
- Lists
- Blockquotes, etc.

**Publish** the post.

---

### What Sanity Actually Stores

Sanity doesn’t store HTML. It stores **structured data** (Portable Text for rich content + references for relationships).

This is extremely powerful because the same content can be rendered on websites, mobile apps, RSS feeds, newsletters, etc.

---

### Query the Content from Next.js

Update or create `app/test/page.tsx`:

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

Visit `http://localhost:3000/test` — you should see your post with resolved author and categories.

---

### Key Concepts

- **Documents**: Individual pieces of content (Post, Author, Category)
- **References** (`_ref`): Links between documents (no data duplication)
- **Portable Text**: Structured rich text instead of HTML
- **GROQ Projections**: Fetch exactly the fields you need

---

### Mental Model To Remember Forever

> A blog post is not an HTML page.  
> It is a **document** with **relationships** and **structured data**.

The frontend’s job is to transform that data into beautiful UI.

---

### Up Next — Part 11: Building the Homepage

We’ll:
- Create a proper homepage that lists posts
- Learn how to render lists in Server Components
- Style cards with Tailwind
- Prepare for dynamic routes (`[slug]`)

This is where GreyMatter Journal starts looking like a real publication.
