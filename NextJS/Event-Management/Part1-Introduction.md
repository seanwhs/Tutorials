# **Part 1: Introduction and Series Overview**:

---

# EventHub: Build a Free Event Management Website with Next.js 16, Clerk, Neon & Inngest

## Welcome

A multi-part, beginner-friendly, code-heavy tutorial series building **EventHub** — a real event management website — from an empty folder to live production, using only free/open-source tools, on **Next.js 16**.

By the end you'll have built an app where:
- **Organizers** create/manage events from a dashboard
- **Attendees** browse events and **RSVP for free** (no payments — strictly free-RSVP, no Stripe)
- Every attendee gets a **QR-code digital ticket**
- Organizers **check attendees in** at the door (scan or manual code), with a live dashboard
- **Confirmation emails** send instantly on RSVP; **reminder emails** send automatically on a schedule — via background jobs, not manual cron scripts
- Deployed live for **$0/month** (Vercel, Neon, Clerk, Inngest free tiers)

## Why Next.js 16, specifically
- **Node.js 20.9+ or 22 LTS required** (Node 18 is EOL/unsupported)
- **Turbopack** is the default bundler for `next dev`/`next build` — no flag needed
- **Every dynamic API is async**: `params`, `searchParams`, Clerk's `auth()`/`currentUser()` all return Promises — always `await` them
- **Tailwind CSS v4 uses CSS-first config** — no `tailwind.config.ts`; config lives in `globals.css` via `@import "tailwindcss";` plus `@plugin`/`@custom-variant` directives

## Who this is for
Assumes basic JS/TS knowledge, some React exposure (not Next.js expertise), zero prior experience with Clerk/Neon/Drizzle/Inngest, and Node 20.9+/22 LTS + free GitHub account. **No credit card needed anywhere.**

## Tech stack

| Concern | Tool | Why |
|---|---|---|
| Framework | Next.js 16 (App Router, Turbopack) | One framework, huge ecosystem, first-class Vercel support |
| Auth | Clerk (free) | Full auth in a few lines, no hand-rolled password hashing |
| Database | Neon (free Postgres) | Real Postgres, scales to zero |
| ORM | Drizzle | Lightweight, type-safe, SQL-like |
| Background jobs | Inngest (free) | Event-driven + cron functions, no queue/server to manage |
| Email | Resend (free, 100/day) | Simple API, generous allowance |
| QR codes | `qrcode` npm package | Server-side, zero cost |
| Styling | Tailwind CSS v4 | CSS-first config |
| Hosting | Vercel (free Hobby) | Native Next.js hosting, GitHub deploys |

## What we're building (plain English)
A stripped-down Eventbrite: public browsing → sign-up to RSVP/organize → RSVP fires an Inngest event → confirmation email w/ QR code → organizer dashboard w/ live check-in view → hourly cron job emails reminders for upcoming events.

## Series structure
1. **Foundations** (Parts 2–7): env setup, Next.js 16 + Tailwind v4 setup, Clerk, Neon+Drizzle, schema
2. **Core features** (Parts 8–11): create/browse/RSVP/My RSVPs
3. **Tickets & check-in** (Parts 12–14): QR codes, check-in flow, live dashboard
4. **Background jobs** (Parts 15–18): Inngest, confirmation emails, reminders, deliverability
5. **Polish** (Parts 19–22): waitlist, search/pagination, authorization, error handling
6. **Ship it** (Part 23): deploy to Vercel free
7. **Part 24**: roadmap/Phase 2 ideas

Each part ends with a **Checkpoint** — don't advance until it's satisfied. Appendix A has the full reference codebase; B–E cover env vars, schema, Inngest functions, and troubleshooting.

## Style note
Real code over abstract explanation throughout — every sample already uses correct async `params`/`searchParams`/`auth()` conventions, nothing to retrofit later.

**Next: Part 2 — Development Environment Setup**
