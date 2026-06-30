# Next.js 16 TypeScript Foundations

# Part 4 — Dynamic Routes and Typed `params`: Understanding Where Route Data Comes From

> **Series:** *From Confusing Layout Syntax to Confident Typed App Router Code*

In Part 3, we learned that a Next.js application is not a collection of pages.

It's a tree of layouts and pages.

Now we're going to answer another question that confuses almost every developer learning the App Router:

> Where does `params` come from?

When developers first encounter code like this:

```tsx
export default function ProductPage({
  params,
}: {
  params: {
    id: string;
  };
}) {
  return (
    <h1>
      Product: {params.id}
    </h1>
  );
}
```

they often ask:

* Who created `params`?
* Why does it suddenly appear?
* Why is `id` a string?
* Where does the value come from?
* Why do some routes use `slug` instead of `id`?
* Why does TypeScript need us to define it?

The answer is surprisingly simple:

> The filesystem creates the route.
>
> The route creates the parameters.
>
> Next.js injects those parameters into your component.

Once you understand this flow, dynamic routes stop feeling magical and start feeling predictable.

---

# Static Routes Versus Dynamic Routes

Let's begin with ordinary routes.

Suppose we have:

```text
app/
├── page.tsx
├── about/
│   └── page.tsx
└── products/
    └── page.tsx
```

These produce:

```text
/
/about
/products
```

These are called **static routes** because their URLs never change.

---

# The Problem With Static Routes

Imagine an ecommerce site.

You might have:

```text
/products/1
/products/2
/products/3
/products/4
```

Creating separate folders would be ridiculous:

```text
products/
    ├── 1/
    ├── 2/
    ├── 3/
    └── 4/
```

Instead, we need a placeholder.

---

# Enter Dynamic Routes

In the App Router, square brackets create dynamic segments.

For example:

```text
app/
└── products/
    └── [id]/
        └── page.tsx
```

This tells Next.js:

> "Match any value here and call it `id`."

Now all of these URLs become valid:

```text
/products/1
/products/2
/products/100
/products/999
```

---

# Where Does `params` Come From?

Suppose a user visits:

```text
/products/42
```

Next.js examines the folder structure:

```text
products/[id]
```

It notices:

```text
[id]
```

means:

```text
Create parameter:
    id
```

Therefore Next.js internally constructs:

```javascript
{
  id: "42"
}
```

and injects it into your page.

Conceptually:

```tsx
ProductPage({
  params: {
    id: "42",
  },
});
```

---

# The Simplest Example

```tsx
export default function ProductPage({
  params,
}) {
  return (
    <h1>
      {params.id}
    </h1>
  );
}
```

Visiting:

```text
/products/123
```

produces:

```html
<h1>123</h1>
```

---

# Visualizing The Flow

```text
URL
 ↓
/products/123
 ↓
Folder Match
 ↓
products/[id]
 ↓
Parameter Object
 ↓
{ id: "123" }
 ↓
Page Component
```

This is the entire dynamic routing mechanism.

---

# Why Is `id` A String?

This surprises many developers.

Suppose you visit:

```text
/products/123
```

You might expect:

```typescript
id: number
```

But URLs are text.

Therefore:

```typescript
params.id
```

is always:

```typescript
string
```

For example:

```text
/products/123
```

becomes:

```typescript
{
  id: "123"
}
```

not:

```typescript
{
  id: 123
}
```

---

# Converting To Numbers

If you need a number:

```tsx
const productId = Number(params.id);
```

or:

```tsx
const productId = parseInt(
  params.id,
  10
);
```

Never assume route parameters are numbers.

---

# Typing `params`

Without TypeScript:

```tsx
export default function ProductPage({
  params,
}) {
  return (
    <div>
      {params.id}
    </div>
  );
}
```

With TypeScript:

```tsx
type ProductPageProps = {
  params: {
    id: string;
  };
};

export default function ProductPage({
  params,
}: ProductPageProps) {
  return (
    <div>
      {params.id}
    </div>
  );
}
```

We're simply describing what Next.js injects.

---

# Why Doesn't Next.js Infer This Automatically?

This is an excellent question.

Consider:

```text
[id]
```

Should TypeScript infer:

```typescript
number?
string?
uuid?
```

Next.js can't know.

So the developer provides the type information.

---

# Using Other Parameter Names

The name inside the brackets becomes the property name.

For example:

```text
app/blog/[slug]
```

creates:

```typescript
params.slug
```

---

```text
app/users/[userId]
```

creates:

```typescript
params.userId
```

---

```text
app/[locale]
```

creates:

```typescript
params.locale
```

---

# Example: Blog Slugs

Folder structure:

```text
app/
└── blog/
    └── [slug]/
        └── page.tsx
```

Page:

```tsx
type Props = {
  params: {
    slug: string;
  };
};

export default function BlogPost({
  params,
}: Props) {
  return (
    <article>
      {params.slug}
    </article>
  );
}
```

URL:

```text
/blog/nextjs-tutorial
```

produces:

```typescript
params.slug
```

equal to:

```typescript
"nextjs-tutorial"
```

---

# Multiple Parameters

Suppose we have:

```text
app/
└── shop/
    └── [category]/
        └── [productId]/
            └── page.tsx
```

Now:

```text
/shop/laptops/123
```

produces:

```typescript
{
  category: "laptops",
  productId: "123",
}
```

---

# Typing Multiple Parameters

```tsx
type Props = {
  params: {
    category: string;
    productId: string;
  };
};

export default function ProductPage({
  params,
}: Props) {
  return (
    <>
      <h1>
        {params.category}
      </h1>

      <h2>
        {params.productId}
      </h2>
    </>
  );
}
```

---

# Visualizing Multiple Parameters

```text
/shop/laptops/123
        ↓
[category]
        ↓
"laptops"

[productId]
        ↓
"123"
```

Result:

```typescript
{
  category: "laptops",
  productId: "123",
}
```

---

# Dynamic Routes Inside Layouts

Pages are not the only components that receive parameters.

Layouts can receive them too.

Suppose:

```text
app/
└── products/
    └── [id]/
        ├── layout.tsx
        └── page.tsx
```

Layout:

```tsx
type Props = {
  children: React.ReactNode;
  params: {
    id: string;
  };
};

export default function ProductLayout({
  children,
  params,
}: Props) {
  return (
    <>
      <h1>
        Product {params.id}
      </h1>

      {children}
    </>
  );
}
```

---

# Why Is This Useful?

Suppose you're building:

```text
/products/123
```

You might want:

```text
Product Header
Product Navigation
Product Sidebar
```

to persist while navigating between:

```text
/products/123
/products/123/reviews
/products/123/specifications
/products/123/images
```

Dynamic layouts make this possible.

---

# Catch-All Routes

Next.js also supports catch-all parameters.

Example:

```text
[...slug]
```

Suppose:

```text
/docs/react/hooks/useEffect
```

The parameter becomes:

```typescript
{
  slug: [
    "react",
    "hooks",
    "useEffect",
  ],
}
```

---

# Optional Catch-All Routes

You can also write:

```text
[[...slug]]
```

which allows:

```text
/docs
```

and:

```text
/docs/react/hooks
```

to use the same route.

---

# The Most Common Beginner Mistake

Consider:

```text
app/products/[productId]
```

Developers often write:

```tsx
params.id
```

This fails.

The folder says:

```text
[productId]
```

Therefore:

```typescript
params.productId
```

must be used.

---

# Another Common Mistake

Assuming:

```typescript
params.id
```

is numeric.

Wrong:

```tsx
const result =
  params.id + 1;
```

Result:

```text
"1231"
```

Correct:

```tsx
const result =
  Number(params.id) + 1;
```

---

# Yet Another Common Mistake

Trying to manually parse URLs:

```tsx
window.location.pathname
```

Don't do this.

Next.js already provides:

```typescript
params
```

for you.

---

# Real Production Example

Suppose we're building an ecommerce site.

Folder structure:

```text
app/
└── products/
    └── [id]/
        ├── layout.tsx
        ├── page.tsx
        ├── reviews/
        ├── images/
        └── specs/
```

Visiting:

```text
/products/123/specs
```

produces:

```typescript
params = {
  id: "123"
}
```

Every page and layout under that route can access the same parameter.

---

# Mental Model

Whenever you see:

```text
[something]
```

translate it mentally into:

```text
Create parameter:
    something
```

Then:

```text
URL
   ↓
Folder Match
   ↓
Parameter Object
   ↓
Page/Layout Props
```

There is no magic.

Just filesystem mapping.

---

# Practice Exercise

Create:

```text
app/
└── products/
    └── [id]/
        └── page.tsx
```

Then:

1. Display `params.id`
2. Convert it to a number
3. Create another route:

```text
/blog/[slug]
```

4. Display `params.slug`
5. Create:

```text
/shop/[category]/[productId]
```

6. Display both parameters.

Observe how the folder names become the property names.

---

# What You've Learned

You now understand:

✓ static routes

✓ dynamic routes

✓ square bracket syntax

✓ where `params` comes from

✓ why parameters are strings

✓ typing route parameters

✓ multiple route parameters

✓ dynamic layouts

✓ catch-all routes

✓ common parameter mistakes

Most importantly, you've learned that `params` is not special framework magic.

It's simply an object that Next.js constructs from your folder names and injects into your components.

In Part 5, we'll connect route parameters to real applications by learning:

> How to fetch data safely using typed boundaries, caching, and error handling.
