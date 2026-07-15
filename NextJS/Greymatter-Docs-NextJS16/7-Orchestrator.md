# Part 7 — The Orchestrator (Next.js Edition)

## Building the End-to-End Automation Pipeline

> **Goal:** Build the orchestration layer that coordinates the entire document generation workflow — from retrieving data to producing finished documents — using a modular, extensible pipeline.

**Milestone:** By the end of this chapter, Greymatter Docs will process document generation jobs through a centralized orchestrator, making it easy to automate individual or batch document creation [4].

---

## THEORY & ARCHITECTURE

Every document we generate follows the same predictable sequence [4]:

```text
Receive Job
     │
     ▼
Load Customer
     │
     ▼
Load Invoice
     │
     ▼
Open Template
     │
     ▼
Replace Placeholders
     │
     ▼
Populate Tables
     │
     ▼
Save Document
```

This predictable pipeline makes debugging and maintenance much simpler [4]. Instead of calling repositories and services directly from an API route (as we've been doing in Parts 3–5), we now introduce a single `DocumentOrchestrator` that owns this entire sequence. Presentation code (our API routes) only ever talks to the orchestrator — never to repositories or the document engine directly, matching the layered principle where the presentation layer receives input, validates it, starts document generation, and returns results [1]:

```text
User
  │
  ▼
Generate Invoice (API route)
  │
  ▼
Document Orchestrator
```

We'll also introduce a `JobContext` object — a single bundle carrying every parameter a job needs (customer ID, invoice ID, output filename, timestamps, job ID) through the pipeline, instead of passing five separate arguments through every function.

---

## Step 1 — Build the `JobContext`

**src/orchestrator/jobContext.js**
```js
// src/orchestrator/jobContext.js
import crypto from "crypto";

export class JobContext {
  constructor({ customerId, invoiceId, outputFileName, overwrite = false }) {
    this.jobId = crypto.randomUUID();
    this.customerId = customerId;
    this.invoiceId = invoiceId;
    this.outputFileName = outputFileName;
    this.overwrite = overwrite;

    this.startedAt = null;
    this.finishedAt = null;
    this.status = "pending"; // pending | success | failed | skipped
    this.error = null;

    this.customer = null;
    this.invoice = null;
    this.items = null;
    this.outputPath = null;
  }

  start() {
    this.startedAt = new Date();
    this.status = "running";
  }

  succeed(outputPath) {
    this.finishedAt = new Date();
    this.status = "success";
    this.outputPath = outputPath;
  }

  fail(error) {
    this.finishedAt = new Date();
    this.status = "failed";
    this.error = error.message || String(error);
  }

  skip(reason) {
    this.finishedAt = new Date();
    this.status = "skipped";
    this.error = reason;
  }

  get durationMs() {
    if (!this.startedAt || !this.finishedAt) return null;
    return this.finishedAt.getTime() - this.startedAt.getTime();
  }
}

export default JobContext;
```

This gives every job a unique `jobId`, and tracks start/end time and total processing time automatically — directly covering the challenge lab requirements of adding a unique `job_id` and recording start/end time for each job [4].

---

## Step 2 — Build the `DocumentOrchestrator`

**src/orchestrator/documentOrchestrator.js**
```js
// src/orchestrator/documentOrchestrator.js
import fs from "fs";
import path from "path";
import { JobContext } from "@/orchestrator/jobContext";
import { customerRepository } from "@/repositories/customerRepository";
import { invoiceRepository } from "@/repositories/invoiceRepository";
import { documentEngineService } from "@/services/documentEngineService";
import { settings } from "@/config/settings";
import { logger } from "@/lib/logger";
import { RecordNotFoundError } from "@/exceptions/databaseExceptions";

export class DocumentOrchestrator {
  /**
   * Runs the full pipeline for a single invoice document job.
   * @param {object} params
   * @param {number} params.customerId
   * @param {number} params.invoiceId
   * @param {string} params.outputFileName
   * @param {boolean} [params.overwrite]
   * @returns {JobContext}
   */
  runInvoiceJob(params) {
    const job = new JobContext(params);
    job.start();

    logger.info("Job received.", { jobId: job.jobId, params });

    try {
      // Step: skip if output already exists (unless overwrite requested)
      const outputPath = path.join(settings.outputDir, job.outputFileName);
      if (fs.existsSync(outputPath) && !job.overwrite) {
        job.skip("Output file already exists and overwrite=false.");
        logger.info("Job skipped.", { jobId: job.jobId, outputPath });
        return job;
      }

      // Step: load customer
      const customer = customerRepository.getCustomerById(job.customerId);
      if (!customer) {
        throw new RecordNotFoundError(`Customer ${job.customerId} not found.`);
      }
      job.customer = customer;
      logger.info("Customer loaded.", { jobId: job.jobId, customerId: customer.id });

      // Step: load invoice
      const invoice = invoiceRepository.getInvoice(job.invoiceId);
      if (!invoice) {
        throw new RecordNotFoundError(`Invoice ${job.invoiceId} not found.`);
      }
      job.invoice = invoice;
      logger.info("Invoice loaded.", { jobId: job.jobId, invoiceId: invoice.id });

      // Step: load line items
      const items = invoiceRepository.getInvoiceItems(job.invoiceId);
      job.items = items;
      if (!items || items.length === 0) {
        logger.warn("Invoice has no line items.", { jobId: job.jobId });
      }

      // Step: open template, replace placeholders, populate tables, save
      // (all handled inside documentEngineService.generateInvoiceDocument)
      const result = documentEngineService.generateInvoiceDocument(
        customer,
        invoice,
        items,
        job.outputFileName
      );

      if (!result.success) {
        throw new Error(result.error);
      }

      job.succeed(result.outputPath);
      logger.info("Job completed.", {
        jobId: job.jobId,
        durationMs: job.durationMs,
        outputPath: result.outputPath,
      });

      return job;
    } catch (error) {
      job.fail(error);
      logger.error("Job failed.", {
        jobId: job.jobId,
        durationMs: job.durationMs,
        error: job.error,
      });
      return job;
    }
  }

  /**
   * Runs multiple jobs in sequence, isolating failures so one bad job
   * doesn't stop the rest of the batch.
   * @param {Array<object>} jobParamsList
   * @returns {{jobs: JobContext[], summary: object}}
   */
  runBatch(jobParamsList) {
    const jobs = jobParamsList.map((params) => this.runInvoiceJob(params));

    const summary = {
      totalJobs: jobs.length,
      successful: jobs.filter((j) => j.status === "success").length,
      failed: jobs.filter((j) => j.status === "failed").length,
      skipped: jobs.filter((j) => j.status === "skipped").length,
      totalExecutionMs: jobs.reduce((sum, j) => sum + (j.durationMs || 0), 0),
    };

    logger.info("Batch complete.", summary);

    return { jobs, summary };
  }
}

export const documentOrchestrator = new DocumentOrchestrator();
export default documentOrchestrator;
```

Notice the batch summary already covers the challenge lab's request for a report showing total jobs processed, successful jobs, failed jobs, and total execution time [4] — and each job is wrapped in its own try/catch so one failure never stops the rest of the batch, exactly the fault-isolation principle needed for reliable batch processing [4].

---

## Step 3 — Rewire the API Routes to Use the Orchestrator

**src/app/api/generate-invoice/route.js** (replaces the Part 5 version)
```js
// src/app/api/generate-invoice/route.js
import { NextResponse } from "next/server";
import { documentOrchestrator } from "@/orchestrator/documentOrchestrator";

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const customerId = Number(searchParams.get("customerId") || "1");
  const invoiceId = Number(searchParams.get("invoiceId") || "1");
  const overwrite = searchParams.get("overwrite") === "true";

  const job = documentOrchestrator.runInvoiceJob({
    customerId,
    invoiceId,
    outputFileName: `invoice_${invoiceId}.docx`,
    overwrite,
  });

  const statusCode = job.status === "failed" ? 500 : 200;

  return NextResponse.json(
    {
      jobId: job.jobId,
      status: job.status,
      durationMs: job.durationMs,
      outputPath: job.outputPath,
      error: job.error,
    },
    { status: statusCode }
  );
}
```

**src/app/api/generate-batch/route.js** (replaces the Part 4 version)
```js
// src/app/api/generate-batch/route.js
import { NextResponse } from "next/server";
import { documentOrchestrator } from "@/orchestrator/documentOrchestrator";

export async function POST(request) {
  const body = await request.json();
  // Expects: { jobs: [{ customerId, invoiceId, outputFileName, overwrite }, ...] }

  const { jobs, summary } = documentOrchestrator.runBatch(body.jobs);

  return NextResponse.json({
    summary,
    jobs: jobs.map((j) => ({
      jobId: j.jobId,
      status: j.status,
      durationMs: j.durationMs,
      outputPath: j.outputPath,
      error: j.error,
    })),
  });
}
```

Test the single-job route:
```text
http://localhost:3000/api/generate-invoice?customerId=1&invoiceId=1
```

Run it twice — the second run should return `status: "skipped"` since the output file already exists, unless you add `&overwrite=true`.

Test the batch route with a POST request body like:

```json
{
  "jobs": [
    { "customerId": 1, "invoiceId": 1, "outputFileName": "invoice_1.docx" },
    { "customerId": 1, "invoiceId": 2, "outputFileName": "invoice_2.docx" },
    { "customerId": 999, "invoiceId": 1, "outputFileName": "invoice_bad.docx" }
  ]
}
```

The third job (invalid customer ID) should fail and appear in the summary as a failed job, while the first two jobs succeed independently. This is exactly the fault-isolation behavior we're aiming for — one failed job does not stop the queue, every failure is logged, and successful jobs continue processing. You should see a JSON response shaped like:

```json
{
  "summary": {
    "totalJobs": 3,
    "successful": 2,
    "failed": 1,
    "skipped": 0,
    "totalExecutionMs": 42
  },
  "jobs": [
    { "jobId": "...", "status": "success", "durationMs": 15, "outputPath": "...", "error": null },
    { "jobId": "...", "status": "success", "durationMs": 14, "outputPath": "...", "error": null },
    { "jobId": "...", "status": "failed", "durationMs": 3, "outputPath": null, "error": "Customer 999 not found." }
  ]
}
```

Check `logs/errors.log` — the failed job's error should appear there with its `jobId`, while `logs/app.log` should show clear entries logged before and after each major processing step (job received, customer loaded, invoice loaded, job completed/failed), which directly addresses the concern that logs are difficult to follow without clear log messages before and after each major processing step [4].

---

## CHALLENGE LAB

1. Add a check in `runInvoiceJob()` that verifies the output file doesn't already exist before saving, unless `overwrite` is explicitly `true` — this guards against the output file being overwritten unintentionally [4].
2. Add validation to `JobContext` construction so a `ValidationError` (from Part 6) is thrown immediately if `customerId` or `invoiceId` is missing — catching bad configuration early rather than deep inside the pipeline, similar to how incorrect job configuration causes wrong customer data to appear in a document if not verified upfront [4].
3. Extend `runBatch()` to accept an optional `stopOnFirstFailure` flag for cases where fault isolation should be disabled.
4. Add a `getJobReport(job)` helper that formats a single job's result as a human-readable summary line, e.g. `Job a1b2c3 — SUCCESS in 42ms → invoice_1.docx`.
5. Persist each job's result to a `job_history` table so past runs can be queried later (a preview of the reporting work in Part 9).

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| Pipeline stops after one failure | Jobs aren't isolated from each other | Confirm each job runs inside its own try/catch inside `runInvoiceJob()`, not a shared block wrapping the whole batch [4] |
| Wrong customer data appears in a document | Incorrect job configuration | Verify the `customerId` and `invoiceId` values passed into `JobContext` [4] |
| Output file overwritten unintentionally | No overwrite check performed | Verify whether the output file exists before saving, and respect the `overwrite` flag [4] |
| Logs are difficult to follow | Insufficient pipeline logging | Add clear log messages before and after each major processing step (customer loaded, invoice loaded, job completed) [4] |
| `job.customerId`/`job.invoiceId` undefined | `JobContext` constructed with missing or mismatched fields | Ensure the object passed into `JobContext` matches the required job attributes exactly [4] |

---

## Chapter Summary

In this chapter, you:

* Built a `JobContext` class that bundles all parameters a job needs, tracks status (pending/running/success/failed/skipped), and records start/end time and total duration
* Built a `DocumentOrchestrator` that owns the entire pipeline: receive job → load customer → load invoice → open template → replace placeholders → populate tables → save document
* Implemented fault isolation so a single failed job never stops the rest of a batch — every failure is logged, and successful jobs continue processing [4]
* Added a batch summary report showing total jobs, successful, failed, skipped, and total execution time
* Rewired API routes so presentation code only ever talks to the orchestrator, never directly to repositories or the document engine

This completes the milestone of an end-to-end automation pipeline [13]. **Next: Part 8 — Output & Delivery**, where we take generated documents further: exporting PDFs, queuing delivery jobs, sending emails, and tracking delivery status through PENDING, SENT, and FAILED states [3].
