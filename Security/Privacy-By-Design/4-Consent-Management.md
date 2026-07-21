# Part 4: Consent Management & User Transparency

---

## 4.1 The Core Principle: Consent Must Be Freely Given, Specific, Informed, and Unambiguous

GDPR Article 4(11) defines valid consent using exactly those four adjectives, and each one rules out a common dark pattern engineers accidentally (or deliberately) ship:

| Requirement | Dark Pattern It Rules Out | Analogy |
|---|---|---|
| **Freely given** | Making "Reject" harder to find/click than "Accept" | A restaurant where saying "no thanks" to dessert requires walking to the kitchen, but saying "yes" just requires a nod |
| **Specific** | One giant "I agree" checkbox covering five unrelated purposes | Signing one blanket form that authorizes a doctor, a dentist, and a gym membership all at once |
| **Informed** | Legal jargon or hidden toggles the user never actually reads | A contract in 6pt font nobody can physically read before signing |
| **Unambiguous** | Pre-checked boxes, or "continuing to browse = consent" | Assuming someone agreed to a night out because they didn't explicitly say no when the invitation was mentioned in passing |

**Analogy for the whole system we're about to build:** Think of a restaurant's dietary preference card, not its terms-and-conditions menu insert. A good dietary card asks clearly, separately, and without judgment: "Any allergies? Vegetarian? Vegan?" — each a clean yes/no, none pre-filled, none worded to guilt you into checking "yes" to everything. A bad one buries "we may also share your dietary data with our marketing partners" inside eight paragraphs of legal text with the checkbox pre-ticked. We are building the dietary card, not the fine print.

---

## 4.2 The Target: The Anti-Dark-Pattern Consent Banner

**The Concept:** Our consent banner must present each purpose from `consentPurposeEnum` (Part 2) as its own independent, equally-weighted toggle — no purpose defaults to "on," no button is visually larger or more colorful than its opposite, and no purpose is bundled with another.

### The Implementation

**Step 1 — Define the purpose metadata (the "informed" requirement, made concrete)**

**File: `src/lib/consent/purposes.ts`**
```typescript
/**
 * The single source of truth for what each consent purpose actually means
 * in plain language. This object is rendered directly in the UI — there is
 * no separate "legal copy" maintained elsewhere that could drift out of
 * sync with what the toggle actually controls. Every purpose here MUST
 * already exist in schema.ts's consentPurposeEnum (Part 2) — adding one
 * here without a matching enum value is a compile-time/migration mismatch,
 * by design, so the two can never silently diverge.
 */
export const CONSENT_PURPOSES = [
  {
    key: "product_analytics" as const,
    label: "Product Analytics",
    description:
      "Allow anonymized usage patterns (e.g., which screens you visit) to help us improve MindfulLog. Never includes your journal or mood content.",
  },
  {
    key: "therapist_data_sharing" as const,
    label: "Share Trends With My Therapist",
    description:
      "Allow a therapist you've explicitly connected to view your mood score trends over time. Never includes your private journal text.",
  },
  {
    key: "marketing_emails" as const,
    label: "Marketing Emails",
    description:
      "Receive occasional emails about new features or wellness tips. Unrelated to your account's core function.",
  },
] as const;

export type ConsentPurposeKey = (typeof CONSENT_PURPOSES)[number]["key"];
```

**Step 2 — Build the Server Action that records a consent decision**

This is the most important function in this Part: it must **never** perform an `UPDATE`. Per Part 2's design, `consent_records` is append-only — every decision is a new row, preserving full history (Principle 6: Visibility and Transparency).

**File: `src/app/actions/consent.ts`**
```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/db";
import { consentRecords, users } from "@/db/schema";
import { eq, desc } from "drizzle-orm";
import { ConsentPurposeKey } from "@/lib/consent/purposes";
import { inngest } from "@/inngest/client";
import { revalidatePath } from "next/cache";

async function getInternalUserId(): Promise<string> {
  const { userId: clerkUserId } = await auth();
  if (!clerkUserId) throw new Error("Not authenticated.");

  const existing = await db.query.users.findFirst({
    where: eq(users.clerkUserId, clerkUserId),
  });
  if (existing) return existing.id;

  const [created] = await db
    .insert(users)
    .values({ clerkUserId })
    .returning({ id: users.id });
  return created.id;
}

/**
 * Records ONE consent decision for ONE purpose. This function NEVER
 * updates an existing row — it always INSERTs a new one. The "current"
 * state of a user's consent is therefore always derived by finding the
 * MOST RECENT row per purpose (see getConsentState below), not by reading
 * a single mutable flag. This design is what makes the ledger an actual
 * audit trail rather than just a settings table with extra steps.
 */
export async function recordConsentDecision(
  purpose: ConsentPurposeKey,
  granted: boolean
): Promise<void> {
  const userId = await getInternalUserId();

  await db.insert(consentRecords).values({
    userId,
    purpose,
    granted, // explicit every time — there is no schema-level DEFAULT to
             // lean on here, because every insert must state its intent
             // clearly, satisfying the "unambiguous" requirement in code.
  });

  // Fan out the new consent state to any other service that needs to know
  // (e.g., an email service that should stop sending marketing emails the
  // instant consent is withdrawn — built out in Section 4.4 below). We
  // send ONLY the purpose, the decision, and the pseudonymous user ID —
  // never any other user data — because this event travels through a
  // third-party system (Inngest), per our Part 1 DPIA data-flow rules.
  await inngest.send({
    name: "consent/updated",
    data: { userId, purpose, granted },
  });

  revalidatePath("/dashboard/settings/privacy");
}

/**
 * Derives the CURRENT consent state per purpose by finding the most recent
 * row for each purpose. This is intentionally computed at read-time rather
 * than cached in a separate mutable column — a subtle but important
 * decision: it guarantees the "current state" view can NEVER drift out of
 * sync with the ledger itself, because they are, structurally, the same
 * data.
 */
export async function getConsentState(): Promise<
  Record<ConsentPurposeKey, boolean>
> {
  const userId = await getInternalUserId();

  const allRecords = await db.query.consentRecords.findMany({
    where: eq(consentRecords.userId, userId),
    orderBy: desc(consentRecords.recordedAt),
  });

  const state = {
    product_analytics: false,
    therapist_data_sharing: false,
    marketing_emails: false,
  } as Record<ConsentPurposeKey, boolean>;

  // Because records are ordered newest-first, the FIRST time we see a
  // given purpose in this loop is guaranteed to be its most recent
  // decision — so we simply skip any purpose we've already resolved.
  const resolved = new Set<string>();
  for (const record of allRecords) {
    if (resolved.has(record.purpose)) continue;
    state[record.purpose as ConsentPurposeKey] = record.granted;
    resolved.add(record.purpose);
  }

  // Anything never explicitly decided remains `false` — Principle 2,
  // Privacy as the Default Setting, applied at the read layer too: silence
  // is never interpreted as consent.
  return state;
}
```

**Step 3 — Build the banner UI itself**

**File: `src/app/dashboard/settings/privacy/page.tsx`**
```typescript
import { getConsentState, recordConsentDecision } from "@/app/actions/consent";
import { CONSENT_PURPOSES } from "@/lib/consent/purposes";

export default async function PrivacySettingsPage() {
  const state = await getConsentState();

  return (
    <main className="mx-auto max-w-xl p-8">
      <h1 className="mb-2 text-2xl font-bold text-slate-800">
        Privacy Preferences
      </h1>
      <p className="mb-6 text-sm text-slate-500">
        Every preference below is off unless you explicitly turn it on.
        You can change any of these at any time — changes take effect
        immediately.
      </p>

      <div className="flex flex-col gap-6">
        {CONSENT_PURPOSES.map((purpose) => {
          const isGranted = state[purpose.key];

          return (
            <div
              key={purpose.key}
              className="rounded-lg border border-slate-200 p-4"
            >
              <div className="mb-2 flex items-start justify-between gap-4">
                <div>
                  <h2 className="font-semibold text-slate-800">
                    {purpose.label}
                  </h2>
                  <p className="mt-1 text-sm text-slate-500">
                    {purpose.description}
                  </p>
                </div>
              </div>

              {/*
                CRITICAL DESIGN DECISION: both buttons below share IDENTICAL
                Tailwind classes for size, padding, and font-weight
                (`px-4 py-2 font-semibold rounded-lg`). The ONLY visual
                difference is color, applied EQUALLY prominently to both —
                a filled dark button for whichever state is CURRENTLY
                active, and an outlined button of equal size for the
                inactive state. Neither option is bigger, bolder, or
                positioned to be an "accidental default click" — this is
                the "freely given" and "unambiguous" requirements made
                literally visible in the markup itself.
              */}
              <div className="flex gap-3">
                <form
                  action={async () => {
                    "use server";
                    await recordConsentDecision(purpose.key, true);
                  }}
                >
                  <button
                    type="submit"
                    className={`rounded-lg px-4 py-2 font-semibold ${
                      isGranted
                        ? "bg-slate-800 text-white"
                        : "border border-slate-300 text-slate-600 hover:bg-slate-50"
                    }`}
                  >
                    Allow
                  </button>
                </form>

                <form
                  action={async () => {
                    "use server";
                    await recordConsentDecision(purpose.key, false);
                  }}
                >
                  <button
                    type="submit"
                    className={`rounded-lg px-4 py-2 font-semibold ${
                      !isGranted
                        ? "bg-slate-800 text-white"
                        : "border border-slate-300 text-slate-600 hover:bg-slate-50"
                    }`}
                  >
                    Don&apos;t Allow
                  </button>
                </form>
              </div>
            </div>
          );
        })}
      </div>
    </main>
  );
}
```

### The Verification

**Step 1 — Confirm defaults are correctly restrictive on first visit**

Sign up as a brand-new test user and visit `/dashboard/settings/privacy` before touching anything. Every toggle should render with **"Don't Allow"** shown as the currently-active (dark, filled) button, and **"Allow"** shown in its unselected (outlined) state — confirming that with zero consent records in the database, `getConsentState()` correctly defaults every purpose to `false`, and the UI correctly reflects that as the active choice rather than leaving both buttons looking neutral/ambiguous.

**Step 2 — Confirm the ledger is genuinely append-only, not update-in-place**

```sql
-- Run in Neon's SQL console after clicking "Allow" then "Don't Allow" on
-- the same purpose, in that order, for one test user.
SELECT purpose, granted, recorded_at
FROM consent_records
WHERE user_id = (SELECT id FROM users WHERE clerk_user_id = 'YOUR_TEST_CLERK_ID')
ORDER BY recorded_at ASC;
```
Expected output: **two rows**, not one — the first with `granted = true`, the second with `granted = false`, each with its own distinct `recorded_at` timestamp. If you only see one row, something in your code is updating instead of inserting, and the audit trail is broken. This two-row result is your proof that a regulator or auditor could reconstruct the complete history of this user's decision, not just its current state.

**Step 3 — Confirm visual symmetry programmatically (not just "by eye")**

Open your browser's DevTools on the privacy settings page, right-click the "Allow" button → **Inspect**, and note its computed `padding`, `font-weight`, and `border-radius`. Do the same for "Don't Allow." All three values must be identical between the two buttons — the only CSS difference permitted is background/border color. This is a simple but genuinely important verification step: it's how you catch an accidental dark pattern (e.g., someone later "helpfully" making the Allow button slightly bigger to "improve conversion") before it ships.

**Step 4 — Confirm the current-state view can never silently diverge from the ledger**

```sql
-- Manually insert a THIRD, contradictory-looking row directly in SQL,
-- simulating what a background migration or admin tool might do:
INSERT INTO consent_records (id, user_id, purpose, granted, recorded_at)
VALUES (
  gen_random_uuid(),
  (SELECT id FROM users WHERE clerk_user_id = 'YOUR_TEST_CLERK_ID'),
  'product_analytics',
  true,
  now()
);
```
Reload `/dashboard/settings/privacy` in the browser. The "Product Analytics" toggle should now show **"Allow"** as active, because `getConsentState()` always derives current state from the most recent row — proving there is no separate, cacheable "current consent" column anywhere that could have drifted out of sync with this new row.

---

## 4.3 The Target: Auditable Consent Retrieval (Extending Reference 3.A's Pattern)

**The Concept:** Recall Reference 3.A from Part 3: any "break glass" cross-user data access should be logged. Consent decisions deserve the same treatment in reverse — we need a way for a user (or an auditor acting on their behalf during a legal dispute) to retrieve the **complete, provable history** of every consent decision ever made, with no gaps and no ambiguity about ordering. This is distinct from the *current-state* view built in 4.2 — this is the full historical ledger.

### The Implementation

**File: `src/app/actions/consent.ts`** (add this new exported function)
```typescript
/**
 * Returns the FULL historical consent ledger for the current user — every
 * decision ever recorded, in chronological order, with no rows omitted or
 * collapsed. This is the artifact a user or auditor would need to prove
 * "on this exact date, this exact preference was in this exact state,"
 * satisfying Principle 6 (Visibility and Transparency) and GDPR's burden-
 * of-proof requirement that a controller must be able to DEMONSTRATE
 * consent was given, not merely assert it.
 */
export async function getFullConsentLedger(): Promise<
  Array<{ purpose: string; granted: boolean; recordedAt: Date }>
> {
  const userId = await getInternalUserId();

  const allRecords = await db.query.consentRecords.findMany({
    where: eq(consentRecords.userId, userId),
    orderBy: desc(consentRecords.recordedAt),
  });

  return allRecords.map((r) => ({
    purpose: r.purpose,
    granted: r.granted,
    recordedAt: r.recordedAt,
  }));
}
```

**File: `src/app/dashboard/settings/privacy/history/page.tsx`**
```typescript
import { getFullConsentLedger } from "@/app/actions/consent";
import { CONSENT_PURPOSES } from "@/lib/consent/purposes";

export default async function ConsentHistoryPage() {
  const ledger = await getFullConsentLedger();

  const labelFor = (purposeKey: string) =>
    CONSENT_PURPOSES.find((p) => p.key === purposeKey)?.label ?? purposeKey;

  return (
    <main className="mx-auto max-w-xl p-8">
      <h1 className="mb-4 text-2xl font-bold text-slate-800">
        Your Consent History
      </h1>
      <p className="mb-6 text-sm text-slate-500">
        This is a complete, permanent record of every privacy decision
        you&apos;ve made on this account. Nothing here can be edited or
        removed, including by us.
      </p>

      <ul className="flex flex-col gap-3">
        {ledger.map((entry, idx) => (
          <li
            key={idx}
            className="flex items-center justify-between rounded-lg border border-slate-200 p-3 text-sm"
          >
            <span className="font-medium text-slate-700">
              {labelFor(entry.purpose)}
            </span>
            <span
              className={
                entry.granted ? "text-emerald-600" : "text-slate-500"
              }
            >
              {entry.granted ? "Allowed" : "Not Allowed"}
            </span>
            <span className="text-xs text-slate-400">
              {entry.recordedAt.toLocaleString()}
            </span>
          </li>
        ))}
      </ul>
    </main>
  );
}
```

### The Verification

Navigate to `/dashboard/settings/privacy/history` after performing the toggles from Section 4.2's verification steps. You should see every single decision listed — including the manually-inserted SQL row from Step 4 — in reverse chronological order, with no rows missing and no rows merged together. Count the rows in the UI and compare against `SELECT count(*) FROM consent_records WHERE user_id = ...` — the numbers must match exactly.

---

## 4.4 The Target: Synchronizing Consent State Across Services via Inngest

**The Concept:** MindfulLog isn't just one database table — a real system has multiple independent services that each need to *react* to a consent change: an email service that must immediately stop sending marketing emails, an analytics pipeline that must immediately stop recording events, a therapist-sharing feature that must immediately cut off access. Recall from Part 0's architecture diagram: this is exactly the "fire alarm every floor hears at once" pattern. We already fired the event in Section 4.2 (`inngest.send({ name: "consent/updated", ... })`) — now we build the listener.

**Why this matters even in a single-database app:** Even if MindfulLog today only has one Postgres database, treating consent propagation as an *event*, not a direct function call, means adding a fourth downstream consumer later (e.g., a new analytics vendor) requires writing one new Inngest function — zero changes to the consent-recording code itself. This is the same "one fire alarm, many listeners" decoupling that lets real companies add/remove data-sharing integrations without ever touching their core consent logic.

### The Implementation

**File: `src/inngest/functions/sync-marketing-consent.ts`**
```typescript
import { inngest } from "@/inngest/client";
import { db } from "@/db";
import { users } from "@/db/schema";
import { eq } from "drizzle-orm";

/**
 * Listens for consent/updated events specifically about marketing emails,
 * and immediately reflects that decision in a hypothetical downstream
 * marketing platform. In a real system this might call Mailchimp's or
 * Customer.io's API to unsubscribe a contact; here we simulate that call
 * with a clearly-labeled stub so the PATTERN is complete and testable,
 * without requiring a real third-party marketing account for this series.
 */
export const syncMarketingConsent = inngest.createFunction(
  { id: "sync-marketing-consent" },
  { event: "consent/updated" },
  async ({ event, step }) => {
    // Only react to the purpose this function cares about — other
    // purposes (analytics, therapist-sharing) are ignored here and would
    // be handled by their OWN dedicated Inngest functions, keeping each
    // downstream integration's logic isolated and independently testable.
    if (event.data.purpose !== "marketing_emails") {
      return { skipped: true, reason: "not a marketing_emails event" };
    }

    const { userId, granted } = event.data;

    // step.run gives us a durable checkpoint: if the downstream API call
    // fails (network blip, vendor outage), Inngest retries THIS step only,
    // without re-evaluating the whole function from scratch.
    await step.run("update-marketing-platform-subscription", async () => {
      const user = await db.query.users.findFirst({
        where: eq(users.id, userId),
      });
      if (!user) return; // user may have been deleted between event and processing

      // --- Real integration would go here, e.g.: ---
      // await mailchimpClient.updateSubscriberStatus(user.clerkUserId, granted);
      // For this series, we log clearly instead of requiring a live vendor
      // account, so the pattern remains 100% runnable by any reader.
      console.log(
        `[sync-marketing-consent] Would set marketing subscription for user ${userId} to: ${granted}`
      );
    });

    return { userId, granted, processed: true };
  }
);
```

**File: `src/app/api/inngest/route.ts`** (update — register the new function)
```typescript
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { securityEventTtlSweep } from "@/inngest/functions/security-event-ttl-sweep";
import { syncMarketingConsent } from "@/inngest/functions/sync-marketing-consent";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    securityEventTtlSweep,
    syncMarketingConsent, // Part 4: propagates consent decisions to downstream services
  ],
});
```

### The Verification

**Step 1 — Trigger and observe in the local Inngest Dev Server**

```bash
npx inngest-cli@latest dev
```
With the dev server and `npm run dev` both running, go to `/dashboard/settings/privacy` and toggle "Marketing Emails" to **Allow**. Then visit `http://localhost:8288`, open the **Runs** tab, and find the most recent invocation of `sync-marketing-consent`. Confirm:
- Its input event shows `purpose: "marketing_emails", granted: true`.
- Its step `update-marketing-platform-subscription` completed successfully.
- Your terminal running `npm run dev` printed the `console.log` line confirming the simulated vendor call happened.

**Step 2 — Confirm irrelevant purposes are correctly ignored**

Toggle "Product Analytics" instead. Check the Inngest dashboard again — you should see a **new** run of `sync-marketing-consent` triggered (because it's subscribed to the entire `consent/updated` event, regardless of purpose), but its output should show `{ "skipped": true, "reason": "not a marketing_emails event" }`, and your terminal should **not** print the marketing-vendor log line. This confirms the function correctly filters by purpose rather than blindly reacting to every consent event — an important distinction once you have multiple purpose-specific listeners all subscribed to the same event stream.

**Step 3 — Confirm retry durability (simulating a downstream outage)**

Temporarily edit `sync-marketing-consent.ts` to force a failure:
```typescript
await step.run("update-marketing-platform-subscription", async () => {
  throw new Error("Simulated vendor outage");
});
```
Toggle "Marketing Emails" again and observe the Inngest dashboard — the run should show a **failed** step, followed by automatic **retry attempts** with increasing backoff, visible directly in the UI's run timeline. This is the concrete proof of the "reliable back-office clerk" analogy from Part 0: a naive `fetch()` call in your Server Action would have silently failed and lost the update forever; Inngest instead surfaces the failure and keeps retrying. **Revert this temporary change** before continuing.

---

## Part 4 — Reference Section: Deep Dives

*(Read now for depth, or skip ahead to Part 5 and return later.)*

### Reference 4.A — Why "Reject All" Must Be a First-Class Button, Not a Buried Link

Many real-world consent banners technically offer a way to decline, but bury it as a small text link ("manage preferences") beneath a large, colorful "Accept All" button. Regulators in the EU (and increasingly the FTC in the US, under unfair/deceptive practices authority) have explicitly flagged this pattern as **not** freely given consent, because the *effort asymmetry* itself constitutes coercion — even without literally lying to the user. Our design in Section 4.2 sidesteps this entirely by not having a single "Accept All" concept at all: every purpose is independently presented, independently toggled, with structurally identical UI weight. There is no "path of least resistance" toward broader data sharing, because no such path exists in the component tree.

### Reference 4.B — Consent vs. Legitimate Interest vs. Contractual Necessity

Not everything in MindfulLog needs a consent toggle — recall from Part 1's DPIA (Section 6, Legal Basis) that account email/auth relies on **contractual necessity**, not consent, because the product cannot function without it. A common engineering mistake is building a consent toggle for something that is actually contractually necessary — this seems "extra safe," but it's actually a UX and legal anti-pattern: if a user can toggle something "off" that the product cannot function without, either the toggle is fake (a dark pattern — appearing to give control that doesn't exist) or toggling it off should functionally break/close the account. The engineering lesson: **before adding a consent toggle for any field, check the DPIA's Legal Basis section first.** If the basis is contract or legitimate interest, it does not belong in the consent ledger at all — it belongs in your Terms of Service, disclosed clearly, but not gated behind an on/off switch that implies false optionality.

### Reference 4.C — Handling Consent Withdrawal Mid-Session

GDPR Article 7(3) requires withdrawing consent to be **as easy as giving it**. Our architecture satisfies this almost for free: because `recordConsentDecision` is the exact same function call regardless of direction (`granted: true` or `granted: false`), and the UI in Section 4.2 presents both directions with identical prominence, there is no "harder path" to withdraw versus grant. The one subtlety worth flagging: withdrawal should take effect **going forward**, not retroactively re-authorize past processing that already legally occurred under a prior valid consent — which is exactly why our ledger is append-only rather than mutable. A user withdrawing `therapist_data_sharing` today does not retroactively make yesterday's already-shared mood trend illegal; it simply means no *further* sharing happens starting now. This is a legal nuance that naturally falls out of our data model rather than requiring special-cased logic.

### Reference 4.D — Scaling This Pattern: Adding a Fourth Consent Purpose

To prove the architecture's decoupling claim from Section 4.4, trace through what adding a new purpose (e.g., `"research_data_sharing"`) would actually require:
1. Add `"research_data_sharing"` to `consentPurposeEnum` in `schema.ts` (Part 2) → generate and run a migration.
2. Add a corresponding entry to `CONSENT_PURPOSES` in `src/lib/consent/purposes.ts` with clear plain-language copy.
3. Update the DPIA's Data Inventory/Legal Basis tables (Part 1, Section 1.5's binding rule) to justify the new purpose.
4. If a downstream service needs to react to this specific purpose, write ONE new Inngest function subscribed to `consent/updated`, filtering on `event.data.purpose === "research_data_sharing"` — following the exact pattern in `sync-marketing-consent.ts`.

Notice step 4 requires **zero changes** to `recordConsentDecision`, the UI banner component, or any existing Inngest function. This is the concrete payoff of the event-driven design: the system grows by *addition*, not by modifying already-tested, already-shipped code paths.

---

## Part 4 — Summary & What Carries Forward

By completing Part 4, your repository now contains:

- ✅ `src/lib/consent/purposes.ts` — the single source of truth for consent purpose copy, kept in sync with `schema.ts`'s enum
- ✅ `src/app/actions/consent.ts` — `recordConsentDecision`, `getConsentState`, and `getFullConsentLedger`, all built on a strictly append-only ledger
- ✅ A fully symmetric, anti-dark-pattern consent settings UI at `/dashboard/settings/privacy`
- ✅ A complete, auditable consent history view at `/dashboard/settings/privacy/history`
- ✅ `src/inngest/functions/sync-marketing-consent.ts` — a durable, retry-safe consumer of consent-change events, registered alongside Part 2's TTL sweep

**What Part 5 inherits from here, directly:** the `consent_records` ledger and `getFullConsentLedger()` function built here become **one of the core data sources** in the DSAR export engine — when a user requests "everything you know about me," their complete consent history is a legally required section of that export. Additionally, the event-driven pattern established in Section 4.4 (`inngest.send` + a dedicated listener function) is the exact same pattern Part 5 uses for the deletion cascade — a `user.deletion.requested` event, with each downstream system (Postgres tables, Clerk's identity record) implemented as its own durable step.

**Quick self-check before moving on:**
1. Can I explain why `consent_records` is append-only, and what legal requirement that satisfies?
2. Did my two-row SQL check in Section 4.2 Step 2 confirm no `UPDATE` is ever happening?
3. Can I identify, from the DPIA, one field in MindfulLog that should **not** have a consent toggle, and explain why (Reference 4.B)?
4. Do I understand why `sync-marketing-consent` filters on `event.data.purpose` rather than having three separate events fired?
