# Next.js 16 TypeScript Foundations

# Part 2 — TypeScript Props for Layouts: Finally Understanding `React.ReactNode`

> **Series:** *From Confusing Layout Syntax to Confident Typed App Router Code*

In Part 1, we learned that `RootLayout` is simply a React component that wraps our entire application.

We also encountered this line:

```tsx
children: React.ReactNode
```

For many developers learning Next.js and TypeScript, this is where things become confusing.

Questions immediately appear:

* What exactly is `React.ReactNode`?
* Why isn't it just `string`?
* Why isn't it `JSX.Element`?
* Why are there curly braces inside more curly braces?
* Why do some tutorials create separate `Props` types?
* Why do others type everything inline?

The good news is that these questions are not really about Next.js.

They are about understanding how React and TypeScript work together.

Once you understand component props in TypeScript, much of the App Router suddenly becomes easier to read.

In this lesson, we'll demystify React props, `children`, and the TypeScript patterns used throughout modern Next.js applications.

---

# Everything Starts With Function Parameters

Let's forget React for a moment.

Consider this ordinary JavaScript function:

```javascript
function greet(person) {
  return `Hello ${person}`;
}
```

We call it like this:

```javascript
greet("Sean");
```

The function receives one parameter:

```text
person = "Sean"
```

Simple.

Now consider:

```javascript
function createUser(user) {
  return `${user.name} (${user.age})`;
}
```

We call:

```javascript
createUser({
  name: "Sean",
  age: 30,
});
```

The parameter is now an object.

---

# React Components Are Just Functions

A React component is simply a function that receives an object.

For example:

```tsx
function Welcome(props) {
  return (
    <h1>
      Hello {props.name}
    </h1>
  );
}
```

Usage:

```tsx
<Welcome name="Sean" />
```

React transforms this conceptually into:

```tsx
Welcome({
  name: "Sean",
});
```

The JSX attributes become object properties.

---

# Destructuring Props

Instead of writing:

```tsx
function Welcome(props) {
  return (
    <h1>
      {props.name}
    </h1>
  );
}
```

we often write:

```tsx
function Welcome({ name }) {
  return (
    <h1>
      {name}
    </h1>
  );
}
```

This is called object destructuring.

JavaScript converts:

```javascript
const name = props.name;
```

automatically.

---

# TypeScript Adds Types To Props

Without TypeScript:

```tsx
function Welcome({ name }) {
  return <h1>{name}</h1>;
}
```

With TypeScript:

```tsx
function Welcome({
  name,
}: {
  name: string;
}) {
  return <h1>{name}</h1>;
}
```

The syntax looks scary, but we're simply saying:

> The object has a property called `name`, and that property is a string.

---

# Understanding The Curly Braces

Many beginners see this:

```tsx
function Welcome({
  name,
}: {
  name: string;
}) {
```

and panic.

Let's separate the pieces.

---

## First Curly Braces

```tsx
{
  name
}
```

These are JavaScript destructuring braces.

---

## Second Curly Braces

```tsx
{
  name: string
}
```

These are TypeScript type definition braces.

---

So:

```tsx
function Welcome(
  { name },
  : { name: string }
)
```

means:

```text
Extract property:
    name

From object type:
    {
      name: string
    }
```

Nothing magical is happening.

---

# Returning To RootLayout

Now our layout should make more sense:

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
```

We're saying:

```text
Extract:
    children

From an object that contains:
    children: React.ReactNode
```

That's all.

---

# What Is `React.ReactNode`?

This is probably the most misunderstood React type.

Many people assume it means:

> "A React component."

It doesn't.

It means:

> "Anything React can render."

---

# Examples Of React Nodes

React can render text:

```tsx
"Hello"
```

---

Numbers:

```tsx
42
```

---

JSX:

```tsx
<h1>Hello</h1>
```

---

Multiple elements:

```tsx
<>
  <h1>Hello</h1>
  <p>World</p>
</>
```

---

Arrays:

```tsx
[
  <div>A</div>,
  <div>B</div>,
]
```

---

Conditional output:

```tsx
isLoggedIn && <Dashboard />
```

---

Null:

```tsx
null
```

---

Boolean values:

```tsx
false
```

All of these are valid React nodes.

Therefore React provides:

```tsx
React.ReactNode
```

which represents:

```text
Anything React knows how to render
```

---

# Why Not Use `string`?

Imagine:

```tsx
function Card({
  children,
}: {
  children: string;
}) {
  return (
    <div>{children}</div>
  );
}
```

This works:

```tsx
<Card>
  Hello
</Card>
```

But this fails:

```tsx
<Card>
  <h1>Hello</h1>
</Card>
```

because:

```tsx
<h1>Hello</h1>
```

is not a string.

---

# Why Not Use `JSX.Element`?

Many developers try:

```tsx
children: JSX.Element;
```

This also causes problems.

This works:

```tsx
<Card>
  <h1>Hello</h1>
</Card>
```

But this fails:

```tsx
<Card>
  Hello
</Card>
```

because:

```tsx
"Hello"
```

is not a JSX element.

Similarly:

```tsx
<Card>
  <>
    <h1>A</h1>
    <h1>B</h1>
  </>
</Card>
```

may not behave as expected.

---

# Why `React.ReactNode` Is Usually Correct

Because React children can be:

```text
text
numbers
elements
fragments
arrays
null
undefined
booleans
```

the safest and most accurate type is:

```tsx
React.ReactNode
```

This is why you see it everywhere.

---

# Inline Types Versus Named Types

There are two common styles.

---

## Style 1: Inline Types

```tsx
function Card({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div>{children}</div>
  );
}
```

Advantages:

* quick
* simple
* fewer files

Disadvantages:

* becomes hard to read
* duplicates code

---

## Style 2: Named Types

```tsx
type CardProps = {
  children: React.ReactNode;
};

function Card({
  children,
}: CardProps) {
  return (
    <div>{children}</div>
  );
}
```

Advantages:

* reusable
* easier to read
* easier to maintain

Disadvantages:

* one extra declaration

---

# Which Style Should You Use?

Small components:

```tsx
function Button({
  label,
}: {
  label: string;
}) {
```

Inline types are fine.

---

Larger components:

```tsx
type ProductCardProps = {
  product: Product;
  featured: boolean;
  children: React.ReactNode;
};
```

Named types are usually better.

---

# The Pattern Used In Production Applications

Most production Next.js applications prefer:

```tsx
type RootLayoutProps = {
  children: React.ReactNode;
};

export default function RootLayout({
  children,
}: RootLayoutProps) {
  return (
    <html>
      <body>{children}</body>
    </html>
  );
}
```

Why?

Because teams often expand props later:

```tsx
type DashboardLayoutProps = {
  children: React.ReactNode;
  sidebar: React.ReactNode;
  breadcrumbs?: boolean;
};
```

Extracting types early makes future changes easier.

---

# Understanding `Readonly`

New Next.js projects often generate:

```tsx
export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
```

This introduces another question:

> What is `Readonly`?

`Readonly` is a TypeScript utility type.

It transforms:

```tsx
{
  children: React.ReactNode;
}
```

into:

```tsx
{
  readonly children: React.ReactNode;
}
```

meaning:

```tsx
children = "hello";
```

becomes illegal.

---

# Do You Need `Readonly`?

Honestly, not usually.

Most developers write:

```tsx
type RootLayoutProps = {
  children: React.ReactNode;
};

export default function RootLayout({
  children,
}: RootLayoutProps) {
```

because it's simpler and easier to teach.

---

# Real-World Example

Suppose we're building an admin dashboard.

```tsx
type DashboardLayoutProps = {
  children: React.ReactNode;
};

export default function DashboardLayout({
  children,
}: DashboardLayoutProps) {
  return (
    <>
      <Sidebar />

      <main>
        {children}
      </main>
    </>
  );
}
```

When users visit:

```text
/dashboard
/dashboard/users
/dashboard/settings
```

Next.js automatically injects the correct page into:

```tsx
{children}
```

---

# Common Beginner Mistakes

## Mistake #1

Using:

```tsx
children: string
```

instead of:

```tsx
children: React.ReactNode
```

---

## Mistake #2

Using:

```tsx
children: JSX.Element
```

which is too restrictive.

---

## Mistake #3

Thinking React components are classes.

They're simply functions.

---

## Mistake #4

Being afraid of destructuring syntax.

Remember:

```tsx
function Example({ name })
```

is just shorthand for:

```tsx
function Example(props) {
  const name = props.name;
}
```

---

# Mental Model To Remember

Whenever you see:

```tsx
function Component({
  something,
}: {
  something: SomeType;
})
```

translate it mentally into:

```text
Receive an object.

Extract "something".

Verify it has the correct type.
```

That's all TypeScript is doing.

---

# Practice Exercise

Refactor your root layout from:

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
```

to:

```tsx
type RootLayoutProps = {
  children: React.ReactNode;
};

export default function RootLayout({
  children,
}: RootLayoutProps) {
```

Then create another component:

```tsx
type CardProps = {
  children: React.ReactNode;
};

function Card({
  children,
}: CardProps) {
  return (
    <div>
      {children}
    </div>
  );
}
```

Experiment with rendering:

* text
* numbers
* JSX
* fragments
* arrays

inside the component.

---

# What You've Learned

You now understand:

✓ React components are functions

✓ JSX attributes become object properties

✓ destructuring syntax

✓ TypeScript prop annotations

✓ why `React.ReactNode` exists

✓ why `JSX.Element` is usually incorrect for children

✓ inline versus named prop types

✓ when to use extracted types

✓ what `Readonly` means

Most importantly, you've learned that the intimidating syntax in Next.js layouts is really just:

> JavaScript object destructuring plus TypeScript type annotations.

In Part 3, we'll move beyond a single layout and explore one of the most powerful features of the App Router:

> How layouts compose together to create nested application structures.
