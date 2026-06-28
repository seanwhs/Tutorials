# Next.js 16 for Absolute Beginners

# Part 2 — Creating Your First Next.js Application

> **Goal of this lesson:** Install Next.js 16, create your first project, and understand every file and folder that Next.js generates.

---

# What Happens When We Create a Next.js Project?

In the previous chapter, we learned that Next.js is a framework built on top of React.

Now we're going to create our first Next.js application.

The command we'll use is:

```bash
npx create-next-app@latest
```

This command:

1. Downloads the latest Next.js project generator.
2. Creates a new project folder.
3. Installs React.
4. Installs Next.js.
5. Configures TypeScript.
6. Configures ESLint.
7. Creates the App Router structure.
8. Creates a development server.

Think of it as generating a complete starter application.

---

# Before We Begin

Verify that Node.js is installed:

```bash
node --version
```

Example:

```bash
v24.2.0
```

Verify npm:

```bash
npm --version
```

Example:

```bash
11.4.2
```

---

# Creating Our Project

Open a terminal:

```bash
npx create-next-app@latest
```

You'll see questions similar to this:

```text
What is your project named?
```

Enter:

```text
next16-beginner
```

---

Next:

```text
Would you like to use TypeScript?
```

Answer:

```text
Yes
```

Why?

Because:

* TypeScript is the default in modern Next.js
* almost every production Next.js application uses it
* it helps us catch mistakes

---

Next:

```text
Would you like to use ESLint?
```

Answer:

```text
Yes
```

ESLint helps detect bugs and bad coding practices.

---

Next:

```text
Would you like to use Tailwind CSS?
```

Answer:

```text
Yes
```

Tailwind has become the standard styling approach in the Next.js ecosystem.

---

Next:

```text
Would you like your code inside a src directory?
```

Answer:

```text
Yes
```

This keeps projects organized.

---

Next:

```text
Would you like to use App Router?
```

Answer:

```text
Yes
```

The App Router is the modern Next.js architecture.

---

Next:

```text
Would you like to use Turbopack?
```

Answer:

```text
Yes
```

Turbopack is the modern development bundler.

---

Next:

```text
Would you like to customize import aliases?
```

Answer:

```text
No
```

---

After installation finishes:

```bash
cd next16-beginner
```

Start the development server:

```bash
npm run dev
```

You'll see:

```text
Ready in 1.3s
Local: http://localhost:3000
```

Open:

```text
http://localhost:3000
```

Congratulations.

You have just started your first Next.js application.

---

# Understanding the Generated Project

Your project probably looks something like this:

```text
next16-beginner/

├── public/
├── src/
│   └── app/
│       ├── favicon.ico
│       ├── globals.css
│       ├── layout.tsx
│       └── page.tsx
├── .gitignore
├── eslint.config.mjs
├── next.config.ts
├── package.json
├── tsconfig.json
└── README.md
```

At first glance this looks intimidating.

It isn't.

---

# package.json

Open:

```text
package.json
```

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
    "react": "19.x",
    "react-dom": "19.x"
  }
}
```

This file tells Node.js:

* what packages to install
* how to run the application
* project metadata

---

# npm Scripts

The important scripts are:

```bash
npm run dev
```

Starts the development server.

---

```bash
npm run build
```

Creates a production build.

---

```bash
npm start
```

Runs the production application.

---

# next.config.ts

This file configures Next.js.

Example:

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
};

export default nextConfig;
```

Later in this course we'll enable:

```typescript
const nextConfig = {
    cacheComponents: true
};
```

This activates the new Next.js 16 Cache Components model.

---

# public/

This folder stores static files.

Example:

```text
public/

logo.png
avatar.jpg
robots.txt
resume.pdf
```

If you place:

```text
public/logo.png
```

You can access it via:

```text
http://localhost:3000/logo.png
```

Example:

```jsx
<img src="/logo.png" />
```

---

# src/

The src folder contains our application code.

```text
src/
```

Everything important lives here.

---

# app/

This is the most important folder.

```text
src/app
```

The App Router works using folders.

Example:

```text
app/
    about/
    contact/
    blog/
```

Each folder becomes a route.

---

# page.tsx

Open:

```text
app/page.tsx
```

You might see:

```tsx
export default function Home() {
    return (
        <main>
            Hello World
        </main>
    );
}
```

This creates:

```text
/
```

the homepage.

---

# Creating Our First Real Page

Replace everything with:

```tsx
export default function HomePage() {
    return (
        <main>
            <h1>My First Next.js App</h1>

            <p>
                Welcome to Next.js 16.
            </p>
        </main>
    );
}
```

Visit:

```text
http://localhost:3000
```

You have just created your first Next.js page.

---

# Creating Another Page

Create:

```text
app/about/page.tsx
```

```tsx
export default function AboutPage() {
    return (
        <main>
            <h1>About Me</h1>

            <p>
                I am learning Next.js.
            </p>
        </main>
    );
}
```

Now visit:

```text
http://localhost:3000/about
```

No routing library.

No configuration.

Just folders.

---

# Creating a Contact Page

Create:

```text
app/contact/page.tsx
```

```tsx
export default function ContactPage() {
    return (
        <main>
            <h1>Contact</h1>

            <p>
                contact@example.com
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

# Your Project Now

```text
app/

├── page.tsx
├── about
│   └── page.tsx
└── contact
    └── page.tsx
```

Produces:

```text
/
/about
/contact
```

This is called:

# File-System Routing

---

# Why File-System Routing Is Amazing

Traditional React:

```text
Install Router
        ↓
Configure Routes
        ↓
Configure Navigation
        ↓
Maintain Route Table
```

Example:

```jsx
<Route
    path="/about"
    element={<AboutPage />}
/>
```

Next.js:

```text
Create Folder
        ↓
Done
```

Example:

```text
about/
    page.tsx
```

---

# What Does export default Mean?

You may have noticed:

```tsx
export default function HomePage() {
}
```

This is standard JavaScript.

It means:

> "This is the main thing exported from this file."

Next.js looks for:

```tsx
export default
```

and renders that component.

Example:

```tsx
export default function ContactPage() {
    return (
        <h1>Contact</h1>
    );
}
```

---

# JSX Explained

This syntax:

```tsx
<h1>Hello</h1>
```

looks like HTML.

It is actually:

# JSX

JSX allows us to write:

```tsx
function Greeting() {
    return (
        <h1>Hello World</h1>
    );
}
```

instead of:

```javascript
function Greeting() {
    return React.createElement(
        "h1",
        null,
        "Hello World"
    );
}
```

Thankfully, we almost never write the second version.

---

# Exercise 1

Create:

```text
/projects
```

Page:

```tsx
export default function ProjectsPage() {
    return (
        <main>
            <h1>Projects</h1>
        </main>
    );
}
```

---

# Exercise 2

Create:

```text
/blog
```

Page:

```tsx
export default function BlogPage() {
    return (
        <main>
            <h1>Blog</h1>
        </main>
    );
}
```

---

# Exercise 3

Create:

```text
/services
```

Page:

```tsx
export default function ServicesPage() {
    return (
        <main>
            <h1>Services</h1>
        </main>
    );
}
```

---

# Final Folder Structure

Your application should now look like this:

```text
app/

├── page.tsx
├── about
│   └── page.tsx
├── contact
│   └── page.tsx
├── projects
│   └── page.tsx
├── blog
│   └── page.tsx
└── services
    └── page.tsx
```

---

# What You've Learned

You now understand:

✅ how to install Next.js

✅ what `create-next-app` does

✅ how to run the development server

✅ what `package.json` is

✅ what `next.config.ts` is

✅ what the `app` folder does

✅ what file-system routing is

✅ what `page.tsx` does

✅ what JSX is

---

# What's Next?

In Part 3 we'll learn one of the most important concepts in all of Next.js:

# Layouts

You'll learn:

* why layouts exist
* why pages disappear during navigation
* how layouts persist
* nested layouts
* root layouts
* shared navigation
* shared footers
* application shells

This is where Next.js starts feeling like a real framework rather than a collection of pages.
