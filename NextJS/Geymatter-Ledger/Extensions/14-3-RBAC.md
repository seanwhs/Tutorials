# Part 14.3: Role-Based Permissions

Right now, every member of a Clerk Organization has identical, unrestricted access to everything in Greymatter Ledger — any team member can create invoices, post bank transactions, or (as of Part 14.2) void a journal entry going back months. A real business usually wants tiers: a bookkeeper who can enter data but shouldn't be able to erase history, an owner who can do anything, and perhaps a read-only external accountant. This part builds that, reusing infrastructure you already have — Clerk Organizations, wired in back in Part 2 — rather than inventing a new permissions system from scratch.

## Step 14.3.1 — Understanding Clerk's Role Model

### The Target
Before writing code, understand what Clerk already gives you for free, and decide which actions in Greymatter Ledger deserve restricting.

### The Concept
Recall the apartment-building-floors analogy from Part 1: a Clerk Organization is like a building, and a member's role is like the *type* of keycard they hold — not which floor they're on (that's `orgId`, already enforced everywhere since Part 3), but what they're allowed to *do* once they're on that floor. Clerk Organizations ship with two built-in roles out of the box: **`admin`** (the organization's creator, and anyone else promoted) and **`member`** (everyone else invited in). You can also define custom roles in Clerk's dashboard, but for this course, the built-in admin/member split is exactly enough.

The design question isn't "how do we implement roles" — Clerk already did that. The real design question is: **which actions in this app should be admin-only?** Looking back across Parts 6–14.2, one category stands out clearly: anything that reverses or erases the historical record. Creating an invoice, recording a payment, uploading a bank CSV — these are routine, low-risk, day-to-day bookkeeping actions any team member should be able to do. **Voiding** anything (Part 14.2) is fundamentally different — it rewrites what the books say happened, and should require elevated trust. Deactivating a Chart of Accounts entry is a similar, if lower-stakes, category. We'll draw the line at exactly that boundary.

### The Implementation

No code yet — first, configure Clerk itself:

1. In your Clerk dashboard, navigate to **Organizations Settings** → **Roles**.
2. Confirm the two default roles, `Admin` and `Member`, are present (they are, by default, once Organizations was enabled back in Part 2.8).
3. For every organization you've created during this course (e.g., "Acme Test Co"), confirm your own account holds the `Admin` role — it should, automatically, since Clerk makes the creator of an organization its first admin.
4. Invite a second test user (or use a second browser/incognito session with a second real account) to one of your test organizations, and confirm they land with the `Member` role by default.

### The Verification

In the Clerk dashboard, under your test organization's **Members** tab, confirm you can see a role column showing `Admin` next to your own account. This is purely a dashboard confirmation step — no app code has been touched yet.

---

## Step 14.3.2 — A Shared Permission-Checking Helper

### The Target
Write one function, `requireOrgRole`, that every sensitive server action will call — mirroring exactly how `postJournalEntry` became the single choke point for balance enforcement back in Part 6.

### The Concept
We don't want twelve different server actions each independently reading `auth().orgRole` and comparing it against a string — that's exactly the kind of duplicated, easy-to-typo logic Part 6 taught us to centralize. One shared helper, thrown from one place, checked everywhere.

### The Implementation

**`src/lib/permissions.ts`**
```typescript
import { auth } from "@clerk/nextjs/server";

// Clerk represents organization roles as strings like "org:admin" or
// "org:member" (the "org:" prefix distinguishes organization-level roles
// from any other role system Clerk might support). We centralize the
// exact string here, once, so a future Clerk SDK change only requires
// updating this one constant, not every call site across the app.
const ADMIN_ROLE = "org:admin";

/**
 * Throws if the currently signed-in user is not an admin of the active
 * organization. Every sensitive server action (voiding, deactivating an
 * account) calls this FIRST, before doing any real work — the same
 * "fail fast, fail loud" discipline postJournalEntry uses for balance
 * checks in Part 6.
 */
export async function requireAdminRole(actionDescription: string) {
  const { orgRole } = await auth();

  if (orgRole !== ADMIN_ROLE) {
    throw new Error(
      `Only an organization admin can ${actionDescription}. Your current role does not have permission for this action.`
    );
  }
}

/**
 * A non-throwing version, for use in page components to conditionally
 * show/hide UI (e.g., hiding a Void button entirely for a non-admin,
 * rather than showing it and letting them click into an error).
 */
export async function isCurrentUserAdmin(): Promise<boolean> {
  const { orgRole } = await auth();
  return orgRole === ADMIN_ROLE;
}
```

### The Verification

No visible output yet — this is a building block. We'll verify it end-to-end once wired into a real action in the next step.

---

## Step 14.3.3 — Guarding Voiding Operations (Admin-Only)

### The Target
Require admin role before any of Part 14.2's void functions — `voidInvoice`, `voidBill`, `voidPayment` — are allowed to run.

### The Concept
This is the highest-value guard in the entire feature, since voiding is precisely the category of action Step 14.3.1 identified as deserving elevated trust. Note where the check goes: **first**, before any database read or write — matching the same "validate before you touch anything" ordering used throughout this course (Part 6's guards, Part 7's account-ownership check).

### The Implementation

**`src/lib/actions/invoices.ts`** (update `voidInvoice` — add the permission check as its very first line)
```typescript
import { requireAdminRole } from "@/lib/permissions";

export async function voidInvoice(invoiceId: string, reason: string) {
  await requireAdminRole("void an invoice");

  const organizationId = await getOrCreateOrganization();

  const invoice = await db.query.invoices.findFirst({
    where: (invoices, { and, eq }) =>
      and(eq(invoices.id, invoiceId), eq(invoices.organizationId, organizationId)),
  });

  if (!invoice) throw new Error("Invoice not found for this organization.");
  if (invoice.status === "void") throw new Error("This invoice has already been voided.");
  if (Number(invoice.amountPaid) > 0) {
    throw new Error(
      "Cannot void an invoice that still has payments recorded against it. Void each payment individually first, then void the invoice."
    );
  }
  if (!invoice.journalEntryId) {
    throw new Error("This invoice has no associated journal entry to reverse.");
  }

  await dbTransactional.transaction(async (tx) => {
    await voidJournalEntry(organizationId, invoice.journalEntryId!, reason, tx);

    await tx
      .update(invoices)
      .set({ status: "void" })
      .where(eq(invoices.id, invoiceId));
  });

  revalidatePath("/invoices");
  revalidatePath(`/invoices/${invoiceId}`);
}
```

Apply the identical one-line addition — `await requireAdminRole("void a bill");` and `await requireAdminRole("void a payment");` as the very first line — to `voidBill` (`src/lib/actions/bills.ts`) and `voidPayment` (`src/lib/actions/payments.ts`) respectively. No other logic in either function changes.

### The Verification

Using your **admin** test account (the organization's creator), void a fresh test invoice exactly as in Part 14.2 — confirm it still succeeds normally.

Now, using your **second, member-role** test account (from Step 14.3.1), sign in, switch to the same organization, and attempt to void a different test invoice. Confirm the action throws: `"Only an organization admin can void an invoice. Your current role does not have permission for this action."` Confirm in Drizzle Studio that **nothing** changed — no reversal entry, no `isVoided` flag flipped — proving the guard runs before any write, not partway through.

---

## Step 14.3.4 — Guarding Chart of Accounts Deactivation

### The Target
Extend the same guard to a second, lower-stakes but still meaningful action: deactivating an account in the Chart of Accounts.

### The Concept
Recall Part 5 — accounts use `isActive` rather than real deletion, but flipping that flag still has real consequences (it disappears from every dropdown used to create new invoices, bills, and journal lines going forward). This wasn't gated by anything in the original course — any signed-in member could quietly deactivate "Cash" itself. Worth closing this while we're building the permission layer, using the exact same one-line pattern.

### The Implementation

Recall from Part 5 that `/accounts` was a read-only viewing page with no deactivate action ever built. We'll add one now, gated correctly from the start rather than as an afterthought.

**`src/lib/actions/accounts.ts`** (new file)
```typescript
"use server";

import { db } from "@/db";
import { accounts } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { requireAdminRole } from "@/lib/permissions";
import { eq, and } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export async function deactivateAccount(accountId: string) {
  await requireAdminRole("deactivate a Chart of Accounts entry");

  const organizationId = await getOrCreateOrganization();

  const account = await db.query.accounts.findFirst({
    where: (accounts, { and, eq }) =>
      and(eq(accounts.id, accountId), eq(accounts.organizationId, organizationId)),
  });

  if (!account) {
    throw new Error("Account not found for this organization.");
  }
  if (!account.isActive) {
    throw new Error("This account is already inactive.");
  }

  await db
    .update(accounts)
    .set({ isActive: false })
    .where(and(eq(accounts.id, accountId), eq(accounts.organizationId, organizationId)));

  revalidatePath("/accounts");
}
```

Add a deactivate control to the accounts page, visible only to admins:

**`src/app/accounts/page.tsx`** (add near the top of the file, and inside the table row rendering)
```tsx
import { deactivateAccount } from "@/lib/actions/accounts";
import { isCurrentUserAdmin } from "@/lib/permissions";

// ...inside the component, near the top:
const isAdmin = await isCurrentUserAdmin();

// ...inside the table row rendering, add a new column/cell:
<td className="px-4 py-2 text-right">
  {isAdmin && account.isActive && (
    <form
      action={async () => {
        "use server";
        await deactivateAccount(account.id);
      }}
    >
      <button className="text-xs text-red-600 hover:underline">
        Deactivate
      </button>
    </form>
  )}
</td>
```

Add a matching empty `<th></th>` to the table header row for this new column.

### The Verification

As an admin, visit `/accounts` and confirm a "Deactivate" link now appears in each active account's row. Deactivate a low-stakes test account (e.g., "Software & Subscriptions Expense," assuming no journal lines reference it yet — deactivating one that already has history is still allowed, matching Part 5's original soft-delete design; only real deletion was ever prevented). Confirm its status badge flips to "Inactive."

As a member-role user, visit `/accounts` and confirm the "Deactivate" link is **entirely absent** from every row — not merely disabled, genuinely not rendered — since `isAdmin` gates the whole block server-side before any HTML reaches the browser.

---

## Step 14.3.5 — Reflecting Role in the UI Elsewhere (Voiding Buttons)

### The Target
Hide the `<VoidButton />` entirely for non-admins across invoices, bills, and payments, rather than showing it and letting a member click into a thrown error.

### The Concept
The server-side guard from Step 14.3.3 is the real security boundary — it can never be bypassed, even if someone tampers with the client. But showing a button that will always fail for a given user is poor design; we additionally hide it client-side for a cleaner experience. This is a `UX improvement layered on top of real security`, not a replacement for it — an important distinction worth internalizing, since it's a common point of confusion for beginners building their first permissions system.

### The Implementation

**`src/app/invoices/[id]/page.tsx`** (update)
```tsx
import { isCurrentUserAdmin } from "@/lib/permissions";

// ...inside the component:
const isAdmin = await isCurrentUserAdmin();

// ...replace the existing conditional void button render:
{isAdmin && invoice.status !== "void" && Number(invoice.amountPaid) === 0 && (
  <VoidButton onVoid={(reason) => voidInvoice(invoice.id, reason)} />
)}
```

Update `<PaymentHistory />` to accept and respect the same flag:

**`src/components/payment-history.tsx`** (updated)
```tsx
"use client";

import { VoidButton } from "@/components/void-button";
import { voidPayment } from "@/lib/actions/payments";

type Payment = {
  id: string;
  amount: string;
  paymentDate: string;
  method: string;
  isVoided: boolean;
};

export function PaymentHistory({
  payments,
  isAdmin,
}: {
  payments: Payment[];
  isAdmin: boolean;
}) {
  if (payments.length === 0) return null;

  return (
    <div className="mt-6 rounded-lg border border-gray-200 bg-gray-50 p-4">
      <h3 className="text-sm font-semibold text-gray-800">Payment History</h3>
      <table className="mt-2 w-full text-left text-sm">
        <tbody>
          {payments.map((p) => (
            <tr key={p.id} className="border-t border-gray-200">
              <td className="py-1.5 text-gray-700">{p.paymentDate}</td>
              <td className="py-1.5 text-gray-700">${p.amount}</td>
              <td className="py-1.5 text-gray-500">{p.method}</td>
              <td className="py-1.5">
                {p.isVoided ? (
                  <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-400">
                    Voided
                  </span>
                ) : isAdmin ? (
                  <VoidButton onVoid={(reason) => voidPayment(p.id, reason)} />
                ) : null}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

Update the call site: `<PaymentHistory payments={invoice.payments} isAdmin={isAdmin} />`. Apply the identical pattern to `src/app/bills/[id]/page.tsx`.

### The Verification

As a member-role user, visit an invoice detail page with an existing payment. Confirm the payment history table renders (read access is fine for members — only the *void* action is restricted), but shows no void link in any row, and the invoice-level void button is absent entirely. As an admin, confirm both remain fully visible and functional, exactly as before this part.

---

## ✅ Checkpoint — Part 14.3

- [x] Confirmed Clerk's built-in Admin/Member roles are active on every test organization
- [x] `requireAdminRole` / `isCurrentUserAdmin` — one shared, centralized permission check
- [x] `voidInvoice`, `voidBill`, `voidPayment` all gated admin-only, checked as the very first line before any read or write
- [x] Chart of Accounts deactivation built out (previously missing entirely) and gated admin-only from day one
- [x] UI elements hidden for non-admins as a UX layer, explicitly distinct from — and never a substitute for — the server-side enforcement
- [x] Verified: a member-role account is correctly blocked at the server level even if UI elements were somehow bypassed, and sees no error-inducing controls in normal use

## 📚 Reference Note

**Why check `orgRole` inside the server action itself, rather than only in `src/proxy.ts`?** Recall Part 2: `proxy.ts` answers one question — "is anyone logged in, and do they have an active organization?" It deliberately does not know about fine-grained, per-action permissions, since that would require it to understand every route's specific business logic, defeating its purpose as a lightweight, generic gatekeeper. Fine-grained checks belong exactly where the sensitive action itself lives — the same "don't trust the caller, check right where it matters" principle from Part 6's account-ownership guard inside `postJournalEntry`.
