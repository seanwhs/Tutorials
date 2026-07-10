## Part 4: Asynchronous Processing

### 1. Concept and Philosophy

Not everything a request triggers needs to finish before the user gets a response. When a user creates a Quikn link, sending a welcome email, updating a search index, and notifying an analytics pipeline can all happen "eventually" rather than "right now." Forcing it all into the synchronous path means perceived latency equals the sum of every downstream system's latency, and a slow/down downstream system takes the whole path down with it.

Async processing via message queues decouples "must happen now" from "must happen eventually" — a direct extension of Part 1's PACELC framing: deliberately introduce a consistency delay in exchange for lower, more predictable latency and resilience to downstream failures. It's also the primary defense against traffic spikes: a queue absorbs a burst and lets workers drain it at a sustainable rate.

### 2. Message Queue Concepts and Options

**Producer** emits events. **Consumer/worker** processes them. **Broker** is the durable buffer between them.

- **RabbitMQ**: traditional broker, push-based, strong routing (exchanges, topics, dead-letter queues). Good for task queues ("process this uploaded image").
- **Kafka / Redpanda** (OSS Kafka-API-compatible, single-binary): a distributed log, not just a queue. Partitioned, ordered, replayable topics; consumers track their own offset. Better for event streaming where multiple independent consumers need the same stream, and replayability matters.
- **Inngest**: free-tier, serverless-native event-driven function platform (great with Next.js/Vercel) — no broker infrastructure to babysit.

Decision framework: task queue for one job done once; event log when multiple independent consumers care about the same event and replay/audit matters; managed/serverless (Inngest) when you want event-driven patterns without operating broker infra yourself.

### 3. Event-Driven Architecture for Decoupling

Quikn's redirect endpoint's only synchronous job is to look up the destination URL and issue the redirect. Recording the click, updating counters, checking notification thresholds are emitted as one event and handled asynchronously.

```
// app/api/[shortcode]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getDestinationUrl } from "@/lib/redis";
import { inngest } from "@/lib/inngest/client";

export async function GET(req: NextRequest, { params }: { params: { shortcode: string } }) {
  const destinationUrl = await getDestinationUrl(params.shortcode);
  if (!destinationUrl) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  // Fire-and-forget: does not block the redirect response
  await inngest.send({
    name: "link/clicked",
    data: {
      shortcode: params.shortcode,
      timestamp: Date.now(),
      userAgent: req.headers.get("user-agent"),
      referrer: req.headers.get("referer"),
      ip: req.headers.get("x-forwarded-for"),
    },
  });

  return NextResponse.redirect(destinationUrl, 302);
}
```

`inngest.send()` returns quickly — it just enqueues. The redirect's latency is now bounded by "cache lookup plus enqueue," not by every downstream write.

Two independent consumers of the same event — the fan-out benefit over direct function calls:

```
// lib/inngest/functions/record-click.ts
import { inngest } from "../client";
import { db } from "@/lib/db";

export const recordClick = inngest.createFunction(
  { id: "record-click", retries: 3 },
  { event: "link/clicked" },
  async ({ event, step }) => {
    await step.run("write-click-event", async () => {
      await db.clickEvent.create({
        data: {
          shortcode: event.data.shortcode,
          clickedAt: new Date(event.data.timestamp),
          referrer: event.data.referrer,
        },
      });
    });
  }
);

// lib/inngest/functions/check-notification-threshold.ts
export const checkThreshold = inngest.createFunction(
  { id: "check-notification-threshold", retries: 3 },
  { event: "link/clicked" },
  async ({ event, step }) => {
    const count = await step.run("get-click-count", async () =>
      db.clickEvent.count({ where: { shortcode: event.data.shortcode } })
    );

    if (count > 0 && count % 1000 === 0) {
      await step.run("send-milestone-notification", async () => {
        // enqueue a notification, itself another async event (Part 7)
      });
    }
  }
);
```

Neither function knows the other exists. Adding a third consumer (fraud detection) later requires zero changes to producer or existing consumers.

### 4. Handling Spikes: Backpressure and Consumer Scaling

A queue absorbs a burst, but workers have a finite rate. If producers sustainedly outpace consumers, the queue grows unboundedly. Remedies:

- **Scale consumers independently from producers** — workers autoscale on queue depth, not request rate.
- **Apply backpressure deliberately** at the producer once queue depth crosses a threshold (Part 6 covers rate limiting) — better than an unbounded queue causing an uncontrolled outage.
- **Partition topics/queues** keyed by shortcode so one viral link doesn't starve processing for everything else, while preserving per-key ordering.

### 5. Idempotency in Async Consumers (preview of Part 6)

Message delivery is generally at-least-once, so every consumer must be safe to run twice on the same event. `recordClick` is naturally idempotent-ish for analytics, but a consumer charging a card or sending an email must deduplicate explicitly via an idempotency key. Full pattern in Part 6.

### 6. C4 Diagram, Event Flow

```
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

Component(redirect, "Redirect Handler", "Next.js Route", "Synchronous: cache lookup + redirect")
Component(broker, "Event Bus", "Inngest / Kafka", "Durable, replayable event log")
Component(clickWorker, "Click Recorder", "Async Worker", "Writes to click_events")
Component(notifyWorker, "Threshold Checker", "Async Worker", "Fires milestone notifications")
Component(fraudWorker, "Fraud Detector (future)", "Async Worker", "Not yet built, added with zero producer changes")

Rel(redirect, broker, "Emits link/clicked event")
Rel(broker, clickWorker, "Delivers event")
Rel(broker, notifyWorker, "Delivers same event")
Rel(broker, fraudWorker, "Would deliver same event")
@enduml
```

### 7. Design Challenge

Quikn's campaign hits 8,000 events/second for six hours. The click-recording worker can currently sustain 2,000 writes/second against Postgres. Design the fix, and explain what happens to the threshold checker if you do nothing to it.

### 8. Solution and Discussion

The event bus absorbs the spike regardless of consumer speed — nothing is lost immediately. Fixes, in order of preference: **(1) batch writes** — consume in small batches and do one multi-row INSERT, dramatically reducing per-row overhead. **(2) scale consumers horizontally**, each owning a different partition (by shortcode hash), so throughput scales roughly linearly with worker count, up to Postgres's own ceiling (Part 3). **(3) temporarily delay aggregation** — write raw events to a cheap sink and run Postgres aggregation as a slightly-delayed batch job, trading analytics freshness for throughput headroom.

If nothing is done to the threshold checker: it still receives every event (broker delivers to all subscribers independently), but issuing 8,000 `COUNT` queries/second against the same table competes with the click-recorder and likely falls behind or times out — degrading independently without taking down the recording path. Its own fix: check thresholds against an approximate Redis `INCR` counter (Part 2) rather than a live `COUNT`. Lesson: "decoupled" does not mean "automatically scales together" — each consumer must be scaled and optimized for its own load profile.

---
*Next: "Scalable Systems Design - Part 5: Service Communication"*
