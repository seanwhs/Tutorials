# Next.js 16 for Absolute Beginners

# Part 12 — Forms, Validation, and User Input

> **Goal of this lesson:** Learn how to build production-grade forms in Next.js 16 using Server Actions, validation, pending states, error handling, and optimistic UI.

---

# Forms Are the Heart of Web Applications

Almost every real application contains forms.

Examples:

```text
Login Form
Registration Form
Search Form
Contact Form
Checkout Form
Blog Editor
Comment Form
Settings Page
```

The web itself was originally designed around forms.

---

# A Simple HTML Form

Before React existed, forms looked like this:

```html
<form>

    <input
        name="email"
    />

    <button>
        Submit
    </button>

</form>
```

The browser already knows how to:

* collect values
* validate required fields
* submit data
* redirect pages

Modern frameworks build on top of this foundation.

---

# Next.js Embraces Native Forms

In Next.js:

```tsx
<form action={login}>

    <input
        name="email"
    />

    <button>
        Login
    </button>

</form>
```

The browser submits:

```text
Form
   |
   V
Server Action
   |
   V
Database
```

No API route required.

---

# Building Our First Real Form

---

## app/actions.ts

```tsx
"use server";

export async function createUser(
    formData: FormData
) {

    const name =
        formData.get("name");

    const email =
        formData.get("email");

    console.log(
        name,
        email
    );
}
```

---

## app/page.tsx

```tsx
import {
    createUser
} from "./actions";

export default function Page() {

    return (
        <form
            action={createUser}
        >

            <input
                name="name"
                placeholder="Name"
            />

            <input
                name="email"
                placeholder="Email"
            />

            <button>
                Submit
            </button>

        </form>
    );
}
```

---

# Visualizing Form Submission

```text
User Types
      |
      V

HTML Form
      |
      V

Browser Creates FormData
      |
      V

Server Action
      |
      V

Database
```

---

# The First Problem

What happens if:

```text
Name: empty
Email: empty
```

We need validation.

---

# Manual Validation

Example:

```tsx
"use server";

export async function createUser(
    formData: FormData
) {

    const name =
        formData.get("name");

    const email =
        formData.get("email");

    if (!name) {

        return {
            error:
                "Name required",
        };

    }

    if (!email) {

        return {
            error:
                "Email required",
        };

    }

    return {
        success: true,
    };
}
```

---

# Visualizing Validation

```text
Request
   |
   V

Validate
   |
   +--- Invalid
   |         |
   |         V
   |      Return Error
   |
   +--- Valid
             |
             V
         Save Data
```

---

# useActionState()

React provides:

```tsx
useActionState()
```

to connect forms with Server Actions.

---

# Example

```tsx
"use client";

import {
    useActionState
} from "react";
```

---

```tsx
const [
    state,
    action,
    pending,
] = useActionState(
    createUser,
    null
);
```

---

# Visualizing useActionState()

```text
Server Action
      |
      V

Return State
      |
      V

React State
      |
      V

UI Updates
```

---

# Complete Example

---

## actions.ts

```tsx
"use server";

export async function createUser(
    previousState: any,
    formData: FormData
) {

    const name =
        formData.get("name");

    if (!name) {

        return {
            error:
                "Name required",
        };

    }

    return {
        success: true,
    };
}
```

---

## UserForm.tsx

```tsx
"use client";

import {
    useActionState
} from "react";

import {
    createUser
} from "@/app/actions";

export default function UserForm() {

    const [
        state,
        action,
        pending,
    ] = useActionState(
        createUser,
        null
    );

    return (
        <form action={action}>

            <input
                name="name"
            />

            <button
                disabled={pending}
            >
                Submit
            </button>

            {state?.error && (
                <p>
                    {state.error}
                </p>
            )}

        </form>
    );
}
```

---

# Pending State

During submission:

```text
pending = true
```

After submission:

```text
pending = false
```

---

# Building Loading Buttons

Example:

```tsx
<button
    disabled={pending}
>

    {pending
        ? "Saving..."
        : "Save"}

</button>
```

---

# Visualizing Loading States

```text
User Clicks
      |
      V

Saving...

      |
      V

Success
```

---

# Multiple Validation Errors

Instead of:

```tsx
return {
    error:
        "Name required"
};
```

we can do:

```tsx
return {
    errors: {
        name:
            "Required",

        email:
            "Invalid",
    },
};
```

---

# Example

```tsx
"use server";

export async function register(
    previousState: any,
    formData: FormData
) {

    const errors: any = {};

    const name =
        formData.get("name");

    const email =
        formData.get("email");

    if (!name) {
        errors.name =
            "Required";
    }

    if (!email) {
        errors.email =
            "Required";
    }

    if (
        Object.keys(errors)
            .length
    ) {

        return {
            errors,
        };
    }

    return {
        success: true,
    };
}
```

---

# Rendering Validation Errors

```tsx
<input name="name" />

{
    state?.errors?.name &&
    (
        <p>
            {
                state.errors.name
            }
        </p>
    )
}
```

---

# Visualizing Error States

```text
Name
  |
  +--- Required

Email
  |
  +--- Invalid
```

---

# HTML Validation Still Works

Example:

```tsx
<input
    required
    type="email"
/>
```

Browser validation:

```text
Before submit
       |
       V
Validate
       |
       V
Show error
```

Use both:

```text
Browser validation
          +
Server validation
```

---

# Why Server Validation Is Mandatory

Never trust the browser.

Bad:

```text
Browser validates
       |
       V
Database
```

Good:

```text
Browser validates
       |
       V
Server validates
       |
       V
Database
```

---

# Introducing Zod

Professional applications usually use:

Zod

Install:

```bash
npm install zod
```

---

# Example Schema

```tsx
import {
    z
} from "zod";

const UserSchema =
    z.object({

        name:
            z.string()
             .min(1),

        email:
            z.email(),

    });
```

---

# Validation

```tsx
const result =
    UserSchema.safeParse({

        name,
        email,

    });

if (!result.success) {

    return {
        errors:
            result.error
                .flatten(),
    };

}
```

---

# Visualizing Zod

```text
Input
   |
   V

Schema
   |
   +--- Valid
   |
   +--- Invalid
```

---

# Resetting Forms

Suppose:

```text
Submit
     |
     V
Success
```

We want:

```text
Clear form
```

Use:

```tsx
<form action={action}>
```

with:

```tsx
redirect()
```

or:

```tsx
formRef.current.reset();
```

inside client components.

---

# Optimistic UI

Suppose saving takes:

```text
3 seconds
```

Waiting feels slow.

Instead:

```text
Show success immediately
```

This is called:

# Optimistic UI

---

# Traditional Flow

```text
Submit
   |
Wait
   |
Wait
   |
Wait
   |
Success
```

---

# Optimistic Flow

```text
Submit
   |
Success
   |
Background save
```

---

# Example

Suppose adding a todo:

```tsx
todos.push({
    text:
        "Learn Next.js"
});
```

Instead of:

```text
Wait
```

we immediately show:

```text
Learn Next.js
```

then confirm later.

---

# useOptimistic()

React provides:

```tsx
useOptimistic()
```

Example:

```tsx
const [
    optimisticTodos,
    addOptimistic,
] = useOptimistic(
    todos,
    (
        state,
        newTodo
    ) => [
        ...state,
        newTodo,
    ]
);
```

---

# Visualizing Optimistic UI

```text
Click
   |
Show New Item
   |
Save
   |
Success
```

---

# Failure Scenario

```text
Click
   |
Show Item
   |
Save
   |
FAILED
   |
Remove Item
```

---

# Search Forms

Example:

```tsx
<form>

    <input
        name="search"
    />

    <button>
        Search
    </button>

</form>
```

Result:

```text
/search?q=react
```

Search forms often don't need Server Actions.

---

# Login Form Example

```tsx
<form action={login}>

    <input
        name="email"
        type="email"
        required
    />

    <input
        name="password"
        type="password"
        required
    />

    <button>
        Login
    </button>

</form>
```

---

# Registration Form Example

```tsx
<form action={register}>

    <input
        name="name"
    />

    <input
        name="email"
    />

    <input
        name="password"
    />

    <button>
        Register
    </button>

</form>
```

---

# Comment Form Example

```tsx
<form action={createComment}>

    <textarea
        name="comment"
    />

    <button>
        Post
    </button>

</form>
```

---

# Professional Folder Structure

```text
app/

    actions/

        auth.ts
        posts.ts
        comments.ts

components/

    forms/

        LoginForm.tsx
        RegisterForm.tsx
        CommentForm.tsx

schemas/

    auth.ts
    posts.ts
```

---

# The Professional Rule

Always validate:

```text
Browser
     +
Server
     +
Database
```

Never trust:

```text
User Input
```

---

# Exercises

## Exercise 1

Build:

```text
Registration Form
```

with:

* name
* email
* password

---

## Exercise 2

Add:

```text
pending state
```

using:

```tsx
useActionState()
```

---

## Exercise 3

Add:

```text
Zod validation
```

to:

```text
createUser()
```

---

# What You've Learned

You now understand:

✅ forms

✅ `FormData`

✅ `useActionState()`

✅ pending states

✅ validation

✅ error handling

✅ Zod

✅ optimistic UI

✅ production form design

---

# Mental Model

Don't think:

```text
Forms
    ↓
Submit data
```

Think:

```text
Forms
    ↓
Validate
    ↓
Mutate
    ↓
Invalidate cache
    ↓
Refresh UI
```

Forms are the primary way users interact with your application.

---

# Part 13 Preview

In the next chapter we'll learn:

# Databases and Data Fetching

Including:

* connecting databases
* PostgreSQL
* Prisma
* data access layers
* repositories
* transactions
* connection pooling
* server-side data fetching
* production data architecture

This is where we'll move from toy applications to real-world application architecture.
