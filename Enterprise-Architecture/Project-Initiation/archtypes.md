# Guide: Strategic Archetypes & Architectural Rigor

Not every service requires the same level of complexity. We align our technical patterns with the organization's strategic posture.

## 1. The Defensive Archetype (Operational Efficiency)
* **Goal:** Reduce costs and improve productivity.
* **Focus:** Consolidation, standardization, and removing "Snowflakes."
* **Tech Strategy:** Mandatory adherence to the **Golden Path**. Use centralized DBs where appropriate to reduce overhead.

## 2. The Aggressive Archetype (Market Penetration)
* **Goal:** Increase revenue in existing markets.
* **Focus:** Speed to market and scalability.
* **Tech Strategy:** Event-Driven Architecture (EDA) to allow rapid feature additions without core system rewrites.

## 3. The Proactive Archetype (Product Development)
* **Goal:** Creating new products for existing or new markets.
* **Focus:** Flexibility and experimentation.
* **Tech Strategy:** **Cell-Based Architecture**. Isolate new experiments so failure does not impact the core "Defensive" revenue streams.

## 4. The Futurity Archetype (Diversification)
* **Goal:** Long-term survival and industry shifts.
* **Focus:** High abstraction and multi-cloud/multi-region presence.
* **Tech Strategy:** Advanced **Service Mesh** and **Policy as Code** (OPA) to allow the business to pivot its security and traffic rules globally in minutes.
