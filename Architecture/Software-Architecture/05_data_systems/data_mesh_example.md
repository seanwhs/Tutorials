# 05 — Data Systems: Implementation & Data Mesh

Modern data systems face the **"Data Swamp"** problem: centralized data lakes become bottlenecks and often produce low-quality, stale, or untrustworthy data. **Data Mesh** solves this by applying **microservice principles to analytical data**, making data a first-class product.

---

## 🏗️ The Four Pillars of Data Mesh

1. **Domain-Oriented Ownership**
   Each domain team owns its data products:
   *Shipping Team → Shipping Data* | *Billing Team → Billing Data*
   Teams are **subject-matter experts**, responsible for quality, evolution, and accountability.

2. **Data as a Product**
   Data is not a byproduct—it is a product with:

* Service Level Objectives (SLOs)
* Versioning & Documentation
* Clear machine-readable contracts

3. **Self-Serve Data Platform**
   A central team provides infrastructure (Kafka, BigQuery, Snowflake) so domain teams can **publish and consume data without managing servers**.

4. **Federated Governance**
   Central policies (e.g., "Mask all PII") are **automatically enforced** in every domain pipeline through **policy-as-code**.

---

## 🛠️ Implementation: From Theory to Code

To operationalize a Data Mesh, we move from **PDFs and spreadsheets** to **machine-readable contracts** and **policy-as-code enforcement**.

### 1. Define a Data Product Contract (YAML)

```yaml
# finance-product-contract.yaml
dataset: monthly_ledger
version: 1.2.0
owner: finance-team@company.com
schema:
  - name: transaction_id
    type: string
    description: "Unique GUID for the transaction"
  - name: amount
    type: decimal
    description: "Value in USD"
quality_rules:
  - column: amount
    rule: not_null
  - column: transaction_id
    rule: unique
service_levels:
  latency: 15m
  freshness: 24h
```

*💡 The contract serves as the “API specification” for your data product.*

---

### 2. Publish Data via the Sidecar (SDK Adapter)

The SDK ensures **contract compliance, masking, and publication** by intercepting the data flow.

```typescript
import { DataMeshSDK } from '@platform/mesh-sdk';

const financeMesh = new DataMeshSDK({
  domain: 'finance',
  contract: './finance-product-contract.yaml'
});

async function publishLedger(data: any[]) {
  // 1. Validate data against contract and mask PII
  const validatedData = await financeMesh.validateAndMask(data);

  // 2. Publish to shared catalog/platform
  await financeMesh.publishToCatalog({
    stream: 'monthly_ledger',
    payload: validatedData
  });
}
```

---

### 3. Federated Governance (Policy-as-Code)

Policies are **automatically enforced** using OPA or similar tools, preventing **non-compliant data** from entering the mesh.

```rego
# policy/data_privacy.rego
package data_mesh.governance

default allow_publish = false

allow_publish {
    input.schema.has_pii_tags == true
    input.infrastructure.encryption == "AES-256"
}
```

---

## 🔄 Data Mesh Flow: Pipeline → Product

```text
           ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
           │ Sales Team  │      │ Inventory   │      │ Finance     │
           │ (Domain)    │      │ Team        │      │ Team        │
           │ Event Stream│      │ Event Stream│      │ Event Stream│
           └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
                  │                     │                     │
                  ▼                     ▼                     ▼
           ┌─────────────────────────────────────────────────────┐
           │          Sidecar / SDK Adapter per Domain           │
           │  - Validates events against contract                │
           │  - Masks PII, enriches metadata                     │
           └───────────┬─────────────┬─────────────┬───────────┘
                       │             │             │
                       ▼             ▼             ▼
          ┌─────────────────────────────────────────────────────┐
          │            Federated Governance Layer               │
          │ - Policy-as-Code enforcement                        │
          │ - Schema enforcement & Access Control               │
          └───────────┬─────────────┬─────────────┬───────────┘
                       │             │             │
           ┌───────────┘             │             └───────────┐
           ▼                         ▼                         ▼
     ┌─────────────┐           ┌─────────────┐           ┌─────────────┐
     │ Self-Serve  │           │ Projection  │           │ Metadata /  │
     │ Platform    │           │ Services    │           │ Catalog     │
     │ - Storage   │           │ - Transform │           │ - Discover- │
     │ - ETL / CI  │           │   Event ->  │           │   able      │
     └──────┬──────┘           │   Table     │           └─────────────┘
            │                  └─────────────┘
            ▼
     ┌─────────────┐
     │ Data Consumers │
     │ - BI / ML      │
     │ - Analytics    │
     └─────────────┘
```

*💡 This flow ensures **every domain controls its own data product**, but all consumers access governed, trustworthy data.*

---

## 📂 Directory Structure

```
/contracts       # YAML specs for domain data products and SLOs
/projections     # ETL/ELT code to materialize analytical tables
/governance      # Rego / OPA scripts for PII masking and schema validation
```

---

