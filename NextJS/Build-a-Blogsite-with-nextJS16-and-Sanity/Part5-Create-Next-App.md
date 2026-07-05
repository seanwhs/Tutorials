# **✅ Part 5 — Creating GreyMatter Journal**

# GreyMatter Journal

## Part 5 — Creating GreyMatter Journal: What `create-next-app` Actually Builds

> **Goal of this lesson:** Initialize our Next.js 16 project and understand what `create-next-app` actually creates. By the end of this lesson, you'll understand that modern web frameworks scaffold engineering platforms, not merely websites.

---

# Finally — Time to Build

For the past few lessons, we've intentionally avoided writing much code.

Instead, we've built mental models.

We've learned:

```text
Root Layout = Application Operating System

Router = Data Transformation Engine

Types = Contracts
```

Now it's finally time to create GreyMatter Journal.

---

# The Command That Starts Everything

Open your terminal and run:

```bash
npx create-next-app@latest greymatter-journal
```

You'll be asked several questions.

Choose the following options:

```text
✔ Would you like to use TypeScript?         Yes
✔ Would you like to use ESLint?             Yes
✔ Would you like to use Tailwind CSS?       Yes
✔ Would you like to use src/ directory?     No
✔ Would you like to use App Router?         Yes
✔ Would you like to use Turbopack?          Yes
```

After a few moments, Next.js will create our project.

At first glance, it may appear that we've simply generated a website.

But something much more significant has actually happened.

---

# What Did We Really Create?

Most beginners think:

```text
create-next-app
        ↓
creates
        ↓
website
```

This is not really true.

What `create-next-app` actually creates is:

```text
Development Environment
        +
Build Pipeline
        +
Compiler Configuration
        +
Type System
        +
Linting System
        +
Bundler
        +
React Runtime
        +
Next.js Runtime
        +
Deployment Target
        +
Application Skeleton
```

In other words:

```text
create-next-app
        =
Software Engineering Platform
```

The homepage is almost the least important thing it creates.

---

# Why These Choices?

Let's examine each option.

---

## TypeScript → Yes

```text
Reason:
Contracts
Safety
Tooling
Maintainability
```

We've already learned:

```text
Types = Contracts
```

As GreyMatter Journal grows, TypeScript will help us describe reality accurately.

Examples:

```text
Post

Author

Category

Comment

Metadata

Route Parameters
```

Without contracts, large systems become fragile.

---

## ESLint → Yes

```text
Reason:
Consistency
Quality
Correctness
```

ESLint acts as an automated reviewer.

It continuously checks for:

```text
Potential bugs

Inconsistent patterns

Unsafe practices

Architectural mistakes
```

Professional engineering teams rarely build systems without automated code analysis.

---

## Tailwind CSS → Yes

```text
Reason:
Speed
Consistency
Composition
```

Instead of writing:

```css
.hero {
  display: flex;
  align-items: center;
  justify-content: center;
}
```

we compose styling directly:

```tsx
<div className="
  flex
  items-center
  justify-center
">
```

Tailwind allows us to build design systems through composition rather than handcrafted CSS files.

---

## src/ Directory → No

Many projects use:

```text
src/

    app/

    components/

    lib/
```

There is nothing wrong with this.

However, for GreyMatter Journal, we intentionally choose:

```text
app/
components/
lib/
styles/
types/
```

because our goal is education.

We want the repository structure itself to teach architecture.

Eventually our project will resemble:

```text
Presentation
        ↓
Application
        ↓
Domain
        ↓
Infrastructure
        ↓
Content
```

This aligns with the architecture we'll formally document in Appendix B.

---

## App Router → Yes

This is perhaps the most important choice.

We choose:

```text
App Router
```

because modern applications are built around:

```text
Persistent Layouts

Server Components

Streaming

Suspense

Server Actions

Nested Routing

Partial Rendering
```

The App Router is not merely a routing library.

It is an application architecture.

---

## Turbopack → Yes

```text
Reason:
Fast feedback loops
```

Modern software development involves:

```text
Write
    ↓
Compile
    ↓
Test
    ↓
Observe
    ↓
Repeat
```

The faster this cycle becomes, the faster developers learn.

Turbopack exists to reduce the cost of iteration.

---

# What Happens Behind The Scenes?

When you execute:

```bash
npx create-next-app@latest greymatter-journal
```

Next.js performs a surprising amount of work.

Conceptually:

```text
Download Template
          ↓
Create Repository
          ↓
Install Dependencies
          ↓
Configure React
          ↓
Configure Next.js
          ↓
Configure TypeScript
          ↓
Configure ESLint
          ↓
Configure Tailwind
          ↓
Configure Turbopack
          ↓
Generate Initial Source Code
```

What appears to be a single command is actually the creation of an entire engineering ecosystem.

---

# Exploring The Repository

After installation, you'll see something similar to:

```text
greymatter-journal/

├── app/
├── public/
├── node_modules/
├── .next/
│
├── package.json
├── package-lock.json
├── tsconfig.json
├── next.config.ts
├── eslint.config.mjs
├── postcss.config.js
└── README.md
```

Most beginners immediately ask:

> Which files matter?

The answer is:

```text
Some files define the application.

Some files define the engineering environment.
```

---

# Application Files

These files define what users experience:

```text
app/
public/
components/
styles/
```

Examples:

```text
Pages

Layouts

Components

Images

CSS

Content
```

---

# Engineering Files

These files define how developers work:

```text
package.json

tsconfig.json

eslint.config.mjs

next.config.ts

package-lock.json
```

Examples:

```text
Dependencies

Compilation

Linting

Type Checking

Build Configuration

Tooling
```

Professional engineering teams spend enormous effort maintaining these files correctly.

---

# The Most Important Folder

Many beginners assume:

```text
package.json
```

is the heart of the application.

Others assume:

```text
components/
```

is the heart.

In the App Router, neither is true.

The most important folder is:

```text
app/
```

because this folder defines:

```text
Routing

Layouts

Rendering

Metadata

Streaming

Navigation

Loading States

Error Recovery

Caching
```

More accurately:

```text
app/
        =
Application Architecture
```

---

# Running The Application

Navigate into the project:

```bash
cd greymatter-journal
```

Start the development server:

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

You should see the default Next.js homepage.

This confirms that:

```text
Compiler ✓
Runtime  ✓
Bundler  ✓
React    ✓
Next.js  ✓
Development Server ✓
```

Everything is working.

---

# Our First Customization

Replace:

```text
app/page.tsx
```

with:

```tsx
export default function HomePage() {
  return (
    <div
      className="
        flex
        min-h-screen
        items-center
        justify-center
      "
    >
      <div className="text-center">
        <h1
          className="
            text-6xl
            font-bold
            tracking-tight
          "
        >
          GreyMatter Journal
        </h1>

        <p
          className="
            mx-auto
            mt-6
            max-w-md
            text-xl
            text-gray-600
          "
        >
          Exploring software engineering,
          systems thinking,
          and architecture.
        </p>
      </div>
    </div>
  );
}
```

Refresh the browser.

Congratulations.

You have rendered your first page.

But more importantly:

You have successfully operated an entire software engineering platform.

---

# The Correct Mental Model

Beginners think:

```text
create-next-app = Create Website
```

Professional engineers think:

```text
create-next-app = Create

Development Platform

        +

Build Platform

        +

Runtime Platform

        +

Deployment Platform

        +

Application Skeleton
```

---

# The Most Important Idea To Remember

When you executed:

```bash
npx create-next-app
```

you did not create a homepage.

You created:

```text
A Compiler

    +

A Runtime

    +

A Build Pipeline

    +

A Deployment Pipeline

    +

An Engineering Environment

    +

The Foundation Of A Distributed System
```

The homepage is simply the first file that happens to render.

---

# Up Next — Part 6: Building Our First Application Shell

Now that we understand the engineering platform we've created, we can begin building the application itself.

We'll create:

```text
Header

Footer

Navigation

Site Layout

Application Shell
```

and discover why modern web applications are built around persistent user interfaces rather than individual pages.
