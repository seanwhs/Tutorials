# Part 3: Secure Coding — "Write Code That Doesn't Suck"

Picking up from Part 2: you have a Supabase database, an RBAC schema, and design docs specifying exactly what "secure" means for SecureTrade. Now we write the actual application code — and this is the first part where we follow the series' signature pattern: **for every major vulnerability class, we build the broken version first, attack it ourselves, then fix it.** You cannot truly understand why a defense matters until you've watched the attack succeed without it.

**Goal recap:** eliminate the OWASP Top 10 in real, running code.

---

## Step 1 — Create the Prisma Client Singleton

### 🎯 The Target
`lib/prisma.ts` — a single, shared Prisma Client instance for the whole app.

### 💡 The Concept
Next.js reloads your server code on nearly every file save during development ("hot reload"). If every file that needs the database just wrote `new PrismaClient()` at the top, you'd silently open a brand-new database connection on every single reload — like a restaurant hiring a new full-time waiter every time a customer orders a drink refill, until there's no room left in the kitchen. A **singleton** (a pattern that guarantees only one instance of something ever exists) solves this by creating the client once and reusing it everywhere.

### 🛠️ The Implementation

##### 📄 File: `lib/prisma.ts`
```typescript
// lib/prisma.ts
//
// Singleton Prisma Client. In development, Next.js's hot-reload would
// otherwise create a new PrismaClient (and a new DB connection pool) on
// every file save. We stash the instance on the Node.js `global` object,
// which SURVIVES hot reloads, so we only ever create one.

import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    // Log slow/error queries in development to make debugging easier,
    // without flooding production logs with every single query.
    log: process.env.NODE_ENV === "development" ? ["warn", "error"] : ["error"],
  });

// Only cache on `global` outside production — in production, each
// serverless function invocation gets a fresh module scope anyway, so this
// is purely a development-time optimization.
if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
```

### ✅ The Verification

```bash
cat > /tmp/test-prisma.ts << 'EOF'
import { prisma } from "@/lib/prisma";
async function main() {
  const count = await prisma.user.count();
  console.log("User count:", count);
}
main().finally(() => prisma.$disconnect());
EOF
npx dotenv -e .env.local -- tsx --tsconfig tsconfig.json /tmp/test-prisma.ts
```
Expected output: `User count: 3` (the three seeded accounts from Part 2). Delete the temp file afterward: `rm /tmp/test-prisma.ts`.

---

## Step 2 — Install and Configure NextAuth (Auth.js v5)

### 🎯 The Target
`auth.config.ts` and `auth.ts` — split into an **edge-safe** configuration and a **full** configuration, wired to our `User` table.

### 💡 The Concept
NextAuth (now called **Auth.js**) handles the fiddly, easy-to-get-wrong parts of authentication: securely setting cookies, signing tokens, protecting its own login form against CSRF. We split configuration into two files for a specific reason: our `middleware.ts` (Step 5) runs on Next.js's **Edge Runtime** — a lightweight, fast execution environment that runs geographically close to the user, but which deliberately *cannot* run Node.js-specific code like `bcrypt` password comparison (which depends on Node's native crypto internals). So:

- `auth.config.ts` — the edge-safe subset (session strategy, callbacks, redirect pages) — used by middleware.
- `auth.ts` — the full configuration, adding the `Credentials` provider (which needs `bcrypt` and Prisma, both Node-only) — used by everything else.

Think of it like a store having a fast, minimal "express checkout" lane (edge-safe, for quick yes/no "are you logged in" checks) and a full checkout counter (Node runtime, for anything requiring the full till).

### 🛠️ The Implementation

```bash
npm install next-auth@beta
```

##### 📄 File: `types/next-auth.d.ts`
```typescript
// types/next-auth.d.ts
//
// Augments NextAuth's built-in types to include our custom `role` field.
// Without this, TypeScript would not know `session.user.role` exists,
// and we'd be tempted to use `any` — exactly the kind of type-safety hole
// that hides bugs like "forgot to check the role."

import type { DefaultSession } from "next-auth";
import type { Role } from "@prisma/client";

declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      role: Role;
    } & DefaultSession["user"];
  }

  interface User {
    role: Role;
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    id: string;
    role: Role;
  }
}
```

##### 📄 File: `auth.config.ts`
```typescript
// auth.config.ts
//
// EDGE-SAFE configuration only. No Prisma, no bcrypt, no providers with
// Node.js dependencies — this file must be importable from middleware.ts,
// which runs on the Edge Runtime.

import type { NextAuthConfig } from "next-auth";

export const authConfig: NextAuthConfig = {
  pages: {
    signIn: "/login",
  },
  // JWT session strategy: the session is a signed token stored in a
  // cookie, not a row in a database. This scales better for serverless
  // deployments (Part 6) since there's no "session store" to query on
  // every request. The trade-off (can't instantly revoke a session
  // server-side) is discussed in this part's Reference section.
  session: {
    strategy: "jwt",
    maxAge: 30 * 60, // REQ-02 from Part 1: sessions expire after 30 minutes
  },
  callbacks: {
    // Runs on every request that matches middleware's matcher (Step 5).
    // This is where we decide "is this request even allowed to proceed,"
    // before it reaches any route handler.
    authorized({ auth }) {
      return true; // actual route-by-route logic lives in middleware.ts
    },
    // Copies the role from the database-backed `user` object (only present
    // at initial sign-in) into the long-lived JWT, so we don't need a
    // database call on every single request just to know the role.
    jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        token.role = user.role;
      }
      return token;
    },
    // Copies role/id from the JWT into the `session` object the app
    // actually reads via `auth()` or `useSession()`.
    session({ session, token }) {
      if (session.user) {
        session.user.id = token.id;
        session.user.role = token.role;
      }
      return session;
    },
  },
  providers: [], // filled in by auth.ts — kept empty here intentionally
};
```

##### 📄 File: `auth.ts`
```typescript
// auth.ts
//
// FULL configuration, including the Credentials provider — this file uses
// Prisma and bcrypt, so it must only run in the Node.js runtime (Route
// Handlers, Server Components, Server Actions), never from middleware.ts.

import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";
import bcrypt from "bcryptjs";
import { authConfig } from "./auth.config";
import { prisma } from "@/lib/prisma";
import { loginSchema } from "@/lib/validation/auth";

export const { handlers, auth, signIn, signOut } = NextAuth({
  ...authConfig,
  providers: [
    Credentials({
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        // NEVER trust the shape of `credentials` blindly — validate it
        // with the same Zod schema we use everywhere else. This is the
        // "never trust the frontend" principle applied to auth itself.
        const parsed = loginSchema.safeParse(credentials);
        if (!parsed.success) return null;

        const { email, password } = parsed.data;

        const user = await prisma.user.findUnique({ where: { email } });
        // Deliberately generic: we do NOT reveal whether the email exists
        // or the password was wrong — both return `null`, which NextAuth
        // turns into the same generic "invalid credentials" error. This
        // closes the account-enumeration threat (T-012 from Part 1).
        if (!user) return null;

        const passwordValid = await bcrypt.compare(password, user.passwordHash);
        if (!passwordValid) return null;

        // The object returned here becomes `user` in the `jwt` callback
        // above, exactly once, at sign-in time.
        return {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        };
      },
    }),
  ],
});
```

##### 📄 File: `app/api/auth/[...nextauth]/route.ts`
```typescript
// app/api/auth/[...nextauth]/route.ts
//
// Wires NextAuth's handlers into the App Router. This single file handles
// /api/auth/signin, /api/auth/callback, /api/auth/session, etc.

export { GET, POST } from "@/auth";
```

Add the session secret (Auth.js needs a strong random key to sign session tokens):

```bash
# Generates a cryptographically random 32-byte secret, base64-encoded
openssl rand -base64 32
```

##### 📄 File: `.env.local` (append)
```bash
AUTH_SECRET="PASTE_THE_GENERATED_VALUE_HERE"
```

##### 📄 File: `.env.example` (append)
```bash
AUTH_SECRET="generate-with: openssl rand -base64 32"
```

##### 📄 File: `lib/validation/auth.ts`
```typescript
// lib/validation/auth.ts
//
// Zod schemas shared by registration and login. Centralizing these means
// the password rules are defined ONCE, not duplicated (and potentially
// drifting out of sync) between the register route and NextAuth's authorize().

import { z } from "zod";

export const registerSchema = z.object({
  email: z.string().trim().toLowerCase().email().max(255),
  name: z.string().trim().min(1, "Name is required").max(100),
  password: z
    .string()
    .min(12, "Password must be at least 12 characters")
    .max(128)
    .regex(/[A-Z]/, "Password must contain an uppercase letter")
    .regex(/[a-z]/, "Password must contain a lowercase letter")
    .regex(/[0-9]/, "Password must contain a digit"),
});

export const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(1, "Password is required"),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
```

### ✅ The Verification

```bash
npx dotenv -e .env.local -- npx tsc --noEmit
```
Expected: no type errors (confirms the `next-auth` module augmentation compiles correctly and `auth.ts`/`auth.config.ts` are structurally valid).

---

## Step 3 — Build the Secure Registration Route

### 🎯 The Target
`app/api/v1/auth/register/route.ts` — the first real, Zod-validated, security-hardened API route.

### 💡 The Concept
"Never trust the frontend" means: even though your React form might disable the submit button until a password meets complexity rules, an attacker doesn't use your form at all — they send raw HTTP requests directly with `curl` or Postman, skipping your UI entirely. **Zod** (a TypeScript-first schema validation library) re-enforces every rule *on the server*, where an attacker cannot bypass it. Think of your frontend validation as a polite sign asking people to wipe their feet, and server-side Zod validation as the actual locked door — only one of them a burglar has to respect.

### 🛠️ The Implementation

##### 📄 File: `app/api/v1/auth/register/route.ts`
```typescript
// app/api/v1/auth/register/route.ts

import { NextRequest, NextResponse } from "next/server";
import bcrypt from "bcryptjs";
import { Prisma } from "@prisma/client";
import { prisma } from "@/lib/prisma";
import { registerSchema } from "@/lib/validation/auth";

// Must match the constant used in prisma/seed.ts (Part 2) — OWASP's
// current minimum recommended bcrypt cost factor.
const BCRYPT_COST_FACTOR = 12;

export async function POST(req: NextRequest) {
  // Defensively parse JSON — a malformed body should never crash the
  // server with an uncaught exception (that itself would be a DoS vector).
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const parsed = registerSchema.safeParse(body);
  if (!parsed.success) {
    // .flatten() gives a clean { fieldErrors, formErrors } shape — enough
    // detail for a legitimate client to fix its form, without ever
    // leaking internal server details (closes T-003 from Part 1).
    return NextResponse.json(
      { error: "Validation failed", issues: parsed.error.flatten() },
      { status: 400 }
    );
  }

  const { email, name, password } = parsed.data;
  const passwordHash = await bcrypt.hash(password, BCRYPT_COST_FACTOR);

  try {
    const user = await prisma.user.create({
      // Note: `role` is deliberately NOT accepted from the request body at
      // all — it isn't even in registerSchema. The database default
      // (`@default(USER)` from Part 2's schema) is the ONLY way a new
      // account gets a role. This is Secure Defaults in action.
      data: { email, name, passwordHash },
    });

    return NextResponse.json(
      { id: user.id, email: user.email, name: user.name },
      { status: 201 }
    );
  } catch (err) {
    // Prisma error code P2002 = unique constraint violation (duplicate
    // email). We still return a generic message rather than internal
    // details, but a 409 for registration (unlike login/reset) is
    // considered acceptable — a user needs to know their own email is
    // already registered to proceed.
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      return NextResponse.json(
        { error: "Unable to register with these details" },
        { status: 409 }
      );
    }

    console.error("Registration error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
```

### ✅ The Verification

```bash
npm run dev
```

In another terminal, test the happy path:
```bash
curl -i -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"trader1@example.com","name":"Tom Trader","password":"SuperSecure123"}'
```
Expected: `HTTP/1.1 201 Created` with the user's `id`, `email`, `name` (no password hash returned — ever).

Now test that server-side validation actually blocks a weak password, even though no frontend exists yet to stop you:
```bash
curl -i -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"trader2@example.com","name":"Test","password":"weak"}'
```
Expected: `HTTP/1.1 400 Bad Request` with `issues.fieldErrors.password` listing the failed rules.

Finally, confirm a duplicate email is rejected:
```bash
curl -i -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"trader1@example.com","name":"Tom Trader","password":"SuperSecure123"}'
```
Expected: `HTTP/1.1 409 Conflict`.

---

## Step 4 — Wire Up the Login UI

### 🎯 The Target
A minimal but functional `/login` page, and the `SessionProvider` wiring it depends on.

### 💡 The Concept
NextAuth's client-side `signIn()` helper needs a React Context Provider wrapping the app — think of it like a building needing one central alarm panel that every room's sensor reports to, rather than each room managing its own separate alarm system.

### 🛠️ The Implementation

##### 📄 File: `app/providers.tsx`
```tsx
// app/providers.tsx
"use client";

import { SessionProvider } from "next-auth/react";
import type { ReactNode } from "react";

export function Providers({ children }: { children: ReactNode }) {
  return <SessionProvider>{children}</SessionProvider>;
}
```

##### 📄 File: `app/layout.tsx`
```tsx
// app/layout.tsx
import type { Metadata } from "next";
import { Providers } from "./providers";
import "./globals.css";

export const metadata: Metadata = {
  title: "SecureTrade",
  description: "A simplified, security-first SGX-style trading app",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

##### 📄 File: `app/login/page.tsx`
```tsx
// app/login/page.tsx
"use client";

import { useState, type FormEvent } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    // `redirect: false` lets us handle success/failure ourselves instead
    // of NextAuth doing a full-page redirect — this gives us a chance to
    // show a friendly error message on failure.
    const result = await signIn("credentials", {
      email,
      password,
      redirect: false,
    });

    setSubmitting(false);

    if (result?.error) {
      // Deliberately generic — matches the generic `authorize()` failure
      // from Step 2. We never say "wrong password" vs "no such account."
      setError("Invalid email or password.");
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <main style={{ maxWidth: 400, margin: "4rem auto", fontFamily: "sans-serif" }}>
      <h1>Log in to SecureTrade</h1>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </div>
        <div>
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </div>
        {error && <p style={{ color: "red" }}>{error}</p>}
        <button type="submit" disabled={submitting}>
          {submitting ? "Logging in..." : "Log in"}
        </button>
      </form>
    </main>
  );
}
```

##### 📄 File: `app/dashboard/page.tsx`
```tsx
// app/dashboard/page.tsx
import { auth } from "@/auth";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  const session = await auth();
  if (!session?.user) redirect("/login");

  return (
    <main style={{ fontFamily: "sans-serif", padding: "2rem" }}>
      <h1>Welcome, {session.user.name}</h1>
      <p>Role: {session.user.role}</p>
    </main>
  );
}
```

### ✅ The Verification

Visit `http://localhost:3000/login` in a browser, and log in with the seeded account from Part 2 (`user@securetrade.test`, password = whatever you set as `SEED_USER_PASSWORD` in `.env.local`). Confirm you're redirected to `/dashboard` and see "Welcome, Uma User" and "Role: USER".

---

## Step 5 — Build `middleware.ts` for Zero-Trust Route Protection

### 🎯 The Target
`middleware.ts` at the project root, enforcing the RBAC matrix from Part 2 at the network edge, before any request reaches a route handler.

### 💡 The Concept
This is Zero Trust made concrete: every single request — no exceptions — passes through this checkpoint, like an airport security line that every passenger walks through regardless of which gate they're flying from. Middleware alone is **not sufficient**, though — a determined attacker (or a future refactor that accidentally changes the matcher pattern) could bypass it. That's why, in Step 8's fixes, route handlers *also* re-check authorization independently. This is Defense in Depth applied literally: two independent checkpoints, not one.

### 🛠️ The Implementation

##### 📄 File: `middleware.ts`
```typescript
// middleware.ts
//
// Runs on Next.js's Edge Runtime, on every request matched by `config`
// below. Implements the RBAC matrix from docs/ARCHITECTURE.md as the
// FIRST line of defense — route handlers still re-check independently.

import { NextResponse } from "next/server";
import { auth } from "@/auth";

// Routes requiring the ADMIN role specifically.
const ADMIN_ROUTE_PREFIXES = ["/admin", "/api/v1/admin", "/api/v1/instruments/create"];

// Routes requiring ADMIN or AUDITOR (anything Auditors are allowed to see).
const AUDITOR_OR_ADMIN_ROUTE_PREFIXES = ["/api/v1/audit-logs", "/audit-logs"];

// Routes requiring only "logged in" (any role).
const AUTHENTICATED_ROUTE_PREFIXES = ["/dashboard", "/api/v1/orders", "/api/v1/users/me"];

function matchesAny(pathname: string, prefixes: string[]): boolean {
  return prefixes.some((p) => pathname === p || pathname.startsWith(p + "/"));
}

export default auth((req) => {
  const { nextUrl } = req;
  const pathname = nextUrl.pathname;

  const isLoggedIn = !!req.auth?.user;
  const role = req.auth?.user?.role;

  const isAdminRoute = matchesAny(pathname, ADMIN_ROUTE_PREFIXES);
  const isAuditorRoute = matchesAny(pathname, AUDITOR_OR_ADMIN_ROUTE_PREFIXES);
  const isAuthenticatedRoute = matchesAny(pathname, AUTHENTICATED_ROUTE_PREFIXES);

  const requiresLogin = isAdminRoute || isAuditorRoute || isAuthenticatedRoute;

  // Checkpoint 1: must be logged in at all.
  if (requiresLogin && !isLoggedIn) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
    return NextResponse.redirect(new URL("/login", nextUrl));
  }

  // Checkpoint 2: must hold the ADMIN role specifically.
  if (isAdminRoute && role !== "ADMIN") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  // Checkpoint 3: must hold ADMIN or AUDITOR.
  if (isAuditorRoute && role !== "ADMIN" && role !== "AUDITOR") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  return NextResponse.next();
});

// Excludes Next.js internals and the NextAuth API routes themselves
// (which must remain reachable to log in at all) from middleware checks.
export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/auth).*)"],
};
```

##### 📄 File: `lib/auth-helpers.ts`
```typescript
// lib/auth-helpers.ts
//
// Reusable server-side authorization helpers, used INSIDE route handlers
// as the second, independent Defense-in-Depth checkpoint — middleware.ts
// is the first, but every route handler re-verifies for itself too.

import { auth } from "@/auth";
import { NextResponse } from "next/server";
import type { Role } from "@prisma/client";
import type { Session } from "next-auth";

export class AuthorizationError extends Error {}

// Returns the current session, or throws a structured error a route
// handler can catch and turn into a proper 401 response.
export async function requireSession(): Promise<Session> {
  const session = await auth();
  if (!session?.user) {
    throw new AuthorizationError("Not authenticated");
  }
  return session;
}

// Verifies the session's role is one of the allowed roles for this
// operation. This is what closes T-005/T-009 at the ROUTE level, not just
// the middleware level.
export function requireRole(session: Session, allowedRoles: Role[]): void {
  if (!allowedRoles.includes(session.user.role)) {
    throw new AuthorizationError(
      `Role ${session.user.role} is not permitted to perform this action`
    );
  }
}

// Converts an AuthorizationError into the correct HTTP response, so every
// route handler can just `catch` and call this, instead of repeating
// status-code logic everywhere.
export function authErrorResponse(err: unknown): NextResponse | null {
  if (err instanceof AuthorizationError) {
    return NextResponse.json({ error: err.message }, { status: 403 });
  }
  return null;
}
```

### ✅ The Verification

```bash
# Not logged in, hitting an authenticated-only API route:
curl -i http://localhost:3000/api/v1/orders
```
Expected: `HTTP/1.1 401 Unauthorized`.

Log in as the seeded `user@securetrade.test` account in the browser, copy the `authjs.session-token` cookie value from DevTools → Application → Cookies, then:
```bash
curl -i http://localhost:3000/admin/users \
  -H "Cookie: authjs.session-token=PASTE_COOKIE_VALUE_HERE"
```
Expected: `HTTP/1.1 403 Forbidden` — a `USER` cannot reach an `/admin` route, confirmed at the network edge before any page code runs.

---

## Step 6 — Install Semgrep and ESLint Security Rules

### 🎯 The Target
Semgrep and `eslint-plugin-security` installed and configured, **before** we write any vulnerable code — so our very first "break it" step immediately gets flagged by tooling, exactly as it would in a real CI pipeline (which we build properly in Part 5).

### 💡 The Concept
**SAST** (Static Application Security Testing) tools read your source code — without running it — looking for known-dangerous *patterns*, like a proofreader who has memorized every commonly-misspelled word and flags them on sight, without needing to understand the whole essay's meaning. **Semgrep** is a SAST tool that matches code against rules that look almost like the code itself, making custom rules easy to write and read. `eslint-plugin-security` does something similar but lives directly inside your existing ESLint setup, giving instant in-editor feedback (thanks to the ESLint VS Code extension from Part 0).

Important expectation to set now: **SAST tools are excellent at catching syntactic patterns** (a raw SQL string, a call to `eval`) **but cannot understand business logic** (whether an authorization check is *present* is easy to detect; whether it's *correct* often is not). You'll see this limitation firsthand in Step 8.

### 🛠️ The Implementation

```bash
# Semgrep's official npm wrapper — installs the real Semgrep engine as a
# postinstall step, so it fits naturally into our existing npm workflow.
npm install -D semgrep

npm install -D eslint-plugin-security
```

##### 📄 File: `.semgrep.yml`
```yaml
# .semgrep.yml
#
# Custom rules targeting the exact vulnerability classes this tutorial
# plants in Step 7. In Part 5, this same file gets wired into CI so these
# checks run automatically on every pull request.

rules:
  - id: no-raw-sql-unsafe
    languages: [typescript, javascript]
    severity: ERROR
    message: >
      Never use $queryRawUnsafe or $executeRawUnsafe with interpolated
      strings — this allows SQL injection. Use Prisma's typed query
      methods (findMany, findUnique, etc.) or $queryRaw with tagged
      template literals, which parameterize automatically.
    patterns:
      - pattern-either:
          - pattern: $PRISMA.$queryRawUnsafe(...)
          - pattern: $PRISMA.$executeRawUnsafe(...)

  - id: no-dynamic-code-execution
    languages: [typescript, javascript]
    severity: ERROR
    message: >
      Never execute dynamically constructed code from user input (eval,
      new Function(...)). This allows arbitrary code execution on the
      server, including reading environment variables/secrets.
    patterns:
      - pattern-either:
          - pattern: eval(...)
          - pattern: new Function(...)

  - id: no-dangerously-set-inner-html-with-variable
    languages: [typescript, javascript]
    severity: ERROR
    message: >
      dangerouslySetInnerHTML bypasses React's automatic escaping and can
      lead to stored XSS if the value includes any user-controlled data.
      Render as plain text/JSX instead, or sanitize with a library like
      DOMPurify if raw HTML rendering is truly required.
    patterns:
      - pattern: dangerouslySetInnerHTML={{ __html: $VAR }}

  - id: possible-ssrf-unvalidated-fetch
    languages: [typescript, javascript]
    severity: WARNING
    message: >
      fetch() called with a variable URL that may originate from user
      input. Verify this URL is validated against an allowlist/blocklist
      (see lib/ssrf-guard.ts) before this fetch executes, to prevent SSRF.
    patterns:
      - pattern: fetch($URL, ...)
      - metavariable-regex:
          metavariable: $URL
          regex: "^(?!['\"]).*$" # flags any non-string-literal URL argument
```

##### 📄 File: `eslint.config.mjs` (edit — add the security plugin)
```javascript
// eslint.config.mjs
import { FlatCompat } from "@eslint/eslintrc";
import security from "eslint-plugin-security";

const compat = new FlatCompat({ baseDirectory: import.meta.dirname });

const eslintConfig = [
  ...compat.extends("next/core-web-vitals", "next/typescript"),
  {
    plugins: { security },
    rules: {
      // Flags eval(), child_process usage with variables, RegExp
      // constructed from variables (ReDoS risk), and more.
      ...security.configs.recommended.rules,
    },
  },
];

export default eslintConfig;
```

##### 📄 File: `package.json` (edit — add scripts)
```json
{
  "scripts": {
    "semgrep": "semgrep scan --config .semgrep.yml --error",
    "lint:security": "eslint . --quiet"
  }
}
```

### ✅ The Verification

```bash
npm run semgrep
```
Expected output on the current (still-clean) codebase:
```
Scanning XX files...

No findings.
```
This confirms the tool works correctly *before* we intentionally introduce bugs — a clean baseline to compare against in Step 8.

---

## Step 7 — 🔓 Break It First: Deploy 7 Vulnerable Features

### 🎯 The Target
Seven intentionally vulnerable files, one per major OWASP Top 10 category from this part's scope. We will attack every single one before fixing any of them.

### 💡 The Concept
Each bug below is written the way a rushed developer — under deadline pressure, copy-pasting from an outdated Stack Overflow answer — actually writes code in the real world. That's deliberate: these aren't cartoonishly bad, they're *realistically* bad, which is exactly why the OWASP Top 10 exists as a list in the first place.

### 🛠️ The Implementation

##### 📄 File: `app/api/v1/instruments/search/route.ts` (🔓 VULNERABLE)
```typescript
// app/api/v1/instruments/search/route.ts
// 🔓 BUG 1: SQL Injection

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q") ?? "";

  // DANGER: building a SQL string by directly concatenating user input.
  // $queryRawUnsafe does NOT parameterize — this is functionally
  // identical to classic PHP `"SELECT * FROM x WHERE y = '" . $_GET['q'] . "'"`.
  const results = await prisma.$queryRawUnsafe(
    `SELECT * FROM "Instrument" WHERE name ILIKE '%${q}%'`
  );

  return NextResponse.json(results);
}
```

##### 📄 File: `app/api/v1/orders/[id]/route.ts` (🔓 VULNERABLE)
```typescript
// app/api/v1/orders/[id]/route.ts
// 🔓 BUG 2: IDOR (Insecure Direct Object Reference)

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { auth } from "@/auth";

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // DANGER: fetches ANY order by ID, with no check that it belongs to the
  // requesting user. Any logged-in user can view any other user's order
  // simply by guessing/incrementing IDs.
  const order = await prisma.order.findUnique({
    where: { id: params.id },
    include: { instrument: true },
  });

  if (!order) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  return NextResponse.json(order);
}
```

##### 📄 File: `app/api/v1/users/me/route.ts` (🔓 VULNERABLE)
```typescript
// app/api/v1/users/me/route.ts
// 🔓 BUG 3: Mass Assignment / Broken Function-Level Authorization

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { auth } from "@/auth";

export async function PATCH(req: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json();

  // DANGER: spreading the raw request body directly into the update.
  // If the body includes { "role": "ADMIN" }, the user just promoted
  // themselves — no validation, no field whitelist.
  const updated = await prisma.user.update({
    where: { id: session.user.id },
    data: body,
  });

  return NextResponse.json(updated);
}
```

##### 📄 File: `app/api/v1/orders/route.ts` (🔓 VULNERABLE)
```typescript
// app/api/v1/orders/route.ts
// 🔓 BUG 4: Trusting client-submitted price (business logic tampering)

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { auth } from "@/auth";

export async function POST(req: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json();

  // DANGER: `body.price` comes straight from the client and is trusted
  // as-is. An attacker can submit any price they want, e.g. buying a
  // $42.50 stock for $0.01.
  const order = await prisma.order.create({
    data: {
      userId: session.user.id,
      instrumentId: body.instrumentId,
      side: body.side,
      quantity: body.quantity,
      executedPrice: body.price, // <-- attacker-controlled
      idempotencyKey: body.idempotencyKey ?? crypto.randomUUID(),
    },
  });

  return NextResponse.json(order, { status: 201 });
}
```

##### 📄 File: `app/admin/users/page.tsx` (🔓 VULNERABLE)
```tsx
// app/admin/users/page.tsx
// 🔓 BUG 5: Stored XSS via dangerouslySetInnerHTML

import { prisma } from "@/lib/prisma";

export default async function AdminUsersPage() {
  const users = await prisma.user.findMany({ orderBy: { createdAt: "desc" } });

  return (
    <main style={{ fontFamily: "sans-serif", padding: "2rem" }}>
      <h1>All Users (Admin)</h1>
      <ul>
        {users.map((u) => (
          // DANGER: rendering a user-controlled field (name, set at
          // registration) as raw HTML. Any registered user can put
          // <script>/<img onerror=...> in their name, and it executes in
          // whichever Admin's browser later loads this page.
          <li key={u.id} dangerouslySetInnerHTML={{ __html: `${u.name} — ${u.email}` }} />
        ))}
      </ul>
    </main>
  );
}
```

##### 📄 File: `app/api/v1/alerts/route.ts` (🔓 VULNERABLE)
```typescript
// app/api/v1/alerts/route.ts
// 🔓 BUG 6: SSRF (Server-Side Request Forgery)

import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/auth";

export async function POST(req: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { webhookUrl } = await req.json();

  // DANGER: the server fetches whatever URL the client provides, with no
  // validation. An attacker can point this at internal-only services
  // (databases, cloud metadata endpoints, admin panels on a private
  // network) that are not reachable directly from the internet, using
  // OUR server as a proxy to reach them.
  const response = await fetch(webhookUrl, { method: "GET" });
  const text = await response.text();

  return NextResponse.json({ status: response.status, body: text.slice(0, 500) });
}
```

##### 📄 File: `app/api/v1/orders/fee/route.ts` (🔓 VULNERABLE)
```typescript
// app/api/v1/orders/fee/route.ts
// 🔓 BUG 7: Code Injection via dynamic evaluation

import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const { quantity, price, formula } = await req.json();

  // DANGER: constructing and executing a function from a user-supplied
  // string. `new Function` runs in the same process, with access to the
  // same closures/globals — including `process.env`, which holds our
  // database credentials and AUTH_SECRET.
  const feeFn = new Function("quantity", "price", `return ${formula};`);
  const fee = feeFn(quantity, price);

  return NextResponse.json({ fee });
}
```

### ✅ The Verification — Exploit Every Bug

First, register an attacker account and note its `id`:
```bash
curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"attacker@evil.test","name":"Attacker","password":"AttackerPass123"}'
```

Log in via the browser as `attacker@evil.test`, copy the session cookie from DevTools, and export it for reuse:
```bash
export ATTACKER_COOKIE="authjs.session-token=PASTE_VALUE_HERE"
```

**Exploit Bug 1 (SQL Injection):**
```bash
curl -s "http://localhost:3000/api/v1/instruments/search?q=%27%20OR%20%271%27%3D%271" | head -c 300
# The payload `' OR '1'='1` breaks out of the intended string literal,
# turning the WHERE clause into always-true — returning ALL rows
# regardless of the intended filter, proving injection succeeded.
```

**Exploit Bug 2 (IDOR):** first find any order ID belonging to a *different* user (e.g. the seeded `user@securetrade.test`), then:
```bash
curl -s http://localhost:3000/api/v1/orders/SOMEONE_ELSES_ORDER_ID \
  -H "Cookie: $ATTACKER_COOKIE"
# Returns the full order — belonging to a user you're not authenticated as.
```

**Exploit Bug 3 (Mass Assignment / Privilege Escalation):**
```bash
curl -s -X PATCH http://localhost:3000/api/v1/users/me \
  -H "Cookie: $ATTACKER_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"role":"ADMIN"}'
# Response shows "role":"ADMIN" — the attacker just promoted themselves.
```

**Exploit Bug 4 (Price Tampering):**
```bash
curl -s -X POST http://localhost:3000/api/v1/orders \
  -H "Cookie: $ATTACKER_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"instrumentId":"<D05_INSTRUMENT_ID>","side":"BUY","quantity":1000,"price":0.01}'
# Buys 1000 shares of a $42.50 stock for one cent each.
```

**Exploit Bug 5 (Stored XSS):** register a second attacker account with a malicious name, then view the admin page as an Admin:
```bash
curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"xss@evil.test","name":"<img src=x onerror=alert(document.domain)>","password":"AttackerPass123"}'
```
Log in as `admin@securetrade.test` in a real browser and visit `/admin/users` — the `alert()` fires in the Admin's browser session.

**Exploit Bug 6 (SSRF):**
```bash
curl -s -X POST http://localhost:3000/api/v1/alerts \
  -H "Cookie: $ATTACKER_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"webhookUrl":"http://localhost:3000/api/v1/orders"}'
# The server itself makes the request — reaching an endpoint the attacker
# is using OUR server's network position to probe.
```

**Exploit Bug 7 (Code Injection):**
```bash
curl -s -X POST http://localhost:3000/api/v1/orders/fee \
  -H "Content-Type: application/json" \
  -d '{"quantity":1,"price":1,"formula":"process.env.AUTH_SECRET"}'
# Returns your AUTH_SECRET value in the "fee" field — a formula field
# just leaked a production secret.
```

All seven should succeed exactly as described. **Do not deploy this code anywhere public.** Now let's fix every single one.

---

## Step 8 — Fix the 7 Bugs (with Semgrep as our guide)

### 🎯 The Target
Patched versions of all seven files, verified both by re-running the exploits (should now fail) and by re-running Semgrep (findings should disappear).

### 💡 The Concept — Run Semgrep First
Before fixing anything, see what our tooling catches on its own:

```bash
npm run semgrep
```

Expected output (abbreviated):
```
Scanning 24 files...

  app/api/v1/instruments/search/route.ts
     no-raw-sql-unsafe
        Never use $queryRawUnsafe...

  app/admin/users/page.tsx
     no-dangerously-set-inner-html-with-variable
        dangerouslySetInnerHTML bypasses React's automatic escaping...

  app/api/v1/alerts/route.ts
     possible-ssrf-unvalidated-fetch
        fetch() called with a variable URL...

  app/api/v1/orders/fee/route.ts
     no-dynamic-code-execution
        Never execute dynamically constructed code from user input...

4 findings.
```

**Notice: only 4 of our 7 bugs were caught.** Bugs 2 (IDOR), 3 (mass assignment), and 4 (trusted price) are invisible to pattern-matching SAST — there's nothing syntactically "wrong" with `prisma.order.findUnique({ where: { id } })`; the bug is that a check is *missing*, and a tool can't easily know what "should" be there. **This is exactly why Part 1's abuse cases and this series' "think like an attacker" mindset are not optional extras — they catch what tools structurally cannot.** We'll fix all 7 regardless, tool-flagged or not.

---

### Bug 1 Fix — SQL Injection

**Concept:** Prisma's typed query methods build parameterized queries automatically — user input is always sent to Postgres as a separate, tagged data value, never spliced into the SQL text itself. This is like a mail-merge template with a clearly labeled `[NAME]` field, versus physically retyping the letter for every recipient by hand — the template's structure can never be corrupted by what goes in the blank.

##### 📄 File: `app/api/v1/instruments/search/route.ts` (✅ FIXED)
```typescript
// app/api/v1/instruments/search/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { z } from "zod";

const searchSchema = z.object({
  q: z.string().trim().max(100).default(""),
});

export async function GET(req: NextRequest) {
  const parsed = searchSchema.safeParse({
    q: req.nextUrl.searchParams.get("q") ?? undefined,
  });
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid query" }, { status: 400 });
  }

  // Prisma's `contains` builds a parameterized ILIKE query internally —
  // the user's input is passed as a bound parameter, never concatenated
  // into the SQL string. Structurally immune to injection.
  const results = await prisma.instrument.findMany({
    where: {
      name: { contains: parsed.data.q, mode: "insensitive" },
    },
  });

  return NextResponse.json(results);
}
```

**Verification:**
```bash
curl -s "http://localhost:3000/api/v1/instruments/search?q=%27%20OR%20%271%27%3D%271"
```
Expected: an empty array `[]` (no instrument literally named `' OR '1'='1`) — the payload is now treated as inert search text, not executable SQL.

---

### Bug 2 Fix — IDOR

**Concept:** every fetch of a specific record must ask two questions: "does this exist?" *and* "is the requester allowed to see this specific one?" — like a hotel front desk checking not just "is this a valid room key" but "does this key match the room number being requested."

##### 📄 File: `app/api/v1/orders/[id]/route.ts` (✅ FIXED)
```typescript
// app/api/v1/orders/[id]/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireSession, authErrorResponse } from "@/lib/auth-helpers";

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  try {
    const session = await requireSession();

    const order = await prisma.order.findUnique({
      where: { id: params.id },
      include: { instrument: true },
    });

    if (!order) {
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }

    // Ownership check: the record must belong to the requester, UNLESS
    // the requester holds a role explicitly permitted to view any order
    // (matches the RBAC matrix from docs/ARCHITECTURE.md).
    const isOwner = order.userId === session.user.id;
    const isPrivilegedRole = session.user.role === "ADMIN" || session.user.role === "AUDITOR";

    if (!isOwner && !isPrivilegedRole) {
      // Return 404, not 403, here — revealing "this exists but isn't
      // yours" still leaks that the ID is valid. A 404 tells an attacker
      // nothing about whether the ID even exists.
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }

    return NextResponse.json(order);
  } catch (err) {
    const authResponse = authErrorResponse(err);
    if (authResponse) return authResponse;
    console.error("Order fetch error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
```

**Verification:**
```bash
curl -s http://localhost:3000/api/v1/orders/SOMEONE_ELSES_ORDER_ID \
  -H "Cookie: $ATTACKER_COOKIE"
```
Expected: `{"error":"Not found"}` with `HTTP 404` — even though the order genuinely exists.

---

### Bug 3 Fix — Mass Assignment

**Concept:** never write a value straight from a request body into a database update. Instead, explicitly whitelist exactly which fields are allowed — like a form with fixed printed fields, rather than a blank sheet of paper where someone could write absolutely anything, including things you never intended to accept.

##### 📄 File: `lib/validation/user.ts`
```typescript
// lib/validation/user.ts

import { z } from "zod";

// Deliberately excludes `role`, `email`, `passwordHash`, `id` — a user may
// only ever change their own display name through this endpoint.
export const updateProfileSchema = z.object({
  name: z.string().trim().min(1).max(100),
});
```

##### 📄 File: `app/api/v1/users/me/route.ts` (✅ FIXED)
```typescript
// app/api/v1/users/me/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireSession, authErrorResponse } from "@/lib/auth-helpers";
import { updateProfileSchema } from "@/lib/validation/user";

export async function PATCH(req: NextRequest) {
  try {
    const session = await requireSession();

    let body: unknown;
    try {
      body = await req.json();
    } catch {
      return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
    }

    // If the request attempted to set fields outside our whitelist (e.g.
    // `role`), we don't just silently ignore them — we explicitly reject
    // the whole request and note it. In Part 7 this exact log line
    // becomes the seed of a real-time "privilege escalation attempt"
    // security alert.
    const bodyKeys = Object.keys(body as Record<string, unknown>);
    const allowedKeys = ["name"];
    const disallowedKeys = bodyKeys.filter((k) => !allowedKeys.includes(k));
    if (disallowedKeys.length > 0) {
      console.warn(
        `SECURITY: user ${session.user.id} attempted to set disallowed fields: ${disallowedKeys.join(", ")}`
      );
      return NextResponse.json(
        { error: `Cannot set fields: ${disallowedKeys.join(", ")}` },
        { status: 400 }
      );
    }

    const parsed = updateProfileSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Validation failed", issues: parsed.error.flatten() },
        { status: 400 }
      );
    }

    // Only ever write the exact, whitelisted fields — never the raw body.
    const updated = await prisma.user.update({
      where: { id: session.user.id },
      data: { name: parsed.data.name },
      select: { id: true, email: true, name: true, role: true },
    });

    return NextResponse.json(updated);
  } catch (err) {
    const authResponse = authErrorResponse(err);
    if (authResponse) return authResponse;
    console.error("Profile update error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
```

**Verification:**
```bash
curl -s -X PATCH http://localhost:3000/api/v1/users/me \
  -H "Cookie: $ATTACKER_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"role":"ADMIN"}'
```
Expected: `HTTP 400` with `{"error":"Cannot set fields: role"}` — and check your server console for the `SECURITY:` warning log line.

---

### Bug 4 Fix — Trusted Client Price

**Concept:** the client may *display* a quoted price, but the server is the only authoritative source of truth for what a trade actually executes at — like a vending machine that shows a price on the label, but the coin mechanism (not the label) is what actually determines whether your payment was sufficient.

##### 📄 File: `lib/validation/order.ts`
```typescript
// lib/validation/order.ts

import { z } from "zod";

export const createOrderSchema = z.object({
  instrumentId: z.string().cuid(),
  side: z.enum(["BUY", "SELL"]),
  quantity: z.number().int().positive().max(1_000_000),
  idempotencyKey: z.string().uuid(),
  // Note: NO price field here at all. The client may separately fetch
  // /api/v1/instruments to DISPLAY a quote to the user, but that value is
  // never sent back to, or trusted by, this endpoint.
});
```

##### 📄 File: `app/api/v1/orders/route.ts` (✅ FIXED)
```typescript
// app/api/v1/orders/route.ts

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireSession, authErrorResponse } from "@/lib/auth-helpers";
import { createOrderSchema } from "@/lib/validation/order";
import { Prisma } from "@prisma/client";

export async function POST(req: NextRequest) {
  try {
    const session = await requireSession();

    let body: unknown;
    try {
      body = await req.json();
    } catch {
      return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
    }

    const parsed = createOrderSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Validation failed", issues: parsed.error.flatten() },
        { status: 400 }
      );
    }

    const { instrumentId, side, quantity, idempotencyKey } = parsed.data;

    // Idempotency check (design from Part 2's API-DESIGN.md): if this
    // exact key was already used, return the existing order instead of
    // creating a duplicate — safely absorbs client retries.
    const existing = await prisma.order.findUnique({ where: { idempotencyKey } });
    if (existing) {
      return NextResponse.json(existing, { status: 200 });
    }

    const instrument = await prisma.instrument.findUnique({ where: { id: instrumentId } });
    if (!instrument) {
      return NextResponse.json({ error: "Instrument not found" }, { status: 404 });
    }

    // THE FIX: executedPrice comes ONLY from server-side data
    // (instrument.currentPrice), never from the request body.
    const executedPrice = instrument.currentPrice;

    try {
      // A transaction ensures the order row, the holding update, and the
      // audit log entry all succeed or all fail together — no partial,
      // inconsistent state (e.g. an order recorded but holdings not
      // updated) if something fails mid-way.
      const order = await prisma.$transaction(async (tx) => {
        const createdOrder = await tx.order.create({
          data: {
            userId: session.user.id,
            instrumentId,
            side,
            quantity,
            executedPrice,
            idempotencyKey,
            status: "FILLED",
          },
        });

        const quantityDelta = side === "BUY" ? quantity : -quantity;
        await tx.holding.upsert({
          where: { userId_instrumentId: { userId: session.user.id, instrumentId } },
          create: { userId: session.user.id, instrumentId, quantity: quantityDelta },
          update: { quantity: { increment: quantityDelta } },
        });

        // Implements REQ-08: every state-changing action is audit-logged.
        await tx.auditLog.create({
          data: {
            actorId: session.user.id,
            action: "ORDER_PLACED",
            targetType: "Order",
            targetId: createdOrder.id,
            metadata: { side, quantity, executedPrice: executedPrice.toString() },
          },
        });

        return createdOrder;
      });

      return NextResponse.json(order, { status: 201 });
    } catch (err) {
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
        // A race condition: two requests with the same idempotency key
        // arrived concurrently. Re-fetch and return the winner's result.
        const raceWinner = await prisma.order.findUnique({ where: { idempotencyKey } });
        if (raceWinner) return NextResponse.json(raceWinner, { status: 200 });
      }
      throw err;
    }
  } catch (err) {
    const authResponse = authErrorResponse(err);
    if (authResponse) return authResponse;
    console.error("Order creation error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
```

**Verification:**
```bash
curl -s -X POST http://localhost:3000/api/v1/orders \
  -H "Cookie: $ATTACKER_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"instrumentId":"<D05_INSTRUMENT_ID>","side":"BUY","quantity":10,"idempotencyKey":"'$(uuidgen)'","price":0.01}'
```
Even with `"price":0.01` still in the payload, inspect the response's `executedPrice` field — it will show `42.5` (the real instrument price), proving the tampered field was silently ignored, not just rejected.

---

### Bug 5 Fix — Stored XSS

**Concept:** React escapes text content by default — `{user.name}` is always rendered as inert text, never interpreted as HTML/JS, unless you explicitly opt out with `dangerouslySetInnerHTML` (whose name is a deliberate, loud warning sign). The fix here is simply: don't opt out.

##### 📄 File: `app/admin/users/page.tsx` (✅ FIXED)
```tsx
// app/admin/users/page.tsx

import { prisma } from "@/lib/prisma";
import { auth } from "@/auth";
import { redirect } from "next/navigation";

export default async function AdminUsersPage() {
  // Defense in Depth: middleware.ts already blocks non-Admins from
  // reaching this route, but we re-check here too — never rely on a
  // single layer, per docs/ARCHITECTURE.md.
  const session = await auth();
  if (!session?.user || session.user.role !== "ADMIN") {
    redirect("/login");
  }

  const users = await prisma.user.findMany({ orderBy: { createdAt: "desc" } });

  return (
    <main style={{ fontFamily: "sans-serif", padding: "2rem" }}>
      <h1>All Users (Admin)</h1>
      <ul>
        {users.map((u) => (
          // THE FIX: plain JSX interpolation. React automatically escapes
          // `<`, `>`, `&`, quotes, etc. — `<img src=x onerror=...>` is
          // rendered as the literal, harmless text "<img src=x onerror=...>",
          // never executed.
          <li key={u.id}>
            {u.name} — {u.email} ({u.role})
          </li>
        ))}
      </ul>
    </main>
  );
}
```

**Verification:** log in as `admin@securetrade.test` and revisit `/admin/users`. The row for the `xss@evil.test` account now displays the literal text `<img src=x onerror=alert(document.domain)>` on the page — visibly ugly, but completely inert. No alert box appears.

---

### Bug 6 Fix — SSRF

**Concept:** never let a server fetch a URL it didn't choose itself. When a feature genuinely requires fetching a user-supplied URL, validate it against a strict allowlist of protocols and reject anything resolving to private/internal network ranges — like a receptionist who will dial any *external* phone number a visitor requests, but will never connect them directly to the CEO's private internal extension no matter what number they ask for.

##### 📄 File: `lib/ssrf-guard.ts`
```typescript
// lib/ssrf-guard.ts
//
// Validates a user-supplied URL before the server is allowed to fetch it.
// Blocks private/internal IP ranges (including the cloud metadata IP
// 169.254.169.254, a classic SSRF target used to steal cloud credentials).

import { lookup } from "node:dns/promises";
import { isIP } from "node:net";

const BLOCKED_HOSTNAMES = new Set(["localhost", "127.0.0.1", "0.0.0.0", "::1"]);

function isPrivateIPv4(ip: string): boolean {
  const parts = ip.split(".").map(Number);
  if (parts.length !== 4) return false;
  const [a, b] = parts;
  return (
    a === 10 ||
    (a === 172 && b >= 16 && b <= 31) ||
    (a === 192 && b === 168) ||
    a === 127 ||
    (a === 169 && b === 254) // covers the cloud metadata endpoint
  );
}

export class UnsafeUrlError extends Error {}

export async function assertSafeWebhookUrl(rawUrl: string): Promise<URL> {
  let url: URL;
  try {
    url = new URL(rawUrl);
  } catch {
    throw new UnsafeUrlError("Invalid URL");
  }

  // Only allow HTTPS — blocks file://, gopher://, and plain http:// (which
  // could be used to bypass some network-level protections).
  if (url.protocol !== "https:") {
    throw new UnsafeUrlError("Only https:// URLs are allowed");
  }

  if (BLOCKED_HOSTNAMES.has(url.hostname)) {
    throw new UnsafeUrlError("This hostname is not allowed");
  }

  // Resolve the hostname to its actual IP and check THAT — a hostname
  // like "my-evil-domain.com" could still have its DNS record point at
  // 127.0.0.1 or an internal IP, which checking the hostname string alone
  // would miss entirely (a classic SSRF filter bypass technique).
  const { address } = await lookup(url.hostname);
  if (isIP(address) === 4 && isPrivateIPv4(address)) {
    throw new UnsafeUrlError("This URL resolves to a private/internal address");
  }

  return url;
}
```

##### 📄 File: `app/api/v1/alerts/route.ts` (✅ FIXED)
```typescript
// app/api/v1/alerts/route.ts

import { NextRequest, NextResponse } from "next/server";
import { requireSession, authErrorResponse } from "@/lib/auth-helpers";
import { assertSafeWebhookUrl, UnsafeUrlError } from "@/lib/ssrf-guard";

export async function POST(req: NextRequest) {
  try {
    await requireSession();

    const { webhookUrl } = await req.json();
    if (typeof webhookUrl !== "string") {
      return NextResponse.json({ error: "webhookUrl is required" }, { status: 400 });
    }

    const safeUrl = await assertSafeWebhookUrl(webhookUrl);

    // Additional Defense in Depth: a short timeout and no automatic
    // redirect-following, since an attacker-controlled server could
    // otherwise respond with a redirect to an internal address, bypassing
    // our upfront check entirely (a well-known SSRF filter bypass).
    const response = await fetch(safeUrl, {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(5000),
    });

    return NextResponse.json({ status: response.status });
  } catch (err) {
    const authResponse = authErrorResponse(err);
    if (authResponse) return authResponse;
    if (err instanceof UnsafeUrlError) {
      return NextResponse.json({ error: err.message }, { status: 400 });
    }
    console.error("Webhook test error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
```

**Verification:**
```bash
curl -s -X POST http://localhost:3000/api/v1/alerts \
  -H "Cookie: $ATTACKER_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"webhookUrl":"http://localhost:3000/api/v1/orders"}'
```
Expected: `HTTP 400` with `{"error":"Only https:// URLs are allowed"}`. Try `"webhookUrl":"https://169.254.169.254/"` too — expected: `{"error":"This URL resolves to a private/internal address"}`.

---

### Bug 7 Fix — Code Injection

**Concept:** if you find yourself wanting to `eval` user input to get "flexibility," that flexibility is a loaded gun pointed at your own server. The fix is almost always the same: replace "arbitrary code" with a small, fixed, safe menu of options — like a restaurant offering a fixed set of spice levels (mild/medium/hot) instead of handing customers the kitchen's raw chemical shelf.

##### 📄 File: `app/api/v1/orders/fee/route.ts` (✅ FIXED)
```typescript
// app/api/v1/orders/fee/route.ts

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";

// A small, fixed set of supported fee tiers — no dynamic code execution
// anywhere. If a genuinely new fee structure is needed in the future, a
// developer adds a new case here (reviewed via a pull request), rather
// than a user supplying arbitrary logic at request time.
const FEE_RATES = {
  STANDARD: 0.0025, // 0.25%
  PREMIUM: 0.001, // 0.10%
} as const;

const feeRequestSchema = z.object({
  quantity: z.number().positive(),
  price: z.number().positive(),
  tier: z.enum(["STANDARD", "PREMIUM"]),
});

export async function POST(req: NextRequest) {
  const parsed = feeRequestSchema.safeParse(await req.json());
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Validation failed", issues: parsed.error.flatten() },
      { status: 400 }
    );
  }

  const { quantity, price, tier } = parsed.data;
  const fee = quantity * price * FEE_RATES[tier];

  return NextResponse.json({ fee });
}
```

**Verification:**
```bash
curl -s -X POST http://localhost:3000/api/v1/orders/fee \
  -H "Content-Type: application/json" \
  -d '{"quantity":1,"price":1,"tier":"STANDARD","formula":"process.env.AUTH_SECRET"}'
```
Expected: `{"fee":0.0025}` — the `formula` field, even if still sent by an old client, is simply ignored because it's not part of `feeRequestSchema` at all. No secret leaks.

### ✅ Final Verification — Re-run Semgrep

```bash
npm run semgrep
```
Expected output:
```
Scanning 24 files...

No findings.
```
All 4 tool-detectable findings are gone. Manually re-run every `curl` exploit from Step 7 — every single one should now fail exactly as shown in each fix's verification above.

---

## Step 9 — Secrets Management

### 🎯 The Target
A documented, enforced policy for how secrets are handled — and a tool (`gitleaks`, previewed here, covered fully in Part 5) that scans for accidentally committed secrets.

### 💡 The Concept
We already practiced good secrets hygiene since Part 2 (`.env.local`, never committed). This step makes that practice explicit and adds a safety net: a scanner that checks *history*, not just the current state of files — because even if you delete a secret from a file today, if it was ever committed, it remains permanently recoverable from Git's history unless that history itself is rewritten (a far more disruptive fix, discussed in the Reference section).

### 🛠️ The Implementation

##### 📄 File: `docs/SECRETS-POLICY.md`
```markdown
# SecureTrade — Secrets Management Policy

## Rules
1. No secret (API key, database URL, session secret, password) is ever
   committed to Git, in any file, at any point — including "temporarily"
   or "I'll remove it in the next commit."
2. Local development secrets live only in `.env.local`, which is
   git-ignored (verified automatically by `scripts/verify-part2.ts`).
3. `.env.example` documents every required variable name with a
   placeholder or generation instruction — never a real value.
4. Production secrets (Part 6) live in Vercel's encrypted Environment
   Variables dashboard, never in the repository.
5. If a secret is ever accidentally committed:
   - Rotate it immediately (generate a new one, update it everywhere) —
     treat the old value as permanently compromised, even if deleted from
     the file afterward.
   - Do not rely on deleting the file/line alone; Git history retains it.

## Tooling
- Local pre-commit scanning: `gitleaks protect` (see below).
- CI-enforced scanning: configured fully in Part 5.

## Future State (Part 6+)
Production secrets will migrate from Vercel's built-in environment
variables to HashiCorp Vault (or a managed equivalent) once the system
has multiple services needing shared, centrally-rotated secrets — Vercel
env vars are appropriate for this project's current single-app scale.
```

```bash
# Install gitleaks (macOS example — see gitleaks.io for other platforms)
brew install gitleaks

# Scan the entire Git history right now, as a baseline check
gitleaks detect --source . --verbose
```

##### 📄 File: `.gitleaks.toml`
```toml
# .gitleaks.toml
# Minimal config: use gitleaks' excellent built-in rule set, but exclude
# known-safe placeholder patterns (like .env.example's instructional text)
# from ever being flagged.

[extend]
useDefault = true

[[allowlist]]
paths = [
  '''\.env\.example$''',
]
```

### ✅ The Verification

```bash
gitleaks detect --source . --verbose
```
Expected output:
```
INF no leaks found
```

If this ever reports a finding, **stop and rotate the exposed secret immediately** before continuing any further work.

---

## Step 10 — Automate Verification of Part 3

### 🎯 The Target
`scripts/verify-part3.ts` — checks that every vulnerable pattern from Step 7 is truly gone, and that our security tooling is wired up correctly.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-part3.ts`
```typescript
// scripts/verify-part3.ts
//
// Verifies Part 3: confirms dangerous patterns are absent from the
// codebase, and that our security tooling configs exist.

import { existsSync, readFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";
import { readdirSync, statSync } from "node:fs";

type Check = { label: string; pass: boolean; detail?: string };
const checks: Check[] = [];

function fileExists(p: string): boolean {
  return existsSync(join(process.cwd(), p));
}

// Recursively collects all .ts/.tsx files under a directory, skipping
// node_modules and .next build output.
function collectSourceFiles(dir: string, acc: string[] = []): string[] {
  const fullDir = join(process.cwd(), dir);
  if (!existsSync(fullDir)) return acc;
  for (const entry of readdirSync(fullDir)) {
    if (entry === "node_modules" || entry === ".next") continue;
    const fullPath = join(fullDir, entry);
    const stat = statSync(fullPath);
    if (stat.isDirectory()) {
      collectSourceFiles(join(dir, entry), acc);
    } else if (entry.endsWith(".ts") || entry.endsWith(".tsx")) {
      acc.push(fullPath);
    }
  }
  return acc;
}

function main() {
  const requiredFiles = [
    "auth.ts",
    "auth.config.ts",
    "middleware.ts",
    "lib/prisma.ts",
    "lib/auth-helpers.ts",
    "lib/ssrf-guard.ts",
    "lib/validation/auth.ts",
    "lib/validation/order.ts",
    "lib/validation/user.ts",
    ".semgrep.yml",
    ".gitleaks.toml",
    "docs/SECRETS-POLICY.md",
  ];
  for (const f of requiredFiles) {
    checks.push({ label: `File exists: ${f}`, pass: fileExists(f) });
  }

  const sourceFiles = collectSourceFiles("app").concat(collectSourceFiles("lib"));
  const allSource = sourceFiles.map((f) => readFileSync(f, "utf-8")).join("\n");

  checks.push({
    label: "No $queryRawUnsafe / $executeRawUnsafe anywhere in app/ or lib/",
    pass: !/\$(queryRawUnsafe|executeRawUnsafe)/.test(allSource),
  });

  checks.push({
    label: "No eval() or new Function() anywhere in app/ or lib/",
    pass: !/\beval\(|new Function\(/.test(allSource),
  });

  checks.push({
    label: "No dangerouslySetInnerHTML anywhere in app/",
    pass: !/dangerouslySetInnerHTML/.test(allSource),
  });

  checks.push({
    label: "orders/route.ts does not read a client-submitted price field",
    pass: fileExists("app/api/v1/orders/route.ts")
      ? !/executedPrice:\s*body\.price/.test(
          readFileSync(join(process.cwd(), "app/api/v1/orders/route.ts"), "utf-8")
        )
      : false,
  });

  // Confirm Semgrep and Gitleaks both run clean right now.
  try {
    execSync("npm run semgrep", { stdio: "pipe" });
    checks.push({ label: "Semgrep scan passes with zero findings", pass: true });
  } catch {
    checks.push({ label: "Semgrep scan passes with zero findings", pass: false });
  }

  try {
    execSync("gitleaks detect --source . --no-banner", { stdio: "pipe" });
    checks.push({ label: "Gitleaks scan finds no secrets", pass: true });
  } catch {
    checks.push({ label: "Gitleaks scan finds no secrets", pass: false });
  }

  console.log("\nSecureTrade — Part 3 Verification\n");
  let allPassed = true;
  for (const c of checks) {
    const icon = c.pass ? "✅" : "❌";
    console.log(`${icon} ${c.label}${c.detail ? ` (${c.detail})` : ""}`);
    if (!c.pass) allPassed = false;
  }
  console.log(
    allPassed
      ? "\nAll Part 3 checks passed. Ready for Part 4.\n"
      : "\nSome checks failed — fix the items above before continuing.\n"
  );
  process.exit(allPassed ? 0 : 1);
}

main();
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "verify:part3": "tsx scripts/verify-part3.ts"
  }
}
```

### ✅ The Verification

```bash
npm run verify:part3
```
All checks should print ✅. Commit everything:

```bash
git add -A
git commit -m "feat: NextAuth, Zod validation, RBAC middleware, fix 7 planted OWASP Top 10 vulnerabilities, secrets policy"
git push
```

---

## ✅ Part 3 Completion Checklist

- [ ] Registration and login work end-to-end with Zod validation and bcrypt
- [ ] `middleware.ts` enforces role-based access at the edge
- [ ] Semgrep and `eslint-plugin-security` installed and passing clean
- [ ] All 7 planted vulnerabilities exploited successfully, then fixed and re-verified
- [ ] Gitleaks scan passes with zero findings
- [ ] `npm run verify:part3` exits all green

---

# 📚 Reference Section — Deep Dives for Part 3

### R1. JWT Sessions vs. Database Sessions

| | JWT Strategy (what we used) | Database Strategy |
|---|---|---|
| **Where session data lives** | Signed inside a cookie, on the client | A row in a `Session` table, server-side |
| **Scalability** | Excellent — no DB lookup needed to verify a session | Requires a DB query on every request |
| **Instant revocation** | Hard — a JWT remains "valid" until it expires, even if you "log the user out" server-side, unless you maintain a denylist | Easy — just delete the row |
| **Best for** | Serverless/edge deployments (our case — Vercel, Part 6) | Apps needing instant, guaranteed session kill-switches (e.g., "suspend this account NOW") |

Our 30-minute `maxAge` (REQ-02) meaningfully bounds the "can't instantly revoke" downside — a stolen JWT session is only usable for a maximum of 30 minutes of inactivity, not indefinitely.

### R2. MFA (Multi-Factor Authentication) — Options for a Future Add-On

We didn't implement MFA in this part (kept the series moving), but ASVS L2 expects it be *available* for sensitive operations. Common approaches, from simplest to most robust:
1. **TOTP** (Time-based One-Time Password) — apps like Google Authenticator; the server and app share a secret seed and both independently compute the same rotating 6-digit code.
2. **WebAuthn/Passkeys** — hardware-backed, phishing-resistant, using the device's built-in biometric/PIN unlock. This is the modern gold standard and where the industry is heading.
3. **SMS OTP** — easiest for users, but weakest (vulnerable to SIM-swapping attacks) — generally discouraged for anything handling money.

### R3. Passwordless Authentication

An alternative to passwords entirely: a "magic link" emailed to the user, or WebAuthn/Passkeys as above. Removes the entire class of "password reuse/weak password/phishing" risks, at the cost of depending on email deliverability or hardware support. NextAuth supports an `Email` provider for magic links out of the box, which would be a natural Part 8 "hardening" addition.

### R4. CSRF (Cross-Site Request Forgery) in Next.js — Why We Didn't Need a Separate Fix

CSRF tricks a logged-in user's browser into submitting a request to your site from a *different* site the attacker controls. NextAuth's own sign-in form already includes built-in CSRF token protection. For our custom API routes, the primary structural defense is that:
1. Our session cookie (set by NextAuth) uses `SameSite=Lax` by default, meaning the browser will *not* automatically attach it to cross-site POST requests.
2. Our routes require `Content-Type: application/json`, which a simple cross-site HTML `<form>` (the classic CSRF vector) cannot trigger without JavaScript — and cross-origin JavaScript `fetch()` calls are blocked by CORS unless we explicitly allow them (which we don't, by default, in Part 6's header configuration).

For a more defense-in-depth-conscious system, an explicit CSRF token (double-submit cookie pattern) can be added on top — worth doing for any future non-JSON form submissions.

### R5. Full OWASP Top 10 (2021) — Where Each Is Addressed in This Series

| # | Risk | Addressed |
|---|---|---|
| A01 | Broken Access Control | Part 2 (RBAC design), Part 3 (middleware + route-level checks, Bugs 2/3) |
| A02 | Cryptographic Failures | Part 3 (bcrypt), Part 6 (TLS/HSTS) |
| A03 | Injection | Part 3 (Bug 1, Bug 7) |
| A04 | Insecure Design | Parts 1–2 (threat modeling, secure architecture) |
| A05 | Security Misconfiguration | Part 6 (headers, WAF) |
| A06 | Vulnerable and Outdated Components | Part 4 (SCA, SBOM) |
| A07 | Identification and Authentication Failures | Part 3 (NextAuth, rate limiting design) |
| A08 | Software and Data Integrity Failures | Part 4 (supply chain), Part 5 (CI integrity) |
| A09 | Security Logging and Monitoring Failures | Part 7 (observability) |
| A10 | Server-Side Request Forgery | Part 3 (Bug 6) |

### R6. Writing Effective Semgrep Rules

A Semgrep rule's `pattern` uses metavariables (`$VAR`, `$URL`) to match structurally similar code regardless of variable naming — `pattern: fetch($URL, ...)` matches `fetch(userInput, {...})`, `fetch(webhookUrl)`, etc. `pattern-either` lets one rule catch multiple equivalent dangerous forms. For high-value custom rules, also explore `pattern-not` (explicitly exclude a known-safe variant) and `metavariable-regex` (constrain what a metavariable is allowed to match, as we did to distinguish string literals from variables in the SSRF rule).

### R7. Why We Fixed 3 Bugs Semgrep Never Flagged

This is worth repeating because it's the single most important lesson of this part: **automated tools are necessary but never sufficient.** IDOR, mass assignment, and business-logic tampering are all *authorization* bugs — the code is syntactically fine; the *business rule* is what's missing or wrong. Catching these requires either (a) a human thinking adversarially, exactly like Part 1's abuse cases, (b) DAST tools that actually exercise the running app with attacker-like requests (Part 5), or (c) rigorous code review checklists that explicitly ask "does this check ownership?" on every single data-access line. All three matter; none alone is enough.

---

**Next up: Part 4 — Dependencies & Supply Chain Security**, where we confront the uncomfortable truth that every `npm install` pulls in hundreds of packages you didn't personally review — and build the tooling (`npm audit`, Snyk, SBOM generation, GitHub Actions CVE gates) to keep that risk under control.
