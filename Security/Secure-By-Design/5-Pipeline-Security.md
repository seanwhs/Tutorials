# Secure by Design — Part 5: Infrastructure & Pipeline Security

## 1. Concept & Architecture Rationale

### The supply chain is now the attack surface

Modern breaches increasingly target the build/deploy pipeline itself rather than the running application (SolarWinds, the xz-utils backdoor, countless typosquatted npm packages). Your CI/CD pipeline has write access to production — it is, architecturally, one of the most privileged systems in your organization, and must be defended as such, not treated as "just tooling."

### Three supply-chain layers to secure

- **Source integrity**: is the code that gets built actually the code that was reviewed? (signed commits from Part 1, protected branches)
- **Build integrity**: does the build environment itself introduce risk? (compromised runners, poisoned build-time dependencies, unpinned actions)
- **Artifact integrity**: once built, can you prove a container image or release artifact hasn't been tampered with before deployment? (signing, provenance attestation)

### Infrastructure-as-Code (IaC) as a threat-modelable artifact

If your infrastructure (Terraform, Pulumi, Kubernetes manifests) is code, it deserves the same static analysis as application code. A misconfigured S3 bucket policy or an overly permissive security group is a vulnerability with the same severity as a SQL injection — arguably worse, since it's often silent until exploited.

## 2. Implementation

### Step 1 — Pin every GitHub Action to a commit SHA, not a tag

A tag like `@v4` can be moved by the action's maintainer (or an attacker who compromises their account) to point at malicious code without your repository changing at all. Pin to the full commit SHA instead — e.g., reference `actions/checkout` at its specific 40-character SHA with a trailing comment noting the version, `# v4.2.2`. Enforce this automatically with **Dependabot** (free, native to GitHub) configured to watch `github-actions` as an ecosystem in `.github/dependabot.yml`, which opens PRs to bump pinned SHAs when new versions are released — you get the safety of pinning without losing the convenience of update tracking.

### Step 2 — Harden the runner: least-privilege GITHUB_TOKEN

By default, GitHub Actions workflows receive a `GITHUB_TOKEN` with broad permissions. Set `permissions: {}` at the workflow level (deny-all default) and grant only the specific scopes each job needs at the job level — e.g., a job that uploads SARIF results needs `security-events: write` and nothing else; a job that only runs tests needs `contents: read` and nothing else. This is Least Privilege (Part 1) applied directly to pipeline identity.

### Step 3 — Use GitHub Environments with required reviewers for production deploys

Configure a `production` Environment (free feature) with required reviewers — a deploy job targeting production pauses and waits for a designated approver, even if all prior CI checks passed. This introduces a human-in-the-loop control specifically at the highest-blast-radius step (the point where code gains the ability to affect real users/data), while keeping every lower-risk step (build, test, scan) fully automated and fast.

### Step 4 — Sign container images with Sigstore/cosign (keyless signing, fully free)

After building a Docker image in CI, sign it before pushing: `cosign sign --yes <registry>/<image>@<digest>` using cosign's keyless mode, which uses your CI job's OIDC identity (GitHub Actions' built-in OIDC token) to obtain a short-lived certificate from the free public Sigstore Fulcio CA — no long-lived signing key to manage or leak. Record the signature in the free public Rekor transparency log automatically. At deploy time, verify: `cosign verify --certificate-identity-regexp "https://github.com/<org>/<repo>/.*" --certificate-oidc-issuer "https://token.actions.githubusercontent.com" <registry>/<image>@<digest>` — deployment proceeds only if the image was signed by your own CI pipeline, specifically, not by anyone who gained push access to your registry through some other means.

### Step 5 — Scan container images with Trivy before push

Trivy (free, open-source, by Aqua Security) scans container images for OS package and application-dependency CVEs, misconfigurations, and even embedded secrets, in one tool: `trivy image --severity CRITICAL,HIGH --exit-code 1 <image>:<tag>` as a CI step run immediately after build and before push — a non-zero exit code fails the job. This is SCA (Part 3) extended to the OS layer, which `npm audit`-style tooling never reaches.

### Step 6 — Harden the Dockerfile itself

Concrete hardening rules to apply and enforce via Trivy's misconfiguration checks: use a minimal, pinned base image digest (not `node:latest` — pin to a specific digest so the base image can't silently change underneath you); run as a non-root `USER` directive, never root; use multi-stage builds so build-time dependencies and secrets (like private npm registry tokens used only during `npm install`) never exist in the final runtime image layer; and add a `HEALTHCHECK` so orchestrators can detect and restart a compromised or hung container quickly (an Availability control).

### Step 7 — IaC scanning with Checkov or tfsec (both free, open-source)

Run `checkov -d ./infrastructure` (or `tfsec ./infrastructure` for a lighter, Terraform-specific alternative) as a required CI check on any PR touching Terraform/Pulumi/Kubernetes manifest files. These tools ship hundreds of built-in rules mapped to CIS Benchmarks and cloud provider best practices — catching, for example, a security group rule allowing inbound `0.0.0.0/0` on port 22, an S3 bucket without encryption-at-rest enabled, or a Kubernetes pod spec running a privileged container — before `terraform apply` or `kubectl apply` ever executes.

### Step 8 — Policy-as-Code with Open Policy Agent (OPA) for org-wide standards

Where Checkov/tfsec provide broad, general rule coverage, **OPA with Rego policies** lets you encode your *own* organization-specific rules as code, evaluated automatically against Terraform plans (via `conftest`, OPA's companion CLI) or Kubernetes admission requests (via OPA Gatekeeper in-cluster). Example policy in prose: deny any Terraform plan that creates a database resource without a `tags["data-classification"]` attribute set, or deny any Kubernetes pod spec that omits `resources.limits`, preventing a single misconfigured deployment from being able to exhaust cluster resources (an Availability threat). Run `conftest test --policy ./policy plan.json` (where `plan.json` is `terraform show -json` output) as a required CI check, exactly parallel to how Semgrep gates application code in Part 3 — this is "Policy-as-Code" in the literal, syllabus-specified sense.

### Step 9 — Generate provenance/SBOM for the full build (not just dependencies)

Combine Syft (Part 4's SBOM tool) with in-toto/SLSA provenance attestation generated via GitHub Actions' native `actions/attest-build-provenance` (free, built into GitHub) to produce a cryptographically signed statement of exactly which source commit, which workflow, and which runner produced a given artifact — satisfying SLSA Build Level 2/3 practices without any paid tooling.

## 3. Exercise Challenge

1. Audit your `.github/workflows/*.yml` files: pin every third-party action to a commit SHA and add `.github/dependabot.yml` watching the `github-actions` ecosystem.
2. Add explicit least-privilege `permissions:` blocks to every workflow and job.
3. Configure a `production` GitHub Environment with at least one required reviewer, and gate your deploy job behind it.
4. Add Trivy image scanning and cosign keyless signing/verification to your container build pipeline.
5. Run Checkov or tfsec against any IaC in your repo and fix the top 3 findings; add it as a required CI check.

## 4. Solution & Explanation

Applied to a typical containerized deployment: the Dockerfile is rewritten to a pinned-digest, multi-stage, non-root build; Trivy scans the resulting image and fails on any Critical/High CVE with an available fix; cosign signs the image using the CI job's GitHub OIDC identity with no managed key material anywhere; the deploy workflow's final job requires the `production` Environment and a human reviewer's approval; and `cosign verify` runs as the very first step of the deploy job itself, refusing to proceed if the image's signature doesn't match the expected repository identity — meaning even if an attacker somehow pushed a malicious image directly to the registry (bypassing CI entirely), the deploy step itself would refuse to run it.

Why this matters architecturally: this closes the "artifact integrity" gap identified at the top of this Part — code review and branch protection (source integrity) and a hardened build (build integrity) are worthless if the thing actually deployed isn't provably the thing that was built and scanned.

## 5. Key Takeaways

- The CI/CD pipeline is a highly privileged system and must be threat-modeled and hardened like production itself.
- Pin GitHub Actions to commit SHAs, not tags; let Dependabot manage updates safely.
- Least-privilege `GITHUB_TOKEN` scoping and required-reviewer Environments apply Least Privilege to pipeline identity, not just human identity.
- Sigstore/cosign keyless signing plus Trivy scanning together secure the container supply chain end-to-end with zero managed key material and zero paid tooling.
- IaC misconfigurations are vulnerabilities with real severity; scan them with Checkov/tfsec, and encode org-specific rules with OPA/Rego via conftest.

Next: Part 6 — Zero-Trust Network Design, where we stop trusting the internal network entirely: mTLS between services, service-to-service authentication, and egress filtering.
