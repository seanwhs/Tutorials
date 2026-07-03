# GreyMatter Journal

# Part 5 — Creating GreyMatter Journal: What `create-next-app` Actually Builds

> **Goal of this lesson:** Create our Next.js 16 application and understand what every generated file and folder actually does.

---

# Finally, We're Going To Build Something

For the last four parts, we've intentionally avoided writing code.

This may feel unusual.

Most tutorials begin with:

```bash
npx create-next-app@latest my-blog
```

and immediately start coding.

But now we understand:

* what Node.js is,
* what npm is,
* what npx is,
* what the App Router is,
* what layouts are,
* what TypeScript contracts are.

Now we can finally create **GreyMatter Journal**.

---

# Creating The Project

Open your terminal and execute:

```bash
npx create-next-app@latest greymatter-journal
```

You will be asked several questions.

Select the following:

```text
✔ Would you like to use TypeScript? ........ Yes
✔ Would you like to use ESLint? ............ Yes
✔ Would you like to use Tailwind CSS? ...... Yes
✔ Would you like your code inside src/? .... No
✔ Would you like to use App Router? ........ Yes
✔ Would you like to use Turbopack? ......... Yes
✔ Would you like to customize imports? ..... No
```

---

# Why Did We Choose These Options?

Many beginners simply accept the defaults.

Let's understand why.

---

## TypeScript

We choose:

```text
Yes
```

because modern Next.js applications are built with TypeScript.

Benefits:

```text
Type Safety
      +
Autocomplete
      +
Refactoring
      +
Documentation
      +
Error Detection
```

Example:

```typescript
type Article = {
  title: string;
  slug: string;
};
```

Instead of discovering mistakes in production, we discover them during development.

---

## ESLint

We choose:

```text
Yes
```

because ESLint acts like a code reviewer.

Example:

```javascript
const x = 5
```

ESLint notices:

```text
Missing semicolon.
```

Or:

```javascript
const unused = "hello";
```

ESLint notices:

```text
Unused variable.
```

Think of ESLint as:

```text
Grammar checker
        ↓
for code
```

---

## Tailwind CSS

We choose:

```text
Yes
```

because modern Next.js applications often use utility-based styling.

Instead of:

```css
.card {
  padding: 20px;
  background: white;
}
```

we can write:

```tsx
<div className="p-5 bg-white">
```

We'll learn Tailwind gradually throughout the series.

---

## App Router

We choose:

```text
Yes
```

because:

```text
App Router
      =
Modern Next.js
```

The App Router enables:

* layouts,
* server components,
* streaming,
* caching,
* server actions.

---

## Turbopack

We choose:

```text
Yes
```

because Turbopack is the modern Next.js development engine.

Traditional development:

```text
Edit
  ↓
Compile
  ↓
Refresh
```

Turbopack performs:

```text
Edit
  ↓
Incremental Update
  ↓
Refresh
```

This creates dramatically faster development cycles.

---

# What Happens Next?

After pressing Enter, Next.js begins creating your project.

Internally:

```text
Download packages
          ↓
Create folders
          ↓
Generate files
          ↓
Install dependencies
          ↓
Configure TypeScript
          ↓
Configure Tailwind
          ↓
Configure ESLint
          ↓
Generate starter application
```

Diagram:

```text
create-next-app

        │
        ▼

  Install React
        │
        ▼
  Install Next.js
        │
        ▼
 Install TypeScript
        │
        ▼
 Install Tailwind
        │
        ▼
 Install ESLint
        │
        ▼
 Generate Files
```

---

# Entering Our Project

After installation:

```bash
cd greymatter-journal
```

Now examine the project:

```bash
dir
```

or:

```bash
ls
```

You'll see something similar to:

```text
greymatter-journal/

app/
public/

package.json
package-lock.json

next.config.ts
tsconfig.json

eslint.config.mjs
postcss.config.mjs

README.md
```

At first glance this appears overwhelming.

But every file exists for a reason.

---

# The Most Important Folder

Let's start with:

```text
app/
```

Remember from Part 2:

```text
app/
     =
application tree
```

Open it:

```text
app/

favicon.ico
globals.css
layout.tsx
page.tsx
```

---

# Understanding `page.tsx`

Open:

```text
app/page.tsx
```

You'll see something similar to:

```tsx
export default function Home() {
  return (
    <main>
      Hello World
    </main>
  );
}
```

This file represents:

```text
/
```

the root route of your website.

Diagram:

```text
app/page.tsx
        ↓
      /
```

---

# Understanding `layout.tsx`

Open:

```text
app/layout.tsx
```

You already know what this file does:

```text
Application Shell
          ↓
Wraps Every Page
```

Diagram:

```text
RootLayout

      │
      ▼

Current Page
```

---

# Understanding `globals.css`

Open:

```text
app/globals.css
```

This file contains CSS that applies everywhere.

Think of it as:

```text
Global Styling
```

Examples:

* fonts,
* colors,
* resets,
* themes,
* variables.

---

# Understanding `public/`

The `public` folder stores static files.

Example:

```text
public/

logo.png
avatar.jpg
robots.txt
favicon.ico
```

Files here become accessible via URLs.

Example:

```text
public/logo.png
        ↓
/logo.png
```

---

# Understanding `package.json`

This is the heart of your application.

Open:

```text
package.json
```

You might see:

```json
{
  "name": "greymatter-journal",
  "version": "0.1.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  }
}
```

Think of this file as:

```text
Application Manifest
```

It answers:

* What is this project?
* Which packages are installed?
* How do we run it?
* How do we build it?

---

# Understanding Scripts

Consider:

```json
"scripts": {
  "dev": "next dev"
}
```

When you execute:

```bash
npm run dev
```

npm performs:

```text
Read package.json
          ↓
Find script
          ↓
Execute command
```

Diagram:

```text
npm run dev
        │
        ▼
package.json
        │
        ▼
next dev
        │
        ▼
Development Server
```

---

# Understanding Dependencies

Further down you'll see:

```json
"dependencies": {
  "next": "...",
  "react": "...",
  "react-dom": "..."
}
```

This means:

```text
GreyMatter Journal

├── Next.js
├── React
└── ReactDOM
```

Our application depends on these packages.

---

# Understanding `node_modules`

Now look at:

```text
node_modules/
```

This folder often contains:

```text
20,000+
files
```

Many beginners panic.

Don't.

Modern applications depend on many packages.

Example:

```text
GreyMatter Journal
          ↓
Next.js
          ↓
React
          ↓
Other Packages
          ↓
More Packages
          ↓
Thousands Of Files
```

This is normal.

---

# Understanding `package-lock.json`

Many developers ignore this file.

They shouldn't.

This file records:

```text
Exact Package Versions
```

Example:

```text
next
 └── react
        └── package A
               └── package B
```

Without the lock file:

```text
Developer A
        ↓
different packages

Developer B
        ↓
different packages
```

With the lock file:

```text
Everyone
      ↓
same packages
```

---

# Understanding `tsconfig.json`

This file configures TypeScript.

Example:

```json
{
  "compilerOptions": {
    "strict": true
  }
}
```

Think of it as:

```text
TypeScript Settings
```

It controls:

* type checking,
* module resolution,
* compiler behavior,
* editor tooling.

---

# Understanding `next.config.ts`

This file configures Next.js itself.

Examples:

* image optimization,
* caching,
* server settings,
* experimental features.

Think of it as:

```text
Next.js Configuration
```

---

# Running GreyMatter Journal

Now execute:

```bash
npm run dev
```

You'll see:

```text
▲ Next.js 16
✓ Ready
```

Open:

```text
http://localhost:3000
```

Congratulations.

You are now running:

```text
Node.js
      +
npm
      +
React
      +
Next.js
      +
TypeScript
      +
Tailwind
      +
Turbopack
```

all working together.

---

# Our First Refactor

Let's replace the starter page.

Open:

```text
app/page.tsx
```

Replace everything with:

```tsx
export default function HomePage() {
  return (
    <main>
      <h1>GreyMatter Journal</h1>

      <p>
        Thoughts on software,
        architecture, and systems.
      </p>
    </main>
  );
}
```

Save the file.

Notice:

```text
Save
   ↓
Turbopack detects changes
   ↓
Recompile
   ↓
Browser refreshes
```

No manual build step.

No restart.

No deployment.

---

# What Just Happened?

This tiny file:

```tsx
export default function HomePage() {
  return (
    <main>
      <h1>GreyMatter Journal</h1>
    </main>
  );
}
```

went through a surprisingly complex pipeline:

```text
TSX
   ↓
TypeScript Compiler
   ↓
React Compiler
   ↓
Next.js Compiler
   ↓
Server Component Compiler
   ↓
HTML
   ↓
Browser
```

And yet we only wrote six lines of code.

This is the power of modern frameworks.

---

# Mental Model To Remember Forever

When you execute:

```bash
npx create-next-app@latest greymatter-journal
```

you are not creating a website.

You are creating:

```text
Development Environment
           +
Compiler
           +
Build System
           +
Application Runtime
           +
UI Framework
           +
Rendering Engine
           +
Type System
```

Everything else is simply configuration.

---

# Up Next

In **Part 6**, we'll build our first real layout and finally understand:

* why websites have application shells,
* how persistent navigation works,
* how `children` powers layout composition,
* and why modern web applications are really trees of interfaces rather than collections of pages.
