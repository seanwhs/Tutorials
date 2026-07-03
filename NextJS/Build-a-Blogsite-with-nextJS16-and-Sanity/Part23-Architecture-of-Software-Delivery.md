# GreyMatter Journal

# Part 23 — Deploying to Production, CI/CD, Edge Networks, and the Architecture of Software Delivery

> **Goal of this lesson:** Deploy GreyMatter Journal to production while learning what deployment actually means, how CI/CD pipelines work, what edge networks are, why environment variables exist, and why software engineering ultimately concerns transforming source code into running systems.

---

# We've Been Living In Development Mode

Until now, our application has lived here:

```text
http://localhost:3000
```

This means:

```text
Your Computer
       =
Entire Internet
```

which is obviously not true.

The fundamental question becomes:

> How does source code become a running system that millions of people can access?

---

# The Beginner Mental Model

Most beginners imagine:

```text
Write Code
     ↓
Upload Website
     ↓
Done
```

Reality:

```text
Write Code
     ↓
Commit
     ↓
Push
     ↓
Build
     ↓
Test
     ↓
Package
     ↓
Deploy
     ↓
Distribute
     ↓
Monitor
     ↓
Maintain
```

---

# What Does "Deploy" Actually Mean?

Suppose you write:

```tsx
export default function Home() {
  return <h1>Hello World</h1>;
}
```

This file exists as:

```text
app/page.tsx
```

Question:

```text
Can browsers execute TypeScript?
```

No.

Can browsers execute React components?

No.

Can browsers execute Next.js routing?

No.

---

# Deployment Is Transformation

Diagram:

```text
Source Code
      │
      ▼

Build Process
      │
      ▼

Executable System
      │
      ▼

Running Application
```

Deployment fundamentally means:

> Transforming developer artifacts into runtime artifacts.

---

# Why We'll Use Vercel

Next.js was created by:

Vercel

and Vercel provides:

```text
✓ Next.js hosting
✓ Serverless functions
✓ Edge network
✓ CDN
✓ Deployment pipelines
✓ Environment management
```

---

# Step 1 — Create A Git Repository

Open terminal:

```bash
git init

git add .

git commit -m "Initial GreyMatter Journal"
```

---

# Wait...

Why Git?

Most beginners think:

```text
Git
   =
Backup System
```

Actually:

```text
Git
   =
History Engine
```

Diagram:

```text
Commit A
    │
    ▼

Commit B
    │
    ▼

Commit C
```

Git stores:

```text
Code
+
History
+
Relationships
```

---

# Step 2 — Push To GitHub

Create a repository:

[GitHub Official Website](https://github.com?utm_source=chatgpt.com)

Then:

```bash
git remote add origin \
https://github.com/USERNAME/greymatter-journal.git

git push -u origin main
```

---

# Why Push To GitHub?

Because modern deployment works like this:

```text
Developer
     │
     ▼

Git Repository
     │
     ▼

Deployment Platform
```

Diagram:

```text
You
 │
 ▼

GitHub
 │
 ▼

Vercel
 │
 ▼

Internet
```

---

# Step 3 — Create A Vercel Account

Visit:

[Vercel Official Website](https://vercel.com?utm_source=chatgpt.com)

Sign in using:

```text
GitHub
```

Then click:

```text
Import Project
```

Choose:

```text
greymatter-journal
```

---

# Wait...

That's It?

Almost.

This simplicity hides an enormous amount of engineering.

When you click:

```text
Deploy
```

Vercel performs:

```text
Clone Repository
        │
        ▼

Install Packages
        │
        ▼

Build Project
        │
        ▼

Compile Next.js
        │
        ▼

Create Assets
        │
        ▼

Deploy Infrastructure
        │
        ▼

Configure CDN
        │
        ▼

Publish Website
```

---

# Step 4 — Add Environment Variables

Open:

```text
Vercel Dashboard

Settings

Environment Variables
```

Add:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID

NEXT_PUBLIC_SANITY_DATASET

SANITY_API_TOKEN

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY

CLERK_SECRET_KEY
```

---

# Wait...

Why Not Commit `.env.local`?

Suppose your repository contains:

```bash
CLERK_SECRET_KEY=
super-secret-key
```

Now imagine:

```text
GitHub Repository
```

becomes public.

Diagram:

```text
Private Secret
        │
        ▼

Public Repository
        │
        ▼

Catastrophe
```

---

# Environment Variables Are Dependency Injection

Instead of:

```typescript
const secret =
  "abc123";
```

we write:

```typescript
const secret =
  process.env.SECRET;
```

Diagram:

```text
Application
      │
      ▼

Environment
      │
      ▼

Configuration
```

This separates:

```text
Code

from

Deployment
```

---

# Step 5 — Deploy

Click:

```text
Deploy
```

Then wait.

Eventually you'll see:

```text
https://greymatter-journal.vercel.app
```

Congratulations.

Your application is now:

```text
Production Software
```

---

# Wait...

What Just Happened?

Let's examine the actual pipeline.

---

# Step 1 — Clone Repository

```text
GitHub
    │
    ▼

Source Code Downloaded
```

---

# Step 2 — Install Dependencies

```bash
npm install
```

Diagram:

```text
package.json
      │
      ▼

Dependency Graph
      │
      ▼

node_modules
```

---

# Step 3 — Build Next.js

```bash
npm run build
```

This performs:

```text
Analyze Routes

Compile React

Compile TypeScript

Optimize Images

Create Server Functions

Generate Static Pages
```

---

# Step 4 — Create Artifacts

Before:

```text
app/

components/

lib/
```

After:

```text
.next/
```

Diagram:

```text
Source
   │
   ▼

Compiler
   │
   ▼

Artifacts
```

---

# What Is An Artifact?

Artifacts are:

> Files that machines execute.

Examples:

```text
JavaScript bundles

HTML

CSS

Serverless functions

Images

Metadata
```

---

# Step 5 — Upload To Edge Network

Vercel distributes:

```text
HTML

CSS

JS

Images

Functions
```

across:

```text
Multiple Regions
```

Diagram:

```text
Singapore

Tokyo

London

Sydney

New York
```

---

# Wait...

What Is The Edge?

Most beginners think:

```text
Internet
      =
Servers
```

Actually:

```text
User
   │
   ▼

Nearby Server
   │
   ▼

Main Server
```

Diagram:

```text
User

   │

Edge

   │

Origin
```

The edge means:

```text
Computers
close
to users.
```

---

# Why Does Edge Matter?

Suppose:

```text
Server:
New York

User:
Singapore
```

Request:

```text
Singapore
     │
     ▼
New York
```

takes:

```text
200ms
```

With edge:

```text
Singapore
     │
     ▼
Singapore Edge
```

takes:

```text
10ms
```

---

# Continuous Integration

Every push triggers:

```text
Push Code
      │
      ▼

Build
      │
      ▼

Test
      │
      ▼

Validate
```

Diagram:

```text
Developer
      │
      ▼

Git Push
      │
      ▼

CI Pipeline
```

This is called:

# Continuous Integration (CI)

---

# Continuous Deployment

If CI succeeds:

```text
Build
    │
    ▼

Deploy
    │
    ▼

Production
```

This is called:

# Continuous Deployment (CD)

---

# CI/CD Together

Diagram:

```text
Code

   │

   ▼

Build

   │

   ▼

Test

   │

   ▼

Deploy

   │

   ▼

Production
```

---

# Why Automate?

Suppose humans deploy manually:

```text
SSH

Copy Files

Restart Server

Hope
```

This creates:

```text
Human Error
```

Automation creates:

```text
Repeatability
```

---

# Environments

Professional systems have:

```text
Development

Staging

Production
```

Diagram:

```text
Developer
      │
      ▼

Development
      │
      ▼

Staging
      │
      ▼

Production
```

---

# Why Multiple Environments?

Because:

```text
Production
```

contains:

```text
Real Users
Real Data
Real Money
```

Testing directly in production is:

```text
Extremely Expensive
```

---

# Infrastructure As Code

Old approach:

```text
Human
    │
    ▼

Configure Server
```

Modern approach:

```text
Code
   │
   ▼

Create Server
```

Example:

```yaml
server:
  memory: 2GB

database:
  replicas: 3
```

Infrastructure itself becomes:

```text
Software
```

---

# Observability

After deployment, we must answer:

```text
Is it working?
```

Questions include:

```text
How many users?

How fast?

Any errors?

Any crashes?

Any failures?
```

---

# Deployment Never Ends

Most beginners think:

```text
Deploy
    │
    ▼
Finished
```

Professional engineers know:

```text
Deploy
    │
    ▼

Observe
    │
    ▼

Fix
    │
    ▼

Deploy Again
```

Diagram:

```text
Build

  │

Deploy

  │

Observe

  │

Improve

  │

Repeat
```

---

# The Hidden Architecture

When you deploy GreyMatter Journal:

```text
Git Commit
     │
     ▼

GitHub
     │
     ▼

Vercel Build
     │
     ▼

Next.js Compiler
     │
     ▼

Artifacts
     │
     ▼

Edge Network
     │
     ▼

CDN
     │
     ▼

Users
```

---

# Wait...

Does This Look Familiar?

We've already discovered:

```text
React Trees

Failure Trees

Reality Trees

Trust Trees

State Trees

Cache Trees
```

Now we discover:

```text
Deployment Trees
```

because software itself evolves through:

```text
Successive
transformations
of artifacts.
```

---

# The Deep Secret Of DevOps

Most beginners think:

```text
Software
       =
Source Code
```

Professional engineers think:

```text
Software
       =
Source Code
       +
Infrastructure
       +
Deployment
       +
Operations
```

The software is not:

```text
Git repository
```

The software is:

```text
The running system.
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Deployment
          =
Uploading Files
```

Professional engineers think:

```text
Deployment
          =
Transforming
          Source
          Into
          Reality
```

Or more generally:

```text
Software Engineering
                    =
The Discipline
                    Of Turning
                    Ideas
                    Into
                    Running Systems
```

---

# Up Next

In **Part 24**, we'll implement observability, analytics, logging, monitoring, and tracing while learning:

* telemetry,
* distributed tracing,
* metrics,
* logs,
* monitoring,
* debugging production systems,
* and why software engineering ultimately becomes the science of observing invisible machines.
