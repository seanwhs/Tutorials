Appendices and Template Pack — Expanded (only this part)

Below is a complete, copy-paste-ready appendix and templates pack designed to live in your Obsidian vault. Each template is written as Markdown-ready content with guidance comments you can remove. Use these as the canonical artifacts for every exercise you run; they’re intentionally practical and minimal so they’re easy to adapt and reuse.

# Folder suggestion: 99-Appendices/

# Appendix A — TTX Toolkit (short reference)
- Purpose: quick guidance on what tools to use for each activity and why.
- Files: `99-Appendices/toolkit.md`

Contents (paste into `toolkit.md`):
```markdown
# TTX Toolkit — Quick Reference

Guiding principle: prefer free/OSS or easily auditable tools so artifacts are portable.

Diagrams
- Excalidraw: best for quick attack-flow diagrams and collaborative drawing during prep.
- Output: PNG / SVG to attach to Obsidian notes.

Knowledge base
- Obsidian (Markdown): single source of truth for RoE, scenarios, MSELs, AARs, and roadmaps.
- Store everything in a well-organized folder structure and version-control if possible.

Live sessions
- Jitsi / BigBlueButton: free/OSS video + breakout rooms.
- Use Jitsi/BBB for audio, screenshare, and breakout coordination.

Chat / Comms
- Use dedicated rooms or channels for exercise traffic; always tag messages with `[TTX-EXERCISE]`.

Artifact generation
- Use sanitized screenshots from your SIEM/EDR or generated images that look real but contain no PII.
- Keep two versions (clean / noisy) of key artifacts for pacing flexibility.

Guidance
- Follow documented RoE always.
- Keep white cell answers consistent.
- Observers log silently.
```

Appendix B — Templates Library (core templates)
- Purpose: ready-to-use Markdown templates for RoE, scenario, MSEL, incident log, AAR, participant invite, and facilitator checklist.
- Files: `99-Appendices/templates/roE-template.md`, `scenario-template.md`, `msel-template.md`, `observer-log-template.md`, `aar-template.md`, `participant-invite-template.md`, `facilitator-checklist.md`

RoE template (paste into `roE-template.md`):
```markdown
# Rules of Engagement — [Scenario Name]

## Metadata
exercise_name: [Scenario Name]
version: 0.1
owner: [IR Lead]
approved_by: [Sponsor]
maturity_level: L2
date: [YYYY-MM-DD]

## Purpose
Short statement of exercise purpose and specific objectives.

## Scope & Boundaries
### In scope
- List teams, systems, processes.
### Out of scope
- List exclusions (no production changes, no regulator notification, etc.)

## No-Blame Clause
- State that the exercise is for learning and process improvement only.

## STOP / PAUSE Authority
- Names & rules for pause and stop.
- Triggers for pause/stop (real incident discovered, emotional distress, scope breach).

## Artifact Handling
- Sanitization rules.
- No production logins.
- Tagging conventions (e.g., `[TTX-EXERCISE]`).

## Communication Rules
- Channels for exercise traffic.
- Email subject prefix and chat channel naming.

## Roles & Responsibilities
- Lead Facilitator:
- White Cell:
- Scribe:
- Observers:
- Participants:

## Deliverables & Use of Findings
- How AAR findings are handled, who owns them, and where they are tracked.

## Version History
- v0.1 — Draft
```

Scenario template (`scenario-template.md`):
```markdown
# Scenario — [Short scenario title]

## Summary
One-paragraph summary.

## Why this scenario
- Threat context and business relevance.

## Attack chain (narrative)
- Steps in the adversary chain.

## Business Impact
- What business processes/systems could be affected.

## Assumptions
- What is taken as given for the exercise.

## Success Criteria
- What constitutes a useful run.

## Key Tensions / Decision Points
- Speed vs confirmation, containment vs continuity, etc.

## ATT&CK Mapping
- A short list of relevant ATT&CK technique IDs (optional).
```

MSEL template (`msel-template.md`):
```markdown
# MSEL — [Scenario Name]

## Session goal
Short statement.

## Media / Delivery rules
- Channel mapping (chat, email, voice, doc).

## Inject table
| Time | Inject ID | Inject content (what participants see) | Channel | Expected Response | ATT&CK Theme | Variance / Actual |
|------|-----------|-----------------------------------------|---------|-------------------|--------------|-------------------|
| T+00:05 | INJ-01 | Short text describing artifact | Chat | Bullet expected actions | T1078 | |
```

Observer log template (`observer-log-template.md`):
```markdown
# Observer Log — [Exercise Name] — [Observer Name]

## Instructions
- Observe silently, timestamp everything, capture assumptions and quotes verbatim when possible.
- Do not intervene.

## Log
| Timestamp | Actor | Action / Quote | Assumptions noted | Impact |
|-----------|-------|----------------|-------------------|--------|
| T+00:05 | SOC | "Looks like a false positive" | Assumed single-source noise | Missed early correlation |
```

AAR template (`aar-template.md`):
```markdown
# After Action Review — [Scenario Name]

## Exercise Summary
- Date:
- Participants:
- Maturity level:
- Duration:

## Narrative
- Short timeline summary.

## Key Observations
- Bulleted list of facts (not judgments).

## Findings
### F-01: Short title
- Observation:
- Finding:
- Category: Policy/Execution/Tooling/Communication/Governance
- Severity: High/Medium/Low
- Owner:
- Due date:
- Validation method:

## Roadmap
- Prioritized actions with owners and dates.

## Lessons Learned
- Practical suggestions for next exercises or improvements.
```

Participant invite / brief template (`participant-invite-template.md`):
```markdown
# Participant Invite — [Exercise Name]

Hello [Name],

You are invited to participate in a tabletop exercise: [Name]. Purpose: [short]. Duration: [X hrs]. Maturity level: [L1|L2|L3|L4]. Location: [Jitsi/BBB link] Date/Time: [YYYY-MM-DD].

Please review these materials beforehand:
- RoE: [link]
- Scenario summary (brief)
- Observer expectations (if applicable)

Respect the no-blame policy. Tag all exercise communications with `[TTX-EXERCISE]`.

Thanks,
[Facilitator]
```

Facilitator checklist (`facilitator-checklist.md`):
```markdown
# Facilitator Checklist — [Exercise Name]

## T-14 days
- Confirm sponsor and objectives.
- Draft RoE and scenario.
- Assemble white cell.

## T-7 days
- Finalize MSEL and artifacts.
- Confirm participants.
- Prepare observer templates.

## T-1 day
- Rehearse white cell.
- Test rooms and audio/video.
- Ensure artifact access and sanitization.

## Day-of
- Open with RoE and pause rules.
- Deliver injects per MSEL.
- Use 2-minute stall rule.
- Capture hot-wash.

## T+1 day
- Collect logs and hot-wash notes.
- Draft initial AAR.

## T+5 days
- Present formal AAR with findings and roadmap.
```

Appendix C — Facilitator’s Checklist (expanded)
- Purpose: step-by-step timeline with exact owner prompts and checkboxes.
- File: `99-Appendices/facilitator-checklist-expanded.md` (use the text above but with owner placeholders and checkboxes).

Appendix D — Sample Artifacts
- Purpose: examples you can adapt (sanitized SIEM screenshot text, mock ransom note, mock journalist inquiry, fake help-desk transcript).
- File: `99-Appendices/sample-artifacts/`
  - `siem-screenshot-example.md` (include redacted imagery guidance)
  - `ransom-note-sample.md`
  - `journalist-email-sample.md`
  - `helpdesk-call-script.md`
- Note: Do NOT keep real sensitive data. Keep samples synthetic.

Appendix E — Glossary
- Purpose: define exercise-specific terms (MSEL, White Cell, Hot-wash, AAR, RoE).
- File: `99-Appendices/glossary.md`

Appendix F — Quick Inject Cookbook (optional)
- Purpose: a library of injects (by theme) you can reuse and adapt.
- File: `99-Appendices/inject-cookbook.md`
- Content examples: login anomaly, vendor help call, privilege change notice, backup integrity alert, ransom note, executive phone call, press inquiry.

Appendix G — Example Complete Exercise (ACME Red Horizon)
- Purpose: keep a fully worked example of Operation Red Horizon that teams can clone.
- File: `99-Appendices/case-studies/acme-red-horizon.md`
- Include: RoE (final), Scenario, Full MSEL, All artifacts, Observer logs (redacted), AAR sample with findings and roadmap.

Quick implementation notes
- Keep templates small and modular; use links between notes rather than duplicating content.
- Version-control the vault (private Git repo) for history and auditability.
- Use consistent tagging (`tag:ttx`, `tag:aar`, `tag:msel`) so you can query across the vault.

Conclusion and next step
- These appendices and templates are intended to be the last chunk you install in your vault before running a real exercise. They provide a repeatable, auditable structure that maps to NIST- and CISA-style guidance while being tailored for Obsidian/Markdown-first workflows.
