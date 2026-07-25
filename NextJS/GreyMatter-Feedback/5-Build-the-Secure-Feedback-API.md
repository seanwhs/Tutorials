# Part 5: Build the Secure Feedback API

In Part 4, participants could complete the form, validate required answers, and save drafts locally. In this part, we will create the server-side submission endpoint.

The endpoint will:

- Accept participant form submissions.
- Validate untrusted request data with Zod.
- Confirm that the session and published form version are still valid.
- Confirm every submitted question belongs to that form version.
- Validate rating ranges, NPS scores, choice options, and text length.
- Hash the client IP address without storing its raw value.
- Rate-limit submissions.
- Send a validated submission event to Inngest.
- Return a fast success response to the participant.
- Clear the local draft only after the server accepts the request.

> In Part 6, Inngest will consume these events and save responses and answers to Neon. This separation keeps the participant experience fast and gives background work reliable retry behavior.

---

## Step 5.1 — Install Upstash rate-limiting dependencies

### The Target

Install the packages needed for distributed rate limiting.

### The Concept

A rate limiter prevents a person or automated script from submitting the same form repeatedly in a short period.

An in-memory rate limiter works only inside one running server process. That is not sufficient for a deployed serverless application because several application instances may handle requests at the same time.

We will use **Upstash Redis** in production. Redis is a fast key-value data store. It acts like a shared ticket counter that every application instance can check.

For local development, GreyMatter Feedback will use a small in-memory fallback so you can continue building without creating an Upstash account immediately.

### The Implementation

Install the packages:

```bash
npm install @upstash/ratelimit @upstash/redis
```

Add these variables to `.env.example`.

### `.env.example`

```dotenv
# Optional during local development.
# Required for production distributed rate limiting.
UPSTASH_REDIS_REST_URL=""
UPSTASH_REDIS_REST_TOKEN=""
```

Add the same empty values to your private `.env` file.

### `.env`

```dotenv
UPSTASH_REDIS_REST_URL=""
UPSTASH_REDIS_REST_TOKEN=""
```

### The Verification

Run:

```bash
npm run lint
```

The command should complete successfully.

---

## Step 5.2 — Update server environment validation

### The Target

Add optional Upstash configuration to the environment schema.

### The Concept

We want local development to work without Upstash, but production must not silently use a single-server fallback.

The application will later enforce this rule:

```text
Development without Upstash → allowed
Production without Upstash  → rejected
```

### The Implementation

Replace `src/lib/env.ts` with this complete version.

### `src/lib/env.ts`

```ts
import { z } from "zod";

const environmentSchema = z.object({
  DATABASE_URL: z.string().url(),
  DIRECT_URL: z.string().url(),

  IP_HASH_SECRET: z.string().min(32),
  ADMIN_SESSION_SECRET: z.string().min(32),
  ADMIN_PASSWORD: z.string().min(12),

  NEXT_PUBLIC_APP_URL: z.string().url(),

  INNGEST_EVENT_KEY: z.string().optional(),
  INNGEST_SIGNING_KEY: z.string().optional(),

  S3_REGION: z.string().optional(),
  S3_BUCKET: z.string().optional(),
  S3_ACCESS_KEY_ID: z.string().optional(),
  S3_SECRET_ACCESS_KEY: z.string().optional(),
  S3_ENDPOINT: z.string().url().or(z.literal("")).optional(),

  UPSTASH_REDIS_REST_URL: z.string().url().or(z.literal("")).optional(),
  UPSTASH_REDIS_REST_TOKEN: z.string().optional(),
});

const parsedEnvironment = environmentSchema.safeParse({
  DATABASE_URL: process.env.DATABASE_URL,
  DIRECT_URL: process.env.DIRECT_URL,
  IP_HASH_SECRET: process.env.IP_HASH_SECRET,
  ADMIN_SESSION_SECRET: process.env.ADMIN_SESSION_SECRET,
  ADMIN_PASSWORD: process.env.ADMIN_PASSWORD,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  INNGEST_EVENT_KEY: process.env.INNGEST_EVENT_KEY,
  INNGEST_SIGNING_KEY: process.env.INNGEST_SIGNING_KEY,
  S3_REGION: process.env.S3_REGION,
  S3_BUCKET: process.env.S3_BUCKET,
  S3_ACCESS_KEY_ID: process.env.S3_ACCESS_KEY_ID,
  S3_SECRET_ACCESS_KEY: process.env.S3_SECRET_ACCESS_KEY,
  S3_ENDPOINT: process.env.S3_ENDPOINT,
  UPSTASH_REDIS_REST_URL: process.env.UPSTASH_REDIS_REST_URL,
  UPSTASH_REDIS_REST_TOKEN: process.env.UPSTASH_REDIS_REST_TOKEN,
});

if (!parsedEnvironment.success) {
  console.error(
    "Invalid GreyMatter Feedback environment configuration:",
    parsedEnvironment.error.flatten().fieldErrors,
  );

  throw new Error(
    "Invalid environment configuration. Check the server logs for details.",
  );
}

const upstashConfigured =
  Boolean(parsedEnvironment.data.UPSTASH_REDIS_REST_URL) &&
  Boolean(parsedEnvironment.data.UPSTASH_REDIS_REST_TOKEN);

if (process.env.NODE_ENV === "production" && !upstashConfigured) {
  throw new Error(
    "UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN are required in production.",
  );
}

export const env = parsedEnvironment.data;
```

### The Verification

Run:

```bash
npm run db:test
```

The database connection test should still succeed.

---

## Step 5.3 — Create privacy-preserving client IP hashing

### The Target

Create a server-only helper that reads a request IP address and converts it into a daily salted SHA-256 hash.

### The Concept

An IP address can be personal data. GreyMatter Feedback does not need to store raw IP addresses to reduce repeated submissions.

Instead, we will generate a one-way fingerprint:

```text
daily salt + client IP address
            ↓
       SHA-256 hash
```

The salt changes each day. This means the same IP produces a different fingerprint tomorrow.

That gives us a limited privacy-preserving identifier for rate limiting without keeping the original IP address in Neon.

### The Implementation

Create this file.

### `src/lib/client-identity.ts`

```ts
import "server-only";

import { createHash } from "node:crypto";
import { env } from "@/lib/env";

/**
 * In a deployed application, a trusted reverse proxy commonly forwards
 * the original client IP in x-forwarded-for. The first address is the
 * original client; later addresses represent proxies in the request path.
 */
export function getClientIpAddress(request: Request): string {
  const forwardedFor = request.headers.get("x-forwarded-for");

  if (forwardedFor) {
    const firstAddress = forwardedFor.split(",")[0]?.trim();

    if (firstAddress) {
      return firstAddress;
    }
  }

  const realIp = request.headers.get("x-real-ip");

  if (realIp) {
    return realIp.trim();
  }

  /**
   * Local browser requests generally do not provide proxy headers.
   * A stable fallback keeps development rate-limit behavior testable,
   * while production platforms should provide a real forwarded IP header.
   */
  return "unknown-client";
}

function getUtcDay(): string {
  return new Date().toISOString().slice(0, 10);
}

export function hashClientIpAddress(ipAddress: string): string {
  const dailySalt = `${env.IP_HASH_SECRET}:${getUtcDay()}`;

  return createHash("sha256")
    .update(`${dailySalt}:${ipAddress}`)
    .digest("hex");
}
```

### The Verification

Create a temporary test script.

### `scripts/test-client-identity.ts`

```ts
import { hashClientIpAddress } from "../src/lib/client-identity";

const firstHash = hashClientIpAddress("203.0.113.25");
const secondHash = hashClientIpAddress("203.0.113.25");
const differentIpHash = hashClientIpAddress("203.0.113.26");

console.log({
  sameIpProducesSameHashToday: firstHash === secondHash,
  differentIpProducesDifferentHash: firstHash !== differentIpHash,
  hashLength: firstHash.length,
});
```

Add this script to `package.json`.

### `package.json`

```json
{
  "scripts": {
    "test:identity": "tsx scripts/test-client-identity.ts"
  }
}
```

Run:

```bash
npm run test:identity
```

Expected output:

```text
{
  sameIpProducesSameHashToday: true,
  differentIpProducesDifferentHash: true,
  hashLength: 64
}
```

Delete the temporary test script after verification:

```bash
rm scripts/test-client-identity.ts
```

Remove `test:identity` from `package.json`.

---

## Step 5.4 — Create the submission rate limiter

### The Target

Create a rate limiter that uses Upstash Redis when configured and a local development fallback otherwise.

### The Concept

The participant API will check two limits:

1. **IP and session limit**: prevents one client from repeatedly submitting to one session.
2. **Session limit**: provides a high-volume safety limit for the whole session.

The IP-and-session key looks like this:

```text
feedback:ip:REACT-2026-Q3:<hashed-client-ip>
```

The session-wide key looks like this:

```text
feedback:session:REACT-2026-Q3
```

In production, those counters live in Upstash Redis. In local development, they live in memory and reset when the Next.js server restarts.

### The Implementation

Create this file.

### `src/lib/rate-limit.ts`

```ts
import "server-only";

import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";
import { env } from "@/lib/env";

type RateLimitResult = {
  allowed: boolean;
  limit: number;
  remaining: number;
  resetAt: number;
};

type MemoryRateLimitEntry = {
  count: number;
  resetAt: number;
};

const memoryStore = new Map<string, MemoryRateLimitEntry>();

const upstashConfigured =
  Boolean(env.UPSTASH_REDIS_REST_URL) &&
  Boolean(env.UPSTASH_REDIS_REST_TOKEN);

const redis = upstashConfigured
  ? new Redis({
      url: env.UPSTASH_REDIS_REST_URL,
      token: env.UPSTASH_REDIS_REST_TOKEN,
    })
  : null;

/**
 * One submission per client/session per five minutes is a conservative
 * default for anonymous feedback. It can be adjusted for your use case.
 */
const perClientSubmissionLimiter = redis
  ? new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(1, "5 m"),
      prefix: "greymatter:feedback:client",
      analytics: true,
    })
  : null;

/**
 * This high safety limit protects a single session from accidental or
 * malicious bursts while allowing normal event usage.
 */
const perSessionSubmissionLimiter = redis
  ? new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(500, "1 h"),
      prefix: "greymatter:feedback:session",
      analytics: true,
    })
  : null;

function memoryLimit(
  key: string,
  limit: number,
  windowMilliseconds: number,
): RateLimitResult {
  const now = Date.now();
  const currentEntry = memoryStore.get(key);

  if (!currentEntry || currentEntry.resetAt <= now) {
    const resetAt = now + windowMilliseconds;

    memoryStore.set(key, {
      count: 1,
      resetAt,
    });

    return {
      allowed: true,
      limit,
      remaining: limit - 1,
      resetAt,
    };
  }

  if (currentEntry.count >= limit) {
    return {
      allowed: false,
      limit,
      remaining: 0,
      resetAt: currentEntry.resetAt,
    };
  }

  currentEntry.count += 1;

  return {
    allowed: true,
    limit,
    remaining: limit - currentEntry.count,
    resetAt: currentEntry.resetAt,
  };
}

async function limitClientSubmission(key: string): Promise<RateLimitResult> {
  if (!perClientSubmissionLimiter) {
    return memoryLimit(key, 1, 5 * 60 * 1000);
  }

  const result = await perClientSubmissionLimiter.limit(key);

  return {
    allowed: result.success,
    limit: result.limit,
    remaining: result.remaining,
    resetAt: result.reset,
  };
}

async function limitSessionSubmission(key: string): Promise<RateLimitResult> {
  if (!perSessionSubmissionLimiter) {
    return memoryLimit(key, 500, 60 * 60 * 1000);
  }

  const result = await perSessionSubmissionLimiter.limit(key);

  return {
    allowed: result.success,
    limit: result.limit,
    remaining: result.remaining,
    resetAt: result.reset,
  };
}

export async function checkFeedbackSubmissionRateLimit(
  sessionId: string,
  clientIpHash: string,
): Promise<RateLimitResult> {
  const clientResult = await limitClientSubmission(
    `session:${sessionId}:client:${clientIpHash}`,
  );

  if (!clientResult.allowed) {
    return clientResult;
  }

  const sessionResult = await limitSessionSubmission(`session:${sessionId}`);

  return sessionResult;
}
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both commands should succeed.

---

## Step 5.5 — Create the feedback submission schema

### The Target

Create a Zod schema that checks the public JSON request body before it reaches the database or background event bus.

### The Concept

Browser code is not a security boundary. Someone can use browser developer tools, a script, or an API client to send malformed data directly to:

```text
POST /api/feedback
```

Zod acts like a security guard at the service desk. It checks the request structure before further processing.

### The Implementation

Create this file.

### `src/lib/feedback-submission.ts`

```ts
import { z } from "zod";

const sessionIdSchema = z
  .string()
  .trim()
  .min(3)
  .max(64)
  .regex(/^[A-Za-z0-9-]+$/);

const uuidSchema = z.string().uuid();

const answerSchema = z.object({
  questionId: uuidSchema,
  value: z.union([
    z.number().int(),
    z.string().trim().max(5000),
  ]),
});

export const feedbackSubmissionSchema = z.object({
  submissionId: uuidSchema,
  sessionId: sessionIdSchema,
  formVersionId: uuidSchema,
  answers: z.array(answerSchema).min(1).max(100),
  metadata: z
    .object({
      source: z.string().trim().max(50).optional(),
      screenWidth: z.number().int().min(0).max(10000).optional(),
      screenHeight: z.number().int().min(0).max(10000).optional(),
    })
    .optional(),
});

export type FeedbackSubmissionInput = z.infer<typeof feedbackSubmissionSchema>;

export type ValidatedFeedbackAnswer = {
  questionId: string;
  numericValue: number | null;
  textValue: string | null;
};

export type FeedbackSubmissionEventData = {
  submissionId: string;
  sessionId: string;
  formVersionId: string;
  clientIpHash: string;
  metadata: {
    source?: string;
    screenWidth?: number;
    screenHeight?: number;
    userAgent: string;
  };
  answers: ValidatedFeedbackAnswer[];
};
```

### The Verification

Run:

```bash
npm run lint
```

The command should complete successfully.

---

## Step 5.6 — Create the Inngest event client contract

### The Target

Define the event shape that the API will send and Part 6 will process.

### The Concept

An event contract is a shared agreement between two systems:

```text
API route sends event
        ↓
Inngest function receives event
```

Both sides need the same field names and data types.

It is similar to a shipping label: the sender and warehouse must agree about where the address, package ID, and handling instructions appear.

### The Implementation

Create this file.

### `src/inngest/client.ts`

```ts
import { Inngest } from "inngest";
import type { FeedbackSubmissionEventData } from "@/lib/feedback-submission";

type GreyMatterEvents = {
  "feedback/submitted": {
    data: FeedbackSubmissionEventData;
  };

  "report/generate.pdf": {
    data: {
      reportId: string;
      sessionId: string;
      requestedBy: string;
    };
  };
};

export const inngest = new Inngest({
  id: "greymatter-feedback",
  eventKey: process.env.INNGEST_EVENT_KEY,
  signingKey: process.env.INNGEST_SIGNING_KEY,
  schemas: new Inngest.EventSchemas().fromRecord<GreyMatterEvents>(),
});
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both commands should succeed.

---

## Step 5.7 — Create authoritative server-side answer validation

### The Target

Validate answers against the published form configuration stored in Neon.

### The Concept

The request body says what the participant claims they answered. The server must compare that claim to the official published form.

For example:

```text
Client submits score 900
Question is a 1–5 rating
Server rejects it
```

Or:

```text
Client submits "Pizza"
Question options are "Presentation", "Exercises", "Discussion"
Server rejects it
```

The API will validate against the exact form version identified by the request.

### The Implementation

Create this file.

### `src/lib/validate-feedback.ts`

```ts
import "server-only";

import { FormVersionStatus, QuestionType } from "@prisma/client";
import { prisma } from "@/lib/prisma";
import {
  parseChoiceOptions,
  parseQuestionSettings,
  type RatingSettings,
  type TextSettings,
} from "@/types/forms";
import type {
  FeedbackSubmissionInput,
  ValidatedFeedbackAnswer,
} from "@/lib/feedback-submission";

export type FeedbackValidationResult =
  | {
      success: true;
      answers: ValidatedFeedbackAnswer[];
    }
  | {
      success: false;
      status: 400 | 404 | 409;
      message: string;
    };

export async function validateFeedbackSubmission(
  submission: FeedbackSubmissionInput,
): Promise<FeedbackValidationResult> {
  const session = await prisma.session.findUnique({
    where: {
      id: submission.sessionId,
    },
    include: {
      activeFormVersion: {
        include: {
          questions: {
            orderBy: {
              orderIndex: "asc",
            },
          },
        },
      },
    },
  });

  if (!session) {
    return {
      success: false,
      status: 404,
      message: "Feedback session not found.",
    };
  }

  if (!session.isActive) {
    return {
      success: false,
      status: 409,
      message: "This feedback session is closed.",
    };
  }

  if (
    !session.activeFormVersion ||
    session.activeFormVersion.status !== FormVersionStatus.PUBLISHED
  ) {
    return {
      success: false,
      status: 409,
      message: "This feedback form is not currently available.",
    };
  }

  if (session.activeFormVersion.id !== submission.formVersionId) {
    return {
      success: false,
      status: 409,
      message:
        "This feedback form has changed. Refresh the page before submitting your answers.",
    };
  }

  const duplicateQuestionIds = new Set<string>();
  const submittedAnswers = new Map<string, unknown>();

  for (const answer of submission.answers) {
    if (duplicateQuestionIds.has(answer.questionId)) {
      return {
        success: false,
        status: 400,
        message: "A question was answered more than once.",
      };
    }

    duplicateQuestionIds.add(answer.questionId);
    submittedAnswers.set(answer.questionId, answer.value);
  }

  const validatedAnswers: ValidatedFeedbackAnswer[] = [];

  for (const question of session.activeFormVersion.questions) {
    const submittedValue = submittedAnswers.get(question.id);
    const hasValue =
      typeof submittedValue === "number" ||
      (typeof submittedValue === "string" && submittedValue.trim().length > 0);

    if (question.isRequired && !hasValue) {
      return {
        success: false,
        status: 400,
        message: `The required question "${question.questionText}" is missing an answer.`,
      };
    }

    if (!hasValue) {
      continue;
    }

    if (
      question.questionType === QuestionType.RATING ||
      question.questionType === QuestionType.NPS
    ) {
      if (typeof submittedValue !== "number" || !Number.isInteger(submittedValue)) {
        return {
          success: false,
          status: 400,
          message: `Question "${question.questionText}" requires a numeric score.`,
        };
      }

      if (question.questionType === QuestionType.RATING) {
        const settings = parseQuestionSettings(
          question.questionType,
          question.settings,
        ) as RatingSettings;

        if (
          submittedValue < settings.min ||
          submittedValue > settings.max
        ) {
          return {
            success: false,
            status: 400,
            message: `Question "${question.questionText}" requires a score between ${settings.min} and ${settings.max}.`,
          };
        }
      }

      if (
        question.questionType === QuestionType.NPS &&
        (submittedValue < 0 || submittedValue > 10)
      ) {
        return {
          success: false,
          status: 400,
          message: `Question "${question.questionText}" requires a score between 0 and 10.`,
        };
      }

      validatedAnswers.push({
        questionId: question.id,
        numericValue: submittedValue,
        textValue: null,
      });

      continue;
    }

    if (typeof submittedValue !== "string") {
      return {
        success: false,
        status: 400,
        message: `Question "${question.questionText}" requires text.`,
      };
    }

    const normalizedValue = submittedValue.trim();

    if (question.questionType === QuestionType.TEXT) {
      const settings = parseQuestionSettings(
        question.questionType,
        question.settings,
      ) as TextSettings;

      if (normalizedValue.length > settings.maxLength) {
        return {
          success: false,
          status: 400,
          message: `Question "${question.questionText}" exceeds the maximum allowed length.`,
        };
      }
    }

    if (question.questionType === QuestionType.CHOICE) {
      const options = parseChoiceOptions(question.options);

      if (!options.includes(normalizedValue)) {
        return {
          success: false,
          status: 400,
          message: `Question "${question.questionText}" contains an invalid option.`,
        };
      }
    }

    validatedAnswers.push({
      questionId: question.id,
      numericValue: null,
      textValue: normalizedValue,
    });
  }

  const knownQuestionIds = new Set(
    session.activeFormVersion.questions.map((question) => question.id),
  );

  for (const submittedQuestionId of submittedAnswers.keys()) {
    if (!knownQuestionIds.has(submittedQuestionId)) {
      return {
        success: false,
        status: 400,
        message: "The form submission contains an unknown question.",
      };
    }
  }

  if (validatedAnswers.length === 0) {
    return {
      success: false,
      status: 400,
      message: "Provide at least one answer before submitting feedback.",
    };
  }

  return {
    success: true,
    answers: validatedAnswers,
  };
}
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both commands should complete successfully.

---

## Step 5.8 — Create the `POST /api/feedback` endpoint

### The Target

Create the public API endpoint that validates, rate-limits, and queues participant feedback.

### The Concept

This API route is the controlled service desk for submissions.

Its workflow is:

```text
Participant form
   ↓
POST /api/feedback
   ↓
Validate JSON structure
   ↓
Hash IP address
   ↓
Check rate limit
   ↓
Validate against current published form in Neon
   ↓
Send feedback/submitted event to Inngest
   ↓
Return 202 Accepted
```

`202 Accepted` means:

> “The request passed validation and was accepted for asynchronous processing.”

It does **not** claim that the background worker has already finished saving the response.

### The Implementation

Create the route folder:

```bash
mkdir -p src/app/api/feedback
```

Create this file.

### `src/app/api/feedback/route.ts`

```ts
import { NextResponse } from "next/server";
import { getClientIpAddress, hashClientIpAddress } from "@/lib/client-identity";
import {
  feedbackSubmissionSchema,
  type FeedbackSubmissionEventData,
} from "@/lib/feedback-submission";
import { checkFeedbackSubmissionRateLimit } from "@/lib/rate-limit";
import { validateFeedbackSubmission } from "@/lib/validate-feedback";
import { inngest } from "@/inngest/client";

export const runtime = "nodejs";

export async function POST(request: Request): Promise<NextResponse> {
  let requestBody: unknown;

  try {
    requestBody = await request.json();
  } catch {
    return NextResponse.json(
      {
        error: "The request body must contain valid JSON.",
      },
      {
        status: 400,
      },
    );
  }

  const parsedSubmission = feedbackSubmissionSchema.safeParse(requestBody);

  if (!parsedSubmission.success) {
    return NextResponse.json(
      {
        error: "The feedback submission has an invalid format.",
        details: parsedSubmission.error.flatten().fieldErrors,
      },
      {
        status: 400,
      },
    );
  }

  const clientIpAddress = getClientIpAddress(request);
  const clientIpHash = hashClientIpAddress(clientIpAddress);

  try {
    const rateLimitResult = await checkFeedbackSubmissionRateLimit(
      parsedSubmission.data.sessionId,
      clientIpHash,
    );

    if (!rateLimitResult.allowed) {
      const retryAfterSeconds = Math.max(
        1,
        Math.ceil((rateLimitResult.resetAt - Date.now()) / 1000),
      );

      return NextResponse.json(
        {
          error:
            "Too many feedback submissions were received from this device. Please try again later.",
        },
        {
          status: 429,
          headers: {
            "Retry-After": String(retryAfterSeconds),
            "X-RateLimit-Limit": String(rateLimitResult.limit),
            "X-RateLimit-Remaining": String(rateLimitResult.remaining),
          },
        },
      );
    }
  } catch (error) {
    console.error("Feedback rate-limit check failed.", error);

    return NextResponse.json(
      {
        error:
          "We could not verify the submission limit. Please try again shortly.",
      },
      {
        status: 503,
      },
    );
  }

  const validationResult = await validateFeedbackSubmission(parsedSubmission.data);

  if (!validationResult.success) {
    return NextResponse.json(
      {
        error: validationResult.message,
      },
      {
        status: validationResult.status,
      },
    );
  }

  const userAgent = request.headers.get("user-agent") ?? "";

  const eventData: FeedbackSubmissionEventData = {
    submissionId: parsedSubmission.data.submissionId,
    sessionId: parsedSubmission.data.sessionId,
    formVersionId: parsedSubmission.data.formVersionId,
    clientIpHash,
    metadata: {
      source: parsedSubmission.data.metadata?.source,
      screenWidth: parsedSubmission.data.metadata?.screenWidth,
      screenHeight: parsedSubmission.data.metadata?.screenHeight,
      // Limiting stored metadata avoids unnecessarily retaining a large value.
      userAgent: userAgent.slice(0, 500),
    },
    answers: validationResult.answers,
  };

  try {
    await inngest.send({
      name: "feedback/submitted",
      data: eventData,
    });
  } catch (error) {
    console.error("Unable to queue feedback submission with Inngest.", error);

    return NextResponse.json(
      {
        error:
          "We could not accept your feedback right now. Your draft remains saved on this device, so please try again.",
      },
      {
        status: 503,
      },
    );
  }

  return NextResponse.json(
    {
      accepted: true,
      submissionId: eventData.submissionId,
    },
    {
      status: 202,
    },
  );
}
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both commands should succeed.

At this stage, a valid submission requires an Inngest development server or production event key. We will configure the worker endpoint and development workflow in Part 6.

You can test malformed JSON immediately:

```bash
curl -i \
  -X POST "http://localhost:3000/api/feedback" \
  -H "Content-Type: application/json" \
  --data "not-json"
```

Expected status:

```text
HTTP/1.1 400 Bad Request
```

Expected JSON:

```json
{
  "error": "The request body must contain valid JSON."
}
```

---

## Step 5.9 — Connect the participant form to the secure API

### The Target

Update the mobile participant form so it submits validated answers to `/api/feedback`.

### The Concept

The browser will create one unique submission ID before sending the request.

That ID becomes the idempotency key for the submission:

```text
Browser creates UUID
   ↓
API sends UUID to Inngest
   ↓
Inngest worker stores UUID as Response.eventId
   ↓
Retries do not create duplicate responses
```

The local draft is cleared only when the API returns `202 Accepted`.

### The Implementation

Replace the complete contents of this file.

### `src/components/participant/feedback-form.tsx`

```tsx
"use client";

import { useEffect, useState } from "react";
import { QuestionInput } from "@/components/participant/question-input";
import {
  clearParticipantDraft,
  loadParticipantDraft,
  saveParticipantDraft,
  type ParticipantAnswerValue,
} from "@/lib/participant-draft";
import type { ParticipantQuestion } from "@/types/forms";

type FeedbackFormProps = {
  sessionId: string;
  formVersionId: string;
  questions: ParticipantQuestion[];
};

type ValidationErrors = Record<string, string>;

type SubmissionState =
  | {
      kind: "idle";
    }
  | {
      kind: "submitting";
    }
  | {
      kind: "success";
    }
  | {
      kind: "error";
      message: string;
    };

function isAnswered(value: ParticipantAnswerValue | undefined): boolean {
  if (typeof value === "number") {
    return true;
  }

  return typeof value === "string" && value.trim().length > 0;
}

function getScreenMetadata() {
  if (typeof window === "undefined") {
    return undefined;
  }

  return {
    source: new URLSearchParams(window.location.search).get("src") ?? undefined,
    screenWidth: window.screen.width,
    screenHeight: window.screen.height,
  };
}

export function FeedbackForm({
  sessionId,
  formVersionId,
  questions,
}: FeedbackFormProps) {
  const [answers, setAnswers] = useState<Record<string, ParticipantAnswerValue>>(
    {},
  );
  const [errors, setErrors] = useState<ValidationErrors>({});
  const [draftRestored, setDraftRestored] = useState(false);
  const [submissionState, setSubmissionState] = useState<SubmissionState>({
    kind: "idle",
  });

  useEffect(() => {
    const storedDraft = loadParticipantDraft(sessionId, formVersionId);

    if (storedDraft) {
      setAnswers(storedDraft.answers);
      setDraftRestored(true);
    }
  }, [formVersionId, sessionId]);

  function updateAnswer(questionId: string, value: ParticipantAnswerValue) {
    setSubmissionState({ kind: "idle" });

    setAnswers((currentAnswers) => {
      const nextAnswers = {
        ...currentAnswers,
        [questionId]: value,
      };

      saveParticipantDraft(sessionId, formVersionId, nextAnswers);

      return nextAnswers;
    });

    setErrors((currentErrors) => {
      const nextErrors = { ...currentErrors };
      delete nextErrors[questionId];
      return nextErrors;
    });
  }

  function validateForm(): ValidationErrors {
    const nextErrors: ValidationErrors = {};

    for (const question of questions) {
      if (question.isRequired && !isAnswered(answers[question.id])) {
        nextErrors[question.id] = "This question requires an answer.";
      }
    }

    return nextErrors;
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const validationErrors = validateForm();
    setErrors(validationErrors);

    if (Object.keys(validationErrors).length > 0) {
      const firstInvalidQuestionId = Object.keys(validationErrors)[0];

      document
        .getElementById(firstInvalidQuestionId ?? "")
        ?.scrollIntoView({ behavior: "smooth", block: "center" });

      return;
    }

    setSubmissionState({ kind: "submitting" });

    const submittedAnswers = Object.entries(answers)
      .filter(([, value]) => isAnswered(value))
      .map(([questionId, value]) => ({
        questionId,
        value: typeof value === "string" ? value.trim() : value,
      }));

    try {
      const response = await fetch("/api/feedback", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          submissionId: crypto.randomUUID(),
          sessionId,
          formVersionId,
          answers: submittedAnswers,
          metadata: getScreenMetadata(),
        }),
      });

      const responseBody = (await response.json()) as {
        accepted?: boolean;
        error?: string;
      };

      if (!response.ok || !responseBody.accepted) {
        setSubmissionState({
          kind: "error",
          message:
            responseBody.error ??
            "We could not submit your feedback. Please try again.",
        });

        return;
      }

      clearParticipantDraft(sessionId, formVersionId);
      setDraftRestored(false);
      setSubmissionState({ kind: "success" });
    } catch {
      setSubmissionState({
        kind: "error",
        message:
          "Your device could not reach the feedback service. Your draft is still saved, so please try again when you have a connection.",
      });
    }
  }

  function discardDraft() {
    clearParticipantDraft(sessionId, formVersionId);
    setAnswers({});
    setErrors({});
    setDraftRestored(false);
    setSubmissionState({ kind: "idle" });
  }

  if (submissionState.kind === "success") {
    return (
      <section
        aria-live="polite"
        className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 text-center shadow-sm sm:p-8"
      >
        <p className="text-sm font-semibold uppercase tracking-wide text-emerald-800">
          Feedback received
        </p>

        <h2 className="mt-3 text-2xl font-bold tracking-tight text-emerald-950">
          Thank you for your feedback.
        </h2>

        <p className="mt-3 leading-7 text-emerald-900">
          Your response was accepted and is being processed securely.
        </p>
      </section>
    );
  }

  return (
    <form onSubmit={handleSubmit}>
      {draftRestored ? (
        <div className="mb-6 rounded-xl border border-indigo-200 bg-indigo-50 p-4 text-sm leading-6 text-indigo-950">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <p>
              <strong>Draft restored.</strong> Your previous answers were
              recovered from this browser.
            </p>

            <button
              className="min-h-10 rounded-lg px-3 py-2 font-semibold text-indigo-800 underline decoration-indigo-300 underline-offset-4 hover:text-indigo-950"
              onClick={discardDraft}
              type="button"
            >
              Discard draft
            </button>
          </div>
        </div>
      ) : null}

      <div className="space-y-5">
        {questions.map((question) => (
          <div id={question.id} key={question.id}>
            <QuestionInput
              error={errors[question.id]}
              onChange={updateAnswer}
              question={question}
              value={answers[question.id]}
            />
          </div>
        ))}
      </div>

      {submissionState.kind === "error" ? (
        <div
          aria-live="polite"
          className="mt-6 rounded-2xl border border-red-200 bg-red-50 p-5 text-red-950"
        >
          <h2 className="font-bold">Your feedback was not submitted.</h2>
          <p className="mt-2 text-sm leading-6">{submissionState.message}</p>
          <p className="mt-2 text-sm leading-6">
            Your answers remain saved on this device.
          </p>
        </div>
      ) : null}

      <button
        className="mt-6 inline-flex min-h-12 w-full items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-indigo-400"
        disabled={submissionState.kind === "submitting"}
        type="submit"
      >
        {submissionState.kind === "submitting"
          ? "Submitting feedback…"
          : "Submit feedback"}
      </button>

      <p className="mt-4 text-center text-sm leading-6 text-slate-500">
        Your draft is saved on this device until your submission is accepted.
      </p>
    </form>
  );
}
```

### The Verification

Start the application:

```bash
npm run dev
```

Open:

```text
http://localhost:3000/e/REACT-2026-Q3
```

Complete the required questions and submit.

Until Part 6 configures the Inngest development server and worker, you may see this expected error:

```text
We could not accept your feedback right now. Your draft remains saved on this device, so please try again.
```

Confirm that:

1. The error is understandable.
2. The page does not falsely display a success message.
3. Refreshing the page restores the answers.
4. Required-field browser validation still works before the API call.

---

## Step 5.10 — Inspect API validation with curl

### The Target

Test the API directly, without relying on the browser form.

### The Concept

Direct API tests are useful because they confirm the server validates requests independently of the user interface.

### The Implementation

Start the Next.js server:

```bash
npm run dev
```

Test malformed request data:

```bash
curl -i \
  -X POST "http://localhost:3000/api/feedback" \
  -H "Content-Type: application/json" \
  --data '{"sessionId":"bad id"}'
```

### The Verification

Expected response:

```text
HTTP/1.1 400 Bad Request
```

You should receive JSON containing:

```json
{
  "error": "The feedback submission has an invalid format."
}
```

To test the rate limiter manually, send two valid requests after completing Part 6, when Inngest is running. The second request from the same local device/session within five minutes should return:

```text
HTTP/1.1 429 Too Many Requests
```

with a `Retry-After` response header.

---

## Part 5 Reference: Security Layers

The feedback submission flow now has these protections:

```text
Participant browser
   ↓
Client-side required-question validation
   ↓
POST /api/feedback
   ↓
Zod request-shape validation
   ↓
Daily salted SHA-256 IP hash
   ↓
Rate limiting
   ↓
Database-backed published-form validation
   ↓
Question-type and option validation
   ↓
Inngest event queue
```

Important files added in this part:

```text
src/
├── app/
│   └── api/
│       └── feedback/
│           └── route.ts
├── inngest/
│   └── client.ts
└── lib/
    ├── client-identity.ts
    ├── feedback-submission.ts
    ├── rate-limit.ts
    └── validate-feedback.ts
```
