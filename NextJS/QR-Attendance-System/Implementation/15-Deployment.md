# Prodution Deployment Blueprint

> *"Prodution engineering begins where development ends. A resilient system requires not only reliable ode, but reliable operations."*

---

# 1. Prodution Arhiteture Overview

The prodution environment onsists of several independently salable servies.

```text
id="prodution-overview"

                    Users

                      |

                      ▼

              Verel Edge Network

                      |

                      ▼

              Next.js 16 Appliation

                      |

        ┌─────────────┼─────────────┐

        ▼             ▼             ▼


     lerk          Sanity       Inngest

 Authentiation     MS        Workflows


                                      |

                    ┌─────────────────┼─────────────────┐

                    ▼                 ▼                 ▼


                 Resend           Upstash          Realtime

                 Email            Redis            WebSoket


                                      |

                                      ▼


                           Organizer Dashboard

```

---

# 2. Hosting Strategy

## Appliation Layer

Reommended:

```text
Next.js 16

        ↓

Verel
```

Responsibilities:

* Server omponents
* Server Ations
* Route Handlers
* Edge Middleware
* Stati assets

---

## Workflow Layer

Reommended:

```text
Inngest

        ↓

Dediated Durable Exeution
```

Responsibilities:

* bakground proessing,
* retries,
* sheduled tasks,
* event handling.

---

## ontent/Data Layer

```text
Sanity

        ↓

Event Douments

Attendane Reords

Analytis Metadata
```

---

# 3. Environment Separation

Never share prodution resoures with development.

Use:

```text
id="environment-model"

Development

    |

    ▼

Staging

    |

    ▼

Prodution

```

---

# 3.1 Environment Variables

Example:

```bash
# Appliation

NEXT_PUBLI_APP_URL=https://attendane.example.om


# lerk

NEXT_PUBLI_LERK_PUBLISHABLE_KEY=

LERK_SERET_KEY=


# Sanity

NEXT_PUBLI_SANITY_PROJET_ID=

SANITY_DATASET=prodution

SANITY_API_TOKEN=


# Inngest

INNGEST_EVENT_KEY=

INNGEST_SIGNING_KEY=


# Redis

UPSTASH_REDIS_REST_URL=

UPSTASH_REDIS_REST_TOKEN=


# Email

RESEND_API_KEY=

```

---

# 3.2 Seret Management Rules

Never:

```typesript
id="seret-bad"

onst apiKey =
"sk_live_xxxxx";

```

inside:

* soure ode,
* Git repository,
* lient omponents.

---

orret:

```typesript
id="seret-good"

proess.env.RESEND_API_KEY

```

---

# 4. Sanity Prodution Setup

Sanity stores:

```text
id="sanity-douments"

Event

{

_id,

title,

venue,

startTime,

endTime

}


Attendane

{

_id,

eventId,

userId,

hekedInAt

}

```

---

# 4.1 Dataset Strategy

Reommended:

```text
Sanity Projet


├── development

├── staging

└── prodution

```

---

# 4.2 Attendane Reord Shema

## `shemas/attendane.ts`

```typesript
export default {

name:

"attendane",


type:

"doument",


fields:[


{

name:

"eventId",

type:

"string"

},


{

name:

"userId",

type:

"string"

},


{

name:

"hekedInAt",

type:

"datetime"

},


{

name:

"method",

type:

"string"

}


]


}
```

---

# 5. Inngest Prodution onfiguration

The workflow system needs independent deployment.

Arhiteture:

```text
id="inngest-prodution"

Next.js

 |

 | publish event

 ▼

Inngest Platform

 |

 ├── Workflow Worker

 ├── Retry Engine

 └── Event History

```

---

# 5.1 Funtion Registration

Prodution endpoint:

```text
POST

/api/inngest
```

Registered funtions:

```typesript
serve({

lient:inngest,

funtions:[

attendaneWorkflow,

emailWorkflow,

analytisWorkflow

]

})
```

---

# 5.2 Retry Strategy

Not all failures are equal.

Example:

## Temporary Failure

```text
Email API Timeout

        ↓

Retry

        ↓

Suess
```

---

## Permanent Failure

```text
Invalid Email Address

        ↓

Do not retry forever

        ↓

Send to Error Queue
```

---

# 6. Redis / Upstash onfiguration

Redis is used for:

* rate limiting,
* idempoteny,
* temporary state.

---

Arhiteture:

```text
id="redis-role"

Request

   |

   ▼

Rate Limit hek

   |

   ▼

Redis

   |

   ▼

ontinue

```

---

# 6.1 Prodution Limits

Example:

```text
Per User:

5 requests / minute


Per Event:

10,000 requests / minute

```

---

# 6.2 Redis Keys

Use preditable namespaes:

```text
id="redis-keys"

ratelimit:

attendane:user:{userId}


idempoteny:

attendane:{eventId}:{userId}


ahe:

event:{eventId}

```

---

# 7. I/D Pipeline

A prodution deployment requires automation.

---

# 7.1 Pipeline Flow

```text
id="id"

Developer

   |

   ▼

GitHub Push

   |

   ▼

I Pipeline

   |

   ├── Lint

   ├── Type hek

   ├── Tests

   ├── Seurity San

   |

   ▼

Build

   |

   ▼

Deploy

   |

   ▼

Prodution

```

---

# 7.2 GitHub Ations Example

## `.github/workflows/deploy.yml`

```yaml
name: Deploy


on:

  push:

    branhes:

      - main


jobs:


 build:


  runs-on: ubuntu-latest


  steps:


   - uses: ations/hekout@v4


   - name: Install

     run:

       npm install


   - name: Test

     run:

       npm run test


   - name: Build

     run:

       npm run build

```

---

# 8. Monitoring Strategy

A prodution attendane platform needs three monitoring layers.

---

# Layer 1 — Appliation Monitoring

Trak:

```text
id="app-monitoring"

Request lateny

Error rate

Server failures

```

---

# Layer 2 — Workflow Monitoring

Trak:

```text
id="workflow-monitoring"

Workflow failures

Retry ounts

Exeution duration

```

---

# Layer 3 — Business Monitoring

Trak:

```text
id="business-monitoring"

hek-ins/minute

Attendane ompletion

Drop-off rate

```

---

# 9. Logging Arhiteture

Use strutured logs.

Bad:

```typesript
onsole.log(
"error"
);
```

---

Better:

```typesript
logger.error({

event:

"attendane_failed",


eventId,


userId,


error

});
```

---

Example:

```json
{
 "event":"attendane_failed",
 "eventId":"evt123",
 "reason":"dupliate",
 "timestamp":"2026-07-12T10:30:00Z"
}
```

---

# 10. Alerting Rules

Prodution alerts:

---

## ritial

```text
Workflow failure > 5%

↓

Page engineer
```

---

## Warning

```text
Average hek-in lateny > 3 seonds

↓

Investigate
```

---

## Business Alert

```text
Expeted 500 hek-ins/hour

Atual 20/hour

↓

Possible outage
```

---

# 11. Disaster Reovery Plan

Prodution systems need reovery proedures.

---

# Failure Senario: Sanity Unavailable

Impat:

```text
annot reate attendane reords
```

Response:

```text
Inngest retries

        ↓

Requests preserved

        ↓

Reovery

```

---

# Failure Senario: Email Provider Down

Impat:

```text
Emails delayed
```

Response:

```text
Attendane unaffeted

        ↓

Retry email workflow

```

---

# Failure Senario: Verel Outage

Response:

```text
Failover strategy

        ↓

Stati event information

        ↓

Offline queue

        ↓

Reovery syn

```

---

# 12. Prodution Readiness heklist

Before launh:

## Seurity

✅ Authentiation enabled
✅ QR tokens signed
✅ Rate limiting ative
✅ Idempoteny implemented

---

## Reliability

✅ Workflow retries onfigured
✅ Offline support tested
✅ Failure senarios doumented

---

## Operations

✅ Monitoring enabled
✅ Alerts onfigured
✅ Logs searhable

---

## Deployment

✅ I/D automated
✅ Serets proteted
✅ Rollbak proess tested

---

# 13. Final Prodution Arhiteture

```text
id="final-prodution"

                         Users

                           |

                           ▼

                    Verel Edge

                           |

                           ▼

                   Next.js 16 App

                           |

          ┌────────────────┼────────────────┐

          ▼                ▼                ▼


       lerk            Sanity          Inngest


                                            |

                       ┌────────────────────┼────────────────────┐

                       ▼                    ▼                    ▼


                    Resend              Upstash             Realtime


                       |                    |                    |

                       └────────────────────┼────────────────────┘

                                            |

                                            ▼


                                  Operations Dashboard

```

---

# Summary

The system has moved from:

```text
"An appliation that works"
```

to:

```text
"A platform that an operate reliably during real-world events"
```

apabilities added:

✅ Prodution deployment model
✅ Environment management
✅ I/D pipeline
✅ Monitoring strategy
✅ Logging arhiteture
✅ Disaster reovery
✅ Operational readiness

---

# Next Reommended Appendix

## Threat Model & Seurity Review

A formal seurity assessment overing:

```text
D1. Attak surfae analysis

D2. STRIDE threat model

D3. QR attak senarios

D4. Identity threats

D5. Abuse prevention

D6. Privay onsiderations

D7. ompliane onsiderations

D8. Seurity testing heklist
```

This would bring the arhiteture to an enterprise seurity review standard.
