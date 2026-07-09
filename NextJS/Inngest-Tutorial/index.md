# Inngest Tutorial — INDEX (Start Here)

**STATUS: complete.** A beginner-friendly, code-heavy, step-by-step tutorial series teaching **Inngest** (durable background jobs, event-driven workflows, scheduling) by building **TaskFlow**, a real team task-management app, on **Next.js 16**.

## Series structure

**Introduction**
- Part 0: Introduction and What Is Inngest

**Foundations**
- Part 1: Project Setup and Your First Function
- Part 2: Events, Functions, and the Serve Route Deep Dive

**Building the real app**
- Part 3: Clerk Auth, Prisma Schema, and Your First Real Event
- Part 3b: Prisma Schema and the Clerk Webhook Function
- Part 4: step.run Deep Dive and Welcome Emails with Resend
- Part 5: Projects and Tasks CRUD UI

**Core Inngest patterns**
- Part 6: Fan-Out Notifications with step.sendEvent
- Part 7: Multi-Day Onboarding Drip with step.sleep
- Part 8: Scheduled Cron Functions
- Part 9: Human-in-the-Loop with step.waitForEvent

**Reliability, observability, and shipping**
- Part 10: Reliability Controls (retries, idempotency, concurrency, rate limiting, throttling)
- Part 11: Observability, Logging, and Testing
- Part 12: Deploying to Vercel and Inngest Cloud

**Conclusion**

## Appendices

- Appendix A INDEX: Full Codebase Reference
- Appendix B: Environment Variables Reference
- Appendix C: Inngest Functions Reference
- Appendix D: Inngest Concepts Cheat Sheet
- Appendix E: Troubleshooting Guide

## What you'll build

**TaskFlow**: users sign up (Clerk), get synced into Postgres with a welcome email plus multi-day onboarding drip, create projects/tasks, get fan-out notifications on task creation/assignment, receive scheduled daily digests and hourly overdue-task alerts, and can submit tasks for review with a 24-hour human-approval window that auto-approves on timeout — all on free tiers of Clerk, Neon, Inngest, Resend, and Vercel.

## Tech stack

Next.js 16 · Inngest · Clerk · Neon · Prisma · Resend · Tailwind CSS v4 · Vitest + `@inngest/test` · Vercel

## How to use this series

Follow the parts in order — each builds on the previous part's code. Every part ends with a Checkpoint and Troubleshooting section. If something breaks, check Appendix E first, then Appendix A's file map.

