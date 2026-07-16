# Appendix C: Code Segment Breakdown

This appendix walks through two of the most architecturally significant code segments built across the series: the Prisma transaction logic that guards progress writes, and the inner workings of `next/dynamic` that prevent plugin code from bloating every page's bundle.

## C.1 Deep Dive: The Prisma Transaction Logic

Here is the complete transaction block from the `completeLesson` Server Action, built across Part 4:

```typescript
try {
  await prisma.$transaction(async (tx) => {
    // 1. Assert registration status exists before saving progress
    const enrollment = await tx.enrollment.findUnique({
      where: {
        userId_courseId: { userId, courseId }
      }
    });

    if (!enrollment) {
      throw new Error('Transaction Failed: Student has not enrolled in the parent course.');
    }

    // 2. Upsert progress state safely
    await tx.progress.upsert({
      where: {
        userId_lessonId: { userId, lessonId }
      },
      update: {
        completed: true,
        completedAt: new Date(),
        score,
        moduleState: moduleState || {},
      },
      create: {
        userId,
        lessonId,
        completed: true,
        completedAt: new Date(),
        score,
        moduleState: moduleState || {},
      }
    });
  });

  revalidateTag(`progress-${courseId}`);
  return { success: true };

} catch (error: any) {
  console.error('CRITICAL: Database transaction rollback executed: ', error.message);
  return { success: false, error: 'Failed to write completed execution progress.' };
}
```

**Line-by-line breakdown:**

**`prisma.$transaction(async (tx) => { ... })`** — This wraps every database operation inside the callback into a single atomic unit. The `tx` parameter is a special transaction-scoped Prisma client — every query made through `tx` (not the regular `prisma` client) participates in the same all-or-nothing unit of work. Think of it like a sealed envelope: nothing inside gets delivered to the database until the entire envelope is ready to send, and if anything goes wrong while sealing it, the whole envelope is discarded instead of partially mailed.

**`tx.enrollment.findUnique({ where: { userId_courseId: { userId, courseId } } })`** — This queries the `Enrollment` table using a compound unique index on `(userId, courseId)`. This lookup is the security checkpoint: it asks "does a row exist proving this specific user enrolled in this specific course?" before anything else happens.

**`if (!enrollment) { throw new Error(...) }`** — This is the critical control-flow moment. Throwing an error *inside* a `$transaction` callback is not like throwing an error in ordinary code — Prisma specifically catches this and triggers a **rollback**, meaning any database operations that might have already run inside this same transaction are undone, and nothing is committed. This is what makes it structurally impossible for a student to ever end up with a `Progress` row for a course they were never enrolled in, no matter what payload a malicious client sends.

**`tx.progress.upsert({ where: { userId_lessonId: { userId, lessonId } }, update: {...}, create: {...} })`** — This only executes if the enrollment check above did *not* throw. An "upsert" is a combined update-or-create operation: if a `Progress` row already exists for this exact `(userId, lessonId)` pair, it updates that row; otherwise, it creates a new one. This single call correctly handles both "first time completing this lesson" and "re-completing an already-finished lesson" without needing separate code paths for each case.

**`revalidateTag(\`progress-${courseId}\`)`** — This runs only after the transaction has fully succeeded. It tells Next.js's caching layer to discard any previously cached data tagged with this specific course's progress key, ensuring the next page load reflects the fresh completion state rather than stale cached data.

**The outer `try { ... } catch (error: any) { ... }`** — This wraps the entire transaction attempt. If the transaction throws for *any* reason — a missing enrollment, a database connection issue, a constraint violation — execution jumps to the `catch` block, which logs the failure with a clearly-labeled `CRITICAL` prefix (making it easy to spot in server logs) and returns a structured `{ success: false, error: ... }` object back to the calling Client Component, rather than letting the error crash the request entirely.

**Why this pattern matters architecturally:** this transaction is the enforcement point of the Course → Chapter → Lesson content hierarchy meeting the transactional data layer. A Lesson's content can include a "Registry-bound JS" `CustomModule` block that a student interacts with, but the *result* of that interaction can only ever be permanently recorded if a legitimate `Enrollment` link exists connecting that student to the parent course — the transaction is what makes that rule unbreakable at the database level rather than just a suggestion enforced by UI code.

## C.2 Deep Dive: How `next/dynamic` Prevents Bundle Bloat

Recall the registry built in Part 3:

```typescript
export const ModuleRegistry: Record<string, ComponentType<GreymatterPluginProps<any>>> = {
  'sql-sandbox': dynamic(
    () => import('@/components/plugins/sql-sandbox').then((mod) => mod.SqlSandbox),
    {
      loading: () => <ModuleLoadingSkeleton />,
      ssr: false,
    }
  ),
};
```

**What `dynamic(() => import(...))` actually does under the hood:** Normally, a static `import` statement at the top of a file tells the JavaScript bundler (the tool that packages your code for the browser) to include that module's code directly in the output bundle, at build time — every user downloads it, whether they need it or not. Wrapping the import inside a function — `() => import(...)` — turns it into a **dynamic import**, which is a native JavaScript feature that returns a `Promise` resolving to the module, fetched *at runtime* rather than bundled in upfront.

`next/dynamic` is a thin wrapper around this native capability, built specifically for React. It automatically:
1. Splits the imported module into its own separate JavaScript file (a "chunk") during the build process
2. Renders the `loading` fallback component immediately, before the chunk has finished downloading
3. Fetches the chunk over the network only at the moment this component actually appears in the render tree
4. Swaps in the real component once the chunk has loaded, replacing the loading fallback

**Why this matters at scale:** Imagine Greymatter eventually has fifty different plugin types registered in `ModuleRegistry` — a SQL sandbox, a code grader, a quiz engine, a diagram tool, and so on. Without dynamic imports, every single one of those fifty components' code would be bundled into *every* lesson page's initial JavaScript download, even if that particular lesson only uses one of them. With `next/dynamic`, only the one plugin type actually referenced by a given lesson's `customModule.moduleType` ever gets downloaded by that student's browser.

**Why `ssr: false` specifically:** This tells Next.js to skip attempting to render this component during the server-side rendering pass entirely, rendering it only client-side, in the browser. This is the correct choice for plugins like the SQL Sandbox that depend on browser-only interactivity (a student typing into a text area, clicking a button) — there is no meaningful "server-rendered" version of that interaction to produce, so skipping SSR avoids wasted server work and potential hydration mismatches.

**The mapping mechanism:** The registry's keys (like `"sql-sandbox"`) are plain strings that match exactly against the `moduleType` field a course author types into Sanity Studio's `CustomModule` block. When a lesson page renders and encounters a `CustomModule` extension block, it looks up that string in `ModuleRegistry` — this lookup is what implements the "Registry-bound JS" concept: Sanity stores nothing more than an identifier, and the actual executable behavior is resolved entirely on the Next.js side, through this dynamic import mechanism [1].
