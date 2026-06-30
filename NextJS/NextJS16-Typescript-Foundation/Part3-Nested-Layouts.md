# Next.js 16 TypeScript Foundations

# Part 3 — Nested Layouts in the App Router: How `children` Flows Through Your Entire Application

> **Series:** *From Confusing Layout Syntax to Confident Typed App Router Code*

In Part 1, we learned that a `RootLayout` is simply a React component that wraps our entire application.

In Part 2, we learned that `children` is just a normal React prop typed with `React.ReactNode`.

Now we're ready for one of the most powerful features of the Next.js App Router:

> Nested layouts.

This is where many developers suddenly realize:

> "Wait...my application isn't a collection of pages. It's actually a tree of layouts and pages."

Understanding this idea changes how you build applications.

Instead of thinking:

```text
Page A
Page B
Page C
```

you begin thinking:

```text
Application
    ├── Marketing Section
    ├── Dashboard Section
    └── Admin Section
```

Each section can have its own persistent UI, navigation, state, and behavior.

In this lesson, we'll learn how layouts compose together and how the `children` prop flows through the entire route tree.

---

# The Problem With Traditional Routing

Imagine building an application with:

```text
/
about
pricing
dashboard
dashboard/users
dashboard/settings
admin
admin/users
admin/settings
```

Without layouts, every page might need to repeat:

```text
Header
Navigation
Sidebar
Footer
```

For example:

```tsx
function DashboardUsers() {
  return (
    <>
      <Header />
      <Sidebar />
      <Users />
      <Footer />
    </>
  );
}
```

Then:

```tsx
function DashboardSettings() {
  return (
    <>
      <Header />
      <Sidebar />
      <Settings />
      <Footer />
    </>
  );
}
```

This creates:

* duplicated code
* maintenance problems
* inconsistent UI
* unnecessary rerenders

---

# The Layout Solution

Instead, Next.js lets us compose layouts.

For example:

```text
Root Layout
     ↓
Dashboard Layout
     ↓
Dashboard Page
```

Now the shared components only exist once.

---

# Your First Nested Layout

Consider this application structure:

```text
app/
├── layout.tsx
├── page.tsx
└── dashboard/
    ├── layout.tsx
    ├── page.tsx
    └── settings/
        └── page.tsx
```

We now have two layouts:

* the root layout
* the dashboard layout

---

# Root Layout

```tsx
// app/layout.tsx

type RootLayoutProps = {
  children: React.ReactNode;
};

export default function RootLayout({
  children,
}: RootLayoutProps) {
  return (
    <html lang="en">
      <body>
        <header>
          Main Navigation
        </header>

        {children}

        <footer>
          Footer
        </footer>
      </body>
    </html>
  );
}
```

---

# Dashboard Layout

```tsx
// app/dashboard/layout.tsx

type DashboardLayoutProps = {
  children: React.ReactNode;
};

export default function DashboardLayout({
  children,
}: DashboardLayoutProps) {
  return (
    <>
      <aside>
        Dashboard Sidebar
      </aside>

      <main>
        {children}
      </main>
    </>
  );
}
```

---

# Dashboard Page

```tsx
// app/dashboard/page.tsx

export default function DashboardPage() {
  return (
    <h1>
      Dashboard Home
    </h1>
  );
}
```

---

# What Actually Gets Rendered?

When a user visits:

```text
/dashboard
```

Next.js internally builds something conceptually like:

```tsx
<RootLayout>
  <DashboardLayout>
    <DashboardPage />
  </DashboardLayout>
</RootLayout>
```

This produces:

```text
Header
    ↓
Dashboard Sidebar
    ↓
Dashboard Home
    ↓
Footer
```

---

# Visualizing Nested Layouts

Think of layouts as Russian nesting dolls.

```text
┌─────────────────────────┐
│      Root Layout        │
│                         │
│ ┌─────────────────────┐ │
│ │ Dashboard Layout    │ │
│ │                     │ │
│ │ ┌─────────────────┐ │ │
│ │ │ Dashboard Page  │ │ │
│ │ └─────────────────┘ │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

Each layout wraps the next level.

---

# The `children` Chain

Remember our earlier mental model:

```text
children = "whatever is inside"
```

Now we extend it:

```text
RootLayout
    children
        ↓
DashboardLayout
            children
                ↓
DashboardPage
```

Each layout receives another component as its `children`.

---

# Adding Another Level

Suppose we add:

```text
app/
└── dashboard/
    └── settings/
        ├── layout.tsx
        └── page.tsx
```

Now we have:

```text
Root Layout
       ↓
Dashboard Layout
       ↓
Settings Layout
       ↓
Settings Page
```

---

# Settings Layout

```tsx
type SettingsLayoutProps = {
  children: React.ReactNode;
};

export default function SettingsLayout({
  children,
}: SettingsLayoutProps) {
  return (
    <>
      <h2>
        Settings Section
      </h2>

      {children}
    </>
  );
}
```

---

# Visiting `/dashboard/settings`

Next.js now renders:

```tsx
<RootLayout>
  <DashboardLayout>
    <SettingsLayout>
      <SettingsPage />
    </SettingsLayout>
  </DashboardLayout>
</RootLayout>
```

The nesting becomes:

```text
Header
    ↓
Sidebar
    ↓
Settings Header
    ↓
Settings Page
    ↓
Footer
```

---

# Why This Is Powerful

Imagine a real SaaS application.

```text
Application
    ├── Marketing
    ├── Dashboard
    ├── Admin
    └── Settings
```

Each area requires different UI.

---

# Marketing Section

```text
Header
Navigation
Footer
```

---

# Dashboard Section

```text
Header
Sidebar
Breadcrumbs
Notifications
```

---

# Admin Section

```text
Header
Admin Navigation
Permissions Panel
```

---

Without nested layouts, every page would repeat these components.

With nested layouts:

```text
Root Layout
    ↓
Section Layout
        ↓
Page
```

everything becomes reusable.

---

# Real Production Folder Structure

A medium-sized application might look like:

```text
app/
├── layout.tsx
├── page.tsx
│
├── dashboard/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── analytics/
│   │   └── page.tsx
│   ├── users/
│   │   └── page.tsx
│   └── settings/
│       └── page.tsx
│
├── admin/
│   ├── layout.tsx
│   ├── users/
│   └── permissions/
│
└── marketing/
    ├── layout.tsx
    ├── pricing/
    └── blog/
```

Notice:

* every section owns its layout
* pages inherit layouts automatically
* shared UI stays centralized

---

# Layout Persistence

One of the biggest App Router features is:

> Layouts persist between navigations.

Suppose you navigate:

```text
/dashboard
```

to:

```text
/dashboard/settings
```

The dashboard layout remains mounted.

Only the page changes.

Conceptually:

```text
Before:

DashboardLayout
    └── DashboardPage

After:

DashboardLayout
    └── SettingsPage
```

The layout itself stays alive.

---

# Why Is This Important?

Persistence enables:

* preserved sidebar state
* preserved search filters
* preserved scroll positions
* better performance
* fewer rerenders

For example:

```tsx
<DashboardSidebar />
```

does not need to reload every time.

---

# A Real Dashboard Example

```tsx
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="dashboard">
      <aside>
        <DashboardSidebar />
      </aside>

      <section>
        <DashboardToolbar />

        {children}
      </section>
    </div>
  );
}
```

Now:

```text
/dashboard
/dashboard/users
/dashboard/settings
/dashboard/billing
```

all share:

* sidebar
* toolbar
* layout structure

without duplication.

---

# How `children` Actually Flows

Consider:

```text
app/
├── layout.tsx
└── dashboard/
    ├── layout.tsx
    └── page.tsx
```

Step 1:

```text
DashboardPage
```

becomes:

```text
DashboardLayout(children)
```

Step 2:

```text
DashboardLayout
```

becomes:

```text
RootLayout(children)
```

Step 3:

```text
RootLayout
```

renders the final HTML.

---

# Mental Model

Think of layouts like envelopes.

```text
Page
  ↓
Envelope
  ↓
Envelope
  ↓
Envelope
```

Or:

```text
Page
  ↓
Section Layout
  ↓
Application Layout
```

Each level wraps the previous level.

---

# Common Beginner Mistakes

## Mistake #1

Thinking layouts replace one another.

They don't.

They stack.

---

## Mistake #2

Expecting layouts to rerender on every navigation.

They persist.

---

## Mistake #3

Duplicating navigation bars across pages.

Use layouts instead.

---

## Mistake #4

Creating one enormous root layout.

Instead create:

```text
Root
   ↓
Dashboard
   ↓
Admin
   ↓
Feature
```

smaller layouts.

---

# When Should You Create A New Layout?

A good rule:

Create a layout when multiple pages share:

* navigation
* sidebars
* toolbars
* providers
* authentication wrappers
* page structure
* persistent state

Do not create layouts just because you can.

---

# Practice Exercise

Create this structure:

```text
app/
├── layout.tsx
├── page.tsx
└── dashboard/
    ├── layout.tsx
    ├── page.tsx
    └── settings/
        └── page.tsx
```

Add:

### Root Layout

```text
Header
Footer
```

### Dashboard Layout

```text
Sidebar
```

### Settings Page

```text
Settings Content
```

Observe how the rendered UI becomes:

```text
Header
    ↓
Sidebar
    ↓
Settings Content
    ↓
Footer
```

without writing any duplicated code.

---

# What You've Learned

You now understand:

✓ layouts compose together

✓ layouts stack instead of replace

✓ `children` flows through the route tree

✓ nested layouts eliminate duplicated UI

✓ layouts persist across navigation

✓ App Router applications are hierarchical trees

✓ large applications can be organized into sections

Most importantly, you've learned that a Next.js application is not a collection of pages.

It's a tree of layouts containing pages.

In Part 4, we'll explore another major App Router concept:

> How dynamic routes create typed `params`, and how those parameters flow through your application.
