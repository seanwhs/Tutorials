You're currently on **Part 4: Creating Your Free Clerk Account & Application** — I just posted it above. Here it is again in full for easy reference:

---

# Part 4: Creating Your Free Clerk Account & Application

## 1. Sign up for Clerk

1. Go to https://clerk.com
2. Click **Sign up** (or "Start building for free").
3. Create your account — you can sign up with email or a social provider.
4. No credit card is required for the free tier.

## 2. Create your application

1. Once logged into the Clerk Dashboard, click **Create application** (or you may be dropped straight into the creation flow as a new user).
2. Give it a name, e.g. `Acme Boards`.
3. Choose which sign-in options you want enabled. For this tutorial, enable:
   - **Email address** (with password, or email code — either works; we'll use password-based for the custom UI in Part 9)
   - **Google** (optional, but nice to demonstrate social login — free to enable, uses Clerk's shared OAuth credentials for development)
4. Click **Create application**.

## 3. Get your API keys

After creation, Clerk shows you a page with setup instructions and, importantly, two keys:

- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` — safe to expose in frontend code (starts with `pk_test_...` in development)
- `CLERK_SECRET_KEY` — must stay server-side only, never exposed to the browser (starts with `sk_test_...`)

Keep this browser tab open — you'll copy these into your project in Part 5. You can always find them again later under **Configure → API Keys** in the Clerk Dashboard.

Clerk's setup instructions page may also show install snippets for Next.js — these are fully compatible with Next.js 16, since `@clerk/nextjs` tracks current Next.js releases closely. We'll follow our own step-by-step version in Part 5 regardless, so you don't need to follow Clerk's on-screen snippet directly.

## 4. Understand development vs. production instances

Every Clerk application starts with a **Development instance**, which:
- Uses `pk_test_...` / `sk_test_...` keys
- Has relaxed settings for local development (e.g. no need for a verified domain)
- Is completely free to use while building

When you deploy to production (Part 14), you'll create a **Production instance** with its own `pk_live_...` / `sk_live_...` keys tied to your real domain. We won't worry about that until Part 14.

## 5. A quick tour of the Clerk Dashboard

Take a minute to look around — you'll come back to these sections throughout the series:

- **Configure → API Keys** — your publishable/secret keys (Part 5)
- **Configure → Sessions** — session lifetime settings
- **Configure → Restrictions** — control who can sign up (allowlist/blocklist)
- **User & Authentication → Email, Phone, Username** — which sign-up fields/methods are required (Part 6)
- **User & Authentication → Social Connections** — enable Google, GitHub, etc.
- **Organizations** — enable/configure multi-tenancy (Part 11)
- **Webhooks** — where we'll register our sync endpoint (Part 13)
- **Users** — see everyone who has signed up, manually ban/delete/edit users

## Checkpoint

- [ ] Clerk account created
- [ ] An application named "Acme Boards" (or similar) created in the Clerk Dashboard
- [ ] You can see your `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY` under Configure → API Keys
- [ ] You understand development vs. production instances

## Troubleshooting

**I don't see a "Create application" button.**
If this is your very first time using Clerk, you may be routed straight into the application-creation wizard right after signing up — that's the same flow, just without a separate button click.

**I accidentally created two applications.**
No harm done — you can delete extras under **Configure → General → Delete application**, or just ignore them and make sure you're using the correct one's keys in Part 5.

**Which sign-in options should I pick if I'm not sure?**
Email + password is the simplest to reason about for learning purposes, and it's what Part 9's fully custom UI uses. You can always add/remove methods later from **User & Authentication** without touching code.

**I don't want to enable Google/social login — is that a problem?**
Not at all — everything in this tutorial works fine with just email/password.

**Clerk's own on-screen setup snippet looks slightly different from what this tutorial shows in Part 5.**
That's expected and fine — follow this tutorial's Part 5 instructions for a version verified to work with Next.js 16.

---

Once you've got your Clerk account and app set up with keys in hand, just say **"next"** for Part 5.
