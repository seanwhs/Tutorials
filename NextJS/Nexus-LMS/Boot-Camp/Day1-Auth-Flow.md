# 🟢 DAY 1 — AUTH FLOW + PROTECTED DASHBOARD

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 1

By the end of today, you will have:

```text id="d1_goal"
✔ Login page working (Clerk)
✔ Protected /dashboard route
✔ User session visible in UI
✔ Basic LMS shell layout
```

This is the first moment Nexus LMS becomes a **real app with users**, not just infrastructure.

---

# 📁 STEP 1 — Create Auth Routes

Create folders:

```text id="d1_folders"
app/
  (auth)/
    sign-in/
      [[...sign-in]]/
        page.tsx
    sign-up/
      [[...sign-up]]/
        page.tsx
```

---

# 🔐 STEP 2 — Add Clerk Sign-in Page

```ts id="d1_signin"
import { SignIn } from "@clerk/nextjs";

export default function Page() {
  return (
    <div style={{ display: "flex", justifyContent: "center", marginTop: 100 }}>
      <SignIn />
    </div>
  );
}
```

---

# 🔐 STEP 3 — Add Clerk Sign-up Page

```ts id="d1_signup"
import { SignUp } from "@clerk/nextjs";

export default function Page() {
  return (
    <div style={{ display: "flex", justifyContent: "center", marginTop: 100 }}>
      <SignUp />
    </div>
  );
}
```

---

# 🧪 CHECKPOINT 1

Run:

```bash id="d1_run1"
npm run dev
```

Visit:

```text id="d1_urls"
http://localhost:3000/sign-in
http://localhost:3000/sign-up
```

✔ Expected:

* login UI appears
* sign-up works

---

# 🐛 DEBUG

| Issue         | Fix                     |
| ------------- | ----------------------- |
| blank page    | check file path exactly |
| Clerk error   | verify env keys         |
| redirect loop | middleware missing      |

---

# 🧭 STEP 4 — Add Middleware Protection

Create:

```text id="d1_mw_file"
middleware.ts
```

---

## Paste:

```ts id="d1_middleware"
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: [
    "/dashboard/:path*"
  ]
};
```

---

# 🧪 CHECKPOINT 2

Try opening:

```text id="d1_dash_try"
http://localhost:3000/dashboard
```

✔ Expected:

* redirected to login page if not signed in

---

# 🧠 STEP 5 — Create Dashboard Layout

Create:

```text id="d1_dash_layout"
app/(dashboard)/layout.tsx
```

---

## Paste:

```ts id="d1_layout"
import { UserButton } from "@clerk/nextjs";

export default function DashboardLayout({ children }) {
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      
      {/* Sidebar */}
      <div style={{ width: 250, padding: 20, borderRight: "1px solid #ddd" }}>
        <h2>Nexus LMS</h2>
        <nav>
          <p>Dashboard</p>
          <p>Courses</p>
          <p>Assignments</p>
        </nav>
      </div>

      {/* Main */}
      <div style={{ flex: 1, padding: 20 }}>
        <div style={{ display: "flex", justifyContent: "flex-end" }}>
          <UserButton />
        </div>

        {children}
      </div>
    </div>
  );
}
```

---

# 🧪 CHECKPOINT 3

Login → go to:

```text id="d1_dash"
http://localhost:3000/dashboard
```

✔ Expected UI:

* sidebar appears
* user avatar appears (top right)
* dashboard shell renders

---

# 🧭 STEP 6 — Create Dashboard Page

Create:

```text id="d1_page_file"
app/(dashboard)/page.tsx
```

---

## Paste:

```ts id="d1_dashboard_page"
export default function Page() {
  return (
    <div>
      <h1>Dashboard</h1>
      <p>Welcome to Nexus LMS</p>
    </div>
  );
}
```

---

# 🧪 FINAL CHECKPOINT

You should now see:

```text id="d1_final"
Sidebar: YES
Dashboard title: YES
User button: YES
Auth redirect: YES
```

---

# 🐛 DEBUG GUIDE

| Problem               | Cause                      | Fix              |
| --------------------- | -------------------------- | ---------------- |
| dashboard shows blank | layout missing             | check file path  |
| user button missing   | Clerk provider not wrapped | check layout.tsx |
| redirect not working  | middleware not applied     | restart server   |

---

# 🧠 WHAT YOU BUILT TODAY

You just implemented:

### 1. Authentication system

* sign in
* sign up
* session handling

### 2. Route protection

* middleware guard
* secure dashboard access

### 3. LMS shell UI

* sidebar layout
* dashboard structure
* user profile control

---

# 🚀 DAY 1 COMPLETE STATE

```text id="d1_state"
Auth system: WORKING
Protected routes: WORKING
Dashboard shell: WORKING
User session: WORKING
```

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🟡 DAY 2 — SUPABASE DATABASE + COURSE SYSTEM (FIRST REAL LMS DATA MODEL)

We will build:

* courses table
* Supabase integration in UI
* create + list courses
* first real LMS data flow
* connect auth → database ownership model
