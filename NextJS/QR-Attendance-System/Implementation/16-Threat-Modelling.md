# Threat Moel & Security Review

> *"A secure system is not one that has no vulnerabilities. A secure system is one where threats are unerstoo, mitigate, monitore, an recoverable."*

---

# 1. Security Review Scope

The review covers:

```text i="security-scope"

QR Attenance Platform


├── Ientity

│   └── Clerk Authentication


├── Fronten

│   └── Next.js 16 Application


├── Workflow

│   └── Inngest Processing


├── ata

│   └── Sanity ocuments


├── APIs

│   └── Server Actions


└── External Services

    ├── Resen

    ├── Upstash

    └── Realtime Provier

```

---

# 2. Threat Moel Methoology

We use **STRIE**.

STRIE categories:

| Threat                 | Meaning                       |
| ---------------------- | ----------------------------- |
| Spoofing               | Pretening to be someone else |
| Tampering              | Moifying ata                |
| Repuiation            | enying an action happene    |
| Information isclosure | Exposing sensitive ata       |
| enial of Service      | Making the system unavailable |
| Elevation of Privilege | Gaining unauthorize access   |

---

# 3. System Trust Bounaries

The most important security concept:

> Never trust ata crossing a bounary.

---

# Trust Bounary iagram

```text i="trust-bounary"

                 INTERNET

                     |

                     |

              Untruste Zone

                     |

                     ▼


             Next.js Application


                     |

        ┌────────────┼────────────┐


        ▼            ▼            ▼


      Clerk       Sanity       Inngest


        |            |            |


    Ientity     Storage     Workflow


```

---

# 4. Attack Surface Analysis

## Attack Surface 1 — QR Coe

The QR coe is public.

Anyone can:

* photograph it,
* share it,
* moify the URL,
* automate requests.

---

Threat:

```text i="qr-attack"

Attacker

   |

   ▼

Copie QR

   |

   ▼

Fake Check-In Requests

```

---

Mitigation:

```text i="qr-efense"

Signe Token

+

Expiration

+

User Authentication

+

Server Valiation

```

---

# 5. QR Replay Attack

## Scenario

Attacker captures:

```text i="qr-replay"

https://app.com/checkin?

event=security2026

```

Later:

```text i="qr-replay2"

Uses same QR

Attempts fake attenance

```

---

## efense

Use:

```json i="token"

{
 eventI:
 "evt123",

 issueAt:
 "10:00",

 expiresAt:
 "10:15",

 nonce:
 "abc123",

 signature:
 "xyz"
}

```

---

Valiation:

```text i="token-valiation"

Receive Token

      |

      ▼

Verify Signature

      |

      ▼

Check Expiration

      |

      ▼

Check Nonce

      |

      ▼

Accept

```

---

# 6. Ientity Threats

The system must prevent:

## User A checking in User B

Example:

```text i="ientity-threat"

Alice

   |

   ▼

Shares account

   |

   ▼

Bob checks in as Alice

```

---

Controls:

## Authentication

Clerk provies:

```text i="ientity"

Session

    |

    ▼

Verifie userI

```

---

## Server Ownership

Never accept:

```typescript i="ba-user"

checkIn({

userI:
"alice"

})

```

from the browser.

---

Instea:

```typescript i="secure-user"

const {

userI

}

=
auth();

```

The server erives ientity.

---

# 7. ata Integrity Threats

## Scenario

Attacker moifies:

```json i="tampering"

{
eventI:
"VIP-event",

userI:
"amin"

}

```

---

efense:

Valiation pipeline:

```text i="valiation-chain"

Client ata

     |

     ▼

Schema Valiation

     |

     ▼

Authentication Check

     |

     ▼

Authorization Check

     |

     ▼

omain Rules

     |

     ▼

atabase Write

```

---

# 8. uplicate Attenance Attack

## Scenario

User sens:

```text i="uplicate"

POST check-in

POST check-in

POST check-in

```

---

Without protection:

```text i="uplicate-result"

Attenance

Attenance

Attenance

```

---

With iempotency:

```text i="uplicate-protection"

(eventI,userI)

       |

       ▼

Alreay exists?

       |

       ├── Yes

       |

       └── Return existing result

```

---

# 9. enial of Service Protection

Possible attack:

```text i="os"

Bot Network

      |

      ▼

Thousans of Check-In Requests

```

---

Protection Layers:

## Layer 1 — Ege Protection

Example:

```text i="ege"

Vercel Firewall

      +

Rate Rules

```

---

## Layer 2 — Application Protection

```typescript i="app-limit"

RateLimit

     |

     ▼

Reject excessive users

```

---

## Layer 3 — Workflow Protection

```text i="workflow-limit"

Inngest

     |

     ▼

Controlle execution

```

---

# 10. Privilege Escalation

Roles:

```text i="roles"

Attenee

    |

    ▼

Organizer

    |

    ▼

Aministrator

```

---

Example attack:

Attenee attempts:

```text i="privilege"

ELETE event

```

---

Authorization:

```typescript i="authorization"

if(

role !== "amin"

){

throw ForbienError();

}

```

---

# 11. Information isclosure

Sensitive ata:

```text i="sensitive-ata"

Attenance Recors

    |

    ├── User Ientity

    ├── Timestamp

    ├── Location

    └── Event History

```

---

Protection:

## ata Minimization

Store only:

```json i="minimal"

{

userI,

eventI,

timestamp

}

```

Avoi unnecessary:

```json i="excess"

{

phone,

aress,

eviceFingerprint

}

```

---

# 12. Privacy Architecture

A prouction system shoul efine:

## ata Classification

| ata              | Classification |
| ----------------- | -------------- |
| Event Name        | Public         |
| Attenance Status | Internal       |
| User Ientity     | Confiential   |
| Location ata     | Sensitive      |

---

# 13. Auit Logging

Every important action shoul create an auit event.

Example:

```json i="auit"

{

event:

"attenance.create",


actor:

"user_123",


resource:

"event_456",


timestamp:

"2026-07-12T10:00:00Z"


}

```

---

Auit events answer:

* Who checke in?
* When?
* From where?
* Was it accepte?
* Was it rejecte?

---

# 14. Security Event Monitoring

etect suspicious patterns.

Example:

Normal:

```text i="normal"

User

1 check-in

```

Suspicious:

```text i="suspicious"

User

50 events

in 1 minute

```

---

Create security signals:

```typescript i="security-event"

logger.warn({

type:

"possible_abuse",


userI,


eventI


});

```

---

# 15. Security Testing Strategy

Prouction testing shoul inclue:

---

## Authentication Testing

Verify:

✅ unauthenticate users rejecte
✅ sessions expire
✅ users cannot impersonate others

---

## Authorization Testing

Verify:

✅ attenee cannot access amin routes
✅ organizer access is scope correctly

---

## QR Testing

Verify:

✅ expire QR rejecte
✅ moifie QR rejecte
✅ replay prevente

---

## Abuse Testing

Verify:

✅ rate limits work
✅ uplicate submissions hanle
✅ automate requests throttle

---

# 16. Security Checklist

Before prouction launch:

## Ientity

✅ Clerk authentication enable
✅ Server erives user ientity
✅ Role checks implemente

---

## QR Security

✅ Signe tokens
✅ Expiration
✅ Replay protection

---

## Application Security

✅ Input valiation
✅ CSRF protection
✅ Secure server actions

---

## ata Security

✅ Least privilege access
✅ Auit logs
✅ ata minimization

---

## Operational Security

✅ Monitoring
✅ Alerts
✅ Incient response process

---

# 17. Final Security Architecture

```text i="security-final"

                 QR Coe

                    |

                    ▼

             Token Valiation

                    |

                    ▼

              Clerk Ientity

                    |

                    ▼

            Rate Limiting Layer

                    |

                    ▼

          Application Authorization

                    |

                    ▼

             omain Valiation

                    |

                    ▼

          Iempotent Persistence

                    |

                    ▼

              Sanity Storage

                    |

                    ▼

             Auit + Monitoring

```

---

# Appenix  Summary

The system now has:

✅ Formal threat moel
✅ STRIE analysis
✅ Attack surface review
✅ Ientity protection
✅ Abuse prevention
✅ Privacy controls
✅ Security testing strategy

The architecture has evolve from:

```text
"QR attenance application"
```

into:

```text
"Enterprise-grae event ientity an attenance platform"
```

---

# Next Recommene Appenix

## Performance Engineering & Scale Testing

This covers the "5,000 people scanning within 5 minutes" scenario:

```text
E1. Loa moel

E2. Concurrency esign

E3. atabase optimization

E4. Caching strategy

E5. Queue tuning

E6. Locust/k6 testing

E7. Capacity planning

E8. Performance benchmarks
```

This completes the journey from **secure architecture → scalable architecture**.
