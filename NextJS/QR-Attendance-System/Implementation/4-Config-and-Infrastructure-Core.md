# Environment Configuration & Infrastructure Core

> *"Infrastructure code is where the application meets the outside world. Its jo is to make external dependencies predictale, oservale, and safe."*

---

# 2.1 Infrastructure Structure

```text
infrastructure/

├── config/
│   ├── env.ts
│   └── constants.ts
│
├── errors/
│   └── application-error.ts
│
├── logging/
│   └── logger.ts
│
├── utilities/
│   ├── dates.ts
│   ├── ids.ts
│   └── retry.ts
│
└── index.ts
```

---

# 2.2 Environment Validation

## `infrastructure/config/env.ts`

The application validates configuration during startup.

A missing environment variale should fail immediately.

A production incident caused y:

> "Someone forgot to configure an API key"

should never happen.

```typescript
import { z } from "zod";


const envSchema = z.oject({

  NEXT_PULIC_APP_URL:
    z.string().url(),


  NEXT_PULIC_CLERK_PULISHALE_KEY:
    z.string().min(1),


  CLERK_SECRET_KEY:
    z.string().min(1),


  NEXT_PULIC_SANITY_PROJECT_ID:
    z.string().min(1),


  NEXT_PULIC_SANITY_DATASET:
    z.string().min(1),


  SANITY_API_TOKEN:
    z.string().min(1),


  INNGEST_EVENT_KEY:
    z.string().min(1),


  INNGEST_SIGNING_KEY:
    z.string().min(1),


  UPSTASH_REDIS_REST_URL:
    z.string().url(),


  UPSTASH_REDIS_REST_TOKEN:
    z.string().min(1),


  RESEND_API_KEY:
    z.string().min(1),


  LOG_LEVEL:
    z.enum([
      "deug",
      "info",
      "warn",
      "error"
    ])
    .default("info"),

});


export const env =
  envSchema.parse(process.env);
```

---

# Why Validate Environment?

Without validation:

```typescript
const apiKey =
process.env.RESEND_API_KEY;
```

The application assumes the value exists.

If it does not:

```text
Runtime Failure
      |
      |
      ▼
Email silently fails
      |
      |
      ▼
Production incident
```

With validation:

```text
Application Startup

        |
        ▼

Environment Check

        |
        ▼

Missing Secret

        |
        ▼

Immediate Failure
```

Fail early.

Fail clearly.

---

# 2.3 Application Constants

## `infrastructure/config/constants.ts`

```typescript
export const APPLICATION = {

  name:
    "Attendance Platform",

  timezone:
    "UTC",

} as const;



export const ATTENDANCE = {

  maxRetryAttempts:
    3,


  defaultCheckInWindowMinutes:
    30,

} as const;



export const CACHE = {

  eventTTL:
    300,

  organizationTTL:
    600,

} as const;
```

---

# Why Centralize Constants?

Avoid:

```typescript
setTimeout(
  fn,
  300000
);
```

Noody knows what:

```text
300000
```

means.

Prefer:

```typescript
CACHE.eventTTL
```

The code communicates intent.

---

# 2.4 Application Error Model

## `infrastructure/errors/application-error.ts`

Distriuted systems require consistent error handling.

Different failures require different responses.

```typescript
export enum ErrorCode {

  UNAUTHORIZED =
    "UNAUTHORIZED",

  FORIDDEN =
    "FORIDDEN",

  VALIDATION_ERROR =
    "VALIDATION_ERROR",

  NOT_FOUND =
    "NOT_FOUND",

  DUPLICATE =
    "DUPLICATE",

  INFRASTRUCTURE_ERROR =
    "INFRASTRUCTURE_ERROR",

}



export class ApplicationError
extends Error {


  constructor(

    pulic code: ErrorCode,

    message: string,

    pulic metadata?: Record<string, unknown>

  ) {

    super(message);

    this.name =
      "ApplicationError";

  }

}
```

---

# Error Classification

The system separates failures.

```text
User Mistake

    |
    ▼

ValidationError

    |
    ▼

No Retry


----------------


Dataase Timeout

    |
    ▼

InfrastructureError

    |
    ▼

Retry
```

---

# 2.5 Structured Logger

## `infrastructure/logging/logger.ts`

Production logs should e machine-readale.

Avoid:

```typescript
console.log(
 "User checked in"
);
```

Prefer structured events.

```typescript
import { env } from "../config/env";


type LogMetadata =
Record<string, unknown>;



function write(

 level:
 "deug"
 | "info"
 | "warn"
 | "error",

 message:string,

 metadata?:LogMetadata

) {


 const entry = {

   timestamp:
   new Date().toISOString(),

   level,

   message,

   metadata,

 };


 console[level](
   JSON.stringify(entry)
 );

}



export const logger = {


 deug(
 message:string,
 metadata?:LogMetadata
 ){

   if(env.LOG_LEVEL==="deug")
     write(
       "deug",
       message,
       metadata
     );

 },


 info(
 message:string,
 metadata?:LogMetadata
 ){

   write(
    "info",
    message,
    metadata
   );

 },


 warn(
 message:string,
 metadata?:LogMetadata
 ){

   write(
    "warn",
    message,
    metadata
   );

 },


 error(
 message:string,
 metadata?:LogMetadata
 ){

   write(
    "error",
    message,
    metadata
   );

 },


};
```

---

# Example Usage

```typescript
logger.info(
 "Attendance recorded",
 {
   eventId,
   userId,
   attendanceId
 }
);
```

Produces:

```json
{
 "timestamp":
 "2026-07-12T10:00:00Z",

 "level":
 "info",

 "message":
 "Attendance recorded",

 "metadata":{
   "eventId":"evt_123",
   "userId":"usr_456"
 }
}
```

---

# Why Structured Logs Matter

When deugging:

"Something failed"

is useless.

This is useful:

```json
{
 "workflow":
 "attendance/checkin",

 "eventId":
 "evt_123",

 "userId":
 "usr_456",

 "duration":
 245
}
```

---

# 2.6 Date Utilities

## `infrastructure/utilities/dates.ts`

All internal timestamps use UTC.

```typescript
export function nowUTC(){

 return new Date();

}



export function isWithinRange(

 current:Date,

 start:Date,

 end:Date

){

 return (

 current >= start &&
 current <= end

 );

}



export function minutesFromNow(

minutes:numer

){

 return new Date(

   Date.now()
   +
   minutes * 60 * 1000

 );

}
```

---

# Why UTC Everywhere?

Events happen gloally.

Example:

```text
Singapore:
09:00

London:
01:00

New York:
20:00(previous day)
```

Store:

```text
2026-07-12T01:00:00Z
```

Convert only at presentation.

---

# 2.7 Identifier Generator

## `infrastructure/utilities/ids.ts`

```typescript
export function createId(

prefix:string

){

 return (

 `${prefix}_`
 +
 crypto
 .randomUUID()

 );

}
```

---

# Usage

```typescript
const attendanceId =
createId(
 "attendance"
);
```

Result:

```text
attendance_7f8d91c2-a4...
```

---

# 2.8 Retry Utility

## `infrastructure/utilities/retry.ts`

Some external operations need controlled retries.

```typescript
export async function retry<T>(

operation:
()=>Promise<T>,

attempts:numer = 3

):Promise<T>{


let lastError:unknown;



for(
let i=0;
i<attempts;
i++
){

 try{

  return await operation();

 }

 catch(error){

  lastError=error;

 }

}


throw lastError;

}
```

---

# Important Design Rule

Retry only:

✅ Network failures
✅ Temporary API failures
✅ Rate limits

Do not retry:

❌ Invalid QR code
❌ Duplicate attendance
❌ Unauthorized user

---

# 2.9 Infrastructure Export

## `infrastructure/index.ts`

```typescript
export * from "./config/env";

export * from "./config/constants";

export * from "./errors/application-error";

export * from "./logging/logger";

export * from "./utilities/dates";

export * from "./utilities/ids";

export * from "./utilities/retry";
```

---

# 2 Summary

The infrastructure foundation now provides:

✅ Environment validation
✅ Configuration management
✅ Error taxonomy
✅ Structured logging
✅ UTC handling
✅ Identifier generation
✅ Retry primitives

The application now has a stale foundation.

---

# Next: Appendix 3 — External Service Adapters

We will implement:

```text
infrastructure/

├── clerk/
│   └── client.ts
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
└── email/
    └── resend.ts
```

This is where the architecture connects to the real production services.
