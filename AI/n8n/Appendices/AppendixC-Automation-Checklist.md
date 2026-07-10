## Appendix C: Automation Checklist — Migrating Local Dev to Production

A step-by-step guide for taking a workflow built and tested on your local `docker-compose.yml` (Part 1) and safely running it on a production VPS (Part 8). Work through this checklist for every workflow before it goes live, and re-run the "Pre-Deploy" section for every subsequent change.

### C.1 Design-Time Checklist (Before You Build)
- [ ] Confirmed which trigger family fits (Webhook / Cron / Poll) — Part 2.1
- [ ] Identified whether this workflow needs idempotency — Part 2.2/2.4
- [ ] Identified whether this workflow has side effects that must be audited — Part 4.2 (`audit_log`)
- [ ] Decided the Code node language (JS default; Python only with a specific reason) — Part 3.6

### C.2 Build-Time Checklist
- [ ] All external-input nodes (Webhook) have authentication configured — never `authentication: none`
- [ ] All Code nodes guard against missing/malformed fields — Part 3.3
- [ ] All Postgres queries use parameterized placeholders (`$1, $2`), never string-interpolated user input — Part 4.5
- [ ] Credentials are referenced by name, never hardcoded — Part 7.2, Appendix B.2
- [ ] Least-privilege DB role is used, not a superuser — Part 4.4
- [ ] Node-level Retry On Fail is configured deliberately — Part 6.2
- [ ] Continue On Fail + dead-letter routing in place for batch-processing nodes — Part 6.4

### C.3 Pre-Deploy (Local Validation) Checklist
- [ ] Workflow tested against pinned sample data, including a deliberately malformed item — Part 3.8
- [ ] Error Workflow is attached in this workflow's Settings — Part 6.3
- [ ] Workflow exported via `n8n export:workflow` and diffed against the previous committed version — Part 7.2
- [ ] `node scripts/validate-workflows.js` passes locally — Part 7.5
- [ ] PR opened using the standard template; CI (`validate-on-pr.yml`) is green — Part 7.6, 7.9

### C.4 Environment Parity Checklist
- [ ] Every credential name referenced exists in the target environment under the exact same name — Part 7.8
- [ ] `.env` values for the target environment come from a secrets manager or GitHub Actions secrets, never copy-pasted from local `.env` — Part 1.5, Part 8
- [ ] `N8N_ENCRYPTION_KEY` for production is distinct, securely generated — never the same key as local/dev — Part 1.5
- [ ] Target Postgres has the required schema applied (`sql/00X_*.sql`) — Appendix A.2

### C.5 Deploy Checklist
- [ ] Merge to `main` triggers `deploy-on-merge.yml`, or manually run `scripts/import-all.sh` — Part 7.7
- [ ] Confirm the workflow is present and **active** on the target instance (common mistake: it stays deactivated)
- [ ] Send one real/synthetic test event and confirm it appears in `execution_entity` with status `success`
- [ ] Confirm a row was written to `audit_log` with the correct `execution_id` — Part 4.6
- [ ] Force one deliberate failure and confirm it lands in `error_log`, and any critical-severity alert fires — Part 6.3, 6.8

### C.6 Production Scaling Readiness Checklist (Queue Mode Specific)
- [ ] `EXECUTIONS_MODE=queue` set on both `n8n-main` and every `n8n-worker-N` — Part 8.3
- [ ] Postgres and Redis have no published ports to the public internet — Part 8.7
- [ ] Caddy is serving a valid TLS certificate on the production domain — Part 8.3.4
- [ ] At least one additional worker replica exists for redundancy — Part 8.5
- [ ] `N8N_CORS_ALLOWED_ORIGINS` set explicitly if browser-origin calls are expected — Part 8.8

### C.7 Post-Deploy Monitoring Checklist (First 24–48 Hours)
- [ ] Watch `error_log` error rate by workflow — Part 6.6
- [ ] Watch `dead_letter_queue` backlog — a growing backlog means a systemic issue
- [ ] Confirm `EXECUTIONS_DATA_PRUNE`/`EXECUTIONS_DATA_MAX_AGE` keep `execution_entity` bounded — Part 1.5/1.8
- [ ] Confirm Redis queue depth returns to baseline between traffic bursts — Part 8.5

### C.8 Rollback Checklist
- [ ] Previous workflow JSON version is retrievable from Git history
- [ ] Rollback = `git checkout <previous-commit> -- workflows/export/<file>.json` + `scripts/import-all.sh`
- [ ] Deactivate (don't delete) a misbehaving workflow first if full rollback isn't ready
- [ ] Postgres schema changes are additive-only (Appendix A.2) so a workflow rollback never requires a schema rollback

### C.9 One-Page Summary

```
DESIGN  → BUILD → VALIDATE LOCALLY → PR + CI → ENVIRONMENT PARITY CHECK
   → DEPLOY → SMOKE TEST → FORCE-FAILURE TEST → MONITOR 24-48H → (rollback plan always ready)
```

Treat this checklist as a literal PR/deploy gate, not aspirational guidance — every workflow shipped through Parts 2–8 should check every box before it's production-ready.
