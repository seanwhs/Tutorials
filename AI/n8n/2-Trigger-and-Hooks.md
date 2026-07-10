## Part 2: Triggers & Hooks

Mastering Webhooks, Cron, and polling — building robust entry points for incoming data from external apps.

### 2.1 The Three Trigger Families

| Family | Node | Use When | Key Risk |
|---|---|---|---|
| Push (event-driven) | **Webhook** | An external system can call you (Stripe, GitHub, a frontend form) | Unauthenticated/unverified calls, duplicate delivery |
| Time-driven | **Cron / Schedule Trigger** | Periodic sweeps (nightly reports, cleanup jobs) | Overlapping runs, missed runs during downtime |
| Pull (poll-driven) | **Polling triggers** (Schedule + HTTP Request) | External system has no webhook support | Duplicate processing, rate limits, drift |

### 2.2 Webhook Node: The Production-Grade Pattern

A naive Webhook node just returns 200 OK to anything. In production you must verify the caller, respond fast, and deduplicate.

**Step 1 — Create the Webhook node**
- Node: `Webhook`, Method: `POST`, Path: `intake/orders` (custom, predictable, not the random UUID default)
- Respond: `Using 'Respond to Webhook' Node` (NOT "Immediately") — lets you validate first
- Authentication: `Header Auth` bound to a credential holding a shared secret header (`X-Webhook-Secret`)

**Step 2 — Verify HMAC signature** (for providers like Stripe/GitHub that sign the raw body):

```javascript
// Code node: "Verify HMAC Signature"
const crypto = require('crypto');

const secret = $credentials.webhookHmacSecret; // stored as an n8n credential, never hardcoded
const signatureHeader = $input.first().json.headers['x-hub-signature-256'] || '';
const rawBody = $input.first().json.body; // requires "Raw Body" enabled on the Webhook node

const expected = 'sha256=' + crypto
  .createHmac('sha256', secret)
  .update(JSON.stringify(rawBody))
  .digest('hex');

const isValid = crypto.timingSafeEqual(
  Buffer.from(signatureHeader),
  Buffer.from(expected)
);

if (!isValid) {
  throw new Error('Invalid webhook signature — possible spoofed request');
}

return $input.all();
```

> **Note:** Enable "Raw Body" in the Webhook node's Options so you sign/verify the exact bytes the provider signed — re-serialized JSON can break HMAC checks.

**Step 3 — Respond immediately, process asynchronously**

```
[Webhook] → [Verify HMAC (Code)] → [Respond to Webhook: 202 {"status":"accepted"}] → [Process Order...]
```

**Step 4 — Idempotency / dedup**

```sql
-- run once, in Part 4's Postgres instance
CREATE TABLE IF NOT EXISTS webhook_dedup (
  event_id TEXT PRIMARY KEY,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

```javascript
// Code node: "Dedup Check" (paired with a Postgres node using ON CONFLICT DO NOTHING)
// Actual insert-or-skip happens in a Postgres node:
// INSERT INTO webhook_dedup (event_id) VALUES ($1) ON CONFLICT DO NOTHING RETURNING event_id
return [{ json: { eventId: $input.first().json.body.id } }];
```

Follow with an `IF` node: if the Postgres `RETURNING` result is empty (conflict → already processed), stop the branch; otherwise continue.

### 2.3 Cron / Schedule Trigger: Doing It Right

- Prefer **Cron Expression** mode (e.g., `0 2 * * *`) over the simplified "Every X" UI — unambiguous and diffable.
- **Design for idempotent re-runs.** A nightly job should be safe to run twice.
- **Guard against overlap** using a lock-row pattern:

```sql
CREATE TABLE IF NOT EXISTS job_locks (
  job_name TEXT PRIMARY KEY,
  locked_at TIMESTAMPTZ,
  locked_by TEXT
);
```

```javascript
// Code node: "Acquire Lock" — right after the Schedule Trigger
// Paired with a Postgres node:
// UPDATE job_locks SET locked_at = now(), locked_by = $1
// WHERE job_name = $2 AND (locked_at IS NULL OR locked_at < now() - interval '30 minutes')
// RETURNING job_name;
// If RETURNING is empty, another instance is still running — abort via IF node.
return [{ json: { jobName: 'nightly_order_sync', runner: $execution.id } }];
```

Release the lock at the end (`UPDATE job_locks SET locked_at = NULL WHERE job_name = 'nightly_order_sync'`), including on the error branch (Part 6).

### 2.4 Polling Triggers: The Generic Pattern

`Schedule Trigger (every 5 min) → HTTP Request (GET /events?since=<cursor>) → Code (dedup + advance cursor) → downstream`

```javascript
// Code node: "Read & Advance Cursor"
const staticData = $getWorkflowStaticData('global');
const since = staticData.lastPolledAt || new Date(Date.now() - 3600_000).toISOString();

// ... after the HTTP Request node fetches items newer than `since` ...
const items = $input.all();
if (items.length > 0) {
  const timestamps = items.map(i => new Date(i.json.updatedAt).getTime());
  staticData.lastPolledAt = new Date(Math.max(...timestamps) + 1).toISOString();
}

return items;
```

> **Why `+ 1` millisecond?** Prevents re-fetching the same "latest" record next poll due to inclusive `>=` filters.

### 2.5 Full Example Workflow JSON (Hardened Webhook Intake)

```json
{
  "name": "Part2 - Hardened Webhook Intake",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "intake/orders",
        "responseMode": "responseNode",
        "options": { "rawBody": true }
      },
      "id": "1",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "position": [240, 300]
    },
    {
      "parameters": {
        "jsCode": "const crypto = require('crypto');\nconst secret = $credentials.webhookHmacSecret;\nconst sig = $input.first().json.headers['x-hub-signature-256'] || '';\nconst raw = $input.first().json.body;\nconst expected = 'sha256=' + crypto.createHmac('sha256', secret).update(JSON.stringify(raw)).digest('hex');\nif (sig !== expected) { throw new Error('Invalid signature'); }\nreturn $input.all();"
      },
      "id": "2",
      "name": "Verify HMAC Signature",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [460, 300]
    },
    {
      "parameters": {
        "respondWith": "json",
        "responseBody": "={{ { status: 'accepted' } }}",
        "options": { "responseCode": 202 }
      },
      "id": "3",
      "name": "Respond to Webhook",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1,
      "position": [680, 300]
    }
  ],
  "connections": {
    "Webhook": { "main": [[{ "node": "Verify HMAC Signature", "type": "main", "index": 0 }]] },
    "Verify HMAC Signature": { "main": [[{ "node": "Respond to Webhook", "type": "main", "index": 0 }]] }
  }
}
```

### 2.6 Exercise Challenge

1. Extend the JSON above with the dedup Postgres check (2.2 Step 4) between "Verify HMAC Signature" and "Respond to Webhook."
2. Build a polling workflow against `https://jsonplaceholder.typicode.com/posts` that only forwards "new" posts using the cursor pattern — simulate `updatedAt` by tracking the highest `id` seen.
3. Add overlap protection to a Cron-triggered workflow using `job_locks`, and verify by triggering it twice in quick succession.

### 2.7 Solution Notes

For (2): since jsonplaceholder posts have no `updatedAt`, the cursor becomes `lastMaxId`, and filtering happens client-side in a Code node (`items.filter(i => i.json.id > lastMaxId)`) — a realistic constraint with legacy REST APIs.

For (3): the second trigger's `UPDATE ... RETURNING` should return zero rows (lock still active), routing to a no-op "Skip — already running" branch.

### 2.8 What's Next

Part 3 goes deep on the Code node — covering JSON parsing, array reshaping, and normalization patterns that standard nodes can't express.
