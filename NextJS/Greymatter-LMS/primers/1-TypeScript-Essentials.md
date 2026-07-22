# Primer 01 — TypeScript Essentials

## Why this primer exists

Starting in Part 1, every single file in GreyMatter LMS is written in TypeScript, with `strict` mode enabled from the very first commit. This isn't a stylistic preference — it's load-bearing. Part 5's database schema, Part 8's enrollment validation, and Part 11's secure grading function all rely on TypeScript catching mistakes *before* code ever runs, not after.

If your JavaScript experience has been "plain JS," the jump into strict TypeScript can feel like a wall the moment you open `db/schema/users.ts` or `lib/modules/types.ts`. This primer removes that wall. It teaches nothing about GreyMatter itself — no Sanity, no Neon, no Next.js — just the TypeScript vocabulary and patterns that appear on nearly every page of the main series, explained from first principles with a plain-JavaScript reader in mind.

**You can safely skip this primer if** you're already comfortable with: type annotations, interfaces, union types, generics, and the difference between `any` and `unknown`. If any of those five phrases are unfamiliar, keep reading.

---

## The core idea: TypeScript is JavaScript with a promise attached

Here's the simplest possible way to think about it. JavaScript is a language where this is completely legal:

```js
function addTax(price) {
  return price + price * 0.08;
}

addTax(100);      // 108 — fine
addTax("100");    // "100" + "1000.08" ... wait, actually "1008" — string concatenation, silently wrong
addTax(undefined); // NaN — silently wrong, no error, no warning
```

Nothing stops you from calling `addTax` with a string, `undefined`, or an object. JavaScript will *try* to do something with whatever you give it, and often that something is quietly, invisibly incorrect. You only find out when a customer's invoice shows `"1008"` dollars instead of `108`, and by then it's in production.

TypeScript's entire value proposition is one sentence: **it lets you write down a promise about what shape a value will have, and then it checks — before your code ever runs — that every place using that value actually keeps the promise.**

```ts
function addTax(price: number): number {
  return price + price * 0.08;
}

addTax(100);       // ✅ fine
addTax("100");     // ❌ TypeScript refuses to compile this, right in your editor
addTax(undefined); // ❌ Same — caught before you ever run the code
```

The `: number` after `price` is the promise: "this parameter will always be a number." The `: number` after the parentheses is a second promise: "this function will always return a number." TypeScript checks every call site against these promises, continuously, as you type — not as a separate step you have to remember to run.

**Analogy:** Think of a mailroom with a strict intake clerk. Plain JavaScript is a mailroom where the clerk accepts any envelope shape — letters, boxes, liquid-filled packages — and just shoves them onto the truck, sorting out the mess only if something leaks *after* delivery. TypeScript is a mailroom where the clerk checks every package against a shipping label *before* it leaves the building. The label doesn't change what's inside the box — it just guarantees nobody downstream gets a surprise.

---

## Type annotations: labeling variables, parameters, and return values

A **type annotation** is the `: type` syntax you just saw. You can attach one to almost anything.

```ts
// Variables
let studentName: string = "Ada Lovelace";
let enrollmentCount: number = 42;
let isPublished: boolean = true;

// Function parameters and return type
function formatGreeting(name: string): string {
  return `Welcome, ${name}!`;
}

// Arrays
let courseIds: string[] = ["course-1", "course-2"];

// Objects (inline)
let course: { title: string; difficulty: string } = {
  title: "Introduction to Databases",
  difficulty: "beginner",
};
```

**A crucial habit worth building immediately: TypeScript can usually *infer* the type for you, without an explicit annotation.**

```ts
let studentName = "Ada Lovelace"; // TypeScript infers: string
let enrollmentCount = 42;         // TypeScript infers: number

studentName = 100; // ❌ Error — TypeScript remembers the inferred type
                    // and enforces it, even without an explicit annotation
```

This is why you'll see very few explicit `: string` annotations on simple `const`/`let` declarations throughout GreyMatter's codebase — TypeScript is already inferring them correctly, and adding a redundant annotation is just extra noise. Explicit annotations become important specifically for **function parameters** (which TypeScript cannot infer from nothing) and **function return types** (as a deliberate promise you want to hold yourself to).

### Verification

Create a scratch file anywhere and try this — it doesn't need to be part of any project:

```ts
function double(x: number): number {
  return x * 2;
}

double(5);      // should work
double("5");    // should show a red squiggly error in your editor
```

If you have TypeScript installed globally or via a project, run:

```bash
npx tsc --noEmit yourfile.ts
```

You should see a compile error naming the exact line and exact mismatch — this instant, precise feedback is the entire point.

---

## `interface` — describing the shape of an object

Inline object types (like the `course` example above) get unwieldy fast, especially once the same shape is used in many places. An **interface** gives that shape a name you can reuse.

```ts
interface Course {
  title: string;
  slug: string;
  difficulty: "beginner" | "intermediate" | "advanced"; // more on this union type below
  learningObjectives: string[];
}

function printCourseSummary(course: Course): string {
  return `${course.title} (${course.difficulty})`;
}

const myCourse: Course = {
  title: "Intro to Databases",
  slug: "intro-to-databases",
  difficulty: "beginner",
  learningObjectives: ["Understand tables", "Write a SELECT query"],
};

printCourseSummary(myCourse); // ✅ works

const brokenCourse: Course = {
  title: "Intro to Databases",
  slug: "intro-to-databases",
  difficulty: "expert", // ❌ Error — "expert" isn't one of the allowed values
  learningObjectives: ["..."],
};
```

This is precisely the pattern you'll see throughout Part 4 and Part 7 of the main series — e.g., `CourseCard`, `CourseDetail`, `LessonSummary` in `sanity/lib/queries.ts` are all interfaces describing exactly what shape a GROQ query's result will have. When you see:

```ts
export interface CourseCard {
  _id: string;
  title: string;
  slug: SanitySlug;
  // ...
}
```

read it as: "I am promising that anything I call a `CourseCard` will have *at least* these fields, with these exact types."

### `interface` vs. plain object types — a quick note

You'll occasionally see the same idea written as a `type` instead of an `interface`:

```ts
type Course = {
  title: string;
  slug: string;
};

// vs.

interface Course {
  title: string;
  slug: string;
}
```

For the purposes of everything in this series, these are interchangeable. GreyMatter uses `interface` for object shapes as a house style, and `type` specifically for unions and simpler type aliases — a convention worth following for consistency, but not a rule TypeScript itself enforces.

### `extends` — building one interface on top of another

```ts
interface CourseCard {
  _id: string;
  title: string;
  slug: string;
}

// CourseDetail has everything CourseCard has, PLUS two more fields —
// without retyping title/slug/_id a second time.
interface CourseDetail extends CourseCard {
  learningObjectives: string[];
  chapters: unknown[]; // simplified for this example
}
```

This is exactly the pattern used in Part 4's `sanity/lib/queries.ts` — worth recognizing on sight, since it appears repeatedly.

---

## Union types: "this OR that, and nothing else"

A **union type** restricts a value to one of a specific, closed list of possibilities — joined with the `|` symbol.

```ts
type Difficulty = "beginner" | "intermediate" | "advanced";

function badge(difficulty: Difficulty): string {
  return difficulty.toUpperCase();
}

badge("beginner");     // ✅
badge("expert");       // ❌ Error — not one of the three allowed strings
```

This is precisely how GreyMatter models roles, statuses, and enum-like values throughout the series:

```ts
// From Part 6:
type UserRole = "STUDENT" | "INSTRUCTOR" | "ADMIN";

// From Part 5's Drizzle schema (conceptually the same idea, enforced
// by the database too — see Primer 04 for the database side of this):
export const userRoleEnum = pgEnum("user_role", ["STUDENT", "INSTRUCTOR", "ADMIN"]);
```

Union types aren't limited to strings — they can combine entirely different types:

```ts
function getEnrollmentId(input: string | null): string {
  if (input === null) {
    return "no enrollment";
  }
  return input; // TypeScript now KNOWS input is a string here, not null
}
```

This pattern — checking for `null` (or `undefined`) before using a value — is called **narrowing**, and it's one of TypeScript's most genuinely useful features. Once you write an `if (input === null)` check, TypeScript *remembers* that fact for every line of code after it, inside that branch. This is exactly what makes Part 6's `requireUser()` function work the way it does:

```ts
export async function requireUser(): Promise<CurrentUser> {
  const user = await getCurrentUser(); // type: CurrentUser | null

  if (!user) {
    redirect("/sign-in"); // this line never "returns" normally
  }

  return user; // TypeScript knows: by this point, user CANNOT be null
               // (because redirect() is typed to never return normally)
}
```

---

## Optional properties and `undefined`

A `?` after a property name means "this field might not be present at all" — distinct from the field being present but holding `null`.

```ts
interface Lesson {
  title: string;
  videoUrl?: string; // optional — a lesson might have no video at all
}

const lessonWithVideo: Lesson = { title: "Intro", videoUrl: "https://..." };
const lessonWithoutVideo: Lesson = { title: "Intro" }; // ✅ fine — videoUrl simply absent

function renderVideo(lesson: Lesson) {
  if (lesson.videoUrl) {
    // Inside this block, TypeScript knows videoUrl is a real string,
    // not undefined — this is narrowing again, applied to optional fields.
    console.log(lesson.videoUrl.toUpperCase());
  }
}
```

This exact pattern appears in Part 9's lesson player: `{lesson.videoUrl && <VideoEmbed url={lesson.videoUrl} />}` — the `&&` check is doing the same narrowing job as the `if` above, just written as a single expression suited to JSX.

---

## Generics: writing one piece of code that works with many types, safely

This is the concept that trips up the most people coming from plain JavaScript, so we'll build it up slowly, in stages.

### The problem generics solve

Imagine you want a function that returns the first item of any array:

```js
function first(arr) {
  return arr[0];
}
```

In plain JavaScript, this "just works" for any array — but you get zero help from your editor about what `first(arr)` actually returns. If you call `first(courseIds)`, does it return a `string`? An object? JavaScript has no idea, and neither does anyone reading your code six months later.

### The naive TypeScript attempt — and why it fails

```ts
function first(arr: string[]): string {
  return arr[0];
}

first(["a", "b", "c"]);    // ✅ works
first([1, 2, 3]);          // ❌ Error — this function only accepts string[]
```

This works, but only for arrays of strings. You'd need to write a nearly identical function for `number[]`, for `Course[]`, for every array type you ever use — real, tedious duplication.

### The generic solution

```ts
function first<T>(arr: T[]): T {
  return arr[0];
}

first(["a", "b", "c"]);        // T is inferred as string; returns string
first([1, 2, 3]);              // T is inferred as number; returns number
first([{ title: "X" }]);       // T is inferred as { title: string }; returns that shape
```

`<T>` declares a **type parameter** — a placeholder type name, filled in fresh every time the function is called, based on whatever you actually pass in. Read `<T>` as: "I don't know yet what type this will be — but whatever it is, use that *same* type consistently everywhere `T` appears in this function's signature."

**Analogy:** think of a generic function like a photocopier machine with an input tray and an output tray. The machine doesn't care whether you feed it a page of text or a page of drawings — whatever type of page goes in, that exact same type comes out. `<T>` is the label on both trays, guaranteeing they always match, without the machine needing a hardcoded rule for every possible page type in advance.

### Where generics show up in GreyMatter, concretely

Part 10's plugin contract is the single most important generic type in the entire series:

```ts
export interface GreyMatterModuleProps<TConfig, TSubmission> {
  moduleId: string;
  lessonId: string;
  config: TConfig;
  initialAttempt: ModuleAttemptSnapshot | null;
  submit: (submission: TSubmission) => Promise<ModuleSubmissionResult>;
}
```

This interface has **two** type parameters: `TConfig` (whatever shape this specific module's authored content takes) and `TSubmission` (whatever shape this specific module's answer takes). When the quiz module uses it:

```ts
interface QuizSubmission {
  selectedOptionIndex: number;
}

export function MultipleChoiceQuiz({
  config,
  submit,
}: GreyMatterModuleProps<QuizConfig, QuizSubmission>) {
  // Inside here, TypeScript KNOWS:
  //   config is specifically shaped like QuizConfig
  //   submit expects specifically a QuizSubmission
}
```

...TypeScript fills in `TConfig = QuizConfig` and `TSubmission = QuizSubmission` for this specific usage, while the `CodeExercise` component fills in entirely different types for the exact same shared interface. This is precisely what lets Part 10 build one plugin *contract* that five wildly different modules can each implement safely, each with their own config/submission shapes, without TypeScript ever letting one module's data accidentally leak into another's expectations.

You'll also see generics constantly in ordinary function calls throughout the series, often without even writing `<T>` yourself, because TypeScript infers it:

```ts
// Part 4 — the generic here is <CourseCard[]>, explicitly provided,
// telling TypeScript exactly what shape to expect back from a query
// whose actual return type it cannot otherwise know (since it comes
// from an external system, Sanity, at runtime):
const courses = await client.fetch<CourseCard[]>(courseCatalogQuery);
```

```ts
// Part 6 — React's useState is itself a generic function; <string | null>
// tells TypeScript exactly what this piece of state can ever hold:
const [result, setResult] = useState<string | null>(null);
```

---

## `any` vs. `unknown` — the two "I don't know the type" options, and why they behave completely differently

This distinction matters a great deal in Part 5 (`jsonb` columns) and Part 10/11 (module submissions), so it's worth understanding precisely.

```ts
let valueA: any = fetchSomethingFromTheInternet();
valueA.toUpperCase(); // TypeScript allows this WITHOUT ANY CHECK —
                      // even though valueA might be a number, an object,
                      // or null, and this line could crash at runtime

let valueB: unknown = fetchSomethingFromTheInternet();
valueB.toUpperCase(); // ❌ TypeScript REFUSES — you must first prove
                      // what valueB actually is before using it
```

`any` means "turn off type checking entirely for this value" — it's an escape hatch, and using it liberally throws away the entire benefit of TypeScript. `unknown` means "I genuinely don't know the type yet, and TypeScript will force me to check before I use it in any specific way."

```ts
let valueB: unknown = fetchSomethingFromTheInternet();

if (typeof valueB === "string") {
  valueB.toUpperCase(); // ✅ fine now — narrowed to string inside this block
}
```

This is exactly why Part 10 and Part 11's module submission types use `unknown`, not `any`:

```ts
export interface GreyMatterModuleProps<TConfig, TSubmission> {
  // ...
  submit: (submission: TSubmission) => Promise<ModuleSubmissionResult>;
}
```

And in the Server Action itself:

```ts
export async function submitModuleAttempt(input: unknown): Promise<ModuleSubmissionResult> {
  const parsed = submitModuleAttemptSchema.safeParse(input); // Zod NARROWS `unknown` safely
  // ...
}
```

The Server Action's `input` parameter is typed `unknown` **deliberately** — recall Part 8/11's central lesson: never trust data crossing a system boundary (a network request, in this case). Typing it `unknown` forces every code path to go through Zod's validation before touching any specific field — TypeScript itself refuses to let you skip that step, because `unknown` gives you no fields or methods to call until you've proven what the value actually is.

**Rule of thumb for the rest of your TypeScript life:** if you're ever tempted to type something `any`, reach for `unknown` instead, and then narrow it properly (with a type guard, a Zod schema, or a plain `typeof`/`instanceof` check) before using it. `any` is rarely a genuine shortcut — it's usually a bug waiting to happen, silently.

---

## Type guards: functions that prove a narrower type

A **type guard** is a function whose return type includes a special `value is SomeType` annotation, telling TypeScript "if this function returns `true`, you can now safely treat the input as `SomeType`."

```ts
interface Cat { meow: () => void }
interface Dog { bark: () => void }

function isCat(pet: Cat | Dog): pet is Cat {
  return "meow" in pet;
}

function makeSound(pet: Cat | Dog) {
  if (isCat(pet)) {
    pet.meow(); // ✅ TypeScript knows pet is specifically a Cat here
  } else {
    pet.bark(); // ✅ and specifically a Dog here
  }
}
```

This exact pattern is used in Part 10's module registry:

```ts
function isKnownModuleType(type: string): type is ModuleBlockType {
  return type in moduleRegistry;
}

// Later:
if (!isKnownModuleType(_type)) {
  return <UnsupportedContentFallback />;
}

const entry = moduleRegistry[_type]; // TypeScript now knows _type is
                                       // safely one of the known keys —
                                       // this line would be an error
                                       // without the type guard above
```

---

## `as const` — locking values down to their exact, literal type

By default, TypeScript widens literal values to their general type:

```ts
const status = "active"; // TypeScript infers: string (general)
```

`as const` tells TypeScript "treat this as its exact, specific literal value, not the general category":

```ts
const status = "active" as const; // TypeScript infers: "active" (the literal)
```

This matters most for objects and arrays, where it also makes every nested value read-only and exact:

```ts
export const moduleRegistry = {
  quizBlock: { /* ... */ },
  codeExerciseBlock: { /* ... */ },
} as const;

export type ModuleBlockType = keyof typeof moduleRegistry;
// Without "as const", ModuleBlockType would just be `string` — with it,
// TypeScript derives the PRECISE union: "quizBlock" | "codeExerciseBlock"
```

This is exactly Part 10's registry pattern — `as const` plus `keyof typeof` is a common, worth-recognizing combination for deriving a precise union type directly from an object's actual keys, rather than typing that union out by hand a second time (which would risk the two definitions drifting apart).

---

## Type inference from runtime validation: `z.infer`

This is a pattern you'll see constantly starting in Part 8, and it deserves its own short section because it looks slightly magical the first time.

```ts
import { z } from "zod";

const enrollInCourseSchema = z.object({
  courseId: z.string().trim().min(1).max(200),
});

// z.infer<typeof X> DERIVES a TypeScript type directly from a Zod
// schema — you never write { courseId: string } by hand separately.
type EnrollInCourseInput = z.infer<typeof enrollInCourseSchema>;
// TypeScript now understands EnrollInCourseInput as: { courseId: string }
```

Why this matters: without `z.infer`, you'd maintain **two** separate descriptions of the same shape — a Zod schema (checked at runtime, when real data arrives) and a hand-written TypeScript interface (checked at compile time, while you're writing code) — and nothing would stop them from silently drifting apart as the project evolves. `z.infer` guarantees there's exactly one source of truth: the Zod schema. This is precisely why Primer 01's earlier "single source of truth" idea keeps reappearing throughout the main series.

---

## Putting it all together: reading a real file from the series

You now have every tool needed to read this real excerpt from Part 11 fluently. Read it slowly, and notice how many concepts from this primer appear in just a few lines:

```ts
const submitModuleAttemptSchema = z.object({
  lessonId: z.string().min(1),
  courseId: z.string().min(1),
  moduleId: z.string().min(1),
  submission: z.unknown(),          // ← unknown, not any — must be validated before use
  idempotencyKey: z.string().uuid().optional(), // ← optional field
}).refine(
  (data) => JSON.stringify(data.submission).length <= MAX_SUBMISSION_JSON_LENGTH,
  { message: "Submission is too large.", path: ["submission"] }
);

export type SubmitModuleAttemptInput = z.infer<typeof submitModuleAttemptSchema>;
// ← type inferred directly from the schema, never duplicated by hand

export type ModuleErrorCode =
  | "NOT_ENROLLED"                  // ← union type: a closed list of
  | "MODULE_NOT_FOUND"               //   allowed string values, nothing else
  | "ATTEMPT_LIMIT_EXCEEDED"
  | "INVALID_SUBMISSION"
  | "SUBMISSION_TOO_LARGE"
  | "UNKNOWN_ERROR";

export interface ModuleSubmissionResult {  // ← interface: names a reusable object shape
  success: boolean;
  isCorrect: boolean | null;               // ← union: boolean OR null, nothing else
  score: number | null;
  message: string;
  errorCode?: ModuleErrorCode;             // ← optional property
}
```

If every line of that block now makes sense, you're ready for Part 1.

---

## You're ready for Part 1 if you can answer these

1. What's the difference between `interface Foo { name: string }` and `interface Bar extends Foo { age: number }`?
2. Why would you type a function parameter as `unknown` instead of `any`, and what do you have to do before you can actually use an `unknown` value?
3. What does `"beginner" | "intermediate" | "advanced"` mean, and what happens if you try to assign `"expert"` to a variable of that type?
4. In `function first<T>(arr: T[]): T`, what is `T`, and why does it let one function work correctly for arrays of any type?
5. What does `z.infer<typeof mySchema>` actually do, and why is it preferable to writing the equivalent interface by hand?

If you can answer all five without looking back, you have everything you need. If any of them feel shaky, re-read that section once more before moving on — every one of these five ideas reappears, unremarked-upon, in nearly every file of the sixteen-part series.
