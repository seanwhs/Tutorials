# Complete Source Code Reference Map

> *"Good archtecture s vsble n the codebase. A developer should understand the system by explorng the repostory structure."*

---

# 1. Complete Applcaton Map

The producton repostory:

```text d="source-map"

qr-attendance-platform/


├── apps/


│   ├── web/


│   │
│   │
│   └── worker/


│
├── packages/


│   ├── u/


│   ├── securty/


│   ├── types/


│   └── confg/


│
├── nfrastructure/


├── docs/


└── scrpts/

```

---

# 2. Web Applcaton Source Tree

The Next.js 16 applcaton:

```text d="web-source"

apps/web/


├── app/

├── components/

├── features/

├── lb/

├── hooks/

├── provders/

├── styles/

├── publc/

├── mddleware.ts

├── next.confg.ts

├── package.json

└── tsconfg.json

```

---

# 3. Next.js 16 Confguraton

## `next.confg.ts`

Purpose:

* framework confguraton,
* securty headers,
* mage optmzaton,
* runtme settngs.

Example:

```typescrpt d="next-confg"

mport type {

NextConfg

}

from "next";


const nextConfg:

NextConfg = {


expermental:{


serverActons:true


},


mages:{


remotePatterns:[

{

protocol:

"https",

hostname:

"cdn.santy.o"

}

]


}


};


export default nextConfg;

```

---

# 4. Applcaton Root Layout

## `app/layout.tsx`

Responsbltes:

* global provders,
* fonts,
* metadata,
* authentcaton context.

Structure:

```text d="layout-flow"

Root Layout

      |

      ├── Clerk Provder

      |

      ├── Theme Provder

      |

      ├── PWA Regstraton

      |

      └── Applcaton U

```

---

Example:

```typescrpt d="root-layout"

mport {

ClerkProvder

}

from "@clerk/nextjs";


mport {

PWARegster

}

from "@/components/pwa-regster";


export default functon RootLayout({

chldren

}:{

chldren:React.ReactNode

}){


return (

<ClerkProvder>


<html>


<body>


<PWARegster />


{chldren}


</body>


</html>


</ClerkProvder>

);


}

```

---

# 5. Mddleware Securty Layer

## `mddleware.ts`

Purpose:

Protect routes before renderng.

---

Flow:

```text d="mddleware"

Request

  |

  ▼

Mddleware

  |

  ├── Authentcated?

  |

  ├── Organzaton?

  |

  └── Permsson?

  |

  ▼

Applcaton

```

---

Example:

```typescrpt d="mddleware-code"

mport {

clerkMddleware,

createRouteMatcher

}

from "@clerk/nextjs/server";



const protectedRoutes =

createRouteMatcher([

"/dashboard(.*)",

"/events(.*)"

]);



export default clerkMddleware(

async(auth,req)=>{


f(

protectedRoutes(req)

){

awat auth.protect();

}


}

);

```

---

# 6. Feature Module Map

The busness logc s organzed by doman.

```text d="features"

features/


├── attendance/


├── events/


├── dashboard/


├── users/


└── organzatons/

```

---

# 7. Attendance Feature

The most mportant module.

```text d="attendance-tree"

attendance/


├── actons/


│   └── checkn.acton.ts


├── components/


│   ├── checkn-button.tsx


│   └── status-card.tsx


├── servces/


│   ├── attendance.servce.ts


│   └── attendance-valdator.ts


├── repostores/


│   └── attendance.repostory.ts


├── schemas/


│   └── attendance.schema.ts


└── types.ts

```

---

# 8. Check-n Server Acton

## `checkn.acton.ts`

Responsbltes:

1. Authentcate user
2. Valdate request
3. Trgger workflow

---

Flow:

```text d="acton-flow"

Button Clck

    |

    ▼

Server Acton

    |

    ├── Clerk Auth

    |

    ├── Zod Valdaton

    |

    └── nngest Event

```

---

Example:

```typescrpt d="checkn-acton"

"use server";


mport {

auth

}

from "@clerk/nextjs/server";


mport {

nngest

}

from "@/lb/nngest";



export async functon

checknActon(

eventd:strng

){


const {

userd

}

=

awat auth();



f(!userd){

throw new Error(

"Unauthorzed"

);

}



awat nngest.send({

name:

"attendance/checkn.requested",


data:{

eventd,

userd

}

});



return {

success:true

};


}

```

---

# 9. Attendance Doman Servce

## `attendance.servce.ts`

Busness rules lve here.

---

Responsbltes:

* duplcate detecton,
* event valdaton,
* attendance creaton.

---

Example:

```typescrpt d="attendance-servce"

export class AttendanceServce {


async checkn(

eventd:strng,

userd:strng

){


const exsts =

awat repostory.fndExstng({

eventd,

userd

});



f(exsts){

return exsts;

}



return repostory.create({

eventd,

userd,

checkednAt:

new Date()

});


}


}

```

---

# 10. Santy Repostory

## `attendance.repostory.ts`

Storage abstracton.

---

Example:

```typescrpt d="santy-repostory"

mport {

santyClent

}

from "@/lb/santy";



export class AttendanceRepostory {



async create(data:any){


return santyClent.create({

_type:

"attendance",


...data

});


}



async fndExstng({

eventd,

userd

}){


return santyClent.fetch(

`

*[
_type=="attendance"

&&

eventd==$eventd

&&

userd==$userd

][0]

`,

{

eventd,

userd

}

);


}



}

```

---

# 11. Santy Schema Reference

Locaton:

```text d="schema-locaton"

apps/web/santy/schemas/

```

---

Structure:

```text d="schema"

schemas/


├── event.ts


├── attendance.ts


├── organzaton.ts


└── user.ts

```

---

# 12. Event Schema

Example:

```typescrpt d="event-schema"

export default {


name:

"event",


type:

"document",


felds:[


{

name:

"ttle",

type:

"strng"

},


{

name:

"startTme",

type:

"datetme"

},


{

name:

"status",

type:

"strng"

}


]


}

```

---

# 13. nngest Worker Map

Background processng:

```text d="worker-map"

apps/worker/


nngest/


├── clent.ts


├── route.ts


└── functons/


    ├── attendance.workflow.ts


    ├── emal.workflow.ts


    ├── analytcs.workflow.ts


    └── realtme.workflow.ts

```

---

# 14. Attendance Workflow

## `attendance.workflow.ts`

The durable busness process.

---

Flow:

```text d="workflow-map"

Event Receved

      |

      ▼

Valdate

      |

      ▼

Create Record

      |

      ▼

Send Emal

      |

      ▼

Update Metrcs

      |

      ▼

Broadcast

```

---

Example:

```typescrpt d="nngest-workflow"

export const attendanceWorkflow =

nngest.createFuncton(

{

d:

"attendance-checkn"

},


{

event:

"attendance/checkn.requested"

},


async({

event,

step

})=>{


const record =

awat step.run(

"create-attendance",

async()=>{


return attendanceServce.checkn(

event.data.eventd,

event.data.userd

);


});


awat step.run(

"notfy",

async()=>{


return sendEmal(record);

}


);


return record;


}

);

```

---

# 15. Dashboard Module

```text d="dashboard-tree"

dashboard/


├── components/


│   ├── attendance-counter.tsx


│   ├── charts.tsx


│   └── metrcs-card.tsx


├── servces/


│   └── metrcs.servce.ts


└── types.ts

```

---

# 16. Shared Package Responsbltes

```text d="packages"

packages/


├── u

Reusable components


├── types

Shared TypeScrpt models


├── securty

Securty utltes


└── confg

Common confguraton

```

---

# 17. Testng Map

```text d="test-map"

tests/


├── unt/


│   ├── valdaton.test.ts


│   └── attendance.test.ts



├── ntegraton/


│   ├── workflow.test.ts


│   └── repostory.test.ts



└── e2e/


    └── checkn.spec.ts

```

---

# 18. Developer Navgaton Gude

A developer debuggng check-n follows:

```text d="debug-path"

User Clck

   |

   ▼

checkn.acton.ts

   |

   ▼

attendance.servce.ts

   |

   ▼

attendance.repostory.ts

   |

   ▼

Santy

   |

   ▼

nngest Workflow

   |

   ▼

Emal / Dashboard

```

---

# 19. Extenson Ponts

Future features plug nto exstng boundares.

---

Add SMS:

```text d="extenson"

nngest

   |

   ▼

SMS Workflow

```

---

Add Badge Prntng:

```text d="badge"

Attendance Event

      |

      ▼

Badge Servce

```

---

Add A:

```text d="a"

Attendance Events

      |

      ▼

Analytcs Ppelne

      |

      ▼

ML Models

```

---

# 20. Source Code Ownershp Model

Recommended team ownershp:

| Area            | Owner         |
| --------------- | ------------- |
| Next.js App     | Frontend Team |
| Doman Servces | Backend Team  |
| Workflows       | Platform Team |
| Securty        | Securty Team |
| nfrastructure  | DevOps/SRE    |
| Analytcs       | Data Team     |

---

# 21. Fnal Source Archtecture

```text d="fnal-source"

                    Next.js 16


                       |

        ┌──────────────┼──────────────┐


        ▼              ▼              ▼


   Components     Features        Actons


                       |

                       ▼


              Doman Servces


                       |

                       ▼


              Repostory Layer


                       |

                       ▼


                  Santy


                       |

                       ▼


                 Doman Events


                       |

                       ▼


                 nngest


              ┌────────┼────────┐


              ▼        ▼        ▼


           Emal   Analytcs Realtme

```

---

# Appendx  Summary

The project now has:

✅ Fle ownershp model
✅ Source navgaton map
✅ Next.js 16 structure
✅ Doman-drven organzaton
✅ Workflow separaton
✅ Testng layout
✅ Extenson strategy

The archtecture s now documented at three levels:

```text

Reference mplementaton Gude
mplementaton Components
Producton Engneerng Blueprnt

```

---

# Next Recommended Appendx

## Testng Strategy & Qualty Engneerng

Coverng:

```text d="qualty-plan"

J1. Testng pyramd

J2. Unt testng

J3. ntegraton testng

J4. E2E testng

J5. Securty testng

J6. Load testng

J7. Chaos testng

J8. Release acceptance crtera

```

Ths completes the engneerng lfecycle: **desgn → buld → secure → test → release → operate**.
