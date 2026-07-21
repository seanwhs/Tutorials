# Phase 3: Secrets Management & Infrastructure as Code

**Core Focus:** Preventing Credential Leaks & Hardening Infrastructure.

Exposed API keys and misconfigured cloud infrastructure are two of the *leading* causes of real-world breaches. In Phase 1 we blocked secrets at the *laptop* (pre-commit). Now we add three more layers:

1. **Repo-wide secret scanning in CI** — catches secrets that slipped past local hooks *and* scans the entire git history.
2. **A real secret manager** — so credentials live in a vault, not in code or even `.env` files, in production.
3. **Infrastructure as Code (IaC) auditing** — we'll define our infrastructure as Terraform, then scan it for misconfigurations *before* it's ever provisioned.

We'll also finally give the app a **real PostgreSQL database**, replacing the in-memory stores — which gives us actual infrastructure to secure.

---

## Step 3.1 — Full-History Secret Scanning in CI

### 🎯 The Target
Add a CI job that scans the *entire git history* (not just the latest commit) for leaked secrets using **gitleaks**.

### 🧠 The Concept
The pre-commit hook from Phase 1 is a **guard at the front door** — but what about secrets that were committed *before* we installed the guard, or by someone who used `--no-verify`? A CI history scan is the **security audit of the entire building**, checking every room and every past visitor log.

> **Critical truth:** Once a secret is committed to git, it lives in history *forever* — even if you delete it in a later commit, `git log` still contains it. Anyone who clones the repo gets the secret. That's why full-history scanning matters: it finds the ones already baked in.

### ⌨️ The Implementation

Add a secrets job. Append to **`.github/workflows/security.yml`** under `jobs:`:

```yaml
  # ── Job 4: Secret scanning across FULL git history ──────────────────────
  secrets:
    name: Secret Scan (gitleaks)
    runs-on: ubuntu-latest
    steps:
      - name: Checkout FULL history
        uses: actions/checkout@v4
        with:
          # fetch-depth: 0 pulls the ENTIRE history, not just the last commit.
          # gitleaks needs this to scan every past commit for leaked secrets.
          fetch-depth: 0

      - name: Run gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          # Uses the .gitleaks.toml config we created in Phase 1.
          GITLEAKS_CONFIG: .gitleaks.toml
```

> This reuses the exact same `.gitleaks.toml` rules from Phase 1 — the *same policy* is now enforced at *two layers* (local pre-commit + central CI). That's defense in depth for secrets.

### ✅ The Verification

Push and open the **Actions** tab — the new **Secret Scan (gitleaks)** job runs and passes green (our history is clean because Phase 1 blocked leaks from day one).

**Prove full-history detection works.** On a scratch branch, commit a secret and then "remove" it in a *second* commit:
```bash
git checkout -b test-history-leak
echo 'const key = "AKIAIOSFODNN7EXAMPLE";' > src/oops.ts
git add . && git commit -m "leak"          # commit 1: introduces secret
rm src/oops.ts
git add . && git commit -m "cleanup"       # commit 2: 'removes' it
git push origin test-history-leak
```
Even though the file is *gone* in the latest commit, the CI **gitleaks job fails** — because the secret still exists in commit 1's history. This is the lesson: deletion ≠ removal. Delete the branch afterward:
```bash
git checkout main && git branch -D test-history-leak
git push origin --delete test-history-leak
```

---

## Step 3.2 — Give the App a Real Database (PostgreSQL)

### 🎯 The Target
Replace the in-memory stores with a real **PostgreSQL** database, accessed via **parameterized queries** — creating genuine infrastructure we then secure.

### 🧠 The Concept
An in-memory store forgets everything on restart. A **database** is **permanent filing cabinets** with locks. We'll run PostgreSQL locally via **Docker Compose** (a way to define and launch containers with a single file) so nobody has to install a database by hand.

> **Definition — Docker Compose:** A YAML file describing one or more containers (like a database) and how to run them together. `docker compose up` launches them.

Every query will be **parameterized** (`$1`, `$2` placeholders) — the database driver keeps user input strictly as *data*, structurally preventing SQL injection (golden rule #2).

### ⌨️ The Implementation

```bash
npm install pg
npm install --save-dev @types/pg
```

Define the local database:

**`docker-compose.yml`**
```yaml
services:
  db:
    image: postgres:16-alpine # pinned major version; alpine = small & fewer CVEs
    restart: unless-stopped
    environment:
      # These are LOCAL DEV values only. Production uses a secret manager.
      POSTGRES_USER: securenotes
      POSTGRES_PASSWORD: localdevpassword
      POSTGRES_DB: securenotes
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data      # persist data across restarts
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro # schema on first boot

volumes:
  pgdata:
```

The database schema, run automatically on first launch:

**`db/init.sql`**
```sql
-- Users table. We store password HASHES, never raw passwords.
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Notes table. Each note is tied to its owner via a foreign key.
-- ON DELETE CASCADE: deleting a user removes their notes (no orphans).
CREATE TABLE IF NOT EXISTS notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast "list my notes" lookups (queries filter by user_id).
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
```

A shared connection pool:

**`src/db/pool.ts`**
```typescript
import pg from "pg";
import { config } from "../config.js";

// A connection POOL reuses a set of DB connections instead of opening a new
// one per request — faster and prevents connection-exhaustion DoS.
export const pool = new pg.Pool({
  connectionString: config.DATABASE_URL,
  max: 10,                       // cap concurrent connections
  idleTimeoutMillis: 30_000,     // release idle connections
  connectionTimeoutMillis: 5_000,
});

// Graceful shutdown: close connections cleanly when the app stops.
export async function closePool(): Promise<void> {
  await pool.end();
}
```

Now make `DATABASE_URL` **required** in config (it was optional). Update **`src/config.ts`** — change that one line:
```typescript
  // Now REQUIRED — the app needs a database from Phase 3 onward.
  DATABASE_URL: z.string().url(),
```
And add it to **`.env`**:
```dotenv
DATABASE_URL=postgres://securenotes:localdevpassword@localhost:5432/securenotes
```

Rewrite the note store to use the database with parameterized queries:

**`src/notes/store.ts`** (full replacement)
```typescript
import { pool } from "../db/pool.js";

export interface Note {
  id: string;
  userId: string;
  title: string;
  body: string;
  createdAt: string;
}

// Map a raw DB row (snake_case) to our clean camelCase Note interface.
function rowToNote(row: Record<string, unknown>): Note {
  return {
    id: row.id as string,
    userId: row.user_id as string,
    title: row.title as string,
    body: row.body as string,
    createdAt: (row.created_at as Date).toISOString(),
  };
}

class NoteStore {
  async create(userId: string, title: string, body: string): Promise<Note> {
    // $1,$2,$3 are PARAMETERS. pg sends them separately from the SQL text,
    // so user input can NEVER be executed as SQL. This defeats SQL injection.
    const { rows } = await pool.query(
      `INSERT INTO notes (user_id, title, body)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [userId, title, body]
    );
    return rowToNote(rows[0]!);
  }

  async listByUser(userId: string): Promise<Note[]> {
    const { rows } = await pool.query(
      `SELECT * FROM notes WHERE user_id = $1 ORDER BY created_at DESC`,
      [userId]
    );
    return rows.map(rowToNote);
  }

  async findOwned(userId: string, noteId: string): Promise<Note | null> {
    // Ownership enforced in the WHERE clause: user_id = $1 AND id = $2.
    // A user physically cannot query another user's note.
    const { rows } = await pool.query(
      `SELECT * FROM notes WHERE user_id = $1 AND id = $2`,
      [userId, noteId]
    );
    return rows[0] ? rowToNote(rows[0]) : null;
  }

  async deleteOwned(userId: string, noteId: string): Promise<boolean> {
    const { rowCount } = await pool.query(
      `DELETE FROM notes WHERE user_id = $1 AND id = $2`,
      [userId, noteId]
    );
    return (rowCount ?? 0) > 0;
  }
}

export const noteStore = new NoteStore();
```

The note routes must now `await` the async store. Update **`src/notes/routes.ts`** handlers to be `async` and `await` each store call. Full replacement:

**`src/notes/routes.ts`**
```typescript
import { Router, type Request, type Response } from "express";
import { noteStore } from "./store.js";
import { createNoteSchema, noteIdSchema } from "./schemas.js";

export const notesRouter = Router();

notesRouter.post("/", async (req: Request, res: Response) => {
  const result = createNoteSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ error: result.error.flatten().fieldErrors });
  }
  const note = await noteStore.create(req.user!.userId, result.data.title, result.data.body);
  return res.status(201).json(note);
});

notesRouter.get("/", async (req: Request, res: Response) => {
  const notes = await noteStore.listByUser(req.user!.userId);
  return res.status(200).json(notes);
});

notesRouter.get("/:id", async (req: Request, res: Response) => {
  const idResult = noteIdSchema.safeParse(req.params.id);
  if (!idResult.success) return res.status(400).json({ error: "Invalid note id" });
  const note = await noteStore.findOwned(req.user!.userId, idResult.data);
  if (!note) return res.status(404).json({ error: "Not found" });
  return res.status(200).json(note);
});

notesRouter.delete("/:id", async (req: Request, res: Response) => {
  const idResult = noteIdSchema.safeParse(req.params.id);
  if (!idResult.success) return res.status(400).json({ error: "Invalid note id" });
  const deleted = await noteStore.deleteOwned(req.user!.userId, idResult.data);
  if (!deleted) return res.status(404).json({ error: "Not found" });
  return res.status(204).send();
});
```

Do the same for the user store:

**`src/auth/userStore.ts`** (full replacement)
```typescript
import bcrypt from "bcryptjs";
import { pool } from "../db/pool.js";

export interface User {
  id: string;
  email: string;
  passwordHash: string;
}

function rowToUser(row: Record<string, unknown>): User {
  return {
    id: row.id as string,
    email: row.email as string,
    passwordHash: row.password_hash as string,
  };
}

class UserStore {
  async register(email: string, password: string): Promise<User> {
    const passwordHash = await bcrypt.hash(password, 12);
    // ON CONFLICT lets us detect duplicate emails without a leaky pre-check.
    const { rows } = await pool.query(
      `INSERT INTO users (email, password_hash)
       VALUES ($1, $2)
       ON CONFLICT (email) DO NOTHING
       RETURNING *`,
      [email, passwordHash]
    );
    if (!rows[0]) throw new Error("Email already registered");
    return rowToUser(rows[0]);
  }

  async verify(email: string, password: string): Promise<User | null> {
    const { rows } = await pool.query(
      `SELECT * FROM users WHERE email = $1`,
      [email]
    );
    if (!rows[0]) return null;
    const user = rowToUser(rows[0]);
    const ok = await bcrypt.compare(password, user.passwordHash);
    return ok ? user : null;
  }
}

export const userStore = new UserStore();
```

### ✅ The Verification

Start the database, then the app:
```bash
docker compose up -d          # launches PostgreSQL in the background
docker compose ps             # confirm "db" is running/healthy
npm run dev
```

Register, log in, and create a note — then prove **persistence** (data survives restart):
```bash
TOKEN=$(curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"db@example.com","password":"supersecret123"}' \
  | node -pe 'JSON.parse(require("fs").readFileSync(0)).token')

curl -s -X POST http://localhost:3000/notes \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Persisted note","body":"survives restarts"}'
```
Now restart the app (`Ctrl+C`, `npm run dev` again), log in, and list notes — the note is **still there**, proving it's in PostgreSQL. Prove injection is defeated:
```bash
# A classic injection attempt in the title is stored as literal text, not executed
curl -s -X POST http://localhost:3000/notes \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"'"'"'; DROP TABLE notes; --","body":"nice try"}'
curl -s http://localhost:3000/notes -H "Authorization: Bearer $TOKEN"
# → the notes table still exists; the malicious title is just a harmless string
```
Commit:
```bash
git add . && git commit -m "feat(db): PostgreSQL with parameterized queries"
```

---

## Step 3.3 — A Secure, Multi-Stage Dockerfile

### 🎯 The Target
Package the app into a minimal, hardened **Docker image** using a multi-stage build that runs as a non-root user.

### 🧠 The Concept
> **Definition — Docker image:** A self-contained, portable package holding your app *and* everything it needs to run (Node, code, dependencies). A running image is a **container**.

A **multi-stage build** is like **cooking in a messy kitchen but serving on a clean plate.** The "build stage" installs compilers and dev tools (messy), then we copy *only the finished dish* into a tiny, clean "runtime stage." The final image contains no compilers, no dev dependencies, no source — a smaller **attack surface** (fewer things for an attacker to exploit).

We also run as a **non-root user**: if an attacker breaks into the container, they shouldn't have admin rights inside it (least privilege).

### ⌨️ The Implementation

**`Dockerfile`**
```dockerfile
# ── STAGE 1: Build ──────────────────────────────────────────────────────────
# Pin to a specific digest-friendly version tag for reproducibility.
FROM node:20-alpine AS build
WORKDIR /app

# Copy only manifests first so Docker can cache the npm install layer.
COPY package.json package-lock.json ./
# Install ALL deps (including dev) needed to compile TypeScript.
RUN npm ci

# Copy source and build to dist/.
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Strip dev dependencies so we copy only production deps to the final image.
RUN npm ci --omit=dev

# ── STAGE 2: Runtime ────────────────────────────────────────────────────────
# Start from a fresh, minimal base — none of the build tooling comes along.
FROM node:20-alpine AS runtime
WORKDIR /app

# Security: run as the built-in unprivileged "node" user, not root.
ENV NODE_ENV=production

# Copy ONLY what production needs: compiled code + prod node_modules.
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./package.json

# Drop privileges. If the app is compromised, the attacker is not root.
USER node

EXPOSE 3000

# A healthcheck lets orchestrators know if the container is alive.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD node -e "fetch('http://localhost:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "dist/server.js"]
```

Prevent build context bloat and secret leakage into the image:

**`.dockerignore`**
```gitignore
node_modules
dist
.git
.env
.env.*
!.env.example
*.log
coverage
docs
.github
```

> **Why `.dockerignore` matters for security:** without it, `COPY . .` could copy your local `.env` (with real secrets) straight into the shipped image. This file makes that impossible.

We also need graceful shutdown so the container stops cleanly. Update the bottom of **`src/server.ts`** — replace the `app.listen(...)` block with:
```typescript
const server = app.listen(config.PORT, () => {
  console.log(`🚀 securenotes running on port ${config.PORT} [${config.NODE_ENV}]`);
});

// Handle orchestrator stop signals (SIGTERM) so in-flight requests finish
// and DB connections close cleanly — prevents corruption and hung containers.
import { closePool } from "./db/pool.js";
function shutdown(signal: string) {
  console.warn(`${signal} received, shutting down gracefully...`);
  server.close(async () => {
    await closePool();
    process.exit(0);
  });
}
process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
```

### ✅ The Verification

Build and inspect the image:
```bash
docker build -t securenotes:local .

# Confirm it runs as non-root (should print "node", NOT "root")
docker run --rm securenotes:local whoami

# Check the image size — should be a few hundred MB, not 1GB+
docker images securenotes:local
```
Run it connected to your local DB (host networking varies; on Linux use `--network host`, on Docker Desktop use `host.docker.internal`):
```bash
docker run --rm -p 3001:3000 \
  -e DATABASE_URL="postgres://securenotes:localdevpassword@host.docker.internal:5432/securenotes" \
  -e JWT_SECRET="dev-only-super-long-secret-change-me-in-production-1234" \
  securenotes:local

# In another terminal:
curl -s http://localhost:3001/health   # → {"status":"ok",...}
```
Stop with `Ctrl+C` (you'll see the graceful shutdown message). Commit:
```bash
git add . && git commit -m "feat(docker): hardened multi-stage non-root image"
```

---

## Step 3.4 — Infrastructure as Code with Terraform

### 🎯 The Target
Define cloud infrastructure as **Terraform** code — the thing we'll audit for misconfigurations in the next step.

### 🧠 The Concept
> **Definition — Infrastructure as Code (IaC):** Describing your servers, databases, and networks in text files instead of clicking buttons in a cloud console. The files are version-controlled, reviewable, and repeatable.
> **Definition — Terraform:** The most popular IaC tool; you declare *what* you want and it makes reality match.

The huge security win: because infrastructure is now *text*, we can **scan it just like code** — catching a "database open to the entire internet" mistake *before* it's ever created, instead of after a breach.

We'll write a *deliberately imperfect* configuration first, so the scanner in Step 3.5 has something real to catch — then fix it.

### ⌨️ The Implementation

**`infra/main.tf`**
```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# An S3 bucket to store application backups.
resource "aws_s3_bucket" "backups" {
  bucket = "${var.project_name}-backups"
}

# Encrypt objects at rest with AES-256 (protects data if disks are stolen).
resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block ALL public access to the backups bucket (defense against data leaks).
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Security group (a virtual firewall) for the database.
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Database access"

  # Allow PostgreSQL only from within our private network CIDR.
  ingress {
    description = "PostgreSQL from app subnet"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.app_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**`infra/variables.tf`**
```hcl
variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Prefix for resource names"
  default     = "securenotes"
}

variable "app_subnet_cidr" {
  type        = string
  description = "CIDR range allowed to reach the database"
  default     = "10.0.1.0/24"
}
```

> Notice we already applied several best practices (encryption, public-access block, a scoped DB firewall). The scanner will confirm these *and* likely find a few subtler issues to fix — which is exactly the point.

### ✅ The Verification

```bash
cd infra
terraform init      # downloads the AWS provider
terraform validate  # → "Success! The configuration is valid."
terraform fmt -check # confirms formatting is consistent
cd ..
```
You don't need to `terraform apply` (that would create real, billable AWS resources). Validation confirms the code is syntactically sound and ready to audit.

---

## Step 3.5 — Audit IaC & the Dockerfile for Misconfigurations

### 🎯 The Target
Add a CI job that scans the Terraform and Dockerfile for security misconfigurations using **Trivy** (config mode) and **Checkov**.

### 🧠 The Concept
An **IaC scanner** is a **building-code inspector reading the blueprints** before construction starts. It knows hundreds of rules ("databases must not be publicly accessible," "S3 buckets must be encrypted," "containers should not run as root") and flags any blueprint that violates them. Catching it in the blueprint costs a code edit; catching it after deployment could cost a breach.

> **Definition — Checkov:** An open-source IaC scanner with thousands of built-in policies for Terraform, CloudFormation, Kubernetes, and Dockerfiles.

### ⌨️ The Implementation

Add an IaC audit job. Append to **`.github/workflows/security.yml`** under `jobs:`:

```yaml
  # ── Job 5: Infrastructure-as-Code & Dockerfile audit ────────────────────
  iac:
    name: IaC & Dockerfile Audit
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      # Trivy config scan: covers Terraform misconfig AND Dockerfile issues.
      - name: Trivy misconfiguration scan
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: "config"
          scan-ref: "."
          severity: "HIGH,CRITICAL"
          exit-code: "1"

      # Checkov: deeper, policy-rich Terraform/Dockerfile analysis.
      - name: Checkov scan
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: .
          framework: terraform,dockerfile
          # Skip checks we've consciously accepted, documented in the config.
          config_file: .checkov.yaml
          quiet: true
          soft_fail: false   # fail the job on findings (this is a gate)
```

Give Checkov a config so accepted risks are explicit and auditable:

**`.checkov.yaml`**
```yaml
# Checkov configuration.
# skip-check lists policies we consciously accept, each with a reason.
skip-check:
  # Example: our S3 bucket doesn't need access logging in this demo.
  # Remove/adjust for production. Every skip MUST be justified in review.
  - CKV_AWS_18   # S3 access logging — out of scope for the tutorial demo

# Compact output in CI logs.
compact: true
```

### ✅ The Verification

Run the audits locally first:
```bash
# Trivy config scan
trivy config . --severity HIGH,CRITICAL

# Checkov (install via: pip install checkov)
checkov -d . --framework terraform dockerfile
```
Push and check the **Actions** tab — the **IaC & Dockerfile Audit** job runs.

**Prove the gate catches a misconfiguration.** Edit `infra/main.tf` and open the database firewall to the whole internet (a catastrophic real-world mistake):
```hcl
  # TEMPORARILY change the db ingress cidr_blocks to:
    cidr_blocks = ["0.0.0.0/0"]   # DANGER: PostgreSQL open to the world
```
Run the scanner:
```bash
checkov -d infra --framework terraform
```
Checkov **fails** with a finding like *"Ensure no security groups allow ingress from 0.0.0.0:0 to port 5432"* — catching a full database exposure before a single resource is created. **Revert the change** back to `var.app_subnet_cidr` and re-run to confirm it passes.

Commit the clean state:
```bash
git add . && git commit -m "ci: add IaC + Dockerfile misconfiguration audit"
git push
```

---

## Step 3.6 — Secrets in Production: The Secret Manager Pattern

### 🎯 The Target
Refactor secret loading so that in production, secrets come from a **secret manager** (fetched at startup) rather than a `.env` file — while keeping local dev simple.

### 🧠 The Concept
A **secret manager** (AWS Secrets Manager, HashiCorp Vault, etc.) is a **bank vault with an access log.** Instead of scattering copies of the vault key (your secrets) across `.env` files on many machines, secrets live in one guarded vault. The app requests them at startup using its *identity* (an IAM role), and every access is logged and can be rotated centrally.

> **Why not just `.env` in production?** `.env` files get copied, backed up, and accidentally logged. A secret manager centralizes control, enables rotation without redeploys, and records *who accessed what, when* (which helps with the "Repudiation" threat).

We'll implement a clean **provider abstraction**: local dev reads `.env`; production reads the manager. The rest of the app doesn't know or care which.

### ⌨️ The Implementation

**`src/secrets/provider.ts`**
```typescript
/**
 * A SecretProvider abstracts WHERE secrets come from.
 * - Local/dev: environment variables (from .env via dotenv).
 * - Production: a real secret manager (AWS Secrets Manager shown as example).
 *
 * The app depends on this interface, not on any specific backend — so we can
 * swap providers without touching business logic (dependency inversion).
 */
export interface SecretProvider {
  get(key: string): Promise<string | undefined>;
}

// ── Environment-variable provider (local development) ───────────────────────
export class EnvSecretProvider implements SecretProvider {
  async get(key: string): Promise<string | undefined> {
    return process.env[key];
  }
}

// ── AWS Secrets Manager provider (production) ───────────────────────────────
// Fetches a single JSON secret once and caches it. Uses the app's IAM role
// for auth — NO credentials are stored in code or env.
export class AwsSecretsProvider implements SecretProvider {
  private cache: Record<string, string> | null = null;
  private readonly secretId: string;

  constructor(secretId: string) {
    this.secretId = secretId;
  }

  private async load(): Promise<Record<string, string>> {
    if (this.cache) return this.cache;
    // Lazy import so the AWS SDK isn't required in local dev.
    const { SecretsManagerClient, GetSecretValueCommand } = await import(
      "@aws-sdk/client-secrets-manager"
    );
    const client = new SecretsManagerClient({});
    const resp = await client.send(
      new GetSecretValueCommand({ SecretId: this.secretId })
    );
    if (!resp.SecretString) {
      throw new Error(`Secret ${this.secretId} has no string value`);
    }
    this.cache = JSON.parse(resp.SecretString) as Record<string, string>;
    return this.cache;
  }

  async get(key: string): Promise<string | undefined> {
    const secrets = await this.load();
    return secrets[key];
  }
}

// Factory: pick the provider based on the environment.
export function createSecretProvider(): SecretProvider {
  if (process.env.NODE_ENV === "production" && process.env.AWS_SECRET_ID) {
    return new AwsSecretsProvider(process.env.AWS_SECRET_ID);
  }
  return new EnvSecretProvider();
}
```

Now make config *asynchronous* so it can fetch from the provider. Update **`src/config.ts`** (full replacement):

**`src/config.ts`**
```typescript
import { z } from "zod";
import dotenv from "dotenv";
import { createSecretProvider } from "./secrets/provider.js";

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3000),
  JWT_SECRET: z.string().min(32, "JWT_SECRET must be at least 32 characters"),
  DATABASE_URL: z.string().url(),
});

export type Config = z.infer<typeof envSchema>;

// Load config from the active secret provider, falling back to process.env.
export async function loadConfig(): Promise<Config> {
  const provider = createSecretProvider();

  // Merge: start with process.env, then let the provider override secrets.
  const merged: Record<string, unknown> = { ...process.env };
  for (const key of ["JWT_SECRET", "DATABASE_URL"]) {
    const val = await provider.get(key);
    if (val !== undefined) merged[key] = val;
  }

  const parsed = envSchema.safeParse(merged);
  if (!parsed.success) {
    console.error("❌ Invalid configuration:");
    console.error(parsed.error.flatten().fieldErrors);
    process.exit(1);
  }
  return parsed.data;
}
```

Because config is now async, the app needs an async bootstrap. Add the AWS SDK as an *optional* production dependency and restructure the server startup.

```bash
npm install @aws-sdk/client-secrets-manager
```

Update **`src/server.ts`** — wrap everything that used `config` in an async `main()`. Full replacement:

**`src/server.ts`**
```typescript
import express, { type Request, type Response, type NextFunction } from "express";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { loadConfig } from "./config.js";
import { authRouter } from "./auth/routes.js";
import { requireAuth } from "./auth/middleware.js";
import { notesRouter } from "./notes/routes.js";
import { closePool } from "./db/pool.js";

async function main() {
  // Load secrets/config from the active provider BEFORE starting the app.
  const config = await loadConfig();

  const app = express();

  app.use(helmet());
  app.use(express.json({ limit: "10kb" }));
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 100,
      standardHeaders: true,
      legacyHeaders: false,
      message: { error: "Too many requests, please try again later." },
    })
  );

  app.get("/health", (_req: Request, res: Response) => {
    res.status(200).json({ status: "ok", uptime: process.uptime() });
  });

  app.use("/auth", authRouter);
  app.use("/notes", requireAuth, notesRouter);

  app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    console.error("Unhandled error:", err.message);
    res.status(500).json({ error: "Internal server error" });
  });

  const server = app.listen(config.PORT, () => {
    console.log(`🚀 securenotes running on port ${config.PORT} [${config.NODE_ENV}]`);
  });

  function shutdown(signal: string) {
    console.warn(`${signal} received, shutting down gracefully...`);
    server.close(async () => {
      await closePool();
      process.exit(0);
    });
  }
  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
}

// Start, and fail loudly if bootstrap throws.
main().catch((err) => {
  console.error("Fatal startup error:", err);
  process.exit(1);
});
```

One dependency detail: `src/db/pool.ts` and `src/auth/jwt.ts` imported the old synchronous `config`. Now that config is async, we pass values explicitly. Update `pool.ts` to read the env directly (it's needed before config resolves) — replace its top:

**`src/db/pool.ts`** (updated)
```typescript
import pg from "pg";

// The pool needs DATABASE_URL. In production the secret manager sets this into
// the environment during bootstrap (or you can pass it in). We read it here.
export const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

export async function closePool(): Promise<void> {
  await pool.end();
}
```

And `src/auth/jwt.ts` should read the secret from the environment (populated at bootstrap):

**`src/auth/jwt.ts`** (updated)
```typescript
import jwt from "jsonwebtoken";

export interface TokenPayload {
  userId: string;
  email: string;
}

function secret(): string {
  const s = process.env.JWT_SECRET;
  if (!s) throw new Error("JWT_SECRET not configured");
  return s;
}

export function signToken(payload: TokenPayload): string {
  return jwt.sign(payload, secret(), { expiresIn: "1h" });
}

export function verifyToken(token: string): TokenPayload {
  return jwt.verify(token, secret()) as TokenPayload;
}
```

To ensure the resolved secret is available to these modules, have `loadConfig` write the final values back into `process.env`. Add to the end of `loadConfig` in **`src/config.ts`**, just before `return parsed.data;`:
```typescript
  // Propagate resolved secrets into process.env so modules that read env
  // (db pool, jwt) get the manager-provided values in production.
  process.env.JWT_SECRET = parsed.data.JWT_SECRET;
  process.env.DATABASE_URL = parsed.data.DATABASE_URL;
```

### ✅ The Verification

Local dev still works exactly as before (uses `EnvSecretProvider`):
```bash
docker compose up -d
npm run build          # confirm the async refactor type-checks
npm run dev            # → 🚀 securenotes running... [development]
curl -s http://localhost:3000/health   # → {"status":"ok",...}
```
Confirm the production path *would* use the manager (dry logic check):
```bash
# With NODE_ENV=production and no AWS_SECRET_ID, it falls back to env (safe).
# With AWS_SECRET_ID set + valid IAM role, it fetches from Secrets Manager.
NODE_ENV=production node -e "import('./dist/secrets/provider.js').then(m=>console.log(m.createSecretProvider().constructor.name))"
# → "EnvSecretProvider"  (no AWS_SECRET_ID set locally, correct fallback)
```
Run the full local security suite:
```bash
npm run lint && npm run build && npm audit --audit-level=high
```
Commit the Phase 3 completion:
```bash
git add . && git commit -m "feat(security): Phase 3 — secrets manager + IaC audit complete"
git push
```

---

## 📚 Phase 3 Reference Section

*Deep dives — skip on first pass.*

### R3.1 — Why git history leaks are so dangerous
Git is a *content-addressed* database: every version of every file is stored as an immutable object. `rm secret.txt && git commit` only records "the file is gone *going forward*" — the old blob remains reachable via `git log`, `git checkout <old-sha>`, or a fresh clone. **Removing a committed secret requires rewriting history** (`git filter-repo` / BFG) *and* rotating the secret, because you must assume it's already compromised.

### R3.2 — Parameterized queries vs escaping
Some developers "escape" quotes in user input to prevent injection. This is fragile — encodings, edge cases, and new SQL features constantly break escaping. Parameterization is structurally safe: the SQL text and the data travel to the database on *separate channels*, so data is never parsed as code. **Always parameterize; never escape.**

### R3.3 — Multi-stage build savings
| | Single-stage | Multi-stage (ours) |
|---|---|---|
| Contains compilers/dev deps | Yes | No |
| Contains source `.ts` | Yes | No (only `dist/`) |
| Typical size | ~1.1 GB | ~180 MB |
| Attack surface | Large | Minimal |
Smaller images also pull faster and have fewer OS packages for the Phase 4 scanner to flag.

### R3.4 — Common IaC misconfigurations scanners catch
- Security groups open to `0.0.0.0/0` on sensitive ports (SSH 22, DB 5432, RDP 3389).
- Unencrypted storage (S3, EBS, RDS).
- Publicly readable S3 buckets.
- Overly permissive IAM policies (`"Action": "*"`).
- Missing logging/audit trails.
- Containers running as root or with no resource limits.

### R3.5 — Secret rotation, the real payoff
The secret-manager pattern's biggest win is **rotation without redeploys.** When you rotate `JWT_SECRET` or DB credentials in the vault, apps pick up the new value on their next fetch/restart — no code change, no `.env` edits across servers. Combined with short cache TTLs, a leaked secret's useful lifetime shrinks dramatically.
