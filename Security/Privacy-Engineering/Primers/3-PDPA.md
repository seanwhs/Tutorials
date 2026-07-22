# Primer 03 — Singapore PDPA Basics

## For GreyMatter MindfulLog

Welcome to **Primer 03: Singapore PDPA Basics**.

This primer adapts our privacy-rights foundation for **Singapore’s Personal Data Protection Act**, commonly called the **PDPA**.

GreyMatter MindfulLog is a privacy-first mental-health journaling application. Users can record mood scores, write private notes, create journal entries, set medication reminders, manage granular consent preferences, request exports of their data, and delete their account and associated data across systems [8].

Because this app may process mental-health information, we treat it as a high-sensitivity system even though Singapore’s PDPA does not use the exact same “special category data” structure as GDPR.

The goal of this primer is not to provide legal advice. The goal is to translate Singapore PDPA concepts into practical engineering decisions for GreyMatter MindfulLog.

---

# 1. Important Disclaimer

This primer is for engineering education.

It is not legal advice.

If GreyMatter MindfulLog is operated as a real product in Singapore or offered to Singapore users, you should consult qualified Singapore privacy counsel and refer to guidance from the **Personal Data Protection Commission**, or **PDPC**.

This primer focuses on practical engineering alignment with Singapore PDPA concepts.

---

# 2. What the Singapore PDPA Is

The **Personal Data Protection Act 2012** is Singapore’s main private-sector data protection law.

At a high level, the PDPA governs how organizations collect, use, disclose, protect, retain, transfer, and manage personal data.

For engineers, the PDPA becomes a set of product and architecture requirements:

| PDPA Concept | Engineering Translation |
|---|---|
| Consent | Ask for clear consent where required and record it reliably |
| Purpose limitation | Use data only for appropriate, notified purposes |
| Notification | Tell users what data is collected and why |
| Access and correction | Let users request access to and correction of their personal data |
| Accuracy | Keep data reasonably accurate where it affects users |
| Protection | Secure personal data against unauthorized access or disclosure |
| Retention limitation | Delete or anonymize data when no longer needed |
| Transfer limitation | Protect data when sent overseas or to vendors |
| Accountability | Maintain policies, records, and responsible governance |
| Data breach notification | Assess and notify notifiable breaches within required timelines |

GreyMatter MindfulLog already follows a privacy-by-design architecture: plaintext health data should not touch disk or logs, access decisions go through a centralized policy engine, consent is append-only, deletion cascades safely, and CI/CD enforces privacy rules [8].

---

# 3. Why PDPA Matters for GreyMatter MindfulLog

GreyMatter MindfulLog handles highly personal information.

Users may write about:

- anxiety,
- depression,
- medication,
- therapy,
- trauma,
- self-harm concerns,
- family conflict,
- workplace stress,
- substance use,
- or other sensitive personal matters.

Under Singapore PDPA, this information is personal data if it can identify an individual directly or indirectly.

Although the PDPA does not classify health data in exactly the same way as GDPR Article 9, mental-health journaling data should be treated as highly sensitive because misuse or exposure could cause serious harm.

Engineering implication:

> Treat mood notes, journal entries, medication reminders, consent records, exports, and deletion workflows as high-risk privacy surfaces.

---

# 4. Key PDPA Vocabulary

## 4.1 Personal Data

Under the PDPA, personal data generally means data about an individual who can be identified from:

1. that data alone; or  
2. that data together with other information the organization has or is likely to have access to.

Examples in GreyMatter MindfulLog:

- email address,
- user account ID,
- mood score,
- journal entry,
- medication reminder,
- consent history,
- IP address or HMAC fingerprint,
- account export,
- deletion request.

A journal entry may identify someone even without a name if the surrounding details are specific enough.

---

## 4.2 Individual

The individual is the person the personal data is about.

In GreyMatter MindfulLog, this is usually the app user.

---

## 4.3 Organization

The organization is the entity that collects, uses, or discloses personal data.

If GreyMatter MindfulLog is operated as a real service, the company or team operating it would likely be the organization responsible under PDPA.

---

## 4.4 Data Intermediary

A data intermediary processes personal data on behalf of another organization.

In this architecture, likely data intermediaries or vendors may include:

- hosting provider,
- authentication provider,
- database provider,
- key management provider,
- background job provider,
- monitoring/logging provider.

GreyMatter MindfulLog maintains a vendor register for providers such as Clerk, Neon, Google Cloud, Vercel, and Inngest, tracking purpose, data processed, risk, and required controls [7].

---

## 4.5 Processing

Processing includes many operations, such as:

- collection,
- storage,
- use,
- disclosure,
- encryption,
- decryption,
- export,
- deletion,
- anonymization,
- logging,
- backup,
- vendor transfer.

Encrypted personal data is still personal data if it can be decrypted or linked back to an individual.

---

# 5. PDPA Obligations as Engineering Requirements

Singapore’s PDPA is often explained through key obligations. Below, each obligation is translated into practical engineering requirements for GreyMatter MindfulLog.

---

# 5.1 Consent Obligation

Organizations generally need consent to collect, use, or disclose personal data unless an exception applies.

For GreyMatter MindfulLog, consent is especially important for optional purposes such as:

- analytics,
- marketing,
- research,
- support access,
- optional product improvement uses.

The app should avoid bundled or manipulative consent.

The consent system should use:

- clear purposes,
- equal choices,
- no pre-checked boxes,
- easy withdrawal,
- append-only consent history.

GreyMatter MindfulLog already uses an append-only consent ledger where every consent decision is recorded as a new immutable record and the current state is derived from the latest record per purpose [4].

Example consent purposes:

```ts
export type ConsentPurpose =
  | "analytics"
  | "marketing"
  | "research"
  | "support_access";
```

Engineering rule:

> Never silently reuse personal data for a new purpose without checking whether the notified purpose and consent basis support that use.

---

# 5.2 Deemed Consent and Exceptions

The PDPA includes concepts such as deemed consent and exceptions to consent in some circumstances.

However, for a high-sensitivity app like GreyMatter MindfulLog, we should be conservative.

Even if a legal basis or exception may exist, the privacy-first product default should be:

- ask clearly where practical,
- minimize the data,
- avoid surprise uses,
- record the purpose,
- give users control.

For example, do not assume that because a user wrote a journal entry, the app may use that content for research, marketing, or AI model training.

That should require a clear, separate, opt-in consent flow.

---

# 5.3 Withdrawal of Consent

Under PDPA, individuals must generally be allowed to withdraw consent, with reasonable notice.

In product terms:

- users should be able to withdraw optional consent,
- the app should explain consequences,
- withdrawal should be recorded,
- downstream processing should stop where required,
- background systems should receive consent-change events.

GreyMatter MindfulLog’s consent model is well suited to this because it does not overwrite old consent. It records each decision as a new event [4].

A withdrawal might be represented as:

```ts
await recordConsent(userId, "analytics", false);
```

Engineering requirement:

> Consent withdrawal must propagate to analytics, research, marketing, support tooling, background jobs, and future exports where relevant.

---

# 5.4 Purpose Limitation Obligation

The PDPA requires collection, use, or disclosure of personal data only for purposes that a reasonable person would consider appropriate in the circumstances and, where applicable, that have been notified to the individual.

For GreyMatter MindfulLog:

| Data | Appropriate Purpose | Risky Secondary Use |
|---|---|---|
| Mood score | User mood tracking | Ad targeting |
| Journal content | Private reflection | AI training without consent |
| Medication reminder | User reminder | Health profiling |
| Consent record | Audit and preference management | Behavioral scoring |
| IP HMAC | Abuse prevention | General analytics without notice |

Engineering requirement:

> Every table and field should have a documented purpose in the DPIA.

The DPIA should be updated after every schema change and should describe each asset, justification, sensitivity, storage, and mitigation [7].

---

# 5.5 Notification Obligation

Users should be informed of the purposes for which their personal data is collected, used, or disclosed.

For GreyMatter MindfulLog, this means transparency should appear in the product, not only in a privacy policy.

Examples:

- onboarding explains what data is collected,
- journal screens explain encrypted storage,
- consent settings explain each purpose,
- export screen explains what will be included,
- deletion screen explains what is deleted or anonymized,
- support-access consent explains what support can see.

Good notification is:

- specific,
- readable,
- timely,
- not hidden,
- not overly legalistic.

Bad notification:

```txt
By using this app, you consent to all processing for any business purpose.
```

Better:

```txt
Analytics helps us understand which features are used. We do not use journal text for analytics. You can turn analytics off at any time.
```

---

# 5.6 Access Obligation

Under PDPA, individuals generally have the right to request access to their personal data and information about how it has been used or disclosed within a relevant period, subject to exceptions.

In GreyMatter MindfulLog, this maps to a user data export flow.

The original project calls this a DSAR export in the GDPR framing, but for Singapore PDPA we can call it:

```txt
Personal Data Access Export
```

or:

```txt
PDPA Access Request Export
```

The export should include:

- mood logs,
- decrypted mood notes,
- journal entries,
- reminders,
- consent history,
- account metadata,
- export manifest.

The existing project includes export functionality as part of privacy rights, alongside deletion workflows [3].

Engineering requirements:

- authenticate the user,
- authorize the export,
- log the export request safely,
- generate the export through a background job,
- avoid storing plaintext export files permanently,
- expire export links,
- include a manifest,
- avoid leaking export links.

---

# 5.7 Correction Obligation

Under PDPA, individuals generally have the right to request correction of errors or omissions in their personal data.

For GreyMatter MindfulLog, many user-created records can simply be edited by the user directly:

- mood score,
- journal title,
- journal content,
- reminder details,
- consent preferences.

However, some data may need special handling:

| Data | Correction Approach |
|---|---|
| Journal entry | User edits entry |
| Mood score | User edits mood log |
| Reminder | User edits reminder |
| Email | Managed through identity provider |
| Consent history | Do not edit old records; append new decision |
| Audit record | Do not mutate; add correction annotation if needed |

Important:

> Append-only consent records should not be rewritten. If a consent decision changes, insert a new event.

This matches the existing consent design where current consent state is derived from the latest record rather than updating historical records [4].

---

# 5.8 Accuracy Obligation

Organizations must make reasonable efforts to ensure personal data is accurate and complete if it is likely to be used to make a decision affecting the individual or disclosed to another organization.

For GreyMatter MindfulLog:

- user-entered journal content is subjective and should not be “corrected” by the app,
- mood scores should be stored accurately as entered,
- reminder times should be accurate,
- consent states should be accurately derived,
- account email should be synced accurately with the identity provider.

Engineering examples:

```ts
if (moodScore < 1 || moodScore > 10) {
  throw new Error("Mood score must be between 1 and 10");
}
```

The schema already constrains mood scores between 1 and 10 [6].

---

# 5.9 Protection Obligation

Organizations must protect personal data in their possession or under their control by making reasonable security arrangements.

For GreyMatter MindfulLog, protection is implemented through:

- field-level encryption,
- centralized policy engine,
- safe logging,
- minimized schema,
- authentication,
- rate limiting,
- background job controls,
- encrypted backups,
- CI privacy scanning,
- incident response.

The architecture uses a centralized policy engine, a PII-redacting logger, field-level encryption, Neon Postgres with encrypted columns, Google Cloud KMS, durable jobs, and Clerk identity lifecycle management [8].

Sensitive mood notes and journal entries should be stored in encrypted binary columns, such as `notes_encrypted BYTEA` and `content_encrypted BYTEA` [6].

The encryption and access-control design protects health data even if the database is breached or a developer makes a mistake [5].

---

# 5.10 Retention Limitation Obligation

Under PDPA, personal data should not be retained when it is no longer necessary for legal or business purposes.

For GreyMatter MindfulLog, retention should be explicit.

Examples:

| Data | Retention Approach |
|---|---|
| Mood logs | User-controlled, with optional maximum retention |
| Journal entries | User-controlled until deletion |
| Reminders | Delete when inactive or account deleted |
| Consent records | Retain/anonymize for audit |
| Export files | Short-lived only |
| Raw logs | Short retention, redacted |
| IP HMAC | Short retention for abuse prevention |

The existing operations plan includes table-specific retention, such as mood logs retained for a maximum of seven years unless consented longer [1].

Deletion should remove local mood logs, journal entries, and reminders, while anonymizing the consent ledger to preserve audit value [3].

Engineering rule:

> Deletion is not just deleting a user row. It is an orchestrated workflow across local data, vendors, exports, logs, jobs, and audit records.

---

# 5.11 Transfer Limitation Obligation

The PDPA restricts transfers of personal data outside Singapore unless the transferred data receives a comparable standard of protection.

For GreyMatter MindfulLog, this matters because vendors may operate globally.

Relevant vendors may include:

- Clerk,
- Neon,
- Google Cloud KMS,
- Vercel,
- Inngest,
- logging or monitoring tools.

Engineering and governance requirements:

- document vendor locations where possible,
- review data processing terms,
- minimize data sent to vendors,
- avoid sending plaintext journal content to vendors,
- use encryption before storage,
- avoid sensitive data in job payloads,
- restrict vendor dashboard access,
- document deletion behavior.

The vendor register should track the vendor purpose, data processed, risk, and required controls [7].

---

# 5.12 Accountability Obligation

Organizations must be accountable for the personal data they process.

For GreyMatter MindfulLog, accountability means keeping privacy governance inside the repo and engineering workflow.

Required artifacts:

```txt
docs/
├── DPIA.md
├── PRIVACY_CONVENTIONS.md
├── THREAT_MODEL.md
├── VENDOR_REGISTER.md
├── PRIVACY_CHECKLIST.md
└── INCIDENT_RESPONSE.md
```

The existing project already requires a living DPIA, STRIDE threat model, vendor register, and privacy engineering conventions [7].

The privacy conventions include:

- never use `console.log` with user data,
- all PII columns must be encrypted or derived,
- every endpoint must go through the policy engine,
- schema changes require DPIA updates,
- consent table is append-only [7].

---

# 5.13 Data Breach Notification Obligation

Singapore PDPA includes mandatory data breach notification requirements.

In general terms, an organization must assess suspected data breaches and notify the PDPC if the breach is notifiable.

A breach is generally notifiable if it:

1. is likely to result in significant harm to affected individuals; or  
2. is of significant scale, commonly understood as affecting 500 or more individuals.

Once the organization determines that a breach is notifiable, notification to the PDPC must generally be made as soon as practicable, and no later than **3 calendar days** after that determination. Affected individuals should also generally be notified as soon as practicable where significant harm is likely.

For GreyMatter MindfulLog, plaintext mental-health data exposure should be treated as critical.

The incident response playbook already classifies plaintext health data exposure as SEV-1 and includes response steps: detect, contain, eradicate, recover, and post-mortem [1].

For Singapore, adapt the incident wording from GDPR’s “72 hours” to PDPA’s breach-assessment and notification model.

Suggested Singapore-specific incident wording:

```md
## SEV-1 Critical Privacy Incident

Examples:
- Plaintext mental-health journal data exposed
- Unauthorized access to decrypted journal content
- Export file exposed to the wrong user
- Large-scale account data breach

Actions:
1. Contain immediately.
2. Preserve evidence.
3. Assess whether the breach is notifiable under Singapore PDPA.
4. If notifiable, notify PDPC as soon as practicable and no later than 3 calendar days after determining the breach is notifiable.
5. Notify affected individuals as soon as practicable where significant harm is likely.
6. Rotate keys or revoke sessions where needed.
7. Update DPIA, threat model, scanner rules, and incident playbook.
```

---

# 6. PDPA vs GDPR: Practical Differences for This Project

If you previously framed the primer around GDPR, here is the practical Singapore adaptation.

| Topic | GDPR Framing | Singapore PDPA Framing |
|---|---|---|
| Regulator | EU supervisory authority | PDPC |
| Sensitive health data | Special category data | Sensitive personal data by risk, though not same formal category |
| Access request | DSAR / Right of Access | Access request under PDPA |
| Correction | Right to rectification | Correction obligation |
| Erasure | Right to be forgotten | Retention limitation, withdrawal effects, deletion/anonymization where no longer needed |
| Breach notification | Often 72 hours to authority | Notify PDPC no later than 3 calendar days after determining breach is notifiable |
| Consent | One lawful basis among several | Central PDPA obligation, with exceptions/deemed consent possible |
| Vendor | Processor | Data intermediary |
| International transfer | Transfer safeguards | Comparable protection requirement |

Important adaptation:

> Do not overclaim a GDPR-style “Right to be Forgotten” under Singapore PDPA. Instead, implement deletion and anonymization as a privacy-first feature that supports retention limitation, consent withdrawal, and user trust.

---

# 7. How This Changes GreyMatter MindfulLog Documentation

If adapting the series to Singapore, rename or adjust these documents.

## 7.1 Rename GDPR-Focused Language

Instead of:

```txt
DSAR Export
Right to be Forgotten
GDPR 72-hour notification
Special Category Data under Article 9
```

Use:

```txt
PDPA Access Request Export
Account Deletion and Retention Limitation
PDPA Notifiable Data Breach Assessment
Sensitive Mental-Health Personal Data
```

---

## 7.2 Update `docs/DPIA.md`

Even though DPIA is a GDPR term, it is still useful as a privacy engineering artifact.

You can keep the name `DPIA.md`, or use:

```txt
docs/PRIVACY_IMPACT_ASSESSMENT.md
```

Add Singapore-specific review sections:

```md
## Singapore PDPA Alignment

This project considers the following PDPA obligations:

- Consent
- Purpose Limitation
- Notification
- Access and Correction
- Accuracy
- Protection
- Retention Limitation
- Transfer Limitation
- Accountability
- Data Breach Notification
```

---

## 7.3 Update `docs/INCIDENT_RESPONSE.md`

Replace GDPR-specific breach notification wording with Singapore PDPA wording.

Original concept:

```md
Plaintext health data exposed → Notify users + regulators within 72h
```

Singapore adaptation:

```md
Plaintext mental-health personal data exposed → SEV-1.
Assess whether breach is notifiable under Singapore PDPA.
If notifiable, notify PDPC as soon as practicable and no later than 3 calendar days after determining that the breach is notifiable.
Notify affected individuals as soon as practicable where significant harm is likely.
```

The rest of the response flow remains useful: detect, contain, eradicate, recover, and post-mortem [1].

---

## 7.4 Update Export Language

Instead of:

```txt
DSAR export
```

Use:

```txt
PDPA Access Request Export
```

You may still mention DSAR as a generic global privacy term, but for a Singapore-focused tutorial, “Access Request” is clearer.

---

## 7.5 Update Deletion Language

Instead of making deletion solely a GDPR “Right to Erasure” feature, frame it as:

```txt
Account Deletion, Withdrawal Handling, and Retention Limitation
```

The implementation can still delete local mood logs, journal entries, and reminders, then anonymize consent records for audit preservation [3].

---

# 8. Singapore PDPA Engineering Checklist

Use this checklist when building GreyMatter MindfulLog for Singapore PDPA alignment.

## Consent

- [ ] Consent purposes are specific.
- [ ] Consent is not bundled unnecessarily.
- [ ] Users can withdraw optional consent.
- [ ] Withdrawal is recorded.
- [ ] Consent history is append-only.
- [ ] Consent withdrawal propagates to downstream systems.

## Notification

- [ ] Users understand what data is collected.
- [ ] Users understand why data is collected.
- [ ] Sensitive uses are explained clearly.
- [ ] Support access is explained before enabling.
- [ ] Export and deletion flows explain consequences.

## Purpose Limitation

- [ ] Every data field has a documented purpose.
- [ ] Journal content is not reused for analytics, research, marketing, or AI training without explicit consent.
- [ ] Vendor payloads are minimized.
- [ ] Background job payloads avoid plaintext sensitive data.

## Access and Correction

- [ ] Users can access/export their personal data.
- [ ] Users can correct editable records.
- [ ] Consent history is not overwritten.
- [ ] Identity-provider data correction is handled through the provider.

## Protection

- [ ] Journal content is encrypted.
- [ ] Mood notes are encrypted.
- [ ] Access goes through the policy engine.
- [ ] Logs redact sensitive content.
- [ ] CI blocks unsafe plaintext schema fields.
- [ ] Backups are encrypted.

## Retention

- [ ] Retention rules are documented.
- [ ] Export files expire.
- [ ] Deleted accounts trigger deletion/anonymization.
- [ ] Logs have limited retention.
- [ ] Consent audit records are anonymized where appropriate.

## Transfer

- [ ] Vendors are documented.
- [ ] Overseas transfers are reviewed.
- [ ] Comparable protection is assessed.
- [ ] Plaintext journal content is not sent unnecessarily to vendors.

## Accountability

- [ ] Privacy policies and practices are documented.
- [ ] DPIA or privacy impact assessment is maintained.
- [ ] Threat model is maintained.
- [ ] Vendor register is maintained.
- [ ] Incident response playbook is maintained.
- [ ] Privacy checklist is reviewed periodically.

## Breach Notification

- [ ] Breach assessment process exists.
- [ ] Significant harm threshold is considered.
- [ ] Significant scale threshold is considered.
- [ ] PDPC notification process is documented.
- [ ] Affected individual notification process is documented.
- [ ] Evidence preservation steps are documented.

---

# 9. Suggested File Renames for Singapore Version

If you want the whole tutorial series to feel Singapore-native, use these names:

```txt
docs/
├── PRIVACY_IMPACT_ASSESSMENT.md
├── PRIVACY_CONVENTIONS.md
├── THREAT_MODEL.md
├── VENDOR_REGISTER.md
├── PDPA_ACCESS_REQUESTS.md
├── ACCOUNT_DELETION_AND_RETENTION.md
├── INCIDENT_RESPONSE.md
└── PRIVACY_CHECKLIST.md
```

For primers:

```txt
docs/primers/
├── Primer-01-Privacy-Engineering-101.md
├── Primer-02-Cryptography-Basics.md
├── Primer-03-Singapore-PDPA-Basics.md
├── Primer-04-Threat-Modeling-with-STRIDE.md
└── Primer-05-Modern-Web-Stack-Essentials.md
```

---

# 10. Key Takeaways

For Singapore PDPA alignment, GreyMatter MindfulLog should be designed around these principles:

1. Personal data includes any data that can identify a user directly or indirectly.
2. Mental-health journaling data should be treated as highly sensitive.
3. Consent must be clear, purpose-specific, and withdrawable.
4. Users should be notified clearly about data collection, use, and disclosure.
5. Access and correction rights should be supported through product workflows.
6. Deletion should be framed around retention limitation, account closure, and withdrawal handling.
7. Sensitive journal content should be encrypted before storage.
8. Logs should not contain private user content.
9. Vendors and overseas transfers must be documented and controlled.
10. Notifiable data breaches require prompt assessment and notification under Singapore PDPA.
