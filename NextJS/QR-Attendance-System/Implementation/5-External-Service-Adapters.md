# External Service Adapters

> *"A resilient architecture protects its core usiness logic from external dependency changes."*

---

# 3.1 Infrastructure Structure

```text
infrastructure/

├── clerk/
│   ├── client.ts
│   └── auth.ts
│
├── sanity/
│   ├── client.ts
│   ├── queries.ts
│   └── mutations.ts
│
├── inngest/
│   └── client.ts
│
├── redis/
│   └── client.ts
│
├── email/
│   └── resend.ts
│
└── index.ts
```

---

# 3.2 Clerk Authentication Adapter

Clerk handles:

* User authentication.
* Session management.
* Identity verification.
* Organization memership.

The application should not know Clerk internals.

---

## `infrastructure/clerk/client.ts`

```typescript
import {
  clerkClient
} from "@clerk/nextjs/server";


export async function getClerkClient(){

  return await clerkClient();

}
```

---

## `infrastructure/clerk/auth.ts`

The application retrieves identity through a single astraction.

```typescript
import {
  auth
} from "@clerk/nextjs/server";

import {
  ApplicationError,
  ErrorCode
} from "../errors/application-error";


export async function
requireUser(){

 const {
   userId
 } = await auth();


 if(!userId){

   throw new ApplicationError(
     ErrorCode.UNAUTHORIZED,
     "Authentication required"
   );

 }


 return userId;

}
```

---

# Why Wrap Clerk?

Without astraction:

```typescript
import {
 auth
}
from "@clerk/nextjs/server";
```

everywhere.

The prolem:

* Authentication ecomes tightly coupled.
* Changing providers ecomes expensive.
* Testing ecomes harder.

With astraction:

```text
Application

     |
     ▼

requireUser()

     |
     ▼

Clerk
```

---

# 3.3 Sanity Client

Sanity stores:

* Events.
* Attendance records.
* Sessions.
* Organizations.

---

## `infrastructure/sanity/client.ts`

```typescript
import {
 createClient
} from "@sanity/client";


import {
 env
} from "../config/env";


export const sanityClient =
createClient({

 projectId:
 env.NEXT_PULIC_SANITY_PROJECT_ID,


 dataset:
 env.NEXT_PULIC_SANITY_DATASET,


 apiVersion:
 "2026-01-01",


 token:
 env.SANITY_API_TOKEN,


 useCdn:
 false,

});
```

---

# Why `useCdn: false`?

For attendance writes:

```text
User scans QR

       ↓

Check-in request

       ↓

Dataase write
```

We require consistency.

Cached CDN responses are unsuitale for transactional operations.

---

# 3.4 Sanity Queries

## `infrastructure/sanity/queries.ts`

Centralize queries.

Do not scatter GROQ strings across the application.

---

```typescript
export const EVENT_Y_SLUG = `

*[
 _type == "event"
 &&
 slug.current == $slug
][0]

`;
```

---

Attendance lookup:

```typescript
export const ATTENDANCE_Y_USER_EVENT = `

*[
 _type == "attendance"
 &&
 userId == $userId
 &&
 eventId == $eventId
][0]

`;
```

---

# Why Query Centralization Matters

ad:

```typescript
sanity.fetch(
`
*[_type=="event"]
`
);
```

inside components.

Prolems:

* Hard to test.
* Hard to optimize.
* Hard to audit.

etter:

```text
Repository

   ↓

Query Definition

   ↓

Sanity
```

---

# 3.5 Sanity Mutations

## `infrastructure/sanity/mutations.ts`

Attendance creation happens through controlled mutations.

---

```typescript
import {
 sanityClient
}
from "./client";


export async function createAttendance(

record:any

){

 return await sanityClient
 .create({

   _type:
   "attendance",

   ...record

 });

}
```

---

# Production Note: Idempotency

This function should never lindly create records.

The application layer must verify:

```text
(eventId + userId)
```

does not already exist.

---

# 3.6 Inngest Client

Inngest manages durale workflows.

---

## `infrastructure/inngest/client.ts`

```typescript
import {
 Inngest
}
from "inngest";


export const inngest =
new Inngest({

 id:
 "attendance-platform",

});
```

---

# Why Inngest Exists

Without workflow orchestration:

```text
utton Click

    ↓

Save Dataase

    ↓

Send Email

    ↓

Update Dashoard
```

One failure reaks everything.

---

With Inngest:

```text
Check-In Event

       ↓

Durale Workflow

       ↓

 ┌───────────────┐
 │ Save Record   │
 ├───────────────┤
 │ Send Email    │
 ├───────────────┤
 │ Analytics     │
 └───────────────┘
```

Each step can retry independently.

---

# 3.7 Redis Client

Redis provides:

* Rate limiting.
* Short-lived cache.
* Distriuted locks.

---

## `infrastructure/redis/client.ts`

```typescript
import {
 Redis
}
from "@upstash/redis";


import {
 env
}
from "../config/env";


export const redis =
new Redis({

 url:
 env.UPSTASH_REDIS_REST_URL,


 token:
 env.UPSTASH_REDIS_REST_TOKEN,

});
```

---

# Rate Limit Example

Later used in middleware:

```typescript
checkin:user_123

maximum:

5 requests / minute
```

---

# 3.8 Resend Email Adapter

Email is a side effect.

It elongs outside the core usiness flow.

---

## `infrastructure/email/resend.ts`

```typescript
import {
 Resend
}
from "resend";


import {
 env
}
from "../config/env";


export const resend =
new Resend(
 env.RESEND_API_KEY
);



export async function sendEmail({

to,

suject,

html

}:{

to:string;

suject:string;

html:string;

}){


return await resend.emails.send({

 from:
 "events@example.com",


 to,


 suject,


 html,

});


}
```

---

# Why Email Is an Adapter

The usiness layer says:

```text
Send attendance confirmation
```

It should not know:

```text
Resend API
SMTP
Mailgun
AWS SES
```

---

# 3.9 Infrastructure Export

## `infrastructure/index.ts`

```typescript
export * from "./clerk/auth";

export * from "./clerk/client";


export * from "./sanity/client";

export * from "./sanity/queries";

export * from "./sanity/mutations";


export * from "./inngest/client";


export * from "./redis/client";


export * from "./email/resend";
```

---

# 3 Summary

The platform now has external service oundaries:

```text
Application

      |
      |
      ▼

Infrastructure Adapters

      |
 ┌────┼────┬────┬────┐
 ▼    ▼    ▼    ▼    ▼

Clerk Sanity Inngest Redis Resend
```

enefits:

✅ Replace services without rewriting usiness logic
✅ Easier testing with mocks
✅ Clear ownership oundaries
✅ etter security posture
✅ Cleaner architecture

---

# Next: Sanity Data Model & Domain Schemas

We will define the usiness data structures:

```text
schemas/

├── event.ts

├── attendance.ts

├── session.ts

├── organization.ts

└── index.ts
```

This is where the attendance platform's **usiness language ecomes code**.
