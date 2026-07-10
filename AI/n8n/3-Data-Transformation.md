## Part 3: Data Transformation — The "Code" Philosophy

Standard nodes (Set, Filter, Merge) cover 70% of data shaping needs. The other 30% — nested arrays, conditional reshaping, multi-source normalization — is where the **Code node** earns its place as a first-class citizen of your workflow, not an escape hatch.

### 3.1 When to Reach for the Code Node (and When Not To)

| Situation | Use | Why |
|---|---|---|
| Rename/derive a handful of fields | `Set` node | Declarative, visually diffable, no JS to maintain |
| Simple truthy/comparison branching | `IF` / `Switch` | Same reason |
| Flattening nested arrays, `groupBy`, deduplication by key, complex `reduce` logic | **Code node** | Requires imperative logic `Set`/`Filter` cannot express |
| Calling a small pure function repeatedly across a pipeline | **Code node** + shared snippet | Keeps logic testable and DRY |

**Rule of thumb:** if you're chaining more than 3 `Set`/`IF` nodes for one transformation, collapse it into one well-commented Code node.

### 3.2 The Two Code Node Modes

- **Run Once for All Items** (default for most transformations): code receives `$input.all()`, must `return` an array of `{ json: {...} }` items. Use for cross-item work (grouping, sorting, dedup).
- **Run Once for Each Item**: code runs per item with `$json` as that item's data, returns a single object. Use for per-item mapping with error isolation (Part 6).

```javascript
// MODE: Run Once for All Items
const items = $input.all();
console.log(`Processing ${items.length} items`);
return items.map(item => ({ json: { ...item.json, processedAt: new Date().toISOString() } }));
```

```javascript
// MODE: Run Once for Each Item
return { ...$json, processedAt: new Date().toISOString() };
```

### 3.3 Core Pattern: Defensive JSON Parsing

```javascript
// Code node: "Safe Parse Incoming Payload"
function safeParse(value, fallback = null) {
  if (value == null) return fallback;
  if (typeof value === 'object') return value;
  try {
    return JSON.parse(value);
  } catch (err) {
    return fallback;
  }
}

const results = [];
for (const item of $input.all()) {
  const raw = item.json.body ?? item.json;
  const parsed = safeParse(raw.payload, {});

  results.push({
    json: {
      ...item.json,
      payload: parsed,
      _parseError: parsed === null,
    },
  });
}

return results;
```

Follow with an `IF` node checking `_parseError === true` to route bad payloads to a dead-letter path (full pattern in Part 6).

### 3.4 Core Pattern: Array Reshaping (Flatten, Group, Dedupe)

**Flattening** (order → per-line-item, enriched):

```javascript
// Code node: "Flatten Order Line Items"
const output = [];

for (const item of $input.all()) {
  const order = item.json;
  const lineItems = order.line_items ?? [];

  for (const line of lineItems) {
    output.push({
      json: {
        orderId: order.id,
        customerEmail: order.customer?.email ?? 'unknown',
        sku: line.sku,
        quantity: line.quantity,
        unitPrice: line.unit_price,
        lineTotal: Number((line.quantity * line.unit_price).toFixed(2)),
      },
    });
  }
}

return output;
```

**Grouping** (inverse — lines back into invoices):

```javascript
// Code node: "Group Line Items Back Into Invoices"
const groups = new Map();

for (const item of $input.all()) {
  const { orderId, ...rest } = item.json;
  if (!groups.has(orderId)) {
    groups.set(orderId, { orderId, lines: [], total: 0 });
  }
  const group = groups.get(orderId);
  group.lines.push(rest);
  group.total += rest.lineTotal;
}

return Array.from(groups.values()).map(g => ({
  json: { ...g, total: Number(g.total.toFixed(2)) },
}));
```

**Dedupe by composite key:**

```javascript
// Code node: "Dedupe by Composite Key"
const seen = new Set();
const output = [];

for (const item of $input.all()) {
  const key = `${item.json.customerEmail}::${item.json.sku}`;
  if (seen.has(key)) continue;
  seen.add(key);
  output.push(item);
}

return output;
```

### 3.5 Core Pattern: Normalization Across Heterogeneous Sources

```javascript
// Code node: "Normalize Customer Shape"
// Runs once for each item; source tagged upstream via a Set node
const source = $json._source;

const normalizers = {
  crm: (d) => ({
    email: d.emailAddress?.toLowerCase().trim(),
    fullName: `${d.firstName} ${d.lastName}`.trim(),
    signupDate: d.createdAt,
  }),
  csv: (d) => ({
    email: d.Email?.toLowerCase().trim(),
    fullName: d['Full Name']?.trim(),
    signupDate: d['Signup Date'],
  }),
};

const normalize = normalizers[source];
if (!normalize) {
  throw new Error(`Unknown source tag: ${source}`);
}

return { ...normalize($json), _source: source };
```

### 3.6 Python in the Code Node: When and Why

Use Python only when: (a) you need a Python-only library's *algorithm* re-expressed simply (Pyodide's stdlib is limited; `pandas`-class libs aren't reliably available), or (b) your team's shared logic is already Python. Otherwise prefer JS — faster startup, full access to `crypto`/`Buffer`.

```python
# Code node, Language: Python
# Equivalent of "Flatten Order Line Items"
output = []

for item in _input.all():
    order = item['json']
    line_items = order.get('line_items', [])
    for line in line_items:
        output.append({
            'json': {
                'orderId': order.get('id'),
                'customerEmail': (order.get('customer') or {}).get('email', 'unknown'),
                'sku': line.get('sku'),
                'quantity': line.get('quantity'),
                'unitPrice': line.get('unit_price'),
                'lineTotal': round(line.get('quantity', 0) * line.get('unit_price', 0), 2),
            }
        })

return output
```

> **Architect's note:** pick ONE language per workflow and stay consistent. Mixing JS and Python Code nodes is a maintenance trap.

### 3.7 Expression Editor vs Code Node

For trivial one-liners, an inline expression on a `Set` node (`{{ $json.price * 1.08 }}`) is more maintainable — visible directly on the field. Reserve Code nodes for logic needing variables, loops, multi-branch conditionals, or error throwing.

### 3.8 Testing Code Nodes Like Real Code

1. Run the workflow once with representative input.
2. Pin the output of the node feeding your Code node.
3. Iterate against that frozen, pinned input — no need to re-trigger the webhook/API.
4. Before shipping, test with a deliberately malformed item to confirm your defensive checks catch it.

### 3.9 Exercise Challenge

1. Write a Code node that flattens orders (some with `line_items: null`) without throwing, tagging malformed ones with `_flattenError: true`.
2. Extend the normalization pattern (3.5) with a third source, `webhook_v2`, nesting email under `contact.primary_email`.
3. Benchmark dedup two ways — `Set`/`Map` vs. `array.find()` in a loop — and explain why `Map` scales better.

### 3.10 Solution Notes

For (1): guard the loop (`order.line_items ?? []`) plus wrap the per-order block in `try {...} catch { output.push({ json: { ...order, _flattenError: true } }) }`.

For (3): `array.find()` is O(n) per lookup → O(n²) overall; `Set.has()` is O(1) amortized → O(n) overall. At 10,000 items this is milliseconds vs. seconds, and counts against n8n's per-node timeout.

### 3.11 What's Next

Part 4 puts these transformation patterns to work feeding a PostgreSQL-backed CRUD workflow that acts as a secure backend API for a real frontend form.
