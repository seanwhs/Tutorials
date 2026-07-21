# Primer 01 — Privacy Engineering 101

## For GreyMatter MindfulLog

Welcome to **Primer 01: Privacy Engineering 101**.

This primer introduces the mindset, vocabulary, engineering practices, and architectural patterns behind **GreyMatter MindfulLog**, a privacy-first mental-health journaling application.

Before we build database tables, encryption utilities, consent screens, DSAR exports, deletion jobs, or incident playbooks, we need to understand what privacy engineering actually is.

Privacy engineering is not the same as writing a privacy policy.

It is not the same as adding a cookie banner.

It is not the same as promising users that their data is safe.

Privacy engineering is the practice of designing systems where privacy-respecting behavior is enforced by architecture, code, defaults, workflows, and operational controls.

The guiding question for this project is:

> What kind of system architecture makes violating user privacy structurally difficult or impossible?

That question is central to the GreyMatter MindfulLog tutorial series. The goal is to build a real application where privacy is the default behavior of the system, not an afterthought or legal checkbox [8].

---

# 1. Why Privacy Engineering Matters

Most software teams treat privacy as something that happens late:

- after the feature is built,
- after the database schema is designed,
- after analytics are added,
- after logs already contain user data,
- after support tooling exists,
- after the product is preparing to launch.

That approach creates fragile privacy.

When privacy is added late, teams usually rely on promises, policies, and manual discipline:

- “Developers should not log sensitive data.”
- “Support staff should only access records when necessary.”
- “We should delete user data when requested.”
- “We should not collect more data than we need.”
- “We should encrypt this later.”

But privacy-first systems do not depend only on “should.”

They use architecture to make safer behavior the natural behavior.

For example, GreyMatter MindfulLog should be designed so that:

- private journal content is not stored as readable database text,
- sensitive fields are encrypted before storage,
- consent records are append-only,
- support access is masked by default,
- data exports are intentional and auditable,
- deletion workflows are explicit and verifiable,
- raw user data is not casually logged,
- new schema fields require privacy review,
- and unknown access decisions fail closed.

This is the difference between **privacy as a promise** and **privacy as a system property**.

---

# 2. Privacy Engineering vs. Compliance

Privacy engineering and compliance are related, but they are not the same thing.

Compliance asks:

> Are we meeting legal obligations?

Privacy engineering asks:

> Is the system designed to protect people even when something goes wrong?

A company can have a privacy policy and still leak user data.

A company can have a consent banner and still manipulate users.

A company can claim data is secure and still store sensitive notes in plaintext.

A company can support account deletion and still leave data behind in logs, backups, analytics tools, or background job payloads.

Privacy engineering tries to close those gaps.

It turns principles into technical controls:

| Privacy Goal | Engineering Control |
|---|---|
| Do not overcollect data | Data minimization and schema review |
| Protect sensitive content | Field-level encryption |
| Prevent unauthorized access | Centralized policy engine |
| Respect consent | Append-only consent ledger |
| Support user rights | DSAR export and deletion workflows |
| Avoid accidental leaks | PII-safe logging and CI checks |
| Prepare for failures | Incident response playbook |

In GreyMatter MindfulLog, privacy is not treated as a final documentation task. It is embedded into the application from the beginning.

The foundations are created before user-facing code because skipping this step leads to privacy and security problems that become expensive or impossible to fix later [7].

---

# 3. The Application Context: GreyMatter MindfulLog

**GreyMatter MindfulLog** is a mental-health journaling application.

Users may use it to:

- record mood scores,
- write private mood notes,
- create journal entries,
- set wellness or medication reminders,
- manage consent settings,
- request an export of their data,
- and delete their account.

This is a high-sensitivity context.

A journal entry may include information about:

- anxiety,
- depression,
- medication,
- therapy,
- trauma,
- family conflict,
- workplace stress,
- substance use,
- diagnosis,
- self-harm ideation,
- or other deeply personal details.

That means the system must be designed with care from the beginning.

A privacy mistake in a generic todo app is bad.

A privacy mistake in a mental-health journaling app can be deeply harmful.

So our design standard is higher.

---

# 4. The Core Privacy Engineering Mindset

Privacy engineering starts with a few simple but powerful assumptions.

## 4.1 Assume Data Will Be Misused If You Make Misuse Easy

If sensitive data is stored in plaintext, someone may eventually see it.

If support tools expose full records, someone may over-access them.

If logs contain request bodies, sensitive data may leak into monitoring systems.

If consent can be overwritten, the audit trail may become unreliable.

If deletion is manual, it may be incomplete.

Privacy-first architecture reduces the number of ways these failures can happen.

---

## 4.2 Assume Developers Make Mistakes

Privacy engineering should not assume perfect developers.

Developers are busy.

They copy patterns.

They debug production issues.

They add fields quickly.

They log objects during troubleshooting.

They may not remember every privacy rule.

So the codebase should help them.

Examples:

- Sensitive database fields should use obviously encrypted column names.
- CI should fail when risky plaintext fields are introduced.
- Logging utilities should redact sensitive values by default.
- Authorization should be centralized instead of duplicated.
- Schema changes should require DPIA updates.
- Consent should be append-only by design.

The project’s privacy conventions explicitly require no raw `console.log` with user data, PII columns to be encrypted or derived, every endpoint to pass through the policy engine, schema changes to update the DPIA, and consent to remain append-only [7].

---

## 4.3 Assume Systems Fail

Privacy engineering does not pretend incidents will never happen.

It prepares for them.

A privacy-first system should answer:

- What if the database is breached?
- What if a log stream contains sensitive data?
- What if a support user accesses too much?
- What if encryption fails?
- What if a DSAR export link is leaked?
- What if account deletion partially fails?
- What if a vendor retains data after deletion?
- What if a consent withdrawal does not propagate?

The final operational layer of the project includes incident response, severity levels, containment steps, key rotation, recovery, and post-mortem updates [1].

---

# 5. The Seven Privacy by Design Principles

GreyMatter MindfulLog is guided by the seven Privacy by Design principles.

These are not abstract slogans. In this project, each one becomes an engineering requirement.

---

## 5.1 Proactive, Not Reactive

Privacy work happens before implementation.

That means:

- threat modeling before schema design,
- DPIA before storing sensitive data,
- vendor review before integrating tools,
- deletion planning before collecting data,
- logging rules before production debugging.

In this series, threat modeling and DPIA work come before writing the schema [8].

---

## 5.2 Privacy as the Default

The safest reasonable behavior should happen automatically.

Users should not need to dig through settings to protect themselves.

Examples:

- analytics consent should default to off unless explicitly granted,
- support access should be masked by default,
- sensitive notes should be encrypted by default,
- raw IP addresses should not be stored by default,
- user deletion should delete or anonymize associated records by default.

Privacy as default means the user is protected even if they never configure anything.

---

## 5.3 Privacy Embedded into Design

Privacy controls should be part of the system architecture.

Not bolted on.

Examples:

- encrypted database fields,
- centralized access-control checks,
- append-only consent records,
- background deletion workflows,
- PII-safe logging,
- CI privacy scanners,
- incident playbooks.

The policy engine is intended to sit at the heart of the application’s privacy architecture [8].

---

## 5.4 Full Functionality

Privacy should not make the product worse.

A common misconception is that privacy and product quality conflict.

GreyMatter MindfulLog takes the opposite view.

Privacy features can improve the product:

- Data export builds trust.
- Deletion gives users control.
- Consent history increases transparency.
- Minimal data collection reduces user anxiety.
- Encryption makes the product safer.
- Clear settings reduce confusion.

Privacy should support the user experience, not obstruct it.

---

## 5.5 End-to-End Security

Sensitive data must be protected throughout its lifecycle.

That includes:

- collection,
- validation,
- transmission,
- storage,
- access,
- background processing,
- export,
- deletion,
- logging,
- backup,
- incident response.

GreyMatter MindfulLog protects sensitive content through field-level encryption and centralized access control so that even if a database is breached or a developer makes a mistake, health data remains better protected [5].

---

## 5.6 Visibility and Transparency

Users should be able to understand what is happening with their data.

That means the application should make it clear:

- what data is collected,
- why it is collected,
- what consent has been given,
- how to withdraw consent,
- how to export data,
- how to delete an account,
- and what happens after deletion.

Transparency is not only a privacy policy.

It is product design.

---

## 5.7 Respect for the User

Respect means avoiding dark patterns.

Consent should be:

- clear,
- specific,
- freely given,
- easy to withdraw,
- not bundled unnecessarily,
- not hidden behind confusing UI,
- and not manipulated through unequal button styling.

The consent system in the project is designed around clear, symmetric, freely given consent with an audit trail that cannot silently drift [4].

---

# 6. Privacy Engineering Building Blocks

GreyMatter MindfulLog uses several major privacy engineering building blocks.

Each one will become a concrete implementation later in the project.

---

## 6.1 Data Minimization

Data minimization means collecting and storing only what is necessary.

The less data you store, the less can be stolen, leaked, misused, subpoenaed, mishandled, or accidentally exposed.

The project designs the schema after the threat model so every column has a documented justification [6].

Ask this for every field:

1. Why do we need this?
2. What feature depends on it?
3. Is there a less sensitive alternative?
4. Can we derive it instead of storing it?
5. Can we store it for less time?
6. Can we encrypt it?
7. Can we avoid sending it to vendors?
8. What happens to it during account deletion?

Bad minimization:

```txt
Store everything now because we might need it later.
```

Good minimization:

```txt
Store only the data needed for a defined feature, document why it exists, and protect it according to sensitivity.
```

---

## 6.2 Purpose Limitation

Purpose limitation means data collected for one reason should not silently become data used for another reason.

For example:

| Data | Original Purpose | Risky Secondary Use |
|---|---|---|
| Mood score | User reflection | Advertising targeting |
| Journal content | Private writing | AI training without consent |
| Reminder label | User notification | Health profiling |
| IP fingerprint | Abuse prevention | Behavioral analytics |

If the purpose changes, consent and documentation may need to change too.

---

## 6.3 Field-Level Encryption

Database encryption at rest is useful, but it is not enough.

If an application or database user can read plaintext sensitive fields, then a breach, bug, or overbroad admin access can expose them.

Field-level encryption means sensitive values are encrypted before they are stored in the database.

For GreyMatter MindfulLog:

- mood notes should be encrypted,
- journal content should be encrypted,
- sensitive reminder labels should be minimized or encrypted.

The schema uses binary encrypted fields such as `notes_encrypted BYTEA` and `content_encrypted BYTEA` for sensitive mood and journal content [6].

---

## 6.4 Zero-Trust Access Control

Zero-trust access control means every access request must prove it is allowed.

The system should not assume that because someone is logged in, they can access everything.

The project uses a centralized policy engine where all access decisions go through one trusted place, and unknown decisions fail closed [5].

Fail closed means:

```txt
If the system is unsure, deny access.
```

Not:

```txt
If the system is unsure, allow access and hope it is fine.
```

Example policy expectations:

| Actor | Expected Access |
|---|---|
| User | Can access their own mood logs and journals |
| Other user | Cannot access another user’s private data |
| Support | Can access masked views only when justified |
| Admin | Must still be constrained and audited |
| Unknown role | Denied |

---

## 6.5 Append-Only Consent

Consent should not be overwritten.

Instead, each consent decision should be recorded as a new event.

That gives the system a trustworthy history:

```txt
2025-01-01 — analytics — denied
2025-02-14 — analytics — granted
2025-03-03 — analytics — denied
```

The current state is derived from the latest event.

This is stronger than updating one row repeatedly because it preserves the user’s consent history.

The consent ledger in the project never updates old consent decisions; every decision is a new immutable record, and the current state is derived from the latest record per purpose [4].

---

## 6.6 DSAR Export

DSAR stands for Data Subject Access Request.

In practical product terms, this means:

> Let the user export a copy of their data.

For GreyMatter MindfulLog, a DSAR export should eventually include:

- mood logs,
- decrypted mood notes,
- journal entries,
- reminders,
- consent history,
- account metadata,
- and a manifest explaining the export.

The DSAR export flow implements the user’s Right of Access [3].

A good export should be:

- complete,
- understandable,
- machine-readable,
- temporary,
- access-controlled,
- auditable.

---

## 6.7 Right to Erasure

Right to Erasure means users can delete their account and associated data.

In real systems, deletion is not just one SQL statement.

It may involve:

- local database records,
- authentication provider records,
- background job payloads,
- consent records,
- exports,
- logs,
- analytics systems,
- vendors,
- backups,
- and audit records.

The project treats deletion as an orchestrated workflow with explicit sequencing and retries [3].

Some records may be fully deleted.

Others may need to be anonymized to preserve security or legal auditability.

For example, the project deletes local mood logs, journal entries, and reminders, then anonymizes consent ledger records to preserve audit value without keeping the original user identity [3].

---

## 6.8 Privacy-Safe Logging

Logs are one of the most common places where sensitive data leaks.

Developers often log:

```ts
console.log(req.body);
console.log(user);
console.log(journalEntry);
console.log(error);
```

In a mental-health journaling app, that can accidentally expose extremely sensitive information.

A safer approach is to use a logger that redacts known sensitive fields before writing them.

The project includes a PII-redacting logger concept that recursively redacts sensitive values before logging, along with a recommendation to block raw `console.log` in favor of safe logging [2].

---

## 6.9 Privacy CI/CD Guardrails

Privacy rules should be enforced automatically.

A developer should not be able to accidentally add a plaintext `journal_content TEXT` column without the build complaining.

Privacy CI/CD can include:

- schema scanners,
- secret scanning,
- lint rules,
- build checks,
- dependency checks,
- tests for authorization,
- tests for encryption,
- tests for deletion,
- tests for consent behavior.

The project’s GitHub Actions privacy pipeline runs dependency installation, `npm run privacy:scan`, `npm run build`, and secret scanning with Gitleaks [2].

---

## 6.10 Incident Response

Privacy engineering includes planning for failure.

An incident response playbook should define:

- severity levels,
- detection steps,
- containment actions,
- eradication,
- recovery,
- post-mortems,
- user notification,
- regulator notification,
- key rotation,
- and DPIA updates.

The incident response plan classifies plaintext health data exposure as SEV-1 and includes steps such as detecting, containing, eradicating, recovering, and updating the DPIA after the incident [1].

---

# 7. Privacy Vocabulary

This section defines terms you will see throughout the project.

## Personal Data

Any information relating to an identified or identifiable person.

Examples:

- email,
- user ID,
- IP address,
- journal entry,
- mood score,
- reminder label.

---

## Sensitive Data

A higher-risk category of personal data.

In GreyMatter MindfulLog, this includes:

- mental-health notes,
- journal content,
- medication reminders,
- crisis-related text,
- therapy-related notes.

---

## PII

Personally Identifiable Information.

Examples:

- name,
- email,
- phone number,
- address,
- IP address,
- government ID.

Not all personal data is obvious PII. Journal content may identify a person even if it does not include their name.

---

## PHI / Health Data

Health-related personal information.

Even if GreyMatter MindfulLog is not positioned as a medical provider, users may enter health-related information. The system should treat that data with high sensitivity.

---

## Data Controller

The entity that decides why and how personal data is processed.

For many SaaS apps, the app operator is the controller for user data.

---

## Data Processor

A vendor or service that processes data on behalf of the controller.

Examples may include:

- hosting provider,
- authentication provider,
- database provider,
- background job platform,
- email service.

---

## DPIA

Data Protection Impact Assessment.

A living document that identifies data, purposes, risks, mitigations, and review triggers.

---

## DSAR

Data Subject Access Request.

A user request to access/export their data.

---

## Right to Erasure

A user’s right to request deletion of personal data, subject to applicable legal and operational constraints.

---

## Consent Ledger

An append-only record of consent decisions.

Instead of overwriting old choices, each choice is stored as a new event.

---

## Data Minimization

The practice of collecting and storing only what is necessary.

---

## Purpose Limitation

The principle that data collected for one purpose should not be silently reused for unrelated purposes.

---

## Pseudonymization

Replacing direct identifiers with internal identifiers.

Example:

```txt
email: alex@example.com
internal user_id: user_2x91...
```

Pseudonymized data can still be personal data if it can be linked back to a person.

---

## Anonymization

Transforming data so it can no longer reasonably identify a person.

True anonymization is hard.

Many systems claim anonymization when they actually mean pseudonymization.

---

## Encryption

Transforming readable data into unreadable ciphertext using cryptographic keys.

---

## HMAC

A keyed hash used to create one-way fingerprints.

For example, an IP address can be transformed into an HMAC value for rate limiting without storing the raw IP address.

The project uses HMAC utilities for identifiable values such as IP addresses in rate limiting or fraud detection contexts [6].

---

# 8. Privacy Threats in GreyMatter MindfulLog

Because this is a mental-health journaling app, we care about more than generic security.

We care about user harm.

Potential privacy threats include:

## 8.1 Database Breach

An attacker gets a copy of the database.

Mitigation:

- field-level encryption,
- minimized schema,
- no plaintext journal content,
- separate key management.

---

## 8.2 Insider Overreach

A support or admin user accesses private journals without a valid reason.

Mitigation:

- masked support views,
- policy engine,
- audit logs,
- just-in-time access,
- consent-based support access.

---

## 8.3 Accidental Logging

A developer logs a request body containing journal text.

Mitigation:

- safe logger,
- ESLint restrictions,
- logging conventions,
- redaction tests.

---

## 8.4 Consent Drift

A user withdraws consent, but downstream systems keep processing data.

Mitigation:

- append-only consent ledger,
- event-driven propagation,
- consent checks before processing,
- audit records.

Consent changes should fan out reliably to other systems using events such as `consent.changed` [4].

---

## 8.5 Incomplete Deletion

A user deletes their account, but some data remains.

Mitigation:

- deletion orchestrator,
- subsystem checklist,
- retries,
- status tracking,
- vendor deletion review,
- backup retention policy.

---

## 8.6 Export Leakage

A DSAR export is generated and exposed through a long-lived or unprotected link.

Mitigation:

- temporary signed URLs,
- expiration,
- authentication,
- audit logging,
- encrypted export storage.

The project’s DSAR workflow returns export metadata such as an expiration window and verifies that the generated ZIP contains decrypted JSON plus a manifest [3].

---

## 8.7 Vendor Data Exposure

A vendor stores data longer than expected or logs sensitive payloads.

Mitigation:

- vendor register,
- minimized payloads,
- DPA review,
- deletion process review,
- no plaintext sensitive content in job payloads.

---

# 9. The Privacy Engineering Lifecycle

Privacy engineering is not one step.

It is a lifecycle.

## 9.1 Design

Questions:

- What data do we need?
- What can we avoid collecting?
- What is sensitive?
- What are the risks?
- Who can access it?
- How long do we keep it?
- What happens during deletion?

Artifacts:

- DPIA,
- threat model,
- vendor register,
- schema design,
- privacy conventions.

---

## 9.2 Build

Implementation controls:

- encrypted fields,
- policy engine,
- consent ledger,
- validation,
- safe logging,
- background jobs,
- export and deletion flows.

---

## 9.3 Verify

Verification methods:

- unit tests,
- integration tests,
- privacy scanner,
- build checks,
- manual database inspection,
- unauthorized access attempts,
- export verification,
- deletion verification.

The final project verification includes checking that encrypted content is binary in the database, unauthorized access is denied, exports produce a valid ZIP, and account deletion removes or anonymizes traces [1].

---

## 9.4 Operate

Operational controls:

- monitoring,
- key rotation,
- backup review,
- incident response,
- privacy metrics,
- quarterly checklist,
- vendor review.

The project includes privacy metrics and a quarterly checklist with targets such as DSAR response time under 30 days and deletion success rate of 100% [2].

---

## 9.5 Improve

After incidents, audits, or feature changes:

- update the DPIA,
- improve scanner rules,
- update threat model,
- revise retention rules,
- improve deletion coverage,
- improve consent propagation,
- strengthen logging controls.

Privacy engineering is continuous.

---

# 10. Practical Rules for This Repository

These rules should shape all future GreyMatter MindfulLog code.

## Rule 1: Do Not Store Sensitive Free Text in Plaintext

Bad:

```sql
journal_content TEXT NOT NULL
```

Better:

```sql
content_encrypted BYTEA NOT NULL
```

Sensitive free text must be encrypted before database storage.

---

## Rule 2: Never Trust Client-Provided User IDs

Bad:

```ts
const { userId } = await req.json();
await getJournalEntries(userId);
```

Better:

```ts
const userId = getAuthenticatedUserIdFromServerSession();
await getJournalEntries(userId);
```

The server should derive identity from trusted authentication context.

---

## Rule 3: All Access Goes Through the Policy Engine

Bad:

```ts
if (entry.userId === user.id) {
  return entry;
}
```

Better:

```ts
if (!PolicyEngine.canView(context, resource)) {
  throw new Error("Forbidden");
}
```

Authorization should not be scattered across the codebase.

---

## Rule 4: Consent Is Append-Only

Bad:

```sql
UPDATE consent_records
SET granted = true
WHERE user_id = $1 AND purpose = 'analytics';
```

Better:

```sql
INSERT INTO consent_records (user_id, purpose, granted)
VALUES ($1, 'analytics', true);
```

Current state should be derived from the latest record.

---

## Rule 5: Logs Must Be Treated as Sensitive

Bad:

```ts
console.log(req.body);
```

Better:

```ts
safeLog("info", "journal_entry_created", {
  userIdHash,
  entryId,
});
```

Logs should contain events and identifiers, not private content.

---

## Rule 6: Deletion Must Be Designed, Not Improvised

Bad:

```ts
await sql`DELETE FROM users WHERE id = ${userId}`;
```

Better:

```ts
await deletionOrchestrator.deleteUserAccount(userId);
```

Deletion should account for related records, vendors, exports, logs, and audit requirements.

---

## Rule 7: Schema Changes Require DPIA Updates

If a pull request adds or changes data storage, it should update the DPIA.

A new field means a new privacy decision.

---

# 11. Privacy Engineering Examples

## Example 1: Mood Score

A mood score from 1 to 10 is personal data.

It may not be as sensitive as free-text journaling, but it still describes emotional state.

Privacy treatment:

- store only the number,
- validate range,
- associate with user ID,
- avoid unnecessary metadata,
- allow deletion.

---

## Example 2: Mood Note

A mood note may contain highly sensitive health information.

Privacy treatment:

- encrypt before storage,
- do not log,
- do not expose to support by default,
- include in DSAR export,
- delete during account deletion.

---

## Example 3: Journal Entry

A journal entry is among the most sensitive data in the app.

Privacy treatment:

- encrypt content,
- strongly authorize access,
- avoid indexing plaintext,
- avoid sending to analytics,
- include in export,
- delete on account deletion.

---

## Example 4: Consent Record

A consent record is not private in the same way as a journal entry, but it is still important.

Privacy treatment:

- append-only,
- auditable,
- timestamped,
- purpose-specific,
- used to derive current state,
- anonymized or retained according to deletion policy.

---

## Example 5: IP Address

An IP address can identify or help identify a user.

Privacy treatment:

- avoid storing raw IP where possible,
- use HMAC fingerprint for abuse prevention,
- define short retention,
- do not use for unrelated analytics without consent.

---

# 12. Privacy Engineering Artifacts

GreyMatter MindfulLog will use several artifacts.

These live in the repository so they evolve with the code.

## 12.1 DPIA

Path:

```txt
docs/DPIA.md
```

Purpose:

- data inventory,
- risk analysis,
- mitigations,
- review triggers.

---

## 12.2 Threat Model

Path:

```txt
docs/THREAT_MODEL.md
```

Purpose:

- identify threats,
- map trust boundaries,
- define mitigations.

---

## 12.3 Vendor Register

Path:

```txt
docs/VENDOR_REGISTER.md
```

Purpose:

- track vendors,
- document data sharing,
- review deletion/export obligations.

---

## 12.4 Privacy Conventions

Path:

```txt
docs/PRIVACY_CONVENTIONS.md
```

Purpose:

- define engineering rules,
- guide contributors,
- support code review.

---

## 12.5 Privacy Checklist

Path:

```txt
docs/PRIVACY_CHECKLIST.md
```

Purpose:

- release readiness,
- quarterly review,
- recurring privacy hygiene.

---

## 12.6 Primers

Path:

```txt
docs/primers/
```

Purpose:

- teach background concepts,
- onboard contributors,
- explain why the architecture works.

This file belongs at:

```txt
docs/primers/Primer-01-Privacy-Engineering-101.md
```

---

# 13. Where This Primer Fits

The primers are background lessons.

They support the main build series.

Recommended primer sequence:

```txt
docs/primers/
├── Primer-01-Privacy-Engineering-101.md
├── Primer-02-Cryptography-Basics.md
├── Primer-03-GDPR-Basics.md
├── Primer-04-Threat-Modeling-with-STRIDE.md
└── Primer-05-Modern-Web-Stack-Essentials.md
```

This primer explains the overall privacy engineering mindset.

The later primers can explain:

- cryptography basics,
- GDPR basics,
- STRIDE threat modeling,
- and the web stack used by GreyMatter MindfulLog.

---

# 14. Mini Exercise: Classify Data

For each data item, decide:

1. Is it personal data?
2. Is it sensitive?
3. Should it be stored?
4. Should it be encrypted?
5. Should it be included in export?
6. Should it be deleted during account deletion?

| Data Item | Personal? | Sensitive? | Store? | Encrypt? | Export? | Delete? |
|---|---:|---:|---:|---:|---:|---:|
| Email address | Yes | High | Prefer vendor only | Vendor-controlled | Yes | Vendor process |
| Mood score | Yes | Medium | Yes | Usually no | Yes | Yes |
| Mood note | Yes | Very high | Optional | Yes | Yes | Yes |
| Journal content | Yes | Very high | Yes | Yes | Yes | Yes |
| Raw IP address | Yes | High | Avoid | N/A | Maybe | Yes/expire |
| IP HMAC | Pseudonymous | Medium | Maybe | N/A | Maybe | Expire |
| Consent event | Yes | Medium | Yes | Usually no | Yes | Anonymize/retain |
| Reminder label | Yes | High | Yes, minimized | Prefer yes | Yes | Yes |

---

# 15. Mini Exercise: Spot the Privacy Problems

Review this example:

```ts
export async function createJournalEntry(req: Request) {
  const body = await req.json();

  console.log("Creating journal entry", body);

  await sql`
    INSERT INTO journal_entries (user_id, title, content)
    VALUES (${body.userId}, ${body.title}, ${body.content})
  `;

  return Response.json({ ok: true });
}
```

Problems:

1. Trusts `body.userId` from the client.
2. Logs the full request body.
3. Stores journal content in plaintext.
4. No validation.
5. No policy-engine check.
6. No encryption.
7. No clear deletion/export handling.
8. No audit event.

A safer design would:

- get user ID from the server session,
- validate input,
- encrypt content,
- avoid logging sensitive text,
- use the policy engine,
- store encrypted bytes,
- include the record in export/deletion workflows.

---

# 16. Privacy Engineering Review Checklist

Use this checklist when designing a new GreyMatter MindfulLog feature.

## Data

- [ ] What data does this feature collect?
- [ ] Is each data field necessary?
- [ ] Can any field be removed?
- [ ] Can any field be derived instead of stored?
- [ ] Is any field sensitive?
- [ ] Does the DPIA need updating?

## Storage

- [ ] Is sensitive data encrypted?
- [ ] Is plaintext storage justified?
- [ ] Is retention defined?
- [ ] Does deletion include this data?
- [ ] Does export include this data?

## Access

- [ ] Who can access this data?
- [ ] Does access go through the policy engine?
- [ ] Does support see only masked data?
- [ ] Are admin actions audited?
- [ ] Does unknown access fail closed?

## Consent

- [ ] Is consent required?
- [ ] Is consent purpose-specific?
- [ ] Can consent be withdrawn?
- [ ] Is consent append-only?
- [ ] Does withdrawal propagate?

## Logging

- [ ] Are logs free of sensitive content?
- [ ] Are identifiers minimized or hashed?
- [ ] Are errors sanitized?
- [ ] Is safe logging used?

## Vendors

- [ ] Does this feature send data to a vendor?
- [ ] Is the vendor listed in the vendor register?
- [ ] Is the payload minimized?
- [ ] What happens on deletion?
- [ ] What happens on export?

## Operations

- [ ] What could go wrong?
- [ ] How would we detect failure?
- [ ] How would we contain it?
- [ ] Does the incident playbook need updating?
- [ ] Do CI checks cover this feature?

---

# 17. Key Takeaways

Privacy engineering is the discipline of turning privacy values into technical systems.

For GreyMatter MindfulLog, that means:

1. Privacy is designed before features.
2. Sensitive data is minimized.
3. Sensitive free text is encrypted.
4. Access decisions are centralized.
5. Consent is append-only.
6. User rights are product features.
7. Logs are treated as risky.
8. CI/CD enforces privacy rules.
9. Incidents are expected and planned for.
10. Documentation evolves with the code.

The result should be a system where safe behavior is not merely encouraged.

It is the default path.

---

# 18. Completion Criteria

You have completed this primer when you can explain:

- what privacy engineering is,
- how it differs from compliance,
- why GreyMatter MindfulLog is high sensitivity,
- what data minimization means,
- why field-level encryption matters,
- what a policy engine does,
- why consent should be append-only,
- what DSAR export means,
- what Right to Erasure means,
- why logs are dangerous,
- how CI/CD can enforce privacy,
- and why incident response is part of privacy engineering.
