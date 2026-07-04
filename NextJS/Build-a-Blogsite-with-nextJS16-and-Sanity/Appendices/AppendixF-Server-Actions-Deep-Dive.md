# **✅ Appendix F — Server Actions Deep Dive**

---

# Appendix F — Server Actions Deep Dive: Remote Function Calls, Mutations, and the Future of Web Applications

> **Goal of this appendix:** Master Next.js Server Actions to execute secure server-side mutations, understand how they differ from traditional APIs, and learn how to manage data flow across the boundaries of space, time, and trust.

---

### 1. The Architectural Shift: From Plumbing to Logic

For years, web development required building explicit “pipes” (API routes) to move data from browser to server. Server Actions simplify this dramatically.

By adding `"use server"` to a function, you tell Next.js:  
> “This function is dangerous and belongs on the server. Make it callable from the browser like a normal function, but ensure it never leaves the server.”

---

### 2. Server Actions as Remote Procedure Calls (RPC)

Server Actions are **Remote Procedure Calls (RPC)**. You “call” a function in your UI, and it “magically” runs on the server.

**Behind the scenes:**
1. Serialization of data
2. Secure network request
3. Execution on server
4. Automatic revalidation

---

### 3. The Three Hurdles: Space, Time, and Trust

- **Space**: Browser is untrusted
- **Time**: Internet is slow
- **Trust**: Security must be enforced on the server

---

### 4. Building a Full-Stack Feedback Form

**Server Action** (`actions/feedback.ts`):

```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { z } from "zod";
import { writeClient } from "@/lib/sanity";
import { revalidatePath } from "next/cache";

const feedbackSchema = z.object({
  message: z.string().min(10),
  rating: z.number().min(1).max(5),
});

export async function submitFeedback(formData: FormData) {
  const { userId } = await auth();
  if (!userId) throw new Error("Unauthorized");

  const parsed = feedbackSchema.parse({
    message: formData.get("message"),
    rating: Number(formData.get("rating")),
  });

  await writeClient.create({
    _type: "feedback",
    userId,
    ...parsed,
  });

  revalidatePath("/feedback");
  return { success: true };
}
```

**UI Component**:

```tsx
"use client";

import { useActionState, useOptimistic } from "react";
import { submitFeedback } from "@/actions/feedback";

export default function FeedbackForm() {
  const [state, action, pending] = useActionState(submitFeedback, null);
  const [optimistic, addOptimistic] = useOptimistic(false, () => true);

  return (
    <form action={async (fd) => {
      addOptimistic(true);
      await action(fd);
    }}>
      <textarea name="message" placeholder="Your feedback..." />
      <input type="number" name="rating" min="1" max="5" defaultValue="5" />
      <button disabled={pending}>
        {optimistic ? "Sending..." : "Submit"}
      </button>
    </form>
  );
}
```

---

### Summary: The Modern Standard

Server Actions unify UI and business logic while maintaining security and performance.

**The Deep Secret:** Most software engineering is about moving computation through space, time, and trust boundaries. Server Actions let you focus on features instead of plumbing.

---

**Appendix F Complete.**
