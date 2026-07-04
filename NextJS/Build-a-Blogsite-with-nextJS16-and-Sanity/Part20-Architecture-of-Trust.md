# **✅ Part 20 — Authentication, Sessions, Cookies, and the Architecture of Trust**

---

# GreyMatter Journal  
## Part 20 — Authentication, Sessions, Cookies, and the Architecture of Trust

> **Goal of this lesson:** Add secure authentication and a protected admin area while understanding identity, sessions, cookies, and trust boundaries in modern web applications.

---

### The Identity Challenge

How does the server know who you are across multiple requests?

HTTP is stateless — each request is independent. Authentication layers identity and state on top of this.

---

### Key Concepts

- **Authentication**: "Who are you?"
- **Authorization**: "What are you allowed to do?"
- **Session**: Temporary record of a logged-in user
- **Cookie**: Mechanism to attach identity to requests

---

### Using Clerk for Authentication

**Install:**

```bash
npm install @clerk/nextjs
```

**Environment variables** (`.env.local`):

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
CLERK_SECRET_KEY=sk_...
```

**Middleware** (`middleware.ts`):

```typescript
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: ["/((?!_next|.*\\..*).*)"],
};
```

**Wrap Root Layout** with `<ClerkProvider>`.

---

### Sign-In Page

Create `app/sign-in/[[...sign-in]]/page.tsx`:

```tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return <SignIn />;
}
```

Clerk provides a complete, secure sign-in UI.

---

### Protected Routes

Example protected admin page (`app/admin/page.tsx`):

```tsx
import { auth } from "@clerk/nextjs/server";

export default async function AdminPage() {
  const { userId } = await auth();

  if (!userId) {
    return <div>Unauthorized</div>;
  }

  return <div>Admin Dashboard</div>;
}
```

---

### Mental Model To Remember Forever

**Security = Trust Management Under Uncertainty**

Every system continuously answers:
- Who are you?
- How do I verify?
- What are you allowed to do?
- How certain am I?

Professional systems are built around **trust boundaries** and **least privilege**.

---

### Up Next — Part 21: Comments, Likes, and User-Generated Content

We’ll implement interactive features and explore mutations, optimistic updates, and event-driven patterns.
