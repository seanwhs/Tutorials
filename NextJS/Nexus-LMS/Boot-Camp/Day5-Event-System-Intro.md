# 🔵 DAY 5 — EVENT SYSTEM INTRO (INNGEST + ASSIGNMENT SUBMISSION FLOW)

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 5

By the end of today, you will have:

```text id="d5_goal"
✔ Assignment submission system
✔ First event emitted (assignment.submitted)
✔ Inngest workflow triggered
✔ Event-driven architecture introduced
✔ Bridge from CRUD → distributed system
```

This is the **most important architectural shift** in Nexus LMS.

---

# 🧠 WHAT CHANGES TODAY

Until now:

```text id="d5_before"
UI → Supabase → UI (CRUD system)
```

Today becomes:

```text id="d5_after"
UI → DB → EVENT → WORKFLOW → FUTURE AI WORKERS
```

---

# 🧱 STEP 1 — Create Submission Table

In Supabase:

Supabase

```sql id="d5_sql1"
create table submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid references assignments(id) on delete cascade,
  content text,
  created_at timestamp default now()
);
```

---

# 🧪 CHECKPOINT 1

Verify:

```text id="d5_table"
submissions table exists
```

---

# 🧠 STEP 2 — Setup Inngest Route Handler

Create:

```text id="d5_file1"
app/api/inngest/route.ts
```

---

## Paste:

```ts id="d5_inngest_route"
import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: []
});
```

---

# 🧪 CHECKPOINT 2

Run dev server:

```bash id="d5_run1"
npm run dev
```

✔ No errors in API route

---

# 🧠 STEP 3 — Create Event Emitter

We emit events from server actions.

---

Update:

```text id="d5_file2"
app/(dashboard)/courses/[courseId]/actions.ts
```

---

## Add submission + event:

```ts id="d5_action1"
"use server";

import { supabase } from "@/lib/supabase";
import { inngest } from "@/lib/inngest";
import { revalidatePath } from "next/cache";

export async function submitAssignment(
  assignmentId: string,
  formData: FormData
) {
  const content = formData.get("content") as string;

  // 1. Save submission
  await supabase.from("submissions").insert({
    assignment_id: assignmentId,
    content
  });

  // 2. Emit event
  await inngest.send({
    name: "assignment.submitted",
    data: {
      assignmentId,
      content
    }
  });

  revalidatePath(`/courses`);
}
```

---

# 🧪 CHECKPOINT 3

No UI yet — ensure no compile errors.

---

# 🧠 STEP 4 — Create Inngest Worker

Create:

```text id="d5_file3"
app/api/inngest/functions.ts
```

---

## Paste:

```ts id="d5_worker"
import { inngest } from "@/lib/inngest";

export const assignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted-worker" },
  { event: "assignment.submitted" },
  async ({ event }) => {
    console.log("EVENT RECEIVED:");
    console.log(event.data);

    // simulate future AI processing
    return {
      success: true,
      processed: true
    };
  }
);
```

---

# 🧠 STEP 5 — Register Worker

Update:

```text id="d5_file4"
app/api/inngest/route.ts
```

---

## Replace with:

```ts id="d5_route2"
import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest";
import { assignmentSubmitted } from "./functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [assignmentSubmitted]
});
```

---

# 🧪 CHECKPOINT 4

Go to:

```text id="d5_inngest_ui"
Inngest Dev Server / Dashboard
```

✔ Expected:

* event appears when triggered
* worker logs execution

---

# 🧠 STEP 6 — Add Submission UI

Edit:

```text id="d5_file5"
app/(dashboard)/courses/[courseId]/page.tsx
```

---

## Add form:

```ts id="d5_ui1"
import { submitAssignment } from "./actions";
import { supabase } from "@/lib/supabase";

export default async function Page({ params }) {
  const { courseId } = params;

  const { data: assignments } = await supabase
    .from("assignments")
    .select("*")
    .eq("course_id", courseId);

  return (
    <div>
      <h1>Course</h1>

      {assignments?.map((a) => (
        <div key={a.id} style={{ border: "1px solid #ddd", padding: 10 }}>
          <h3>{a.title}</h3>

          {/* SUBMISSION FORM */}
          <form action={submitAssignment.bind(null, a.id)}>
            <textarea name="content" placeholder="Write answer..." />
            <button type="submit">Submit</button>
          </form>
        </div>
      ))}
    </div>
  );
}
```

---

# 🧪 CHECKPOINT 5

Go to:

```text id="d5_url"
Course page
```

Try:

* submit assignment

✔ Expected:

```text id="d5_expected"
submission saved in DB
event fired to Inngest
worker logs execution
```

---

# 🧠 STEP 7 — What You Just Built

You now have a **real event-driven system**:

---

## Flow

```text id="d5_flow"
User submits assignment
  ↓
Supabase stores data
  ↓
Inngest event emitted
  ↓
Worker executes
  ↓
Logs appear in dashboard
```

---

## Architectural milestone

You transitioned from:

> CRUD system → distributed event system

---

# 🚀 DAY 5 COMPLETE STATE

```text id="d5_state"
Assignments: WORKING
Submissions: WORKING
Event system: ACTIVE
Inngest: CONNECTED
Workers: EXECUTING
```

---

# 🐛 DEBUG GUIDE

| Issue              | Cause                | Fix                    |
| ------------------ | -------------------- | ---------------------- |
| event not firing   | missing inngest.send | check server action    |
| worker not running | route not registered | verify functions array |
| DB empty           | insert failed        | check supabase insert  |

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🟣 DAY 6 — FIRST AI WORKER (GRADING + SIMULATED AI INTELLIGENCE LAYER)

We will build:

* mock AI grading worker
* structured AI output schema
* event → AI processing pipeline
* foundation for Markly-style grading system
* first “intelligent LMS behavior” layer
