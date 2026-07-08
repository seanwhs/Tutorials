# Part 5: API Key Management

Goal: let logged-in users create, list, and revoke API keys. We never store a raw key — only its SHA-256 hash — so a Redis leak alone can't be used to impersonate a key.

---

## 1. API key helpers

Create `src/lib/api-keys/api-keys.ts`:

```ts
import { createHash, randomBytes } from "node:crypto";
import { nanoid } from "nanoid";
import { redis } from "@/lib/redis";

export type ApiKeyRecord = {
  id: string;
  name: string;
  ownerEmail: string;
  prefix: string;
  hash: string;
  createdAt: string;
  revokedAt: string | null;
};

export function hashApiKey(rawKey: string) {
  return createHash("sha256").update(rawKey).digest("hex");
}

function userKeysSet(email: string) {
  return `user:${email.toLowerCase()}:keys`;
}

function apiKeyRecordKey(id: string) {
  return `key:${id}`;
}

function apiKeyHashKey(hash: string) {
  return `key_hash:${hash}`;
}

export async function createApiKey(ownerEmail: string, name: string) {
  const id = nanoid(12);
  const secret = randomBytes(24).toString("base64url");
  const rawKey = `hdb_live_${id}_${secret}`;
  const hash = hashApiKey(rawKey);
  const prefix = rawKey.slice(0, 18);

  const record: ApiKeyRecord = {
    id,
    name: name || "Default key",
    ownerEmail: ownerEmail.toLowerCase(),
    prefix,
    hash,
    createdAt: new Date().toISOString(),
    revokedAt: null,
  };

  await redis.set(apiKeyRecordKey(id), record);
  await redis.set(apiKeyHashKey(hash), id);
  await redis.sadd(userKeysSet(ownerEmail), id);

  return { rawKey, record };
}

export async function listApiKeys(ownerEmail: string) {
  const ids = await redis.smembers<string[]>(userKeysSet(ownerEmail));
  if (!ids.length) return [];

  const records = await Promise.all(ids.map((id) => redis.get<ApiKeyRecord>(apiKeyRecordKey(id))));
  return records
    .filter((record): record is ApiKeyRecord => Boolean(record))
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export async function revokeApiKey(ownerEmail: string, id: string) {
  const record = await redis.get<ApiKeyRecord>(apiKeyRecordKey(id));
  if (!record || record.ownerEmail !== ownerEmail.toLowerCase()) return false;

  const updated: ApiKeyRecord = {
    ...record,
    revokedAt: new Date().toISOString(),
  };

  await redis.set(apiKeyRecordKey(id), updated);
  await redis.del(apiKeyHashKey(record.hash));
  return true;
}

export async function validateApiKey(rawKey: string) {
  const hash = hashApiKey(rawKey);
  const id = await redis.get<string>(apiKeyHashKey(hash));
  if (!id) return null;

  const record = await redis.get<ApiKeyRecord>(apiKeyRecordKey(id));
  if (!record || record.revokedAt) return null;
  return record;
}
```

---

## 2. Create-key route

Create `src/app/api/keys/route.ts`:

```ts
import { getCurrentUser } from "@/lib/auth/session";
import { createApiKey } from "@/lib/api-keys/api-keys";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const user = await getCurrentUser();
  if (!user) return Response.json({ error: "Unauthorized" }, { status: 401 });

  const formData = await request.formData();
  const name = String(formData.get("name") ?? "Default key").trim();
  const { rawKey } = await createApiKey(user.email, name);

  const redirectUrl = new URL("/dashboard/keys", request.url);
  redirectUrl.searchParams.set("created", rawKey);
  return Response.redirect(redirectUrl);
}
```

---

## 3. Revoke-key route

Create `src/app/api/keys/revoke/route.ts`:

```ts
import { getCurrentUser } from "@/lib/auth/session";
import { revokeApiKey } from "@/lib/api-keys/api-keys";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const user = await getCurrentUser();
  if (!user) return Response.json({ error: "Unauthorized" }, { status: 401 });

  const formData = await request.formData();
  const id = String(formData.get("id") ?? "");
  await revokeApiKey(user.email, id);

  return Response.redirect(new URL("/dashboard/keys", request.url));
}
```

---

## 4. API keys dashboard page

Create `src/app/dashboard/keys/page.tsx`:

```tsx
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth/session";
import { listApiKeys } from "@/lib/api-keys/api-keys";
import { Card, CardDescription, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

export default async function KeysPage({
  searchParams,
}: {
  searchParams: Promise<{ created?: string }>;
}) {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const params = await searchParams;
  const keys = await listApiKeys(user.email);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">API Keys</h1>
        <p className="mt-2 text-slate-600">Create keys for your apps. Copy new keys immediately — they are shown only once.</p>
      </div>

      {params.created ? (
        <Card className="border-emerald-300 bg-emerald-50">
          <CardTitle>New API key created</CardTitle>
          <CardDescription>Copy this now. You will not be able to see it again.</CardDescription>
          <pre className="mt-4 overflow-x-auto rounded-lg bg-slate-950 p-4 text-sm text-emerald-300">{params.created}</pre>
        </Card>
      ) : null}

      <Card>
        <CardTitle>Create a key</CardTitle>
        <form action="/api/keys" method="post" className="mt-4 flex gap-3">
          <input
            name="name"
            placeholder="My property app"
            className="flex-1 rounded-lg border border-slate-300 px-3 py-2"
          />
          <Button>Create key</Button>
        </form>
      </Card>

      <Card>
        <CardTitle>Your keys</CardTitle>
        <div className="mt-4 overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b text-slate-500">
                <th className="py-2">Name</th>
                <th className="py-2">Prefix</th>
                <th className="py-2">Created</th>
                <th className="py-2">Status</th>
                <th className="py-2"></th>
              </tr>
            </thead>
            <tbody>
              {keys.map((key) => (
                <tr key={key.id} className="border-b last:border-0">
                  <td className="py-3 font-medium">{key.name}</td>
                  <td className="py-3 font-mono">{key.prefix}...</td>
                  <td className="py-3">{new Date(key.createdAt).toLocaleString()}</td>
                  <td className="py-3">
                    <Badge tone={key.revokedAt ? "danger" : "success"}>
                      {key.revokedAt ? "Revoked" : "Active"}
                    </Badge>
                  </td>
                  <td className="py-3 text-right">
                    {!key.revokedAt ? (
                      <form action="/api/keys/revoke" method="post">
                        <input type="hidden" name="id" value={key.id} />
                        <Button variant="danger">Revoke</Button>
                      </form>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {keys.length === 0 ? <p className="py-6 text-slate-500">No keys yet.</p> : null}
        </div>
      </Card>
    </div>
  );
}
```

This uses the Next.js 16 pattern where `searchParams` is a Promise even in Server Components: `const params = await searchParams;`.

---

## Checkpoint

- [ ] Creating a key shows the raw key exactly once, in a green success card.
- [ ] The keys table lists name, prefix, created date, and status.
- [ ] Revoking a key flips its badge to "Revoked" and removes the Revoke button.
- [ ] A revoked key's raw value (if you saved one earlier) no longer validates (we'll test this fully in Part 7-8).

---

## Troubleshooting

**Raw key shows up in the browser URL bar**
Acceptable for this tutorial, but not ideal for production — see Appendix C for a flash-storage or client-modal alternative.

**`smembers` result type looks like `unknown`**
The generic passed to `redis.smembers<string[]>` helps TypeScript, but always keep the `.filter(Boolean)` step as a runtime safety net.

**Revoked key still seems to validate**
Confirm `revokeApiKey` actually deletes `key_hash:{hash}` — that reverse-lookup deletion is what makes `validateApiKey` fail afterward.

---

Ready for **Part 6 — Fetching HDB Data from data.gov.sg**?
