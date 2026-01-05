# Guide: The Enterprise Architecture Lifecycle

Scaling beyond 50 applications requires a move from "Project Thinking" to "Lifecycle Thinking." This guide outlines the four phases of the EA Practice.

## Phase 1: Strategic Alignment (The "Why")
Before code is written, architecture must align with business intent. 
* **Focus:** Identifying if the initiative is **Defensive** (Efficiency), **Aggressive** (Growth), or **Proactive** (Innovation).
* **Action:** Map the business case to the "Golden Path" to determine if existing platforms can support the goal.

## Phase 2: Initiative Delivery (The "What")
Architecture acts as the bridge between business leaders and project teams.
* **Initiation:** Develop **Solution Overviews** and **Options Assessments** (e.g., Buy vs. Build).
* **Implementation:** Translate outlines into **Solution Designs** using established Blueprints (Saga, Outbox).

## Phase 3: Governance & Enablement (The "How")
Moving from "Gatekeeper" to "Enabler."
* **The TDA (Technical Design Authority):** Peer reviews that focus on **Friction Removal**. If a standard causes friction without adding value, the standard must be refactored.
* **ADR Harvesting:** Capturing unique project decisions and promoting them to global standards.

## Phase 4: Asset Modernization (The "Legacy")
Managing the "Snowflake" inventory.
* **Audit:** Continuous identification of services outside the Golden Path.
* **Sunset:** Defining the decommissioning path for legacy systems to reduce the "Maintenance Tax."
