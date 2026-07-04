# From Scripts to Systems: Monorepos and CI/CD Pipelines

Once you’ve standardized workflows with `package.json` scripts, the next step is scaling them across multiple apps, packages, and environments. This is where monorepos and CI/CD pipelines come in.

### Why Monorepos?

A monorepo is a single repository that contains multiple projects—apps, shared libraries, backend services, and more.

Instead of this:

- Separate repos for frontend, backend, UI components

You get:

- One repo with shared dependencies, tooling, and scripts

This is especially powerful in modern stacks like Next.js + API services + shared UI libraries.

### The Problem Scripts Alone Can’t Solve

Basic npm scripts work well in a single project, but they struggle with:

- Coordinating tasks across multiple packages
- Avoiding redundant builds
- Managing dependency relationships between internal packages

This is where tools like Turborepo and Nx step in.

### Turborepo: Script Orchestration at Scale

Turborepo builds on top of your existing scripts and adds intelligent orchestration.

You still write scripts like:

```json
{
  "scripts": {
    "build": "next build",
    "lint": "eslint ."
  }
}
```

But now Turborepo can:

- Run tasks across multiple packages (`apps/web`, `packages/ui`)
- Cache results (locally and remotely)
- Skip work if nothing has changed
- Run tasks in parallel where possible

Example command:

`npx turbo run build`

This executes `build` across all relevant packages, respecting dependency order.

### Key Concept: Task Graph

Turborepo creates a dependency graph between tasks.

For example:

- `apps/web` depends on `packages/ui`
- So `ui` must build before `web`

This is handled automatically—no manual scripting required.

### Nx: A More Opinionated Alternative

Nx provides similar capabilities but with more built-in structure and tooling:

- Code generators
- Dependency graph visualization
- Integrated testing and linting strategies

If Turborepo is lightweight and flexible, Nx is more like a full framework for monorepos.

### Structuring a Monorepo

A typical layout:

```
apps/
  web/
  api/
packages/
  ui/
  config/
```

Each package has its own `package.json`, but shares:

- Root-level dependencies (via workspaces)
- Centralized tooling configs
- A unified script orchestration layer

### Workspaces: The Foundation

npm (and pnpm/yarn) workspaces link everything together:

```json
{
  "workspaces": ["apps/*", "packages/*"]
}
```

This enables:

- Local package linking (no publishing required)
- Shared dependency management
- Faster installs

### CI/CD: Turning Scripts into Pipelines

Once your scripts and monorepo are in place, CI/CD becomes a natural extension.

Instead of inventing new commands, your pipeline simply runs your scripts.

Example (conceptually):

- Install dependencies
- Run `npm run check`
- Run `npm run build`
- Deploy

### Example: GitHub Actions Workflow

A simplified pipeline:

```yaml
name: CI

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm install
      - run: npm run check
      - run: npm run build
```

If you’re using Turborepo:

```yaml
- run: npx turbo run build
```

Now your CI pipeline benefits from:

- Caching
- Parallel execution
- Incremental builds

### The Key Principle: Local = CI = Production

Your scripts should behave the same everywhere:

- On your machine
- In CI
- In production builds

This eliminates the classic “works on my machine” problem.

### Advanced Pattern: Pipeline Optimization

With tools like Turborepo:

- Only affected packages are rebuilt
- Cached outputs are reused
- Deployments become faster and cheaper

For example:

- Change in `ui` → rebuild `ui` and `web`
- No change in `api` → skip entirely

### Where npx Fits at This Level

Even here, npx remains useful for:

- Bootstrapping (`create-turbo`)
- Running tools in CI without global installs
- Trying new tooling before committing to it

But most execution moves into:

- Scripts
- Orchestrators (turbo, nx)

### Mental Model Upgrade

At this stage, your stack looks like this:

- npm → dependency management
- npx → ad hoc execution
- package.json scripts → workflow interface
- Turborepo/Nx → orchestration layer
- CI/CD → automation layer

Each layer builds on the previous one.

### A Practical Example

Imagine a change to a shared UI button:

- You update `packages/ui/button.tsx`
- Turborepo detects the change
- Rebuilds `ui`
- Rebuilds `apps/web` (because it depends on `ui`)
- Skips everything else
- CI runs the same logic automatically

This is the kind of leverage that turns a codebase into a system.
