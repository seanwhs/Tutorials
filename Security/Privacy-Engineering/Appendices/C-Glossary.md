# Appendix C: Glossary of Privacy & Security Terms

---

### Comprehensive Glossary

This glossary explains all the key terms used throughout the **Privacy by Design: Engineering the Default** series in beginner-friendly language with real-world analogies.

---

#### Core Privacy Concepts

**Privacy by Design**  
Building privacy into the architecture from day one, rather than adding it later as a patch.  
*Analogy*: Installing good locks while building the house instead of adding them after someone moves in.

**Data Minimization**  
Collecting and storing only the minimum amount of personal data necessary for a specific purpose.  
*Example*: Storing only a mood score (1-10) instead of full personal details unless required.

**Special Category Data** (GDPR Article 9)  
Highly sensitive data such as health, biometric, or religious information that requires extra protection.  
*In this project*: Mental health notes and journal entries.

**Data Protection Impact Assessment (DPIA)**  
A living document that inventories all personal data, identifies risks, and records how those risks are mitigated.  
*Our version*: The `docs/DPIA.md` file that grows with the project.

**Right to be Forgotten (Right to Erasure)**  
The user’s right to have their personal data deleted across all systems.  
*Implemented in*: Part 5 deletion orchestrator.

**DSAR (Data Subject Access Request)**  
The right to receive a copy of all personal data held about you.  
*Implemented in*: Part 5 export engine with ZIP + manifest.

---

#### Technical & Cryptography Terms

**Envelope Encryption**  
A two-layer encryption technique: data is encrypted with a Data Encryption Key (DEK), which is then encrypted with a Key Encryption Key (KEK) stored in a Hardware Security Module (HSM).  
*Used in*: `lib/encryption.ts` with Google Cloud KMS.

**AES-256-GCM**  
A strong, modern encryption algorithm that provides both confidentiality and tamper detection (via authentication tag).  
*Used for*: All health data in this project.

**Bytea**  
PostgreSQL data type for binary data. Perfect for storing encrypted information because the database cannot interpret it as readable text.

**Zero-Trust Architecture**  
Never trust any user, device, or system by default — always verify every access request.  
*Implemented via*: `PolicyEngine` class.

**Append-Only Ledger**  
A database table where records are never updated or deleted — only new records are added. Current state is derived from the latest record.  
*Used for*: Consent management.

**HMAC (Hash-based Message Authentication Code)**  
A one-way cryptographic hash function used to pseudonymize data (e.g., IP addresses) while allowing consistency checks.  
*Used in*: `privacy-utils.ts`

**PII (Personally Identifiable Information)**  
Any data that can be used to identify an individual.  
*Our scanner*: Automatically flags potential PII in schema files.

---

#### Compliance & Operational Terms

**STRIDE Threat Model**  
A framework for identifying security threats:  
- **S**poofing  
- **T**ampering  
- **R**epudiation  
- **I**nformation Disclosure  
- **D**enial of Service  
- **E**levation of Privilege

**Fail-Closed**  
Default behavior is to deny access if the system cannot make a clear decision.  
*Opposite of*: Fail-open (dangerous for privacy).

**Anti-Dark Pattern**  
Design choices that avoid tricking users into giving more consent than intended (e.g., equally prominent Allow/Don’t Allow buttons).

**Schrems II**  
EU court ruling requiring additional safeguards for data transfers to countries without adequate protection (e.g., US).  
*Addressed via*: Proper vendor DPAs and encryption.

---

#### Tools & Libraries Glossary

- **Clerk**: Authentication-as-a-service platform.
- **Neon**: Serverless PostgreSQL with database branching.
- **Inngest**: Durable background job system with automatic retries.
- **Zod**: TypeScript-first schema validation library.
- **Upstash Redis**: Serverless Redis for rate limiting and caching.

---

**Appendix C Complete**
