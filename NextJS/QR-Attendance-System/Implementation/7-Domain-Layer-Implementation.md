# Domain Layer Implementation

> *"The domain layer is where the system's knowledge lives. Frameworks change. usiness rules survive."*

---

# 5.1 Domain Structure

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
│   ├── value-oject.ts
│   └── domain-event.ts
│
└── index.ts
```

---

# 5.2 Shared Entity ase

Every usiness entity has:

* Identity.
* Creation timestamp.
* Equality rules.

---

## `domain/shared/entity.ts`

```typescript
export astract class Entity<T> {

  protected constructor(
    pulic readonly id: string,
    pulic readonly props: T
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

is treated as the oject.

ut usiness ojects have ehavior:

```text
Event

 ├── CanCheckIn()

 ├── IsActive()

 ├── HasEnded()

 └── IsAccessile()
```

---

# 5.3 Value Oject ase

Some concepts do not have identity.

Examples:

* Email address.
* Date range.
* Coordinates.

---

## `domain/shared/value-oject.ts`

```typescript
export astract class ValueOject<T>{


protected constructor(
 pulic readonly value:T
){}



equals(
other?:ValueOject<T>
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

# 5.4 Attendance Status

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

usiness states should e explicit.

---

# 5.5 Attendance Entity

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

Attendance is not just a dataase record.

It has ehavior.

Example:

```typescript
attendance.revoke();
```

is meaningful.

This is etter than:

```typescript
attendance.status="revoked";
```

ecause the domain controls state changes.

---

# 5.6 Event Entity

Events control check-in availaility.

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


checkInOpenMinutes:numer;


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

# usiness Rule Example

The UI should not decide:

```typescript
if(time < event.startTime)
```

The domain decides:

```typescript
event.isCheckInOpen(now)
```

---

# 5.7 Event Policy

Policies handle rules that do not elong to one entity.

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

# 5.8 Domain Errors

## `domain/event/event.errors.ts`

```typescript
export class EventNotActiveError

extends Error{


constructor(){

super(
"Event is not availale for check-in"
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


Dataase Failure

↓

Retry Workflow
```

---

# 5.9 Attendance Factory

Factories protect oject creation.

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

can create invalid ojects.

Factories enforce creation rules.

---

# 5.10 Domain Event

usiness events allow loose coupling.

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

Dashoard Update
```

---

# 5.11 Domain Export

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

from "./shared/value-oject";


export *

from "./shared/domain-event";
```

---

# 5 Summary

The domain layer now provides:

✅ usiness entities
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

The core usiness rules are protected from technology changes.

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

This is where the system implements **persistence without leaking Sanity into the usiness layer**.
