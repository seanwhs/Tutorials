# Appendix A — Deploying GreyMatter Journal to Vercel

> **Goal of this appendix:** Learn how to deploy GreyMatter Journal to production using Vercel while understanding what actually happens during the deployment process, how environment variables work, and how modern cloud platforms transform source code into globally distributed applications.

---

# Introduction

Throughout this tutorial series, we built and tested GreyMatter Journal locally using:

```bash
npm run dev
```

This launches a development server on:

```text
http://localhost:3000
```

While this is perfect for development, nobody else can access your application.

To make GreyMatter Journal available to the world, we need to deploy it to production.

Fortunately, Next.js and Vercel provide one of the simplest deployment experiences available today.

---

# Why Vercel?

Vercel is the company behind Next.js. Their platform is specifically designed to run Next.js applications efficiently.

Vercel provides:

* Global CDN distribution
* Automatic HTTPS
* Serverless functions
* Edge computing
* Automatic image optimization
* Continuous deployment
* Preview deployments
* Environment variable management
* Analytics and observability

Most importantly, Vercel understands the internal architecture of Next.js, allowing it to optimize your application automatically.

---

# Before You Begin

Ensure you have:

* Completed the GreyMatter Journal tutorial series
* A GitHub account
* A Vercel account
* A working Sanity project
* A functioning local application

Verify your application runs locally:

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

Confirm that:

* Articles load
* Images render
* Authentication works
* Comments function correctly

Only deploy applications that work locally.

---

# Step 1 — Create a Git Repository

Open your project folder:

```bash
cd greymatter-journal
```

Initialize Git:

```bash
git init
```

Add your files:

```bash
git add .
```

Create your first commit:

```bash
git commit -m "Initial GreyMatter Journal deployment"
```

---

# What Is Git Doing?

Git creates a snapshot of your project.

Think of Git as a timeline:

```text
Commit A
    ↓
Commit B
    ↓
Commit C
```

Each commit represents a complete version of your application.

Modern deployment systems use Git commits as the source of truth.

---

# Step 2 — Create a GitHub Repository

Open GitHub and create a new repository:

```text
greymatter-journal
```

Do not initialize the repository with:

* README
* .gitignore
* License

Your local project already contains these files.

---

# Step 3 — Connect Your Local Repository

GitHub will provide commands similar to:

```bash
git remote add origin \
https://github.com/YOUR_USERNAME/greymatter-journal.git

git branch -M main

git push -u origin main
```

After pushing, refresh GitHub.

You should see your complete project.

---

# Why Push to GitHub?

Modern deployment pipelines typically work like this:

```text
Developer
     ↓
Git Commit
     ↓
GitHub
     ↓
Deployment Platform
     ↓
Production
```

GitHub acts as the bridge between development and deployment.

---

# Step 4 — Create a Vercel Account

Visit:

```text
https://vercel.com
```

Sign in using your GitHub account.

This allows Vercel to:

* Read repositories
* Monitor commits
* Trigger deployments automatically

---

# Step 5 — Import Your Project

Inside the Vercel dashboard:

```text
Add New
    ↓
Project
```

Select:

```text
greymatter-journal
```

Vercel will automatically detect:

```text
Framework:
Next.js
```

This detection enables automatic optimization.

---

# Step 6 — Configure Environment Variables

Before deployment, add your environment variables.

Open:

```text
Project Settings
      ↓
Environment Variables
```

Add:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=
your_project_id

NEXT_PUBLIC_SANITY_DATASET=
production

SANITY_API_TOKEN=
your_api_token
```

If you implemented authentication:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
your_publishable_key

CLERK_SECRET_KEY=
your_secret_key
```

---

# Why Environment Variables Exist

Never write secrets directly into source code.

Bad:

```typescript
const apiKey =
  "my-secret-key";
```

Good:

```typescript
const apiKey =
  process.env.API_KEY;
```

This separates:

```text
Application Code

from

Deployment Configuration
```

---

# Step 7 — Deploy

Click:

```text
Deploy
```

Vercel now performs several operations automatically:

```text
Clone Repository
        ↓
Install Dependencies
        ↓
Compile TypeScript
        ↓
Build Next.js
        ↓
Generate Artifacts
        ↓
Deploy Functions
        ↓
Configure CDN
        ↓
Publish Website
```

After several minutes, you'll receive a URL similar to:

```text
https://greymatter-journal.vercel.app
```

Congratulations.

GreyMatter Journal is now live.

---

# Understanding the Build Process

When Vercel executes:

```bash
npm run build
```

Next.js transforms your source code into production artifacts.

Your source files:

```text
app/
components/
lib/
```

become:

```text
.next/
```

containing:

* JavaScript bundles
* HTML
* CSS
* Serverless functions
* Metadata
* Route manifests
* Optimized assets

This process is called compilation.

---

# Step 8 — Configure Sanity CORS

Open your Sanity dashboard:

```text
API
   ↓
CORS Origins
```

Add:

```text
https://greymatter-journal.vercel.app
```

Without this configuration, your application may fail to communicate with Sanity.

---

# Step 9 — Configure Revalidation Webhooks (Optional)

To automatically refresh content after publishing articles:

Open:

```text
Sanity
   ↓
API
   ↓
Webhooks
```

Create a webhook pointing to:

```text
https://your-site.vercel.app/api/revalidate
```

This allows published content to appear immediately without waiting for cache expiration.

---

# Preview Deployments

One of Vercel's most powerful features is Preview Deployments.

Suppose you push:

```bash
git push
```

Vercel automatically creates:

```text
https://greymatter-journal-git-feature.vercel.app
```

This allows you to:

* Test features
* Share previews
* Review changes
* Validate functionality

before publishing to production.

---

# Continuous Deployment

After initial setup, deployment becomes automatic.

Your workflow becomes:

```text
Write Code
     ↓
Commit
     ↓
Push
     ↓
Vercel Builds
     ↓
Vercel Deploys
     ↓
Production Updates
```

This process is called:

```text
Continuous Deployment
```

---

# Troubleshooting Common Errors

## Missing Environment Variables

Error:

```text
undefined environment variable
```

Solution:

* Verify variables exist in Vercel
* Redeploy the application

---

## Sanity Authentication Errors

Error:

```text
Unauthorized
```

Solution:

* Verify API token
* Verify project ID
* Verify dataset name

---

## Image Errors

Error:

```text
Invalid src prop
```

Solution:

Ensure your:

```text
next.config.ts
```

contains the proper image configuration.

---

## Build Failures

Run locally:

```bash
npm run build
```

If the local build fails, the Vercel build will also fail.

Always fix local build errors first.

---

# The Hidden Architecture

When a visitor opens GreyMatter Journal:

```text
User
   ↓
DNS
   ↓
Nearest Vercel Edge
   ↓
CDN Cache
   ↓
Serverless Function
   ↓
Sanity CDN
   ↓
Sanity Database
   ↓
Response
```

What appears to be:

```text
A blog website
```

is actually:

```text
A globally distributed,
cached,
serverless,
edge-computing system.
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
        Source Code
        Into
        Distributed Reality
```

When you deploy GreyMatter Journal, you are not simply publishing a website.

You are orchestrating a distributed system spanning:

* GitHub
* Vercel
* Edge networks
* CDNs
* Serverless functions
* Object storage
* Databases
* Authentication providers
* Content delivery systems

This is modern software engineering.
