# Part 1: Foundations — Threat Modeling, DPIA, and Project Scaffold

### Why Foundations First?
Before writing a single line of user-facing code, we establish the **security and privacy foundation**. This is the equivalent of pouring concrete and laying rebar before building the walls of a house. Skipping this leads to leaky foundations that are expensive (or impossible) to fix later.

---

#### Step 1.1: The Target — Initialize the Next.js Project + Core Dependencies

**The Concept**:  
Think of this as setting up the empty lot and bringing in all the heavy machinery (framework, auth, database client, validation, background jobs). Doing it now prevents painful refactors later.

**Implementation**:

Run these commands in your project root (sandbox already prepared with base structure):

```bash
# If you haven't already:
npx create-next-app@latest . --typescript --tailwind --eslint --app --yes

npm install @clerk/nextjs @neondatabase/serverless inngest zod @upstash/redis
npm install -D @types/bcryptjs  # for future utilities
```

**Key Files After Setup**:

**package.json** (critical dependencies section):
```json
{
  "name": "mindful-log",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "16.2.11",
    "react": "^19.0.0-rc",
    "react-dom": "^19.0.0-rc",
    "@clerk/nextjs": "^6.9.0",
    "@neondatabase/serverless": "^1.12.0",
    "inngest": "^3.29.0",
    "zod": "^3.23.8",
    "@upstash/redis": "^1.34.0",
    "next-themes": "^0.4.0"
  },
  "devDependencies": {
    "@types/node": "^22",
    "@types/react": "^19",
    "typescript": "^5",
    "eslint": "^9",
    "tailwindcss": "^4"
  }
}
```

**Verification**:
```bash
npm run build
# Should complete without errors
```

---

#### Step 1.2: The Target — Clerk Authentication Setup (Middleware + Layout)

**The Concept**:  
Authentication is your front gate. Clerk manages user identities securely and gives us webhooks for deletion events later. We wrap the entire app so protected routes require authentication.

**Implementation**:

**middleware.ts** (create in project root):
```ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';

const isProtectedRoute = createRouteMatcher([
  '/dashboard(.*)',
  '/journal(.*)',
  '/settings(.*)',
  '/export(.*)',
  '/delete-account(.*)',
]);

export default clerkMiddleware((auth, req) => {
  if (isProtectedRoute(req)) {
    auth().protect(); // Redirects to sign-in if not authenticated
  }
});

export const config = {
  matcher: [
    // Skip Next.js internals and static files
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    '/(api|trpc)(.*)',
  ],
};
```

**app/layout.tsx**:
```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import { ThemeProvider } from "next-themes";
import "./globals.css";

export const metadata: Metadata = {
  title: "MindfulLog — Private Mental Health Journal",
  description: "Your thoughts. Your data. Your control.",
  icons: { icon: "/favicon.ico" },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en" suppressHydrationWarning>
        <body>
          <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
            {children}
          </ThemeProvider>
        </body>
      </html>
    </ClerkProvider>
  );
}
```

**Verification**:
1. Run `npm run dev`
2. Visit `http://localhost:3000`
3. You should be redirected to Clerk’s sign-up/sign-in page.
4. Create an account — you should land on a blank home page.

---

#### Step 1.3: The Target — Environment Variables & Database Connection

**The Concept**:  
Never hard-code secrets. Environment variables act like a secure vault for configuration. Neon gives us serverless Postgres + database branching (like Git branches for your DB — perfect for testing deletions safely).

**Implementation**:

Create `.env.local` (add to `.gitignore`!):

```env
# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...

# Database
DATABASE_URL=postgresql://...

# Redis (Upstash)
UPSTASH_REDIS_REST_URL=https://...
UPSTASH_REDIS_REST_TOKEN=...

# Google KMS (we'll configure in Part 3)
GOOGLE_CLOUD_PROJECT=...
KMS_KEY_RING=projects/.../keyRings/...
KMS_KEY_NAME=projects/.../cryptoKeys/...
```

**lib/db.ts**:
```ts
import { neon } from '@neondatabase/serverless';

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not set");
}

export const sql = neon(process.env.DATABASE_URL);

// Test connection helper
export async function testConnection() {
  try {
    const result = await sql`SELECT NOW() as current_time`;
    console.log("✅ Database connected:", result[0].current_time);
    return true;
  } catch (error) {
    console.error("❌ Database connection failed:", error);
    return false;
  }
}
```

**Verification**:
```bash
node -e '
  import("./lib/db.js").then(({ testConnection }) => testConnection());
'
# Should print current timestamp
```

---

#### Step 1.4: The Target — STRIDE Threat Modeling + Living DPIA Document

**The Concept**:  
**STRIDE** is a threat modeling framework (like a safety inspection checklist for your app).  
**DPIA** (Data Protection Impact Assessment) is the living map of every piece of data, why we need it, and how we protect it.

**Implementation**:

Create folder `docs/` and file `docs/DPIA.md`:

```markdown
# Living DPIA - MindfulLog

## 1. Data Inventory (Updated after every schema change)
| Asset | Justification | Sensitivity | Storage | Mitigation |
|-------|---------------|-------------|---------|----------|
| mood_score | Trend analysis | Low | Plain int | Minimized |
| notes | Health data | Very High (Art 9 GDPR) | Encrypted bytea | Envelope + KMS |
| ... | ... | ... | ... | ... |

## 2. STRIDE Threat Model
- **Spoofing**: Mitigated by Clerk + session tokens
- **Tampering**: AES-GCM + auth tags (Part 3)
- **Information Disclosure**: Field-level encryption + policy engine
- **Denial of Service**: Rate limiting + Neon scaling
- **Elevation of Privilege**: ABAC policy engine (fail-closed)
- **Repudiation**: Immutable audit logs + consent ledger

## 3. Vendor Register & Agreements
- Clerk: DPA signed
- Neon: SCCs in place
- Google Cloud: Data Processing Addendum
```

**Verification**:
```bash
cat docs/DPIA.md | grep -E "(STRIDE|Mitigation|Asset)"
```

---

#### Step 1.5: The Target — Binding Privacy Engineering Conventions

**The Concept**:  
Create repo-level rules so the team (or future you) cannot accidentally violate privacy.

**Implementation**:

Create `docs/PRIVACY_CONVENTIONS.md`:

```markdown
# Privacy Engineering Conventions

1. Never use `console.log` with user data → use `safeLogger`
2. All PII columns must be `bytea` or derived
3. Every new endpoint must go through policy engine
4. Schema changes require DPIA update
5. No UPDATE on consent table — append only
```

**Verification**: Review the file.
