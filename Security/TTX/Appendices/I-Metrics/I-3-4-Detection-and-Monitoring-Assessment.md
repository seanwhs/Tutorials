# Appendix I.3.4 — Detection & Monitoring Assessment Workbook

> *"You cannot respond to what you cannot see."*

---

# Purpose

Cyber resilience depends on timely and reliable detection.

Modern enterprises generate billions of security-relevant events every day, but only a tiny fraction represent genuine threats. Mature organizations distinguish signal from noise through disciplined monitoring, well-engineered detection capabilities, contextual threat intelligence, and effective operational processes.

This workbook evaluates whether the organization can:

* Detect malicious activity rapidly.
* Maintain visibility across enterprise environments.
* Prioritize high-confidence alerts.
* Support rapid investigation.
* Continuously improve detection effectiveness.

---

# Assessment Scope

This workbook evaluates:

* Security monitoring strategy.
* Security Operations Center (SOC) maturity.
* Log management.
* Detection engineering.
* Threat intelligence integration.
* Endpoint detection.
* Network visibility.
* Cloud monitoring.
* AI-assisted detection.
* Detection governance and continuous improvement.

---

# Capability Objectives

A mature detection capability ensures that:

✓ Critical business services are continuously monitored.

✓ Security-relevant telemetry is collected, retained, and protected.

✓ High-risk attack techniques are reliably detected.

✓ Detection content evolves with the threat landscape.

✓ Analysts can investigate alerts efficiently.

✓ Detection performance is measured and improved.

---

# Capability Areas

| Section | Capability                           |
| ------- | ------------------------------------ |
| D1      | Monitoring Strategy & Governance     |
| D2      | Security Operations Center (SOC)     |
| D3      | Log & Telemetry Management           |
| D4      | Detection Engineering                |
| D5      | Threat Intelligence Integration      |
| D6      | Endpoint, Network & Cloud Visibility |
| D7      | Investigation & Threat Hunting       |
| D8      | Detection Performance & Metrics      |
| D9      | Detection Resilience                 |
| D10     | Continuous Detection Improvement     |

---

# D1 — Monitoring Strategy & Governance

## Objective

Determine whether monitoring activities support business priorities and enterprise risk.

### Assessment Questions

| #     | Assessment Question                                                     | Score |
| ----- | ----------------------------------------------------------------------- | :---: |
| D1.1  | A documented enterprise monitoring strategy exists.                     |       |
| D1.2  | Monitoring priorities align with critical business services.            |       |
| D1.3  | Roles and responsibilities are formally defined.                        |       |
| D1.4  | Monitoring requirements are reviewed annually.                          |       |
| D1.5  | Security monitoring is integrated into enterprise architecture reviews. |       |
| D1.6  | Monitoring standards are consistently applied across business units.    |       |
| D1.7  | Executive leadership reviews monitoring performance.                    |       |
| D1.8  | Monitoring scope includes cloud, on-premises, and remote environments.  |       |
| D1.9  | Monitoring exceptions require documented approval.                      |       |
| D1.10 | Governance effectiveness is periodically assessed.                      |       |

### Evidence Checklist

* Monitoring strategy.
* SOC charter.
* Architecture standards.
* Governance committee minutes.
* Monitoring policies.
* Internal audit reports.

### Common Weaknesses

* Monitoring focused only on infrastructure.
* Limited visibility into cloud services.
* Undefined ownership.
* Inconsistent logging standards.

---

# D2 — Security Operations Center (SOC)

## Objective

Assess operational maturity of the SOC.

### Assessment Areas

Evaluate:

* Staffing model.
* Operating hours.
* Escalation procedures.
* Case management.
* Incident triage.
* Knowledge management.
* Analyst training.

### Sample Questions

| Question                                        | Score |
| ----------------------------------------------- | :---: |
| SOC roles are clearly defined.                  |       |
| Escalation procedures are documented.           |       |
| Analysts receive continuous training.           |       |
| Case management is standardized.                |       |
| Lessons learned improve operational procedures. |       |

### Maturity Indicators

**Level 1:** Reactive monitoring with limited staffing.

**Level 3:** Formal SOC processes with defined escalation.

**Level 5:** Intelligence-driven SOC using automation, orchestration, and continuous optimization.

---

# D3 — Log & Telemetry Management

## Objective

Determine whether telemetry supports effective detection and investigation.

### Assessment Areas

* Endpoint logs.
* Network telemetry.
* Cloud audit logs.
* Identity logs.
* SaaS monitoring.
* OT telemetry (where applicable).
* Time synchronization.
* Log integrity.
* Retention policies.

### Evidence Examples

* Logging standards.
* SIEM ingestion reports.
* Retention policies.
* Audit configurations.

### Common Weaknesses

* Critical systems not logging.
* Short retention periods.
* Unsynchronized timestamps.
* Excessive noise reducing analyst effectiveness.

---

# D4 — Detection Engineering

## Objective

Assess the organization's ability to design, validate, and maintain detection logic.

### Assessment Areas

Evaluate:

* Detection use cases.
* ATT&CK technique coverage.
* Rule lifecycle management.
* Detection tuning.
* False positive reduction.
* Detection validation.
* Purple team feedback.

### Sample Questions

| Question                                                   | Score |
| ---------------------------------------------------------- | :---: |
| Detection rules follow documented engineering practices.   |       |
| High-risk attack techniques are mapped to detection rules. |       |
| Detection logic is periodically reviewed.                  |       |
| False positives are measured and reduced.                  |       |
| Detection content is tested before deployment.             |       |

---

# D5 — Threat Intelligence Integration

## Objective

Evaluate whether threat intelligence improves detection quality.

### Assessment Areas

* Strategic intelligence.
* Operational intelligence.
* Tactical indicators.
* Intelligence sharing.
* Sector-specific threats.
* Intelligence-driven detection updates.

### Evidence

* Intelligence reports.
* Threat briefings.
* Detection updates linked to intelligence.

---

# D6 — Endpoint, Network & Cloud Visibility

## Objective

Assess monitoring coverage across enterprise technology.

### Assessment Areas

* Endpoint Detection and Response (EDR).
* Network Detection and Response (NDR).
* Cloud-native monitoring.
* Identity monitoring.
* SaaS visibility.
* Container and Kubernetes monitoring.
* OT monitoring (where applicable).

### Sample Questions

| Question                                               | Score |
| ------------------------------------------------------ | :---: |
| EDR coverage includes all critical endpoints.          |       |
| Cloud audit logging is enabled for critical workloads. |       |
| Identity events are centrally monitored.               |       |
| Network visibility supports incident investigations.   |       |
| Monitoring coverage is periodically validated.         |       |

---

# D7 — Investigation & Threat Hunting

## Objective

Evaluate proactive security operations.

### Assessment Areas

Assess:

* Threat hunting program.
* Investigation playbooks.
* Digital forensics capability.
* Root cause analysis.
* Cross-functional investigations.

### Maturity Indicators

**Level 1:** Alert-driven investigations only.

**Level 3:** Scheduled threat hunting informed by intelligence.

**Level 5:** Continuous hypothesis-driven hunting supported by automation and analytics.

---

# D8 — Detection Performance & Metrics

## Objective

Measure detection effectiveness.

### Recommended Metrics

* Mean Time to Detect (MTTD).
* Detection coverage of critical attack techniques.
* False positive rate.
* True positive rate.
* Analyst workload.
* Investigation time.
* Detection rule maintenance frequency.

### Executive Metrics

| Metric                         | Current | Target | Trend |
| ------------------------------ | ------: | -----: | :---: |
| MTTD                           |         |        |       |
| False Positive Rate            |         |        |       |
| High-Severity Alert Validation |         |        |       |
| Detection Coverage             |         |        |       |

---

# D9 — Detection Resilience

## Objective

Determine whether monitoring capabilities remain effective during adverse conditions.

### Assessment Areas

Evaluate:

* SIEM availability.
* Log redundancy.
* Secure log storage.
* Monitoring continuity during outages.
* Backup monitoring capabilities.
* Integrity of telemetry.

---

# D10 — Continuous Detection Improvement

## Objective

Assess whether monitoring capabilities evolve based on experience.

### Assessment Areas

* Incident lessons learned.
* Exercise outcomes.
* Red team feedback.
* Purple team validation.
* Emerging threats.
* Technology modernization.

### Improvement Questions

| Question                                                                  | Score |
| ------------------------------------------------------------------------- | :---: |
| Detection rules are updated after incidents.                              |       |
| Threat hunting results improve monitoring content.                        |       |
| Exercises identify monitoring improvements.                               |       |
| Detection metrics drive investment decisions.                             |       |
| New technologies receive updated monitoring before production deployment. |       |

---

# Domain Scoring Worksheet

| Capability Area                      | Score |
| ------------------------------------ | ----: |
| Monitoring Strategy & Governance     |       |
| Security Operations Center           |       |
| Log & Telemetry Management           |       |
| Detection Engineering                |       |
| Threat Intelligence Integration      |       |
| Endpoint, Network & Cloud Visibility |       |
| Investigation & Threat Hunting       |       |
| Detection Performance & Metrics      |       |
| Detection Resilience                 |       |
| Continuous Detection Improvement     |       |

**Overall Detection & Monitoring Score:** ______ / 5

---

# Executive Interpretation

|   Score | Maturity Level | Interpretation                                                                                                                |
| ------: | -------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| 0.0–0.9 | Initial        | Monitoring is fragmented, reactive, and provides limited visibility.                                                          |
| 1.0–1.9 | Developing     | Core monitoring exists but lacks consistency and enterprise coverage.                                                         |
| 2.0–2.9 | Defined        | Standardized monitoring supports most critical business services.                                                             |
| 3.0–3.9 | Managed        | Detection capabilities are measured, tuned, and integrated with risk management.                                              |
| 4.0–5.0 | Adaptive       | Detection is intelligence-driven, continuously optimized, resilient, and aligned with enterprise cyber resilience objectives. |

---

# Executive Reporting Metrics

Recommended quarterly reporting:

| KPI                            | Description                                                        |
| ------------------------------ | ------------------------------------------------------------------ |
| Mean Time to Detect (MTTD)     | Average time from malicious activity to detection.                 |
| Detection Coverage             | Percentage of critical systems and attack techniques monitored.    |
| False Positive Rate            | Percentage of alerts determined to be benign.                      |
| Threat Hunting Effectiveness   | Number of validated findings from proactive hunts.                 |
| Detection Engineering Velocity | Number of new or improved detection rules deployed.                |
| Monitoring Availability        | Availability of core monitoring platforms and telemetry pipelines. |

---

# Improvement Planning Worksheet

| Priority | Improvement Action | Business Justification | Owner | Target Date | Status |
| -------- | ------------------ | ---------------------- | ----- | ----------- | ------ |
| High     |                    |                        |       |             |        |
| Medium   |                    |                        |       |             |        |
| Low      |                    |                        |       |             |        |

---

# Assessor Notes

Document:

* Significant visibility gaps.
* Detection engineering weaknesses.
* High-risk systems lacking monitoring.
* Intelligence integration opportunities.
* Executive investment priorities.
* Recommended roadmap initiatives.

These observations should be integrated into the enterprise cyber resilience improvement plan and reviewed during subsequent maturity assessments.

---

# End of Appendix I.3.4

## Next Workbook

**Appendix I.3.5 — Incident Response Assessment Workbook**

This workbook evaluates the organization's ability to prepare for, coordinate, contain, eradicate, recover from, and learn from cyber incidents. It will cover incident command, technical response, executive crisis management, communications, legal coordination, digital forensics, post-incident learning, and resilience metrics, making it one of the largest and most operationally significant workbooks in the assessment framework.
