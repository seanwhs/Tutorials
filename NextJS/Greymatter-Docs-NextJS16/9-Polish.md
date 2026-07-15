# Part 9 — Professional Polish (Next.js Edition)

## Batch Processing, Progress Monitoring, and Execution Reports

> **Goal:** Add batch processing, progress reporting, performance optimizations, and operational enhancements that prepare Greymatter Docs for high-volume document generation [3].

**Milestone:** By the end of this chapter, Greymatter Docs will support batch processing and performance improvements [13].

---

## THEORY & ARCHITECTURE

Up to now, our `DocumentOrchestrator` runs one job at a time (or a small array of jobs via `runBatch()`). For high-volume document generation, we need a dedicated component whose job is to run many documents reliably, report progress as it goes, and hand back detailed statistics when finished.

The `BatchProcessor` becomes the single entry point for high-volume document generation, with responsibilities including: executing jobs, handling failures, updating progress, measuring performance, and returning execution statistics [2]. This keeps orchestration focused on document generation rather than operational concerns [2] — the `DocumentOrchestrator` still owns *how* a single document gets built, while `BatchProcessor` owns *how many, how fast, and with what visibility*.

```text
BatchProcessor
     │
     ▼
DocumentOrchestrator (per job)
     │
     ▼
ProgressMonitor ── reports progress as jobs complete
     │
     ▼
Execution Report (TXT / CSV / JSON)
```

The `ProgressMonitor` provides immediate visibility into long-running operations. Instead of wondering whether the application is still active, users can see something like:

```text
Progress: 73/500 (14.6%)
```

This is especially valuable when processing large batches [2].

---

## Step 1 — Build the `ProgressMonitor`

**src/orchestrator/progressMonitor.js**
```js
// src/orchestrator/progressMonitor.js
import { logger } from "@/lib/logger";

export class ProgressMonitor {
  constructor(total) {
    this.total = total;
    this.completed = 0;
    this.startedAt = Date.now();
  }

  increment() {
    this.completed += 1;
    this._report();
  }

  _report() {
    const percent = ((this.completed / this.total) * 100).toFixed(1);
    logger.info(`Progress: ${this.completed}/${this.total} (${percent}%)`);
  }

  /**
   * Estimated time remaining, based on average time per completed job.
   * Directly addresses the challenge lab request to add an ETA to the
   * progress monitor.
   */
  getEta() {
    if (this.completed === 0) return null;
    const elapsedMs = Date.now() - this.startedAt;
    const avgMsPerJob = elapsedMs / this.completed;
    const remainingJobs = this.total - this.completed;
    return Math.round(avgMsPerJob * remainingJobs);
  }

  getSummary() {
    return {
      total: this.total,
      completed: this.completed,
      percent: Number(((this.completed / this.total) * 100).toFixed(1)),
      etaMs: this.getEta(),
    };
  }
}

export default ProgressMonitor;
```

---

## Step 2 — Build the `BatchProcessor`

This wraps our existing `DocumentOrchestrator` (Part 7), adding progress tracking, per-job timing, duplicate-job skipping, and configurable batch sizing with pause intervals — covering the challenge lab items directly [2].

**src/orchestrator/batchProcessor.js**
```js
// src/orchestrator/batchProcessor.js
import { documentOrchestrator } from "@/orchestrator/documentOrchestrator";
import { ProgressMonitor } from "@/orchestrator/progressMonitor";
import { logger } from "@/lib/logger";

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export class BatchProcessor {
  /**
   * @param {Array<object>} jobParamsList
   * @param {object} [options]
   * @param {number} [options.batchSize] - jobs per chunk before pausing
   * @param {number} [options.pauseMs] - pause duration between chunks
   */
  async run(jobParamsList, options = {}) {
    const { batchSize = jobParamsList.length, pauseMs = 0 } = options;

    // Skip duplicate jobs within the same batch (same customerId + invoiceId)
    const seen = new Set();
    const dedupedJobs = jobParamsList.filter((params) => {
      const key = `${params.customerId}-${params.invoiceId}`;
      if (seen.has(key)) {
        logger.warn("Duplicate job skipped within batch.", { key });
        return false;
      }
      seen.add(key);
      return true;
    });

    const progress = new ProgressMonitor(dedupedJobs.length);
    const jobResults = [];
    const startedAt = Date.now();

    for (let i = 0; i < dedupedJobs.length; i += batchSize) {
      const chunk = dedupedJobs.slice(i, i + batchSize);

      for (const params of chunk) {
        const jobStart = Date.now();
        const job = documentOrchestrator.runInvoiceJob(params);
        const jobDurationMs = Date.now() - jobStart;

        jobResults.push({
          jobId: job.jobId,
          status: job.status,
          durationMs: jobDurationMs,
          outputPath: job.outputPath,
          error: job.error,
        });

        progress.increment();
      }

      // Pause between batches, unless this was the final chunk
      if (pauseMs > 0 && i + batchSize < dedupedJobs.length) {
        logger.info("Pausing between batches.", { pauseMs });
        await sleep(pauseMs);
      }
    }

    const totalExecutionMs = Date.now() - startedAt;

    const summary = {
      totalJobs: jobResults.length,
      successful: jobResults.filter((j) => j.status === "success").length,
      failed: jobResults.filter((j) => j.status === "failed").length,
      skipped: jobResults.filter((j) => j.status === "skipped").length,
      duplicatesSkipped: jobParamsList.length - dedupedJobs.length,
      totalExecutionMs,
      averageJobMs: Math.round(totalExecutionMs / (jobResults.length || 1)),
    };

    logger.info("Batch execution complete.", summary);

    return { jobs: jobResults, summary };
  }
}

export const batchProcessor = new BatchProcessor();
export default batchProcessor;
```

---

## Step 3 — Build the Execution Report Generator

The original challenge lab requires generating reports in TXT, CSV, and JSON [2]. Here's a dedicated `ReportGenerator` that produces all three formats from a batch result.

**src/services/reportGenerator.js**
```js
// src/services/reportGenerator.js
import fs from "fs";
import path from "path";
import { settings } from "@/config/settings";
import { logger } from "@/lib/logger";

export class ReportGenerator {
  generate(batchResult, baseFileName = "execution-report") {
    const reportsDir = path.join(settings.outputDir, "reports");
    if (!fs.existsSync(reportsDir)) {
      fs.mkdirSync(reportsDir, { recursive: true });
    }

    const jsonPath = path.join(reportsDir, `${baseFileName}.json`);
    const csvPath = path.join(reportsDir, `${baseFileName}.csv`);
    const txtPath = path.join(reportsDir, `${baseFileName}.txt`);

    fs.writeFileSync(jsonPath, JSON.stringify(batchResult, null, 2));

    const csvHeader = "jobId,status,durationMs,outputPath,error\n";
    const csvRows = batchResult.jobs
      .map((j) =>
        [j.jobId, j.status, j.durationMs, j.outputPath || "", j.error || ""].join(",")
      )
      .join("\n");
    fs.writeFileSync(csvPath, csvHeader + csvRows);

    const txtLines = [
      "Greymatter Docs — Execution Report",
      "-----------------------------------",
      `Total Jobs:        ${batchResult.summary.totalJobs}`,
      `Successful:        ${batchResult.summary.successful}`,
      `Failed:            ${batchResult.summary.failed}`,
      `Skipped:           ${batchResult.summary.skipped}`,
      `Duplicates Skipped:${batchResult.summary.duplicatesSkipped}`,
      `Total Time (ms):   ${batchResult.summary.totalExecutionMs}`,
      `Avg Job Time (ms): ${batchResult.summary.averageJobMs}`,
    ];
    fs.writeFileSync(txtPath, txtLines.join("\n"));

    logger.info("Execution reports generated.", { jsonPath, csvPath, txtPath });

    return { jsonPath, csvPath, txtPath };
  }
}

export const reportGenerator = new ReportGenerator();
export default reportGenerator;
```

---

## Step 4 — Verify With an API Route

**src/app/api/batch-generate/route.js**
```js
// src/app/api/batch-generate/route.js
import { NextResponse } from "next/server";
import { batchProcessor } from "@/orchestrator/batchProcessor";
import { reportGenerator } from "@/services/reportGenerator";

export async function POST(request) {
  const body = await request.json();
  // Expects: { jobs: [...], batchSize: 2, pauseMs: 500 }

  const result = await batchProcessor.run(body.jobs, {
    batchSize: body.batchSize,
    pauseMs: body.pauseMs,
  });

  const reportPaths = reportGenerator.generate(result);

  return NextResponse.json({ ...result, reportPaths });
}
```

Test with a POST body like:
```json
{
  "jobs": [
    { "customerId": 1, "invoiceId": 1, "outputFileName": "invoice_1.docx" },
    { "customerId": 1, "invoiceId": 1, "outputFileName": "invoice_1.docx" },
    { "customerId": 1, "invoiceId": 2, "outputFileName": "invoice_2.docx" },
    { "customerId": 999, "invoiceId": 1, "outputFileName": "invoice_bad.docx" }
  ],
  "batchSize": 2,
  "pauseMs": 300
}
```

The second job (duplicate of the first) should be skipped, the fourth should fail cleanly, and `output/reports/` should contain `execution-report.json`, `.csv`, and `.txt` summarizing the run.

---

## CHALLENGE LAB

Directly from the original challenge lab, adapted to our stack [2]:

1. Add an estimated time remaining (ETA) to the progress monitor — already implemented via `ProgressMonitor.getEta()`; wire it into a live-updating UI or log line.
2. Record the processing time for each individual job — already captured as `durationMs` per job.
3. Generate reports in TXT, CSV, and JSON — already implemented via `ReportGenerator`.
4. Skip duplicate jobs within the same batch — already implemented via the `seen` Set in `BatchProcessor.run()`.
5. Add configurable batch sizes and pause intervals between batches — already implemented via `batchSize`/`pauseMs` options; try tuning these for a batch of 20+ jobs and observe the pacing in your logs.

As a stretch goal beyond the original lab: stream progress updates to the browser in real time using Server-Sent Events or a WebSocket, so a UI can show a live progress bar instead of only reading logs.

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| Batch stops entirely on first failure | Error escaping the per-job loop | Confirm `documentOrchestrator.runInvoiceJob()` already catches its own errors internally (from Part 7) |
| Duplicate jobs not being skipped | Dedup key doesn't match job shape | Confirm `customerId`/`invoiceId` are present and consistently typed (numbers, not strings) |
| Reports directory missing | `output/reports/` not created before writing | Confirm `ReportGenerator.generate()` creates the directory with `recursive: true` |
| ETA shows `null` | Called before any job has completed | `getEta()` requires at least one completed job to estimate remaining time |
| Batch pacing doesn't seem to pause | `pauseMs` not passed through, or batch fits in a single chunk | Ensure `batchSize` is smaller than total job count to see pausing behavior |

---

## Chapter Summary

In this chapter, you:

* Built a `ProgressMonitor` reporting live completion percentage and ETA
* Built a `BatchProcessor` as the single entry point for high-volume document generation, handling execution, failures, progress updates, and performance measurement [2]
* Added duplicate-job skipping and configurable batch sizes with pause intervals between chunks
* Built a `ReportGenerator` producing execution reports in TXT, CSV, and JSON [2]
* Verified the full batch pipeline end-to-end via an API route

This completes the milestone of batch processing and performance improvements [13]. **Next: Part 10 — Deployment & Scale**, where we prepare Greymatter Docs for production deployment, scheduling, and operational hardening [13].
