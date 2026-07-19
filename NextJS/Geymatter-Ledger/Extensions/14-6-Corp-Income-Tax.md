# Part 14.6: Corporate Income Tax / ACRA Filing Prep

A US-focused course might prepare figures for a Schedule C or 1099 form. For Singapore, the locally-relevant equivalent is preparing an internal estimate of **chargeable income** for Corporate Income Tax purposes, and surfacing the basic figures **ACRA** (Accounting and Corporate Regulatory Authority) annual return filings require. Every Singapore-incorporated company must file both, every year — this part builds a report that extends Part 9's Profit & Loss with the specific adjustments a tax computation needs.

## Step 14.6.1 — Understanding the Gap Between Accounting Profit and Chargeable Income

### The Target
Before writing code, understand why "Net Income" from the P&L report (Part 9) is *not* the same number IRAS taxes.

### The Concept
Recall Part 9's Profit & Loss: Net Income = Total Revenue − Total Expenses, computed strictly from what your Chart of Accounts says happened. But tax law doesn't always agree with accounting on what counts. Two categories of difference matter most for a simplified model like this course's:

- **Non-deductible expenses** — real business spending that accounting correctly counts as an expense, but which IRAS does not allow you to deduct when computing tax (e.g., certain entertainment expenses, fines and penalties, private car expenses). These get *added back* to accounting profit to arrive at chargeable income — the business spent the money, but can't use it to reduce tax.
- **Capital allowances** — the tax system's own version of depreciation, letting a business deduct the cost of qualifying equipment over time, following IRAS's own prescribed schedules rather than whatever depreciation method (if any) your own books use. This course does not model actual depreciation at all (no depreciation schedule was built in any earlier part), so this figure is left as a manually-entered adjustment rather than computed — an honest, explicit limitation rather than a fabricated calculation.

The point of this feature, precisely scoped: **surface accounting Net Income, let the user enter known adjustments, and compute an estimated chargeable income and illustrative tax** — never a substitute for a real tax computation, exactly the same disclaimer given for Part 10's GST F5 report.

## Step 14.6.2 — Designing the Adjustments Schema

### The Target
A small table to record ad-hoc tax adjustments per fiscal year, since these are judgment calls a business/accountant makes manually, not something derivable from the ledger.

### The Implementation

**`src/db/schema.ts`** (new addition)
```typescript
export const taxAdjustmentTypeEnum = pgEnum("tax_adjustment_type", [
  "add_back_non_deductible", // increases chargeable income
  "capital_allowance", // decreases chargeable income
  "other_deduction", // decreases chargeable income
]);

export const taxAdjustments = pgTable("tax_adjustments", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  fiscalYearStart: date("fiscal_year_start").notNull(),
  fiscalYearEnd: date("fiscal_year_end").notNull(),

  adjustmentType: taxAdjustmentTypeEnum("adjustment_type").notNull(),
  description: text("description").notNull(),
  amount: numeric("amount", { precision: 14, scale: 2 }).notNull(),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

### The Verification

```bash
npm run db:generate
npm run db:migrate
```

Confirm `tax_adjustments` appears in Drizzle Studio, along with the new `tax_adjustment_type` enum.

---

## Step 14.6.3 — Computing the Estimate

### The Target
A function combining Part 9's P&L aggregation with the manually-entered adjustments to produce an estimated chargeable income and illustrative tax figure.

### The Concept
Notice the pattern one more time: this report, like every other one in this course, doesn't invent new aggregation logic — it reuses `getAccountBalancesForRange` from Part 9 for the accounting Net Income starting point, then layers a small, explicit adjustment step on top. Singapore's actual corporate tax rate is a flat 17% with partial exemptions on the first tranche of income — this course models the flat 17% rate only, explicitly excluding the partial exemption scheme's tiered calculation, since it changes periodically and (like GST F5's real complexity) belongs in a real tax advisor's hands, not hardcoded into a learning project.

### The Implementation

**`src/lib/tax.ts`**
```typescript
import { db } from "@/db";
import { taxAdjustments } from "@/db/schema";
import { eq, and } from "drizzle-orm";
import { getAccountBalancesForRange } from "@/lib/reports";

export type TaxEstimate = {
  fiscalYearStart: string;
  fiscalYearEnd: string;
  accountingNetIncome: number;
  totalAddBacks: number;
  totalDeductions: number;
  estimatedChargeableIncome: number;
  illustrativeTaxAt17Percent: number;
  adjustments: {
    id: string;
    adjustmentType: string;
    description: string;
    amount: number;
  }[];
};

const CORPORATE_TAX_RATE = 0.17; // Singapore's flat headline rate, simplified —
// this deliberately excludes the partial tax exemption scheme's tiered
// calculation on the first $200,000 (approx.) of chargeable income, since
// that scheme's exact thresholds are set by IRAS and subject to change —
// exactly the same "internal estimate, not a real filing" scope as
// Part 10's GST F5 report.

export async function getTaxEstimate(
  organizationId: string,
  fiscalYearStart: string,
  fiscalYearEnd: string
): Promise<TaxEstimate> {
  const balances = await getAccountBalancesForRange(
    organizationId,
    fiscalYearStart,
    fiscalYearEnd
  );

  const totalRevenue = balances
    .filter((b) => b.accountType === "revenue")
    .reduce((sum, a) => sum + a.balance, 0);
  const totalExpenses = balances
    .filter((b) => b.accountType === "expense")
    .reduce((sum, a) => sum + a.balance, 0);

  const accountingNetIncome = totalRevenue - totalExpenses;

  const adjustments = await db
    .select()
    .from(taxAdjustments)
    .where(
      and(
        eq(taxAdjustments.organizationId, organizationId),
        eq(taxAdjustments.fiscalYearStart, fiscalYearStart),
        eq(taxAdjustments.fiscalYearEnd, fiscalYearEnd)
      )
    );

  const totalAddBacks = adjustments
    .filter((a) => a.adjustmentType === "add_back_non_deductible")
    .reduce((sum, a) => sum + Number(a.amount), 0);

  const totalDeductions = adjustments
    .filter((a) => a.adjustmentType === "capital_allowance" || a.adjustmentType === "other_deduction")
    .reduce((sum, a) => sum + Number(a.amount), 0);

  const estimatedChargeableIncome = Math.max(
    0,
    accountingNetIncome + totalAddBacks - totalDeductions
  );

  return {
    fiscalYearStart,
    fiscalYearEnd,
    accountingNetIncome,
    totalAddBacks,
    totalDeductions,
    estimatedChargeableIncome,
    illustrativeTaxAt17Percent: estimatedChargeableIncome * CORPORATE_TAX_RATE,
    adjustments: adjustments.map((a) => ({
      id: a.id,
      adjustmentType: a.adjustmentType,
      description: a.description,
      amount: Number(a.amount),
    })),
  };
}

export async function addTaxAdjustment(input: {
  fiscalYearStart: string;
  fiscalYearEnd: string;
  adjustmentType: "add_back_non_deductible" | "capital_allowance" | "other_deduction";
  description: string;
  amount: number;
}) {
  const { getOrCreateOrganization } = await import("@/lib/organizations");
  const { requireAdminRole } = await import("@/lib/permissions");
  await requireAdminRole("add a tax adjustment");

  const organizationId = await getOrCreateOrganization();

  await db.insert(taxAdjustments).values({
    organizationId,
    fiscalYearStart: input.fiscalYearStart,
    fiscalYearEnd: input.fiscalYearEnd,
    adjustmentType: input.adjustmentType,
    description: input.description,
    amount: input.amount.toFixed(2),
  });
}
```

### The Verification

No visible output yet — verified alongside the report page.

---

## Step 14.6.4 — The Tax Estimate Report Page

### The Target
Build `/reports/tax-estimate`, showing accounting Net Income, listed adjustments, estimated chargeable income, and an illustrative tax figure — with the same explicit non-filing disclaimer used in Part 10.

### The Implementation

**`src/app/reports/tax-estimate/page.tsx`**
```tsx
import { getOrCreateOrganization } from "@/lib/organizations";
import { getTaxEstimate, addTaxAdjustment } from "@/lib/tax";
import { isCurrentUserAdmin } from "@/lib/permissions";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";
import { ReportsNav } from "@/components/reports-nav";

function firstDayOfCurrentYear() {
  const now = new Date();
  return new Date(now.getFullYear(), 0, 1).toISOString().split("T")[0];
}
function lastDayOfCurrentYear() {
  const now = new Date();
  return new Date(now.getFullYear(), 11, 31).toISOString().split("T")[0];
}

export default async function TaxEstimatePage({
  searchParams,
}: {
  searchParams: Promise<{ start?: string; end?: string }>;
}) {
  const { start, end } = await searchParams;
  const fiscalYearStart = start ?? firstDayOfCurrentYear();
  const fiscalYearEnd = end ?? lastDayOfCurrentYear();

  const organizationId = await getOrCreateOrganization();
  const [estimate, isAdmin] = await Promise.all([
    getTaxEstimate(organizationId, fiscalYearStart, fiscalYearEnd),
    isCurrentUserAdmin(),
  ]);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-2xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Tax Estimate</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <div className="mt-4">
          <ReportsNav />
        </div>

        <form className="mt-4 flex items-end gap-3 rounded-lg border border-gray-200 bg-white p-4">
          <div>
            <label className="block text-xs text-gray-600">Fiscal Year Start</label>
            <input type="date" name="start" defaultValue={fiscalYearStart} className="mt-1 rounded border border-gray-300 px-2 py-1 text-sm" />
          </div>
          <div>
            <label className="block text-xs text-gray-600">Fiscal Year End</label>
            <input type="date" name="end" defaultValue={fiscalYearEnd} className="mt-1 rounded border border-gray-300 px-2 py-1 text-sm" />
          </div>
          <button className="rounded bg-blue-600 px-3 py-1.5 text-sm text-white">Update</button>
        </form>

        <div className="mt-6 rounded-lg border border-gray-200 bg-white p-6">
          <p className="text-sm text-gray-500">
            Fiscal Year: {estimate.fiscalYearStart} to {estimate.fiscalYearEnd}
          </p>

          <table className="mt-4 w-full text-left text-sm">
            <tbody>
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">Accounting Net Income (from P&amp;L)</td>
                <td className="py-1.5 text-right text-gray-900">
                  ${estimate.accountingNetIncome.toFixed(2)}
                </td>
              </tr>
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">Add: Non-deductible expenses</td>
                <td className="py-1.5 text-right text-gray-900">
                  +${estimate.totalAddBacks.toFixed(2)}
                </td>
              </tr>
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">Less: Capital allowances &amp; other deductions</td>
                <td className="py-1.5 text-right text-gray-900">
                  −${estimate.totalDeductions.toFixed(2)}
                </td>
              </tr>
              <tr className="border-t border-gray-300 font-semibold">
                <td className="py-1.5">Estimated Chargeable Income</td>
                <td className="py-1.5 text-right">${estimate.estimatedChargeableIncome.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>

          <div className="mt-6 flex justify-between border-t-2 border-gray-800 pt-3 text-lg font-bold">
            <span>Illustrative Tax (flat 17%)</span>
            <span className="text-red-700">${estimate.illustrativeTaxAt17Percent.toFixed(2)}</span>
          </div>

          <h3 className="mt-6 text-sm font-semibold text-gray-800">Adjustments on record</h3>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              {estimate.adjustments.length === 0 && (
                <tr><td className="py-2 text-gray-400">No adjustments entered for this fiscal year.</td></tr>
              )}
              {estimate.adjustments.map((a) => (
                <tr key={a.id} className="border-t border-gray-100">
                  <td className="py-1.5 text-gray-700">{a.description}</td>
                  <td className="py-1.5 text-gray-500">{a.adjustmentType.replace(/_/g, " ")}</td>
                  <td className="py-1.5 text-right">${a.amount.toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {isAdmin && (
            <form
              action={async (formData: FormData) => {
                "use server";
                await addTaxAdjustment({
                  fiscalYearStart,
                  fiscalYearEnd,
                  adjustmentType: formData.get("adjustmentType") as any,
                  description: formData.get("description") as string,
                  amount: parseFloat(formData.get("amount") as string),
                });
              }}
              className="mt-4 flex gap-2 text-sm"
            >
              <select name="adjustmentType" className="rounded border border-gray-300 px-2 py-1">
                <option value="add_back_non_deductible">Add-back (non-deductible)</option>
                <option value="capital_allowance">Capital allowance</option>
                <option value="other_deduction">Other deduction</option>
              </select>
              <input name="description" placeholder="Description" required className="flex-1 rounded border border-gray-300 px-2 py-1" />
              <input name="amount" type="number" step="0.01" placeholder="Amount" required className="w-32 rounded border border-gray-300 px-2 py-1" />
              <button className="rounded bg-blue-600 px-3 py-1 text-white">Add</button>
            </form>
          )}

          <p className="mt-6 text-xs text-gray-400">
            This is a simplified educational estimate only — it excludes IRAS&apos;s
            partial tax exemption scheme, capital allowance schedules, loss
            carry-forwards, and other real corporate tax rules, and is not a
            substitute for a qualified tax advisor or an actual ACRA/IRAS filing.
          </p>
        </div>
      </div>
    </div>
  );
}
```

Update `ReportsNav` (Part 9/10) with one more link:

```tsx
<Link href="/reports/tax-estimate" className="text-blue-600 hover:underline">
  Tax Estimate
</Link>
```

Add `/reports/tax-estimate` — already covered by the existing `/reports(.*)` matcher in `proxy.ts`, no change needed there.

### The Verification

Visit `/reports/tax-estimate`. Confirm it defaults to the current calendar year and shows Accounting Net Income matching the same-period figure on `/reports/profit-and-loss` — cross-check this explicitly, the same discipline used in Part 10.

As admin, add one adjustment: type "Add-back (non-deductible)," description "Client entertainment," amount $500. Confirm Estimated Chargeable Income increases by exactly $500, and the illustrative tax figure increases by $85.00 (17% of $500). Add a second adjustment: "Capital allowance," description "Laptop purchase," amount $1,200 — confirm chargeable income decreases correspondingly.

As a member-role account, confirm the "Add" adjustment form is absent, but the report itself (read-only) remains fully visible.
