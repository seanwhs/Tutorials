# Part 7: Incident Response & Operations

#### Step 7.1: The Target — Incident Response Playbook

**The Concept**:  
Prepare for the worst before it happens. Clear severity levels and responsibilities.

**Implementation** — `docs/INCIDENT_RESPONSE.md`:

```markdown
# MindfulLog Incident Response Playbook

## Severity Levels
- **SEV-1 (Critical)**: Plaintext health data exposed → Notify users + regulators within 72h (GDPR)
- **SEV-2**: Potential breach of encrypted data
- **SEV-3**: Near-miss or policy violation

## Response Steps
1. **Detect** → Monitoring alerts (logs, KMS failures)
2. **Contain** → Revoke sessions, rotate keys
3. **Eradicate** → Delete compromised data
4. **Recover** → Restore from encrypted backups
5. **Post-Mortem** → Update DPIA + scanner rules

## Key Rotation Strategy
- Rotate KEK annually via Google Cloud KMS versioning
- New DEKs per encryption operation (already implemented)
```

---

#### Step 7.2: The Target — Backup & Retention Policies

**Implementation** (in Neon + scripts):
- Backups encrypted separately from DEKs.
- Table-specific retention (e.g., mood logs: 7 years max unless consented longer).

---

#### 7.3: Final Project Verification

Run these commands:

```bash
npm run build
npm run privacy:scan
node -e 'import("./lib/db.js").then(m => m.testConnection())'
```

**Manual Checks**:
1. Insert journal entry → Confirm `content_encrypted` is binary in DB.
2. Attempt unauthorized access → Policy engine denies.
3. Trigger export → Receive valid ZIP.
4. Delete account → All traces removed or anonymized.

**What You Have Built**:
- Living DPIA
- Encrypted, minimized schema
- Envelope encryption library
- Centralized policy engine
- Append-only consent system
- DSAR + Deletion pipelines
- Privacy CI/CD
- Full incident playbook

---

**[COMPLETED: Part 7]**  
**[SERIES COMPLETE — Privacy by Design: Engineering the Default]**

**Congratulations!** You have built a real, production-grade privacy-first application. The safe behavior is now the *only* behavior the code allows.

### Next Steps for You
1. Deploy to Vercel + connect Neon.
2. Add your own features using the same patterns.
3. Audit and open-source parts of it.
4. Teach others — the industry desperately needs this mindset.

The complete project exists in the working environment with all files implemented step-by-step as described.

You are now a privacy engineer.

**Thank you for completing the full series.**  
