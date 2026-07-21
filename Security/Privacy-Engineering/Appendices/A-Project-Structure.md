# Appendix A: Full Project Structure, File Inventory & .gitignore** 

---

### Why This Appendix Matters
A clear project structure helps maintainability, especially as your application grows. This appendix serves as your **master map** of the entire MindfulLog codebase.

---

### 1. Complete Project Structure

```bash
mindful-log/
├── app/                          # Next.js App Router
│   ├── api/                      # API routes (future)
│   ├── dashboard/                # Protected pages
│   ├── journal/                  # Journal entry pages
│   ├── settings/
│   │   └── consent/
│   │       └── page.tsx          # Consent management UI
│   ├── layout.tsx                # Root layout with ClerkProvider
│   ├── globals.css               # Tailwind styles
│   └── page.tsx                  # Public landing page
│
├── lib/                          # Core business logic (most important folder)
│   ├── db.ts                     # Neon database connection
│   ├── encryption.ts             # Envelope encryption with KMS
│   ├── policy-engine.ts          # Zero-trust access control
│   ├── privacy-utils.ts          # Masking, HMAC, etc.
│   ├── consent.ts                # Append-only consent logic
│   ├── safe-logger.ts            # PII-redacting logger
│   ├── dsar-export.ts            # Data export engine
│   ├── delete-account.ts         # Deletion orchestrator
│   └── schema.sql                # Database schema (for reference)
│
├── docs/                         # Living documentation
│   ├── DPIA.md                   # Data Protection Impact Assessment
│   ├── PRIVACY_CONVENTIONS.md    # Engineering rules
│   ├── INCIDENT_RESPONSE.md      # Playbook
│   └── STRIDE.md                 # Threat model
│
├── scripts/                      # Automation scripts
│   └── pii-scanner.ts            # Privacy CI checker
│
├── public/                       # Static assets
│   └── favicon.ico
│
├── .github/
│   └── workflows/
│       └── privacy-ci.yml        # GitHub Actions privacy pipeline
│
├── .env.local                    # Local secrets (gitignored)
├── .gitignore
├── next.config.ts
├── middleware.ts                 # Clerk + route protection
├── package.json
├── tsconfig.json
└── README.md                     # (Generated below)
```

---

### 2. Recommended `.gitignore` (Complete & Production-Ready)

```gitignore
# Dependencies
node_modules/
.pnp
.pnp.js

# Environment & Secrets
.env
.env*.local
.env.production
.env.development

# Vercel / Deployment
.vercel
.vercel-build-output

# Next.js
.next/
out/
build/

# Logs & Runtime
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pids
*.pid
*.seed
*.pid.lock

# Coverage & Testing
coverage/
*.lcov
.nyc_output

# Editor & OS files
.DS_Store
Thumbs.db
.vscode/
.idea/

# TypeScript cache
*.tsbuildinfo

# Temporary files
*.tmp
*.temp

# Database dumps (never commit real data)
*.sql.bak
```

---

### 3. Essential File Summaries

| File | Purpose | Why It Matters for Privacy |
|------|--------|---------------------------|
| `lib/encryption.ts` | Envelope encryption logic | Makes plaintext storage impossible |
| `lib/policy-engine.ts` | Centralized access decisions | Zero-trust enforcement |
| `lib/consent.ts` | Consent recording & queries | Immutable audit trail |
| `docs/DPIA.md` | Living privacy documentation | Required for compliance |
| `scripts/pii-scanner.ts` | Automated privacy guard | Catches mistakes in CI |

---

**Appendix A Complete**
