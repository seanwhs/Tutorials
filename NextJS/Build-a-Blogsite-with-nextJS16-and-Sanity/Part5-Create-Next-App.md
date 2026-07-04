# **✅ Part 5 — Creating GreyMatter Journal**

# GreyMatter Journal

## Part 5 — Creating GreyMatter Journal: What `create-next-app` Actually Builds

> **Goal of this lesson:** Create our Next.js 16 project, understand what `create-next-app` generates, and learn why modern web applications begin as development platforms rather than collections of pages.

---

# We've Been Thinking Like Architects

In the previous lessons, we deliberately avoided writing much code.

Instead, we focused on building mental models:

* Modern applications are not collections of pages.
* Applications are persistent UI trees.
* Layouts create application shells.
* TypeScript types are contracts.
* Components compose into systems.

Now that we understand the architecture, we can finally build the project itself.

---

# Creating GreyMatter Journal

Open your terminal and run:

```bash
npx create-next-app@latest greymatter-journal
```

You'll be asked several questions.

Choose the following options:

```text
✔ Would you like to use TypeScript? ............ Yes

✔ Would you like to use ESLint? ................ Yes

✔ Would you like to use Tailwind CSS? .......... Yes

✔ Would you like your code inside a src/ folder? No

✔ Would you like to use App Router? ............ Yes

✔ Would you like to use Turbopack? ............. Yes

✔ Would you like to customize the import alias? No
```

After a few moments, Next.js creates your project.

But what exactly did it create?

---

# You Didn't Create A Website

Many beginners think:

```text
create-next-app
        ↓
creates website
```

This isn't quite true.

What actually happened is:

```text
create-next-app
        ↓
creates
development platform
```

That platform includes:

```text
Node.js Runtime

        +

React

        +

Next.js

        +

TypeScript

        +

Tailwind CSS

        +

ESLint

        +

Turbopack

        +

Build System

        +

Routing System

        +

Server Runtime
```

The website itself doesn't exist yet.

We've only created the environment that allows us to build it.

---

# Why We Chose These Options

Let's understand why we selected each option.

| Option        | Choice | Why                                                         |
| ------------- | ------ | ----------------------------------------------------------- |
| TypeScript    | Yes    | Gives us contracts, autocomplete, and safer refactoring     |
| ESLint        | Yes    | Detects bugs and enforces good practices                    |
| Tailwind CSS  | Yes    | Provides a utility-first design system                      |
| src directory | No     | Keeps the project structure simpler for learning            |
| App Router    | Yes    | Enables layouts, Server Components, and modern architecture |
| Turbopack     | Yes    | Provides an extremely fast development experience           |

These choices aren't arbitrary.

They reflect how modern production applications are built.

---

# Your First Project Structure

After installation, you'll see something like:

```text
greymatter-journal/

├── app/
├── public/

├── next.config.ts
├── tsconfig.json
├── package.json
├── eslint.config.mjs
├── postcss.config.mjs

└── README.md
```

At first glance, this can feel overwhelming.

Fortunately, you only need to understand a few files initially.

---

# The `app/` Directory

The most important directory is:

```text
app/
```

Inside, you'll typically see:

```text
app/

├── layout.tsx
├── page.tsx
├── globals.css
└── favicon.ico
```

These files form the foundation of your application.

---

## `app/layout.tsx`

This is your root layout.

Remember from Part 3:

```text
Root Layout
        =
Application Operating System
```

It controls:

* HTML document structure
* Global styles
* Metadata
* Providers
* Application infrastructure

---

## `app/page.tsx`

This is your homepage.

```text
URL

/

        ↓

app/page.tsx
```

Unlike traditional websites, this page exists inside your application's layout hierarchy.

---

## `app/globals.css`

This file contains global styles.

Initially it may look simple:

```css
@import "tailwindcss";
```

But eventually our architecture will evolve into:

```text
globals.css
        ↓

tokens.css
        ↓

themes.css
        ↓

prose.css
        ↓

animations.css
```

This becomes the foundation of our design system.

---

# The `public/` Directory

Another important folder is:

```text
public/
```

Anything placed here is served directly by the browser.

Example:

```text
public/logo.svg
        ↓
/logo.svg

public/images/hero.png
        ↓
/images/hero.png
```

Typical assets include:

* logos
* favicons
* Open Graph images
* illustrations
* downloadable files

---

# The Most Important File Nobody Talks About

Arguably the most important file is:

```text
package.json
```

This file defines your entire project.

Example:

```json
{
  "name": "greymatter-journal",

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

Think of `package.json` as:

```text
Application Manifest

        +

Dependency Registry

        +

Task Runner

        +

Project Identity
```

Whenever you run:

```bash
npm run dev
```

you're executing instructions defined here.

---

# Starting The Development Server

Navigate into your project:

```bash
cd greymatter-journal
```

Then start the development server:

```bash
npm run dev
```

You'll see something like:

```text
▲ Next.js 16.x (Turbopack)

✓ Ready in 800ms

Local:
http://localhost:3000
```

Open your browser and visit:

```text
http://localhost:3000
```

You'll see the default Next.js starter page.

---

# Our First Customization

Let's replace the default homepage.

Open:

```text
app/page.tsx
```

Replace everything with:

```tsx
export default function HomePage() {
  return (
    <main
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
            text-5xl
            font-bold
            tracking-tight
            sm:text-6xl
          "
        >
          GreyMatter Journal
        </h1>

        <p
          className="
            mx-auto
            mt-6
            max-w-xl
            text-lg
            text-gray-600
          "
        >
          Exploring software engineering,
          systems thinking,
          and architecture.
        </p>

      </div>
    </main>
  );
}
```

Save the file.

The browser updates instantly.

This is Turbopack at work.

---

# Our Architecture Will Soon Evolve

The default project structure is intentionally minimal:

```text
app/
    page.tsx
```

But our final architecture will eventually become:

```text
app/

├── layout.tsx
├── globals.css

├── (site)/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── about/
│   └── posts/

├── api/
```

We'll gradually build:

```text
components/

hooks/

lib/

styles/

types/

actions/

studio/
```

One piece at a time.

You do not need to understand the final architecture yet.

We're simply building toward it.

---

# The Mental Model To Remember Forever

When you run:

```bash
npx create-next-app
```

you are not creating a website.

You are creating:

```text
Development Platform

        ↓

Application Runtime

        ↓

Application Architecture

        ↓

Application Code

        ↓

Website
```

The visible website is only the final layer.

Everything underneath exists to make that website maintainable, scalable, and reliable.

---

# Up Next — Part 6: Building Our First Application Shell

We'll begin transforming the default project into GreyMatter Journal by:

* creating our `(site)` route group
* building our first `SiteLayout`
* creating `Header` and `Footer`
* introducing reusable components
* establishing our Tailwind design foundation

This is where GreyMatter Journal begins to feel like a real application rather than a tutorial project.
