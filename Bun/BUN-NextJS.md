# ⚡ Full-Stack Bun + Next.js Capstone Blueprint (AI-Native Autonomous Edition)

A **production-grade, multi-layer autonomous work management system** combining:

* ⚙️ **Bun** → High-speed tooling & dependency management
* ⚛️ **Next.js (App Router)** → Server runtime + UI orchestration layer
* 🧠 **Prisma** → Type-safe relational persistence engine
* 🔐 **Auth.js (v5)** → OAuth + session security layer
* 🎨 **Tailwind CSS** → UI system (stateless presentation layer)
* 🗄 **SQLite → Postgres** → Dev-to-prod database portability
* 🤖 **Gemini 1.5 Pro** → Planning + reasoning + replanning engine
* 🤖 **Gemini Flash** → Fast execution agent runtime

---

# 🧠 SYSTEM CONCEPT (CORE MENTAL MODEL)

You are building a **multi-user AI-native execution system** (Linear + Notion AI + Jira + autonomous agents).

### Users provide:

> “Build a SaaS onboarding flow with billing + auth + email verification”

### System produces:

* Epics (strategic decomposition)
* Tasks (atomic execution units)
* Dependency graphs (execution ordering)
* Priority + complexity scoring
* Live adaptive replanning
* Autonomous execution agents

---

## 🧠 Core Principle

> UI is disposable.
> Server is authoritative.
> AI is advisory (planning + adaptation only).
> Agents are executional (but constrained).

---

# 🧱 1. SYSTEM ARCHITECTURE (FULL AUTONOMOUS STACK)

```text
            ┌──────────────────────────────────────┐
            │           UI Layer (Next.js)          │
            │   Stateless Kanban + AI Controls      │
            └────────────────────┬─────────────────┘
                                 │ Server Actions
                                 ▼
            ┌──────────────────────────────────────┐
            │     Business Layer (Auth + Guards)    │
            │   Ownership + Authorization Rules     │
            └────────────────────┬─────────────────┘
                                 │
                                 ▼
            ┌──────────────────────────────────────┐
            │   AI Planning Layer (Gemini Pro)      │
            │   Goal → Epic → Task Graph           │
            └────────────────────┬─────────────────┘
                                 │
            ┌────────────────────┴─────────────────┐
            ▼                                      ▼
┌──────────────────────────┐        ┌──────────────────────────┐
│  Auto-Replanning Engine  │        │ Execution Agent System   │
│ (State-driven adaptation)│        │ (Task workers / agents)  │
└─────────────┬────────────┘        └─────────────┬────────────┘
              │                                   │
              └──────────────┬────────────────────┘
                             ▼
            ┌──────────────────────────────────────┐
            │   Persistence Layer (Prisma ORM)      │
            │   SQLite → Postgres ready             │
            └──────────────────────────────────────┘
```

---

# 🚀 2. PROJECT BOOTSTRAP

```bash
bun create next-app@latest capstone-dash
cd capstone-dash
```

## Recommended setup:

* TypeScript ✔
* ESLint ✔
* Tailwind ✔
* App Router ✔
* src/ directory ✔
* alias @/* ✔

---

## Install Dependencies

```bash
bun add @prisma/client next-auth@beta @auth/prisma-adapter
bun add @google/generative-ai
bun add -d prisma
```

---

# 🗄 3. DATA LAYER (PRISMA DOMAIN MODEL)

## Full Autonomous Schema

```prisma
datasource db {
  provider = "sqlite"
  url      = "file:./dev.db"
}

generator client {
  provider = "prisma-client-js"
}
```

---

## 👤 Identity Layer

```prisma
model User {
  id            String   @id @default(cuid())
  name          String?
  email         String?  @unique
  image         String?

  accounts      Account[]
  sessions      Session[]

  tasks         Task[]
  epics         Epic[]
}
```

---

## 📦 Core Planning Model

```prisma
model Epic {
  id          String   @id @default(cuid())
  title       String
  description String?
  userId      String

  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  tasks       Task[]
  replans     ReplanEvent[]

  user        User @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

---

## 🧩 Task Execution Model (Enhanced)

```prisma
model Task {
  id              String   @id @default(cuid())
  title           String
  description     String?

  status          String   @default("TODO")
  priority        String   @default("MEDIUM")

  complexity      Int      @default(1)

  executionStatus String   @default("IDLE")
  result          String?

  epicId          String?
  userId          String

  blocked         Boolean  @default(false)
  blockedReason   String?

  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  epic Epic? @relation(fields: [epicId], references: [id], onDelete: Cascade)
  user User  @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

---

## 🔁 Replanning History

```prisma
model ReplanEvent {
  id        String   @id @default(cuid())
  reason    String
  context   String

  epicId    String
  createdAt DateTime @default(now())

  epic Epic @relation(fields: [epicId], references: [id], onDelete: Cascade)
}
```

---

# 🔐 4. AUTH LAYER (AUTH.JS v5)

## Config

```ts
import GitHub from "next-auth/providers/github";

export const authConfig = {
  providers: [
    GitHub({
      clientId: process.env.AUTH_GITHUB_ID!,
      clientSecret: process.env.AUTH_GITHUB_SECRET!,
    }),
  ],
  pages: { signIn: "/login" },
};
```

---

## Auth Engine

```ts
import NextAuth from "next-auth";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { PrismaClient } from "@prisma/client";
import { authConfig } from "./auth.config";

const prisma = new PrismaClient();

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  session: { strategy: "jwt" },
  ...authConfig,
});
```

---

## Middleware Guard

```ts
import NextAuth from "next-auth";
import { authConfig } from "./auth.config";

const { auth } = NextAuth(authConfig);

export default auth((req) => {
  const loggedIn = !!req.auth;
  const isLogin = req.nextUrl.pathname.startsWith("/login");

  if (!loggedIn && !isLogin) {
    return Response.redirect(new URL("/login", req.nextUrl));
  }

  if (loggedIn && isLogin) {
    return Response.redirect(new URL("/", req.nextUrl));
  }
});

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
```

---

# ⚙️ 5. SERVER ACTION LAYER (SOURCE OF TRUTH)

```ts
"use server";

import { PrismaClient } from "@prisma/client";
import { auth } from "@/auth";
import { revalidatePath } from "next/cache";

const prisma = new PrismaClient();

async function requireUser() {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");
  return session.user.id;
}
```

---

## Task Operations

```ts
export async function createTask(formData: FormData) {
  const userId = await requireUser();

  const title = formData.get("title");
  if (!title || typeof title !== "string") {
    throw new Error("Invalid task title");
  }

  await prisma.task.create({
    data: {
      title,
      description: String(formData.get("description") || ""),
      priority: String(formData.get("priority") || "MEDIUM"),
      userId,
    },
  });

  revalidatePath("/");
}
```

---

# 🧩 6. UI LAYER (KANBAN RENDER ENGINE)

```text
UI = pure projection of DB state
No business logic in React
No API routes
Server Actions only
```

---

## Kanban Board

(kept intact conceptually)

* TODO
* IN_PROGRESS
* DONE
* BLOCKED

UI remains:

> stateless, server-driven, reactive projection layer

---

# 🤖 7. AI PLANNING ENGINE (GEMINI PRO)

## Structured Decomposition Engine

```ts
import { GoogleGenerativeAI, Type } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

const model = genAI.getGenerativeModel({
  model: "gemini-1.5-pro",
});
```

---

## Schema-Guaranteed Output

```ts
const schema = {
  type: Type.OBJECT,
  properties: {
    epic: {
      type: Type.OBJECT,
      properties: {
        title: { type: Type.STRING },
        description: { type: Type.STRING },
      },
      required: ["title", "description"],
    },
    tasks: {
      type: Type.ARRAY,
      items: {
        type: Type.OBJECT,
        properties: {
          title: { type: Type.STRING },
          description: { type: Type.STRING },
          priority: { type: Type.STRING },
          complexity: { type: Type.INTEGER },
        },
        required: ["title", "description", "priority", "complexity"],
      },
    },
  },
  required: ["epic", "tasks"],
};
```

---

## Goal → Plan Compiler

```ts
export async function decomposeGoal(goal: string) {
  const res = await model.generateContent({
    contents: [{ role: "user", parts: [{ text: goal }] }],
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: schema,
      temperature: 0.1,
    },
  });

  return JSON.parse(res.response.text());
}
```

---

# ⚡ 8. AI BACKLOG DEPLOYMENT

```ts
"use server";

import { prisma } from "@/lib/prisma";
import { auth } from "@/auth";
import { decomposeGoal } from "@/lib/ai/decompose";

export async function deployAIGeneratedBacklog(formData: FormData) {
  const session = await auth();
  const goal = String(formData.get("goal"));

  const plan = await decomposeGoal(goal);

  await prisma.$transaction(async (tx) => {
    const epic = await tx.epic.create({
      data: {
        title: plan.epic.title,
        description: plan.epic.description,
        userId: session!.user!.id,
      },
    });

    await tx.task.createMany({
      data: plan.tasks.map((t: any) => ({
        ...t,
        epicId: epic.id,
        userId: session!.user!.id,
        status: "TODO",
        executionStatus: "PENDING",
      })),
    });
  });

  revalidatePath("/");
}
```

---

# 🔁 9. AUTO-REPLANNING SYSTEM (ADAPTIVE ENGINE)

## SYSTEM BEHAVIOR

> The system continuously adapts when reality deviates from plan.

---

## Architecture Loop

```text
Task State Change
      ↓
Event Trigger (BLOCKED / DELAYED / MODIFIED)
      ↓
Gemini Replanner Evaluation
      ↓
Delta Plan Output
      ↓
Transactional DB Mutation
      ↓
Updated Kanban Projection
```

---

## Replanner Engine

```ts
export async function initiateAutonomousReplan(epicId: string, reason: string) {
  const epic = await prisma.epic.findUnique({
    where: { id: epicId },
    include: { tasks: true },
  });

  const prompt = `
Analyze execution deviation.

Epic: ${epic?.title}
Tasks: ${JSON.stringify(epic?.tasks)}
Reason: ${reason}

Return adjusted task set.
`;

  const result = await model.generateContent(prompt);

  const delta = JSON.parse(result.response.text());

  await prisma.$transaction(async (tx) => {
    await tx.replanEvent.create({
      data: { epicId, reason, context: JSON.stringify(delta) },
    });

    await tx.task.deleteMany({
      where: { epicId, status: { not: "DONE" } },
    });

    await tx.task.createMany({
      data: delta.tasks.map((t: any) => ({
        ...t,
        epicId,
        userId: epic!.userId,
      })),
    });
  });

  return delta;
}
```

---

# 🤖 10. AUTONOMOUS EXECUTION AGENTS

## EXECUTION MODEL

> Tasks are no longer passive. They are executable units.

---

## Agent Execution Loop

```ts
export async function executeAutomatedTaskWorker(taskId: string) {
  const task = await prisma.task.findUnique({ where: { id: taskId } });
  if (!task || task.executionStatus !== "PENDING") return;

  await prisma.task.update({
    where: { id: taskId },
    data: { executionStatus: "RUNNING" },
  });

  const result = await model.generateContent(`
Execute task conceptually:

${task.title}
${task.description}
`);

  await prisma.task.update({
    where: { id: taskId },
    data: {
      executionStatus: "DONE",
      status: "DONE",
      result: result.response.text(),
    },
  });
}
```

---

## Agent Dispatcher

```ts
export async function globalAgentDispatcherDaemon() {
  const tasks = await prisma.task.findMany({
    where: { executionStatus: "PENDING" },
    take: 10,
  });

  await Promise.all(
    tasks.map((t) => executeAutomatedTaskWorker(t.id))
  );
}
```

---

# 🧠 FINAL SYSTEM BEHAVIOR MODEL

## You now have a closed-loop autonomous system:

```text
        USER INTENT
             ↓
      AI PLANNER (Gemini Pro)
             ↓
     STRUCTURED BACKLOG (Prisma)
             ↓
      EXECUTION AGENTS (Flash)
             ↓
     STATE CHANGES IN DB
             ↓
   AUTO-REPLANNER (Gemini Pro)
             ↓
     UPDATED TASK GRAPH
             ↓
           UI RENDER
             ↓
        (Loop continues)
```

---

# 🚀 WHAT THIS SYSTEM ACTUALLY IS

Not a todo app.

Not a Kanban board.

Not a CRUD system.

---

## It is:

> 🧠 **A self-correcting autonomous software execution engine**

capable of:

* planning software projects
* adapting to failure conditions
* executing conceptual tasks
* maintaining dependency graphs
* continuously reorganizing itself
