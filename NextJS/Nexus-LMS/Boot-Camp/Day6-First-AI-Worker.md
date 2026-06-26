# 🟣 DAY 6 — FIRST AI WORKER (GRADING INTELLIGENCE LAYER)

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 6

By the end of today, you will have:

```text id="d6_goal"
✔ AI grading worker (mock intelligence)
✔ Structured AI output schema
✔ Assignment submission → AI processing pipeline
✔ Stored “grade + feedback” results
✔ First real LMS intelligence layer
```

This is where Nexus LMS becomes **AI-native**, not just event-driven.

---

# 🧠 WHAT CHANGES TODAY

Before:

```text id="d6_before"
event → worker logs only
```

Today:

```text id="d6_after"
event → AI worker → grading result → stored feedback
```

---

# 🧱 STEP 1 — Create Grades Table

In Supabase:

Supabase

```sql id="d6_sql1"
create table grades (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid,
  score int,
  feedback text,
  created_at timestamp default now()
);
```

---

# 🧪 CHECKPOINT 1

Verify table exists:

```text id="d6_check1"
grades table created
```

---

# 🧠 STEP 2 — Upgrade Event Payload (Important)

We now enrich the event.

Update:

```text id="d6_file1"
actions.ts (submitAssignment)
```

---

## Replace event emit:

```ts id="d6_event"
await inngest.send({
  name: "assignment.submitted",
  data: {
    assignmentId,
    content
  }
});
```

✔ (no change needed, but now we *interpret it differently*)

---

# 🧠 STEP 3 — Create AI Grading Worker

Update:

```text id="d6_file2"
app/api/inngest/functions.ts
```

---

## Replace worker:

```ts id="d6_worker"
import { inngest } from "@/lib/inngest";
import { supabase } from "@/lib/supabase";

function fakeAIGrader(content: string) {
  const length = content.length;

  let score = 50;

  if (length > 50) score += 20;
  if (length > 150) score += 20;

  return {
    score: Math.min(score, 100),
    feedback:
      score > 80
        ? "Excellent explanation. Strong understanding."
        : score > 60
        ? "Good attempt. Add more detail."
        : "Needs improvement. Expand your answer."
  };
}

export const assignmentGradingWorker = inngest.createFunction(
  { id: "ai-grading-worker" },
  { event: "assignment.submitted" },
  async ({ event }) => {
    const { assignmentId, content } = event.data;

    // 1. AI processing (mocked)
    const result = fakeAIGrader(content);

    // 2. Store grade
    const { data, error } = await supabase.from("grades").insert({
      submission_id: assignmentId,
      score: result.score,
      feedback: result.feedback
    });

    console.log("GRADE RESULT:", result);

    if (error) {
      console.error("DB error:", error.message);
    }

    return {
      success: true,
      graded: true,
      result
    };
  }
);
```

---

# 🧠 STEP 4 — Register Worker

Update:

```text id="d6_file3"
app/api/inngest/route.ts
```

---

## Replace:

```ts id="d6_route"
import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest";
import { assignmentGradingWorker } from "./functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [assignmentGradingWorker]
});
```

---

# 🧪 CHECKPOINT 2

Trigger submission again:

```text id="d6_test1"
Submit assignment in UI
```

✔ Expected:

```text id="d6_expected1"
Event fired → worker runs → grade inserted in DB
```

---

# 🧠 STEP 5 — View Grades in UI

Update course page:

```text id="d6_file4"
app/(dashboard)/courses/[courseId]/page.tsx
```

---

## Add grade fetch:

```ts id="d6_ui"
const { data: grades } = await supabase.from("grades").select("*");
```

---

## Display:

```tsx id="d6_render"
<h2>Grades</h2>

{grades?.map((g) => (
  <div key={g.id} style={{ border: "1px solid #ddd", padding: 10 }}>
    <p>Score: {g.score}</p>
    <p>{g.feedback}</p>
  </div>
))}
```

---

# 🧪 CHECKPOINT 3

✔ Submit assignment
✔ Grade appears below

---

# 🧠 STEP 6 — What You Just Built

You now have a full **AI processing pipeline**:

---

## Flow

```text id="d6_flow"
Student submits assignment
   ↓
Event emitted (Inngest)
   ↓
AI worker runs grading logic
   ↓
Score + feedback generated
   ↓
Stored in Supabase
   ↓
Displayed in UI
```

---

## This is the key milestone:

> You just built your first AI-powered LMS feature.

---

# 🧠 STEP 7 — Architecture Upgrade

You now introduced:

---

## 1. AI abstraction layer

```text id="d6_ai"
fakeAIGrader → real LLM later
```

---

## 2. Structured output contract

```json id="d6_schema"
{
  "score": 85,
  "feedback": "..."
}
```

---

## 3. Event-driven AI pipeline

* no UI coupling
* no synchronous blocking
* fully async intelligence layer

---

# 🚀 DAY 6 COMPLETE STATE

```text id="d6_state"
Assignments: WORKING
Submissions: WORKING
AI Worker: ACTIVE
Grading system: LIVE
Database: storing AI output
```

---

# 🐛 DEBUG GUIDE

| Issue            | Cause                | Fix                     |
| ---------------- | -------------------- | ----------------------- |
| no grades        | worker not triggered | check event name        |
| empty feedback   | insert failed        | check supabase schema   |
| duplicate grades | multiple events      | verify submission logic |

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🟣 DAY 7 — PLUGIN REGISTRY (SANITY) + DYNAMIC AI WORKER SYSTEM

We will build:

* Sanity-based worker registry
* dynamic AI tool discovery
* remove hardcoded workers
* first “plugin-based LMS architecture”
* foundation for Markly-style external AI integrations
