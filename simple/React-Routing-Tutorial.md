# 📘 React Router v7 Tutorial 

React Router v7 represents the **mature, production-grade evolution** of routing in React.
Routing in v7 is no longer a thin layer that simply switches views — it’s the **core application orchestrator**.

React Router now handles:

* **URL → UI mapping**
* **Data loading before render**
* **Form mutations**
* **Redirects**
* **Error boundaries**
* **Layout composition**
* **Pending / transition states**

In React Router **v7.12.0**, these patterns are **first-class, stable, and expected in real-world apps**.

Understanding this shift will make you not just “a user of React Router,” but someone who **architects scalable React apps**.

---

## 🧩 1. Installation — Get Started Fast

Install React Router for browser-based applications:

```bash
npm install react-router-dom
```

This single package gives you:

* Browser routing
* Data APIs (`loader`, `action`)
* Navigation primitives
* Error handling
* Fetcher utilities
* Pending / transition state support

No need for separate packages — everything modern routing needs is here.

---

## 🧠 2. React Router v7 Mental Model — What Changed?

React Router v7 enforces a **Route-Centric Architecture**, and this is the single most important idea.

### 🕰 Legacy Thinking (Old Way — Now Obsolete)

In older patterns, apps relied on:

* Routes inside JSX components
* `useEffect` for data fetching
* Manual loading and error states
* Logic spread across components

This works for small apps — but quickly becomes chaotic at scale.

---

### ⚡ Modern Thinking (v7 Philosophy)

With v7:

✔ Routes are **configuration**
✔ Data loads **before render**
✔ Mutations belong to the route
✔ Errors are **route-scoped**
✔ UI components render **pure view logic**

> In v7, **routes *are* your application structure.**

This mirrors how modern frameworks (like Remix or Next.js) structure apps, but keeps you in control on the client.

---

## 🧱 3. Creating the Router — Route Object API

React Router v7 centers around **Route Objects** and a **Router Provider**.

This completely replaces:

* `<BrowserRouter>`
* `<Routes>`
* `<Route />`

### main.jsx

```jsx
import { createRoot } from 'react-dom/client';
import {
  createBrowserRouter,
  RouterProvider,
} from 'react-router-dom';

import RootLayout from './layouts/RootLayout';
import Home from './pages/Home';
import Dashboard from './pages/Dashboard';
import About from './pages/About';
import ErrorPage from './pages/ErrorPage';

const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    errorElement: <ErrorPage />,
    children: [
      { index: true, element: <Home /> },
      { path: 'dashboard', element: <Dashboard /> },
      { path: 'about', element: <About /> },
    ],
  },
]);

createRoot(document.getElementById('root')).render(
  <RouterProvider router={router} />
);
```

---

### What This Does

#### 📌 `createBrowserRouter`

* Uses the HTML5 History API
* Enables clean URLs
* Drives all v7 Data APIs

This function **defines your entire app structure and behavior**.

---

#### 📌 `RouterProvider`

This is the runtime engine for routing.

It:

* Injects router state into your app
* Runs loaders, actions, and errors
* Coordinates navigation and transitions

---

#### 📌 `index: true`

* Marks a **default child route**
* Renders when the parent path matches exactly
* Avoids redundant `/` paths

---

## 📐 4. Layout Routes & `<Outlet />`

Layout routes allow you to build **persistent UI shells** that wrap changing content — think:

* Navigation bars
* Sidebars
* Footers
* Dashboard scaffolding

This is essential for real apps with shared UI.

### RootLayout.jsx

```jsx
import { Outlet } from 'react-router-dom';
import Navbar from '../components/Navbar';

export default function RootLayout() {
  return (
    <>
      <Navbar />
      <main>
        <Outlet />
      </main>
    </>
  );
}
```

---

### How Layout Routing Works

* Layout routes render **once**
* `<Outlet />` displays the active child route
* Navigating only swaps the **inner content**

This pattern prevents UI duplication and promotes composition.

---

## 🔗 5. Navigation — Links Without Reloads

### ❌ Don’t Use `<a href="">` for Internal Navigation

Anchor tags:

* Cause full page reload
* Break SPA behavior
* Reset React state and context

---

### ✅ Use `<Link>` and `<NavLink>`

```jsx
import { Link, NavLink } from 'react-router-dom';

export default function Navbar() {
  return (
    <nav>
      <Link to="/">Home</Link>

      <NavLink
        to="/about"
        className={({ isActive }) =>
          isActive ? 'active' : undefined
        }
      >
        About
      </NavLink>
    </nav>
  );
}
```

---

### Why `NavLink` Is Useful

* Detects active route
* Automatically adds active styling
* Perfect for menus, tabs, sidebars

This removes manual class logic.

---

## 🧬 6. Dynamic Routes & URL State

Dynamic routes let you reuse a component for many URLs.

### Route Definition

```js
{
  path: 'users/:username',
  element: <UserProfile />,
}
```

---

### Reading Parameters

```jsx
import { useParams } from 'react-router-dom';

export default function UserProfile() {
  const { username } = useParams();
  return <h1>User: {username}</h1>;
}
```

> In v7, the URL is **application state**, not just navigation.

Treating URLs as state unlocks powerful UX patterns.

---

## 📥 7. Data Fetching with `loader()` — The v7 Standard

React Router v7 makes **route-level data fetching the default**.

This eliminates `useEffect` and centralizes data logic.

---

### Defining a Loader

```js
{
  path: 'dashboard',
  element: <Dashboard />,
  loader: async () => {
    const response = await fetch('/api/dashboard');
    if (!response.ok) {
      throw new Response('Failed to load dashboard', { status: 500 });
    }
    return response.json();
  },
}
```

---

### Consuming Loader Data

```jsx
import { useLoaderData } from 'react-router-dom';

export default function Dashboard() {
  const data = useLoaderData();
  return <pre>{JSON.stringify(data, null, 2)}</pre>;
}
```

---

### Why Loaders Are Better

✅ Load data **before rendering**
✅ No `useEffect` boilerplate
✅ Consistent error and loading behavior
✅ Built-in pending state
✅ Shared logic across screens

This creates **declarative data dependencies**.

---

## ✉️ 8. Mutations with `action()` — Forms Done Right

React Router v7 treats **form submissions as route mutations**.

This finally gives forms the structure they deserve.

---

### Route Action

```js
{
  path: 'login',
  element: <Login />,
  action: async ({ request }) => {
    const formData = await request.formData();
    const username = formData.get('username');

    if (!username) {
      return { error: 'Username required' };
    }

    return redirect('/dashboard');
  },
}
```

---

### Form Component

```jsx
import { Form, useActionData } from 'react-router-dom';

export default function Login() {
  const error = useActionData();

  return (
    <Form method="post">
      <input name="username" />
      <button type="submit">Log In</button>
      {error && <p>{error.error}</p>}
    </Form>
  );
}
```

---

### Why Route Actions Matter

* No `preventDefault()`
* No fetch boilerplate
* Native browser behavior preserved
* Fully accessible forms
* Progressive enhancement

Forms now behave like **first-class citizens** in your router.

---

## 🧭 9. Programmatic Navigation

When you must navigate from code:

```jsx
import { useNavigate } from 'react-router-dom';

export default function LogoutButton() {
  const navigate = useNavigate();

  function handleLogout() {
    // clear auth state
    navigate('/');
  }

  return <button onClick={handleLogout}>Log Out</button>;
}
```

Prefer links/forms when possible — keep navigation declarative.

---

## ❗ 10. Error Handling — Route Scoped & Predictable

React Router v7 treats errors as **route-localized boundaries**.

---

### Error Page

```jsx
import { useRouteError } from 'react-router-dom';

export default function ErrorPage() {
  const error = useRouteError();

  return (
    <div>
      <h1>Something went wrong</h1>
      <pre>{error.statusText || error.message}</pre>
    </div>
  );
}
```

Sources of errors include:

* Loaders
* Actions
* Render failures
* Unmatched routes

Each route manages its own failures — preventing app-wide crashes.

---

## ✅ 11. Summary Checklist (v7.12.0 Ready)

✔ Route objects define app structure
✔ `RouterProvider` powers routing
✔ Layouts + `<Outlet />` for shared UI
✔ `<Link>` / `<NavLink>` navigation
✔ Dynamic routes (`:param`)
✔ `loader()` for data fetching
✔ `action()` for mutations
✔ Route-scoped error boundaries

---

## 📌 Final Perspective

React Router v7 isn’t just routing anymore — it’s:

* A **coordination layer**
* A **data lifecycle manager**
* A **UI composition system**

When you embrace the **route-centric mindset**, React Router becomes the **backbone of your application architecture**.


