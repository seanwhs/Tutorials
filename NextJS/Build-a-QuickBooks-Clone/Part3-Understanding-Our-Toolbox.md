## Part 3: Understanding Our Toolbox

**Goal:** understand, in plain English, what Clerk, Neon, Drizzle, and Inngest each do, before installing any of them. No code in this part.

**Prerequisite:** Parts 1-2 completed.

---

### 1. The problem: a website needs more than just pages

Our app can currently show pages. A real accounting app also needs to: know who's using it, support multiple businesses each seeing only their own data, remember data permanently, safely query that data, and do things later or on a schedule.

### 2. Clerk — authentication and multi-tenancy

Clerk is a hosted service handling sign-up, sign-in, and sessions, so you never write password-handling code yourself. Its **Organizations** feature lets a user belong to multiple organizations and switch between them — we map this directly: **1 Clerk Organization = 1 Company File.**

### 3. Neon / Postgres — where data lives

Postgres is a mature, open-source relational database — data organized into tables that reference each other. Neon runs Postgres for you in the cloud with a generous free tier that doesn't expire from inactivity, plus "branching" (copying your whole database structure to experiment safely).

### 4. Drizzle — talking to the database safely

Drizzle is an ORM: define your tables as TypeScript, then query using type-checked function calls instead of raw SQL text. Typos in column names get caught before you even run the code. It also gives us migrations — a controlled, tracked way to evolve your database structure.

### 5. Inngest — background and scheduled jobs

Inngest lets you write normal functions that run in response to events ("an invoice was created") or on a schedule ("every night at 2am"), with automatic retries if something fails, without blocking the user's page load.

### 6. How it all connects — one example

A user (Clerk) creates an invoice in Joe's Landscaping (a Clerk Organization). Our server code inserts it into Neon via Drizzle, tagged with that org's ID. Instead of generating a PDF and emailing it inline, our code tells Inngest "an invoice was created" — Inngest handles the email in the background, and later checks on its own schedule if it becomes overdue.

### 7. Why this build order

We do the "boring plumbing" (auth, database) before real features, because features need that foundation first.

---

### ✅ Checkpoint (conceptual, no code)

- [ ] What does Clerk do, and what does an "Organization" represent in our app?
- [ ] What's the difference between Postgres and Neon?
- [ ] Why Drizzle instead of raw SQL text?
- [ ] One example of something Inngest is good for that a normal page request is not
- [ ] Describe the invoice example above in your own words

---

### Troubleshooting

No code was written this part, so there's nothing to break. If any of the five concepts above still feel unclear, that's completely normal at this stage — re-read the relevant section, or ask for it explained a different way before moving to Part 4. It's worth being solid on this before installing anything, since Parts 4-7 build directly on these ideas without re-explaining them from scratch.

---

Ready for **Part 4: Adding Login with Clerk** ?
