## AI SaaS Tutorial - Appendix A (1 of 4): Config, Schema & Core Lib

This appendix consolidates every file from the series into one reference, organized by area, validated for Next.js 16. This part covers project config, the Prisma schema, and core `lib/` utilities (DB, workspace, RAG helpers). See parts 2–4 of this appendix for auth/routes, upload/RAG pipeline, and chat/billing/UI files respectively.

*Dynamic params column note: files in this part (`db.ts`, `workspace.ts`, `limits.ts`, `usage.ts`) do not receive route params directly, so the Promise-based params pattern does not apply to them. `workspace.ts` does use Clerk's async `auth()` (Next.js 16 requirement).*

### package.json (key dependencies installed across the series)
```json
{
  "dependencies": {
    "next": "16.x",
    "react": "19.x",
    "react-dom": "19.x",
    "@clerk/nextjs": "latest",
    "@prisma/client": "latest",
    "prisma": "latest",
    "ai": "latest",
    "@ai-sdk/openai-compatible": "latest",
    "@ai-sdk/react": "latest",
    "zod": "latest",
    "uploadthing": "latest",
    "@uploadthing/react": "latest",
    "stripe": "latest",
    "svix": "latest",
    "pdf-parse": "latest",
    "tailwindcss": "latest"
  }
}
```
Node.js requirement: 20.9+ or 22 LTS (verified in Part 1 Step 0). Tailwind is v4 (CSS-first config, no `tailwind.config.js` — see globals.css in Part 1).

### prisma/schema.prisma (Part 2)
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id          String       @id @default(cuid())
  clerkId     String       @unique
  email       String       @unique
  name        String?
  createdAt   DateTime     @default(now())
  memberships Membership[]
  messages    Message[]
}

model Workspace {
  id            String         @id @default(cuid())
  clerkOrgId    String         @unique
  name          String
  createdAt     DateTime       @default(now())
  memberships   Membership[]
  documents     Document[]
  messages      Message[]
  subscription  Subscription?
}

model Membership {
  id          String    @id @default(cuid())
  role        Role      @default(MEMBER)
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId      String
  workspace   Workspace @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  workspaceId String
  createdAt   DateTime  @default(now())

  @@unique([userId, workspaceId])
}

enum Role {
  OWNER
  ADMIN
  MEMBER
}

model Document {
  id          String     @id @default(cuid())
  workspace   Workspace  @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  workspaceId String
  name        String
  fileUrl     String
  status      DocStatus  @default(PROCESSING)
  createdAt   DateTime   @default(now())
  chunks      Chunk[]
}

enum DocStatus {
  PROCESSING
  READY
  FAILED
}

model Chunk {
  id         String                     @id @default(cuid())
  document   Document                   @relation(fields: [documentId], references: [id], onDelete: Cascade)
  documentId String
  content    String
  embedding  Unsupported("vector(768)")?
  createdAt  DateTime                   @default(now())

  @@index([documentId])
}

model Message {
  id          String    @id @default(cuid())
  workspace   Workspace @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  workspaceId String
  user        User?     @relation(fields: [userId], references: [id], onDelete: SetNull)
  userId      String?
  role        MsgRole
  content     String
  createdAt   DateTime  @default(now())

  @@index([workspaceId])
}

enum MsgRole {
  USER
  ASSISTANT
}

model Subscription {
  id                   String    @id @default(cuid())
  workspace            Workspace @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  workspaceId          String    @unique
  stripeCustomerId     String?   @unique
  stripeSubscriptionId String?   @unique
  plan                 Plan      @default(FREE)
  status               String    @default("active")
  currentPeriodEnd     DateTime?
}

enum Plan {
  FREE
  PRO
}
```
Plus two raw-SQL migration additions (Part 2): the `embedding vector(768)` column and the `ivfflat` cosine similarity index, and `CREATE EXTENSION IF NOT EXISTS vector;` / `pgcrypto` run in the Neon SQL editor.

### src/lib/db.ts (Part 2)
```ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const db = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = db;
```

### src/lib/workspace.ts (Part 4) — uses Clerk's async `auth()`, a Next.js 16 requirement
```ts
import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";

export async function getCurrentWorkspaceAndRole() {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) return null;

  const user = await db.user.findUnique({ where: { clerkId: userId } });
  const workspace = await db.workspace.findUnique({ where: { clerkOrgId: orgId } });
  if (!user || !workspace) return null;

  const membership = await db.membership.findUnique({
    where: { userId_workspaceId: { userId: user.id, workspaceId: workspace.id } },
  });
  if (!membership) return null;

  return { user, workspace, role: membership.role };
}

export function canManageWorkspace(role: "OWNER" | "ADMIN" | "MEMBER") {
  return role === "OWNER" || role === "ADMIN";
}
```

### src/lib/billing/limits.ts (Part 13)
```ts
export const PLAN_LIMITS = {
  FREE: { maxDocuments: 3, maxMessagesPerMonth: 20 },
  PRO: { maxDocuments: 100, maxMessagesPerMonth: 2000 },
} as const;

export type PlanName = keyof typeof PLAN_LIMITS;
```

### src/lib/billing/usage.ts (Part 13)
```ts
import { db } from "@/lib/db";
import { PLAN_LIMITS, type PlanName } from "./limits";

export async function getWorkspacePlan(workspaceId: string): Promise<PlanName> {
  const subscription = await db.subscription.findUnique({ where: { workspaceId } });
  return (subscription?.plan as PlanName) ?? "FREE";
}

export async function getDocumentCount(workspaceId: string) {
  return db.document.count({ where: { workspaceId } });
}

export async function getMessageCountThisMonth(workspaceId: string) {
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);
  return db.message.count({
    where: { workspaceId, role: "USER", createdAt: { gte: startOfMonth } },
  });
}

export async function checkCanUploadDocument(workspaceId: string) {
  const plan = await getWorkspacePlan(workspaceId);
  const count = await getDocumentCount(workspaceId);
  const limit = PLAN_LIMITS[plan].maxDocuments;
  return { allowed: count < limit, count, limit, plan };
}

export async function checkCanSendMessage(workspaceId: string) {
  const plan = await getWorkspacePlan(workspaceId);
  const count = await getMessageCountThisMonth(workspaceId);
  const limit = PLAN_LIMITS[plan].maxMessagesPerMonth;
  return { allowed: count < limit, count, limit, plan };
}
```

## AI SaaS Tutorial - Appendix A (2 of 4): Auth, Middleware & Webhooks

*Next.js 16 API usage in this part: both webhook route handlers (Clerk and Stripe) use the async `headers()` API and must await it. `middleware.ts` uses Clerk's async `clerkMiddleware` handler signature. No dynamic `[param]` routes appear in this part.*

### src/app/layout.tsx (Part 3)
```tsx
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### src/middleware.ts (Part 3)
```ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher([
  "/",
  "/sign-in(.*)",
  "/sign-up(.*)",
  "/api/webhooks(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (!isPublicRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: ["/((?!_next|.*\\..*).*)", "/(api|trpc)(.*)"],
};
```

### src/app/sign-in/[[...sign-in]]/page.tsx (Part 3)
```tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignIn />
    </div>
  );
}
```

### src/app/sign-up/[[...sign-up]]/page.tsx (Part 3)
```tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignUp />
    </div>
  );
}
```

### src/app/api/webhooks/clerk/route.ts (Part 3) — awaits `headers()` per Next.js 16
```ts
import { headers } from "next/headers";
import { Webhook } from "svix";
import { db } from "@/lib/db";

export async function POST(req: Request) {
  const secret = process.env.CLERK_WEBHOOK_SIGNING_SECRET!;
  const headerPayload = await headers();
  const svixId = headerPayload.get("svix-id");
  const svixTimestamp = headerPayload.get("svix-timestamp");
  const svixSignature = headerPayload.get("svix-signature");

  if (!svixId || !svixTimestamp || !svixSignature) {
    return new Response("Missing svix headers", { status: 400 });
  }

  const body = await req.text();
  const wh = new Webhook(secret);
  let evt: any;
  try {
    evt = wh.verify(body, {
      "svix-id": svixId,
      "svix-timestamp": svixTimestamp,
      "svix-signature": svixSignature,
    });
  } catch {
    return new Response("Invalid signature", { status: 400 });
  }

  const { type, data } = evt;

  if (type === "user.created" || type === "user.updated") {
    await db.user.upsert({
      where: { clerkId: data.id },
      update: {
        email: data.email_addresses?.[0]?.email_address ?? "",
        name: `${data.first_name ?? ""} ${data.last_name ?? ""}`.trim(),
      },
      create: {
        clerkId: data.id,
        email: data.email_addresses?.[0]?.email_address ?? "",
        name: `${data.first_name ?? ""} ${data.last_name ?? ""}`.trim(),
      },
    });
  }

  if (type === "organization.created" || type === "organization.updated") {
    await db.workspace.upsert({
      where: { clerkOrgId: data.id },
      update: { name: data.name },
      create: { clerkOrgId: data.id, name: data.name },
    });
  }

  if (type === "organizationMembership.created" || type === "organizationMembership.updated") {
    const user = await db.user.findUnique({ where: { clerkId: data.public_user_data.user_id } });
    const workspace = await db.workspace.findUnique({ where: { clerkOrgId: data.organization.id } });
    if (user && workspace) {
      const role = data.role === "org:admin" ? "OWNER" : "MEMBER";
      await db.membership.upsert({
        where: { userId_workspaceId: { userId: user.id, workspaceId: workspace.id } },
        update: { role },
        create: { userId: user.id, workspaceId: workspace.id, role },
      });
    }
  }

  return new Response("ok", { status: 200 });
}
```

### src/app/api/webhooks/stripe/route.ts (Part 12) — awaits `headers()` per Next.js 16
```ts
import { headers } from "next/headers";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";

export async function POST(req: Request) {
  const body = await req.text();
  const signature = (await headers()).get("stripe-signature")!;

  let event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    return new Response("Invalid signature", { status: 400 });
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as any;
      const workspaceId = session.metadata.workspaceId;
      const subscription = await stripe.subscriptions.retrieve(session.subscription);
      await db.subscription.update({
        where: { workspaceId },
        data: {
          stripeSubscriptionId: subscription.id,
          plan: "PRO",
          status: subscription.status,
          currentPeriodEnd: new Date(subscription.current_period_end * 1000),
        },
      });
      break;
    }
    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const sub = event.data.object as any;
      const existing = await db.subscription.findUnique({
        where: { stripeSubscriptionId: sub.id },
      });
      if (existing) {
        await db.subscription.update({
          where: { id: existing.id },
          data: {
            plan: sub.status === "active" ? "PRO" : "FREE",
            status: sub.status,
            currentPeriodEnd: new Date(sub.current_period_end * 1000),
          },
        });
      }
      break;
    }
  }

  return new Response("ok", { status: 200 });
}
```

### src/lib/stripe.ts (Part 12)
```ts
import Stripe from "stripe";

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2025-01-27.acacia",
});
```

### src/app/(dashboard)/layout.tsx (Part 4)
```tsx
import { OrganizationSwitcher, UserButton } from "@clerk/nextjs";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="flex items-center justify-between border-b bg-white px-6 py-3">
        <span className="font-bold">Acme Docs AI</span>
        <div className="flex items-center gap-4">
          <OrganizationSwitcher
            afterCreateOrganizationUrl="/workspaces"
            afterSelectOrganizationUrl="/workspaces"
            hidePersonal
          />
          <UserButton afterSignOutUrl="/" />
        </div>
      </nav>
      <main className="mx-auto max-w-5xl px-6 py-8">{children}</main>
    </div>
  );
}
```

## AI SaaS Tutorial - Appendix A (3 of 4): Upload & RAG Pipeline

*Next.js 16 API usage in this part: none of these files use dynamic route params or async headers/cookies APIs — the UploadThing core middleware calls `getCurrentWorkspaceAndRole()` which internally awaits Clerk's `auth()`, but that's encapsulated in `workspace.ts` (Appendix A 1 of 4). All other files here are plain library/DB/route code, confirmed compatible with Next.js 16 as-is.*

### src/app/api/uploadthing/core.ts (Parts 5 & 13)
```ts
import { createUploadthing, type FileRouter } from "uploadthing/next";
import { getCurrentWorkspaceAndRole } from "@/lib/workspace";
import { checkCanUploadDocument } from "@/lib/billing/usage";
import { db } from "@/lib/db";

const f = createUploadthing();

export const ourFileRouter = {
  documentUploader: f({
    pdf: { maxFileSize: "16MB", maxFileCount: 5 },
    text: { maxFileSize: "4MB", maxFileCount: 5 },
  })
    .middleware(async () => {
      const ctx = await getCurrentWorkspaceAndRole();
      if (!ctx) throw new Error("Unauthorized");

      const { allowed, count, limit } = await checkCanUploadDocument(ctx.workspace.id);
      if (!allowed) {
        throw new Error(
          `Document limit reached (${count}/${limit}) for your plan. Upgrade to Pro for more.`
        );
      }

      return { workspaceId: ctx.workspace.id };
    })
    .onUploadComplete(async ({ metadata, file }) => {
      const doc = await db.document.create({
        data: {
          workspaceId: metadata.workspaceId,
          name: file.name,
          fileUrl: file.url,
          status: "PROCESSING",
        },
      });

      fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/documents/process`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ documentId: doc.id }),
      }).catch(() => {});

      return { documentId: doc.id };
    }),
} satisfies FileRouter;

export type OurFileRouter = typeof ourFileRouter;
```

### src/app/api/uploadthing/route.ts (Part 5)
```ts
import { createRouteHandler } from "uploadthing/next";
import { ourFileRouter } from "./core";

export const { GET, POST } = createRouteHandler({ router: ourFileRouter });
```

### src/lib/uploadthing.ts (Part 5)
```ts
import { generateUploadButton, generateUploadDropzone } from "@uploadthing/react";
import type { OurFileRouter } from "@/app/api/uploadthing/core";

export const UploadButton = generateUploadButton<OurFileRouter>();
export const UploadDropzone = generateUploadDropzone<OurFileRouter>();
```

### src/lib/rag/extract.ts (Part 6)
```ts
import pdfParse from "pdf-parse";

export async function extractText(fileUrl: string, fileName: string): Promise<string> {
  const res = await fetch(fileUrl);
  const buffer = Buffer.from(await res.arrayBuffer());

  if (fileName.toLowerCase().endsWith(".pdf")) {
    const parsed = await pdfParse(buffer);
    return parsed.text;
  }

  return buffer.toString("utf-8");
}
```

### src/lib/rag/chunk.ts (Part 6)
```ts
interface ChunkOptions {
  chunkSize?: number;
  overlap?: number;
}

export function chunkText(text: string, options: ChunkOptions = {}): string[] {
  const { chunkSize = 1000, overlap = 150 } = options;
  const cleaned = text.replace(/\s+/g, " ").trim();
  if (!cleaned) return [];

  const chunks: string[] = [];
  let start = 0;

  while (start < cleaned.length) {
    const end = Math.min(start + chunkSize, cleaned.length);
    chunks.push(cleaned.slice(start, end));
    if (end === cleaned.length) break;
    start = end - overlap;
  }

  return chunks;
}
```

### src/app/api/documents/process/route.ts (Part 6)
```ts
import { db } from "@/lib/db";
import { extractText } from "@/lib/rag/extract";
import { chunkText } from "@/lib/rag/chunk";
import { embedAndStoreChunks } from "@/lib/rag/embed";

export async function POST(req: Request) {
  const { documentId } = await req.json();

  const document = await db.document.findUnique({ where: { id: documentId } });
  if (!document) {
    return new Response("Document not found", { status: 404 });
  }

  try {
    const text = await extractText(document.fileUrl, document.name);
    const chunks = chunkText(text);

    if (chunks.length === 0) {
      await db.document.update({ where: { id: documentId }, data: { status: "FAILED" } });
      return new Response("No extractable text", { status: 200 });
    }

    await embedAndStoreChunks(documentId, chunks);
    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error("Document processing failed", err);
    await db.document.update({ where: { id: documentId }, data: { status: "FAILED" } });
    return new Response("Processing failed", { status: 500 });
  }
}
```

### src/lib/rag/embed-query.ts (Part 8)
```ts
export async function getEmbeddingForQuery(text: string): Promise<number[]> {
  const baseUrl = process.env.EMBEDDING_BASE_URL!;
  const apiKey = process.env.EMBEDDING_API_KEY!;
  const model = process.env.EMBEDDING_MODEL!;

  const res = await fetch(`${baseUrl}/embeddings`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ model, input: text }),
  });

  if (!res.ok) {
    throw new Error(`Embedding request failed: ${res.status} ${await res.text()}`);
  }

  const json = await res.json();
  return json.data[0].embedding;
}
```

### src/lib/rag/embed.ts (Part 7 — uses the shared query embedder)
```ts
import { db } from "@/lib/db";
import { getEmbeddingForQuery as getEmbedding } from "./embed-query";

export async function embedAndStoreChunks(documentId: string, chunks: string[]) {
  for (const content of chunks) {
    const embedding = await getEmbedding(content);
    const vectorLiteral = `[${embedding.join(",")}]`;

    await db.$executeRawUnsafe(
      `INSERT INTO "Chunk" (id, "documentId", content, embedding, "createdAt")
       VALUES (gen_random_uuid()::text, $1, $2, $3::vector, now())`,
      documentId,
      content,
      vectorLiteral
    );
  }

  await db.document.update({ where: { id: documentId }, data: { status: "READY" } });
}
```

### src/lib/rag/retrieve.ts (Part 8)
```ts
import { db } from "@/lib/db";
import { getEmbeddingForQuery } from "./embed-query";

interface RetrievedChunk {
  id: string;
  content: string;
  documentId: string;
  documentName: string;
  similarity: number;
}

export async function retrieveRelevantChunks(
  workspaceId: string,
  question: string,
  topK = 5,
  minSimilarity = 0.65
): Promise<RetrievedChunk[]> {
  const queryEmbedding = await getEmbeddingForQuery(question);
  const vectorLiteral = `[${queryEmbedding.join(",")}]`;

  const results = await db.$queryRawUnsafe<RetrievedChunk[]>(
    `
    SELECT
      c.id,
      c.content,
      c."documentId",
      d.name AS "documentName",
      1 - (c.embedding <=> $1::vector) AS similarity
    FROM "Chunk" c
    JOIN "Document" d ON d.id = c."documentId"
    WHERE d."workspaceId" = $2
      AND d.status = 'READY'
    ORDER BY c.embedding <=> $1::vector
    LIMIT $3
    `,
    vectorLiteral,
    workspaceId,
    topK
  );

  return results.filter((r) => r.similarity >= minSimilarity);
}
```

## AI SaaS Tutorial - Appendix A (4 of 4): Chat UI and AI Provider Registry

*Next.js 16 note: `/api/chat/route.ts` uses plain Request/Response with no dynamic params — no version-specific concerns. The model registry and provider factory are plain TypeScript, unaffected by Next.js version.*

### src/lib/ai/models.ts (Part 11)
```ts
export interface FreeModel {
  id: string;
  label: string;
  provider: "groq" | "openrouter" | "ollama";
  modelName: string;
  baseUrl: string;
  requiresApiKey: boolean;
}

export const FREE_MODELS: FreeModel[] = [
  {
    id: "groq-llama-3.1-8b",
    label: "Llama 3.1 8B (Groq, free tier, fast)",
    provider: "groq",
    modelName: "llama-3.1-8b-instant",
    baseUrl: "https://api.groq.com/openai/v1",
    requiresApiKey: true,
  },
  {
    id: "groq-llama-3.3-70b",
    label: "Llama 3.3 70B (Groq, free tier, stronger)",
    provider: "groq",
    modelName: "llama-3.3-70b-versatile",
    baseUrl: "https://api.groq.com/openai/v1",
    requiresApiKey: true,
  },
  {
    id: "openrouter-free-llama",
    label: "Llama 3.1 (OpenRouter, free tier)",
    provider: "openrouter",
    modelName: "meta-llama/llama-3.1-8b-instruct:free",
    baseUrl: "https://openrouter.ai/api/v1",
    requiresApiKey: true,
  },
  {
    id: "ollama-llama3.1",
    label: "Llama 3.1 8B (Ollama, local, no API key)",
    provider: "ollama",
    modelName: "llama3.1",
    baseUrl: "http://localhost:11434/v1",
    requiresApiKey: false,
  },
];

export function getFreeModel(id: string): FreeModel {
  const model = FREE_MODELS.find((m) => m.id === id);
  if (!model) throw new Error("Unknown model id: " + id);
  return model;
}

export const DEFAULT_MODEL_ID = "ollama-llama3.1";
```

### src/lib/ai/provider.ts (Part 11)
```ts
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import { getFreeModel } from "./models";

export function getModelInstance(modelId: string) {
  const model = getFreeModel(modelId);

  const apiKey =
    model.provider === "groq"
      ? process.env.GROQ_API_KEY
      : model.provider === "openrouter"
      ? process.env.OPENROUTER_API_KEY
      : "ollama";

  if (model.requiresApiKey && !apiKey) {
    throw new Error("Missing API key for provider: " + model.provider);
  }

  const client = createOpenAICompatible({
    name: model.provider,
    baseURL: model.baseUrl,
    apiKey: apiKey!,
  });

  return client(model.modelName);
}
```

### src/app/api/chat/route.ts (Parts 9, 10, 11, 13 combined — final version)
```ts
import { streamText, convertToModelMessages, type UIMessage } from "ai";
import { getModelInstance } from "@/lib/ai/provider";
import { DEFAULT_MODEL_ID } from "@/lib/ai/models";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve";
import { getCurrentWorkspaceAndRole } from "@/lib/workspace";
import { checkCanSendMessage } from "@/lib/billing/usage";
import { db } from "@/lib/db";

export async function POST(req: Request) {
  const { messages, workspaceId, modelId }: {
    messages: UIMessage[];
    workspaceId: string;
    modelId?: string;
  } = await req.json();

  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) {
    return new Response("Unauthorized", { status: 401 });
  }

  const usage = await checkCanSendMessage(workspaceId);
  if (!usage.allowed) {
    return new Response(
      JSON.stringify({
        error: "Message limit reached (" + usage.count + "/" + usage.limit + ") for your plan this month. Upgrade to Pro for more.",
      }),
      { status: 403, headers: { "Content-Type": "application/json" } }
    );
  }

  const lastUserMessage = messages[messages.length - 1];
  const question = lastUserMessage.parts
    .filter((p) => p.type === "text")
    .map((p) => p.text)
    .join(" ");

  await db.message.create({
    data: { workspaceId, userId: ctx.user.id, role: "USER", content: question },
  });

  const relevantChunks = await retrieveRelevantChunks(workspaceId, question);

  const contextBlock = relevantChunks.length
    ? relevantChunks
        .map((c, i) => "[Source " + (i + 1) + ": " + c.documentName + "]\n" + c.content)
        .join("\n\n")
    : "No relevant document content was found for this question.";

  const systemPrompt = "You are a helpful assistant that answers questions using ONLY the document excerpts provided below. If the excerpts do not contain the answer, say you do not know based on the uploaded documents - do not make things up.\n\nDOCUMENT EXCERPTS:\n" + contextBlock;

  const result = streamText({
    model: getModelInstance(modelId ?? DEFAULT_MODEL_ID),
    system: systemPrompt,
    messages: convertToModelMessages(messages),
    onFinish: async ({ text }) => {
      await db.message.create({
        data: { workspaceId, role: "ASSISTANT", content: text },
      });
    },
  });

  return result.toUIMessageStreamResponse();
}
```

## AI SaaS Tutorial - Appendix A (4b of 4): Chat Component, Billing Actions and Pages

*Next.js 16 dynamic params summary for this appendix's page files: every `[workspaceId]` page (workspace home, documents, chat, billing) uses the Promise-based params pattern: `{ params }: { params: Promise<{ workspaceId: string }> }` then `const { workspaceId } = await params;`. Server Actions (`billing/actions.ts`) take `workspaceId` as a plain function argument (bound via `.bind(null, workspaceId)` in the calling page), so they are not affected by the params Promise change directly — only the page that reads params and passes it down is.*

### src/app/(dashboard)/workspaces/[workspaceId]/chat/chat-ui.tsx (Parts 9, 10, 11, 13 combined)
```tsx
"use client";

import { useChat } from "@ai-sdk/react";
import { useState } from "react";
import { FREE_MODELS, DEFAULT_MODEL_ID } from "@/lib/ai/models";

export function ChatUI({
  workspaceId,
  initialMessages = [],
}: {
  workspaceId: string;
  initialMessages?: any[];
}) {
  const [input, setInput] = useState("");
  const [modelId, setModelId] = useState(DEFAULT_MODEL_ID);
  const { messages, sendMessage, status, error } = useChat({ messages: initialMessages });

  return (
    <div className="flex h-[70vh] flex-col rounded-lg border bg-white">
      <div className="border-b p-2">
        <select
          value={modelId}
          onChange={(e) => setModelId(e.target.value)}
          className="rounded border px-2 py-1 text-sm"
        >
          {FREE_MODELS.map((m) => (
            <option key={m.id} value={m.id}>
              {m.label}
            </option>
          ))}
        </select>
      </div>

      <div className="flex-1 space-y-4 overflow-y-auto p-4">
        {messages.length === 0 && (
          <p className="text-center text-gray-400">Ask a question about your uploaded documents.</p>
        )}
        {messages.map((m) => (
          <div key={m.id} className={m.role === "user" ? "text-right" : "text-left"}>
            <div
              className={
                "inline-block max-w-[80%] rounded-lg px-4 py-2 " +
                (m.role === "user" ? "bg-blue-600 text-white" : "bg-gray-100 text-gray-900")
              }
            >
              {m.parts.map((part, i) =>
                part.type === "text" ? <span key={i}>{part.text}</span> : null
              )}
            </div>
          </div>
        ))}
        {status === "streaming" && <p className="text-sm text-gray-400">Thinking...</p>}
      </div>

      {error && (
        <p className="border-t bg-red-50 p-3 text-sm text-red-700">{error.message}</p>
      )}

      <form
        onSubmit={(e) => {
          e.preventDefault();
          if (!input.trim()) return;
          sendMessage({ text: input }, { body: { workspaceId, modelId } });
          setInput("");
        }}
        className="flex gap-2 border-t p-4"
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask about your documents..."
          className="flex-1 rounded border px-3 py-2"
        />
        <button
          type="submit"
          disabled={status === "streaming"}
          className="rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-50"
        >
          Send
        </button>
      </form>
    </div>
  );
}
```

### src/app/(dashboard)/workspaces/[workspaceId]/billing/actions.ts (Part 12)
```ts
"use server";

import { redirect } from "next/navigation";
import { stripe } from "@/lib/stripe";
import { getCurrentWorkspaceAndRole, canManageWorkspace } from "@/lib/workspace";
import { db } from "@/lib/db";

export async function createCheckoutSession(workspaceId: string) {
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) throw new Error("Not authorized");
  if (!canManageWorkspace(ctx.role)) throw new Error("Only owners/admins can manage billing");

  let subscription = await db.subscription.findUnique({ where: { workspaceId } });
  let customerId = subscription?.stripeCustomerId;

  if (!customerId) {
    const customer = await stripe.customers.create({
      email: ctx.user.email,
      metadata: { workspaceId },
    });
    customerId = customer.id;
    subscription = await db.subscription.upsert({
      where: { workspaceId },
      update: { stripeCustomerId: customerId },
      create: { workspaceId, stripeCustomerId: customerId, plan: "FREE" },
    });
  }

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    line_items: [{ price: process.env.STRIPE_PRO_PRICE_ID!, quantity: 1 }],
    success_url: process.env.NEXT_PUBLIC_APP_URL + "/workspaces/" + workspaceId + "/billing?success=1",
    cancel_url: process.env.NEXT_PUBLIC_APP_URL + "/workspaces/" + workspaceId + "/billing?canceled=1",
    metadata: { workspaceId },
  });

  redirect(session.url!);
}

export async function createBillingPortalSession(workspaceId: string) {
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) throw new Error("Not authorized");
  if (!canManageWorkspace(ctx.role)) throw new Error("Only owners/admins can manage billing");

  const subscription = await db.subscription.findUnique({ where: { workspaceId } });
  if (!subscription?.stripeCustomerId) throw new Error("No billing account yet");

  const session = await stripe.billingPortal.sessions.create({
    customer: subscription.stripeCustomerId,
    return_url: process.env.NEXT_PUBLIC_APP_URL + "/workspaces/" + workspaceId + "/billing",
  });

  redirect(session.url);
}
```

### Page files summary (full code already shown in their respective Parts — listed here for reference)

All of these use the Next.js 16 Promise-based params pattern: `{ params }: { params: Promise<{ workspaceId: string }> }` then `const { workspaceId } = await params;`

- `src/app/(dashboard)/workspaces/page.tsx` — Part 4 (no params — reads workspace from `auth()` context only)
- `src/app/(dashboard)/workspaces/[workspaceId]/page.tsx` — Parts 4 and 13 (workspace home + usage widget) — uses `await params`
- `src/app/(dashboard)/workspaces/[workspaceId]/documents/page.tsx` — Parts 5 and 14 (documents list + empty state) — uses `await params`
- `src/app/(dashboard)/workspaces/[workspaceId]/documents/uploader.tsx` — Parts 5 and 14 (client component, no params)
- `src/app/(dashboard)/workspaces/[workspaceId]/chat/page.tsx` — Parts 9, 10, 14 (chat page + history + warnings) — uses `await params`
- `src/app/(dashboard)/workspaces/[workspaceId]/billing/page.tsx` — Part 12 — uses `await params`
- `src/app/(dashboard)/workspaces/[workspaceId]/loading.tsx` and `error.tsx` — Part 14 (no params)
- `src/app/not-found.tsx` — Part 14 (no params)

Refer back to the numbered Part note for the exact, complete code of each page — they are not duplicated again here to avoid drift between copies. This appendix's purpose is to give you the "core building block" files (schema, lib, API routes, chat/AI/billing logic) in one place; page-level UI composition is thin and best read directly from its originating Part.

This completes **Appendix A**, fully validated for Next.js 16.

