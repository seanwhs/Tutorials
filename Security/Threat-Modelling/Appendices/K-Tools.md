# Appendix K – Threat Modeling Tools & Platform Comparison Guide

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix K**
>
> **Purpose:** This appendix provides a comprehensive comparison of the most widely used **threat modeling tools**, including commercial and open-source solutions. It explains when to use each tool, its strengths, limitations, integration capabilities, and suitability for different organizational sizes and maturity levels.
>
> **Audience:** Security Architects, Enterprise Architects, Application Architects, DevSecOps Engineers, Security Consultants, Security Champions, Software Development Teams, and CISOs.

---

# Table of Contents

1. Why Threat Modeling Tools Matter
2. Categories of Threat Modeling Tools
3. Selecting the Right Tool
4. Microsoft Threat Modeling Tool
5. OWASP Threat Dragon
6. IriusRisk
7. ThreatModeler
8. PyTM
9. Threagile
10. CAIRIS
11. Enterprise Architecture Tools
12. Diagramming Tools
13. Comparison Matrix
14. Integration with DevSecOps
15. Recommended Tool Selection by Organization Size
16. Tool Evaluation Checklist
17. Future Trends
18. Quick Reference Guide

---

# 1. Why Threat Modeling Tools Matter

Threat modeling can be performed using whiteboards and spreadsheets, but dedicated tools provide significant advantages:

### Benefits

* Standardized methodology
* Consistent documentation
* Automated threat generation
* Threat libraries
* Risk tracking
* Collaboration
* Version control
* Reporting
* Integration with CI/CD
* Traceability
* Governance support

### Manual vs Automated

| Manual Approach       | Tool-Assisted Approach   |
| --------------------- | ------------------------ |
| Whiteboards           | Interactive diagrams     |
| Excel spreadsheets    | Threat databases         |
| Static documentation  | Dynamic models           |
| Manual reviews        | Automated analysis       |
| Limited collaboration | Multi-user collaboration |

---

# 2. Categories of Threat Modeling Tools

Threat modeling tools generally fall into six categories.

## 1. Diagram-Based Tools

Focus on visualizing systems and manually identifying threats.

Examples:

* Microsoft Threat Modeling Tool
* OWASP Threat Dragon

---

## 2. Risk-Centric Platforms

Focus on governance, compliance, and enterprise risk.

Examples:

* ThreatModeler
* IriusRisk

---

## 3. Infrastructure-as-Code (IaC) Threat Modeling

Automatically analyze cloud infrastructure definitions.

Examples:

* Threagile
* PyTM

---

## 4. Enterprise Architecture Platforms

Integrate threat modeling into enterprise architecture repositories.

Examples:

* Sparx Enterprise Architect
* Archi
* LeanIX
* Bizzdesign

---

## 5. DevSecOps Automation

Embed threat modeling into CI/CD pipelines.

Examples:

* Threagile
* PyTM
* IriusRisk APIs
* ThreatModeler integrations

---

## 6. Documentation & Collaboration

Support workshops and collaborative modeling.

Examples:

* Microsoft Visio
* Draw.io (diagrams.net)
* Lucidchart
* Miro

---

# 3. Selecting the Right Tool

When evaluating a threat modeling solution, consider:

### Functional Requirements

* Supports STRIDE?
* Supports custom methodologies?
*
