## DevOps Mastery: Automating the Modern Software Lifecycle with GitHub

**Perspective:** Principal DevOps Engineer / Technical Instructor
**Tooling:** 100% free & open-source — GitHub Actions, GitHub Packages/GHCR, Docker-based self-hosted runners
**Deployment target:** Vercel (Serverless/PaaS)

### Series Structure

| Part | Title | Core Skill | Status |
|---|---|---|---|
| — | INDEX | Repo structure, prerequisites, framing | ✅ |
| 1 | The CI/CD Foundations | Actions architecture: Workflows, Jobs, Steps, Runners. First test pipeline | ✅ |
| 2 | Advanced Pipeline Logic | Caching, matrix builds, reusable workflows, composite actions | ✅ |
| 3 | Containerization & Registry | Docker builds in CI, layer caching, GHCR push, tagging strategy | ✅ |
| 4 | Infrastructure as Code | OpenTofu provisioning, remote state, OIDC to cloud | ✅ (prose-style code) |
| 5 | DevSecOps & Shift-Left | CodeQL, npm audit/Dependabot, secret scanning, PR-blocking gates | ✅ |
| 6 | GitOps Deployment Strategy | Vercel Blue/Green via aliases, manual approval via GitHub Environments | ✅ |
| 7 | Observability & Feedback | Status checks, PR comments, Slack/Discord webhooks | ✅ (prose-style code) |
| 8 | Scale & Maintenance | Self-hosted runners in Docker, autoscaling, cost/latency tradeoffs | ✅ (prose-style code) |
| — | Appendices A/B/C | File tree + deployment-manifest.yaml, DevOps Matrix, OIDC checklist | ✅ |

### Reference Repository Structure
```
my-app/
├── .github/
│   ├── workflows/
│   │   ├── ci-test.yml              # Part 1
│   │   ├── ci-matrix.yml            # Part 2
│   │   ├── reusable-node-setup.yml  # Part 2
│   │   ├── docker-build-push.yml    # Part 3
│   │   ├── iac-opentofu.yml         # Part 4
│   │   ├── security-scan.yml        # Part 5
│   │   ├── deploy-vercel.yml        # Part 6
│   │   ├── notify.yml               # Part 7
│   │   └── runner-maintenance.yml   # Part 8
│   ├── CODEOWNERS
│   └── dependabot.yml
├── infra/ (backend.tf, main.tf, variables.tf, outputs.tf)
├── deployment-manifest.yaml         # Appendix A
├── docker/Dockerfile
├── src/, tests/, package.json, README.md
```

Each part follows: **Concept Explanation → Implementation → Exercise Challenge → Solution & Explanation.**
