# Appendix A29 — Production Runbooks

## How Professional Engineers Operate Systems During Incidents

> **Purpose:** Tutorials teach you how to build systems. Production engineering teaches you how to keep them alive. A runbook is a predefined operational procedure used during failures, incidents, outages, and emergencies.

---

# Introduction

The biggest misconception about production systems is:

```text id="7vrhgn"
If we build
it correctly,

it will not fail.
```

Professional engineers understand:

```text id="mho48l"
Everything
fails.

Eventually.
```

The purpose of operations is not:

```text id="rrb83g"
Preventing
all failures.
```

The purpose of operations is:

```text id="v7shxk"
Recovering
quickly
from failure.
```

---

# The Incident Lifecycle

```text id="mjlwm1"
Detection

    |

Triage

    |

Containment

    |

Mitigation

    |

Recovery

    |

Postmortem

    |

Learning
```

---

# The First Rule of Incident Response

Never ask:

```text id="mjlwm2"
Who broke it?
```

Ask:

```text id="mjlwm3"
What failed?
```

---

# The Second Rule

Do not optimize for:

```text id="mjlwm4"
Being right.
```

Optimize for:

```text id="mjlwm5"
Restoring service.
```

---

# Incident Severity Levels

| Severity | Description          | Example                        |
| -------- | -------------------- | ------------------------------ |
| P0       | Complete outage      | Entire application unavailable |
| P1       | Critical degradation | Payments failing               |
| P2       | Major issue          | Search unavailable             |
| P3       | Minor issue          | Reporting dashboard broken     |
| P4       | Cosmetic issue       | UI rendering bug               |

---

# Universal Incident Checklist

During every incident:

```text id="mjlwm6"
✓ Stop the bleeding

✓ Assess impact

✓ Communicate

✓ Restore service

✓ Investigate

✓ Document

✓ Learn
```

---

# Runbook 1

# Database Outage

---

## Symptoms

```text id="mjlwm7"
500 errors

Timeouts

Slow responses

Connection failures
```

---

## Detection

Check:

```bash id="mjlwm8"
Database status

Connection count

CPU

Memory

Disk

Replication lag
```

---

## Triage Questions

```text id="mjlwm9"
Is database reachable?

Is primary alive?

Are replicas healthy?

Is storage full?

Are connections exhausted?
```

---

## Immediate Actions

### Step 1

Reduce load:

```text id="mjlwm10"
Disable batch jobs

Pause workers

Rate limit traffic
```

---

### Step 2

Restart failed connections.

---

### Step 3

Fail over if necessary.

---

## Recovery

Verify:

```text id="mjlwm11"
Reads work

Writes work

Replication works

Latency normal
```

---

## Prevention

```text id="mjlwm12"
Connection pools

Read replicas

Monitoring

Backups

Failover testing
```

---

# Runbook 2

# Redis Outage

---

## Symptoms

```text id="mjlwm13"
Sessions lost

Cache misses

Queue failures

Rate limiter failures
```

---

## Questions

```text id="mjlwm14"
Is Redis down?

Is memory exhausted?

Are replicas alive?

Are queues blocked?
```

---

## Immediate Response

### Disable:

```text id="mjlwm15"
Caching
```

if possible.

---

### Enable:

```text id="mjlwm16"
Graceful degradation.
```

---

### Restart:

```text id="mjlwm17"
Redis cluster.
```

---

## Long-Term Fix

Question:

```text id="mjlwm18"
What happens
when Redis dies?
```

If answer:

```text id="mjlwm19"
Everything.
```

Redesign.

---

# Runbook 3

# Next.js Production Failure

---

## Symptoms

```text id="mjlwm20"
500 errors

Hydration failures

Blank pages

Slow responses
```

---

## Checklist

Verify:

```text id="mjlwm21"
Deployment status

Environment variables

API endpoints

Database connectivity

CDN status
```

---

## Immediate Response

Rollback:

```bash id="mjlwm22"
vercel rollback
```

---

If rollback unavailable:

```text id="mjlwm23"
Restore
previous deployment.
```

---

## Prevention

```text id="mjlwm24"
Blue-green deployment

Canary releases

Feature flags
```

---

# Runbook 4

# Queue Backlog

---

## Symptoms

```text id="mjlwm25"
Jobs delayed

Workers overloaded

Latency increases
```

---

## Diagnosis

Measure:

```text id="mjlwm26"
Queue length

Worker count

Job duration

Failure rate
```

---

## Response

Options:

```text id="mjlwm27"
Add workers

Pause producers

Prioritize jobs

Drop low-priority tasks
```

---

# Runbook 5

# Authentication Failure

---

## Symptoms

```text id="mjlwm28"
Users cannot login.
```

---

## Verify

```text id="mjlwm29"
Identity provider

Secrets

Certificates

JWT expiration

Clock synchronization
```

---

## Recovery

Fallback:

```text id="mjlwm30"
Emergency auth
provider.
```

---

# Runbook 6

# Security Incident

---

## Rule #1

Assume:

```text id="mjlwm31"
Compromise.
```

---

## Immediate Actions

```text id="mjlwm32"
Contain

Isolate

Rotate secrets

Disable access

Preserve evidence
```

---

## Never

```text id="mjlwm33"
Delete logs.
```

---

## Investigation

Determine:

```text id="mjlwm34"
Entry point

Blast radius

Affected systems

Exfiltration
```

---

# Runbook 7

# Cloud Region Failure

---

## Symptoms

```text id="mjlwm35"
Entire region
unavailable.
```

---

## Response

Activate:

```text id="mjlwm36"
Disaster recovery.
```

---

## Failover

```text id="mjlwm37"
Region A

↓

Region B
```

---

## Verify

```text id="mjlwm38"
DNS

Database

Storage

Authentication

Queues
```

---

# Runbook 8

# CDN Failure

---

## Symptoms

```text id="mjlwm39"
Static assets
unavailable.
```

---

## Response

```text id="mjlwm40"
Bypass CDN.
```

---

Serve:

```text id="mjlwm41"
Origin directly.
```

---

# Runbook 9

# Deployment Failure

---

## Symptoms

```text id="mjlwm42"
Deployment succeeds.

Users fail.
```

---

## Rule

Never debug production during outage.

---

## Response

```text id="mjlwm43"
Rollback first.

Investigate later.
```

---

## Verify

```text id="mjlwm44"
Previous version healthy.
```

---

# Runbook 10

# Data Corruption

---

## Immediate Rule

Stop:

```text id="mjlwm45"
All writes.
```

---

## Questions

```text id="mjlwm46"
What corrupted?

How much?

Since when?

Can we restore?
```

---

## Recovery

Options:

```text id="mjlwm47"
Restore backup

Replay events

Manual repair
```

---

# Runbook 11

# AI Hallucination Incident

---

## Symptoms

```text id="mjlwm48"
Incorrect answers

Fabricated facts

Unsafe actions
```

---

## Response

```text id="mjlwm49"
Disable automation.

Enable review.
```

---

## Investigation

Determine:

```text id="mjlwm50"
Prompt

Context

Tools

Model

Validation
```

---

## Prevention

```text id="mjlwm51"
Verification

Human review

Constraints
```

---

# Runbook 12

# Prompt Injection Attack

---

## Example

```text id="mjlwm52"
Ignore all
previous instructions.
```

---

## Immediate Response

```text id="mjlwm53"
Disable tool execution.
```

---

## Investigation

Review:

```text id="mjlwm54"
Prompt logs

Tool calls

User input

Memory
```

---

## Prevention

```text id="mjlwm55"
Sandboxing

Isolation

Validation

Permission boundaries
```

---

# Runbook 13

# Agent Runaway Incident

---

## Symptoms

```text id="mjlwm56"
Infinite loops

Massive token usage

Unexpected actions
```

---

## Immediate Response

```text id="mjlwm57"
Kill agent.
```

---

## Verify

```text id="mjlwm58"
Token budget

Execution limits

Loop detection
```

---

# Communication Runbook

During incidents communicate:

---

## What happened?

```text id="mjlwm59"
Observed failure.
```

---

## Who is affected?

```text id="mjlwm60"
User impact.
```

---

## What are we doing?

```text id="mjlwm61"
Current mitigation.
```

---

## When is next update?

```text id="mjlwm62"
Update schedule.
```

---

# Never Say

```text id="mjlwm63"
Everything is fine.
```

when:

```text id="mjlwm64"
You do not know.
```

---

# Incident Timeline Template

```text id="mjlwm65"
08:00 Alert triggered

08:03 Investigation started

08:10 Root cause suspected

08:15 Mitigation applied

08:22 Service restored

09:30 Postmortem started
```

---

# Postmortem Template

---

## What happened?

---

## Why did it happen?

---

## Why wasn't it detected?

---

## Why wasn't it prevented?

---

## How do we prevent recurrence?

---

# The Five Whys

Example:

```text id="mjlwm66"
Why outage?

Database full.
```

---

Why?

```text id="mjlwm67"
Logs grew.
```

---

Why?

```text id="mjlwm68"
Cleanup failed.
```

---

Why?

```text id="mjlwm69"
Job crashed.
```

---

Why?

```text id="mjlwm70"
No monitoring.
```

---

Why?

```text id="mjlwm71"
Nobody owned it.
```

---

Root cause:

```text id="mjlwm72"
Ownership failure.
```

---

# The SRE Mental Model

Systems fail because of:

```text id="mjlwm73"
Humans

Processes

Dependencies

Complexity
```

---

Systems recover because of:

```text id="mjlwm74"
Preparation.
```

---

# Final Rule

Amateurs ask:

```text id="mjlwm75"
How do we
avoid failures?
```

Professionals ask:

```text id="mjlwm76"
How do we
recover
when failure
becomes inevitable?
```

Because production engineering is not the art of building systems that never fail.

It is the art of building organizations that can survive failure.
