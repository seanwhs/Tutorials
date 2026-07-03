# Appendix D2 — Schema Evolution: Managing Change in a Distributed Data Lake

> **Goal of this appendix:** Master the strategies for evolving your database schema without downtime. Learn how to handle "breaking changes" gracefully, ensuring your application remains resilient even as your data structure matures.

---

## 1. The Reality of Data Evolution

In a static application, you define a schema and it stays put. In a live system like GreyMatter Journal, **change is inevitable**. You will eventually need to rename a field, split an object, or change a type.

If you just change the schema in Sanity, your application will break immediately for every user because the frontend expects the "old" structure. This is the **Schema Drift Problem**.

---

## 2. The Three Migration Strategies

### A. The "Additive" Strategy (Easiest)

Never delete or rename a field immediately. Instead, add the new field while keeping the old one.

1. **Add:** Create `newField` in your Sanity schema.
2. **Sync:** Update your code to write to *both* fields.
3. **Migrate:** Run a background script to copy data from `oldField` to `newField`.
4. **Cleanup:** Once all records are migrated, update your frontend to read only from `newField`, then delete the `oldField`.

### B. The "Transformation" Strategy (Dynamic)

If you cannot migrate all 10,000 records at once, perform the transformation in your application code.

```typescript
// Always handle both the new and old structure
const getPost = (data) => ({
  title: data.newTitle || data.oldTitle || "Untitled",
  ...
});

```

### C. The "Versioned" Strategy

Treat your data as versioned API endpoints. If your schema changes drastically, add a `version` field to your documents.

* `v1`: `{ title: "..." }`
* `v2`: `{ metadata: { title: "..." } }`

Your code then branches based on the version:

```typescript
if (doc.version === 1) { /* adapt */ }
else { /* process v2 */ }

```

---

## 3. The "Soft" Migration Workflow

To avoid the "Big Bang" migration where everything breaks at once, use this sequence:

1. **Phase 1: Dual-Write:** Your Server Actions write to both the old and new structures.
2. **Phase 2: Background Migration:** Use Sanity's "Migration CLI" to update existing documents in the background.
3. **Phase 3: The Switch:** Point your frontend components to the new structure.
4. **Phase 4: Pruning:** Once you are confident, deprecate the old schema fields.

---

## 4. Professional Best Practices

* **Schema Guardrails:** In Sanity, use **validation rules** in your schema definition (`required()`, `min()`, `max()`) to ensure that even during migrations, the data maintains integrity.
* **Idempotent Migrations:** Ensure your migration scripts can be run multiple times without causing duplicates or errors. If the script crashes halfway through, you should be able to restart it without corrupting data.
* **The "Zero-Downtime" Rule:** Never perform a breaking change on the live production schema. Always test your migration script against a clone of your production dataset first.

---

## Summary: The Mental Model

Beginners think: **"I will just edit the schema and fix the errors."**
Professional engineers think: **"I will evolve the schema by treating the transition as an API contract between the old data and the new requirements."**

> **The Deep Secret:** Schema migration is not a technical task; it is an exercise in **compatibility**. Your goal is to ensure the frontend is always shielded from the messy reality of data restructuring.
