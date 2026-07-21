# Part 7: Incident Response & Operations

---

### Why We Need This
Even the best systems can have incidents. Preparation turns potential disasters into manageable events.

---

#### Step 7.1: The Target — Incident Response Playbook

**Implementation** — Create **`docs/INCIDENT_RESPONSE.md`**:

```markdown
# MindfulLog Incident Response Playbook

## Severity Levels
- **SEV-1 (Critical)**: Unencrypted health data exposed
- **SEV-2**: Encrypted data potentially compromised
- **SEV-3**: Policy violation or near-miss

## Response Process
1. **Identify** (0-15 min) — Confirm incident via logs/scanner
2. **Contain** (15-60 min) — Revoke sessions, disable affected features
3. **Eradicate** — Rotate KMS keys, delete compromised records
4. **Recover** — Restore from backups, notify users if required
5. **Lessons Learned** — Update DPIA, scanner rules, and code

## Key Rotation
- Rotate KEK yearly via Google Cloud KMS
- DEKs are per-field and ephemeral (already implemented)
```

---

#### 7.2: Final Project Verification Checklist

Run these commands:

```bash
npm run privacy:scan
npm run build
node -e 'import("./lib/db.js").then(m => m.testDatabaseConnection())'
```

**Manual Tests**:
- Create mood log with notes → Confirm encrypted in DB
- Toggle consents → Check ledger
- Trigger export → Valid ZIP
- Simulate deletion → Data removed safely

Deploy it, extend it, and be proud of the privacy engineering mindset you've developed.

**Thank you for following the entire series.**  
You are now equipped to build privacy by design into every future project.
