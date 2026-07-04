# GreyMatter Journal

# Part 1 — Creating Our First Next.js 16 Application and Understanding Modern Development Environments

> **Goal of this lesson:** Understand the foundational tools of modern JavaScript development—Node.js, npm, npx, and Next.js—and learn why creating a new application is really the process of creating an entire software development environment.

---

# Before We Write a Single Line of Code

Most tutorials begin with:

```bash
npx create-next-app@latest my-app
```

and immediately move on to writing components.

We'll take a different approach.

Before running that command, we should understand what these tools actually are and why they exist.

Because one of the biggest obstacles for beginners is not syntax.

It's mystery.

When developers don't understand what their tools are doing, software feels like magic.

Professional engineers try to remove magic.

They replace it with mental models.

---

# Twenty Years of Web Development in One Diagram

Twenty years ago, building a website looked like this:

```text
Create HTML
       ↓
Open Browser
       ↓
Done
```

A simple website required:

```text
index.html
style.css
script.js
```

Today's applications are dramatically more complex.

Modern web applications require:

* component systems
* routing
* state management
* bundling
* transpilation
* optimization
* development servers
* hot reloading
* type checking
* image optimization
* metadata generation
* server rendering
* caching
* deployment pipelines

Visually:

```text
Application
      ↓

UI Framework
      ↓

Compiler
      ↓

Bundler
      ↓

Type System
      ↓

Development Server
      ↓

Build System
      ↓

Optimization Pipeline
      ↓

Runtime
```

Building all of this manually would be extremely difficult.

Frameworks exist to manage this complexity.

---

# What Is Node.js?

One of the most common misconceptions is:

> Node.js is a programming language.

It isn't.

Node.js is a:

```text
JavaScript Runtime
```

built on Google's V8 JavaScript engine.

Traditionally, JavaScript could only execute inside a browser:

```text
JavaScript
       ↓
Browser
```

Node.js changed this by allowing JavaScript to run outside the browser:

```text
JavaScript
       ↓
Node.js
       ↓
Computer
```

This means JavaScript programs can now access:

```text
File System

Network

Processes

Operating System

Environment Variables
```

This is why tools like:

* Next.js
* TypeScript
* ESLint
* Tailwind
* Vite
* Turbopack

can all be written in JavaScript.

---

# Browser JavaScript vs Node.js

A useful mental model is:

| Environment | Available APIs                      |
| ----------- | ----------------------------------- |
| Browser     | DOM, Window, Local Storage, Fetch   |
| Node.js     | File System, Processes, Network, OS |

For example:

Browser JavaScript can do:

```javascript
document.querySelector();
```

Node.js cannot.

Meanwhile, Node.js can do:

```javascript
import fs from "fs";
```

but browsers cannot.

The language is the same.

The environment is different.

---

# What Is npm?

Once Node.js existed, another problem appeared:

> How do developers share code?

The answer became:

```text
npm
```

which stands for:

```text
Node Package Manager
```

npm performs three jobs:

```text
Download Packages

Manage Dependencies

Execute Scripts
```

For example:

```bash
npm install next
```

performs:

```text
Contact Registry
       ↓
Download Package
       ↓
Download Dependencies
       ↓
Store in node_modules
```

The npm registry is now one of the largest software repositories in human history.

---

# What Is npx?

If npm installs software, then:

```text
npx
```

executes software.

The name originally meant:

```text
Node Package Execute
```

Its most important feature is:

> It can run packages without permanently installing them.

For example:

```bash
npx create-next-app
```

does not require:

```bash
npm install -g create-next-app
```

Instead:

```text
Download Package
        ↓
Execute Package
        ↓
Delete Temporary Installation
```

This allows us to always run the latest version.

---

# Breaking Down the Command

Our command is:

```bash
npx create-next-app@latest greymatter-journal
```

Each part has meaning:

| Component            | Purpose                           |
| -------------------- | --------------------------------- |
| `npx`                | Execute package                   |
| `create-next-app`    | Official Next.js scaffolding tool |
| `@latest`            | Use newest release                |
| `greymatter-journal` | Project directory                 |

This command is not creating a website.

It is creating an entire development environment.

---

# What Does create-next-app Actually Do?

When you execute:

```bash
npx create-next-app@latest greymatter-journal
```

the following occurs:

```text
Download create-next-app
           ↓
Create Project Folder
           ↓
Generate Files
           ↓
Install Dependencies
           ↓
Configure Toolchain
           ↓
Initialize Development Environment
```

Specifically, it installs:

* Next.js
* React
* React DOM
* TypeScript
* ESLint
* Tailwind CSS
* Turbopack
* Development tooling

In effect, it builds an entire software factory.

---

# Recommended Options for GreyMatter Journal

When prompted:

```text
✔ TypeScript? ................ Yes
✔ ESLint? .................... Yes
✔ Tailwind CSS? .............. Yes
✔ App Router? ................ Yes
✔ Turbopack? ................. Yes
✔ src/ directory? ............ No
✔ Customize import alias? .... No
```

Our choices reflect architectural decisions.

---

## Why TypeScript?

Because software grows.

TypeScript allows us to describe:

```text
Contracts
```

between different parts of our system.

---

## Why Tailwind?

Because modern UI development requires:

```text
Composable Design Systems
```

rather than isolated CSS files.

---

## Why App Router?

Because modern applications are:

```text
Persistent UI Trees
```

rather than collections of pages.

We'll spend much of this series exploring this idea.

---

## Why No src Directory?

Many teams prefer:

```text
src/
```

For GreyMatter Journal, we'll use:

```text
app/
components/
lib/
```

directly in the project root.

This keeps the architecture visually simple while learning.

---

# Exploring the Generated Project

After installation:

```text
greymatter-journal/

├── app/
├── public/
├── node_modules/

├── package.json
├── tsconfig.json
├── next.config.ts
├── eslint.config.ts
├── postcss.config.mjs
└── README.md
```

At first glance, this appears overwhelming.

In reality, each file exists to solve a specific problem.

---

# Understanding package.json

The most important file initially is:

```text
package.json
```

Think of it as:

```text
Project Manifest
```

Example:

```json
{
  "name": "greymatter-journal",

  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },

  "dependencies": {
    "next": "16.x",
    "react": "^19",
    "react-dom": "^19"
  }
}
```

This file answers:

```text
What is this project?

What software does it depend on?

How do we run it?
```

---

# Running Our Application

Now we finally execute:

```bash
cd greymatter-journal

npm run dev
```

This command triggers:

```text
npm
    ↓
package.json
    ↓
next dev
    ↓
Node.js
    ↓
Next.js Development Server
    ↓
Turbopack
```

Open:

```text
http://localhost:3000
```

Congratulations.

You now have:

* a compiler
* a bundler
* a development server
* a React runtime
* a Next.js framework
* a TypeScript environment
* a CSS pipeline
* a build system

all working together.

---

# Frameworks Are Architectural Decisions

One of the most important ideas in modern software engineering is:

> Frameworks are not libraries.

A library provides functionality:

```text
Your Code
      ↓
Library
```

A framework provides architecture:

```text
Framework
      ↓
Your Code
```

When you choose Next.js, you are choosing:

* routing architecture
* rendering architecture
* caching architecture
* deployment architecture
* build architecture
* optimization architecture

Frameworks are pre-built engineering decisions.

---

# Mental Model To Remember Forever

Beginners think:

```text
npx create-next-app
          ↓
Creates Website
```

Professional engineers think:

```text
npx create-next-app
          ↓
Creates
A Software Engineering Environment
```

More fundamentally:

```text
Frameworks
       =
Collections
Of Architectural Decisions
```

And software engineering is largely the process of deciding:

> Which complexities should we solve ourselves, and which should we allow the framework to solve for us?

---

# Up Next — Part 2: The App Router Revolution

We'll explore:

* why folders became routes
* why layouts became trees
* why pages stopped being pages
* why React Server Components changed rendering forever

and discover that modern web applications are not collections of screens.

They are persistent trees that evolve over time.
