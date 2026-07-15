# Part 1 — Foundations (Next.js Edition)

## The Foundations & Initial Setup

> **Goal:** Prepare the development environment, install Node.js and our document-processing dependencies, verify the toolchain works, and establish a clean, modular Next.js project structure. By the end of this chapter, you'll have a solid foundation ready for the rest of the series.

This part adapts the original Python/LibreOffice foundations chapter [12] into JavaScript. In the original series, four core components had to work together before any document generation could happen: Python (the application), LibreOffice (the document engine), the UNO API (the bridge between them), and a clean project structure [12]. Our Next.js version needs the same four conceptual layers — just with different tools:

```text
Next.js Application
│
▼
Configuration
│
▼
Logging System
│
▼
Document Engine (docx/docxtemplater)
│
▼
Document Processing
```

Everything we build in later parts depends on this foundation, exactly as in the original [12] — so we'll take the time to get it right.

---

## THEORY & ARCHITECTURE

Just like the original series centralized settings to avoid hard-coded paths scattered throughout the project [12], we'll do the same in Next.js using a central config module. And just as the original built a stub `LibreOfficeService` early — with logging and exception handling in place before any real document logic existed [12] — we'll build a stub `DocumentEngineService` here, so every later part can plug real behavior into an already-tested shape.

### Why start with a stub, not the real thing?

This mirrors the original philosophy directly: build working software incrementally, keep modules focused on a single responsibility, and test each milestone before moving on [13]. We are not going to wire up real DOCX generation yet — that comes in Part 4. Right now we just prove that the *pipeline shape* works end-to-end.

---

## Step 1 — Install Core Tools

You'll need:

1. **Node.js 20+** — download from nodejs.org, or use `nvm`:
```bash
nvm install 20
nvm use 20
node -v
```

2. **A code editor** — VS Code recommended.

3. **Git** (optional but recommended for version control).

---

## Step 2 — Scaffold the Next.js 16 Project

```bash
npx create-next-app@latest greymatter-docs
```

When prompted, choose:

```text
✔ Would you like to use TypeScript?  … No
✔ Would you like to use ESLint?      … Yes
✔ Would you like to use Tailwind CSS? … Yes
✔ Would you like to use `src/` directory? … Yes
✔ Would you like to use App Router?  … Yes
✔ Would you like to customize the default import alias? … No
```

We're using plain **JavaScript**, not TypeScript, to keep this beginner-friendly — matching the original series' emphasis on simple, readable code over clever code [13].

```bash
cd greymatter-docs
npm run dev
```

Visit `http://localhost:3000` — if you see the default Next.js welcome page, your environment is working.

---

## Step 3 — Install Our Core Dependencies

These are the JS equivalents of the original's SQLite + LibreOffice/UNO toolchain, which we'll actually wire up starting in Parts 2–4:

```bash
npm install better-sqlite3
npm install docxtemplater pizzip
npm install nodemailer
npm install winston
```

| Package | Role (maps to original component) |
|---|---|
| `better-sqlite3` | SQLite driver → replaces Python's `sqlite3` module [9] |
| `docxtemplater` + `pizzip` | Template engine → replaces `.ott` + regex placeholder engine [8] |
| `nodemailer` | Email delivery → replaces `SmtpService` [3] |
| `winston` | Structured logging → replaces Python's `logging` module [5] |

Don't worry about understanding all of these yet — we're just installing them now so Part 1 finishes with a fully prepared environment, matching the original's "install now, use later" approach [12].

---

## Step 4 — Build a Clean, Modular Project Structure

The original series organized Python code into `config/`, `database/`, `processor/`, `services/`, and `exceptions/` folders, each with a single responsibility [12] [5]. We'll mirror that exactly inside `src/`:

```text
greymatter-docs/
├── src/
│   ├── app/                  ← Next.js routes/pages
│   ├── config/
│   │   └── settings.js
│   ├── lib/
│   │   └── logger.js
│   ├── database/
│   │   └── database.js        (Part 2)
│   ├── repositories/           (Part 2)
│   ├── processor/              (Parts 3–5)
│   ├── services/               (Parts 4, 8)
│   └── exceptions/             (Part 6)
├── templates/                  ← document templates (Part 3)
├── output/                     ← generated documents
└── package.json
```

Create the folders now:

```bash
mkdir -p src/config src/lib src/database src/repositories src/processor src/services src/exceptions templates output
```

---

## Step 5 — Centralized Configuration

Just as the original's `settings.py` centralized configuration values to avoid hard-coded paths throughout the project [12], we create a single settings module.

**src/config/settings.js**
```js
// src/config/settings.js
import path from "path";

const ROOT_DIR = process.cwd();

export const settings = {
  databaseFile: path.join(ROOT_DIR, "data", "greymatter.db"),
  templatesDir: path.join(ROOT_DIR, "templates"),
  outputDir: path.join(ROOT_DIR, "output"),
  logsDir: path.join(ROOT_DIR, "logs"),
  env: process.env.NODE_ENV || "development",
};

export default settings;
```

This gives every other module in the project one place to ask "where is the database?" or "where do templates live?" — nothing gets hard-coded elsewhere.

---

## Step 6 — Structured Logging

The original series used Python's `logging` module throughout every layer, logging both informational events and exceptions with full context [5] [9]. We'll use `winston` to get the same structured, leveled logging in JavaScript.

**src/lib/logger.js**
```js
// src/lib/logger.js
import winston from "winston";
import path from "path";
import fs from "fs";
import { settings } from "@/config/settings";

// Ensure the logs directory exists
if (!fs.existsSync(settings.logsDir)) {
  fs.mkdirSync(settings.logsDir, { recursive: true });
}

export const logger = winston.createLogger({
  level: settings.env === "production" ? "info" : "debug",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
      const metaString = Object.keys(meta).length
        ? JSON.stringify(meta)
        : "";
      return `${timestamp} [${level.toUpperCase()}] ${message} ${metaString}`;
    })
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({
      filename: path.join(settings.logsDir, "app.log"),
    }),
    new winston.transports.File({
      filename: path.join(settings.logsDir, "errors.log"),
      level: "error",
    }),
  ],
});

export default logger;
```

Notice we already split logs into a general `app.log` and an `errors.log` — the same separation the original series' challenge lab asked readers to add manually in Part 6 [5]. We're building it in from day one here.

---

## Step 7 — Build a Stub Document Engine Service

In the original, Part 1 built a **stub `LibreOfficeService`** — with logging and exception handling wired up, but no real document logic yet [12]. This let every later chapter plug real behavior into an already-proven shape. We do the same here with a `DocumentEngineService` stub, which we'll bring to life with `docxtemplater` in Part 4.

**src/services/documentEngineService.js**
```js
// src/services/documentEngineService.js
import { logger } from "@/lib/logger";

export class DocumentEngineService {
  constructor() {
    this.connected = false;
  }

  connect() {
    try {
      // Real implementation arrives in Part 4 (docxtemplater bridge)
      logger.info("DocumentEngineService: connection stub initialized.");
      this.connected = true;
      return true;
    } catch (error) {
      logger.error("DocumentEngineService failed to initialize.", {
        error: error.message,
      });
      throw new Error("Unable to initialize document engine.");
    }
  }

  isConnected() {
    return this.connected;
  }
}

export default DocumentEngineService;
```

---

## Step 8 — Create an Entry-Point Verification Script

The original series finished Part 1 by creating the application's entry point and verifying that the environment initializes successfully [12]. In Next.js, we don't have a single `main.py` — but we can create a simple verification API route (or a script) that proves every piece we just built is wired together correctly.

**src/app/api/health/route.js**
```js
// src/app/api/health/route.js
import { NextResponse } from "next/server";
import { logger } from "@/lib/logger";
import { settings } from "@/config/settings";
import { DocumentEngineService } from "@/services/documentEngineService";

export async function GET() {
  try {
    logger.info("Health check started.");

    const engine = new DocumentEngineService();
    engine.connect();

    const status = {
      status: "ok",
      environment: settings.env,
      engineConnected: engine.isConnected(),
      timestamp: new Date().toISOString(),
    };

    logger.info("Health check passed.", status);

    return NextResponse.json(status);
  } catch (error) {
    logger.error("Health check failed.", { error: error.message });
    return NextResponse.json(
      { status: "error", message: error.message },
      { status: 500 }
    );
  }
}
```

Run the dev server and visit:

```text
http://localhost:3000/api/health
```

You should see JSON like:

```json
{
  "status": "ok",
  "environment": "development",
  "engineConnected": true,
  "timestamp": "2025-01-01T00:00:00.000Z"
}
```

And in your terminal (and in `logs/app.log`), you should see log lines confirming the health check ran. This is our equivalent of the original's "verify that the environment initializes successfully" milestone [12].

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `Module not found: @/config/settings` | Import alias not configured | Confirm `jsconfig.json` has `"paths": { "@/*": ["./src/*"] }` |
| `EACCES` or permission errors creating `logs/`/`output/` | Directory permissions | Run with proper permissions, or manually `mkdir` the folders first |
| `/api/health` returns 500 | Error thrown inside `connect()` | Check `logs/errors.log` for the stack trace |
| `better-sqlite3` fails to install | Native build tools missing | Install build essentials (`npm install --global windows-build-tools` on Windows, or `xcode-select --install` on macOS) |

---

## Chapter Summary

In this chapter, you:

* Installed Node.js and scaffolded a Next.js 16 project with JavaScript
* Installed our core dependencies (`better-sqlite3`, `docxtemplater`, `nodemailer`, `winston`)
* Created a modular project structure (`config/`, `lib/`, `database/`, `repositories/`, `processor/`, `services/`, `exceptions/`)
* Configured centralized application settings
* Implemented production-ready structured logging with separate error logs
* Built a stub `DocumentEngineService` with logging and error handling
* Created a health-check API route and verified the environment initializes successfully


