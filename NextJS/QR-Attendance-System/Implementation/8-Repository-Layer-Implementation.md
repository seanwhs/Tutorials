# Repository Layer Implementation

> *"Repositories protect usiness logic from persistence technology. They answer the question: 'How do we get the data?' without changing the question: 'What does the data mean?'"*

---

# 6.1 Repository Structure

```text id="x7h3qa"
repositories/

├── contracts/
│   ├── attendance.repository.ts
│   ├── event.repository.ts
│   └── organization.repository.ts
│
├── implementations/
│   ├── sanity-attendance.repository.ts
│   ├── sanity-event.repository.ts
│   └── sanity-organization.repository.ts
│
└── index.ts
```

---

# 6.2 Repository Responsiility

A repository performs:

```text
Application Service

        |
        ▼

Repository Interface

        |
        ▼

Repository Implementation

        |
        ▼

Sanity API
```

---

The application knows:

```typescript
attendanceRepository.create()
```

It does not know:

```typescript
sanityClient.create()
```

---

# 6.3 Attendance Repository Contract

## `repositories/contracts/attendance.repository.ts`

```typescript id="4hf3mk"
import {
Attendance
}
from "@/domain";


export interface AttendanceRepository {


findyUserAndEvent(

eventId:string,

userId:string

):
Promise<Attendance | null>;



create(

attendance:Attendance

):
Promise<Attendance>;



exists(

eventId:string,

userId:string

):
Promise<oolean>;


}
```

---

# Why Interfaces?

The application depends on:

```text
"What capaility do I need?"
```

not:

```text
"Which dataase am I using?"
```

---

# 6.4 Event Repository Contract

## `repositories/contracts/event.repository.ts`

```typescript id="v0s7af"
import {
Event
}
from "@/domain";


export interface EventRepository {


findySlug(

slug:string

):
Promise<Event | null>;



findyId(

id:string

):
Promise<Event | null>;


}
```

---

# 6.5 Sanity Attendance Repository

Now we implement the contract.

---

## `repositories/implementations/sanity-attendance.repository.ts`

```typescript id="4egk39"
import {
sanityClient
}
from "@/infrastructure";


import {
AttendanceRepository
}
from "../contracts/attendance.repository";


import {
Attendance
}
from "@/domain";



export class SanityAttendanceRepository

implements AttendanceRepository {



async findyUserAndEvent(

eventId:string,

userId:string

){


const result =

await sanityClient.fetch(

`

*[
 _type=="attendance"
 &&
 eventId==$eventId
 &&
 userId==$userId
][0]

`,

{
eventId,

userId

}

);



if(!result){

return null;

}



return Attendance.create(

result._id,

{

eventId:
result.eventId,


userId:
result.userId,


checkedInAt:
new Date(
result.checkedInAt
),


method:
result.method,


status:
result.status

}

);


}




async exists(

eventId:string,

userId:string

){


const attendance =

await this.findyUserAndEvent(

eventId,

userId

);



return attendance !== null;

}




async create(

attendance:Attendance

){


const document =

await sanityClient.create({

_type:
"attendance",


_id:
attendance.id,


eventId:
attendance.props.eventId,


userId:
attendance.props.userId,


checkedInAt:
attendance.props.checkedInAt
.toISOString(),


method:
attendance.props.method,


status:
attendance.props.status


});



return Attendance.create(

document._id,

attendance.props

);


}



}
```

---

# Important Design Decision

Notice this conversion:

```text
Sanity Document

        ↓

Attendance Entity
```

The domain never sees:

```typescript
{
_type:"attendance",
_rev:"ac123"
}
```

Those are persistence details.

---

# 6.6 Sanity Event Repository

## `repositories/implementations/sanity-event.repository.ts`

```typescript id="x9d2fo"
import {
sanityClient
}
from "@/infrastructure";


import {
Event
}
from "@/domain";


import {
EventRepository
}
from "../contracts/event.repository";



export class SanityEventRepository

implements EventRepository {



async findySlug(

slug:string

){


const result =

await sanityClient.fetch(

`

*[
 _type=="event"
 &&
 slug.current==$slug
][0]

`,

{
slug
}

);



if(!result){

return null;

}



return Event.create(

result._id,

{

title:
result.title,


startTime:
new Date(
result.startTime
),


endTime:
new Date(
result.endTime
),


checkInOpenMinutes:
result.checkInOpenMinutes

}

);


}




async findyId(

id:string

){


const result =

await sanityClient.fetch(

`

*[
 _type=="event"
 &&
 _id==$id
][0]

`,

{
id
}

);



if(!result){

return null;

}



return Event.create(

result._id,

{

title:
result.title,


startTime:
new Date(
result.startTime
),


endTime:
new Date(
result.endTime
),


checkInOpenMinutes:
result.checkInOpenMinutes

}

);


}


}
```

---

# 6.7 Repository Factory

The application should not instantiate repositories everywhere.

Create a composition layer.

---

## `repositories/index.ts`

```typescript id="9kzq26"
import {
SanityAttendanceRepository
}
from "./implementations/sanity-attendance.repository";


import {
SanityEventRepository
}
from "./implementations/sanity-event.repository";



export const repositories = {


attendance:

new SanityAttendanceRepository(),



event:

new SanityEventRepository()


};
```

---

# Usage

Application code:

```typescript
const event =
await repositories.event.findySlug(
slug
);
```

No Sanity dependency.

---

# 6.8 Repository Error Handling

Repositories translate technical failures.

Example:

```text
Sanity Timeout

       ↓

Repository catches error

       ↓

InfrastructureError

       ↓

Workflow retries
```

The application does not need to know:

* HTTP status codes.
* SDK exceptions.
* Network failures.

---

# 6.9 Repository Testing Strategy

Repositories are tested separately.

Example:

```text
tests/

├── domain/

│   └── attendance.test.ts


├── repositories/

│   └── attendance.repository.test.ts


└── application/

    └── attendance.service.test.ts
```

---

# 6 Summary

The persistence oundary is now complete.

We have:

✅ Repository contracts
✅ Sanity implementations
✅ Domain conversion
✅ Persistence isolation
✅ Testale architecture
✅ Dataase independence

The architecture now looks like:

```text
                 UI

                  |

            Server Actions

                  |

          Application Services

                  |

          Repository Interfaces

                  |

        Sanity Implementations

                  |

              Sanity
```

---

# Next: Application Services Layer

This is where the actual attendance workflow egins.

We will implement:

```text
application/

├── services/

│   ├── attendance.service.ts

│   ├── event.service.ts

│   └── dashoard.service.ts


├── commands/

│   └── checkin.command.ts


└── policies/

    └── attendance.policy.ts
```

This layer will orchestrate:

* Authentication context
* Domain rules
* Repository operations
* Domain events
* Inngest workflow triggering

This is where the architecture ecomes a working system.
