# Secure by Design — Part 3: Secure Coding & Taint Analysis

## 1. Concept & Architecture Rationale

### Shift-Left in the PR, not just the mindset

Part 1 gave you the mindset; Part 3 makes it enforceable. If a security control depends on a developer remembering to run a scan manually, it will eventually be skipped. The architectural answer is to make the CI/CD pipeline itself a security gate — untrusted code cannot reach main without passing automated checks.

### Two complementary, distinct problems: SAST vs SCA

- **SAST (Static Application Security Testing)** analyzes code you wrote for dangerous patterns — taint flows from untrusted input to a dangerous sink (e.g., user input flowing unsanitized into a SQL query, a shell command, or `dangerouslySetInnerHTML`). Tool: **Semgrep** (free, open-source, OSS rule registry).
- **SCA (Software Composition Analysis)** analyzes code you didn't write — your third-party dependencies — for known vulnerabilities (CVEs) and license risk. Tool: **OWASP Dependency-Track** (free, open-source, ingests SBOMs).

Both are necessary: a perfectly written application built on top of a dependency with a known Remote Code Execution CVE is still compromised.

### Taint analysis, conceptually

Taint analysis tracks data from a **source** (user input: request body, query param, header, uploaded file) through the code to a **sink** (dangerous operation: raw SQL, shell exec, file path, HTML render, HTTP request to a URL derived from input). If tainted data reaches a sink without passing through a recognized **sanitizer**, it's flagged. This is exactly how Semgrep's dataflow engine and CodeQL work, and it's the mental model behind SQL Injection, Command Injection, SSRF, and XSS — all of Part 4's OWASP Top 10 focus starts as a taint-flow problem caught here in Part 3.

## 2. Implementation

### Step 1 — Install and run Semgrep locally

Semgrep is free and open-source, distributed via pip or Docker. Command: `pip install semgrep`, then `semgrep --config auto .` from the repo root runs Semgrep's free community ruleset (auto-detects language and framework, including dedicated React/Next.js and Node.js rule packs) against your codebase.

For a security-focused subset specifically targeting the OWASP Top 10 categories, use the curated pack: `semgrep --config p/owasp-top-ten .`

### Step 2 — Write a custom rule for a project-specific taint pattern

Generic rules catch generic mistakes. A Principal Architect also writes rules for their own architecture's specific dangerous patterns — for example, catching any Server Action that queries the database without the `requireRole` guard from Part 2. This is a YAML rule file (`.semgrep/require-role-check.yml`) that pattern-matches: any exported async function inside a file under `src/actions/` whose body calls `db.` methods, where the pattern `requireRole(...)` or `requirePermission(...)` does NOT appear anywhere earlier in the function body, is flagged as an error-severity finding with the message "Server Action queries the database without an authorization guard — see Part 2 pattern." This single custom rule operationalizes the entire Part 2 architectural decision as an automated, unskippable gate.

### Step 3 — Wire Semgrep into GitHub Actions as a required check

Workflow file `.github/workflows/semgrep.yml` structure: triggered on `pull_request`; single job running on `ubuntu-latest` using the official `returntocorp/semgrep-action` (or the `semgrep/semgrep` Docker image directly); runs `semgrep ci --config auto --config .semgrep/`; uploads SARIF results to GitHub's Code Scanning tab via the `github/codeql-action/upload-sarif` action, so findings appear as inline PR annotations, not just console output. Mark this job's name (`semgrep-scan`) as a required status check in the branch protection rule you configured back in Part 1.

### Step 4 — Stand up OWASP Dependency-Track for SCA

Dependency-Track runs as two free Docker containers (API server + frontend): `docker compose up` against the official `dependencytrack/dependency-track` compose file spins up the full stack locally or on any free-tier VM. It ingests a Software Bill of Materials (SBOM) rather than scanning source directly.

### Step 5 — Generate an SBOM in CI and upload it

Use **Syft** (free, open-source, by Anchore) to generate a CycloneDX SBOM from your project: `syft dir:. -o cyclonedx-json > sbom.json`. Then upload it to your Dependency-Track instance via its REST API in the same CI job: an authenticated POST to `/api/v1/bom` with the project UUID and the SBOM file. Dependency-Track cross-references every component against the National Vulnerability Database (NVD) and OSS Index continuously, meaning a dependency that was safe last week and became vulnerable today (a new CVE published) triggers an alert on your *existing* codebase even with zero new commits — this is a critical property that a one-time `npm audit` at commit time cannot give you.

### Step 6 — Fail the build on policy violation, not just report it

Both tools support a policy gate. Semgrep: `semgrep ci` returns a non-zero exit code on any finding at or above a configured severity, which naturally fails the GitHub Actions job and blocks merge via required status checks. Dependency-Track: configure a **Policy** (e.g., "no component with a Critical or High severity vulnerability and no fix available may exist in a production-tagged project") and use the `dependency-track-cli` or a REST poll step in CI to query policy violations after upload, failing the pipeline if any exist.

### Step 7 — Track the metric that matters: Mean Time to Remediate (MTTR)

A scanner that only reports is a dashboard; a scanner wired to fail builds and tracked for MTTR is a governance system. Log every finding (Semgrep SARIF + Dependency-Track policy violation) with a first-seen timestamp, and review MTTR trend in your Part 8 audit — a rising MTTR is itself a leading indicator of security debt accumulating faster than the team can address it.

## 3. Exercise Challenge

1. Install Semgrep locally and run `semgrep --config p/owasp-top-ten .` against an existing project. Triage the top 3 findings — for each, mark it as a true positive with a fix, or a false positive with a documented `# nosemgrep` suppression comment explaining why.
2. Write one custom Semgrep rule encoding a project-specific architectural invariant (like the `requireRole` example above) and prove it fires on a deliberately broken test file.
3. Stand up Dependency-Track locally via Docker Compose, generate an SBOM with Syft, and upload it. Identify at least one transitive dependency with a known CVE.
4. Add both scans as required GitHub Actions status checks referenced in your Part 1 branch protection rule.

## 4. Solution & Explanation

The worked solution closes the loop opened in Part 1's branch protection config (`"contexts": ["semgrep-scan", "dependency-review", "secret-scan"]`) — those context names are no longer placeholders; they are now real, required CI jobs. The custom Semgrep rule from Step 2 is the single highest-leverage artifact in this part: it converts a one-time architecture decision (Part 2's `requireRole` pattern) into a permanent, automatically-enforced invariant that survives team turnover, time pressure, and forgetfulness — the actual mechanism of "Shift-Left," not just the philosophy of it.

## 5. Key Takeaways

- SAST (Semgrep) catches dangerous patterns in code you wrote; SCA (Dependency-Track) catches known vulnerabilities in code you didn't write. You need both.
- Taint analysis — source, sink, sanitizer — is the mental model underlying injection, XSS, and SSRF; it's the same model Part 4 uses to reason about OWASP Top 10 mitigations.
- Custom Semgrep rules let you encode your own architectural invariants (like mandatory authorization guards) as unskippable, automated CI gates.
- SBOM-based SCA continuously re-checks existing dependencies against newly published CVEs — a static point-in-time audit is insufficient.
- Wire scanners to fail builds via required status checks, not just report to a dashboard nobody reads.

Next: Part 4 — Data Protection & Cryptography, where we implement encryption-at-rest, environment-isolated secrets management, and close out Injection, SSRF, and XSS with concrete Zod validation and sanitization code.

