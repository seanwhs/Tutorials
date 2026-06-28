# Next.js 16 for Absolute Beginners

# Part 21 — Testing: How Professional Next.js Applications Stay Correct

> **Goal of this lesson:** Learn how to test Next.js 16 applications properly using unit tests, integration tests, end-to-end tests, Server Actions testing, and component testing.

---

# Beginners Often Don't Test

Most beginners build applications like this:

```text
Write Code
    |
Click Browser
    |
Looks Good
    |
Ship
```

This works until:

```text
Feature #10
```

Then:

```text
Feature #11
```

breaks:

```text
Feature #3
```

---

# What Is Testing?

Testing answers one question:

> "How do we know our application still works after we change it?"

---

# Example

Suppose you wrote:

```ts
export function add(
    a: number,
    b: number
) {
    return a + b;
}
```

How do you know it works?

You test it.

---

# Your First Test

Create:

```text
add.test.ts
```

---

```ts
import { add }
    from "./add";

test(
    "adds numbers",
    () => {

        expect(
            add(2, 3)
        ).toBe(5);

    }
);
```

---

# Visualizing Testing

```text
Function
    |
Input
    |
Expected Output
    |
Pass/Fail
```

---

# Why Testing Matters

Without tests:

```text
Change Code
     |
Hope
```

With tests:

```text
Change Code
     |
Run Tests
     |
Confidence
```

---

# The Four Types of Tests

Professional applications usually have:

```text
Unit Tests

Integration Tests

Component Tests

End-to-End Tests
```

---

# Visualizing The Testing Pyramid

```text
          E2E
           ▲
     Integration
           ▲
          Unit
```

---

# Unit Tests

Unit tests test:

```text
One function
One class
One module
```

---

# Example

Suppose:

```ts
export function calculateTax(
    amount: number
) {

    return amount * 0.09;

}
```

Test:

```ts
test(
    "calculates tax",
    () => {

        expect(
            calculateTax(100)
        ).toBe(9);

    }
);
```

---

# What Should Be Unit Tested?

Examples:

```text
Validators

Utilities

Permissions

Calculations

Formatters

Business Rules
```

---

# Example Validator

```ts
export function validateEmail(
    email: string
) {

    return email.includes("@");

}
```

---

Test:

```ts
test(
    "valid email",
    () => {

        expect(
            validateEmail(
                "a@b.com"
            )
        ).toBe(true);

    }
);

test(
    "invalid email",
    () => {

        expect(
            validateEmail(
                "abc"
            )
        ).toBe(false);

    }
);
```

---

# Integration Tests

Integration tests test:

```text
Multiple systems together.
```

---

Example:

```text
Server Action
      |
Repository
      |
Database
```

---

# Visualizing Integration Testing

```text
Component A
      |
Component B
      |
Database
      |
Pass/Fail
```

---

# Example

Suppose:

```ts
export async function createUser(
    email: string
) {

    return db.user.create({

        data: { email }

    });

}
```

---

Test:

```ts
test(
    "creates user",
    async () => {

        const user =
            await createUser(
                "test@test.com"
            );

        expect(
            user.email
        ).toBe(
            "test@test.com"
        );

    }
);
```

---

# Component Testing

Component tests verify:

```text
Does the UI render correctly?
```

---

Example component:

```tsx
export function Button() {

    return (

        <button>

            Save

        </button>

    );

}
```

---

Test:

```tsx
import {
    render,
    screen
} from "@testing-library/react";

test(
    "renders button",
    () => {

        render(
            <Button />
        );

        expect(

            screen.getByText(
                "Save"
            )

        ).toBeTruthy();

    }
);
```

---

# Visualizing Component Testing

```text
Render Component
        |
Inspect DOM
        |
Verify
```

---

# End-to-End Testing

End-to-end (E2E) tests simulate:

```text
Real users.
```

---

Example:

```text
Open browser
      |
Login
      |
Create post
      |
Publish
      |
Verify
```

---

# Visualizing E2E

```text
Browser
    |
Application
    |
Database
    |
Success
```

---

# Why E2E Matters

Unit tests may pass:

```text
✓
✓
✓
✓
```

But users may still experience:

```text
Everything broken.
```

Because:

```text
Integration failed.
```

---

# Example User Flow

Test:

```text
Login
```

Flow:

```text
Homepage
     |
Login Page
     |
Enter Credentials
     |
Submit
     |
Dashboard
```

---

# Example E2E Test

```ts
test(
    "user login",
    async ({ page }) => {

        await page.goto(
            "/login"
        );

        await page.fill(
            "#email",
            "user@test.com"
        );

        await page.fill(
            "#password",
            "password"
        );

        await page.click(
            "button"
        );

        await expect(
            page
        ).toHaveURL(
            "/dashboard"
        );

    }
);
```

---

# What Should Be Tested?

Always test:

```text
Authentication

Authorization

Payments

Forms

Server Actions

Permissions

Critical Business Logic
```

---

# What Should NOT Be Tested?

Avoid testing:

```text
CSS colors

Tailwind classes

Third-party libraries

Framework internals
```

---

# Testing Server Actions

Example:

```tsx
"use server";

export async function createPost(
    title: string
) {

    return db.post.create({

        data: {
            title,
        },

    });

}
```

---

Test:

```ts
test(
    "creates post",
    async () => {

        const post =
            await createPost(
                "Hello"
            );

        expect(
            post.title
        ).toBe(
            "Hello"
        );

    }
);
```

---

# Testing Repositories

Repository:

```ts
export async function getPosts() {

    return db.post.findMany();

}
```

---

Test:

```ts
test(
    "returns posts",
    async () => {

        const posts =
            await getPosts();

        expect(
            posts
        ).toHaveLength(1);

    }
);
```

---

# Testing Permissions

Suppose:

```ts
export function canDeletePost(
    role: string
) {

    return role === "admin";

}
```

---

Test:

```ts
test(
    "admin can delete",
    () => {

        expect(

            canDeletePost(
                "admin"
            )

        ).toBe(true);

    }
);

test(
    "user cannot delete",
    () => {

        expect(

            canDeletePost(
                "user"
            )

        ).toBe(false);

    }
);
```

---

# Snapshot Testing

Example:

```tsx
const component =
    render(
        <Card />
    );

expect(
    component
).toMatchSnapshot();
```

---

# Why Snapshot Testing Is Dangerous

Bad snapshots become:

```text
"Accept everything."
```

Professional teams use snapshots sparingly.

---

# Mocking

Sometimes:

```text
Database unavailable
```

or:

```text
API unavailable
```

We replace them with:

```text
Mocks
```

---

# Example Mock

```ts
const db = {

    user: {

        findMany() {

            return [];

        },

    },

};
```

---

# Visualizing Mocking

```text
Real Database
        |
        X

Fake Database
        |
Tests
```

---

# Testing Authentication

Test:

```text
Unauthenticated User
         |
Access Dashboard
         |
Redirect Login
```

---

Example:

```ts
test(
    "redirects guests",
    async () => {

        const response =
            await visit(
                "/dashboard"
            );

        expect(
            response.redirect
        ).toBe(
            "/login"
        );

    }
);
```

---

# Testing Error States

Suppose:

```text
Database crashes.
```

Your application should still behave correctly.

---

Example:

```ts
test(
    "shows error page",
    async () => {

        mockDatabaseFailure();

        const page =
            await render();

        expect(
            page
        ).toContain(
            "Error"
        );

    }
);
```

---

# Testing Loading States

Example:

```tsx
<Suspense
    fallback={
        <Loading />
    }
>
```

Verify:

```text
Loading UI appears.
```

---

# Testing Cache Behavior

Example:

```text
Request
   |
Cache Miss
   |
Database

Request
   |
Cache Hit
```

Verify:

```text
Database called once.
```

---

# Continuous Integration

Professional teams run:

```text
Tests
   |
Every Commit
```

---

# Visualizing CI

```text
Push Code
      |
Run Tests
      |
Pass
      |
Deploy
```

---

# Test Folder Structure

```text
tests/

    unit/

    integration/

    e2e/

__tests__/
```

---

# Example Project

```text
tests/

    unit/

        auth.test.ts

        permissions.test.ts

    integration/

        posts.test.ts

    e2e/

        login.spec.ts

        publish.spec.ts
```

---

# The Professional Rule

Test:

```text
Business logic heavily.
```

Test:

```text
UI moderately.
```

Test:

```text
Framework behavior lightly.
```

---

# What To Test In Our Nexus CMS

```text
✓ Login

✓ Logout

✓ Permissions

✓ Create Post

✓ Edit Post

✓ Delete Post

✓ Publish Post

✓ Upload Image

✓ Comments

✓ Search

✓ Notifications

✓ Cache Invalidation
```

---

# Exercises

## Exercise 1

Write tests for:

```ts
calculateTax()
```

---

## Exercise 2

Write tests for:

```ts
canDeletePost()
```

---

## Exercise 3

Write an integration test for:

```ts
createPost()
```

---

## Exercise 4

Write an E2E test for:

```text
Login → Dashboard
```

---

# What You've Learned

You now understand:

✅ unit tests

✅ integration tests

✅ component tests

✅ end-to-end tests

✅ Server Action testing

✅ repository testing

✅ mocking

✅ authentication testing

✅ cache testing

✅ CI testing

---

# Mental Model

Don't think:

```text
Does my code work?
```

Think:

```text
How do I prove
my code works?
```

Because professional engineering isn't about confidence.

It's about evidence.

---

# Part 22 Preview

In the next chapter we'll learn:

# Observability and Production Debugging

Including:

* logging
* metrics
* tracing
* monitoring
* error tracking
* performance profiling
* cache observability
* database observability
* debugging production systems

This is where developers start becoming production engineers.
