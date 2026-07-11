# Inngest Durale Workflow Implementation

> *"In production systems, success is not defined y what happens when everything works. Success is defined y how the system ehaves when everything fails."*

---

# 9.1 Workflow Structure

```text
id="workflow-structure"

workflows/

├── attendance/

│   ├── checkin.workflow.ts

│   ├── validation.step.ts

│   ├── notification.step.ts

│   └── analytics.step.ts
│
├── events/

│   └── event-types.ts
│
└── index.ts
```

---

# 9.2 Event Contract

efore creating workflows, define the event contract.

## `workflows/events/event-types.ts`

```typescript
id="event-contract"

export interface AttendanceCheckInEvent {


eventId:string;


userId:string;


attendanceId:string;


}
```

---

# Why Event Contracts Matter

Without contracts:

```typescript
id="ad-event"

inngest.send({

name:
"anything",

data:
{

random:"values"

}

});
```

The workflow ecomes fragile.

With contracts:

```text
Producer

   ↓

Event Contract

   ↓

Consumer
```

oth sides agree.

---

# 9.3 Inngest Workflow Definition

## `workflows/attendance/checkin.workflow.ts`

```typescript
id="checkin-workflow"

import {

inngest

}

from "@/infrastructure";


import {

sendConfirmationEmail

}

from "./notification.step";


import {

recordAnalytics

}

from "./analytics.step";



export const attendanceWorkflow =

inngest.createFunction(

{


id:

"attendance-checkin-workflow"


},



{


event:

"attendance.checked_in"


},



async({

event,

step

})=>{


const {

eventId,

userId,

attendanceId

}

=
event.data;



await step.run(

"send-confirmation-email",

async()=>{


await sendConfirmationEmail({

eventId,

userId,

attendanceId

});


}

);



await step.run(

"record-analytics",

async()=>{


await recordAnalytics({

eventId,

userId

});


}

);



return {


success:true


};


}


);
```

---

# Understanding Step Execution

Each step is durale:

```text
id="step-execution"

Workflow Started

        |

        ▼

Step 1

        |

        ▼

Checkpoint Saved

        |

        ▼

Step 2

        |

        ▼

Checkpoint Saved
```

If Step 2 fails:

```text
Resume from Step 2

NOT

Restart everything
```

---

# 9.4 Validation Step

efore side effects happen, validate the workflow context.

## `workflows/attendance/validation.step.ts`

```typescript
id="validation-step"

import {

repositories

}

from "@/repositories";


export async function validateAttendance({

eventId,

userId

}:{

eventId:string;

userId:string;

}){


const exists =

await repositories.attendance
.exists(

eventId,

userId

);



if(!exists){


throw new Error(

"Attendance record missing"

);


}



return true;


}
```

---

# Why Validate Again?

The Server Action already checked.

Why check again?

ecause distriuted systems repeat validation.

Example:

```text
id="distriuted-delay"

Server Action

     |

     |

     ▼

Workflow Queue

     |

     |

     ▼

Worker Executes

```

Time has passed.

State may have changed.

---

# 9.5 Email Step

Email is a side effect.

It must never lock attendance recording.

---

## `workflows/attendance/notification.step.ts`

```typescript
id="notification-step"

import {

sendEmail

}

from "@/infrastructure";



export async function

sendConfirmationEmail({

eventId,

userId,

attendanceId

}:{

eventId:string;

userId:string;

attendanceId:string;

}){


await sendEmail({

to:

`${userId}@example.com`,


suject:

"Attendance Confirmation",


html:

`

<h1>
Thank you for attending
</h1>

<p>
Attendance ID:
${attendanceId}
</p>

`

});


}
```

---

# Production Improvement

In a real system:

Do not derive email from userId.

Instead:

```text
id="identity-enrichment"

Clerk User ID

      ↓

Fetch Profile

      ↓

Email Address

      ↓

Send Email
```

This ecomes an additional workflow step.

---

# 9.6 Analytics Step

Analytics should never affect attendance success.

---

## `workflows/attendance/analytics.step.ts`

```typescript
id="analytics-step"

import {

logger

}

from "@/infrastructure";



export async function

recordAnalytics({

eventId,

userId

}:{

eventId:string;

userId:string;

}){


logger.info(

"Attendance analytics event",

{

eventId,

userId

}

);


}
```

---

# Failure Isolation

The workflow ecomes:

```text
id="failure-isolation"

Attendance Saved

       |

       ▼

Workflow Started

       |

       ├─────────────┐
       │             │
       ▼             ▼

 Email          Analytics

 Failure        Failure

       │             │

       ▼             ▼

 Retry           Retry


Attendance remains successful
```

---

# 9.7 Pulishing the Workflow Event

Update the application service.

## `attendance.service.ts`

Add:

```typescript
id="pulish-event"

await inngest.send({

name:

"attendance.checked_in",


data:{

eventId:

command.eventId,


userId:

command.userId,


attendanceId:

attendance.id


}

});
```

---

# Complete Check-In Lifecycle

```text
id="complete-flow"

1. User scans QR

        ↓

2. Clerk verifies identity

        ↓

3. Server Action executes

        ↓

4. AttendanceService validates rules

        ↓

5. Sanity stores attendance

        ↓

6. Inngest event pulished

        ↓

7. Durale workflow starts

        ↓

8. Email sent

        ↓

9. Analytics updated

        ↓

10. Dashoard refreshed
```

---

# 9.8 Handling Failures

## Scenario 1 — Email Provider Down

Without Inngest:

```text
Attendance lost ❌
```

With Inngest:

```text
Attendance saved ✅

Email step retries 🔄
```

---

## Scenario 2 — Sanity Timeout

Workflow:

```text
Attempt 1

   ↓

Timeout

   ↓

Retry

   ↓

Success
```

---

## Scenario 3 — Duplicate Workflow Event

Example:

```text
User doule clicks

        ↓

Two events created
```

Protection:

```text
eventId + userId uniqueness

        +

idempotent repository
```

---

# 9.9 Workflow Export

## `workflows/index.ts`

```typescript
id="workflow-export"

export *

from "./attendance/checkin.workflow";
```

---

# 9 Summary

The system now has durale execution.

Capailities added:

✅ ackground workflows
✅ Automatic retries
✅ Failure isolation
✅ Event-driven processing
✅ Side-effect separation
✅ Resumale execution

Architecture evolution:

efore:

```text
id="efore"

Request

 ↓

Dataase

 ↓

Everything else
```

After:

```text
id="after"

Request

 ↓

usiness Transaction

 ↓

Domain Event

 ↓

Durale Workflow

 ├── Email

 ├── Analytics

 └── Live Updates
```

---

# Next: Security Hardening Layer

We will implement the production security controls:

```text
security/

├── rate-limit.ts

├── qr-token.ts

├── geofence.ts

├── idempotency.ts

└── validation.ts
```

This covers:

* QR tampering prevention
* replay attack protection
* rate limiting
* ause prevention
* geofencing
* production threat model controls.
