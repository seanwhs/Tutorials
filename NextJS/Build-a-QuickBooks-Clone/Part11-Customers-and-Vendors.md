## Part 11: Customers & Vendors

**Goal:** build our first user-facing CRUD feature using Server Actions, for both Customers and Vendors.

**Prerequisite:** Parts 1-10 completed.

---

### 1. Add the schema

Open src/lib/db/schema.ts. Add these two tables at the end of the file (keep everything already there):

```ts
export const customers = pgTable("customers", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  email: text("email"),
  phone: text("phone"),
  billingAddress: text("billing_address"),
  notes: text("notes"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const vendors = pgTable("vendors", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  email: text("email"),
  phone: text("phone"),
  billingAddress: text("billing_address"),
  notes: text("notes"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});
```

Run:
```
npm run db:generate
npm run db:migrate
```

### 2. Create the customers Server Action

Create the folder src/app/dashboard/customers/. Inside it, create actions.ts:

```ts
"use server";

import { db } from "@/lib/db";
import { customers } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function createCustomer(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const name = formData.get("name") as string;
  const email = formData.get("email") as string | null;
  const phone = formData.get("phone") as string | null;

  if (!name || name.trim() === "") {
    throw new Error("Customer name is required");
  }

  await db.insert(customers).values({
    orgId,
    name,
    email: email || null,
    phone: phone || null,
  });

  revalidatePath("/dashboard/customers");
  redirect("/dashboard/customers");
}
```

### 3. Build the customer list + form page

In the same folder, create page.tsx:

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { customers } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { createCustomer } from "./actions";

export default async function CustomersPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allCustomers = await db
    .select()
    .from(customers)
    .where(eq(customers.orgId, orgId))
    .orderBy(customers.name);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Customers</h1>

      <form action={createCustomer} style={{ marginBottom: "2rem" }}>
        <input name="name" placeholder="Customer name" required />
        <input name="email" placeholder="Email (optional)" type="email" />
        <input name="phone" placeholder="Phone (optional)" />
        <button type="submit">Add Customer</button>
      </form>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Phone</th>
          </tr>
        </thead>
        <tbody>
          {allCustomers.map((c) => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{c.email ?? "-"}</td>
              <td>{c.phone ?? "-"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

Visit http://localhost:3000/dashboard/customers, add a couple of test customers, confirm they appear immediately.

### 4. Repeat the exact same pattern for Vendors

Create the folder src/app/dashboard/vendors/. Inside it, create actions.ts:

```ts
"use server";

import { db } from "@/lib/db";
import { vendors } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function createVendor(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const name = formData.get("name") as string;
  const email = formData.get("email") as string | null;
  const phone = formData.get("phone") as string | null;

  if (!name || name.trim() === "") {
    throw new Error("Vendor name is required");
  }

  await db.insert(vendors).values({
    orgId,
    name,
    email: email || null,
    phone: phone || null,
  });

  revalidatePath("/dashboard/vendors");
  redirect("/dashboard/vendors");
}
```

And page.tsx:

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { vendors } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { createVendor } from "./actions";

export default async function VendorsPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allVendors = await db
    .select()
    .from(vendors)
    .where(eq(vendors.orgId, orgId))
    .orderBy(vendors.name);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Vendors</h1>

      <form action={createVendor} style={{ marginBottom: "2rem" }}>
        <input name="name" placeholder="Vendor name" required />
        <input name="email" placeholder="Email (optional)" type="email" />
        <input name="phone" placeholder="Phone (optional)" />
        <button type="submit">Add Vendor</button>
      </form>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Phone</th>
          </tr>
        </thead>
        <tbody>
          {allVendors.map((v) => (
            <tr key={v.id}>
              <td>{v.name}</td>
              <td>{v.email ?? "-"}</td>
              <td>{v.phone ?? "-"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

### 5. Add navigation

Open src/app/dashboard/page.tsx. Add this import at the top:
```tsx
import Link from "next/link";
```
Inside the returned JSX, just below the welcome paragraph, add:
```tsx
<nav style={{ marginTop: "1rem", display: "flex", gap: "1rem" }}>
  <Link href="/dashboard/accounts">Chart of Accounts</Link>
  <Link href="/dashboard/customers">Customers</Link>
  <Link href="/dashboard/vendors">Vendors</Link>
</nav>
```

### 6. Commit

```
git add .
git commit -m "Add Customers and Vendors CRUD using Server Actions"
```

---

### Checkpoint

- [ ] customers and vendors tables exist
- [ ] /dashboard/customers lets you add and immediately see a customer
- [ ] /dashboard/vendors works the same way
- [ ] Dashboard has working nav links to all three pages

---

### Troubleshooting

**Clicking "Add Customer" does nothing visible**
Check your terminal running npm run dev for a red error message — a thrown Error inside a Server Action shows up there and may also show a Next.js error overlay in the browser. The most common cause: you left the "name" field empty (it's `required` on the input, so the browser should already block submission — if it didn't, check the input has `required` exactly as shown).

**New customer doesn't appear in the list after submitting**
Confirm `revalidatePath("/dashboard/customers")` is present and spelled correctly before the redirect line — without it, Next.js may show a cached version of the list.

**Error: "orgId is possibly null" (TypeScript)**
This is why we check `if (!orgId) throw new Error(...)` at the top of the action, and `if (!orgId) redirect("/")` at the top of the page — both narrow the type so TypeScript knows orgId is a real string afterward. If you see this error, confirm you added those exact guard lines before using orgId anywhere else in the function.

**Both Customers and Vendors pages show the SAME data**
This usually means you copy-pasted actions.ts or page.tsx for vendors but forgot to change `customers` to `vendors` in one or more places (the import, the table name in the query, the variable names). Re-check every occurrence carefully.

**Form submits but shows a blank page or a Next.js redirect error in the console**
This is often harmless — `redirect()` inside a Server Action works by throwing a special internal signal that Next.js catches; some browser extensions or dev tools can misreport this in the console as an "error" when it's actually expected behavior. Confirm the actual page navigation happened correctly (URL bar shows /dashboard/customers) before assuming something's broken.

**"Module not found: Can't resolve './actions'"**
Confirm actions.ts and page.tsx are in the exact same folder (src/app/dashboard/customers/ or .../vendors/), and that the import in page.tsx says `from "./actions"` with the correct relative path.

---

Ready for **Part 12: Building Invoices** ? This is the first feature with real accounting consequences.
