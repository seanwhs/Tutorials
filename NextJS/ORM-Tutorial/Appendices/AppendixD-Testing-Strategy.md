# Appendix D: Testing Strategy for Both ORMs

## 1. Testing Pyramid for a Data Layer

| Layer | Tool | What it covers |
|---|---|---|
| Unit tests | Vitest | Validation schemas (Zod), pure helper functions |
| Integration tests | Vitest + a real test database | Actual ORM queries against Postgres (Prisma or Drizzle) |
| Server Action tests | Vitest, mocking `next/navigation` and `next/cache` | Action logic (validation → DB call → revalidate/redirect) |
| E2E tests | Playwright | Full user flows through the actual running app |

> **Never mock the ORM itself for integration tests.** Mocking `db.post.findMany` just tests that you called a mock correctly — it proves nothing about your actual SQL, constraints, or relations. Use a real (disposable) test database instead.

## 2. Test Database Setup (Shared by Both ORMs)

```bash
# Create a second, throwaway Neon branch/project dedicated to tests
# Neon's branching feature is ideal here: instant copy-on-write branch of your schema/data
```

```bash
# .env.test
DATABASE_URL="postgresql://user:pass@ep-test-pooler.neon.tech/orm_demo_test?sslmode=require"
DIRECT_URL="postgresql://user:pass@ep-test.neon.tech/orm_demo_test?sslmode=require"
```

```json
// package.json (add-on, either variant)
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "pretest": "dotenv -e .env.test -- npm run db:migrate"
  }
}
```

```bash
pnpm add -D vitest dotenv-cli
```

## 3. Prisma Integration Test Example

```ts
// src/lib/db.test.ts
import { describe, it, expect, beforeEach, afterAll } from "vitest";
import { PrismaClient } from "@/generated/prisma";

// Separate client instance pointed explicitly at the test DB,
// independent from the app's singleton in src/lib/db.ts
const db = new PrismaClient({
  datasources: { db: { url: process.env.DATABASE_URL } },
});

beforeEach(async () => {
  // Wipe tables between tests for isolation — order matters due to FKs
  await db.postTag.deleteMany();
  await db.post.deleteMany();
  await db.tag.deleteMany();
  await db.author.deleteMany();
});

afterAll(async () => {
  await db.$disconnect();
});

describe("Post model", () => {
  it("creates a post linked to an author", async () => {
    const author = await db.author.create({
      data: { name: "Test Author", email: "test@example.com" },
    });

    const post = await db.post.create({
      data: { title: "Test Post", content: "Hello", authorId: author.id },
    });

    expect(post.title).toBe("Test Post");
    expect(post.published).toBe(false); // verifies the schema default
  });

  it("cascades delete: removing an author deletes their posts", async () => {
    const author = await db.author.create({
      data: { name: "Cascade Test", email: "cascade@example.com" },
    });
    await db.post.create({
      data: { title: "Will be deleted", content: "...", authorId: author.id },
    });

    await db.author.delete({ where: { id: author.id } });

    const remaining = await db.post.findMany({ where: { authorId: author.id } });
    expect(remaining).toHaveLength(0); // proves onDelete: Cascade actually works at the DB level
  });
});
```

## 4. Drizzle Integration Test Example

```ts
// src/db/index.test.ts
import { describe, it, expect, beforeEach } from "vitest";
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import * as schema from "./schema";
import { authors, posts } from "./schema";
import { eq } from "drizzle-orm";

const sql = neon(process.env.DATABASE_URL!);
const db = drizzle(sql, { schema });

beforeEach(async () => {
  // Truncate is faster than sequential deletes and resets identity sequences
  await sql`TRUNCATE post_tags, posts, tags, authors CASCADE`;
});

describe("Post table", () => {
  it("creates a post linked to an author", async () => {
    const [author] = await db
      .insert(authors)
      .values({ name: "Test Author", email: "test@example.com" })
      .returning();

    const [post] = await db
      .insert(posts)
      .values({ title: "Test Post", content: "Hello", authorId: author.id })
      .returning();

    expect(post.title).toBe("Test Post");
    expect(post.published).toBe(false);
  });

  it("cascades delete: removing an author deletes their posts", async () => {
    const [author] = await db
      .insert(authors)
      .values({ name: "Cascade Test", email: "cascade@example.com" })
      .returning();

    await db.insert(posts).values({
      title: "Will be deleted",
      content: "...",
      authorId: author.id,
    });

    await db.delete(authors).where(eq(authors.id, author.id));

    const remaining = await db.query.posts.findMany({
      where: (p, { eq }) => eq(p.authorId, author.id),
    });
    expect(remaining).toHaveLength(0);
  });
});
```

## 5. Testing Server Actions (ORM-agnostic pattern)

```ts
// src/app/posts/actions.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";

// Mock Next.js APIs that Server Actions call but that don't exist
// outside a real request context
vi.mock("next/cache", () => ({ revalidatePath: vi.fn() }));
vi.mock("next/navigation", () => ({ redirect: vi.fn() }));

import { createPost } from "./actions";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

describe("createPost action", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns field errors for invalid input instead of throwing", async () => {
    const formData = new FormData();
    formData.set("title", "ab"); // too short, fails Zod's min(3)
    formData.set("content", "short");
    formData.set("authorId", "not-a-uuid");

    const result = await createPost({}, formData);

    expect(result.errors?.title).toBeDefined();
    expect(redirect).not.toHaveBeenCalled(); // should bail out before mutating
  });

  it("creates a valid post and revalidates + redirects", async () => {
    // Assumes a real author exists in the test DB (seed before this test,
    // or create one inline via the ORM client as shown in sections 3/4)
    const formData = new FormData();
    formData.set("title", "Valid Title");
    formData.set("content", "Valid content long enough");
    formData.set("authorId", "00000000-0000-0000-0000-000000000000");

    await createPost({}, formData);

    expect(revalidatePath).toHaveBeenCalledWith("/posts");
    expect(redirect).toHaveBeenCalledWith("/posts");
  });
});
```

## 6. E2E Test with Playwright (Ties It All Together)

```ts
// e2e/posts.spec.ts
import { test, expect } from "@playwright/test";

test("user can create, publish, and delete a post", async ({ page }) => {
  await page.goto("/posts/new");

  await page.fill('input[name="title"]', "E2E Test Post");
  await page.fill('textarea[name="content"]', "Content written by Playwright");
  await page.selectOption('select[name="authorId"]', { index: 0 });
  await page.click('button[type="submit"]');

  // Redirected back to the list, new post should be visible
  await expect(page.getByText("E2E Test Post")).toBeVisible();

  // Publish it via the inline form
  await page.getByText("Publish").first().click();
  await expect(page.getByText("Unpublish")).toBeVisible();

  // Delete it and confirm it's gone
  await page.getByText("Delete").first().click();
  await expect(page.getByText("E2E Test Post")).not.toBeVisible();
});
```

```bash
pnpm add -D @playwright/test
pnpm dlx playwright install
pnpm dlx playwright test
```

## 7. CI Considerations

| Concern | Recommendation |
|---|---|
| Test DB isolation | Use a dedicated Neon branch per CI run if possible (Neon supports ephemeral branches via API) |
| Migration before tests | Run `db:migrate` (Prisma: `migrate deploy`; Drizzle: `migrate` script) as a `pretest` step |
| Parallel test workers | Each worker should get its own schema/branch, or serialize DB-touching tests to avoid race conditions on shared tables |
| Secrets | Store `DATABASE_URL`/`DIRECT_URL` for the test DB as CI secrets, never commit them |

Continue to **Appendix E: Deployment Checklist**.
