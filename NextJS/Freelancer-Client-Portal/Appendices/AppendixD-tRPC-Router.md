# Appendix D: Full tRPC Router Reference

A quick-reference index of every procedure in the app: which router it lives in, its access level, inputs, and what it does. Full implementations are in the Parts noted.

## health (Part 4)

| Procedure | Type | Access | Input | Description |
|---|---|---|---|---|
| ping | query | public | none | Sanity check, returns `{ message, time }`. |

## client (Part 5)

| Procedure | Type | Access | Input | Description |
|---|---|---|---|---|
| list | query | admin | none | All clients + their projects. |
| byId | query | admin | `{ id }` | One client + its projects. |
| create | mutation | admin | `{ name, company?, email }` | Creates a Client. |
| update | mutation | admin | `{ id, name, company?, email }` | Updates a Client. |
| delete | mutation | admin | `{ id }` | Deletes a Client (cascades to projects). |

## project (Parts 5, 9, 12)

| Procedure | Type | Access | Input | Description |
|---|---|---|---|---|
| list | query | admin | none | All projects + client info. |
| listMine | query | protected | none | Caller's own projects (client role). Added Part 12. |
| byId | query | protected + ownership check | `{ id }` | One project + client/proposals/invoices. Upgraded from admin-only in Part 9. |
| create | mutation | admin | `{ clientId, name, description? }` | Creates a Project under a Client. |
| updateStatus | mutation | admin | `{ id, status }` | Updates ACTIVE/ON_HOLD/COMPLETED. |

## invoice (Parts 6, 10, 11)

| Procedure | Type | Access | Input | Description |
|---|---|---|---|---|
| listAll | query | admin | none | All invoices across all clients. |
| listByProject | query | admin | `{ projectId }` | Invoices for one project. |
| listMine | query | protected | none | Caller's own invoices (client role). |
| byId | query | protected + ownership check | `{ id }` | One invoice + items; admin sees any, client sees own. |
| create | mutation | admin | `{ projectId, dueDate, items[] }` | Creates invoice with line items, auto-generates number, computes total. |
| send | mutation | admin | `{ id }` | Sets status SENT; emails client (Part 11). |
| markPaidManually | mutation | admin | `{ id }` | Sets status PAID, paidAt now — manual/offline payment fallback. |
| createCheckoutSession | mutation | protected + ownership check | `{ invoiceId }` | Creates a Stripe Checkout Session, returns redirect url. |

## proposal (Parts 7, 11)

| Procedure | Type | Access | Input | Description |
|---|---|---|---|---|
| listByProject | query | admin | `{ projectId }` | Proposals for one project. |
| listMine | query | protected | none | Caller's own proposals (client role). |
| byId | query | protected + ownership check | `{ id }` | One proposal; admin sees any, client sees own. |
| create | mutation | admin | `{ projectId, title, content, amount }` | Creates a DRAFT proposal. |
| send | mutation | admin | `{ id }` | Sets status SENT, sentAt now; emails client (Part 11). |
| approve | mutation | protected + ownership check | `{ id }` | Sets status APPROVED, respondedAt now; emails admin (Part 11). |
| requestChanges | mutation | protected + ownership check | `{ id, comment }` | Sets status CHANGES_REQUESTED, logs a Message, emails admin (Part 11). |

## message (Part 9)

| Procedure | Type | Access | Input | Description |
|---|---|---|---|---|
| listByProject | query | protected + ownership check | `{ projectId }` | Full thread for a project, oldest first. |
| send | mutation | protected + ownership check | `{ projectId, body }` | Appends a message from the caller. |

## dashboard (Part 12)

| Procedure | Type | Access | Input | Description |
|---|---|---|---|---|
| adminStats | query | admin | none | `{ clientCount, activeProjectCount, outstandingTotal, unpaidInvoiceCount, pendingProposals }`. |

## Access level legend

- **public**: no auth required (procedure built on `publicProcedure`).
- **admin**: caller's `User.role` must be `ADMIN` (`adminProcedure`).
- **protected**: caller must be signed in and synced to a `User` row (`protectedProcedure`); no further restriction beyond that.
- **protected + ownership check**: `protectedProcedure` plus an explicit in-procedure check that either `ctx.user.role === "ADMIN"` or the resource's `Client.userId === ctx.user.id`, throwing `TRPCError({ code: "FORBIDDEN" })` otherwise. This is the pattern used for every resource a client should only see their own copy of.

## Adding a new procedure (checklist for Phase 2 work)

1. Decide the access level using the legend above.
2. Define a zod input schema (even if just `z.object({ id: z.string() })`) — never trust unvalidated input.
3. If it's a shared (protected) procedure touching one specific resource, always include the ownership check pattern shown throughout `invoice.ts` / `proposal.ts` / `message.ts`.
4. Wrap multi-table writes in `ctx.db.$transaction(...)` if they must succeed or fail together (see `proposal.requestChanges` for a reference example).
5. Register the router (or new procedure) in `src/server/api/root.ts`.
6. Wrap any third-party side effect (email, webhook call) in a `.catch()` so it can't fail the core mutation.
