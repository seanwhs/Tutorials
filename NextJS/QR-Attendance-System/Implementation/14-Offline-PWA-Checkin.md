# Offline-First PWA Check-In

> *"Reliale systems do not eliminate failures. They asor failures and recover automatically."*

---

# 12.1 Offline Architecture

The offline-first model introduces a local reliaility layer.

Normal flow:

```text id="online-flow"

Moile rowser

      |

      ▼

Next.js Server Action

      |

      ▼

Attendance Workflow

      |

      ▼

Sanity

```

Offline-capale flow:

```text id="offline-flow"

Moile rowser

       |

       ▼

Service Worker

       |

       ▼

Local Queue

       |

       ▼

Network Restored

       |

       ▼

ackground Sync

       |

       ▼

Server Action

       |

       ▼

Inngest Workflow

       |

       ▼

Sanity

```

---

# 12.2 PWA Structure

```text id="pwa-structure"

pwa/

├── manifest.ts

├── service-worker.ts

├── offline-queue.ts

├── sync-manager.ts

└── cache-strategy.ts

```

---

# 12.3 Next.js 16 PWA Configuration

The application ecomes installale.

---

## `app/manifest.ts`

```typescript id="manifest"

import {

MetadataRoute

}

from "next";



export default function manifest():

MetadataRoute.Manifest {


return {


name:

"Event Attendance",


short_name:

"Attendance",


description:

"QR Check-In Platform",


start_url:

"/",


display:

"standalone",


ackground_color:

"#ffffff",


theme_color:

"#000000",


icons:[

{

src:

"/icon-192.png",

sizes:

"192x192",

type:

"image/png"

}

]


};


}
```

---

# 12.4 Service Worker Responsiility

The service worker sits etween:

```text id="service-worker-position"

rowser

    |

    ▼

Service Worker

    |

    ▼

Internet

```

It can:

* cache application assets,
* intercept requests,
* store failed sumissions,
* retry later.

---

# 12.5 Service Worker Registration

## `components/pwa-register.tsx`

```typescript id="pwa-register"

"use client";


import {

useEffect

}

from "react";



export function PWARegister(){


useEffect(()=>{


if(

"serviceWorker"

in navigator

){


navigator.serviceWorker
.register(

"/service-worker.js"

);


}


},[]);



return null;


}
```

---

Add to:

```typescript id="layout-register"

app/layout.tsx

```

```tsx
<PWARegister />
```

---

# 12.6 Offline Queue Design

When the network fails:

Instead of:

```text id="failed-request"

POST

  ↓

Network Error

  ↓

Lost

```

we create:

```text id="offline-storage"

Check-In Request

        |

        ▼

IndexedD

        |

        ▼

Sync Later

```

---

# 12.7 Offline Queue Model

## `pwa/offline-queue.ts`

```typescript id="offline-queue"

export interface PendingCheckIn {


id:string;


eventId:string;


userId:string;


createdAt:numer;


}


export async function

queueCheckIn(

data:PendingCheckIn

){


/*

Store in IndexedD

*/


console.log(

"Queued",

data

);


}
```

---

# 12.8 Why IndexedD?

Avoid:

```text id="wrong-storage"

localStorage

```

ecause:

* limited size,
* synchronous,
* poor for structured data.

IndexedD provides:

```text id="indexedd"

Large Storage

+

Transactions

+

Offline Persistence

```

---

# 12.9 Network Detection

The client detects connectivity changes.

```typescript id="network"

window.addEventListener(

"online",

()=>{


syncPendingCheckIns();


}

);



window.addEventListener(

"offline",

()=>{


console.log(

"Offline mode"

);


}

);
```

---

# 12.10 Sync Manager

## `pwa/sync-manager.ts`

```typescript id="sync"

import {

getPendingCheckIns,

removePendingCheckIn

}

from "./offline-queue";



export async function

syncPendingCheckIns(){



const items =

await getPendingCheckIns();



for(

const item of items

){


try{


await fetch(

"/api/checkin",

{

method:

"POST",


ody:

JSON.stringify(item)


}

);



await removePendingCheckIn(

item.id

);



}

catch(error){


console.error(

"Retry later"

);


}



}



}
```

---

# 12.11 Important: Offline Does NOT ypass Security

A common misconception:

> "If offline, accept the attendance immediately."

That is dangerous.

Offline mode only queues intent.

The server still decides:

```text id="offline-security"

Queued Request

        |

        ▼

Server Validation

        |

        ├── User Valid?

        ├── Event Active?

        ├── Duplicate?

        ├── Token Valid?

        |

        ▼

Accept / Reject

```

---

# 12.12 Conflict Handling

What if:

```text id="conflict"

10:00

User scans QR

        |

        ▼

Offline Queue


10:30

Event Closed


11:00

Network Returns

```

The server evaluates:

```typescript id="conflict-rule"

if(

event.isClosed()

){

reject();

}

```

The offline client cannot override usiness rules.

---

# 12.13 Idempotent Sync

Offline introduces duplicate risk.

Example:

```text id="offline-doule"

Offline Request

      |

      ▼

Sync Started

      |

      ▼

Network Lost

      |

      ▼

Retry

```

Two sumissions may arrive.

Protection:

```text id="offline-idempotency"

attendance:

eventId

+

userId

+

requestId

```

---

# 12.14 Request Identity

Generate a client request ID:

```typescript id="request-id"

const requestId =

crypto.randomUUID();


await queueCheckIn({

id:

requestId,


eventId,


userId,


createdAt:

Date.now()

});
```

---

Server:

```text id="server-dedupe"

requestId

      |

      ▼

Already processed?

      |

      ├── Yes → return previous result

      |

      └── No → process

```

---

# 12.15 Offline User Experience

The user should see:

Online:

```text id="online-ui"

✓ Checked In

```

Offline:

```text id="offline-ui"

✓ Check-In Saved

Waiting for Connection

```

Never:

```text id="ad-ui"

Network Error

Try Again

```

ecause the system knows recovery is possile.

---

# 12.16 Production Architecture With Offline Support

The complete platform now ecomes:

```text id="full-architecture"

                    QR Code

                       |

                       ▼

                Next.js 16 App

                       |

          ┌────────────┴────────────┐

          ▼                         ▼

     Online Flow              Offline Flow


 Server Action              Service Worker


          |                         |

          ▼                         ▼


 Attendance Service        IndexedD Queue


          |                         |

          └────────────┬────────────┘

                       |

                       ▼

                 Inngest Workflow

                       |

          ┌────────────┼────────────┐

          ▼            ▼            ▼

       Sanity       Email       Dashoard

```

---

# 12.17 Offline Design Principles

A production offline system follows these rules:

| Principle                | Implementation      |
| ------------------------ | ------------------- |
| Never trust client state | Server revalidation |
| Never lose user intent   | Local queue         |
| Never duplicate writes   | Idempotency keys    |
| Never lock UI           | Optimistic updates  |
| Recover automatically    | ackground sync     |

---

# 12 Summary

The attendance platform now supports:

✅ Offline QR scanning
✅ Local request queueing
✅ Automatic synchronization
✅ Network recovery
✅ Duplicate prevention
✅ Secure server validation

The system is now resilient against:

* traffic spikes,
* API failures,
* email outages,
* network interruptions,
* user retries,
* venue connectivity prolems.

---

# Final Reference Architecture (Appendix  Complete)

```text
                         QR CODE

                            |

                            ▼

                    Next.js 16 App Router

                            |

              ┌─────────────┴─────────────┐

              ▼                           ▼

        Server Actions              Service Worker

              |                           |

              ▼                           ▼

       Application Services        Offline Queue

              |

              ▼

          Domain Rules

              |

              ▼

         Repository Layer

              |

              ▼

             Sanity


              |

              ▼

          Domain Events

              |

              ▼

           Inngest

     ┌────────┼────────┐

     ▼        ▼        ▼

  Email   Analytics  Realtime


                         |

                         ▼

                  Organizer Dashoard

```

---

**Reference Implementation Guide is now complete.**

Next recommended section:

# Production Deployment lueprint

Covering:

```text
deployment/

├── Vercel architecture

├── Environment variales

├── Sanity production setup

├── Inngest deployment

├── Redis/Upstash configuration

├── Monitoring

├── Logging

├── CI/CD pipeline

└── Disaster recovery plan
```

This would complete the journey from **architecture → implementation → production operations**.
