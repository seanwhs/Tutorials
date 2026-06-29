# Next.js 16 for Absolute Beginners

# Part 2 — Creating Your First Next.js Application

> **Goal of this lesson:** Install Next.js 16, create your first project, explore the generated files and folders, understand the App Router, and learn about some common real-world issues that beginners encounter.

---

## What Happens When You Run `create-next-app`?

In Part 1, we learned that Next.js is a full-stack React framework designed for building modern web applications.

Now it's time to create your first real Next.js application.

The official command is:

```bash
npx create-next-app@latest
```

Although this looks like a simple command, it actually performs a tremendous amount of work for you.

It:

* Downloads the latest Next.js template
* Creates a new project directory
* Installs Next.js 16
* Installs React 19
* Configures TypeScript
* Configures ESLint
* Configures Tailwind CSS
* Sets up the App Router
* Enables Turbopack for development
* Creates a Git repository
* Generates all required configuration files

Think of it as receiving a fully configured, production-ready starter project rather than having to assemble everything manually.

---

## Before You Begin

Verify that Node.js is installed:

```bash
node --version
npm --version
```

For Next.js 16, you should have:

```bash
v20.18+
```

or newer LTS versions:

```bash
v22.x
v24.x
```

If Node.js is not installed, download it from:

https://nodejs.org

---

## Creating Your First Project

Open your terminal and run:

```bash
npx create-next-app@latest
```

In Next.js 16, you'll typically see something similar to:

```text
Would you like to use the recommended Next.js defaults?
```

For this course, choose:

```text
Yes, use recommended defaults
```

This creates a project with:

| Feature        | Enabled |
| -------------- | ------- |
| TypeScript     | ✓       |
| ESLint         | ✓       |
| Tailwind CSS   | ✓       |
| React Compiler | No      |
| App Router     | ✓       |
| Turbopack      | ✓       |
| AGENTS.md      | ✓       |

If you prefer to customize everything manually, use:

```text
No, customize
```

---

## Installing the Application

Once installation completes:

```bash
cd next16-beginner
npm run dev
```

You should see:

```text
▲ Next.js 16.x (Turbopack)

✓ Ready in 1s
```

Open your browser:

```text
http://localhost:3000
```

You should see the default Next.js welcome page.

Congratulations! You have created your first Next.js 16 application.

---

## Verifying Your Installation

Before continuing, verify your framework versions:

```bash
npm ls next react react-dom
```

Expected output:

```text
next@16.x
react@19.x
react-dom@19.x
```

This confirms your installation is correct.

---

## Understanding Turbopack

In older versions of Next.js, the development server used Webpack.

Next.js 16 now uses **Turbopack** by default.

Turbopack is:

* written in Rust
* significantly faster than Webpack
* optimized for incremental updates
* capable of near-instant hot reloads

This is why your development server starts in under a second.

---

## Common Warning: Workspace Root Detection

Some developers encounter a warning similar to:

```text
Warning: Next.js inferred your workspace root,
but it may not be correct.
```

For example:

```text
Detected multiple lockfiles:

Documents/package-lock.json
learn-next/package-lock.json
```

This happens because Next.js searches upward for workspace boundaries.

Example:

```text
Documents/
├── package-lock.json
└── learn-next/
    └── package-lock.json
```

### Recommended Fix

Delete the accidental parent lockfile:

Windows:

```powershell
Remove-Item ..\package-lock.json
```

Linux/macOS:

```bash
rm ../package-lock.json
```

### Alternative Fix

Configure Turbopack manually:

```js
import path from "path";

/** @type {import('next').NextConfig} */
const nextConfig = {
  turbopack: {
    root: path.resolve(__dirname),
  },
};

module.exports = nextConfig;
```

Most developers never need this configuration.

---

## Important Warning: Avoid `npm audit fix --force`

After installation, you may see:

```bash
npm audit
```

reporting vulnerabilities.

Do not immediately run:

```bash
npm audit fix --force
```

This command can accidentally downgrade framework packages.

For example:

```text
next@16
↓
next@9
```

This occurs because npm prioritizes security constraints over framework compatibility.

Instead, use:

```bash
npm audit
npm audit fix
```

Or simply ignore framework-level advisories in freshly generated projects.

> Rule of thumb:
>
> Never run `npm audit fix --force` immediately after creating a modern framework project.

---

## Understanding the Project Structure

Depending on your choices, your project may look like:

```text
next16-beginner/
├── app/
│   ├── favicon.ico
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── public/
├── .gitignore
├── eslint.config.mjs
├── next.config.ts
├── package.json
├── tsconfig.json
├── postcss.config.mjs
└── README.md
```

If you chose the `src` option:

```text
next16-beginner/
└── src/
    └── app/
```

Don't worry if this looks overwhelming. We'll break it down piece by piece.

---

## Important Files and Folders

### `package.json`

This is the heart of your application.

Example:

```json
{
  "name": "next16-beginner",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "16.x",
    "react": "^19",
    "react-dom": "^19"
  }
}
```

Useful commands:

```bash
npm run dev
```

Starts the development server.

```bash
npm run build
```

Creates a production build.

```bash
npm start
```

Runs the production build locally.

---

### `next.config.ts`

This file configures Next.js behavior.

Most projects start with:

```ts
const nextConfig = {};

export default nextConfig;
```

Later, you'll use this file for:

* caching
* image optimization
* middleware configuration
* Turbopack settings
* experimental features

---

### `public/`

The `public` folder stores static assets.

Example:

```text
public/logo.png
```

becomes:

```text
http://localhost:3000/logo.png
```

Typical files stored here:

* images
* PDFs
* fonts
* videos
* icons

---

### `app/` (or `src/app/`)

This is the most important folder in modern Next.js.

It powers the **App Router**.

---

# File-System Routing: The Magic of Next.js

In Next.js:

> Folders become URLs.

For example:

```text
app/
├── page.tsx
├── about/
│   └── page.tsx
└── contact/
    └── page.tsx
```

creates:

```text
/
 /about
 /contact
```

No routing configuration is required.

---

## Creating Your First Custom Page

Open:

```text
app/page.tsx
```

Replace its contents:

```tsx
export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8">
      <h1 className="text-5xl font-bold mb-4">
        My First Next.js 16 App
      </h1>

      <p className="text-xl text-gray-600">
        Welcome to the future of web development.
      </p>
    </main>
  );
}
```

Save the file.

Turbopack automatically refreshes the browser.

Visit:

```text
http://localhost:3000
```

---

## Creating More Pages

Create:

```text
app/about/page.tsx
```

```tsx
export default function AboutPage() {
  return (
    <main className="p-8">
      <h1 className="text-4xl font-bold">
        About Me
      </h1>

      <p className="mt-4 text-lg">
        I am learning Next.js 16 from scratch.
      </p>
    </main>
  );
}
```

Visit:

```text
http://localhost:3000/about
```

---

Create:

```text
app/contact/page.tsx
```

```tsx
export default function ContactPage() {
  return (
    <main className="p-8">
      <h1 className="text-4xl font-bold">
        Contact
      </h1>

      <p className="mt-4">
        Email: hello@yourname.com
      </p>
    </main>
  );
}
```

Visit:

```text
http://localhost:3000/contact
```

---

## Why File-System Routing Is Powerful

### Traditional React

You typically need:

* React Router
* route configuration files
* route tables
* route maintenance

### Next.js App Router

You simply:

* create folders
* add `page.tsx`
* navigate to the URL

Next.js automatically provides:

* routing
* code splitting
* lazy loading
* server rendering
* performance optimizations

---

## What Is `export default`?

Every route file must export a default component:

```tsx
export default function Page() {
  return <div>Hello</div>;
}
```

The function name is arbitrary.

The `default export` is what Next.js actually uses.

---

## JSX Refresher

This syntax:

```tsx
<h1>Hello World</h1>
```

is called JSX.

JSX allows you to write HTML-like syntax inside JavaScript and TypeScript.

Internally:

```tsx
<h1>Hello</h1>
```

becomes:

```js
React.createElement("h1", null, "Hello")
```

Fortunately, modern React handles this transformation automatically.

---

## Exercises

### Exercise 1

Create:

```text
/projects
```

---

### Exercise 2

Create:

```text
/blog
```

---

### Exercise 3

Create:

```text
/services
```

---

### Bonus Challenge

Use Tailwind classes to make each page visually distinct.

Your final structure should resemble:

```text
app/
├── page.tsx
├── about/
│   └── page.tsx
├── contact/
│   └── page.tsx
├── projects/
│   └── page.tsx
├── blog/
│   └── page.tsx
└── services/
    └── page.tsx
```

---

## What You've Learned

You now understand:

* how to create a Next.js 16 project
* how `create-next-app` works
* how Turbopack works
* how App Router file-system routing works
* how pages are created
* how workspace root detection works
* why `npm audit fix --force` is dangerous
* how JSX and default exports work

---

## What's Next?

In Part 3, we'll explore one of the most important concepts in Next.js:

# Layouts

You'll learn:

* root layouts
* nested layouts
* shared navigation
* persistent UI
* reusable page structures

This is where your application begins to feel like a real professional website.
