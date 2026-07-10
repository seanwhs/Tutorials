# Part 3: The Component Bloat

## The Habit You Need to Break

Two habits made component trees bloated and hard to navigate: wrapping every reusable input in `forwardRef`, and passing data down through five layers of props ("prop drilling") because Context felt heavyweight or you needed to read it conditionally. React 19 removes both excuses with "ref as a prop" and the `use` API, plus a clearer mental model for splitting Server and Client components.

---

## 1. The Anti-Pattern: forwardRef Everywhere

```tsx
// components/TextInput.tsx (React 18 style - DO NOT COPY)
"use client";

import { forwardRef } from "react";

interface TextInputProps {
  label: string;
  placeholder?: string;
}

const TextInput = forwardRef<HTMLInputElement, TextInputProps>(
  function TextInput({ label, placeholder }, ref) {
    return (
      <label>
        {label}
        <input ref={ref} placeholder={placeholder} />
      </label>
    );
  }
);

export default TextInput;
```

```tsx
// components/LoginCard.tsx (React 18 style - DO NOT COPY)
"use client";

import { useRef } from "react";
import TextInput from "@/components/TextInput";

export default function LoginCard() {
  const emailRef = useRef<HTMLInputElement>(null);

  function focusEmail() {
    emailRef.current?.focus();
  }

  return (
    <div>
      <TextInput ref={emailRef} label="Email" placeholder="you@example.com" />
      <button onClick={focusEmail}>Focus Email</button>
    </div>
  );
}
```

### Why This Feels "Right" But Isn't
- Every reusable input, button, or wrapper component needs a special `forwardRef` wrapper just to forward a single ref through.
- `forwardRef`'s type signature (`forwardRef<RefType, PropsType>`) is backwards from how you write every other component's props, which confuses beginners.
- It adds an extra layer of nesting in React DevTools and an extra function call for no product benefit.

---

## 2. The Anti-Pattern: Prop Drilling for Theme/Context-like Data

```tsx
// React 18 style - DO NOT COPY
"use client";

function App({ theme }: { theme: "light" | "dark" }) {
  return <Page theme={theme} />;
}

function Page({ theme }: { theme: "light" | "dark" }) {
  return <Sidebar theme={theme} />;
}

function Sidebar({ theme }: { theme: "light" | "dark" }) {
  return <UserCard theme={theme} />;
}

function UserCard({ theme }: { theme: "light" | "dark" }) {
  return <div className={theme === "dark" ? "bg-black text-white" : "bg-white"}>Profile</div>;
}
```

### The Problem, Explained Simply
- `theme` is threaded through 3 components that don't use it themselves, just to reach `UserCard`.
- Adding a new prop means touching every intermediate component's signature.
- Refactoring the tree (removing/renaming `Sidebar`) breaks the whole chain.
- Developers reached for Context to fix this, but the old `useContext` hook has to be called unconditionally at the top of a component — you can't read Context only inside an `if` branch, which pushed some people right back to prop drilling in conditional-render scenarios.

---

## 3. The Modern React 19 Solution

### Step 1: Ref as a Prop (No More forwardRef)

```tsx
// components/TextInput.tsx (React 19)
"use client";

interface TextInputProps {
  label: string;
  placeholder?: string;
  ref?: React.Ref<HTMLInputElement>;
}

export default function TextInput({ label, placeholder, ref }: TextInputProps) {
  return (
    <label>
      {label}
      <input ref={ref} placeholder={placeholder} />
    </label>
  );
}
```

```tsx
// components/LoginCard.tsx (React 19)
"use client";

import { useRef } from "react";
import TextInput from "@/components/TextInput";

export default function LoginCard() {
  const emailRef = useRef<HTMLInputElement>(null);

  function focusEmail() {
    emailRef.current?.focus();
  }

  return (
    <div>
      <TextInput ref={emailRef} label="Email" placeholder="you@example.com" />
      <button onClick={focusEmail}>Focus Email</button>
    </div>
  );
}
```

`ref` is now just a regular prop. Destructure it like any other prop, type it with `React.Ref<T>`, and pass it straight to the DOM element. No wrapper function, no special generic signature.

### Step 2: The `use` API for Conditional Context Reads

```tsx
// context/ThemeContext.tsx
"use client";

import { createContext } from "react";

export type Theme = "light" | "dark";
export const ThemeContext = createContext<Theme>("light");
```

```tsx
// components/UserCard.tsx (React 19)
"use client";

import { use } from "react";
import { ThemeContext } from "@/context/ThemeContext";

export default function UserCard({ showTheme }: { showTheme: boolean }) {
  // `use` can be called conditionally — unlike useContext
  if (showTheme) {
    const theme = use(ThemeContext);
    return (
      <div className={theme === "dark" ? "bg-black text-white" : "bg-white"}>
        Profile
      </div>
    );
  }

  return <div>Profile</div>;
}
```

Only `UserCard` reads `ThemeContext` — `Page` and `Sidebar` no longer need to know it exists. No prop drilling.

### Step 3: The `use` API for Unwrapping Promises (Streaming from Server to Client)

```tsx
// app/dashboard/page.tsx (Server Component)
import { Suspense } from "react";
import Comments from "@/components/Comments";

async function getComments(postId: string) {
  const res = await fetch("https://api.example.com/posts/" + postId + "/comments");
  return res.json();
}

export default function DashboardPage({ postId }: { postId: string }) {
  // Do NOT await here — pass the Promise straight down to stream it in
  const commentsPromise = getComments(postId);

  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<p>Loading comments...</p>}>
        <Comments commentsPromise={commentsPromise} />
      </Suspense>
    </div>
  );
}
```

```tsx
// components/Comments.tsx (Client Component)
"use client";

import { use } from "react";

interface Comment {
  id: string;
  text: string;
}

export default function Comments({
  commentsPromise,
}: {
  commentsPromise: Promise<Comment[]>;
}) {
  // `use` suspends this component until the promise resolves,
  // triggering the nearest <Suspense> fallback automatically
  const comments = use(commentsPromise);

  return (
    <ul>
      {comments.map((c) => (
        <li key={c.id}>{c.text}</li>
      ))}
    </ul>
  );
}
```

The page shell renders immediately; comments stream in when ready, with no manual `isLoading` state anywhere.

### Step 4: Proper Client vs. Server Component Splitting

```tsx
// app/posts/[id]/page.tsx (Server Component — no "use client")
import LikeButton from "@/components/LikeButton";

async function getPost(id: string) {
  const res = await fetch("https://api.example.com/posts/" + id);
  return res.json();
}

export default async function PostPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const post = await getPost(id);

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.body}</p>
      {/* Only the interactive piece is a Client Component */}
      <LikeButton postId={post.id} initialLikes={post.likes} />
    </article>
  );
}
```

```tsx
// components/LikeButton.tsx (Client Component — needs interactivity)
"use client";

import { useState } from "react";
import { likePostAction } from "@/app/actions/posts";

export default function LikeButton({
  postId,
  initialLikes,
}: {
  postId: string;
  initialLikes: number;
}) {
  const [likes, setLikes] = useState(initialLikes);

  async function handleLike() {
    setLikes((n) => n + 1);
    await likePostAction(postId);
  }

  return <button onClick={handleLike}>👍 {likes}</button>;
}
```

```ts
// app/actions/posts.ts (Server Action, called from a Client Component)
"use server";

export async function likePostAction(postId: string) {
  await fetch("https://api.example.com/posts/" + postId + "/like", {
    method: "POST",
  });
}
```

**The rule:** default to Server Components (no directive needed). Add `"use client"` only to the specific leaf components that need interactivity (`useState`, event handlers, browser APIs). Add `"use server"` only to functions the client needs to invoke as mutations. This keeps the vast majority of your component tree — and its dependencies — out of the client JS bundle entirely.

---

## 4. Migration Steps

1. **Search your codebase for `forwardRef`.** For each usage, delete the wrapper and add `ref` as a normal destructured prop typed `React.Ref<T>`.
2. **Search for prop chains 3+ levels deep** that only exist to pass data through. Replace with a Context + `use()` read at the exact component that needs the value.
3. **Identify components currently marked `"use client"` "just in case."** Remove the directive if the component has no state, effects, or event handlers — let it become a Server Component by default.
4. **For components needing server-fetched data but rendered inside a Client subtree,** pass a Promise down as a prop and unwrap it with `use()` inside a `<Suspense>` boundary, instead of fetching in `useEffect`.
5. **Move mutation logic into `"use server"` functions** rather than calling `fetch` directly from client event handlers.

---

## Quick Checklist

- [ ] No `forwardRef` — `ref` is destructured as a normal prop
- [ ] No prop chains longer than 2 levels for data unrelated to the intermediate component
- [ ] `use(Context)` used for conditional or deeply-nested reads instead of drilling
- [ ] `use(promise)` + `<Suspense>` used for streaming server data into Client Components
- [ ] `"use client"` applied only to genuinely interactive leaf components
- [ ] `"use server"` applied only to functions invoked as mutations from the client
- [ ] Server Components remain the default for anything without interactivity

**Next:** Part 4: The Performance and Hydration Killers — index-as-key, Context re-render storms, Suspense placement, and deploying to free tiers.
