# Appendix F: Folder Structure Reference

Targets Next.js 16. The complete project folder structure as it exists after finishing Part 13. Use this to sanity-check that your file layout matches what every Part's code blocks assume. Note there is intentionally no `tailwind.config.js` anywhere — Tailwind v4 config lives entirely inside `src/app/globals.css` (see Part 1).

```
freelancer-portal/
├─ prisma/
│  ├─ schema.prisma
│  └─ migrations/
│     └─ ...timestamped migration folders...
├─ src/
│  ├─ app/
│  │  ├─ page.tsx                                 (Part 2 - homepage w/ sign in/up links)
│  │  ├─ layout.tsx                                (Part 4 - ClerkProvider + TRPCReactProvider + Toaster)
│  │  ├─ globals.css                               (Tailwind v4 CSS-first config lives here — no tailwind.config.js)
│  │  ├─ dispatch/
│  │  │  └─ page.tsx                               (Part 2 - role-based redirect)
│  │  ├─ sign-in/[[...sign-in]]/page.tsx           (Part 2)
│  │  ├─ sign-up/[[...sign-up]]/page.tsx           (Part 2)
│  │  ├─ admin/
│  │  │  ├─ layout.tsx                             (Part 5 - sidebar nav)
│  │  │  ├─ page.tsx                               (Part 12 - dashboard w/ stats)
│  │  │  ├─ clients/
│  │  │  │  ├─ page.tsx                            (Part 5)
│  │  │  │  ├─ new-client-dialog.tsx               (Part 5)
│  │  │  │  ├─ loading.tsx                         (Part 12)
│  │  │  │  └─ [id]/                               (dynamic route — page.tsx uses async params: Promise<{ id: string }>)
│  │  │  │     ├─ page.tsx                         (Part 5 - client detail)
│  │  │  │     └─ new-project-dialog.tsx           (Part 5)
│  │  │  ├─ projects/
│  │  │  │  ├─ page.tsx                            (Part 5 - all projects)
│  │  │  │  ├─ loading.tsx                         (Part 12)
│  │  │  │  └─ [id]/                               (dynamic route — async params)
│  │  │  │     ├─ page.tsx                         (Part 9 - project detail w/ chat, attachments)
│  │  │  │     ├─ new-proposal-dialog.tsx          (Part 7)
│  │  │  │     └─ new-invoice-dialog.tsx           (Part 6)
│  │  │  ├─ proposals/
│  │  │  │  └─ [id]/                               (dynamic route — async params)
│  │  │  │     ├─ page.tsx                         (Part 7 - proposal detail)
│  │  │  │     └─ send-proposal-button.tsx         (Part 7)
│  │  │  └─ invoices/
│  │  │     ├─ page.tsx                            (Part 6 - all invoices)
│  │  │     ├─ loading.tsx                         (Part 12)
│  │  │     └─ [id]/                               (dynamic route — async params)
│  │  │        ├─ page.tsx                         (Part 6 - invoice detail)
│  │  │        └─ invoice-actions.tsx              (Part 6 - send/mark paid)
│  │  ├─ portal/
│  │  │  ├─ layout.tsx                             (Part 12 - sidebar nav)
│  │  │  ├─ page.tsx                               (Part 12 - client overview)
│  │  │  ├─ projects/
│  │  │  │  ├─ loading.tsx                         (Part 12)
│  │  │  │  └─ [id]/                               (dynamic route — async params)
│  │  │  │     └─ page.tsx                         (Part 9 - project detail w/ chat)
│  │  │  ├─ proposals/
│  │  │  │  ├─ page.tsx                            (Part 7)
│  │  │  │  ├─ loading.tsx                         (Part 12)
│  │  │  │  └─ [id]/                               (dynamic route — async params)
│  │  │  │     ├─ page.tsx                         (Part 7 - approve/request changes)
│  │  │  │     └─ proposal-response-actions.tsx    (Part 7)
│  │  │  └─ invoices/
│  │  │     ├─ page.tsx                            (Part 6)
│  │  │     ├─ loading.tsx                         (Part 12)
│  │  │     └─ [id]/                               (dynamic route — async params)
│  │  │        ├─ page.tsx                         (Part 6/10 - view + pay)
│  │  │        └─ pay-button.tsx                   (Part 10)
│  │  └─ api/
│  │     ├─ trpc/[trpc]/route.ts                   (Part 4 - catch-all route segment, not the async-params pattern)
│  │     ├─ uploadthing/
│  │     │  ├─ core.ts                             (Part 8)
│  │     │  └─ route.ts                            (Part 8)
│  │     └─ webhooks/
│  │        ├─ clerk/route.ts                      (Part 5 - uses await headers())
│  │        └─ stripe/route.ts                      (Part 10, updated Part 11 - uses await headers())
│  ├─ components/
│  │  ├─ ui/                                        (Part 1 - shadcn generated: button, input, label, card, dialog, table, badge, avatar, textarea, dropdown-menu, separator, tabs, sonner, form, select)
│  │  ├─ project-attachments.tsx                    (Part 8)
│  │  └─ project-chat.tsx                           (Part 9)
│  ├─ server/
│  │  ├─ db.ts                                      (Part 3)
│  │  ├─ stripe.ts                                  (Part 10)
│  │  ├─ invoice-number.ts                          (Part 6)
│  │  ├─ email/
│  │  │  ├─ resend.ts                               (Part 11)
│  │  │  └─ templates.ts                            (Part 11)
│  │  └─ api/
│  │     ├─ trpc.ts                                 (Part 4)
│  │     ├─ root.ts                                 (Part 4, updated every part after)
│  │     └─ routers/
│  │        ├─ health.ts                            (Part 4)
│  │        ├─ client.ts                            (Part 5)
│  │        ├─ project.ts                           (Part 5, updated Parts 9/12)
│  │        ├─ invoice.ts                           (Part 6, updated Parts 10/11)
│  │        ├─ proposal.ts                          (Part 7, updated Part 11)
│  │        ├─ message.ts                           (Part 9)
│  │        └─ dashboard.ts                         (Part 12)
│  ├─ lib/
│  │  ├─ utils.ts                                    (Part 1 - shadcn's cn helper)
│  │  └─ uploadthing.ts                              (Part 8)
│  ├─ trpc/
│  │  ├─ client.tsx                                  (Part 4)
│  │  └─ server.ts                                   (Part 4 - getServerApi() helper)
│  └─ middleware.ts                                  (Part 2 - project-root level, not inside app/)
├─ .env.local                                         (gitignored - see Appendix B)
├─ .env                                                (gitignored - Prisma CLI copy of DATABASE_URL, see Part 3)
├─ components.json                                    (Part 1 - shadcn config)
├─ package.json                                        (includes "engines": { "node": ">=20.9.0" } — see Part 1 and Appendix A)
├─ tsconfig.json
└─ next.config.ts (or .js/.mjs depending on scaffold choices)
```

Notably absent from this tree: `tailwind.config.js`. This is correct and expected for Tailwind CSS v4 — do not create one.

## Notes on this layout

- Every `admin/*` route mirrors a corresponding `portal/*` route where the feature is shared (projects, proposals, invoices) — same underlying data, different tRPC procedures (`adminProcedure` vs `protectedProcedure`+ownership) and slightly different UI (e.g., admin gets Send/Mark Paid buttons; client gets Approve/Pay buttons).
- Every `[id]` (or similarly bracketed) folder under `app/` is a Next.js 16 dynamic route segment whose `page.tsx` receives `params` as a `Promise` — always `await params` before using it, as shown throughout Parts 5-12.
- `src/server/api/routers/` contains one file per resource, always registered in `src/server/api/root.ts`.
- `src/components/` (top-level, not `components/ui/`) holds the two genuinely shared, reusable feature components (`ProjectChat`, `ProjectAttachments`) used by both admin and portal pages — everything else feature-specific lives colocated next to the page that uses it (e.g., `new-client-dialog.tsx` sits inside `app/admin/clients/` rather than in a global components folder), following Next.js App Router's colocation convention.
- If your file tree diverges from this appendix, it's a strong first place to check when something "can't find module" — import paths throughout the series assume this exact layout.

---

That completes the entire tutorial series: **Parts 0–14** plus **Appendices A through F**, all confirmed accurate against the stored notes. This is the full "Freelancer Client Portal" tutorial, built on Next.js 16, tRPC, Prisma, Clerk, UploadThing, Resend, Stripe, and Tailwind CSS v4 + shadcn/ui. Let me know if you'd like anything revisited, expanded, or exported differently.
