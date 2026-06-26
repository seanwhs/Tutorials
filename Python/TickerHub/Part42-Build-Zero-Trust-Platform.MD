# Building TickerHub

## Part 42: Building the Security, Identity, Authorization & Zero-Trust Platform — Teaching TickerHub to Trust Nobody

> There is an uncomfortable truth in professional finance:
>
> ```text
> The market
> is not your biggest threat.
> ```
>
> Your biggest threats are:
>
> * attackers,
> * compromised accounts,
> * stolen credentials,
> * insider abuse,
> * misconfigured systems,
> * and occasionally yourself.
>
> Professional financial systems operate under a simple principle:
>
> ```text
> Trust nothing.
>
> Verify everything.
> ```

At this point, TickerHub can:

* process markets,
* execute trades,
* manage risk,
* survive failures,
* observe itself,
* recover from disasters.

Unfortunately:

```text
Any intern with
database access
can still destroy everything.
```

---

# The Beginner Security Model

Most applications implement:

```python
if username == "admin":
    allow_access()
```

---

Or:

```python
if logged_in:
    allow_everything()
```

---

This works until:

```text
Production.
```

---

Then you discover:

```text
Authentication
is not security.
```

---

# The Professional Security Model

Professional financial systems ask:

```text
Who are you?
```

↓

```text
What can you do?
```

↓

```text
Where can you do it?
```

↓

```text
When can you do it?
```

↓

```text
Why are you doing it?
```

↓

```text
Can we prove it later?
```

---

# Security Architecture

```text
User
    |
    V

Identity Provider
    |
    V

Authentication
    |
    V

Authorization
    |
    V

Policy Engine
    |
    V

Audit Engine
    |
    V

Application
```

---

# Authentication

Question:

```text
Who are you?
```

---

Examples:

```text
Password
```

---

```text
MFA
```

---

```text
Biometrics
```

---

```text
Hardware Keys
```

---

# Identity Providers

Examples:

```text
Okta
```

---

```text
Auth0
```

---

```text
Microsoft Entra
```

---

```text
Keycloak
```

---

# Why Passwords Fail

Problem:

```text
Users reuse passwords.
```

---

Problem:

```text
Users share passwords.
```

---

Problem:

```text
Passwords get stolen.
```

---

Therefore:

```text
Passwords are insufficient.
```

---

# Multi-Factor Authentication

Require:

```text
Something you know
```

*

```text
Something you have
```

---

Example:

```text
Password
```

*

```text
Authenticator App
```

---

# Session Tokens

After login:

```text
Identity Provider
        |
        V

JWT
        |
        V

Application
```

---

Example:

```json
{
  "user":"trader01",

  "role":"portfolio_manager",

  "expires":"2026-06-27"
}
```

---

# Token Expiration

Question:

```text
What happens
if tokens never expire?
```

---

Answer:

```text
Compromises
never end.
```

---

# Refresh Tokens

Access token:

```text
15 minutes
```

---

Refresh token:

```text
30 days
```

---

Benefits:

```text
Security

+

Usability
```

---

# Authorization

Question:

```text
What can you do?
```

---

Example:

```text
Trader
```

Can:

```text
Submit Orders
```

---

Cannot:

```text
Change Risk Limits
```

---

# Role-Based Access Control (RBAC)

Create:

```text
roles/

    trader

    risk_manager

    admin

    auditor
```

---

Example:

```text
Trader
```

Permissions:

```text
View Market
```

---

```text
Submit Orders
```

---

```text
Cancel Orders
```

---

# Risk Manager

Permissions:

```text
View Risk
```

---

Permissions:

```text
Pause Trading
```

---

Permissions:

```text
Change Limits
```

---

# Auditor

Permissions:

```text
Read Only
```

---

Permissions:

```text
Export Logs
```

---

Permissions:

```text
View History
```

---

# Attribute-Based Access Control (ABAC)

Question:

```text
Can traders
view all portfolios?
```

---

Example:

```python
if (
    user.region == portfolio.region
    and
    user.desk == portfolio.desk
):
    allow()
```

---

Now authorization depends on:

```text
User
```

*

```text
Resource
```

*

```text
Context
```

---

# Policy Engine

Professional systems implement:

```text
Policies
```

---

Example:

```text
Traders
cannot modify
risk limits.
```

---

Example:

```text
Orders above
10M
require approval.
```

---

Example:

```text
Trading forbidden
outside market hours.
```

---

# Separation of Duties

Question:

```text
Can the same person
create
and approve
a trade?
```

---

Answer:

```text
No.
```

---

Example:

```text
Trader
```

↓

```text
Supervisor
```

↓

```text
Execution
```

---

# Principle of Least Privilege

Rule:

```text
Grant
the minimum access
required.
```

---

Not:

```text
Admin
```

---

Instead:

```text
Exactly enough.
```

---

# Zero Trust

Traditional model:

```text
Inside Network
     =
Trusted
```

---

Professional model:

```text
Nothing
is trusted.
```

---

Every request requires:

```text
Authentication
```

---

Every request requires:

```text
Authorization
```

---

Every request requires:

```text
Verification
```

---

# Service-to-Service Authentication

Question:

```text
Can Risk Service
trust Market Service?
```

---

Answer:

```text
No.
```

---

Instead:

```text
Market Service
```

presents:

```text
Certificate
```

---

Then:

```text
Risk Service
```

validates:

```text
Certificate
```

---

# Secrets Management

Never store:

```python
PASSWORD = "secret"
```

---

Never commit:

```text
.env
```

---

Use:

```text
Vault
```

---

Use:

```text
Cloud Secrets
```

---

Use:

```text
Key Management Systems
```

---

# Encryption

Encrypt:

```text
Network Traffic
```

---

Encrypt:

```text
Databases
```

---

Encrypt:

```text
Backups
```

---

Encrypt:

```text
Secrets
```

---

# TLS Everywhere

Instead of:

```text
HTTP
```

---

Use:

```text
HTTPS
```

---

Instead of:

```text
Kafka
```

---

Use:

```text
TLS Kafka
```

---

Instead of:

```text
Redis
```

---

Use:

```text
TLS Redis
```

---

# Audit Logging

Question:

```text
Who changed
the risk limit?
```

---

Question:

```text
When?
```

---

Question:

```text
Why?
```

---

Question:

```text
From where?
```

---

Question:

```text
Can we prove it?
```

---

Example:

```json
{
  "timestamp":"2026-06-26",

  "user":"trader01",

  "action":"modify_limit",

  "old":1000000,

  "new":2000000,

  "ip":"10.1.1.22"
}
```

---

# Immutable Audit Logs

Requirement:

```text
Nobody
can modify history.
```

---

Therefore:

```text
Append Only
```

---

Properties:

```text
Tamper Evident
```

---

Properties:

```text
Cryptographically Verifiable
```

---

# Fraud Detection

Question:

```text
Why did a trader
submit
1000 orders
in 2 seconds?
```

---

Question:

```text
Why did someone
log in
from Singapore
and London
simultaneously?
```

---

Question:

```text
Why did an auditor
submit trades?
```

---

Generate:

```text
Security Alert
```

---

# Rate Limiting

Question:

```text
Can users
send unlimited requests?
```

---

Answer:

```text
No.
```

---

Example:

```text
100 requests/minute
```

---

Example:

```text
1000 orders/hour
```

---

# DDoS Protection

Protect:

```text
API Gateway
```

---

Protect:

```text
Authentication
```

---

Protect:

```text
WebSockets
```

---

Protect:

```text
Market Feeds
```

---

# Incident Response

Question:

```text
Account stolen?
```

---

Actions:

```text
Disable Account
```

↓

```text
Revoke Tokens
```

↓

```text
Freeze Trading
```

↓

```text
Audit Activity
```

---

# Security Monitoring

Monitor:

```text
Failed Logins
```

---

Monitor:

```text
Privilege Escalation
```

---

Monitor:

```text
Suspicious Trades
```

---

Monitor:

```text
Anomalous Access
```

---

# Security Dashboard

Display:

```text
Active Users
```

---

Display:

```text
Failed Logins
```

---

Display:

```text
Open Sessions
```

---

Display:

```text
Security Events
```

---

Display:

```text
Audit Trails
```

---

Display:

```text
Threat Level
```

---

# Compliance

Support:

```text
SOC2
```

---

Support:

```text
ISO 27001
```

---

Support:

```text
MAS TRM
```

---

Support:

```text
GDPR
```

---

Support:

```text
Financial Regulations
```

---

# Security Pipeline

```text
Identity
      |
      V

Authentication
      |
      V

Authorization
      |
      V

Policy Engine
      |
      V

Audit Engine
      |
      V

Monitoring
```

---

# Why Security Matters

Because eventually someone will ask:

```text
Who executed
this trade?
```

---

And then:

```text
Can you prove it?
```

---

Professional systems answer:

```text
Yes.
```

---

# Architecture Lesson #42

Beginners think:

```text
Security
    =
Login Screen
```

Professionals think:

```text
Security
    =
A continuously enforced,
continuously verified,
continuously audited
system of identity,
authorization,
accountability,
and distrust
```

---

# Current Architecture

```text
Users
    |
    V

Identity Provider
    |
    V

Authentication
    |
    V

Authorization
    |
    V

Policy Engine
    |
    V

Audit Engine
    |
    V

Monitoring
    |
    V

Application
```

TickerHub now contains:

✅ Authentication

✅ MFA

✅ JWT

✅ RBAC

✅ ABAC

✅ Policy engines

✅ Separation of duties

✅ Zero trust

✅ Service authentication

✅ Secret management

✅ Encryption

✅ Audit logging

✅ Fraud detection

✅ Rate limiting

✅ Incident response

✅ Compliance

At this point, TickerHub no longer resembles a trading terminal.

It resembles:

```text
A Zero-Trust Financial Computing Platform
capable of proving,
verifying,
authorizing,
auditing,
monitoring,
and defending
every action
performed within the system.
```

---

# In Part 43

We will build the **Data Platform, Event Sourcing & Time-Travel Architecture**, where you'll discover that professional financial systems are not designed merely to answer:

```text
What is the current state?
```

but:

```text
What was the exact state
of every object,
every market,
every portfolio,
and every decision
at any moment
in history?
```
