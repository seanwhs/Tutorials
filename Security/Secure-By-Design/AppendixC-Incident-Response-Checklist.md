# Appendix C: Incident Readiness Checklist — Incident Response Plan (IRP) Template

A ready-to-adapt IRP. Fill in the bracketed fields for your organization. This template assumes the tooling built across Parts 1–7 (centralized logging, structured audit events, STRIDE-mapped alerts) is already in place — an IRP without observability is just a hope, not a plan.

## 0. Plan Metadata

- **Plan owner:** [name/role]
- **Last reviewed:** [date] — review cadence: quarterly, aligned with the Part 8 audit cycle
- **Scope:** [systems/environments covered — e.g., production only, or production + staging]

## 1. Roles & Responsibilities (define before an incident, not during)

| Role | Responsibility | Primary | Backup |
|---|---|---|---|
| Incident Commander | Owns the response, makes go/no-go calls, coordinates communication | [name] | [name] |
| Technical Lead | Drives containment/eradication technical work | [name] | [name] |
| Communications Lead | Handles internal updates, customer notification, regulatory notification | [name] | [name] |
| Scribe | Maintains the incident timeline log in real time | [name] | [name] |

## 2. Severity Classification

| Severity | Definition | Example | Response SLA |
|---|---|---|---|
| SEV-1 (Critical) | Active data breach, or system fully unavailable | Confirmed unauthorized access to customer PII/financial data | Immediate, all-hands, IC engaged within 15 min |
| SEV-2 (High) | Suspected breach, partial outage, or high-confidence attack in progress | Alert fires: authz_check denial spike matching Elevation-of-Privilege pattern (Part 7) | Engaged within 1 hour |
| SEV-3 (Medium) | Isolated vulnerability or anomaly, no evidence of exploitation yet | Trivy/Dependency-Track finds a Critical CVE in a running dependency, no active exploit signal | Engaged within 1 business day |
| SEV-4 (Low) | Hygiene finding, no immediate risk | Semgrep finding on a non-production code path | Normal backlog triage |

## 3. Phase 1 — Detection

- [ ] Alert received via [Grafana Alerting / Wazuh / manual report] — confirm it is not a false positive by cross-referencing the centralized log stream (Part 7).
- [ ] Identify which STRIDE category (Part 1) and which system boundary (Part 8 C4 diagram) the alert maps to.
- [ ] Classify severity (Section 2) and page the Incident Commander accordingly.
- [ ] Open an incident channel/ticket; Scribe begins the timeline log immediately (timestamp every action from this point forward).
- [ ] Preserve evidence: snapshot relevant logs, do NOT restart or redeploy affected systems yet if doing so would destroy forensic evidence (in-memory attacker artifacts, active network connections).

## 4. Phase 2 — Containment

- [ ] **Short-term containment** (stop the bleeding, minimal disruption): revoke the specific compromised credential/token (Part 2's short-lived-token design makes this fast and low-blast-radius), block the offending IP/identity at the WAF or network policy layer (Part 6), or temporarily disable the specific affected feature/endpoint.
- [ ] **Isolate, don't immediately destroy**: if a container/service is suspected compromised, isolate its network access (Part 6 egress-deny) rather than killing it outright, to preserve forensic state for Phase 5.
- [ ] **Long-term containment** (once immediate risk is stopped): rotate all potentially-exposed secrets (Part 4), force-invalidate all active sessions for affected accounts, patch/redeploy from a known-good, signed image (Part 5's cosign verification ensures you're redeploying something provably clean).
- [ ] Confirm containment is effective: re-check the alert condition from Phase 1 has stopped firing.

## 5. Phase 3 — Eradication

- [ ] Identify root cause: which control failed, and why? (Trace back through the specific Part 1–7 layer that should have prevented this — was it missing, misconfigured, or bypassed?)
- [ ] Remove the root cause: patch the vulnerable code (verify with a fresh Semgrep/Trivy scan, Part 3/5), fix the misconfiguration (verify with Checkov/tfsec, Part 5), close the gap in the authorization model (Part 2).
- [ ] Verify no persistence mechanism remains (unexpected scheduled jobs, unexpected new credentials/API keys, unexpected new admin accounts — check the Part 7 audit trail for any admin_action events during the incident window).

## 6. Phase 4 — Recovery

- [ ] Restore affected systems from known-clean, signed artifacts (Part 5).
- [ ] Gradually restore traffic/access, monitoring closely for recurrence (heightened alerting sensitivity for 48-72 hours post-incident).
- [ ] Confirm with the Technical Lead and Incident Commander that the system is fully operational and the specific threat is confirmed eradicated before declaring the incident closed.

## 7. Phase 5 — Notification (legal/compliance — customize per jurisdiction)

- [ ] Determine notification obligations: does this incident involve personal data, payment data, or health data triggering GDPR/CCPA/PCI-DSS/HIPAA notification requirements? [Consult legal counsel — timelines are often as short as 72 hours from discovery under GDPR.]
- [ ] Notify affected customers/users per your jurisdiction's requirements and your own trust commitments — be specific about what data was affected, what wasn't, and what actions users should take.
- [ ] Notify relevant regulators if required.
- [ ] Prepare an internal stakeholder summary (leadership, board if applicable) distinct from the external customer communication.
- [ ] If applicable, notify any third-party processors/vendors whose data or systems were involved.

## 8. Phase 6 — Post-Incident Review (Blameless Postmortem)

- [ ] Conduct within 5 business days of resolution, while details are fresh.
- [ ] Build a full timeline from the Scribe's log plus the centralized audit trail (Part 7) — cross-reference to ensure completeness.
- [ ] Identify: what detected this (or why detection was slow), what contained it, what the root cause was, and — critically — which specific Part 1-8 control should be added or strengthened to prevent recurrence.
- [ ] Feed every finding back into: the Part 1 threat model (`threat-model.json` update), the Part 3 Semgrep custom rule set (if a code pattern was the root cause), the Part 7 alerting rules (if detection was slow, what new rule would have caught it sooner), and the Part 8 OSA-domain scoring table.
- [ ] Assign owners and dates to every remediation action — track to completion, don't let the postmortem doc become the final artifact with no follow-through.
- [ ] Explicitly blameless: the review's output is "which control was missing or weak," never "who made a mistake" — psychological safety here is what makes people report near-misses *before* they become incidents.

## 9. Pre-Built Contact & Escalation Sheet (fill in and keep accessible outside of any system that might itself be affected — e.g., a printed card or an out-of-band messaging channel)

| Contact | Role | Method | When to engage |
|---|---|---|---|
| [name] | Incident Commander | [phone/backup channel] | SEV-1/SEV-2 immediately |
| [name] | Legal counsel | [contact] | Any suspected data breach |
| [name/vendor] | Cloud/infra provider support | [contact] | Infrastructure-level incidents |
| [name] | External PR/comms (if applicable) | [contact] | Customer-facing incidents |

## 10. Tabletop Exercise Schedule

Run a tabletop exercise (a walkthrough simulation, not a live-fire test) against this plan at least twice a year, rotating scenarios across STRIDE categories — e.g., one exercise simulates a leaked credential (Spoofing/Tampering), another simulates a data-exfiltration alert (Information Disclosure) — to ensure every role knows their responsibilities before a real incident, and to surface gaps in this document itself (an IRP that's never been rehearsed will have gaps you won't find until it's too late to matter).

## Closing Principle

This checklist is only as good as the observability built in Part 7 and the governance discipline built in Part 8. An Incident Response Plan is not a document you write once and file away — it is a living artifact, rehearsed, updated after every real incident and every tabletop exercise, and directly wired back into the same threat model, code rules, and alerting logic that the rest of this series builds. That feedback loop — breach or near-miss informs design, design informs automated enforcement, enforcement informs monitoring, monitoring informs the next audit — is the complete practice of Secure by Design.
