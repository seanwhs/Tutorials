# Part 8 — Output & Delivery (Next.js Edition)

## PDF Export, Email Delivery, and Delivery Status Tracking

> **Goal:** Extend Greymatter Docs so generated documents can be exported to PDF, queued for delivery, emailed to recipients, and tracked through their delivery lifecycle.

**Milestone:** By the end of this chapter, Greymatter Docs will support PDF generation and email delivery working end-to-end [13].

---

## THEORY & ARCHITECTURE

The output and delivery stage follows a clear, independent-stage workflow: generate the document, export it to PDF, create a delivery job, send the email, and update the delivery status [3]. Each stage is independent, making it easier to recover from failures [3] — if email sending fails, we don't need to regenerate the document; we just retry the delivery step.

```text
Generate Document
        │
        ▼
Export PDF
        │
        ▼
Create Delivery Job
        │
        ▼
Send Email
        │
        ▼
Update Delivery Status
```

Delivery jobs move through three states, matching the original status model exactly [3]:

| Status | Meaning |
|---|---|
| PENDING | Waiting for delivery |
| SENT | Successfully delivered |
| FAILED | Delivery failed |

In our Next.js version, "Export PDF" happens via a JS-native conversion library instead of the original's document-engine export filter, and "Send Email" uses `nodemailer` (installed back in Part 1) instead of Python's `smtplib`.

---

## Step 1 — Add a `delivery_queue` Table

**src/database/schema.sql** (append)
```sql
CREATE TABLE IF NOT EXISTS delivery_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id TEXT NOT NULL,
  customer_id INTEGER NOT NULL,
  recipient_email TEXT NOT NULL,
  pdf_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING',
  error_message TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);
```

---

## Step 2 — Install PDF Conversion Dependencies

```bash
npm install docx-pdf
```

We'll use `docx-pdf`, a pure Node.js wrapper that converts `.docx` buffers to PDF without needing an external desktop application installed on the server — keeping this deployable on Vercel's serverless functions.

---

## Step 3 — Build a `PdfService`

**src/services/pdfService.js**
```js
// src/services/pdfService.js
import fs from "fs";
import path from "path";
import docxToPdf from "docx-pdf";
import { settings } from "@/config/settings";
import { logger } from "@/lib/logger";

export class PdfService {
  /**
   * Converts a .docx file already saved in output/ to a PDF in the same folder.
   * @param {string} docxFileName - e.g. "invoice_1.docx"
   * @returns {Promise<string>} path to the generated PDF
   */
  convertToPdf(docxFileName) {
    return new Promise((resolve, reject) => {
      const inputPath = path.join(settings.outputDir, docxFileName);
      const outputPath = inputPath.replace(/\.docx$/, ".pdf");

      if (!fs.existsSync(inputPath)) {
        const message = `Cannot export PDF, source file not found: ${inputPath}`;
        logger.error(message);
        return reject(new Error(message));
      }

      docxToPdf(inputPath, outputPath, (error) => {
        if (error) {
          logger.error("PDF export failed.", { inputPath, error: error.message });
          return reject(new Error("Unable to export PDF."));
        }

        logger.info("PDF exported.", { outputPath });
        resolve(outputPath);
      });
    });
  }
}

export const pdfService = new PdfService();
export default pdfService;
```

---

## Step 4 — Build the `SmtpService`

This is the direct JS equivalent of the original's `SmtpService`, which builds an email message, attaches the PDF, sends it, and logs delivery — raising a clear error instead of letting a raw exception escape [3].

**src/services/smtpService.js**
```js
// src/services/smtpService.js
import nodemailer from "nodemailer";
import fs from "fs";
import path from "path";
import { logger } from "@/lib/logger";

const SMTP_SERVER = process.env.SMTP_SERVER;
const SMTP_PORT = Number(process.env.SMTP_PORT || 587);
const SMTP_USERNAME = process.env.SMTP_USERNAME;
const SMTP_PASSWORD = process.env.SMTP_PASSWORD;
const SMTP_SENDER = process.env.SMTP_SENDER;

export class SmtpService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      host: SMTP_SERVER,
      port: SMTP_PORT,
      secure: false,
      auth: {
        user: SMTP_USERNAME,
        pass: SMTP_PASSWORD,
      },
    });
  }

  /**
   * Sends an email with a PDF attachment.
   * @param {string} recipient
   * @param {string} subject
   * @param {string} body
   * @param {string} attachmentPath
   */
  async sendEmail(recipient, subject, body, attachmentPath) {
    try {
      const fileBuffer = fs.readFileSync(attachmentPath);

      await this.transporter.sendMail({
        from: SMTP_SENDER,
        to: recipient,
        subject,
        text: body,
        attachments: [
          {
            filename: path.basename(attachmentPath),
            content: fileBuffer,
            contentType: "application/pdf",
          },
        ],
      });

      logger.info("Email delivered.", { recipient });
    } catch (error) {
      logger.error("Email delivery failed.", {
        recipient,
        error: error.message,
      });
      throw new Error("Unable to send email.");
    }
  }
}

export const smtpService = new SmtpService();
export default smtpService;
```

Add the required environment variables to `.env.local`:
```text
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-username
SMTP_PASSWORD=your-password
SMTP_SENDER=noreply@example.com
```

---

## Step 5 — Build the `DeliveryRepository`

Following the same Repository pattern established in Parts 2 and 5.

**src/repositories/deliveryRepository.js**
```js
// src/repositories/deliveryRepository.js
import { dbManager } from "@/database/database";
import { logger } from "@/lib/logger";

export class DeliveryRepository {
  createDeliveryJob({ jobId, customerId, recipientEmail, pdfPath }) {
    const db = dbManager.getConnection();
    const stmt = db.prepare(`
      INSERT INTO delivery_queue (job_id, customer_id, recipient_email, pdf_path, status)
      VALUES (@jobId, @customerId, @recipientEmail, @pdfPath, 'PENDING')
    `);
    const result = stmt.run({ jobId, customerId, recipientEmail, pdfPath });
    logger.info("Delivery job created.", { deliveryId: result.lastInsertRowid });
    return result.lastInsertRowid;
  }

  updateStatus(deliveryId, status, errorMessage = null) {
    const db = dbManager.getConnection();
    const stmt = db.prepare(`
      UPDATE delivery_queue
      SET status = @status, error_message = @errorMessage, updated_at = CURRENT_TIMESTAMP
      WHERE id = @deliveryId
    `);
    stmt.run({ deliveryId, status, errorMessage });
    logger.info("Delivery status updated.", { deliveryId, status });
  }

  getPendingDeliveries() {
    const db = dbManager.getConnection();
    return db.prepare("SELECT * FROM delivery_queue WHERE status = 'PENDING'").all();
  }
}

export const deliveryRepository = new DeliveryRepository();
export default deliveryRepository;
```

---

## Step 6 — Extend the Orchestrator to Handle Delivery

Add a new method to `DocumentOrchestrator` (Part 7) that chains document generation → PDF export → delivery queue → email send → status update, keeping each stage independent so a failure at one stage doesn't require redoing previous stages [3].

**src/orchestrator/documentOrchestrator.js** (add this method)
```js
import { pdfService } from "@/services/pdfService";
import { smtpService } from "@/services/smtpService";
import { deliveryRepository } from "@/repositories/deliveryRepository";

  async runDeliveryJob(params) {
    const job = this.runInvoiceJob(params);

    if (job.status !== "success") {
      logger.warn("Skipping delivery, document generation did not succeed.", {
        jobId: job.jobId,
      });
      return job;
    }

    let deliveryId;

    try {
      // Stage: export PDF
      const pdfPath = await pdfService.convertToPdf(job.outputFileName);

      // Stage: create delivery job (PENDING)
      deliveryId = deliveryRepository.createDeliveryJob({
        jobId: job.jobId,
        customerId: job.customer.id,
        recipientEmail: job.customer.email,
        pdfPath,
      });

      // Stage: send email
      await smtpService.sendEmail(
        job.customer.email,
        `Your Invoice ${job.invoice.invoice_number}`,
        `Dear ${job.customer.first_name}, please find your invoice attached.`,
        pdfPath
      );

      // Stage: update status to SENT
      deliveryRepository.updateStatus(deliveryId, "SENT");

      job.deliveryStatus = "SENT";
      logger.info("Delivery completed.", { jobId: job.jobId, deliveryId });
    } catch (error) {
      if (deliveryId) {
        deliveryRepository.updateStatus(deliveryId, "FAILED", error.message);
      }
      job.deliveryStatus = "FAILED";
      job.deliveryError = error.message;
      logger.error("Delivery failed.", { jobId: job.jobId, error: error.message });
    }

    return job;
  }
```

---

## Step 7 — Verify With an API Route

**src/app/api/deliver-invoice/route.js**
```js
// src/app/api/deliver-invoice/route.js
import { NextResponse } from "next/server";
import { documentOrchestrator } from "@/orchestrator/documentOrchestrator";

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const customerId = Number(searchParams.get("customerId") || "1");
  const invoiceId = Number(searchParams.get("invoiceId") || "1");

  const job = await documentOrchestrator.runDeliveryJob({
    customerId,
    invoiceId,
    outputFileName: `invoice_${invoiceId}.docx`,
    overwrite: true,
  });

  return NextResponse.json({
    jobId: job.jobId,
    status: job.status,
    deliveryStatus: job.deliveryStatus,
    deliveryError: job.deliveryError || null,
  });
}
```

Visit:

```text
http://localhost:3000/api/deliver-invoice?customerId=1&invoiceId=1
```

should return a JSON response like:

```json
{
  "jobId": "a1b2c3d4-...",
  "status": "success",
  "deliveryStatus": "SENT",
  "deliveryError": null
}
```

Check the `delivery_queue` table — you should see a row with `status = 'SENT'`, along with the `pdf_path` pointing to the exported PDF. Check your inbox (or a tool like Mailtrap/Ethereal for testing) — the customer's email should have arrived with the invoice PDF attached.

To confirm failure handling works correctly, try an invalid SMTP configuration temporarily (e.g., wrong password in `.env.local`) and re-run the request. You should see:

```json
{
  "jobId": "e5f6g7h8-...",
  "status": "success",
  "deliveryStatus": "FAILED",
  "deliveryError": "Unable to send email."
}
```

Notice that `status` (document generation) still shows `"success"` — the document was generated fine — while `deliveryStatus` shows `"FAILED"` independently. This is exactly the point of treating each stage as independent: a delivery failure doesn't mean document generation failed, and if email sending fails, we don't need to regenerate the document, only retry the delivery step.

Check the `delivery_queue` table again — the row should now show `status = 'FAILED'` along with the `error_message` populated, giving you a retryable record instead of a lost job.

---

## CHALLENGE LAB

1. Build a `/api/retry-delivery` route that reads all `FAILED` rows from `delivery_queue`, re-attempts `smtpService.sendEmail()` using the stored `pdf_path`, and updates status back to `SENT` on success — this is the natural next step once failed deliveries are preserved instead of lost.
2. Add a `/api/delivery-status` route that returns all rows from `delivery_queue`, so administrators can monitor queue status without querying the database directly.
3. Extend `PdfService` to delete the intermediate `.docx` file after successful PDF conversion, keeping the output folder lean.
4. Add a `sentAt` timestamp update alongside the `SENT` status change in `DeliveryRepository.updateStatus()`.
5. Add a maximum retry count column (`retry_count`) to `delivery_queue`, and stop retrying a delivery job after 3 failed attempts, marking it `FAILED_PERMANENT` instead.

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| PDF conversion fails silently | `docx-pdf` couldn't locate the source `.docx` file | Confirm the file exists in `output/` before calling `convertToPdf()` |
| Email never arrives | Incorrect SMTP credentials or blocked port | Double-check `.env.local` values; test with a service like Ethereal or Mailtrap first |
| `delivery_queue` row stuck on `PENDING` | Error thrown before `createDeliveryJob()` ran, or process crashed mid-flow | Check `logs/errors.log` for the stage that failed; ensure `deliveryId` is only referenced after creation |
| Attachment appears corrupted in the received email | PDF buffer read incorrectly, or wrong `contentType` | Confirm `fs.readFileSync(attachmentPath)` runs after the PDF file is fully written to disk |
| Delivery marked `SENT` but customer never received it | Email may have landed in spam, or `SMTP_SENDER` domain isn't properly authenticated | Verify SMTP provider setup (SPF/DKIM) — this is an infrastructure concern outside the app itself |

---

## Chapter Summary

In this chapter, you:

* Added a `delivery_queue` table to track document delivery through PENDING, SENT, and FAILED states
* Built a `PdfService` to convert generated `.docx` documents into PDF using a pure Node.js library
* Built an `SmtpService` using `nodemailer` to send emails with PDF attachments
* Built a `DeliveryRepository` following the same Repository pattern used throughout the series
* Extended the `DocumentOrchestrator` with a `runDeliveryJob()` method that chains document generation → PDF export → delivery queue creation → email send → status update, keeping each stage independent so failures can be retried without redoing previous stages
* Verified the full flow end-to-end, including confirming that a delivery failure doesn't affect the success status of document generation itself

**Next: Part 9 — Polish**, where we build a `BatchProcessor` for high-volume runs, add real-time progress monitoring (e.g., "Progress: 73/500 (14.6%)"), measure execution performance, and generate execution reports summarizing batch results.
