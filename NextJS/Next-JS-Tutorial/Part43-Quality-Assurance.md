# Next.js 16 for Absolute Beginners

# Part 43 — Testing, Quality Assurance, and Engineering Confidence

> **Goal of this lesson:** Learn how professional engineers test Next.js 16 applications using unit tests, integration tests, end-to-end tests, mocks, contract tests, performance tests, and CI pipelines.

---

# The Fifth Biggest Lie in Software Engineering

The first lie:

> Users wait.

The second lie:

> Everything happens immediately.

The third lie:

> Users refresh pages.

The fourth lie:

> Tests passing means production works.

The fifth lie:

> Testing is about finding bugs.

It isn't.

Testing is about:

```text id="a1z8kr"
Building confidence.
```

---

# Beginners Think Testing Looks Like This

```text id="p87rjh"
Write code
    |
Run test
    |
Pass
```

Professionals think:

```text id="e2xv9m"
Can I safely change
this system
six months later?
```

---

# What Is Testing?

Testing answers one question:

> **How certain are we that the system behaves correctly?**

---

# Visualizing Confidence

```text id="yw0rf9"
No Tests
    |
Fear
    |
No Changes
```

versus:

```text id="prx2um"
Tests
    |
Confidence
    |
Fast Changes
```

---

# What We're Building

By the end of this chapter, we'll have:

```text id="k6v3db"
✓ Unit tests
✓ Integration tests
✓ End-to-end tests
✓ Mocking
✓ Test doubles
✓ API tests
✓ Contract tests
✓ Performance tests
✓ Security tests
✓ CI pipelines
```

---

# The Testing Pyramid

Professional testing looks like this:

```text id="3k3a0g"
             E2E
            /   \
           /     \
     Integration
        /       \
       /         \
      Unit Tests
```

---

# Why?

Because:

```text id="rypj3u"
Unit tests:
Fast

Integration:
Realistic

E2E:
Expensive
```

---

# Part 1 — Unit Testing

Unit tests verify:

```text id="j3k7nd"
One thing.
```

---

# Example Function

```ts id="mpvcce"
export function
calculateTax(

  amount: number

) {

  return amount
    * 0.07;

}
```

---

# Install Vitest

```bash id="qlfop2"
npm install -D

vitest
```

---

# Create Test

```ts id="t9y2za"
import {

  expect,

  test,

} from "vitest";

import {

  calculateTax,

} from "./tax";

test(

  "calculates tax",

  () => {

    expect(

      calculateTax(
        100
      )

    ).toBe(7);

  }

);
```

---

# Visualizing Unit Tests

```text id="n3aqry"
Input
   |
Function
   |
Output
```

---

# Good Unit Tests

Test:

```text id="cwwmlo"
✓ Pure functions
✓ Validation
✓ Business rules
✓ Utilities
```

---

# Bad Unit Tests

Avoid testing:

```text id="vjg7xn"
React internals

Libraries

Framework code
```

---

# Example Validation Test

```ts id="3hm2ms"
test(

  "email validation",

  () => {

    expect(

      isValidEmail(

        "a@test.com"

      )

    ).toBe(true);

  }

);
```

---

# Part 2 — Testing Server Actions

Example:

```ts id="75q1pw"
"use server";

export async function
createPost(

  title: string

) {

  if (!title)

    throw Error();

}
```

---

# Test

```ts id="96ehz2"
test(

  "requires title",

  async () => {

    await expect(

      createPost("")

    ).rejects
      .toThrow();

  }

);
```

---

# Visualizing

```text id="frj7vc"
Input
   |
Server Action
   |
Result
```

---

# Part 3 — Mocking

Problem:

```text id="2vgn7n"
Real database.
```

---

Example:

```ts id="ym9b7v"
await db.user
  .findMany();
```

---

You don't want:

```text id="ftuj9a"
Real database
```

inside unit tests.

---

# Create Mock

```ts id="akafcv"
const db = {

  user: {

    findMany:

      vi.fn(),

  },

};
```

---

# Example

```ts id="gr06ok"
db.user.findMany
  .mockResolvedValue(

    []

  );
```

---

# Visualizing Mocking

```text id="18thq1"
Real Dependency
       |
Fake Dependency
```

---

# Types of Test Doubles

```text id="swnld7"
Dummy

Stub

Spy

Mock

Fake
```

---

# Part 4 — Integration Tests

Integration tests verify:

```text id="nl21na"
Components
working together.
```

---

# Example

Test:

```text id="pl3ev2"
API
 +
Database
```

---

# Example

```ts id="2mtsh6"
test(

  "creates user",

  async () => {

    const user =

      await createUser();

    expect(

      user.id

    ).toBeDefined();

  }

);
```

---

# Visualizing

```text id="e1z6s6"
API
  |
Database
  |
Result
```

---

# Integration Tests Are About

```text id="0xav2k"
Boundaries.
```

---

# Part 5 — Component Testing

Install:

```bash id="gcbf0r"
npm install

@testing-library/react
```

---

# Example Component

```tsx id="kgam5n"
export function
Button() {

  return (

    <button>

      Save

    </button>

  );

}
```

---

# Test

```ts id="cnk7um"
render(

  <Button />

);

expect(

  screen.getByText(
    "Save"
  )

).toBeDefined();
```

---

# Why?

Because users don't care about:

```text id="1fcsrn"
Props.
```

Users care about:

```text id="jlwm4j"
Behavior.
```

---

# Part 6 — API Testing

Example:

```text id="vw4g7m"
/api/posts
```

---

Test:

```ts id="3gz9rj"
const response =

  await fetch(
    "/api/posts"
  );

expect(

  response.status

).toBe(200);
```

---

# Verify:

```text id="rsmwz7"
✓ Status
✓ Headers
✓ Body
✓ Errors
```

---

# Part 7 — End-to-End Testing

E2E tests verify:

```text id="k8qiy1"
Entire workflows.
```

---

# Install Playwright

```bash id="u2qdz0"
npm install

@playwright/test
```

---

# Example

```ts id="yhv5se"
test(

  "login",

  async ({ page }) => {

    await page.goto(
      "/login"
    );

    await page.fill(

      "#email",

      "a@test.com"

    );

    await page.click(
      "button"
    );

  }

);
```

---

# Visualizing E2E

```text id="zgjov5"
Browser
   |
Application
   |
Database
```

---

# Example E2E Flow

```text id="2qzz3f"
Register
    |
Login
    |
Create Post
    |
Publish
    |
Logout
```

---

# Part 8 — Contract Testing

Suppose:

```text id="lm7vns"
Frontend
```

expects:

```json id="npsq0t"
{
  "name":
    "Sean"
}
```

Backend returns:

```json id="rwbyw4"
{
  "fullName":
    "Sean"
}
```

Everything breaks.

---

# Contract Tests Verify

```text id="wtk95v"
API agreements.
```

---

# Example

```ts id="e0axd2"
expect(

  response

).toMatchObject({

  name:
    expect.any(
      String
    ),

});
```

---

# Part 9 — Snapshot Tests

Example:

```tsx id="7n4g6n"
expect(

  component

).toMatchSnapshot();
```

---

# Warning

Snapshots can become:

```text id="crl0gh"
5000-line monsters.
```

Use sparingly.

---

# Part 10 — Performance Testing

Measure:

```text id="vjlwmr"
Latency

Throughput

Memory

CPU
```

---

# Example

```ts id="4iz50d"
const start =

  performance.now();
```

---

```ts id="9ok20q"
expect(

  duration

).toBeLessThan(
  100
);
```

---

# Example Load Test

```text id="jv2xl4"
1000 users

500 requests/sec
```

---

# Tools

```text id="mrgxks"
k6

Artillery

JMeter
```

---

# Part 11 — Security Testing

Verify:

```text id="t6b7iz"
✓ Authentication
✓ Authorization
✓ Injection
✓ XSS
✓ CSRF
✓ Rate limiting
```

---

# Example

```ts id="ozv5sk"
expect(

  response.status

).toBe(403);
```

---

# Why?

Because:

```text id="kghm1t"
Working
≠
Secure.
```

---

# Part 12 — Mutation Testing

Question:

```text id="d0ob5h"
Would tests fail
if code changed?
```

---

Example:

```ts id="sn0o2i"
return a+b;
```

becomes:

```ts id="ksifx2"
return a-b;
```

---

If tests still pass:

```text id="lccwz6"
Your tests failed.
```

---

# Part 13 — Coverage

Example:

```text id="td3mfw"
Statements

Branches

Functions

Lines
```

---

# Warning

```text id="hjv70s"
100%
coverage
```

does NOT mean:

```text id="wg5yjb"
100%
correct.
```

---

# Example

```ts id="cgppg0"
if(true)
```

can achieve:

```text id="bxw86j"
100%
coverage
```

while being useless.

---

# Part 14 — CI Testing

Every push:

```text id="2fjlwm"
Git Push
    |
Tests
    |
Build
    |
Deploy
```

---

# Example Workflow

```yaml id="j8m37r"
steps:

  - run:
      npm test

  - run:
      npm run build
```

---

# Why?

Because humans forget.

CI never forgets.

---

# Part 15 — Testing Next.js Cache Components

Example:

```ts id="kwnd52"
"use cache";

cacheTag(
  "posts"
);
```

---

Verify:

```text id="qcrj80"
First request:
miss

Second request:
hit
```

---

# Part 16 — Testing Strategy

Test heavily:

```text id="6u1rm8"
Business logic

Security

Payments

Permissions
```

---

Test lightly:

```text id="fydwr4"
Framework code

Styling

Libraries
```

---

# Testing Architecture

```text id="1shyqq"
               E2E
                 |
          Integration
                 |
              Units
```

---

# Part 17 — The Economics of Testing

No tests:

```text id="7vw9pc"
Cheap now
Expensive later
```

---

Tests:

```text id="dl4y9t"
Expensive now
Cheap later
```

---

# What We've Built

```text id="4oxr6i"
✓ Unit tests

✓ Server Action tests

✓ Mocks

✓ Integration tests

✓ Component tests

✓ API tests

✓ E2E tests

✓ Contract tests

✓ Performance tests

✓ CI pipelines
```

---

# Testing Philosophy

Beginners write tests to:

```text id="ih3j8w"
Find bugs.
```

Professional engineers write tests to:

```text id="r9t8sv"
Enable change.
```

Because the value of testing isn't proving your code works today.

It's proving you can safely change it tomorrow.

---

# Exercises

## Exercise 1

Write:

```text id="o7pmys"
Unit tests
```

for RBAC.

---

## Exercise 2

Write:

```text id="lcc6qu"
Integration tests
```

for authentication.

---

## Exercise 3

Write:

```text id="j3wz7g"
Playwright tests
```

for login.

---

## Exercise 4

Write:

```text id="4s7c8b"
Performance tests
```

for search.

---

# Mental Model

Beginners think:

```text id="xoqznw"
Tests
    =
Verification
```

Professional engineers think:

```text id="z1iyf5"
Tests
    =
Engineering confidence
```

Because software engineering isn't about writing code.

It's about being able to change code without fear.

---

# Part 44 Preview

In the next chapter we'll build:

# Deployment, Infrastructure, Containers, CI/CD, and Production Architecture

Including:

```text id="4mhj1g"
✓ Deployment
✓ Docker
✓ Containers
✓ CI/CD
✓ Kubernetes
✓ Vercel
✓ Infrastructure
✓ Scaling
✓ Blue-green deployments
✓ Production architecture
```

This is where Next.js becomes a real production platform.
