Here's Appendix B.

---

# Appendix B — TypeScript's `"strict": true`, Flag by Flag

In Part 0, we enabled `"strict": true` in `tsconfig.json` with a one-line justification: "the single most important flag." This appendix unpacks exactly what that one setting actually turns on, since it's really shorthand for eight distinct compiler checks bundled together.

## The Flags Inside `strict`

| Flag | What It Catches | Example of What It Prevents |
|---|---|---|
| `noImplicitAny` | Variables/parameters TypeScript can't infer a type for, silently treated as `any` (meaning "skip all checking on this") | `function log(msg) { ... }` — without strict mode, `msg` silently becomes `any`; with it, TypeScript forces you to write `function log(msg: string)` |
| `strictNullChecks` | Using a possibly `null`/`undefined` value as if it's guaranteed to exist | Prevents `user.email.toLowerCase()` from compiling if `user` might be `undefined` — forces a check first |
| `strictFunctionTypes` | Unsound function parameter comparisons when assigning one function type to another | Catches subtle type-safety holes in callback-heavy code (e.g. event handlers, `.map()` callbacks) |
| `strictBindCallApply` | Type-checks the arguments passed to `.bind()`, `.call()`, `.apply()` | Prevents `fn.call(obj, "wrong", "args")` from silently compiling with mismatched argument types |
| `strictPropertyInitialization` | Class properties declared but never assigned a value in the constructor | Prevents a class field like `apiKey: string;` from being `undefined` at runtime despite its type claiming otherwise |
| `noImplicitThis` | Using `this` in a context where its type can't be determined | Common trap in old-style callback functions where `this` doesn't refer to what you expect |
| `alwaysStrict` | Emits `"use strict"` in compiled output, enabling JavaScript's own runtime strict mode | Catches JS-level footguns like accidental global variable creation |
| `useUnknownInCatchVariables` | Types a `catch` block's error variable as `unknown` instead of `any` | Forces you to narrow the type (e.g. `if (error instanceof Error)`) before accessing properties like `.message` |

## Why This Series Leaned on Specific Flags Repeatedly

**`useUnknownInCatchVariables`** is the exact reason Part 0's dial-tone script and every later error-handling block used this pattern:

```typescript
} catch (error) {
  if (error instanceof OpenAI.APIError) {
    console.error(`❌ OpenAI API error [${error.status}]: ${error.message}`);
  } else {
    console.error("❌ Unexpected error:", error);
  }
}
```

Without strict mode, `error` would be typed `any`, and you could write `error.status` directly — compiling fine, but crashing at runtime the moment something threw a plain string or a non-`APIError` object instead. Strict mode forces the `instanceof` check first, which is exactly the discipline that made our error handling actually safe rather than just *look* safe.

**`strictNullChecks`** is why `noUncheckedIndexedAccess` (a separate, non-bundled flag we also enabled manually in Part 0) mattered so much once we started working with arrays of retrieved chunks in Part 3-4: `results[0]` is typed as possibly `undefined`, forcing patterns like:

```typescript
const embedding = embeddings[i];
if (!embedding) {
  throw new Error(`Missing embedding for chunk at index ${i}`);
}
```

instead of silently trusting an index that might not exist — precisely the kind of bug that would otherwise surface as a confusing runtime crash deep inside a retrieval pipeline, far from where the actual mistake was made.

## The One Rule Worth Remembering

If a type error ever tempts you to reach for `// @ts-ignore` or flip a strict flag off to "fix" it: don't. That's disabling the smoke detector instead of putting out the fire. In nearly every case across this series, the type error was pointing at a real, latent bug (an unhandled `undefined`, an unchecked error shape) — not a false alarm. Strict mode's entire value proposition is trading a few extra minutes of upfront friction for entire categories of runtime crashes that never happen in the first place.
