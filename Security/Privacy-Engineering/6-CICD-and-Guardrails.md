# Part 6: Auditing, Monitoring & Privacy CI/CD

---

### Why Automation & Auditing Matter
Manual checks eventually fail. We build automated guards so privacy violations are caught early.

---

#### Step 6.1: The Target — PII Schema Scanner

**The Concept**:  
A script that scans schema files and fails if it finds suspicious plaintext columns.

**Implementation**:

Create folder `scripts/` and file **`pii-scanner.ts`**:

```ts
import fs from 'fs';
import path from 'path';

const SENSITIVE_TERMS = ['email', 'phone', 'ssn', 'password', 'notes', 'content', 'health', 'journal'];

function scanFile(filePath: string): boolean {
  const content = fs.readFileSync(filePath, 'utf8').toLowerCase();
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (SENSITIVE_TERMS.some(term => line.includes(term)) && 
        !line.includes('bytea') && 
        !line.includes('encrypted') && 
        !line.includes('hmac')) {
      
      console.error(`🚨 POTENTIAL PII LEAK FOUND in ${filePath}:${i+1}`);
      console.error(line.trim());
      return false;
    }
  }
  return true;
}

console.log("🔍 Running Privacy Schema Scanner...");
const schemaPath = path.join(process.cwd(), 'lib/schema.sql');

if (scanFile(schemaPath)) {
  console.log("✅ PII Scanner passed. No plaintext sensitive columns detected.");
} else {
  console.error("❌ PII Scanner failed. Fix issues before committing.");
  process.exit(1);
}
```

Add to `package.json`:
```json
"scripts": {
  "privacy:scan": "ts-node scripts/pii-scanner.ts"
}
```

---

#### Step 6.2: The Target — PII-Redacting Logger

**Implementation** — **`lib/safe-logger.ts`**:

```ts
const REDACT_KEYS = new Set(['notes', 'content', 'notes_encrypted', 'email', 'phone']);

export function safeLog(level: 'log' | 'info' | 'warn' | 'error', data: any) {
  const cleaned = JSON.parse(JSON.stringify(data, (key, value) => {
    if (REDACT_KEYS.has(key)) return '[REDACTED]';
    if (typeof value === 'string' && value.length > 80) return value.substring(0, 40) + '...';
    return value;
  }));

  console[level](`[${new Date().toISOString()}]`, cleaned);
}
```

---

#### Step 6.3: The Target — GitHub Actions Privacy Pipeline

Create `.github/workflows/privacy-ci.yml`:

```yaml
name: Privacy & Security Checks

on:
  pull_request:
    branches: [ main ]

jobs:
  privacy-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci
      - run: npm run privacy:scan
      - run: npm run build
      - name: Run security scan
        uses: gitleaks/gitleaks-action@v2
```

---

**Part 6 Complete!**

Privacy is now enforced by automation.

You're doing fantastic. The full application is almost complete.
