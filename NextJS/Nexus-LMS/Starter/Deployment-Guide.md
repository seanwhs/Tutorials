# 🚀 NEXUS LMS — FULL DEPLOYMENT GUIDE (PRODUCTION READY)

This guide takes your repo from:

> “codebase” → “live AI-native LMS on the internet”

It covers **every platform, in the correct order**, with no missing steps.

---

# 🧠 0. DEPLOYMENT OVERVIEW

You will deploy 4 core systems:

```text id="d0_stack"
1. Supabase → Database + Auth backend
2. Sanity → Plugin registry (AI workers)
3. Inngest → Event orchestration layer
4. Vercel → Next.js frontend + API
```

---

# 🗄 1. SUPABASE SETUP (DATABASE FIRST)

Supabase

---

## 1.1 Create project

Go to:

[https://supabase.com](https://supabase.com) → New Project

* Name: `nexus-lms`
* Database password: generate strong one
* Region: closest to users (e.g. Asia Pacific)

---

## 1.2 Create tables

Run SQL:

```sql id="d1_schema"
create table submissions (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  assignment_id text not null,
  content text,
  created_at timestamp default now()
);
```

---

## 1.3 Enable Row Level Security (IMPORTANT)

```sql id="d1_rls"
alter table submissions enable row level security;
```

---

## 1.4 Create policy

```sql id="d1_policy"
create policy "tenant access"
on submissions
for select
using (auth.uid()::text = user_id);
```

---

## 1.5 Get credentials

Copy:

* SUPABASE_URL
* SUPABASE_ANON_KEY
* SUPABASE_SERVICE_ROLE_KEY (keep secret)

---

# 🧩 2. SANITY SETUP (PLUGIN REGISTRY)

Sanity

---

## 2.1 Create project

[https://sanity.io](https://sanity.io)

```text id="d2_sanity"
Project: nexus-lms-registry
Dataset: production
```

---

## 2.2 Install Sanity CLI

```bash id="d2_cli"
npm install -g sanity
sanity init
```

---

## 2.3 Add worker schema

```ts id="d2_schema"
export default {
  name: "worker",
  type: "document",
  fields: [
    { name: "name", type: "string" },
    { name: "event", type: "string" },
    { name: "endpoint", type: "url" },
    { name: "enabled", type: "boolean" },
    { name: "priority", type: "number" }
  ]
};
```

---

## 2.4 Create sample worker

```json id="d2_worker"
{
  "name": "AI Grader",
  "event": "assignment.submitted",
  "endpoint": "https://your-api.com/api/grade",
  "enabled": true,
  "priority": 1
}
```

---

# ⚡ 3. INNGEST SETUP (EVENT SYSTEM)

Inngest

---

## 3.1 Install SDK

```bash id="d3_install"
npm install inngest
```

---

## 3.2 Create client

```ts id="d3_client"
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "nexus-lms" });
```

---

## 3.3 Create API route

```ts id="d3_api"
// app/api/inngest/route.ts

import { serve } from "inngest/next";
import { functions } from "@/packages/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions,
});
```

---

## 3.4 Create test function

```ts id="d3_fn"
export const assignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted" },
  { event: "assignment.submitted" },
  async ({ event }) => {
    console.log("event received:", event.data);
    return { ok: true };
  }
);
```

---

# 🌐 4. VERCEL DEPLOYMENT (FRONTEND)

Vercel

---

## 4.1 Push repo to GitHub

```bash id="d4_git"
git init
git add .
git commit -m "nexus lms deploy"
git branch -M main
git remote add origin https://github.com/you/nexus-lms.git
git push -u origin main
```

---

## 4.2 Import to Vercel

* Go to [https://vercel.com/new](https://vercel.com/new)
* Import repo
* Framework: Next.js
* Click Deploy

---

## 4.3 Add environment variables

In Vercel dashboard:

```env id="d4_env"
SUPABASE_URL=
SUPABASE_ANON_KEY=

CLERK_SECRET_KEY=

INNGEST_EVENT_KEY=

SANITY_PROJECT_ID=
SANITY_DATASET=

OPENAI_KEY=
```

---

## 4.4 Add production domains

Update:

* Supabase auth redirect URLs
* Clerk allowed domains
* Inngest endpoint URL

---

# 🔐 5. CLERK AUTH SETUP

Clerk

---

## Steps:

* create project
* enable email/password or OAuth
* copy keys into Vercel
* set redirect URLs

---

# 🔁 6. FULL SYSTEM ACTIVATION CHECK

---

## 6.1 Test frontend

✔ dashboard loads
✔ login works
✔ routes protected

---

## 6.2 Test event flow

Trigger:

```text id="d6_test"
submit assignment
```

Expected:

```text id="d6_flow"
Next.js → Inngest → worker → Supabase
```

---

## 6.3 Test plugin system

✔ Sanity returns worker
✔ worker executes
✔ output stored

---

## 6.4 Test AI layer

✔ structured JSON output
✔ no invalid responses
✔ schema validation passes

---

# 🧠 7. FINAL PRODUCTION ARCHITECTURE

```text id="d7_arch"
User
 ↓
Next.js (Vercel)
 ↓
Inngest (Events)
 ↓
Sanity (Plugin Registry)
 ↓
AI Workers (OpenAI / Claude)
 ↓
Supabase (Database)
 ↓
UI Updates
```

---

# 🧠 8. COMMON DEPLOYMENT ISSUES

---

## ❌ Inngest not firing

Fix:

* check `/api/inngest` route
* verify event name match

---

## ❌ Supabase auth failing

Fix:

* add correct redirect URLs
* enable RLS policies

---

## ❌ Workers not executing

Fix:

* check Sanity registry query
* ensure `enabled = true`

---

## ❌ AI returning invalid JSON

Fix:

* enforce structured prompts
* add schema validation layer

---

# 🧠 FINAL INSIGHT

> Deployment is not the final step — it is the moment your architecture becomes real.

Once deployed, Nexus LMS becomes:

* a distributed system
* an AI orchestration engine
* a plugin-based execution platform


* 🧠 real production monitoring system (logging + tracing dashboard)
* 🚀 “Nexus LMS v2 architecture upgrade (AI agent swarm system)”
