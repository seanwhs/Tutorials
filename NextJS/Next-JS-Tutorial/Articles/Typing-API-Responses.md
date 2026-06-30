# Mastering Type Safety in Async Workflows: Typing API Responses in TypeScript

Once your local data structures are strongly typed, the next challenge is the boundary between your app and the outside world. That boundary is where most bugs happen: network failures, malformed payloads, missing fields, and inconsistent response shapes. TypeScript helps you make those failure modes visible before they reach production.

Unlike static objects you define yourself, API responses are only partially under your control. That means the safest approach is to treat every async response as uncertain until you have validated or narrowed it. With `strictNullChecks` enabled, TypeScript forces you to account for `null` and `undefined` instead of quietly assuming they do not exist. [typescriptlang](https://www.typescriptlang.org/tsconfig/strictNullChecks.html)

### Why Async Types Matter

Async data usually arrives in one of three forms: a successful payload, an error response, or an empty state. If you do not model these states explicitly, your code tends to accumulate defensive checks in random places. Strong typing gives you a single source of truth for what each state looks like.

A good mental model is this: local code can be trusted, remote code must be verified. That is why annotations alone are not enough for external data; they should be paired with runtime validation when the source is untrusted.

### Typing a Simple Fetch Response

A common pattern is to define a response shape and use it as the return type of your async function.

```ts
type User = {
  id: number;
  name: string;
  email: string;
};

async function getUser(id: number): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) {
    throw new Error("Failed to fetch user");
  }

  return res.json();
}
```

This gives callers a clear contract: if the promise resolves, they receive a `User`. The return type also makes refactors safer because any mismatch between the declared shape and the real data becomes easier to spot.

### Modeling Loading and Error States

In UI code, the response itself is only part of the story. You also need to represent loading, success, and failure states.

```ts
type ApiState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; message: string };
```

This pattern works especially well in React because it keeps state transitions explicit. Instead of relying on loose booleans like `isLoading` and `hasError`, your component can reason about one structured state object.

### Using Generics for Reusability

Generics are the cleanest way to make async typing reusable across multiple endpoints.

```ts
async function request<T>(url: string): Promise<T> {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error("Request failed");
  }

  return res.json();
}

const user = await request<User>("/api/users/1");
```

This pattern is useful when building API clients, data layers, or shared utility functions. It lets you preserve type safety without rewriting the same logic for every endpoint.

### Validate Before You Trust

Type annotations describe what you expect; they do not prove that the server sent it. If an API is external, changing, or loosely controlled, add runtime validation with a schema library before you trust the response.

A practical rule is:
- Use TypeScript types to describe the shape you want.
- Use runtime validation to confirm the shape you actually received.

That combination is much stronger than either one alone.

### React and Async Data

In React, typed async data becomes especially valuable in hooks and props. If your component depends on a `User` object, typing that prop clearly prevents accidental misuse. For `children`, `React.ReactNode` remains the right choice because it covers everything React can render, including strings, elements, arrays, and `null` or `undefined`. [medium](https://medium.com/@nsaiaparanji/summary-notes-on-children-reactnode-in-react-typescript-reactnode-vs-any-71c6927ae240)

```ts
interface UserCardProps {
  user: User;
  children?: React.ReactNode;
}
```

This keeps your component flexible while still preserving strict boundaries around the data it expects.

### Common Mistakes

A few mistakes show up repeatedly in async TypeScript code:

- Returning `any` from API helpers, which removes the main benefit of TypeScript.
- Assuming `fetch(...).json()` is automatically safe, even though the payload may not match your type.
- Ignoring `undefined` in state or optional fields when `strictNullChecks` is enabled. [typescriptlang](https://www.typescriptlang.org/tsconfig/strictNullChecks.html)
- Using overly broad types that make every response look valid.

The fix is usually to narrow sooner, validate earlier, and make each state explicit.

### Closing Thought

The real power of TypeScript is not just in typing variables, but in making boundaries visible. Async boundaries are the most important ones in modern applications, because they connect trusted code to untrusted data.
