## Appendix A Part 3: Root Pages, Middleware, Dashboard Core

### src/middleware.ts

```ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher(["/dashboard(.*)"]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

### src/app/layout.tsx

```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "QB Clone",
  description: "A QuickBooks clone built for learning",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### src/app/page.tsx

```tsx
import {
  SignedIn,
  SignedOut,
  SignInButton,
  SignUpButton,
  UserButton,
  OrganizationSwitcher,
} from "@clerk/nextjs";
import { auth } from "@clerk/nextjs/server";
import Link from "next/link";

export default async function Home() {
  const { orgId } = await auth();

  return (
    <main style={{ padding: "2rem" }}>
      <h1>QB Clone</h1>

      <SignedOut>
        <p>You are not signed in.</p>
        <SignInButton />
        <SignUpButton />
      </SignedOut>

      <SignedIn>
        <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
          <UserButton />
          <OrganizationSwitcher
            afterCreateOrganizationUrl="/dashboard"
            afterSelectOrganizationUrl="/dashboard"
          />
        </div>

        {orgId ? (
          <p style={{ marginTop: "1rem" }}>
            <Link href="/dashboard">Go to your Dashboard -&gt;</Link>
          </p>
        ) : (
          <p style={{ marginTop: "1rem" }}>
            Create or select a company above to get started.
          </p>
        )}
      </SignedIn>
    </main>
  );
}
```

---
## Appendix A Part 3b: Dashboard Home, Accounts Page

### src/app/dashboard/page.tsx (final version, with all nav links accumulated across the build)

```tsx
import { auth, currentUser } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function DashboardPage() {
  const { orgId } = await auth();
  const user = await currentUser();

  if (!orgId) {
    redirect("/");
  }

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Dashboard</h1>
      <p>Welcome, {user?.firstName ?? "friend"}!</p>
      <p>You&apos;re currently working in organization: {orgId}</p>

      <nav style={{ marginTop: "1rem", display: "flex", gap: "1rem", flexWrap: "wrap" }}>
        <Link href="/dashboard/accounts">Chart of Accounts</Link>
        <Link href="/dashboard/customers">Customers</Link>
        <Link href="/dashboard/vendors">Vendors</Link>
        <Link href="/dashboard/invoices">Invoices</Link>
        <Link href="/dashboard/bills">Bills</Link>
        <Link href="/dashboard/bank-import">Bank Import</Link>
        <Link href="/dashboard/reports/profit-and-loss">Profit & Loss</Link>
        <Link href="/dashboard/reports/balance-sheet">Balance Sheet</Link>
        <Link href="/dashboard/reports/ar-aging">AR Aging</Link>
        <Link href="/dashboard/reports/ap-aging">AP Aging</Link>
      </nav>
    </main>
  );
}
```

### src/app/dashboard/accounts/page.tsx

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { accounts } from "@/lib/db/schema";
import { eq } from "drizzle-orm";

export default async function AccountsPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.orgId, orgId))
    .orderBy(accounts.code);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Chart of Accounts</h1>
      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Code</th>
            <th>Name</th>
            <th>Type</th>
            <th>Subtype</th>
            <th>Normal Balance</th>
          </tr>
        </thead>
        <tbody>
          {allAccounts.map((a) => (
            <tr key={a.id}>
              <td>{a.code}</td>
              <td>{a.name}</td>
              <td>{a.type}</td>
              <td>{a.subtype}</td>
              <td>{a.normalBalance}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

---
Let me pull Part 3c.
## Appendix A Part 3c: Customers and Vendors Pages

### src/app/dashboard/customers/actions.ts

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

### src/app/dashboard/customers/page.tsx

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

### src/app/dashboard/vendors/actions.ts

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

### src/app/dashboard/vendors/page.tsx

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

This completes Appendix A Part 3 (root pages, middleware, dashboard core, accounts, customers, vendors).

---

Next up is **Appendix A Part 4 (Invoices, Final State)** — the final version of `invoices/actions.ts` (already includes ledger posting AND the Inngest event, not the earlier draft version), plus the new-invoice form and list page. Want me to continue?
