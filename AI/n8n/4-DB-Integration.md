## Part 4: Database Integration

Configuring PostgreSQL nodes for CRUD operations, and building a workflow that acts as a secure, audited backend API for a frontend (e.g., Next.js) form — no traditional backend server required.

### 4.1 Architecture: n8n as a Backend API

```
[Next.js Form] --POST--> [n8n Webhook] --validate--> [Postgres Node: INSERT]
                                                            |
                                                    [Postgres Node: audit_log INSERT]
                                                            |
                                                    [Respond to Webhook: 201]
```

This replaces a hand-rolled Express/Next.js API route for simple CRUD-behind-a-form use cases — the frontend only ever talks to a stable webhook URL.

### 4.2 Provisioning a Dedicated "Business" Database

Don't reuse n8n's own internal Postgres database (Part 1) for application data — keep them logically separate.

```sql
-- Run once via: docker compose exec postgres psql -U n8n_admin -d postgres
CREATE DATABASE app_db;
```

```sql
-- Connect to app_db, then create the schema
\c app_db

CREATE TABLE IF NOT EXISTS customers (
  id SERIAL PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_log (
  id SERIAL PRIMARY KEY,
  workflow_name TEXT NOT NULL,
  execution_id TEXT NOT NULL,
  action TEXT NOT NULL,          -- 'CREATE' | 'UPDATE' | 'DELETE' | 'READ'
  entity TEXT NOT NULL,          -- e.g. 'customers'
  entity_id TEXT,
  actor TEXT,                    -- e.g. caller IP, API key label
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_entity ON audit_log (entity, entity_id);
```

### 4.3 Configuring the Postgres Credential in n8n

**Credentials → New → Postgres**:

| Field | Value |
|---|---|
| Host | `postgres` (Docker service name) |
| Port | `5432` |
| Database | `app_db` |
| User | A dedicated least-privilege user (4.4), not `n8n_admin` |
| SSL | `disable` for local dev; `require` in production (Part 8) |

### 4.4 Principle of Least Privilege: A Dedicated App Role

```sql
CREATE ROLE app_workflow_user WITH LOGIN PASSWORD 'use_a_real_secret_here';
GRANT CONNECT ON DATABASE app_db TO app_workflow_user;
\c app_db
GRANT USAGE ON SCHEMA public TO app_workflow_user;
GRANT SELECT, INSERT, UPDATE ON customers TO app_workflow_user;
GRANT SELECT, INSERT ON audit_log TO app_workflow_user; -- no UPDATE/DELETE — audit logs are append-only
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_workflow_user;
```

Note: no `DELETE` grant on `customers` — deletions route through a soft-delete flag instead (4.6).

### 4.5 The CREATE Workflow (Secure Intake From a Next.js Form)

**Trigger:** `Webhook` (POST `/api/customers`), Header Auth credential holding an API key sent via `Authorization: Bearer <key>` (never expose to the browser — call from a Server Action/Route Handler).

**Step 1 — Validate input shape:**

```javascript
// Code node: "Validate Customer Payload"
const body = $input.first().json.body;

const errors = [];
if (!body.fullName || typeof body.fullName !== 'string' || body.fullName.trim().length < 2) {
  errors.push('fullName is required (min 2 chars)');
}
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!body.email || !emailRegex.test(body.email)) {
  errors.push('email must be a valid address');
}

if (errors.length > 0) {
  throw new Error(`Validation failed: ${errors.join('; ')}`);
}

return [{
  json: {
    fullName: body.fullName.trim(),
    email: body.email.toLowerCase().trim(),
  },
}];
```

**Step 2 — Insert via Postgres node** (`Execute Query`, for `ON CONFLICT`/`RETURNING`):

```sql
INSERT INTO customers (full_name, email)
VALUES ($1, $2)
ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name, updated_at = now()
RETURNING id, full_name, email, created_at;
```

Query parameters (positional):
```
={{ $json.fullName }}
={{ $json.email }}
```

> **Always use parameterized queries.** Never string-interpolate user input into SQL — direct injection vector.

**Step 3 — Write the audit log:**

```sql
INSERT INTO audit_log (workflow_name, execution_id, action, entity, entity_id, actor, payload)
VALUES ($1, $2, 'CREATE', 'customers', $3, $4, $5);
```

Parameters:
```
={{ $workflow.name }}
={{ $execution.id }}
={{ $json.id }}
={{ $('Webhook').item.json.headers['x-api-key-label'] || 'unknown' }}
={{ JSON.stringify($json) }}
```

**Step 4 — Respond to the frontend:**
```
Respond to Webhook → 201, body: {{ { success: true, customer: $json } }}
```

### 4.6 READ, UPDATE, DELETE (Soft Delete) Workflows

**READ** (GET `/api/customers/:id`):
```sql
SELECT id, full_name, email, created_at, updated_at
FROM customers
WHERE id = $1 AND deleted_at IS NULL;
```
(Add `deleted_at TIMESTAMPTZ` via `ALTER TABLE customers ADD COLUMN deleted_at TIMESTAMPTZ;`)

**UPDATE:**
```sql
UPDATE customers
SET full_name = $1, updated_at = now()
WHERE id = $2 AND deleted_at IS NULL
RETURNING id, full_name, email, updated_at;
```

**DELETE (soft):**
```sql
UPDATE customers
SET deleted_at = now()
WHERE id = $1
RETURNING id;
```

Each follows the same shape as CREATE: `Webhook → Validate (Code) → Postgres → Audit Log INSERT → Respond to Webhook`. Part 7 shows how to DRY these via a shared sub-workflow for the audit-log step.

### 4.7 Calling This From Next.js

```typescript
// app/actions/create-customer.ts (Server Action — key never reaches the browser)
'use server';

export async function createCustomer(formData: FormData) {
  const res = await fetch(process.env.N8N_CUSTOMER_WEBHOOK_URL!, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${process.env.N8N_API_KEY}`,
      'x-api-key-label': 'nextjs-app',
    },
    body: JSON.stringify({
      fullName: formData.get('fullName'),
      email: formData.get('email'),
    }),
  });

  if (!res.ok) {
    const errorBody = await res.json().catch(() => ({}));
    throw new Error(errorBody.message ?? 'Failed to create customer');
  }

  return res.json();
}
```

### 4.8 Connection Pooling Consideration

Every workflow execution opens a Postgres connection — under load this can exhaust `max_connections` (default 100). Part 8 fronts Postgres with **PgBouncer** (transaction pooling); be aware Queue Mode workers multiply concurrent connections.

### 4.9 Exercise Challenge

1. Build READ and soft-DELETE workflows end-to-end, including audit log writes.
2. Add rate limiting via a `rate_limits` table + Code node, rejecting >100 req/hour with `429`.
3. Modify CREATE so a duplicate email (`ON CONFLICT` branch) logs `'UPDATE'` instead of `'CREATE'`.

### 4.10 Solution Notes

For (3): compare `created_at`/`updated_at` in the `RETURNING` clause — equal means fresh insert; otherwise route via `IF` to log `'UPDATE'`.

### 4.11 What's Next

Part 5 wires an AI Agent into this architecture — using this Part 4 CRUD workflow as a callable **Tool** the agent can invoke.
