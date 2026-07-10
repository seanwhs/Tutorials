# Secure by Design — Part 7: Monitoring & Incident Response

## 1. Concept & Architecture Rationale

### You cannot respond to what you cannot see

Every control built in Parts 1–6 reduces the probability of a breach; none reduce it to zero. The architectural humility required at this stage: assume breach, and design for fast, confident detection and response. This is the difference between an organization that discovers a breach from a customer's tweet three months later, and one that contains it within hours because the system was built to tell them.

### Observability, reframed for security (not just performance)

Traditional observability (metrics, logs, traces) is usually built for debugging performance issues. Security observability asks different questions of the same data: not "why is this slow" but "is this normal, and if not, who should know right now?" This requires the audit-event discipline introduced in Part 2 (every authz decision logged) to be extended system-wide.

### The three pillars of security monitoring

- **Centralized logging**: every service's logs — application, authz decisions (Part 2), CI/CD pipeline events (Part 5), network policy denials (Part 6) — land in one searchable place. A security event is only useful if it can be correlated with events from other layers within seconds.
- **Audit trails**: an immutable, tamper-evident record of who did what, when — specifically built to answer the Repudiation question from Part 1's STRIDE model.
- **Automated alerting**: the gap between "the data exists somewhere" and "a human was notified in time to act" is where most real-world incident response fails; alerting rules must be written *before* the incident, based on the threat model from Part 1, not improvised during one.

## 2. Implementation

### Step 1 — Centralize logs with a free, open-source stack

**Grafana Loki** (free, open-source, lightweight) paired with **Grafana** for visualization, or the heavier but more powerful **OpenSearch** (free, open-source Elasticsearch fork maintained after the Elastic license change) with its bundled dashboards, both provide a fully free centralized logging pipeline. Ship logs from every layer — application server, database (Postgres `log_statement` for DDL/permission changes at minimum), CI/CD (Part 5's workflow run logs), and network policy deny events (Part 6) — using **Vector** or **Fluent Bit** (both free, open-source, lightweight log shippers) as the collection agent running as a sidecar or daemonset.

### Step 2 — Structure every log line as a security-parseable event

Unstructured text logs are nearly useless for automated detection. Every log line should be structured JSON with, at minimum: `timestamp`, `service`, `event_type`, `severity`, `actor` (user/service identity), `action`, `resource`, `result` (success/failure/denied), and `request_id` (to correlate a single request across every service it touched — critical in a microservice architecture, and directly enabled by the service identity work from Part 6). This is the same structured-audit-log pattern introduced for authz events in Part 2, now applied universally.

### Step 3 — Build a "Security Events" index/dashboard distinct from general application logs

Rather than hunting for security-relevant signal inside general-purpose logs, explicitly tag and route a subset of events to a dedicated security stream: failed authentication attempts, authorization denials (Part 2), Semgrep/Trivy/Dependency-Track findings surfaced in CI (Parts 3 and 5), network policy denials (Part 6), secret-scanning hits (Trufflehog, Part 4), admin-privilege actions (role changes, permission grants), and data export/bulk-read events (a common exfiltration pattern). A Grafana dashboard built specifically against this stream becomes your team's daily security cockpit, distinct from the performance dashboards engineers already watch.

### Step 4 — Automated alerting rules mapped directly to your STRIDE threat model

This is the step that closes the loop all the way back to Part 1: for every threat identified in your threat model, write a corresponding detection rule. Concrete examples, expressed as alerting logic rather than a specific tool's exact syntax (implementable in Grafana Alerting, free and built into the Grafana stack, or in the free-tier of **Wazuh**, a full open-source SIEM):

- **Spoofing indicator**: more than N failed login attempts for a single account within 5 minutes, from more than 2 distinct IP addresses — suggests credential stuffing, not a user who simply forgot their password.
- **Elevation-of-Privilege indicator**: a spike in `authz_check` events with `result: denied` for a single actor within a short window (directly consuming the Part 2 audit log) — a strong signal of an active privilege-escalation probing attempt.
- **Tampering indicator**: any write to the `role_permissions` table (Part 2) or any change to branch protection rules (Part 1) outside of a reviewed, signed-commit PR — GitHub's audit log API can be polled for exactly this and piped into your centralized log stream.
- **Information Disclosure indicator**: a single actor reading an anomalously high volume of customer records in a short window compared to their historical baseline — a classic insider-threat or compromised-credential exfiltration pattern.
- **Denial-of-Service indicator**: request rate to a single endpoint exceeding a rolling baseline by a wide margin, correlated with the egress-denial events from Part 6's network policies (a compromised internal service attempting to call out is itself a DoS-adjacent signal worth alerting on).

### Step 5 — Wazuh as a free, complete open-source SIEM (if you want more than "logging + alerting")

For teams wanting integrated SIEM/SOAR capability without a paid product, **Wazuh** (fully free and open-source) provides file integrity monitoring, log analysis, vulnerability detection (overlapping usefully with Part 3/5's scanning), and active response (automated containment actions, like temporarily blocking an IP after repeated failed logins) in a single deployable agent+manager architecture — genuinely the closest free equivalent to a commercial SIEM/SOAR platform named in the syllabus.

### Step 6 — Runtime intrusion detection with Falco (free, open-source, CNCF)

For containerized environments specifically, **Falco** monitors kernel-level syscalls in real time and alerts on anomalous runtime behavior a static scan could never catch: a shell spawned unexpectedly inside a container that should never spawn a shell, a process attempting to read `/etc/shadow`, an unexpected outbound connection from a process that has no legitimate reason to make one. This is the runtime complement to Part 5's build-time Trivy scanning — Trivy tells you what *could* go wrong before deploy; Falco tells you what *is* going wrong right now, in production.

### Step 7 — Automated response, not just automated alerting (the "SOAR" half)

An alert that pages a human at 3am to manually revoke a token is slower than the attacker. Where safe to automate, wire specific high-confidence alerts directly to a response action: repeated-failed-login detection triggers automatic temporary account lockout via your Part 2 identity system's API; a Trufflehog CI hit on a verified live credential triggers an automatic call to revoke that specific credential via the relevant provider's API in the same pipeline run, before a human even sees the alert. Reserve human-in-the-loop response for ambiguous, high-blast-radius decisions (Part 5's required-reviewer Environment pattern is the same philosophy applied here); automate the unambiguous, time-critical ones.

## 3. Exercise Challenge

1. Stand up Grafana + Loki (or OpenSearch) locally via Docker Compose and ship structured JSON logs from at least one service.
2. Extend the Part 2 `authz_check` audit event pattern to at least 3 more event types across your system (auth success/failure, admin action, data export).
3. Write one alerting rule directly derived from a specific STRIDE finding in your Part 1 threat model — name the threat category explicitly in the alert's description.
4. Identify one high-confidence, low-ambiguity alert (e.g., repeated failed logins) and design (even if you don't fully implement) an automated containment response for it.

## 4. Solution & Explanation

Applied end to end on the QB Clone architecture: Vector ships structured logs from the Next.js app, the Inngest background workers, and Postgres's statement log into Loki; a dedicated Grafana "Security Events" dashboard filters on `event_type IN (authz_check, auth_attempt, admin_action, export)`; an alert rule fires when `authz_check.result = denied` exceeds 5 occurrences for one `actor` in 10 minutes, explicitly labeled in its description as "STRIDE: Elevation of Privilege — see threat-model.json"; and a second alert on repeated login failures triggers an automated, temporary account lockout via a Clerk API call, with the lockout itself logged as its own audit event (closing the Repudiation loop — even the automated response is attributable and reviewable after the fact).

Why this matters architecturally: the traceability from a specific Part 1 STRIDE row, to a Part 2 audit event schema, to a Part 7 alert rule, to a Part 7 automated response, is the entire point of "Secure by Design" as a discipline — security isn't a separate monitoring bolt-on, it's the same threat model, implemented consistently, all the way from whiteboard to production alert.

## 5. Key Takeaways

- Security observability asks "is this normal, and who should know right now" — not just "why is this slow."
- Structure every log as a security-parseable event (actor, action, resource, result, request_id) from day one; retrofitting this later is far more painful.
- Every alerting rule should trace back to a specific, named threat in your STRIDE model — this keeps alerting focused and explainable rather than noisy.
- Falco (runtime) and Trivy (build-time) are complementary, not redundant, exactly like WAF-vs-app-validation in Part 6.
- Automate response only for high-confidence, low-ambiguity signals; keep humans in the loop for anything with real blast radius or ambiguity.

Next: Part 8 — The Security Audit, where we self-assess the entire architecture built across Parts 1–7 using the C4 model and OSA (Open Security Architecture) patterns to find the gaps that remain.

