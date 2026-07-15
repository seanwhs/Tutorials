# Part 4: Dependencies & Supply Chain Security

Picking up from Part 3: SecureTrade's own code is now hardened against the OWASP Top 10. But here's an uncomfortable fact — run `npm ls --all | wc -l` in your project right now and you'll likely see **hundreds** of packages, and you personally wrote approximately zero of them. Every one of those is code you're trusting to run on your server, with the same access to your database credentials and `AUTH_SECRET` as your own code.

**Goal recap:** roughly 80% of real-world vulnerabilities in modern apps don't come from bugs *you* wrote — they come from `npm install`. This part builds the tooling to keep that risk visible and under control.

---

## Step 1 — Document the Supply Chain Attack Surface

### 🎯 The Target
`docs/SUPPLY-CHAIN.md` — naming exactly what can go wrong when you depend on third-party packages, before we install any tooling to guard against it.

### 💡 The Concept
Think about a restaurant's supply chain: even a chef who cooks every dish perfectly is still at the mercy of whoever supplies the meat, vegetables, and spices. If one supplier's flour shipment is contaminated, the chef's own skill doesn't matter — the poison is already inside the walls. Your `node_modules` folder is that supply chain. A vulnerability doesn't have to be in code you wrote to end up running with full access to your server.

There are three distinct failure modes here, and they need different defenses:
1. **Known vulnerabilities** in packages you intentionally depend on (a library has a bug, later fixed in a newer version) → solved by **SCA** (Software Composition Analysis).
2. **Malicious packages** deliberately planted to look legitimate (typosquatting, or a maintainer's account being compromised) → solved by vigilance + lockfiles + minimizing dependency count.
3. **Supply chain integrity failures** — the exact code you tested isn't the exact code that gets installed later → solved by **lockfiles** and reproducible installs.

### 🛠️ The Implementation

##### 📄 File: `docs/SUPPLY-CHAIN.md`
```markdown
# SecureTrade — Supply Chain Security

## Why This Matters
As of this writing, `npm ls --all` in this project reports well over 300
transitive packages, from roughly 15 direct dependencies we deliberately
chose. We audited zero lines of the other 285+. Industry research
(Sonatype, Snyk state-of-open-source-security reports) consistently finds
that the large majority of exploited vulnerabilities in modern web apps
originate in dependencies, not first-party code — this is why this part
exists as its own dedicated stage in the series, not a footnote.

## Threat Categories

### 1. Known Vulnerabilities (CVEs)
A dependency (or one of ITS dependencies) has a publicly disclosed
security flaw, tracked as a CVE (Common Vulnerabilities and Exposures
identifier) or a GitHub Security Advisory (GHSA). Example: a vulnerable
version of a JSON parsing library allows a crafted input to cause a
Denial of Service via excessive CPU usage (ReDoS).

Mitigation: SCA tooling (Step 2, Step 4) + a CI gate that blocks merging
new Critical/High vulnerabilities (Step 8).

### 2. Malicious Packages
An attacker publishes a package deliberately designed to steal secrets,
mine cryptocurrency, or install a backdoor — either as:
- **Typosquatting**: a name deliberately similar to a popular package
  (e.g. `expres` instead of `express`, hoping for a typo in an `npm
  install` command).
- **Dependency confusion**: publishing a public package with the same
  name as an organization's INTERNAL private package, tricking build
  tools into pulling the malicious public one instead.
- **Maintainer account compromise / protestware**: a legitimate,
  previously-trustworthy package is altered by its own maintainer,
  either through account takeover or the maintainer's own choice (see the
  `colors.js` case study, Step 6).

Mitigation: minimize total dependency count, pin exact versions, review
diffs on dependency updates, use tools that flag suspicious install-time
behavior (`npm audit signatures`, Socket.dev-style analysis).

### 3. Supply Chain Integrity Failures
The code that gets installed on a teammate's machine, in CI, and in
production is not byte-for-byte identical to what was tested — because a
version range like `^4.2.0` silently resolved to a *different*, newer
4.x version at each of those times.

Mitigation: commit `package-lock.json`, always install with `npm ci` (not
`npm install`) in CI/production (Step 3).

## Our Defense Layers (Defense in Depth, applied to dependencies)
1. **Lockfile discipline** — `package-lock.json` committed, `npm ci` used everywhere except active local development.
2. **SCA scanning** — `npm audit` locally, Dependabot + a CI gate continuously.
3. **SBOM generation** — a complete, versioned inventory of every dependency, for audit and incident-response purposes (Part 7 will use this).
4. **Minimal dependency footprint** — before adding any new package, ask "can I write this in 20 lines myself instead?"
```

### ✅ The Verification

```bash
npm ls --all 2>/dev/null | wc -l
```
Note the number — this is your current total dependency surface. Keep this document open; we'll refer back to it as we build each defense layer.

---

## Step 2 — Run and Interpret `npm audit`

### 🎯 The Target
A clean (or triaged) `npm audit` report — our first, most basic SCA tool, already built into `npm` itself.

### 💡 The Concept
`npm audit` compares every package (and sub-package) in your `package-lock.json` against a public database of known vulnerabilities, then tells you exactly which of your dependencies are affected and how severe each issue is. It's like a food safety inspector checking every ingredient's supplier against a public recall list before a dish reaches a customer — free, fast, and something you should run habitually, not just once.

### 🛠️ The Implementation

```bash
npm audit
```

Read the severity legend it prints (`critical` / `high` / `moderate` / `low`) and try the JSON output, which is what we'll later feed into automated tooling:

```bash
npm audit --json > /tmp/audit-report.json
cat /tmp/audit-report.json | head -c 500
```

If any vulnerabilities appear, try npm's automatic fixer first:

```bash
# Only applies fixes that DON'T change any package's major version —
# i.e., won't introduce breaking changes to your code.
npm audit fix
```

If vulnerabilities remain after `npm audit fix` (common — often the fix requires a major version bump that could break your code), document the decision rather than silently ignoring it:

##### 📄 File: `docs/VULNERABILITY-EXCEPTIONS.md`
```markdown
# SecureTrade — Accepted Vulnerability Exceptions

Any `npm audit` finding NOT immediately fixed must be recorded here with a
justification and a re-review date. Nothing gets silently ignored.

| Package | Advisory | Severity | Reason Not Fixed Yet | Re-review By |
|---|---|---|---|---|
| _(none currently — fill in if `npm audit` reports unfixable findings)_ | | | | |
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "audit:check": "npm audit --audit-level=high"
  }
}
```

`--audit-level=high` makes the command **exit with a non-zero status code** if any `high` or `critical` finding exists — turning a human-readable report into a machine-checkable gate, which is exactly what we wire into CI in Step 8.

### ✅ The Verification

```bash
npm run audit:check
echo "Exit code: $?"
```
Expected: `Exit code: 0` if clean, or a clear list of `high`/`critical` findings plus a non-zero exit code if not — in which case, resolve them with `npm audit fix` or document them above before continuing.

---

## Step 3 — Lockfile Discipline: Why `package-lock.json` Matters

### 🎯 The Target
A verified, committed `package-lock.json`, and every install command in the project (docs, scripts, and soon CI) standardized on `npm ci` instead of `npm install`.

### 💡 The Concept
Your `package.json` says "I want React version `^18.2.0`" — the caret (`^`) means "this version, or any newer compatible version." That's a *range*, not a specific version. `package-lock.json` is the difference between ordering "a coffee" (could be a slightly different roast every single day) and ordering "medium roast, single-origin Ethiopian, roasted March batch #4" (the exact same thing, every time, guaranteed). 

Without a committed lockfile, three different machines running `npm install` on the same `package.json`, on three different days, can each end up with **different actual code** installed — even though nobody changed `package.json` at all. This is exactly the "Supply Chain Integrity Failure" named in Step 1: the version you code-reviewed and tested is not guaranteed to be the version that ends up running in production.

`npm ci` (Clean Install) is the enforcement mechanism: it reads `package-lock.json` **only**, installs those exact versions, and — critically — **fails loudly** if `package.json` and `package-lock.json` have drifted out of sync, instead of silently "fixing" the mismatch for you the way `npm install` would.

### 🛠️ The Implementation

Confirm the lockfile is committed (it should already be, from `create-next-app` in Part 1):

```bash
git ls-files package-lock.json
```
Expected: it prints `package-lock.json`, confirming Git is tracking it.

Now add a `.npmrc` to enforce exact version pinning going forward for anything you add manually:

##### 📄 File: `.npmrc`
```ini
# .npmrc
#
# save-exact: when you run `npm install some-package`, write the EXACT
# resolved version into package.json (e.g. "4.2.1"), not a caret range
# (e.g. "^4.2.1"). This closes the gap between what package.json PROMISES
# and what package-lock.json actually pins, making intent unambiguous at
# a glance in code review — a reviewer sees exactly what version was
# chosen, not a range that could mean many different things over time.
save-exact=true

# engine-strict: refuses to install if the current Node version doesn't
# match the "engines" field in package.json (added below) — catching a
# mismatched Node version BEFORE it causes a subtle, hard-to-debug bug,
# rather than after.
engine-strict=true
```

##### 📄 File: `package.json` (edit — add the `engines` field)
```json
{
  "name": "securetrade",
  "engines": {
    "node": ">=22.0.0"
  }
}
```

Update your local development habit and document it clearly for anyone (including future-you) who clones this repo:

##### 📄 File: `docs/LOCKFILE-POLICY.md`
```markdown
# SecureTrade — Lockfile & Install Policy

## The Rule
- **Local development, adding a NEW dependency**: `npm install <package>`
  (this updates both `package.json` and `package-lock.json` together —
  commit BOTH files in the same commit, never one without the other).
- **Everywhere else** (fresh clone, CI, Docker builds, Vercel deploys):
  `npm ci`, never `npm install`.

## Why
`npm ci`:
1. Deletes `node_modules` first, guaranteeing no leftover stale packages.
2. Installs EXACTLY what `package-lock.json` specifies — no version
   resolution, no surprises.
3. Fails immediately and loudly if `package.json` and
   `package-lock.json` disagree, instead of silently reconciling them.
4. Is measurably faster than `npm install`, since no dependency
   resolution algorithm needs to run.

## Enforcement
- `.npmrc` sets `save-exact=true` so every manually-added dependency is
  pinned to an exact version in `package.json` itself, not just the
  lockfile.
- CI (Part 4 Step 8, extended in Part 5) uses `npm ci` exclusively.
```

### ✅ The Verification

Simulate what CI will do — delete `node_modules` and reinstall strictly from the lockfile:

```bash
rm -rf node_modules
npm ci
```
Expected: installs successfully, with output ending in something like `added 312 packages in 8s` — no warnings about resolving different versions. Then confirm the "fails loudly on drift" behavior:

```bash
# Deliberately edit package.json to require a version that doesn't match
# the lockfile, WITHOUT updating the lockfile:
npm pkg set dependencies.zod="99.0.0"
npm ci
```
Expected: `npm ci` **fails** with an error like `npm ERR! Invalid: lock file's zod@... does not satisfy zod@99.0.0` — exactly the safety net we want. Revert the change:
```bash
git checkout package.json
npm ci
```

---

## Step 4 — Configure Dependabot for Automated Dependency Updates

### 🎯 The Target
`.github/dependabot.yml` — GitHub's native bot that opens pull requests automatically when a dependency has a new version or a known vulnerability.

### 💡 The Concept
`npm audit` and lockfiles are *reactive/defensive* — they tell you when something's already wrong. Dependabot is *proactive* — it's like a smoke detector with a direct line to a handyman: the moment smoke is detected (a new vulnerable version is disclosed, or simply a newer version exists), it doesn't just alert you, it opens a ready-to-review pull request with the fix already drafted. Your job shrinks from "manually check for updates" to "review and approve a PR someone (something) else already prepared."

### 🛠️ The Implementation

##### 📄 File: `.github/dependabot.yml`
```yaml
# .github/dependabot.yml
#
# GitHub-native dependency update automation. No separate account or
# billing needed — this is free on all GitHub repos, public or private.

version: 2
updates:
  # --- npm packages ---
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "03:00"
      timezone: "Asia/Singapore"
    # Group minor/patch updates into a SINGLE pull request instead of one
    # PR per package — a dozen individually trivial version bumps are far
    # easier to review as one batch than as twelve separate PRs.
    groups:
      minor-and-patch:
        update-types:
          - "minor"
          - "patch"
    # Major version bumps often include breaking changes — keep these as
    # SEPARATE, individually-reviewed PRs rather than grouped, since each
    # one may need actual code changes, not just a version number change.
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "automated"
    commit-message:
      prefix: "chore(deps)"

  # --- GitHub Actions workflow versions (relevant from Part 5 onward) ---
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "ci"
    commit-message:
      prefix: "chore(ci)"
```

Enable Dependabot **security updates** (a separate, always-on feature distinct from the version-update schedule above) via the GitHub CLI:

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/{owner}/securetrade/vulnerability-alerts

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/{owner}/securetrade/automated-security-fixes
```
Replace `{owner}` with your GitHub username. These two API calls turn on **Dependabot alerts** (notifies you of known vulnerabilities in your dependency tree) and **Dependabot security updates** (auto-opens a PR specifically for the fix, even outside the weekly schedule, as soon as a vulnerability is disclosed) — these fire immediately, independent of the weekly cadence configured above.

### ✅ The Verification

```bash
git add -A
git commit -m "chore: configure Dependabot for weekly dependency and CI action updates"
git push
```

```bash
gh api /repos/{owner}/securetrade/vulnerability-alerts -i | head -1
```
Expected: `HTTP/2.0 204` (No Content, meaning it's enabled — GitHub's API returns 204 for this check, not 200). Then check the repo's **Insights → Dependency graph → Dependabot** tab in the browser — confirm it shows "Dependabot is enabled."

---

## Step 5 — Install Snyk and OSV-Scanner (Deeper SCA)

### 🎯 The Target
Snyk CLI and Google's OSV-Scanner installed locally, giving a second and third opinion beyond `npm audit`'s built-in database.

### 💡 The Concept
`npm audit` checks against npm's own advisory database — good, but it's one single source. Getting a second medical opinion from a different specialist sometimes catches something the first missed, because each maintains its own independent research and disclosure relationships. **Snyk** maintains its own proprietary vulnerability database (often faster to catalog new issues than public sources) and adds license-compliance checking. **OSV-Scanner** (Open Source Vulnerabilities, backed by Google) queries the community-run OSV.dev database, which aggregates advisories from GitHub, PyPI, npm, Go, and more into one unified, fully open format — valuable specifically because it's vendor-neutral and free forever, unlike Snyk's paid tiers at higher usage.

### 🛠️ The Implementation

```bash
# Snyk CLI
npm install -D snyk

# Authenticate (free tier — opens a browser to sign up/log in)
npx snyk auth
```

##### 📄 File: `package.json` (edit — add scripts)
```json
{
  "scripts": {
    "scan:snyk": "snyk test --severity-threshold=high",
    "scan:osv": "osv-scanner scan --lockfile=package-lock.json"
  }
}
```

Install OSV-Scanner (a standalone Go binary, not an npm package):

```bash
# macOS
brew install osv-scanner

# Linux — download the latest release binary directly
curl -L -o osv-scanner https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_linux_amd64
chmod +x osv-scanner
sudo mv osv-scanner /usr/local/bin/
```

### ✅ The Verification

```bash
npm run scan:snyk
```
Expected output ends with something like `Tested 312 dependencies for known issues, no vulnerable paths found.` (or a clear, specific list if issues exist — resolve or document them in `docs/VULNERABILITY-EXCEPTIONS.md` exactly as in Step 2).

```bash
npm run scan:osv
```
Expected output: a table (empty if clean) — confirm it runs without a fatal error, distinct from `npm audit`, giving us three independent SCA opinions (`npm audit`, Snyk, OSV) all wired up.

---

## Step 6 — Case Study: The `colors.js` Incident (and a Typosquatting Guard)

### 🎯 The Target
`docs/CASE-STUDY-colorsjs.md` documenting the incident, plus `scripts/check-typosquats.ts` — a lightweight guard that flags suspiciously-named new dependencies before they're approved into the project.

### 💡 The Concept
In January 2022, the maintainer of two enormously popular npm packages — `colors.js` (20+ million weekly downloads, used for terminal text coloring) and `faker.js` (a fake-data generator used in countless test suites) — **deliberately sabotaged his own packages**, pushing an update that printed an infinite loop of garbage characters (including the text "LIBERTY LIBERTY LIBERTY") to the console of every application that updated to the new version, effectively a self-inflicted Denial of Service. This wasn't a hacker breaking in — it was the *legitimate, trusted maintainer* himself, reportedly protesting large corporations profiting from unpaid open-source labor.

This incident is important precisely because it defeats the mental model of "I only need to worry about *malicious outsiders*." A package can turn hostile from **inside**, by its own trusted maintainer, at any time, with a single `npm publish`. Think of it like a trusted employee with a company keycard suddenly deciding to sabotage the building from within — no lock or firewall stops that, because they were never "breaking in" to begin with.

The practical lesson: **lockfiles + pinned exact versions (Step 3) are your primary defense here** — if `colors.js` had been pinned to an exact known-good version rather than a caret range, an `npm install` would never have silently pulled in the sabotaged update at all. A second lesson is minimizing dependency count and preferring long-established, widely-maintained packages over obscure ones for anything security-relevant.

### 🛠️ The Implementation

##### 📄 File: `docs/CASE-STUDY-colorsjs.md`
```markdown
# Case Study: The colors.js / faker.js Incident (January 2022)

## What Happened
The maintainer of `colors.js` and `faker.js` — both extremely popular,
widely-trusted npm packages — intentionally published sabotaged versions
of his own packages. The new version of `colors.js` entered an infinite
loop printing corrupted text to the console, breaking every application
that auto-updated to it via a caret (`^`) version range. This was not a
hack or account compromise — it was the legitimate maintainer's own
deliberate action, reportedly in protest of unpaid open-source labor
being used for profit by large companies.

## Why It Matters for SecureTrade
1. **Trust boundaries include your own dependencies' maintainers** — not
   just "external attackers." A package can turn hostile at any time,
   from a fully legitimate source.
2. **Version ranges are the delivery mechanism.** Any project using
   `"colors": "^1.4.0"` (a caret range) automatically received the
   sabotaged version on its next `npm install`. Any project that had
   pinned an EXACT version and used `npm ci` was unaffected until a
   human deliberately chose to upgrade.
3. **Blast radius depends on dependency depth.** Both packages were often
   pulled in as *transitive* dependencies (a dependency of a dependency)
   — many affected teams didn't even know they used `colors.js` at all
   until their builds broke.

## Our Mitigations (cross-referenced to this part's other steps)
| Mitigation | Where |
|---|---|
| Exact version pinning (`save-exact=true`) | `.npmrc`, Step 3 |
| `npm ci` everywhere except local dev | `docs/LOCKFILE-POLICY.md`, Step 3 |
| Dependabot PRs reviewed by a human before merge — never auto-merged | `.github/dependabot.yml`, Step 4 |
| Typosquatting name-similarity check on new dependencies | `scripts/check-typosquats.ts`, this step |
| SBOM tracking exact versions/hashes in use at all times | Step 7 |
```

##### 📄 File: `data/popular-packages.json`
```json
[
  "react", "react-dom", "next", "express", "lodash", "axios", "chalk",
  "commander", "dotenv", "typescript", "eslint", "prettier", "webpack",
  "babel", "jest", "mocha", "colors", "faker", "request", "moment",
  "uuid", "zod", "prisma", "bcrypt", "bcryptjs", "jsonwebtoken",
  "next-auth", "tailwindcss", "postcss", "vite", "rollup"
]
```

##### 📄 File: `scripts/check-typosquats.ts`
```typescript
// scripts/check-typosquats.ts
//
// A lightweight heuristic guard: computes the "edit distance" (how many
// single-character changes separate two strings) between each of our
// actual dependency names and a list of extremely popular package names.
// A very small distance (1-2) to a popular name, combined with NOT being
// an exact match, is a strong typosquatting red flag — e.g. "expres" is
// distance 1 from "express".
//
// This is a heuristic aid for human review, not a definitive verdict —
// it flags candidates for a person to look at, exactly like a spell
// checker flags a word for a human to confirm is really a typo.

import { readFileSync } from "node:fs";
import { join } from "node:path";

function levenshteinDistance(a: string, b: string): number {
  const matrix: number[][] = Array.from({ length: a.length + 1 }, (_, i) =>
    Array.from({ length: b.length + 1 }, (_, j) => (i === 0 ? j : j === 0 ? i : 0))
  );

  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1, // deletion
        matrix[i][j - 1] + 1, // insertion
        matrix[i - 1][j - 1] + cost // substitution
      );
    }
  }
  return matrix[a.length][b.length];
}

function main() {
  const pkgJson = JSON.parse(
    readFileSync(join(process.cwd(), "package.json"), "utf-8")
  );
  const ourDeps: string[] = [
    ...Object.keys(pkgJson.dependencies ?? {}),
    ...Object.keys(pkgJson.devDependencies ?? {}),
  ];

  const popular: string[] = JSON.parse(
    readFileSync(join(process.cwd(), "data", "popular-packages.json"), "utf-8")
  );

  const suspicious: { ours: string; similarTo: string; distance: number }[] = [];

  for (const dep of ourDeps) {
    for (const famous of popular) {
      if (dep === famous) continue; // exact match = the real package, not a typosquat
      const distance = levenshteinDistance(dep, famous);
      // Distance 1-2 on a reasonably long name is suspicious; very short
      // names (e.g. 2-3 chars) naturally have small distances to lots of
      // things, so we scale the threshold by name length to reduce noise.
      const threshold = famous.length <= 4 ? 1 : 2;
      if (distance > 0 && distance <= threshold) {
        suspicious.push({ ours: dep, similarTo: famous, distance });
      }
    }
  }

  console.log("\nSecureTrade — Typosquatting Heuristic Check\n");
  if (suspicious.length === 0) {
    console.log("✅ No suspiciously-named dependencies found.\n");
    process.exit(0);
  }

  console.log("⚠️  Review these dependencies manually before trusting them:\n");
  for (const s of suspicious) {
    console.log(`  "${s.ours}" is very similar to popular package "${s.similarTo}" (edit distance ${s.distance})`);
  }
  console.log(
    "\nIf any of these is NOT the package you intended to install, remove it immediately.\n"
  );
  process.exit(1);
}

main();
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "check:typosquats": "tsx scripts/check-typosquats.ts"
  }
}
```

### ✅ The Verification

```bash
npm run check:typosquats
```
Expected output: `✅ No suspiciously-named dependencies found.` Now prove the check actually works by temporarily installing a deliberately-similar fake name (a real, harmless package that happens to have a name close to a popular one) — or simulate it directly by editing `package.json`:

```bash
npm pkg set devDependencies.expres="1.0.0"
npm run check:typosquats
```
Expected: the script reports `"expres" is very similar to popular package "express"` and exits non-zero. Revert:
```bash
git checkout package.json
```

---

## Step 7 — Generate an SBOM with CycloneDX

### 🎯 The Target
`sbom.json` — a complete, machine-readable inventory of every package (direct and transitive) in SecureTrade, in the industry-standard CycloneDX format.

### 💡 The Concept
An **SBOM** (Software Bill of Materials) is exactly like the ingredients label on packaged food — a complete, precise list of everything inside, down to sub-ingredients, so that if a specific ingredient (say, a particular batch of an additive) is later recalled, anyone holding the label can instantly check "do I have that?" without re-inspecting the product from scratch. When the next `colors.js`-style incident happens — and there will be a next one — having an SBOM means you can answer "are we affected?" with a single `grep`, in seconds, instead of manually auditing hundreds of packages under pressure.

**CycloneDX** is one of the two dominant SBOM standard formats (the other being SPDX) — we use CycloneDX because its tooling has excellent first-class npm/JavaScript support.

### 🛠️ The Implementation

```bash
npm install -D @cyclonedx/cyclonedx-npm
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "sbom:generate": "cyclonedx-npm --output-file sbom.json --output-format JSON"
  }
}
```

```bash
npm run sbom:generate
```

Inspect the structure it produced:
```bash
cat sbom.json | head -c 2000
```

You'll see a `bomFormat: "CycloneDX"`, a `specVersion`, and a `components` array — one entry per package, each with a `name`, `version`, `purl` (Package URL — a standardized identifier like `pkg:npm/zod@3.22.4`), and often a cryptographic `hash`.

##### 📄 File: `docs/SBOM-POLICY.md`
```markdown
# SecureTrade — SBOM Policy

## What
`sbom.json` (CycloneDX format) is a complete inventory of every direct
and transitive dependency in this project — package name, exact version,
and package URL (purl) for each.

## When It's Regenerated
- On every pull request that changes `package.json` or
  `package-lock.json` (automated in CI — Step 8).
- On every release/deployment (Part 6).

## How It's Used
1. **Incident response** (Part 7): when a new CVE is disclosed for ANY
   package, `grep` this file to instantly know if/where we're affected,
   without re-scanning the whole project live.
2. **Compliance / audits**: MAS TRM and enterprise customer due-diligence
   processes increasingly require a current SBOM on request — this file
   IS that artifact, always current, always in the repo.
3. **License compliance**: `cyclonedx-npm` can also capture license
   metadata per package, letting us later automate "flag any GPL-licensed
   dependency" checks if needed.

## Where It Lives
Committed to the repository root as `sbom.json`, regenerated (not
hand-edited) whenever dependencies change.
```

### ✅ The Verification

```bash
# Confirm it's valid CycloneDX JSON and count how many components it captured
cat sbom.json | python3 -c "import json,sys; d=json.load(sys.stdin); print('bomFormat:', d['bomFormat']); print('components:', len(d['components']))"
```
Expected output: `bomFormat: CycloneDX` and a component count in the low hundreds, matching roughly what `npm ls --all` showed back in Step 1.

```bash
git add -A
git commit -m "chore: generate initial SBOM with CycloneDX"
git push
```

---

## Step 8 — Lab: GitHub Actions Pipeline to Block PRs with Critical CVEs + Generate SBOM

### 🎯 The Target
`.github/workflows/dependency-security.yml` — the first real CI workflow in this series, running on every pull request, that **fails the check (blocking merge)** if any Critical/High vulnerability is found, and automatically regenerates and uploads the SBOM as a build artifact.

### 💡 The Concept
Every check we've run so far (`npm audit`, Snyk, OSV, typosquat check, SBOM generation) has been something *you* had to remember to run manually. That's fragile — humans forget, skip steps under deadline pressure, or simply don't run tools on a Friday afternoon. **CI (Continuous Integration)** is a robot co-worker that runs these exact checks automatically, on every single pull request, with zero chance of "forgetting" — like a mandatory metal detector at a building entrance that every single person walks through, with no supervisor able to wave a friend past it "just this once."

This workflow is intentionally scoped to *dependency* security only — Part 5 builds the fuller pipeline (SAST, tests, DAST, deploy) and will sit alongside, not replace, this one.

### 🛠️ The Implementation

##### 📄 File: `.github/workflows/dependency-security.yml`
```yaml
# .github/workflows/dependency-security.yml
#
# Runs on every pull request. Blocks merging if a Critical or High severity
# vulnerability is found in any dependency. Also regenerates and uploads
# the SBOM so it's always current and inspectable from the PR itself.

name: Dependency Security

on:
  pull_request:
    branches: [main]
    # Only re-run this (relatively slow) workflow when dependency-related
    # files actually change — saves CI minutes on PRs that only touch,
    # say, a markdown file.
    paths:
      - "package.json"
      - "package-lock.json"
      - ".github/workflows/dependency-security.yml"
  # Also run weekly on main, independent of any PR — catches NEWLY
  # disclosed vulnerabilities in packages we already depend on, which
  # wouldn't otherwise trigger any PR at all.
  schedule:
    - cron: "0 3 * * 1" # Every Monday 03:00 UTC
  workflow_dispatch: {} # allows manually triggering from the Actions tab

# Restricts what this workflow's automatic GITHUB_TOKEN can do — Least
# Privilege applied to CI itself. We only need read access to code and
# write access to pull-request comments/checks, nothing more.
permissions:
  contents: read
  pull-requests: write
  security-events: write

jobs:
  audit:
    name: SCA — npm audit
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"

      # npm ci, not npm install — see docs/LOCKFILE-POLICY.md. CI is
      # exactly the environment that policy exists for.
      - name: Install dependencies (from lockfile only)
        run: npm ci

      - name: Run npm audit (fails build on high/critical)
        run: npm run audit:check

      - name: Check for typosquatting-like dependency names
        run: npm run check:typosquats

  snyk:
    name: SCA — Snyk
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"
      - run: npm ci

      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/node@master
        env:
          # Stored as a GitHub Actions secret (Settings → Secrets and
          # variables → Actions) — NEVER hardcoded here. This is the exact
          # same "never commit a secret" principle from docs/SECRETS-POLICY.md,
          # applied to CI configuration itself.
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  sbom:
    name: Generate SBOM
    runs-on: ubuntu-latest
    needs: [audit] # only bother generating if the basic audit already passed
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"
      - run: npm ci

      - name: Generate SBOM (CycloneDX)
        run: npm run sbom:generate

      # Uploads sbom.json as a downloadable artifact attached to this
      # specific workflow run — reviewable from the GitHub Actions UI
      # without needing to check out the branch locally.
      - name: Upload SBOM artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.json
          retention-days: 90

  osv-scan:
    name: SCA — OSV Scanner
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run OSV-Scanner
        uses: google/osv-scanner-action@v1
        with:
          scan-args: |-
            --lockfile=package-lock.json
```

Add the SBOM upload directory to `.gitignore` locally if you'd rather not commit `sbom.json` on every dependency bump manually (CI regenerates and uploads it automatically as an artifact regardless):

##### 📄 File: `.gitignore` (append, optional — only if you prefer CI-only SBOM generation)
```
# Optional: uncomment if you'd rather rely solely on the CI-generated
# artifact instead of a committed file. We keep it committed in this
# series for simplicity, so leave this commented out.
# sbom.json
```

Configure the `SNYK_TOKEN` secret (needed for the `snyk` job above):

```bash
npx snyk config get api
# Copy the printed token value, then:
gh secret set SNYK_TOKEN --body "PASTE_YOUR_SNYK_API_TOKEN_HERE"
```

### ✅ The Verification

Commit and push the workflow, then open a test pull request to trigger it:

```bash
git checkout -b test/dependency-security-pipeline
git add -A
git commit -m "ci: add dependency security workflow (SCA gate + SBOM generation)"
git push -u origin test/dependency-security-pipeline

gh pr create --title "Test: dependency security pipeline" \
  --body "Verifying the new dependency-security.yml workflow runs correctly." \
  --base main
```

```bash
gh pr checks --watch
```
Expected: all four jobs (`audit`, `snyk`, `sbom`, `osv-scan`) show ✅ green. Click through to the Actions run in the browser, open the `sbom` job, and confirm the `sbom` artifact is downloadable at the bottom of the run summary page.

Now **prove the gate actually blocks something** — intentionally introduce a known-vulnerable old package version:

```bash
npm install lodash@4.17.15 --save-exact
git add -A
git commit -m "test: intentionally add vulnerable lodash version to verify CI gate"
git push
```

```bash
gh pr checks --watch
```
Expected: the `audit` job now shows ❌ failed, and the pull request is marked as having failing checks — GitHub will (once branch protection is enabled) refuse to allow merging. Revert this test change immediately:

```bash
npm install lodash@latest --save-exact
git add -A
git commit -m "revert: remove intentionally vulnerable lodash test version"
git push
```

Close out the test PR once satisfied:
```bash
gh pr close --delete-branch
```

---

## Step 9 — Automate Verification of Part 4

### 🎯 The Target
`scripts/verify-part4.ts` — checks every artifact and configuration from this part exists and is internally sound.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-part4.ts`
```typescript
// scripts/verify-part4.ts

import { existsSync, readFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";

type Check = { label: string; pass: boolean; detail?: string };
const checks: Check[] = [];

function fileExists(p: string): boolean {
  return existsSync(join(process.cwd(), p));
}

function readDoc(p: string): string {
  return readFileSync(join(process.cwd(), p), "utf-8");
}

function main() {
  const requiredFiles = [
    "docs/SUPPLY-CHAIN.md",
    "docs/LOCKFILE-POLICY.md",
    "docs/CASE-STUDY-colorsjs.md",
    "docs/SBOM-POLICY.md",
    "docs/VULNERABILITY-EXCEPTIONS.md",
    ".npmrc",
    ".github/dependabot.yml",
    ".github/workflows/dependency-security.yml",
    "scripts/check-typosquats.ts",
    "data/popular-packages.json",
    "sbom.json",
    "package-lock.json",
  ];
  for (const f of requiredFiles) {
    checks.push({ label: `File exists: ${f}`, pass: fileExists(f) });
  }

  if (fileExists(".npmrc")) {
    const npmrc = readDoc(".npmrc");
    checks.push({
      label: ".npmrc enforces save-exact=true",
      pass: /save-exact\s*=\s*true/.test(npmrc),
    });
  }

  if (fileExists("package.json")) {
    const pkg = JSON.parse(readDoc("package.json"));
    checks.push({
      label: "package.json declares an engines.node constraint",
      pass: !!pkg.engines?.node,
    });
    checks.push({
      label: "audit:check script exists with --audit-level=high",
      pass: /--audit-level=high/.test(pkg.scripts?.["audit:check"] ?? ""),
    });
  }

  if (fileExists("sbom.json")) {
    const sbom = JSON.parse(readDoc("sbom.json"));
    checks.push({
      label: "sbom.json is valid CycloneDX with components listed",
      pass: sbom.bomFormat === "CycloneDX" && Array.isArray(sbom.components) && sbom.components.length > 0,
      detail: `${sbom.components?.length ?? 0} components`,
    });
  }

  // Live re-run of the audit gate — same command CI uses.
  try {
    execSync("npm run audit:check", { stdio: "pipe" });
    checks.push({ label: "npm audit currently passes (no high/critical)", pass: true });
  } catch {
    checks.push({ label: "npm audit currently passes (no high/critical)", pass: false });
  }

  console.log("\nSecureTrade — Part 4 Verification\n");
  let allPassed = true;
  for (const c of checks) {
    const icon = c.pass ? "✅" : "❌";
    console.log(`${icon} ${c.label}${c.detail ? ` (${c.detail})` : ""}`);
    if (!c.pass) allPassed = false;
  }
  console.log(
    allPassed
      ? "\nAll Part 4 checks passed. Ready for Part 5.\n"
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
    "verify:part4": "tsx scripts/verify-part4.ts"
  }
}
```

### ✅ The Verification

```bash
npm run verify:part4
```
All checks should print ✅. Commit:

```bash
git add -A
git commit -m "feat: supply chain security — SCA tooling, SBOM, typosquat guard, Dependabot, CI dependency gate"
git push
```

---

## ✅ Part 4 Completion Checklist

- [ ] `npm audit`, Snyk, and OSV-Scanner all run clean (or exceptions are documented)
- [ ] `.npmrc` enforces `save-exact` and `engine-strict`; `package-lock.json` committed
- [ ] Dependabot enabled for both npm and GitHub Actions ecosystems
- [ ] `docs/CASE-STUDY-colorsjs.md` written; typosquat guard script working
- [ ] `sbom.json` generated via CycloneDX and committed
- [ ] `.github/workflows/dependency-security.yml` runs on every PR and **actually blocks** on a deliberately-introduced vulnerable package (tested in Step 8)
- [ ] `npm run verify:part4` exits all green

---

# 📚 Reference Section — Deep Dives for Part 4

### R1. CVE vs. GHSA vs. OSV — Understanding the Identifier Ecosystem

| Identifier | Issued By | Scope |
|---|---|---|
| **CVE** (Common Vulnerabilities and Exposures) | MITRE Corporation (US-government-funded, industry standard) | Any software vulnerability, any language/ecosystem |
| **GHSA** (GitHub Security Advisory) | GitHub | Vulnerabilities in packages hosted/tracked on GitHub; often assigned faster than CVEs, and can later be cross-linked to a CVE |
| **OSV** (Open Source Vulnerability) | OSV.dev (Google-backed, open community project) | A unified schema aggregating CVEs, GHSAs, and ecosystem-specific advisories (PyPI, npm, RubyGems, Go, etc.) into one consistent format |

You'll see all three IDs referenced interchangeably in tool output — they frequently describe the *same underlying vulnerability*, just catalogued by different organizations, sometimes with different disclosure timing.

### R2. CVSS — Understanding the Severity Score Behind "Critical/High/Medium/Low"

**CVSS** (Common Vulnerability Scoring System) is the standardized 0.0–10.0 severity score behind the human-readable labels `npm audit` and Snyk show you:

| Score Range | Severity Label |
|---|---|
| 9.0 – 10.0 | Critical |
| 7.0 – 8.9 | High |
| 4.0 – 6.9 | Medium |
| 0.1 – 3.9 | Low |

CVSS is computed from several sub-metrics: **Attack Vector** (can it be exploited remotely over a network, or does it need local/physical access?), **Attack Complexity**, **Privileges Required**, **User Interaction**, and **Impact** (on Confidentiality/Integrity/Availability). Our `--audit-level=high` gate in Step 2 specifically means: block anything scoring 7.0 or above — a deliberate risk-acceptance line drawn by the team, consistent with treating "Medium and below" as acceptable background risk to be fixed on a normal schedule rather than blocking merges (this becomes a formal SLA — Service Level Agreement — in Part 8's vulnerability management process).

### R3. Dependency Confusion Attacks — A Deeper Look

Beyond typosquatting (a *similar-looking* name), **dependency confusion** exploits *identical* names across public and private registries. If your company has an internal package named `@securetrade/internal-utils` published only to a private registry, and an attacker publishes a *public* npm package with that exact same name, some build tool configurations will — under certain misconfigurations — prefer the public registry, silently pulling the attacker's malicious code into your build instead of your real internal package. Mitigation: always explicitly scope internal package registry configuration (`.npmrc` with an explicit `@securetrade:registry=` mapping to your private registry), and never assume default registry resolution order is safe for scoped internal packages.

### R4. Software Composition Analysis — SAST vs. SCA vs. DAST (Preview of Part 5)

| | What It Analyzes | Analogy |
|---|---|---|
| **SAST** (Part 3) | Your own first-party source code, statically | A proofreader checking your own essay for mistakes |
| **SCA** (this part) | Third-party dependencies, statically, against vulnerability databases | Checking every ingredient supplier against a public food recall list |
| **DAST** (Part 5) | The running application, dynamically, by actually attacking it | A mystery shopper actually trying to shoplift from your store to test its defenses |

All three are complementary, not redundant — each catches a category of risk invisible to the other two, which is precisely why Part 5 builds a pipeline running all of them together.

### R5. SPDX vs. CycloneDX — The Two SBOM Standards

| | CycloneDX (what we used) | SPDX |
|---|---|---|
| Origin | OWASP Foundation | Linux Foundation |
| Primary strength | Security-focused (vulnerability and dependency-relationship metadata is a first-class concept) | Originally license-compliance-focused (older, broader legal/industry adoption, e.g. required in some government procurement contexts) |
| Format | JSON or XML | JSON, RDF, tag-value, spreadsheet |

Both are increasingly interoperable and many tools support converting between them (`cyclonedx-cli` can convert CycloneDX ↔ SPDX). We chose CycloneDX for its stronger JavaScript/npm-ecosystem tooling and native vulnerability-metadata support, which pairs naturally with the SCA work in this part — but if a future client/regulator specifically requires SPDX, converting our existing SBOM is straightforward rather than starting over.

### R6. When *Not* to Add a Dependency

The single most effective supply-chain security control is often the simplest: **don't add the dependency at all.** Before running `npm install` for a new package, this quick checklist (informally, "is this worth the risk?") is worth internalizing:
1. Does this package have a small footprint (few or zero *transitive* dependencies of its own), or does it drag in 40 more packages for one convenience function?
2. Is it actively maintained (a commit or release within the last several months), with more than one maintainer (bus-factor risk — what happens if the sole maintainer disappears, sells the package, or turns malicious like the `colors.js` case)?
3. Could this genuinely be ~20-50 lines of code you write and fully own instead? (A left-pad-style utility function is rarely worth an external dependency.)

Every "yes" to writing it yourself is one less unaudited package with production access to your secrets.

---

**Next up: Part 5 — Testing & CI/CD Security**, where we build on this part's dependency-security workflow to construct the FULL pipeline: SAST (Semgrep/CodeQL) → automated tests → DAST (OWASP ZAP attacking a real Vercel preview deployment) → secret scanning → and finally, a secure deploy step using OIDC instead of long-lived cloud credentials.
