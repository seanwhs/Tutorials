# 🚀 From Zero to Published  
## Part 2: Building a Modern Portfolio Blog with Next.js 16 & Sanity

### A Beginner-Friendly Step-by-Step Guide for Developers Who Know HTML/CSS/JS But Are New to React, Next.js, and Sanity

Learn React, Next.js 16, Server Components, Headless CMS Architecture, GROQ, SEO, Performance Optimization, and Production Deployment by Building a Real Portfolio Blog from Scratch.

***

## Who This Tutorial Is For

This guide assumes you:

- Are comfortable with **HTML**, **CSS**, and **basic JavaScript**
- Have built a few static pages or small JS apps
- Are **new to React**, **Next.js**, and **Sanity**
- Want to build a **real portfolio website + blog** you can link to on your resume and LinkedIn

You do **not** need:

- Prior React experience
- Prior framework experience
- A complicated development environment

By the end of this tutorial, you will have:

✅ A **portfolio website and blog** powered by Next.js 16  
✅ A **content management system** powered by Sanity  
✅ Dynamic article pages, author profiles, categories, and tags  
✅ Optimized image delivery and SEO-friendly URLs  
✅ Type-safe content models  
✅ Production-ready deployment on **Vercel**

And you will understand **every** technology involved, from first principles.

***

# Introduction

Most tutorials teach you how to copy and paste code.

This tutorial teaches you how modern content platforms and developer portfolios actually work.

By the end of this guide you will have built:

* A **portfolio website + blog** powered by Next.js 16
* A content management system powered by **Sanity**
* Dynamic article pages
* Author profiles (for you, and optionally collaborators)
* Categories and tags for organizing your content
* Optimized image delivery for thumbnails and hero images
* SEO-friendly URLs and metadata
* Type-safe content models
* Production-ready deployment on Vercel

More importantly, you will understand every technology involved.

Nothing will be treated as magic.

Every concept will be explained from first principles, in plain language, before you type any code.

***

# What We Are Building

Before writing any code, let's understand the system we are about to create and how it fits your portfolio needs.

Imagine your final project as two main parts:

* **Content Brain**: where you write and manage posts, project writeups, and profile information (**Sanity**).
* **Presentation Skin**: what visitors actually see in their browser (**Next.js 16**).

```text
┌────────────────────────────┐
│       Sanity Studio        │
│    Content Management UI   │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│       Content Lake         │
│  Structured Content Store  │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│        Next.js 16          │
│  Portfolio + Blog Frontend │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│          Visitors          │
│  Recruiters • Clients etc. │
└────────────────────────────┘
```

When you (or any editor) publish an article:

1. The article is stored in **Sanity's Content Lake**.
2. The Next.js 16 app requests that content through Sanity's APIs.
3. Next.js renders the content into HTML, using React Server Components where possible.
4. Readers see the article on your portfolio blog with fast loading and good SEO.

This architecture powers:

* Company blogs
* Marketing websites
* Documentation portals
* Ecommerce content systems
* Enterprise publishing platforms

And now, **your developer portfolio + blog** will use the same architectural principles.

***

# Part I

## Understanding the Technologies Before Writing Code

Many beginners struggle because they start coding before they understand **what problem each tool is solving**.

In this part, you will not write any code.

Instead, you will build mental models:

* How websites evolved
* What React does
* What Next.js adds on top of React
* What a CMS is
* Why Sanity fits a modern portfolio/blog

Think of this as learning the map before driving the car.

***

# Chapter 1

## How Websites Evolved

### Static Websites

The earliest websites looked like this:

```html
<h1>My Blog</h1>
<p>Hello World</p>
```

Every page was manually written by editing `.html` files.

If you wanted ten blog posts, you might have:

```text
post1.html
post2.html
post3.html
...
post10.html
```

Each file repeated the header, footer, navigation, and styles.

**Problems:**

* Duplicate layouts across many files
* Difficult maintenance when designs change
* No real content management (everything is manual)
* Poor scalability as the site grows

Static sites are simple, but they don't scale well when you have a lot of content or non-technical editors.

***

### Traditional CMS Platforms

Systems such as WordPress introduced **dynamic publishing** and a web-based admin panel.

**Architecture:**

```text
Browser
   │
   ▼
WordPress (PHP)
   │
   ▼
Database (MySQL)
```

**Benefits:**

* Easy publishing through a browser
* User accounts and roles (admin, editor, author)
* Admin dashboards for managing content

**Problems:**

* The frontend is tightly coupled to the backend
* Plugins can conflict and become a maintenance burden
* Deep customization often requires fighting the platform
* Performance and security can become issues at scale

Traditional CMSs are great for non-technical users but less ideal when you want:

* A modern React-based frontend
* Full control over design and performance
* The ability to use the same content in multiple places (website, mobile app, documentation, etc.)

***

### Headless CMS Architecture

Modern systems separate **content** from **presentation**.

```text
Content (Sanity)
   │
   ▼
API (HTTP / GROQ)
   │
   ▼
Frontend (Next.js)
```

**Benefits:**

* Independent scaling: the CMS and frontend can scale separately.
* Better performance: your frontend can use CDNs and static generation.
* Better security: your content store is not directly exposed as HTML templates.
* Omnichannel publishing: the same content can power web, mobile, documentation, in-app help, etc.

This is the architecture you will build for your portfolio blog.

***

# Chapter 2

## Understanding React

Before understanding Next.js, you must understand **React**.

React is a **user interface library**.

Its primary goal is:

> Build reusable UI components that describe how the UI looks.

Without React, you might copy-paste the same markup everywhere:

```html
<h1>Home</h1>
<h1>About</h1>
<h1>Contact</h1>
```

With React, you can create a reusable component:

```tsx
function Heading() {
  return <h1>My Blog</h1>
}
```

Then reuse it:

```tsx
<Heading />
<Heading />
<Heading />
```

**Advantages:**

* **Reusability:** one definition, many uses.
* **Maintainability:** change the component once, all usages update.
* **Predictability:** UI is a pure function of props and state.

Everything in React is built from **components**.

You will use React components to define:

* Layouts (header, footer, navigation)
* Pages (home, blog, about)
* Reusable parts (post cards, author badges, tag chips)

### The Tiny Bit of React You Need Right Now

In this tutorial, we will mostly use **simple function components**:

```tsx
type HeadingProps = {
  title: string
}

function Heading({ title }: HeadingProps) {
  return <h1>{title}</h1>
}
```

You can think of this like a JavaScript function that takes an object as a parameter and returns JSX:

```ts
function heading(props) {
  return `<h1>${props.title}</h1>`
}
```

The difference is: the React version is type-safe (with TypeScript) and integrates with the rest of the React ecosystem.

In React terms:

* A **component** is a function that returns JSX.
* **Props** are the "parameters" a component receives from its parent.
* **State** is data a component manages itself (you'll mostly use Server Components for data in this tutorial).

***

# Chapter 3

## Understanding Next.js 16

React solves **how to build UI**.

Next.js solves **how to build an application around that UI**.

React alone does not provide:

* Routing (URLs → pages)
* SEO features (HTML `<head>` management)
* Image optimization and caching
* Data fetching conventions and caching
* Static generation, streaming, or server-side rendering
* Opinionated deployment strategies

Next.js 16 adds these production features on top of React.

Think of Next.js as:

```text
React
+
Production Features (routing, data fetching, builds)
=
Next.js
```

For your portfolio blog, this means:

* Clean URLs like `/blog/my-first-post`
* Automatic performance optimizations
* Server Components by default in the App Router
* Easy deployment to platforms like Vercel

***

# Chapter 4

## The Most Important Next.js 16 Concept: Server Components

One of the biggest innovations in modern React development is **React Server Components**, heavily used in the Next.js App Router.

**Traditional (client-only) React:**

```text
Browser
   │
   ▼
Download JavaScript
   │
   ▼
Fetch Data in the Browser
   │
   ▼
Render UI in the Browser
```

**React Server Components in Next.js 16:**

```text
Server
   │
   ▼
Fetch Data (e.g., from Sanity)
   │
   ▼
Render HTML on the Server
   │
   ▼
Send Result to Browser
```

**Advantages:**

* Faster initial page loads (less JavaScript shipped)
* Smaller bundles, better Core Web Vitals
* Better SEO because HTML arrives already rendered
* Improved scalability because the server does more work once, instead of every browser doing everything

In this tutorial, you will primarily use **Server Components** for your pages and data fetching.

You will also see where **Client Components** make sense (for interactive elements like theme toggles or interactive filters).

For this portfolio blog, Server Components mean your readers get HTML quickly, which helps both user experience and SEO, especially when sharing your posts on social media.

***

# Chapter 5

## Understanding Content Management Systems

A **Content Management System (CMS)** allows content creators to manage content without editing source code.

Examples:

* WordPress
* Drupal
* Ghost
* Sanity

Instead of modifying HTML files like:

```html
<h1>My Article</h1>
<p>Some content...</p>
```

an editor writes content through a web-based interface.

The CMS:

* Stores the content in a structured way
* Handles drafts, publishing, and revisions
* Exposes content via an API or template system

In your portfolio blog:

* You will act as both **developer** and **editor**.
* You will still benefit from having a real CMS: you can add/edit posts without touching code once the system is set up.

***

# Chapter 6

## Why We Are Using Sanity

Sanity is a **headless CMS** with a flexible content model and a React-based studio.

Instead of storing pages, Sanity stores **structured content** (documents and fields).

Sanity refers to this storage layer as the **Content Lake**.

Think of it as:

```text
Posts
Authors
Categories
Tags
Images
Site Settings
Navigation
Projects (later)
Testimonials (later)
```

stored as structured documents.

**Advantages:**

* Reusable content across different sections of your portfolio.
* Real-time updates in the Studio and Content Lake.
* API-first architecture with a flexible query language (GROQ).
* Strong typing and schema definitions that live in code.
* Excellent developer experience when combined with React/Next.js.

Sanity lets you treat content as data, not just HTML blobs.

This is perfect for a portfolio that may grow into:

* Multiple content sections (blog, projects, talks)
* Multiple authors or collaborators
* Different layouts based on content type

You can think of the Content Lake as "Sanity's cloud database for content," but you never write SQL; you just define schemas in JavaScript/TypeScript.

***

# Chapter 7

## Content Modeling Before Coding

Professional CMS projects **do not start by coding**.

They start with **content modeling**: designing the shapes of your data.

For your portfolio blog, your core content types will be:

```text
Post
 ├── Title
 ├── Slug
 ├── Excerpt
 ├── Cover Image
 ├── Body
 ├── Author
 ├── Categories
 ├── Tags (optional)
 └── Published Date
```

Additional content types:

```text
Author
 ├── Name
 ├── Biography
 ├── Profile Image
 └── Social Links (GitHub, LinkedIn, etc.)
```

```text
Category
 ├── Name
 └── Slug
```

```text
Site Settings
 ├── Site Title
 ├── Description
 ├── Primary Color / Theme
 └── Social Links
```

Later, you can add types like:

```text
Project
 ├── Title
 ├── Slug
 ├── Tech Stack
 ├── Description
 ├── Live URL
 └── GitHub URL
```

These models become the **blueprints** for your CMS.

They also map directly to TypeScript types later in the tutorial, so your editor can autocomplete your content fields.

***

# Part II

## Creating the Next.js 16 Project

At the end of this section you will have:

* A working Next.js 16 application
* Tailwind CSS configured for styling (optional but recommended)
* TypeScript configured (for safer code and better editor support)
* App Router enabled (the modern Next.js routing system)
* A development environment running at `http://localhost:3000`

You will see your first custom homepage and understand how routing works.

***

# Chapter 8

## Installing Node.js

### What is Node.js?

Node.js is a **JavaScript runtime** that runs outside the browser.

Normally, JavaScript runs inside browsers like Chrome or Firefox.

Node.js allows JavaScript to run on your computer directly. This enables:

* Development servers (like `next dev`)
* Build tools (like the Next.js compiler)
* Package managers (npm, pnpm, yarn)
* Automation scripts (linting, formatting, deployments)

### Install Node.js

1. Go to the official Node.js website.
2. Download the **LTS** version (recommended for stability).
3. Install it using the installer for your operating system.

After installation, open a terminal and verify:

```bash
node -v
npm -v
```

**What these commands do:**

* `node -v` prints the installed Node.js version. It verifies that Node.js is available on your system path.
* `npm -v` prints the installed npm (Node Package Manager) version. npm comes with Node and is used to install JavaScript packages.

If both commands show a version number, you are ready to proceed.

***

# Chapter 9

## Creating the Application

In your terminal, navigate to the folder where you want to create your project, then run:

```bash
npx create-next-app@latest my-portfolio-blog
```

### What is `npx`?

* `npx` is a tool that comes with npm.
* It allows you to run a package **without** installing it globally.
* Here, it downloads and runs `create-next-app` directly.

### What is `npm`?

* `npm` stands for **Node Package Manager**.
* It manages JavaScript packages (libraries) that your project depends on.

### What are "packages" and "dependencies"?

* A **package** is a reusable chunk of code (like Next.js, React, or Tailwind).
* A **dependency** is a package your project relies on to work.
* Dependencies are listed in `package.json` so others (or deployment platforms) can install them automatically.

### Setup options

`create-next-app` will ask you several questions. For this tutorial, choose:

* **TypeScript**: Yes (we want type safety and better DX).
* **ESLint**: Yes (helps catch common mistakes).
* **Tailwind CSS**: Yes (makes styling easier and consistent).
* **App Router**: Yes (this is the modern Next.js routing system).
* **Turbopack**: Optional; you can enable it for faster local builds if offered.

For beginners, using the defaults suggested by the CLI is usually safe unless this tutorial specifies otherwise.

***

# Chapter 10

## Understanding the Generated Project Structure

After `create-next-app` finishes, open the project folder in your editor.

You will see a structure like:

```text
src/
  app/
public/
package.json
next.config.ts
tsconfig.json
tailwind.config.ts
postcss.config.mjs
```

### Key folders and files

* `src/`  
  Where your application code lives (components, routes, etc.).

* `src/app/`  
  This is the **App Router** root. Each folder inside `app` can represent a route (like `/blog`, `/about`).

* `public/`  
  Static assets you want to serve directly (e.g., favicon, static images).

* `package.json`  
  Lists your dependencies and scripts (`npm run dev`, `npm run build`, etc.).

* `next.config.ts`  
  Configuration for Next.js (images, experimental features, etc.).

* `tsconfig.json`  
  TypeScript configuration (compiler options, path aliases, etc.).

* `tailwind.config.ts` and `postcss.config.mjs`  
  Configuration files for Tailwind CSS and PostCSS.

### How App Router Works

In the App Router:

* A folder with a `page.tsx` file becomes a route.
* For example, `app/page.tsx` is the `/` route (homepage).
* `app/blog/page.tsx` becomes `/blog`.
* `app/blog/[slug]/page.tsx` becomes `/blog/:slug` for dynamic routes.

**Checkpoint:** Your first custom homepage

1. Open `src/app/page.tsx`.
2. Replace the default content with:

   ```tsx
   export default function Home() {
     return <h1>My Portfolio Blog</h1>
   }
   ```

3. Run:

   ```bash
   npm run dev
   ```

4. Visit `http://localhost:3000` in your browser.

**What you should see:**

You should see a simple page with large text at the top reading:

> My Portfolio Blog

At this point, you have a working Next.js 16 app.

***

# Part III

## Creating the Sanity Studio

Goal:

Create a content management system for your portfolio blog.

By the end of this section you will be able to:

* Create content (posts, authors, categories)
* Edit content in a browser
* Upload images
* Publish articles
* See these changes later reflected in your Next.js app

***

# Chapter 11

## Installing and Configuring Sanity

At the end of this chapter you will have:

* A working Sanity project
* A local Sanity Studio running in your browser
* A configured Content Lake in the cloud
* Secure local development access (CORS set up correctly)

***

## What Are We Installing?

So far you have built a **frontend application** with Next.js.

Now you need a place to store your content.

This is where Sanity comes in.

Sanity provides two major pieces of infrastructure:

### 1. Content Lake

The **Content Lake** is Sanity's cloud-hosted content database.

Think of it as:

```text
Posts
Authors
Categories
Images
Site Settings
Projects (optional later)
```

stored as structured documents.

Unlike a traditional SQL database, the Content Lake is optimized specifically for **content** and supports real-time updates and flexible querying.

### 2. Sanity Studio

**Sanity Studio** is the administrative interface (built in React) that content creators use.

Instead of writing blog posts inside code files:

```html
<h1>My Blog Post</h1>
```

you will create content using a professional editing environment with:

* Rich text fields
* Image upload
* Referencing authors and categories
* Validation

Think of Sanity Studio as:

```text
WordPress Admin
        +
Modern Headless CMS
        =
Sanity Studio
```

You will embed this Studio inside your Next.js app so it lives at a route like `/studio`.

***

## Creating a Sanity Project

Open a new terminal (or a split pane) and run:

```bash
npm create sanity@latest
```

The CLI will guide you through several questions.

For this tutorial, choose:

* **Create New Project**
* A **Blog** or "Clean" template (if a blog template is available, pick that for faster schema setup).
* **TypeScript**
* **Hosted Dataset** (recommended for beginners)
* If asked for a project name, use something like `portfolio-blog-sanity`.

When the installation finishes, Sanity:

* Creates a new folder for your Studio.
* Provisions a Content Lake in the cloud.
* Generates default schemas if you chose a starter template.

***

## Understanding What Just Happened

Behind the scenes, your architecture now looks like:

```text
Your Computer
      │
      ▼
Sanity Studio (React app)
      │
      ▼
Content Lake (Sanity cloud)
      │
      ▼
Sanity API (for reading/writing content)
```

The Studio runs locally in your browser.

The Content Lake lives in the cloud.

Later, your Next.js portfolio blog will communicate with the Content Lake through Sanity's APIs using GROQ queries.

***

## Starting the Sanity Studio

Navigate into your Sanity project folder:

```bash
cd sanity-blog
npm run dev
```

You should see output similar to:

```text
Local: http://localhost:3333
```

Open that URL in your browser.

You should see the Sanity Studio login/landing page.

Once you sign in (or create an account), you can access your project and start creating documents.

At this point you already have a functioning content management system.

**Checkpoint:** Sanity Studio is running

* In your browser, you should see Sanity Studio at `http://localhost:3333`.
* You should be able to log in and see your project dashboard listing documents like "Post", "Author", and "Category" (if you used a blog template).

***

## Understanding CORS

Before you connect Next.js and Sanity, you need to discuss an important security concept: **CORS**.

Many beginner tutorials skip this step and readers become confused when requests suddenly fail with mysterious browser errors.

### What is CORS?

CORS stands for:

**Cross-Origin Resource Sharing**.

Browsers enforce a security rule called the **Same-Origin Policy**.

Imagine:

```text
Website A (origin A)
   │
   ├── Automatically allowed to access origin A
   │
   └── Not automatically allowed to access origin B
```

This prevents malicious websites from silently accessing sensitive resources from other sites.

### Why Does Sanity Need CORS Configuration?

When your blog runs locally at:

```text
http://localhost:3000
```

and Sanity's API endpoint runs at:

```text
https://<your-project-id>.api.sanity.io
```

the browser sees these as different **origins**.

Therefore, Sanity must explicitly approve your local application as a trusted origin.

Without approval:

```text
Browser
   │
   ▼
Sanity API
   │
   ▼
❌ Request Blocked (CORS error)
```

With approval:

```text
Browser
   │
   ▼
Sanity API
   │
   ▼
✅ Request Allowed
```

This is why configuring CORS is essential before wiring up your queries.

***

## Configuring Local Development Access

To allow your Next.js application to communicate with Sanity during development:

### Step 1: Open the Management Dashboard

1. Go to the Sanity management dashboard in your browser.
2. Log in and navigate to your project.

### Step 2: Open API Settings

Inside the project dashboard, find:

```text
Project Settings
 └── API
```

Open the **API configuration** section.

### Step 3: Add a New CORS Origin

Click:

```text
Add CORS Origin
```

Enter:

```text
http://localhost:3000
```

This tells Sanity to allow requests from your local Next.js app.

### Step 4: Enable Credentials

Check:

```text
Allow Credentials
```

This permits authenticated requests during local development (for features like draft previews and Studio embedding).

Features such as:

* Preview Mode
* Viewing Draft Content
* Authenticated API requests
* Secure content previews inside your portfolio site

rely on browser credentials such as cookies. Enabling credentials now prevents future configuration issues that can be hard to debug.

### Step 5: Save Changes

Your configuration should now resemble:

```text
Origin:
http://localhost:3000

Credentials:
✓ Enabled
```

Click **Save**.

***

## Returning to Your Next.js Application

Now switch back to the Next.js project folder (e.g., `my-portfolio-blog`).

Start the development server:

```bash
npm run dev
```

You should see output similar to:

```text
Local: http://localhost:3000
```

***

## Viewing the Application

Open:

```text
http://localhost:3000
```

This is your public-facing portfolio homepage.

Visitors (recruiters, hiring managers, clients) will eventually land here to:

* Read your about section
* See your featured projects
* Read your blog posts (powered by Sanity)

***

## Accessing the Content Management Dashboard

In this tutorial, you will use an **embedded Studio** architecture, where Sanity Studio is served from within your Next.js app at a route like `/studio`.

Once you wire it up (later chapters), you will be able to open:

```text
http://localhost:3000/studio
```

This will be your content management dashboard.

From here you will:

* Create blog posts
* Upload images
* Manage authors
* Create categories
* Configure site settings (site title, description, social links)

***

## What You Have Accomplished So Far

At this point you have:

✅ Created a Next.js 16 application with the App Router  
✅ Created a Sanity project with a Content Lake in the cloud  
✅ Set up a local Sanity Studio  
✅ Configured local development security via CORS  
✅ Registered `http://localhost:3000` as a CORS origin with credentials  
✅ Started both the Next.js dev server and Sanity Studio

You now have **both halves** of a modern content platform ready:

* The frontend (Next.js)  
* The backend/content layer (Sanity)

Next, you will shape **what** content can exist.

***

# Chapter 12

## Building Content Schemas

In this chapter, you will define the content types that power your portfolio blog.

You will create:

* `Post` schema (for blog posts)
* `Author` schema (for you and any collaborators)
* `Category` schema (for organizing posts)
* `Site Settings` schema (site-level configuration)

Along the way you will learn key Sanity concepts:

* **Documents**: top-level records (e.g., a post, an author).
* **Fields**: properties inside documents (e.g., `title`, `slug`, `body`).
* **References**: links from one document to another (e.g., a post referencing an author).
* **Arrays**: lists of things (e.g., categories on a post).
* **Validation**: rules that prevent invalid content (e.g., required titles).
* **Rich text / Portable Text**: structured content for the body of a post.

You will then publish your **first article** through the Studio and confirm it appears as a document in the Content Lake.

**Checkpoint:** First article published

* In Sanity Studio, create a new Post.
* Fill in at least:
  * Title
  * Slug
  * Excerpt
  * A short body (a few paragraphs)
* Publish the post.
* In the Studio, you should see your post listed under "Post".

In the next part of this tutorial series, you will:

* Connect Next.js to Sanity
* Build queries with GROQ
* Render real blog posts on your homepage and article pages
* Add dynamic routing, SEO, performance optimizations, and production deployment
