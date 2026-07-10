# Part 4: Infrastructure as Code with OpenTofu

**Module Goal:** Provision cloud resources declaratively using OpenTofu (the open-source Terraform fork) orchestrated entirely through GitHub Actions, authenticating via OIDC instead of long-lived cloud credentials.

> **Note:** This part is written in structural/prose form rather than literal fenced code blocks, due to a recurring note-tool parsing error with nested YAML/HCL code fences in this session. If you want it converted into full literal `.tf`/`.yml` code blocks like Parts 1–3, just ask and I'll regenerate it.

---

## 1. Concept Explanation

### Why OpenTofu

OpenTofu is a Linux Foundation-governed, fully open-source fork of Terraform, created after Terraform's license change to BSL. It is drop-in compatible with existing Terraform HCL syntax and providers. For this series' strict "free and open-source only" constraint, OpenTofu is the correct choice over Terraform CLI itself.

### The GitOps Model for Infrastructure

In Part 1 we established that the pipeline is living documentation for application deployment. Part 4 extends that principle to infrastructure: your `infra` directory, committed to Git, is the single source of truth for what cloud resources exist. Nobody provisions a database or a storage bucket by clicking a cloud console. Every change flows through a pull request, gets reviewed, and is applied only by the pipeline.

This gives you three properties a console-driven workflow cannot:
- **Auditability** — every infra change has a PR, an author, a review, and a commit SHA.
- **Reproducibility** — disaster recovery means re-running the pipeline against a fresh account, not remembering forty manual console steps.
- **Drift detection** — running plan on a schedule reveals when someone made an out-of-band console change that diverges from the committed state.

### Why OIDC Instead of Static Cloud Keys

The naive approach to cloud auth in CI is to generate a long-lived Access Key and Secret Key for a service account, then paste them into GitHub Secrets. This is a standing liability: if that secret leaks, it is valid until someone manually rotates it, with no expiry.

OpenID Connect flips this model. GitHub's OIDC provider issues a short-lived, cryptographically signed JSON Web Token for every single workflow run. Your cloud provider is configured to trust tokens signed by GitHub's OIDC issuer, scoped narrowly to a specific repository, branch, or environment. The cloud provider exchanges that token for temporary credentials that expire automatically at the end of the job. There is no secret to leak, because no long-lived secret exists.

We use AWS as the reference cloud provider below since it has first-class GitHub OIDC support and a generous free tier, but the pattern (trust policy + role assumption) is directly portable to GCP Workload Identity Federation or Azure Federated Credentials.

---

## 2. Implementation

### Step 1 — Directory Layout

The `infra` directory sits alongside your application code in the same repository, reinforcing that infrastructure and application are versioned together: `infra/backend.tf`, `infra/main.tf`, `infra/variables.tf`, `infra/outputs.tf`.

### Step 2 — Remote State Backend

OpenTofu needs a remote backend so state is shared across pipeline runs rather than living on a single runner's disk (which is destroyed after every job). We use an S3 bucket with native S3 locking.

Contents of `infra/backend.tf`: a `terraform` block with `required_version` set to greater than or equal to 1.6, a `required_providers` block declaring `aws` sourced from `hashicorp/aws` version 5.x, and a `backend "s3"` block specifying `bucket = "my-app-tofu-state"`, `key = "prod/terraform.tfstate"`, `region = "us-east-1"`, and `use_lockfile = true` for native locking without needing a separate DynamoDB table.

### Step 3 — Example Resource Definitions

Contents of `infra/main.tf`: an `aws_s3_bucket` resource for application uploads, an `aws_iam_role` for the app's runtime permissions, and an `aws_dynamodb_table` for a simple key-value store the app reads from. Each resource is tagged with `Environment`, `ManagedBy` set to `opentofu`, and `Repository` set to the GitHub repository name, so anyone auditing the cloud account can trace any resource straight back to the Git repository that owns it.

Contents of `infra/variables.tf`: declares `environment`, `aws_region` with a default of `us-east-1`, and `app_name` as input variables.

Contents of `infra/outputs.tf`: exposes the S3 bucket name, the IAM role ARN, and the DynamoDB table name as outputs consumed by later pipeline stages or by the application's runtime configuration.

### Step 4 — Configuring OIDC Trust on the AWS Side (one-time setup, done via OpenTofu itself)

Before the main pipeline can assume a role, AWS must trust GitHub's OIDC issuer. This is itself defined as OpenTofu code in a bootstrap configuration, run once by an administrator with existing credentials:

- An `aws_iam_openid_connect_provider` resource pointing at `url = https://token.actions.githubusercontent.com`, with the audience `sts.amazonaws.com`, and the correct GitHub OIDC thumbprint.
- An `aws_iam_role` resource named `github-actions-deploy-role`, whose `assume_role_policy` trusts that OIDC provider, with a condition restricting the token subject claim to `repo:your-org/my-app:ref:refs/heads/main` for production deploys, and a broader `repo:your-org/my-app:pull_request` condition for a separate plan-only role used on PRs.
- An `aws_iam_role_policy` attached to that role, scoped narrowly to only the S3, DynamoDB, and IAM actions the pipeline actually needs — never `AdministratorAccess`.

### Step 5 — The GitHub Actions Workflow

File path: `.github/workflows/iac-opentofu.yml`

**Trigger configuration:** runs on `pull_request` events touching the `infra` path for plan-only runs, and on `push` to `main` touching the `infra` path for apply runs. Also exposes `workflow_dispatch` for manual runs.

**Top-level permissions block:** `id-token` set to `write` (this is the permission that allows the job to request an OIDC token from GitHub at all — without it, the OIDC exchange fails outright), `contents` set to `read`, and `pull-requests` set to `write` (needed later to post the plan output as a PR comment).

**Job** named `tofu-plan-and-apply` running on `ubuntu-latest`, with an `environment` block set to `production` only on the apply path, gating the apply job behind a GitHub Environment protection rule requiring manual reviewer approval — the same primitive used again in Part 6 for deployment approval gates.

**Steps in order:** checkout the repository using `actions/checkout`; configure AWS credentials using `aws-actions/configure-aws-credentials` at version 4, passing `role-to-assume` set to the ARN of `github-actions-deploy-role`, and `aws-region`; set up OpenTofu using `opentofu/setup-opentofu` at version 1, pinning `tofu_version` to a specific release like 1.7.x; run `tofu init` inside the infra directory; run `tofu fmt -check` to enforce formatting standards as a gate rather than a suggestion; run `tofu validate` to catch syntax and internal consistency errors; run `tofu plan -out=tfplan` and capture its human-readable output into a file for the PR comment step; and finally, only on push to `main` and only after the environment approval gate has been satisfied, run `tofu apply tfplan` using the exact plan artifact generated earlier rather than re-planning at apply time, which guarantees what gets applied is byte-for-byte what was reviewed.

### Step 6 — Why the Plan Artifact Must Be Passed Between Plan and Apply

This is a critical correctness detail. If your apply step runs a fresh `tofu plan` followed by `tofu apply`, you have a race condition: cloud state could have drifted between the reviewed plan and the actual apply, and a reviewer could be approving one set of changes while a different set gets applied. The correct pattern uploads the `tfplan` binary file as a build artifact from the plan job, and the apply job downloads that exact artifact before running `tofu apply` against it. This is the same `actions/upload-artifact` and `actions/download-artifact` mechanism introduced in Part 2, now serving a security and correctness purpose rather than just convenience.

---

## 3. Exercise Challenge

1. Add a scheduled workflow, running nightly via a cron trigger, that runs `tofu plan` only, with no apply step, and fails the run (exit code 1) if the plan output is non-empty — this is automated drift detection.
2. Modify the OIDC trust policy so that the plan-only role used on pull requests cannot under any circumstance perform a `tofu apply`, even if someone maliciously edits the workflow YAML in a PR branch.
3. Add a step that posts the plan output as a comment on the pull request, updating the same comment on subsequent pushes rather than spamming a new comment every time.

---

## 4. Solution & Explanation

**Item 1:** The drift-detection workflow uses `on: schedule` with a cron expression such as `"0 6 * * *"` for a daily 6am UTC run, plus `workflow_dispatch` for manual triggering. It runs the identical init/plan sequence as the main workflow, but pipes the plan's exit code through the convention that `tofu plan -detailed-exitcode` returns 0 for no changes, 1 for an error, and 2 for changes present. The final step checks for exit code 2 specifically and if found, fails the job deliberately so the red X and any configured notification (Part 7) surfaces the drift to the team immediately, well before it causes a production incident.

**Item 2:** The key insight is that IAM trust policy conditions are enforced by AWS itself at the token-exchange step, not by anything inside your workflow YAML. Even if an attacker fully controls the workflow file in a malicious pull request, the plan-only role's trust policy condition restricts `token.actions.githubusercontent.com` subject claims to exactly `repo:your-org/my-app:pull_request` — AWS will simply refuse to hand out credentials for that role to a token asserting any other subject, such as a `ref:refs/heads/main` claim. This is the entire point of scoping OIDC trust conditions precisely: the security boundary lives in the cloud provider's trust policy, which a PR author cannot edit, not in the workflow file, which they can.

**Item 3:** The solution uses `actions/github-script` or the community action `peter-evans/create-or-update-comment`, searching existing PR comments for a hidden HTML marker such as a comment tag containing the string `tofu-plan-marker`, and updating that comment's body if found, or creating a new one if not. This keeps the PR conversation clean across multiple pushes to the same branch instead of accumulating a new plan comment on every commit — directly setting up the pattern generalized further in Part 7's observability workflows.

---

**Next:** Part 5 — DevSecOps & Shift-Left →
