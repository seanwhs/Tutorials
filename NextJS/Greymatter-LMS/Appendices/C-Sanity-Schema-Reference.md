# Appendix C — Sanity Schema Reference

This expanded reference documents every Sanity schema type in GreyMatter LMS: the complete content hierarchy with a full diagram, every field with its type, validation rules and rationale, the distinction between document and object types explained with concrete consequences, Portable Text's structure explained in depth, complete GROQ query examples for every common access pattern, and the draft/publish lifecycle explained precisely. Use this as the authoritative reference for anything content-model related.

---

## C.1 The complete content hierarchy diagram

```text
                              ┌───────────────┐
                              │   category     │  (document)
                              │───────────────│
                              │ title          │
                              │ slug           │
                              │ description    │
                              └───────┬────────┘
                                      │ referenced by
                                      ▼
┌───────────────┐            ┌───────────────┐
│  instructor    │            │    course      │  (document)
│───────────────│  referenced│───────────────│
│ name           │◄───────────│ title          │
│ slug           │    by      │ slug           │
│ avatar         │            │ description    │
│ bio            │            │ thumbnail      │
│ title          │            │ difficulty     │
│ userId  [P15]  │            │ category ──────┼──► category (ref)
└───────────────┘            │ instructor ────┼──► instructor (ref)
                              │learningObjectives[]│
                              │ chapters[] ────┼──┐
                              │ isPublished    │  │
                              └───────────────┘  │
                                                  │ array of references
                                                  ▼
                                          ┌───────────────┐
                                          │   chapter      │  (document)
                                          │───────────────│
                                          │ title          │
                                          │ slug           │
                                          │ order          │
                                          │ lessons[] ─────┼──┐
                                          └───────────────┘  │
                                                              │ array of references
                                                              ▼
                                                      ┌───────────────┐
                                                      │    lesson      │  (document)
                                                      │───────────────│
                                                      │ title          │
                                                      │ slug           │
                                                      │ order          │
                                                      │ isPreview      │
                                                      │ videoUrl       │
                                                      │ content[] ─────┼──┐
                                                      └───────────────┘  │
                                                                         │ Portable Text array
                                    ┌────────────────────────────────────┼─────────────────────┐
                                    ▼                ▼                  ▼                      ▼
                            ┌──────────┐    ┌───────────────┐   ┌────────────────┐    ┌──────────────────┐
                            │  block   │    │     image      │   │  calloutBlock   │    │    quizBlock       │
                            │(built-in)│    │  (built-in)     │   │   (object)      │    │    (object)        │
                            │──────────│    │────────────────│   │─────────────────│    │────────────────────│
                            │ normal   │    │ asset           │   │ tone            │    │ moduleId           │
                            │ h2, h3   │    │ hotspot         │   │ text            │    │ question           │
                            │ blockquote│   │ alt (required)  │   └─────────────────┘    │ options[]          │
                            │ bullet/  │    └────────────────┘                          │ correctOptionIndex │
                            │ numbered │                                                └────────────────────┘
                            │ list     │
                            │ strong/  │    ┌──────────────────────┐    ┌─────────────────┐   ┌───────────────────┐
                            │ em/code  │    │ codeExerciseBlock     │    │reflectionBlock  │   │ checkpointBlock    │
                            │ marks    │    │      (object)         │    │   (object)      │   │    (object)        │
                            └──────────┘    │───────────────────────│    │─────────────────│   │────────────────────│
                                            │ moduleId              │    │ moduleId        │   │ moduleId           │
                                            │ prompt                │    │ prompt          │   │ label              │
                                            │ language              │    │ minWords        │   └───────────────────┘
                                            │ starterCode           │    └─────────────────┘
                                            │ expectedKeywords[]    │
                                            └───────────────────────┘
```

**The one relationship this diagram makes visually obvious:** every arrow from `course` down to `lesson` is a **reference chain**, not nesting. This is what makes Part 4's course-scoped query pattern (`course → chapters[]→ → lessons[]→`) both possible and *necessary* — you cannot reach a lesson without walking down through its actual course and chapter, which is exactly the property that prevents lesson-slug spoofing across courses.

---

## C.2 Document types vs. object types — the complete, consequential distinction

This distinction was introduced in Part 3, but its consequences ripple through the entire series. Here is every practical difference, in one table:

| | Document type (`course`, `chapter`, `lesson`, `instructor`, `category`) | Object type (`calloutBlock`, `quizBlock`, `codeExerciseBlock`, `reflectionBlock`, `checkpointBlock`) |
|---|---|---|
| Has its own `_id`? | Yes — globally unique across the dataset | No — only has a `_key` (unique *within its parent array*, not globally) |
| Appears in Studio's document list? | Yes, as its own top-level entry | No — only visible nested inside a lesson's content editor |
| Can be referenced (`type: "reference"`) from elsewhere? | Yes | No |
| Can exist independently, with no parent? | Yes | No — always embedded inside a `content[]` array |
| Queryable directly via `*[_type == "X"]`? | Yes, meaningfully — returns real standalone documents | Technically yes, but returns fragments with no independent identity — never done in this series' queries |
| Has draft/publish lifecycle? | Yes (see C.6) | No — inherits its parent document's draft/publish state entirely |
| GROQ dereference syntax needed? | Yes, `->` when referenced | No — it's already inline data, no dereferencing needed |

**A concrete consequence worth internalizing:** you cannot write `*[_type == "quizBlock"]` and expect a meaningful, independent list of "every quiz in the platform" the way you can with `*[_type == "course"]`. A `quizBlock` only exists as a fragment inside some lesson's `content` array — to find "every quiz," you'd need to query lessons and extract their `content` arrays, filtering by `_type` within each. Part 12's `courseRequiredContentQuery` does exactly this:

```groq
*[_type == "course" && _id == $courseId][0]{
  chapters[]->{
    lessons[]->{
      "moduleIds": content[
        _type in ["quizBlock", "codeExerciseBlock", "reflectionBlock", "checkpointBlock"]
      ].moduleId
    }
  }
}
```

---

## C.3 Complete field reference for every document type

### `course`

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | Yes, max 120 chars | |
| `slug` | `slug` | Yes | Source: `title`, max 120 chars |
| `description` | `text` | Yes, max 600 chars | Shown on catalog cards and detail page |
| `thumbnail` | `image` (hotspot) | Yes | Rendered via `urlForImage()` at multiple sizes |
| `difficulty` | `string` (radio list) | Yes | `beginner` \| `intermediate` \| `advanced` |
| `category` | `reference → category` | Yes | |
| `instructor` | `reference → instructor` | Yes | |
| `learningObjectives` | `array of string` | Min 1 | Rendered as a checkmarked list |
| `chapters` | `array of reference → chapter` | Yes, min 1 | Order determined by chapter's own `order` field, not array position |
| `isPublished` | `boolean` | — | Default `false`. **Not** the same as Sanity's own draft/publish state — see C.6 |

### `chapter`

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | Yes, max 100 chars | |
| `slug` | `slug` | Yes | |
| `order` | `number` | Yes, integer ≥ 0 | Editor-controlled sequence position |
| `lessons` | `array of reference → lesson` | Yes, min 1 | |

### `lesson`

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | Yes, max 120 chars | |
| `slug` | `slug` | Yes | |
| `order` | `number` | Yes, integer ≥ 0 | Sequence within the parent chapter |
| `isPreview` | `boolean` | — | Default `false`. Gates public, unauthenticated access (Part 4) |
| `videoUrl` | `url` | — | Rendered only if the domain matches Part 9's YouTube/Vimeo allow-list |
| `content` | Portable Text `array` | — | See C.4 for the full block inventory |

### `instructor`

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | `string` | Yes, max 80 chars | |
| `slug` | `slug` | Yes | |
| `avatar` | `image` (hotspot) | — | |
| `bio` | `text` | Max 500 chars | |
| `title` | `string` | — | e.g. "Senior Backend Engineer" |
| `userId` | `string` | — | **[Part 15 addition]** Manually-set link to an internal Neon `users.id`. Powers course-ownership verification for the instructor dashboard. Not managed by any automatic sync — a deliberate, documented manual step. |

### `category`

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `string` | Yes, max 60 chars | |
| `slug` | `slug` | Yes | |
| `description` | `text` | — | 2 rows |

---

## C.4 Complete field reference for every object type (Portable Text blocks)

### `block` (Sanity's built-in rich text type — configured, not authored by us)

| Configured option | Values allowed |
|---|---|
| `styles` | `normal`, `h2` ("Heading 2"), `h3` ("Heading 3"), `blockquote` ("Quote") |
| `lists` | `bullet`, `number` |
| `marks.decorators` | `strong` (Bold), `em` (Italic), `code` (Code) |

Deliberately restricted, per Part 3's reasoning: a fixed, small vocabulary of formatting options keeps every lesson visually consistent and ensures our rendering components (`baseFieldComponents` in `portable-text-renderer.tsx`) never encounter a style they don't know how to display.

### `image` (Sanity's built-in image type, with one custom field added)

| Field | Type | Required | Notes |
|---|---|---|---|
| `asset` | (managed by Sanity) | Yes | The actual uploaded file reference |
| `hotspot` | (managed by Sanity, `hotspot: true` enabled) | — | Lets editors choose a focal point for responsive cropping |
| `alt` | `string` | **Yes** | Custom field added in Part 3 specifically for accessibility — enforced at the schema level so it can never be silently skipped |

### `calloutBlock`

| Field | Type | Required | Notes |
|---|---|---|---|
| `tone` | `string` (radio) | Yes, default `info` | `info` \| `tip` \| `warning` — maps to `info`/`success`/`warning` Alert variants respectively |
| `text` | `text` | Yes, 3 rows | |

### `quizBlock`

| Field | Type | Required | Notes |
|---|---|---|---|
| `moduleId` | `string` | Yes | Stable identifier — changing after students have attempted it disconnects their history |
| `question` | `text` | Yes, 2 rows | |
| `options` | `array of string` | Yes, min 2, max 6 | |
| `correctOptionIndex` | `number` | Yes, min 0 | Custom-validated: must be `< options.length` (Part 3's `.custom()` rule). **Never sent to any browser-facing query since Part 11.** |

### `codeExerciseBlock`

| Field | Type | Required | Notes |
|---|---|---|---|
| `moduleId` | `string` | Yes | |
| `prompt` | `text` | Yes, 3 rows | |
| `language` | `string` (list) | Default `sql` | `sql` \| `javascript` \| `plaintext` |
| `starterCode` | `text` | — | Pre-filled in the student's editor |
| `expectedKeywords` | `array of string` | Yes, min 1 | Case-insensitive substrings checked at grading time. **Never sent to any browser-facing query since Part 11.** |

### `reflectionBlock` **[Part 10 addition]**

| Field | Type | Required | Notes |
|---|---|---|---|
| `moduleId` | `string` | Yes | |
| `prompt` | `text` | Yes, 2 rows | |
| `minWords` | `number` | Default 20 | A soft guideline only — never enforced server-side as a hard requirement |

### `checkpointBlock` **[Part 10 addition]**

| Field | Type | Required | Notes |
|---|---|---|---|
| `moduleId` | `string` | Yes | |
| `label` | `string` | Yes, default "Mark as complete" | Button text |

---

## C.5 Which fields are visible to the browser — the complete answer-key map

This table is the single most security-critical piece of information in this entire appendix. It shows, for every object type with an answer key, exactly which query is allowed to fetch it.

| Field | Public catalog (`previewLessonQuery`) | Authenticated lesson player (`lessonWithinCourseQuery`) | Server-only grading (`assessmentDefinitionQuery`) |
|---|---|---|---|
| `quizBlock.correctOptionIndex` | ❌ Never | ❌ Never (fixed in Part 11) | ✅ Yes — this is its *only* legitimate destination |
| `codeExerciseBlock.expectedKeywords` | ❌ Never | ❌ Never (fixed in Part 11) | ✅ Yes — this is its *only* legitimate destination |
| `quizBlock.question`, `.options` | ✅ Yes | ✅ Yes | Not needed (grading only needs the answer key + submission) |
| `codeExerciseBlock.prompt`, `.language`, `.starterCode` | ✅ Yes | ✅ Yes | Not needed |
| `reflectionBlock`, `checkpointBlock` (all fields) | ✅ Yes | ✅ Yes | N/A — no answer key exists |

**The rule this table encodes:** exactly one query in the entire codebase (`assessmentDefinitionQuery`, defined in `sanity/lib/queries.ts`, called only from `submitModuleAttempt` in `lib/modules/submit-module-attempt.ts`) is permitted to fetch an answer-key field. Every other query — public or authenticated — must use a conditional projection to explicitly exclude it, per Part 4 and Part 11's pattern:

```groq
content[]{
  ...,
  _type == "quizBlock" => {
    _type, _key, moduleId, question, options
    // correctOptionIndex deliberately absent
  },
  _type == "codeExerciseBlock" => {
    _type, _key, moduleId, prompt, language, starterCode
    // expectedKeywords deliberately absent
  }
}
```

---

## C.6 The draft/publish lifecycle, precisely

Sanity's own draft/publish mechanism is easy to conflate with GreyMatter's custom `isPublished` field — they are **two entirely separate systems**, and confusing them is a common source of "why doesn't my content show up" confusion.

### Sanity's built-in mechanism

Every document, the moment it's created in Studio, exists as a **draft** — internally stored with an ID prefixed `drafts.` (e.g. `drafts.abc123`). Clicking **Publish** copies that draft's content to a document with the plain ID (`abc123`), which is what our GROQ queries — using the standard, unprefixed dataset — actually read. Clicking **Publish** again after further edits updates the published document; the draft version can continue to diverge until published again.

```text
Studio: create document
        │
        ▼
   drafts.abc123  ◄── exists immediately, editable, NOT visible to our app's queries
        │
        │  Click "Publish"
        ▼
   abc123          ◄── created/updated; THIS is what client.fetch() reads
```

Our `sanity/lib/client.ts` uses `useCdn: true` reading from the standard (published-only) dataset perspective — meaning **unpublished drafts are structurally invisible to the entire application**, regardless of any other logic. This is why Part 3's verification steps repeatedly instruct "click Publish, not just Save" — a saved-but-unpublished course would never appear anywhere in the app, with no error message explaining why.

### GreyMatter's custom `isPublished` field

This is a plain boolean field on the `course` document, entirely separate from the mechanism above. It exists to model a *different, additional* real-world need: an instructor might want to fully write, proofread, and **publish** (in Sanity's sense) a course internally — sharing a preview link with colleagues — while still keeping it hidden from the *public catalog* until an announced launch date.

```text
Course is published (Sanity sense) AND isPublished = false
        │
        ▼
   Visible to: Studio, direct Sanity API queries with the right permissions
   Invisible to: courseCatalogQuery, courseDetailQuery (both filter on isPublished == true)
```

Every browser-facing course query in this series filters on **both** conditions simultaneously — Sanity's implicit "published, not draft" state (simply by virtue of which dataset we read) **and** the explicit `isPublished == true` check:

```groq
*[_type == "course" && isPublished == true]  // isPublished check
// implicitly ALSO only matches published (non-draft) documents,
// because client.fetch() reads the standard dataset, which never
// contains drafts.* documents at all
```

---

## C.7 Complete GROQ query catalog

Every query used across the series, in one place, annotated with its purpose and security properties.

```groq
// ── Part 4: Public catalog ──────────────────────────────────────────
*[_type == "course" && isPublished == true] | order(title asc) {
  _id, title, slug, description, thumbnail, difficulty,
  category->{ title, slug },
  instructor->{ name, slug }
}

// ── Part 4: Public course detail (with resolved chapters/lessons) ───
*[_type == "course" && slug.current == $slug && isPublished == true][0]{
  _id, title, slug, description, thumbnail, difficulty, learningObjectives,
  category->{ title, slug },
  instructor->{ name, slug },
  chapters[]->{
    _id, title, slug, order,
    lessons[]->{ _id, title, slug, order, isPreview }
  } | order(order asc)
}

// ── Part 4: Public preview lesson (answer keys excluded) ────────────
*[_type == "lesson" && slug.current == $lessonSlug && isPreview == true][0]{
  _id, title, slug, order, isPreview,
  content[]{
    ...,
    _type == "quizBlock" => { _type, _key, moduleId, question },
    _type == "codeExerciseBlock" => { _type, _key, moduleId, prompt, language, starterCode }
  }
}

// ── Part 4/9/11: Course-scoped lesson (answer keys excluded since P11) ──
*[_type == "course" && slug.current == $courseSlug && isPublished == true][0]
.chapters[]->.lessons[]->[slug.current == $lessonSlug][0]{
  _id, title, slug, order, isPreview, videoUrl,
  content[]{
    ...,
    _type == "quizBlock" => { _type, _key, moduleId, question, options },
    _type == "codeExerciseBlock" => { _type, _key, moduleId, prompt, language, starterCode }
  }
}

// ── Part 7: Multiple courses by ID (dashboard course list) ──────────
*[_type == "course" && _id in $ids]{ _id, title, slug, thumbnail, difficulty }

// ── Part 8: Existence + publication check (enrollment guard) ────────
*[_type == "course" && _id == $courseId][0]{ _id, isPublished }

// ── Part 11: SERVER-ONLY assessment definition (the answer key) ─────
*[_type == "course" && _id == $courseId][0]
.chapters[]->.lessons[]->[_id == $lessonId][0]
.content[moduleId == $moduleId][0]{
  _type, moduleId, correctOptionIndex, "optionCount": count(options), expectedKeywords
}

// ── Part 12: Full required-content shape (for progress recalculation) ──
*[_type == "course" && _id == $courseId][0]{
  _id,
  chapters[]->{
    lessons[]->{
      _id,
      "moduleIds": content[
        _type in ["quizBlock", "codeExerciseBlock", "reflectionBlock", "checkpointBlock"]
      ].moduleId
    }
  }
}

// ── Part 15: Courses by instructor's linked user ID ──────────────────
*[_type == "course" && instructor->userId == $userId]{ _id, title, slug, isPublished }

// ── Part 15: Course ownership check ──────────────────────────────────
*[_type == "course" && _id == $courseId][0]{ _id, "instructorUserId": instructor->userId }
```

---

## C.8 GROQ syntax patterns used, cross-referenced to where they're introduced

| Pattern | Meaning | First introduced |
|---|---|---|
| `*[filter]` | Every document matching filter | Part 4 |
| `{ field, field }` | Projection — select exactly these fields | Part 4 |
| `field->{ ... }` | Dereference a single reference | Part 4 |
| `field[]->{ ... }` | Dereference every item in a reference array | Part 4 |
| `[0]` | Take the first match, collapsing array → single object | Part 4 |
| `\| order(field asc)` | Sort results | Part 4 |
| `$paramName` | Safely-injected parameter (never string concatenation) | Part 4 |
| `_type == "X" => {...}` | Conditional projection — different field selection per block type | Part 4 |
| `...` | Spread every field of the current object | Part 4 |
| `_id in $ids` | Membership test against an array parameter | Part 7 |
| `count(field)` | Count items in an array field | Part 11 |
| `content[moduleId == $moduleId][0]` | Filter *within* an already-fetched array field | Part 11 |
| `content[_type in [...]]` | Filter array items by multiple possible types | Part 12 |
| `.chapters[]->.lessons[]->[...]` | Chained multi-level dereference + filter (the course-scoping pattern) | Part 4, Step 9; extended Part 11 |

---

## C.9 Content authoring workflow, end to end

A complete, ordered checklist for authoring one new course from scratch — useful as an onboarding reference for any future content editor.

```text
1. Ensure at least one Category exists (create if needed) → Publish
2. Ensure the Instructor document exists → set userId if instructor dashboard
   access is needed → Publish
3. Create each Lesson:
   a. Set title, slug (Generate), order
   b. Toggle isPreview ON for exactly the lessons meant to be publicly
      readable without enrollment (typically just the first lesson)
   c. Optionally set videoUrl (must be a YouTube or Vimeo URL — Part 9's
      allow-list silently renders nothing for any other domain)
   d. Author content: paragraphs, headings, images (with alt text),
      callouts, and any interactive blocks (quiz/code-exercise/
      reflection/checkpoint) — each needs a unique moduleId
   e. Publish
4. Create each Chapter:
   a. Set title, slug, order
   b. Add lessons in the array, IN THE ORDER they should appear
      (order also comes from each lesson's own "order" field — keep
      both consistent to avoid confusion)
   c. Publish
5. Create the Course:
   a. Set title, slug, description, thumbnail, difficulty
   b. Select category and instructor
   c. Add learning objectives
   d. Add chapters, in order
   e. Leave isPublished OFF while still drafting/reviewing
   f. Once ready for the public catalog: toggle isPublished ON
   g. Publish
```

**A critical ordering note:** because chapters reference lessons and courses reference chapters, Sanity's reference picker will only let you select *already-created* documents. This is why lessons must be authored before their chapter, and chapters before their course — attempting the reverse order simply means the reference field has nothing to select from yet, not a hard error, but worth doing in this order to avoid friction.
