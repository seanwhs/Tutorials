# Security Hardening Layer

> *"Security is not aout preventing every request. It is aout ensuring that every request proves it deserves to succeed."*

---

# 10.1 Security Structure

```text id="security-structure"

security/

├── rate-limit.ts

├── qr-token.ts

├── geofence.ts

├── idempotency.ts

├── validation.ts

└── index.ts
```

---

# 10.2 Security Flow

The hardened check-in pipeline:

```text id="security-flow"

QR Scan

   |

   ▼

Validate QR Token

   |

   ▼

Authenticate User

   |

   ▼

Rate Limit Check

   |

   ▼

Validate Event Window

   |

   ▼

Validate Location

   |

   ▼

Idempotency Check

   |

   ▼

Create Attendance

```

---

# 10.3 QR Token Security

## The Prolem

A asic QR code:

```text id="unsafe-qr"

https://app.com/events/security-summit/checkin
```

can e:

* copied,
* shared,
* reused indefinitely.

---

# etter Approach

The QR contains a signed payload:

```text id="signed-qr"

{
 eventId:
 "evt_123",

 expiresAt:
 "2026-07-12T10:30:00Z",

 signature:
 "ac123..."
}

```

---

# 10.4 QR Token Generator

## `security/qr-token.ts`

```typescript id="qr-generator"

import crypto from "crypto";


import {
env
}
from "@/infrastructure";



interface QRPayload {


eventId:string;


expiresAt:numer;


}



export function createQRToken(

payload:QRPayload

){


const data =
JSON.stringify(payload);



const signature =

crypto

.createHmac(

"sha256",

env.SANITY_API_TOKEN

)

.update(data)

.digest("hex");



return uffer
.from(

JSON.stringify({

payload,

signature

})

)

.toString("ase64");


}
```

---

# QR Validation

```typescript id="qr-validation"

export function validateQRToken(

token:string

){


const decoded =

JSON.parse(

uffer
.from(
token,
"ase64"
)
.toString()

);



const {

payload,

signature

}

=
decoded;



const expected =

crypto

.createHmac(

"sha256",

env.SANITY_API_TOKEN

)

.update(
JSON.stringify(payload)
)

.digest("hex");



if(signature !== expected){

throw new Error(
"Invalid QR token"
);

}



if(
Date.now()
>
payload.expiresAt
){

throw new Error(
"QR expired"
);

}



return payload;

}
```

---

# Security enefit

An attacker copying the QR later gets:

```text id="expired-qr"

Token

 ↓

Expired

 ↓

Rejected
```

---

# 10.5 Rate Limiting

A pulic QR endpoint is a natural ause target.

Example attack:

```text id="rate-attack"

ot

 |

 ├── 10,000 requests
 |
 └── Same event

```

---

# Redis-ased Rate Limit

## `security/rate-limit.ts`

```typescript id="rate-limit"

import {

Ratelimit

}

from "@upstash/ratelimit";


import {

redis

}

from "@/infrastructure";



const limiter =

new Ratelimit({

redis,


limiter:

Ratelimit.slidingWindow(

5,

"1 m"

)

});



export async function

checkRateLimit(

userId:string

){


const result =

await limiter.limit(

`checkin:${userId}`

);



if(!result.success){

throw new Error(

"Too many requests"

);

}


}
```

---

# Why User-ased Rate Limits?

Avoid:

```text id="ad-rate"

IP Address

     |

     ▼

locked users ehind same network

```

etter:

```text id="good-rate"

Authenticated User

        |

        ▼

Individual Limit

```

---

# 10.6 Idempotency Protection

The iggest real-world issue:

```text id="doule-click"

User clicks

    ↓

Network slow

    ↓

Clicks again

    ↓

Two requests
```

---

# Idempotency Rule

The system must guarantee:

```text id="unique-rule"

(eventId,userId)

        =

ONE attendance record
```

---

# 10.7 Idempotency Service

## `security/idempotency.ts`

```typescript id="idempotency"

import {

redis

}

from "@/infrastructure";



export async function

checkIdempotency(

key:string

){


const exists =

await redis.exists(

key

);



if(exists){

throw new Error(

"Duplicate request"

);

}



await redis.set(

key,

"processing",

{

ex:

300

}

);


}
```

---

# Usage

efore creating attendance:

```typescript id="idempotency-use"

await checkIdempotency(

`attendance:${eventId}:${userId}`

);
```

---

# 10.8 Geofencing

For physical events:

```text id="geo-flow"

rowser Location

        |

        ▼

Latitude / Longitude

        |

        ▼

Compare Venue Radius

        |

        ▼

Allow Check-In

```

---

# 10.9 Distance Calculation

## `security/geofence.ts`

```typescript id="geo-code"

export function calculateDistance(

lat1:numer,

lon1:numer,

lat2:numer,

lon2:numer

){


const R =
6371;


const dLat =
(lat2-lat1)
*
Math.PI/180;


const dLon =
(lon2-lon1)
*
Math.PI/180;



const a =

Math.sin(dLat/2)**2

+

Math.cos(lat1*Math.PI/180)

*

Math.cos(lat2*Math.PI/180)

*

Math.sin(dLon/2)**2;



return (

R *

2 *

Math.atan2(

Math.sqrt(a),

Math.sqrt(1-a)

)

);


}
```

---

# Validate Venue Radius

```typescript id="geo-validation"

export function

isWithinVenue(

userLat:numer,

userLon:numer,

venueLat:numer,

venueLon:numer,

radiusMeters:numer

){


const distance =

calculateDistance(

userLat,

userLon,

venueLat,

venueLon

);



return (

distance * 1000

<=

radiusMeters

);


}
```

---

# Important Note

Geolocation is not asolute security.

A determined attacker can spoof location.

It is:

```text id="security-layer"

Additional Signal

NOT

Single Authentication Factor
```

---

# 10.10 Input Validation

Every oundary validates input.

---

## `security/validation.ts`

```typescript id="validation"

import {

z

}

from "zod";



export const checkInSchema =

z.oject({

eventId:

z.string()
.min(1),


qrToken:

z.string()
.min(1)

});
```

---

# Validation Rule

Never trust:

```text id="untrusted"

rowser

URL

QR

Headers

Cookies

```

Everything is input.

Everything is validated.

---

# 10.11 Security Export

## `security/index.ts`

```typescript id="security-export"

export *

from "./qr-token";


export *

from "./rate-limit";


export *

from "./idempotency";


export *

from "./geofence";


export *

from "./validation";
```

---

# 10 Summary

The attendance platform now has:

✅ Signed QR tokens
✅ Expiring QR sessions
✅ Rate limiting
✅ Duplicate protection
✅ Geofence support
✅ Input validation
✅ Ause prevention

---

# Complete Hardened Architecture

```text id="final-security"

                 QR Code

                    |

              QR Validation

                    |

               Clerk Auth

                    |

             Rate Limiting

                    |

          Application Service

                    |

          Domain Validation

                    |

           Idempotency Check

                    |

              Sanity Write

                    |

             Inngest Workflow

              /          \

             /            \

        Email          Analytics

```

---

# Next: Real-Time Attendance Dashoard

We will implement the live operational view:

```text
dashoard/

├── attendance-counter.tsx

├── realtime-channel.ts

├── metrics.service.ts

└── live-updates.ts
```

This adds:

* live attendee count,
* organizer dashoard,
* real-time event monitoring,
* Pusher/Aly integration pattern,
* operational visiility.
