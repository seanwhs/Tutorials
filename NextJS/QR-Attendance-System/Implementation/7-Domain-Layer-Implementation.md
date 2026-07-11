Continuing the reference implementation.

We now move into the **Domain Layer**.

This is one of the most important architectural boundaries in the entire system.

The previous appendix defined **how data is stored**.

This appendix defines:

* What the business objects mean.
* What rules they enforce.
* What states are valid.
* What operations are allowed.

The domain layer should be independent of:

* Next.js
* React
* Clerk
* Sanity
* Inngest
* Redis

It represents the business itself.

---

# Appendix B5 — Domain Layer Implementation

> *"The domain layer is where the system's knowledge lives. Frameworks change. Business rules survive."*

---

# B5.1 Domain Structure

```text
domain/

├── attendance/
│   ├── attendance.entity.ts
│   ├── attendance-status.ts
│   ├── attendance.errors.ts
│   └── attendance.factory.ts
│
├── event/
│   ├── event.entity.ts
│   ├── event-policy.ts
│   └── event.errors.ts
│
├── organization/
│   └── organization.entity.ts
│
├── shared/
│   ├── entity.ts
│   ├── value-object.ts
│   └── domain-event.ts
│
└── index.ts
```

---

# B5.2 Shared Entity Base

Every business entity has:

* Identity.
* Creation timestamp.
* Equality rules.

---

## `domain/shared/entity.ts`

```typescript
export abstract class Entity<T> {

  protected constructor(
    public readonly id: string,
    public readonly props: T
  ) {}


  equals(
    entity?: Entity<T>
  ){

    if(!entity){
      return false;
    }


    return this.id === entity.id;

  }

}
```

---

# Why Entities?

A common mistake:

```typescript
{
 id:"123",
 name:"Conference"
}
```

is treated as the object.

But business objects have behavior:

```text
Event

 ├── CanCheckIn()

 ├── IsActive()

 ├── HasEnded()

 └── IsAccessible()
```

---

# B5.3 Value Object Base

Some concepts do not have identity.

Examples:

* Email address.
* Date range.
* Coordinates.

---

## `domain/shared/value-object.ts`

```typescript
export abstract class ValueObject<T>{


protected constructor(
 public readonly value:T
){}



equals(
other?:ValueObject<T>
){

if(!other){
 return false;
}


return JSON.stringify(
 this.value
)
===
JSON.stringify(
 other.value
);

}


}
```

---

# B5.4 Attendance Status

## `domain/attendance/attendance-status.ts`

```typescript
export enum AttendanceStatus {


PRESENT =
"present",


CANCELLED =
"cancelled",


REVOKED =
"revoked"


}
```

---

# Why Status Exists

Avoid:

```typescript
status:"yes"
```

or:

```typescript
active:true
```

Business states should be explicit.

---

# B5.5 Attendance Entity

## `domain/attendance/attendance.entity.ts`

```typescript
import {
Entity
}
from "../shared/entity";


import {
AttendanceStatus
}
from "./attendance-status";


export interface AttendanceProps {


eventId:string;


userId:string;


checkedInAt:Date;


method:string;


status:AttendanceStatus;

}



export class Attendance

extends Entity<AttendanceProps>{



private constructor(

id:string,

props:AttendanceProps

){

super(
id,
props
);

}



static create(

id:string,

props:AttendanceProps

){

return new Attendance(
id,
props
);

}



revoke(){

this.props.status =
AttendanceStatus.REVOKED;

}



isActive(){

return (

this.props.status ===
AttendanceStatus.PRESENT

);

}


}
```

---

# Domain Rule

Attendance is not just a database record.

It has behavior.

Example:

```typescript
attendance.revoke();
```

is meaningful.

This is better than:

```typescript
attendance.status="revoked";
```

because the domain controls state changes.

---

# B5.6 Event Entity

Events control check-in availability.

---

## `domain/event/event.entity.ts`

```typescript
import {
Entity
}
from "../shared/entity";



export interface EventProps {


title:string;


startTime:Date;


endTime:Date;


checkInOpenMinutes:number;


}



export class Event

extends Entity<EventProps>{



isCheckInOpen(

currentTime:Date

){


const openTime =

new Date(

this.props.startTime.getTime()

-

this.props.checkInOpenMinutes
*
60
*
1000

);



return (

currentTime >= openTime

&&

currentTime <= this.props.endTime

);


}



hasEnded(

currentTime:Date

){

return (

currentTime >
this.props.endTime

);


}


}
```

---

# Business Rule Example

The UI should not decide:

```typescript
if(time < event.startTime)
```

The domain decides:

```typescript
event.isCheckInOpen(now)
```

---

# B5.7 Event Policy

Policies handle rules that do not belong to one entity.

Example:

"Can this user check into this event?"

---

## `domain/event/event-policy.ts`

```typescript
import {
Event
}
from "./event.entity";



export class EventPolicy {



static canCheckIn(

event:Event,

now:Date

){

return event
.isCheckInOpen(now);

}


}
```

---

# Why Policies?

Some rules are cross-cutting.

Example:

```text
Event

+

User Role

+

Registration Status

+

Venue Rules
```

A policy keeps these decisions organized.

---

# B5.8 Domain Errors

## `domain/event/event.errors.ts`

```typescript
export class EventNotActiveError

extends Error{


constructor(){

super(
"Event is not available for check-in"
);

this.name =
"EventNotActiveError";

}


}
```

---

# Why Domain Errors?

Different failures require different handling.

Example:

```text
Event Closed

↓

User Message

"Check-in has ended"


Database Failure

↓

Retry Workflow
```

---

# B5.9 Attendance Factory

Factories protect object creation.

---

## `domain/attendance/attendance.factory.ts`

```typescript
import {
Attendance
}
from "./attendance.entity";


import {
AttendanceStatus
}
from "./attendance-status";


export function createAttendance({

id,

eventId,

userId

}:{

id:string;

eventId:string;

userId:string;

}){


return Attendance.create(

id,

{

eventId,

userId,


checkedInAt:
new Date(),


method:
"qr",


status:
AttendanceStatus.PRESENT

}

);


}
```

---

# Why Factories?

Without factories:

```typescript
new Attendance(
...
)
```

can create invalid objects.

Factories enforce creation rules.

---

# B5.10 Domain Event

Business events allow loose coupling.

---

## `domain/shared/domain-event.ts`

```typescript
export interface DomainEvent {


name:string;


occurredAt:Date;


payload:
Record<string,unknown>;


}
```

---

Example:

```typescript
{

name:

"attendance.checked_in",


payload:{

eventId,

userId

}

}
```

---

This event can later trigger:

```text
Attendance Checked In

        ↓

Email

        ↓

Analytics

        ↓

Dashboard Update
```

---

# B5.11 Domain Export

## `domain/index.ts`

```typescript
export *

from "./attendance/attendance.entity";


export *

from "./attendance/attendance-status";


export *

from "./event/event.entity";


export *

from "./event/event-policy";


export *

from "./shared/entity";


export *

from "./shared/value-object";


export *

from "./shared/domain-event";
```

---

# B5 Summary

The domain layer now provides:

✅ Business entities
✅ Explicit states
✅ Check-in rules
✅ Domain validation
✅ Domain events
✅ Framework independence

The architecture now looks like:

```text
                Domain

                  ▲

                  |

          Application Layer

                  ▲

                  |

          Infrastructure
```

The core business rules are protected from technology changes.

---

# Next: Repository Layer Implementation

We now connect the domain to Sanity through repositories:

```text
repositories/

├── attendance.repository.ts

├── event.repository.ts

├── organization.repository.ts

└── implementations/

    ├── sanity-attendance.repository.ts

    └── sanity-event.repository.ts
```

This is where the system implements **persistence without leaking Sanity into the business layer**.
