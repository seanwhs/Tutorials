# 🟡 DAY 4 — ASSIGNMENTS SYSTEM (LMS STRUCTURE INTRO)

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 4

By the end of today, you will have:

```text id="d4_goal"
✔ Assignments table in Supabase
✔ Course → Assignment relationship
✔ Assignment creation UI
✔ Assignment listing per course
✔ First real LMS hierarchy (Course → Assignments)
```

This is where Nexus LMS stops being “a list of courses” and becomes a **real learning system**.

---

# 🧱 STEP 1 — Create Assignments Table

Go to Supabase SQL Editor and run:

Supabase

```sql id="d4_sql1"
create table assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id) on delete cascade,
  title text not null,
  description text,
  created_at timestamp default now()
);
```

---

# 🧪 CHECKPOINT 1

Go to Supabase Table Editor:

✔ You should now see:

```text id="d4_table"
courses
assignments
```

---

# 🧠 STEP 2 — Update Folder Structure

We introduce course-level routing:

```text id="d4_folders"
app/(dashboard)/courses/[courseId]/
  page.tsx
  actions.ts
```

---

# 🔗 STEP 3 — Course Page (Dynamic Route)

Create:

```text id="d4_file1"
app/(dashboard)/courses/[courseId]/page.tsx
```

---

## Paste:

```ts id="d4_course_page"
import { supabase } from "@/lib/supabase";
import { createAssignment } from "./actions";

export default async function Page({ params }) {
  const { courseId } = params;

  const { data: assignments } = await supabase
    .from("assignments")
    .select("*")
    .eq("course_id", courseId);

  return (
    <div>
      <h1>Course</h1>

      {/* CREATE ASSIGNMENT FORM */}
      <form action={createAssignment.bind(null, courseId)}>
        <input name="title" placeholder="Assignment title" />
        <input name="description" placeholder="Description" />
        <button type="submit">Create Assignment</button>
      </form>

      {/* LIST ASSIGNMENTS */}
      <h2>Assignments</h2>

      {assignments?.map((a) => (
        <div key={a.id} style={{ padding: 10, border: "1px solid #ddd" }}>
          <h3>{a.title}</h3>
          <p>{a.description}</p>
        </div>
      ))}
    </div>
  );
}
```

---

# 🧱 STEP 4 — Create Assignment Action

Create:

```text id="d4_file2"
app/(dashboard)/courses/[courseId]/actions.ts
```

---

## Paste:

```ts id="d4_action"
"use server";

import { supabase } from "@/lib/supabase";
import { revalidatePath } from "next/cache";

export async function createAssignment(
  courseId: string,
  formData: FormData
) {
  const title = formData.get("title") as string;
  const description = formData.get("description") as string;

  await supabase.from("assignments").insert({
    course_id: courseId,
    title,
    description
  });

  revalidatePath(`/courses/${courseId}`);
}
```

---

# 🧪 CHECKPOINT 2

Go to:

```text id="d4_url1"
http://localhost:3000/dashboard
```

Then:

* open a course (we will add navigation next)
* create assignment

✔ Expected:

```text id="d4_expected"
Assignments appear under course
```

---

# 🧭 STEP 5 — Add Course Navigation Links

Update dashboard:

```text id="d4_file3"
app/(dashboard)/page.tsx
```

---

## Replace course list with links:

```ts id="d4_links"
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { createCourse } from "./actions";

export default async function Page() {
  const { data } = await supabase.from("courses").select("*");

  return (
    <div>
      <h1>Dashboard</h1>

      <form action={createCourse}>
        <input name="title" placeholder="Course title" />
        <button>Create</button>
      </form>

      <h2>Courses</h2>

      {data?.map((course) => (
        <Link
          key={course.id}
          href={`/courses/${course.id}`}
          style={{
            display: "block",
            padding: 10,
            border: "1px solid #ddd",
            marginTop: 10
          }}
        >
          {course.title}
        </Link>
      ))}
    </div>
  );
}
```

---

# 🧪 CHECKPOINT 3

✔ Click course → navigates to course page
✔ Assignments load per course

---

# 🧠 STEP 6 — What You Just Built

You now have a **real LMS data hierarchy**:

---

## Data model

```text id="d4_model"
Course
  ↓
Assignments
```

---

## System flow

```text id="d4_flow"
Dashboard → Course → Assignment
```

---

## Architecture milestone

You now have:

* relational LMS structure
* dynamic routing
* nested data fetching
* server-side mutation flow

---

# 🚀 DAY 4 COMPLETE STATE

```text id="d4_state"
Courses: WORKING
Assignments: WORKING
Nested routing: WORKING
CRUD flow: EXTENDED
LMS hierarchy: REAL
```

---

# 🐛 DEBUG GUIDE

| Issue                   | Cause             | Fix                 |
| ----------------------- | ----------------- | ------------------- |
| assignments not showing | wrong courseId    | check URL           |
| insert fails            | missing course_id | ensure bind() works |
| page 404                | folder mismatch   | verify `[courseId]` |

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🔵 DAY 5 — EVENT SYSTEM INTRO (INNGEST + ASSIGNMENT SUBMISSION FLOW)

We will build:

* assignment submission system
* first event emission
* Inngest workflow trigger
* foundation for AI workers
* transition from CRUD → event-driven LMS

This is the **real architecture shift point** of Nexus LMS.
