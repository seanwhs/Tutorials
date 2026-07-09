# Neon Tutorial - Part 10: Free Tier Limits, Monitoring & Scaling Considerations

## 1. What "Free" Actually Includes (Recap + Detail)

> As with Part 1, treat these numbers as directionally correct at time of writing — always verify current limits at [neon.tech/pricing](https://neon.tech/pricing) before making production decisions.

| Resource | Free Tier | What Happens If You Exceed It |
|---|---|---|
| Projects | 1 | Create a new account/org, or upgrade, to get a 2nd project |
| Branches | Up to 10 per project | Oldest/least-used branches must be deleted before creating new ones |
| Storage | 0.5 GB per branch (shared via CoW until diverged) | Writes start failing; delete unused data/branches or upgrade |
| Compute hours | Generous monthly allowance, autosuspend ~5 min idle | Compute is throttled/paused until the next billing cycle or upgrade |
| Compute size | Shared 0.25 vCPU class | Fine for dev/small apps; heavier workloads need a paid compute size |
| Data transfer (egress) | Included monthly allowance | Additional egress may incur charges or require upgrade past free tier |
| Point-in-time restore | Short window (hours, not days) | Can't roll back to older points — rely on your own backups for longer retention needs |

## 2. Where to Monitor Usage in the Console

The Neon console has a **Monitoring** (or **Usage**) tab per project showing:

- Current storage used vs. limit
- Compute hours consumed this billing period
- Active/idle compute endpoint status
- Branch count vs. the 10-branch cap

Check this periodically, especially after Part 7's automated per-PR branching — a busy repo with many open PRs can approach the branch limit faster than expected.

## 3. A Simple Script to Audit Branches

```ts
// scripts/audit-branches.ts
// Run locally with: pnpm tsx scripts/audit-branches.ts
// Requires NEON_API_KEY and NEON_PROJECT_ID env vars (from the Neon
// console → Account Settings → API Keys, and the project dashboard URL).

const NEON_API_KEY = process.env.NEON_API_KEY!;
const NEON_PROJECT_ID = process.env.NEON_PROJECT_ID!;

async function main() {
  const res = await fetch(
    `https://console.neon.tech/api/v2/projects/${NEON_PROJECT_ID}/branches`,
    { headers: { Authorization: `Bearer ${NEON_API_KEY}` } }
  );
  const data = await res.json();

  console.log(`Total branches: ${data.branches.length} / 10`);
  for (const branch of data.branches) {
    console.log(`- ${branch.name} (created ${branch.created_at})`);
  }
}

main();
```

```bash
NEON_API_KEY=... NEON_PROJECT_ID=... pnpm tsx scripts/audit-branches.ts
```

## 4. Cleaning Up Stale Preview Branches

```bash
# List all branches
neonctl branches list --project-id <your-project-id>

# Delete ones matching old/merged PRs
neonctl branches delete preview/old-feature-branch --project-id <your-project-id>
```

If the Vercel-Neon integration (Part 7) is configured to auto-delete branches on PR close/merge, this is mostly automatic — but it's worth a periodic manual check, especially early on while confirming the integration behaves as expected.

## 5. Signs You've Outgrown the Free Tier

| Symptom | Likely Cause | Next Step |
|---|---|---|
| Frequent "storage limit reached" errors | Real data (not branches) exceeding 0.5 GB | Archive/delete old data, or upgrade compute+storage plan |
| Hitting the 10-branch cap regularly | High PR velocity with per-PR branching | Reduce branch retention window, or upgrade for a higher branch limit |
| Users report the app "hanging" briefly on first load | Cold-start latency from scale-to-zero, occurring more often now that usage grew | Consider a paid "always on" compute option if UX-critical |
| Queries feel slow under real traffic | Shared 0.25 vCPU compute size straining under real concurrent load | Upgrade compute size once you have paying users / real load |

## 6. Cost-Conscious Habits Even on Free Tier

- Add indexes early (Part 8) — avoids needing a bigger compute size just to compensate for slow unindexed scans.
- Delete branches you're done with — don't let stale `dev/*` or `preview/*` branches quietly consume your 10-branch cap.
- Prefer `SELECT` specific columns over `SELECT *` — smaller responses, especially relevant with the HTTP driver.
- Keep an eye on the Monitoring tab monthly, the same way you'd watch any other free-tier cloud resource (Vercel, Clerk, etc.).

## 7. When You're Ready to Scale Beyond Free

Neon's paid tiers (not needed for this tutorial, but good to know exist) generally unlock:

- More/larger projects
- More branches
- More storage per branch
- Larger, non-shared compute sizes
- "Always on" compute (no autosuspend, no cold starts)
- Longer point-in-time restore windows

The migration path is simple because everything in this series is 100% standard Postgres — no code changes required to upgrade, only a plan change in the Neon console.

## 8. Checkpoint

- [ ] Know the concrete free-tier numbers (1 project, 10 branches, 0.5 GB/branch)
- [ ] Checked the Monitoring/Usage tab in the Neon console at least once
- [ ] Ran (or understand) the branch-audit script
- [ ] Know the manual and integration-based ways to clean up stale branches
- [ ] Understand upgrading requires zero code changes — only a plan change

## Troubleshooting

| Problem | Fix |
|---|---|
| Neon API returns 401 on the audit script | Regenerate the API key in Account Settings → API Keys, ensure it's not expired/revoked |
| Storage climbing faster than expected | Check for accidental duplicate seed-script runs, or large unindexed/unused tables left from earlier tutorial parts |
| Branch count stuck at 10 with no obvious PRs open | Some CI/preview branches may not have been cleaned up automatically — audit and delete manually |

## Next

Read the **Conclusion** for a full recap and architecture overview, then **Appendix A** for the complete final codebase reference.
