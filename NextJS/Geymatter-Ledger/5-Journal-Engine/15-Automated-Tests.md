# Part 15 — Automated Tests for the Journal Engine

In Part 14, we manually tested the journal engine through the browser.

We proved that:

```txt
Valid balanced entries post successfully.
Invalid unbalanced entries are rejected.
Rejected entries do not create database rows.
```

Manual testing is useful, but we should not rely on clicking buttons forever.

In this part, we will add automated tests for the journal validation layer.

By the end of this part, you will have:

- Vitest installed
- A test script in `package.json`
- A dedicated journal validation module
- A cleaner `postJournalEntry()` service that reuses the validation module
- Automated tests for valid entries
- Automated tests for unbalanced entries
- Automated tests for invalid lines
- Automated tests for dates, memos, UUIDs, and integer cents
- A repeatable `pnpm test` command
- A stronger `pnpm check` command that includes tests

This part is a major quality milestone.

The journal engine is the heart of the accounting system. It deserves tests.

---

# 1. Understand What We Are Testing

## The Target

We are adding automated tests around the accounting rules enforced before a journal entry is posted.

---

## The Concept

Manual tests are like checking a door lock by hand.

Automated tests are like installing a machine that checks the lock every time you change the building.

Every time we run:

```bash
pnpm test
```

the test suite should confirm that the core accounting rules still work.

We will focus on the **pure validation layer** first.

A pure validation layer means:

```txt
Input goes in.
Validation result comes out.
No database required.
No Clerk session required.
No browser required.
```

That makes the tests fast, repeatable, and reliable.

---

## The Implementation

We will extract validation logic from:

```txt
services/journal/post-journal-entry.ts
```

into:

```txt
services/journal/validate-post-journal-entry.ts
```

Then `postJournalEntry()` will call that validation module.

The relationship will look like this:

```txt
Automated tests
  |
  v
validatePostJournalEntryInput()
  |
  v
Validation result

postJournalEntry()
  |
  v
validatePostJournalEntryInput()
  |
  v
Account ownership checks
  |
  v
Database transaction
```

This gives us both:

```txt
Fast automated validation tests
Real database-backed posting service
```

---

## The Verification

At the end:

```bash
pnpm test
```

should pass.

And:

```bash
pnpm check
```

should run:

```txt
lint
tests
build
```

successfully.

---

# 2. Install Vitest

## The Target

We are installing **Vitest**, a fast test runner for TypeScript projects.

---

## The Concept

A test runner is a tool that finds test files, runs them, and reports whether they pass or fail.

Vitest works well with TypeScript and modern frontend/full-stack projects.

A test file usually looks like:

```ts
import { describe, expect, it } from "vitest";

describe("some feature", () => {
  it("does something correctly", () => {
    expect(1 + 1).toBe(2);
  });
});
```

The words mean:

```txt
describe = group of tests
it       = one specific test case
expect   = assertion about the result
```

An assertion is a statement that must be true.

---

## The Implementation

Run:

```bash
pnpm add -D vitest
```

---

## The Verification

Run:

```bash
pnpm vitest --version
```

You should see a version number.

Example:

```txt
vitest/...
```

---

# 3. Add Vitest Configuration

## The Target

We are creating:

```txt
vitest.config.ts
```

This file configures the test environment and the `@/*` import alias.

---

## The Concept

Our app imports files like this:

```ts
import { formatMoney } from "@/lib/money";
```

Vitest needs to understand that:

```txt
@/
```

means:

```txt
project root
```

So we add an alias in the Vitest config.

---

## The Implementation

Create:

```txt
vitest.config.ts
```

Add:

```ts
// vitest.config.ts

import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
    globals: false,
  },
  resolve: {
    alias: {
      "@": fileURLToPath(new URL(".", import.meta.url)),
    },
  },
});
```

Important part:

```ts
"@": fileURLToPath(new URL(".", import.meta.url))
```

This tells Vitest:

> When an import starts with `@`, resolve it from the project root.

---

## The Verification

Run:

```bash
pnpm vitest --run
```

You may see:

```txt
No test files found
```

That is okay right now because we have not created tests yet.

---

# 4. Add Test Scripts

## The Target

We are updating:

```txt
package.json
```

with test scripts.

---

## The Concept

Instead of typing long commands, we add named scripts.

We want:

```bash
pnpm test
```

to run the test suite once.

We also want:

```bash
pnpm test:watch
```

to keep tests running while we develop.

And we want:

```bash
pnpm check
```

to run:

```txt
lint -> test -> build
```

That way our project health check includes automated tests.

---

## The Implementation

Open:

```txt
package.json
```

Update the `"scripts"` block so it includes:

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "test": "vitest --run",
    "test:watch": "vitest",
    "check": "pnpm lint && pnpm test && pnpm build",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio",
    "db:push": "drizzle-kit push"
  }
}
```

Do not replace your whole `package.json` blindly because your dependency versions may differ.

Only update the scripts block.

---

## The Verification

Run:

```bash
pnpm test
```

You may still see no test files found.

That is fine for the moment.

---

# 5. Extract Journal Validation into a Dedicated Module

## The Target

We are creating:

```txt
services/journal/validate-post-journal-entry.ts
```

This module contains the pure validation logic used by the journal engine.

---

## The Concept

The journal posting service does two kinds of work:

```txt
Pure validation:
  - Is the date valid?
  - Is the memo present?
  - Do lines have valid amounts?
  - Do debits equal credits?

Database/security validation:
  - Does the account exist?
  - Does the account belong to this organization?
  - Is the account active?
```

The first category can be tested without a database.

So we extract it.

This makes the most important accounting invariant easy to test:

```txt
total debits = total credits
```

---

## The Implementation

Create:

```txt
services/journal/validate-post-journal-entry.ts
```

Add:

```ts
// services/journal/validate-post-journal-entry.ts

import { journalSourceTypeEnum } from "@/db/schema";
import type { MoneyCents } from "@/lib/money";

export type JournalSourceType =
  (typeof journalSourceTypeEnum.enumValues)[number];

export type PostJournalEntryLineInput = {
  accountId: string;
  description?: string | null;
  debitCents?: MoneyCents;
  creditCents?: MoneyCents;
};

export type PostJournalEntryInput = {
  entryDate: string;
  memo: string;
  sourceType?: JournalSourceType;
  sourceId?: string | null;
  lines: PostJournalEntryLineInput[];
};

export type NormalizedJournalLineInput = {
  accountId: string;
  description: string | null;
  debitCents: MoneyCents;
  creditCents: MoneyCents;
};

export type NormalizedJournalEntryInput = {
  entryDate: string;
  memo: string;
  sourceType: JournalSourceType;
  sourceId: string | null;
  lines: NormalizedJournalLineInput[];
};

export type JournalInputValidationResult = {
  normalizedInput: NormalizedJournalEntryInput;
  totalDebitCents: MoneyCents;
  totalCreditCents: MoneyCents;
  issues: string[];
};

const validJournalSourceTypes = journalSourceTypeEnum.enumValues;

const uuidRegex =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isValidUuid(value: string): boolean {
  return uuidRegex.test(value);
}

export function isValidJournalDateString(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }

  const parsed = new Date(`${value}T00:00:00.000Z`);

  if (Number.isNaN(parsed.getTime())) {
    return false;
  }

  /**
   * Prevent JavaScript from accepting impossible dates by normalization.
   *
   * Example:
   *   "2026-02-31" should be invalid.
   */
  return parsed.toISOString().slice(0, 10) === value;
}

export function isIntegerCents(value: number): boolean {
  return Number.isInteger(value) && Number.isSafeInteger(value);
}

function normalizeOptionalText(value: string | null | undefined): string | null {
  const normalized = value?.trim() ?? "";

  return normalized.length > 0 ? normalized : null;
}

export function normalizePostJournalEntryInput(
  input: PostJournalEntryInput,
): NormalizedJournalEntryInput {
  return {
    entryDate: input.entryDate.trim(),
    memo: input.memo.trim(),
    sourceType: input.sourceType ?? "manual",
    sourceId: normalizeOptionalText(input.sourceId),
    lines: input.lines.map((line) => ({
      accountId: line.accountId.trim(),
      description: normalizeOptionalText(line.description),
      debitCents: line.debitCents ?? 0,
      creditCents: line.creditCents ?? 0,
    })),
  };
}

/**
 * Validates journal entry input before database posting.
 *
 * This function is pure:
 * - no Clerk calls
 * - no database calls
 * - no network calls
 *
 * That makes it ideal for automated tests.
 */
export function validatePostJournalEntryInput(
  rawInput: PostJournalEntryInput,
): JournalInputValidationResult {
  const input = normalizePostJournalEntryInput(rawInput);
  const issues: string[] = [];

  if (!isValidJournalDateString(input.entryDate)) {
    issues.push("Journal entry date must be a valid YYYY-MM-DD date.");
  }

  if (!input.memo) {
    issues.push("Journal entry memo is required.");
  }

  if (input.memo.length > 500) {
    issues.push("Journal entry memo must be 500 characters or fewer.");
  }

  if (!validJournalSourceTypes.includes(input.sourceType)) {
    issues.push("Journal entry source type is invalid.");
  }

  if (input.sourceId && !isValidUuid(input.sourceId)) {
    issues.push("Journal entry source ID must be a valid UUID when provided.");
  }

  if (input.lines.length < 2) {
    issues.push("A journal entry must contain at least two lines.");
  }

  let totalDebitCents = 0;
  let totalCreditCents = 0;

  input.lines.forEach((line, index) => {
    const lineNumber = index + 1;

    if (!line.accountId) {
      issues.push(`Line ${lineNumber}: account ID is required.`);
    } else if (!isValidUuid(line.accountId)) {
      issues.push(`Line ${lineNumber}: account ID must be a valid UUID.`);
    }

    if (!isIntegerCents(line.debitCents)) {
      issues.push(`Line ${lineNumber}: debit must be integer cents.`);
    }

    if (!isIntegerCents(line.creditCents)) {
      issues.push(`Line ${lineNumber}: credit must be integer cents.`);
    }

    if (line.debitCents < 0) {
      issues.push(`Line ${lineNumber}: debit cannot be negative.`);
    }

    if (line.creditCents < 0) {
      issues.push(`Line ${lineNumber}: credit cannot be negative.`);
    }

    if (line.debitCents > 0 && line.creditCents > 0) {
      issues.push(
        `Line ${lineNumber}: a line cannot have both debit and credit amounts.`,
      );
    }

    if (line.debitCents === 0 && line.creditCents === 0) {
      issues.push(
        `Line ${lineNumber}: a line must have either a debit or a credit amount.`,
      );
    }

    if (line.description && line.description.length > 500) {
      issues.push(`Line ${lineNumber}: description must be 500 characters or fewer.`);
    }

    totalDebitCents += line.debitCents;
    totalCreditCents += line.creditCents;
  });

  if (totalDebitCents !== totalCreditCents) {
    issues.push(
      `Journal entry is unbalanced: debits total ${totalDebitCents} cents but credits total ${totalCreditCents} cents.`,
    );
  }

  if (totalDebitCents === 0 && totalCreditCents === 0) {
    issues.push("Journal entry total must be greater than zero.");
  }

  return {
    normalizedInput: input,
    totalDebitCents,
    totalCreditCents,
    issues,
  };
}
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 6. Update `postJournalEntry()` to Use the Validation Module

## The Target

We are updating:

```txt
services/journal/post-journal-entry.ts
```

so it reuses the new validation module.

---

## The Concept

We do not want two different versions of journal validation.

That would be dangerous.

Bad:

```txt
Tests validate one function.
Production posting uses different validation.
```

Good:

```txt
Tests validate validatePostJournalEntryInput().
postJournalEntry() uses validatePostJournalEntryInput().
```

That means our automated tests protect the real posting path.

---

## The Implementation

Open:

```txt
services/journal/post-journal-entry.ts
```

Replace the entire file with:

```ts
// services/journal/post-journal-entry.ts

import { auth } from "@clerk/nextjs/server";
import { and, eq, inArray } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  journalEntries,
  journalLines,
  type Account,
  type JournalEntry,
  type JournalLine,
} from "@/db/schema";
import type { MoneyCents } from "@/lib/money";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";
import { JournalEntryValidationError } from "@/services/journal/journal-errors";
import {
  type NormalizedJournalLineInput,
  type PostJournalEntryInput,
  type JournalSourceType,
  validatePostJournalEntryInput,
} from "@/services/journal/validate-post-journal-entry";

export type {
  JournalSourceType,
  PostJournalEntryInput,
  PostJournalEntryLineInput,
} from "@/services/journal/validate-post-journal-entry";

export type PostedJournalEntryResult = {
  journalEntry: JournalEntry;
  journalLines: JournalLine[];
  totalDebitCents: MoneyCents;
  totalCreditCents: MoneyCents;
};

function validateAccountsForPosting(params: {
  lines: NormalizedJournalLineInput[];
  accountRows: Account[];
}): string[] {
  const issues: string[] = [];

  const accountById = new Map(
    params.accountRows.map((account) => [account.id, account]),
  );

  params.lines.forEach((line, index) => {
    const lineNumber = index + 1;
    const account = accountById.get(line.accountId);

    if (!account) {
      issues.push(
        `Line ${lineNumber}: account does not exist for the active organization.`,
      );
      return;
    }

    if (!account.isActive) {
      issues.push(
        `Line ${lineNumber}: account ${account.code} ${account.name} is inactive.`,
      );
    }
  });

  return issues;
}

/**
 * Posts a balanced journal entry for the currently active organization.
 *
 * This is the core accounting write function.
 *
 * It is intentionally strict:
 * - validates entry shape
 * - enforces balanced debits and credits
 * - verifies accounts belong to the active organization
 * - verifies accounts are active
 * - writes entry and lines in one transaction
 */
export async function postJournalEntry(
  rawInput: PostJournalEntryInput,
): Promise<PostedJournalEntryResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  const validation = validatePostJournalEntryInput(rawInput);

  if (validation.issues.length > 0) {
    throw new JournalEntryValidationError(validation.issues);
  }

  const input = validation.normalizedInput;

  const distinctAccountIds = [
    ...new Set(input.lines.map((line) => line.accountId)),
  ];

  const result = await db.transaction(async (tx) => {
    const accountRows = await tx
      .select()
      .from(accounts)
      .where(
        and(
          eq(accounts.organizationId, organization.id),
          inArray(accounts.id, distinctAccountIds),
        ),
      );

    const accountIssues = validateAccountsForPosting({
      lines: input.lines,
      accountRows,
    });

    if (accountIssues.length > 0) {
      throw new JournalEntryValidationError(accountIssues);
    }

    const now = new Date();

    const [createdJournalEntry] = await tx
      .insert(journalEntries)
      .values({
        organizationId: organization.id,
        entryDate: input.entryDate,
        memo: input.memo,
        sourceType: input.sourceType,
        sourceId: input.sourceId,
        postedByUserId: userId ?? null,
        createdAt: now,
        updatedAt: now,
      })
      .returning();

    if (!createdJournalEntry) {
      throw new Error("Journal entry could not be created.");
    }

    const lineValues = input.lines.map((line, index) => ({
      journalEntryId: createdJournalEntry.id,
      organizationId: organization.id,
      accountId: line.accountId,
      lineNumber: index + 1,
      description: line.description,
      debitCents: line.debitCents,
      creditCents: line.creditCents,
      createdAt: now,
    }));

    const createdJournalLines = await tx
      .insert(journalLines)
      .values(lineValues)
      .returning();

    return {
      journalEntry: createdJournalEntry,
      journalLines: createdJournalLines,
      totalDebitCents: validation.totalDebitCents,
      totalCreditCents: validation.totalCreditCents,
    };
  });

  return result;
}
```

The important architectural improvement is:

```ts
const validation = validatePostJournalEntryInput(rawInput);
```

The production service now uses the same validation function our tests will use.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 7. Create the Journal Validation Test File

## The Target

We are creating:

```txt
tests/journal-validation.test.ts
```

This file tests the core journal validation rules.

---

## The Concept

A test file should describe behavior clearly.

We will test:

```txt
Valid balanced entries pass.
Unbalanced entries fail.
Entries with one line fail.
Missing memo fails.
Invalid dates fail.
Invalid account UUIDs fail.
Both debit and credit on one line fail.
Zero amount lines fail.
Negative amounts fail.
Decimal cents fail.
Invalid source IDs fail.
```

These tests protect the most important rules before database posting.

---

## The Implementation

Create the folder:

```bash
mkdir -p tests
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force tests
```

Create:

```txt
tests/journal-validation.test.ts
```

Add:

```ts
// tests/journal-validation.test.ts

import { describe, expect, it } from "vitest";
import {
  isValidJournalDateString,
  validatePostJournalEntryInput,
} from "@/services/journal/validate-post-journal-entry";

const bankAccountId = "11111111-1111-4111-8111-111111111111";
const capitalAccountId = "22222222-2222-4222-8222-222222222222";
const receivableAccountId = "33333333-3333-4333-8333-333333333333";
const revenueAccountId = "44444444-4444-4444-8444-444444444444";
const gstAccountId = "55555555-5555-4555-8555-555555555555";

describe("isValidJournalDateString", () => {
  it("accepts a real YYYY-MM-DD date", () => {
    expect(isValidJournalDateString("2026-01-31")).toBe(true);
  });

  it("rejects impossible calendar dates", () => {
    expect(isValidJournalDateString("2026-02-31")).toBe(false);
  });

  it("rejects non-YYYY-MM-DD formats", () => {
    expect(isValidJournalDateString("31/01/2026")).toBe(false);
    expect(isValidJournalDateString("2026-1-31")).toBe(false);
    expect(isValidJournalDateString("not-a-date")).toBe(false);
  });
});

describe("validatePostJournalEntryInput", () => {
  it("accepts a valid owner contribution entry", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Owner contributes startup cash",
      sourceType: "manual",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 1000000,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 1000000,
        },
      ],
    });

    expect(result.issues).toEqual([]);
    expect(result.totalDebitCents).toBe(1000000);
    expect(result.totalCreditCents).toBe(1000000);
    expect(result.normalizedInput.sourceType).toBe("manual");
    expect(result.normalizedInput.lines).toHaveLength(2);
  });

  it("accepts a valid GST invoice-style entry", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-05",
      memo: "Invoice issued for S$109 including GST",
      sourceType: "invoice",
      sourceId: "66666666-6666-4666-8666-666666666666",
      lines: [
        {
          accountId: receivableAccountId,
          debitCents: 10900,
          creditCents: 0,
        },
        {
          accountId: revenueAccountId,
          debitCents: 0,
          creditCents: 10000,
        },
        {
          accountId: gstAccountId,
          debitCents: 0,
          creditCents: 900,
        },
      ],
    });

    expect(result.issues).toEqual([]);
    expect(result.totalDebitCents).toBe(10900);
    expect(result.totalCreditCents).toBe(10900);
    expect(result.normalizedInput.sourceType).toBe("invoice");
  });

  it("defaults sourceType to manual", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Default source type test",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 100,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toEqual([]);
    expect(result.normalizedInput.sourceType).toBe("manual");
  });

  it("trims memo, date, account IDs, descriptions, and source ID", () => {
    const result = validatePostJournalEntryInput({
      entryDate: " 2026-01-01 ",
      memo: "  Trimmed memo  ",
      sourceId: " 66666666-6666-4666-8666-666666666666 ",
      lines: [
        {
          accountId: ` ${bankAccountId} `,
          description: "  Bank side  ",
          debitCents: 100,
          creditCents: 0,
        },
        {
          accountId: ` ${capitalAccountId} `,
          description: "  Capital side  ",
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toEqual([]);
    expect(result.normalizedInput.entryDate).toBe("2026-01-01");
    expect(result.normalizedInput.memo).toBe("Trimmed memo");
    expect(result.normalizedInput.sourceId).toBe(
      "66666666-6666-4666-8666-666666666666",
    );
    expect(result.normalizedInput.lines[0]?.description).toBe("Bank side");
  });

  it("rejects an unbalanced entry", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Unbalanced test",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 10000,
          creditCents: 0,
        },
        {
          accountId: revenueAccountId,
          debitCents: 0,
          creditCents: 9000,
        },
      ],
    });

    expect(result.totalDebitCents).toBe(10000);
    expect(result.totalCreditCents).toBe(9000);
    expect(result.issues).toContain(
      "Journal entry is unbalanced: debits total 10000 cents but credits total 9000 cents.",
    );
  });

  it("rejects an entry with fewer than two lines", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "One line test",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 100,
          creditCents: 0,
        },
      ],
    });

    expect(result.issues).toContain(
      "A journal entry must contain at least two lines.",
    );
  });

  it("rejects a missing memo", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "   ",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 100,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toContain("Journal entry memo is required.");
  });

  it("rejects an invalid date", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-02-31",
      memo: "Invalid date test",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 100,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toContain(
      "Journal entry date must be a valid YYYY-MM-DD date.",
    );
  });

  it("rejects invalid account UUIDs", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Invalid UUID test",
      lines: [
        {
          accountId: "not-a-uuid",
          debitCents: 100,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toContain("Line 1: account ID must be a valid UUID.");
  });

  it("rejects a line with both debit and credit", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Both sides test",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 100,
          creditCents: 100,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toContain(
      "Line 1: a line cannot have both debit and credit amounts.",
    );
  });

  it("rejects a line with neither debit nor credit", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Zero line test",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 0,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toContain(
      "Line 1: a line must have either a debit or a credit amount.",
    );
  });

  it("rejects negative amounts", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Negative amount test",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: -100,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toContain("Line 1: debit cannot be negative.");
  });

  it("rejects decimal cents", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Decimal cents test",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 100.5,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100.5,
        },
      ],
    });

    expect(result.issues).toContain("Line 1: debit must be integer cents.");
    expect(result.issues).toContain("Line 2: credit must be integer cents.");
  });

  it("rejects an invalid source ID", () => {
    const result = validatePostJournalEntryInput({
      entryDate: "2026-01-01",
      memo: "Invalid source ID test",
      sourceType: "invoice",
      sourceId: "invoice-123",
      lines: [
        {
          accountId: bankAccountId,
          debitCents: 100,
          creditCents: 0,
        },
        {
          accountId: capitalAccountId,
          debitCents: 0,
          creditCents: 100,
        },
      ],
    });

    expect(result.issues).toContain(
      "Journal entry source ID must be a valid UUID when provided.",
    );
  });
});
```

---

## The Verification

Run:

```bash
pnpm test
```

You should see all tests pass.

Example output shape:

```txt
✓ tests/journal-validation.test.ts
Test Files  1 passed
Tests       15 passed
```

The exact number may differ slightly if Vitest counts nested tests differently, but every test should pass.

---

# 8. Add Tests for `JournalEntryValidationError`

## The Target

We are creating:

```txt
tests/journal-errors.test.ts
```

This verifies our custom journal validation error behaves correctly.

---

## The Concept

The journal service throws:

```ts
JournalEntryValidationError
```

when validation fails.

Server actions use the type guard:

```ts
isJournalEntryValidationError()
```

to show helpful messages.

We should test that behavior.

---

## The Implementation

Create:

```txt
tests/journal-errors.test.ts
```

Add:

```ts
// tests/journal-errors.test.ts

import { describe, expect, it } from "vitest";
import {
  isJournalEntryValidationError,
  JournalEntryValidationError,
} from "@/services/journal/journal-errors";

describe("JournalEntryValidationError", () => {
  it("stores validation issues and combines them into the error message", () => {
    const error = new JournalEntryValidationError([
      "First issue.",
      "Second issue.",
    ]);

    expect(error.name).toBe("JournalEntryValidationError");
    expect(error.issues).toEqual(["First issue.", "Second issue."]);
    expect(error.message).toBe("First issue. Second issue.");
  });

  it("is recognized by the type guard", () => {
    const error = new JournalEntryValidationError(["Invalid journal entry."]);

    expect(isJournalEntryValidationError(error)).toBe(true);
  });

  it("does not classify normal errors as journal validation errors", () => {
    const error = new Error("Database connection failed.");

    expect(isJournalEntryValidationError(error)).toBe(false);
  });

  it("does not classify arbitrary values as journal validation errors", () => {
    expect(isJournalEntryValidationError(null)).toBe(false);
    expect(isJournalEntryValidationError(undefined)).toBe(false);
    expect(isJournalEntryValidationError("not an error")).toBe(false);
  });
});
```

---

## The Verification

Run:

```bash
pnpm test
```

You should now see two test files pass:

```txt
tests/journal-validation.test.ts
tests/journal-errors.test.ts
```

---

# 9. Add Tests for Money Helpers

## The Target

We are creating:

```txt
tests/money.test.ts
```

This verifies our money helper behavior.

---

## The Concept

The journal engine depends on integer cents.

So our money helpers are part of the accounting foundation.

We want to confirm:

```txt
formatMoney(10900) displays S$109.00
dollarsToCents("109.00") returns 10900
decimal floating mistakes are avoided by integer cents
invalid inputs are rejected
```

---

## The Implementation

Create:

```txt
tests/money.test.ts
```

Add:

```ts
// tests/money.test.ts

import { describe, expect, it } from "vitest";
import { dollarsToCents, formatMoney } from "@/lib/money";

describe("formatMoney", () => {
  it("formats integer cents as Singapore dollars", () => {
    expect(formatMoney(10900)).toBe("S$109.00");
  });

  it("formats zero cents", () => {
    expect(formatMoney(0)).toBe("S$0.00");
  });

  it("formats negative cents", () => {
    expect(formatMoney(-10900)).toBe("-S$109.00");
  });

  it("rejects non-integer cents", () => {
    expect(() => formatMoney(109.99)).toThrow(
      "Money amounts must be stored as integer cents.",
    );
  });
});

describe("dollarsToCents", () => {
  it("converts whole dollar strings to cents", () => {
    expect(dollarsToCents("109")).toBe(10900);
  });

  it("converts decimal dollar strings to cents", () => {
    expect(dollarsToCents("109.00")).toBe(10900);
    expect(dollarsToCents("109.9")).toBe(10990);
    expect(dollarsToCents("109.99")).toBe(10999);
  });

  it("converts number input to cents", () => {
    expect(dollarsToCents(109)).toBe(10900);
    expect(dollarsToCents(109.5)).toBe(10950);
  });

  it("converts negative amounts", () => {
    expect(dollarsToCents("-10.25")).toBe(-1025);
  });

  it("rejects more than two decimal places", () => {
    expect(() => dollarsToCents("109.999")).toThrow(
      "Invalid money amount. Use a whole number or up to two decimal places.",
    );
  });

  it("rejects non-money text", () => {
    expect(() => dollarsToCents("abc")).toThrow(
      "Invalid money amount. Use a whole number or up to two decimal places.",
    );
  });
});
```

---

## The Verification

Run:

```bash
pnpm test
```

You should see all three test files pass.

---

# 10. Run the Full Project Check

## The Target

We are running the complete project health command.

---

## The Concept

Our `check` script now runs:

```txt
lint
tests
build
```

This gives us a stronger safety net.

A useful analogy:

```txt
lint  = grammar check
tests = behavior check
build = production readiness check
```

All three should pass before committing.

---

## The Implementation

Run:

```bash
pnpm check
```

---

## The Verification

The command should complete successfully.

Expected flow:

```txt
pnpm lint
pnpm test
pnpm build
```

If any step fails, fix it before continuing.

---

# 11. Manually Confirm the App Still Works

## The Target

We are verifying that extracting validation did not break the browser workflow.

---

## The Concept

Automated tests are excellent, but after refactoring production code, we should still quickly verify the app pages.

Especially because we changed:

```txt
postJournalEntry()
```

The manual journal test page should still work.

---

## The Implementation

Start the dev server:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/settings/database/journal/manual-test
```

Click:

```txt
Post owner contribution
```

Then click:

```txt
Try invalid entry
```

---

## The Verification

Expected:

- Owner contribution still posts.
- Invalid entry is still rejected.
- Journal diagnostics still show balanced entries only.

Open:

```txt
http://localhost:3000/settings/database/journal
```

Every displayed journal entry should still show:

```txt
Balanced
```

---

# 12. Add Testing Notes to the README

## The Target

We are updating:

```txt
README.md
```

to document test commands.

---

## The Concept

A README should tell future developers how to verify the project.

Now that we have tests, the README should include:

```bash
pnpm test
pnpm test:watch
pnpm check
```

---

## The Implementation

Open:

```txt
README.md
```

Replace the whole file with this updated version:

```md
# GreyMatter Ledger

GreyMatter Ledger is a Singapore-ready double-entry accounting web application built with Next.js, TypeScript, Tailwind CSS, Clerk, Drizzle ORM, Neon Postgres, Inngest, and Vercel.

This project is built as a comprehensive tutorial series. It starts from an empty folder and grows into a professional-grade accounting application.

## Core Goals

- Enforce double-entry accounting rules
- Support multiple company workspaces
- Keep each organization's accounting data isolated
- Build GST-aware invoicing and reporting workflows
- Generate financial reports from journal entries
- Provide auditability for important accounting actions
- Support bank import and reconciliation
- Automate reminders and recurring invoices with background jobs

## Tech Stack

- Next.js
- React
- TypeScript
- Tailwind CSS
- Clerk
- Neon Postgres
- Drizzle ORM
- Inngest
- Vercel
- Vitest

## Local Development

Install dependencies:

```bash
pnpm install
```

Start the development server:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

## Useful Scripts

```bash
pnpm dev
pnpm build
pnpm start
pnpm lint
pnpm test
pnpm test:watch
pnpm check
pnpm db:generate
pnpm db:migrate
pnpm db:studio
```

## Testing

Run the automated test suite:

```bash
pnpm test
```

Run tests in watch mode while developing:

```bash
pnpm test:watch
```

Run the full project health check:

```bash
pnpm check
```

The check command runs linting, automated tests, and a production build.

## Accounting Principle

The central rule of the application is:

```txt
Total debits must equal total credits.
```

Every invoice, bill, payment, adjustment, and bank transaction will eventually be represented as a balanced journal entry.

## Money Storage

Money is stored as integer cents.

Examples:

```txt
S$109.00 = 10900
S$9.00 = 900
```

This avoids floating-point rounding bugs.

## Multi-Tenancy

Every organization has isolated accounting data.

Future accounting tables are scoped by organization ID so one company cannot see or modify another company's records.
```

---

## The Verification

Run:

```bash
pnpm check
```

The project should still pass.

---

# 13. Commit the Automated Test Setup

## The Target

We are saving the automated test work with Git.

---

## The Concept

This is a major engineering quality milestone.

The app now has automated tests protecting the journal validation rules.

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
README.md
package.json
pnpm-lock.yaml
services/journal/post-journal-entry.ts
services/journal/validate-post-journal-entry.ts
tests/journal-errors.test.ts
tests/journal-validation.test.ts
tests/money.test.ts
vitest.config.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Add automated tests for journal validation"
```

---

## The Verification

Run:

```bash
git status
```

You should see:

```txt
nothing to commit, working tree clean
```

---

# Common Errors and Fixes

## Error: Vitest cannot resolve `@/`

Check:

```txt
vitest.config.ts
```

Make sure it contains:

```ts
resolve: {
  alias: {
    "@": fileURLToPath(new URL(".", import.meta.url)),
  },
}
```

Then rerun:

```bash
pnpm test
```

---

## Error: `No test files found`

Make sure your test files are inside:

```txt
tests/
```

and end with:

```txt
.test.ts
```

Example:

```txt
tests/journal-validation.test.ts
```

---

## Error: Money formatting test fails because of locale output

Different Node environments may format currency slightly differently, though `en-SG` should usually output:

```txt
S$109.00
```

If your environment outputs a non-breaking space or slightly different currency formatting, inspect the actual output:

```ts
console.log(formatMoney(10900));
```

Then adjust the assertion carefully.

Do not weaken money tests too much; currency formatting matters.

---

## Error: `db.transaction is not a function`

This is from the runtime posting service, not the pure validation tests.

Update Drizzle and Neon packages:

```bash
pnpm add drizzle-orm@latest @neondatabase/serverless@latest
pnpm add -D drizzle-kit@latest
```

Then run:

```bash
pnpm check
```

---

## Error: `journalSourceTypeEnum.enumValues` fails in tests

Update Drizzle:

```bash
pnpm add drizzle-orm@latest
pnpm add -D drizzle-kit@latest
```

If needed, confirm `db/schema.ts` exports:

```ts
export const journalSourceTypeEnum = pgEnum(...)
```

---

## Error: `pnpm check` fails because `DATABASE_URL` is missing

The build step includes database-backed server pages.

Make sure `.env.local` contains:

```bash
DATABASE_URL="postgresql://..."
```

Vitest itself does not need the database for these pure validation tests, but `pnpm build` does.

---

# Phase 5 Reference — Testing Strategy

## Unit Test

A unit test checks a small piece of logic in isolation.

In this part, we unit-tested:

```txt
validatePostJournalEntryInput()
JournalEntryValidationError
money helpers
```

---

## Integration Test

An integration test checks multiple systems together.

For example:

```txt
Clerk + Drizzle + Neon + postJournalEntry()
```

We have not added full database integration tests yet because they require careful test database setup.

The manual test harness currently covers the real database path.

---

## Positive Test

A positive test proves valid behavior works.

Example:

```txt
A balanced owner contribution entry passes validation.
```

---

## Negative Test

A negative test proves invalid behavior is rejected.

Example:

```txt
An unbalanced journal entry fails validation.
```

---

## Why We Extracted Validation

We extracted validation so the same rules are used by:

```txt
Automated tests
Production postJournalEntry()
```

This avoids testing one version of the rules while the app uses another.

---

# Part 15 Completion Checklist

You are ready for Part 16 if:

- [ ] `vitest` is installed
- [ ] `vitest.config.ts` exists
- [ ] `package.json` includes `test` and `test:watch`
- [ ] `package.json` check script runs lint, test, and build
- [ ] `services/journal/validate-post-journal-entry.ts` exists
- [ ] `postJournalEntry()` uses `validatePostJournalEntryInput()`
- [ ] `tests/journal-validation.test.ts` exists
- [ ] Valid balanced entries pass automated tests
- [ ] Unbalanced entries fail automated tests
- [ ] Invalid line structures fail automated tests
- [ ] Invalid dates and UUIDs fail automated tests
- [ ] `tests/journal-errors.test.ts` exists
- [ ] `tests/money.test.ts` exists
- [ ] `pnpm test` succeeds
- [ ] `pnpm check` succeeds
- [ ] Manual journal test page still works
- [ ] README documents testing commands
- [ ] Changes are committed with Git
