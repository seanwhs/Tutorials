# Architectural Review Tough Questions

As an Enterprise Architect, your role in a review meeting isn't just to approve designs—it's to stress-test them. In an ecosystem of **50+ apps**, a "simple" design flaw in one service can cause a catastrophic "blast radius" across the enterprise.

Use these questions during **HLSO Reviews** or **QARs** to flush out hidden risks and ensure alignment with the EA Framework.

---

## 1. On Reliability & Failure (The "Assume Breach" Mindset)

* **The "Blast Radius" Question:** "If your service goes down or experiences a 5-second latency spike, which of the other 49 apps will break immediately?"
* **The "Zombie" Question:** "Does this service have a 'Circuit Breaker'? If the database is unreachable, does the app return a graceful error or hang indefinitely, consuming thread pools?"
* **The "Retries" Question:** "You have a retry policy. If 1,000 requests fail simultaneously, will your retries create a 'Self-Inflicted DDoS' on the downstream service?"

---

## 2. On Data & Consistency (The "Source of Truth" Mindset)

* **The "Shadow Master" Question:** "You are caching 'Customer Data' for performance. How do you handle a 'Right to be Forgotten' (GDPR) request if that data exists in your local cache and the master database?"
* **The "Dual-Write" Question:** "You are updating a database and sending a message to Kafka. What happens if the database commit succeeds but the Kafka publish fails?" (Push them toward the **Transactional Outbox Blueprint**).
* **The "Sovereignty" Question:** "Does any PII (Personally Identifiable Information) cross a regional border in this design?"

---

## 3. On Lifecycle & Cost (The "Value" Mindset)

* **The "Exit Strategy" Question:** "If we decide to harvest this asset in two years, how hard will it be to extract the data and redirect its consumers? Are we using proprietary vendor features that 'lock us in'?"
* **The "Utility" Question:** "This looks like a custom-built notification engine. Why aren't we reusing the 'Global Notification Service' (App-14) that already exists?"
* **The "Maintenance" Question:** "Who owns this at 3:00 AM? If the original developers move to a different 'Stream-aligned' team, is the **Runbook** clear enough for a stranger to fix it?"

---

## 4. On Security & Connectivity (The "Zero Trust" Mindset)

* **The "Identity" Question:** "How does Service A prove to Service B that it is actually Service A? Are we relying on IP white-listing (Old way) or **mTLS/SPIFFE** (EA Standard)?"
* **The "Secret" Question:** "Where are the API keys stored? If I scan your IaC repository right now, will I find any hardcoded credentials?"

---

## 5. The "Golden Path" Alignment

* **The "Bypass" Question:** "I see you're using a custom deployment script. Why does the standard **Platform IaC Module** not work for your use case? What can we improve in the module to bring you back to the Golden Path?"

---

### How to use these in a meeting:

> "This design looks solid for a **Pioneer Archetype**, but since we’ve classified this as a **Critical Scaler**, I need to push on the **Data Consistency** piece. Let's look at the **Transactional Outbox** blueprint again..."


