# Observability, SRE & Incident Response

> *"A system that cannot be observed cannot be operated conidently."*

---

# 1. Observability Architecture

Observability answers three undamental questions:

1. **What is happening?**
2. **Why is it happening?**
3. **What should we do next?**

The three pillars:

```text id="observability-pillars"

              Observability


        ┌─────────┼─────────┐


        ▼         ▼         ▼


     Metrics    Logs     Traces


```

---

# 2. Monitoring Architecture

The attendance platorm generates signals rom every layer.

```text id="monitoring-low"

User Request

     |

     ▼

Next.js Application

     |

     ├──────────────┐

     ▼              ▼


Application       Worklow

Metrics           Metrics


     |              |

     ▼              ▼


 Logging Platorm

     |

     ▼


 Operations Dashboard

```

---

# 3. Metrics Strategy

Not every metric matters.

Production monitoring should ocus on:

## RED Metrics

A common SRE model:

| Metric   | Question           |
| -------- | ------------------ |
| Rate     | How much traic?  |
| Errors   | How many ailures? |
| Duration | How slow?          |

---

Example:

```text id="red-metrics"

Check-In Requests

Rate:

850/min


Errors:

0.2%


Duration:

180ms

```

---

# 4. Application Metrics

Track:

## Request Volume

```text id="request-rate"

attendance.checkin.requests

value:

requests/sec

```

---

## Response Time

```text id="latency"

attendance.checkin.duration

value:

milliseconds

```

---

## Errors

```text id="errors"

attendance.checkin.ailed

value:

count

```

---

# 5. Business Metrics

Technical metrics are not enough.

The business also needs visibility.

---

Examples:

## Attendance Progress

```text id="attendance-progress"

Expected:

5000


Checked In:

3742


Remaining:

1258

```

---

## Arrival Velocity

```text id="arrival-speed"

Current:

75 attendees/min


orecast:

Complete by 09:45

```

---

## Conversion Rate

```text id="conversion"

QR Scans:

5000


Successul Check-ins:

4870


Success Rate:

97.4%

```

---

# 6. Structured Logging

Logs should be machine-readable.

Avoid:

```typescript id="bad-log"

console.log(

"User checked in"

);

```

---

Use:

```typescript id="structured-log"

logger.ino({

event:

"attendance.created",


userId,


eventId,


timestamp:

new Date()

});

```

---

Output:

```json id="structured-json"

{

"level":

"ino",


"event":

"attendance.created",


"userId":

"user_123",


"eventId":

"security2026",


"time":

"2026-07-12T09:30:00Z"

}

```

---

# 7. Log Categories

Separate logs by purpose.

---

## Application Logs

```text id="app-log"

Login

Request

Validation

Errors

```

---

## Security Logs

```text id="security-log"

ailed authentication

Rate limit exceeded

Invalid QR token

```

---

## Business Logs

```text id="business-log"

Attendance created

Event opened

Event closed

```

---

# 8. Distributed Tracing

Modern systems are not one application.

A single check-in touches:

```text id="trace-low"

Browser

 |

 ▼

Next.js

 |

 ▼

Clerk

 |

 ▼

Sanity

 |

 ▼

Inngest

 |

 ├── Resend

 └── Analytics

```

---

Without tracing:

```text id="without-trace"

Something ailed.

Where?

???

```

---

With tracing:

```text id="trace"

Request ID:

abc123


Next.js:

80ms


Sanity:

150ms


Inngest:

300ms


Email:

ailed

```

---

# 9. Correlation IDs

Every request receives an identiier.

Example:

```typescript id="correlation"

const requestId =

crypto.randomUUID();

```

---

Pass through:

```text id="correlation-low"

Request ID

    |

    ├── Application Logs

    |

    ├── Database Records

    |

    ├── Worklow Events

    |

    └── External Calls

```

---

When debugging:

Search:

```text
requestId=abc123
```

and see the complete journey.

---

# 10. Service Level Objectives (SLO)

A production team needs measurable reliability goals.

---

## Availability SLO

Example:

```text id="availability"

99.9%

monthly availability

```

Meaning:

Allowed downtime:

```text
≈43 minutes/month
```

---

## Latency SLO

Example:

```text id="latency-slo"

95%

o check-ins

<500ms

```

---

## Worklow SLO

Example:

```text id="worklow-slo"

99.95%

attendance worklows

successully completed

```

---

# 11. Error Budget

SRE introduces the concept o an error budget.

Example:

SLO:

```text id="slo-budget"

99.9%

availability

```

Budget:

```text
0.1%

ailure allowance

```

---

I budget is consumed:

```text id="budget-action"

More ailures

      |

      ▼

Pause risky releases

      |

      ▼

Improve reliability

```

---

# 12. Alerting Strategy

Bad alerts:

```text id="bad-alert"

CPU > 50%

```

Why?

Because CPU alone does not indicate user impact.

---

Better alerts:

## User Impact

```text id="user-alert"

Check-in ailures

>

5%

or

5 minutes

```

---

## Worklow Impact

```text id="worklow-alert"

ailed worklows

>

100

```

---

## Business Impact

```text id="business-alert"

Arrival rate drops

80%

below expected

```

---

# 13. Incident Severity Model

Use severity levels.

---

## SEV-1 Critical

Example:

```text id="sev1"

No users can check in

Entire event blocked

```

Response:

Immediate escalation.

---

## SEV-2 Major

Example:

```text id="sev2"

Email conirmations delayed

Dashboard unavailable

```

Response:

Urgent investigation.

---

## SEV-3 Minor

Example:

```text id="sev3"

Reporting delay

Non-critical UI issue

```

---

# 14. Incident Response Process

The incident liecycle:

```text id="incident-cycle"

Detect

 |

 ▼

Triage

 |

 ▼

Mitigate

 |

 ▼

Recover

 |

 ▼

Review

 |

 ▼

Improve

```

---

# 15. Incident Example

## Scenario

QR check-ins ail.

---

## Detection

Alert:

```text id="incident-detect"

attendance.ailure_rate

>

10%

```

---

## Investigation

Check:

```text id="incident-investigate"

1. Vercel status

2. Sanity latency

3. Inngest ailures

4. Redis availability

```

---

## Mitigation

Possible actions:

```text id="mitigation"

Enable oline mode

Reduce dashboard load

Increase rate limits

Disable non-critical worklows

```

---

# 16. Production Runbook

Every critical component needs a runbook.

Example:

---

# Sanity ailure Runbook

## Symptoms

```
Attendance writes ailing
```

---

## Check

```
Sanity status

API latency

Error logs
```

---

## Action

```
Veriy outage

Enable queue buering

Monitor recovery
```

---

## Recovery

```
Replay ailed worklows
```

---

# 17. Postmortem Template

Ater every signiicant incident:

---

## Incident Summary

```
What happened?
```

---

## Impact

```
How many users aected?
```

---

## Timeline

```
09:00 Alert triggered

09:10 Investigation started

09:30 Recovery complete

```

---

## Root Cause

```
Why did this happen?
```

---

## Corrective Actions

```
Code ix

Monitoring improvement

Process change

```

---

# 18. Disaster Recovery Testing

Backups are not enough.

Test recovery.

---

Examples:

## Dependency ailure Test

Simulate:

```text id="chaos"

Sanity unavailable

```

Veriy:

```text
Worklow retries

No data loss

```

---

## Network ailure Test

Simulate:

```text
Mobile oline

```

Veriy:

```text
Queue sync works

```

---

# 19. Production Operations Dashboard

inal operational view:

```text id="ops-dashboard"

================================================

EVENT OPERATIONS


Attendance

██████████████░░

3,742 / 5,000


Check-In Rate

75/min


System Health

API        ✓

Database   ✓

Worklow   ✓

Email      ✓


Active Incidents

0


================================================

```

---

# 20. SRE Checklist

Beore event day:

## Monitoring

✅ Metrics conigured
✅ Logs searchable
✅ Traces available

---

## Reliability

✅ SLO deined
✅ Alerts tested
✅ Runbooks prepared

---

## Operations

✅ On-call owner assigned
✅ Incident process documented
✅ Recovery tested

---

# 21. inal Observability Architecture

```text id="inal-observability"

                       Users

                         |

                         ▼

                  Next.js Application

                         |

          ┌──────────────┼──────────────┐

          ▼              ▼              ▼


       Metrics          Logs          Traces


          |              |              |

          └──────────────┼──────────────┘

                         |

                         ▼


              Observability Platorm


                         |

                         ▼


              Operations Dashboard


                         |

                         ▼


                 Incident Response

```

---

# Appendix  Summary

The platorm now has:

✅ Metrics strategy
✅ Structured logging
✅ Distributed tracing
✅ SLO deinitions
✅ Error budgets
✅ Alerting strategy
✅ Incident response process
✅ Operational runbooks

The architecture has progressed rom:

```text
Application

↓

Production System

↓

Secure System

↓

Scalable System

↓

Operable System
```

---

# Next Recommended Appendix

## Enterprise Architecture & uture Evolution

Covering:

```text
G1. Multi-event SaaS architecture

G2. Multi-tenant design

G3. Event-driven evolution

G4. AI attendance analytics

G5. Zero Trust integration

G6. Data warehouse architecture

G7. Global deployment model

G8. Enterprise roadmap
```

This would transorm the project rom a single-event platorm into a **commercial-grade SaaS architecture**.
