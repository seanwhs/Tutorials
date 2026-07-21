# Part 4: Consent Management & User Transparency

---

### Why Consent Management Is So Important
Traditional consent is often a single vague checkbox. We do the opposite: **granular, transparent, and immutable**. Every decision is recorded forever in an append-only ledger. This makes compliance easy and gives users real trust.

---

#### Step 4.1: The Target — Append-Only Consent Ledger Functions

**The Concept**:  
Instead of updating a row when the user changes consent, we add a new row every time. The current state is calculated by looking at the most recent record per purpose.

**Implementation**:

Create **`lib/consent.ts`**:

```ts
import { sql } from './db';
import { hmacValue } from './privacy-utils';

export type ConsentPurpose = 
  | 'analytics' 
  | 'marketing' 
  | 'research' 
  | 'support_access';

export async function recordConsent(
  userId: string,
  purpose: ConsentPurpose,
  granted: boolean,
  ipAddress?: string
) {
  const ipHmac = ipAddress ? hmacValue(ipAddress) : null;

  const result = await sql`
    INSERT INTO consent_records (user_id, purpose, granted, ip_hmac)
    VALUES (${userId}, ${purpose}, ${granted}, ${ipHmac})
    RETURNING id, recorded_at;
  `;

  console.log(`✅ Consent recorded for ${purpose}: ${granted}`);
  return result[0];
}

export async function getCurrentConsents(userId: string) {
  const rows = await sql`
    WITH latest_consents AS (
      SELECT DISTINCT ON (purpose) purpose, granted
      FROM consent_records
      WHERE user_id = ${userId}
      ORDER BY purpose, recorded_at DESC
    )
    SELECT * FROM latest_consents;
  `;

  const consents: Record<ConsentPurpose, boolean> = {
    analytics: false,
    marketing: false,
    research: false,
    support_access: false,
  };

  rows.forEach((row: any) => {
    consents[row.purpose as ConsentPurpose] = row.granted;
  });

  return consents;
}

export async function getFullConsentHistory(userId: string) {
  return await sql`
    SELECT id, purpose, granted, recorded_at, ip_hmac
    FROM consent_records
    WHERE user_id = ${userId}
    ORDER BY recorded_at DESC;
  `;
}
```

---

#### Step 4.2: The Target — Anti-Dark-Pattern Consent UI Page

**The Concept**:  
Buttons for "Allow" and "Don’t Allow" are the same size and prominence. No pre-checked boxes. Clear descriptions.

**Implementation**:

Create folder **`app/settings/consent`** and file **`page.tsx`**:

```tsx
'use client';

import { useUser } from "@clerk/nextjs";
import { useState, useEffect } from "react";
import { recordConsent, getCurrentConsents, ConsentPurpose } from "@/lib/consent";

const purposes = [
  { 
    key: "analytics" as ConsentPurpose, 
    label: "Analytics & Improvement", 
    description: "Anonymous usage data to help us make MindfulLog better." 
  },
  { 
    key: "marketing" as ConsentPurpose, 
    label: "Product Updates", 
    description: "Occasional emails about new features (maximum 4 per year)." 
  },
  { 
    key: "research" as ConsentPurpose, 
    label: "Mental Health Research", 
    description: "Contribute fully anonymized data to scientific studies." 
  },
  { 
    key: "support_access" as ConsentPurpose, 
    label: "Customer Support Access", 
    description: "Allow support team to view your data when you request help." 
  },
];

export default function ConsentPage() {
  const { user } = useUser();
  const [currentConsents, setCurrentConsents] = useState<Record<ConsentPurpose, boolean>>({
    analytics: false, marketing: false, research: false, support_access: false
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (user?.id) {
      getCurrentConsents(user.id).then(setCurrentConsents);
    }
  }, [user]);

  const toggleConsent = async (purpose: ConsentPurpose) => {
    if (!user?.id) return;
    setLoading(true);

    const newValue = !currentConsents[purpose];
    await recordConsent(user.id, purpose, newValue);
    
    setCurrentConsents(prev => ({ ...prev, [purpose]: newValue }));
    setLoading(false);
  };

  return (
    <div className="max-w-3xl mx-auto py-12 px-6">
      <h1 className="text-4xl font-bold mb-4">Your Privacy Choices</h1>
      <p className="text-lg text-gray-600 mb-10">
        You control exactly how your data is used. Every change is permanently recorded.
      </p>

      <div className="space-y-8">
        {purposes.map(({ key, label, description }) => (
          <div key={key} className="border border-gray-200 rounded-2xl p-8 hover:border-blue-200 transition-all">
            <div className="flex justify-between items-start gap-8">
              <div className="flex-1">
                <h3 className="text-xl font-semibold mb-2">{label}</h3>
                <p className="text-gray-600 leading-relaxed">{description}</p>
              </div>

              <div className="flex gap-4 flex-shrink-0">
                <button
                  onClick={() => toggleConsent(key)}
                  disabled={loading}
                  className={`px-8 py-4 rounded-2xl font-semibold text-sm transition-all ${
                    currentConsents[key]
                      ? "bg-green-600 text-white shadow-md"
                      : "bg-gray-100 hover:bg-gray-200 text-gray-700"
                  }`}
                >
                  Allow
                </button>

                <button
                  onClick={() => toggleConsent(key)}
                  disabled={loading}
                  className={`px-8 py-4 rounded-2xl font-semibold text-sm transition-all ${
                    !currentConsents[key]
                      ? "bg-red-600 text-white shadow-md"
                      : "bg-gray-100 hover:bg-gray-200 text-gray-700"
                  }`}
                >
                  Don’t Allow
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-12 text-center">
        <a href="/settings/consent/history" className="text-blue-600 hover:underline text-sm">
          View complete consent history →
        </a>
      </div>
    </div>
  );
}
```

---

**Part 4 Complete!**

You now have a beautiful, ethical consent system with full auditability.

You're building something truly special. Keep going!
