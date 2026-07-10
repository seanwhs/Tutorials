## Part 7: Git-Based Versioning

Setting up CI/CD to push n8n JSON workflow definitions into Git for collaboration and change tracking. n8n Community Edition doesn't ship a built-in Git sync (Enterprise-only), so we build our own using the **n8n CLI**, free and included in the standard image.

### 7.1 Why This Matters

Without version control, a workflow edited directly in the production UI is an unauditable black box: no diff, no rollback, no review. Treating workflow JSON as source code gives you everything software engineering already solved: PR review, blame, rollback, branching per environment.

### 7.2 The n8n CLI: Export and Import

```bash
docker compose exec n8n n8n export:workflow --all --output=/home/node/workflows/export
```

Writes one JSON file per workflow into `./workflows/export/` on your host (via Part 1's volume mount).

Export a single workflow by ID:
```bash
docker compose exec n8n n8n export:workflow --id=42 --output=/home/node/workflows/export/customer-crud.json
```

Import (used in CI/CD):
```bash
docker compose exec n8n n8n import:workflow --input=/home/node/workflows/export/customer-crud.json
```

Import an entire directory:
```bash
docker compose exec n8n n8n import:workflow --separate --input=/home/node/workflows/export
```

Export credentials **references only** (never plaintext — n8n encrypts these, keyed to `N8N_ENCRYPTION_KEY`):
```bash
docker compose exec n8n n8n export:credentials --all --output=/home/node/workflows/credentials-export
```

> **Hard rule:** commit workflow JSON. Do **not** commit credentials export files — even encrypted, unnecessary blast radius if the repo leaks. Recreate credentials per-environment (7.8) instead.

### 7.3 Repo Structure for Versioned Workflows

```
n8n-production-stack/
├── docker-compose.yml
├── docker-compose.prod.yml        # Part 8
├── .env.example
├── .gitignore
├── workflows/
│   ├── export/
│   │   ├── part2-hardened-webhook-intake.json
│   │   ├── part4-customer-create.json
│   │   ├── part4-customer-read.json
│   │   ├── part4-customer-update.json
│   │   ├── part4-customer-delete.json
│   │   ├── part5-ai-agent.json
│   │   ├── part5-rag-ingestion.json
│   │   └── part6-global-error-handler.json
│   └── README.md                  # naming convention + owner per workflow
├── scripts/
│   ├── export-all.sh
│   ├── import-all.sh
│   └── validate-workflows.js
└── .github/
    └── workflows/
        ├── validate-on-pr.yml
        └── deploy-on-merge.yml
```

### 7.4 Helper Scripts

```bash
#!/usr/bin/env bash
# scripts/export-all.sh
set -euo pipefail

echo "Exporting all workflows from running n8n container..."
docker compose exec -T n8n n8n export:workflow --all --separate --output=/home/node/workflows/export

echo "Done. Review changes with: git status / git diff workflows/export"
```

```bash
#!/usr/bin/env bash
# scripts/import-all.sh
set -euo pipefail

echo "Importing all workflows from ./workflows/export into the running n8n container..."
docker compose exec -T n8n n8n import:workflow --separate --input=/home/node/workflows/export

echo "Import complete."
```

```bash
chmod +x scripts/export-all.sh scripts/import-all.sh
```

### 7.5 Validating Workflow JSON Before It's Merged

```javascript
// scripts/validate-workflows.js
// Run with: node scripts/validate-workflows.js
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'workflows', 'export');
const files = fs.readdirSync(dir).filter((f) => f.endsWith('.json'));

let failed = false;
const secretPatterns = [/sk-[a-zA-Z0-9]{20,}/, /AKIA[0-9A-Z]{16}/, /-----BEGIN [A-Z ]+-----/];

for (const file of files) {
  const raw = fs.readFileSync(path.join(dir, file), 'utf8');
  const workflow = JSON.parse(raw);

  // Check 1: Error Workflow configured
  const hasErrorWorkflow = workflow.settings && workflow.settings.errorWorkflow;
  if (!hasErrorWorkflow) {
    console.error(`[FAIL] ${file}: no errorWorkflow configured in settings`);
    failed = true;
  }

  // Check 2: no obvious hardcoded secrets
  for (const pattern of secretPatterns) {
    if (pattern.test(raw)) {
      console.error(`[FAIL] ${file}: possible hardcoded secret matching ${pattern}`);
      failed = true;
    }
  }

  // Check 3: webhook nodes must have authentication set
  const webhookNodes = (workflow.nodes || []).filter((n) => n.type === 'n8n-nodes-base.webhook');
  for (const node of webhookNodes) {
    if (!node.parameters?.authentication || node.parameters.authentication === 'none') {
      console.error(`[FAIL] ${file}: Webhook node "${node.name}" has no authentication configured`);
      failed = true;
    }
  }
}

if (failed) {
  console.error(`\nValidation failed for one or more workflows.`);
  process.exit(1);
} else {
  console.log(`All ${files.length} workflow(s) passed validation.`);
}
```

### 7.6 GitHub Actions: Validate on Pull Request

```yaml
# .github/workflows/validate-on-pr.yml
name: Validate Workflows

on:
  pull_request:
    paths:
      - 'workflows/export/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Run workflow validation
        run: node scripts/validate-workflows.js
      - name: Lint JSON formatting
        run: |
          for f in workflows/export/*.json; do
            node -e "JSON.parse(require('fs').readFileSync('$f'))" || (echo "Invalid JSON: $f" && exit 1)
          done
```

### 7.7 GitHub Actions: Deploy on Merge to Main

```yaml
# .github/workflows/deploy-on-merge.yml
name: Deploy Workflows to Production

on:
  push:
    branches: [main]
    paths:
      - 'workflows/export/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_PRIVATE_KEY }}
          script: |
            cd /opt/n8n-production-stack
            git pull origin main
            docker compose exec -T n8n n8n import:workflow --separate --input=/home/node/workflows/export
            echo "Deployed $(date)"
```

### 7.8 Recreating Credentials Per-Environment (Not Via Git)

| Credential Name (must match exactly across envs) | Type | Notes |
|---|---|---|
| `app_db_postgres` | Postgres | Different host/password per env, same name |
| `webhook_hmac_secret` | Header Auth / generic | Rotate independently per env |
| `ollama_local` | Ollama | Points to that env's Ollama service |
| `slack_alerts_webhook` | HTTP Header Auth | Route to `#prod-alerts` vs `#dev-alerts` |

Document this in `workflows/README.md` so onboarding a new environment is a checklist, not tribal knowledge.

### 7.9 Workflow Review Etiquette (PR Template)

```markdown
<!-- .github/pull_request_template.md -->
## What changed
- [ ] Workflow(s) affected: 
- [ ] Behavior change or pure refactor?

## Safety Checklist
- [ ] Error Workflow is attached (Part 6)
- [ ] No hardcoded secrets (validated by CI)
- [ ] Tested against a pinned sample payload (Part 3.8)
- [ ] Backward compatible with existing callers
```

### 7.10 Exercise Challenge

1. Export every workflow from Parts 2, 4, 5, 6; commit and open a PR to see `validate-on-pr.yml` run.
2. Introduce a hardcoded API key into a Code node, export, confirm CI catches it.
3. Extend `validate-workflows.js` with a check flagging Postgres queries that concatenate `$json` directly into SQL instead of using parameterized placeholders.

### 7.11 Solution Notes

For (3): a heuristic regex like `/query["']?\s*:\s*["'].*\$\{.*\$json/` won't catch everything but catches the common copy-paste mistake of string-templating user input into SQL.

### 7.12 What's Next

Part 8 deploys this Git-backed, validated workflow set to a real production VPS with Queue Mode scaling, TLS, and hardened network/credential security.
