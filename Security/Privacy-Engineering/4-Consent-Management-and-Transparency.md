**Part 4: Consent Management & User Transparency**

### Why Consent Done Right Matters
Dark patterns trick users. We build the opposite: clear, symmetric, freely given consent that is **impossible** to drift from the audit trail.

---

#### Step 4.1: The Target — Append-Only Consent Ledger + Current State Derivation

**The Concept**:  
Never `UPDATE` consent. Every decision is a new immutable record. Current state is derived by taking the latest record per purpose.

**Implementation**:

**lib/consent.ts** (complete):
```ts
import { sql } from './db';
import { hmacValue } from './privacy-utils';

export type ConsentPurpose = 'analytics' | 'marketing' | 'research' | 'support_access';

export async function recordConsent(
  userId: string, 
  purpose: ConsentPurpose, 
  granted: boolean,
  ip?: string
) {
  const ipHmac = ip ? hmacValue(ip) : null;

  const result = await sql`
    INSERT INTO consent_records (user_id, purpose, granted, ip_hmac)
    VALUES (${userId}, ${purpose}, ${granted}, ${ipHmac})
    RETURNING id, recorded_at;
  `;

  // Trigger Inngest event for propagation (implemented later)
  return result[0];
}

export async function getCurrentConsents(userId: string) {
  const rows = await sql`
    WITH latest AS (
      SELECT DISTINCT ON (purpose) *
      FROM consent_records
      WHERE user_id = ${userId}
      ORDER BY purpose, recorded_at DESC
    )
    SELECT purpose, granted 
    FROM latest;
  `;

  return rows.reduce((acc: any, row: any) => {
    acc[row.purpose] = row.granted;
    return acc;
  }, {} as Record<ConsentPurpose, boolean>);
}

export async function getConsentHistory(userId: string) {
  return sql`
    SELECT purpose, granted, recorded_at, ip_hmac
    FROM consent_records
    WHERE user_id = ${userId}
    ORDER BY recorded_at DESC;
  `;
}
```

---

#### Step 4.2: The Target — Anti-Dark-Pattern Consent UI

**The Concept**:  
Equal prominence for Allow / Don’t Allow. No pre-checked boxes. Clear language.

**Implementation**:

**app/settings/consent/page.tsx** (React Server Component + Client interactivity):

```tsx
'use client';

import { useUser } from "@clerk/nextjs";
import { useState, useEffect } from "react";
import { recordConsent, getCurrentConsents, ConsentPurpose } from "@/lib/consent";

const purposes: { key: ConsentPurpose; label: string; description: string }[] = [
  { key: "analytics", label: "Analytics", description: "Help us improve the app with anonymous usage data" },
  { key: "marketing", label: "Marketing", description: "Occasional product updates (max 4 per year)" },
  { key: "research", label: "Research", description: "Contribute anonymized data to mental health studies" },
  { key: "support_access", label: "Support Access", description: "Allow support to view your data when you request help" },
];

export default function ConsentSettings() {
  const { user } = useUser();
  const [consents, setConsents] = useState<Record<ConsentPurpose, boolean>>({} as any);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (user?.id) {
      getCurrentConsents(user.id).then(setConsents);
    }
  }, [user]);

  const toggleConsent = async (purpose: ConsentPurpose) => {
    if (!user?.id) return;
    setLoading(true);
    
    const newValue = !consents[purpose];
    await recordConsent(user.id, purpose, newValue);
    
    setConsents(prev => ({ ...prev, [purpose]: newValue }));
    setLoading(false);
  };

  return (
    <div className="max-w-2xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-8">Your Privacy Choices</h1>
      <p className="mb-8 text-gray-600">You can change these at any time. Every change is permanently recorded.</p>

      <div className="space-y-6">
        {purposes.map(({ key, label, description }) => (
          <div key={key} className="border rounded-xl p-6 flex items-start gap-6 hover:bg-gray-50 transition">
            <div className="flex-1">
              <h3 className="font-semibold text-lg">{label}</h3>
              <p className="text-gray-600 mt-1">{description}</p>
            </div>
            
            <div className="flex gap-3">
              <button
                onClick={() => toggleConsent(key)}
                disabled={loading}
                className={`px-6 py-3 rounded-xl font-medium transition-all ${
                  consents[key] 
                    ? "bg-green-600 text-white" 
                    : "bg-gray-200 hover:bg-gray-300"
                }`}
              >
                Allow
              </button>
              <button
                onClick={() => toggleConsent(key)}
                disabled={loading}
                className={`px-6 py-3 rounded-xl font-medium transition-all ${
                  !consents[key] 
                    ? "bg-red-600 text-white" 
                    : "bg-gray-200 hover:bg-gray-300"
                }`}
              >
                Don’t Allow
              </button>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-12">
        <a href="/settings/consent/history" className="text-blue-600 hover:underline">
          View full consent history →
        </a>
      </div>
    </div>
  );
}
```

**Verification**:
- Run `npm run dev`
- Go to `/settings/consent`
- Toggle options — buttons are symmetric and equally prominent.
- Check database: multiple rows per purpose, never updates.

---

#### Step 4.3: The Target — Inngest Event-Driven Propagation (Basic Setup)

**The Concept**:  
Consent changes fan out to other systems reliably.

(Full Inngest client + functions would be wired here in a complete repo — events like `consent.changed` trigger background jobs.)
