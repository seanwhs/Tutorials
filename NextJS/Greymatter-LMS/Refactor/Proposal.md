# Architectural Proposal: Refactoring the Greymatter LMS Core Architecture

---

## 1. Executive Summary

The initial iteration of the Greymatter LMS architecture delegated runtime assessment pipelines—specifically quiz generation and grading—to external LLM microservices. While this structure initially demonstrated architectural flexibility, production scaling introduces serious operational bottlenecks:

* **High Operational Expenditure:** Real-time token consumption patterns for repetitive, predictable evaluation loops create high structural costs.


* **Latency Profiles:** Relying on external third-party API availability numbers creates unacceptable user interface blocking conditions during critical synchronous operations.
* **Non-Deterministic Grading Boundaries:** Standard LLM text parsing introduces non-zero error rates, response formatting failures, and structural hallucination vulnerabilities during multi-choice and direct evaluation tasks.



This proposal formalizes a thorough structural refactor designed to decouple core multi-tenant learning management state from the AI execution engine layer. By implementing a dedicated, deterministic **Quizzes & Exams Module** within the edge/server infrastructure layer (Next.js), re-centering **Sanity CMS** as a read-only structured content vault, and designating **Neon Postgres** as the single source of truth for runtime metrics, the system eliminates unnecessary operational expenditures while scaling non-blocking event chains via the **Inngest Workflow Engine**.

---

## 2. Structural Component Realignment

To establish absolute separation of concerns, eliminate data orchestration redundancy, and isolate failure domains, the architectural components are mapped into specific operational boundaries:

```text
       [ Next.js Front-End Shell (apps/web) ]
                    │                  │
 1. Fetch JSON      │                  │ 3. Submit Answers
    Course/Quiz Data│                  │    (Zero-Token Post Request)
                    ▼                  ▼
      ┌────────────────────────┐  ┌────────────────────────────────────┐
      │       SANITY CMS       │  │    DEDICATED QUIZ/EXAM MODULE      │
      ├────────────────────────┤  │     (Next.js App / Server Layer)   │
      │ • Structural Courses   │  ├────────────────────────────────────┤
      │ • Lesson Markdown      │  │ • Pulls correct keys from Sanity  │
      │ • Pre-authored Questions│ │ • Evaluates checks locally in JS   │
      │ • Right/Wrong Keys     │  │ • Computes final exact integer score│
      └────────────────────────┘  └────────────────────────────────────┘
                                                   │
                                                   │ 4. Persist Results & 
                                                   │    State Write
                                                   ▼
                                  ┌────────────────────────────────────┐
                                  │       NEON POSTGRES DATABASE       │
                                  ├────────────────────────────────────┤
                                  │ • Student Enrollments              │
                                  │ • Raw Submissions JSON             │
                                  │ • Calculated Math Scores           │
                                  └────────────────────────────────────┘
                                                   │
                                                   │ 5. Trigger Non-Blocking
                                                   │    Post-Quiz Hooks
                                                   ▼
                                  ┌────────────────────────────────────┐
                                  │      INNGEST WORKFLOW ENGINE       │
                                  ├────────────────────────────────────┤
                                  │ • Asynchronous Student Metrics     │
                                  │ • Conditional Remediation Triggers │
                                  │ • Certification / Passing Hooks    │
                                  └────────────────────────────────────┘

```

### A. Content Domain: Sanity CMS

Sanity moves away from dynamic worker registry metadata configurations to focus exclusively on highly optimized, structured content delivery.

* **Core Responsibilities:** Storing multi-tenant course graph structural models, markdown document components, localized quiz item schemas, and corresponding evaluation keys.
* **Security Control Assertions:** Correct answer key fields are restricted via schema-level rules. These target parameters are filtered out of public GraphQL/GROQ execution vectors and remain readable solely by authenticated server routes executing within secure environments.

### B. Execution Domain: Dedicated Quiz & Exams Module

A localized execution engine integrated completely within the Next.js server runtime shell.

* **Core Responsibilities:** Ingesting structured user input answer payloads from client-side network pipelines, querying secure master key data targets out of Sanity, validating equality checks via standard JavaScript processing engines, and computing deterministic integer values.
* **Financial Impact Analysis:** Drops runtime API token evaluation dependency costs down to absolute zero ($0.00) for all predictable, objective assessments.

### C. State & Relational Domain: Neon Postgres (via Prisma ORM)

Neon serves as the central state hub for multi-tenant isolation boundaries, persistent operational storage, and data relationship constraints.

* **Core Responsibilities:** Validating student enrollment limits, logging raw user evaluation answers inside JSON data blocks, and maintaining indexed columns for precise integer scoring outputs.



### D. Asynchronous Events Domain: Inngest Workflow Engine

Inngest is decoupled from blocking frontend web server response cycles and high-latency third-party system dependencies.

* **Core Responsibilities:** Processing event routing metrics asynchronously. Once a quiz score is written to Postgres, Inngest triggers non-blocking downstream actions, including automated certification builds, overall user analytics calculations, and targeted system remediation notification alerts.



---

## 3. Implementation Details & Data Schema

To ensure type safety and explicit structural data integrity across all environments, the relational schema transitions to Prisma ORM. The data models within `infra/db/schema.prisma` are optimized for fast multi-tenant query patterns:

```prisma
// infra/db/schema.prisma

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

/// @section Core Learning Management System Records
model QuizSubmission {
  id              String   @id @default(uuid()) @db.Uuid
  orgId           String   @map("org_id")           // Strict multi-tenant operational boundary tracking
  studentId       String   @map("student_id")       // Reference to verified authentication account (e.g., Clerk ID)
  quizId          String   @map("quiz_id")          // Corresponds directly to the origin Sanity document ID
  selectedAnswers Json     @map("selected_answers") // Exact structural map of user choices: e.g., { "q1": "B", "q2": "A" }
  finalScore      Int      @map("final_score")      // Evaluated instantly via local backend JavaScript engine
  createdAt       DateTime @default(now()) @map("created_at")

  @@index([orgId])
  @@index([studentId])
  @@index([quizId])
  @@map("quiz_submissions")
}

```

### Server Execution Orchestration Blueprint

Below is the programmatic implementation for the Next.js execution block, providing deterministic server grading and asynchronous event generation:

```typescript
// apps/web/actions/quiz-actions.ts
import { PrismaClient } from "@prisma/client";
import { inngest } from "@/infra/inngest/client";
import { fetchSanityMasterKeys } from "@/infra/sanity/client";

const prisma = new PrismaClient();

interface SubmissionPayload {
  orgId: string;
  studentId: string;
  quizId: string;
  answers: Record<string, string>; // e.g., { "q_01": "B", "q_02": "D" }
}

export async function processQuizSubmission(payload: SubmissionPayload) {
  try {
    // 1. Fetch secure, server-side grading criteria from Sanity CMS vault
    const masterKeys = await fetchSanityMasterKeys(payload.quizId);
    
    // 2. Compute exact scores locally - consuming zero external AI tokens
    let correctCount = 0;
    const totalQuestions = Object.keys(masterKeys).length;

    for (const [questionId, correctAnswer] of Object.entries(masterKeys)) {
      if (payload.answers[questionId] === correctAnswer) {
        correctCount++;
      }
    }

    const calculatedScore = Math.round((correctCount / totalQuestions) * 100);

    // 3. Persist exact operational metrics directly to Neon Postgres via Prisma Client
    const record = await prisma.quizSubmission.create({
      data: {
        orgId: payload.orgId,
        studentId: payload.studentId,
        quizId: payload.quizId,
        selectedAnswers: payload.answers,
        finalScore: calculatedScore,
      },
    });

    // 4. Asynchronously hand off secondary side effects to the Inngest architecture
    await inngest.send({
      name: "lms/quiz.submitted",
      payload: {
        submissionId: record.id,
        orgId: record.orgId,
        studentId: record.studentId,
        quizId: record.quizId,
        finalScore: record.finalScore,
      },
    });

    return {
      success: true,
      submissionId: record.id,
      score: record.finalScore,
    };
  } catch (error) {
    console.error("Critical failure executing deterministic quiz sequence:", error);
    throw new Error("Internal Assessment Evaluation Failure");
  }
}

```

---

## 4. Business & Technical Benefits

### Absolute Operational Determinism

Grading tasks move from non-deterministic LLM analysis arrays down to simple, compile-time variable evaluation layers. This completely isolates the core grading mechanism from typical production text processing failure conditions:

* **Hallucination Protection:** Eliminates instances where dynamic models misinterpret structural rules or apply incorrect grading rubric conditions.


* **Format Predictability:** Bypasses reliance on strict prompt engineering techniques to ensure output JSON shapes match expectations.



### Elimination of UI Blocking Conditions

Because the evaluation loop is calculated directly within native memory spaces on server components, client browsers experience zero processing wait times. The system eliminates asynchronous polling loops, network failure timeouts, and microservice messaging bottlenecks during critical exam grading cycles.

### Strategic AI Allocation & Token Cost Management

By offloading all predictable, rule-based operations down to standard code systems, production operational expenses drop immediately. This enables strategic reallocation of computational budgets:

| Assessment Form | Primary Compute Tool | Financial Token Cost |
| --- | --- | --- |
| **Multiple Choice Questions** | JavaScript Engine | **$0.00** |
| **Exact Formula Matching** | JavaScript Engine | **$0.00** |
| **Structured Core Exam Keys** | JavaScript Engine | **$0.00** |
| **Open-Ended Conceptual Synthesis Review** | Specialized AI Worker | Metered Usage |
| **Proactive Student Mentorship Loops** | Specialized AI Worker | Metered Usage

 |

This architectural adjustment balances fast response times with clean separation of concerns, ensuring Greymatter LMS scales efficiently across multi-tenant production bounds.
