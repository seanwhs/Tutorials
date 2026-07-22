# GreyMatter LMS: From Zero to Production-Ready Learning Platform

# Part 0 — What We Are Building

## 0.1 Welcome to GreyMatter LMS

Imagine you're opening a school from scratch. Before you hang a sign on the door, you have to answer some unglamorous questions: Where are student records kept? Who's allowed into which classroom? Who updates the whiteboard for tomorrow's lecture? What happens if a hundred students try to hand in the same assignment at the same instant?

**GreyMatter LMS** is the school we're going to build together, one wall at a time. By the end of this series you will have designed, coded, tested, and deployed a real, multi-user **Learning Management System** — a website where instructors publish courses and students take them, similar in spirit to Udemy or a university's online classroom.

This will not be a toy project glued together with shortcuts. We will write the kind of code a professional engineering team would ship: typed database access, validated inputs, real authorization checks, background job processing, and automated tests. But before any code appears, every concept is explained in plain language, using everyday comparisons, so nothing lands on the page unexplained.

### Who this series is for

You should already be comfortable with:

- Basic HTML and CSS
- Basic JavaScript (functions, arrays, objects, `async`/`await`)
- Basic React (components, props, `useState`)

You do **not** need to already know any of the following — each is introduced carefully, exactly when you need it:

- Next.js Server Components, Server Actions, or Route Handlers
- SQL or PostgreSQL
- Drizzle ORM
- Sanity (a "headless CMS" — defined below)
- Inngest or event-driven background job systems
- Webhooks
- Database transactions
- Authorization design
- Automated testing (Vitest, Playwright)

### How to use this series

Each part builds directly on the one before it. You cannot skip Part 5 and expect Part 8 to make sense — the database tables created in Part 5 are used, unmodified, in Part 8. Follow the parts **in order**, and complete the verification steps at the end of each before moving on. It's like assembling flat-pack furniture: skip step 4, and step 9 won't screw in — and you won't know why.

Starting with Part 1, every part follows the same rhythm:

1. **The goal** — what we're building.
2. **Why it exists** — the problem it solves.
3. **The data flow** — how information moves.
4. **The implementation** — full, working, copy-pasteable code.
5. **Code walkthrough** — plain-language explanation of the tricky lines.
6. **Verification** — exact commands/checks to prove it worked.
7. **Common mistakes** — what usually goes wrong, and the fix.
8. **Git checkpoint** — a commit command, so you always have a save point.

Part 0 has no code. Instead, it builds the **mental model** that makes every later decision feel obvious instead of arbitrary.

---

## 0.2 What does an LMS actually need to manage?

Every LMS — GreyMatter included — manages two very different categories of information. Confusing them is the most common design mistake beginners make, so we'll nail the distinction before writing code.

### Category 1: Content — "what everyone sees"

Written once by an instructor; every student sees the identical version:

- Course titles, descriptions, thumbnails
- Chapters and lessons
- Lesson text, images, videos
- Quiz questions and their possible answers
- Instructor bios

Analogy: a **textbook**. A publisher writes it once; every student reads the identical copy. Nobody's personal copy differs based on who they are.

### Category 2: Transactional data — "what's true about *you*, right now"

Different for every user, changes constantly, and must never cross between users:

- Which courses has *this* student enrolled in?
- Which lessons has *this* student finished?
- What score did *this* student get on *this* attempt?
- Has *this* student earned a certificate?

Analogy: your **library card and borrowing history**. The building and its books are the same for everyone; your borrowing record is uniquely yours. Mixing it up with someone else's is a serious problem, not a cosmetic bug.

### Why this drives our architecture

| | Content (textbook) | Transactional data (library card) |
|---|---|---|
| Changes how often? | Rarely | Constantly |
| Same for every user? | Yes | No |
| Needs rich editing tools? | Yes (images, formatted text, video) | No — structured facts |
| Needs strict relational integrity? | Somewhat | Absolutely — grades/certificates depend on it |
| Read-to-write ratio | Read constantly, written rarely | Read and written constantly |

Because the needs are nearly opposite, GreyMatter uses **two databases**:

- **Sanity** (a headless CMS — a content system with no public website of its own, just an API and an authoring tool) stores the textbook: courses, chapters, lessons, quiz *definitions*, instructor bios.
- **Neon** (managed PostgreSQL — a mature relational database engine) stores the library card: users, enrollments, lesson progress, quiz *attempts*, certificates.

This is the single most important architectural decision in the series. Whenever you're unsure later — "does this belong in Sanity or Neon?" — return to the test: *same for everyone and rarely edited → Sanity; unique per user and frequently changing → Neon.*

---

## 0.3 Synchronous requests versus background workflows

A second distinction governs how our *code* is organized, not just our data.

Picture a bank teller accepting a check deposit. Two things happen:

1. **Right now, while you wait:** the teller confirms the deposit and hands you a receipt. Must be fast.
2. **Sometime after you leave:** the check clears, funds move between banks, statements get generated. None of this should make you stand at the counter.

This is exactly an LMS's shape:

- **Synchronous, must-happen-now:** "Save that this student answered this quiz question." Must happen inside the HTTP request — the student is watching the screen.
- **Background, can-happen-a-moment-later:** "Recalculate overall course completion. Check certificate eligibility. Email the student. Update instructor analytics." None of this needs to block the current screen.

The fast synchronous part is handled by **Next.js Server Actions** and **Route Handlers** talking directly to Neon. The background part is handled by **Inngest**, a tool built for durable background jobs — jobs that reliably retry on failure instead of silently vanishing.

```text
Student clicks "Submit Quiz Answer"
        │
        ▼
Next.js Server Action (must respond quickly)
        │
        ├── Save the answer + score to Neon        ◄── synchronous, blocking
        │
        └── Emit a "lesson/completed" event          ◄── fire-and-forget
                │
                ▼
        Inngest picks up the event moments later
                │
                ├── Recalculate whole-course progress %
                ├── Check certificate eligibility
                ├── Send a notification email
                └── Update instructor-facing analytics
```

We build the synchronous half in Parts 8 and 11, and the background half starting in Part 12.

---

## 0.4 Trust boundaries: why the server can never trust the browser

A scenario that trips up nearly every beginner building their first quiz feature:

A student takes a 10-question quiz. JavaScript *in the browser* checks the answers, computes "9 out of 10," and sends `{ score: 9 }` to the server, which saves it as-is.

**This is a serious security flaw.** Anyone can open developer tools, intercept the request, and change the body to `{ score: 10 }` before sending — no programming skill required beyond "Edit and Resend." The server simply believed whatever number arrived.

It's like a driving examiner handing the *student* the scorecard and asking them to fill in their own result and mail it back.

The fix, repeated throughout this series:

> **The server is the only party allowed to decide what is true. The browser only makes requests; it never supplies the answer.**

Concretely:

- The browser sends *which answer the student picked* (e.g., `"b"`).
- The server — never the browser — looks up the correct answer from Sanity and computes the score itself.
- The server verifies the student is actually enrolled in the course before accepting anything.
- Only the server-computed result is saved to Neon and returned to the student.

We implement this rigorously in Part 11. For now: **the browser proposes, the server disposes.**

---

## 0.5 A quick tour of the tools, in plain language

- **Next.js** — the framework running our whole website: both the pages a browser renders and the server-side logic that talks to our databases, in one project. Like a building housing both classrooms (what students see) and a staff-only back office (server logic).
- **React** — the library Next.js uses to build the UI out of reusable components, like building a wall from standardized bricks instead of hand-carving each one.
- **Tailwind CSS** — a styling toolkit describing appearance directly in markup (`className="rounded-lg bg-blue-600 p-4"`) instead of separate stylesheets. A box of pre-cut materials instead of a lumber yard.
- **Sanity** — our headless CMS (the textbook system). "Headless" means it has no public website of its own — just a content database and an editor screen called **Sanity Studio**. Our own Next.js pages fetch content from it via an API.
- **Neon** — our managed PostgreSQL database (the library-card system). PostgreSQL is a relational database: data is stored in strict, related tables (e.g., an `enrollments` table pointing at a `users` table), which prevents data from becoming inconsistent or contradictory.
- **Drizzle ORM** — a tool that lets us write database queries as typed TypeScript function calls instead of raw SQL strings, so mistakes get caught while typing instead of at 2 a.m. in production. An ORM ("Object-Relational Mapper") is a translator between "table rows" and "JavaScript objects."
- **Clerk** — a hosted authentication service. Rather than building our own password storage, reset-email flows, and session cookies (all extremely easy to get wrong from a security standpoint), we outsource that responsibility to a specialist, the way a small business outsources payroll instead of building its own payroll department.
- **Inngest** — our background workflow engine, the "back office" that clears the check after the teller hands you a receipt.
- **Zod** — a validation library. It checks that data arriving from the browser (or a webhook) actually has the shape we expect *before* we trust it — like a bouncer checking ID at the door before letting anyone in.
- **Vitest / Playwright** — our testing tools. Vitest tests small pieces of logic in isolation (unit tests); Playwright drives an actual browser to click through the whole app like a real user (end-to-end tests).

---

## 0.6 The three roles GreyMatter serves

| Role | Can do |
|---|---|
| **Student** | Browse courses, enroll, read lessons, complete interactive modules, submit quizzes, track progress, earn certificates. |
| **Instructor** | Preview authored content, view enrolled students, inspect completion/assessment data, view analytics, trigger reminders. |
| **Administrator** | Manage roles, control course availability, review all enrollments/workflows, view platform-wide analytics. |

A fourth "role," the **Content Editor**, doesn't log into our Next.js app at all — they work entirely inside Sanity Studio, authoring courses, chapters, lessons, and quizzes. This matters architecturally: content authoring and application usage are two completely separate surfaces that happen to be connected by an API, not two features bolted onto the same login system. Keeping that boundary clean is exactly why Sanity exists as a separate system in the first place, rather than an "admin panel" bolted onto our own database.

---

## 0.7 The final architecture, end to end

Here is the complete system you will have built by the final part of this series. Don't worry about understanding every arrow yet — treat this as a map you'll recognize pieces of as we go, and can flip back to whenever you feel lost.

```text
                              ┌─────────────────────────┐
                              │        Browser           │
                              │  (Student / Instructor /  │
                              │   Admin — React UI)       │
                              └────────────┬─────────────┘
                                           │  HTTPS
                                           ▼
                        ┌──────────────────────────────────────┐
                        │            Next.js 16 App              │
                        │  ┌───────────────┐  ┌────────────────┐ │
                        │  │ Server         │  │ Route Handlers │ │
                        │  │ Components /   │  │ (webhooks,     │ │
                        │  │ Server Actions │  │  Inngest API)  │ │
                        │  └───────┬───────┘  └───────┬────────┘ │
                        └──────────┼───────────────────┼─────────┘
                                   │                    │
                     ┌─────────────┴───────┐    ┌───────┴─────────┐
                     ▼                     ▼    ▼                 ▼
           ┌──────────────────┐  ┌──────────────────┐   ┌──────────────────┐
           │   Sanity Content  │  │  Neon PostgreSQL  │   │      Clerk        │
           │  (Courses,        │  │  (Users, Roles,   │   │ (Auth, sessions,  │
           │   Chapters,       │  │   Enrollments,    │   │  webhooks on      │
           │   Lessons,        │  │   Progress,       │   │  user create/     │
           │   Quizzes,        │  │   Attempts,       │   │  update/delete)   │
           │   Portable Text)  │  │   Certificates)    │   │                  │
           └──────────────────┘  └────────┬───────────┘   └──────────────────┘
                                          │
                                          │  emits events
                                          ▼
                              ┌──────────────────────────┐
                              │         Inngest            │
                              │  (durable background jobs) │
                              │                             │
                              │  • Onboard new users        │
                              │  • Confirm enrollment        │
                              │  • Recalculate progress      │
                              │  • Detect course completion   │
                              │  • Generate certificates       │
                              │  • Send emails / reminders      │
                              │  • Build analytics summaries     │
                              └──────────────────────────────────┘
```

Notice the shape of it: **Next.js sits in the middle**, talking to three specialist services, each responsible for exactly one job — Sanity for content, Neon for transactional truth, Clerk for identity, and Inngest for anything that can happen "a moment later." This is a very common, very production-realistic pattern called **separation of concerns** — nobody in this diagram is asked to do a job outside their specialty, the same way a hospital doesn't ask the radiologist to also run the pharmacy.

---

## 0.8 The final project folder structure

You don't need to create any of this yet — Part 1 will build it piece by piece — but seeing the destination up front helps every future decision make sense.

```text
greymatter-lms/
├── app/                        # Next.js App Router: pages, layouts, route handlers
│   ├── (marketing)/             # Public landing pages
│   ├── (auth)/                  # Sign-in / sign-up routes
│   ├── courses/                 # Public course catalog & detail pages
│   ├── dashboard/                # Authenticated student area
│   ├── instructor/                # Authenticated instructor area
│   ├── admin/                      # Authenticated admin area
│   ├── studio/                      # Embedded Sanity Studio
│   └── api/                          # Route handlers (webhooks, Inngest endpoint)
├── components/
│   ├── ui/                       # Design-system primitives (button, card, input...)
│   └── ...                        # Feature-specific components
├── db/
│   ├── schema/                    # Drizzle table definitions
│   ├── migrations/                 # Generated SQL migrations
│   └── client.ts                    # Neon connection setup
├── inngest/
│   ├── client.ts                    # Inngest client instance
│   └── functions/                    # Individual background workflow definitions
├── lib/
│   ├── auth/                         # Session + role helper functions
│   └── validation/                    # Zod schemas
├── sanity/
│   ├── schema-types/                  # Sanity document/block schema definitions
│   └── lib/                            # Sanity client + GROQ query helpers
├── public/                              # Static assets
├── tests/
│   ├── unit/                             # Vitest unit tests
│   └── e2e/                               # Playwright end-to-end tests
├── .env.example
└── package.json
```

Every top-level folder maps directly to one of the concepts we just discussed: `sanity/` is the textbook system, `db/` is the library-card system, `inngest/` is the back office, `app/` is the building that houses all of it, and `lib/auth/` is the security desk checking IDs at every door.

---

## 0.9 Series conventions

A few ground rules that will hold for the rest of the series, so nothing feels inconsistent later:

- **Package manager:** we'll use `npm` in all terminal commands. If you prefer `pnpm` or `yarn`, the commands translate directly — just swap the executable name.
- **Language:** everything is written in **TypeScript**, not plain JavaScript. TypeScript adds type checking on top of JavaScript — it's the difference between a form that lets you scribble anything in any box, versus one that refuses to accept letters in a box labeled "phone number" before you even submit it. This matters enormously in an app juggling three external systems with three different data shapes.
- **File paths:** every code block is labeled with its exact relative path from the project root, as a heading directly above the block, e.g. `db/schema/users.ts`. When we say "open this file," we mean relative to your `greymatter-lms/` project folder.
- **Environment variables:** any secret (API keys, database URLs) will always be introduced through an environment variable and documented in `.env.example`, never hard-coded — this is a security practice, not a stylistic preference.
- **Git checkpoints:** at the end of every part, you'll run a `git commit` with a specific message we provide. If something breaks two parts later, you can always check out an earlier checkpoint and diff against it.
- **"Beginner box" callouts:** whenever a term is used for the first time, it will be defined in-line, in parentheses, the moment it appears — the same way we've done throughout this very part.

---

## 0.10 Reader deliverables checklist

By the end of the full series, you will have personally built and can check off:

- [ ] A running Next.js 16 + React 19 + Tailwind CSS application
- [ ] A reusable, accessible design-system component library
- [ ] A Sanity Studio content model for courses, chapters, lessons, and quizzes
- [ ] Public, SEO-friendly course catalog and detail pages
- [ ] A Neon PostgreSQL database with versioned Drizzle migrations
- [ ] Clerk authentication with an internal user record synchronized via webhooks
- [ ] Role-based authorization (Student / Instructor / Admin) enforced on both routes *and* individual server operations
- [ ] A secure course-enrollment flow with duplicate-enrollment protection
- [ ] A full lesson player rendering Portable Text, images, video, and code
- [ ] An extensible interactive-module plugin system (quizzes, exercises, checkpoints)
- [ ] Server-authoritative grading — the browser never determines its own score
- [ ] Inngest-powered background workflows for onboarding, progress, and completion
- [ ] Automatic course-completion detection and downloadable certificates
- [ ] Scheduled learner-reminder and notification workflows
- [ ] An instructor analytics dashboard
- [ ] Unit tests (Vitest) and end-to-end tests (Playwright)
- [ ] A deployed, production-configured application (Vercel + Neon + Sanity + Clerk + Inngest, all wired together)

---

## 0.11 The development roadmap

This is the order we will build in, and — importantly — *why* this order and no other:

```text
Project foundation           (Part 1–2)   → You need a place to put code before you put code in it.
    → Content modeling        (Part 3–4)   → You need something to teach before students can enroll.
    → Database modeling        (Part 5)     → You need a place to record who's enrolled before enrollment exists.
    → Authentication            (Part 6)     → You need to know who the user is before you track their progress.
    → Enrollment                 (Part 7–8)   → You need a relationship between user and course before lessons matter.
    → Lesson delivery              (Part 9)     → You need to actually deliver content before it can be interactive.
    → Interactive modules           (Part 10)    → You need a plugin system before you can grade anything server-side.
    → Secure progress tracking       (Part 11)    → You need graded attempts before background jobs have anything to react to.
    → Inngest automation              (Part 12)    → You need events before you can build workflows that consume them.
    → Certificates & reminders         (Part 13–14) → You need completion detection before certificates make sense.
    → Instructor analytics               (Part 15)    → You need real data flowing before analytics has anything to show.
    → Testing & deployment                 (Part 16)    → You need a finished app before you can test and ship it.
```

Notice this isn't an arbitrary checklist — each stage is a **hard prerequisite** for the one after it. This is why the series must be followed in order: Part 11's "server-authoritative grading" is meaningless without Part 10's plugin contract, which is meaningless without Part 9's lesson player, which is meaningless without Part 4's Sanity queries. Every part is a load-bearing wall for the ones that follow.

---

## 0.12 The key lesson of Part 0

If you remember exactly one thing from this introduction before diving into real code, make it this:

> **Content lives in Sanity. Per-user truth lives in Neon. Anything that can wait a moment lives in Inngest. And the browser never gets to grade its own homework.**

Every architectural decision for the rest of this series is a direct consequence of that one sentence. When a part later asks you to put something in one system rather than another, you'll now understand *why*, instead of memorizing it as an arbitrary rule.

---

## What's next

Part 1 moves from theory into practice: we'll install our tools, scaffold the actual Next.js 16 project, wire up TypeScript and Tailwind CSS, set up environment variables and Git, and finish with a running application and a passing build — the literal first brick in GreyMatter LMS's foundation.
