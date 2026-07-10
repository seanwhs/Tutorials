## Appendix D — Sample Artifacts

This appendix gives you copy-ready sample artifacts for the Red Horizon exercise. They are written to feel realistic enough for facilitation, but generic enough to stay safe and reusable.

### 1. Simulated SIEM alert

Use this as a chat message, ticket note, or screenshot text.

```markdown
[TTX-EXERCISE] SIEM Alert: Suspicious Login Pattern

Alert ID: SIEM-2026-041
Source: Vendor VPN Gateway
Severity: High
Time Detected: 2026-07-11 09:05
Description: Multiple failed login attempts followed by a successful login from an unusual geography. Session duration and access pattern are inconsistent with normal vendor activity.
Associated Indicators:
- Impossible travel
- New device fingerprint
- Access to internal admin subnet
- Follow-up network scan activity
Recommended Action:
- Triage immediately
- Correlate with vendor identity records
- Escalate to IR if confirmed suspicious
```

### 2. Mock help-desk transcript

This is useful as a voice inject or a pasted note in the room.

```markdown
[TTX-EXERCISE] Help Desk Call Log

Caller: "Hi, this is from one of your vendors. Someone from IT called earlier and asked me to install remote access software. I just want to verify that’s normal."

Agent Notes:
- Caller sounded unsure but calm.
- No ticket reference provided.
- Request appears connected to vendor support activity.
- Verified callback number does not match known vendor contact record.
Suggested Action:
- Record the call
- Verify through approved vendor contact channels
- Escalate if tied to active compromise indicators
```

### 3. Executive status note

This works well once the incident becomes business-relevant.

```markdown
[TTX-EXERCISE] Executive Update Draft

Subject: Potential Vendor-Origin Security Incident

Current Status:
We are investigating a suspicious vendor access event that may be linked to broader unauthorized activity. At this time, we have not confirmed business impact, but the pattern suggests a credible risk to internal systems.

What We Know:
- Unusual vendor login behavior was detected.
- Follow-up activity suggests internal exploration.
- Security and IT are correlating alerts and validating scope.

What We Are Doing:
- Confirming identity and access history.
- Reviewing affected systems.
- Preparing containment options if the incident is confirmed.

Decision Needed:
- Whether to activate cross-functional incident response leadership now or wait for additional evidence.
```

### 4. Journalist inquiry email

Use this later in the exercise to test external communications pressure.

```markdown
[TTX-EXERCISE] External Inquiry

Subject: Urgent comment requested regarding reported manufacturing disruption

Hello,

We are hearing reports that your company may be dealing with a cybersecurity incident affecting production operations. Can you confirm whether customer data, operational systems, or vendor access were impacted?

Please provide a response by 3:00 PM today.

Regards,
Reporter Name
News Outlet
```

### 5. Ransom note sample

Keep it short and non-graphic. The goal is pressure, not spectacle.

```markdown
[TTX-EXERCISE] Ransom Note

Your files have been encrypted.
Your network has been compromised through a trusted access path.
Do not attempt recovery without contacting us.
We have copied selected data and will begin release if you do not respond.

Next steps are under your control.
```

### 6. Backup integrity alert

This is a useful late-stage inject for testing recovery confidence.

```markdown
[TTX-EXERCISE] Backup Verification Alert

System: Backup Monitoring
Status: Partial anomaly detected
Description: Last successful backup exists, but immutable snapshot verification has not been completed for the affected system set.
Risk:
- Recovery confidence cannot be fully confirmed yet.
Action:
- Verify backup integrity
- Confirm restore readiness
- Report to incident leadership
```

### 7. Vendor account confirmation message

This helps test whether the team trusts the vendor too quickly.

```markdown
[TTX-EXERCISE] Vendor Response

Hello,

We checked our logs and found suspicious activity on one of our support accounts. We are investigating on our side.

Please advise if you observed any unusual behavior from our VPN access or shared systems.

Regards,
Vendor Security Contact
```

### 8. Internal scan alert

This works as a bridge between initial access and broader compromise.

```markdown
[TTX-EXERCISE] Network Alert

Alert ID: NDR-2026-117
Source: Internal Monitoring
Description: Unusual internal scanning behavior observed from a host associated with vendor-access activity. Repeated service enumeration attempts were detected across adjacent subnets.
Recommended Action:
- Correlate with authentication events
- Verify asset ownership
- Escalate if behavior persists
```

## Appendix E — Glossary

This glossary keeps the series consistent and makes the notes easier to reuse across exercises.

### A

**AAR**  
After-Action Review. The structured review that turns exercise observations into findings, owners, and improvement actions.

**ATT&CK**  
MITRE ATT&CK, a knowledge base of adversary tactics and techniques used to map realistic threat behavior.

### C

**Containment**  
Actions taken to limit further impact from an incident, such as isolating systems, disabling access, or segmenting traffic.

### E

**Exercise Level**  
The maturity or depth of the exercise, from discussion-based to full-scale.

### H

**Hot-wash**  
An immediate informal review right after the exercise while memories are still fresh.

### I

**Inject**  
A controlled event or piece of information introduced during the exercise to force a decision or response.

**IRP**  
Incident Response Plan.

### L

**L1 / L2 / L3 / L4**  
Exercise maturity levels:
- L1: Discussion-based.
- L2: Facilitated table read.
- L3: Operations-based.
- L4: Full-scale.

### M

**MSEL**  
Master Scenario Events List. The facilitator’s timeline and script for the exercise.

### P

**PAUSE / STOP**  
Authority to temporarily halt or fully end the exercise if the situation requires it.

### R

**RoE**  
Rules of Engagement. The document that defines scope, boundaries, safety, and communication norms for the exercise.

### S

**Scenario**  
The fictional but realistic incident narrative that the exercise is built around.

**Scribe**  
The person responsible for capturing actions, decisions, and timestamps during the exercise.

### T

**Tabletop Exercise (TTX)**  
A discussion-based exercise where participants walk through a scenario and decide how they would respond.

### W

**White Cell**  
The small planning group that holds scenario truth, manages pacing, and answers hard questions consistently.

## Appendix F — Quick Inject Cookbook

This appendix gives you reusable inject ideas that can be adapted to many scenarios.

### Identity and access injects
- Impossible travel login.
- MFA fatigue pattern.
- Vendor account misuse.
- Privileged group membership change.
- Unusual access from a trusted location.

### Discovery injects
- Internal scan activity.
- Unexpected admin console access.
- Service enumeration on sensitive subnets.
- Endpoint process alert tied to admin tooling.

### Communications injects
- Help-desk verification call.
- Executive phone call.
- Vendor security inquiry.
- Journalist request.
- Customer complaint about service disruption.

### Impact injects
- Ransom note.
- Backup integrity warning.
- File share encryption alert.
- Production slowdown notification.
- Cloud workload interruption.

### Recovery injects
- Restore test failure.
- Immutable backup uncertainty.
- Missing admin credentials.
- Delayed decision on system rejoin.
- Conflict between business urgency and verification.

## Appendix G — Full Example Package

This appendix should hold your complete cloneable reference case for ACME Red Horizon.

### Suggested contents
- Final RoE.
- Final scenario note.
- Full MSEL.
- Participant list.
- Observer log examples.
- Hot-wash notes.
- Final AAR.
- Roadmap summary.

### Suggested file structure
```text
99-Appendices/
  case-studies/
    acme-red-horizon/
      roe.md
      scenario.md
      msel.md
      participants.md
      observer-log-example.md
      hot-wash-notes.md
      aar.md
      roadmap.md
```

### Why this matters
A full worked example makes the series easier to teach, easier to reuse, and easier to adapt for clients. It also gives you a canonical “gold standard” package you can compare future exercises against.

## Final Roadmap

At this point, your series is complete in structure:

- Part 0 introduces the program.
- Part 1 establishes maturity and RoE.
- Part 2 builds the threat model and scenario.
- Part 3 prepares the exercise.
- Part 4 designs the inject engine and MSEL.
- Part 5 runs the live session.
- Part 6 sharpens facilitation.
- Part 7 converts logs into a roadmap.
- Part 8 institutionalizes the program.
- Appendices provide reusable templates, artifacts, and reference material.

The best next step is to turn this into a polished document set in your vault, then run one dry-run tabletop using the templates exactly as written before customizing for a real client or internal team.
