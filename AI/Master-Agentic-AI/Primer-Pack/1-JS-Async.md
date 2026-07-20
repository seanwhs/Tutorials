# Primer 1: Async JavaScript Mental Models

*Optional pre-reading. If you're already comfortable with `async`/`await` and Promises, skip straight to Part 0 of the main course.*

## Why This Primer Exists

Nearly every file in this course is built around asynchronous code — waiting on a model's response, waiting on a database-style lookup, waiting on a cookie to resolve. If the difference between `await callA()` and calling `callA()` and `callB()` without awaiting either first doesn't feel completely intuitive yet, this primer is for you. Get this mental model solid, and the rest of the course reads far more naturally.

## The Restaurant Order Analogy

Imagine you're at a restaurant with a friend, and you both want to order food. There are two ways this could go:

**Sequential (blocking) ordering:** You tell the waiter your order. The waiter walks to the kitchen, waits for your food to be fully cooked, brings it back to the table — *and only then* asks your friend what they want. Your friend's food doesn't even start cooking until yours is completely done and delivered. If each dish takes 10 minutes, the whole table waits 20 minutes before anyone can eat, even though nothing about cooking your dish and cooking your friend's dish depended on each other at all.

**Concurrent (non-blocking) ordering:** You and your friend both give your orders to the waiter one after another, quickly. The waiter passes both orders to the kitchen. Both dishes cook *at the same time*, each taking their own 10 minutes, and the whole table is eating in 10 minutes total — not 20 — because there was never any real reason to make one dish wait for the other.

This is exactly the distinction between awaiting things one at a time versus letting independent things run concurrently, which is the entire foundation of Phase 6's `Promise.all()` pattern.

## What a Promise Actually Is

A **Promise** in JavaScript is not the result itself — it's a placeholder, like a restaurant buzzer they hand you after you order. The buzzer doesn't have your food in it. It's a token that represents "your food is being prepared, and this buzzer will eventually let you know it's ready." You can hold that buzzer, do other things while waiting, and only "cash it in" (i.e., go get your food) when you're actually ready to.

```js
// Calling an async function does NOT wait for it to finish.
// It immediately returns a Promise — the "buzzer" — and the actual
// work (in this case, the setTimeout) continues in the background.
function orderFood() {
  return new Promise((resolve) => {
    setTimeout(() => resolve('Your burger is ready!'), 3000);
  });
}

const buzzer = orderFood(); // returns INSTANTLY — this is just the buzzer
console.log(buzzer); // Promise { <pending> } — not the food yet!
```

## `await`: "Cash In the Buzzer Now, and Wait Here Until It's Ready"

The `await` keyword is what actually pauses your code at that specific line, until the Promise resolves:

```js
async function getMyFood() {
  const buzzer = orderFood();       // order placed, buzzer in hand — code keeps running
  console.log('Doing other things while waiting...');
  const food = await buzzer;        // NOW we stop and wait for the buzzer to go off
  console.log(food);                // "Your burger is ready!"
}
```

Crucially: **`await` only pauses the function it's written inside** — it does not freeze your entire application. While one function is `await`-ing something, the rest of your server can keep handling completely unrelated requests from other users. This is why Node.js can serve thousands of concurrent requests on a single thread — nothing is ever truly "frozen" waiting; it's just one function's execution that's paused at that point, politely stepping aside so other work can proceed.

## Why `Promise.all()` Is Faster Than Awaiting One at a Time

This is the exact code pattern behind Phase 6's concurrent multi-agent system, boiled down to its simplest form:

```js
// SLOW: sequential. Each await fully blocks progress until that
// specific call finishes, before the NEXT one even starts.
const architect = await runArchitectAgent(input);  // waits ~2s
const security = await runSecurityAgent(input);    // only STARTS after the line above finishes — waits another ~2s
// Total: ~4 seconds, even though neither call depended on the other's result.

// FAST: concurrent. Both calls are STARTED immediately, back to back,
// with no await in between — meaning both are "in flight" over the
// network at the same time.
const architectPromise = runArchitectAgent(input); // starts immediately, returns a Promise instantly
const securityPromise = runSecurityAgent(input);   // ALSO starts immediately — doesn't wait for the line above
const [architect, security] = await Promise.all([architectPromise, securityPromise]);
// Total: ~2 seconds — roughly the time of the SLOWEST single call, not the SUM of both.
```

The key insight: **calling an async function starts its work immediately, whether or not you `await` it right away.** The only thing `await` controls is *when your code pauses to wait for the result* — not when the underlying work begins. If two pieces of work don't depend on each other's results, there's no reason to make one wait for the other to even start.

## Why `try`/`catch` Looks Different With Async Code

One subtlety worth internalizing before you hit Phase 1's error handling: a `try`/`catch` block around an `await`-ed call works exactly like it would around ordinary synchronous code — if the awaited Promise rejects (fails), execution jumps straight to `catch`, skipping everything else in the `try` block:

```js
async function safeCall() {
  try {
    const result = await riskyOperation(); // if this rejects, we jump straight to catch
    console.log('This line only runs if riskyOperation succeeded:', result);
  } catch (error) {
    console.log('Caught a failure:', error.message);
  }
}
```

This is exactly the pattern used in nearly every route handler across the entire course — and it's why the series consistently prefers Zod's `safeParse()` (which returns a checked result object) over `parse()` (which throws) for *expected*, routine validation failures, reserving `try`/`catch` for genuinely *exceptional* failures like a network error or a provider outage. Once this distinction feels natural, you're ready for every error-handling pattern in this course.
