## Part 6: Resilience & Observability

Implementing "Try-Catch" logic within workflows, retry policies, and log streaming for a real audit trail. This is what separates a demo automation from one you can be paged for at 3 AM.

### 6.1 Failure Modes You Must Design For

| Failure | Example | Mitigation |
|---|---|---|
| Transient network error | Third-party API times out | Node-level retry with backoff |
| Bad input data | Malformed webhook payload | Validation + dead-letter routing (Part 3/4) |
| Downstream service down | Postgres or Ollama unreachable | Error Trigger workflow + alerting |
| Partial batch failure | 3 of 50 items fail transformation | Per-item error isolation ("Continue on Fail") |
| Silent logic bug | Wrong field mapped, no crash | Structured audit logging + assertions |

### 6.2 Node-Level Retry Policies

- **Retry On Fail:** ON
- **Max Tries:** 3–5 for flaky external HTTP calls; leave OFF for non-idempotent side effects (e.g., a payment charge) unless you've implemented an idempotency key (Part 2.2).
- **Wait Between Tries:** start at 1000ms; for rate-limited APIs, prefer explicit exponential backoff in a Code node:

```javascript
// Code node: "Call With Exponential Backoff"
async function callWithBackoff(url, options, maxAttempts = 5) {
  let attempt = 0;
  while (attempt < maxAttempts) {
    try {
      const res = await this.helpers.httpRequest({ url, ...options });
      return res;
    } catch (err) {
      attempt++;
      if (attempt >= maxAttempts) throw err;
      const delayMs = Math.min(1000 * 2 ** attempt, 30_000) + Math.random() * 250;
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
}

const result = await callWithBackoff.call(this, 'https://api.example.com/data', { method: 'GET' });
return [{ json: result }];
```

> `this.helpers.httpRequest` is n8n's Code-node HTTP client — prefer it over raw `fetch`/`axios` so requests respect n8n's proxy/timeout config.

### 6.3 "Try-Catch" at the Workflow Level: Error Workflows

Any workflow can designate an **Error Workflow** (Settings → Error Workflow) that receives execution data whenever it fails.

**Step 1 — Build a central "Global Error Handler" workflow:**

```
[Error Trigger] -> [Code: Format Error Context] -> [Postgres: INSERT into error_log]
                                                   -> [IF: severity == 'critical'] -> [HTTP Request: Slack/Discord webhook]
```

```sql
CREATE TABLE IF NOT EXISTS error_log (
  id SERIAL PRIMARY KEY,
  workflow_name TEXT NOT NULL,
  workflow_id TEXT NOT NULL,
  execution_id TEXT NOT NULL,
  node_name TEXT,
  error_message TEXT,
  severity TEXT NOT NULL DEFAULT 'error',
  raw_execution JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

```javascript
// Code node: "Format Error Context" (inside the Error Trigger workflow)
const err = $json;

const nodeName = err.execution?.lastNodeExecuted ?? 'unknown';
const message = err.execution?.error?.message ?? 'Unknown error';

const criticalKeywords = ['postgres', 'payment', 'charge', 'customers'];
const severity = criticalKeywords.some(k => nodeName.toLowerCase().includes(k) || message.toLowerCase().includes(k))
  ? 'critical'
  : 'error';

return [{
  json: {
    workflowName: err.workflow?.name ?? 'unknown',
    workflowId: err.workflow?.id ?? 'unknown',
    executionId: err.execution?.id ?? 'unknown',
    nodeName,
    errorMessage: message,
    severity,
    rawExecution: err,
  },
}];
```

**Step 2 — Attach it to EVERY production workflow** (Part 2 webhook, Part 4 CRUD, Part 5 agent) — a checklist item you'll see again in Appendix C.

**Step 3 — Alert on critical severity:**

```javascript
// Code node: "Build Slack Alert Payload" (only reached if severity == 'critical')
return [{
  json: {
    text: `🚨 *Critical failure* in \`${$json.workflowName}\`\nNode: \`${$json.nodeName}\`\nError: ${$json.errorMessage}\nExecution: ${$json.executionId}`,
  },
}];
```
Followed by `HTTP Request` POSTing to a Slack/Discord webhook (stored as credential, not hardcoded).

### 6.4 Per-Item Error Isolation: "Continue On Fail"

Enable **Continue On Fail** on the node, inspect `error` per item:

```javascript
// Code node: "Split Success vs Failure" (fed by a node with Continue On Fail enabled)
const successes = [];
const failures = [];

for (const item of $input.all()) {
  if (item.json.error) {
    failures.push({ json: { ...item.json, _failedAt: new Date().toISOString() } });
  } else {
    successes.push(item);
  }
}

return successes;
```

In practice, wire with a `Switch` node (Success/Failure outputs) rather than manual redirection.

```sql
CREATE TABLE IF NOT EXISTS dead_letter_queue (
  id SERIAL PRIMARY KEY,
  source_workflow TEXT NOT NULL,
  item_payload JSONB NOT NULL,
  error_message TEXT,
  reprocessed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

A separate "Reprocess Dead Letters" workflow reads `WHERE reprocessed = false`, retries, and flips the flag — a safe replay mechanism instead of silently dropped data.

### 6.5 Log Streaming for Audit Trails

```yaml
# Additions to the n8n service's environment block in docker-compose.yml
      N8N_LOG_LEVEL: info
      N8N_LOG_OUTPUT: console,file
      N8N_LOG_FILE_LOCATION: /home/node/.n8n/logs/n8n.log
```

Prefer the Postgres-based `audit_log`/`error_log` tables for structured, queryable trails — logs answer "what happened technically," these tables answer "who did what to which record" (what compliance actually asks for).

### 6.6 A Minimal Observability Dashboard Query Set

```sql
-- Error rate by workflow, last 24h
SELECT workflow_name, COUNT(*) AS error_count
FROM error_log
WHERE created_at > now() - interval '24 hours'
GROUP BY workflow_name
ORDER BY error_count DESC;

-- Dead letter backlog
SELECT source_workflow, COUNT(*) AS pending
FROM dead_letter_queue
WHERE reprocessed = false
GROUP BY source_workflow;

-- Slowest executions today
SELECT "workflowId", "startedAt",
       EXTRACT(EPOCH FROM ("stoppedAt" - "startedAt")) AS duration_seconds
FROM execution_entity
WHERE "startedAt" > now() - interval '1 day'
ORDER BY duration_seconds DESC
LIMIT 10;
```

### 6.7 Exercise Challenge

1. Attach the Global Error Handler to all workflows from Parts 2, 4, 5; force a failure in each and confirm correct `severity` lands in `error_log`.
2. Implement the Reprocess Dead Letters workflow; prove it flips `reprocessed = true` only on successful retry.
3. Add an email alert channel that only fires when the same workflow produces 3+ critical errors within 10 minutes (a basic circuit-breaker guard).

### 6.8 Solution Notes

For (3): `SELECT COUNT(*) FROM error_log WHERE workflow_name = $1 AND severity = 'critical' AND created_at > now() - interval '10 minutes'` — only alert once the count crosses your threshold, preventing alert fatigue during sustained outages.

### 6.9 What's Next

Part 7 puts every workflow under real version control — exporting JSON definitions, diffing changes, and reviewing them via pull requests before production.
