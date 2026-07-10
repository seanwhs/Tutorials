# Secure by Design — Part 8: The Security Audit

## 1. Concept & Architecture Rationale

### Closing the loop: from mindset to measurable assurance

Parts 1–7 built controls layer by layer. Part 8 answers the Principal Architect's real final question: "how do I know this actually holds together, and where are the gaps I can't see because I built the thing?" A structured self-audit is how you find your own blind spots before an external auditor, a penetration tester, or an attacker does.

### Why C4 model for security audit specifically

The **C4 model** (Context, Containers, Components, Code — free, open methodology by Simon Brown) gives you four zoom levels to review architecture at, and each level surfaces a different class of security gap:

- **Context diagram** (system + external actors/systems): surfaces missing trust-boundary analysis — did you threat-model every external integration, or only the obvious ones? (Part 1)
- **Container diagram** (deployable units — app, database, queue, cache): surfaces missing network segmentation and Zero-Trust gaps — does every container-to-container hop have the identity/mTLS treatment from Part 6, or did one get missed?
- **Component diagram** (internal structure within a container): surfaces missing authorization enforcement — does every component that touches sensitive data actually call the Part 2 guard functions, or is there a code path that bypasses them?
- **Code**: surfaces the literal implementation gaps — is validation (Part 4) actually present at every input boundary the Component diagram implies it should be?

Auditing top-down through these four levels, rather than jumping straight to code review, ensures you don't miss systemic gaps (a whole missing trust boundary) while chasing implementation details.

### OSA (Open Security Architecture) patterns as a gap-finding checklist

**OSA** is a free, community-maintained catalog of security architecture patterns and controls, organized by domain (icons/patterns for identity, network, data, etc.) — functionally, a checklist of "here is what a mature control in this domain typically looks like." Using it as an audit tool means comparing your actual implementation against each relevant OSA pattern and explicitly recording match / partial-match / gap for each, rather than relying on an unstructured "does this feel secure" impression.

## 2. Implementation: Running the Self-Audit

### Step 1 — Produce (or update) your C4 diagrams

Use **Structurizr** (the C4 model's own free, open-source-friendly DSL and rendering tool — the "Lite" version runs fully free via Docker: `docker run -p 8080:8080 -v $PWD:/usr/local/structurizr structurizr/lite`) to produce or refresh all four levels. Critically, this should not be drawn from memory — derive it from what's actually deployed (your Part 5 IaC definitions, your Part 6 network policies, your actual `docker-compose.yml`/Kubernetes manifests) so the diagram reflects reality, not intent.

### Step 2 — Context-level audit: re-run STRIDE against the *current* system

Return to your Part 1 `threat-model.json`. For every external entity and trust boundary in your *current* Context diagram, confirm a corresponding STRIDE entry exists. Any new integration added during Parts 2–7 (a new third-party API, a new background job system) that lacks a STRIDE entry is an immediate, concrete finding — record it as "Gap: missing threat model coverage for [integration]."

### Step 3 — Container-level audit: verify Zero-Trust coverage

For every arrow in the Container diagram (every container-to-container connection), check off: is this connection mTLS-authenticated (Part 6)? Is egress from this container explicitly allowlisted, or still default-allow? Is this container's image signed and verified at deploy (Part 5)? Any "no" is a finding, prioritized by the sensitivity of data the container touches.

### Step 4 — Component-level audit: authorization coverage sweep

Grep the codebase (reusing Part 3's Semgrep custom rule — run it fresh, don't assume it still passes) for every database-touching function; confirm each either calls `requireRole`/`requirePermission` (Part 2) or is explicitly documented as intentionally public with a reviewed reason. This is the single highest-value, most concrete finding-generator in the whole audit, because authorization gaps are both common and severe.

### Step 5 — Score each domain against OSA patterns

Build a simple scoring table — for each OSA-style domain (Identity Federation, Data Isolation, Input Validation, Secret Orchestration, Network Segmentation, Logging/Audit, Incident Response) — score: **0 = absent, 1 = partial/manual, 2 = implemented, 3 = implemented + automated/enforced in CI**. A system scoring mostly 2-3 across domains, with specific named exceptions, is a far more credible and actionable audit output than an unscored narrative summary.

### Step 6 — Validate controls actually work, don't just check they exist (control testing)

A control that exists in config but was never verified is a false sense of security. Concretely: attempt to deploy an unsigned container image and confirm the Part 5 cosign verification step actually refuses it; attempt an authenticated-but-wrong-role API call and confirm the Part 2 guard actually returns 403, not 500 or a silent success; attempt to push a commit containing a fake-but-plausible secret and confirm Part 4's Trufflehog check actually catches it in CI. This is the same principle as chaos engineering, applied to security controls specifically — sometimes called "control validation testing" or informally a "purple team" exercise when done collaboratively between builders and reviewers.

### Step 7 — Run a free, automated external-perspective scan as a cross-check

Use **OWASP ZAP** (free, open-source DAST tool) in automated baseline mode against a staging environment: `docker run -t zaproxy/zap-stable zap-baseline.py -t https://staging.yourapp.com -r zap-report.html` — this exercises the running application from an attacker's black-box perspective, independent of your own code-level review, and is a useful sanity check that your Part 3/4 SAST and input-validation work actually holds up against real HTTP-level probing (missing security headers, exposed debug endpoints, weak session cookie flags are ZAP baseline staples).

### Step 8 — Produce the audit artifact: gaps, owners, and dates — not just findings

The output of this Part should be a living document (a note, a repo file — not a slide deck that gets forgotten) with: the finding, the C4 level and OSA domain it maps to, severity, an assigned owner, and a target remediation date. Re-run this entire Part 8 process on a fixed cadence (quarterly is a reasonable default for a small team) — a security audit that happens once is a snapshot; a security audit that happens on a cadence is a governance practice.

## 3. Exercise Challenge

1. Produce (via Structurizr or even hand-drawn, but derived from actual deployed config) all four C4 levels for your system.
2. Re-run STRIDE at the Context level and identify at least one integration added since your original Part 1 threat model that lacks coverage.
3. Run the Component-level authorization sweep (Semgrep custom rule from Part 3) and record every finding, even ones you fix immediately — the historical record matters.
4. Build the OSA-domain scoring table (0-3 scale) across at least 5 domains and identify your single lowest-scoring domain as your next quarter's priority.
5. Run OWASP ZAP baseline scan against a staging environment and triage every finding.

## 4. Solution & Explanation

Applied to the cumulative example system built across Parts 1-7: the Context-level re-audit surfaces that the Plaid integration (added conceptually during the data-protection work) was never added to `threat-model.json` — a concrete, real gap, remediated by adding a STRIDE entry specifically for the OAuth token exchange with Plaid (Spoofing/Tampering risk) and the bank-data ingestion pipeline (Information Disclosure risk, directly linking back to Part 4's envelope encryption pattern as the required mitigation). The Component-level sweep finds one background job (an Inngest function processing recurring invoices) that queries the database without calling `requireRole`, because background jobs run without an HTTP request context and were never covered by the original guard design — a genuine architectural gap requiring a *new* pattern (a service-identity-based check for background jobs, conceptually extending Part 6's SPIFFE/SPIRE workload-identity approach rather than the request-scoped Part 2 guard) rather than a simple bug fix.

Why this matters architecturally: the most valuable audit findings are not "we forgot to run a scanner" — they're structural gaps like "our authorization model implicitly assumed every code path has an HTTP request context, and background jobs violate that assumption." This is exactly the kind of gap that only surfaces from a systematic, multi-level audit — never from ad hoc code review alone.

## 5. Key Takeaways

- Audit top-down through C4 levels (Context → Container → Component → Code) to catch systemic gaps, not just implementation bugs.
- Re-derive diagrams from actual deployed config, not memory or original design intent — systems drift.
- OSA-pattern scoring (0-3 per domain) turns a vague "is this secure" impression into a comparable, trackable metric across audit cycles.
- Test that controls actually work (attempt to bypass them) — a control that exists only in configuration, never exercised, is not a verified control.
- The audit's output is a living, owned, dated gap list — and the audit itself is a recurring governance practice, not a one-time event.

## Series Closing Note

Across these 8 parts, every decision traced back to the same discipline: identify the threat (Part 1), design the control (Parts 2, 4, 6), automate its enforcement (Parts 3, 5), watch for its failure (Part 7), and periodically verify it's all still true (Part 8). This is "Secure by Design" as a practice, not a slogan — see Appendix A for the pattern library reference, Appendix B for the full open-source toolkit list, and Appendix C for the Incident Response Plan template that operationalizes everything Part 7 designed.
