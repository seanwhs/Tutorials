# Part 0: Introduction

Welcome! In this tutorial series you're going to build a real, working **Next.js 16** application with full user authentication - sign up, sign in, sessions, protected pages, teams/organizations, roles, and even syncing users to your own database - using **Clerk** for auth and **Tailwind CSS v4** for styling.

## Why Clerk?

Authentication is one of those things every app needs, but it's genuinely hard to build correctly and safely from scratch: password hashing, session tokens, email verification, password reset flows, social login (Google/GitHub), multi-factor auth, protecting against common attacks... it's a lot, and getting it wrong has serious consequences.

Clerk is a hosted authentication service that handles all of that for you, while giving you flexible building blocks (prebuilt components AND hooks for full custom UIs) so your app can still look and feel exactly like your own product. It has a free tier generous enough for learning, side projects, and even early-stage startups.

## Why Tailwind CSS?

Tailwind is a utility-first CSS framework. Instead of writing custom CSS files, you style elements directly in your markup with small utility classes like `flex`, `p-4`, `text-lg`, `bg-blue-600`. It's extremely popular in the Next.js ecosystem, is free and open source, and pairs very well with Clerk's `appearance` prop for theming (which you'll see in Part 10). This series uses **Tailwind CSS v4**, which uses a simpler CSS-first configuration (no separate `tailwind.config.ts` file needed for basic usage).

## Why Next.js 16 specifically?

This series targets **Next.js 16** as its baseline, which matters for a few concrete reasons you'll see throughout:
- **Turbopack is the default** bundler for both `next dev` and `next build` (previously opt-in).
- **Dynamic APIs are async.** Functions like `headers()`, `cookies()`, and route `params`/`searchParams` must be `await`ed - this affects how we write Server Components and our webhook route.
- **Node.js 20.9+ or 22 LTS is required.** Older Node versions are not supported.
- Clerk's SDK (`@clerk/nextjs`) is fully compatible with Next.js 16 and already uses async patterns internally, so nothing about Clerk itself changes - we just need to write our own code (like `auth()` calls) the async-aware way.

If you're following this series with a slightly newer or older patch version of Next.js 16, the concepts and code will still apply - just watch for the version-specific troubleshooting notes sprinkled throughout.

## What we're building

A small SaaS-style app shell called **"Acme Boards"** (you can rename it anything you like) with:
1. A public marketing homepage
2. Sign up / sign in pages
3. A protected `/dashboard` only logged-in users can reach
4. A polished, Tailwind-styled UI throughout, including a fully custom auth form (not just the default Clerk look)
5. Organizations - so users can create/join a "team" or "company workspace"
6. Roles - admins can do things members can't
7. A webhook endpoint that syncs new Clerk users into your own database table
8. A live deployment on Vercel's free tier

This mirrors the kind of auth setup you'd see in a real multi-tenant SaaS product.

## Prerequisites

You do **not** need prior experience with Clerk. You should be comfortable with:
- Basic JavaScript/TypeScript
- Basic React (components, props, hooks like `useState`)
- Using a terminal to run commands (we'll walk through everything)

You do **not** need prior Tailwind experience - Part 3 is a crash course.

## Tools we'll use (all free)

| Tool | Purpose | Cost |
|---|---|---|
| Node.js 20.9+ / 22 LTS | JavaScript runtime | Free, open source |
| VS Code | Code editor | Free |
| Git + GitHub | Version control / hosting code | Free |
| Next.js 16 | React framework (App Router, Turbopack) | Free, open source |
| Tailwind CSS v4 | Styling | Free, open source |
| Clerk | Authentication | Free tier (10,000 MAUs at time of writing) |
| Vercel | Deployment | Free Hobby tier |

No credit card is required for any of these at the scale we're working at.

## How each part works

Every part follows the same shape:
1. **Concept** - a short explanation of what we're adding and why
2. **Code** - the exact files to create or edit, shown in full, so you can type them yourself
3. **Test it** - how to run and check that what you just built actually works
4. **Checkpoint** - a quick summary of what's now true about your app
5. **Troubleshooting** - common mistakes and their fixes, including Next.js 16-specific gotchas

Type the code yourself rather than skimming it - that's how it sticks. Every part assumes you completed the previous ones in order.

## A note on versions

Clerk, Next.js, and Tailwind all update frequently. This tutorial is built specifically around **Next.js 16's** conventions (async dynamic APIs, Turbopack default, Node 20.9+/22 required) and **Tailwind CSS v4's** CSS-first setup. If a command's output looks slightly different for you on a minor patch version, that's normal - the concepts and file structure will still apply. Troubleshooting sections flag the most common version-related snags.

Ready? Let's set up your computer in Part 1.
