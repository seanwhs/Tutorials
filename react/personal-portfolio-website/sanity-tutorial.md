# Sanity CMS for Absolute Beginners

*A step-by-step guide to managing content without writing code.*

---

## Table of Contents
- [What is Sanity?](#what-is-sanity)
- [Why Use a Headless CMS?](#why-use-a-headless-cms)
- [Part 1: Creating Your Sanity Account](#part-1-creating-your-sanity-account)
- [Part 2: Setting Up Your First Project](#part-2-setting-up-your-first-project)
- [Part 3: Understanding the Sanity Studio](#part-3-understanding-the-sanity-studio)
- [Part 4: Creating Content (The Editor)](#part-4-creating-content-the-editor)
- [Part 5: Understanding Schemas (The Blueprint)](#part-5-understanding-schemas-the-blueprint)
- [Part 6: Connecting to Your Website](#part-6-connecting-to-your-website)
- [Part 7: Publishing and Managing Content](#part-7-publishing-and-managing-content)
- [Part 8: Common Tasks](#part-8-common-tasks)
- [Glossary](#glossary)

---

## What is Sanity?

**Sanity** is a tool that helps you create, store, and manage content for your website — without needing to write code or touch your website's files.

Think of it like this:

> **Microsoft Word** lets you write documents and save them on your computer.
>
> **Sanity** lets you write content (like blog posts) and makes it available to your website automatically.

Sanity is a **headless CMS** (Content Management System). Let's break that down.

---

## Why Use a Headless CMS?

### The Old Way (Traditional CMS)
Imagine WordPress. Your content (words, images) and your website design (colors, layout) are mixed together in one place. If you want to change your website's look, you risk breaking your content. If you want to use your content somewhere else (like a mobile app), you can't easily do it.

```
┌─────────────────────────────┐
│        WordPress             │
│  ┌──────┐  ┌─────────────┐  │
│  │Content│  │   Design    │  │
│  │(posts)│  │  (themes)   │  │
│  └──────┘  └─────────────┘  │
│        Mixed together         │
└─────────────────────────────┘
```

### The New Way (Headless CMS)
Your content lives in one place (Sanity). Your website lives in another place (React/Vercel). They talk to each other through the internet.

```
┌──────────────┐      Internet      ┌──────────────┐
│   Sanity     │  ←────────────→   │   Website    │
│  (Content)   │      (API)        │  (React app) │
│              │                   │              │
│  Blog Post 1 │                   │  Shows Post 1│
│  Blog Post 2 │                   │  Shows Post 2│
│  Blog Post 3 │                   │  Shows Post 3│
└──────────────┘                   └──────────────┘
```

**Why this is better:**
| Traditional CMS | Headless CMS (Sanity) |
|-----------------|----------------------|
| Content and design stuck together | Content and design separate |
| Hard to redesign without breaking content | Redesign anytime, content stays safe |
| Content only works on one website | Content can go to websites, apps, anywhere |
| Limited editor features | Rich editor with images, code blocks, etc. |
| You manage servers and updates | Sanity handles hosting and backups |

---

## Part 1: Creating Your Sanity Account

### Step 1: Sign Up
1. Go to [sanity.io](https://sanity.io)
2. Click **Get Started** (usually a blue button)
3. You can sign up with:
   - **Google** (click and choose your Google account)
   - **GitHub** (click and authorize with your GitHub account)
   - **Email** (enter your email and create a password)

### Step 2: Verify Your Email (if using email)
If you signed up with email, check your inbox for a verification email from Sanity. Click the link inside to confirm.

**What you now have:** A free Sanity account. The free plan includes:
- Unlimited content types
- 3 user accounts
- 100GB bandwidth per month
- Community support

---

## Part 2: Setting Up Your First Project

A **project** in Sanity is like a container for your content. Think of it as a folder that holds all your blog posts, images, and settings.

### Step 1: Install the Sanity Tool on Your Computer
Open your terminal (Command Prompt on Windows, Terminal on Mac) and run:

```bash
npm install -g @sanity/cli
```

**What this does:** Installs a command-line tool that lets you create and manage Sanity projects from your computer.

**To verify it worked:**
```bash
sanity --version
```
You should see a version number like `3.x.x`.

### Step 2: Create a New Folder for Your CMS
In your terminal, run:

```bash
# Create a folder called "my-blog-cms"
mkdir my-blog-cms

# Move into that folder
cd my-blog-cms
```

### Step 3: Initialize Your Sanity Project
Still in the terminal, run:

```bash
sanity init
```

**What happens next:** A setup wizard asks you questions. Here's what to answer:

| Question | What to Choose | Why |
|----------|---------------|-----|
| Login method | Choose your account (Google/GitHub/Email) | Links project to your Sanity account |
| Create or select project | **Create new project** | Starting fresh |
| Project name | Type "My Blog" (or any name) | This is just for you to recognize it |
| Use default dataset config? | **Yes** | "Production" is the standard name |
| Project output path | Press **Enter** | Accepts the current folder |
| Select project template | **Clean project with no predefined schemas** | We'll build our own |
| Use TypeScript? | **No** (for beginners) | Keeps things simpler |
| Package manager | **npm** | Standard choice |

**What just happened:** Sanity created a bunch of files in your `my-blog-cms` folder. These files define how your content will be structured.

### Step 4: Start the Sanity Studio
Run:

```bash
npm run dev
```

**What you see:** Text saying something like:
```
Sanity Studio using vite@4.x running at http://localhost:3333
```

Open your browser and go to `http://localhost:3333`

**You should see:** The Sanity Studio interface. It might look empty right now — that's normal! We haven't defined what content we want yet.

---

## Part 3: Understanding the Sanity Studio

When you open Sanity Studio, you'll see:

```
┌────────────────────────────────────────────┐
│  Sanity Studio                              │
│                                             │
│  ┌──────────┐  ┌─────────────────────────┐  │
│  │ Content  │  │                         │  │
│  │          │  │  No document types      │  │
│  │ (empty)  │  │  found                  │  │
│  │          │  │                         │  │
│  │          │  │  Create a schema to     │  │
│  │          │  │  get started            │  │
│  └──────────┘  └─────────────────────────┘  │
└────────────────────────────────────────────┘
```

**Key areas:**
| Area | What It Is |
|------|-----------|
| **Left sidebar** | Lists all your content types (blog posts, authors, pages, etc.) |
| **Main area** | Shows your actual content (posts, images, etc.) |
| **Top bar** | Search, create new content, user menu |

Right now it says "No document types found" because we haven't told Sanity what kind of content we want to store. Let's fix that.

---

## Part 4: Creating Content (The Editor)

Before we can write blog posts, we need to tell Sanity what a "blog post" looks like. This is called a **schema**.

### What is a Schema?
A schema is like a form template. It defines what fields every blog post should have.

**Real-world analogy:**
> When you fill out a job application, the form asks for specific things: name, email, experience, etc. The company designed that form to collect exactly what they need.
>
> A schema is like designing that form. We tell Sanity: "Every blog post needs a title, a summary, content, a category, and a date."

### Step 1: Define Your Blog Post Schema
In your `my-blog-cms` folder, find the file:
```
schemaTypes/post.js
```

If it doesn't exist, create it. Replace everything with:

```javascript
export default {
  name: 'post',
  title: 'Blog Post',
  type: 'document',
  fields: [
    {
      name: 'title',
      title: 'Title',
      type: 'string',
      description: 'The headline of your blog post',
      validation: (Rule) => Rule.required().max(100)
    },
    {
      name: 'slug',
      title: 'Slug (URL Name)',
      type: 'slug',
      description: 'The web address for this post (e.g., my-first-post)',
      options: {
        source: 'title',
        maxLength: 96,
      },
      validation: (Rule) => Rule.required()
    },
    {
      name: 'excerpt',
      title: 'Short Summary',
      type: 'text',
      rows: 3,
      description: 'A brief description that appears on the blog listing page',
      validation: (Rule) => Rule.required().max(300)
    },
    {
      name: 'content',
      title: 'Article Content',
      type: 'array',
      description: 'The main body of your blog post',
      of: [
        { 
          type: 'block',
          styles: [
            { title: 'Normal', value: 'normal' },
            { title: 'Heading 1', value: 'h1' },
            { title: 'Heading 2', value: 'h2' },
            { title: 'Quote', value: 'blockquote' }
          ]
        },
        { type: 'image' }
      ]
    },
    {
      name: 'coverImage',
      title: 'Cover Image',
      type: 'image',
      description: 'The main image for this post',
      options: { hotspot: true }
    },
    {
      name: 'category',
      title: 'Category',
      type: 'string',
      description: 'What type of post is this?',
      options: {
        list: [
          { title: 'Opinion', value: 'opinion' },
          { title: 'Tutorial', value: 'tutorial' },
          { title: 'AI Engineering', value: 'ai-engineering' },
          { title: 'Architecture', value: 'architecture' },
          { title: 'Career', value: 'career' }
        ]
      }
    },
    {
      name: 'tags',
      title: 'Tags',
      type: 'array',
      description: 'Keywords to help people find this post',
      of: [{ type: 'string' }],
      options: { layout: 'tags' }
    },
    {
      name: 'publishedAt',
      title: 'Publish Date',
      type: 'datetime',
      description: 'When should this post go live?',
      validation: (Rule) => Rule.required()
    },
    {
      name: 'featured',
      title: 'Featured Post?',
      type: 'boolean',
      description: 'Check this to highlight this post on your homepage',
      initialValue: false
    }
  ],
  preview: {
    select: {
      title: 'title',
      category: 'category',
      publishedAt: 'publishedAt'
    },
    prepare({ title, category, publishedAt }) {
      return {
        title,
        subtitle: `${category || 'No category'} • ${publishedAt ? new Date(publishedAt).toLocaleDateString() : 'No date'}`
      };
    }
  }
}
```

### Step 2: Register Your Schema
Find the file `schemaTypes/index.js` and make sure it looks like this:

```javascript
import post from './post'

export const schemaTypes = [post]
```

**What this does:** Tells Sanity: "I have one type of content called 'post'. Please make it available in the Studio."

### Step 3: See Your Schema in Action
If your Studio is still running (from `npm run dev`), refresh your browser (`F5` or `Cmd+R`).

**You should now see:**
```
┌────────────────────────────────────────────┐
│  Sanity Studio                              │
│                                             │
│  ┌──────────┐  ┌─────────────────────────┐  │
│  │ Content  │  │                         │  │
│  │          │  │  Blog Post              │  │
│  │ ▼ Blog   │  │  ─────────────────────  │  │
│  │   Post   │  │  No documents           │  │
│  │          │  │                         │  │
│  │          │  │  [Create new document]  │  │
│  │          │  │                         │  │
│  └──────────┘  └─────────────────────────┘  │
└────────────────────────────────────────────┘
```

Click **"Create new document"** → **"Blog Post"**

### Step 4: Write Your First Blog Post
You'll see a form with these fields:

| Field | What to Enter | Example |
|-------|---------------|---------|
| **Title** | Your post headline | "Why I Left Corporate Life" |
| **Slug** | Click "Generate" — it auto-creates from title | "why-i-left-corporate-life" |
| **Short Summary** | 1-2 sentence teaser | "After 20 years in enterprise architecture, I decided to forge my own path..." |
| **Article Content** | Your full article (rich text editor) | Write paragraphs, add headings, insert images |
| **Cover Image** | Click to upload an image | Your post's main image |
| **Category** | Select from dropdown | "Career" |
| **Tags** | Type keywords, press Enter | "freelancing", "career change", "architecture" |
| **Publish Date** | Click to select date and time | Today's date |
| **Featured Post?** | Check the box if you want it highlighted | ☑️ or ☐ |

**The Rich Text Editor:**
The "Article Content" field is special. It's a rich text editor that lets you:
- Type normal paragraphs
- Press `Ctrl+B` (or `Cmd+B`) for **bold**
- Press `Ctrl+I` (or `Cmd+I`) for *italic*
- Click the `+` button to add:
  - **Headings** (H1, H2)
  - **Images** (upload from your computer)
  - **Quotes** (styled blockquotes)
  - **Code blocks** (for programming tutorials)

### Step 5: Publish Your Post
When you're done writing:
1. Look at the bottom-right corner of the screen
2. You'll see a **"Publish"** button
3. Click it

**What happens:** Your post is now saved to Sanity's database and is ready to be fetched by your website.

**Important buttons to know:**
| Button | What It Does |
|--------|-------------|
| **Publish** | Makes your post live (visible to your website) |
| **Save** | Saves a draft without publishing |
| **Unpublish** | Hides a published post |
| **Delete** | Permanently removes the post |

---

## Part 5: Understanding Schemas (The Blueprint)

Let's understand what we built. Our schema defines 9 fields for every blog post:

```
┌─────────────────────────────────────────────────┐
│           BLOG POST SCHEMA                      │
│                                                 │
│  ┌─────────────┐    ┌─────────────────────┐    │
│  │   Field     │    │      Type           │    │
│  ├─────────────┤    ├─────────────────────┤    │
│  │ title       │ →  │ text (short)        │    │
│  │ slug        │ →  │ text (URL-friendly) │    │
│  │ excerpt     │ →  │ text (long)         │    │
│  │ content     │ →  │ rich text           │    │
│  │ coverImage  │ →  │ image               │    │
│  │ category    │ →  │ dropdown            │    │
│  │ tags        │ →  │ list of text        │    │
│  │ publishedAt │ →  │ date & time         │    │
│  │ featured    │ →  │ yes/no checkbox     │    │
│  └─────────────┘    └─────────────────────┘    │
└─────────────────────────────────────────────────┘
```

### Common Field Types in Sanity

| Type | What It's For | Example |
|------|--------------|---------|
| `string` | Short text (titles, names) | "My Blog Post" |
| `text` | Longer text (descriptions, summaries) | "This post is about..." |
| `slug` | URL-friendly version of text | "my-blog-post" |
| `array` | Rich text with multiple elements | Paragraphs, images, code blocks |
| `image` | Upload and manage images | Cover photos, diagrams |
| `datetime` | Date and time picker | Publish schedule |
| `boolean` | Yes/No checkbox | Featured? Published? |
| `number` | Numeric values | Price, rating, count |
| `reference` | Link to another document | Author of a post |

### Adding More Content Types (Advanced)
As you grow, you might want:
- **Author profiles** (your bio, photo, social links)
- **Project showcases** (for your portfolio)
- **Testimonials** (client quotes)
- **Pages** (About, Contact, Services)

Each would have its own schema file, registered in `schemaTypes/index.js`.

---

## Part 6: Connecting to Your Website

Your content lives in Sanity. Your website needs to ask Sanity for that content. This happens through an **API** (Application Programming Interface).

Think of an API like a waiter at a restaurant:
- You (the website) ask the waiter (API) for food (content)
- The waiter goes to the kitchen (Sanity database)
- The waiter brings back your food (content data)

### Step 1: Get Your API Credentials
1. Go to [sanity.io/manage](https://sanity.io/manage)
2. Click on your project ("My Blog")
3. Go to the **API** tab
4. You'll see:
   - **Project ID** (looks like `abc123de`)
   - **Dataset** (usually "production")

**Keep these handy — you'll need them for your website.**

### Step 2: Install the Sanity Client in Your Website
In your website project (the React app), run:

```bash
npm install @sanity/client @sanity/image-url
```

### Step 3: Create the Connection File
Create a new file in your website: `src/lib/sanity.js`

```javascript
import { createClient } from '@sanity/client';
import imageUrlBuilder from '@sanity/image-url';

// Connect to Sanity
const client = createClient({
  projectId: 'YOUR_PROJECT_ID',     // Replace with your actual Project ID
  dataset: 'production',
  apiVersion: '2026-06-28',         // Use today's date
  useCdn: true,                     // true = faster, cached data
});

// Helper for images
const builder = imageUrlBuilder(client);

export function urlFor(source) {
  return builder.image(source);
}

export default client;
```

**Important:** Replace `YOUR_PROJECT_ID` with your actual Project ID from the Sanity dashboard.

### Step 4: Fetch Content in Your Website
Here's how your website asks Sanity for blog posts:

```javascript
import client from './lib/sanity';

// This is GROQ — Sanity's query language
const query = `*[_type == "post"] | order(publishedAt desc) {
  _id,
  title,
  slug,
  excerpt,
  category,
  publishedAt
}`;

// Fetch the posts
client.fetch(query).then((posts) => {
  console.log('My blog posts:', posts);
});
```

**What this GROQ query means:**
| Part | Meaning |
|------|---------|
| `*[_type == "post"]` | Get all documents of type "post" |
| `\| order(publishedAt desc)` | Sort by publish date, newest first |
| `{ _id, title, slug... }` | Only return these specific fields |

### Step 5: Display the Content
Once you have the posts, you display them using React:

```jsx
function Blog() {
  const [posts, setPosts] = useState([]);

  useEffect(() => {
    client.fetch(`*[_type == "post"] | order(publishedAt desc)`)
      .then(setPosts);
  }, []);

  return (
    <div>
      {posts.map((post) => (
        <article key={post._id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
          <span>{post.category}</span>
        </article>
      ))}
    </div>
  );
}
```

---

## Part 7: Publishing and Managing Content

### The Content Lifecycle

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Draft   │ →  │  Review  │ →  │ Publish  │ →  │   Live   │
│ (writing)│    │ (editing)│    │ (click   │    │ (visible)│
│          │    │          │    │  button) │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
       ↑                                            │
       └──────────── Unpublish ──────────────────────┘
```

### Daily Workflow

**To write a new post:**
1. Open Sanity Studio (`http://localhost:3333`)
2. Click **"Create new document"** → **"Blog Post"**
3. Fill in all fields
4. Click **"Publish"**
5. Your website automatically shows the new post (within ~60 seconds)

**To edit an existing post:**
1. In Sanity Studio, find your post in the list
2. Click on it
3. Make changes
4. Click **"Publish"** again

**To unpublish (hide) a post:**
1. Open the post
2. Click the **"Unpublish"** button
3. The post disappears from your website

**To delete a post:**
1. Open the post
2. Click the **"Delete"** button (usually a trash icon)
3. Confirm deletion
4. ⚠️ **Warning:** This permanently removes the post

---

## Part 8: Common Tasks

### Task 1: Upload Images
1. In any post, click the **Cover Image** field
2. Drag and drop an image from your computer, or click to browse
3. Sanity automatically optimizes the image
4. You can crop and adjust the "hotspot" (focus point) for responsive cropping

### Task 2: Add a Code Block to a Post
1. In the **Article Content** rich text editor, click the `+` button
2. Select **"Code block"**
3. Choose the programming language (JavaScript, Python, etc.)
4. Paste or type your code
5. The code will be displayed with syntax highlighting on your website

### Task 3: Schedule a Post for Later
1. Set the **Publish Date** to a future date and time
2. Publish the post
3. It won't appear on your website until that date arrives

### Task 4: Feature a Post
1. Edit the post
2. Check the **"Featured Post?"** checkbox
3. Publish
4. Your website can now highlight this post in a special section

### Task 5: Organize with Tags
1. In the **Tags** field, type a keyword and press Enter
2. Add multiple tags: "react", "tutorial", "beginners"
3. Your website can filter posts by these tags

### Task 6: Deploy Your Studio Online
Right now, your Studio only runs on your computer. To access it from anywhere:

```bash
sanity deploy
```

This gives you a URL like `https://my-blog.sanity.studio` that you can open from any browser, anywhere in the world.

---

## Glossary

| Term | Simple Definition |
|------|-------------------|
| **API** | A way for two computer programs to talk to each other |
| **CMS** | Content Management System — software for creating and managing digital content |
| **Dataset** | A collection of related content (like a database) |
| **Document** | A single piece of content (one blog post, one author profile) |
| **Field** | One piece of information in a document (title, date, image) |
| **GROQ** | Sanity's query language — how you ask for specific content |
| **Headless CMS** | A CMS that only handles content, not website design |
| **Project ID** | A unique identifier for your Sanity project |
| **Rich Text** | Text with formatting — bold, headings, images, links |
| **Schema** | A blueprint that defines what fields a document has |
| **Slug** | A URL-friendly version of a title ("My Post" → "my-post") |
| **Studio** | Sanity's web-based content editor interface |

---

## Quick Reference Card

**Start Studio:**
```bash
cd my-blog-cms
npm run dev
```

**Deploy Studio:**
```bash
sanity deploy
```

**Create new content type:**
1. Create file in `schemaTypes/`
2. Register in `schemaTypes/index.js`
3. Restart Studio

**Fetch all posts (GROQ):**
```javascript
*[_type == "post"] | order(publishedAt desc)
```

**Fetch single post by slug:**
```javascript
*[_type == "post" && slug.current == "my-post"][0]
```

**Fetch posts by category:**
```javascript
*[_type == "post" && category == "tutorial"] | order(publishedAt desc)
```

---

## Next Steps

Now that you understand Sanity, you can:
1. **Write 3-5 blog posts** to populate your website
2. **Add an Author schema** to include your bio with each post
3. **Add a Project schema** to manage your portfolio pieces
4. **Customize the Studio** appearance with your branding
5. **Invite team members** to collaborate on content

**Helpful resources:**
- [Sanity Documentation](https://www.sanity.io/docs)
- [GROQ Query Cheat Sheet](https://www.sanity.io/docs/query-cheat-sheet)
- [Sanity Community Slack](https://slack.sanity.io/)

---

*Congratulations! You now know how to manage content like a pro — no coding required.*
