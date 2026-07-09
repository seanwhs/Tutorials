# Part 5 Code Appendix — Full Snippets

Companion code for **EntNext16 - Part 5: Testing Strategy**. Uses Vitest + React Testing Library + Playwright.

---

## Setup

```
npm i -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/user-event @playwright/test
```

```ts
// vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
  },
});
```

---

## 1. Fake Repository (test double implementing the real interface)

```ts
// lib/repositories/project-repository.fake.ts
import type { Project, ProjectRepository } from "./types";

export class FakeProjectRepository implements ProjectRepository {
  constructor(private projects: Project[] = []) {}

  async getAll(): Promise<Project[]> {
    return this.projects;
  }

  async getById(id: string): Promise<Project | null> {
    return this.projects.find((p) => p.id === id) ?? null;
  }

  // Test helper, not part of the interface.
  seed(project: Project) {
    this.projects.push(project);
  }
}
```

```ts
// lib/repositories/project-repository.test.ts
import { describe, it, expect } from "vitest";
import { FakeProjectRepository } from "./project-repository.fake";

describe("FakeProjectRepository", () => {
  it("returns null for an unknown id", async () => {
    const repo = new FakeProjectRepository();
    const result = await repo.getById("missing-id");
    expect(result).toBeNull();
  });

  it("returns a seeded project by id", async () => {
    const repo = new FakeProjectRepository();
    repo.seed({
      id: "p1",
      name: "Acme Redesign",
      status: "active",
      updatedAt: new Date().toISOString(),
    });

    const result = await repo.getById("p1");
    expect(result?.name).toBe("Acme Redesign");
  });
});
```

---

## 2. Unit-testing a Server Action (Part 2)

```ts
// lib/actions/project-actions.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("next/cache", () => ({
  revalidateTag: vi.fn(),
}));

vi.mock("@/lib/db", () => ({
  db: {
    project: {
      update: vi.fn(),
    },
  },
}));

import { revalidateTag } from "next/cache";
import { db } from "@/lib/db";
import { archiveProject } from "./project-actions";

describe("archiveProject", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns a typed error for an invalid id", async () => {
    const result = await archiveProject("not-a-uuid");

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error).toBe("Invalid project id.");
    }
  });

  it("archives a valid project and revalidates both tags", async () => {
    const id = "123e4567-e89b-12d3-a456-426614174000";
    (db.project.update as ReturnType<typeof vi.fn>).mockResolvedValue({
      id,
      name: "Acme Redesign",
      status: "archived",
      updatedAt: new Date().toISOString(),
    });

    const result = await archiveProject(id);

    expect(result.success).toBe(true);
    expect(revalidateTag).toHaveBeenCalledWith("projects");
    expect(revalidateTag).toHaveBeenCalledWith(`project:${id}`);
  });
});
```

---

## 3. Integration-testing an async Server Component

```tsx
// components/project-stats.test.tsx
import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";

vi.mock("@/lib/repositories/project-repository", () => ({
  projectRepository: {
    getById: vi.fn().mockResolvedValue({
      id: "p1",
      name: "Acme Redesign",
      status: "active",
      updatedAt: "2026-01-01T00:00:00.000Z",
    }),
  },
}));

import { ProjectStats } from "./project-stats";

describe("ProjectStats (Server Component)", () => {
  it("renders resolved project data", async () => {
    // Await the async Server Component function directly — it's just a function.
    const element = await ProjectStats({ projectId: "p1" });
    render(element);

    expect(screen.getByText("active")).toBeInTheDocument();
  });
});
```

---

## 4. Testing Suspense fallback and error boundary (Part 4)

```tsx
// components/ui/error-boundary.test.tsx
import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { ErrorBoundary } from "./error-boundary";

function ThrowingWidget(): JSX.Element {
  throw new Error("Simulated widget failure");
}

describe("ErrorBoundary", () => {
  it("renders the fallback when a child throws", () => {
    const consoleSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    render(
      <ErrorBoundary fallback={<p>Related items unavailable.</p>}>
        <ThrowingWidget />
      </ErrorBoundary>
    );

    expect(screen.getByText("Related items unavailable.")).toBeInTheDocument();
    consoleSpy.mockRestore();
  });
});
```

```tsx
// components/ui/suspense-example.test.tsx
import { describe, it, expect } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { Suspense, use } from "react";

function SlowContent({ promise }: { promise: Promise<string> }) {
  const value = use(promise);
  return <p>{value}</p>;
}

describe("Suspense fallback behavior", () => {
  it("shows the fallback, then the resolved content", async () => {
    let resolvePromise!: (value: string) => void;
    const promise = new Promise<string>((resolve) => {
      resolvePromise = resolve;
    });

    render(
      <Suspense fallback={<p>Loading…</p>}>
        <SlowContent promise={promise} />
      </Suspense>
    );

    expect(screen.getByText("Loading…")).toBeInTheDocument();

    resolvePromise("Resolved content");

    await waitFor(() => {
      expect(screen.getByText("Resolved content")).toBeInTheDocument();
    });
  });
});
```

---

## 5. Unit-testing a Facade (Part 4) with a mocked SDK

```ts
// lib/facades/payments.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";

const mockCreate = vi.fn();

vi.mock("stripe", () => {
  return {
    default: vi.fn().mockImplementation(() => ({
      charges: { create: mockCreate },
    })),
  };
});

import { paymentsFacade } from "./payments";

describe("paymentsFacade.createCharge", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("normalizes a successful charge", async () => {
    mockCreate.mockResolvedValue({ id: "ch_123", status: "succeeded" });

    const result = await paymentsFacade.createCharge({
      amountCents: 1000,
      currency: "usd",
      customerId: "cus_123",
    });

    expect(result).toEqual({
      success: true,
      data: { id: "ch_123", status: "succeeded" },
    });
  });

  it("normalizes an SDK failure into a FacadeResult", async () => {
    mockCreate.mockRejectedValue(new Error("Card declined"));

    const result = await paymentsFacade.createCharge({
      amountCents: 1000,
      currency: "usd",
      customerId: "cus_123",
    });

    expect(result).toEqual({ success: false, error: "Card declined" });
  });
});
```

---

## 6. Playwright E2E — URL state survives refresh (Part 2)

```ts
// e2e/project-filters.spec.ts
import { test, expect } from "@playwright/test";

test("filter selection updates the URL and survives a refresh", async ({ page }) => {
  await page.goto("/dashboard/projects");

  await page.selectOption('select[name="status"]', "archived");
  await expect(page).toHaveURL(/status=archived/);

  await page.reload();

  await expect(page.locator('select[name="status"]')).toHaveValue("archived");
});
```

## 7. Playwright E2E — optimistic archive flow (Part 2)

```ts
// e2e/archive-project.spec.ts
import { test, expect } from "@playwright/test";

test("archiving a project updates instantly, then persists after reload", async ({ page }) => {
  await page.goto("/dashboard/projects");

  const row = page.getByRole("listitem").filter({ hasText: "Acme Redesign" });
  await row.getByRole("button", { name: "Archive" }).click();

  // Optimistic UI: status flips immediately, before network settles.
  await expect(row.getByText("archived")).toBeVisible();

  await page.reload();

  // Server-confirmed after revalidateTag("projects") on the real deployment.
  await expect(row.getByText("archived")).toBeVisible();
});
```

---

## Anti-pattern reference (for contrast, do not copy)

```tsx
// BAD — testing business logic only through full component render + fetch mocking
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import DashboardPage from "./page"; // old client-fetching version from Part 1's anti-pattern

test("loads and archives a project", async () => {
  global.fetch = vi.fn().mockResolvedValueOnce({
    ok: true,
    json: async () => [{ id: "p1", name: "Acme Redesign", status: "active" }],
  }) as unknown as typeof fetch;

  render(<DashboardPage />);

  await waitFor(() => screen.getByText("Acme Redesign"));
  fireEvent.click(screen.getByText("Archive"));
  // ...and so on — slow, brittle, and the archive logic itself is untestable
  // in isolation because it's welded to the click handler.
});
```
