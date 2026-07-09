**Build "Acme Shop" — Stripe Payments with Next.js 16 & Tailwind CSS**

## What you're building
A demo storefront ("Acme Shop") covering: product catalog with one-time Stripe Checkout, a multi-item cart, verified webhooks recording orders in a database, order history, subscriptions, and a self-service Customer Portal — all testable for free using Stripe test mode.

## Stack (100% free)
| Concern | Tool |
|---|---|
| Framework | Next.js 16 (App Router, Turbopack) |
| Styling | Tailwind CSS v4 |
| Payments | Stripe (test mode) |
| Local webhook testing | Stripe CLI |
| Database | SQLite |
| ORM | Prisma |
| Hosting | Vercel (Hobby tier) |

## Parts (0–15)
0. Introduction & architecture
1. Dev environment & project setup
2. Stripe account setup, API keys & SDK
3. Product catalog & "Buy Now" (one-time payment)
4. Success & cancel pages
5. Multi-item shopping cart
6. Cart checkout (multiple line items)
7. Database setup (Prisma + SQLite)
8. Stripe webhooks (signature verification + `checkout.session.completed`)
9. Local webhook testing with the Stripe CLI
10. Order history page
11. Subscriptions (recurring Checkout mode)
12. Customer Portal (self-service manage/cancel)
13. Polish (error handling, env safety, security)
14. Deploying to Vercel for free
15. Conclusion & next steps

## Appendices
- **A (1–5 of 5)** — Full codebase reference (split across 5 notes: config/lib/schema → components → pages → more pages → API routes)
- **B** — Environment variables reference
- **C** — Stripe test card & test data reference
- **D** — Troubleshooting guide
- **E** — Further resources & next steps
