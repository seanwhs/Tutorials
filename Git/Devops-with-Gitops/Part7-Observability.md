# Part 7: Observability & Feedback

**Module Goal:** Surface pipeline results in real time through native GitHub status checks, automated PR comments, and external Slack/Discord webhook notifications, so pipeline health is visible without anyone needing to go looking for it.

> **Note:** This part is written in structural/prose form rather than literal fenced code blocks, due to a recurring note-tool parsing error with nested code fences in this session. If you want it converted into full literal `.yml` code blocks like Parts 1–3 and 6, just ask and I'll regenerate it.

---

## 1. Concept Explanation

### Observability Is Not Just Logging

A pipeline that only reports success or failure as a green or red icon buried in the Actions tab is not observable — it is merely inspectable, which requires someone to go looking. True observability pushes information to where people already are: the PR conversation, a team chat channel, a status dashboard. The goal is that a developer never has to ask "did my deploy work," because the pipeline already told them, unprompted, in a channel they already watch.

### Status Checks as the Universal Interface

Every job in every workflow automatically becomes a GitHub Status Check, visible directly on the commit and the PR. This is the baseline layer of observability and it is free — nothing to configure beyond what was already built in Parts 1 through 6. This module builds two more layers on top: **PR comments**, which are rich, contextual, human readable summaries posted directly into the conversation, and **external webhooks**, which push the same signal to Slack or Discord, both free tools with native incoming webhook support, so the team does not need to be staring at GitHub to know something happened.

### Why a Reusable Notification Workflow

Nearly every workflow in this series — CI, security scans, IaC applies, and deployments — eventually wants to say "here is what happened" to a chat channel. Rather than duplicating webhook posting logic across eight different files, this module packages it once as a reusable workflow, the composition pattern introduced in Part 2, that any other workflow can call with a status and a message.

---

## 2. Implementation

### Step 1 — Provisioning the Webhook

For Discord: Server Settings → Integrations → Webhooks → New Webhook, copy the URL. For Slack: create an Incoming Webhook via the Slack API app dashboard, install it to your workspace, copy the URL. Store the URL as a repository secret named `DISCORD_WEBHOOK_URL` or `SLACK_WEBHOOK_URL`. Never hardcode a webhook URL directly in a workflow file — it is a bearer credential, anyone who has it can post to your channel.

### Step 2 — The Reusable Notification Workflow

File path: `.github/workflows/notify.yml`

**Trigger:** `workflow_call`, accepting four inputs: `status` (required, string, expected values `success` or `failure`), `title` (required, string), `details` (optional, string, defaults to empty), and a secret named `webhook_url` (required).

Single job named `send-notification`, running on `ubuntu-latest`, with one step that uses `curl` directly against the Discord webhook URL, POSTing a JSON payload built with a shell heredoc. The payload sets the embed color conditionally — green (`3066993`) for success and red (`15158332`) for failure — based on the `status` input, and includes the title, details, the repository name pulled from the `github.repository` context, the branch or ref, the actor who triggered the run, and a direct link back to the specific workflow run using `github.server_url`, `github.repository`, and `github.run_id` concatenated into a run URL.

### Step 3 — Calling the Reusable Notification Workflow from CI

Appended to the end of `ci-test.yml` from Part 1, as a new job that depends on all prior jobs and always runs regardless of their outcome:

A job named `notify-ci-result`, with `needs` listing `lint-and-typecheck`, `unit-tests`, and `build`, and an `if` condition of `always()`, so this job runs whether upstream jobs passed or failed — which is essential, you want a failure notification precisely when something failed. This job uses the reusable workflow via a `uses` reference to `./.github/workflows/notify.yml`, passing `status` computed from checking whether any needed job's result was `failure`, `title` set to a descriptive string referencing the workflow name and repository, and `details` summarizing which jobs passed or failed. Secrets are passed through explicitly, `webhook_url` set to `secrets.DISCORD_WEBHOOK_URL`.

### Step 4 — Automated PR Comments with Rich Context

Beyond simple text comments (used already in Part 4 for plan output and Part 6 for preview URLs), a more advanced pattern posts a single consolidated "pipeline summary" comment aggregating results from multiple jobs, using `actions/github-script` with a job needing all upstream jobs and running with `if: always()`. The script constructs a Markdown table listing each check name and its result emoji, searches existing comments for a hidden marker, and either updates that comment or creates a new one — exactly mirroring the update-in-place pattern from Part 4's Exercise Solution, now generalized into a project-wide standard rather than a one-off IaC-specific trick.

### Step 5 — Wiring Notifications Into Security and Deployment Workflows

The same `notify.yml` reusable workflow is called from `security-scan.yml` (Part 5) on schedule-triggered runs specifically, since a scheduled CodeQL run finding a new vulnerability with nobody watching a PR is exactly the silent-failure scenario observability is meant to prevent, and from `deploy-vercel.yml` (Part 6) after both the preview deploy and the production promotion steps, so the team's channel becomes a real-time deployment log — itself a form of living documentation, this time of runtime history rather than pipeline definition.

---

## 3. Exercise Challenge

1. Extend `notify.yml` to support routing to Slack in addition to Discord, using the payload format Slack's Incoming Webhooks expect, and add a `channel` input parameter so different workflows can target different rooms — for example, a security-alerts channel versus a deployments channel.
2. Add rate-limiting logic so that if the same workflow fails five times in a row within an hour (a classic sign of a flaky pipeline rather than five independent real failures), the sixth notification is suppressed and replaced with a single "this pipeline is flapping" escalation message instead of spamming the channel.
3. Add a scheduled daily digest workflow that queries the Actions API for the previous 24 hours of workflow runs and posts a single summary message: total runs, pass rate, and any deployments promoted to production.

---

## 4. Solution & Explanation

**Item 1:** The reusable workflow gains a new input named `platform`, accepting values `discord` or `slack`, and a conditional step for each. Slack's webhook payload shape differs from Discord's embed structure, using a `blocks` array with a section block containing a `text` object in `mrkdwn` format, rather than Discord's `embeds` array with `color`, `title`, and `description` fields as separate top-level keys. The calling workflow simply passes `platform: slack` and a different secret name, and the underlying `curl` command branches on which JSON shape to construct, keeping both platforms behind one unified interface for every calling workflow, none of which need to know which chat platform is actually receiving the message.

**Item 2:** The practical implementation avoids trying to maintain cross-run state inside the stateless notify workflow itself, and instead uses the GitHub Actions API from within a wrapper step to query the last five runs of the current workflow via the REST endpoint for workflow runs, checking each one's `conclusion` field. If all five most recent runs concluded as `failure`, the notification message text is swapped for an escalation-flagged variant mentioning a specific on-call role, and a label such as `flaky-pipeline` is applied to any open PR associated with the run — both surfacing the pattern distinctly from a one-off failure and avoiding notification fatigue that causes teams to start ignoring the channel entirely, which is the single biggest risk to any observability system's long-term effectiveness.

**Item 3:** The digest workflow runs on a nightly schedule trigger, authenticates with the default `GITHUB_TOKEN` (read-only access to Actions run history is sufficient, no elevated permissions needed), calls the list-workflow-runs API endpoint filtered by created date within the last 24 hours, computes total run count and the ratio of successful conclusions to total, separately filters for runs of `deploy-vercel.yml` specifically to report how many production promotions occurred, and posts one consolidated message through the same `notify.yml` reusable workflow used everywhere else in the series — reinforcing that a daily digest is not a special case requiring new infrastructure, it is simply one more caller of the same notification primitive built once in Step 2.

---

**Next:** Part 8 — Scale and Maintenance →
