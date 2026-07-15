# Part 10 — Deployment & Scale (Next.js Edition)

## Production Deployment, Scheduling, and Operational Hardening

> **Goal:** Prepare Greymatter Docs for production deployment with operational practices like structured logging, backups, configuration management, and health checks.

**Milestone:** By the end of this chapter, Greymatter Docs will be ready for production deployment, scheduling, and hardening — completing the "Deployment & Scale" stage of the roadmap [13].

---

## THEORY & ARCHITECTURE

A production deployment requires more than working code. Operational practices such as structured logging, backups, configuration management, and health checks improve reliability and simplify maintenance [11]. This chapter is about closing that gap — everything we've built in Parts 1–9 works correctly, but "works correctly on my machine" isn't the same as "ready to run unattended in production."

We'll cover four operational pillars, adapted directly from the original's production readiness checklist [11]:

```text
Structured Logging
        │
        ▼
Configuration Management
        │
        ▼
Backup Strategy
        │
        ▼
Health Checks
```

---

## Step 1 — Separate Logs by Purpose

The original recommends separating logs into distinct files by purpose, so monitoring and troubleshooting stay simple [11]:

| File | Contents |
|---|---|
| `application.log` | Normal operations |
| `error.log` | Errors and exceptions |
| `audit.log` | Business events (e.g., document generated, email sent) |
| `execution.log` | Batch summaries |

We already split `app.log`/`errors.log` with rotation back in Part 6. Let's add the remaining two logger channels.

**src/lib/logger.js** (extend with additional transports)
```js
// src/lib/logger.js (additions)
import winston from "winston";
import "winston-daily-rotate-file";
import path from "path";
import { settings } from "@/config/settings";

function makeRotatingLogger(fileNamePrefix, level = "info") {
  return winston.createLogger({
    level,
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.printf(({ timestamp, level, message, ...meta }) => {
        const metaString = Object.keys(meta).length ? JSON.stringify(meta) : "";
        return `${timestamp} [${level.toUpperCase()}] ${message} ${metaString}`;
      })
    ),
    transports: [
      new winston.transports.DailyRotateFile({
        filename: path.join(settings.logsDir, `${fileNamePrefix}-%DATE%.log`),
        datePattern: "YYYY-MM-DD",
        maxFiles: "30d",
      }),
    ],
  });
}

export const auditLogger = makeRotatingLogger("audit");
export const executionLogger = makeRotatingLogger("execution");
```

Use `auditLogger` for business events (document generated, email sent, delivery status changed) and `executionLogger` for batch summaries from the `BatchProcessor` (Part 9):

```js
// Example usage inside DocumentOrchestrator
import { auditLogger } from "@/lib/logger";

auditLogger.info("Document generated.", { customerId, invoiceId, outputPath });
```

```js
// Example usage inside BatchProcessor, after a run completes
import { executionLogger } from "@/lib/logger";

executionLogger.info("Batch execution summary.", summary);
```

Separating logs this way means an operator investigating "did customer X get their invoice?" checks `audit.log`, while someone investigating "why did last night's batch run slow?" checks `execution.log` — without either being drowned out by routine request noise in `application.log`.

---

## Step 2 — Environment-Based Configuration

Production settings should never be hardcoded. Extend `src/config/settings.js` (built in Part 1, validated in Part 6) to pull every environment-sensitive value from environment variables, with safe local defaults.

**src/config/settings.js** (updated)
```js
// src/config/settings.js
import path from "path";

const ROOT_DIR = process.cwd();

export const settings = {
  databaseFile: process.env.DATABASE_FILE || path.join(ROOT_DIR, "data", "greymatter.db"),
  templatesDir: process.env.TEMPLATES_DIR || path.join(ROOT_DIR, "templates"),
  outputDir: process.env.OUTPUT_DIR || path.join(ROOT_DIR, "output"),
  logsDir: process.env.LOGS_DIR || path.join(ROOT_DIR, "logs"),
  env: process.env.NODE_ENV || "development",
  maxBatchSize: Number(process.env.MAX_BATCH_SIZE || 50),
  smtp: {
    server: process.env.SMTP_SERVER,
    port: Number(process.env.SMTP_PORT || 587),
    username: process.env.SMTP_USERNAME,
    password: process.env.SMTP_PASSWORD,
    sender: process.env.SMTP_SENDER,
  },
};

export default settings;
```

This ensures that when we deploy in Part 11, every path and credential can be reconfigured through environment variables in the hosting dashboard, without touching code.

---

## Step 3 — Backup Strategy

Since `better-sqlite3` stores everything in a single file, backups are straightforward — but they still need to be automated and verified, not left as a manual afterthought.

**src/services/backupService.js**
```js
// src/services/backupService.js
import fs from "fs";
import path from "path";
import { settings } from "@/config/settings";
import { logger } from "@/lib/logger";

export class BackupService {
  backupDatabase() {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
      const backupDir = path.join(settings.outputDir, "backups");

      if (!fs.existsSync(backupDir)) {
        fs.mkdirSync(backupDir, { recursive: true });
      }

      const backupPath = path.join(backupDir, `greymatter-${timestamp}.db`);
      fs.copyFileSync(settings.databaseFile, backupPath);

      logger.info("Database backup created.", { backupPath });

      return backupPath;
    } catch (error) {
      logger.error("Database backup failed.", { error: error.message });
      throw error;
    }
  }

  /**
   * Keeps only the N most recent backups, deleting older ones.
   */
  pruneOldBackups(keep = 7) {
    const backupDir = path.join(settings.outputDir, "backups");
    if (!fs.existsSync(backupDir)) return;

    const files = fs
      .readdirSync(backupDir)
      .map((name) => ({
        name,
        time: fs.statSync(path.join(backupDir, name)).mtime.getTime(),
      }))
      .sort((a, b) => b.time - a.time);

    const toDelete = files.slice(keep);
    toDelete.forEach((file) => {
      fs.unlinkSync(path.join(backupDir, file.name));
      logger.info("Old backup pruned.", { file: file.name });
    });
  }
}

export const backupService = new BackupService();
export default backupService;
```

**src/app/api/backup/route.js**
```js
// src/app/api/backup/route.js
import { NextResponse } from "next/server";
import { backupService } from "@/services/backupService";

export async function POST() {
  const backupPath = backupService.backupDatabase();
  backupService.pruneOldBackups(7);
  return NextResponse.json({ status: "ok", backupPath });
}
```

In production, this route should be triggered on a schedule (e.g., a daily cron job via your hosting platform, or an external scheduler hitting this endpoint).

---

## Step 4 — Health Checks

We built a basic health check in Part 1. Let's expand it to verify every operational dependency: database connectivity, template availability, and output directory writability.

**src/app/api/health/route.js** (updated)
```js
// src/app/api/health/route.js
import { NextResponse } from "next/server";
import { logger } from "@/lib/logger";
import { settings } from "@/config/settings";
import { dbManager } from "@/database/database";
import fs from "fs";

export async function GET() {
  const checks = {};
  let healthy = true;

  try {
    const db = dbManager.getConnection();
    db.prepare("SELECT 1").get();
    checks.database = "ok";
  } catch (error) {
    checks.database = "failed";
    healthy = false;
    logger.error("Health check: database failed.", { error: error.message });
  }

  try {
    fs.accessSync(settings.templatesDir, fs.constants.R_OK);
    checks.templates = "ok";
  } catch {
    checks.templates = "failed";
    healthy = false;
  }

  try {
    fs.accessSync(settings.outputDir, fs.constants.W_OK);
    checks.output = "ok";
  } catch {
    checks.output = "failed";
    healthy = false;
  }

  const status = {
    status: healthy ? "ok" : "degraded",
    environment: settings.env,
    checks,
    timestamp: new Date().toISOString(),
  };

  return NextResponse.json(status, { status: healthy ? 200 : 503 });
}
```

A hosting platform (or uptime monitor) can now poll `/api/health` and get a real signal of whether Greymatter Docs is actually operational, not just whether the server process is running.

---

## Step 5 — Scheduling Batch Jobs

For unattended, recurring document generation (e.g., "run every night at 2 AM"), we don't run a persistent background process the way a traditional server might — Next.js apps, especially on serverless hosts, are request-driven. Instead, we expose the batch endpoint and trigger it externally via a scheduler.

**src/app/api/scheduled-batch/route.js**
```js
// src/app/api/scheduled-batch/route.js
import { NextResponse } from "next/server";
import { batchProcessor } from "@/orchestrator/batchProcessor";
import { reportGenerator } from "@/services/reportGenerator";
import { backupService } from "@/services/backupService";
import { executionLogger } from "@/lib/logger";

const CRON_SECRET = process.env.CRON_SECRET;

export async function POST(request) {
  const authHeader = request.headers.get("authorization");
  if (authHeader !== `Bearer ${CRON_SECRET}`) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }

  const body = await request.json();

  backupService.backupDatabase();
  backupService.pruneOldBackups(7);

  const result = await batchProcessor.run(body.jobs, {
    batchSize: body.batchSize,
    pauseMs: body.pauseMs,
  });

  reportGenerator.generate(result, `scheduled-${Date.now()}`);
  executionLogger.info("Scheduled batch complete.", result.summary);

  return NextResponse.json(result);
}
```

This route is protected by a `CRON_SECRET` bearer token so it can't be triggered by anyone who stumbles onto the URL. In Part 11, we'll wire an external scheduler (like a free cron service, or your hosting platform's built-in cron feature) to call this endpoint on a schedule.

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| Logs grow indefinitely | No log rotation or archival configured | Configure rotating handlers and archive old log files [11] |
| Backup file is corrupted or empty | Backup taken while database was mid-write | Use `better-sqlite3`'s WAL mode (already enabled in Part 2) which allows safe concurrent reads during backup |
| `/api/health` returns 503 unexpectedly | One dependency check failing (DB, templates, or output dir) | Check the `checks` object in the response to isolate which dependency failed |
| Scheduled batch runs but nothing happens | `CRON_SECRET` mismatch | Confirm the scheduler sends the exact `Authorization: Bearer <secret>` header matching your environment variable |
| Old backups never get cleaned up | `pruneOldBackups()` not called after each backup | Ensure `/api/backup` always calls `pruneOldBackups()` right after `backupDatabase()` |

---

## Chapter Summary

In this chapter, you:

* Separated logs into `application`, `error`, `audit`, and `execution` channels for clearer monitoring and troubleshooting [11]
* Made all sensitive and environment-specific configuration values overridable via environment variables
* Built a `BackupService` that backs up the SQLite database and prunes old backups automatically
* Expanded the health check endpoint to verify database connectivity, template availability, and output directory writability
* Built a secured, externally-triggerable endpoint for scheduled batch runs

This completes the operational readiness milestone: production deployment, scheduling, and hardening [13]. **Next: Part 11 — Deploy to Vercel (Free)**, where we take Greymatter Docs live on the internet, wire up environment variables in the hosting dashboard, connect an external scheduler to our batch endpoint, and address the realities of stateless, ephemeral deployments.
