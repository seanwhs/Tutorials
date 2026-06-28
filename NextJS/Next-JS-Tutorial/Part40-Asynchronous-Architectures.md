# Next.js 16 for Absolute Beginners

# Part 40 — Background Jobs, Queues, Cron Jobs, and Asynchronous Architectures

> **Goal of this lesson:** Learn how to build production-grade asynchronous systems using Next.js 16, background jobs, queues, workers, retries, scheduled tasks, and event-driven architectures.

---

# The Second Biggest Lie in Web Development

The first lie is:

> "Users wait for pages to load."

The second lie is:

> "Everything should happen immediately."

---

# Beginners Write Code Like This

```ts
await uploadImage();

await resizeImage();

await generateThumbnail();

await sendEmail();

await notifyUsers();

await updateAnalytics();
```

Looks reasonable.

Unfortunately:

```text
User
  |
Wait
  |
Wait
  |
Wait
  |
Wait
  |
Wait
```

The user waits for everything.

---

# Real Applications Work Differently

```text
User Request
      |
Return Success
      |
Queue Work
      |
Background Processing
```

---

# Why Background Jobs Exist

Some tasks are:

```text
✓ Slow
✓ Expensive
✓ Unreliable
✓ Independent
✓ Retryable
```

Examples:

```text
Send email
Resize images
Generate PDFs
Process videos
Compute analytics
Generate reports
Run AI jobs
Backup databases
```

---

# Visualizing Synchronous Architecture

```text
Browser
    |
Server
    |
Task A
    |
Task B
    |
Task C
    |
Response
```

Total:

```text
A+B+C
```

---

# Visualizing Asynchronous Architecture

```text
Browser
    |
Server
    |
Queue Job
    |
Response

Worker
    |
Task A
    |
Task B
    |
Task C
```

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ Background jobs
✓ Job queues
✓ Workers
✓ Retries
✓ Delayed jobs
✓ Cron jobs
✓ Dead letter queues
✓ Event systems
✓ Email queues
✓ Media processing
✓ Reliability architecture
```

---

# Step 1 — Create Job Model

For learning purposes, we'll build our own queue.

Open:

```prisma
model Job {

  id String
     @id
     @default(uuid())

  type String

  payload Json

  status JobStatus
         @default(PENDING)

  attempts Int
           @default(0)

  scheduledAt DateTime
              @default(now())

  createdAt DateTime
            @default(now())

}
```

---

# Create Status Enum

```prisma
enum JobStatus {

  PENDING

  RUNNING

  COMPLETED

  FAILED

}
```

---

# Visualizing Jobs

```text
Job

    Type

    Payload

    Status

    Attempts
```

---

# Example Job

```json
{
  "type": "send_email",

  "payload": {
    "to": "user@example.com",
    "subject": "Welcome"
  },

  "status": "PENDING"
}
```

---

# Step 2 — Create Queue Function

```ts
export async function
enqueue(

  type: string,

  payload: any

) {

  return db.job.create({

    data: {

      type,

      payload,

    },

  });

}
```

---

# Usage

Instead of:

```ts
await sendEmail();
```

do:

```ts
await enqueue(

  "send_email",

  {

    email,

    name,

  }

);
```

---

# Visualizing Queueing

```text
Application
      |
Create Job
      |
Database
```

---

# Step 3 — Create Worker

Create:

```text
workers/process.ts
```

---

```ts
while(true) {

  const job =

    await db.job
      .findFirst({

      where: {

        status:
          "PENDING",

      },

    });

}
```

---

# Visualizing Worker

```text
Queue
   |
Poll
   |
Process
   |
Repeat
```

---

# Step 4 — Lock Jobs

Problem:

```text
Worker A
    |
Job 1

Worker B
    |
Job 1
```

Oops.

---

# Fix

```ts
await db.job.update({

  where: {

    id:
      job.id,

  },

  data: {

    status:
      "RUNNING",

  },

});
```

---

# Visualizing

```text
PENDING
    |
RUNNING
    |
COMPLETED
```

---

# Step 5 — Process Jobs

```ts
switch(job.type) {

  case
    "send_email":

    await sendEmail(
      job.payload
    );

    break;

}
```

---

# Example Email Job

```json
{
  "type":
    "send_email",

  "payload": {

    "email":
      "test@test.com",

    "subject":
      "Hello"

  }
}
```

---

# Step 6 — Complete Jobs

```ts
await db.job.update({

  where: {

    id:
      job.id,

  },

  data: {

    status:
      "COMPLETED",

  },

});
```

---

# Visualizing Lifecycle

```text
PENDING
    |
RUNNING
    |
COMPLETED
```

---

# Step 7 — Retry Failed Jobs

```ts
catch(error) {

  await db.job.update({

    where: {

      id:
        job.id,

    },

    data: {

      attempts: {

        increment: 1,

      },

      status:
        "PENDING",

    },

  });

}
```

---

# Why Retry?

Because failures happen.

Examples:

```text
Email server down

Network failure

Storage unavailable

Database timeout
```

---

# Visualizing Retries

```text
Attempt 1
     |
Fail

Attempt 2
     |
Fail

Attempt 3
     |
Success
```

---

# Step 8 — Maximum Retries

```ts
if (

  job.attempts >

  5

)
```

then:

```ts
status:

  "FAILED"
```

---

# Why?

Infinite retries create:

```text
Infinite suffering.
```

---

# Step 9 — Dead Letter Queue

Failed jobs move here:

```text
Main Queue
      |
Too Many Failures
      |
Dead Letter Queue
```

---

# Example

```prisma
model DeadJob {

  id String
     @id

  payload Json

  error String

}
```

---

# Why Dead Queues?

Because eventually someone asks:

```text
Why wasn't the email sent?
```

---

# Step 10 — Delayed Jobs

Example:

```text
Send reminder
tomorrow.
```

---

Store:

```ts
scheduledAt:

  tomorrow
```

---

Worker:

```ts
where: {

  scheduledAt: {

    lte:
      new Date(),

  },

}
```

---

# Visualizing

```text
Now
 |
Wait
 |
Tomorrow
 |
Execute
```

---

# Step 11 — Cron Jobs

Examples:

```text
Daily backups

Weekly reports

Analytics

Cleanup tasks
```

---

Example:

```bash
0 0 * * *
```

means:

```text
Midnight
Every Day
```

---

# Visualizing Cron

```text
Clock
   |
Trigger
   |
Execute
```

---

# Step 12 — Build Cleanup Job

```ts
export async function
cleanup() {

  await db.session
    .deleteMany({

      where: {

        expiresAt: {

          lt:
            new Date(),

        },

      },

    });

}
```

---

# Schedule

```text
Every hour.
```

---

# Step 13 — Email Queue

Bad:

```ts
await sendEmail();
```

---

Good:

```ts
await enqueue(

  "email",

  {

    to,

    subject,

  }

);
```

---

# Visualizing

```text
Signup
   |
Queue Email
   |
Return
```

---

# Step 14 — Image Processing Queue

Upload:

```text
User Upload
```

creates:

```text
Resize
Generate thumbnail
Optimize
Extract metadata
```

jobs.

---

# Visualizing

```text
Upload
    |
Queue
    |
Workers
    |
Variants
```

---

# Step 15 — Event-Driven Architecture

Instead of:

```ts
await sendEmail();

await analytics();

await notify();
```

emit:

```ts
emit(

  "user.registered",

  user
);
```

---

Then:

```text
Event
   |
Email
   |
Analytics
   |
Notifications
```

---

# Why Events?

Benefits:

```text
✓ Decoupling
✓ Scalability
✓ Flexibility
✓ Reliability
```

---

# Step 16 — Parallel Workers

One worker:

```text
100 jobs/minute
```

Ten workers:

```text
1000 jobs/minute
```

---

# Visualizing

```text
Queue

  |
  +---- Worker 1

  |
  +---- Worker 2

  |
  +---- Worker 3
```

---

# Step 17 — Queue Priorities

Example:

```text
HIGH

MEDIUM

LOW
```

---

Emails:

```text
LOW
```

Payments:

```text
HIGH
```

---

# Why?

Because:

```text
Password reset
```

is more important than:

```text
Weekly newsletter.
```

---

# Step 18 — Production Queue Systems

Nobody builds queues forever.

Eventually use:

```text
BullMQ

Redis Queue

RabbitMQ

SQS

Google Pub/Sub

Kafka
```

---

# Visualizing Production

```text
Application
      |
      V
Queue System
      |
      V
Workers
      |
      V
Services
```

---

# Step 19 — Background Jobs + Next.js

Next.js handles:

```text
Request
Response
Server Actions
```

Workers handle:

```text
Long-running work
```

---

# Architecture

```text
Browser
    |
Next.js
    |
Queue
    |
Worker
    |
External Service
```

---

# Step 20 — Full Asynchronous Architecture

```text
                 User
                  |
                  V
             Next.js App
                  |
          +-------+-------+
          |               |
          V               V
      Immediate        Queue
       Response          |
                          |
                    Background
                      Worker
                          |
            +------+------+------+
            |             |      |
            V             V      V
          Email       Images   Analytics
```

---

# Reliability Principles

Never assume:

```text
Network works.

Email works.

Storage works.

API works.
```

Assume:

```text
Everything eventually fails.
```

---

# What We've Built

```text
✓ Queues

✓ Workers

✓ Retries

✓ Dead letters

✓ Delayed jobs

✓ Cron jobs

✓ Events

✓ Email queues

✓ Image processing

✓ Distributed workers
```

---

# Queue Philosophy

Beginners build:

```text
Applications.
```

Professional engineers build:

```text
Systems that survive failure.
```

Because software doesn't fail when code is wrong.

Software fails when reality happens.

---

# Exercises

## Exercise 1

Implement:

```text
Password reset email queue.
```

---

## Exercise 2

Implement:

```text
Thumbnail generation queue.
```

---

## Exercise 3

Add:

```text
Job priority.
```

---

## Exercise 4

Create:

```text
Event bus.
```

---

# Mental Model

Beginners think:

```text
Do work now.
```

Professional engineers think:

```text
Do work eventually.
```

Because scalability begins when users stop waiting.

---

# Part 41 Preview

In the next chapter we'll build:

# Real-Time Systems, WebSockets, SSE, and Live Updates

Including:

```text
✓ Polling
✓ Server-Sent Events
✓ WebSockets
✓ Presence
✓ Live notifications
✓ Live dashboards
✓ Real-time comments
✓ Event streams
✓ Distributed realtime
✓ Scalability patterns
```

This is where Next.js becomes a real-time application platform.
