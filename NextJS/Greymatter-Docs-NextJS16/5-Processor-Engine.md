# Part 5 — The Processor Engine (Next.js Edition)

## Dynamic Tables and Repeating Data

> **Goal:** Expand Greymatter Docs beyond single-record letters into full business documents — invoices with dynamic line-item tables that grow or shrink based on live data, without ever touching the template file itself.

**Milestone:** By the end of this chapter, Greymatter Docs generates documents combining single-value placeholders with dynamic tabular data, marking the transition from basic document automation into a true document generation platform.

---

## THEORY & ARCHITECTURE

Up to now, our templates have only handled one-to-one placeholder replacement — one value in, one value out. Real business documents need something more: tables with a variable number of rows, like invoice line items, where the same row structure repeats however many times the data requires.

The key idea is **dynamic row creation**. Instead of designing a template with, say, 100 empty rows to cover every possible case, we create only one sample row, and the processor duplicates it as needed. If the database contains 3 records, the generated document gets 3 rows. If it contains 50 records, it gets 50 rows. The template itself never changes — only the data driving it does.

This is Layer 4 of our architecture in action: Template Loader → Placeholder Processor → **Table Processor** → Document Processor. The Table Processor's job is specifically to populate dynamic tables with repeating data.

### Our JS Equivalent: `docxtemplater` Loops

Instead of manually duplicating table rows via a document object model, `docxtemplater` (which we already installed in Part 1) supports **loop tags** natively: `{#items}...{/items}`. When placed inside a table row, everything between the tags repeats once per array item automatically — this is our direct equivalent of dynamic row creation.

---

## Step 1 — Expand the Database Schema

We need invoices and line items. Add these tables alongside the `customers` table from Part 2.

**src/database/schema.sql** (append to the existing file)
```sql
CREATE TABLE IF NOT EXISTS invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  invoice_number TEXT NOT NULL,
  invoice_date TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE IF NOT EXISTS invoice_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id)
);
```

Run your existing seed process (or re-run `initSchema()`) to apply this.

---

## Step 2 — Seed Sample Invoice Data

**src/database/seedInvoices.js**
```js
// src/database/seedInvoices.js
import { dbManager } from "@/database/database";
import { logger } from "@/lib/logger";

function seedInvoices() {
  dbManager.initSchema();
  const db = dbManager.getConnection();

  const existing = db.prepare("SELECT COUNT(*) AS count FROM invoices").get();
  if (existing.count > 0) {
    logger.info("Invoices already seeded, skipping.");
    return;
  }

  const insertInvoice = db.prepare(`
    INSERT INTO invoices (customer_id, invoice_number, invoice_date)
    VALUES (@customer_id, @invoice_number, @invoice_date)
  `);

  const insertItem = db.prepare(`
    INSERT INTO invoice_items (invoice_id, description, quantity, unit_price)
    VALUES (@invoice_id, @description, @quantity, @unit_price)
  `);

  const seedTransaction = db.transaction(() => {
    const invoiceId = insertInvoice.run({
      customer_id: 1,
      invoice_number: "INV-1001",
      invoice_date: "2025-01-15",
    }).lastInsertRowid;

    const items = [
      { description: "Web Development", quantity: 10, unit_price: 85 },
      { description: "UI/UX Design", quantity: 5, unit_price: 95 },
      { description: "Server Setup", quantity: 2, unit_price: 150 },
    ];

    items.forEach((item) => {
      insertItem.run({ invoice_id: invoiceId, ...item });
    });
  });

  seedTransaction();
  logger.info("Seeded invoices and invoice_items.");
}

seedInvoices();
```

Run it:
```bash
node src/database/seedInvoices.js
```

---

## Step 3 — Build the `InvoiceRepository`

Following the same Repository pattern as `CustomerRepository` in Part 2.

**src/repositories/invoiceRepository.js**
```js
// src/repositories/invoiceRepository.js
import { dbManager } from "@/database/database";
import { logger } from "@/lib/logger";

export class InvoiceRepository {
  getInvoice(invoiceId) {
    try {
      const db = dbManager.getConnection();
      const stmt = db.prepare("SELECT * FROM invoices WHERE id = ?");
      return stmt.get(invoiceId);
    } catch (error) {
      logger.error("Failed to fetch invoice.", { invoiceId, error: error.message });
      throw error;
    }
  }

  getInvoiceItems(invoiceId) {
    try {
      const db = dbManager.getConnection();
      const stmt = db.prepare("SELECT * FROM invoice_items WHERE invoice_id = ?");
      return stmt.all(invoiceId);
    } catch (error) {
      logger.error("Failed to fetch invoice items.", { invoiceId, error: error.message });
      throw error;
    }
  }

  createInvoice(invoice, items) {
    try {
      const db = dbManager.getConnection();
      const insertInvoice = db.prepare(`
        INSERT INTO invoices (customer_id, invoice_number, invoice_date)
        VALUES (@customer_id, @invoice_number, @invoice_date)
      `);
      const insertItem = db.prepare(`
        INSERT INTO invoice_items (invoice_id, description, quantity, unit_price)
        VALUES (@invoice_id, @description, @quantity, @unit_price)
      `);

      const runAll = db.transaction(() => {
        const invoiceId = insertInvoice.run(invoice).lastInsertRowid;
        items.forEach((item) => insertItem.run({ invoice_id: invoiceId, ...item }));
        return invoiceId;
      });

      return runAll();
    } catch (error) {
      logger.error("Failed to create invoice.", { error: error.message });
      throw error;
    }
  }
}

export const invoiceRepository = new InvoiceRepository();
export default invoiceRepository;
```

---

## Step 4 — Design the Invoice Template

Create a new `.docx` file with standard placeholders **plus** a table containing a `docxtemplater` loop.

Save as `templates/invoice.docx`:

```text
Invoice Number: {{invoice_number}}
Invoice Date: {{invoice_date}}

Customer: {{first_name}} {{last_name}}
Company: {{company}}
```

Then insert a table with a header row and exactly **one** body row using loop tags:

| Description | Quantity | Unit Price | Total |
|---|---|---|---|
| {{#items}}{{description}} | {{quantity}} | {{unit_price}} | {{line_total}}{{/items}} |

The `{{#items}}` tag goes in the first cell of the body row, and `{{/items}}` goes in the last cell of the *same* row — `docxtemplater` recognizes this as a loop spanning the whole row and repeats the entire row once per item in the `items` array automatically.

---

## Step 5 — Build the `TableProcessor`

This module prepares invoice items for the loop — including calculating each line's total — before handing everything to `docxtemplater`.

**src/processor/tableProcessor.js**
```js
// src/processor/tableProcessor.js
import { logger } from "@/lib/logger";

export class TableProcessor {
  /**
   * Prepares invoice line items for template rendering, calculating
   * each row's total and the overall invoice total.
   * @param {Array<{description:string, quantity:number, unit_price:number}>} items
   */
  prepareItems(items) {
    try {
      const preparedItems = items.map((item) => ({
        ...item,
        line_total: (item.quantity * item.unit_price).toFixed(2),
      }));

      const invoiceTotal = preparedItems
        .reduce((sum, item) => sum + Number(item.line_total), 0)
        .toFixed(2);

      logger.info("Table data prepared.", {
        rowCount: preparedItems.length,
        invoiceTotal,
      });

      return { items: preparedItems, invoice_total: invoiceTotal };
    } catch (error) {
      logger.error("Failed to prepare table data.", { error: error.message });
      throw error;
    }
  }
}

export const tableProcessor = new TableProcessor();
export default tableProcessor;
```

The template never needs to change regardless of whether there are 3 line items or 50 — `docxtemplater`'s loop handles the row duplication, and our `TableProcessor` handles the math.

---

## Step 6 — Wire It Into the Document Engine Service

Extend the `DocumentEngineService` from Part 4 with an invoice-specific method that combines placeholders and table data.

**src/services/documentEngineService.js** (add this method to the existing class)
```js
  generateInvoiceDocument(customer, invoice, items, outputFileName) {
    if (!this.connected) {
      this.connect();
    }

    try {
      const tableData = tableProcessor.prepareItems(items);

      const values = this._withGeneratedFields({
        ...customer,
        ...invoice,
        ...tableData,
      });

      const buffer = templateProcessor.render("invoice.docx", values);

      this._lastDocumentModified = buffer && buffer.length > 0;

      if (!fs.existsSync(settings.outputDir)) {
        fs.mkdirSync(settings.outputDir, { recursive: true });
      }

      const outputPath = path.join(settings.outputDir, outputFileName);
      fs.writeFileSync(outputPath, buffer);

      logger.info("Invoice document generated.", {
        outputPath,
        rowCount: items.length,
      });

      return { success: true, outputPath, modified: this._lastDocumentModified };
    } catch (error) {
      logger.error("Invoice generation failed.", { error: error.message });
      return { success: false, error: error.message };
    }
  }
```

Add the import at the top of the file:
```js
import { tableProcessor } from "@/processor/tableProcessor";
```

---

## Step 7 — Verify With an API Route

**src/app/api/generate-invoice/route.js**
```js
// src/app/api/generate-invoice/route.js
import { NextResponse } from "next/server";
import { customerRepository } from "@/repositories/customerRepository";
import { invoiceRepository } from "@/repositories/invoiceRepository";
import { documentEngineService } from "@/services/documentEngineService";
import { logger } from "@/lib/logger";

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const invoiceId = Number(searchParams.get("invoiceId") || "1");

  try {
    const invoice = invoiceRepository.getInvoice(invoiceId);
    if (!invoice) {
      return NextResponse.json({ error: "Invoice not found." }, { status: 404 });
    }

    const customer = customerRepository.getCustomerById(invoice.customer_id);
    if (!customer) {
      return NextResponse.json({ error: "Customer not found." }, { status: 404 });
    }

    const items = invoiceRepository.getInvoiceItems(invoiceId);
    if (!items || items.length === 0) {
      logger.warn("Invoice has no line items.", { invoiceId });
    }

    const outputFileName = `invoice_${invoice.invoice_number}.docx`;

    const result = documentEngineService.generateInvoiceDocument(
      customer,
      invoice,
      items,
      outputFileName
    );

    if (!result.success) {
      return NextResponse.json({ error: result.error }, { status: 500 });
    }

    logger.info("Invoice document request complete.", {
      invoiceId,
      outputFileName,
    });

    return NextResponse.json({
      status: "ok",
      file: outputFileName,
      rowCount: items.length,
    });
  } catch (error) {
    logger.error("Invoice generation request failed.", { error: error.message });
    return NextResponse.json({ error: "Invoice generation failed." }, { status: 500 });
  }
}
```

Run the dev server and visit:

```text
http://localhost:3000/api/generate-invoice?invoiceId=1
```

Open `output/invoice_INV-1001.docx` — you should see the customer's name and company filled in from placeholders, plus a table with three line-item rows, each with a calculated `line_total`, matching the three items seeded in Step 2. Try adding a fourth or fifth item to the `invoice_items` table and regenerating — the row count in the document should grow automatically, with no template changes required.

---

## CHALLENGE LAB

1. Add a `{{invoice_total}}` placeholder outside the table (in the closing section of the template) and confirm the `TableProcessor`'s calculated total appears correctly.
2. Add a `tax_rate` field and extend `TableProcessor.prepareItems()` to calculate a `tax_amount` and `grand_total`.
3. Create a second invoice (`invoice_id = 2`) with a *different* number of line items (e.g., 5 instead of 3) and confirm the table grows correctly with zero template changes.
4. Add validation: if `items` is empty, log a warning and skip document generation instead of producing a blank table.
5. Extend `InvoiceRepository.createInvoice()` so it can be called from a new API route to create invoices via a POST request instead of only through the seed script.

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| Table remains empty | The `{{#items}}`/`{{/items}}` tags weren't placed correctly across the row, or `items` array is empty | Verify the loop tags span the full row correctly and confirm `invoiceRepository.getInvoiceItems()` returns data [6] |
| Only one row appears regardless of data | Loop tags aren't recognized because the row was manually duplicated instead of using `{{#items}}` | Keep only one template row and let `docxtemplater`'s loop handle duplication, matching the same principle of leaving one template row and letting the processor insert new ones [6] |
| Calculated totals are incorrect | Numeric values weren't coerced properly before math | Ensure `quantity` and `unit_price` are treated as numbers in `prepareItems()`, not strings [6] |
| `docxtemplater` throws a tag mismatch error | `{{#items}}` and `{{/items}}` don't match (e.g., one was mistyped) | Check both tags exactly, including matching case and spelling |

---

## Chapter Summary

In this chapter, you:

* Expanded the database schema with `invoices` and `invoice_items` tables, related to `customers` in a one-to-many-to-many structure [6]
* Built an `InvoiceRepository` following the same Repository pattern as `CustomerRepository`
* Designed an invoice template combining static placeholders with a dynamic, repeating table using `docxtemplater`'s loop syntax
* Built a `TableProcessor` that calculates line totals and an invoice grand total before rendering
* Extended `DocumentEngineService` with a `generateInvoiceDocument()` method
* Verified that the same template correctly handles any number of line items without modification

**Next: Part 6 — Production Mechanics**, where we transform Greymatter Docs into a production-ready application with structured logging, centralized configuration, a custom exception hierarchy, and consistent validation across every module [5].
