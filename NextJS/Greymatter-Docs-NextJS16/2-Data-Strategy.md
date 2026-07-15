# Part 2 — Data Strategy (Next.js Edition)

## Building the SQLite Database, Access Layer, and Repository Pattern

> **Goal:** Design a production-ready SQLite database, implement a reusable database access layer, and build the first repository that retrieves data for document generation — all in JavaScript, running inside our Next.js project.

**Milestone:** By the end of this chapter, Greymatter Docs will have a fully functional SQLite database, a reusable database manager, and a repository capable of storing and retrieving customer data [9].

This directly mirrors the original Part 2, which built a SQLite schema, a `DatabaseManager`, and a `CustomerRepository` using the Repository pattern [9]. We're keeping the same architecture — just swapping Python's `sqlite3` module for `better-sqlite3`.

---

## THEORY & ARCHITECTURE

In the original series, the `DatabaseManager` was the **only** component that knows how to connect to SQLite. By centralizing connection logic, changing the database engine in the future (for example, to PostgreSQL) becomes much easier [9]. We'll follow the exact same principle in JavaScript.

```text
SQLite
│
▼
DatabaseManager
│
▼
Repositories
```

This is the same "Layer 3 — Repository Layer" pattern described in the architecture appendix: repositories isolate all database operations, and nothing above them is allowed to touch SQLite directly [1]. Presentation code (our Next.js pages/API routes) should never query SQLite directly — it always goes through an orchestrator and repository [1]:

```text
Presentation
↓
Orchestrator
↓
Repository
```

We won't build the orchestrator until Part 7 [4], but we're laying the groundwork correctly now so nothing needs to be refactored later.

---

## Step 1 — Design the Schema

Just like the original, we start with a `customers` table [9]. Create a `data/` folder for the database file (this matches the `databaseFile` path we set in `src/config/settings.js` back in Part 1):

```bash
mkdir -p data
```

**src/database/schema.sql**
```sql
CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  company TEXT,
  email TEXT NOT NULL,
  country TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

This mirrors the field set used in the original placeholder examples (`first_name`, `last_name`, `company`, `email`, `country`) [8], so our template placeholders in Part 3 will line up perfectly with this schema.

---

## Step 2 — Build the `DatabaseManager`

The original `DatabaseManager` centralized connection handling, used `sqlite3.Row` for dict-like row access, logged every connection, and raised a meaningful custom exception instead of a generic error [5]:

```python
class DatabaseManager:
    def get_connection(self):
        try:
            connection = sqlite3.connect(DATABASE_FILE)
            connection.row_factory = sqlite3.Row
            logger.info("Connected to SQLite.")
            return connection
        except sqlite3.Error as error:
            logger.exception(error)
            raise DatabaseConnectionError(
                "Unable to connect to SQLite."
            ) from error
```

Here's the direct JavaScript equivalent, using `better-sqlite3` (which is synchronous, so no callbacks or promises needed — great for beginners):

**src/database/database.js**
```js
// src/database/database.js
import Database from "better-sqlite3";
import fs from "fs";
import path from "path";
import { settings } from "@/config/settings";
import { logger } from "@/lib/logger";

class DatabaseConnectionError extends Error {
  constructor(message) {
    super(message);
    this.name = "DatabaseConnectionError";
  }
}

class DatabaseManager {
  constructor() {
    this._db = null;
  }

  getConnection() {
    if (this._db) {
      return this._db;
    }

    try {
      // Ensure the data directory exists before connecting
      const dataDir = path.dirname(settings.databaseFile);
      if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir, { recursive: true });
      }

      this._db = new Database(settings.databaseFile);
      this._db.pragma("journal_mode = WAL");

      logger.info("Connected to SQLite.", { file: settings.databaseFile });

      return this._db;
    } catch (error) {
      logger.error("Failed to connect to SQLite.", { error: error.message });
      throw new DatabaseConnectionError("Unable to connect to SQLite.");
    }
  }

  initSchema() {
    const db = this.getConnection();
    const schemaPath = path.join(process.cwd(), "src/database/schema.sql");
    const schema = fs.readFileSync(schemaPath, "utf-8");
    db.exec(schema);
    logger.info("Database schema initialized.");
  }
}

export const dbManager = new DatabaseManager();
export { DatabaseConnectionError };
export default dbManager;
```

Notice the parallels to the original: one class owns the connection, logs on success, and raises a **custom, meaningful exception** (`DatabaseConnectionError`) on failure instead of a generic error [5] [9]. We're already anticipating Part 6's custom exception pattern here, just like the original series did in Part 2 before formalizing it later.

`better-sqlite3` is synchronous and returns plain JS objects for rows automatically — this gives us the same dict-like row access that `sqlite3.Row` provided in Python, with no extra configuration needed [9].

---

## Step 3 — Seed the Database

The original series seeded the database with sample customer records after creating the table [9]. Let's do the same with a small seed script.

**src/database/seed.js**
```js
// src/database/seed.js
import { dbManager } from "@/database/database";
import { logger } from "@/lib/logger";

function seed() {
  dbManager.initSchema();
  const db = dbManager.getConnection();

  const existing = db.prepare("SELECT COUNT(*) AS count FROM customers").get();

  if (existing.count > 0) {
    logger.info("Customers table already seeded, skipping.");
    return;
  }

  const insert = db.prepare(`
    INSERT INTO customers (first_name, last_name, company, email, country)
    VALUES (@first_name, @last_name, @company, @email, @country)
  `);

  const sampleCustomers = [
    {
      first_name: "John",
      last_name: "Smith",
      company: "Greymatter Consulting",
      email: "john@example.com",
      country: "Singapore",
    },
    {
      first_name: "Amara",
      last_name: "Diallo",
      company: "Diallo Textiles",
      email: "amara@example.com",
      country: "Senegal",
    },
    {
      first_name: "Li",
      last_name: "Wei",
      company: "Wei Logistics",
      email: "liwei@example.com",
      country: "Singapore",
    },
  ];

  const insertMany = db.transaction((customers) => {
    for (const customer of customers) {
      insert.run(customer);
    }
  });

  insertMany(sampleCustomers);

  logger.info("Seeded customers table.", { count: sampleCustomers.length });
}

seed();
```

Run it with:

```bash
node -r dotenv/config src/database/seed.js
```

(Or add a script to `package.json`: `"seed": "node src/database/seed.js"` and run `npm run seed`.)

Just like the original, we wrap the inserts in a **transaction** — the same reliability practice the original series highlighted: use transactions, context managers, logging, and exception handling to create a reliable data access layer [9].

---

## Step 4 — Build the `CustomerRepository`

Now the repository itself — the piece responsible for retrieving data for document generation [9]. This is the JS equivalent of the original's `CustomerRepository`, following the same Repository pattern.

**src/repositories/customerRepository.js**
```js
// src/repositories/customerRepository.js
import { dbManager } from "@/database/database";
import { logger } from "@/lib/logger";

export class CustomerRepository {
  getCustomerById(id) {
    try {
      const db = dbManager.getConnection();
      const stmt = db.prepare("SELECT * FROM customers WHERE id = ?");
      const customer = stmt.get(id);

      if (!customer) {
        logger.info("No customer found.", { id });
        return null;
      }

      return customer;
    } catch (error) {
      logger.error("Failed to fetch customer.", { id, error: error.message });
      throw error;
    }
  }

  getAllCustomers() {
    try {
      const db = dbManager.getConnection();
      const stmt = db.prepare("SELECT * FROM customers ORDER BY id ASC");
      return stmt.all();
    } catch (error) {
      logger.error("Failed to fetch customers.", { error: error.message });
      throw error;
    }
  }

  createCustomer(customer) {
    try {
      const db = dbManager.getConnection();
      const stmt = db.prepare(`
        INSERT INTO customers (first_name, last_name, company, email, country)
        VALUES (@first_name, @last_name, @company, @email, @country)
      `);
      const result = stmt.run(customer);
      logger.info("Customer created.", { id: result.lastInsertRowid });
      return result.lastInsertRowid;
    } catch (error) {
      logger.error("Failed to create customer.", { error: error.message });
      throw error;
    }
  }
}

export const customerRepository = new CustomerRepository();
export default customerRepository;
```

Every method: opens a connection through the shared `DatabaseManager`, logs what happened, and never lets a raw database error leak out unlogged — exactly the reliability standard the original repository layer set [9] [1].

---

## Step 5 — Verify With an API Route

Let's prove this works end-to-end, the same way we verified Part 1 with a health-check route.

**src/app/api/customers/route.js**
```js
// src/app/api/customers/route.js
import { NextResponse } from "next/server";
import { customerRepository } from "@/repositories/customerRepository";
import { logger } from "@/lib/logger";

export async function GET() {
  try {
    const customers = customerRepository.getAllCustomers();
    logger.info("Fetched customers.", { count: customers.length });
    return NextResponse.json({ customers });
  } catch (error) {
    logger.error("GET /api/customers failed.", { error: error.message });
    return NextResponse.json(
      { error: "Unable to fetch customers." },
      { status: 500 }
    );
  }
}
```

Run the seed script, start the dev server, and visit:

```text
http://localhost:3000/api/customers
```

You should see your three seeded customers returned as JSON — proof that our data access layer is fully wired up.

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `Cannot find module 'better-sqlite3'` | Dependency not installed | Re-run `npm install better-sqlite3` from Part 1 |
| `SQLITE_CANTOPEN` error | The `data/` directory doesn't exist yet | Ensure `DatabaseManager.getConnection()` creates the directory before connecting (it does in our code above), or manually run `mkdir data` |
| `/api/customers` returns an empty array | Seed script wasn't run, or ran against a different DB file | Run `npm run seed` and confirm `settings.databaseFile` points to the same path used by both scripts |
| Seed script inserts duplicate rows every time it runs | No "already seeded" guard | Our `seed.js` checks `COUNT(*)` first and skips if customers already exist — confirm that check wasn't removed |
| `database is locked` errors | Multiple processes writing without WAL mode | Confirm `db.pragma("journal_mode = WAL")` is set in `DatabaseManager.getConnection()` |

This mirrors the same categories of issues the original Python version had to guard against — missing directories, uninitialized schemas, and duplicate seed inserts — just with SQLite driver–specific error codes instead of Python's `sqlite3.Error` [9].

---

## Chapter Summary

In this chapter, you:

* Designed a `customers` table schema matching the fields used later for placeholder templates
* Built a `DatabaseManager` that centralizes all SQLite connection logic, uses WAL mode, and raises a meaningful `DatabaseConnectionError` instead of a generic error
* Wrote a seed script that safely inserts sample customer data using a transaction, guarding against duplicate seeding
* Built a `CustomerRepository` following the Repository pattern — the only layer allowed to touch SQLite directly
* Verified everything end-to-end with a `/api/customers` API route

This gives Greymatter Docs the same foundation the original series established: a database layer that's isolated, reusable, and ready for the orchestrator to call in later parts, without any component above it needing to know SQLite exists [9] [1].
