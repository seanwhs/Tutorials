# Part 6: Secure Deployment & Cloud Config

Picking up from Part 5: SecureTrade has a full CI/CD pipeline that catches vulnerabilities before merge. But remember Step 6's ZAP scan flagged three things as `WARN`, not `FAIL`: missing Content-Security-Policy, missing Strict-Transport-Security, missing Permissions-Policy headers. We deferred those deliberately — this part is where we finally close them out, plus harden the infrastructure itself so the app doesn't get owned on day one in production.

**Goal recap:** don't get owned on day 1 in prod.

---

## Step 1 — Document the Deployment Architecture and Threats

### 🎯 The Target
`docs/DEPLOYMENT-ARCHITECTURE.md` — naming exactly what's exposed once SecureTrade goes from `localhost` to a real, public production URL.

### 💡 The Concept
Everything up to now has run on your laptop or in an ephemeral CI runner — neither is a target a real attacker can reach at 3 AM on a Tuesday. The moment SecureTrade gets a real public domain, it joins the pool of things constantly, automatically scanned by internet-wide bots the second it's discoverable — think of it like the difference between keeping cash in your house (only people who know your address can target it) versus opening a storefront on a busy street (everyone walking by can see it, try the door, and peek in the windows). This step names the new risks that only exist once we're "on the street."

### 🛠️ The Implementation

##### 📄 File: `docs/DEPLOYMENT-ARCHITECTURE.md`
```markdown
# SecureTrade — Deployment Architecture & Threats

## Production Topology
```
Internet
   │
   ▼
Vercel Edge Network (global CDN + Edge Runtime middleware)
   │  - TLS termination
   │  - Vercel WAF / Firewall rules (Step 4)
   │  - Rate limiting (Step 4)
   │  - Security headers injected here (Step 2)
   ▼
Next.js Server Functions (Node.js runtime, per-region)
   │
   ▼
Supabase Postgres (ap-southeast-1) — via pooled connection
```

## New Threats Introduced By Going Public

| Threat | Why It Only Matters Now |
|---|---|
| Clickjacking (embedding our login page in a malicious invisible iframe) | Requires a real, dereferenceable public URL to embed |
| Man-in-the-middle downgrade to plain HTTP | Only exploitable once real users on real (possibly hostile) networks connect |
| Mixed-content / MIME-sniffing attacks | Only relevant once we're serving over a real public origin browsers apply full security models to |
| Volumetric / brute-force traffic from botnets | CI/local environments are never targeted; public IPs are scanned constantly |
| Configuration drift between "what we tested" and "what's actually deployed" | Only a risk once infra is provisioned outside of a single controlled dev machine |

## Compliance Note (MAS TRM, PDPA)
MAS TRM expects documented resilience (RPO/RTO — see Step 7) and access
logging for systems handling financial data before go-live. PDPA's
Protection Obligation extends to infrastructure configuration, not just
application code — a misconfigured storage bucket or missing TLS
enforcement is itself a PDPA compliance failure, independent of any bug
in our own code.
```

### ✅ The Verification

```bash
grep -c "^|" docs/DEPLOYMENT-ARCHITECTURE.md
```
Expected: a non-zero count confirming the threat table rendered. Keep this doc open as our checklist for the rest of this part.

---

## Step 2 — Implement Security Headers (CSP, HSTS, and More)

### 🎯 The Target
`middleware.ts` (extended from Part 3) and `next.config.ts`, adding a full suite of security response headers — closing the exact `WARN` findings ZAP raised in Part 5.

### 💡 The Concept
HTTP security headers are instructions your server gives to the *browser* about how to defend itself on your behalf — like a host handing every guest a laminated card the moment they walk in: "don't accept packages through the mail slot from strangers" (CSP), "always use the front door with the deadbolt, never the back door" (HSTS), "you're not allowed to be photographed through someone else's window" (X-Frame-Options). The browser enforces these rules; our server just has to ask clearly, on every single response.

**Content-Security-Policy (CSP)** is the most powerful of these: it tells the browser exactly which sources of scripts, styles, images, and connections are legitimate — so even if an attacker somehow got a malicious `<script>` tag onto our page (say, a stored-XSS bug we hadn't caught), the browser would simply *refuse to execute it*, because it didn't come from an allowlisted source. This is a genuine last-resort safety net, Defense in Depth applied at the browser layer.

We use a **nonce-based** CSP (a nonce — "number used once" — is a random value generated fresh on every single request) rather than a static `unsafe-inline` allowance, because a static allowance would defeat the entire point: it would let *any* inline script execute, including an attacker's injected one.

### 🛠️ The Implementation

##### 📄 File: `middleware.ts` (complete file, extended from Part 3)
```typescript
// middleware.ts
//
// Extends Part 3's RBAC enforcement with security response headers,
// generated fresh on every request.

import { NextResponse } from "next/server";
import { auth } from "@/auth";

const ADMIN_ROUTE_PREFIXES = ["/admin", "/api/v1/admin", "/api/v1/instruments/create"];
const AUDITOR_OR_ADMIN_ROUTE_PREFIXES = ["/api/v1/audit-logs", "/audit-logs"];
const AUTHENTICATED_ROUTE_PREFIXES = ["/dashboard", "/api/v1/orders", "/api/v1/users/me"];

function matchesAny(pathname: string, prefixes: string[]): boolean {
  return prefixes.some((p) => pathname === p || pathname.startsWith(p + "/"));
}

// Generates a fresh, cryptographically random nonce for THIS request only.
// Reused for every <script> tag we intentionally render server-side, and
// checked by the browser against the CSP header — any script WITHOUT this
// exact nonce is refused, including anything an attacker injects.
function generateNonce(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes));
}

function buildCspHeader(nonce: string): string {
  const directives = [
    // default-src 'self': the fallback rule for any resource type not
    // explicitly listed below — deny everything except our own origin.
    `default-src 'self'`,
    // script-src: only scripts carrying today's nonce, or from our own
    // origin, may execute. 'strict-dynamic' lets a trusted (nonced)
    // script load further scripts it needs (e.g. Next.js's own chunks)
    // without us having to allowlist every internal bundle path by hand.
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    `style-src 'self' 'unsafe-inline'`, // Next.js/Tailwind inline styles; tightened further once a nonce-per-style pipeline is added
    `img-src 'self' data: https:`,
    `font-src 'self' data:`,
    // connect-src: restricts which origins client-side fetch/XHR/WebSocket
    // calls may target — our own origin plus Supabase (for any future
    // client-side realtime features) and Sentry (Step 6).
    `connect-src 'self' https://*.supabase.co https://*.sentry.io`,
    `frame-ancestors 'none'`, // equivalent to (and stronger than) X-Frame-Options: DENY — closes clickjacking
    `base-uri 'self'`, // prevents an injected <base> tag from redirecting all relative URLs elsewhere
    `form-action 'self'`, // our forms may only submit to our own origin
    `object-src 'none'`, // blocks <object>/<embed> — a legacy but still-real injection vector
    `upgrade-insecure-requests`, // instructs the browser to auto-upgrade any accidental http:// sub-resource to https://
  ];
  return directives.join("; ");
}

export default auth((req) => {
  const { nextUrl } = req;
  const pathname = nextUrl.pathname;

  const isLoggedIn = !!req.auth?.user;
  const role = req.auth?.user?.role;

  const isAdminRoute = matchesAny(pathname, ADMIN_ROUTE_PREFIXES);
  const isAuditorRoute = matchesAny(pathname, AUDITOR_OR_ADMIN_ROUTE_PREFIXES);
  const isAuthenticatedRoute = matchesAny(pathname, AUTHENTICATED_ROUTE_PREFIXES);
  const requiresLogin = isAdminRoute || isAuditorRoute || isAuthenticatedRoute;

  if (requiresLogin && !isLoggedIn) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
    return NextResponse.redirect(new URL("/login", nextUrl));
  }
  if (isAdminRoute && role !== "ADMIN") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }
  if (isAuditorRoute && role !== "ADMIN" && role !== "AUDITOR") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const nonce = generateNonce();

  // Pass the nonce forward to Server Components via a request header, so
  // any inline <script> WE deliberately render (rare, but e.g. analytics
  // snippets) can read it and tag itself correctly. See app/layout.tsx.
  const requestHeaders = new Headers(req.headers);
  requestHeaders.set("x-nonce", nonce);

  const response = NextResponse.next({ request: { headers: requestHeaders } });

  // --- Security headers applied to EVERY response ---
  response.headers.set("Content-Security-Policy", buildCspHeader(nonce));

  // HSTS: once a browser sees this header even ONCE, it refuses to ever
  // connect to this exact domain over plain HTTP again, for the next
  // 2 years (63072000 seconds) — even if a user deliberately types
  // "http://" or clicks an old bookmark. includeSubDomains extends this
  // to every subdomain; preload opts into browsers' hardcoded HSTS list
  // (see Reference section for what "preload" really commits you to).
  response.headers.set(
    "Strict-Transport-Security",
    "max-age=63072000; includeSubDomains; preload"
  );

  // Prevents this page from EVER being rendered inside a <frame>/<iframe>
  // on any other site — the classic clickjacking defense. CSP's
  // frame-ancestors above is the modern, more flexible equivalent; we
  // keep this header too for older browsers that don't respect CSP.
  response.headers.set("X-Frame-Options", "DENY");

  // Stops the browser from trying to "guess" a file's type from its
  // content instead of trusting the declared Content-Type — closes a
  // class of attack where a file uploaded as "image.jpg" is actually
  // executable script content that some browsers would otherwise sniff
  // and run.
  response.headers.set("X-Content-Type-Options", "nosniff");

  // Controls how much of OUR OWN url is leaked to external sites when a
  // user clicks an outbound link from our app — sends only the origin,
  // never the full path/query (which might contain sensitive parameters).
  response.headers.set("Referrer-Policy", "strict-origin-when-cross-origin");

  // Explicitly disables powerful browser APIs we never use, so that even
  // if an attacker injected code somehow, it couldn't access the
  // microphone/camera/geolocation through this origin.
  response.headers.set(
    "Permissions-Policy",
    "camera=(), microphone=(), geolocation=(), payment=()"
  );

  // Removes the "X-Powered-By: Next.js" header Next.js sets by default —
  // a small Information Disclosure reduction (T-003 from Part 1): don't
  // hand an attacker a free hint about our exact tech stack.
  response.headers.delete("X-Powered-By");

  return response;
});

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/auth).*)"],
};
```

##### 📄 File: `next.config.ts`
```typescript
// next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Belt-and-suspenders: removes the X-Powered-By header at the framework
  // level too, in case a future code path bypasses middleware entirely
  // (e.g. a static export or an edge case Next.js handles before
  // middleware runs).
  poweredByHeader: false,

  // Applies a baseline set of headers via Next.js's own config, as a
  // second independent layer alongside middleware.ts — Defense in Depth
  // applied to header configuration itself. If middleware.ts is ever
  // accidentally misconfigured or its matcher excludes a path it
  // shouldn't, these still apply.
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
        ],
      },
    ];
  },
};

export default nextConfig;
```

Wire the nonce into `app/layout.tsx` so any future inline script we intentionally add can be tagged correctly:

##### 📄 File: `app/layout.tsx` (edit)
```tsx
// app/layout.tsx
import type { Metadata } from "next";
import { headers } from "next/headers";
import { Providers } from "./providers";
import "./globals.css";

export const metadata: Metadata = {
  title: "SecureTrade",
  description: "A simplified, security-first SGX-style trading app",
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  // Reads the nonce middleware.ts generated for THIS specific request —
  // available to Server Components via the forwarded request header.
  const nonce = (await headers()).get("x-nonce") ?? undefined;

  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
        {/* Example of how a future inline script would be tagged — no
            inline script exists yet, this just documents the pattern. */}
        {/* <script nonce={nonce}>...</script> */}
      </body>
    </html>
  );
}
```

### ✅ The Verification

```bash
npm run dev
curl -sI http://localhost:3000 | grep -Ei "content-security-policy|strict-transport-security|x-frame-options|x-content-type-options|referrer-policy|permissions-policy|x-powered-by"
```
Expected: every header except `x-powered-by` appears (confirm `x-powered-by` is **absent** — its absence is the correct, verified outcome). Then confirm the nonce actually changes per-request:
```bash
curl -sI http://localhost:3000 | grep -o "nonce-[A-Za-z0-9+/=]*"
curl -sI http://localhost:3000 | grep -o "nonce-[A-Za-z0-9+/=]*"
```
Expected: two **different** nonce values, proving it's freshly generated every request, not a hardcoded constant.

---

## Step 3 — Test the CSP Actually Blocks Injected Scripts

### 🎯 The Target
A live browser test proving the CSP genuinely stops an injected script from executing — not just that the header exists, but that it *works*.

### 💡 The Concept
A header that exists but doesn't actually get enforced is worse than no header at all — it creates false confidence. This step is the CSP equivalent of Part 3's "break it first" pattern: we deliberately try to violate our own policy and confirm the browser refuses.

### 🛠️ The Implementation

No new file — this is a manual browser verification. Open `http://localhost:3000` in Chrome, open DevTools Console, and run:

```javascript
// Attempt to inject and execute a script WITHOUT the correct nonce —
// exactly what a successful XSS injection would try to do.
const s = document.createElement("script");
s.textContent = "alert('XSS should be BLOCKED by CSP')";
document.body.appendChild(s);
```

### ✅ The Verification

Expected: **no alert box appears.** The DevTools Console instead shows a red error like:
```
Refused to execute inline script because it violates the following Content Security Policy directive: "script-src 'self' 'nonce-...' 'strict-dynamic'". Either the 'unsafe-inline' keyword, a hash ('sha256-...'), or a nonce ('nonce-...') is required to enable inline execution.
```
This is exactly what closes any *future* stored-XSS bug (even one Part 3's fixes and Part 5's ZAP scan somehow both missed) at the browser layer — the last line of Defense in Depth.

---

## Step 4 — Configure Vercel WAF, Rate Limiting, and CORS

### 🎯 The Target
Vercel's native Web Application Firewall (WAF) and rate-limiting rules, configured via `vercel.json`, closing threat T-004 (DoS via request flooding) from Part 1 at the infrastructure layer — separate from and in addition to any application-level rate limiting.

### 💡 The Concept
A **WAF** sits in front of your entire application and inspects traffic patterns *before* any of your code runs at all — like a bouncer checking IDs at the club entrance, long before anyone reaches the bar. This matters because our Part 3 rate-limiting design was scoped to specific routes in application logic; a WAF-layer rule protects the *entire* domain, including routes we haven't thought to protect yet, and can block traffic based on patterns (request rate, geographic anomalies, known bad IP reputation) our application code has no visibility into at all.

### 🛠️ The Implementation

##### 📄 File: `vercel.json`
```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "github": {
    "silent": false
  },
  "headers": [
    {
      "source": "/api/v1/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "no-store"
        }
      ]
    }
  ]
}
```

Note: `Cache-Control: no-store` on every API route is itself a security-relevant configuration — it prevents any intermediate cache (a corporate proxy, a shared CDN edge) from ever storing a response that might contain another user's financial data, closing a subtle variant of the Information Disclosure threat (T-008) at the HTTP caching layer.

Now configure the WAF and rate limiting in the Vercel dashboard (Firewall rules are not yet fully expressible in `vercel.json` at the time of writing, so this part is configured via the dashboard, with the exact settings documented below for reproducibility):

1. Go to your Vercel project → **Firewall** tab.
2. Under **Rate Limiting**, click **Add Rule**:
   - Name: `login-endpoint-limit`
   - Path: `/api/v1/auth/login`
   - Limit: `5` requests per `5 minutes`, scoped by **IP Address**
   - Action: `Deny` (returns HTTP 429)
3. Add a second rule:
   - Name: `global-api-limit`
   - Path: `/api/v1/*`
   - Limit: `100` requests per `1 minute`, scoped by **IP Address**
   - Action: `Deny`
4. Under **Managed Rules**, enable Vercel's **OWASP Core Ruleset** (blocks common attack signatures — SQLi/XSS payload patterns — at the edge, before they reach your Next.js server at all, functioning as a network-level second opinion alongside our application-level defenses from Part 3).
5. Under **Bot Protection**, enable **Challenge suspected bots** for all routes except `/api/v1/instruments` (which should remain crawlable/publicly fast, since it serves only public market data).

##### 📄 File: `docs/WAF-CONFIG.md`
```markdown
# SecureTrade — Vercel WAF & Rate Limiting Configuration

Configured via the Vercel Dashboard → Firewall tab (not fully expressible
in `vercel.json` as of this writing — documented here for reproducibility
and audit purposes, per MAS TRM's expectation of documented configuration).

## Rate Limit Rules
| Rule Name | Path | Limit | Scope | Action |
|---|---|---|---|---|
| login-endpoint-limit | `/api/v1/auth/login` | 5 req / 5 min | Per IP | Deny (429) |
| global-api-limit | `/api/v1/*` | 100 req / 1 min | Per IP | Deny (429) |

Matches the design specified in `docs/API-DESIGN.md` (Part 2) — this is
the infrastructure-layer ENFORCEMENT of that design, closing T-004.

## Managed Rules
- OWASP Core Ruleset: ENABLED (blocks common SQLi/XSS/LFI attack
  signatures at the edge, before reaching application code)
- Bot Challenge: ENABLED on all routes except `/api/v1/instruments`
  (public market data — must remain fast and crawlable)

## CORS Policy
No `Access-Control-Allow-Origin` header is set for any route — the
default, most restrictive posture (Secure Defaults, Part 2). Our own
frontend never needs CORS since it's same-origin; if a future partner
integration requires cross-origin API access, it will be added as an
explicit, narrowly-scoped exception here, never a wildcard `*`.
```

### ✅ The Verification

Deploy to a preview (push any commit), then load-test the login endpoint against the live preview URL:

```bash
PREVIEW_URL="https://your-preview-url.vercel.app"
for i in {1..8}; do
  curl -s -o /dev/null -w "Request $i: %{http_code}\n" \
    -X POST "$PREVIEW_URL/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"wrong"}'
done
```
Expected: the first ~5 requests return `401` (invalid credentials, handled by our app), and requests 6, 7, 8 return `429 Too Many Requests` — the WAF-level limit engaging exactly as configured, entirely before our application code even runs.

---

## Step 5 — Infrastructure as Code with Terraform

### 🎯 The Target
Terraform configuration codifying the AWS S3 bucket and IAM role from Part 5 (previously created via one-off `aws` CLI commands) — now version-controlled, reviewable, and reproducible.

### 💡 The Concept
Every AWS resource we created in Part 5 (Step 7) exists only as a memory of commands someone once typed into a terminal. If that bucket were accidentally deleted, or you needed to stand up an identical staging environment, you'd be reconstructing it from documentation and hoping you remembered every flag correctly. **Terraform** (an Infrastructure as Code tool) turns infrastructure into a text file describing the *desired end state* — like an architectural blueprint that a construction crew (Terraform's engine) can execute identically, any number of times, on any environment, with git-reviewable diffs showing exactly what changed between versions. This is the same underlying value as the Prisma migrations from Part 2 (a recorded, versioned change log) — applied to cloud infrastructure instead of database schema.

### 🛠️ The Implementation

```bash
mkdir -p infra
```

##### 📄 File: `infra/main.tf`
```hcl
# infra/main.tf

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state storage: Terraform's own state file (which tracks what
  # currently exists) must NEVER live only on one engineer's laptop — if
  # that laptop is lost, nobody else can safely know the infrastructure's
  # true state. This bucket must be created ONCE, manually, before running
  # `terraform init` here (a classic bootstrapping chicken-and-egg problem
  # every IaC setup has to solve once).
  backend "s3" {
    bucket         = "securetrade-terraform-state"
    key            = "securetrade/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "securetrade-terraform-locks" # prevents two people running `terraform apply` simultaneously and corrupting state
  }
}

provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Project     = "securetrade"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

variable "environment" {
  description = "Deployment environment name (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "github_repo" {
  description = "GitHub repo in owner/name format, used to scope the OIDC trust policy"
  type        = string
}

# --- S3 bucket for security artifacts (SBOMs, ZAP reports) ---
# Secure Defaults applied throughout: private by default, encrypted by
# default, versioned by default — none of these require a human to
# remember to configure them correctly after the fact.
resource "aws_s3_bucket" "security_artifacts" {
  bucket = "securetrade-security-artifacts"
}

resource "aws_s3_bucket_public_access_block" "security_artifacts" {
  bucket                  = aws_s3_bucket.security_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "security_artifacts" {
  bucket = aws_s3_bucket.security_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning means an accidental (or malicious) overwrite/deletion doesn't
# permanently destroy history — directly supports the immutable-audit-
# trail philosophy from Part 1/Part 2's AuditLog design, applied here to
# infrastructure-level artifacts instead of application-level records.
resource "aws_s3_bucket_versioning" "security_artifacts" {
  bucket = aws_s3_bucket.security_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- OIDC provider trusting GitHub Actions ---
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# --- IAM role GitHub Actions assumes via OIDC — scoped to main branch only ---
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_artifacts" {
  name               = "securetrade-github-actions-artifacts"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

data "aws_iam_policy_document" "s3_upload_only" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.security_artifacts.arn}/*"]
  }
}

resource "aws_iam_role_policy" "s3_upload_only" {
  name   = "s3-upload-only"
  role   = aws_iam_role.github_actions_artifacts.id
  policy = data.aws_iam_policy_document.s3_upload_only.json
}

output "artifacts_role_arn" {
  value       = aws_iam_role.github_actions_artifacts.arn
  description = "ARN to store as the AWS_ARTIFACTS_ROLE_ARN GitHub Actions variable"
}
```

##### 📄 File: `infra/.gitignore`
```
# infra/.gitignore
# Terraform's local state cache and variable files may contain sensitive
# values — never commit them, even though the actual state lives remotely
# in S3 (configured above). This is the exact same secrets-hygiene
# principle from docs/SECRETS-POLICY.md, applied to infrastructure code.
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
!*.tfvars.example
```

##### 📄 File: `infra/terraform.tfvars.example`
```hcl
# Copy to terraform.tfvars (git-ignored) and fill in your real values.
environment = "production"
github_repo = "yourusername/securetrade"
```

Bootstrap the one-time remote state bucket and lock table (this is the only infrastructure in this whole series still created manually — a well-known, unavoidable Terraform chicken-and-egg step, documented here rather than hidden):

```bash
aws s3api create-bucket \
  --bucket securetrade-terraform-state \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

aws s3api put-bucket-versioning \
  --bucket securetrade-terraform-state \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name securetrade-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

Now import the existing resources from Part 5 (created via raw CLI) into Terraform's management, rather than destroying and recreating them:

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual github_repo value

terraform init

terraform import aws_s3_bucket.security_artifacts securetrade-security-artifacts
terraform import aws_iam_openid_connect_provider.github_actions \
  "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
terraform import aws_iam_role.github_actions_artifacts securetrade-github-actions-artifacts
```

### ✅ The Verification

```bash
terraform plan
```
Expected: after importing, the plan should show **no changes needed** (or only minor, expected additions like the versioning/encryption resources if they weren't set via the original CLI commands — apply those specifically):

```bash
terraform apply
```
Type `yes` when prompted. Then confirm the state is genuinely stored remotely, not just locally:
```bash
aws s3 ls s3://securetrade-terraform-state/securetrade/
```
Expected: `terraform.tfstate` is listed — proving any teammate could `terraform init` against this same backend and see identical, shared infrastructure state.

---

## Step 6 — Integrate Sentry for Error and Security Event Monitoring

### 🎯 The Target
Sentry wired into both client and server code, capturing unhandled errors — laying the groundwork for the alerting work in Part 7.

### 💡 The Concept
Right now, if something goes wrong in production — an unhandled exception, a failed database query — the only record is a `console.error` line buried in Vercel's function logs, which nobody is actively watching. **Sentry** is like installing a proper alarm system that not only detects a break-in but immediately calls a specific phone number with the exact time, location, and details — instead of a login-book that only reveals a break-in happened if someone thinks to flip back through the pages later.

### 🛠️ The Implementation

```bash
npx @sentry/wizard@latest -i nextjs
```
This wizard prompts you to log in/create a free Sentry account, select your project, and automatically generates the config files below (shown here in their final, reviewed form — the wizard's output, with our own security-conscious comments and one important edit: scrubbing PII before it's sent).

##### 📄 File: `sentry.client.config.ts`
```typescript
// sentry.client.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,

  // Captures 100% of errors, but only a SAMPLE of performance traces —
  // full performance tracing on every request would be costly and
  // unnecessary; errors, by contrast, we always want to know about.
  tracesSampleRate: 0.1,

  // PDPA-conscious: strip anything that looks like it could be personal
  // data BEFORE it ever leaves the browser and reaches Sentry's servers.
  // This directly implements REQ-10 from Part 1 (data minimization in
  // outbound communications) — Sentry is a third-party service, so
  // anything we send it is functionally the same as TB-5 from Part 1's
  // trust boundaries.
  beforeSend(event) {
    if (event.request?.cookies) {
      delete event.request.cookies; // session tokens must NEVER reach a third party
    }
    if (event.user?.email) {
      // Keep enough to correlate reports to an account without sending
      // the raw, PDPA-classified email address itself.
      event.user.email = undefined;
    }
    return event;
  },
});
```

##### 📄 File: `sentry.server.config.ts`
```typescript
// sentry.server.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,

  beforeSend(event) {
    // Server-side errors can carry FAR more sensitive context than
    // client-side ones (full request bodies, headers including cookies,
    // stack frames referencing internal file paths) — scrub aggressively.
    if (event.request) {
      delete event.request.cookies;
      if (event.request.headers) {
        delete event.request.headers["authorization"];
        delete event.request.headers["cookie"];
      }
      // Never send raw request bodies — they may contain passwords
      // (registration/login) or full financial order details.
      delete event.request.data;
    }
    return event;
  },
});
```

##### 📄 File: `.env.local` (append)
```bash
NEXT_PUBLIC_SENTRY_DSN="https://your-real-dsn@o000000.ingest.sentry.io/0000000"
SENTRY_AUTH_TOKEN="your-sentry-auth-token-for-sourcemap-uploads"
```

##### 📄 File: `.env.example` (append)
```bash
NEXT_PUBLIC_SENTRY_DSN="get from Sentry project settings"
SENTRY_AUTH_TOKEN="get from Sentry: Settings > Auth Tokens"
```

Add a deliberate, safe test error route so we can verify the entire pipeline end-to-end without waiting for a real production bug:

##### 📄 File: `app/api/v1/debug/sentry-test/route.ts`
```typescript
// app/api/v1/debug/sentry-test/route.ts
//
// A deliberately-thrown error, ONLY for verifying the Sentry pipeline
// works end-to-end. Guarded so it can NEVER be triggered in production —
// closes off this becoming an unintended, permanent DoS/noise vector.

import { NextResponse } from "next/server";

export async function GET() {
  if (process.env.VERCEL_ENV === "production") {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  throw new Error("Intentional test error to verify Sentry integration");
}
```

### ✅ The Verification

```bash
npm run dev
curl -s http://localhost:3000/api/v1/debug/sentry-test
```
Expected: a 500 response locally, and within ~30 seconds, a new issue titled **"Intentional test error to verify Sentry integration"** appears in your Sentry dashboard under **Issues**. Click into it and confirm the stack trace is readable (not minified gibberish — the wizard's source map upload step handles this), and confirm no `cookie` or `authorization` header appears anywhere in the captured request context.

---

## Step 7 — Backup, Disaster Recovery, and RPO/RTO

### 🎯 The Target
`docs/DISASTER-RECOVERY.md` — documented, tested backup configuration for Supabase, with explicit RPO/RTO targets.

### 💡 The Concept
Two terms that sound similar but answer very different questions:
- **RPO (Recovery Point Objective)**: "How much data can we afford to lose?" — if backups run every 24 hours and disaster strikes right before the next backup, you lose up to 24 hours of data. Think of it like how far back your last "auto-save" was in a word processor before a crash.
- **RTO (Recovery Time Objective)**: "How long can we afford to be down?" — the time it takes to actually restore from that backup and be fully operational again. Think of it like how long it takes the fire department to arrive, not how much smoke damage already happened.

For a financial trading app, both numbers matter enormously and for different reasons: a large RPO means real trades could simply vanish (a direct MAS TRM concern); a large RTO means real money is inaccessible to real users for an extended period (a business continuity and reputational concern).

### 🛠️ The Implementation

In the Supabase dashboard: **Project Settings → Add-ons → Point in Time Recovery (PITR)** — enable this (available on paid tiers; the free tier defaults to daily backups only, which we document honestly below as a current limitation).

##### 📄 File: `docs/DISASTER-RECOVERY.md`
```markdown
# SecureTrade — Disaster Recovery Plan

## Recovery Objectives

| Metric | Target | Current Actual (Supabase Free Tier) |
|---|---|---|
| RPO (max acceptable data loss) | 5 minutes | 24 hours (daily backup only — see limitation below) |
| RTO (max acceptable downtime) | 1 hour | ~2-4 hours (manual restore process, untested at scale) |

**Documented limitation**: Supabase's free tier provides only daily
backups, not continuous Point-in-Time Recovery (PITR). This means our
CURRENT actual RPO (24 hours) does not yet meet our TARGET RPO (5
minutes) — this gap is intentionally and honestly documented here rather
than hidden, with a clear remediation path below. This is exactly the
kind of gap MAS TRM expects an organization to identify and track, not
pretend doesn't exist.

**Remediation plan**: upgrade to a Supabase paid tier with PITR enabled
before accepting real financial transaction volume in production —
tracked as a pre-launch blocking item in Part 8's final checklist.

## Backup Configuration
- **Database**: Supabase automatic daily backups (upgrade path: PITR,
  giving continuous backup with minute-level granularity).
- **Encryption**: backups are encrypted at rest by Supabase by default.
- **Retention**: 7 days on free tier; 30 days on Pro tier.

## What Is NOT Backed Up (and why that's acceptable)
- **Vercel deployment artifacts**: not needed — the Git repository IS the
  source of truth; any deployment can be rebuilt identically from any
  commit via CI/CD (Part 5), by design. This is itself a form of DR: our
  entire application layer is reproducible from version control alone.
- **CI/CD secrets**: intentionally never backed up outside their
  respective secret stores (GitHub Secrets, Vercel env vars) — a backup
  of a secret is itself a new copy of that secret, working against
  docs/SECRETS-POLICY.md's minimization principle.

## Restore Procedure (Tested — see verification log below)
1. In Supabase dashboard → Database → Backups, select the desired
   restore point.
2. Click "Restore" — Supabase provisions a new database instance from
   the backup (does NOT overwrite the live database automatically).
3. Update `DATABASE_URL`/`DIRECT_URL` in Vercel's environment variables
   to point at the restored instance, OR use Supabase's "point current
   project at this restore" option if performing a full rollback.
4. Redeploy the Vercel project (forces all serverless functions to pick
   up the new connection string on next cold start).
5. Verify: run `npm run db:studio` against the restored database and
   confirm expected record counts/recent data are present.

## Test Log
| Date | Performed By | Result | Notes |
|---|---|---|---|
| _(fill in after first DR drill)_ | | | Schedule the first drill before Part 8's final project sign-off |
```

### ✅ The Verification

```bash
# Confirm backups are actually enabled and recent, via the Supabase
# Management API (requires a personal access token from
# Supabase dashboard → Account → Access Tokens)
curl -s "https://api.supabase.com/v1/projects/YOUR_PROJECT_REF/database/backups" \
  -H "Authorization: Bearer YOUR_SUPABASE_ACCESS_TOKEN" | python3 -m json.tool
```
Expected: a JSON array showing at least one backup entry with a recent timestamp. Schedule an actual restore drill (to a throwaway test project, never production) before Part 8 — record the real result in the Test Log table above rather than leaving it hypothetical.

---

## Step 8 — Automate Verification of Part 6

### 🎯 The Target
`scripts/verify-part6.ts` — checks security headers are actually present on a live response, Terraform files are valid, and all documentation exists.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-part6.ts`
```typescript
// scripts/verify-part6.ts

import { existsSync, readFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";

type Check = { label: string; pass: boolean; detail?: string };
const checks: Check[] = [];

function fileExists(p: string): boolean {
  return existsSync(join(process.cwd(), p));
}

async function checkHeaders(baseUrl: string) {
  try {
    const res = await fetch(baseUrl, { redirect: "manual" });
    const requiredHeaders = [
      "content-security-policy",
      "strict-transport-security",
      "x-frame-options",
      "x-content-type-options",
      "referrer-policy",
      "permissions-policy",
    ];
    for (const h of requiredHeaders) {
      checks.push({
        label: `Response includes ${h} header`,
        pass: res.headers.has(h),
      });
    }
    checks.push({
      label: "X-Powered-By header is absent",
      pass: !res.headers.has("x-powered-by"),
    });
  } catch (err) {
    checks.push({
      label: `Could not reach ${baseUrl} to check headers (is 'npm run dev' running?)`,
      pass: false,
    });
  }
}

async function main() {
  const requiredFiles = [
    "docs/DEPLOYMENT-ARCHITECTURE.md",
    "docs/WAF-CONFIG.md",
    "docs/DISASTER-RECOVERY.md",
    "vercel.json",
    "infra/main.tf",
    "infra/.gitignore",
    "sentry.client.config.ts",
    "sentry.server.config.ts",
  ];
  for (const f of requiredFiles) {
    checks.push({ label: `File exists: ${f}`, pass: fileExists(f) });
  }

  await checkHeaders("http://localhost:3000");

  if (fileExists("infra/main.tf")) {
    try {
      execSync("terraform fmt -check", { cwd: join(process.cwd(), "infra"), stdio: "pipe" });
      checks.push({ label: "Terraform files are correctly formatted", pass: true });
    } catch {
      checks.push({ label: "Terraform files are correctly formatted", pass: false });
    }
    try {
      execSync("terraform validate", { cwd: join(process.cwd(), "infra"), stdio: "pipe" });
      checks.push({ label: "Terraform configuration is syntactically valid", pass: true });
    } catch {
      checks.push({ label: "Terraform configuration is syntactically valid", pass: false });
    }
  }

  if (fileExists("docs/DISASTER-RECOVERY.md")) {
    const dr = readFileSync(join(process.cwd(), "docs/DISASTER-RECOVERY.md"), "utf-8");
    checks.push({
      label: "DR doc defines both RPO and RTO targets",
      pass: dr.includes("RPO") && dr.includes("RTO"),
    });
  }

  console.log("\nSecureTrade — Part 6 Verification\n");
  let allPassed = true;
  for (const c of checks) {
    const icon = c.pass ? "✅" : "❌";
    console.log(`${icon} ${c.label}${c.detail ? ` (${c.detail})` : ""}`);
    if (!c.pass) allPassed = false;
  }
  console.log(
    allPassed
      ? "\nAll Part 6 checks passed. Ready for Part 7.\n"
      : "\nSome checks failed — fix the items above before continuing.\n"
  );
  process.exit(allPassed ? 0 : 1);
}

main();
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "verify:part6": "tsx scripts/verify-part6.ts"
  }
}
```

### ✅ The Verification

With `npm run dev` running in one terminal:
```bash
npm run verify:part6
```
All checks should print ✅. Commit everything:

```bash
git add -A
git commit -m "feat: security headers (CSP/HSTS), Vercel WAF + rate limiting, Terraform IaC, Sentry monitoring, DR plan"
git push
```

---

## ✅ Part 6 Completion Checklist

- [ ] CSP, HSTS, X-Frame-Options, and other security headers present on every response, verified live
- [ ] CSP genuinely blocks an injected inline script in a real browser test
- [ ] Vercel WAF + rate limiting configured and verified with a live load test (429s observed)
- [ ] Terraform manages the S3 bucket + IAM OIDC role from Part 5, with remote state in S3+DynamoDB
- [ ] Sentry captures a real test error end-to-end, with cookies/auth headers/request bodies scrubbed
- [ ] `docs/DISASTER-RECOVERY.md` honestly documents current RPO/RTO gaps and a remediation path
- [ ] `npm run verify:part6` exits all green

---

# 📚 Reference Section — Deep Dives for Part 6

### R1. CSP Directives — Full Reference

| Directive | Controls | Our Setting | Why |
|---|---|---|---|
| `default-src` | Fallback for unlisted resource types | `'self'` | Deny-by-default, Secure Defaults |
| `script-src` | Where JS may load/execute from | `'self' 'nonce-X' 'strict-dynamic'` | Blocks all unauthorized script execution, including injected XSS |
| `style-src` | Where CSS may load from | `'self' 'unsafe-inline'` | Next.js/Tailwind require inline styles currently; a stricter nonce-per-style setup is a future hardening step |
| `frame-ancestors` | Who may iframe this page | `'none'` | Total clickjacking prevention |
| `object-src` | `<object>`/`<embed>` sources | `'none'` | Legacy plugin-based injection vector, fully closed |
| `upgrade-insecure-requests` | Auto-upgrades http:// sub-resources | (flag, no value) | Defense in depth alongside HSTS |

**CSP Report-Only mode**: before enforcing a new/stricter CSP in a mature production app, you can deploy it as `Content-Security-Policy-Report-Only` first — the browser reports violations to a `report-uri`/`report-to` endpoint without actually blocking anything, letting you catch legitimate breakage before flipping to full enforcement. Worth using for any *future* CSP tightening in SecureTrade.

### R2. HSTS Preload — What You're Really Committing To

Adding `preload` to your HSTS header and submitting your domain to [hstspreload.org](https://hstspreload.org) bakes your domain directly into the source code of Chrome, Firefox, Safari, and Edge — meaning browsers refuse plain HTTP to your domain **even on a user's very first visit**, before your server ever gets to send the HSTS header at all (closing the narrow "first request" gap HSTS alone can't cover). The serious trade-off: removal from the preload list, once shipped in browser releases, can take **months** to propagate out to all users — so only preload a domain you are certain will support HTTPS-only, permanently, forever. Not something to do casually on a domain still under active early development.

### R3. Vercel WAF vs. a Dedicated Cloud WAF (AWS WAF, Cloudflare)

| | Vercel Firewall (what we used) | AWS WAF / Cloudflare |
|---|---|---|
| Setup complexity | Low — dashboard toggles, no separate account | Higher — separate service, own IAM/ACL policies |
| Integration | Native, zero extra latency (same edge network) | An additional network hop, unless already using that provider's CDN |
| Rule sophistication | Good baseline (OWASP Core Ruleset, rate limiting, bot detection) | Extremely deep customization (custom Lambda-based rules, geographic rules, more) |
| Best fit | Small-to-mid apps fully hosted on Vercel (our case) | Large enterprises with multi-cloud or highly custom traffic-shaping needs |

We chose Vercel's native WAF because it matches our deployment target exactly with zero added complexity — a valid, common real-world choice for apps that don't yet need AWS/Cloudflare-level customization.

### R4. Terraform State Security — Why the Backend Bucket Itself Needs Hardening

Terraform's state file is arguably one of the most sensitive files in this entire project — it can contain resource IDs, and depending on the resources managed, sometimes even plaintext secrets in certain provider outputs. This is precisely why: (1) the state bucket has versioning enabled (recoverable from accidental corruption), (2) it's encrypted, and (3) access to it should itself be restricted via IAM policy to only the specific engineers/CI roles that need it — treat your Terraform state bucket with at least the same paranoia as `.env.local`.

### R5. Sentry Alternatives and the Broader Observability Landscape

| Tool | Primary Focus |
|---|---|
| **Sentry** (what we used) | Error tracking + basic performance tracing, excellent Next.js integration |
| **Datadog** | Full-stack observability — logs, metrics, traces, infrastructure monitoring, all in one platform (heavier, pricier, more powerful at scale) |
| **Better Stack / Logtail** | Simpler, log-centric, often more affordable for smaller teams |
| **Grafana + Prometheus + Loki** (self-hosted) | Full control and no per-seat/per-event pricing, at the cost of operating the monitoring stack yourself |

We chose Sentry specifically for its low setup friction and first-class Next.js support — Part 7 builds directly on this same Sentry integration for security-specific alerting (e.g., "5 failed logins," "admin action performed"), so the investment here compounds.

### R6. The Shared Responsibility Model

A concept worth internalizing explicitly: Vercel is responsible for the physical security of its data centers, the security of its edge network infrastructure, and patching the underlying OS/runtime. **We** remain fully responsible for our application code, our CSP configuration, our database access policies, our secrets management, and our own dependency choices. Cloud providers never absorb 100% of security responsibility — they shift the boundary, they don't eliminate it. Understanding exactly where that boundary sits for every service you depend on (Vercel, Supabase, AWS) is itself a core security-engineering skill, and one worth explicitly re-examining any time you adopt a new third-party service.

---

**Next up: Part 7 — Detection, Response & Incident Handling**, where we assume breach: build proper security-event logging on top of the Sentry pipeline from this part, define Sigma-style alerting rules, write a full incident response runbook, and — following the series' "break it first" pattern one final time — simulate a real SQL injection attack against SecureTrade and walk through the entire detect-contain-eradicate-recover-postmortem cycle ourselves.
