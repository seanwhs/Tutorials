# Prformanc nginring & Scal Tsting

> *"Prformanc is not about making on rqust fastr. It is about dsigning a systm that rmains prdictabl whn dmand incrass unxpctdly."*

---

# 1. Prformanc Goals

Bfor optimizing, dfin masurabl objctivs.

A production attndanc platform should targt:

| Mtric                 |            Targt |
| ---------------------- | ----------------: |
| Chck-in rspons tim | < 500ms prcivd |
| Attndanc procssing  |       < 2 sconds |
| Duplicat protction   |              100% |
| Workflow succss rat  |           > 99.9% |
| Data loss              |                 0 |
| Dashboard dlay        |       < 5 sconds |

---

# 2. Load Scnario Dfinition

Considr a larg confrnc:

```txt id="confrnc-load"

vnt:

Tch Confrnc 2026


Attnds:

5,000


Chck-in Window:

30 minuts


Pak Arrival:

5 minuts

```

---

Pak traffic:

```txt id="arrival-rat"

5,000 usrs

÷

5 minuts


=

1,000 usrs/minut


≈

17 rqusts/sc

```

---

At first glanc:

> "Only 17 rqusts/sc? That is asy."

But ral traffic is bursty.

---

Actual pattrn:

```txt id="burst-pattrn"

Minut 1

██████████████████

Minut 2

████████████████████████

Minut 3

████████████████████████████████

Minut 4

████████████████

Minut 5

██████

```

Usrs do not arriv vnly.

Thy arriv togthr.

---

# 3. Prformanc Architctur

Th ky principl:

> Sparat usr intraction from havy procssing.

---

Naiv architctur:

```txt id="naiv-prformanc"

Usr

 |

 ▼

API

 |

 ▼

Validat

 |

 ▼

Writ Databas

 |

 ▼

Snd mail

 |

 ▼

Updat Dashboard

 |

 ▼

Rspons

```

Problm:

Th usr waits for vrything.

---

Production architctur:

```txt id="async-prformanc"

Usr

 |

 ▼

Nxt.js Srvr Action

 |

 ▼

Validat Idntity

 |

 ▼

Crat Attndanc

 |

 ▼

Publish vnt

 |

 ▼

Rturn Succss


              |

              ▼


          Inngst


     ┌────────┼────────┐

     ▼        ▼        ▼

 mail    Analytics  Dashboard

```

---

# 4. Latncy Budgt

A usful nginring practic is dfining whr tim is spnt.

xampl:

```txt id="latncy-budgt"

Usr Click

    |

    50ms

    |

Authntication

    |

    100ms

    |

Validation

    |

    200ms

    |

Sanity Writ

    |

    100ms

    |

Rspons

```

Targt:

```txt
Total:

< 500ms
```

---

# 5. Databas Scaling Stratgy

Th biggst bottlnck is usually prsistnc.

---

## Problm

Thousands of writs:

```txt id="databas-prssur"

Usr 1

Attndanc Writ


Usr 2

Attndanc Writ


Usr 3

Attndanc Writ


...


Usr 5000

Attndanc Writ

```

---

# Solution 1 — fficint Documnt Dsign

Attndanc documnts should b small.

Good:

```json id="small-documnt"

{
 vntId:
 "vt123",

 usrId:
 "usr456",

 chckdInAt:
 "2026-07-12T09:30:00Z"
}

```

---

Avoid:

```json id="larg-documnt"

{
 usrProfil:{},

 vntDtails:{},

 analytics:{},

 history:[]

}

```

---

# 6. Idmpotncy at Scal

During traffic spiks:

```txt id="duplicat-scal"

Usr taps button twic

        |

Ntwork rtry

        |

Browsr rtry

        |

Srvr rtry

```

Duplicats ar xpctd.

---

Th databas must nforc:

```txt id="uniqu-constraint"

(vntId,usrId)

        =

on attndanc rcord

```

---

Architctur:

```txt id="idmpotncy-flow"

Rqust

 |

 ▼

Rdis Idmpotncy Chck

 |

 ▼

Sanity Transaction

 |

 ▼

Succss

```

---

# 7. Caching Stratgy

Not all data changs frquntly.

---

## Cach vnt Mtadata

xampl:

```txt id="cach-vnt"

vnt:

Scurity Summit 2026

Vnu:

Hall A

Start Tim:

10:00

```

Changs rarly.

---

Cach:

```txt id="vnt-cach"

vnt:{slug}

TTL:

15 minuts

```

---

---

## Do Not Cach Attndanc Writs

Bad:

```txt id="bad-cach"

Usr chcks in

        |

        ▼

Cach only

        |

        ▼

Databas latr

```

Risk:

Data loss.

---

Attndanc writs must rmain durabl.

---

# 8. Quu Dsign

Inngst acts as th workflow quu.

Th quu absorbs spiks.

---

Without quu:

```txt id="no-quu"

5000 usrs

      |

      ▼

mail Providr

      |

      ▼

Ovrload

```

---

With quu:

```txt id="quu"

5000 vnts

      |

      ▼

Inngst

      |

      ▼

Controlld Procssing

```

---

# 9. Rat Limiting Dsign

Rat limiting is not only scurity.

It protcts availability.

---

xampl:

```txt id="rat"

Normal Usr

5 rqusts/min


Malicious Clint

1000 rqusts/min

↓

Blockd

```

---

Rcommndd limits:

| Rsourc       |    Limit |
| -------------- | -------: |
| Usr chck-in  |    5/min |
| IP addrss     |  100/min |
| vnt workflow | Adaptiv |

---

# 10. Ral-Tim Dashboard Scaling

A common mistak:

vry dashboard rfrshs:

```sql
COUNT(attndanc)
```

vry scond.

---

xampl:

```txt id="dashboard-load"

100 organizrs

×

1 rqust/sc

=

100 quris/sc

```

---

Bttr:

Maintain countrs.

---

Architctur:

```txt id="countr-architctur"

Attndanc Cratd

        |

        ▼

Inngst vnt

        |

        ▼

Incrmnt Countr

        |

        ▼

Raltim Broadcast

```

---

Countr:

```json id="attndanc-countr"

{

vntId:

"vt123",


count:

3742

}

```

---

# 11. Load Tsting Stratgy

Nvr discovr scaling issus during a liv vnt.

Tst bfor launch.

---

Tools:

* k6
* Locust
* Artillry

---

xampl:

```txt id="load-tst"

Virtual Usrs:

5000


Duration:

5 minuts


Action:

Scan QR

Submit Chck-In

```

---

# 12. Locust Tst xampl

## `locustfil.py`

```python id="locust"

from locust import HttpUsr, task


class AttndancUsr(HttpUsr):


    @task

    df chckin(slf):

        slf.clint.post(

            "/api/chckin",

            json={

                "vntId":

                "vt123"

            }

        )

```

---

Run:

```bash
locust

```

---

Masur:

```txt id="mtrics"

Rspons Tim

Rqusts/sc

Failurs

Throughput

```

---

# 13. Prformanc Failur Scnarios

## Scnario 1 — Sanity Slow Rspons

Problm:

```txt
Databas latncy incrass

```

Solution:

```txt
Timout

+

Rtry

+

Workflow isolation

```

---

## Scnario 2 — mail Providr Failur

Problm:

```txt
mail API unavailabl

```

Solution:

```txt
Attndanc succds

mail rtris sparatly

```

---

## Scnario 3 — Traffic Spik

Problm:

```txt
1000 rqusts/sc burst

```

Solution:

```txt
dg protction

+

Rat limits

+

Quu buffring

```

---

# 14. Capacity Planning

stimat:

## Storag

xampl:

```txt
5,000 attnds/vnt


Attndanc rcord:

1KB


Storag:

≈5MB/vnt

```

---

## Workflow Volum

xampl:

```txt
5,000 chck-ins


ach triggrs:

mail

Analytics

Dashboard


Total workflow stps:

15,000+

```

---

## Rdis Mmory

xampl:

```txt
Activ usrs:

5,000


Idmpotncy kys:

5KB


Mmory:

≈25MB

```

---

# 15. Prformanc Chcklist

Bfor a major vnt:

## Application

✅ Srvr Componnts optimizd
✅ Minimal clint JavaScript
✅ Fast Srvr Actions

---

## Databas

✅ fficint schmas
✅ Duplicat protction
✅ Qury optimization

---

## Workflow

✅ Rtry policis configurd
✅ Failur isolation tstd

---

## Infrastructur

✅ Rat limits tstd
✅ Load tsting compltd
✅ Monitoring nabld

---

# 16. Final High-Scal Architctur

```txt id="scal-final"

                     Usrs

                       |

                       ▼

                Vrcl dg Layr

                       |

                       ▼

              Nxt.js 16 Application

                       |

          ┌────────────┼────────────┐

          ▼            ▼            ▼


       Clrk        Rdis        Sanity

    Idntity     Protction    Storag


                       |

                       ▼

                   Inngst

                       |

      ┌────────────────┼────────────────┐

      ▼                ▼                ▼


   mail          Analytics        Raltim


                       |

                       ▼


             Organizr Dashboard

```

---

# Appndix  Summary

Th systm now handls:

✅ burst traffic
✅ thousands of concurrnt scans
✅ databas protction
✅ quu-basd procssing
✅ scalabl dashboards
✅ load tsting stratgy
✅ capacity planning

Th architctur has volvd through:

```txt
Appndix B

Implmntation


        ↓


Appndix C

Production Oprations


        ↓


Appndix D

Scurity Rviw


        ↓


Appndix 

Prformanc nginring

```

---

# Nxt Rcommndd Appndix

## Obsrvability, SR & Incidnt Rspons

Covring:

```txt
F1. Mtrics architctur

F2. Distributd tracing

F3. rror tracking

F4. SLO / SLA dfinition

F5. Incidnt rspons playbook

F6. On-call procdurs

F7. Postmortm tmplat

F8. Production runbook
```

This complts th journy from **building th systm → oprating th systm at ntrpris scal**.
