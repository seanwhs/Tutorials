# GreyMatter Journal

# Part 1 — Creating Our First Next.js 16 Application

> **Goal of this lesson:** Understand what Node.js, npm, npx, and `create-next-app` actually are, and learn how to create the foundation of a modern Next.js application.

---

# Before We Build Anything

Most tutorials begin with this:

```bash
npx create-next-app@latest my-app
```

Then they immediately start writing React code.

But this command is doing far more than most developers realize.

Before we run it, we need to answer four important questions:

* What is Node.js?
* What is npm?
* What is npx?
* What exactly is `create-next-app`?

Because if you understand these four concepts, you'll understand how most modern JavaScript tooling works.

---

# The Problem We're Trying To Solve

Imagine you want to build a website.

Twenty years ago, you might have written:

```html
<h1>Hello World</h1>
```

saved the file as:

```text
index.html
```

and opened it in your browser.

Simple.

But modern applications require much more:

* Components
* Routing
* Bundling
* Optimization
* TypeScript compilation
* Image optimization
* CSS processing
* Code splitting
* Development servers
* Production builds

You could build all of this yourself.

Or you could use a framework.

This is why frameworks like Next.js exist.

---

# What Is Node.js?

One of the biggest misconceptions among beginners is:

> Node.js is a programming language.

It isn't.

Node.js is:

> A JavaScript runtime environment.

---

# What Does "Runtime" Mean?

A runtime is simply a program capable of executing another program.

For example:

```text
C Program
    ↓
C Runtime
```

```text
Java Program
    ↓
JVM Runtime
```

```text
JavaScript Program
    ↓
Browser Runtime
```

Traditionally, JavaScript only ran inside browsers.

```text
Chrome
Firefox
Safari
Edge
```

For example:

```html
<script>
console.log("Hello");
</script>
```

The browser executes the JavaScript.

---

# The Problem

Suppose we want to do this:

```javascript
const fs = require("fs");
```

or:

```javascript
const http = require("http");
```

Browsers don't allow this.

Why?

Because browsers are designed for web pages, not operating systems.

---

# Enter Node.js

Node.js gives JavaScript access to your operating system.

```text
JavaScript
      ↓
Node.js
      ↓
Windows
macOS
Linux
```

Now JavaScript can:

* read files,
* create servers,
* access networks,
* install software,
* compile applications.

For example:

```javascript
import fs from "node:fs";

const text = fs.readFileSync("notes.txt");

console.log(text);
```

This is impossible in a browser.

---

# Why Does Next.js Need Node.js?

Because Next.js itself is a program.

When you execute:

```bash
npm run dev
```

you are actually doing:

```text
Terminal
    ↓
Node.js
    ↓
Next.js
    ↓
Development Server
```

Similarly:

```bash
npm run build
```

becomes:

```text
Terminal
    ↓
Node.js
    ↓
Next.js Compiler
    ↓
Production Application
```

Without Node.js, Next.js cannot run.

---

# What Is npm?

After installing Node.js, you automatically get another tool:

```text
npm
```

Many beginners believe npm means:

> Node Programming Manager

It actually stands for:

```text
Node Package Manager
```

Its primary job is simple:

```text
Download packages
        ↓
Install packages
        ↓
Manage packages
```

For example:

```bash
npm install react
```

performs:

```text
Connect to npm Registry
          ↓
Download React
          ↓
Download Dependencies
          ↓
Store Inside node_modules
```

---

# What Is The npm Registry?

The npm Registry is essentially the world's largest software library.

```text
npm Registry

├── React
├── Next.js
├── TypeScript
├── Tailwind
├── Prisma
├── Sanity
└── Millions More
```

When you execute:

```bash
npm install next
```

npm downloads:

* Next.js,
* its dependencies,
* their dependencies,
* their dependencies' dependencies.

This dependency tree can easily contain thousands of packages.

---

# What Is npx?

This is where many beginners become confused.

Suppose you install a package:

```bash
npm install next
```

Now Next.js exists inside:

```text
node_modules/
```

But how do you run it?

You could write:

```bash
./node_modules/.bin/next
```

which is inconvenient.

Instead, npx executes packages for you.

For example:

```bash
npx next
```

becomes:

```text
Find package
       ↓
Execute package
```

---

# The Superpower Of npx

npx can execute packages that aren't even installed.

For example:

```bash
npx cowsay hello
```

produces:

```text
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

How?

```text
Download package
        ↓
Execute package
        ↓
Delete package
```

This capability powers modern project generators.

---

# What Is create-next-app?

Now we're finally ready to understand:

```bash
npx create-next-app@latest greymatter-journal
```

Let's break it apart.

---

## Part 1

```bash
npx
```

means:

```text
Execute package
```

---

## Part 2

```bash
create-next-app
```

is a project scaffolding tool created by the Next.js team.

Its job is to:

* create folders,
* install dependencies,
* generate configuration,
* create starter files.

---

## Part 3

```bash
@latest
```

means:

```text
Install latest version
```

---

## Part 4

```bash
greymatter-journal
```

is the name of our project folder.

---

# What Actually Happens?

When you execute:

```bash
npx create-next-app@latest greymatter-journal
```

the following occurs:

```text
Download create-next-app
              ↓
Execute installer
              ↓
Create project folder
              ↓
Install Next.js
              ↓
Install React
              ↓
Install TypeScript
              ↓
Install dependencies
              ↓
Generate configuration
              ↓
Generate starter files
```

Diagram:

```text
Terminal
    │
    ▼
npx
    │
    ▼
create-next-app
    │
    ▼
Project Generator
    │
    ├── Install React
    ├── Install Next.js
    ├── Install TypeScript
    ├── Install ESLint
    ├── Install Tailwind
    └── Generate Files
```

---

# Creating GreyMatter Journal

Open a terminal and execute:

```bash
npx create-next-app@latest greymatter-journal
```

You'll be asked several questions.

Select:

```text
✔ Would you like to use TypeScript? ........ Yes
✔ Would you like to use ESLint? ............ Yes
✔ Would you like to use Tailwind CSS? ...... Yes
✔ Would you like your code inside src/? .... No
✔ Would you like to use App Router? ........ Yes
✔ Would you like to use Turbopack? ......... Yes
✔ Would you like to customize imports? ..... No
```

After installation:

```bash
cd greymatter-journal
```

---

# Our First Look At The Project

You should see something similar to:

```text
greymatter-journal/

app/
public/
node_modules/

package.json
package-lock.json
tsconfig.json
next.config.ts
eslint.config.mjs
postcss.config.mjs
```

At first glance, this can look overwhelming.

But every file has a specific purpose.

---

# Understanding package.json

Perhaps the most important file is:

```text
package.json
```

Think of it as the identity card of your application.

Example:

```json
{
  "name": "greymatter-journal",
  "version": "0.1.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build"
  }
}
```

This file answers:

* What is this project called?
* Which packages are installed?
* How do we start the project?
* How do we build the project?

---

# Understanding node_modules

Beginners often panic when they see:

```text
node_modules/
```

because it contains thousands of files.

This is normal.

```text
Your code
     +
Next.js code
     +
React code
     +
Dependency code
     +
Dependency dependency code
```

Modern applications depend on thousands of small packages.

---

# Running Our Application

Execute:

```bash
npm run dev
```

This runs:

```text
package.json
       ↓
scripts.dev
       ↓
next dev
       ↓
Next.js Development Server
```

You'll see:

```text
http://localhost:3000
```

Open it in your browser.

Congratulations.

You've just launched a modern React application powered by:

* Node.js
* npm
* npx
* React
* Next.js
* TypeScript
* Tailwind CSS
* Turbopack

---

# Mental Model To Remember Forever

When you type:

```bash
npx create-next-app@latest greymatter-journal
```

you are not creating a website.

You are creating an entire software development environment.

```text
Node.js Runtime
        +
Package Manager
        +
React
        +
Next.js
        +
TypeScript
        +
Tailwind
        +
Compiler
        +
Bundler
        +
Development Server
```

---

# Up Next

In **Part 2**, we'll answer one of the most confusing questions for beginners:

> Why does a Next.js project contain an `app` folder?

We'll learn:

* What the App Router actually is
* Why folders become URLs
* What `page.tsx` does
* What `layout.tsx` does
* Why layouts changed web architecture
* How Next.js builds application trees instead of pages

Because modern web applications are not collections of pages.

They're collections of user interfaces that persist across navigation.
