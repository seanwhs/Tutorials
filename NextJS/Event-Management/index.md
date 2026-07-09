# EventHub Tutorial — INDEX (Start Here)

**STATUS: fully regenerated in place and explicitly validated for Next.js 16.** A beginner-friendly, code-heavy, step-by-step tutorial series for building a free event management website ("EventHub") with Next.js 16, Clerk, Neon, Drizzle ORM, and Inngest — deployed live for $0/month.

## Next.js 16 baseline (applies to every part)
- **Node.js 20.9+ or 22 LTS required**
- **Turbopack** is the default dev/build bundler
- **All dynamic APIs are async**: `params`, `searchParams`, Clerk's `auth()`/`currentUser()` — always awaited
- **Tailwind CSS v4, CSS-first config** — no `tailwind.config.ts`, everything lives in `globals.css`

## Series structure

**Introduction** — Part 1: Introduction and Series Overview

**Foundations** — Part 2: Dev Environment Setup · Part 3: Next.js 16 Project Setup · Part 4: Clerk Auth · Part 5: Neon + Drizzle · Part 6: Schema Design · Part 7: Data Model, Migrations & Clerk Sync

**Core event features** — Part 8/8b/8c: Event Creation UI · Part 9: Public Listing/Detail · Part 10: RSVP Flow · Part 11: Attendee Dashboard

**Tickets & check-in** — Part 12: QR Codes · Part 13: Check-In Flow · Part 14: Check-In Dashboard & Live Stats

**Background jobs** — Part 15: Inngest Setup · Part 16: Confirmation Emails · Part 17: Scheduled Reminders · Part 18: Email Deliverability/Idempotency

**Polish & production** — Part 19: Waitlist/Capacity · Part 20: Search/Pagination · Part 21: Authorization/Roles · Part 22: Testing/Error Handling

**Ship it** — Part 23: Deploy to Vercel · Part 24: Roadmap

**Conclusion**

## Appendices
- **A**: Full Codebase Reference (INDEX + Parts 1, 2, 3, 3b, 4, 5, 5b, 5c, 5d)
- **B**: Environment Variables Reference
- **C**: Database Schema Reference
- **D**: Inngest Functions Reference
- **E**: Troubleshooting Guide (incl. Next.js 16 gotchas)

## Tech stack
Next.js 16 (App Router, Turbopack) · Clerk · Neon · Drizzle ORM · Inngest · Resend · `qrcode` + `html5-qrcode` · Tailwind CSS v4 · Vitest · Vercel

**How to use:** follow parts in order, hit each "Checkpoint" before moving on, use Appendix E for troubleshooting and Appendix A to diff your code against the final reference.
