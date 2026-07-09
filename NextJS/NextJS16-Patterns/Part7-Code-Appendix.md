# Part 7 Code Appendix — Full Snippets

Companion code for **Part 7: Auth and Authorization Patterns**.

---

## `lib/auth/types.ts`

```ts
export type Role = "member" | "admin" | "owner";

export interface AuthUser {
  id: string;
  orgId: string;
  email: string;
  role: Role;
}
```

## `lib/auth/session.ts` (request-scoped session accessor, Facade over your provider)

```ts
import "server-only";
import { cache } from "react";
import { cookies } from "next/headers";
import { verifySessionToken } from "./token"; // your provider-specific verification
import type { AuthUser } from "./types";

export const getCurrentUser = cache(async (): Promise<AuthUser | null> => {
  const cookieStore = await cookies();
  const token = cookieStore.get("session")?.value;
  if (!token) return null;

  try {
    const payload = await verifySessionToken(token);
    return {
      id: payload.sub,
      orgId: payload.orgId,
      email: payload.email,
      role: payload.role,
    };
  } catch {
    return null;
  }
});

// Throws-if-missing helper: narrows AuthUser | null to AuthUser for callers.
export async function requireUser(): Promise<AuthUser> {
  const user = await getCurrentUser();
  if (!user) {
    throw new Error("UNAUTHENTICATED");
  }
  return user;
}
```

---

## `lib/authz/types.ts`

```ts
export type AuthzResult =
  | { allowed: true }
  | { allowed: false; reason: string };
```

## `lib/authz/policies.ts` (pure, testable policy functions)

```ts
import type { AuthUser } from "@/lib/auth/types";
import type { AuthzResult } from "./types";
import type { Project } from "@/lib/repositories/types";

export function canArchiveProject(user: AuthUser, project: Project): AuthzResult {
  if (project.orgId !== user.orgId) {
    return { allowed: false, reason: "Project belongs to a different organization." };
  }

  if (user.role === "member") {
    return { allowed: false, reason: "Members cannot archive projects." };
  }

  return { allowed: true };
}

export function canManageBilling(user: AuthUser): AuthzResult {
  if (user.role !== "owner") {
    return { allowed: false, reason: "Only the organization owner can manage billing." };
  }
  return { allowed: true };
}
```

---

## Usage — Server Action composing session + policy + repository (Parts 1, 2, 4, 6 tie-in)

```ts
// lib/actions/project-actions.ts
"use server";

import { revalidateTag } from "next/cache";
import { requireUser } from "@/lib/auth/session";
import { canArchiveProject } from "@/lib/authz/policies";
import { projectRepository } from "@/lib/repositories/project-repository";
import { withLogging } from "@/lib/observability/with-logging";
import { db } from "@/lib/db";
import type { ActionResult } from "./types";
import type { Project } from "@/lib/repositories/types";

async function archiveProjectImpl(id: string): Promise<ActionResult<Project>> {
  const user = await requireUser(); // throws UNAUTHENTICATED if no session

  const project = await projectRepository.getById(id);
  if (!project) {
    return { success: false, error: "Project not found." };
  }

  const decision = canArchiveProject(user, project);
  if (!decision.allowed) {
    return { success: false, error: decision.reason };
  }

  const updated = await db.project.update({
    where: { id },
    data: { status: "archived" },
  });

  revalidateTag("projects");
  revalidateTag(`project:${id}`);

  return { success: true, data: updated };
}

export const archiveProject = withLogging("archiveProject", archiveProjectImpl);
```

---

## Middleware — coarse-grained "is there a session" check (Part 7 2c)

```ts
// middleware.ts
import { NextResponse, type NextRequest } from "next/server";

const PROTECTED_PREFIXES = ["/dashboard"];

export function middleware(request: NextRequest) {
  const isProtected = PROTECTED_PREFIXES.some((prefix) =>
    request.nextUrl.pathname.startsWith(prefix)
  );

  if (!isProtected) return NextResponse.next();

  const hasSession = request.cookies.has("session");
  if (!hasSession) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirectTo", request.nextUrl.pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*"],
};
```

Note: this only confirms a session cookie exists — it cannot check "does this user own project X," because middleware runs before the route's dynamic segments are resolved into application logic. Fine-grained checks stay in the Server Action/repository layer above.

---

## Multi-tenant repository — `orgId` sourced from session, never from client input (Part 7 2d)

```ts
// lib/repositories/project-repository.ts
import "server-only";
import { logger } from "@/lib/observability/logger";
import type { Project, ProjectRepository } from "./types";

interface GetAllParams {
  orgId: string; // must come from getCurrentUser(), never req.query/body
  status?: "all" | "active" | "archived" | "draft";
}

class HttpProjectRepository implements ProjectRepository {
  async getAll({ orgId, status = "all" }: GetAllParams): Promise<Project[]> {
    const res = await fetch(
      `${process.env.API_BASE_URL}/orgs/${orgId}/projects?status=${status}`,
      { next: { revalidate: 60, tags: ["projects", `org:${orgId}:projects`] } }
    );

    if (!res.ok) {
      logger.error("project.listFetchFailed", { orgId, status: res.status });
      throw new Error(`Failed to load projects for org ${orgId}: ${res.status}`);
    }

    return res.json();
  }

  async getById(id: string): Promise<Project | null> {
    const res = await fetch(`${process.env.API_BASE_URL}/projects/${id}`, {
      next: { tags: ["projects", `project:${id}`] },
    });

    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`Failed to load project ${id}: ${res.status}`);
    return res.json();
  }
}

export const projectRepository: ProjectRepository = new HttpProjectRepository();
```

```ts
// app/dashboard/projects/page.tsx — the org id is derived from the session, not the URL
import { requireUser } from "@/lib/auth/session";
import { projectRepository } from "@/lib/repositories/project-repository";

export default async function ProjectsPage() {
  const user = await requireUser();
  const projects = await projectRepository.getAll({ orgId: user.orgId });

  return (
    <ul>
      {projects.map((p) => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

---

## Unit-testing a policy function (Part 5 tie-in — pure function, no rendering/DB)

```ts
// lib/authz/policies.test.ts
import { describe, it, expect } from "vitest";
import { canArchiveProject } from "./policies";
import type { AuthUser } from "@/lib/auth/types";
import type { Project } from "@/lib/repositories/types";

const baseProject: Project = {
  id: "p1",
  name: "Acme Redesign",
  status: "active",
  updatedAt: new Date().toISOString(),
  orgId: "org_1",
} as Project;

describe("canArchiveProject", () => {
  it("denies members", () => {
    const member: AuthUser = { id: "u1", orgId: "org_1", email: "a@b.com", role: "member" };
    const result = canArchiveProject(member, baseProject);
    expect(result.allowed).toBe(false);
  });

  it("denies cross-org access", () => {
    const admin: AuthUser = { id: "u1", orgId: "org_2", email: "a@b.com", role: "admin" };
    const result = canArchiveProject(admin, baseProject);
    expect(result.allowed).toBe(false);
  });

  it("allows admins in the same org", () => {
    const admin: AuthUser = { id: "u1", orgId: "org_1", email: "a@b.com", role: "admin" };
    const result = canArchiveProject(admin, baseProject);
    expect(result.allowed).toBe(true);
  });
});
```

---

## Anti-pattern reference (for contrast, do not copy)

```tsx
// BAD — client-only check, no server-side re-verification, tenant id trusted from the client
"use client";

export function ArchiveButton({ project, currentUserRole, orgId }: {
  project: { id: string };
  currentUserRole: string;
  orgId: string; // passed in from client state — trivially spoofable
}) {
  if (currentUserRole !== "admin") return null; // hides button, does NOT stop the API call

  async function handleClick() {
    // No server-side re-check of role or orgId ownership before this mutates data.
    await fetch(`/api/projects/${project.id}/archive?orgId=${orgId}`, { method: "POST" });
  }

  return <button onClick={handleClick}>Archive</button>;
}
```
