# Logging and Observability Standard

In a distributed landscape of **50+ applications**, searching through raw text logs is impossible. To debug a single user request that spans ten different services, logs must be treated as **structured data**. This standard ensures that every log entry across the enterprise is machine-readable and globally searchable.

---

## 1. The Core Standard: JSON over Plain Text

All applications must emit logs in **Structured JSON format**. This allows our centralized logging platform (ELK, Splunk, or Datadog) to index specific fields without expensive regex parsing.

---

## 2. Mandatory Common Schema

Every log entry must contain the following "Core" fields to enable cross-service correlation:

| Field | Type | Description |
| --- | --- | --- |
| `timestamp` | ISO8601 | Use UTC format (e.g., `2024-05-20T14:30:00.000Z`). |
| `level` | String | Must be one of: `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`. |
| `service_id` | String | The unique name of the service (e.g., `payment-service`). |
| `trace_id` | String | **The most critical field.** Used to correlate logs across services. |
| `span_id` | String | Identifies the specific operation within a service. |
| `message` | String | A human-readable summary of the event. |
| `context` | Object | Optional key-value pairs for domain-specific data (e.g., `order_id`). |

---

## 3. Log Correlation & Trace Propagation

To track a request across the ecosystem, the **Trace ID** must be propagated through every hop.

1. **Entry Point:** The API Gateway generates a `trace_id` if one doesn't exist.
2. **Propagation:** The ID is passed via HTTP Headers (`X-Trace-Id` or W3C `traceparent`) or Kafka Message Headers.
3. **Logging:** The Shared Logging Library automatically extracts this ID and attaches it to every log statement.

---

## 4. Error Logging & Exception Handling

When an error occurs, the log must provide actionable "Forensics."

* **Stack Traces:** Should be included in the `exception` field (as a string or object) only for `ERROR` and `FATAL` levels.
* **Avoid PII:** Never log passwords, credit card numbers, or sensitive PII. Shared libraries should include a "Masking" filter.
* **HTTP Context:** For web services, include `http_method`, `url`, and `status_code`.

---

## 5. Logging Levels & Policy

* **INFO:** Normal operational events (e.g., "Order Processed").
* **WARN:** Non-critical issues that might need attention (e.g., "Database connection retry").
* **ERROR:** A specific request failed, but the service is still running.
* **FATAL:** The service is crashing or cannot function (e.g., "Cannot connect to Kafka").

> **Performance Tip:** Avoid "Logging in Loops." If a process handles 10,000 items, log a summary at the end rather than one line per item.

---

## 6. Compliance Checklist

* [ ] Is the service emitting logs in JSON format?
* [ ] Is the `trace_id` being propagated from incoming requests to outgoing calls?
* [ ] Are sensitive PII fields being masked or excluded?
* [ ] Does the `timestamp` use the ISO8601 UTC format?
* [ ] Is the service registered in the logging platform with the correct `service_id`?

---

### Recommended Learning

**The Three Pillars of Observability**
Understand the relationship between Metrics, Logging, and Tracing:
[https://www.youtube.com/watch?v=mP07IsUf09w](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3DmP07IsUf09w)

---

