## Part 19: Your First Background Job

Goal of this part: install Inngest, understand events and functions (Inngest's core concepts), and build our first real background job — sending an invoice confirmation email in the background after an invoice is created, instead of making the user wait for it.

Prerequisite: Parts 1-18 completed.

---

### 1. Why this needed its own dedicated part, this late in the course

Recall Part 3's explanation: Inngest handles things that shouldn't block a web request (emails, PDFs) and things that need to run on a schedule with no request at all (Part 20). We deliberately waited until now to introduce it, because Inngest is most useful once you actually have real actions worth automating — and now we do: eighteen parts of invoices, bills, and payments give us plenty of real events to react to.

### 2. Two core Inngest concepts: events and functions

**An event** is a small piece of data describing "something happened" — e.g. `{ name: "invoice/created", data: { invoiceId: "abc-123", orgId: "org_xyz" } }`. Your app SENDS events whenever something notable occurs.

**A function** is code that RUNS in response to one or more event types. You register functions with Inngest ahead of time, each declaring which event(s) trigger it. When a matching event arrives, Inngest calls your function — reliably, with automatic retries if it fails, and (starting Part 20) on a schedule too.

The key shift in thinking: instead of your invoice-creation code directly calling "send an email" inline, it just sends an event ("an invoice was created") and moves on immediately. A separate function, running independently, picks up that event and handles the email — on its own time, with its own retry logic, completely decoupled from the original request.

### 3. Sign up for Inngest and install the package

1. Go to https://www.inngest.com and sign up for a free account (the free tier is generous and plenty for this whole course)
2. You don't need to create anything in their dashboard yet for local development — Inngest provides a local dev server we'll run alongside our Next.js app

Install the package:
```
npm install inngest
```

### 4. Create the Inngest client

Create `src/lib/inngest/client.ts`:

```ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "qb-clone" });
```

This id is just a name identifying your app to Inngest — keep it as-is.

### 5. Create the Inngest API route

Inngest needs a route in your Next.js app that it can call to discover and invoke your functions. Create `src/app/api/inngest/route.ts`:

```ts
import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest/client";
import { sendInvoiceEmail } from "@/lib/inngest/functions/send-invoice-email";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [sendInvoiceEmail],
});
```

We'll create `sendInvoiceEmail` next — this file's job is just to register every Inngest function your app has, in one place, so Inngest can find them.

### 6. Write your first Inngest function

Create `src/lib/inngest/functions/send-invoice-email.ts`:

```ts
import { inngest } from "@/lib/inngest/client";
import { db } from "@/lib/db";
import { invoices, customers } from "@/lib/db/schema";
import { eq } from "drizzle-orm";

export const sendInvoiceEmail = inngest.createFunction(
  { id: "send-invoice-email" },
  { event: "invoice/created" },
  async ({ event, step }) => {
    const { invoiceId } = event.data;

    const invoice = await step.run("fetch-invoice", async () => {
      const [inv] = await db
        .select({
          id: invoices.id,
          invoiceNumber: invoices.invoiceNumber,
          totalCents: invoices.totalCents,
          customerName: customers.name,
          customerEmail: customers.email,
        })
        .from(invoices)
        .innerJoin(customers, eq(customers.id, invoices.customerId))
        .where(eq(invoices.id, invoiceId))
        .limit(1);
      return inv;
    });

    if (!invoice || !invoice.customerEmail) {
      return { skipped: true, reason: "No invoice or customer email found" };
    }

    await step.run("send-email", async () => {
      // For this part, we log instead of actually sending a real email -
      // a real email provider is a great add-on, but logging keeps this
      // part focused on the Inngest pattern itself.
      console.log(
        `[EMAIL] To: ${invoice.customerEmail} - Invoice ${invoice.invoiceNumber} for $${(
          invoice.totalCents / 100
        ).toFixed(2)}`
      );
    });

    return { sent: true, invoiceId };
  }
);
```

What's new here, carefully:
- `inngest.createFunction` takes a config object (a unique id for this function), a trigger (which event fires it — here, "invoice/created"), and the handler itself.
- The handler receives `event` (the event data that triggered it) and `step` — `step` is Inngest's tool for breaking your function into named, independently-retried stages. Each `step.run("some-name", async () => {...})` is checkpointed: if your function fails partway through and Inngest retries it, steps that already succeeded are NOT re-run — only the failed step (and anything after it) runs again. This is exactly the "multi-step, retry-safe" behavior Part 3 promised.
- Why does this matter for us specifically? Imagine "send-email" succeeds but something after it fails (in a more complex function) — without steps, a retry would re-send the email, potentially spamming the customer twice. With steps, Inngest remembers "send-email already succeeded" and won't repeat it.

### 7. Send the event when an invoice is created

Open `src/app/dashboard/invoices/actions.ts` from Part 13. After the `db.transaction` block completes successfully (so we only send the event once the invoice AND its journal entry are safely committed), send the event:

```ts
import { inngest } from "@/lib/inngest/client";

// ...inside createInvoice, after the db.transaction(...) call completes:

await inngest.send({
  name: "invoice/created",
  data: { invoiceId: /* the invoice id from inside the transaction */, orgId },
});
```

Important detail: capture the created invoice's id from inside the transaction (assign it to a variable declared outside the transaction callback, or return it from the transaction) so it's available here, after the transaction has committed. Sending the event AFTER the transaction succeeds — not inside it — matters: if we sent the event from inside the transaction and the transaction later rolled back (e.g., an unbalanced entry, per Part 13's test), we'd have sent an email event for an invoice that doesn't actually exist. Always trigger events for side effects only after you're certain the underlying data really was saved.

### 8. Run Inngest's local dev server

Inngest provides a local dev server that discovers your functions and lets you trigger/watch them during development. In a new terminal tab (keep `npm run dev` running in another):

```
npx inngest-cli@latest dev
```

This starts a dashboard, usually at http://localhost:8288. Open it in your browser — this is Inngest's local control panel, showing every function it's discovered and every event that's been sent, entirely on your machine, no cloud account interaction needed for this local view.

### 9. Test it

With both `npm run dev` and `npx inngest-cli@latest dev` running, create a new invoice through your app as usual (`/dashboard/invoices/new`). Then check:
1. Your Next.js terminal — you should see the `[EMAIL] To: ...` console.log output appear a moment after the invoice was created (not instantly within the same request — it happened asynchronously).
2. The Inngest dev dashboard at localhost:8288 — you should see the `invoice/created` event listed, and the `send-invoice-email` function run shown as succeeded, with both of its steps (`fetch-invoice`, `send-email`) visible individually.

Click into a function run in the dashboard — you can see exactly how long each step took, and if anything fails, you'd see the error and retry attempts right there. This visibility is a big part of why Inngest is nicer to work with than hand-rolling your own background job queue.

### 10. Commit your progress

```
git add .
git commit -m "Add Inngest, send invoice/created event, background email function with steps"
```

---

### Checkpoint — confirm before moving on

- [ ] `inngest` package installed, client created, API route registered
- [ ] `sendInvoiceEmail` function created using `step.run` for its two stages
- [ ] `createInvoice` sends the `invoice/created` event only after its transaction has committed successfully
- [ ] Running `npx inngest-cli@latest dev` shows your function and lets you watch it execute
- [ ] Creating an invoice triggers the background email log, visible in both your terminal and the Inngest dashboard
- [ ] You can explain, in your own words, why `step.run` matters for retry-safety, and why we send the event after the transaction rather than inside it

---

### Troubleshooting

**Creating an invoice works fine, but nothing appears in the Inngest dev dashboard**
Confirm `npx inngest-cli@latest dev` is actually still running in its own terminal tab (it's easy to accidentally close that terminal while working in another one). Also confirm your Next.js dev server (`npm run dev`) is running — Inngest's dev server needs to be able to reach your app's `/api/inngest` route to discover functions.

**Inngest dashboard shows the function but it never runs / stays "Queued" forever**
This usually means the event was never actually sent. Double check `await inngest.send({ name: "invoice/created", data: {...} })` is present in your invoice Server Action, AFTER the `db.transaction` block completes, not accidentally deleted or commented out.

**Error: "sendInvoiceEmail is not defined" in the route.ts file**
Confirm the import path in `src/app/api/inngest/route.ts` exactly matches where you created the function file: `@/lib/inngest/functions/send-invoice-email`, and that the function is exported with the exact name `sendInvoiceEmail` (case-sensitive) in that file.

**The email log appears TWICE in your terminal for one invoice**
This can happen if Inngest retried the function because an earlier attempt appeared to fail (check the Inngest dashboard's function run details for an error on the first attempt) — or, more commonly during development, if you have two Next.js dev servers accidentally running at once (check for multiple terminal tabs both running `npm run dev`, and stop the extra one).

**TypeScript error around `event.data` having property `invoiceId` doesn't exist**
Inngest's TypeScript types for event data are permissive by default in this simple setup — if you see a strict typing error, you can add an explicit type assertion like `const { invoiceId } = event.data as { invoiceId: string };` as a pragmatic fix, though a fuller setup would define shared event types across your app (a good improvement for later, not required now).

**"Cannot find module 'inngest/next'" when importing serve**
Confirm `npm install inngest` completed successfully — check your `package.json`'s dependencies list for an `"inngest"` entry. If it's missing, re-run the install command.

**Invoice creation now feels slower than before you added Inngest**
It shouldn't be — `inngest.send()` is a fire-and-forget style call that returns almost instantly; the actual email-sending work happens asynchronously in a separate function run. If you're seeing a real slowdown, confirm you didn't accidentally `await` something inside the Inngest function call chain that blocks the request — the whole point of this pattern is that the user's request finishes immediately while Inngest handles the rest independently.

**The Inngest dev dashboard at localhost:8288 won't load in the browser**
Confirm the `npx inngest-cli@latest dev` command is still running and didn't error out — check its terminal output for a message like "Dev server ready" and a URL. If port 8288 is already in use by something else, the CLI will usually pick a different port and print it — check the actual terminal output rather than assuming 8288.

---

### What's next
Part 20: Scheduled Jobs / Cron — we'll teach Inngest to run functions on a timer rather than in response to an event, building an overdue invoice reminder job that runs daily and a simple recurring-invoice generator, tying directly back into the AR aging logic from Part 18.
