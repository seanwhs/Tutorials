Let me pull Part 22 and check for its troubleshooting addendum.
Got both. This part is shorter (conceptual, intentionally lighter on code), so I can fit it in one message.
## Part 22 (Optional / Phase 2 Preview): Connecting Real Banks with Plaid

**Goal:** understand, conceptually and with a lightly-coded starting point, how automatic bank feeds work via Plaid — so you know exactly what comes after CSV import, even if you treat full implementation as a project you tackle after this course. This part is intentionally lighter on "type this exact code" than earlier parts, since Plaid requires a developer account, has real security/compliance considerations, and is explicitly Phase 2 in our project plan — not required to have a working, demoable app.

**Prerequisite:** Parts 1-21 completed. This part is optional — the core app is complete and fully functional without it.

---

### 1. What Plaid actually is, and why it's different from anything else we've used

Plaid is a service that sits between your app and thousands of banks, letting users securely connect their real bank account to your app without ever giving your app their actual bank username/password. When a user connects their bank through Plaid, your app receives a token representing that connection, and can then ask Plaid for that account's transactions on an ongoing basis — Plaid handles the messy reality of talking to thousands of different banks' own systems so you don't have to.

This is meaningfully different from everything else we've integrated: Clerk handles who's using your app, Neon stores your data, Inngest runs your background jobs — but Plaid involves a THIRD PARTY holding a live, ongoing connection to a user's real financial institution. That's a bigger trust and security responsibility than anything else in this course, which is exactly why real production use requires Plaid's approval process (not just an instant signup like Neon or Clerk).

### 2. The Plaid Link flow, conceptually

1. Your app asks Plaid for a "link token" (a short-lived token authorizing the next step)
2. Your app shows Plaid's own prebuilt UI component (called "Plaid Link") to the user — a secure popup where THEY log into their real bank directly with Plaid, never your servers
3. On success, Plaid gives your app a "public token"
4. Your server exchanges that public token for a permanent "access token" — THIS is the credential your app stores and uses going forward to fetch that account's data
5. Your app calls Plaid's transactions API periodically (perfect use case for an Inngest cron job, exactly like Part 20's pattern) to pull new transactions
6. Each fetched transaction gets inserted into your bank_transactions table — the exact same table and categorization flow you built in Part 21

This last point is worth emphasizing: the entire Part 21 categorization UI and journal-posting logic needs ZERO changes to support Plaid. Plaid just becomes a second, automated way of populating bank_transactions, alongside CSV upload. This is a great example of designing a data model around the underlying concept ("a bank transaction that needs categorizing") rather than around a specific data source.

### 3. Setting up a Plaid developer account (if you want to experiment)

1. Go to https://plaid.com and sign up for a free developer account
2. Plaid provides a "Sandbox" environment with fake banks and fake test credentials — completely free, no real bank connection required, perfect for learning the flow without any real financial data or compliance concerns
3. You'll get a client_id and a secret (sandbox-specific) — same "keep it in .env.local, never commit it" discipline as every other secret in this course

### 4. A minimal sandbox-only sketch (optional to actually build)

If you want to experiment, install Plaid's SDK: `npm install plaid react-plaid-link`

A minimal server-side setup, src/lib/plaid/client.ts:
```ts
import { Configuration, PlaidApi, PlaidEnvironments } from "plaid";

const configuration = new Configuration({
  basePath: PlaidEnvironments.sandbox,
  baseOptions: {
    headers: {
      "PLAID-CLIENT-ID": process.env.PLAID_CLIENT_ID!,
      "PLAID-SECRET": process.env.PLAID_SECRET!,
    },
  },
});

export const plaidClient = new PlaidApi(configuration);
```

A route to create a link token, src/app/api/plaid/create-link-token/route.ts, would call `plaidClient.linkTokenCreate({...})` and return it to the browser. The frontend would use Plaid's react-plaid-link package's `usePlaidLink` hook to open the Plaid Link popup with that token. On success, you'd send the resulting public_token to another route that calls `plaidClient.itemPublicTokenExchange({...})` to get a permanent access_token, which you'd store (encrypted, ideally) associated with that organization's bank connection.

We're intentionally not building this out fully line-by-line the way earlier parts did — the sandbox flow, error handling, and secure token storage involve enough real-world nuance that treating this as a guided exploration (using Plaid's own excellent quickstart docs alongside what you now understand conceptually) is more valuable than a rushed, incomplete implementation here.

### 5. Fetching transactions on a schedule (tying back to Part 20)

Once you have a stored access_token for a connection, an Inngest cron function (exactly like Part 20's pattern) would run nightly, call `plaidClient.transactionsSync({ access_token })`, and insert any new transactions into your existing bank_transactions table with status "uncategorized" — reusing 100% of Part 21's review/categorization UI without modification.

### 6. Why this course treats Plaid as optional rather than required

Three honest reasons: (1) it requires signing up for a third-party service with its own approval process for production use, (2) it introduces real security considerations (storing access tokens securely) beyond what we've needed so far, and (3) most importantly — your app is already fully functional and demoable without it, since Part 21's CSV import solves the same underlying problem (getting bank data into the system) in a way that works today, for any bank, with no external dependency. Treat this part as a roadmap for later, not a blocker.

---

### Troubleshooting

**Signing up for Plaid asks for business information you don't have yet**
For Sandbox-only experimentation (fake banks, no real data), Plaid's signup is still free and typically only asks for basic developer account details — you do not need a real company to explore the Sandbox environment.

**"Cannot find module 'plaid'" or 'react-plaid-link'**
Confirm you ran `npm install plaid react-plaid-link` if you chose to experiment with the code sketch — this part deliberately doesn't require these packages unless you're following the optional hands-on exploration.

**PLAID_CLIENT_ID / PLAID_SECRET environment variables are undefined**
Same discipline as every other secret in this course: add them to `.env.local`, never commit that file, and restart your dev server after adding new environment variables.

**Plaid Link popup never opens when testing the frontend flow**
This usually means the link token wasn't successfully created and passed to the usePlaidLink hook — check your browser's console for errors from the /api/plaid/create-link-token route, and confirm your Plaid client credentials are for the Sandbox environment specifically.

**You're unsure whether to actually build this part out or skip it**
Skip it for now unless you're specifically motivated to explore bank feed integration — the core app (Parts 1-21 plus 23-24) is fully complete, deployable, and demoable without any Plaid code at all.

**If you do build it out and get stuck on Plaid-specific API errors**
Plaid's own documentation and quickstart guides (docs.plaid.com) are excellent and up to date — their official docs will always be more current than anything fixed in this course's text.

---

### What's next

Part 23: Deploying to Vercel for FREE — we take everything built across Parts 1-21 (skipping Plaid, which stays local/optional) and put it on the real internet, using entirely free tiers across Vercel, Neon, Clerk, and Inngest, with no credit card required anywhere in the process.
