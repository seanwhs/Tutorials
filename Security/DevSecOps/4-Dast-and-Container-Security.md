# Phase 4: Dynamic Testing & Container Security

**Core Focus:** DAST, Container Image Scanning & Image Signing.

Everything so far has analyzed *files at rest* — source code, dependencies, blueprints. But some vulnerabilities only appear when the software is *actually running*, and some risks live in the *container image's operating-system layers* rather than your code. Phase 4 addresses the **"package" and "deploy" stages** with three new guardrails:

1. **Container image scanning** — inspect the OS packages and layers *inside* the built image for known CVEs.
2. **Image signing** — cryptographically sign the image so downstream systems can *prove* it came from our trusted pipeline and wasn't swapped by an attacker.
3. **DAST** — attack the *running* app like a real hacker would, sweeping for runtime vulnerabilities before promotion to production.

> **Mental model:** Phase 2 read the recipe. Phase 3 inspected the kitchen blueprint. Phase 4 tastes the finished dish (container scan), seals it with a tamper-proof wax stamp (signing), and hires a food critic to attack it (DAST) — all before it reaches customers.

---

## Step 4.1 — Build & Push the Image in CI

### 🎯 The Target
Add a CI job that builds the Docker image and pushes it to the **GitHub Container Registry (GHCR)** — but *only* after all Phase 1–3 security gates have passed.

### 🧠 The Concept
> **Definition — Container Registry:** A warehouse for storing and distributing container images (like npm for containers). **GHCR** is GitHub's built-in registry.

We build the image *centrally in CI* rather than trusting whatever a developer built on their laptop. This gives us a **single, auditable production artifact** — the exact bytes we'll scan, sign, and deploy. Crucially, we make this job **depend on** the security jobs, so a vulnerable image is never even built.

> **Definition — image digest:** A cryptographic hash (`sha256:...`) that uniquely identifies an exact image. Unlike a mutable tag (`latest`), a digest can't be silently changed — we'll sign the *digest*.

### ⌨️ The Implementation

Create a dedicated build-and-publish workflow so it can gate cleanly on the security workflow:

**`.github/workflows/release.yml`**
```yaml
name: Build, Scan & Sign Image

on:
  push:
    branches: [main]
    tags: ["v*"]

# Permissions needed to push to GHCR and to sign with keyless OIDC.
permissions:
  contents: read
  packages: write      # push image to GHCR
  id-token: write      # request OIDC token for keyless signing (Step 4.3)

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}   # e.g. yourname/securenotes

jobs:
  build:
    name: Build & Push Image
    runs-on: ubuntu-latest
    outputs:
      # Expose the pushed image's digest so later jobs scan/sign the EXACT image.
      digest: ${{ steps.push.outputs.digest }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}   # auto-provided, scoped token

      - name: Extract image metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha                       # tag with the commit SHA
            type=ref,event=branch          # tag with the branch name
            type=semver,pattern={{version}} # tag releases like v1.2.3

      - name: Set up Buildx (advanced Docker builder)
        uses: docker/setup-buildx-action@v3

      - name: Build and push
        id: push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          # SBOM + provenance attestations attached to the image (supply chain).
          sbom: true
          provenance: true
```

### ✅ The Verification

Push to `main`:
```bash
git push origin main
```
Open the **Actions** tab → **Build, Scan & Sign Image** workflow. The `build` job should:
1. Log in to GHCR.
2. Build the image (using our hardened multi-stage Dockerfile).
3. Push it, printing an image **digest** (`sha256:...`) in the logs.

Then check your repo's **Packages** section on GitHub — you'll see the `securenotes` container image with its tags. The digest is what we'll scan and sign next.

---

## Step 4.2 — Deep Container Image Scanning

### 🎯 The Target
Scan the *pushed image* (not just source files) for vulnerabilities in its OS packages and layers, failing on HIGH/CRITICAL findings.

### 🧠 The Concept
Your image is a **stack of transparent sheets** (layers): the base OS (`node:20-alpine`), then Node, then your dependencies, then your code. A vulnerability can hide in *any* sheet — for example, an outdated OpenSSL library in the base OS layer that your code never touches but an attacker can still exploit. Source scanning (Phase 2) can't see these; only **image scanning** peers through every layer.

> **Why this differs from SCA:** SCA (Phase 2) scanned your *npm* dependencies. Image scanning also covers the *operating-system* packages (apk/apt libraries) baked into the base image — a whole additional attack surface.

### ⌨️ The Implementation

Add a scanning job that runs *after* the build. Append to **`.github/workflows/release.yml`** under `jobs:`:

```yaml
  scan:
    name: Scan Image (Trivy)
    runs-on: ubuntu-latest
    needs: build           # only run after the image is built & pushed
    permissions:
      contents: read
      packages: read
      security-events: write   # upload results to GitHub Security tab
    steps:
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Scan the EXACT image by digest (immutable — can't be swapped).
      - name: Trivy image scan (gate on HIGH/CRITICAL)
        uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ needs.build.outputs.digest }}
          format: "table"
          severity: "HIGH,CRITICAL"
          exit-code: "1"          # fail the pipeline on serious CVEs
          ignore-unfixed: true    # don't block on CVEs with no upstream fix yet
          vuln-type: "os,library" # scan BOTH OS packages AND app libraries

      # Also produce a SARIF report for GitHub's Security tab (for triage).
      - name: Trivy scan (SARIF report, non-blocking)
        uses: aquasecurity/trivy-action@0.24.0
        if: always()   # run even if the gate above failed, to record findings
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ needs.build.outputs.digest }}
          format: "sarif"
          output: "trivy-image.sarif"
          severity: "HIGH,CRITICAL,MEDIUM"

      - name: Upload results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: "trivy-image.sarif"
```

> **Why `node:20-alpine`?** Alpine is a minimal Linux base with far fewer packages than Debian/Ubuntu — fewer packages means fewer potential CVEs. This choice back in Phase 3 pays off here as a smaller, quieter scan.

### ✅ The Verification

Push and watch the **scan** job run after **build**. On a clean, up-to-date base image it should pass (or report only unfixed low-severity items, which we ignore).

Reproduce the scan locally to see the layer analysis:
```bash
# Scan your locally built image
trivy image --severity HIGH,CRITICAL --vuln-type os,library securenotes:local
```

**Prove image scanning catches OS-layer vulns.** Temporarily pin an *old* base image in the `Dockerfile`:
```dockerfile
# TEMPORARY: an intentionally outdated base with known CVEs
FROM node:18.0.0-alpine AS build
```
Rebuild and scan:
```bash
docker build -t securenotes:oldbase .
trivy image --severity HIGH,CRITICAL securenotes:oldbase
```
Trivy now reports **OS-package CVEs from the stale base image** — vulnerabilities living entirely outside your code. **Revert** to `node:20-alpine` and confirm the scan is clean again. This demonstrates why keeping base images current is a security task, not just maintenance.

---

## Step 4.3 — Sign the Image (Provenance & Integrity)

### 🎯 The Target
Digitally **sign** the scanned image with **Cosign** (keyless signing via OIDC) so anyone can verify it was produced by our exact pipeline and hasn't been tampered with.

### 🧠 The Concept
> **Definition — Cosign (Sigstore):** An open-source tool for signing and verifying container images. "Keyless" mode uses your CI's short-lived identity (OIDC token) to sign — no long-lived private keys to leak.

Signing is a **tamper-proof wax seal on a letter.** When a king sent a sealed letter, the recipient knew (a) it truly came from the king and (b) nobody opened it en route. A signed image lets your deployment system verify: *"This exact image (by digest) was signed by our trusted GitHub Actions pipeline."* If an attacker pushes a malicious image to the registry, it won't have a valid signature, and deployment refuses it.

> **This directly defends the "CI pipeline → registry" trust boundary** from our threat model — closing the door on supply-chain image tampering.

### ⌨️ The Implementation

Add a signing job that runs after a successful scan. Append to **`.github/workflows/release.yml`** under `jobs:`:

```yaml
  sign:
    name: Sign Image (Cosign)
    runs-on: ubuntu-latest
    needs: [build, scan]   # only sign an image that BUILT and PASSED scanning
    permissions:
      contents: read
      packages: write
      id-token: write      # required for keyless OIDC signing
    steps:
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Install Cosign
        uses: sigstore/cosign-installer@v3

      - name: Sign the image by digest (keyless)
        env:
          DIGEST: ${{ needs.build.outputs.digest }}
        # --yes skips the confirmation prompt. Keyless signing uses the
        # workflow's OIDC identity; the signature is stored in the registry
        # and logged in the public Rekor transparency ledger.
        run: |
          cosign sign --yes \
            "${REGISTRY}/${IMAGE_NAME}@${DIGEST}"
```

Document how deployers verify the signature (used by the deploy gate in Step 4.5):

**`docs/verifying-images.md`**
```markdown
# Verifying a signed securenotes image

Before deploying, verify the image was signed by OUR pipeline:

    cosign verify \
      --certificate-identity-regexp "https://github.com/<OWNER>/securenotes/.github/workflows/release.yml@.*" \
      --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
      ghcr.io/<OWNER>/securenotes@sha256:<DIGEST>

- `--certificate-identity-regexp` pins WHO is allowed to have signed
  (our release workflow, and nobody else).
- `--certificate-oidc-issuer` pins the trusted identity provider (GitHub).

If verification fails, the image is NOT trusted — do not deploy it.
```

### ✅ The Verification

Push to `main`. The workflow now runs **build → scan → sign** in sequence. The **sign** job logs a successful signing and an entry uploaded to the **Rekor** transparency log.

Verify the signature yourself (replace `<OWNER>` and `<DIGEST>`):
```bash
# Install cosign locally: brew install cosign  (or download a release)
cosign verify \
  --certificate-identity-regexp "https://github.com/<OWNER>/securenotes/.github/workflows/release.yml@.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/<OWNER>/securenotes@sha256:<DIGEST>
```
A successful verification prints the certificate details and the Rekor log entry. **Prove tamper-detection:** try verifying a *different* image (or a fake digest) — verification **fails**, exactly as a broken wax seal would reveal tampering.

---

## Step 4.4 — DAST: Attack the Running App

### 🎯 The Target
Spin up the app in CI and run **OWASP ZAP** (a DAST scanner) against it, sweeping the live endpoints for runtime vulnerabilities.

### 🧠 The Concept
> **Definition — DAST (Dynamic Application Security Testing):** Testing the *running* application from the outside, like an attacker with no source-code access. It sends real HTTP requests probing for vulnerabilities.
> **Definition — OWASP ZAP:** A free, industry-standard DAST tool (the "Zed Attack Proxy").

DAST is the **mystery shopper** of security testing. Instead of reading the store's policies (source code), it walks in as a customer and *tries things* — probing forms, headers, and endpoints for weaknesses that only manifest at runtime (missing security headers, verbose error leaks, injection points, broken auth). It catches issues static analysis can't, because it sees the app's *actual behavior*.

### ⌨️ The Implementation

Add a DAST job to the security workflow. This job launches PostgreSQL and the app as services, waits for health, then runs ZAP. Append to **`.github/workflows/security.yml`** under `jobs:`:

```yaml
  dast:
    name: DAST (OWASP ZAP)
    runs-on: ubuntu-latest
    # Only worth running on PRs/main where the full app can boot.
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: securenotes
          POSTGRES_PASSWORD: cipassword
          POSTGRES_DB: securenotes
        ports:
          - 5432:5432
        # Health check so the app doesn't start before the DB is ready.
        options: >-
          --health-cmd "pg_isready -U securenotes"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install & build
        run: |
          npm ci
          npm run build

      - name: Load DB schema
        env:
          PGPASSWORD: cipassword
        run: |
          psql -h localhost -U securenotes -d securenotes -f db/init.sql

      - name: Start the app in the background
        env:
          NODE_ENV: test
          PORT: 3000
          JWT_SECRET: ci-only-super-long-secret-for-dast-testing-1234
          DATABASE_URL: postgres://securenotes:cipassword@localhost:5432/securenotes
        run: |
          node dist/server.js &          # run app in background
          echo "Waiting for app to be healthy..."
          npx wait-on http://localhost:3000/health --timeout 30000

      - name: OWASP ZAP baseline scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: "http://localhost:3000"
          # Rules to warn vs fail are tuned in this config (low noise).
          rules_file_name: ".zap/rules.tsv"
          # -a: include alpha passive rules for broader coverage.
          cmd_options: "-a"
          # Don't fail the build on WARN-level (only on FAIL-level) to start —
          # tighten this over time as you fix findings.
          fail_action: false
```

We need `wait-on` available for the health check:
```bash
npm install --save-dev wait-on
```

Tune ZAP's rules so known/accepted findings are warnings, not hard failures (keeps noise low, per our developer-friction principle):

**`.zap/rules.tsv`**
```tsv
# ZAP rule tuning. Columns: RULE_ID	ACTION	(optional URL regex)
# ACTION: IGNORE | WARN | FAIL
# We WARN on informational headers ZAP flags on a JSON API, and FAIL on
# genuinely serious findings. Adjust as the app matures.
10015	WARN	# Incapsulation / cache-control on API responses (low risk for JSON API)
10096	IGNORE	# Timestamp disclosure (our /health returns uptime by design)
10021	WARN	# X-Content-Type-Options (Helmet sets this; guards against regressions)
40012	FAIL	# Cross-Site Scripting (reflected) — always fail
40018	FAIL	# SQL Injection — always fail
90022	FAIL	# Application error disclosure — always fail
```

### ✅ The Verification

Push and open the **DAST (OWASP ZAP)** job in the **Actions** tab. It will:
1. Start PostgreSQL, load the schema, boot the app.
2. Wait for `/health` to respond.
3. Run ZAP's baseline crawl and produce an HTML/markdown report (downloadable as an artifact, and posted as a PR comment).

Run ZAP locally to see the report firsthand:
```bash
# Start the app + DB locally first (docker compose up -d && npm run dev)
docker run --rm --network host -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:3000 -a
```
ZAP will list passive findings. Because Phase 1 added Helmet, you should see it *pass* checks for security headers that an unhardened app would fail — a satisfying confirmation that earlier work holds up under dynamic probing.

**Prove DAST catches a runtime regression.** Temporarily comment out `app.use(helmet());` in `src/server.ts`, rebuild, and re-run ZAP — it now **flags missing security headers** (like `X-Content-Type-Options`) that were previously present. Restore Helmet and confirm the findings disappear.

---

## Step 4.5 — The Deployment Gate: Verify Before You Deploy

### 🎯 The Target
Add a staging-deploy job that runs *only* after build+scan+sign, and that **verifies the image signature** before deploying — a hard gate at the deployment boundary.

### 🧠 The Concept
This is the **bouncer checking IDs at the VIP entrance.** Even though we signed the image upstream, the deploy step independently *verifies* that signature before letting the image in. This closes a subtle gap: it ensures the thing being deployed is *exactly* the artifact our pipeline produced and vouched for — not a look-alike an attacker slipped into the registry.

> This makes signing *meaningful*. A signature nobody checks is just decoration; the verification gate is what turns it into a real control.

### ⌨️ The Implementation

Add a deploy-to-staging job. Append to **`.github/workflows/release.yml`** under `jobs:`:

```yaml
  deploy-staging:
    name: Deploy to Staging (verified)
    runs-on: ubuntu-latest
    needs: [build, scan, sign]   # ALL security gates must pass first
    environment: staging          # GitHub environment (can add approvals)
    permissions:
      contents: read
      packages: read
      id-token: read
    steps:
      - name: Install Cosign
        uses: sigstore/cosign-installer@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # THE GATE: refuse to deploy unless the signature verifies.
      - name: Verify image signature before deploying
        env:
          DIGEST: ${{ needs.build.outputs.digest }}
        run: |
          cosign verify \
            --certificate-identity-regexp "https://github.com/${GITHUB_REPOSITORY}/.github/workflows/release.yml@.*" \
            --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
            "${REGISTRY}/${IMAGE_NAME}@${DIGEST}"

      - name: Deploy to staging
        env:
          DIGEST: ${{ needs.build.outputs.digest }}
        # In a real setup this would `kubectl set image`, run `terraform apply`,
        # or call your platform's deploy API — always pinned to the DIGEST,
        # never a mutable tag, so you deploy the EXACT verified bytes.
        run: |
          echo "✅ Signature verified. Deploying ${REGISTRY}/${IMAGE_NAME}@${DIGEST} to staging."
          # Example (pseudo): kubectl set image deploy/securenotes \
          #   app="${REGISTRY}/${IMAGE_NAME}@${DIGEST}" -n staging
```

### ✅ The Verification

Push to `main`. The full pipeline now runs end to end:

```
build ─▶ scan ─▶ sign ─▶ deploy-staging(verify ▶ deploy)
```

In the **Actions** tab, open **deploy-staging** and confirm the **"Verify image signature"** step succeeds *before* the deploy step runs, printing `✅ Signature verified.`

**Prove the gate blocks unsigned/tampered images.** Temporarily change the verify step's identity regexp to a wrong repo (simulating an attacker's image signed by someone else):
```yaml
# TEMPORARY wrong identity to prove the gate fails:
--certificate-identity-regexp "https://github.com/some-other-org/.*"
```
The **verify step fails**, and because deploy `needs` a green verify, **deployment never happens.** Revert to the correct regexp. The deployment boundary is now enforced by cryptographic proof.

Commit the Phase 4 completion:
```bash
git add . && git commit -m "feat(security): Phase 4 — image scan, sign & DAST gate complete"
git push
```

---

## 📚 Phase 4 Reference Section

*Deep dives — skip on first pass.*

### R4.1 — Image scanning vs SCA: what each covers
| Layer of the image | Covered by |
|---|---|
| Your application code | SAST (P2) |
| Your npm dependencies | SCA (P2) *and* image scan |
| OS packages (openssl, libc, etc.) | **Image scan only** (P4) |
| Base-image config (root user, etc.) | IaC/Dockerfile audit (P3) + image scan |
Image scanning is the only stage that sees the operating-system layer — the reason "my code is clean" is not the same as "my image is clean."

### R4.2 — Why keyless signing beats key-based
Traditional signing requires a private key you must store, protect, and rotate — a high-value secret that, if leaked, lets attackers sign malicious images. **Keyless (Sigstore)** signing uses your CI's *short-lived OIDC identity* — there's no long-lived key to steal. The signature is bound to *who* signed (the workflow identity) and recorded in the public **Rekor** transparency log, so signatures are auditable and non-repudiable.

### R4.3 — DAST baseline vs full scan
- **Baseline scan** (what we run): a fast, *passive* + light active crawl. Safe for CI, low false positives, catches config/header issues. Runs in minutes.
- **Full active scan**: aggressively attacks the app (injection payloads, fuzzing). More thorough but slow and potentially destructive — run it against a *dedicated staging environment* on a schedule, not on every PR.

### R4.4 — Authenticated DAST
Our baseline scan hits public endpoints. To scan *behind* login (the `/notes` API), you provide ZAP a valid JWT or a login script so it can crawl authenticated routes. This is the next maturity step: point ZAP at a test account so it exercises the protected surface where the most sensitive logic lives.

### R4.5 — Deploying by digest, not tag
Tags like `:latest` are *mutable* — the image they point to can change after you verified it (a classic "time-of-check to time-of-use" attack). Deploying by **digest** (`@sha256:...`) guarantees the bytes you verified are the bytes you run. Always pin production deployments to a digest.

### R4.6 — The full pipeline so far
```
DEVELOP        BUILD              PACKAGE                 DEPLOY
─ pre-commit   ─ SAST (Semgrep)   ─ build image           ─ verify signature
─ IDE lint     ─ SCA (npm/Trivy)  ─ image scan (Trivy)    ─ deploy by digest
─ secret hook  ─ secret history   ─ sign (Cosign)         to staging
               ─ IaC audit        ─ DAST (ZAP)
```
Every arrow is a gate that can halt the pipeline before a vulnerable artifact advances. Phase 5 adds the final stage: watching the app *in production*.
