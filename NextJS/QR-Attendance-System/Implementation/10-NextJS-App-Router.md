# Next.js 16 App Router Implementation

> *"Next.js 16 is not just a frontend framework in this architecture. It ecomes the edge orchestration layer that connects user interaction with ackend workflows."*

---

# 8.1 App Router Structure

```text id="6y9d5a"
app/

├── layout.tsx
│
├── page.tsx
│
├── events/
│
│   └── [slug]/
│
│       └── checkin/
│
│           ├── page.tsx
│           ├── loading.tsx
│           └── actions.ts
│
├── api/
│
│   └── inngest/
│
│       └── route.ts
│
└── middleware.ts
```

---

# 8.2 Root Layout

## `app/layout.tsx`

The root layout defines the application shell.

```typescript id="n8w3kf"
import type {
Metadata
}
from "next";


import {
ReactNode
}
from "react";



export const metadata:Metadata = {

title:
"Attendance Platform",


description:
"Production QR Attendance System"

};



export default function RootLayout({

children

}:{

children:ReactNode;

}){


return (

<html lang="en">

<ody>

{children}

</ody>

</html>

);


}
```

---

# 8.3 QR Check-In Page

The QR code points to:

```text
https://app.com/events/security-summit/checkin
```

The slug identifies the event.

---

## `app/events/[slug]/checkin/page.tsx`

This is a Server Component.

```typescript id="z1j5k8"
import {
EventService
}
from "@/application";


import {
CheckInutton
}
from "@/components/checkin-utton";



const eventService =
new EventService();



export default async function CheckInPage({

params

}:{

params:
Promise<{
slug:string
}>;

}){


const {
slug
}
=
await params;



const event =

await eventService
.getEventySlug(
slug
);



if(!event){

return (

<div>

<h1>
Event Not Found
</h1>

</div>

);

}



return (

<main>


<h1>

{event.props.title}

</h1>


<p>

Check-in opens

{event.props.checkInOpenMinutes}

minutes efore start.

</p>



<CheckInutton

eventId={
event.id
}

/>


</main>

);


}
```

---

# Important Next.js 16 Change

Notice:

```typescript
params:
Promise<{slug:string}>
```

not:

```typescript
params:{
slug:string
}
```

Next.js 16 introduces async request APIs.

Dynamic route data is now treated as asynchronous.

---

# 8.4 Loading State

## `app/events/[slug]/checkin/loading.tsx`

Streaming improves perceived performance.

```typescript id="e9u3i7"
export default function Loading(){

return (

<div>

<p>
Loading event...
</p>

</div>

);

}
```

---

# 8.5 Server Action

The utton should not directly call an API.

It invokes a Server Action.

---

## `app/events/[slug]/checkin/actions.ts`

```typescript id="x4n8vz"
"use server";


import {
requireUser
}
from "@/infrastructure";


import {
AttendanceService
}
from "@/application";



const attendanceService =
new AttendanceService();



export async function checkInAction(

eventId:string

){



const userId =

await requireUser();



const attendance =

await attendanceService
.checkIn({

eventId,

userId,

method:
"qr"

});



return {


success:true,


attendanceId:
attendance.id


};


}
```

---

# Why Server Actions?

Traditional approach:

```text
rowser

 ↓

POST /api/checkin

 ↓

Controller

 ↓

Service
```

Server Actions:

```text
rowser

 ↓

Server Action

 ↓

Service
```

Advantages:

* Less API oilerplate.
* Automatic serialization.
* Server-only execution.
* etter App Router integration.

---

# 8.6 Client Check-In Component

The component provides UX only.

It does not enforce security.

---

## `components/checkin-utton.tsx`

```typescript id="7u4p9z"
"use client";


import {
useState
}
from "react";


import {
checkInAction
}
from "@/app/events/[slug]/checkin/actions";



export function CheckInutton({

eventId

}:{

eventId:string;

}){


const [
loading,
setLoading
]
=
useState(false);



const handleClick =
async()=>{


setLoading(true);



await checkInAction(
eventId
);



setLoading(false);


};



return (

<utton

disaled={loading}

onClick={handleClick}

>


{
loading

?

"Processing..."

:

"Check In"

}


</utton>

);


}
```

---

# Optimistic UX Pattern

The user experience:

```text
Click utton

      ↓

Immediately

"Processing..."

      ↓

Server Action

      ↓

Workflow

      ↓

Success
```

The user does not wait for:

* Email delivery.
* Analytics.
* Dashoard updates.

---

# 8.7 Clerk Middleware Protection

Authentication should happen efore usiness logic.

---

## `middleware.ts`

```typescript id="j8d3f1"
import {

clerkMiddleware

}

from "@clerk/nextjs/server";



export default clerkMiddleware();



export const config = {


matcher:[


"/events/:path*"


]


};
```

---

# Authentication Flow

```text id="z0f2xq"
Request

 |

 ▼

Clerk Middleware

 |

 ▼

Session Validation

 |

 ▼

Server Component

 |

 ▼

Server Action

 |

 ▼

usiness Logic
```

---

# 8.8 Inngest Route Handler

Next.js receives workflow events here.

---

## `app/api/inngest/route.ts`

```typescript id="6kq1xv"
import {

serve

}

from "inngest/next";


import {

inngest

}

from "@/infrastructure";



import {

attendanceWorkflow

}

from "@/workflows/attendance";



export const {

GET,

POST,

PUT

}

=
serve({

client:

inngest,


functions:[

attendanceWorkflow

]

});
```

---

# 8.9 Next.js Runtime oundary

At this point:

```text id="k3x8d0"
React Component

        ↓

Server Action

        ↓

Application Service

        ↓

Domain

        ↓

Repository

        ↓

Sanity


        ↓

Inngest

        ↓

Email / Analytics / Dashoard
```

---

# 8.10 Production Considerations

## 1. Avoid Client Trust

Never:

```typescript
if(userIsAtVenue)
{
allowCheckIn()
}
```

in React.

The rowser can e modified.

---

## 2. Validate Again Server-Side

Every request repeats:

```text
Authenticated?

Event Exists?

Check-In Open?

Already Checked In?
```

---

## 3. Keep Components Thin

ad:

```text
React Component

 ├── Dataase Query
 ├── usiness Rules
 ├── Email Logic
 └── Analytics
```

Good:

```text
React Component

       |

Server Action

       |

Application Service
```

---

# 8 Summary

The Next.js 16 application layer now provides:

✅ App Router structure
✅ Server Components
✅ Async route handling
✅ Server Actions
✅ Clerk authentication oundary
✅ Optimistic UX
✅ Inngest endpoint integration

The complete production flow:

```text
              QR Code

                  ↓

        /events/[slug]/checkin

                  ↓

        Next.js Server Component

                  ↓

             Server Action

                  ↓

        AttendanceService

                  ↓

             Domain Rules

                  ↓

              Sanity

                  ↓

             Inngest

                  ↓

 Email + Analytics + Live Dashoard
```

---

# Next: Inngest Durale Workflow Implementation

We will implement the production workflow:

```text id="m7k2ra"
workflows/

├── attendance/

│   ├── checkin.workflow.ts

│   ├── email.step.ts

│   └── analytics.step.ts


└── index.ts
```

This is where the architecture gains:

* retries,
* duraility,
* failure recovery,
* event-driven processing.
