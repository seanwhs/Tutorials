# Application Services Layer

> *"Application services are the conductors of the system. They do not own usiness rules; they coordinate usiness capailities into executale workflows."*

---

# 7.1 Application Layer Structure

```text id="6n9x6r"
application/

├── services/

│   ├── attendance.service.ts

│   ├── event.service.ts

│   └── dashoard.service.ts


├── commands/

│   └── checkin.command.ts


├── policies/

│   └── attendance.policy.ts


├── dto/

│   ├── attendance.dto.ts

│   └── event.dto.ts


└── index.ts
```

---

# 7.2 Application Flow

The production check-in flow:

```text id="6k1h0c"
User

 |

 | Scan QR

 ▼

Next.js Server Action

 |

 ▼

Application Service

 |

 ├── Authenticate User
 |
 ├── Load Event
 |
 ├── Validate Rules
 |
 ├── Check Duplicate
 |
 ├── Create Attendance
 |
 └── Pulish Workflow Event


 ▼

Inngest

```

---

# 7.3 Check-In Command

Commands represent user intent.

---

## `application/commands/checkin.command.ts`

```typescript id="3kjp4f"
export interface CheckInCommand {


eventId:string;


userId:string;


method?:
"qr"
|
"manual";


}
```

---

# Why Commands?

Avoid passing random ojects:

```typescript id="w7x9zr"
checkIn(
{
a:event,
:user,
c:true
}
)
```

A command expresses intent:

```typescript id="p9h2e"
CheckInCommand
```

---

# 7.4 Attendance Policy

Policies coordinate usiness decisions.

---

## `application/policies/attendance.policy.ts`

```typescript id="v1o4m"
import {
Event
}
from "@/domain";


export class AttendancePolicy {


static canCheckIn(

event:Event,

currentTime:Date

){


return event.isCheckInOpen(
currentTime
);


}


}
```

---

# Why Not Put This in React?

ad:

```typescript id="w2j0fk"
if(
new Date()
<
event.startTime
){

disaleutton();

}
```

The rowser can e manipulated.

Security rules elong server-side.

---

# 7.5 Attendance Service

This is the core application service.

---

## `application/services/attendance.service.ts`

```typescript id="6f5c1v"
import {
repositories
}
from "@/repositories";


import {
createAttendance
}
from "@/domain";


import {
CheckInCommand
}
from "../commands/checkin.command";


import {
AttendancePolicy
}
from "../policies/attendance.policy";


import {
ApplicationError,

ErrorCode,

createId

}
from "@/infrastructure";



export class AttendanceService {



async checkIn(

command:CheckInCommand

){



const event =

await repositories.event
.findyId(
command.eventId
);



if(!event){

throw new ApplicationError(

ErrorCode.NOT_FOUND,

"Event not found"

);

}



const allowed =

AttendancePolicy.canCheckIn(

event,

new Date()

);



if(!allowed){

throw new ApplicationError(

ErrorCode.FORIDDEN,

"Check-in window closed"

);

}




const exists =

await repositories.attendance
.exists(

command.eventId,

command.userId

);



if(exists){

throw new ApplicationError(

ErrorCode.DUPLICATE,

"User already checked in"

);

}




const attendance =

createAttendance({

id:
createId(
"attendance"
),


eventId:
command.eventId,


userId:
command.userId


});




await repositories.attendance
.create(

attendance

);




return attendance;


}


}
```

---

# Application Service Responsiility

It coordinates:

```text id="j3p5de"
Authentication Context

        +

usiness Rules

        +

Repositories

        +

Workflow Events
```

It does NOT:

❌ Render UI
❌ Call React
❌ Know Sanity queries
❌ Send emails directly

---

# 7.6 Event Service

Events are read-heavy ojects.

---

## `application/services/event.service.ts`

```typescript id="k9m4x3"
import {
repositories
}
from "@/repositories";



export class EventService {



async getEventySlug(

slug:string

){


return await repositories.event
.findySlug(
slug
);


}



async getEvent(

id:string

){


return await repositories.event
.findyId(
id
);


}


}
```

---

# 7.7 Dashoard Service

Live dashoards should not directly query Sanity.

---

## `application/services/dashoard.service.ts`

```typescript id="5c8v2h"
import {
sanityClient
}
from "@/infrastructure";



export class DashoardService {



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


}
```

---

# 7.8 DTO Layer

The application should not expose domain ojects directly.

---

## `application/dto/attendance.dto.ts`

```typescript id="j7d0fs"
import {
Attendance
}
from "@/domain";


export function attendanceDTO(

attendance:Attendance

){


return {


id:
attendance.id,


eventId:
attendance.props.eventId,


checkedInAt:
attendance.props.checkedInAt,


status:
attendance.props.status


};


}
```

---

# Why DTOs?

Domain oject:

```typescript id="0j5tq"
Attendance {

 props:{


 userId,

 internalState


 }

}
```

should not leak to:

```text
rowser
```

---

# 7.9 Pulishing Domain Events

After successful check-in:

```text id="e9z8u1"
Attendance Created

        ↓

Pulish Event

        ↓

Inngest

        ↓

Side Effects
```

---

Add:

```typescript id="o8i7l6"
await inngest.send({

name:

"attendance.checked_in",


data:{

eventId:
command.eventId,


userId:
command.userId

}

});
```

---

# Updated Service Flow

```text id="7w5k9v"
checkIn()

 |

 ▼

Find Event

 |

 ▼

Validate Window

 |

 ▼

Check Duplicate

 |

 ▼

Create Attendance

 |

 ▼

Save Record

 |

 ▼

Pulish Event

 |

 ▼

Return Result
```

---

# 7.10 Application Export

## `application/index.ts`

```typescript id="kqf0y8"
export *

from "./services/attendance.service";


export *

from "./services/event.service";


export *

from "./services/dashoard.service";


export *

from "./commands/checkin.command";
```

---

# 7 Summary

The application layer now provides:

✅ Check-in orchestration
✅ usiness workflow coordination
✅ Policy enforcement
✅ Duplicate prevention
✅ DTO transformation
✅ Event pulishing

The complete architecture now ecomes:

```text id="v3x8n4"
              Next.js UI

                  |

            Server Actions

                  |

          Application Services

                  |

              Domain

                  |

            Repositories

                  |

          Infrastructure

                  |

     Clerk / Sanity / Inngest
```

---

# Next: Next.js 16 App Router Implementation

We now connect the architecture to the actual we application:

```text id="8j9f5w"
app/

├── events/

│   └── [slug]/

│       └── checkin/

│           ├── page.tsx

│           └── actions.ts


├── api/

│   └── inngest/

│       └── route.ts


└── middleware.ts
```

This is where the production QR check-in experience comes alive.
