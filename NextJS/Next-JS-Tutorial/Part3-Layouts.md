# Next.js 16 for Absolute Beginners

# Part 3 — Understanding Layouts: The Secret Behind Modern Web Applications

> **Goal of this lesson:** Understand how the Next.js App Router builds applications using layouts, route segments, and persistent UI trees—and learn why layouts are the foundation of modern web application architecture.

---

# Stop Thinking in Pages

One of the biggest conceptual shifts when learning Next.js is realizing that modern web applications are not collections of pages.

Most beginners start with a mental model like this:

```text
Website
├── Home Page
├── About Page
├── Blog Page
└── Contact Page
```

This model comes from traditional websites, where clicking a link causes the browser to:

* destroy the current page
* request a new HTML document
* rebuild the entire interface

In other words:

```text
Click Link
    ↓
Destroy Everything
    ↓
Reload Everything
```

This model made sense when websites were primarily collections of documents.

You clicked a link.

The browser downloaded a completely new HTML page.

The old page disappeared.

The new page appeared.

For decades, this was how the web worked.

---

# The Evolution of Web Architecture

Understanding layouts requires understanding how web applications evolved.

Traditional websites were built around documents.

```text
Browser
    ↓
Request HTML
    ↓
Receive Document
    ↓
Render Page
```

Every navigation destroyed the previous document and loaded a new one.

This approach worked well for:

* news websites
* blogs
* documentation sites
* company websites
* informational portals

However, modern users no longer think of websites as documents.

They think of them as applications.

Users now expect applications to behave more like desktop software:

* navigation should feel instant
* menus should remain open
* search state should persist
* sidebars should not reset
* interfaces should remain responsive
* transitions should feel continuous

This changes the architectural model completely.

Instead of thinking:

```text
Website
    ↓
Pages
```

we now think:

```text
Application
    ↓
Persistent Interface
    ↓
Changing Content
```

Modern web applications don't work like collections of pages.

Instead, professional developers think about applications as hierarchical user interfaces composed of reusable shells and changing content regions.

```text
Application
│
├── Shared Interface
│   ├── Header
│   ├── Navigation
│   ├── Sidebar
│   └── Footer
│
└── Current Content
```

When navigation occurs, only the parts of the interface that actually change are replaced.

Everything else remains alive.

This is the fundamental idea behind layouts.

---

# Think Like an Architect

Imagine constructing a shopping mall.

Every shop shares:

* entrances
* escalators
* elevators
* parking
* electricity
* air conditioning
* security systems

Individual stores don't rebuild this infrastructure.

They only customize their own interior spaces.

```text
Shopping Mall
      ↓
Shared Infrastructure
      ↓
Individual Stores
```

Next.js applications work exactly the same way.

```text
Next.js Application
      ↓
Shared Layouts
      ↓
Individual Pages
```

Layouts provide the infrastructure.

Pages provide the content.

This architectural approach has enormous benefits:

* less duplicated code
* better performance
* preserved application state
* easier maintenance
* consistent user experience
* faster navigation

Professional developers don't think:

> "How do I build pages?"

They think:

> "What parts of my application should persist, and what parts should change?"

That question leads naturally to layouts.

---

# The App Router Is a UI Composition Engine

Many developers initially believe the App Router is simply a "page router."

It isn't.

The App Router is actually a persistent UI composition engine that constructs React component trees from your folder structure.

Traditional thinking:

```text
URL
   ↓
Page
```

Next.js App Router thinking:

```text
URL
   ↓
Route Segments
   ↓
Special Files
   ↓
Layout Tree
   ↓
React Component Tree
   ↓
Rendered Application
```

This means:

* folders become route segments
* route segments become layouts
* layouts become React component trees
* component trees become persistent user interfaces

Many developers try to memorize:

* `layout.tsx`
* `page.tsx`
* `loading.tsx`
* `error.tsx`
* `template.tsx`

without understanding what the framework is actually doing.

Internally, Next.js continuously transforms:

```text
URL
   ↓
Route Segments
   ↓
Special Files
   ↓
Layout Tree
   ↓
React Component Tree
   ↓
Rendered Application
```

This means the App Router isn't merely a routing system.

It is a **persistent UI composition engine** that continuously constructs and preserves a hierarchy of React components.

This is arguably the single most important concept in the entire App Router architecture.

Once you understand this idea, the rest of the App Router begins to make sense.

---

# Visualizing the App Router

Suppose you have:

```text
app/
├── layout.tsx
└── dashboard/
     ├── layout.tsx
     └── users/
          └── page.tsx
```

When a user visits:

```text
/dashboard/users
```

Many beginners imagine:

```text
Open Page
```

But internally, Next.js constructs:

```text
RootLayout
      ↓
DashboardLayout
      ↓
UsersPage
```

Which is equivalent to:

```tsx
<RootLayout>
  <DashboardLayout>
    <UsersPage />
  </DashboardLayout>
</RootLayout>
```

The URL does not merely select a page.

The URL constructs an entire React component hierarchy.

This hierarchy is called the **layout tree**.

Understanding the layout tree is the key to understanding the App Router.

---

# Mental Model Check

At this point, stop and ask yourself:

When navigating from:

```text
/dashboard/users
```

to:

```text
/dashboard/settings
```

does Next.js:

### Option A

```text
Destroy Everything
Create Everything
```

or

### Option B

```text
Keep Shared Layouts
Replace Changed Content
```

The correct answer is:

### ✅ Option B

This single idea explains:

* layouts
* partial rendering
* state preservation
* fast navigation
* application-like behavior

And it is the foundation of modern Next.js architecture.

---

---

# Special Files Define Application Behavior

Unlike React Router, which requires you to explicitly configure routes, Next.js uses special filenames to define application behavior.

Instead of writing:

```jsx
<Route path="/about" element={<AboutPage />} />
<Route path="/blog" element={<BlogPage />} />
<Route path="/users" element={<UsersPage />} />
```

you create files with special names inside the `app/` directory.

| File            | Purpose                      | Required  |
| --------------- | ---------------------------- | --------- |
| `page.tsx`      | Creates a route              | Yes       |
| `layout.tsx`    | Creates persistent shared UI | Root only |
| `template.tsx`  | Creates remounting UI        | No        |
| `loading.tsx`   | Loading state                | No        |
| `error.tsx`     | Error boundary               | No        |
| `not-found.tsx` | 404 UI                       | No        |
| `route.ts`      | API endpoint                 | No        |

Consider:

```text
app/
├── layout.tsx
├── page.tsx
├── about/
│   └── page.tsx
└── blog/
    ├── layout.tsx
    ├── loading.tsx
    └── [slug]/
        └── page.tsx
```

Many beginners look at this and think:

> "These files create pages."

But that's only partially true.

These files actually define:

* how your application loads
* how errors are handled
* which UI persists
* which UI remounts
* which loading states appear
* which component tree gets constructed

In other words:

```text
Files
   ↓
Application Behavior
```

rather than:

```text
Files
   ↓
Pages
```

This distinction becomes increasingly important as applications grow.

---

# Thinking Like a Compiler

When you create:

```text
app/
├── layout.tsx
├── dashboard/
│   ├── layout.tsx
│   └── users/
│       └── page.tsx
```

you might see:

```text
Folders
```

Next.js sees:

```text
Route Segments
        ↓
Layouts
        ↓
React Tree
```

The framework effectively acts like a compiler.

Input:

```text
Filesystem
```

Output:

```text
React Component Hierarchy
```

This is why the App Router is often described as a filesystem-based compiler for user interfaces.

---

# Route Segments: The Building Blocks

Every folder inside `app/` becomes a route segment.

Consider:

```text
app/
└── blog/
     └── react/
          └── hooks/
               └── page.tsx
```

This generates:

```text
/blog/react/hooks
```

But internally, Next.js sees:

```text
/
└── blog
     └── react
          └── hooks
```

Each segment can contribute:

* layouts
* pages
* templates
* loading states
* error boundaries
* not-found states

This means your URL structure directly creates your UI structure.

This is one of the most powerful ideas in the App Router.

---

# Visualizing Route Segments

Suppose we create:

```text
app/
├── layout.tsx
└── dashboard/
    ├── layout.tsx
    └── reports/
        ├── layout.tsx
        └── sales/
            └── page.tsx
```

The URL:

```text
/dashboard/reports/sales
```

creates this route hierarchy:

```text
/
└── dashboard
     └── reports
          └── sales
```

Which becomes this layout hierarchy:

```text
RootLayout
      ↓
DashboardLayout
      ↓
ReportsLayout
      ↓
SalesPage
```

Which becomes this React tree:

```tsx
<RootLayout>
  <DashboardLayout>
    <ReportsLayout>
      <SalesPage />
    </ReportsLayout>
  </DashboardLayout>
</RootLayout>
```

Notice what happened.

The filesystem became:

* a URL hierarchy
* a layout hierarchy
* a React component hierarchy

simultaneously.

---

# Why Layouts Exist

Suppose your application contains:

```text
/
/about
/blog
/contact
```

Each page requires:

* a header
* navigation
* footer

Without layouts, you might write:

```tsx
export default function HomePage() {
  return (
    <>
      <header>...</header>

      <main>
        Home Content
      </main>

      <footer>...</footer>
    </>
  );
}
```

Then:

```tsx
export default function AboutPage() {
  return (
    <>
      <header>...</header>

      <main>
        About Content
      </main>

      <footer>...</footer>
    </>
  );
}
```

Then:

```tsx
export default function BlogPage() {
  return (
    <>
      <header>...</header>

      <main>
        Blog Content
      </main>

      <footer>...</footer>
    </>
  );
}
```

At first, this doesn't seem terrible.

But professional developers immediately recognize several problems.

---

# The Problems with Repeating UI

## Problem #1 — Code Duplication

The same interface appears repeatedly.

```text
Header
Footer
Navigation
Header
Footer
Navigation
Header
Footer
Navigation
```

Duplicate code eventually becomes technical debt.

---

## Problem #2 — Maintenance Overhead

Suppose you want to add:

```text
Notifications
```

to the navigation.

Now you must update:

```text
Home
About
Blog
Contact
Products
Pricing
Support
Dashboard
Admin
```

The larger the application becomes, the worse this problem gets.

---

## Problem #3 — Inconsistent User Experience

Over time:

```text
Page A → old navigation
Page B → new navigation
Page C → missing footer
Page D → different sidebar
```

Applications slowly become inconsistent.

---

## Problem #4 — Performance Problems

Traditional navigation behaves like this:

```text
Destroy Header
Destroy Navigation
Destroy Footer

Create Header
Create Navigation
Create Footer
```

Even though nothing actually changed.

This wastes:

* rendering time
* network bandwidth
* browser work
* JavaScript execution

---

# Enter Layouts

A layout is a React component that wraps pages and other layouts.

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header>
          <h1>Next.js Academy</h1>
        </header>

        {children}

        <footer>
          Copyright 2026
        </footer>
      </body>
    </html>
  );
}
```

Think of a layout as an application shell.

```text
Application Shell
        ↓
Persistent UI
        ↓
Changing Content
```

This architectural pattern appears everywhere:

| Application | Persistent Shell              |
| ----------- | ----------------------------- |
| Gmail       | Sidebar + Header              |
| Slack       | Workspace + Sidebar           |
| Discord     | Server List + Channels        |
| Notion      | Navigation + Workspace        |
| GitHub      | Navigation + Repository Shell |

Next.js layouts implement this same architectural idea.

---

# The Root Layout

Every App Router application requires exactly one root layout.

```text
app/
├── layout.tsx
└── page.tsx
```

The root layout has two responsibilities.

---

## Responsibility #1: Wrap the Entire Application

Every page renders inside the root layout.

```text
RootLayout
      ↓
Everything Else
```

---

## Responsibility #2: Define the HTML Document

Unlike ordinary React components, the root layout must render:

```html
<html>
<body>
```

Example:

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

Without a root layout, your application cannot run.

---

# Understanding the RootLayout Syntax

Many beginners find this intimidating:

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
```

Let's break it down.

---

## Step 1: Next.js Passes an Object

Internally:

```tsx
RootLayout({
  children: <CurrentPage />,
});
```

The function receives an object.

---

## Step 2: JavaScript Destructuring

Instead of:

```tsx
function RootLayout(props) {
  return props.children;
}
```

we write:

```tsx
function RootLayout({ children }) {
  return children;
}
```

This is called object destructuring.

---

## Step 3: TypeScript Adds a Contract

```tsx
{
  children: React.ReactNode;
}
```

This tells TypeScript:

> This property contains something React can render.

---

# What Is React.ReactNode?

`React.ReactNode` represents anything React can display.

Examples:

```tsx
"Hello"

42

<div>Hello</div>

<Component />

null

[
  <li>A</li>,
  <li>B</li>
]
```

Think of `React.ReactNode` as:

> "Any valid React output."

This type is intentionally broad because React can render many different kinds of values.

---

# Children Are Placeholders

Consider:

```tsx
<body>
  <header>Header</header>

  {children}

  <footer>Footer</footer>
</body>
```

Suppose the user visits:

```text
/about
```

and `about/page.tsx` contains:

```tsx
export default function AboutPage() {
  return <h2>About Us</h2>;
}
```

Next.js produces:

```html
<body>
  <header>Header</header>

  <h2>About Us</h2>

  <footer>Footer</footer>
</body>
```

The page is injected into the layout automatically.

---

# Another Way to Think About Children

Many beginners imagine:

```text
Page
    ↓
Wrapped By Layout
```

But internally, Next.js behaves more like this:

```text
Layout
    ↓
Contains Placeholder
    ↓
Next.js Injects Page
```

Visualize it like this:

```tsx
<Layout>
    {CURRENT_ROUTE}
</Layout>
```

The layout already exists.

The page simply gets inserted into the placeholder.

This explains why layouts remain alive while pages change.

---

# The Most Important Mental Model

Beginners think:

```text
Page
    ↓
Layout
```

Next.js actually works like this:

```text
Layout
    ↓
Page Slot
    ↓
Injected Page
```

The layout is permanent.

The page is temporary.

Once this idea clicks, you'll understand why:

* layouts persist
* state survives navigation
* partial rendering works
* applications feel fast
* modern web applications behave like desktop software

And that understanding will carry you through the rest of the App Router.

---

---

# Server Components vs Client Components

One of the biggest differences between traditional React applications and the Next.js App Router is where components execute.

In traditional React applications, the answer is simple:

```text id="4edxgn"
Browser
    ↓
Everything
```

Your application:

* downloads JavaScript
* executes JavaScript
* renders UI
* manages state
* performs data fetching

all inside the browser.

This approach works, but it comes with costs:

* large JavaScript bundles
* slower startup times
* unnecessary client-side computation
* more work for the browser

The App Router introduces a fundamentally different model.

```text id="2kt24p"
Server
   ↓
Server Components

Browser
   ↓
Client Components
```

Instead of asking:

> "Should this component be rendered?"

we now ask:

> "Where should this component execute?"

This is one of the most important architectural questions in modern React development.

---

# Server Components: The Default

Consider:

```tsx id="4nk5gn"
export default function Page() {
  return <h1>Hello World</h1>;
}
```

Many beginners assume this executes in the browser.

It doesn't.

By default, every component inside the App Router is a **Server Component**.

This means:

```text id="42u7os"
Server
     ↓
Execute Component
     ↓
Generate UI
     ↓
Send Result
```

The browser receives the rendered result rather than the component logic itself.

---

# Why Server Components Exist

Server Components solve several problems that traditional React applications face.

## Smaller JavaScript Bundles

Traditional React:

```text id="yz7dh4"
Browser
     ↓
Download Everything
```

Server Components:

```text id="rfg0dv"
Server
     ↓
Execute Logic
     ↓
Send Result
```

Less JavaScript needs to be downloaded.

---

## Faster Rendering

Instead of:

```text id="m7kwnk"
Download JS
Execute JS
Render UI
```

the server can perform the expensive work:

```text id="39b8g0"
Server Render
      ↓
Send Result
```

This improves:

* startup performance
* rendering speed
* user experience

---

## Direct Database Access

Traditional React:

```text id="edv25i"
Browser
    ↓
API
    ↓
Database
```

Server Components:

```text id="35d4i5"
Server Component
        ↓
Database
```

Example:

```tsx id="r7g7my"
export default async function UsersPage() {
  const users = await db.users.findMany();

  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>
          {user.name}
        </li>
      ))}
    </ul>
  );
}
```

No API route required.

No client fetch required.

No loading state required.

---

## Improved Security

Secrets remain on the server.

```text id="uyi4ae"
Database Password
API Keys
Private Tokens
Server Credentials
```

never reach the browser.

This dramatically reduces the attack surface of your application.

---

# Server Components Are Not Limited Components

Many beginners think:

```text id="3c5f8r"
Server Component
       ↓
Weak Component
```

This is incorrect.

Server Components are actually:

```text id="0ym3cz"
Server Component
       ↓
Powerful Component
```

They can:

* access databases
* read files
* call internal APIs
* perform authentication
* access environment variables
* perform expensive computation

The only thing they cannot do is interact directly with the browser.

---

# When Do You Need a Client Component?

Client Components exist for browser interactivity.

If your component needs browser features, you must opt into client-side execution.

| Feature             | Requires Client Component |
| ------------------- | ------------------------- |
| `useState()`        | Yes                       |
| `useReducer()`      | Yes                       |
| `useEffect()`       | Yes                       |
| `onClick`           | Yes                       |
| `window`            | Yes                       |
| `document`          | Yes                       |
| `localStorage`      | Yes                       |
| `usePathname()`     | Yes                       |
| `useSearchParams()` | Yes                       |

Example:

```tsx id="5ddw0x"
"use client";

import { useState } from "react";

export default function Counter() {
  const [count, setCount] =
    useState(0);

  return (
    <button
      onClick={() =>
        setCount(count + 1)
      }
    >
      {count}
    </button>
  );
}
```

The line:

```tsx id="u90h4m"
"use client";
```

changes where the component executes.

Without it:

```text id="1yv6cx"
Server
```

With it:

```text id="o56p0m"
Browser
```

---

# The Golden Rule

Many beginners discover `"use client"` and then write:

```tsx id="xmqn2y"
"use client";

export default function RootLayout() {
  ...
}
```

This is usually a mistake.

Remember:

> Keep `"use client"` as high as necessary, but as low as possible.

Good:

```text id="ghgx8l"
RootLayout (server)
      ↓
Header (server)
      ↓
SearchBox (client)
```

Only the interactive part becomes client-side.

Bad:

```text id="7m3ttw"
RootLayout (client)
      ↓
Entire Application
```

Now the browser must download and execute everything.

---

# Why Small Client Boundaries Matter

Suppose your application contains:

```text id="4ujfxf"
Header
Sidebar
Search
Dashboard
Reports
Analytics
Settings
```

If only the search box requires interaction:

Bad:

```text id="h2qfbi"
Entire App
      ↓
Client
```

Good:

```text id="zjzj3k"
Entire App
      ↓
Server

Search
      ↓
Client
```

This reduces:

* JavaScript bundle size
* browser execution
* hydration work
* memory usage

Smaller client boundaries create faster applications.

---

# Layouts Are Persistent Application Shells

Beginners think:

```text id="f0jpd2"
Reusable Wrapper
```

Professional developers think:

```text id="pvn0g9"
Persistent Application Shell
```

Consider:

```text id="tdrzz5"
Browser
│
├── RootLayout
│
├── Header
│
├── Navigation
│
├── AdminLayout
│
│   └── Current Page
│
└── Footer
```

When navigation occurs:

```text id="e9fipk"
Current Page
      ↓
Replace
```

Everything else remains alive.

This is one of the most important features of the App Router.

---

# Why Persistent Layouts Feel Fast

Suppose a user:

1. opens a sidebar
2. expands several menus
3. enters search text
4. navigates elsewhere

Traditional websites behave like this:

```text id="8wzn9v"
Open Sidebar
      ↓
Navigate
      ↓
Everything Resets
```

The App Router behaves like this:

```text id="msxkdb"
Open Sidebar
      ↓
Navigate
      ↓
Everything Remains
```

Traditional websites:

```text id="gbhzb8"
Destroy Everything
       ↓
Recreate Everything
```

App Router:

```text id="1vmtaz"
Keep Layout Tree Alive
       ↓
Replace Changed Content
```

This preserved state is what makes modern web applications feel like desktop applications.

---

# Nested Layouts

Consider:

```text id="6qx1wf"
app/
├── layout.tsx
└── blog/
    ├── layout.tsx
    └── [slug]/
        └── page.tsx
```

Visiting:

```text id="8fdyk7"
/blog/hello-world
```

does not simply render:

```text id="7h60ga"
BlogPostPage
```

Instead, Next.js constructs:

```text id="jxxxtf"
RootLayout
      ↓
BlogLayout
      ↓
BlogPostPage
```

Equivalent React:

```tsx id="w9wzlf"
<RootLayout>
  <BlogLayout>
    <BlogPostPage />
  </BlogLayout>
</RootLayout>
```

This hierarchy is called the **layout tree**.

---

# The Layout Tree

Many beginners think:

```text id="r4tmy4"
URL
     ↓
Page
```

Professionals think:

```text id="b7hnrb"
URL
     ↓
Layout Tree
     ↓
React Tree
```

Suppose:

```text id="tklwza"
/dashboard/reports/sales
```

Your application might construct:

```text id="fjb9go"
RootLayout
      ↓
DashboardLayout
      ↓
ReportsLayout
      ↓
SalesPage
```

Every route creates a component hierarchy.

The URL does not select a page.

The URL builds an application tree.

---

# The Superpower: Persistent Layouts

Suppose we have:

```text id="mj4aj9"
/admin/users
/admin/settings
```

Both routes share:

```text id="rlz2oj"
RootLayout
      ↓
AdminLayout
```

When navigating:

```text id="w0frna"
/admin/users
       ↓
/admin/settings
```

Traditional websites perform:

```text id="3pn9k9"
Destroy Everything
Create Everything
```

Next.js performs:

```text id="4l3n2z"
Keep RootLayout
Keep AdminLayout
Destroy UsersPage
Create SettingsPage
```

This enables:

* preserved sidebar state
* preserved search boxes
* preserved scroll position
* faster navigation
* application-like behavior

---

# Mental Model Check

Suppose your sidebar is inside:

```text id="j34c2n"
AdminLayout
```

and the user collapses it.

After navigating:

```text id="qlp9cw"
/admin/users
       ↓
/admin/settings
```

Why does the sidebar remain collapsed?

Because:

```text id="9z0u4w"
AdminLayout
```

never disappeared.

The page changed.

The layout survived.

This simple idea explains most of the App Router's behavior.

---

---

# Partial Rendering

Traditional websites follow a simple but expensive process.

Suppose you navigate from:

```text id="tq6ph5"
/admin/users
       ↓
/admin/settings
```

The browser performs:

```text id="l2trpj"
Destroy Page
       ↓
Request New HTML
       ↓
Download New Assets
       ↓
Rebuild Interface
       ↓
Render Everything
```

Even if:

* the header didn't change
* the sidebar didn't change
* the footer didn't change
* the navigation didn't change

everything gets rebuilt anyway.

---

# How Next.js Thinks About Rendering

The App Router takes a completely different approach.

Instead of asking:

> "What page should I load?"

it asks:

> "What part of the current interface changed?"

Suppose we have:

```text id="s10hsv"
RootLayout
      ↓
AdminLayout
      ↓
UsersPage
```

and navigate to:

```text id="lo4b85"
RootLayout
      ↓
AdminLayout
      ↓
SettingsPage
```

Next.js immediately notices:

```text id="ic2clv"
RootLayout
     =
unchanged

AdminLayout
     =
unchanged

Current Page
     =
changed
```

Therefore it performs:

```text id="u2i33z"
Keep RootLayout
Keep AdminLayout
Replace Current Page
```

This optimization is called **partial rendering**.

---

# Why Partial Rendering Is Efficient

Suppose we navigate:

```text id="q5wzdk"
/dashboard/users
        ↓
/dashboard/settings
```

Traditional websites perform:

```text id="yqazm8"
Download HTML
Download CSS
Download JavaScript
Build DOM
Render Everything
```

The App Router performs:

```text id="hkl6fr"
Analyze Route
       ↓
Find Shared Layouts
       ↓
Keep Them Mounted
       ↓
Fetch Changed Segment
       ↓
Replace Changed Subtree
```

Before:

```text id="a6df7t"
Header
Sidebar
UsersPage
Footer
```

After:

```text id="ttrmgo"
Header
Sidebar
SettingsPage
Footer
```

Notice what didn't change:

```text id="3fjlwm"
Header
Sidebar
Footer
```

Because these components remain mounted:

* JavaScript isn't re-executed
* state isn't destroyed
* DOM nodes aren't recreated
* browser work is minimized

This is why App Router navigation often feels instantaneous.

---

# What Happens When You Click a Link?

Suppose a user clicks:

```text id="fdygj5"
/admin/settings
```

while currently viewing:

```text id="1t3ovk"
/admin/users
```

Internally, Next.js performs:

```text id="3eqarf"
1. Analyze URL
          ↓
2. Parse Route Segments
          ↓
3. Build New Layout Tree
          ↓
4. Compare Layout Trees
          ↓
5. Preserve Shared Layouts
          ↓
6. Remove Changed Subtree
          ↓
7. Render New Subtree
```

Visually:

Before:

```text id="9rn1z7"
RootLayout
      ↓
AdminLayout
      ↓
UsersPage
```

After:

```text id="0t18fi"
RootLayout
      ↓
AdminLayout
      ↓
SettingsPage
```

The App Router performs the smallest update possible.

This philosophy is one of the reasons React and Next.js scale so well.

---

# Interactive Layouts

Sometimes layouts themselves require interactivity.

Examples include:

* collapsible sidebars
* theme switchers
* active navigation
* keyboard shortcuts
* command palettes
* user preferences
* persisted UI state

These features require browser APIs.

Therefore they require Client Components.

Example:

```tsx id="v21lm4"
"use client";
```

Remember:

Only the interactive portion should become a Client Component.

---

# Persisting Sidebar State

Suppose your dashboard sidebar can collapse.

```tsx id="d5jz08"
const [collapsed, setCollapsed] =
  useState(false);
```

You can persist the state using `localStorage`.

Load:

```tsx id="a5mklj"
useEffect(() => {
  const saved =
    localStorage.getItem(
      "sidebar"
    );

  if (saved) {
    setCollapsed(
      saved === "true"
    );
  }
}, []);
```

Save:

```tsx id="t1zj4e"
useEffect(() => {
  localStorage.setItem(
    "sidebar",
    String(collapsed)
  );
}, [collapsed]);
```

Result:

```text id="egxx0l"
Collapse Sidebar
       ↓
Navigate
       ↓
Refresh Browser
       ↓
Sidebar Remains Collapsed
```

Because:

```text id="mhhx53"
Layout
      ↓
State
      ↓
Persistence
```

---

# Active Navigation

Most dashboards highlight the current route.

Example:

```tsx id="l5nlpw"
"use client";

import {
  usePathname,
} from "next/navigation";

export default function Sidebar() {
  const pathname =
    usePathname();

  return <>{pathname}</>;
}
```

This enables:

* active links
* breadcrumbs
* route-aware menus
* dashboard navigation
* navigation highlighting

Example:

```text id="jslnst"
/dashboard/users
```

might render:

```text id="jq3v7s"
Dashboard
→ Users
```

while:

```text id="wntxam"
/dashboard/settings
```

renders:

```text id="nd72r1"
Dashboard
→ Settings
```

---

# Sharing State with Context

Suppose multiple components need sidebar state.

A beginner might do:

```text id="sj5cy0"
Layout
    ↓
Page
    ↓
Component
    ↓
Child
```

This is called **prop drilling**.

Instead, use Context.

```text id="upm7hl"
SidebarProvider
       ↓
AdminLayout
       ↓
Entire Dashboard
```

Example:

```tsx id="stuh18"
const {
  collapsed,
  toggleSidebar,
} = useSidebar();
```

Benefits:

* no prop drilling
* centralized state
* cleaner components
* easier maintenance

---

# Layouts vs Templates

One of the most confusing App Router concepts is the difference between:

```text id="f4y1rh"
layout.tsx
```

and:

```text id="ywvmyx"
template.tsx
```

The easiest way to remember the difference is:

```text id="mzvwls"
layout.tsx
      =
remember everything

template.tsx
      =
forget everything
```

| Feature            | layout.tsx | template.tsx |
| ------------------ | ---------- | ------------ |
| Persists           | Yes        | No           |
| Preserves state    | Yes        | No           |
| Preserves scroll   | Yes        | No           |
| Remounts           | No         | Yes          |
| Replays animations | No         | Yes          |

---

# When Should You Use Templates?

Templates intentionally recreate the component tree.

This makes them useful for:

### Replay animations

```text id="ljlwm8"
Navigate
      ↓
Replay Animation
```

### Reset forms

```text id="ftf4e6"
Navigate Away
       ↓
Navigate Back
       ↓
Start Fresh
```

### Re-run initialization logic

```text id="8szkya"
Route Change
      ↓
Reinitialize
```

For most applications:

```text id="9v06vw"
95%
layout.tsx

5%
template.tsx
```

is a reasonable rule of thumb.

---

# Production Architecture

Large applications often look like:

```text id="y17r4w"
app/
│
├── layout.tsx
│
├── auth/
│   └── layout.tsx
│
├── dashboard/
│   ├── layout.tsx
│   ├── analytics/
│   ├── users/
│   ├── reports/
│   └── settings/
│
└── marketing/
    ├── layout.tsx
    ├── blog/
    └── pricing/
```

Each layout becomes its own application shell.

| Layout    | Responsibility      |
| --------- | ------------------- |
| Root      | Global application  |
| Auth      | Authentication      |
| Marketing | Public website      |
| Dashboard | Dashboard shell     |
| Settings  | Settings navigation |

---

# Designing Layouts Before Writing Code

Professional developers rarely start by creating folders.

Instead, they design the layout hierarchy first.

Ask three questions.

---

## Question 1

What appears everywhere?

Examples:

* header
* footer
* providers
* theme

These belong in:

```text id="ah31ng"
RootLayout
```

---

## Question 2

What appears only in certain sections?

Examples:

* dashboard sidebar
* admin navigation
* settings menu

These become:

```text id="n11m6j"
Nested Layouts
```

---

## Question 3

What actually changes?

Examples:

* reports
* analytics
* users
* settings

These become:

```text id="xj0lmo"
page.tsx
```

---

# Example Architecture Planning

Before coding:

```text id="8oxmsu"
Application
│
├── RootLayout
│
├── Marketing
│
└── DashboardLayout
      │
      ├── Sidebar
      ├── Navigation
      │
      └── Current Page
```

After planning:

```text id="sg1wyh"
app/
├── layout.tsx
├── marketing/
│    └── page.tsx
└── dashboard/
     ├── layout.tsx
     ├── users/
     └── settings/
```

The filesystem becomes a reflection of your architecture.

---

# Production Best Practices

Keep layouts server-first.

```text id="zbzncz"
Server Layout
      ↓
Small Client Components
```

Store persistent UI state inside layouts.

Examples:

* sidebar state
* theme selection
* filters
* active tabs
* panel visibility

Use Context for shared state.

Avoid prop drilling.

Extract complex logic into hooks.

Example:

```text id="okn0gl"
hooks/
└── useAdminSidebar.ts
```

Use state libraries only when necessary.

Examples:

* Zustand
* Jotai
* Redux Toolkit

---

# Knowledge Check

## Question 1

Given:

```text id="ztgok8"
app/
├── layout.tsx
└── dashboard/
     ├── layout.tsx
     └── users/
          └── page.tsx
```

What renders for:

```text id="72wm4g"
/dashboard/users
```

### Answer

```text id="eq2rwp"
RootLayout
      ↓
DashboardLayout
      ↓
UsersPage
```

Equivalent React:

```tsx id="3dvcgt"
<RootLayout>
  <DashboardLayout>
    <UsersPage />
  </DashboardLayout>
</RootLayout>
```

---

## Question 2

When navigating:

```text id="cgdh1u"
/dashboard/users
      ↓
/dashboard/settings
```

what remains mounted?

### Answer

```text id="opmxr8"
RootLayout
DashboardLayout
```

Only the page changes.

---

## Question 3

Which preserves state?

A) `page.tsx`

B) `template.tsx`

C) `layout.tsx`

### Answer

✅ `layout.tsx`

---

## Question 4

Which require Client Components?

* `useState`
* `useEffect`
* `window`
* `localStorage`
* `onClick`
* `fetch`

### Answer

Require client:

✅ `useState`
✅ `useEffect`
✅ `window`
✅ `localStorage`
✅ `onClick`

Do not require client:

❌ `fetch`

because Server Components can fetch directly.

---

# The Ultimate Mental Model

Beginners think:

```text id="0o7kzf"
Website
      ↓
Pages
```

Professional Next.js engineers think:

```text id="x4l3qj"
Website
      ↓
Route Segments
      ↓
Special Files
      ↓
Layout Tree
      ↓
Server Components
      ↓
Client Components
      ↓
Persistent UI Shell
      ↓
Rendered Application
```

Or put another way:

> The App Router is not a page router.

It is a **persistent UI composition engine that constructs and preserves a hierarchical React component tree based on the current URL.**

Once you understand this idea, you understand the philosophy behind modern Next.js.

---

This completes the enhanced Part 3. Part 4 can now naturally transition into Routing, Navigation, and Dynamic Routes, because students now understand that routing is really about constructing and updating the layout tree.
