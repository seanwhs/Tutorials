# Part 4: Lightweight Signed-Cookie Login

Goal: build a minimal, real, working login system using a signed cookie — no third-party auth provider, no passwords. Just enough to identify a user across requests so we can attach API keys and usage to them.

This is intentionally simple for teaching purposes. See Appendix C for production auth upgrades.

---

## 1. Session token helpers

Create `src/lib/auth/session.ts`:

```ts
import { cookies } from "next/headers";
import { createHmac, timingSafeEqual } from "node:crypto";
import { env } from "@/lib/env";

const COOKIE_NAME = "hdb_api_session";

type SessionPayload = {
  email: string;
  createdAt: string;
};

function base64url(input: string) {
  return Buffer.from(input).toString("base64url");
}

function unbase64url(input: string) {
  return Buffer.from(input, "base64url").toString("utf8");
}

function sign(value: string) {
  return createHmac("sha256", env.AUTH_COOKIE_SECRET).update(value).digest("base64url");
}

export function createSessionToken(payload: SessionPayload) {
  const body = base64url(JSON.stringify(payload));
  const signature = sign(body);
  return `${body}.${signature}`;
}

export function verifySessionToken(token: string): SessionPayload | null {
  const [body, signature] = token.split(".");
  if (!body || !signature) return null;

  const expected = sign(body);
  const a = Buffer.from(signature);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return null;
  if (!timingSafeEqual(a, b)) return null;

  try {
    return JSON.parse(unbase64url(body)) as SessionPayload;
  } catch {
    return null;
  }
}

export async function getCurrentUser() {
  const cookieStore = await cookies();
  const token = cookieStore.get(COOKIE_NAME)?.value;
  if (!token) return null;
  return verifySessionToken(token);
}

export async function setSession(email: string) {
  const cookieStore = await cookies();
  cookieStore.set(COOKIE_NAME, createSessionToken({ email, createdAt: new Date().toISOString() }), {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24 * 30,
  });
}

export async function clearSession() {
  const cookieStore = await cookies();
  cookieStore.delete(COOKIE_NAME);
}
```

Note the Next.js 16 pattern: `cookies()` returns a Promise, so every caller does `const cookieStore = await cookies();`.

---

## 2. User storage helper

Create `src/lib/auth/users.ts`:

```ts
import { redis } from "@/lib/redis";

export type AppUser = {
  email: string;
  createdAt: string;
};

export function userKey(email: string) {
  return `user:${email.toLowerCase()}`;
}

export async function ensureUser(email: string) {
  const normalized = email.toLowerCase();
  const key = userKey(normalized);
  const existing = await redis.get<AppUser>(key);
  if (existing) return existing;

  const user: AppUser = {
    email: normalized,
    createdAt: new Date().toISOString(),
  };

  await redis.set(key, user);
  return user;
}
```

---

## 3. Login page

Create `src/app/login/page.tsx`:

```tsx
import { Card, CardDescription, CardTitle } from "@/components/ui/card";

export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-950 px-6">
      <Card className="w-full max-w-md">
        <CardTitle>Get your API key</CardTitle>
        <CardDescription>
          Enter your email to create a tutorial account. No password needed.
        </CardDescription>
        <form action="/api/auth/login" method="post" className="mt-6 space-y-4">
          <label className="block">
            <span className="text-sm font-medium text-slate-700">Email</span>
            <input
              name="email"
              type="email"
              required
              placeholder="you@example.com"
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 outline-none focus:border-emerald-500"
            />
          </label>
          <button className="w-full rounded-lg bg-emerald-600 px-4 py-2 font-semibold text-white hover:bg-emerald-700">
            Continue
          </button>
        </form>
      </Card>
    </main>
  );
}
```

---

## 4. Login route

Create `src/app/api/auth/login/route.ts`:

```ts
import { ensureUser } from "@/lib/auth/users";
import { setSession } from "@/lib/auth/session";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const formData = await request.formData();
  const email = String(formData.get("email") ?? "").trim().toLowerCase();

  if (!email || !email.includes("@")) {
    return Response.json({ error: "A valid email is required." }, { status: 400 });
  }

  await ensureUser(email);
  await setSession(email);

  return Response.redirect(new URL("/dashboard", request.url));
}
```

---

## 5. Logout route

Create `src/app/api/auth/logout/route.ts`:

```ts
import { clearSession } from "@/lib/auth/session";

export const runtime = "nodejs";

export async function POST(request: Request) {
  await clearSession();
  return Response.redirect(new URL("/", request.url));
}
```

---

## 6. Dashboard home page

Create `src/app/dashboard/page.tsx`:

```tsx
import { redirect } from "next/navigation";
import { Card, CardDescription, CardTitle } from "@/components/ui/card";
import { ButtonLink } from "@/components/ui/button";
import { getCurrentUser } from "@/lib/auth/session";

export default async function DashboardPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="mt-2 text-slate-600">Signed in as {user.email}</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardTitle>API keys</CardTitle>
          <CardDescription>Create and revoke keys for your apps.</CardDescription>
          <div className="mt-4">
            <ButtonLink href="/dashboard/keys">Manage keys</ButtonLink>
          </div>
        </Card>
        <Card>
          <CardTitle>Usage</CardTitle>
          <CardDescription>See how many API calls your keys made.</CardDescription>
          <div className="mt-4">
            <ButtonLink href="/dashboard/usage" variant="secondary">View usage</ButtonLink>
          </div>
        </Card>
      </div>
    </div>
  );
}
```

---

## Checkpoint

- [ ] `/login` accepts an email and redirects to `/dashboard`.
- [ ] Visiting `/dashboard` while logged out redirects back to `/login`.
- [ ] Logging out clears the session and redirects home.
- [ ] Refreshing `/dashboard` while logged in keeps you signed in.

---

## Troubleshooting

**TypeScript error around `cookies()`**
In Next.js 16, always `await cookies()` before calling `.get()`/`.set()`/`.delete()` on it — it returns a Promise now, not a synchronous store.

**Login redirects but dashboard still shows "redirect to login"**
Confirm `setSession(email)` is awaited before `Response.redirect(...)` runs, so the `Set-Cookie` header is attached to the response.

**Cookie doesn't persist in production**
Production cookies use `secure: true`, requiring HTTPS — Vercel serves HTTPS by default, so this should just work once deployed.

**"Invalid Date" or JSON parse errors reading the session**
This usually means `AUTH_COOKIE_SECRET` changed between when the cookie was signed and now (e.g., you regenerated it). Log out and back in.

---

Ready for **Part 5 — API Key Management**?
