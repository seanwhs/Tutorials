# Appendix A22 — Next.js 16 Testing, Verification & Quality Engineering Cheat Sheet

## The Complete Guide to Proving That Your Software Works Before Your Users Prove That It Doesn't

> **Purpose:** This appendix is the definitive reference for testing and quality engineering in Next.js 16 applications. Testing is not the process of finding bugs. Testing is the process of reducing uncertainty.

---

# Introduction

The biggest misconception beginners have is:

```text
Testing
=
Checking if
the code works.
```

Professional engineers understand:

```text
Testing
=
Building confidence
that the system
behaves correctly.
```

Because software engineering is fundamentally:

```text
Making decisions

under uncertainty.
```

And testing exists to reduce that uncertainty.

---

# The Golden Rule

Never ask:

```text
Did I test it?
```

Ask:

```text
What assumptions
remain untested?
```

---

# Why Testing Exists

Without tests:

```text
Change

   |

Fear

   |

No deployment
```

---

With tests:

```text
Change

   |

Confidence

   |

Deployment
```

---

# Testing Pyramid

```text
          E2E

        Integration

           Unit
```

---

# Rule

Most tests should be:

```text
Unit tests.
```

Some should be:

```text
Integration tests.
```

Very few should be:

```text
End-to-end tests.
```

---

# Unit Tests

Question:

```text
Does this
piece of logic
work?
```

---

Example:

```ts
function sum(
  a: number,
  b: number
) {
  return a + b;
}
```

---

Test:

```ts
it("adds", () => {
  expect(
    sum(1,2)
  ).toBe(3);
});
```

---

# Benefits

```text
✓ Fast

✓ Cheap

✓ Reliable
```

---

# Integration Tests

Question:

```text
Do these
components
work together?
```

---

Example:

```text
Server Action

      |

Database

      |

Cache
```

---

# Example

```ts
await createPost();

expect(
  await db.posts.count()
).toBe(1);
```

---

# End-to-End Tests

Question:

```text
Can the user
actually complete
the workflow?
```

---

Example:

```text
Browser

   |

Login

   |

Checkout

   |

Payment
```

---

# Benefits

```text
✓ Realistic

✓ High confidence
```

---

# Costs

```text
✗ Slow

✗ Fragile

✗ Expensive
```

---

# Testing Strategy

Test:

```text
Business logic
heavily.
```

---

Test:

```text
Framework code
lightly.
```

---

# Example

Do not test:

```tsx
<button>
  Save
</button>
```

---

Test:

```text
Can unauthorized
users save?
```

---

# The Testing Trophy

Modern testing often looks like:

```text
       E2E

 Integration

Component

 Static
```

---

# Static Testing

Examples:

```text
TypeScript

ESLint

Prettier

Schema validation
```

---

# Type Safety

TypeScript catches:

```text
Wrong types

Missing fields

Invalid APIs
```

---

# Example

```ts
type User = {
  id: string;
};
```

---

Error:

```ts
user.name
```

---

Detected:

```text
Before runtime.
```

---

# Next.js Testing Layers

```text
Page

 |

Component

 |

Hook

 |

Action

 |

Database
```

---

# Testing Server Components

Question:

```text
Did the component
render correctly?
```

---

Verify:

```text
HTML

Data

Errors

Loading states
```

---

# Testing Client Components

Verify:

```text
Interactions

Events

State changes
```

---

# Testing Server Actions

Verify:

```text
Validation

Authorization

Persistence

Errors
```

---

# Example

```ts
it(
  "creates post",
  async () => {

    await createPost();

  }
);
```

---

# Database Testing

Question:

```text
Did data
change correctly?
```

---

Verify:

```text
Insert

Update

Delete

Rollback
```

---

# API Testing

Verify:

```text
Status codes

Payloads

Headers

Errors
```

---

# Example

```ts
expect(
  response.status
).toBe(200);
```

---

# Authentication Testing

Verify:

```text
Login

Logout

Expiration

Permissions
```

---

# Authorization Testing

Question:

```text
Who should
NOT have
access?
```

---

Example:

```text
Admin

Editor

User
```

---

# Security Testing

Verify:

```text
Validation

Permissions

Rate limits

Sessions
```

---

# Performance Testing

Question:

```text
Is it fast enough?
```

---

Measure:

```text
Latency

Throughput

Concurrency
```

---

# Load Testing

Question:

```text
Can it handle
expected traffic?
```

---

# Stress Testing

Question:

```text
When does
it break?
```

---

# Soak Testing

Question:

```text
Does it fail
over time?
```

---

# Snapshot Testing

Example:

```tsx
expect(
  tree
).toMatchSnapshot();
```

---

Use for:

```text
Stable output.
```

---

Avoid for:

```text
Rapidly changing UI.
```

---

# Mocking

Purpose:

```text
Remove
external dependencies.
```

---

Example:

```ts
vi.mock(
  "./database"
);
```

---

# Benefits

```text
✓ Fast

✓ Predictable
```

---

# Risks

```text
✗ Unrealistic
```

---

# Test Fixtures

Purpose:

```text
Known data.
```

---

Example:

```ts
const user = {
  id: "1",
  role: "admin",
};
```

---

# Test Data Factories

Better:

```ts
createUser({

  role:
    "admin",

});
```

---

# Property Testing

Question:

```text
Does this
always hold true?
```

---

Example:

```text
a + b
=
b + a
```

---

# Fuzz Testing

Question:

```text
What happens
with weird input?
```

---

Example:

```text
Null

Unicode

Large strings

Invalid JSON
```

---

# Contract Testing

Question:

```text
Do services
agree on
their APIs?
```

---

Example:

```text
Frontend

   |

Contract

   |

Backend
```

---

# Regression Testing

Question:

```text
Did we
break something?
```

---

Purpose:

```text
Prevent
old bugs
from returning.
```

---

# Smoke Testing

Question:

```text
Does anything
work at all?
```

---

Examples:

```text
Login

Search

Checkout
```

---

# Exploratory Testing

Question:

```text
What did
we forget
to test?
```

---

# Mutation Testing

Question:

```text
Can our tests
detect
broken code?
```

---

Example:

```text
Original:

a + b

Mutation:

a - b
```

---

# Test Coverage

Question:

```text
What code
executed?
```

---

Example:

```text
80%
coverage
```

---

# Important Rule

Coverage measures:

```text
Execution.
```

---

Coverage does NOT measure:

```text
Correctness.
```

---

# Example

Bad:

```text
100% coverage

0% confidence
```

---

# Test Isolation

Every test should:

```text
Pass alone.

Pass together.
```

---

# Test Naming

Bad:

```text
test1
```

---

Better:

```text
should reject
expired token
```

---

# Arrange-Act-Assert

Structure:

```text
Arrange

   |

Act

   |

Assert
```

---

# Example

```ts
// Arrange
const user =
  createUser();

// Act
login(user);

// Assert
expect(
  session
).toExist();
```

---

# Continuous Testing

Run tests:

```text
Before commit

Before merge

Before deploy
```

---

# Testing in CI

Pipeline:

```text
Lint

   |

Types

   |

Unit

   |

Integration

   |

E2E

   |

Deploy
```

---

# Flaky Tests

Symptoms:

```text
Pass

Fail

Pass

Fail
```

---

Rule:

```text
A flaky test
is a broken test.
```

---

# Test Failure Analysis

Question:

```text
Did:

The code fail?

The test fail?

The environment fail?
```

---

# Quality Engineering

Quality is:

```text
Testing

+

Architecture

+

Observability

+

Process
```

---

# Shift Left Testing

Move testing:

```text
Earlier.
```

---

Instead of:

```text
Build

Test
```

---

Use:

```text
Test

Build
```

---

# Production Testing

Examples:

```text
Feature flags

Canary releases

Shadow traffic
```

---

# Chaos Testing

Question:

```text
What happens if:

Database dies?

Cache dies?

API dies?
```

---

# Test Checklist

Verify:

```text
✓ Unit tests

✓ Integration tests

✓ E2E tests

✓ Security tests

✓ Performance tests

✓ Regression tests

✓ Authorization tests

✓ Error handling

✓ Edge cases

✓ Failure scenarios
```

---

# Common Beginner Mistakes

---

## Mistake 1

Testing implementation details.

---

## Mistake 2

Chasing coverage numbers.

---

## Mistake 3

Not testing failures.

---

## Mistake 4

Skipping authorization tests.

---

## Mistake 5

Mocking everything.

---

## Mistake 6

Writing fragile E2E tests.

---

## Mistake 7

Assuming tested code is correct.

---

# The Testing Decision Tree

Question:

```text
Can this fail?
```

If:

```text
No
```

Then:

```text
Don't test it.
```

---

Question:

```text
Would failure
be expensive?
```

If:

```text
Yes
```

Then:

```text
Test heavily.
```

---

Question:

```text
Can users
trigger it?
```

If:

```text
Yes
```

Then:

```text
Test it.
```

---

# The Complete Quality Pipeline

```text
Requirements
      |
Design
      |
Static Analysis
      |
Unit Tests
      |
Integration Tests
      |
E2E Tests
      |
Deploy
      |
Observe
      |
Learn
```

---

# Mental Model

Beginners think:

```text
Testing
=
Finding bugs.
```

Professional engineers think:

```text
Testing
=
Reducing uncertainty
about system behavior.
```

Because the purpose of testing is not to prove that software works.

It is to determine how much confidence you have that it will continue to work tomorrow.
