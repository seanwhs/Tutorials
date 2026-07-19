# Part 14.5: CPF Contributions (In Place of Payroll)

A US-focused course would build payroll around federal/state withholding forms. For a Singapore-context business like Greymatter Ledger, the locally-relevant equivalent is **CPF (Central Provident Fund)** — Singapore's mandatory retirement savings scheme, where both employer and employee contribute a percentage of wages, at rates that vary by the employee's age band. This part builds a simplified CPF-aware pay run feature that posts correctly into the existing journal engine.

## Step 14.5.1 — Understanding CPF, In Plain English

### The Target
Before writing code, understand the actual mechanics of a CPF-aware pay run.

### The Concept
When a Singapore employer pays an employee, two separate contributions get set aside on top of (and out of) that wage: the **employee's own share**, withheld from their pay and forwarded to their CPF account, and the **employer's own additional share**, paid entirely by the employer on top of the wage, not deducted from it. Both shares get paid into the same government-administered CPF Board account — from the business's perspective, both are amounts owed to a single external body until actually remitted.

Concretely, for a $3,000 monthly wage with simplified illustrative rates (20% employee, 17% employer — this course uses simplified flat rates rather than IRAS's real age-banded tables, which change periodically and require official reference, not a hardcoded course value):

- Employee's take-home pay: $3,000 − $600 (employee CPF) = $2,400 actually paid out as cash.
- Employer's total cost: $3,000 (wage) + $510 (employer CPF) = $3,510.
- Total CPF owed to the CPF Board: $600 + $510 = $1,110.

This maps directly onto the debit/credit vocabulary from Part 4: Salary Expense and Employer CPF Expense both increase (debits); Cash decreases by the net pay amount, and CPF Payable increases by the total contribution (credits).

## Step 14.5.2 — Extending the Chart of Accounts

### The Target
Add two new default accounts: a Liability (`CPF Payable`) and an Expense (`Employer CPF Contribution Expense`).

### The Implementation

**`src/lib/seed-accounts.ts`** (add two entries to `DEFAULT_CHART_OF_ACCOUNTS`)
```typescript
const DEFAULT_CHART_OF_ACCOUNTS = [
  // ...existing 15 accounts from Part 5 remain unchanged...
  { code: "2300", name: "CPF Payable", accountType: "liability", normalBalance: "credit", subtype: "cpf_payable" },
  { code: "5500", name: "Employer CPF Contribution Expense", accountType: "expense", normalBalance: "debit", subtype: "operating_expense" },
] as const;
```

New organizations will seed these automatically. For any existing test organization, use the same backfill pattern from Part 5, Step 5.6 — temporarily call `seedDefaultChartOfAccounts` again isn't sufficient (it exits early once *any* accounts exist), so instead insert these two rows directly via a one-off script or Drizzle Studio for existing test orgs.

### The Verification

For a brand-new test organization, visit `/accounts` and confirm `2300 CPF Payable` and `5500 Employer CPF Contribution Expense` both appear in their respective sections.

---

## Step 14.5.3 — Designing the `employees` and `pay_runs` Tables

### The Target
A minimal employee roster, and a pay run record mirroring the invoice/bill header-plus-posting pattern already established.

### The Implementation

**`src/db/schema.ts`** (new additions)
```typescript
export const employees = pgTable("employees", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  name: text("name").notNull(),
  monthlyWage: numeric("monthly_wage", { precision: 14, scale: 2 }).notNull(),

  // Simplified, single flat rate per employee rather than IRAS's real
  // age-banded percentage tables — this course models the MECHANISM of
  // CPF posting correctly, not the exact current statutory rates, which
  // change periodically and should be sourced from IRAS/CPF Board
  // directly in a real payroll product (same disclaimer as Part 10's GST
  // F5 report).
  employeeCpfRate: numeric("employee_cpf_rate", { precision: 5, scale: 2 }).notNull().default("20.00"),
  employerCpfRate: numeric("employer_cpf_rate", { precision: 5, scale: 2 }).notNull().default("17.00"),

  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const payRuns = pgTable("pay_runs", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  employeeId: uuid("employee_id")
    .notNull()
    .references(() => employees.id, { onDelete: "restrict" }),

  payDate: date("pay_date").notNull(),

  grossWage: numeric("gross_wage", { precision: 14, scale: 2 }).notNull(),
  employeeCpfAmount: numeric("employee_cpf_amount", { precision: 14, scale: 2 }).notNull(),
  employerCpfAmount: numeric("employer_cpf_amount", { precision: 14, scale: 2 }).notNull(),
  netPay: numeric("net_pay", { precision: 14, scale: 2 }).notNull(),

  journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id, {
    onDelete: "set null",
  }),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const payRunsRelations = relations(payRuns, ({ one }) => ({
  employee: one(employees, {
    fields: [payRuns.employeeId],
    references: [employees.id],
  }),
}));
```

### The Verification

```bash
npm run db:generate
npm run db:migrate
```

Confirm `employees` and `pay_runs` appear in Drizzle Studio.

---

## Step 14.5.4 — The Pay Run Server Action

### The Target
`runPayroll(employeeId, payDate)` — computes CPF, posts the correct four-line journal entry, all atomically.

### The Concept
Recall Step 14.5.1's math. The journal shape:

```
Debit  Salary Expense (new, or reuse an operating_expense line)  = grossWage
Debit  Employer CPF Contribution Expense (5500)                  = employerCpfAmount
Credit Cash (1000)                                                = netPay (grossWage − employeeCpf)
Credit CPF Payable (2300)                                         = employeeCpfAmount + employerCpfAmount
```

This is structurally identical to `createBill`'s multi-debit-line-against-one-credit shape from Part 8 — the engine handles it without any change at all, exactly as Part 14 predicted.

### The Implementation

Add a Salary Expense account to the seed list too, since it wasn't part of Part 5's original 15:

**`src/lib/seed-accounts.ts`** (add one more entry)
```typescript
{ code: "5600", name: "Salary Expense", accountType: "expense", normalBalance: "debit", subtype: "operating_expense" },
```

**`src/lib/actions/payroll.ts`**
```typescript
"use server";

import { dbTransactional, db } from "@/db";
import { payRuns, accounts, employees } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { postJournalEntry } from "@/lib/journal";
import { requireAdminRole } from "@/lib/permissions";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export async function runPayroll(employeeId: string, payDate: string) {
  // Payroll touches real wages and CPF liability — treated as an
  // admin-only action, same trust tier as voiding (Part 14.3).
  await requireAdminRole("run payroll");

  const organizationId = await getOrCreateOrganization();

  const employee = await db.query.employees.findFirst({
    where: (e, { and, eq }) => and(eq(e.id, employeeId), eq(e.organizationId, organizationId)),
  });
  if (!employee) throw new Error("Employee not found for this organization.");

  const orgAccounts = await db.select().from(accounts).where(eq(accounts.organizationId, organizationId));
  const cashAccount = orgAccounts.find((a) => a.code === "1000");
  const cpfPayableAccount = orgAccounts.find((a) => a.code === "2300");
  const employerCpfExpenseAccount = orgAccounts.find((a) => a.code === "5500");
  const salaryExpenseAccount = orgAccounts.find((a) => a.code === "5600");

  if (!cashAccount || !cpfPayableAccount || !employerCpfExpenseAccount || !salaryExpenseAccount) {
    throw new Error(
      "Required accounts (1000, 2300, 5500, 5600) are missing from this organization's Chart of Accounts."
    );
  }

  const grossWageCents = Math.round(Number(employee.monthlyWage) * 100);
  const employeeCpfCents = Math.round(grossWageCents * (Number(employee.employeeCpfRate) / 100));
  const employerCpfCents = Math.round(grossWageCents * (Number(employee.employerCpfRate) / 100));
  const netPayCents = grossWageCents - employeeCpfCents;
  const totalCpfCents = employeeCpfCents + employerCpfCents;

  const result = await dbTransactional.transaction(async (tx) => {
    const [payRun] = await tx
      .insert(payRuns)
      .values({
        organizationId,
        employeeId,
        payDate,
        grossWage: (grossWageCents / 100).toFixed(2),
        employeeCpfAmount: (employeeCpfCents / 100).toFixed(2),
        employerCpfAmount: (employerCpfCents / 100).toFixed(2),
        netPay: (netPayCents / 100).toFixed(2),
      })
      .returning();

    const journalResult = await postJournalEntry(
      {
        organizationId,
        entryDate: payDate,
        description: `Payroll: ${employee.name}`,
        sourceType: "payroll",
        sourceId: payRun.id,
        lines: [
          { accountId: salaryExpenseAccount.id, debit: grossWageCents / 100 },
          { accountId: employerCpfExpenseAccount.id, debit: employerCpfCents / 100 },
          { accountId: cashAccount.id, credit: netPayCents / 100 },
          { accountId: cpfPayableAccount.id, credit: totalCpfCents / 100 },
        ],
      },
      tx
    );

    await tx
      .update(payRuns)
      .set({ journalEntryId: journalResult.entry.id })
      .where(eq(payRuns.id, payRun.id));

    return payRun;
  });

  revalidatePath("/payroll");
  return result; 
}

export async function getEmployees() {
  const organizationId = await getOrCreateOrganization();
  return db
    .select()
    .from(employees)
    .where(eq(employees.organizationId, organizationId));
}

export async function createEmployee(input: {
  name: string;
  monthlyWage: number;
  employeeCpfRate: number;
  employerCpfRate: number;
}) {
  await requireAdminRole("add an employee");
  const organizationId = await getOrCreateOrganization();

  await db.insert(employees).values({
    organizationId,
    name: input.name,
    monthlyWage: input.monthlyWage.toFixed(2),
    employeeCpfRate: input.employeeCpfRate.toFixed(2),
    employerCpfRate: input.employerCpfRate.toFixed(2),
  });

  revalidatePath("/payroll");
}

export async function getPayRuns() {
  const organizationId = await getOrCreateOrganization();
  return db.query.payRuns.findMany({
    where: (p, { eq }) => eq(p.organizationId, organizationId),
    with: { employee: true },
    orderBy: (p, { desc }) => desc(p.payDate),
  });
}
```

### The Verification

Check debits equal credits before ever touching the UI, using the Step 14.5.1 worked example: gross wage $3,000, employee CPF 20% = $600, employer CPF 17% = $510.

```
Debit  Salary Expense              = 3000.00
Debit  Employer CPF Expense        = 510.00
                                    -----------
Total debits                       = 3510.00

Credit Cash (net pay = 3000 - 600) = 2400.00
Credit CPF Payable (600 + 510)     = 1110.00
                                    -----------
Total credits                      = 3510.00
```

Debits ($3,510.00) = Credits ($3,510.00). ✅ Balanced — confirms the math before any code runs.

---

## Step 14.5.5 — The Payroll Page

### The Target
Build `/payroll`, letting an admin add employees and run a pay cycle for each.

### The Implementation

**`src/app/payroll/page.tsx`**
```tsx
import { getEmployees, getPayRuns, runPayroll, createEmployee } from "@/lib/actions/payroll";
import { isCurrentUserAdmin } from "@/lib/permissions";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

export default async function PayrollPage() {
  const [employeeList, payRunList, isAdmin] = await Promise.all([
    getEmployees(),
    getPayRuns(),
    isCurrentUserAdmin(),
  ]);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Payroll (CPF)</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        {isAdmin && (
          <form
            action={async (formData: FormData) => {
              "use server";
              await createEmployee({
                name: formData.get("name") as string,
                monthlyWage: parseFloat(formData.get("monthlyWage") as string),
                employeeCpfRate: parseFloat(formData.get("employeeCpfRate") as string) || 20,
                employerCpfRate: parseFloat(formData.get("employerCpfRate") as string) || 17,
              });
            }}
            className="mt-6 flex gap-2 rounded-lg border border-gray-200 bg-white p-4 text-sm"
          >
            <input name="name" placeholder="Employee name" required className="rounded border border-gray-300 px-2 py-1" />
            <input name="monthlyWage" type="number" step="0.01" placeholder="Monthly wage" required className="rounded border border-gray-300 px-2 py-1" />
            <input name="employeeCpfRate" type="number" step="0.01" placeholder="Employee CPF % (default 20)" className="rounded border border-gray-300 px-2 py-1" />
            <input name="employerCpfRate" type="number" step="0.01" placeholder="Employer CPF % (default 17)" className="rounded border border-gray-300 px-2 py-1" />
            <button className="rounded bg-blue-600 px-4 py-2 text-white">Add Employee</button>
          </form>
        )}

        <div className="mt-6 overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-100 text-gray-600">
              <tr>
                <th className="px-4 py-2">Name</th>
                <th className="px-4 py-2">Monthly Wage</th>
                <th className="px-4 py-2">Employee CPF %</th>
                <th className="px-4 py-2">Employer CPF %</th>
                <th className="px-4 py-2"></th>
              </tr>
            </thead>
            <tbody>
              {employeeList.map((e) => (
                <tr key={e.id} className="border-t border-gray-100">
                  <td className="px-4 py-2">{e.name}</td>
                  <td className="px-4 py-2">${e.monthlyWage}</td>
                  <td className="px-4 py-2">{e.employeeCpfRate}%</td>
                  <td className="px-4 py-2">{e.employerCpfRate}%</td>
                  <td className="px-4 py-2 text-right">
                    {isAdmin && (
                      <form
                        action={async (formData: FormData) => {
                          "use server";
                          await runPayroll(e.id, formData.get("payDate") as string);
                        }}
                        className="flex justify-end gap-2"
                      >
                        <input type="date" name="payDate" required className="rounded border border-gray-300 px-2 py-1 text-xs" />
                        <button className="rounded bg-green-600 px-3 py-1 text-xs text-white">Run Payroll</button>
                      </form>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <h2 className="mt-8 font-semibold text-gray-800">Pay Run History</h2>
        <div className="mt-2 overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-100 text-gray-600">
              <tr>
                <th className="px-4 py-2">Date</th>
                <th className="px-4 py-2">Employee</th>
                <th className="px-4 py-2">Gross</th>
                <th className="px-4 py-2">Employee CPF</th>
                <th className="px-4 py-2">Employer CPF</th>
                <th className="px-4 py-2">Net Pay</th>
              </tr>
            </thead>
            <tbody>
              {payRunList.map((p) => (
                <tr key={p.id} className="border-t border-gray-100">
                  <td className="px-4 py-2">{p.payDate}</td>
                  <td className="px-4 py-2">{p.employee.name}</td>
                  <td className="px-4 py-2">${p.grossWage}</td>
                  <td className="px-4 py-2">${p.employeeCpfAmount}</td>
                  <td className="px-4 py-2">${p.employerCpfAmount}</td>
                  <td className="px-4 py-2 font-semibold">${p.netPay}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
```

Add `/payroll` to `src/proxy.ts`'s protected matcher.

### The Verification

As an admin, add an employee: "Test Employee," monthly wage $3,000, default rates (20%/17%). Click **Run Payroll** for today's date.

In Drizzle Studio: `pay_runs` shows one row — `grossWage = 3000.00`, `employeeCpfAmount = 600.00`, `employerCpfAmount = 510.00`, `netPay = 2400.00`, non-null `journalEntryId`. `journal_lines` shows four rows matching the Step 14.5.4 worked example exactly. Visit `/reports/balance-sheet` — confirm still "✅ balanced." Visit `/reports/profit-and-loss` — confirm both Salary Expense ($3,000.00) and Employer CPF Expense ($510.00) appear, correctly reducing Net Income.

As a member-role account, confirm the "Add Employee" form and "Run Payroll" buttons are entirely absent.

