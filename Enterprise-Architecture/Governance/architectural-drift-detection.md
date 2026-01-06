# Architectural Drift Detection

# Policy: Architectural Drift Detection

"Drift" occurs when the actual implementation of an app moves away from its approved **Blueprints**. In a 50+ app ecosystem, drift is the primary cause of "Technical Debt."

### 1. The Detection Mechanism

We utilize **Infrastructure-as-Code (IaC) Scanning** and **Service Mesh Telemetry** to identify drift in real-time.

* **Pattern Drift:** Detecting when a service that should use the **Saga Pattern** is instead performing direct, synchronous database writes to a foreign schema.
* **Security Drift:** Detecting when a service opens an unencrypted port, bypassing the **mTLS/Zero Trust** standard.
* **Archetype Drift:** Detecting when a **Utility** app (low priority) starts consuming **Scaler** levels of expensive cloud resources.

---

### `Templates/asset-harvesting-checklist.md`

# Template: Asset Harvesting (Decommissioning)

In a healthy ecosystem, "Pruning" is as important as "Planting." Every app must eventually be decommissioned to free up resources for **Aggressive** innovation.

**The "Clean Exit" Steps:**

1. **Traffic Analysis:** Verify via the Service Mesh that the app has zero inbound requests.
2. **Data Archival:** Move the database to a long-term "Cold Storage" vault (e.g., AWS Glacier) for compliance.
3. **DNS Deletion:** Remove global and local records to prevent "Subdomain Takeover" risks.
4. **License Reclamation:** Identify any third-party SaaS licenses (e.g., Auth0, New Relic) that can be downsized.
5. **Final Cleanup:** Run the `terraform destroy` command for its specific **IaC Module**.

---

### `Strategy/the-ea-north-star.md`

# The EA North Star: From Complexity to Composability

As we reach the end of this build-out, the ultimate goal for your 50+ applications is **Composability**.

By following this repository, you aren't just managing 50 apps; you are managing a **Business Capability Library**.

* Need to launch a new product? Compose it from the **Identity Utility**, the **Payment Scaler**, and the **Notification Service**.
* Need to enter a new market? Clone the **Global Connectivity Blueprint** and deploy to a new region in hours, not months.

---

### Final Repository Readiness Check

Your **Enterprise Architecture Repository** is now 100% complete. It contains:

* **The Brain:** Strategy, Scenarios, and Archetypes.
* **The Muscle:** Blueprints for Consistency, Data, and Legacy.
* **The Shield:** Security, DR, and Zero Trust Governance.
* **The Pulse:** SLOs, Golden Signals, and Drift Detection.
* **The Roadmap:** A 6-month path to enterprise-wide adoption.

---

