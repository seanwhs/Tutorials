# Part 6: Auditing, Monitoring & Privacy CI/CD

#### Step 6.1: The Target — PII Schema Scanner (CI Enforcement)

**The Concept**:  
Prevent accidental plaintext columns from reaching production.

**Implementation**:

Create **scripts/pii-scanner.ts**:

```ts
import fs from 'fs';

const SENSITIVE_PATTERNS = ['email', 'phone', 'ssn', 'notes', 'content', 'health', 'password'];

function scanFile(filePath: string) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].toLowerCase();
    if (SENSITIVE_PATTERNS.some(p => line.includes(p)) && 
        !line.includes('bytea') && 
        !line.includes('encrypted')) {
      console.error(`❌ Potential PII in ${filePath}:${i+1}`);
      console.error(line.trim());
      process.exit(1);
    }
  }
}

console.log("🔍 Running PII Schema Scan...");
scanFile('lib/schema.sql');
console.log("✅ PII Scan passed");
```

Add to `package.json`:
```json
"scripts": {
  "privacy:scan": "ts-node scripts/pii-scanner.ts"
}
```

---

#### Step 6.2: The Target — PII-Redacting Logger

**The Concept**:  
Recursive walker that redacts sensitive values before logging.

**Implementation**:

**lib/safe-logger.ts**:
```ts
const REDACTED = '[REDACTED]';

const SENSITIVE_KEYS = new Set(['notes', 'content', 'email', 'phone', 'notes_encrypted']);

export function safeLog(level: string, data: any) {
  const redacted = JSON.parse(JSON.stringify(data, (key, value) => {
    if (SENSITIVE_KEYS.has(key)) return REDACTED;
    if (typeof value === 'string' && value.length > 100) return value.slice(0, 50) + '...';
    return value;
  }));

  console[level](new Date().toISOString(), redacted);
}

// Usage: safeLog('info', { userId, notes: "secret" });
```

**ESLint Rule** (`.eslintrc` or config):
Block raw `console.log` in favor of `safeLogger`.

---

#### Step 6.3: The Target — GitHub Actions Privacy Pipeline

**Implementation** — `.github/workflows/privacy.yml`:

```yaml
name: Privacy Checks

on:
  pull_request:
    branches: [ main ]

jobs:
  privacy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - run: npm ci
      - run: npm run privacy:scan
      - run: npm run build
      - name: Secret Scan
        uses: gitleaks/gitleaks-action@v2
```

---

#### Step 6.4: The Target — Privacy Metrics & Quarterly Checklist

Create `docs/PRIVACY_CHECKLIST.md` with items like DSAR response time < 30 days, deletion success rate 100%, etc.

Almost done!
