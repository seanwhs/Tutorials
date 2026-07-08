# Part 11: Transactional Emails with Resend

Previous: Part 10 (Payments with Stripe).

## 1. Concept

Emails at key moments: proposal sent → client; proposal approved/changes requested → admin; invoice sent → client; invoice paid → admin. Plain HTML template functions (no React Email needed, though it's a natural upgrade — Appendix E). Sent inside tRPC mutations and the Stripe webhook, right after the DB write succeeds.

## 2. Create a Resend account and verify a sending domain

1. resend.com → sign up.
2. Verify a domain (or use `onboarding@resend.dev` for local testing — only delivers to your own account email).
3. Copy API key.
4. `.env.local`:

```bash
RESEND_API_KEY=re_xxxxxxxx
EMAIL_FROM="Freelancer Portal <notifications@yourdomain.com>"
```

## 3. Install the SDK

```bash
pnpm add resend
```

## 4. Resend client + email templates

```ts
// src/server/email/resend.ts
import { Resend } from "resend";

export const resend = new Resend(process.env.RESEND_API_KEY);

export const EMAIL_FROM = process.env.EMAIL_FROM ?? "Freelancer Portal <onboarding@resend.dev>";
```

```ts
// src/server/email/templates.ts
export function proposalSentEmail({ clientName, title, url }: { clientName: string; title: string; url: string }) {
  return {
    subject: `New proposal: ${title}`,
    html: `
      <div style="font-family: sans-serif; max-width: 480px;">
        <h2>Hi ${clientName},</h2>
        <p>You have a new proposal to review: <strong>${title}</strong>.</p>
        <p><a href="${url}" style="background:#111;color:#fff;padding:10px 16px;border-radius:6px;text-decoration:none;">Review Proposal</a></p>
      </div>
    `,
  };
}

export function proposalRespondedEmail({
  title,
  approved,
  url,
}: {
  title: string;
  approved: boolean;
  url: string;
}) {
  return {
    subject: approved ? `Proposal approved: ${title}` : `Changes requested: ${title}`,
    html: `
      <div style="font-family: sans-serif; max-width: 480px;">
        <h2>${approved ? "Great news!" : "Update needed"}</h2>
        <p>Your proposal <strong>${title}</strong> was ${approved ? "approved" : "sent back with requested changes"} by the client.</p>
        <p><a href="${url}" style="background:#111;color:#fff;padding:10px 16px;border-radius:6px;text-decoration:none;">View Proposal</a></p>
      </div>
    `,
  };
}

export function invoiceSentEmail({
  clientName,
  number,
  total,
  url,
}: {
  clientName: string;
  number: string;
  total: string;
  url: string;
}) {
  return {
    subject: `New invoice ${number} - $${total} due`,
    html: `
      <div style="font-family: sans-serif; max-width: 480px;">
        <h2>Hi ${clientName},</h2>
        <p>A new invoice <strong>${number}</strong> for <strong>$${total}</strong> is ready for your review.</p>
        <p><a href="${url}" style="background:#111;color:#fff;padding:10px 16px;border-radius:6px;text-decoration:none;">View & Pay Invoice</a></p>
      </div>
    `,
  };
}

export function invoicePaidEmail({ number, total }: { number: string; total: string }) {
  return {
    subject: `Payment received for ${number}`,
    html: `
      <div style="font-family: sans-serif; max-width: 480px;">
        <h2>Payment received</h2>
        <p>Invoice <strong>${number}</strong> for <strong>$${total}</strong> has been paid.</p>
      </div>
    `,
  };
}
```

## 5. Send email on proposal.send (to the client)

```ts
// src/server/api/routers/proposal.ts (update the send procedure)
import { resend, EMAIL_FROM } from "@/server/email/resend";
import { proposalSentEmail } from "@/server/email/templates";

send: adminProcedure
  .input(z.object({ id: z.string() }))
  .mutation(async ({ ctx, input }) => {
    const updated = await ctx.db.proposal.update({
      where: { id: input.id },
      data: { status: "SENT", sentAt: new Date() },
      include: { project: { include: { client: true } } },
    });

    const clientEmail = updated.project.client.email;
    if (clientEmail) {
      const { subject, html } = proposalSentEmail({
        clientName: updated.project.client.name,
        title: updated.title,
        url: `${process.env.NEXT_PUBLIC_APP_URL}/portal/proposals/${updated.id}`,
      });

      await resend.emails.send({ from: EMAIL_FROM, to: clientEmail, subject, html }).catch((err) => {
        console.error("Failed to send proposal-sent email", err);
      });
    }

    return updated;
  }),
```

The `.catch()` ensures an email provider hiccup never fails the mutation.

## 6. Send email on proposal.approve / requestChanges (to the admin)

```bash
# .env.local
ADMIN_NOTIFICATION_EMAIL=you@yourdomain.com
```

```ts
// src/server/api/routers/proposal.ts (update approve)
import { proposalRespondedEmail } from "@/server/email/templates";

approve: protectedProcedure
  .input(z.object({ id: z.string() }))
  .mutation(async ({ ctx, input }) => {
    const proposal = await ctx.db.proposal.findUniqueOrThrow({
      where: { id: input.id },
      include: { project: { include: { client: true } } },
    });

    if (ctx.user.role !== "ADMIN" && proposal.project.client.userId !== ctx.user.id) {
      throw new TRPCError({ code: "FORBIDDEN" });
    }

    const updated = await ctx.db.proposal.update({
      where: { id: input.id },
      data: { status: "APPROVED", respondedAt: new Date() },
    });

    if (process.env.ADMIN_NOTIFICATION_EMAIL) {
      const { subject, html } = proposalRespondedEmail({
        title: proposal.title,
        approved: true,
        url: `${process.env.NEXT_PUBLIC_APP_URL}/admin/proposals/${proposal.id}`,
      });
      await resend.emails
        .send({ from: EMAIL_FROM, to: process.env.ADMIN_NOTIFICATION_EMAIL, subject, html })
        .catch((err) => console.error("Failed to send proposal-approved email", err));
    }

    return updated;
  }),
```

Apply the same pattern (`approved: false`) inside `requestChanges` after its `$transaction` succeeds.

## 7. Send email on invoice.send (to the client)

```ts
// src/server/api/routers/invoice.ts (update the send procedure)
import { resend, EMAIL_FROM } from "@/server/email/resend";
import { invoiceSentEmail } from "@/server/email/templates";

send: adminProcedure
  .input(z.object({ id: z.string() }))
  .mutation(async ({ ctx, input }) => {
    const updated = await ctx.db.invoice.update({
      where: { id: input.id },
      data: { status: "SENT" },
      include: { project: { include: { client: true } } },
    });

    const clientEmail = updated.project.client.email;
    if (clientEmail) {
      const { subject, html } = invoiceSentEmail({
        clientName: updated.project.client.name,
        number: updated.number,
        total: Number(updated.total).toFixed(2),
        url: `${process.env.NEXT_PUBLIC_APP_URL}/portal/invoices/${updated.id}`,
      });
      await resend.emails.send({ from: EMAIL_FROM, to: clientEmail, subject, html }).catch((err) => {
        console.error("Failed to send invoice-sent email", err);
      });
    }

    return updated;
  }),
```

## 8. Send email when Stripe webhook marks an invoice PAID (to the admin)

```ts
// src/app/api/webhooks/stripe/route.ts (update the checkout.session.completed branch)
import { resend, EMAIL_FROM } from "@/server/email/resend";
import { invoicePaidEmail } from "@/server/email/templates";

if (event.type === "checkout.session.completed") {
  const session = event.data.object as Stripe.Checkout.Session;
  const invoiceId = session.metadata?.invoiceId;

  if (invoiceId) {
    const updated = await db.invoice.update({
      where: { id: invoiceId },
      data: {
        status: "PAID",
        paidAt: new Date(),
        stripePaymentIntentId:
          typeof session.payment_intent === "string" ? session.payment_intent : undefined,
      },
    });

    if (process.env.ADMIN_NOTIFICATION_EMAIL) {
      const { subject, html } = invoicePaidEmail({
        number: updated.number,
        total: Number(updated.total).toFixed(2),
      });
      await resend.emails
        .send({ from: EMAIL_FROM, to: process.env.ADMIN_NOTIFICATION_EMAIL, subject, html })
        .catch((err) => console.error("Failed to send invoice-paid email", err));
    }
  }
}
```

## Checkpoint

- [ ] Sending a proposal emails the client
- [ ] Approving/requesting changes emails admin
- [ ] Sending an invoice emails the client
- [ ] Stripe test payment emails admin
- [ ] Misconfigured Resend doesn't fail mutations

## Troubleshooting

- **Nothing arrives**: check domain verification or resend.dev test-sender limits
- **"from" rejected**: needs verified domain in production

## Next

Continue to **Part 12: Admin Dashboard Polish & Role-Based Views**.
