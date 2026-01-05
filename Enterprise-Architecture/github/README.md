# Repository Automation & Contribution Standards

This directory contains the configurations and automation required to maintain the integrity of the Enterprise Architecture (EA) repository.

## Components
* **workflows/**: Automated CI/CD pipelines for linting ADRs (Markdownlint), validating link integrity, and auto-generating the Tech Radar site.
* **ISSUE_TEMPLATE/**: Standardized forms for proposing new architectural standards or reporting "Snowflake" services.
* **PULL_REQUEST_TEMPLATE.md**: A mandatory checklist ensuring all changes are mapped to business value and cross-referenced with relevant ADRs.

## Contribution Workflow
1. **Propose**: Open an issue using the "Request for Standard" template.
2. **Draft**: Create a PR adding a draft ADR or Blueprint.
3. **Review**: Peer review by the Architecture Review Board (ARB).
4. **Merge**: Once approved, the new standard becomes part of the "Golden Path."
