---

title: Appendix G
section: G.3
subtitle: Threat Intelligence Package
description: Executive cyber threat intelligence assessment supporting Operation Red Horizon.
classification: TLP:CLEAR (Exercise Use Only)
---

# G.3 Threat Intelligence Package

> *"Threat intelligence is not about predicting the future—it is about reducing uncertainty so that organizations can make better decisions."*

---

# Purpose of this Intelligence Package

Effective tabletop exercises are grounded in realistic threat intelligence rather than fictional Hollywood-style attacks.

The objective of this intelligence package is to provide the business and technical context that explains **why** ACME Manufacturing Group has become a target, **how** a threat actor is likely to operate, and **which organizational capabilities will be exercised** during Operation Red Horizon.

The information presented here is intentionally representative rather than tied to a specific real-world threat group. It reflects tactics, techniques, and procedures (TTPs) commonly observed in financially motivated ransomware campaigns targeting manufacturing organizations and critical supply chains.

Participants are not expected to memorize technical indicators. Instead, they should understand the broader operational patterns that inform defensive decision-making throughout the exercise.

---

# Executive Summary

Recent threat intelligence indicates a sustained increase in attacks against manufacturing organizations worldwide.

Rather than exploiting sophisticated zero-day vulnerabilities, many successful intrusions begin by abusing trusted relationships, compromised credentials, unmanaged remote access pathways, or weaknesses within third-party service providers.

Manufacturing organizations remain attractive targets because they often prioritize operational continuity over prolonged system outages. Threat actors understand that production downtime creates immediate commercial pressure, increasing the likelihood that victims will prioritize rapid recovery over extended forensic investigations.

Operation Red Horizon simulates one such campaign, beginning with the compromise of a trusted vendor account before progressing through reconnaissance, privilege escalation, lateral movement, data theft, and ransomware deployment.

---

# Threat Landscape

The manufacturing sector faces a diverse range of cyber threats.

Common adversaries include:

* Financially motivated ransomware groups.
* Organized cybercrime syndicates.
* Industrial espionage actors.
* Supply chain attackers.
* Insider threats.
* Opportunistic credential theft campaigns.

While each group differs in motivation and capability, many employ similar techniques during the early stages of an intrusion.

---

# Why Manufacturing?

Several characteristics make manufacturing organizations particularly attractive targets.

## Operational Pressure

Production interruptions quickly translate into financial losses, missed contractual obligations, and supply chain disruption.

---

## Valuable Intellectual Property

Engineering designs, manufacturing processes, and research data represent years of investment and significant competitive advantage.

---

## Complex Supply Chains

Manufacturers depend on numerous suppliers, contractors, logistics providers, and equipment vendors.

Each trusted relationship introduces additional attack surface.

---

## Operational Technology

Manufacturing environments frequently combine modern digital systems with legacy industrial equipment, creating complex security challenges and constrained maintenance windows.

---

## Global Operations

Multiple jurisdictions increase legal complexity, regulatory obligations, and coordination challenges during significant incidents.

---

# Adversary Objectives

The threat actor represented in this exercise seeks to achieve several objectives.

Primary objectives include:

* Obtain privileged access.
* Expand operational control.
* Steal commercially valuable information.
* Disrupt manufacturing operations.
* Maximize financial leverage through ransomware.
* Pressure executive leadership into rapid decision-making.

The exercise assumes that financial gain—not political or ideological objectives—is the primary motivation.

---

# Campaign Overview

The simulated campaign unfolds over multiple phases.

| Phase                | Objective                                         |
| -------------------- | ------------------------------------------------- |
| Initial Access       | Compromise trusted vendor credentials             |
| Establish Foothold   | Maintain authenticated access                     |
| Discovery            | Identify valuable systems and privileged accounts |
| Privilege Escalation | Increase operational control                      |
| Lateral Movement     | Expand access across enterprise systems           |
| Collection           | Identify and stage sensitive information          |
| Exfiltration         | Transfer selected data outside the organization   |
| Impact               | Deploy ransomware against prioritized systems     |

Participants enter the scenario after the initial compromise has already occurred.

Their challenge is to determine the scope of the incident before irreversible business impact develops.

---

# Initial Access Assessment

The exercise assumes that a trusted third-party maintenance provider has experienced a credential compromise.

The affected account possesses legitimate remote access privileges used for scheduled maintenance activities.

Because authentication appears valid, early malicious activity initially resembles normal administrative behavior.

This ambiguity creates the first major decision point for participants:

**Is the activity legitimate maintenance, or evidence of compromise?**

---

# Likely Adversary Behaviour

Threat intelligence suggests the attacker is likely to:

* Blend into legitimate administrative activity.
* Avoid noisy malware during early stages.
* Reuse valid credentials wherever possible.
* Perform extensive internal reconnaissance.
* Escalate privileges gradually.
* Delay disruptive actions until sufficient access has been established.

These behaviours intentionally challenge defenders who rely solely on signature-based detection.

---

# Expected Indicators

Participants may encounter indicators such as:

Identity anomalies:

* Impossible travel.
* Unusual login times.
* New device registrations.
* Multiple authentication failures.
* Unexpected privilege requests.

Endpoint activity:

* Administrative tools executed outside normal maintenance windows.
* Suspicious PowerShell usage.
* Credential dumping attempts.
* Security tool tampering.

Network activity:

* Internal network scanning.
* Service enumeration.
* SMB connections between unrelated systems.
* Remote administration activity.

Cloud activity:

* Unusual administrative actions.
* Unexpected application registrations.
* Elevated permissions.
* Large data transfers.

Each indicator is individually explainable.

Only through correlation do they reveal the broader attack.

---

# Defensive Challenges

Operation Red Horizon deliberately introduces ambiguity.

Participants must decide:

* When does suspicious become malicious?
* How much evidence is required before containment?
* When should executives be informed?
* Should production systems be isolated?
* What operational risk is acceptable?

These questions rarely have perfect answers.

The exercise is designed to explore decision-making under uncertainty rather than technical perfection.

---

# Intelligence Gaps

As with any real incident, participants begin with incomplete information.

Unknowns include:

* Whether credentials have been stolen.
* The extent of lateral movement.
* Whether data exfiltration has occurred.
* Which systems are compromised.
* Whether ransomware deployment is imminent.
* Whether additional threat actors are involved.

The White Cell gradually reveals information as participants investigate.

---

# Intelligence Assumptions

For the purpose of the exercise, the following assumptions apply.

* The threat actor is patient and disciplined.
* Initial compromise predates detection.
* Multiple systems may already be affected.
* Not every alert represents malicious activity.
* Some information received during the exercise may be incomplete or contradictory.

These assumptions encourage participants to validate evidence before making high-impact operational decisions.

---

# Mapping to the MITRE ATT&CK Framework

The scenario incorporates behaviours aligned with common ATT&CK tactics.

| ATT&CK Tactic        | Exercise Theme                 |
| -------------------- | ------------------------------ |
| Initial Access       | Trusted vendor credentials     |
| Execution            | Administrative tooling         |
| Persistence          | Continued authenticated access |
| Privilege Escalation | Identity abuse                 |
| Discovery            | Internal reconnaissance        |
| Lateral Movement     | Remote administration          |
| Collection           | Sensitive business information |
| Exfiltration         | Data staging and transfer      |
| Impact               | Ransomware deployment          |

The focus is not on memorizing ATT&CK technique identifiers but on recognizing behavioural patterns that support effective incident response.

---

# Intelligence Priorities for Participants

As the exercise unfolds, participants should continually seek answers to five critical questions:

1. What do we know with confidence?
2. What assumptions are we making?
3. Which business services are currently at risk?
4. What decisions cannot wait?
5. What additional information do we need before escalating our response?

These questions provide a consistent framework for evaluating evidence throughout the exercise.

---

# Success Criteria

The intelligence package has achieved its purpose if participants:

* Recognize that trusted relationships can become attack vectors.
* Appreciate the importance of correlating weak signals rather than relying on isolated alerts.
* Balance technical investigation with business risk.
* Understand the relationship between threat intelligence and executive decision-making.
* Use evolving intelligence to inform proportionate response actions.

---

# Transition to the Next Section

The threat landscape is now understood.

The organization is known.

The critical business services have been identified.

The adversary's objectives and likely behaviours have been established.

The next step is to translate this intelligence into a structured threat model that identifies the organization's most significant attack paths, trust boundaries, defensive assumptions, and business risks.

This threat model becomes the analytical foundation upon which the Operation Red Horizon scenario is built.
