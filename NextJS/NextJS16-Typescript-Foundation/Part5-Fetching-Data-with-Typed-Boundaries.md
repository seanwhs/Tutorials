# Next.js 16 TypeScript Foundations

# Part 5 — Fetching Data with Typed Boundaries: From Route Parameters to Real Applications

> **Series:** *From Confusing Layout Syntax to Confident Typed App Router Code*

In Part 4, we learned that dynamic routes create typed `params` objects.

For example:

```tsx
type Props = {
  params: {
    id: string;
  };
};

export default function ProductPage({
  params,
}: Props) {
  return (
    <h1>
      {params.id}
    </h1>
  );
}
```

This is useful.

But in real applications, we don't display IDs.

We display data.

When users visit:

```text
/products/123
```

they expect to see:

```text
Product Name
Price
Description
Reviews
Images
Inventory
```

This raises an important question:

> How do we safely move from route parameters to real application data?

This is where many developers begin writing code like this:

```tsx
export default async function ProductPage({
  params,
}: any) {
  const product = await fetch(
    `https://api.example.com/products/${params.id}`
  );

  return (
    <div>
      {(await product.json()).name}
    </div>
  );
}
```

The code works.

But it has several problems:

* no type safety
* no error handling
* no validation
* no separation of concerns
* difficult testing
* difficult maintenance

Professional applications solve this by creating **typed boundaries**.

In this lesson, we'll learn how to move data safely through our application.

---

# What Is A Typed Boundary?

A typed boundary is simply:

> A point where unknown data becomes known data.

Consider this:

```text
Internet
    ↓
Unknown Data
    ↓
Validation
    ↓
Typed Data
    ↓
UI
```

The important idea is:

> Never allow unknown data to flow directly into your components.

---

# The Simplest Fetch

Suppose we have:

```text
/products/123
```

Our first attempt might be:

```tsx
export default async function ProductPage({
  params,
}: {
  params: {
    id: string;
  };
}) {
  const response = await fetch(
    `https://api.example.com/products/${params.id}`
  );

  const product = await response.json();

  return (
    <h1>
      {product.name}
    </h1>
  );
}
```

This works.

But TypeScript now believes:

```typescript
product: any
```

which means:

```tsx
product.name
product.foo
product.bar
product.whatever
```

all compile.

That's dangerous.

---

# Step 1: Define A Type

First, define what a product looks like.

```typescript
type Product = {
  id: number;
  name: string;
  description: string;
  price: number;
};
```

Now we have a contract.

---

# Step 2: Create A Typed Fetch Function

Instead of fetching directly inside the page:

```tsx
async function getProduct(
  id: string
): Promise<Product> {
  const response = await fetch(
    `https://api.example.com/products/${id}`
  );

  return response.json();
}
```

Notice what happened.

Before:

```text
fetch
   ↓
any
```

Now:

```text
fetch
   ↓
Product
```

We've created our first typed boundary.

---

# Step 3: Use The Typed Function

Our page becomes:

```tsx
type ProductPageProps = {
  params: {
    id: string;
  };
};

export default async function ProductPage({
  params,
}: ProductPageProps) {
  const product = await getProduct(
    params.id
  );

  return (
    <>
      <h1>
        {product.name}
      </h1>

      <p>
        ${product.price}
      </p>
    </>
  );
}
```

Now TypeScript knows:

```typescript
product.name
```

exists.

---

# Visualizing The Data Flow

```text
URL
   ↓
params.id
   ↓
getProduct()
   ↓
Product
   ↓
UI
```

This is the core architecture of most Next.js applications.

---

# Why Separate Fetching From Rendering?

Beginners often write:

```tsx
export default async function ProductPage({
  params,
}) {
  const response = await fetch(...);

  const product = await response.json();

  // lots of business logic

  return (...);
}
```

Eventually this becomes:

```text
500 lines
1000 lines
1500 lines
```

Instead, separate concerns:

```text
Page
   ↓
Service
   ↓
Fetch
```

---

# Example Architecture

```text
app/
├── products/
│   └── [id]/
│       └── page.tsx
│
lib/
└── products.ts
```

---

# products.ts

```typescript
export type Product = {
  id: number;
  name: string;
  price: number;
};

export async function getProduct(
  id: string
): Promise<Product> {
  const response = await fetch(
    `https://api.example.com/products/${id}`
  );

  return response.json();
}
```

---

# page.tsx

```tsx
import {
  getProduct,
} from "@/lib/products";

export default async function ProductPage({
  params,
}: {
  params: {
    id: string;
  };
}) {
  const product = await getProduct(
    params.id
  );

  return (
    <h1>
      {product.name}
    </h1>
  );
}
```

Now our page is primarily responsible for rendering.

---

# What Happens When Fetch Fails?

Consider:

```text
/products/999999
```

Suppose the API returns:

```text
404
```

Our application crashes.

We need error handling.

---

# Handling Response Errors

```typescript
export async function getProduct(
  id: string
): Promise<Product> {
  const response = await fetch(
    `https://api.example.com/products/${id}`
  );

  if (!response.ok) {
    throw new Error(
      "Product not found"
    );
  }

  return response.json();
}
```

Now invalid responses become exceptions.

---

# Using `notFound()`

Next.js provides a helper:

```tsx
import { notFound } from "next/navigation";

export async function getProduct(
  id: string
): Promise<Product> {
  const response = await fetch(
    `https://api.example.com/products/${id}`
  );

  if (!response.ok) {
    notFound();
  }

  return response.json();
}
```

This automatically displays:

```text
not-found.tsx
```

if it exists.

---

# Error Boundaries

Suppose:

```text
fetch()
```

throws:

```text
Database Error
API Error
Network Error
```

Next.js can automatically render:

```text
error.tsx
```

---

# Example

```text
app/
└── products/
    └── [id]/
        ├── page.tsx
        └── error.tsx
```

---

# error.tsx

```tsx
"use client";

export default function Error({
  error,
}: {
  error: Error;
}) {
  return (
    <div>
      Failed to load:
      {error.message}
    </div>
  );
}
```

Now failures become user-friendly.

---

# Server Components Change Everything

In traditional React:

```text
Browser
    ↓
Fetch
    ↓
Loading Spinner
    ↓
Render
```

In Next.js App Router:

```text
Server
    ↓
Fetch
    ↓
Render
    ↓
Send HTML
```

This means:

```tsx
export default async function Page() {
  const data = await fetch(...);

  return <div />;
}
```

is perfectly valid.

---

# Why This Is Powerful

Benefits:

* faster page loads
* better SEO
* smaller bundles
* fewer client requests
* improved security

---

# Fetch Caching

One of the biggest surprises in Next.js:

```tsx
await fetch(...)
```

is cached by default.

Example:

```tsx
const response = await fetch(
  "https://api.example.com/products"
);
```

Next.js may reuse this result.

---

# Disabling Cache

For dynamic data:

```tsx
await fetch(url, {
  cache: "no-store",
});
```

This means:

```text
Always fetch fresh data.
```

---

# Revalidation

Sometimes we want caching.

But only temporarily.

Example:

```tsx
await fetch(url, {
  next: {
    revalidate: 60,
  },
});
```

This means:

```text
Cache for 60 seconds.
```

---

# Visualizing Cache Behavior

```text
Request
    ↓
Cache Exists?
      ↓
    Yes ------> Return Cache
      ↓
    No
      ↓
Fetch API
      ↓
Store Cache
      ↓
Return Data
```

---

# Real Ecommerce Example

Suppose:

```text
/products/123
```

Our flow becomes:

```text
URL
   ↓
params.id
   ↓
getProduct()
   ↓
fetch()
   ↓
cache
   ↓
validation
   ↓
typed Product
   ↓
render UI
```

---

# Why Validation Matters

Suppose the API returns:

```json
{
  "title": "Laptop"
}
```

instead of:

```json
{
  "name": "Laptop"
}
```

Without validation:

```tsx
product.name
```

becomes:

```text
undefined
```

Production applications often validate responses using:

* Zod
* Valibot
* ArkType

For example:

```typescript
const ProductSchema = z.object({
  id: z.number(),
  name: z.string(),
  price: z.number(),
});
```

Now invalid responses fail immediately.

---

# A Production Folder Structure

Large applications often use:

```text
app/
lib/
services/
schemas/
types/
```

Example:

```text
lib/
├── api.ts
├── products.ts
├── users.ts

schemas/
├── product.ts
├── user.ts

types/
├── product.ts
├── user.ts
```

This separates:

* fetching
* validation
* typing
* rendering

---

# Common Beginner Mistakes

## Mistake #1

Using:

```typescript
any
```

everywhere.

---

## Mistake #2

Fetching directly inside every component.

---

## Mistake #3

Ignoring failed responses.

---

## Mistake #4

Assuming API responses are always correct.

---

## Mistake #5

Putting business logic inside JSX.

---

# Mental Model

Whenever you fetch data, think:

```text
Unknown Data
      ↓
Fetch
      ↓
Validate
      ↓
Type
      ↓
Render
```

Never skip the middle steps.

---

# Practice Exercise

Build:

```text
app/
└── products/
    └── [id]/
        ├── page.tsx
        ├── error.tsx
        └── not-found.tsx
```

Create:

```typescript
type Product = {
  id: number;
  name: string;
  price: number;
};
```

Then:

1. Create `getProduct()`
2. Add error handling
3. Add `notFound()`
4. Add cache control
5. Render the product

Observe how data flows from:

```text
URL
   ↓
params
   ↓
fetch
   ↓
typed object
   ↓
UI
```

---

# What You've Learned

You now understand:

✓ typed boundaries

✓ typed fetch functions

✓ separating fetching from rendering

✓ server-side data fetching

✓ error handling

✓ `notFound()`

✓ `error.tsx`

✓ caching

✓ revalidation

✓ validation

✓ production folder structures

Most importantly, you've learned that good Next.js applications don't pass unknown data directly into UI components.

They create typed boundaries that transform unknown data into trusted application data.

In Part 6, we'll bring everything together and explore the patterns, conventions, and pitfalls that separate tutorial projects from production-grade Next.js applications.
