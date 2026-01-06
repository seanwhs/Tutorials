# Enterprise Data Strategy

In a landscape of **50+ applications**, data is the most valuable—and most dangerous—asset. Without a strategy, the enterprise becomes a "Data Swamp" of duplicated, stale, and conflicting information. This strategy defines how we maintain a **Single Source of Truth** while allowing for distributed innovation.

---

## 1. Source of Truth (SoT) Philosophy

Every data element (e.g., *Customer Email*, *Product Price*) must have exactly **one** authoritative owner.

* **Producer Responsibility:** The service that owns the data is responsible for its quality, validation, and distribution.
* **Consumer Policy:** All other 49+ apps must consume this data via API or Event Stream. They may cache it for performance, but they must never treat their local copy as the master.

---

## 2. Global vs. Local Data (Cell-Based Strategy)

To align with the **Defensive Strategic Scenario** (Compliance) and the **Scaler Archetype** (Performance), we categorize data by its "Gravity":

* **Local (Regional) Data:** PII, Transactions, and User Preferences. These are stored in regional "Cells" to comply with data sovereignty laws (GDPR/CCPA).
* **Global Reference Data:** Product Catalogs, Currency Rates, and Internal Taxonomy. This is replicated across all regions for low-latency access.

---

## 3. The Data Mesh Approach

We move away from a single, monolithic Data Warehouse. Instead, we treat **Data as a Product**.

* **Domain Ownership:** The "Payments" team doesn't just provide an API; they provide a "Data Product" (a curated, cleaned dataset) for the rest of the enterprise to analyze.
* **Self-Serve Platform:** The infrastructure team provides the "Data Lake" and "Query Engine," but the individual app teams are responsible for the data they put into it.

---

## 4. Operational vs. Analytical Data

We strictly decouple the databases used for running the business from the databases used for analyzing the business.

* **Operational (OLTP):** Optimized for high-speed writes and consistent transactions (e.g., Postgres, MySQL).
* **Analytical (OLAP):** Optimized for complex queries and massive scale (e.g., Snowflake, BigQuery).
* **The Bridge:** We use **CDC (Change Data Capture)** to stream updates from OLTP to OLAP in real-time, ensuring analysts work with fresh data without slowing down production apps.

---

## 5. EA Lifecycle Alignment

| Phase | Data Strategy Responsibility |
| --- | --- |
| **Strategic Planning** | Classify data sensitivity (Public, Internal, Confidential, Restricted). |
| **Initiative Delivery** | Define the "Schema" and "Data Contract." Implement the **Outbox Pattern** for data propagation. |
| **Asset Management** | Monitor data quality and "Freshness" metrics. Ensure backup and purge policies are active. |
| **Asset Harvesting** | Execute the "Final Archive." Securely wipe PII while retaining anonymized data for long-term trends. |

---

### Recommended Standard

**The Data Contract**
Before one app consumes data from another, they must agree on a "Data Contract" (Protobuf, Avro, or JSON Schema) that is versioned and governed just like an API.

---

