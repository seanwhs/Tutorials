# Real-Time Attendance Dashoard

> *"The same event that records attendance should also power operational intelligence. Oservaility should e a natural consequence of good architecture, not an afterthought."*

---

# 11.1 Dashoard Architecture

The dashoard uses the existing event-driven architecture.

```text id="dashoard-flow"

Attendee

   |

   ▼

Check-In

   |

   ▼

Attendance Record

   |

   ▼

Inngest Event

   |

   ├───────────────┐
   |               |
   ▼               ▼

Analytics       Real-Time roadcast

                    |

                    ▼

             Organizer Dashoard

```

---

# 11.2 Dashoard Structure

```text id="dashoard-structure"

dashoard/

├── components/

│   ├── attendance-counter.tsx

│   ├── attendance-chart.tsx

│   └── session-reakdown.tsx


├── services/

│   ├── metrics.service.ts

│   └── realtime.service.ts


├── providers/

│   └── realtime-provider.tsx


└── types.ts

```

---

# 11.3 Dashoard Requirements

The organizer dashoard should answer:

## Current Attendance

```text
Registered:

5,000


Checked In:

3,742
```

---

## Arrival Rate

Example:

```text
Last 10 minutes:

+235 attendees
```

---

## Session Attendance

```text
Opening Keynote

1,200 attendees


Security Workshop

450 attendees
```

---

# 11.4 Metrics Service

The dashoard should not query raw attendance documents repeatedly.

Instead:

```text id="metrics-layer"

Dashoard

    |

    ▼

Metrics Service

    |

    ▼

Optimized Queries

```

---

## `dashoard/services/metrics.service.ts`

```typescript id="metrics-service"

import {

sanityClient

}

from "@/infrastructure";



export class MetricsService {



async getAttendanceCount(

eventId:string

){


return await sanityClient.fetch(

`

count(

*[
_type=="attendance"

&&

eventId==$eventId

]

)

`,

{

eventId

}

);


}




async getRecentCheckIns(

eventId:string

){


return await sanityClient.fetch(

`

*[
_type=="attendance"

&&

eventId==$eventId

]

| order(
checkedInAt desc
)

[0...10]

`,

{

eventId

}

);


}


}
```

---

# 11.5 Why Separate Metrics?

Avoid this:

```typescript id="ad-dashoard"

Dashoard Component

       |

       ├── Sanity Query

       ├── usiness Logic

       ├── Formatting

       └── Rendering

```

etter:

```text id="clean-dashoard"

Component

    |

    ▼

Metrics Service

    |

    ▼

Data Source

```

---

# 11.6 Attendance Counter Component

## `dashoard/components/attendance-counter.tsx`

```typescript id="counter"

"use client";


import {

useEffect,

useState

}

from "react";



export function AttendanceCounter({

eventId

}:{

eventId:string;

}){


const [

count,

setCount

]

=

useState(0);



useEffect(()=>{


const interval =

setInterval(async()=>{


const response =

await fetch(

`/api/events/${eventId}/attendance`

);



const data =

await response.json();



setCount(
data.count
);



},5000);



return ()=>clearInterval(interval);



},[eventId]);



return (

<div>


<h2>

Live Attendance

</h2>


<p>

{count}

attendees

</p>


</div>

);


}
```

---

# Development Version vs Production Version

The polling approach works:

```text id="polling"

Dashoard

    |

Every 5 seconds

    |

API Request

```

ut at scale:

```text id="polling-scale"

1,000 dashoards

×

12 requests/minute

=

12,000 requests/minute

```

A real system should use push.

---

# 11.7 Real-Time Architecture

Production approach:

```text id="realtime"

Attendance Event

       |

       ▼

Inngest

       |

       ▼

Realtime Provider

       |

       ▼

WeSocket Channel

       |

       ▼

Dashoard Clients

```

---

# 11.8 Realtime Adapter

The application should not depend directly on Pusher or Aly.

Create an astraction.

---

## `dashoard/services/realtime.service.ts`

```typescript id="realtime-service"

export interface RealtimePulisher {


pulish(

channel:string,

event:string,

payload:any

):

Promise<void>;



}
```

---

# Provider Implementation Example

## Pusher Adapter

```typescript id="pusher-adapter"

export class PusherRealtimePulisher

implements RealtimePulisher {



async pulish(

channel:string,

event:string,

payload:any

){


/*

Pusher SDK call

*/


console.log({

channel,

event,

payload

});


}



}
```

---

# Why Adapter Pattern?

Today:

```text
Pusher
```

Tomorrow:

```text
Aly

AWS AppSync

Socket.IO

```

No application rewrite.

---

# 11.9 Inngest Dashoard Step

Extend the workflow.

---

## `workflows/attendance/checkin.workflow.ts`

Add:

```typescript id="roadcast-step"

await step.run(

"roadcast-attendance",

async()=>{


await realtime.pulish(

`event:${eventId}`,

"attendance.updated",

{

eventId,

userId

}

);


}

);

```

---

# Workflow Now

```text id="workflow-dashoard"

Attendance Created

        |

        ▼

Inngest

        |

 ┌──────┼─────────┐

 ▼      ▼         ▼

Email Analytics Realtime

                  |

                  ▼

              Dashoard

```

---

# 11.10 Dashoard Page

## `app/dashoard/events/[id]/page.tsx`

```typescript id="dashoard-page"

import {

MetricsService

}

from "@/dashoard/services/metrics.service";


import {

AttendanceCounter

}

from "@/dashoard/components/attendance-counter";



export default async function DashoardPage({

params

}:{

params:
Promise<{
id:string
}>

}){


const {

id

}

=

await params;



const metrics =

new MetricsService();



const count =

await metrics
.getAttendanceCount(
id
);



return (

<main>


<h1>

Event Dashoard

</h1>



<AttendanceCounter

eventId={id}

/>


<p>

Initial Count:

{count}

</p>



</main>

);


}
```

---

# 11.11 Operational Monitoring

A production dashoard should expose:

## System Health

```text id="health"

Workflow Success:

99.98%


Average Check-In Time:

180ms


Failed Notifications:

12

```

---

## Attendance Health

```text id="attendance-health"

Expected:

5000


Current:

3742


Arrival Rate:

45/min

```

---

# 11.12 Event Metrics Model

For very large events:

Do not count documents every time.

Instead maintain aggregates.

Example:

```text id="aggregate"

attendance_counter

{

eventId:

"evt123",


count:

3742,


updatedAt:

timestamp

}

```

Update:

```text id="counter-update"

Attendance Event

        |

        ▼

Increment Counter

```

---

# 11.13 Scaling Consideration

For:

## Small Event

```
500 attendees

Sanity count()
```

is acceptale.

---

## Large Conference

```
50,000 attendees

Use:

- Redis counters
- Event streams
- Aggregated metrics
```

---

# 11 Summary

The platform now provides:

✅ Live attendance count
✅ Organizer dashoard
✅ Real-time updates
✅ Metrics astraction
✅ Event-driven roadcasting
✅ Scalale monitoring pattern

---

# Updated Production Architecture

```text id="complete-platform"

                    QR Code

                       |

                Next.js App Router

                       |

                 Server Actions

                       |

              Attendance Service

                       |

                  Domain Rules

                       |

                 Sanity Storage

                       |

                  Inngest

          ┌────────────┼────────────┐

          ▼            ▼            ▼

       Email       Analytics     Realtime

                                     |

                                     ▼

                              Organizer Dashoard

```

---

# Next: Offline-First PWA Check-In

We will implement the final resilience layer:

```text id="pwa-structure"

pwa/

├── service-worker.ts

├── offline-queue.ts

├── sync-manager.ts

└── manifest.ts

```

This covers:

* weak venue Wi-Fi,
* moile network failures,
* queued check-ins,
* ackground synchronization,
* reliale door-entry experience.
