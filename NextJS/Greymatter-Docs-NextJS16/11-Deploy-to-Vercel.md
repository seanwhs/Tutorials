# Part 11 — Deploy to Vercel (Free)

## Taking Greymatter Docs Live

> **Goal:** Deploy the completed Greymatter Docs application to a live, publicly accessible URL using Vercel's free tier, wiring up environment variables, persistent-storage considerations, and an external scheduler for automated batch runs.

**Milestone:** By the end of this chapter, Greymatter Docs will be running as a live web application, with scheduled document generation triggered automatically and improvements like CSV-based bulk invoice creation and a progress indicator in place.

---

## THEORY & ARCHITECTURE

Deploying a Next.js application to Vercel is straightforward, but our app has real operational needs that a purely stateless serverless environment doesn't provide out of the box: a writable SQLite file, a `templates/` folder, an `output/` folder for generated documents, and a way to trigger scheduled batch jobs without a persistently running process.

The original series closes with the same production concerns — environment-based configuration, scheduled execution, health checks, and deployment automation — so that the platform can run reliably as an unattended production service [11]. We'll carry those same concerns into a Vercel deployment, adapting only where serverless constraints require it.

```text
GitHub Repository
        │
        ▼
   Vercel Build
        │
        ▼
Environment Variables (Vercel Dashboard)
        │
        ▼
Deployed Next.js App
        │
        ▼
External Scheduler ──▶ /api/scheduled-batch
```

**Important constraint:** Vercel's serverless filesystem is ephemeral — anything written to disk during a request (like a SQLite file or generated documents) does not persist across deployments or even across separate function invocations reliably. For a genuinely production-grade deployment, the database and generated output should live outside the serverless function itself. We'll cover the free-tier-friendly path below, plus the recommended upgrade path for real persistence.

---

## Step 1 — Push the Project to GitHub

```bash
git init
git add .
git commit -m "Greymatter Docs — initial commit"
git branch -M main
git remote add origin https://github.com/your-username/greymatter-docs.git
git push -u origin main
```

Make sure `.gitignore` excludes local artifacts:

```text
node_modules/
.next/
data/*.db
output/*
logs/*
.env.local
```

---

## Step 2 — Connect the Repository to Vercel

1. Go to vercel.com and sign in with GitHub.
2. Click **Add New Project**, select your `greymatter-docs` repository.
3. Framework preset should auto-detect as **Next.js**.
4. Leave build settings as default (`next build`).
5. Don't deploy yet — first add environment variables.

---

## Step 3 — Configure Environment Variables

In the Vercel dashboard, under **Settings → Environment Variables**, add every value our `settings.js` and `smtpService.js` expect (from Part 10):

```text
NODE_ENV=production
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-username
SMTP_PASSWORD=your-password
SMTP_SENDER=noreply@example.com
CRON_SECRET=a-long-random-string
MAX_BATCH_SIZE=25
```

For `DATABASE_FILE`, `TEMPLATES_DIR`, `OUTPUT_DIR`, and `LOGS_DIR` — leave these unset on Vercel's free tier so they fall back to their `process.cwd()`-relative defaults, but understand the limitation below.

---

## Step 4 — Understand the Free-Tier Persistence Limitation

On Vercel's free (Hobby) tier, serverless functions run in an ephemeral, read-only filesystem except for `/tmp`, and even `/tmp` doesn't persist between invocations. This means:

- Our SQLite file (`better-sqlite3`) won't reliably persist between requests once deployed.
- Files written to `output/` (generated `.docx`/`.pdf`) will vanish after each function's execution finishes.

**For learning and demoing purposes**, you can point `databaseFile` to `/tmp/greymatter.db` and seed it fresh on cold start — this lets the whole pipeline run and prove itself end-to-end on every request, at the cost of not persisting customer/invoice data between calls.

**src/config/settings.js** (production-aware path)
```js
import path from "path";

const ROOT_DIR = process.cwd();
const isProd = process.env.NODE_ENV === "production";

export const settings = {
  databaseFile: process.env.DATABASE_FILE || (isProd ? "/tmp/greymatter.db" : path.join(ROOT_DIR, "data", "greymatter.db")),
  templatesDir: process.env.TEMPLATES_DIR || path.join(ROOT_DIR, "templates"),
  outputDir: process.env.OUTPUT_DIR || (isProd ? "/tmp/output" : path.join(ROOT_DIR, "output")),
  logsDir: process.env.LOGS_DIR || (isProd ? "/tmp/logs" : path.join(ROOT_DIR, "logs")),
  env: process.env.NODE_ENV || "development",
  maxBatchSize: Number(process.env.MAX_BATCH_SIZE || 50),
};

export default settings;
```

**For a genuinely production-ready deployment**, swap the database and file storage for services designed to persist beyond a single function call, while keeping every repository/service module we built exactly the same on the outside:
- Database: a hosted SQLite-compatible service (e.g., Turso) or a managed Postgres instance, accessed through the same `DatabaseManager` interface
- Generated files: an object storage bucket (e.g., Vercel Blob, S3-compatible storage) instead of the local `output/` folder

This is a drop-in swap at the `DatabaseManager` and file-writing layer only — because we built everything behind repository and service abstractions from Part 2 onward, nothing above those layers needs to change.

---

## Step 5 — Seed on Cold Start (Free-Tier Demo Path)

Add an idempotent seed check that runs automatically the first time the database is touched in a fresh serverless instance.

**src/database/database.js** (extend `getConnection()`)
```js
getConnection() {
  if (this._db) {
    return this._db;
  }

  try {
    const dataDir = path.dirname(settings.databaseFile);
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }

    this._db = new Database(settings.databaseFile);
    this._db.pragma("journal_mode = WAL");

    this.initSchema();
    this._maybeSeed();

    logger.info("Connected to SQLite.", { file: settings.databaseFile });
    return this._db;
  } catch (error) {
    logger.error("Failed to connect to SQLite.", { error: error.message });
    throw new DatabaseConnectionError("Unable to connect to SQLite.");
  }
}

_maybeSeed() {
  const count = this._db.prepare("SELECT COUNT(*) AS count FROM customers").get();
  if (count.count === 0) {
    // Insert the same sample customers used in Part 2's seed script
    const insert = this._db.prepare(`
      INSERT INTO customers (first_name, last_name, company, email, country)
      VALUES (@first_name, @last_name, @company, @email, @country)
    `);
    insert.run({ first_name: "John", last_name: "Smith", company: "Greymatter Consulting", email: "john@example.com", country: "Singapore" });
  }
}
```

---

## Step 6 — Deploy

Back in the Vercel dashboard, click **Deploy**. Once the build finishes, visit your live URL:

```text
https://greymatter-docs.vercel.app/api/health
```

You should get back the same JSON health-check shape from Part 10, confirming database, templates, and output checks all pass.

Test document generation live:
```text
https://greymatter-docs.vercel.app/api/generate-invoice?customerId=1&invoiceId=1
```

---

## Step 7 — Wire Up an External Scheduler

Since Vercel's free tier doesn't run a persistent background process, use a free external cron service (e.g., cron-job.org) to call your scheduled batch endpoint from Part 10 on a recurring basis:

```text
POST https://greymatter-docs.vercel.app/api/scheduled-batch
Authorization: Bearer <your CRON_SECRET>
Content-Type: application/json

{
  "jobs": [
    { "customerId": 1, "invoiceId": 1, "outputFileName": "invoice_1.docx" }
  ],
  "batchSize": 5,
  "pauseMs": 200
}
```

Vercel's own Hobby plan also supports simple **Vercel Cron Jobs** via a `vercel.json` file:

```json
{
  "crons": [
    {
      "path": "/api/scheduled-batch",
      "schedule": "0 2 * * *"
    }
  ]
}
```

Note: Vercel Cron on the Hobby tier only supports GET requests without custom headers, so for the `Authorization` bearer-token pattern above, an external scheduler that supports custom headers (like cron-job.org) is the more flexible free option.

---

## CHALLENGE LAB

Improve your deployment with the following, adapted directly from the original's deployment challenge lab [10]:

1. **CSV bulk upload**: Add a `/api/upload-customers` route accepting a CSV file, parsing it (e.g., with `papaparse`), inserting each row via `CustomerRepository.createCustomer()`, and generating an invoice for each one automatically [10].
2. **Progress bar**: Since our `BatchProcessor` (Part 9) already tracks progress internally, stream updates to the browser via Server-Sent Events so a UI can render a live bar like:
```text
Generating...
██████░░░░░ 60%
```
3. **Admin stats page**: Build a `/admin` page (a simple Next.js page, no auth required for the demo) showing total customers, total invoices generated, and recent delivery statuses from `delivery_queue`.
4. **Zip and download**: Add a route that zips all currently generated documents in `output/` (or your object storage bucket) and returns them as a single downloadable file.
5. **Persistent storage migration**: As a stretch goal, migrate `DatabaseManager` to use Turso (hosted SQLite) instead of a local file, and confirm every repository built in Parts 2 and 5 continues to work unchanged.

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| Data disappears between requests | Vercel Hobby tier's ephemeral filesystem doesn't persist `/tmp` between invocations | Expected on free tier; migrate to a hosted database (e.g., Turso) for real persistence |
| Build fails on `better-sqlite3` | Native binary not compiled for Vercel's serverless runtime | Ensure `better-sqlite3` is listed as a regular dependency (not devDependency) so Vercel rebuilds its native bindings during deploy |
| `/api/scheduled-batch` returns 401 | `CRON_SECRET` mismatch between scheduler and Vercel environment variable | Double check both values match exactly, with no trailing whitespace |
| Emails not sending in production | SMTP environment variables not set in Vercel dashboard | Re-check **Settings → Environment Variables**, redeploy after adding them |
| PDF conversion times out | Serverless function execution time limit exceeded on Hobby tier | Reduce batch size per invocation, or move PDF conversion to a background job/queue outside the request lifecycle |

---

## Chapter Summary

In this chapter, you:

* Pushed Greymatter Docs to GitHub and connected it to Vercel
* Configured environment variables for production, including SMTP credentials and a secured cron secret
* Understood Vercel's ephemeral filesystem constraints and adapted the app with a free-tier demo path and a documented upgrade path to persistent storage
* Deployed the app live and verified health checks and document generation through public URLs
* Wired an external scheduler to trigger batch document generation automatically
* Received a challenge lab covering CSV bulk upload, live progress bars, an admin stats page, and a path to persistent hosted storage

This completes the full Greymatter Docs series — from foundations to a live, deployed, production-hardened document generation platform, mirroring the original's complete ten-part roadmap from Foundations through Deployment & Scale [13], now fully realized in Next.js 16 and standard JavaScript libraries with a free deployment path on Vercel.
