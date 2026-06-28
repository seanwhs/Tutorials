# Next.js 16 for Absolute Beginners

# Part 8 — Components and Composition: Building Applications Out of LEGO Bricks

> **Goal of this lesson:** Learn how to build reusable components, pass data between components, compose large applications, and think about UI architecture like a professional developer.

---

# Everything in React Is a Component

Modern web applications are not built as pages.

They are built as trees of components.

For example, when you visit YouTube:

```text
YouTube Page
     |
     +--- Header
     |
     +--- Sidebar
     |
     +--- SearchBar
     |
     +--- VideoList
               |
               +--- VideoCard
               |
               +--- VideoCard
               |
               +--- VideoCard
```

Or Amazon:

```text
Amazon Page
      |
      +--- Header
      |
      +--- SearchBar
      |
      +--- ProductGrid
                  |
                  +--- ProductCard
                  |
                  +--- ProductCard
                  |
                  +--- ProductCard
```

This idea is called:

# Component Composition

---

# Why Components Exist

Suppose we write:

```tsx
export default function HomePage() {
    return (
        <main>

            <article>
                <h2>
                    Article One
                </h2>
            </article>

            <article>
                <h2>
                    Article Two
                </h2>
            </article>

            <article>
                <h2>
                    Article Three
                </h2>
            </article>

        </main>
    );
}
```

This works.

But what happens when we need:

* 10 articles?
* 100 articles?
* 1000 articles?

Copying code is a disaster.

---

# Creating Our First Component

Create:

```text
components/
    Article.tsx
```

---

## components/Article.tsx

```tsx
export default function Article() {
    return (
        <article>

            <h2>
                Hello Article
            </h2>

        </article>
    );
}
```

---

Now use it:

```tsx
import Article
    from "@/components/Article";

export default function HomePage() {
    return (
        <main>

            <Article />
            <Article />
            <Article />

        </main>
    );
}
```

Result:

```text
Hello Article
Hello Article
Hello Article
```

---

# Components Are Functions

Remember:

```tsx
function Article() {
    return (
        <article>
            Hello
        </article>
    );
}
```

is really:

```text
Input
   ↓
Function
   ↓
UI
```

Just like:

```javascript
function add(a, b) {
    return a + b;
}
```

---

# The Problem

Our component always shows:

```text
Hello Article
```

How do we make it reusable?

---

# Props

Props are inputs to components.

Example:

```tsx
function Greeting(props) {
    return (
        <h1>
            Hello {props.name}
        </h1>
    );
}
```

Usage:

```tsx
<Greeting name="Sean" />
<Greeting name="John" />
<Greeting name="Mary" />
```

Produces:

```text
Hello Sean
Hello John
Hello Mary
```

---

# Building a Real Article Component

```tsx
type ArticleProps = {
    title: string;
    author: string;
};

export default function Article({
    title,
    author,
}: ArticleProps) {

    return (
        <article>

            <h2>
                {title}
            </h2>

            <p>
                By {author}
            </p>

        </article>
    );
}
```

---

Usage:

```tsx
<Article
    title="Learning Next.js"
    author="Sean"
/>

<Article
    title="Understanding React"
    author="John"
/>

<Article
    title="Building APIs"
    author="Mary"
/>
```

---

Result:

```text
Learning Next.js
By Sean

Understanding React
By John

Building APIs
By Mary
```

---

# Visualizing Props

```text
title
author
      |
      V

Article Component

      |
      V

Rendered UI
```

---

# Lists of Components

Suppose we have:

```tsx
const posts = [
    {
        id: 1,
        title: "React",
        author: "Sean",
    },
    {
        id: 2,
        title: "Next.js",
        author: "John",
    },
];
```

We can render:

```tsx
export default function HomePage() {

    return (
        <main>

            {posts.map(post => (

                <Article
                    key={post.id}
                    title={post.title}
                    author={post.author}
                />

            ))}

        </main>
    );
}
```

---

# Why key Exists

React tracks components using:

```tsx
key
```

Bad:

```tsx
<Article />
<Article />
<Article />
```

Good:

```tsx
<Article
    key={post.id}
/>
```

This helps React determine:

```text
Old UI
     ↓
Changes
     ↓
New UI
```

efficiently.

---

# Components Inside Components

Example:

```text
Page
   |
   +--- Header
   |
   +--- Sidebar
   |
   +--- Content
              |
              +--- Article
              |
              +--- Article
```

---

# Creating a Header Component

```tsx
export default function Header() {

    return (
        <header>

            <h1>
                Next Academy
            </h1>

        </header>
    );
}
```

---

# Creating a Sidebar Component

```tsx
export default function Sidebar() {

    return (
        <aside>

            <ul>
                <li>Home</li>
                <li>Posts</li>
                <li>Users</li>
            </ul>

        </aside>
    );
}
```

---

# Creating a Page Component

```tsx
import Header
    from "@/components/Header";

import Sidebar
    from "@/components/Sidebar";

export default function Page() {

    return (
        <div>

            <Header />

            <Sidebar />

            <main>
                Content
            </main>

        </div>
    );
}
```

---

# The children Prop

Sometimes we don't know the content ahead of time.

Example:

```tsx
<Card>
    Hello World
</Card>
```

How does React pass:

```text
Hello World
```

to the component?

Using:

```tsx
children
```

---

# Creating a Card Component

```tsx
type CardProps = {
    children: React.ReactNode;
};

export default function Card({
    children,
}: CardProps) {

    return (
        <div>

            {children}

        </div>
    );
}
```

---

Usage:

```tsx
<Card>

    <h2>
        Hello
    </h2>

    <p>
        World
    </p>

</Card>
```

Produces:

```html
<div>

    <h2>Hello</h2>

    <p>World</p>

</div>
```

---

# Visualizing children

```text
<Card>

    Hello

</Card>

        |
        V

children

        |
        V

Card Component
```

---

# Building a Layout Component

```tsx
type LayoutProps = {
    children: React.ReactNode;
};

export default function Layout({
    children,
}: LayoutProps) {

    return (
        <div>

            <header>
                Header
            </header>

            {children}

            <footer>
                Footer
            </footer>

        </div>
    );
}
```

Usage:

```tsx
<Layout>

    <main>
        Home Page
    </main>

</Layout>
```

---

# Component Composition

This is the secret behind React.

Example:

```text
Application
      |
      +--- Layout
               |
               +--- Header
               |
               +--- Sidebar
               |
               +--- Dashboard
                              |
                              +--- Card
                              |
                              +--- UserTable
                              |
                              +--- Statistics
```

Small pieces combine into larger pieces.

---

# Server Components Can Compose Server Components

Example:

```tsx
import Header
    from "@/components/Header";

import Sidebar
    from "@/components/Sidebar";

export default async function Page() {

    return (
        <div>

            <Header />

            <Sidebar />

        </div>
    );
}
```

Everything executes on the server.

---

# Server Components Can Include Client Components

Example:

```tsx
import ThemeToggle
    from "@/components/ThemeToggle";

export default async function Page() {

    return (
        <main>

            <h1>
                Dashboard
            </h1>

            <ThemeToggle />

        </main>
    );
}
```

---

# Client Components Cannot Import Server Components

This is invalid:

```tsx
"use client";

import Dashboard
    from "./Dashboard";
```

if:

```tsx
Dashboard
```

is a Server Component.

Why?

Because:

```text
Browser
      ↓
Cannot execute
Server code
```

---

# Good Architecture

```text
Server Components
        |
        |
        +---- Client Components
```

---

# Bad Architecture

```text
Client Component
        |
        |
        +---- Entire Application
```

This forces everything into the browser.

---

# Example Folder Structure

```text
components/

ui/
    Button.tsx
    Card.tsx
    Modal.tsx

layout/
    Header.tsx
    Sidebar.tsx
    Footer.tsx

dashboard/
    UserTable.tsx
    Statistics.tsx
    Analytics.tsx
```

---

# Real Example

```text
DashboardPage
        |
        +--- DashboardHeader
        |
        +--- StatisticsPanel
        |
        +--- RevenueChart
        |
        +--- UserTable
        |
        +--- NotificationPanel
```

Each component:

* does one thing
* has one responsibility
* can be reused

---

# The Professional Rule

When you see:

```tsx
return (
    <div>

        500 lines

    </div>
);
```

you probably need:

```text
more components
```

---

# Exercises

## Exercise 1

Create:

```text
components/UserCard.tsx
```

with props:

```text
name
email
role
```

---

## Exercise 2

Create:

```text
components/Card.tsx
```

that uses:

```tsx
children
```

---

## Exercise 3

Build:

```text
Dashboard
      |
      +--- Header
      |
      +--- Sidebar
      |
      +--- Statistics
      |
      +--- UserTable
```

using separate components.

---

# What You've Learned

You now understand:

✅ reusable components

✅ props

✅ children

✅ component composition

✅ component trees

✅ server component composition

✅ client component composition

✅ application architecture

---

# Mental Model

Stop thinking:

```text
Websites
     ↓
Pages
```

Start thinking:

```text
Applications
       ↓
Trees
       ↓
Components
       ↓
Components
       ↓
Components
```

Modern React applications are not pages.

They are **hierarchies of composable components**.

---

# Part 9 Preview

In the next chapter we'll learn one of the most important features of Next.js 16:

# Cache Components and the New Caching Model

Including:

* what changed in Next.js 16
* `cacheComponents: true`
* `"use cache"`
* `cacheLife()`
* `cacheTag()`
* why caching is now explicit
* how Partial Prerendering works
* how Next.js decides what to cache

This chapter is where Next.js 16 becomes fundamentally different from previous versions.
