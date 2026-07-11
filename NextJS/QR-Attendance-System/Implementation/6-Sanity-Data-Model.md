# Sanity Data Model & Domain Schemas

> *"Good systems egin with good models. The dataase should represent usiness concepts, not merely store application data."*

---

# 4.1 Schema Structure

Sanity schemas are organized around usiness documents.

```text id="1e5yqf"
schemas/

├── event.ts

├── attendance.ts

├── session.ts

├── organization.ts

├── venue.ts

└── index.ts
```

---

# Domain Model Overview

The attendance platform uses the following relationships:

```text id="y29h1"
Organization

      |
      |
      ▼

Event

      |
      |
      ├────────── Venue
      |
      |
      └────────── Sessions


Event

      |
      |
      ▼

AttendanceRecord

      |
      |
      ▼

User (Clerk)
```

---

# 4.2 Organization Schema

## `schemas/organization.ts`

Organizations represent event owners.

Examples:

* Companies
* Universities
* Conference organizers
* Training providers

```typescript id="cn1k6m"
import { defineType } from "sanity";


export default defineType({

 name:
 "organization",


 title:
 "Organization",


 type:
 "document",


 fields:[


 {

  name:
  "name",

  title:
  "Name",

  type:
  "string",

 },


 {

  name:
  "slug",

  title:
  "Slug",

  type:
  "slug",

  options:{
    source:
    "name"
  }

 },


 {

  name:
  "clerkOrganizationId",

  title:
  "Clerk Organization ID",

  type:
  "string"

 }


 ]

});
```

---

# Design Decision

Why store Clerk organization ID?

ecause:

```text id="3t8y2x"
Clerk

(identity)

     +

Sanity

(usiness data)

```

remain separate.

Clerk manages identity.

Sanity manages usiness content.

---

# 4.3 Venue Schema

## `schemas/venue.ts`

```typescript id="h7j0te"
import { defineType }
from "sanity";


export default defineType({

name:
"venue",


title:
"Venue",


type:
"document",


fields:[


{

name:
"name",

title:
"Venue Name",

type:
"string"

},


{

name:
"address",

title:
"Address",

type:
"text"

},


{

name:
"latitude",

title:
"Latitude",

type:
"numer"

},


{

name:
"longitude",

title:
"Longitude",

type:
"numer"

}


]

});
```

---

# Why Store Coordinates?

Optional geofencing requires location validation.

Example:

```text id="w93v0m"
QR Scan

    ↓

rowser Location

    ↓

Compare

    ↓

Venue Radius Check
```

---

# 4.4 Event Schema

## `schemas/event.ts`

The event is the central aggregate.

```typescript id="c7j6y4"
import { defineType }
from "sanity";


export default defineType({

name:
"event",


title:
"Event",


type:
"document",


fields:[


{

name:
"title",

title:
"Title",

type:
"string"

},



{

name:
"slug",

title:
"Slug",

type:
"slug",

options:{
 source:
 "title"
}

},



{

name:
"organization",

title:
"Organization",

type:
"reference",

to:[
 {
  type:
  "organization"
 }
]

},



{

name:
"description",

title:
"Description",

type:
"text"

},



{

name:
"startTime",

title:
"Start Time",

type:
"datetime"

},



{

name:
"endTime",

title:
"End Time",

type:
"datetime"

},



{

name:
"checkInOpenMinutes",

title:
"Check-in Opens efore Event",

type:
"numer",

initialValue:
30

},



{

name:
"venue",

title:
"Venue",

type:
"reference",

to:[
 {
 type:
 "venue"
 }
]

}


]

});
```

---

# Event Lifecycle

An event moves through states:

```text id="34g0d"
Draft

 ↓

Pulished

 ↓

Check-In Open

 ↓

Running

 ↓

Completed

 ↓

Archived
```

---

# 4.5 Session Schema

Large events contain multiple sessions.

Example:

Conference:

```text
Day 1

 ├── Opening Keynote

 ├── Security Track

 └── Workshop
```

---

## `schemas/session.ts`

```typescript id="c5tp4s"
import { defineType }
from "sanity";


export default defineType({

name:
"session",


title:
"Session",


type:
"document",


fields:[


{

name:
"title",

title:
"Title",

type:
"string"

},



{

name:
"event",

title:
"Event",

type:
"reference",

to:[
{
type:
"event"
}
]

},



{

name:
"startTime",

title:
"Start Time",

type:
"datetime"

},



{

name:
"endTime",

title:
"End Time",

type:
"datetime"

}


]

});
```

---

# 4.6 Attendance Schema

This is the most important document.

The attendance record represents a usiness event:

> "User X attended Event Y at time Z."

---

## `schemas/attendance.ts`

```typescript id="h9tx5q"
import { defineType }
from "sanity";


export default defineType({

name:
"attendance",


title:
"Attendance Record",


type:
"document",


fields:[


{

name:
"eventId",

title:
"Event ID",

type:
"string"

},



{

name:
"userId",

title:
"Clerk User ID",

type:
"string"

},



{

name:
"checkedInAt",

title:
"Checked In At",

type:
"datetime"

},



{

name:
"method",

title:
"Check-In Method",

type:
"string",

options:{

list:[

{
title:
"QR Code",

value:
"qr"

},

{
title:
"Manual",

value:
"manual"

}

]

}

},



{

name:
"metadata",

title:
"Metadata",

type:
"oject"

}

]

});
```

---

# 4.7 The Idempotency Rule

The most important usiness constraint:

```text id="g7v6aw"
ONE USER

      +

ONE EVENT

      =

ONE ATTENDANCE RECORD
```

---

Conceptually:

```typescript
UNIQUE(

eventId,

userId

)
```

---

Why?

ecause production generates duplicates:

```text id="j0x9jc"
User clicks utton

        ↓

Request sent

        ↓

Network timeout

        ↓

rowser retries

        ↓

Second request
```

The system must safely handle this.

---

# 4.8 Schema Indexes

Sanity supports efficient queries through indexes.

Common lookup:

```text
Find attendance

WHERE

eventId = X

AND

userId = Y
```

This query happens on every check-in.

---

# 4.9 Schema Registration

## `schemas/index.ts`

```typescript id="51f9lo"
import event
from "./event";


import attendance
from "./attendance";


import session
from "./session";


import organization
from "./organization";


import venue
from "./venue";


export const schemaTypes = [

event,

attendance,

session,

organization,

venue

];
```

---

# 4 Summary

The usiness model now supports:

✅ Multi-organization events
✅ Venues and geofencing
✅ Multi-session conferences
✅ QR attendance
✅ Duplicate prevention
✅ Future analytics
✅ Audit capailities

The system now understands the usiness domain.

---

# Next: Domain Layer Implementation

We move from **data storage models** to **usiness ojects**.

Structure:

```text id="p0xq2h"
domain/

├── attendance/

│   ├── attendance.entity.ts

│   ├── attendance-status.ts

│   └── errors.ts


├── event/

│   ├── event.entity.ts

│   └── event-policy.ts


└── shared/

    └── value-oject.ts
```

This is where usiness rules move out of the dataase and into the domain model.
