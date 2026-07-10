# Appendix B: Open-Source Toolkit

A consolidated list of every free/open-source tool referenced across the series, grouped by function, with install and first-run commands. All tools here are free — no paid tiers required to follow this series.

## SAST — Static Application Security Testing

**Semgrep** — pattern-based static analysis with dataflow/taint tracking.
- Install: `pip install semgrep`
- First run: `semgrep --config auto .`
- OWASP-focused ruleset: `semgrep --config p/owasp-top-ten .`
- Used in: Part 3 (core), Part 5, Part 8

## SCA — Software Composition Analysis

**OWASP Dependency-Track** — continuous dependency vulnerability monitoring via SBOM ingestion.
- Install: `docker compose -f docker-compose.yml up -d` (official compose file from the Dependency-Track GitHub repo)
- Used in: Part 3

**Syft** — SBOM generator (by Anchore).
- Install: `curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin`
- First run: `syft dir:. -o cyclonedx-json > sbom.json`
- Used in: Part 3, Part 5

## Container & Supply Chain Security

**Trivy** — container image, filesystem, and IaC misconfiguration scanner.
- Install: `brew install aquasecurity/trivy/trivy` (or Docker: `docker run aquasec/trivy`)
- First run: `trivy image --severity CRITICAL,HIGH <image>:<tag>`
- Used in: Part 5

**cosign** (Sigstore) — keyless container image signing and verification.
- Install: `brew install cosign`
- Sign: `cosign sign --yes <registry>/<image>@<digest>`
- Verify: `cosign verify --certificate-identity-regexp "..." --certificate-oidc-issuer "https://token.actions.githubusercontent.com" <image>@<digest>`
- Used in: Part 5

## Secrets Scanning

**Trufflehog** — verified secret detection in git history.
- Install: `brew install trufflehog`
- First run: `trufflehog git file://. --since-commit HEAD~1 --only-verified`
- Used in: Part 4, Part 8

**Infisical** / **HashiCorp Vault (OSS)** — self-hosted secrets management.
- Infisical install: `docker run -p 8080:8080 infisical/infisical`
- Used in: Part 4

## DAST — Dynamic Application Security Testing

**OWASP ZAP** — automated black-box web app scanning.
- Install: Docker image `zaproxy/zap-stable`
- First run: `docker run -t zaproxy/zap-stable zap-baseline.py -t https://staging.yourapp.com -r zap-report.html`
- Used in: Part 8

## IaC & Policy-as-Code

**Checkov** — IaC misconfiguration scanner.
- Install: `pip install checkov`
- First run: `checkov -d ./infrastructure`
- Used in: Part 5

**tfsec** — lightweight Terraform-specific scanner.
- Install: `brew install tfsec`
- First run: `tfsec ./infrastructure`
- Used in: Part 5

**Open Policy Agent (OPA) + Conftest** — custom policy-as-code evaluation.
- Install: `brew install opa conftest`
- First run: `conftest test --policy ./policy plan.json`
- Used in: Part 5

## Threat Modeling

**OWASP Threat Dragon** — DFD-based STRIDE threat modeling tool.
- Install: `docker run -p 3000:3000 owasp/threat-dragon:latest`
- Used in: Part 1, Part 8

## Identity & Network

**Keycloak** — self-hosted, free OIDC/OAuth2 identity provider.
- Install: `docker run -p 8080:8080 quay.io/keycloak/keycloak:latest start-dev`
- Used in: Part 2 (alternative to Clerk/Auth0)

**step-ca** — private certificate authority for service identity.
- Install: `brew install step step-cli step-ca`
- Used in: Part 6

**Linkerd** — lightweight service mesh with automatic mTLS.
- Install: `curl -sL https://run.linkerd.io/install | sh`
- First run: `linkerd install | kubectl apply -f -`
- Used in: Part 6

**SPIRE** — SPIFFE runtime for workload identity.
- Used in: Part 6

**ModSecurity + OWASP Core Rule Set** — open-source WAF.
- Used in: Part 6

## Monitoring & SIEM/SOAR

**Grafana + Loki** — centralized logging and dashboards.
- Install: `docker compose up` (official Grafana/Loki compose file)
- Used in: Part 7

**Vector** — log/metrics shipping agent.
- Install: `curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | bash`
- Used in: Part 7

**Wazuh** — full open-source SIEM with active response.
- Install: `curl -sO https://packages.wazuh.com/4.x/wazuh-install.sh && sudo bash wazuh-install.sh -a`
- Used in: Part 7

**Falco** — runtime intrusion detection for containers.
- Install: `helm install falco falcosecurity/falco`
- Used in: Part 7

## Architecture & Audit

**Structurizr Lite** — free C4 model diagramming.
- Install: `docker run -p 8080:8080 -v $PWD:/usr/local/structurizr structurizr/lite`
- Used in: Part 8

**OSA (Open Security Architecture)** — free pattern catalog (reference site/documentation, not installable software).
- Used in: Part 8

## GitHub-Native (all free)

- **Dependabot** — dependency + GitHub Actions update PRs
- **Secret Scanning + Push Protection** — native leak prevention
- **CodeQL** — GitHub's native SAST (complementary to Semgrep)
- **Branch Protection Rules** — required status checks, signed commits
- **Environments** — scoped secrets, required reviewers
- **actions/attest-build-provenance** — native SLSA provenance attestation

## Quick-Start Priority Order (if starting from zero)

1. GitHub branch protection + secret scanning (Part 1) — zero infrastructure, immediate value
2. Semgrep in CI (Part 3) — highest signal-to-effort ratio for catching real bugs
3. Trufflehog in CI (Part 4) — cheap insurance against the most common real-world leak vector
4. Dependency-Track + Syft (Part 3) — closes the "vulnerable dependency" gap
5. Trivy + cosign (Part 5) — once you're shipping containers
6. Grafana/Loki + structured audit logging (Part 7) — before you need it, not after an incident
7. Service mesh mTLS (Part 6) — once you have more than one internal service worth isolating
