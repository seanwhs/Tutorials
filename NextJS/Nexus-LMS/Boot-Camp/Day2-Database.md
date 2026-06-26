# 🟡 DAY 2 — SUPABASE DATABASE + COURSE SYSTEM

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 2

By the end of today, you will have:

```text id="d2_goal"
✔ Supabase connected to LMS
✔ Courses table created
✔ Courses listed in dashboard UI
✔ First real LMS data flow working
```

This is the moment Nexus LMS becomes a **data-driven application**.

---

# 🧱 STEP 1 — Create Supabase Project (if not done)

Go to:

Supabase

Create a new project:

* Name: `nexus-lms`
* Save:

  * Project URL
  * anon key

---

# 🔑 STEP 2 — Add Environment Variables

Update `.env.local`:

```env id="d2_env"
NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
```

---

# 🧠 STEP 3 — Create Supabase Client

Create:

```text id="d2_file1"
lib/supabase.ts
```

---

## Paste:

```ts id="d2_supabase_client"
import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

---

# 🧪 CHECKPOINT 1

Restart server:

```bash id="d2_run1"
npm run dev
```

✔ No errors in terminal

---

# 🗄️ STEP 4 — Create Courses Table

In Supabase SQL Editor, run:

```sql id="d2_sql1"
create table courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  created_at timestamp default now()
);
```

---

# 🧪 CHECKPOINT 2

Go to Supabase Table Editor:

✔ You should see:

```text id="d2_table"
courses table created
```

---

# ✍️ STEP 5 — Insert Test Data

Run SQL:

```sql id="d2_sql2"
insert into courses (title)
values ('Introduction to Nexus LMS');
```

---

✔ Expected:

* one row appears in `courses`

---

# 🔗 STEP 6 — Fetch Courses in Dashboard

Edit:

```text id="d2_file2"
app/(dashboard)/page.tsx
```

---

## Replace with:

```ts id="d2_dashboard_fetch"
import { supabase } from "@/lib/supabase";

export default async function Page() {
  const { data, error } = await supabase.from("courses").select("*");

  if (error) {
    return <div>Error loading courses</div>;
  }

  return (
    <div>
      <h1>Dashboard</h1>

      <h2>Courses</h2>

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

# 🧪 CHECKPOINT 3

Go to:

```text id="d2_url"
http://localhost:3000/dashboard
```

✔ Expected:

```text id="d2_ui"
Dashboard
Courses
- Introduction to Nexus LMS
```

---

# 🐛 DEBUG GUIDE

| Problem        | Cause                    | Fix            |
| -------------- | ------------------------ | -------------- |
| empty list     | table empty              | insert row     |
| fetch error    | wrong URL/key            | check env      |
| undefined data | supabase not initialized | restart server |

---

# 🧠 STEP 7 — Understanding What You Built

Today you created:

---

## 1. Real database layer

```text id="d2_layer1"
Next.js → Supabase → PostgreSQL
```

---

## 2. First LMS domain model

```text id="d2_model"
Course = core learning unit
```

---

## 3. Data-driven UI

Your dashboard is now:

> dynamically powered by database state

---

# 🚀 DAY 2 COMPLETE STATE

```text id="d2_final"
Frontend: WORKING
Auth: WORKING
Database: CONNECTED
Courses: LOADING FROM DB
LMS foundation: REAL
```

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🟠 DAY 3 — COURSE CREATION SYSTEM + FIRST FULL CRUD FLOW

We will build:

* create course form
* server actions
* real CRUD pipeline
* user-generated LMS content
* connect auth → ownership model (important step toward multi-tenancy)
