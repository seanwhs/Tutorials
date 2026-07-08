# Part 4: Creating a Free Sanity Project & Core Concepts

In this part we create a free Sanity account and project, and learn the core concepts we'll rely on for the rest of the series: **projects, datasets, documents, schemas, and GROQ**.

## What is Sanity?

Sanity is a **headless CMS**. Unlike WordPress or Squarespace, it doesn't render your website — it only stores and serves your content via an API. You build the actual website yourself (with Next.js, in our case) and just fetch content from Sanity.

Sanity has two main parts:
1. **Content Lake** — the hosted database that stores your content and serves it via a fast, global API.
2. **Sanity Studio** — an open-source, free, and fully customizable content-editing UI (built in React) that you can either host separately or, as we'll do, embed directly inside your own Next.js app.

## Sanity's Free Tier

The free "Free" plan includes (at time of writing):
- 1 project with unlimited datasets... in practice we'll use exactly 1 dataset (`production`)
- Up to 3 users on the project
- 10GB of assets (images/files) bandwidth per month, 5GB asset storage
- 1,000,000 API CDN requests/month
- Free, embeddable Studio

This is far more than enough for a personal portfolio site. No credit card required.

## Step 1: Create a Sanity Account

1. Go to https://www.sanity.io/get-started
2. Sign up for free — you can use a GitHub or Google account for a faster signup
3. You'll land on the Sanity dashboard (manage.sanity.io)

## Step 2: Create a New Project

We're going to create the Sanity project directly from inside our Next.js codebase using the Sanity CLI, which is the fastest, most standard approach.

In your terminal, inside the `my-portfolio` folder, run:

```bash
npm create sanity@latest -- --template clean --create-project "My Portfolio CMS" --dataset production
```

This will:
1. Prompt you to log in to Sanity (opens a browser window) if you haven't already
2. Create a new Sanity project called "My Portfolio CMS"
3. Create a dataset named `production`
4. Ask where to put the Studio files — **when asked for a path, we'll actually handle this manually in Part 5 for a fully embedded setup**, so for now you can let it scaffold into a separate folder; we will move/adjust things next part

> Note: Depending on the CLI version, it may ask "Would you like to add configuration files for a Next.js project?" — answer **No**, since we'll set up the embedded Studio manually in Part 5 to keep things clean and explicit for learning purposes.

If prompted for a project template, choose **Clean project with no predefined schemas** — we'll design our own schemas from scratch in Part 6.

## Step 3: Note Your Project ID and Dataset

After creation, Sanity will print something like:

```txt
Project ID: ab12cd34
Dataset: production
```

**Write this Project ID down** — you'll need it repeatedly. You can always find it again at https://www.sanity.io/manage, by clicking into your project.

## Step 4: Core Sanity Concepts

### Project
The top-level container for your Sanity content, identified by a unique **Project ID**. One project can contain multiple datasets.

### Dataset
A named collection of content within a project (e.g. `production`, `staging`). We'll use just one dataset called `production` for simplicity.

### Document
A single piece of content, e.g. one blog post, one project, one skill. Every document has a `_type` (which schema it follows) and a unique `_id`.

### Schema
A schema defines the *shape* of a document type — its fields, their types, and validation rules. We write schemas in JavaScript/TypeScript using Sanity's schema builder (`defineType`, `defineField`). We'll design ours in Part 6.

### GROQ
**G**raph-**R**elational **O**bject **Q**ueries — Sanity's query language, purpose-built for querying JSON content. Example:

```groq
*[_type == "project"] | order(publishedAt desc) {
  title,
  slug,
  summary
}
```

This says: "get all documents of type `project`, order by `publishedAt` descending, and return only the `title`, `slug`, and `summary` fields." We'll write many queries like this starting in Part 7.

### API (CDN)
Once content is published, it's available via a fast global CDN at a URL like:
```
https://<project-id>.apicdn.sanity.io/v2024-01-01/data/query/production?query=...
```
The `next-sanity` client library (Part 7) handles building these URLs for us — we won't write raw fetch URLs by hand.

## Step 5: Explore manage.sanity.io (Optional but Recommended)

Visit https://www.sanity.io/manage, click into "My Portfolio CMS", and note the tabs:
- **Datasets** — manage your `production` dataset
- **API** → **Tokens** — where we'll later generate a read/write token (Part 7 and Part 15)
- **API** → **CORS origins** — where we'll allow `http://localhost:3000` and your future Vercel domain to talk to Sanity's API

### Add CORS Origins Now

While you're there, click **API** → **CORS Origins** → **Add CORS origin**, and add:

```txt
http://localhost:3000
```

Check "Allow credentials" and save. We'll come back to add your production Vercel URL in Part 16.

## Checkpoint ✅

You should now have:
- A free Sanity account
- A Sanity project (e.g. "My Portfolio CMS") with a `production` dataset
- Your **Project ID** written down somewhere safe
- `http://localhost:3000` added as an allowed CORS origin
- A conceptual understanding of projects, datasets, documents, schemas, and GROQ

Next up: **Part 5: Embedding Sanity Studio Inside the Next.js App**, where we install the Studio directly into our Next.js project at the `/studio` route.

---

Ready for Part 5?
