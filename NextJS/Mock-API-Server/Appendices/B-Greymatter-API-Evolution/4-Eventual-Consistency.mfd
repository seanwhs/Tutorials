# Chapter 4 — Understanding Eventual Consistency

The investigation had narrowed considerably.

The mutation endpoints were working.

The dashboard was working.

The uploaded data was valid.

The application wasn't crashing.

Yet the dashboard occasionally displayed stale information immediately after a successful mutation.

The remaining question was simple.

**How could one successful request be followed immediately by an incorrect read?**

Answering that question requires understanding one of the most important concepts in distributed computing:

**eventual consistency.**

---

# What Is Eventual Consistency?

In a traditional desktop application, saving a file usually means the next read immediately returns the updated contents.

Developers naturally come to expect this behavior because it is true on their own machines.

Distributed systems are different.

Instead of one computer, there may be:

* multiple application instances
* multiple storage servers
* content delivery networks (CDNs)
* cache layers
* geographically distributed infrastructure

Data still becomes consistent.

It simply does not always become consistent **immediately**.

This property is known as **eventual consistency**.

---

> **Definition**
>
> Eventual consistency is a consistency model in which updates are guaranteed to become visible over time, but not necessarily to every reader immediately after the write completes.

---

# Local Consistency

The original version of Greymatter API effectively behaved like a strongly consistent application.

Everything happened inside one process.

```mermaid
flowchart LR

Browser["Browser"]

Server["Next.js Server"]

Disk[("db.json")]

Browser --> Server

Server --> Disk
```

The sequence looked like this.

```text
Read file

↓

Modify data

↓

Write file

↓

Read file again

↓

Updated data returned
```

There were no intermediate systems.

No distributed caches.

No replication.

No propagation delays.

Every read observed the most recent write.

---

# Distributed Consistency

Cloud-native applications introduce additional layers.

A simplified production request might resemble this.

```mermaid
flowchart LR

Browser["Browser"]

CDN["CDN"]

Function["Serverless Function"]

Blob[("Object Storage")]

Browser --> CDN

CDN --> Function

Function --> Blob
```

Now consider what happens after a write.

The application writes new data.

The storage layer confirms success.

Immediately afterward another request asks for the same data.

That request may not necessarily observe the newest version immediately.

The delay is often extremely small.

Sometimes it is effectively invisible.

Occasionally, however, the timing becomes visible to users.

That is exactly what happened in Greymatter API.

---

# A Timeline of Events

The production bug becomes easier to understand when viewed as a timeline.

```mermaid
sequenceDiagram

participant Dashboard

participant Admin

participant Blob

Dashboard->>Admin: POST /admin/load-preset

Admin->>Blob: Save dataset

Blob-->>Admin: Save complete

Admin-->>Dashboard: HTTP 200 OK

Dashboard->>Admin: GET /admin/collections

Admin->>Blob: Read dataset

Blob-->>Admin: Previous version returned

Admin-->>Dashboard: Old collections rendered
```

Notice what is important.

Nothing failed.

Every request succeeded.

Every HTTP response returned successfully.

The issue was simply that the second request observed an older view of the data.

---

# The Difference Between Failure and Visibility

This distinction is subtle but extremely important.

The storage operation itself succeeded.

```text
Save operation

↓

Success
```

The problem occurred later.

```text
Immediate read

↓

Older version observed
```

The application therefore experienced a **visibility problem**, not a **write failure**.

That distinction completely changes how engineers think about the solution.

---

# Why Refreshing the Browser Didn't Help

One of the earliest workarounds was simply refreshing the page.

Intuitively this seems reasonable.

After all, refreshing causes the browser to perform a new request.

Unfortunately, the request sequence remained exactly the same.

```text
Mutation

↓

Reload page

↓

GET collections
```

A browser refresh cannot change the behavior of the underlying storage system.

If the read still occurs before the updated data becomes fully visible, the page simply reloads the same stale information.

Reloading the page also introduced several disadvantages.

* The entire application restarted.
* React state was discarded.
* Additional HTTP requests were generated.
* The user experience became slower.
* The underlying architectural problem remained.

The refresh treated the symptom.

It did not address the cause.

---

# Could React Be Responsible?

React often becomes the first suspect when a user interface displays incorrect information.

In this case, however, React behaved exactly as designed.

The dashboard rendered whatever data it received.

If the server returned:

```json
{
  "collections": [
    "users",
    "posts"
  ]
}
```

then React displayed those collections.

If the server returned stale data, React faithfully rendered stale data.

The framework was not introducing inconsistency.

It was exposing inconsistency elsewhere in the system.

---

# Could Browser Caching Explain It?

Modern browsers cache aggressively.

Likewise, CDNs and reverse proxies often cache responses to improve performance.

These layers can absolutely contribute to stale reads.

However, they were not the complete explanation.

Several observations suggested something deeper.

* The first read was sometimes stale.
* The second read usually succeeded.
* The mutation always completed successfully.
* The stale period was brief.

These characteristics are typical of timing-related visibility rather than permanent caching.

---

# A Distributed System Behaving Like a Distributed System

Perhaps the most important realization during the investigation was philosophical rather than technical.

Nothing in the cloud deployment was actually behaving incorrectly.

The infrastructure was behaving exactly as designed.

The mistake lay in the assumptions carried over from local development.

The original implementation implicitly assumed:

> Once a write succeeds, every subsequent read immediately observes that write.

That assumption held true for a local filesystem.

It is much weaker in distributed environments.

The application had been written for one execution model while running in another.

---

> **Engineering Insight**
>
> Many production bugs are not caused by incorrect code.
>
> They are caused by **correct code running under incorrect assumptions**.
>
> The transition from a single-process application to a distributed system often exposes those assumptions for the first time.

---

# Thinking Like an Architect

At this point, the investigation reached a crossroads.

Several possible solutions existed.

Some focused on making reads more reliable.

Others attempted to force storage synchronization.

Some proposed retries.

Others suggested disabling caches.

All of those ideas had merit.

But they shared one characteristic.

They accepted the existing request flow as fixed.

The engineering team asked a different question.

Instead of asking:

> **"How can we make the second request more reliable?"**

they asked:

> **"Why does the second request exist at all?"**

That simple question changed the direction of the entire investigation.

Rather than improving the read-after-write sequence, the team began exploring whether the second read could be eliminated completely.

The next chapter examines the alternative solutions that were considered, why some improved reliability only marginally, and why the final solution ultimately involved changing the architecture instead of tuning the infrastructure.
