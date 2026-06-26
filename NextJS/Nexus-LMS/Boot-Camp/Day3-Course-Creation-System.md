# 🟠 DAY 3 — COURSE CREATION (FULL CRUD FLOW)

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 3

By the end of today, you will have:

```text id="d3_goal"
✔ Create course form in UI
✔ Server-side course creation
✔ Real-time database insert (Supabase)
✔ Courses refresh in dashboard
✔ First full CRUD loop working
```

This is where Nexus LMS becomes a **real interactive system**, not just a viewer.

---

# 🧱 STEP 1 — Create Server Action (Create Course)

Create file:

```text id="d3_file1"
app/(dashboard)/actions.ts
```

---

## Paste:

```ts id="d3_action"
"use server";

import { supabase } from "@/lib/supabase";

export async function createCourse(formData: FormData) {
  const title = formData.get("title") as string;

  if (!title) return;

  const { error } = await supabase.from("courses").insert({
    title
  });

  if (error) {
    console.error("Error creating course:", error.message);
  }
}
```

---

# 🧪 CHECKPOINT 1

No UI yet — just ensure server compiles:

```bash id="d3_run1"
npm run dev
```

✔ No errors

---

# 🧠 STEP 2 — Add Create Course Form

Edit:

```text id="d3_file2"
app/(dashboard)/page.tsx
```

---

## Replace with:

```ts id="d3_dashboard_ui"
import { supabase } from "@/lib/supabase";
import { createCourse } from "./actions";

export default async function Page() {
  const { data } = await supabase.from("courses").select("*");

  return (
    <div>
      <h1>Dashboard</h1>

      {/* CREATE COURSE FORM */}
      <form action={createCourse} style={{ marginTop: 20 }}>
        <input
          name="title"
          placeholder="Enter course title"
          style={{
            padding: 8,
            marginRight: 10,
            border: "1px solid #ccc"
          }}
        />
        <button type="submit">Create Course</button>
      </form>

      {/* COURSE LIST */}
      <h2 style={{ marginTop: 30 }}>Courses</h2>

      {data?.map((course) => (
        <div
          key={course.id}
          style={{
            padding: 10,
            border: "1px solid #ddd",
            marginTop: 10
          }}
        >
          {course.title}
        </div>
      ))}
    </div>
  );
}
```

---

# 🧪 CHECKPOINT 2

Go to:

```text id="d3_url1"
http://localhost:3000/dashboard
```

Try:

* Enter course name
* Click “Create Course”

✔ Expected:

```text id="d3_expected"
New course appears after refresh
```

---

# 🐛 DEBUG GUIDE

| Issue             | Cause                   | Fix                           |
| ----------------- | ----------------------- | ----------------------------- |
| form does nothing | server action not bound | check `action={createCourse}` |
| insert fails      | Supabase permissions    | disable RLS temporarily       |
| no refresh        | expected behavior       | refresh manually              |

---

# 🧠 STEP 3 — Improve UX (Auto Refresh Fix)

Right now, Next.js does NOT auto-refresh.

We fix this properly.

---

## Update server action:

```ts id="d3_action2"
"use server";

import { supabase } from "@/lib/supabase";
import { revalidatePath } from "next/cache";

export async function createCourse(formData: FormData) {
  const title = formData.get("title") as string;

  await supabase.from("courses").insert({ title });

  revalidatePath("/dashboard");
}
```

---

# 🧪 CHECKPOINT 3

Now:

✔ Course appears instantly after submit
✔ No manual refresh needed

---

# 🧠 STEP 4 — Understand What You Built

Today you implemented:

---

## 1. Write path

```text id="d3_flow1"
UI form → Server Action → Supabase insert
```

---

## 2. Read path

```text id="d3_flow2"
Dashboard → Supabase select → UI render
```

---

## 3. Reactivity layer

```text id="d3_flow3"
revalidatePath("/dashboard")
```

---

# 🧩 CORE CONCEPT LEARNED

> You just built your first full CRUD loop:

* Create ✔
* Read ✔
* UI sync ✔

---

# 🚀 DAY 3 COMPLETE STATE

```text id="d3_final"
Auth: WORKING
Database: CONNECTED
Course creation: WORKING
Course listing: WORKING
CRUD loop: COMPLETE
```

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🟡 DAY 4 — ASSIGNMENTS SYSTEM + LMS STRUCTURE INTRO

We will build:

* assignments table
* course → assignment relationship
* nested LMS structure
* first real “learning hierarchy”
* foundation for AI workers later (important step)
