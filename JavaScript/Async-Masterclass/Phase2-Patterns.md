## Phase 2: Evolution of Patterns

### 2.1 Callback Hell — The Original Async Pattern

Before Promises existed, async work was handled with plain callbacks: functions passed into other functions, to be invoked later. This worked fine for one async step. It became unmanageable for *sequences* of async steps.

**Learning Lab 2.1 — The Pyramid of Doom**

```javascript
function getUser(id, callback) {
  setTimeout(() => callback(null, { id, name: 'Ada' }), 300);
}
function getPosts(userId, callback) {
  setTimeout(() => callback(null, ['post1', 'post2']), 300);
}
function getComments(postId, callback) {
  setTimeout(() => callback(null, ['comment1']), 300);
}

getUser(1, (err, user) => {
  if (err) return console.error(err);
  getPosts(user.id, (err, posts) => {
    if (err) return console.error(err);
    getComments(posts[0], (err, comments) => {
      if (err) return console.error(err);
      console.log({ user, posts, comments });
      // Nesting keeps growing rightward with every new async step.
      // Error handling is duplicated at every single level.
    });
  });
});
```

Problems this creates: rightward drift ("Pyramid of Doom"), duplicated error-handling branches, no single funnel for errors, and difficulty composing/reusing steps.

> **Pro-Tip:** Callback hell isn't really about nesting depth — it's about *inversion of control*. You hand your continuation to a function you don't control and simply trust it will call you back correctly, exactly once, with the right arguments.

### 2.2 Promises — Anatomy of Pending / Fulfilled / Rejected

A Promise is an object representing the *eventual* result of an async operation. It exists in exactly one of three states at any time:

- **Pending**: initial state, neither fulfilled nor rejected yet.
- **Fulfilled**: the operation completed successfully; the promise now holds a value.
- **Rejected**: the operation failed; the promise now holds a reason (usually an Error).

Critically: once a promise transitions to fulfilled or rejected, it is **settled** — permanently locked in that state and value forever (immutability). You can attach `.then`/`.catch` handlers at any time, even after settlement, and they'll still fire correctly.

**Learning Lab 2.2 — Building and Consuming a Promise**

```javascript
function delay(ms, value, shouldFail = false) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (shouldFail) {
        reject(new Error(`Failed after ${ms}ms`));
      } else {
        resolve(value);
      }
    }, ms);
  });
}

delay(300, 'Hello from the future')
  .then((value) => {
    console.log('Fulfilled with:', value);
    return value.toUpperCase(); // .then always returns a NEW promise
  })
  .then((upper) => console.log('Chained:', upper))
  .catch((err) => console.error('Rejected with:', err.message))
  .finally(() => console.log('Always runs, success or failure'));
```

**Learning Lab 2.2b — Rewriting Callback Hell with Promise Chaining**

```javascript
function getUserP(id) {
  return new Promise((res) => setTimeout(() => res({ id, name: 'Ada' }), 300));
}
function getPostsP(userId) {
  return new Promise((res) => setTimeout(() => res(['post1', 'post2']), 300));
}
function getCommentsP(postId) {
  return new Promise((res) => setTimeout(() => res(['comment1']), 300));
}

getUserP(1)
  .then((user) => getPostsP(user.id).then((posts) => ({ user, posts })))
  .then(({ user, posts }) => getCommentsP(posts[0]).then((comments) => ({ user, posts, comments })))
  .then((result) => console.log(result))
  .catch((err) => console.error('Single funnel for ALL errors:', err));
```

Notice: **one** `.catch` at the bottom now catches a rejection from *any* step in the chain — this is the core win over callbacks.

> **Pro-Tip:** `.then(onFulfilled, onRejected)` technically accepts two arguments, but prefer `.then(...).catch(...)` — mixing the second argument into `.then` can silently swallow errors thrown inside the first callback.

### 2.3 Async/Await — Syntactic Sugar, Perfected

`async/await` doesn't replace Promises — it's built entirely on top of them. An `async` function always returns a Promise. `await` pauses that function's execution (without blocking the thread) until the awaited promise settles.

**Learning Lab 2.3 — The Same Chain, Now Linear**

```javascript
async function loadFeed(userId) {
  try {
    const user = await getUserP(userId);
    const posts = await getPostsP(user.id);
    const comments = await getCommentsP(posts[0]);
    return { user, posts, comments };
  } catch (err) {
    // ONE try/catch replaces every .catch() in the chain
    console.error('loadFeed failed:', err.message);
    throw err; // re-throw if the caller needs to react too
  } finally {
    console.log('loadFeed attempt finished (success or failure)');
  }
}

(async () => {
  const feed = await loadFeed(1);
  console.log(feed);
})();
```

**Learning Lab 2.3b — Sequential vs Concurrent Awaiting (a common beginner trap)**

```javascript
// SLOW (sequential): each await blocks the next line - 900ms total
async function sequential() {
  const a = await delay(300, 'A');
  const b = await delay(300, 'B');
  const c = await delay(300, 'C');
  return [a, b, c];
}

// FAST (concurrent): fire all three immediately, await together - ~300ms total
async function concurrent() {
  const pA = delay(300, 'A');
  const pB = delay(300, 'B');
  const pC = delay(300, 'C');
  return Promise.all([pA, pB, pC]);
}
```

> **Pro-Tip:** `await` inside a loop over independent async calls is one of the most common performance bugs in real codebases. If the calls don't depend on each other's results, start them all first, then await together (see Phase 3's `Promise.all`).

### Phase 2 Exercise

Refactor the following callback-based function into an `async/await` function with proper `try/catch`. It should fetch a user, then their account balance, then log a formatted summary. If either step fails, log a friendly error instead of crashing.

```javascript
function getUserCb(id, cb) { setTimeout(() => cb(null, { id, name: 'Grace' }), 200); }
function getBalanceCb(userId, cb) { setTimeout(() => cb(null, 1042.5), 200); }

// TODO: rewrite using promises + async/await
function printSummary(id, cb) {
  getUserCb(id, (err, user) => {
    if (err) return cb(err);
    getBalanceCb(user.id, (err, balance) => {
      if (err) return cb(err);
      cb(null, `${user.name}'s balance: $${balance}`);
    });
  });
}
```

### Phase 2 Solution

```javascript
function getUser(id) {
  return new Promise((resolve) => setTimeout(() => resolve({ id, name: 'Grace' }), 200));
}
function getBalance(userId) {
  return new Promise((resolve) => setTimeout(() => resolve(1042.5), 200));
}

async function printSummary(id) {
  try {
    const user = await getUser(id);
    const balance = await getBalance(user.id);
    const summary = `${user.name}'s balance: $${balance}`;
    console.log(summary);
    return summary;
  } catch (err) {
    console.error('Could not load account summary:', err.message);
  }
}

printSummary(1);
```

**Why this is better:** no rightward nesting, a single `try/catch` funnel for both steps, and the function now returns a real Promise so callers can `await printSummary(1)` or chain `.then()` on it — composable in a way the callback version never could be.
