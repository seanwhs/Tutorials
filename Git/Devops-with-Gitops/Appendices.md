# Appendices

---

## Appendix A: Codebase Reference

### Full `/workflows` Directory Structure

```
my-app/
├── .github/
│   ├── workflows/
│   │   ├── ci-test.yml                  # Part 1 - lint, typecheck, unit tests, build
│   │   ├── ci-matrix.yml                # Part 2 - cross Node version / OS test matrix
│   │   ├── reusable-node-setup.yml      # Part 2 - reusable workflow (setup+lint+typecheck)
│   │   ├── reusable-upload-coverage.yml # Part 2 - reusable coverage artifact handler
│   │   ├── docker-build-push.yml        # Part 3 - multi-stage build, push to GHCR
│   │   ├── iac-opentofu.yml             # Part 4 - OpenTofu plan/apply via OIDC
│   │   ├── security-scan.yml            # Part 5 - CodeQL, npm audit, Gitleaks
│   │   ├── deploy-vercel.yml            # Part 6 - preview + production Blue/Green
│   │   ├── rollback.yml                 # Part 6 - manual production rollback
│   │   ├── notify.yml                   # Part 7 - reusable Slack/Discord notifier
│   │   └── runner-maintenance.yml       # Part 8 - self-hosted fleet health/prune
│   ├── actions/
│   │   └── setup-project/
│   │       └── action.yml               # Part 2 - composite action
│   ├── CODEOWNERS
│   └── dependabot.yml                   # Part 5 - dependency + action version updates
├── infra/
│   ├── backend.tf                       # Part 4 - remote state config
│   ├── main.tf                          # Part 4 - resource definitions
│   ├── variables.tf
│   └── outputs.tf
├── docker/
│   └── Dockerfile                       # Part 3 - multi-stage build
├── runner/
│   ├── Dockerfile                       # Part 8 - self-hosted runner image
│   ├── entrypoint.sh                    # Part 8 - registration + ephemeral run logic
│   └── docker-compose.yml               # Part 8 - local runner fleet
├── deployment-manifest.yaml             # This appendix, below
├── src/
├── tests/
├── package.json
└── README.md
```

### Sample `deployment-manifest.yaml`

This file is a human- and machine-readable summary of what a specific deployment *is* — a lightweight, declarative record generated or referenced by the pipeline, sitting alongside (not replacing) the workflow YAML itself. Its purpose: at any point, anyone can look at this one file and know what's running, where it came from, and how it got there — the "living documentation" principle applied to a single point-in-time snapshot rather than the whole pipeline history.

```yaml
apiVersion: devops-mastery/v1
kind: DeploymentManifest

metadata:
  application: my-app
  environment: production
  generatedBy: github-actions
  generatedAt: "2026-04-20T14:32:00Z"

source:
  repository: your-org/my-app
  commitSha: a1b2c3d4e5f6
  branch: main
  triggeredBy: octocat
  workflowRun: "https://github.com/your-org/my-app/actions/runs/123456789"

build:
  containerImage: ghcr.io/your-org/my-app:a1b2c3d
  buildPlatforms: [linux/amd64, linux/arm64]
  securityScans:
    codeql: passed
    dependencyAudit: passed
    secretScan: passed

infrastructure:
  provisionedBy: opentofu
  stateBackend: s3://my-app-tofu-state/prod/terraform.tfstate
  authMethod: github-oidc
  resources:
    - type: aws_s3_bucket
      name: my-app-uploads
    - type: aws_dynamodb_table
      name: my-app-keyvalue-store
    - type: aws_iam_role
      name: my-app-runtime-role

deployment:
  target: vercel
  strategy: blue-green
  previousDeploymentUrl: https://my-app-abc123.vercel.app
  currentDeploymentUrl: https://my-app-def456.vercel.app
  productionAlias: my-app.com
  approvedBy: jane-doe
  approvalTimestamp: "2026-04-20T14:35:00Z"
  smokeTestsPassed: true

notifications:
  channel: "#deployments"
  platform: discord
  notifiedAt: "2026-04-20T14:36:12Z"
```

---

## Appendix B: The DevOps Matrix

### Actions vs. Webhooks

| Criterion | GitHub Actions | Raw Webhooks |
|---|---|---|
| Best for | Orchestrating multi-step processes (build, test, deploy) with state, retries, approvals | Firing a single event to an external system (notify, trigger an external job) |
| Compute | Runs on GitHub's (or your own) runner — has a filesystem, can install tools, cache | None — just an HTTP POST; the receiving service does the work |
| Built-in secrets management | Yes — native encrypted repo/org/environment secrets | No — you manage auth on both ends yourself |
| Approval gates | Native (GitHub Environments) | Not native — must be built into the receiving service |
| Use when | The GitHub repo itself should drive multi-step logic | You just need to notify or trigger something external and let *that system* own the logic (e.g., Part 7's Discord/Slack notifications are themselves outbound webhooks *called from* an Action) |

### CI vs. CD

| Criterion | Continuous Integration (CI) | Continuous Deployment/Delivery (CD) |
|---|---|---|
| Question it answers | "Is this change safe to merge?" | "Is this change safe (and ready) to run in production?" |
| Series parts | 1, 2, 3, 5 (build, test, scan) | 4, 6 (provision, deploy) |
| Trigger | Every push/PR | Merge to main, tag push, or manual promotion |
| Failure cost if skipped | Bad code enters the shared branch | Bad code reaches real users |
| Typical gate | Automated (tests, lint, scan) | Automated + human (approval Environments) |

### Secret Management Best Practices

| Practice | Why |
|---|---|
| Prefer OIDC over long-lived cloud keys | No secret to leak; tokens expire automatically (Part 4, Appendix C) |
| Scope secrets to GitHub Environments, not repo-wide | A `staging`-only secret should be unreachable from a `production`-targeting job and vice versa |
| Never echo secrets in logs | Actions auto-masks known secret values, but string concatenation or base64-encoding can defeat masking — avoid manipulating secret values in shell steps |
| Rotate what can't be OIDC'd (e.g., webhook URLs) on a schedule | Some integrations (Slack/Discord webhooks) have no OIDC equivalent — treat as bearer tokens, rotate periodically |
| Use `permissions:` blocks to scope `GITHUB_TOKEN` per job | Least privilege — a lint job never needs `packages: write` |
| Never bake secrets into Docker image layers | Anyone who can pull the image can extract any layer's filesystem history (Part 3) |
| Use Dependabot for the workflow files themselves | Your CI's own action dependencies are part of your supply chain (Part 5) |

---

## Appendix C: Deployment Checklist — Setting Up OIDC Between GitHub and Your Cloud Provider

Follow in order. Reference: Part 4.

1. **Enable GitHub's OIDC provider on the cloud side.**
   Create an Identity Provider resource trusting `https://token.actions.githubusercontent.com` as the issuer, with audience `sts.amazonaws.com` (AWS) or the provider-specific equivalent (GCP Workload Identity Pool, Azure Federated Credential). Do this once, via IaC (Part 4), not manually.

2. **Create a dedicated IAM role (not a user) for GitHub Actions.**
   Never reuse a human's IAM identity. This role exists solely to be assumed by CI.

3. **Write a narrow trust policy condition.**
   Restrict the `sub` claim to an exact pattern: `repo:your-org/your-repo:ref:refs/heads/main` for production-deploy roles, `repo:your-org/your-repo:pull_request` for plan-only/read-only roles. Never trust `repo:your-org/*` broadly across an entire org unless every repo in that org is equally trusted.

4. **Attach a least-privilege permission policy to the role.**
   Enumerate only the specific actions the pipeline performs (e.g., `s3:PutObject` on one named bucket) — never attach a managed `AdministratorAccess`-equivalent policy.

5. **Add `permissions: id-token: write` to the workflow.**
   Without this line, the job cannot request an OIDC token from GitHub at all, and the cloud provider's `sts.AssumeRoleWithWebIdentity` call fails before it starts.

6. **Use the official cloud-provider Action to exchange the token.**
   E.g., `aws-actions/configure-aws-credentials@v4` with `role-to-assume` set to the role's ARN. This action performs the OIDC-to-temporary-credentials exchange for you — no manual `curl`/`sts` calls needed.

7. **Verify no static keys remain in repo/org secrets.**
   Audit Settings → Secrets and remove any `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` pairs once OIDC is confirmed working — leaving both in place defeats the purpose.

8. **Scope the role per-Environment, not per-repo, when you have multiple deploy targets.**
   Use GitHub Environments (`staging`, `production`) each with their own `environment:` secrets/role ARN, so a compromised staging pipeline cannot assume the production role.

9. **Test the exchange with a plan-only/read-only action first.**
   Run a workflow that only calls `tofu plan` (Part 4) or an equivalent read-only cloud call before ever wiring up an `apply`/write path — confirms the trust policy works without risking any real infrastructure change.

10. **Add the drift-detection and rollback safety nets from Parts 4 and 6 before your first real production apply.**
    OIDC removes the *credential* risk; it does not remove the *logic* risk of a bad `apply`. Pair secure auth with the plan-artifact-integrity and approval-gate patterns already covered.

---

**Series complete.** Return to the **"DevOps Mastery - INDEX (Start Here)"** note for the full table of contents and reading order.

---

That's the full 8-part series plus all three appendices — every note has now been delivered in this chat. As a reminder: Parts 4, 7, and 8 are stored in prose/structural form rather than literal fenced code blocks due to a recurring note-tool error. If you'd like me to retry converting those three into full literal `.yml`/`.tf`/Dockerfile code blocks (matching the style of Parts 1, 2, 3, 6, and the Appendices), just let me know and I'll regenerate them.
