# 🧠 NEXUS LMS BOOTCAMP (EXECUTABLE EDITION)

> Goal: A beginner can follow this and end with a working AI-native LMS platform.

---

# 🗺️ OVERALL BUILD STRATEGY

We build in 4 phases:

```text
Phase 1: Foundation (Day 0–2)
Phase 2: Core LMS (Day 3–5)
Phase 3: Event + AI Layer (Day 6–8)
Phase 4: Plugin System + Production (Day 9–10)
```

---

# 🟢 DAY 0 — PROJECT SETUP (ZERO TO START)

## Goal

Create a working Next.js app + Supabase + Clerk + Sanity + Inngest.

---

## 0.1 Install dependencies

```bash
npx create-next-app@latest nexus-lms
cd nexus-lms
npm install @clerk/nextjs @supabase/supabase-js inngest sanity
```

---

## 0.2 Folder structure (initial)

```text
nexus-lms/
  app/
  lib/
  components/
  .env.local
```

---

## 0.3 Environment variables

```env
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=

CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=

INNGEST_EVENT_KEY=
```

---

## ✅ CHECKPOINT

Run:

```bash
npm run dev
```

Expected:

* Next.js homepage loads

---

## 🐛 DEBUG

| Problem    | Fix                       |
| ---------- | ------------------------- |
| blank page | check app/page.tsx exists |
| env error  | restart dev server        |

---

# 🟢 DAY 1 — AUTH SYSTEM (CLERK)

## Goal

Users can log in.

---

## 1.1 Wrap app with Clerk

```ts
// app/layout.tsx
import { ClerkProvider } from "@clerk/nextjs";

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

---

## 1.2 Middleware

```ts
// middleware.ts
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: ["/dashboard/:path*"]
};
```

---

## 1.3 Add login page

```text
app/sign-in/[[...sign-in]]/page.tsx
```

```ts
import { SignIn } from "@clerk/nextjs";

export default function Page() {
  return <SignIn />;
}
```

---

## ✅ CHECKPOINT

* visit `/sign-in`
* login works

---

## 🐛 DEBUG

| Issue         | Fix               |
| ------------- | ----------------- |
| redirect loop | check middleware  |
| blank login   | verify Clerk keys |

---

# 🟢 DAY 2 — SUPABASE SETUP

## Goal

Store users + courses.

---

## 2.1 Create Supabase client

```ts
// lib/supabase.ts
import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

---

## 2.2 Database tables

```sql
create table courses (
  id uuid primary key default gen_random_uuid(),
  title text,
  created_at timestamp default now()
);
```

---

## 2.3 Test insert

```ts
await supabase.from("courses").insert({
  title: "Nexus 101"
});
```

---

## ✅ CHECKPOINT

* course appears in Supabase dashboard

---

## 🐛 DEBUG

| Issue        | Fix                |
| ------------ | ------------------ |
| insert fails | check RLS disabled |
| no data      | verify table name  |

---

# 🟡 DAY 3 — LMS CORE (COURSES UI)

## Goal

Display courses in UI.

---

## Folder structure

```text
app/dashboard/
  page.tsx
```

---

## 3.1 Fetch courses

```ts
import { supabase } from "@/lib/supabase";

export default async function Dashboard() {
  const { data } = await supabase.from("courses").select("*");

  return (
    <div>
      <h1>Courses</h1>
      {data?.map((c) => (
        <div key={c.id}>{c.title}</div>
      ))}
    </div>
  );
}
```

---

## ✅ CHECKPOINT

* `/dashboard` shows courses

---

# 🟡 DAY 4 — CREATE COURSE FLOW

## Goal

Add courses from UI.

---

## 4.1 Server action

```ts
"use server";

import { supabase } from "@/lib/supabase";

export async function createCourse(title: string) {
  await supabase.from("courses").insert({ title });
}
```

---

## 4.2 Form UI

```ts
<form action={createCourse}>
  <input name="title" />
  <button>Create</button>
</form>
```

---

## ✅ CHECKPOINT

* form adds course
* refresh shows it

---

# 🟡 DAY 5 — ASSIGNMENTS SYSTEM

## Goal

Introduce LMS structure.

---

## Table

```sql
create table assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid,
  title text
);
```

---

## UI

```text
Course → Assignments list
```

---

## CHECKPOINT

* can create assignment
* can list assignments

---

# 🔵 DAY 6 — EVENT SYSTEM (INNGEST INTRO)

## Goal

Introduce event-driven architecture.

---

## 6.1 Setup Inngest client

```ts
// lib/inngest.ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "nexus-lms" });
```

---

## 6.2 Emit event

```ts
await inngest.send({
  name: "assignment.submitted",
  data: { assignmentId: "123" }
});
```

---

## ✅ CHECKPOINT

* event appears in Inngest dashboard

---

# 🔵 DAY 7 — FIRST AI WORKER (MOCK)

## Goal

Simulate AI worker.

---

## Worker

```ts
export const assignmentWorker = inngest.createFunction(
  { id: "worker" },
  { event: "assignment.submitted" },
  async ({ event }) => {
    console.log("Processing:", event.data);
  }
);
```

---

## CHECKPOINT

* event triggers worker
* logs appear

---

# 🔵 DAY 8 — PLUGIN REGISTRY (SANITY)

## Goal

Introduce dynamic workers.

---

## Worker schema

```ts
{
  name: "worker",
  fields: [
    { name: "name", type: "string" },
    { name: "events", type: "array" },
    { name: "endpoint", type: "url" }
  ]
}
```

---

## Registry query

```ts
const workers = await sanity.fetch(`*[_type=="worker"]`);
```

---

## CHECKPOINT

* workers visible in CMS

---

# 🟣 DAY 9 — FULL AI PIPELINE

## Goal

Fan-out execution.

---

```text
event → multiple workers → results stored
```

---

## Worker call

```ts
await fetch(worker.endpoint, {
  method: "POST",
  body: JSON.stringify(event.data)
});
```

---

## CHECKPOINT

* multiple workers respond

---

# 🟣 DAY 10 — PRODUCTION SYSTEM

## Goal

Final architecture working system.

---

## Includes:

* Supabase RLS
* event logging
* worker results storage
* observability hooks
* full LMS flow

---

## FINAL FLOW

```text
User submits assignment
→ event emitted
→ Inngest triggers workflow
→ registry finds workers
→ AI executes
→ results stored
→ UI updates
```

---

# 🧪 FINAL PROJECT STRUCTURE

```text
nexus-lms/
  app/
  lib/
    supabase/
    inngest/
    registry/
  workers/
  sanity/
  infra/
```

---

# 🧠 FINAL OUTCOME

A beginner who completes this will have built:

* full LMS
* AI worker system
* plugin architecture
* event-driven backend
* production-ready foundation



Just say: **“upgrade to production v2”**
