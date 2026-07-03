# Appendix A — Deploying GreyMatter Journal to Vercel

> **Goal of this appendix:** Learn how to deploy GreyMatter Journal to production using Vercel while understanding what actually happens during the deployment process, how environment variables work, and how modern cloud platforms transform source code into globally distributed applications. [nextjs](https://nextjs.org/learn/pages-router/deploying-nextjs-app-deploy)

***

# Introduction

Throughout this tutorial series, we built and tested GreyMatter Journal locally using:

```bash
npm run dev
```

This launches a development server on:

```text
http://localhost:3000
```

This is perfect for development, but nobody else can access your application.

To make GreyMatter Journal available to the world, we need to deploy it to production.

Next.js and Vercel together provide one of the simplest deployment experiences available today, especially for App Router projects. [vercel](https://vercel.com/docs/frameworks/full-stack/nextjs)

***

# Why Vercel?

Vercel is the company behind Next.js, and their platform is specifically designed to run Next.js applications efficiently. [vercel](https://vercel.com/frameworks/nextjs)

Vercel provides:

- Global CDN distribution  
- Automatic HTTPS and certificates  
- Serverless and edge functions  
- Edge network routing  
- Automatic image optimization  
- Continuous deployment from Git  
- Preview deployments per branch  
- Environment variable management  
- Analytics and observability

Most importantly, Vercel understands the internal architecture of Next.js, which allows it to optimize builds, routing, and caching automatically. [vercel](https://vercel.com/frameworks/nextjs)

***

# Before You Begin

Ensure you have:

- Completed the GreyMatter Journal tutorial series  
- A GitHub account  
- A Vercel account  
- A working Sanity project  
- A functioning local application

Verify your application runs locally:

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

Confirm that:

- Articles load  
- Images render  
- Authentication works  
- Comments function correctly  

Only deploy applications that already work locally. If `npm run build` fails locally, it will fail on Vercel as well. [nextjs](https://nextjs.org/learn/pages-router/deploying-nextjs-app-deploy)

***

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

***

## What Is Git Doing?

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

Modern deployment systems use Git commits as their source of truth: they build exactly what you pushed, with a clear history of how it changed. [vercel](https://vercel.com/kb/guide/deploying-next-and-userbase-with-vercel)

***

# Step 2 — Create a GitHub Repository

Open GitHub and create a new repository:

```text
greymatter-journal
```

Do not initialize the repository with:

- README  
- .gitignore  
- License  

Your local project already contains these files.

***

# Step 3 — Connect Your Local Repository

GitHub will provide commands similar to:

```bash
git remote add origin \
https://github.com/YOUR_USERNAME/greymatter-journal.git

git branch -M main

git push -u origin main
```

After pushing, refresh GitHub.

You should see your complete project in the repository.

***

## Why Push to GitHub?

Modern deployment pipelines typically look like:

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

GitHub acts as the bridge between your local work and the deployment platform. Vercel listens for changes on specific branches and automatically rebuilds and redeploys your app. [youtube](https://www.youtube.com/watch?v=9n8Gh4t5byE)

***

# Step 4 — Create a Vercel Account

Visit:

```text
https://vercel.com
```

Sign in using your GitHub account.

This allows Vercel to:

- Read your repositories  
- Monitor commits and pull requests  
- Trigger deployments automatically  

The integration gives you “push to deploy” behavior with minimal setup. [youtube](https://www.youtube.com/watch?v=f8nrw6fdMeM)

***

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

This detection enables:

- Automatic `next build` execution  
- Next.js-aware routing and functions  
- Edge and serverless configurations optimized for App Router [vercel](https://vercel.com/docs/frameworks/full-stack/nextjs)

***

# Step 6 — Configure Environment Variables

Before deployment, add your environment variables.

In the Vercel dashboard:

```text
Project → Settings → Environment Variables
```

Add:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id
NEXT_PUBLIC_SANITY_DATASET=production
SANITY_API_TOKEN=your_api_token
```

If you implemented authentication:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_publishable_key
CLERK_SECRET_KEY=your_secret_key
```

Vercel supports separate values for Development, Preview, and Production environments, so you can scope secrets appropriately. [vercel](https://vercel.com/docs/environment-variables)

***

## Why Environment Variables Exist

Never write secrets directly into source code.

Bad:

```typescript
const apiKey = "my-secret-key";
```

Good:

```typescript
const apiKey = process.env.API_KEY;
```

This separates:

```text
Application Code

from

Deployment Configuration
```

Environment variables let you:

- Change credentials without changing code  
- Use different settings per environment (dev / preview / prod)  
- Keep secrets out of Git history [vercel](https://vercel.com/academy/nextjs-foundations/env-and-security)

In Next.js:

- Variables prefixed with `NEXT_PUBLIC_` are exposed to the browser.  
- Others are only available on the server side. [zenn](https://zenn.dev/slowhand/articles/9cb5d6830fc018?locale=en)

***

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

After a few minutes, you’ll receive a URL similar to:

```text
https://greymatter-journal.vercel.app
```

At this moment:

```text
GreyMatter Journal
is live.
```

***

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

- JavaScript bundles  
- HTML  
- CSS  
- Serverless and edge function bundles  
- Route and build manifests  
- Optimized images and static assets [vercel](https://vercel.com/docs/frameworks/full-stack/nextjs)

This process is called **compilation** and **bundling**. The `.next` directory is what actually runs in production, not your TypeScript and JSX files.

***

# Step 8 — Configure Sanity CORS

Open your Sanity project’s API settings:

```text
Sanity → API → CORS Origins
```

Add:

```text
https://greymatter-journal.vercel.app
```

Without this configuration, your deployed application may fail to communicate with Sanity due to CORS restrictions.

You may also add:

```text
https://*.vercel.app
```

during development and preview, then tighten it later if needed. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

# Step 9 — Configure Revalidation Webhooks (Optional)

To automatically refresh content after publishing articles:

In the Sanity dashboard:

```text
API → Webhooks
```

Create a webhook pointing to:

```text
https://your-site.vercel.app/api/revalidate
```

This allows published content to appear immediately without waiting for cache expiration, by triggering ISR or tag-based revalidation via a serverless route. [dev](https://dev.to/realacjoshua/nextjs-16-caching-explained-revalidation-tags-draft-mode-real-production-patterns-26dl)

***

# Preview Deployments

One of Vercel’s most powerful features is **Preview Deployments**.

Suppose you push:

```bash
git push origin feature/new-layout
```

Vercel automatically creates a preview deployment:

```text
https://greymatter-journal-git-feature-new-layout.vercel.app
```

This allows you to:

- Test features in isolation  
- Share previews with teammates or stakeholders  
- Review UI and behavior before merging  
- Validate functionality under production-like conditions

Every non-production branch gets its own URL with its own environment scope. [vercel](https://vercel.com/academy/svelte-on-vercel/preview-deployments)

***

# Continuous Deployment

After the initial setup, deployment becomes automatic.

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

This is called:

```text
Continuous Deployment
```

Combined with automated builds and tests, this forms your basic CI/CD pipeline. [youtube](https://www.youtube.com/watch?v=f8nrw6fdMeM)

***

# Troubleshooting Common Errors

## Missing Environment Variables

Error:

```text
undefined environment variable
```

Solution:

- Verify variables are defined in Vercel’s Environment Variables for the correct scope (Production / Preview).  
- Ensure names match exactly those used in `process.env`.  
- Trigger a new deployment after changes. [value1](https://value1.shop/tutorials/nextjs-env-vars-vercel/)

***

## Sanity Authentication Errors

Error:

```text
Unauthorized
```

Solution:

- Verify `SANITY_API_TOKEN` has the correct permissions.  
- Verify `NEXT_PUBLIC_SANITY_PROJECT_ID` and dataset names.  
- Ensure CORS origins include your Vercel domain. [sanity](https://www.sanity.io/blog/build-your-own-blog-with-sanity-and-next-js)

***

## Image Errors

Error:

```text
Invalid src prop
```

Solution:

- Ensure your `next.config.ts` (or `next.config.js`) allows the Sanity image domain in `images.remotePatterns` or `images.domains`.  
- Confirm the URL generated by `urlFor()` is valid.

***

## Build Failures

If Vercel builds fail, run locally:

```bash
npm run build
```

If this fails locally, fix errors in your source code before redeploying.

Vercel’s build logs will also show:

- TypeScript errors  
- Missing imports  
- Misconfigured environment variables [eastondev](https://eastondev.com/blog/en/posts/dev/20251220-nextjs-vercel-deploy-guide/)

***

# The Hidden Architecture of a Request

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
Serverless / Edge Function
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

Vercel, Next.js, Sanity, and your code together form a multi-layered distributed application.

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
        Source Code
        Into
        Distributed Reality
```

When you deploy GreyMatter Journal, you are not simply publishing HTML.

You are orchestrating a distributed system spanning:

- GitHub (source of truth)  
- Vercel (builds and edge network)  
- Edge networks and CDNs  
- Serverless and edge functions  
- Object storage and CDNs for images  
- Databases and headless CMSes  
- Authentication providers  
- Observability and analytics pipelines [vercel](https://vercel.com/docs/environment-variables)

This is modern software engineering: turning ideas and source code into globally distributed, observable, and maintainable systems.
