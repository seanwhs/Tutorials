# Part 0: Introduction — Welcome to GreyMatter Mindfulness Log

## 0.1 What are we actually building?

Imagine a small notebook that only you can read. Every night, you jot down how you're feeling on a scale of 1–10, maybe scribble a paragraph about your day, and occasionally note "took my medication at 9pm." Now imagine that notebook is smart enough to remind you to write in it, lets you look back over months of entries in a graph, and — critically — is built by a company that has to treat every single page of it as if it were radioactive, because in the eyes of the law, it kind of is.

That's **GreyMatter Mindfulness Log**: a mood-tracking and journaling web application. Functionally, it will let a signed-in user:

- Log a **daily mood score** (e.g., 1–10) with an optional short note.
- Write longer **free-text journal entries**.
- Set **medication reminders** (e.g., "Sertraline, 9:00 AM daily").
- Manage **consent preferences** — explicit, granular opt-ins for things like "allow anonymized data to be used for research" or "send me email reminders."
- Request a full **export of their data** (a machine-readable copy of everything the app knows about them).
- Request **full account deletion** ("the right to be forgotten"), including all downstream copies of their data.

On the surface, this sounds like a CRUD app with a calendar widget — the kind of thing you could scaffold in an afternoon. And technically, you could. But we're not going to build it that way, because of one crucial detail: **this data is about mental health.**

### Why that one detail changes everything

Under data protection law — most famously the EU's General Data Protection Regulation (GDPR), but mirrored in similar laws worldwide (HIPAA in the US healthcare context, CCPA/CPRA in California, PIPEDA in Canada) — personal data about health, including mental health, is classified as a **"special category" of data** (sometimes called "sensitive personal data"). Think of it like the difference between someone knowing your favorite pizza topping versus someone knowing your psychiatric diagnosis. Both are "facts about you," but leaking one embarrasses you at a dinner party, and leaking the other can cost someone their job, their custody battle, their insurance premium, or their safety.

Because of this, special category data comes with **extra legal obligations**:

- You generally need **explicit, specific consent** to collect it (not just a buried checkbox).
- You must practice **data minimization** — only collect what you strictly need, nothing "just in case."
- You must be able to prove, on demand, **what you collected, why, and under what legal basis**.
- You must let users **export** and **permanently delete** their data on request, within a defined time window.
- You must protect it with **appropriate technical measures** — encryption, access control, audit trails — not just "we have a password field."

Most tutorials treat privacy and security as garnish — something you sprinkle on at the end, if there's time ("oh, and remember to hash passwords"). **This series treats privacy as the main course.** We picked mental health data specifically *because* it's the hard case — if you learn to handle this correctly, you'll have a mental toolkit that transfers to any app dealing with sensitive data: fintech, HR systems, legal tech, dating apps, anything with a "Delete My Account" button that actually needs to mean it.

## 0.2 Who this series is for

This series is written for developers who are comfortable with:

- Basic JavaScript/TypeScript.
- The general shape of a web app (frontend, backend, database) — you don't need to have built one with this exact stack before.
- Using a terminal to run commands like `npm install`.

You do **not** need to already know:

- Next.js 16 specifically (we'll explain the App Router, Server Components, Server Actions, and Route Handlers as we go, the first time each concept appears).
- Clerk, Tailwind, or Inngest (each gets a proper introduction with an analogy before we write a line of code using it).
- Anything about GDPR, DPIAs, or compliance (we'll define every acronym in plain English the first time it shows up — starting right now: **DPIA** stands for **Data Protection Impact Assessment**, which is essentially a formal, written-down risk assessment you do *before* building a feature that touches sensitive data, so you catch problems on paper instead of in production).

Every technical term gets defined inline, in plain language, the moment it's introduced — think of this series as "beginner-friendly on the outside, production-grade on the inside." The prose will use everyday analogies to build your intuition; the code will be complete, secure, and copy-pasteable, with no `// TODO: implement this later` placeholders. If a code block appears in this series, it is meant to run.

## 0.3 The tech stack, and why each piece was chosen

| Tool | What it is (analogy) | Why we're using it here |
|---|---|---|
| **Next.js 16** | A full "kitchen" for a restaurant — it handles both the dining room (what the customer/browser sees) and the kitchen (server-side logic), in one unified project. | Lets us write React for the UI and server-side logic (API routes, Server Actions) in a single codebase, with sensible defaults for routing, rendering, and performance. |
| **Tailwind CSS** | A box of pre-labeled LEGO bricks for styling — instead of naming and writing custom CSS classes from scratch, you snap together small utility classes (`p-4`, `text-sm`, `bg-slate-900`) directly in your markup. | Fast, consistent styling without context-switching between files; especially good for a tutorial because styles are visible right next to the markup they affect. |
| **Clerk** | A professional bouncer and ID-checking service for your app's front door, so you don't have to build your own lock-picking-proof door from scratch. | Authentication (proving who a user is) is security-critical and easy to get subtly wrong. Clerk handles sign-up, sign-in, sessions, and multi-factor auth for us, correctly, out of the box. |
| **Postgres** | A very strict, very reliable filing cabinet, with rules about what kind of paper can go in which drawer. | We need a relational database with strong support for constraints (rules that prevent bad data from ever being saved) and, later, encryption-friendly column types. |
| **Inngest** | A team of tireless, reliable background workers who pick up a task (like "export this user's data" or "react to this consent change") and see it through — even retrying automatically if something fails partway. | DSAR (Data Subject Access Request) processing and consent-reaction workflows are multi-step, must-not-fail processes. Inngest gives us durable, retryable, observable background jobs without us hand-rolling a queue. |

We'll meet each of these tools properly, one at a time, exactly when we need them — not all at once. In Part 1 (Foundations), for instance, we'll only need Next.js and Clerk. Postgres arrives in Part 3. Inngest doesn't show up until Part 5. This mirrors how you'd actually build a real system: infrastructure arrives when a real requirement demands it, not upfront "just in case."

## 0.4 The architecture we're building toward

Below is the *finished-state* architecture of GreyMatter Mindfulness Log. Don't worry about understanding every box right now — this is a map we're pinning to the wall at the start of a road trip. We'll revisit it at the start of every subsequent Part, highlighting the piece we're about to build, so you always know where "you are" relative to the whole.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              BROWSER (Client)                            │
│  Next.js React components — mood entry form, journal editor, consent UI  │
│                     Tailwind CSS for all styling                         │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 │  HTTPS
                                 ▼
┌────────────────────────────────────────────────────────────────────────-─┐
│                     NEXT.JS 16 APPLICATION SERVER                        │
│                                                                          │
│  ┌────────────────────┐   ┌───────────────────────────────────────────┐ │
│  │   Clerk Middleware   │   │            Route Handlers /               │ │
│  │  (auth on every      │──▶│            Server Actions                 │ │
│  │   request)            │   │  - create mood entry                    │ │
│  └────────────────────┘   │  - create journal entry                  │ │
│                              │  - update consent                        │ │
│                              │  - request DSAR export/deletion          │ │
│                              └───────────────┬───────────────────────────┘ │
│                                               │                            │
│                              ┌────────────────▼───────────────────┐        │
│                              │      Access Control Layer          │        │
│                              │   (RBAC / ABAC — who can see       │        │
│                              │    what, based on role + context)  │        │
│                              └────────────────┬───────────────────┘        │
│                                               │                            │
│                              ┌────────────────▼───────────────────┐        │
│                              │   Data Access Layer (Prisma/SQL)    │        │
│                              │  - encrypts sensitive fields before │        │
│                              │    writing (field-level encryption)│        │
│                              │  - decrypts on authorized read only │        │
│                              │  - masks data for lower-privilege  │        │
│                              │    roles (admin dashboards, etc.)  │        │
│                              └────────────────┬───────────────────┘        │
└────────────────────────────────────────────────┼────────────────────────-─┘
                                                  │
                       ┌──────────────────────────┼──────────────────────────┐
                       ▼                          ▼                          ▼
        ┌─────────────────────────┐  ┌─────────────────────────┐  ┌────────────────────┐
        │   POSTGRES DATABASE      │  │   CONSENT LEDGER         │  │  INNGEST (background│
        │  - mood_entries          │  │  (append-only table:    │  │   workflows)        │
        │  - journal_entries       │  │   every consent change  │  │  - DSAR export job  │
        │    (ciphertext columns)  │  │   ever made, immutable) │  │  - account deletion │
        │  - medication_reminders  │  └─────────────────────────┘  │    cascade job      │
        │  - consent_preferences   │                                │  - consent-change   │
        │  - users (synced from    │                                │    reaction jobs    │
        │    Clerk)                │                                └──────────┬─────────┘
        └─────────────────────────┘                                           │
                                                                               ▼
                                                              ┌─────────────────────────────┐
                                                              │  Downstream side effects:   │
                                                              │  - email/notification stub  │
                                                              │  - "research opt-in" sync   │
                                                              │  - audit log entries        │
                                                              └─────────────────────────────┘

        ┌───────────────────────────────────────────────────────────────────────┐
        │                     CI/CD PIPELINE (GitHub Actions)                    │
        │  - runs on every pull request                                         │
        │  - static scan: fails the build if a sensitive DB column is added     │
        │    without encryption or without a consent-ledger link                │
        │  - runs tests, lints, and (eventually) deploys                        │
        └───────────────────────────────────────────────────────────────────────┘
```

A few things worth noticing about this diagram, in plain English, before we've written any code:

1. **Every request passes through Clerk's middleware first.** This is the "ID check at the door" — no request reaches our actual business logic without us first knowing exactly who is asking, whether they're signed in, and (later) what role they hold. We build this in Part 1.

2. **There's a dedicated Access Control Layer sitting *between* the routes and the database.** This is deliberate. It would be easy to sprinkle `if (user.role === 'admin')` checks throughout our route handlers, but that's how access-control bugs get born — one forgotten check in one forgotten file, and a support agent can suddenly read someone's private journal entry. Instead, we centralize the rule "who can see what" into one layer everything must pass through, like a single reception desk in a building instead of every floor having its own unlocked door. This is our **RBAC/ABAC** layer (Role-Based / Attribute-Based Access Control), built in Part 4.

3. **Sensitive columns in Postgres are stored as ciphertext, not plaintext.** "Ciphertext" just means "scrambled, unreadable text produced by an encryption algorithm" — as opposed to "plaintext," which means normal, readable text. If our database were ever stolen or leaked (it happens even to careful teams), an attacker with the raw database file would see gibberish where a journal entry used to be, not "Today I felt hopeless and skipped my medication." This is **field-level encryption**, and we build it in Part 4.

4. **The Consent Ledger is a separate, append-only table.** "Append-only" means rows are only ever *added*, never edited or deleted — like a bank statement, not a whiteboard. If a user changes their mind about a consent setting, we don't overwrite the old value; we add a new row recording the change, so there's always a permanent, provable history of exactly what the user agreed to and when. This is essential for regulatory audits ("prove to me this user consented to X on this date") and we build it in Part 5.

5. **Inngest handles anything that is multi-step, slow, or must not silently fail.** Exporting a user's entire data history, or cascading a full account deletion across several tables, isn't something you want to do inline while a user waits on a spinning button — and if a step fails halfway through (say, the database times out on step 3 of 5), you need the system to retry intelligently rather than leave the user in a half-deleted, corrupted state. This is what "durable workflows" means, and it's the subject of Parts 5 and 6.

6. **CI/CD guardrails run on every pull request, before code ever reaches production.** This is our final safety net: an automated script that inspects new database migrations and fails the build if someone adds a sensitive-looking column (e.g., `diagnosis`, `medication_name`) without the required encryption annotation or consent-ledger linkage. This closes the loop between "we wrote a policy in Part 2's DPIA" and "the code actually enforces that policy, automatically, forever" — built in Part 7.

You do not need to memorize this diagram. Bookmark it mentally. We will return to a version of it at the start of every Part, with the relevant section highlighted, so you always know which piece of the map you're standing on.

## 0.5 How the series is structured

Here is the full roadmap. Each Part builds strictly on the code from the previous one — there is no skipping ahead, and nothing is introduced before it's needed.

| Part | Title | What you'll have by the end |
|---|---|---|
| **0** | Introduction *(you are here)* | Understand the "why," the stack, and the target architecture. |
| **1** | Foundations | A running Next.js 16 app with Clerk authentication wired up, protected routes, and your first DPIA document. |
| **2** | *(folded into Part 1's DPIA work per blueprint — see note below)* | — |
| **3** | Data Minimization | Postgres enums constraining consent categories; masking utilities so internal tools never over-expose raw text. |
| **4** | Architecture & Storage | Full database schema, field-level encryption for sensitive columns, and a working RBAC/ABAC layer. |
| **5** | Consent Management & Transparency | An append-only consent ledger, a consent UI designed against "dark patterns," and an Inngest consumer reacting to consent changes. |
| **6** | Automated DSAR & Right to be Forgotten | Inngest workflows that fully automate data export requests and account deletion. |
| **7** | CI/CD & Guardrails | A GitHub Actions pipeline that automatically blocks unencrypted sensitive columns from reaching production. |

> **A quick note on numbering:** the original blueprint lists "Foundations" and "DPIA" as closely paired activities within the early build. We fold them together as **Part 1: Foundations**, since scaffolding the app and writing the DPIA are done in the same sitting and inform each other directly — you can't honestly document "what data are we collecting and why" until you've stood up the project and decided on your first data model. Every phase from the original seven-part plan is still fully covered; nothing is cut.

By the time you reach the end of Part 7, you will have hand-built, from an empty folder to a CI-guarded production-ready codebase:

- A real authenticated Next.js 16 application.
- A privacy-by-design data model with encryption and access control baked in, not bolted on.
- An append-only consent ledger with a transparent, non-manipulative consent UI.
- Fully automated data export and account deletion workflows.
- A CI pipeline that mechanically enforces your own privacy rules so a future teammate (or future you, at 2 AM, in a hurry) can't accidentally violate them.

More importantly, you'll come away with **patterns**, not just a finished app. "Append-only ledger for anything that needs an audit trail," "encrypt at the field level, not just at rest," "centralize access control instead of scattering `if` checks," "automate the boring-but-legally-critical workflows" — these ideas apply just as well to a fintech app tracking transactions, an HR system storing performance reviews, or a legal tech tool handling case files. Mental health data is simply the strictest teacher available.

## 0.6 What you'll need before starting Part 1

To follow along hands-on (highly recommended — reading code and typing code build very different muscles), have ready:

- **Node.js 20 or later** installed (`node -v` to check).
- **A code editor** (VS Code is assumed for any editor-specific instructions, but any editor works).
- **A terminal** you're comfortable running commands in.
- **A free Clerk account** (we'll walk through creating one in Part 1 — no need to sign up yet).
- **Git**, for version control (we'll initialize a repository in Part 1).

You do **not** need a Postgres database yet, a Vercel/hosting account yet, or an Inngest account yet — we introduce each account/service exactly at the moment it's first required, so you're never staring at an empty dashboard for a tool you don't understand yet.

## 0.7 A word on the tone of what follows

From here on, every step in this series follows the same four-beat rhythm, so you always know what kind of information you're reading:

1. **The Target** — the exact file or feature we're building right now.
2. **The Concept** — a plain-English explanation, with an analogy, of *why* this piece works the way it does, before you see the code.
3. **The Implementation** — the complete, working code, fully written out, with comments on any line that isn't self-explanatory.
4. **The Verification** — a concrete way to prove to yourself, right now, that the step worked, before moving forward.

Nothing will be left as an exercise for the reader. If something is complex enough to deserve a deeper conceptual detour or a full library API reference, it will be pulled out into a standalone reference section at the end of the relevant Part — so the main tutorial thread stays fast and practical, while the depth is still there if you want it.

Let's build something real.
