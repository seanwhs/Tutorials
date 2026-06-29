# Next.js 16 for Absolute Beginners

## Part 2 — Creating Your First Next.js Application

> **Goal of this lesson:** Install Next.js 16, create your first project, explore every generated file and folder, and understand how the App Router turns folders into URLs.

---

### What Happens When You Run `create-next-app`?

In Part 1, we learned that Next.js is a powerful framework built on React. Now it’s time to create your first real application.

The official command is:

```bash
npx create-next-app@latest
```

This single command does a lot of work for you:

- Downloads the latest Next.js starter template
- Creates a new project folder
- Installs React 19 and Next.js 16
- Sets up TypeScript (recommended)
- Configures ESLint for code quality
- Adds Tailwind CSS for styling
- Creates the modern **App Router** structure
- Sets up Turbopack (the fast new dev server)

Think of it as getting a **complete, production-ready starter kit** instead of building everything from scratch.

---

### Before You Begin

Make sure Node.js is installed and up to date:

```bash
node --version
# Should show v20.18+ or v22.x / v24.x

npm --version
```

If you don’t have Node.js, download it from [nodejs.org](https://nodejs.org).

---

### Creating the Project

Open your terminal and run:

```bash
npx create-next-app@latest
```

You’ll be asked several questions. Here are the recommended answers for this course:

| Question                                 | Answer | Reason |
|------------------------------------------|--------|--------|
| Project name?                            | `next16-beginner` | Clear and descriptive |
| TypeScript?                              | Yes    | Industry standard + better developer experience |
| ESLint?                                  | Yes    | Catches bugs early |
| Tailwind CSS?                            | Yes    | Fast, modern styling (widely used with Next.js) |
| `src/` directory?                        | Yes    | Cleaner project structure |
| App Router?                              | Yes    | The future of Next.js |
| Turbopack?                               | Yes    | Much faster development server |
| Customize import aliases?                | No     | Keep it simple for now |

After installation completes:

```bash
cd next16-beginner
npm run dev
```

Open your browser and go to: **http://localhost:3000**

You should see the default Next.js welcome page. **Congratulations!** You’ve created your first Next.js 16 application.

---

### Understanding the Project Structure

Here’s what your project looks like:

```text
next16-beginner/
├── src/
│   └── app/
│       ├── favicon.ico
│       ├── globals.css
│       ├── layout.tsx
│       └── page.tsx
├── public/
├── .gitignore
├── eslint.config.mjs
├── next.config.ts
├── package.json
├── tsconfig.json
├── README.md
└── tailwind.config.ts
```

Don’t worry — it looks more intimidating than it is. Let’s break it down.

---

### Important Files & Folders

#### `package.json`
This is the heart of your project. It lists dependencies and scripts:

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

**Key commands:**
- `npm run dev` — Start development server (with hot reload)
- `npm run build` — Create optimized production build
- `npm start` — Run the production build locally

#### `next.config.ts`
Configuration file for Next.js. Currently mostly empty, but we’ll use it later to enable Next.js 16 features like enhanced caching.

#### `public/`
Stores static files (images, fonts, PDFs, etc.) that are served directly.

Anything placed here is available at the root URL:
- `public/logo.png` → accessible at `/logo.png`

#### `src/app/`
This is the **most important folder** in modern Next.js. It uses the **App Router**.

---

### File-System Routing (The Magic)

In Next.js, **folders = routes**.

Create a folder → you get a new URL. It’s that simple.

Let’s try it.

---

### Your First Custom Page

Replace the content of `src/app/page.tsx` with:

```tsx
export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8">
      <h1 className="text-5xl font-bold mb-4">My First Next.js 16 App</h1>
      <p className="text-xl text-gray-600">
        Welcome to the future of web development.
      </p>
    </main>
  );
}
```

Save the file and refresh **http://localhost:3000**. You’ll see your new homepage.

---

### Creating More Pages

1. Create folder: `src/app/about`
2. Inside it, create `page.tsx`:

```tsx
export default function AboutPage() {
  return (
    <main className="p-8">
      <h1 className="text-4xl font-bold">About Me</h1>
      <p className="mt-4 text-lg">I am learning Next.js 16 from scratch.</p>
    </main>
  );
}
```

Visit: **http://localhost:3000/about**

3. Create a Contact page:

- Folder: `src/app/contact`
- File: `page.tsx`

```tsx
export default function ContactPage() {
  return (
    <main className="p-8">
      <h1 className="text-4xl font-bold">Contact</h1>
      <p className="mt-4">Email: hello@yourname.com</p>
    </main>
  );
}
```

Now visit: **http://localhost:3000/contact**

---

### Why File-System Routing is Powerful

**Traditional React (with React Router):**
- Install extra library
- Configure routes in one central file
- Maintain a big route table

**Next.js App Router:**
- Just create folders and `page.tsx` files
- Automatic routing, code splitting, and performance optimizations

This simplicity is one of the biggest reasons developers love Next.js.

---

### What is `export default`?

Every `page.tsx` file must export a **default component**. This is the component Next.js will render for that route.

```tsx
export default function PageName() {
  return <div>...</div>;
}
```

You can name the function anything, but `export default` is required.

---

### JSX Quick Refresher

You’ve seen this syntax:

```tsx
<h1>Hello World</h1>
```

This is **JSX** — a syntax extension that lets you write HTML-like code inside JavaScript/TypeScript. Under the hood, it gets transformed into efficient React elements.

You almost never need to write the long `React.createElement()` version.

---

### Exercises

**Exercise 1:** Create a `/projects` page

**Exercise 2:** Create a `/blog` page

**Exercise 3:** Create a `/services` page

**Bonus:** Make each page have a slightly different heading and short description using Tailwind classes.

After completing them, your folder structure should look like this:

```text
src/app/
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

### What You’ve Learned

- How to create a Next.js 16 project with best practices
- The purpose of key files (`package.json`, `next.config.ts`, etc.)
- How the App Router and file-system routing work
- How to create new pages
- Basics of JSX and default exports

---

### What’s Next? (Part 3 Preview)

In the next chapter, we’ll explore one of Next.js’s most powerful features: **Layouts**.

You’ll learn:
- How to create persistent navigation and footers
- Why layouts are better than repeating code
- Root layouts vs nested layouts
- Shared UI across pages

This is where your app starts feeling like a real, professional website.

---

**Ready for Part 3?** Let me know when you want it, or if you’d like any adjustments to this chapter first!
