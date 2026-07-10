# Part 6: GitOps Deployment Strategy (Vercel)

**Module Goal:** Automate deployments to Vercel end to end, implement a Blue/Green style promotion strategy using Vercel's alias system, and gate production releases behind manual approval using GitHub Environments.

---

## 1. Concept Explanation

### Why Vercel Fits the GitOps Model Naturally

Vercel already deploys every pull request to a unique, immutable preview URL automatically once the GitHub integration is installed. That default behavior is actually GitOps in action: every commit produces an inspectable, shareable artifact before it ever touches production. This module builds on top of that default behavior rather than replacing it, using GitHub Actions to add what Vercel's default integration does not provide out of the box: enforced approval gates, controlled production promotion, and Blue/Green style instant rollback.

### Preview vs. Production, and the Promotion Model

Every Vercel deployment is immutable and gets its own unique URL. "Production" is not a separate build pipeline — it is simply an alias (most commonly your custom domain) pointed at one specific immutable deployment. Promoting to production means repointing that alias, not rebuilding anything. This is the entire mechanism behind Blue/Green deployments on Vercel: the "old" version and the "new" version both already exist as immutable deployments, and promotion is an instant, atomic alias swap. Rollback is equally instant — repoint the alias back to the previous deployment's URL.

### Where GitHub Actions Fits In

Vercel's native GitHub integration can build and deploy on its own with zero custom workflow files. We introduce GitHub Actions specifically to insert control points Vercel's default flow lacks: a required manual approval step before production promotion (via GitHub Environments), a verification step that runs smoke tests against the new deployment's preview URL before promoting it, and a single audit trail tying a production promotion event to an approving reviewer's identity — the same auditability principle established for infrastructure in Part 4.

---

## 2. Implementation

### Step 1 — Disconnect Vercel's Auto-Deploy, Use Actions as the Orchestrator

In Vercel Project Settings → Git, disable "Auto-assign custom domains to every push" and switch deployment triggering off for the Git integration if you want Actions to be the sole orchestrator (optional — many teams keep Vercel's preview auto-deploy for PRs and only use Actions to control the *production promotion* step, which is the pattern shown below).

### Step 2 — Required Secrets

Repository secrets needed: `VERCEL_TOKEN` (generated from Vercel Account Settings → Tokens), `VERCEL_ORG_ID`, and `VERCEL_PROJECT_ID` (both found in your Vercel project's `.vercel/project.json` after running `vercel link` locally once).

### Step 3 — The Deployment Workflow

`.github/workflows/deploy-vercel.yml`:

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
  VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}

permissions:
  contents: read
  deployments: write
  pull-requests: write

jobs:
  deploy-preview:
    name: Deploy Preview
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    outputs:
      preview-url: ${{ steps.deploy.outputs.preview-url }}
    steps:
      - uses: actions/checkout@v4

      - name: Install Vercel CLI
        run: npm install --global vercel@latest

      - name: Pull Vercel environment config
        run: vercel pull --yes --environment=preview --token=${{ secrets.VERCEL_TOKEN }}

      - name: Build project artifacts
        run: vercel build --token=${{ secrets.VERCEL_TOKEN }}

      - name: Deploy preview to Vercel
        id: deploy
        run: |
          url=$(vercel deploy --prebuilt --token=${{ secrets.VERCEL_TOKEN }})
          echo "preview-url=$url" >> "$GITHUB_OUTPUT"

      - name: Comment preview URL on PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `Preview deployed: ${{ steps.deploy.outputs.preview-url }}`
            })

  deploy-production:
    name: Deploy to Production
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: ${{ steps.deploy.outputs.production-url }}
    steps:
      - uses: actions/checkout@v4

      - name: Install Vercel CLI
        run: npm install --global vercel@latest

      - name: Pull Vercel environment config
        run: vercel pull --yes --environment=production --token=${{ secrets.VERCEL_TOKEN }}

      - name: Build project artifacts for production
        run: vercel build --prod --token=${{ secrets.VERCEL_TOKEN }}

      - name: Deploy prebuilt artifact (creates immutable deployment, NOT yet aliased)
        id: deploy
        run: |
          url=$(vercel deploy --prebuilt --prod --skip-domain --token=${{ secrets.VERCEL_TOKEN }})
          echo "production-url=$url" >> "$GITHUB_OUTPUT"

      - name: Run smoke tests against the new deployment
        run: |
          npx wait-on ${{ steps.deploy.outputs.production-url }} -t 60000
          curl --fail ${{ steps.deploy.outputs.production-url }}/api/health

      - name: Promote to production alias (Blue/Green swap)
        run: vercel alias set ${{ steps.deploy.outputs.production-url }} my-app.com --token=${{ secrets.VERCEL_TOKEN }}
```

### Step 4 — Wiring the Manual Approval Gate

The `environment: name: production` block on `deploy-production` is what triggers GitHub's approval gate — but only once you configure the Environment itself: Settings → Environments → New environment → `production` → check **Required reviewers** and add the individuals or teams who must approve. Once configured, every run of this job **pauses** after being queued and waits for a reviewer to click Approve in the Actions UI, before the runner is even provisioned. The approving reviewer's identity is permanently recorded against that specific deployment run.

### Step 5 — Why We Split Deploy and Promote

Notice the `--skip-domain` flag: this step creates a fully-built, fully live, immutable deployment **without** touching the production alias yet. Only after the smoke test step succeeds does `vercel alias set` repoint `my-app.com` at it. This two-phase sequence is the Blue/Green pattern in practice: "Green" (the new version) is fully deployed and verifiable at its own unique URL *before* traffic (the alias) is switched to it. If the smoke test fails, the job stops, the alias is untouched, and users never see a broken deployment — "Blue" (the old version) keeps serving traffic the entire time.

### Step 6 — Instant Rollback

Because every deployment is immutable and retained, rollback is a one-line manual (or scripted) command referencing the previous deployment's URL:

```bash
vercel alias set <previous-deployment-url> my-app.com --token=$VERCEL_TOKEN
```

This can be wrapped in its own `workflow_dispatch`-triggered workflow (`rollback.yml`) taking the target deployment URL as a manual input — giving you a one-click rollback button directly in the Actions UI for incident response.

---

## 3. Exercise Challenge

1. The smoke test above only checks one `/api/health` endpoint. Extend it into a small matrix of critical-path checks (homepage 200 OK, auth endpoint reachable, a key API route returns expected JSON shape).
2. Add a Canary variant: instead of an immediate full alias swap, use Vercel's traffic splitting (via `vercel alias` with weighted rollout, or a middleware-based percentage rollout) to send only 10% of traffic to the new deployment for 15 minutes, monitored by an automated check, before promoting to 100%.
3. Add a `rollback.yml` workflow, triggered by `workflow_dispatch`, that accepts a deployment URL as input and performs the alias swap, also requiring the same `production` Environment approval gate.

---

## 4. Solution & Explanation

**1 — Multi-check smoke test:**

```yaml
      - name: Run smoke test suite against new deployment
        run: |
          BASE_URL=${{ steps.deploy.outputs.production-url }}
          npx wait-on "$BASE_URL" -t 60000
          curl --fail "$BASE_URL" -o /dev/null -w "Homepage: %{http_code}\n"
          curl --fail "$BASE_URL/api/health" -o /dev/null -w "Health: %{http_code}\n"
          RESPONSE=$(curl --fail -s "$BASE_URL/api/status")
          echo "$RESPONSE" | jq -e '.status == "ok"' > /dev/null || (echo "::error::Status endpoint did not return ok" && exit 1)
```

`jq -e` exits non-zero if the JSON condition is false, cascading the failure up through the `run:` step's exit code — the same exit-code-as-signal mechanic established in Part 1.

**3 — Rollback workflow:**

```yaml
name: Rollback Production Deployment

on:
  workflow_dispatch:
    inputs:
      deployment_url:
        description: "The previous immutable deployment URL to roll back to"
        required: true
        type: string

permissions:
  contents: read
  deployments: write

jobs:
  rollback:
    name: Roll Back Production Alias
    runs-on: ubuntu-latest
    environment:
      name: production
    steps:
      - name: Install Vercel CLI
        run: npm install --global vercel@latest

      - name: Repoint production alias
        run: vercel alias set ${{ inputs.deployment_url }} my-app.com --token=${{ secrets.VERCEL_TOKEN }}

      - name: Record rollback event
        run: echo "::notice::Rolled back production to ${{ inputs.deployment_url }}, approved by ${{ github.actor }}"
```

**Explanation:** Gating rollback behind the *same* `production` Environment approval means even an emergency rollback goes through the identical audit trail as a forward deployment — no "break glass" backdoor that bypasses review. In a real incident, the on-call engineer triggering this workflow and a second reviewer approving it takes seconds, but still preserves the auditability guarantee end to end.

---

**Next:** Part 7 — Observability & Feedback →
