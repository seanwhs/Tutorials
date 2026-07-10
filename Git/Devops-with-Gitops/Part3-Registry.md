# Part 3: Containerization & Registry

**Module Goal:** Build optimized Docker images in CI and push them to GitHub Container Registry (GHCR).

---

## 1. Concept Explanation

### Why GHCR, and why it matters as free/OSS

**GitHub Container Registry (GHCR)** is GitHub's OCI-compliant image registry, free for public repos and included in the free tier for private repos (with generous storage/bandwidth limits). It's tightly integrated with Actions: authentication piggybacks on the same `GITHUB_TOKEN` already available in every workflow run — no separate Docker Hub account, no extra secret to provision for the basic push path.

### The Two Costs of Naive Docker Builds in CI

1. **Build time** — a naive `docker build` in CI re-downloads and reinstalls every dependency layer on every run, because CI runners start with a cold Docker cache each time.
2. **Image size** — a naive single-stage Dockerfile ships your entire build toolchain (compilers, dev dependencies, source maps) into production, bloating the image and expanding the attack surface (more on this in Part 5).

Both are solved by the same two techniques: **multi-stage builds** and **BuildKit layer caching via GitHub Actions cache (`gha` cache backend)**.

### Image Tagging Strategy (GitOps Principle)

Every image pushed to GHCR should be traceable back to the exact commit that produced it. We tag with the Git SHA (immutable, unambiguous) *and* a mutable convenience tag (`latest`, `main`) for humans. Never deploy `latest` to production — always deploy a pinned SHA tag. This is the container-image equivalent of "the pipeline is the source of truth": `ghcr.io/org/app:a1b2c3d` tells you unambiguously which commit is running in prod, at a glance, without cross-referencing a deploy log.

---

## 2. Implementation

### Step 1 — Multi-Stage Dockerfile

`docker/Dockerfile`:

```dockerfile
# ---- Stage 1: Dependencies ----
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# ---- Stage 2: Build ----
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- Stage 3: Runtime ----
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Run as a non-root user (security best practice, revisited in Part 5)
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

USER nextjs
EXPOSE 3000
ENV PORT=3000

CMD ["npm", "start"]
```

**Why three stages:** `deps` installs only production dependencies (small, cacheable independently). `builder` installs *all* dependencies (including devDependencies needed to build) and compiles the app. `runner` is the final image — it copies only the compiled output and production `node_modules` from the earlier stages, discarding the build toolchain entirely. The final image never contains TypeScript, ESLint, test files, or dev dependencies.

### Step 2 — The Build & Push Workflow

`.github/workflows/docker-build-push.yml`:

```yaml
name: Docker Build and Push to GHCR

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

permissions:
  contents: read
  packages: write   # required to push to GHCR

jobs:
  build-and-push:
    name: Build & Push Docker Image
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build image (and push only on non-PR events)
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ./docker/Dockerfile
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
```

### Step 3 — Design Decisions Explained

1. **`push: ${{ github.event_name != 'pull_request' }}`** — on a PR, we *build* the image (to catch Dockerfile errors and validate the build works) but never *push* it. Pushing unreviewed images to your registry on every PR is both wasteful and a security concern — an attacker opening a malicious PR could otherwise get arbitrary code published as an "official" image under your org's namespace.

2. **`docker/metadata-action`** — auto-generates the tag list based on context: a short Git SHA on every build, the branch name (`main`), a semver tag if you push a `v1.2.3` Git tag, and `latest` **only** when on the default branch. This single action encodes your entire tagging policy declaratively instead of hand-rolling bash string logic.

3. **`cache-from: type=gha` / `cache-to: type=gha,mode=max`** — this tells BuildKit to store and retrieve layer cache using GitHub's Actions cache backend (same underlying storage as `actions/cache`, but BuildKit-native). `mode=max` caches *all* layers, including intermediate build stages — critical for our multi-stage Dockerfile, since without `mode=max` only the final stage's layers get cached, and the `deps`/`builder` stages rebuild from scratch every run.

4. **`platforms: linux/amd64,linux/arm64`** — builds a multi-arch manifest in one step, so the same image tag works on both x86 GHCR-hosted runners *and* ARM-based deployment targets (e.g., AWS Graviton, or Apple Silicon dev machines pulling the image locally) without users needing to know which architecture to pull.

5. **`packages: write` permission, scoped to this job** — GHCR push requires this scope on the `GITHUB_TOKEN`. Note we did *not* grant it at the workflow level in Part 1's style — always scope permissions to the minimum job that needs them.

### Step 4 — Verifying the Push

After a successful run to `main`, your image appears at:
```
https://github.com/<org>/<repo>/pkgs/container/<repo>
```

Pull it locally to verify:
```bash
docker pull ghcr.io/<org>/<repo>:main
docker run -p 3000:3000 ghcr.io/<org>/<repo>:main
```

---

## 3. Exercise Challenge

1. GHCR packages are **private by default** even in public repos, which breaks anonymous `docker pull`. Add a step (or documented manual action) to make the package public, and explain the security tradeoff.
2. Add a `.dockerignore` file — explain in your own words what breaks without one, in the context of Docker build context and caching.
3. Modify the workflow so that pushing a Git tag `v1.2.3` also generates a `v1`, and `v1.2` "rolling" tag (common convenience pattern seen in official Docker images).

---

## 4. Solution & Explanation

**1 — Public visibility:**

GHCR package visibility isn't set via workflow YAML — it's a package-level setting (Package Settings → Change Visibility) or via the GitHub API/`gh` CLI:

```bash
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  /orgs/<org>/packages/container/<repo>/visibility \
  -f visibility='public'
```

**Tradeoff:** Public images can be pulled by anyone, including scanning your image for secrets baked into layers (another reason multi-stage builds matter — see Part 5's secret-scanning coverage) or reverse-engineering your app's internals. Keep private unless there's a clear reason (e.g., publishing an official public SDK image).

**2 — `.dockerignore`:**

```
node_modules
.next
.git
.github
*.md
.env*
coverage
tests
```

Without it, the entire `node_modules` and `.git` history get sent to the Docker build daemon as "build context" on every build — this massively slows down context transfer, and worse, can leak `.env` files or `.git` history containing old secrets directly into image layers if a `COPY . .` instruction isn't scoped carefully. `.dockerignore` is a *security* control, not just a performance one.

**3 — Rolling major/minor tags:**

```yaml
      - name: Extract metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=raw,value=latest,enable={{is_default_branch}}
```

`docker/metadata-action` natively supports the `{{major}}` and `{{major}}.{{minor}}` semver patterns — pushing tag `v1.2.3` now produces four tags in one build: `1.2.3`, `1.2`, `1`, plus the SHA tag. This lets downstream consumers pin to `:1` for "latest patch within major version 1" the same way official base images work.

---

**Next:** Part 4 — Infrastructure as Code with OpenTofu →
