# 🟢 DAY 0 — NEXUS LMS FOUNDATION SETUP

> Goal: You successfully run a Next.js app connected to all core services (no LMS logic yet).

---

# 📦 What you will build today

By the end of Day 0 you will have:

```text
Next.js app running locally
✔ Clerk authentication ready
✔ Supabase connected
✔ Inngest initialized
✔ Sanity studio initialized
✔ Environment variables configured
```

No LMS logic yet — just infrastructure.

---

# 🧱 STEP 1 — Create Next.js project

Run:

```bash
npx create-next-app@latest nexus-lms
```

Select:

* TypeScript: YES
* App Router: YES
* ESLint: YES

---

# 📁 Folder after setup

```text
nexus-lms/
  app/
  public/
  node_modules/
  package.json
```

---

# 🧪 CHECKPOINT 1

Run:

```bash
npm run dev
```

Open:

```
http://localhost:3000
```

✔ Expected:
Next.js homepage loads

---

# 🐛 If broken

| Issue       | Fix                         |
| ----------- | --------------------------- |
| port in use | kill process or change port |
| blank page  | ensure app/page.tsx exists  |

---

# 🔐 STEP 2 — Install core dependencies

```bash
npm install @clerk/nextjs
npm install @supabase/supabase-js
npm install inngest
npm install sanity
```

---

# 📁 Updated structure

```text
nexus-lms/
  app/
  lib/
  node_modules/
```

---

# 🔑 STEP 3 — Environment variables

Create:

```text
.env.local
```

Paste:

```env
# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=

# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=

# Inngest
INNGEST_EVENT_KEY=
```

---

# 🧪 CHECKPOINT 2

Restart server:

```bash
npm run dev
```

✔ No env errors in terminal

---

# 🧠 STEP 4 — Create shared lib folder

Create structure:

```text
lib/
  supabase.ts
  inngest.ts
```

---

# 📄 Supabase client

```ts
// lib/supabase.ts

import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

---

# 📄 Inngest client

```ts
// lib/inngest.ts

import { Inngest } from "inngest";

export const inngest = new Inngest({
  id: "nexus-lms"
});
```

---

# 🧪 CHECKPOINT 3

Run:

```bash
npm run dev
```

✔ App still runs without errors

---

# 🔐 STEP 5 — Add Clerk provider

Edit:

```text
app/layout.tsx
```

---

## Paste:

```ts
import { ClerkProvider } from "@clerk/nextjs";

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

---

# 🧪 CHECKPOINT 4

✔ App loads normally
✔ No hydration errors

---

# 🧭 STEP 6 — Create folder structure baseline

Create:

```text
app/
  (auth)/
  (dashboard)/
  api/
```

---

Final structure:

```text
nexus-lms/
  app/
    (auth)/
    (dashboard)/
    api/
  lib/
  public/
```

---

# 🧠 WHAT YOU LEARNED TODAY

You just built the **foundation of an AI-native LMS platform**:

* Next.js app initialized
* Authentication system installed (Clerk)
* Database layer prepared (Supabase)
* Event system initialized (Inngest)
* Future CMS layer ready (Sanity)
* Clean modular architecture started

---

# 🚀 DAY 0 COMPLETE STATE

```text
Frontend: READY
Auth: READY
Database: CONNECTED (not used yet)
Events: INITIALIZED
CMS: READY
Business logic: NOT STARTED YET
```

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🟢 DAY 1 — AUTH FLOW + PROTECTED DASHBOARD

We will build:

* login page
* protected routes
* user session handling
* dashboard shell
* first real LMS UI layer

---
