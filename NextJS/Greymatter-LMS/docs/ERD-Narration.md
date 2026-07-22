# GreyMatter LMS — Entity-Relationship Diagram Narration

**Document type:** ERD Narration (companion to the visual Entity-Relationship Diagram)
**Product:** GreyMatter LMS
**Version:** 1.0 (reflects implemented system, Parts 0–16)
**Status:** Baseline — approved
**Location:** `docs/ERD_NARRATION.md`
**Companion documents:** `docs/DATA_DICTIONARY.md`, Appendix B, Appendix C

---

## 1. Purpose of This Document

An entity-relationship diagram shows *what* connects to *what*. It does not, by itself, explain *why* a connection exists, *what kind* of connection it is, or *what happens* at each end when data changes. This document is the spoken walkthrough that should accompany the visual ERD — read it alongside the diagram, entity by entity, relationship by relationship, exactly as you would narrate the diagram to a new engineer standing at a whiteboard.

This narration covers **two separate diagrams that must be understood together**: the **Neon relational ERD** (Section 2) and the **Sanity content ERD** (Section 3) — plus the **seam between them** (Section 4), which is the single most important architectural idea in the entire data model. Section 5 walks the complete diagram as one continuous narrative, the way you'd present it in a design review.

---

## 2. The Neon Relational ERD, Narrated

### 2.1 The overall shape, before the details

Look at the diagram as a whole first. You'll notice one entity sitting at the top with lines radiating outward to almost everything else — that's `users`. Every other entity in this diagram exists **because of** a user: an enrollment is a user's relationship to a course, a certificate is a user's proof of achievement, a notification is a message addressed to a user. There is no entity in this diagram that makes sense independent of a user, with one partial exception (`workflow_events`), which we'll address specifically when we get there.

This "hub and spoke" shape is deliberate. It reflects the PRD's own framing: GreyMatter's relational database exists specifically to answer "what is true about *this specific person*, right now" — so it should be unsurprising that the person (`users`) is the gravitational center of the entire diagram.

### 2.2 `users` — the hub

Start here. `users` has one primary key, `id`, and two fields worth narrating specifically: `auth_provider_id` and `email`, both marked unique. `auth_provider_id` is the thread connecting this entire diagram to a system that *isn't* in this diagram at all — Clerk, the identity provider. Every other entity's `user_id` foreign key ultimately traces back to this one row, but this one row itself traces back, one level further, to an external system.

Draw this as a dotted line off the edge of your diagram if you're presenting it live: `users.auth_provider_id → (external) Clerk account`. It's a real relationship, just not one Postgres can enforce, because the other end of it lives outside Postgres entirely.

### 2.3 `users → enrollments` — one-to-many, cascade

Follow the first line down from `users` to `enrollments`. This is a classic one-to-many: one user can have many enrollments (one per course), but each enrollment belongs to exactly one user. The line itself is drawn as a foreign key on `enrollments.user_id`, and it's worth narrating the **arrowhead behavior**, not just the connection: this foreign key is configured `ON DELETE CASCADE`, meaning if you erase the `users` row at the top, every `enrollments` row hanging off it disappears automatically, without anyone needing to clean them up by hand.

Now look at `enrollments` itself, and notice a **second** field: `course_id`. If you're narrating this diagram to someone unfamiliar with the system, this is the moment to pause and say explicitly: *"this looks like it should be a foreign key, the same way `user_id` is — but it isn't. There is no line connecting `enrollments.course_id` to anything else in this diagram, because the thing it points to doesn't live in this diagram at all."* We'll come back to this precise point in Section 4 — it's the single most important thing to communicate about this ERD, and it's easy for a reader to miss if it isn't called out explicitly.

### 2.4 `enrollments → lesson_progress` and `enrollments → course_progress` — both one-to-many, both cascade

From `enrollments`, two lines fan out: one to `lesson_progress`, one to `course_progress`. Both are one-to-many relationships from the *enrollment's* perspective — one enrollment can have many `lesson_progress` rows (one per lesson the student has touched) and, notably, only **one** `course_progress` row (the aggregate summary for that whole enrollment).

This is worth narrating as a deliberate asymmetry: `lesson_progress` is *fine-grained* (many rows per enrollment, one per lesson), while `course_progress` is *coarse-grained* (exactly one row per enrollment, holding a rolled-up percentage). If someone asks "why are these two separate tables instead of one," the answer is exactly this asymmetry — they have genuinely different cardinalities relative to the enrollment, and cramming them together would force one of the two into an awkward shape.

Both relationships also carry `ON DELETE CASCADE` back to `users` (through `enrollments`) — delete the user, and the entire chain unwinds cleanly.

### 2.5 `users → module_attempts` — one-to-many, cascade, but notice what's *missing*

Draw the line from `users` directly to `module_attempts` — notice this one bypasses `enrollments` entirely, connecting straight from `users`. This is worth calling out explicitly during narration, because it's easy to assume every "learning activity" table hangs off `enrollments` the same way — it doesn't.

`module_attempts` references `user_id` directly, and carries its own `lesson_id` and `module_id` as plain text fields — again, no foreign key, for the same cross-system reason as `enrollments.course_id`. The reasoning for *not* routing this through `enrollments` is architectural: a module attempt is fundamentally about "did this student answer this specific question," a fact that's meaningful even independent of which enrollment or course it happened under. In practice the system always resolves it through the enrollment relationship at query time (verifying the user is enrolled in the course containing this module before grading), but the *storage* relationship is deliberately direct to the user.

### 2.6 `users → certificates` — one-to-many, cascade

A simple, direct line, structurally identical in shape to `enrollments`. The interesting detail to narrate here isn't the relationship line itself — it's two fields sitting *inside* the `certificates` box that don't participate in any relationship line at all: `course_title` and `recipient_email`. Point at these specifically and say: *"these look like they should be joins — pull the title live from the course, pull the email live from the user — but they're deliberately stored as static, frozen copies instead."* This is the ERD's visual representation of the **snapshot pattern**: the box has no line reaching out to `course` or back to `users.email`, because it doesn't need one — it carries its own permanent record of what those values were at one specific moment.

### 2.7 `webhook_events` — no relationship lines at all

This entity sits alone in the diagram, with no foreign keys pointing in or out. Narrate this explicitly, because an isolated box in an ERD often looks like a mistake — it isn't. `webhook_events` doesn't model a relationship between two things; it models a **ledger of events that have already happened**, keyed by `(source, external_id)`. It has no reason to connect to `users`, because a webhook event might arrive and be processed *before* the corresponding user even exists in the `users` table yet (recall the provisioning-race scenario) — coupling this table to `users` would actually be architecturally wrong.

### 2.8 `workflow_events` — also isolated, for a related but distinct reason

Similarly isolated, and worth distinguishing from `webhook_events` in your narration even though they look superficially similar (both are "event ledgers" with a `payload` JSONB field). `webhook_events` is about **external** events arriving *into* the system; `workflow_events` is about **internal** background job runs — a record of what Inngest did, for our own operational visibility, independent of Inngest's own external dashboard. Neither needs a line to `users` for the same underlying reason: they're operational metadata about *processes*, not records *about* a specific person.

### 2.9 `audit_logs` — the one exception to the cascade rule

Draw the line from `users` to `audit_logs` last, and narrate it differently from every other line in the diagram, because it behaves differently. Every other foreign key we've walked through says "if the user disappears, this row disappears too" (`CASCADE`). This one says the opposite: "if the user disappears, this row *stays*, but its `user_id` field goes blank" (`SET NULL`).

This is worth dwelling on visually — if your diagramming tool distinguishes cascade behavior with different arrowhead styles (a filled diamond vs. an open one, or a labeled annotation), this is the one relationship in the entire diagram that should look visually distinct from all the others. The reasoning: an audit log entry is evidence of something that happened. Evidence shouldn't vanish just because the account it was about later got deleted.

### 2.10 `users → notifications` and `users → notification_preferences`

Two more direct, cascading lines from `users`, structurally unremarkable compared to what we've already covered — except `notification_preferences` carries a **unique** constraint on `user_id` alone (not a compound key with anything else), meaning this is a genuine one-to-*one* relationship, the only one in the entire diagram. Every other line from `users` is one-to-*many*. Worth pointing at this specifically: *"this is the one place in the whole schema where a user has at most one row, not potentially several."*

---

## 3. The Sanity Content ERD, Narrated

### 3.1 A different shape entirely — a tree, not a hub

Switch diagrams now. Where the Neon ERD radiated outward from one central `users` entity, the Sanity content ERD is a **strict tree**, narrated top to bottom: `course` at the top, branching down through `chapter`, down through `lesson`, down into a set of embedded content types at the bottom. There is no entity at the bottom of this tree that points back up — content flows one direction only, from course down to individual interactive blocks.

### 3.2 `course → category` and `course → instructor` — the two "sideways" references

Before going downward, narrate the two lines that point *sideways* out of `course`: one to `category`, one to `instructor`. These are genuine Sanity references (the `->` dereference syntax in GROQ), conceptually similar to foreign keys, though — worth noting for anyone comparing this to the Neon diagram — Sanity does not *enforce* these references the way Postgres enforces a foreign key; a broken reference in Sanity shows up as a visible warning in Studio's editing interface, not a hard database-level rejection.

Point at `instructor` specifically and mention the one field on it that reaches *outside* this entire content ERD: `userId`. This is the Sanity-side half of the cross-system seam we'll fully narrate in Section 4 — draw it as a dotted line leaving the diagram entirely, pointing toward the Neon ERD's `users.id`, exactly mirroring the dotted line we drew off `users.auth_provider_id` toward Clerk in Section 2.2. Three systems, three dotted lines leaving this narration's two solid diagrams — Clerk, Neon, and now this reverse direction from Sanity back into Neon.

### 3.3 `course → chapters[]` — an array of references, not nesting

This is the line worth narrating most carefully in the whole content diagram, because it's easy to draw incorrectly. `course` does **not** contain chapters the way a folder contains files nested inside it. It holds an **array of references** — pointers to chapter documents that exist independently, elsewhere in the dataset, each with its own identity. If you're narrating this at a whiteboard, resist the urge to draw `chapter` as a box *physically inside* the `course` box (which would visually suggest nesting/ownership-by-containment). Draw it as a separate, standalone box, connected by a line labeled "references, in order" — because a chapter genuinely could, in principle, be referenced by more than one course, even though in practice this system's authoring workflow doesn't currently do that.

### 3.4 `chapter → lessons[]` — the identical pattern, one level down

Narrate this exactly the same way as 3.3, because it's exactly the same relationship shape repeated one level deeper. This repetition is worth pointing out explicitly — once a reader understands "array of references, not nesting" for chapters, they already understand it for lessons too. The diagram's self-similarity here isn't an accident; it's the same authoring-flexibility reasoning applied consistently at every level of the hierarchy.

### 3.5 `lesson → content[]` — where the tree fans out into five different shapes at once

This is the most visually complex part of the content ERD, and it deserves the most narration time. Draw one line from `lesson` down to a single array field, `content` — but that one field can hold **six different kinds of things**, mixed together in any order the author chooses: a plain text block, an image block, and four custom object types (`calloutBlock`, `quizBlock`, `codeExerciseBlock`, `reflectionBlock`, `checkpointBlock`).

Narrate this explicitly as a **polymorphic array** — a single field whose array *elements* can each independently be a different type, distinguished at read-time by an internal `_type` tag on each element. This is meaningfully different from every relationship we've drawn so far, which have all been "one type of thing, referenced from one specific field." Here, one field holds a *mixture*.

### 3.6 The four object types at the bottom of the tree — draw them without outgoing lines

`calloutBlock`, `quizBlock`, `codeExerciseBlock`, `reflectionBlock`, and `checkpointBlock` sit at the very bottom of this diagram, and none of them have any lines leaving them at all — no references, no further nesting. Narrate why this matters: these are **object types**, not document types (the distinction covered extensively in Appendix C §C.2). They have no independent existence, no global identity, and nothing in the entire dataset can point *at* them the way `course` points at `chapter`. If you tried to draw an arrow from anywhere else in the diagram to `quizBlock`, you'd be drawing something that doesn't actually exist in the system — the only way to reach a `quizBlock` is by first reaching the specific `lesson` that contains it, and then finding it inside that lesson's `content` array.

This is worth stating as a rule while narrating: **anything at the leaves of this tree with no outgoing lines is reachable only by walking the entire path down from the root.** That sentence, stated out loud during a walkthrough, is actually the plain-English description of the "course-scoped query" pattern that appears constantly throughout the SRD and Architecture documents — the ERD's shape and the system's security model are the same idea, viewed from two different angles.

---

## 4. The Seam: Narrating What Connects the Two Diagrams

This section is the one most worth rehearsing before presenting this ERD to anyone, because it's the part a reader is most likely to misunderstand if it's rushed.

### 4.1 There is no line connecting the two diagrams — and that absence is the entire point

If you've been narrating carefully, you'll have noticed something: every text field in the Neon diagram that conceptually "should" point at something in the Sanity diagram — `enrollments.course_id`, `lesson_progress.lesson_id`, `module_attempts.module_id`, `certificates.course_id` — has **no drawn line** connecting it to the Sanity ERD at all. If you were building this as a single unified diagram spanning both systems, every one of these fields would want an arrow, and none of them get one.

Narrate this explicitly, as a deliberate choice, not a gap in the diagram: *"These fields point at real documents in the other system. But Postgres cannot draw that arrow, because Postgres has no idea Sanity exists. So instead of a database-enforced line, every one of these fields is backed by an application-code promise: 'I will independently check this relationship, every single time, before I trust it.'"*

### 4.2 A recommended way to actually draw this on a real diagram

If you're producing an actual visual ERD (not just this narration), represent the seam using a **different line style** entirely — a dashed, unlabeled-arrowhead line, crossing between the two diagrams, explicitly distinct from the solid foreign-key lines used everywhere else in the Neon diagram and the solid reference lines used in the Sanity diagram. Label each dashed line with the specific verification mechanism responsible for it:

```text
enrollments.course_id  ┄┄┄► course._id
   (verified by: existence + isPublished check at enrollment time)

lesson_progress.lesson_id  ┄┄┄► lesson._id
   (verified by: course-scoped lesson query)

module_attempts.module_id  ┄┄┄► content[].moduleId
   (verified by: course → chapter → lesson → content scoped query)

certificates.course_id  ┄┄┄► course._id
   (verified by: existence check at issuance; then FROZEN — snapshot,
    not re-verified again afterward)

instructor.userId  ┄┄┄► users.id
   (verified by: course-ownership check on every instructor-scoped request)
```

This block is worth including directly on the visual diagram itself, as a small legend box, rather than leaving it only in this narration document — anyone looking at the diagram cold, without this narration read aloud to them, should still be able to see at a glance which lines are database-enforced and which are promises kept entirely by application code.

### 4.3 Why this seam exists at all, narrated as a closing thought

If someone in the room asks "why not just put everything in one database, then, and avoid this whole problem" — this is the moment to step back to the PRD's opening framing. Content and transactional data have almost opposite lifecycles: content is authored occasionally by a handful of people and read identically by everyone; transactional data is written constantly, uniquely, per user. A single database optimized for one of these jobs is a poor fit for the other. The seam — and the extra verification work it requires at every crossing point — is the price paid for giving each side of the system a data store genuinely suited to what it actually needs to do. The dashed lines aren't a flaw in the diagram; they're the visible cost of a deliberate trade-off, made once, and then handled consistently everywhere it recurs.

---

## 5. The Complete Walkthrough — A Single Continuous Narration

For a live presentation (design review, onboarding session, or architecture walkthrough), the following is a complete, spoken-word script tying every section above into one continuous pass through the full diagram, start to finish.

> "We're looking at two diagrams that together represent the entire data model of the system, plus the seam between them.
>
> Start with the left-hand diagram — Neon, our transactional database. Everything radiates from `users`, at the top. A user has many enrollments — one per course — and if we ever delete a user, every enrollment they had disappears automatically with them; that's a cascade delete, and it's true for almost every relationship in this diagram.
>
> From each enrollment, two things branch off: a detailed, per-lesson progress record — one row per lesson the student has touched — and a single, rolled-up course-progress summary, holding one overall completion percentage. Two tables, two different shapes, because they answer two different questions: 'how far into this specific lesson did they get' versus 'how far into the whole course are they.'
>
> Separately, hanging directly off `users` rather than through enrollments, sits `module_attempts` — one row per graded interaction with one specific quiz or exercise. And separately again, `certificates` — one per completed course, carrying its own frozen, permanent copy of the course title and the student's email at the moment it was issued, rather than looking those values up live.
>
> Off to the side, two tables with no relationship lines at all: `webhook_events`, a ledger proving we've never processed the same external delivery twice, and `workflow_events`, an internal record of every background job run. Neither needs to connect to `users`, because both are about processes, not people.
>
> And one more line, drawn differently from all the others: `audit_logs`. Every other line says 'delete the user, delete this too.' This one says 'delete the user, but keep the record — just blank out whose it was.' It's the one deliberate exception in the entire diagram.
>
> Now the right-hand diagram — Sanity, our content system. This one is a tree, not a hub. `course` sits at the top, referencing a category and an instructor sideways, and referencing an ordered array of chapters downward — not containing them, *referencing* them, the same way a table of contents points at page numbers rather than holding the actual pages. Chapters, in turn, reference lessons the same way. And lessons hold one special field — `content` — which is an array that can mix plain text, images, and four different kinds of interactive assessment blocks together, in whatever order an author chooses. Those four block types sit at the very bottom of the tree with nothing pointing further down from them, and critically, nothing anywhere else in the dataset can reference them directly — the only way to reach one is to walk all the way down from the course at the top.
>
> Now — the seam. Look back at the Neon diagram, at fields like `enrollments.course_id`, `module_attempts.module_id`. These are plain text. There is no solid line connecting them to the Sanity diagram, because Postgres has no way to enforce a relationship into a completely different system. Instead, every single one of these fields is backed by a promise, kept in application code, verified fresh on every single access: before we trust that a course ID is real, we check Sanity. Before we trust that a lesson belongs to a course, we walk the actual reference chain. Before we grade a quiz, we prove the module genuinely belongs to the lesson and course the student claims to be in.
>
> That's the whole system: one hub of per-user truth, one tree of shared content, and a seam between them held together not by a database constraint, but by a rule we apply the same way, every time, without exception."
