# 📘 React Routing Tutorial

React Router v7 represents the **mature, production-grade evolution** of routing in React.
Routing is no longer just about switching components—it is now the **core application orchestration layer**, responsible for:

* URL → UI mapping
* Data loading
* Form mutations
* Redirects
* Error boundaries
* Layout composition

In React Router **v7.12.0**, these concepts are **first-class**, stable, and expected in real-world applications.

---

## 1. Installation

Install React Router for browser-based applications:

```bash
npm install react-router-dom
```

This single package provides:

* Browser routing
* Data APIs (`loader`, `action`)
* Navigation primitives
* Error handling
* Fetcher utilities
* Pending / transition state support

---

## 2. The React Router v7 Mental Model (Critical)

React Router v7 enforces a **route-centric architecture**.

### Old Thinking (Deprecated)

* Routes inside JSX
* `useEffect` for data fetching
* Manual loading & error state
* Logic scattered across components

### Modern Thinking (v7)

* Routes are **configuration**
* Data loads **before render**
* Mutations live at the route
* Errors are **route-scoped**
* Components render **pure UI**

> **In v7, your routes *are* your application structure.**

---

## 3. Creating the Router (Route Object API)

React Router v7 uses **route objects** and a **Router Provider**.
This replaces `<BrowserRouter>` and `<Routes>` entirely.

---

### `main.jsx`

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

### Core Concepts Explained

#### `createBrowserRouter`

* Uses the HTML5 History API
* Enables clean URLs
* Required for **all v7 Data APIs**

#### `RouterProvider`

* Injects routing context
* Handles navigation, loaders, actions, errors

#### `index: true`

* Marks the **default child route**
* Renders when the parent path matches exactly

---

## 4. Layout Routes & `<Outlet />`

Layout routes allow you to define **persistent UI shells**:

* Headers
* Sidebars
* Navigation
* Footers

---

### Root Layout Component

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

### How Layout Routing Works

* The layout renders once
* `<Outlet />` is replaced by the active child route
* Navigation swaps only the content region

This pattern is **mandatory** for scalable apps.

---

## 5. Navigation (Client-Side, Zero Reloads)

### ❌ Never Use `<a href="">`

Anchor tags:

* Reload the page
* Destroy React state
* Break SPA behavior

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

### `NavLink` Advantages

* Automatically detects active route
* Ideal for menus, tabs, and sidebars

---

## 6. Dynamic Routes & URL State

Dynamic routing allows **one component to represent many URLs**.

---

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

> In v7, the **URL is application state**, not just navigation.

---

## 7. Data Fetching with `loader()` (v7 Standard)

React Router v7 makes **route-level data fetching the default**.

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

### Why This Is the v7 Way

✅ Data loads **before rendering**
✅ No `useEffect` boilerplate
✅ Automatic pending state handling
✅ Built-in error boundaries

---

## 8. Mutations with `action()` (Forms the Modern Way)

React Router v7 handles **form submissions at the route level**.

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

### Why This Matters

* No manual `preventDefault`
* No fetch boilerplate
* Native browser semantics preserved
* Fully accessible

---

## 9. Programmatic Navigation

For navigation triggered by logic:

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

---

## 10. Error Handling (Route-Scoped by Design)

React Router v7 uses **route-level error boundaries**.

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

Errors can come from:

* Loaders
* Actions
* Rendering failures
* Missing routes

---

## 11. Summary Checklist (v7.12.0 Ready)

✅ Route objects define app structure
✅ `RouterProvider` replaces legacy routers
✅ Layout routes + `<Outlet />` for shared UI
✅ `<Link>` / `<NavLink>` for navigation
✅ Dynamic routes (`:param`) for URL state
✅ `loader()` for data fetching
✅ `action()` for mutations
✅ Route-level error boundaries


