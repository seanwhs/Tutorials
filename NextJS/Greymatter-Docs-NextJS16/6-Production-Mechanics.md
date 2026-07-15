# Part 6 — Production Mechanics (Next.js Edition)

## Centralized Configuration, Custom Exceptions, and Validation Utilities

> **Goal:** Transform Greymatter Docs into a production-ready application with structured logging, centralized configuration, a custom exception hierarchy, and consistent validation across every module.

This mirrors the original goal for this stage of the series exactly, just implemented in JavaScript instead of Python: centralize application configuration, introduce a custom exception hierarchy, enhance logging, add reusable validation utilities, and consolidate error handling across repositories and services [5].

---

## THEORY & ARCHITECTURE

A production application needs to fail *predictably*. Instead of generic errors bubbling up from anywhere, every layer should raise a specific, meaningful exception type, and every important event should be logged with enough context to diagnose problems later [5]. We'll formalize both of these across the whole project structure we've built so far.

Our updated structure, mirroring the original's reorganization [5]:

```text
greymatter-docs/
├── src/
│   ├── config/
│   │   ├── settings.js
│   │   └── validation.js
│   ├── exceptions/
│   │   ├── databaseExceptions.js
│   │   ├── processorExceptions.js
│   │   ├── serviceExceptions.js
│   │   └── validationExceptions.js
│   ├── lib/
│   │   └── logger.js
│   ├── database/
│   ├── repositories/
│   ├── processor/
│   ├── services/
│   └── app/
├── templates/
├── output/
└── logs/
```

---

## Step 1 — Build a Custom Exception Hierarchy

Just as the original introduced domain-specific exception modules for the database, processor, and service layers [5], we build the JS equivalent using `Error` subclasses.

**src/exceptions/databaseExceptions.js**
```js
// src/exceptions/databaseExceptions.js
export class DatabaseConnectionError extends Error {
  constructor(message) {
    super(message);
    this.name = "DatabaseConnectionError";
  }
}

export class RecordNotFoundError extends Error {
  constructor(message) {
    super(message);
    this.name = "RecordNotFoundError";
  }
}
```

**src/exceptions/processorExceptions.js**
```js
// src/exceptions/processorExceptions.js
export class TemplateNotFoundError extends Error {
  constructor(message) {
    super(message);
    this.name = "TemplateNotFoundError";
  }
}

export class PlaceholderRenderError extends Error {
  constructor(message) {
    super(message);
    this.name = "PlaceholderRenderError";
  }
}
```

**src/exceptions/serviceExceptions.js**
```js
// src/exceptions/serviceExceptions.js
export class DocumentEngineError extends Error {
  constructor(message) {
    super(message);
    this.name = "DocumentEngineError";
  }
}

export class DeliveryError extends Error {
  constructor(message) {
    super(message);
    this.name = "DeliveryError";
  }
}
```

**src/exceptions/validationExceptions.js**
```js
// src/exceptions/validationExceptions.js
export class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = "ValidationError";
  }
}

export class ConfigurationError extends Error {
  constructor(message) {
    super(message);
    this.name = "ConfigurationError";
  }
}
```

`ConfigurationError` is included here as our built-in version of the original challenge lab's request to add a `ConfigurationError` exception for invalid application settings [5].

---

## Step 2 — Centralize Configuration Validation

The original's `settings.py`/`config` layer centralized paths; now we validate them too, per the challenge lab's request to validate that the output directory is writable before generating documents [5].

**src/config/validation.js**
```js
// src/config/validation.js
import fs from "fs";
import { ConfigurationError } from "@/exceptions/validationExceptions";
import { logger } from "@/lib/logger";

export function assertDirectoryWritable(dirPath, label) {
  try {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
    fs.accessSync(dirPath, fs.constants.W_OK);
    logger.info(`${label} directory is writable.`, { dirPath });
  } catch (error) {
    logger.error(`${label} directory is not writable.`, {
      dirPath,
      error: error.message,
    });
    throw new ConfigurationError(`${label} directory is not writable: ${dirPath}`);
  }
}

export function validateSettings(settings) {
  assertDirectoryWritable(settings.outputDir, "Output");
  assertDirectoryWritable(settings.logsDir, "Logs");
  assertDirectoryWritable(settings.templatesDir, "Templates");
}
```

Wire this into `src/config/settings.js` so it runs a validation check whenever settings are loaded — matching the original's emphasis on validating settings before generating documents [5].

---

## Step 3 — Reusable Validation Utilities

**src/config/validators.js**
```js
// src/config/validators.js
import { ValidationError } from "@/exceptions/validationExceptions";

export function requireFields(obj, fields) {
  const missing = fields.filter((field) => obj[field] === undefined || obj[field] === null || obj[field] === "");
  if (missing.length > 0) {
    throw new ValidationError(`Missing required fields: ${missing.join(", ")}`);
  }
}

export function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function assertValidEmail(email) {
  if (!isValidEmail(email)) {
    throw new ValidationError(`Invalid email address: ${email}`);
  }
}
```

---

## Step 4 — Enhance Logging With Rotating, Separated Log Files

We already split `app.log` and `errors.log` back in Part 1. Now let's add rotation, matching the original's request to configure separate log files for application events and errors only [5] — plus keep file sizes under control in production.

```bash
npm install winston-daily-rotate-file
```

**src/lib/logger.js** (updated)
```js
// src/lib/logger.js
import winston from "winston";
import "winston-daily-rotate-file";
import path from "path";
import fs from "fs";
import { settings } from "@/config/settings";

if (!fs.existsSync(settings.logsDir)) {
  fs.mkdirSync(settings.logsDir, { recursive: true });
}

const appTransport = new winston.transports.DailyRotateFile({
  filename: path.join(settings.logsDir, "app-%DATE%.log"),
  datePattern: "YYYY-MM-DD",
  maxFiles: "14d",
});

const errorTransport = new winston.transports.DailyRotateFile({
  filename: path.join(settings.logsDir, "errors-%DATE%.log"),
  datePattern: "YYYY-MM-DD",
  level: "error",
  maxFiles: "30d",
});

export const logger = winston.createLogger({
  level: settings.env === "production" ? "info" : "debug",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
      const metaString = Object.keys(meta).length ? JSON.stringify(meta) : "";
      return `${timestamp} [${level.toUpperCase()}] ${message} ${metaString}`;
    })
  ),
  transports: [new winston.transports.Console(), appTransport, errorTransport],
});

export default logger;
```

---

## Step 5 — Log Execution Time (Decorator Equivalent)

The original challenge lab asked for a decorator that logs the execution time of repository methods [5]. JavaScript doesn't have Python-style decorators for plain classes by default, so we use a higher-order function wrapper — the idiomatic JS equivalent.

**src/lib/withTiming.js**
```js
// src/lib/withTiming.js
import { logger } from "@/lib/logger";

export function withTiming(label, fn) {
  return (...args) => {
    const start = Date.now();
    try {
      const result = fn(...args);
      const durationMs = Date.now() - start;
      logger.info(`${label} completed.`, { durationMs });
      return result;
    } catch (error) {
      const durationMs = Date.now() - start;
      logger.error(`${label} failed.`, { durationMs, error: error.message });
      throw error;
    }
  };
}
```

Usage example, wrapping a repository method:
```js
import { withTiming } from "@/lib/withTiming";
import { customerRepository } from "@/repositories/customerRepository";

const getAllCustomersTimed = withTiming(
  "CustomerRepository.getAllCustomers",
  customerRepository.getAllCustomers.bind(customerRepository)
);
```

---

## Step 6 — Consolidate Error Handling in Repositories and Services

Update `CustomerRepository` (Part 2) to throw our new domain-specific exceptions instead of generic errors:

**src/repositories/customerRepository.js** (relevant excerpt updated)
```js
import { RecordNotFoundError } from "@/exceptions/databaseExceptions";

getCustomerById(id) {
  const db = dbManager.getConnection();
  const stmt = db.prepare("SELECT * FROM customers WHERE id = ?");
  const customer = stmt.get(id);

  if (!customer) {
    logger.info("No customer found.", { id });
    throw new RecordNotFoundError(`Customer with id ${id} not found.`);
  }

  return customer;
}
```

Update API routes to catch these specific exception types and respond with appropriate status codes:

```js
import { RecordNotFoundError } from "@/exceptions/databaseExceptions";
import { ValidationError, ConfigurationError } from "@/exceptions/validationExceptions";

try {
  // ...
} catch (error) {
  if (error instanceof RecordNotFoundError) {
    return NextResponse.json({ error: error.message }, { status: 404 });
  }
  if (error instanceof ValidationError) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  if (error instanceof ConfigurationError) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  return NextResponse.json({ error: "Unexpected error." }, { status: 500 });
}
```

This mirrors the original goal of avoiding generic errors everywhere and instead using domain-specific exception classes so problems are diagnosable and predictable, rather than surfacing as an unhelpful generic `RuntimeError` [5]. It also preserves the original's principle of logging the problem with enough detail for diagnosis while raising a meaningful exception and avoiding exposing internal errors to end users [5].

One more important detail from the original architecture applies directly here: when you catch a lower-level error and throw a new domain-specific one, don't lose the original stack trace. The Python version emphasized `raise ... from error` to preserve the original cause [5]. In JavaScript, the equivalent is passing `{ cause: error }` when constructing the new error, so nothing is lost during translation:

```js
// src/repositories/customerRepository.js (excerpt)
import { DatabaseConnectionError } from "@/exceptions/databaseExceptions";

getCustomerById(id) {
  try {
    const db = dbManager.getConnection();
    const stmt = db.prepare("SELECT * FROM customers WHERE id = ?");
    return stmt.get(id);
  } catch (error) {
    logger.error("Failed to fetch customer.", { id, error: error.message });
    throw new DatabaseConnectionError("Unable to fetch customer.", { cause: error });
  }
}
```

---

## CHALLENGE LAB

1. Add a `postal_code` column to the `customers` table and update the seed data accordingly [9].
2. Implement `updateCustomer(id, data)` and `deleteCustomer(id)` on `CustomerRepository`, using `ValidationError` for missing required fields via `requireFields()` [9].
3. Add a `RotatingFileHandler`-style limit to our Winston setup (already handled via `winston-daily-rotate-file`) and confirm old log files are cleaned up automatically, preventing logs from growing unbounded [5].
4. Validate that all required template files exist *before* any document processing begins, not after — mirroring the lesson that validating files too late causes unexpected crashes [5].
5. Wrap at least one repository method with `withTiming()` and confirm execution duration appears in the logs.

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| Log file grows too large | Log rotation not configured | Use `winston-daily-rotate-file` with sensible `maxFiles` limits [5] |
| Generic errors make debugging difficult | Code throws plain `Error` everywhere instead of domain-specific types | Introduce and consistently use domain-specific exception classes [5] |
| Missing templates cause unexpected crashes | Validation happens too late, after processing has already started | Validate all required files and directories before processing begins [5] |
| Important errors missing from logs | Logger level excludes error severity | Ensure the logger's configured level includes `error` [5] |
| Original error cause lost when re-thrown | New error thrown without linking to the original | Pass `{ cause: error }` when constructing the new exception, preserving the original stack trace [5] |

---

## Chapter Summary

In this chapter, you:

* Built a custom exception hierarchy across database, processor, service, and validation layers
* Centralized configuration validation, ensuring output/log/template directories are writable before processing begins [5]
* Added reusable validation utilities (`requireFields`, `assertValidEmail`)
* Upgraded logging with daily rotation and separated error logs [5]
* Built a `withTiming()` wrapper as the JS equivalent of a timing decorator
* Consolidated repositories and API routes to throw and handle meaningful, specific exceptions instead of generic errors, preserving original error causes [5]

This completes the production-hardening milestone — logging and robust error handling implemented [13]. **Next: Part 7 — Orchestrator**, where we introduce `JobContext` and a `DocumentOrchestrator` that wires the full pipeline together end-to-end, with fault isolation so one failed job never stops the rest of the queue [4].
