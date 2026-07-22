# GreyMatter LMS — User Manual

**Document type:** End-User Manual
**Product:** GreyMatter LMS
**Audience:** Students, Instructors, Content Editors, Administrators
**Location:** `docs/USER_MANUAL.md`
**Companion documents:** `docs/PRD.md`, `docs/ARCHITECTURE.md`

---

## How to Use This Manual

This manual is written differently from the technical documentation elsewhere in `docs/`. Instead of describing the system feature-by-feature in the abstract, it follows **four realistic people** through their actual day-to-day use of GreyMatter LMS — a student, an instructor, a content editor, and an administrator. Every feature the platform offers appears somewhere in one of these journeys, in the order a real person would naturally encounter it, with screenshots-in-words, exact button labels, and practical tips.

If you want to look something up quickly rather than read a full journey, jump to **Section 6: Feature Quick Reference**, which indexes every feature back to the case study where it's demonstrated in context.

| Section | Covers |
|---|---|
| 1. Getting Started | Account creation, sign-in, for every role |
| 2. Case Study: The Student — Maria | Browsing, enrolling, learning, assessments, progress, certificates, notifications |
| 3. Case Study: The Instructor — Mr. Chen | Roster, analytics, at-risk students, reminders, exports |
| 4. Case Study: The Content Editor — Priya | Authoring courses, chapters, lessons, quizzes, publishing |
| 5. Case Study: The Administrator — Sam | Role management, platform oversight |
| 6. Feature Quick Reference | Alphabetical index of every feature |
| 7. Frequently Asked Questions | Common questions from every role |
| 8. Troubleshooting | What to do when something doesn't work as expected |

---

## 1. Getting Started

### 1.1 Creating an Account

Anyone can create a GreyMatter LMS account — no invitation is required to sign up as a student.

1. Visit the GreyMatter LMS homepage.
2. Click **Sign In** (top right, or in the hero section).
3. On the sign-in screen, click **Sign up** at the bottom.
4. Enter your email address and choose a password (or click **Continue with Google**, if enabled).
5. If prompted, check your email for a verification code and enter it.
6. You'll be redirected automatically to your **Dashboard** — your account now exists, and you've been signed in immediately.

> **What just happened behind the scenes:** the moment you completed sign-up, GreyMatter created an internal record for you and set your role to **Student** by default. Every account starts as a Student — Instructor and Administrator access is granted separately by an administrator (see Section 5).

### 1.2 Signing In (Returning Users)

1. Click **Sign In**.
2. Enter your email and password (or use your connected Google account).
3. You'll land on your Dashboard, exactly where you left off.

### 1.3 Managing Your Account

Click your avatar in the top-right corner of any authenticated page (the **user menu**) to:
- View or update your account details
- Change your password
- Sign out

This menu is the same regardless of your role — students, instructors, and administrators all use the identical account menu.

---

## 2. Case Study: The Student Journey — Maria

Maria is a marketing coordinator who wants to learn database fundamentals for a work project. She has never used GreyMatter LMS before. This case study follows her from the moment she discovers the platform through earning her first certificate.

### 2.1 Browsing the Course Catalog (No Account Needed)

Maria finds a link to GreyMatter LMS's course catalog shared by a colleague. She clicks it and lands on the **public course catalog** — no sign-in required at this stage.

She sees a grid of course cards, each showing:
- A thumbnail image
- A **difficulty badge** (Beginner / Intermediate / Advanced)
- A **category badge** (e.g., "Web Development")
- The course title and a short description
- The instructor's name

She finds **"Introduction to Databases,"** tagged **Beginner** under **Web Development**, and clicks it.

### 2.2 Viewing a Course Detail Page

The course detail page shows:
- A larger hero image, title, and full description
- A **"What you'll learn"** card listing learning objectives as a checklist
- A **"Course content"** outline: every chapter, listing every lesson inside it, with a green **"Free preview"** badge next to any lesson she can read without enrolling
- Since she's not signed in, a **"Sign in to enroll"** button instead of an active enroll button

She scrolls down and finds a full, real preview of the first lesson — **"What is a Database?"** — rendered right there on the public page, including a highlighted tip box. This lets her sample the actual teaching style before committing to an account.

> **Tip:** Free preview lessons are chosen by the instructor. Typically it's the very first lesson of a course, meant to give you a genuine feel for the material before you enroll.

### 2.3 Signing Up and Enrolling

Convinced, Maria clicks **"Sign in to enroll"**, which takes her to the sign-up flow (Section 1.1). After completing it, she's redirected to her empty Dashboard.

She navigates back to `/courses`, finds "Introduction to Databases" again, and this time sees a real **"Enroll — Free"** button. She clicks it.

- The button briefly shows **"Enrolling..."**
- Within a moment, she's automatically taken to her course dashboard page for this course
- If she somehow tried to click Enroll a second time on the same course, she'd see a message: *"You are already enrolled in this course"* — GreyMatter never creates a duplicate enrollment, no matter how many times the button is clicked

### 2.4 The Student Dashboard

Maria's Dashboard (`/dashboard`) now shows one course card: "Introduction to Databases," with a progress bar reading **0%**. If she had multiple courses enrolled, they'd all appear here as a grid, each with its own progress bar.

**On the left**, a persistent sidebar shows three links: **Overview**, **Achievements**, **Settings**. On a narrower screen (phone or small tablet), this sidebar collapses into a hamburger menu icon in the top bar instead.

**In the top bar**, she notices a bell icon (the **notification center**, covered in Section 2.9) and her account avatar.

She clicks the course card to enter it.

### 2.5 Navigating a Course

Inside the course, Maria sees:
- A left-hand panel listing every **chapter** as a section header, with every **lesson** underneath it, each marked with a small status icon: **○** (not started), **●** (in progress), or **✓** (completed, shown in green)
- The course thumbnail, title, and description
- A progress card showing her current completion percentage
- A **"Start learning →"** link (this will later read **"Resume learning →"** once she's visited a lesson)

She clicks **"Start learning."**

### 2.6 The Lesson Player

She's now on the actual lesson page for "What is a Database?" This is where most of her time in the platform will be spent. The page includes:

- The **outline panel** on the left (same as the course page, but now highlighting her current lesson in a solid color)
- The **lesson title**, with a green **"Free preview"** badge if applicable
- If the lesson has one, an **embedded video** (from YouTube or Vimeo)
- The actual **lesson content**: paragraphs, headings, images, and occasionally a highlighted **callout box** (a colored box with a tip, warning, or informational note)
- At the bottom, **Previous** and **Next lesson** buttons

She reads through the lesson and clicks **"Writing Your First Query →"** at the bottom.

### 2.7 Completing an Interactive Quiz

The second lesson contains a real, interactive **multiple-choice quiz**:

> *"Which SQL keyword retrieves rows from a table?"*
> ○ SELECT ○ INSERT ○ DELETE ○ UPDATE

Maria selects **INSERT** (guessing) and clicks **"Submit answer."** The button briefly reads **"Checking..."**, then a red box appears: *"Not quite — review below."* The options remain selectable, so she tries again — this time selecting **SELECT** — and clicks Submit again. A green box appears: **"Correct!"** — and the answer options now lock, showing her final, correct choice.

> **Important to understand:** every quiz answer is checked by GreyMatter's own server, not by your browser. There is no way to "trick" the page into showing a correct answer for a wrong response — the grading happens somewhere Maria's browser cannot see or influence. If she refreshes the page, her correct, locked-in answer is still shown exactly as she left it.

> **Note on attempts:** each interactive module allows a limited number of attempts (five, by default). If Maria exhausted her attempts without answering correctly, she'd see a message explaining the limit has been reached for that specific exercise.

### 2.8 Other Interactive Module Types

As Maria continues through the course, she encounters other kinds of interactive content, each behaving a little differently:

- **Code/short-answer exercises:** a text box (sometimes pre-filled with starter code) where she types a response — for example, writing a basic SQL query. Clicking **Submit** grades her answer based on whether it contains the expected key elements, even if her exact wording differs from a model answer.
- **Reflection prompts:** an open-ended text box with no "correct" answer — she's simply asked to write a short response (e.g., *"What surprised you about SQL syntax so far?"*). A live word counter shows her how much she's written against a suggested minimum. Clicking **"Save response"** always succeeds — there's no pass/fail here, just a permanent record that she engaged with the prompt.
- **Completion checkpoints:** a simple button, often labeled something like *"I've written my first query,"* that she clicks to mark a specific task as done. Once clicked, it becomes a disabled **"✓ Done"** state.

Maria completes every interactive element across both lessons in the course.

### 2.9 Progress, Resuming, and Notifications

A short while after her last quiz submission, Maria checks her course page again and notices her progress bar has updated to **100%** — GreyMatter recalculates this automatically in the background every time she completes something; she never needs to manually refresh or trigger a recalculation herself.

If Maria had stopped partway through and come back a day later, her course dashboard page would show **"Resume learning →"** instead of "Start learning," taking her directly back to the exact lesson she'd last opened — not the beginning of the course.

**If Maria goes quiet for a while** (doesn't visit an active, incomplete course for about a week), she'll automatically receive a friendly reminder email, and a matching entry will appear in her in-app **notification bell** — but only once per week at most, and never for a course she's already finished or opted out of reminders for.

She can also expect an occasional **weekly progress digest** email summarizing her status across every course she's enrolled in, if she has more than one active at a time.

**Managing notification preferences:** Maria visits **Dashboard → Settings**, where she finds two toggles:
- **Inactivity reminders** — on by default
- **Weekly progress digest** — on by default

She can switch either off at any time; the change takes effect immediately.

**Checking notification history:** clicking the bell icon in the top bar opens a dropdown showing every notification she's ever received, most recent first, with unread ones highlighted. Opening the dropdown automatically marks them as read.

### 2.10 Earning and Downloading Her Certificate

The moment Maria's course reaches 100% completion, GreyMatter automatically:
1. Issues her a certificate, with a unique certificate number (e.g., `GM-2025-000001`)
2. Sends her a congratulatory email
3. Makes the certificate available in her dashboard — no request or manual action needed on her part

She visits **Dashboard → Achievements** and sees a card for "Introduction to Databases," showing a green **"Completed"** badge, her certificate number, the issue date, and a **"Download PDF"** button. She clicks it, and a real PDF downloads — a formatted certificate showing her email address, the course title, her certificate number, and the date, inside a bordered design.

She also notices a **"🎓 Download your certificate"** button now appears directly on the course's own dashboard page, as a shortcut.

> **What if Maria enrolls in the same course twice, or the completion event somehow fires twice?** GreyMatter guarantees she will only ever receive **one** certificate per course, permanently — this is enforced at the database level, not just by careful coding, so it holds even under unusual timing conditions.

### 2.11 Summary of Every Student Feature Demonstrated

| Feature | Where in this case study |
|---|---|
| Public catalog browsing | 2.1 |
| Course detail page + free preview | 2.2 |
| Account creation | 2.3 |
| Enrollment (with duplicate protection) | 2.3 |
| Dashboard course list | 2.4 |
| Responsive sidebar / mobile navigation | 2.4 |
| Course outline navigation | 2.5 |
| Lesson player, video, rich content, callouts | 2.6 |
| Multiple-choice quiz (server-graded) | 2.7 |
| Code/short-answer exercise | 2.8 |
| Reflection prompt | 2.8 |
| Completion checkpoint | 2.8 |
| Automatic progress recalculation | 2.9 |
| Resume-learning | 2.9 |
| Inactivity reminders | 2.9 |
| Weekly digest | 2.9 |
| Notification preferences | 2.9 |
| In-app notification center | 2.9 |
| Automatic certificate issuance | 2.10 |
| Certificate PDF download | 2.10 |

---

## 3. Case Study: The Instructor Journey — Mr. Chen

Mr. Chen is the instructor of record for "Introduction to Databases." An administrator has already linked his account to the Instructor role and his Sanity instructor profile (see Section 5). This case study follows him checking in on his course a few weeks after launch.

### 3.1 Accessing the Instructor Dashboard

Mr. Chen signs in normally, the same way any student would. Instead of navigating to `/dashboard`, he visits `/instructor` directly (a link his administrator gave him; a future version of the platform may surface this link more prominently for confirmed instructors).

He sees a minimal instructor-specific header reading **"GreyMatter Instructor,"** and below it, a list of every course linked to his instructor profile — in his case, one card: **"Introduction to Databases,"** with a green **"Published"** badge.

> **Note:** if Mr. Chen tried to visit this page without being an instructor, he'd be redirected straight back to the regular student dashboard, without any error message explaining why — instructor tools are simply invisible to non-instructors.

He clicks the course card.

### 3.2 The Course Overview

The course overview page shows a single, prominent number: **Enrolled students** — currently showing a real count of everyone enrolled in his course (Maria among them). Below it, two buttons: **"View students"** and **"View analytics."**

### 3.3 The Student Roster

Clicking **"View students"** shows a table:

| Email | Status | Progress | Enrolled |
|---|---|---|---|
| maria@example.com | COMPLETED | ▓▓▓▓▓▓▓▓▓▓ 100% | Jan 3, 2025 |
| ... | ACTIVE | ▓▓▓░░░░░░░ 30% | Jan 10, 2025 |

Each row shows the student's email, their enrollment status, a live progress bar, and their enrollment date. If Mr. Chen's course has many students, the table paginates — he sees **"Page 1 of 3 (47 total)"** at the bottom, with **Previous/Next** buttons.

He clicks **"Export CSV"** in the top right, and a spreadsheet-ready `.csv` file downloads containing every student's email, status, completion percentage, and enrollment date — useful for his own records or reporting outside the platform.

### 3.4 Course Analytics

Mr. Chen navigates back and clicks **"View analytics"** instead. Three sections appear:

**Lesson completion funnel** — a list of every lesson in the course, each showing how many students have completed it:

```
What is a Database?         42 completed
Writing Your First Query    31 completed
```

This immediately tells him something useful: eleven students completed the first lesson but never finished the second — a real signal that something in "Writing Your First Query" might need attention (perhaps the quiz is too difficult, or the lesson is too long).

**Average scores by module** — every quiz/exercise `moduleId`, with its average score and how many attempts have been made:

```
first-query-quiz    78% avg (52 attempts)
```

**At-risk students** — a list of students who are enrolled, under 50% complete, and haven't visited the course in three or more days:

```
alex@example.com   22% — inactive since Jan 15, 2025   [Send reminder]
```

### 3.5 Sending a Manual Reminder

Mr. Chen notices one at-risk student, Alex, who hasn't returned in over a week. Rather than waiting for the platform's own automatic weekly reminder cycle, he clicks **"Send reminder"** next to Alex's name.

The button changes to **"Sending..."** and then **"Sent ✓."** Alex will receive a personal-feeling reminder email referencing the specific course, and a matching notification will appear in Alex's in-app notification center — recorded distinctly from GreyMatter's own automated reminders, so if Alex or an administrator ever reviewed this history, it would be clear this particular reminder was instructor-initiated.

### 3.6 Summary of Every Instructor Feature Demonstrated

| Feature | Where in this case study |
|---|---|
| Instructor-only dashboard access | 3.1 |
| Owned-course list | 3.1 |
| Enrollment count | 3.2 |
| Paginated student roster | 3.3 |
| CSV export | 3.3 |
| Lesson completion funnel | 3.4 |
| Average scores by module | 3.4 |
| At-risk student detection | 3.4 |
| Manual reminder trigger | 3.5 |

---

## 4. Case Study: The Content Editor Journey — Priya

Priya is a subject-matter expert brought in to author a brand-new course, "Web Accessibility Fundamentals." She has no engineering background and has been given access to Sanity Studio, the platform's content-authoring tool, entirely separate from the main student/instructor application.

### 4.1 Accessing Studio

Priya visits `/studio` on the platform's domain and signs in with her Sanity account credentials (set up for her in advance). She lands on Studio's main screen — a document list on the left, organized by content type: **Course**, **Category**, **Instructor**, **Chapter**, **Lesson**.

> **Note:** Studio is a completely separate authoring interface from the student/instructor dashboard — nothing Priya does here requires any involvement from engineering, and nothing she does here goes live to real students until she explicitly publishes it.

### 4.2 Authoring Prerequisites: Category and Instructor Profile

Before creating her course, Priya checks whether a suitable **Category** already exists (e.g., "Web Development"). If not, she clicks **Category → Create**, fills in a title, clicks **"Generate"** next to the slug field to auto-create a URL-friendly identifier, and clicks **Publish**.

She does the same for her own **Instructor** profile if one doesn't already exist: name, a short bio, a professional title, and a profile photo (uploaded via drag-and-drop, with a **hotspot** tool letting her choose which part of the photo stays visible when it's cropped to different shapes).

### 4.3 Authoring Lessons

Priya creates her lessons **before** the chapter that will contain them, since a chapter needs existing lessons to reference.

She clicks **Lesson → Create**:
- **Title:** "Why Accessibility Matters"
- **Slug:** generated automatically from the title
- **Order:** `1`
- **Available as free preview:** she toggles this **on**, since she wants this specific lesson visible to anyone browsing the public catalog, even without enrolling
- **Video URL:** she pastes a YouTube link — GreyMatter will safely embed it, but only because it recognizes it as a trusted YouTube URL specifically
- **Content:** she starts typing directly into the content editor, formatting text with **Bold**, *Italic*, headings, and bullet lists using a familiar toolbar

Partway through, she wants to highlight an important point. She clicks the **"+"** button within the content area and selects **Callout**, choosing the "Tip" tone, and types her note. It renders inline as a colored highlight box, exactly where she inserted it — not appended awkwardly to the end of the lesson.

Further down, she inserts a **Quiz** block:
- **Module ID:** she types a short, permanent identifier, `a11y-quiz-1` (she's told this should never be changed later, since renaming it would disconnect students' past attempts from this exercise)
- **Question:** "Which HTML attribute provides alternative text for an image?"
- **Answer options:** `alt`, `title`, `src`, `href`
- **Correct option (index):** she carefully selects the option corresponding to `alt` — the *position* in the list (starting from zero), not the text itself

> **A safeguard she notices:** if she accidentally set the correct answer to point at a position beyond the number of options she'd typed, Studio would refuse to let her publish, showing a validation error explaining exactly what's wrong — before any student ever sees a broken quiz.

She also inserts a **Reflection** block (an open-ended prompt with no right answer) and a **Completion Checkpoint** (a simple "mark as done" button with a custom label she writes herself), each with their own unique Module ID.

Once satisfied, she clicks **Publish**.

She repeats this process for a second lesson, "Writing Semantic HTML," leaving "Available as free preview" turned **off** this time, since only the first lesson should be publicly readable without enrollment.

### 4.4 Authoring the Chapter

She clicks **Chapter → Create**:
- **Title:** "Getting Started with Accessibility"
- **Order:** `1`
- **Lessons:** she adds both lessons she just created, in the exact order she wants them to appear

She clicks **Publish**.

### 4.5 Authoring the Course

Finally, she clicks **Course → Create**:
- **Title:** "Web Accessibility Fundamentals"
- **Slug:** generated automatically
- **Description:** a few sentences summarizing the course
- **Thumbnail:** she uploads a cover image
- **Difficulty:** she selects **Beginner** from the radio options
- **Category:** she selects the "Web Development" category she confirmed earlier
- **Instructor:** she selects her own instructor profile
- **Learning objectives:** she adds three short bullet points
- **Chapters:** she adds the chapter she just created

Critically, she leaves **Published** **unchecked** for now — she wants a colleague to review it first before it appears in the public catalog.

She clicks **Publish** (this publishes the *document* in Sanity's own sense, making it reviewable and previewable — it does **not** yet make it appear on the public course catalog, because of the still-unchecked "Published" box).

> **Understanding the two different meanings of "published," precisely:** Sanity's own Publish button (used constantly throughout Studio) simply means "save this as the live, current version of this document, replacing whatever draft existed before." GreyMatter's own **"Published"** checkbox on the Course document specifically controls whether it shows up in the *public catalog* real students browse. A course can be fully "Published" in Sanity's sense — reviewable, linkable internally — while its own "Published" checkbox remains off, keeping it hidden from the actual student-facing catalog until Priya's colleague signs off.

### 4.6 Reviewing Before Launch

Priya shares a direct Studio link with her colleague, who reviews the course, checks each lesson's content and quiz answer keys, and gives the go-ahead. Priya returns to the Course document, checks the **Published** box, and clicks **Publish** one final time.

Within about a minute, "Web Accessibility Fundamentals" appears in the public course catalog for any visitor to discover — no engineering deployment, no code change, nothing beyond Priya's own actions inside Studio.

### 4.7 Summary of Every Content Editor Feature Demonstrated

| Feature | Where in this case study |
|---|---|
| Embedded Studio access | 4.1 |
| Category and Instructor authoring | 4.2 |
| Lesson authoring: rich text, headings, lists | 4.3 |
| Free-preview designation | 4.3 |
| Video embed (allow-listed providers) | 4.3 |
| Callout blocks | 4.3 |
| Quiz block authoring, with author-time validation | 4.3 |
| Reflection and Checkpoint block authoring | 4.3 |
| Chapter authoring and lesson ordering | 4.4 |
| Course authoring: metadata, category, instructor, objectives | 4.5 |
| Draft/publish workflow and internal preview before public launch | 4.5–4.6 |

---

## 5. Case Study: The Administrator Journey — Sam

Sam is responsible for platform governance. This journey is intentionally shorter, since dedicated administrative tooling is a documented, deliberate gap in the current release (see `docs/ARCHITECTURE.md`, Section 11) — the *capability* exists, but not yet a polished interface for every administrative task.

### 5.1 Promoting a User to Instructor

When Mr. Chen needed instructor access (Section 3), Sam performed this as a manual, one-time operational step rather than through a self-service screen:

1. Sam confirms Mr. Chen's account already exists (he signed up normally, like any student, first).
2. Using a small internal script provided to administrators, Sam updates Mr. Chen's role from `STUDENT` to `INSTRUCTOR`, referencing his account email.
3. Separately, in Sanity Studio, Sam (or Priya, acting as a content editor) opens Mr. Chen's **Instructor** profile document and sets its **"Linked user ID"** field to Mr. Chen's internal account identifier — this is what connects his platform login to the specific course(s) authored under his instructor profile.
4. Mr. Chen signs out and back in; his account now has full access to `/instructor`.

> **Why this is manual today:** role promotion is a rare, high-consequence action. The underlying permission check (restricting access to genuine administrators) is fully built and enforced; only the convenience layer — a polished screen for performing this without running a script — is deferred to a future release.

### 5.2 What Administrators Can Expect in a Future Release

Documented, planned, but not yet built as of this release:
- A dedicated screen for browsing and changing any user's role, without needing script access
- Platform-wide visibility into every enrollment and completion, across every instructor's courses
- Visibility into background workflow health (e.g., a failed certificate issuance) with the ability to retry it directly from the interface

---

## 6. Feature Quick Reference

An alphabetical index of every feature, with the role it applies to and where it's demonstrated.

| Feature | Role | Case study reference |
|---|---|---|
| Account creation / sign-up | All | §1.1 |
| Achievements page (certificate list) | Student | §2.10 |
| At-risk student detection | Instructor | §3.4 |
| Callout boxes (tips/warnings in lessons) | Student (reader), Content Editor (author) | §2.6, §4.3 |
| Certificate — automatic issuance | Student | §2.10 |
| Certificate — PDF download | Student | §2.10 |
| Chapter authoring | Content Editor | §4.4 |
| Checkpoint modules | Student, Content Editor | §2.8, §4.3 |
| Code/short-answer exercises | Student, Content Editor | §2.8, §4.3 |
| Course authoring | Content Editor | §4.5 |
| Course catalog (public) | Anyone | §2.1 |
| Course detail page (public) | Anyone | §2.2 |
| CSV roster export | Instructor | §3.3 |
| Draft vs. published content | Content Editor | §4.5–4.6 |
| Enrollment | Student | §2.3 |
| Lesson authoring | Content Editor | §4.3 |
| Lesson completion funnel | Instructor | §3.4 |
| Lesson player | Student | §2.6 |
| Manual reminder | Instructor | §3.5 |
| Module average scores | Instructor | §3.4 |
| Notification center (in-app) | Student | §2.9 |
| Notification preferences | Student | §2.9 |
| Previous/Next lesson navigation | Student | §2.6 |
| Progress bar / completion tracking | Student | §2.9 |
| Quiz modules | Student, Content Editor | §2.7, §4.3 |
| Reflection modules | Student, Content Editor | §2.8, §4.3 |
| Reminder emails (automatic, inactivity) | Student | §2.9 |
| Resume learning | Student | §2.9 |
| Role promotion | Administrator | §5.1 |
| Sign-in | All | §1.2 |
| Student roster (paginated) | Instructor | §3.3 |
| Video embeds | Student, Content Editor | §2.6, §4.3 |
| Weekly progress digest | Student | §2.9 |

---

## 7. Frequently Asked Questions

**Q: I clicked "Enroll" twice by accident. Do I have two enrollments now?**
No. GreyMatter guarantees exactly one enrollment per student per course, no matter how many times you click. The second attempt simply shows a message letting you know you're already enrolled.

**Q: Can I go back and change a quiz answer after I got it right?**
No — once you've answered a question correctly, the options lock to prevent accidental changes. If you answered incorrectly, you can try again (up to a limited number of attempts).

**Q: Why did my quiz say "Checking..." for a moment before showing the result?**
Every answer is verified by the server, not your browser — that brief "Checking..." message reflects the real time it takes to confirm your answer against the actual answer key, which never leaves the server.

**Q: I finished every lesson, but I don't see a certificate yet. What's wrong?**
Certificate issuance runs as a background process immediately after your last completed lesson, typically finishing within moments. If it's been more than a few minutes and your course dashboard still doesn't show 100%, refresh the page — progress recalculation is also a very fast background step, but occasionally a page needs a manual refresh to reflect the very latest state.

**Q: Can I retake a course after completing it?**
Your progress and certificate remain permanently recorded. Revisiting lessons is always possible, but a second certificate for the same course will not be issued — one certificate per course, per student, is permanent.

**Q: I unsubscribed from reminders. Will I still get my weekly digest?**
No — these are two independent toggles in Settings. Turning off inactivity reminders does not affect your weekly digest, and vice versa; toggle each one individually based on your preference.

**Q: As an instructor, can I see students enrolled in courses I don't own?**
No. Instructor tools are scoped strictly to courses your instructor profile is linked to — attempting to view another instructor's course data (even by guessing a URL) will show the same "not found" result as a genuinely nonexistent course.

**Q: As a content editor, can my changes accidentally go live to students immediately?**
Only if you check the course's **"Published"** box and click Sanity's own **Publish** button. Both conditions must be true. Saving or publishing individual lessons/chapters without ever checking the parent course's "Published" box keeps everything invisible to the public catalog, letting you draft and review freely.

---

## 8. Troubleshooting for End Users

| Symptom | What to try |
|---|---|
| A course I just enrolled in doesn't show on my dashboard | Refresh the page. If it still doesn't appear after a minute, try signing out and back in. |
| My quiz answer shows as wrong, but I'm sure it's right | Double-check you selected exactly the option you intended before submitting — once submitted, the specific answer you chose is what's graded, not your later intention. If you believe there's a genuine error in the question itself, contact your instructor. |
| I can't access `/instructor` even though I was told I'm an instructor | Sign out completely and sign back in — role changes take effect on your next sign-in, not instantly mid-session. If it still doesn't work, confirm with your administrator that both your role and your Sanity instructor profile link were set correctly. |
| My certificate PDF won't open | Confirm your device has a PDF viewer installed; try downloading again, or try a different browser. |
| I stopped getting reminder emails | Check Dashboard → Settings — you (or someone with account access) may have turned off that specific preference. Also check your email provider's spam folder. |
| A video embedded in a lesson won't play | Only YouTube and Vimeo videos are supported; if a lesson's video doesn't load, it may use an unsupported provider — report this to your instructor or content editor. |
| I see "Course not found" for a course I know exists | This message also appears if you're not currently enrolled, or if the course has been unpublished. Confirm your enrollment status from your dashboard, and try enrolling again if needed. |
