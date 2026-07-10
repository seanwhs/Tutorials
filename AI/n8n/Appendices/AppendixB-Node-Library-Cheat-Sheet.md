## Appendix B: The Node Library Cheat Sheet

Quick-reference tables for data mapping, writing robust Code nodes, and workflow branching logic. Bookmark this — you'll return to it more than any other note in the series.

### B.1 Data Mapping Tips

| Task | Best Node/Technique | Tip |
|---|---|---|
| Rename a field | `Set` (Edit Fields) | Prefer over Code node for readability/diffability |
| Combine fields from two branches | `Merge` node, mode "Combine" | Match on a key field, not positional index, whenever order isn't guaranteed |
| Flatten a nested array into multiple items | `Split Out` | Use for simple cases; use Code node (Part 3.4) when per-line enrichment from the parent object is needed |
| Convert many items into one aggregated item | `Aggregate` / `Summarize` | Faster and clearer than a Code node `reduce` for simple sums/counts/lists |
| Access a prior (non-immediately-upstream) node's output | `$('Node Name').item.json.field` | Works across the whole execution — invaluable when branches rejoin |
| Reference the current item consistently | `$json` | Always refers to the item currently being processed |
| Get workflow-level metadata | `$workflow.id`, `$workflow.name` | Useful for audit logs (Part 4, 6) |
| Get execution-level metadata | `$execution.id` | Correlate logs/audit rows back to a specific run |
| Static, persisted-between-runs values | `$getWorkflowStaticData('global')` | Lightweight; use a real DB table if needed outside n8n (Part 2.4) |
| Date/time math | Luxon via expressions: `{{ $now.plus({days: 1}) }}` | n8n exposes Luxon directly — avoid hand-rolled date math |
| Type coercion in expressions | `{{ Number($json.qty) }}`, `{{ String($json.id) }}` | Coerce explicitly rather than relying on implicit JS coercion |

### B.2 Writing Robust Code Nodes

| Principle | Do | Don't |
|---|---|---|
| Input safety | Guard every nested access: `order.customer?.email ?? 'unknown'` | Assume upstream shape never changes |
| Return shape | Always `return` an array of `{ json: {...} }` (All Items) or one object (Each Item) | Return raw values or forget the `json` wrapper |
| Error signaling | `throw new Error('clear message')` to route to the Error Workflow (Part 6) | Silently `return []` on failure |
| Side effects | Keep Code nodes pure; push writes to dedicated nodes downstream | Bury a fetch/DB call deep inside a "transformation" Code node |
| Secrets | Reference via `$credentials.name` | Hardcode API keys/passwords as string literals |
| Performance | Use `Map`/`Set` for lookups and dedup (Part 3.9) | Use `array.find()`/`array.includes()` in a loop over large datasets |
| Testability | Pin sample input data (Part 3.8) and iterate against it | Re-trigger the real webhook/API for every code tweak |
| Language consistency | Pick JS or Python per workflow and stay consistent | Mix JS and Python Code nodes in one workflow |
| Logging | `console.log()` for debug output | Rely on `alert()`-style patterns (don't exist in this sandbox) |
| Async code | Use `await` directly — n8n supports async Code nodes | Forget `await` on a Promise-returning call |

### B.3 Workflow Branching Logic

| Scenario | Node | Notes |
|---|---|---|
| Simple two-way boolean split | `IF` | Cleanest for a single condition |
| Multi-way split on a discrete value | `Switch` | Prefer over chained `IF`s at 3+ branches |
| Route based on tool-call intent (AI Agent) | Tool `description` field | LLM reads descriptions to choose — write precisely (Part 5.5) |
| Fan-out to parallel branches that must all complete | `Merge` ("Wait for all inputs") | Needed when two systems must both succeed before responding |
| Stop a branch early without error | `NoOp` node or empty return | Cleaner than throwing for expected business logic |
| Conditional error handling per item | `Continue On Fail` + downstream `Switch` | Part 6.4 — isolates one bad item from failing the whole batch |
| Loop over items N-at-a-time | `Split In Batches` (Loop node) | Pairs with `Wait` node to respect rate limits |
| Guard against duplicate/overlapping runs | `IF` gated on a Postgres lock-row check | Not native — hand-rolled with a lock table (Part 2.3) |

### B.4 Expression Quick Reference

| Expression | Result |
|---|---|
| `{{ $json.email.toLowerCase() }}` | Lowercased email from current item |
| `{{ $('Webhook').item.json.headers['x-api-key'] }}` | Read a header from a named upstream node |
| `{{ $now.toISO() }}` | Current timestamp, ISO 8601 |
| `{{ $itemIndex }}` | Zero-based index in "Run Once for Each Item" |
| `{{ $input.all().length }}` | Count of items entering this node |
| `{{ JSON.stringify($json) }}` | Serialize the current item (audit log payloads) |
| `{{ $json.price * 1.08 }}` | Inline math — use `Set` node fields instead of Code |

### B.5 When NOT to Use a Given Node (Common Anti-Patterns)

| Anti-pattern | Why it's a problem | Fix |
|---|---|---|
| A Code node that only renames 2 fields | Hides simple logic, harder to diff | Use `Set` |
| An `IF` node chain 5 levels deep | Unreadable graph | Use `Switch`, or one Code node |
| Hardcoded credentials in a Code node string | Security risk, breaks CI secret scan | Use n8n Credentials + `$credentials` |
| A single giant Code node doing fetch + transform + DB write | Untestable, opaque errors | Split into `HTTP Request → Code → Postgres` |
| Public Webhook with `authentication: none` | Anyone can trigger it | Header Auth or HMAC (Part 2.2) |
