# GreyMatter Journal

# Part 23 — Deploying to Production, CI/CD, Edge Networks, and the Architecture of Software Delivery

> **Goal of this lesson:** Deploy GreyMatter Journal to production while learning what deployment actually means, how CI/CD pipelines work, what edge networks are, why environment variables exist, and why software engineering ultimately concerns transforming source code into running systems. [nextjs](https://nextjs.org/learn/pages-router/deploying-nextjs-app-deploy)

***

# We've Been Living in Development Mode

Until now, our application has lived here:

```text
http://localhost:3000
```

This implies:

```text
Your Computer
       =
Entire Internet
```

which is obviously not true.

The fundamental question becomes:

> How does source code become a running system that millions of people can access?

***

# The Beginner Mental Model

Most beginners imagine:

```text
Write Code
     ↓
Upload Website
     ↓
Done
```

Reality looks more like:

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

Each step is a distinct phase in turning ideas into reliable, running software.

***

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

Questions:

```text
Can browsers execute TypeScript?

Can browsers execute React components?

Can browsers execute Next.js routing?
```

Answer:

```text
No.
```

Browsers understand HTML, CSS, and JavaScript—not TypeScript, JSX, or Next.js’ server component model.

***

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

Think of it as a compiler pipeline for entire systems, not just for individual files.

***

# Why We'll Use Vercel

Next.js was created by:

```text
Vercel
```

Vercel provides:

```text
✓ First-class Next.js hosting
✓ Serverless and edge functions
✓ Global edge network
✓ Built-in CDN
✓ Git-based deployment pipelines
✓ Environment management
```

For most Next.js apps, Vercel offers the “default path”: push code to Git, Vercel builds and deploys automatically. [vercel](https://vercel.com/docs/frameworks/full-stack/nextjs)

***

# Step 1 — Create a Git Repository

In your terminal:

```bash
git init

git add .

git commit -m "Initial GreyMatter Journal"
```

Git turns your project into a versioned history of changes rather than a loose folder of files.

***

# Wait…

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

It lets you move through time: compare versions, revert mistakes, and branch experiments without losing track.

***

# Step 2 — Push to GitHub

Create a repository on GitHub.

Then:

```bash
git remote add origin \
https://github.com/USERNAME/greymatter-journal.git

git push -u origin main
```

Now your source of truth lives in a hosted Git repository that deployment platforms can pull from. [vercel](https://vercel.com/kb/guide/deploying-next-and-userbase-with-vercel)

***

# Why Push to GitHub?

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

Instead of manually uploading files, you push commits; the platform reacts to those commits by building and deploying. [youtube](https://www.youtube.com/watch?v=9n8Gh4t5byE)

***

# Step 3 — Create a Vercel Account

Visit:

```text
https://vercel.com
```

Sign in with:

```text
GitHub
```

Then click:

```text
New Project
```

Choose:

```text
greymatter-journal
```

Vercel will automatically detect that this is a Next.js project and apply sensible defaults for build settings. [vercel](https://vercel.com/docs/frameworks/full-stack/nextjs)

***

# Wait…

That's It?

Almost.

This simplicity hides an enormous amount of engineering.

When you click:

```text
Deploy
```

Vercel does roughly:

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

Create Artifacts
        │
        ▼

Provision Infrastructure
        │
        ▼

Configure Edge + CDN
        │
        ▼

Publish Website
```

All that is compressed into a single “Deploy” button. [youtube](https://www.youtube.com/watch?v=f8nrw6fdMeM)

***

# Step 4 — Add Environment Variables

In the Vercel dashboard:

```text
Project → Settings → Environment Variables
```

Add:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID
NEXT_PUBLIC_SANITY_DATASET
SANITY_API_TOKEN

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
CLERK_SECRET_KEY
```

Use the same values you configured in `.env.local`, but now stored securely in Vercel’s environment. [eastondev](https://eastondev.com/blog/en/posts/dev/20251220-nextjs-vercel-deploy-guide/)

***

# Wait…

Why Not Commit `.env.local`?

Suppose your repository contains:

```bash
CLERK_SECRET_KEY=super-secret-key
```

and your repo becomes public.

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

Anyone could impersonate your backend or access your users’ data.

Environment variables keep secrets **out of** the codebase and **in** the deployment environment.

***

# Environment Variables as Dependency Injection

Instead of:

```typescript
const secret = "abc123";
```

we write:

```typescript
const secret = process.env.SECRET;
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

The same code can run in development, staging, and production with different configuration injected at runtime. [eastondev](https://eastondev.com/blog/en/posts/dev/20251220-nextjs-vercel-deploy-guide/)

***

# Step 5 — Deploy

Click:

```text
Deploy
```

Vercel will:

- Clone the repo,
- Install dependencies,
- Run `next build`,
- Upload the resulting `.next` artifacts,
- Wire everything into its edge network and CDN. [youtube](https://www.youtube.com/watch?v=f8nrw6fdMeM)

Eventually you’ll see a URL like:

```text
https://greymatter-journal.vercel.app
```

Your application is now:

```text
Production Software
```

***

# Wait…

What Just Happened? (The Pipeline)

Let’s zoom into each stage.

***

## Stage 1 — Clone Repository

```text
GitHub
    │
    ▼

Source Code Downloaded
```

Vercel pulls the exact commit you pushed, so builds are reproducible and traceable. [vercel](https://vercel.com/kb/guide/deploying-next-and-userbase-with-vercel)

***

## Stage 2 — Install Dependencies

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

The platform recreates your dependency tree to ensure the build environment matches your project’s requirements. [vercel](https://vercel.com/kb/guide/deploying-next-and-userbase-with-vercel)

***

## Stage 3 — Build Next.js

```bash
npm run build
```

This step:

```text
Analyzes routes

Compiles React components

Compiles TypeScript

Builds server and client bundles

Optimizes images and assets

Configures data fetching and caching
```

Next.js emits serverless/edge functions and static assets into the `.next/` directory. [vercel](https://vercel.com/docs/frameworks/full-stack/nextjs)

***

## Stage 4 — Create Artifacts

Before:

```text
app/
components/
lib/
```

After:

```text
.next/
  server/
  static/
  routes-manifest.json
  build-manifest.json
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

***

# What Is an Artifact?

Artifacts are:

> Files that machines execute.

Examples:

```text
JavaScript bundles
HTML files
CSS files
Serverless function bundles
Edge function bundles
Optimized images
Metadata & manifests
```

These are what actually run in production; your TypeScript and JSX never leave the build step. [vercel](https://vercel.com/docs/frameworks/full-stack/nextjs)

***

## Stage 5 — Upload to the Edge Network

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
and Edge Locations
```

Diagram:

```text
Singapore

Tokyo

London

Sydney

New York
```

Each region caches static assets and runs serverless/edge functions close to users. [vercel](https://vercel.com/frameworks/nextjs)

***

# What Is the Edge?

Most beginners think:

```text
Internet
      =
Single Server
```

Actually:

```text
User
   │
   ▼

Nearby Edge Node
   │
   ▼

Origin Infrastructure
```

Diagram:

```text
User

   │

Edge

   │

Origin
```

The **edge** means:

```text
Computers
close
to users.
```

Inference: we move computation and data outward, closer to where requests originate.

***

# Why Does Edge Matter?

Suppose:

```text
Server:
New York

User:
Singapore
```

Without edge:

```text
Singapore
     │
     ▼
New York
```

Latency might be:

```text
~200ms
```

With edge:

```text
Singapore
     │
     ▼
Singapore Edge
```

Latency can drop to:

```text
~10–20ms
```

Multiply that across dozens of assets and thousands of users, and the difference becomes enormous.

***

# Continuous Integration (CI)

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

```text
Continuous Integration (CI)
```

CI aims to catch integration issues early by building and testing on every change. [medium](https://medium.com/@itsamanyadav/deploying-your-next-js-app-on-vercel-step-by-step-943d3a1ac7c8)

***

# Continuous Deployment (CD)

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

This is:

```text
Continuous Deployment (CD)
```

CD automates the path from “build is green” to “feature is live”, often with safeguards such as approvals or release strategies. [youtube](https://www.youtube.com/watch?v=9n8Gh4t5byE)

***

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

Every commit can go through this pipeline, creating a chain of small, frequent, low-risk releases instead of big, risky ones.

***

# Why Automate?

Manual deployment:

```text
SSH into server
Copy files
Install dependencies
Restart processes
Hope
```

This yields:

```text
Human Error
Inconsistent Environments
Undocumented Steps
```

Automation yields:

```text
Repeatability
Traceability
Confidence
```

The same pipeline runs the same way every time.

***

# Environments

Professional systems rarely have just one environment.

They typically use:

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

Each environment has its own databases, credentials, and risk profile.

***

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

Staging and preview deployments let you test builds with realistic settings before promoting them to production. [nextjs](https://nextjs.org/learn/pages-router/deploying-nextjs-app-deploy)

***

# Infrastructure as Code

Old approach:

```text
Human
    │
    ▼

Click Around Cloud Console
Configure Server by Hand
```

Modern approach:

```text
Code
   │
   ▼

Create Infrastructure
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

So the environment can be versioned, reviewed, and reproduced just like code.

***

# Observability

After deployment, we must answer:

```text
Is it working?
```

Key questions:

```text
How many users?

How fast?

Any errors?

Any crashes?

Any failed requests?
```

Platforms like Vercel provide analytics, logs, and error tracking; you can also integrate external APM and monitoring tools. [youtube](https://www.youtube.com/watch?v=9n8Gh4t5byE)

***

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

Deployment is a **loop**, not a single event.

***

# The Hidden Architecture of Delivery

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

Your readers never see this pipeline; they just see a URL that works.

***

# Deployment Trees

We’ve already discovered:

```text
React Trees

Failure Trees

Reality Trees

Trust Trees

State Trees

Cache Trees
```

Now we add:

```text
Deployment Trees
```

because software itself evolves through:

```text
Successive
transformations
of artifacts.
```

Each stage in the pipeline produces a new “shape” of your system: source, build, artifacts, release.

***

# The Deep Secret of DevOps

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
Just the Git repository
```

The software is:

```text
The running system.
```

DevOps is about aligning how we write code with how we run and operate it.

***

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

Once you see deployment as a pipeline of transformations, CI/CD, infrastructure as code, edge networks, and observability all become different lenses on the same process.

***

# Up Next

In **Part 24**, we'll implement observability, analytics, logging, monitoring, and tracing while learning:

- telemetry,
- distributed tracing,
- metrics,
- logs,
- monitoring,
- debugging production systems,

and why software engineering ultimately becomes the science of observing invisible machines.
