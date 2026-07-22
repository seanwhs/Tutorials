# Primer 02 — Asynchronous JavaScript

## Why this primer exists

Open almost any file in GreyMatter LMS and you'll find the word `async` within the first few lines. Server Components `await` Sanity and Neon directly. Server Actions are declared `async`. Inngest functions `await` every `step.run(...)`. If asynchronous JavaScript feels like something you "sort of get" — you've used `.then()` before, or copy-pasted an `await` without fully understanding why it was there — this primer closes that gap properly, from first principles, before you meet it at scale in Part 1 onward.

**You can safely skip this primer if** you're already comfortable with: what a Promise represents, how `async`/`await` relates to Promises, how errors propagate through `async` functions, and why `Promise.all` exists. If any of those feel uncertain, keep reading.

---

## The core problem: some things take time

Ordinary JavaScript code runs top to bottom, each line finishing before the next begins:

```js
console.log("A");
console.log("B");
console.log("C");
// Always prints: A, B, C — in that exact order, every time
```

But some operations don't finish instantly — reading a file from disk, requesting data from a database across the network, waiting for a user to click a button. JavaScript can't simply *pause* the entire program while waiting for these — that would freeze your whole application (imagine a website that couldn't scroll or respond to any click while one image was still loading). Instead, JavaScript hands off slow operations to be completed **later**, and continues running other code in the meantime.

**Analogy:** Think of a restaurant kitchen. A cook doesn't stand motionless staring at the oven for the fifteen minutes bread takes to bake — they put the bread in, set a timer, and immediately start chopping vegetables for a different order. When the timer goes off, they come back and take the bread out. The "timer going off" is a Promise resolving; the cook checking back later is the `await`.

---

## The Promise: a receipt for something that isn't ready yet

A **Promise** is an object representing a value that doesn't exist *yet*, but will exist (or definitively fail to exist) at some point in the future. It's not the value itself — it's a stand-in, a receipt, that will eventually be exchanged for the real thing.

```js
function orderCoffee() {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      const success = true;
      if (success) {
        resolve("Here is your coffee ☕");
      } else {
        reject(new Error("Out of coffee beans"));
      }
    }, 2000); // simulates a 2-second wait
  });
}

const coffeePromise = orderCoffee();
console.log(coffeePromise); // Promise { <pending> } — not the coffee itself yet!
```

Every Promise exists in exactly one of three states at any moment:

```text
┌─────────────┐      succeeds       ┌───────────┐
│   pending    │ ──────────────────► │ fulfilled  │  (resolve() was called)
│ (in progress)│                     └───────────┘
│              │        fails        ┌───────────┐
│              │ ──────────────────► │  rejected  │  (reject() was called)
└─────────────┘                     └───────────┘
```

Once a Promise settles (fulfilled or rejected), it **never changes state again** — a Promise that's already fulfilled can't later become rejected, or vice versa. This permanence is important: it means you can safely hand a Promise to other code, and that code can trust the eventual outcome won't shift underneath it.

### Getting the value out: `.then()` and `.catch()`

Before `async`/`await` existed (and still valid today, just less common in this series), you'd extract a Promise's eventual value like this:

```js
orderCoffee()
  .then((result) => {
    console.log(result); // "Here is your coffee ☕" — only runs after 2 seconds
  })
  .catch((error) => {
    console.error(error.message); // only runs if the Promise was rejected
  });

console.log("This prints FIRST, immediately, before the coffee is ready");
```

This is genuinely important to internalize: `console.log("This prints FIRST...")` really does print *before* the coffee log line, even though it appears *after* it in the source code. The `.then()` callback is scheduled to run only once the Promise settles — everything else in the program keeps running in the meantime.

---

## `async`/`await`: the same thing, written to *look* synchronous

`.then()` chains work, but they get awkward fast, especially when one asynchronous step depends on the result of a previous one (a "callback pyramid"). `async`/`await` is syntax that lets you write asynchronous code that *reads* top-to-bottom, like ordinary synchronous code, while still behaving exactly like the Promise-based version underneath.

```js
async function getMyCoffee() {
  console.log("Ordering...");
  const result = await orderCoffee(); // PAUSES this function (and only this
                                        // function) until the Promise settles
  console.log(result); // only runs after the Promise resolves
  return result;
}

getMyCoffee();
console.log("This still prints FIRST"); // the rest of the program keeps going
```

Two rules to hold onto permanently:

1. **`await` can only be used inside a function marked `async`.** You cannot sprinkle `await` into a regular function.
2. **`await` only pauses the function it's inside — never the whole program.** Other code (other requests, other event handlers) continues running while an `async` function is paused at an `await`.

**Every `async` function itself returns a Promise**, automatically, even if you don't explicitly write `return new Promise(...)`:

```js
async function getFive() {
  return 5;
}

getFive(); // Promise { 5 } — NOT the number 5 directly!

async function useIt() {
  const value = await getFive(); // NOW you get the actual number 5
  console.log(value); // 5
}
```

This single fact — *an `async` function's return value is always wrapped in a Promise* — is exactly why Part 1's health-check route looks like this:

```ts
export async function GET() {
  const info = getAppInfo();
  return NextResponse.json({ status: "ok", ...info });
}
```

Next.js knows this function returns a `Promise<Response>` (even though the code just says `return NextResponse.json(...)`), and it correctly waits for that Promise to settle before sending anything to the browser.

---

## Error handling: `try`/`catch` around `await`

When a Promise rejects, the `await` expression that was waiting on it **throws** — exactly like a synchronous `throw`. This means ordinary `try`/`catch` works for asynchronous code too, once you're using `await`:

```js
async function getMyCoffeeSafely() {
  try {
    const result = await orderCoffee();
    console.log(result);
  } catch (error) {
    console.error("Something went wrong:", error.message);
  }
}
```

Without the `try`/`catch`, a rejected Promise inside an `async` function becomes an **unhandled rejection** — in a browser, this shows up as a red error in the console; in a Node.js server (like our Next.js backend), an unhandled rejection can, in some configurations, crash the entire process. This is exactly why every Server Action in GreyMatter LMS wraps its risky operations — database writes, external API calls — in `try`/`catch`, returning a structured, safe result instead of letting an error escape unhandled:

```ts
// From Part 8's enrollInCourse — notice the try/catch specifically
// wraps the one operation genuinely capable of throwing (the database
// write), converting a possible rejection into a safe, structured
// return value the calling UI can handle predictably.
try {
  await createEnrollmentWithProgress({ userId: user.id, courseId });
} catch (error) {
  console.error("Enrollment creation failed:", error);
  return { success: false, error: "Something went wrong. Please try again." };
}
```

---

## Running multiple asynchronous operations: sequential vs. concurrent

This is one of the most consequential distinctions in the entire primer, and it appears constantly in the main series' database and Sanity queries.

### Sequential — one `await` after another

```js
async function sequential() {
  const a = await fetchThingA(); // waits for A to fully finish...
  const b = await fetchThingB(); // ...before even STARTING B
  return [a, b];
}
```

If `fetchThingA` takes 200ms and `fetchThingB` takes 300ms, this takes **500ms total** — B doesn't even begin until A is completely done, even though B has nothing to do with A's result.

### Concurrent — starting multiple operations at once with `Promise.all`

```js
async function concurrent() {
  const [a, b] = await Promise.all([fetchThingA(), fetchThingB()]);
  return [a, b];
}
```

Here, both `fetchThingA()` and `fetchThingB()` are **started at the same moment** — neither waits for the other. `Promise.all` then waits for *both* to finish, and gives you back an array of their results, in the same order you passed them in. Total time: roughly **300ms** (however long the *slower* of the two takes), not 500ms.

```text
Sequential:                          Concurrent (Promise.all):
  0ms ─── fetch A starts               0ms ─── fetch A starts
  200ms ─ fetch A done                 0ms ─── fetch B ALSO starts (same moment)
  200ms ─ fetch B starts               200ms ─ fetch A done
  500ms ─ fetch B done                 300ms ─ fetch B done — Promise.all resolves
  ─────────────────────                ─────────────────────
  Total: 500ms                         Total: ~300ms
```

**This is exactly why Part 7's `getEnrolledCourses` function is written the way it is:**

```ts
const [userEnrollments, userProgress] = await Promise.all([
  findActiveEnrollmentsForUser(userId),
  findCourseProgressForUser(userId),
]);
```

Neither of these two Neon queries depends on the other's result — there's no reason to make the second one wait for the first to finish. `Promise.all` runs them concurrently, and the comment in the actual source code says exactly this: *"this small habit compounds into meaningful speed savings once dashboards involve many concurrent queries."*

### When you must use sequential `await`, not `Promise.all`

Sequential awaiting is *required*, not just simpler, whenever one operation genuinely needs the *result* of a previous one:

```js
// This MUST be sequential — you can't fetch the course's chapters
// before you know which course you're even looking at.
const course = await fetchCourse(courseId);
const chapters = await fetchChapters(course.chapterIds); // needs `course` first
```

You'll see exactly this reasoning in Part 4's course detail page — the preview lesson query only runs *after* the course query has resolved and told us which lesson (if any) is the preview lesson:

```ts
const course = await client.fetch<CourseDetail | null>(courseDetailQuery, { slug: courseSlug });
if (!course) notFound();

const previewLessonSummary = course.chapters
  .flatMap((chapter) => chapter.lessons)
  .find((lesson) => lesson.isPreview);

// This second fetch NEEDS the result of the first — it can't run concurrently
const previewLesson = previewLessonSummary
  ? await client.fetch<LessonPreviewContent | null>(previewLessonQuery, { lessonSlug: previewLessonSummary.slug.current })
  : null;
```

**The decision rule, distilled:** if operation B needs a value that only exists after operation A finishes, they must be sequential. If B doesn't need anything from A, run them concurrently with `Promise.all` — it's free performance you'd otherwise be leaving on the table.

---

## `fetch()` — the browser and Node's built-in way to make network requests

`fetch()` is a built-in function (available in browsers and, since a few years ago, in Node.js directly) that makes an HTTP request and returns a Promise. It's the foundation underneath Sanity's client, and it's what GreyMatter's own `HealthCheckButton` uses directly:

```tsx
async function handleClick() {
  setIsLoading(true);
  try {
    const response = await fetch("/api/health"); // sends the request, waits for a response
    const data = await response.json(); // parses the response BODY — this is ALSO async
    setResult(`✅ ${data.status}`);
  } catch {
    setResult("❌ Could not reach the health check endpoint.");
  } finally {
    setIsLoading(false);
  }
}
```

Notice **two separate `await`s** here — this trips people up the first time. `fetch()` resolves as soon as the response's *headers* arrive (enough to know the status code), but the actual response *body* (the JSON content) is a separate stream that must be awaited independently via `.json()`. This two-step shape (`await fetch(...)` then `await response.json()`) is worth memorizing as a fixed pattern, since it appears identically almost everywhere `fetch` is used.

Also notice the `finally` block: code inside `finally` runs regardless of whether the `try` block succeeded or the `catch` block ran — exactly the right place for "stop the loading spinner," since you want that to happen whether the request succeeded or failed.

---

## Why Server Components can `await` directly, and why this is a genuinely different pattern

If you've only ever written asynchronous *client-side* JavaScript (a button's click handler, a `useEffect`), Part 1's Server Components will look unusual at first:

```tsx
// A Server Component — notice the component function ITSELF is async
export default async function HomePage() {
  const info = getAppInfo(); // synchronous, no await needed here
  // ...
}
```

```tsx
// From Part 4 — a Server Component directly awaiting a database-like call
export default async function CourseCatalogPage() {
  const courses = await client.fetch<CourseCard[]>(courseCatalogQuery);
  return (/* JSX using `courses` directly, already resolved */);
}
```

In ordinary client-side React, you cannot make a component function itself `async` — React doesn't know what to do with a component that returns a Promise instead of JSX, so this pattern is traditionally handled with `useEffect` + `useState` (fetch in an effect, store the result in state, re-render once it arrives).

**Server Components genuinely can be `async` functions**, because they run once, on the server, before any HTML is sent to the browser at all. There's no "re-render" concept to worry about the way there is in the browser — the function runs top to bottom exactly once per request, `await`s whatever it needs, and then produces final, already-resolved HTML. This is precisely why Part 1 emphasized: *"a Server Component fetches the data and renders finished HTML in one motion, the same way a librarian who already has the requested book in hand simply hands it to you."*

This is a genuinely different asynchronous pattern than what you may have used before in plain React — worth sitting with until it feels natural, since nearly every page in Parts 4 through 15 is built this way.

---

## `Promise.allSettled` — when you want every result, even the failures

`Promise.all` has an important, easy-to-miss behavior: **if any single Promise in the array rejects, the entire `Promise.all` immediately rejects too** — you lose access to whichever other results *did* succeed.

```js
try {
  const results = await Promise.all([taskThatSucceeds(), taskThatFails()]);
} catch (error) {
  // You end up HERE, and you have NO idea if taskThatSucceeds() actually
  // succeeded — Promise.all doesn't give you partial results on failure.
}
```

`Promise.allSettled` fixes this — it always resolves (never rejects), giving you back an array describing the outcome of *every* Promise, whether it succeeded or failed:

```js
const results = await Promise.allSettled([taskThatSucceeds(), taskThatFails()]);

results.forEach((result, index) => {
  if (result.status === "fulfilled") {
    console.log(`Task ${index}: succeeded with`, result.value);
  } else {
    console.log(`Task ${index}: failed with`, result.reason);
  }
});
```

This is exactly the tool Part 8's concurrent-enrollment test script uses to prove the database's unique constraint works correctly under real concurrent load:

```ts
// Deliberately fires TWO enrollment attempts at nearly the same instant.
// Promise.allSettled is used SPECIFICALLY because we EXPECT one of these
// to fail (the duplicate), and we want to inspect BOTH outcomes, not
// have the whole script crash the moment the failing one rejects.
const results = await Promise.allSettled([
  createEnrollmentWithProgress({ userId: user.id, courseId: SAMPLE_COURSE_ID }),
  createEnrollmentWithProgress({ userId: user.id, courseId: SAMPLE_COURSE_ID }),
]);
```

**The decision rule:** use `Promise.all` when every operation genuinely *must* succeed for the overall result to make sense (fetching two pieces of data you'll display together — if one fails, showing half a page is meaningless anyway). Use `Promise.allSettled` when you specifically expect, or want to tolerate, some operations failing independently of others.

---

## A note on `void` and "fire-and-forget"

Occasionally in the series, you'll see an `async` function called *without* an `await` in front of it, sometimes preceded by the `void` keyword:

```ts
// From Part 9's lesson player:
void markLessonVisited(course._id, lesson._id);
```

This is a deliberate choice, not a mistake: we genuinely don't want to wait for `markLessonVisited` to finish before rendering the page — it's bookkeeping that should never delay or block the student from reading the lesson. The `void` keyword is purely a readability signal to future readers (including future you): "I am intentionally not awaiting this Promise; this is fire-and-forget, not an accidentally-missing `await`." It has no runtime effect on its own — the function call would behave identically without `void` — but it makes the *intent* unambiguous at a glance, which matters a great deal when someone else (or you, months later) is scanning the code trying to figure out if a missing `await` is a bug or a deliberate choice.

---

## Putting it all together: reading a real function from the series

```ts
export async function getEnrolledCourses(userId: string): Promise<EnrolledCourseSummary[]> {
  const [userEnrollments, userProgress] = await Promise.all([
    findActiveEnrollmentsForUser(userId),
    findCourseProgressForUser(userId),
  ]); // ← concurrent, since neither query depends on the other's result

  if (userEnrollments.length === 0) {
    return []; // ← an async function can `return` a plain value directly;
                //   TypeScript/JS automatically wraps it in a resolved Promise
  }

  const courseIds = userEnrollments.map((enrollment) => enrollment.courseId);

  const courses = await client.fetch<CourseTitleLookup[]>(coursesByIdsQuery, {
    ids: courseIds,
  }); // ← sequential relative to the block above, because this query
      //   genuinely needs courseIds, which only exists after the first
      //   Promise.all resolved

  // ... merge logic, no more awaiting needed ...
}
```

If every line of that function's asynchronous structure now makes sense — why some calls are grouped in `Promise.all` and others aren't, why an early `return []` inside an `async` function is perfectly normal — you're ready for Part 1.

---

## You're ready for Part 1 if you can answer these

1. What are the three states a Promise can be in, and why can a Promise never move backward between them (e.g., from fulfilled back to pending)?
2. Why does `await` pause only the function it's inside, rather than the entire program?
3. If `fetchA()` and `fetchB()` don't depend on each other's results, why is `Promise.all([fetchA(), fetchB()])` faster than `await fetchA(); await fetchB();`?
4. What's the difference in behavior between `Promise.all` and `Promise.allSettled` when one of the operations fails?
5. Why can a Next.js Server Component's function itself be declared `async`, when a typical client-side React component function cannot?

If all five feel solid, move on to Part 1 (or Primer 03, if you're working through the primers in order). If any feel shaky, re-read that section — asynchronous code is used on nearly every page of the main series, and a shaky mental model here will resurface as confusion in Part 4's data fetching, Part 8's transactions, and Part 12's Inngest steps alike.
