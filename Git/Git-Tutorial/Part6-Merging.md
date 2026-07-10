## Part 6: Professional Pipelines

Series: Mastering Version Control | Prev: Part 5, Time Travel and Recovery | Next: Appendices

### Section 1: Concept Explanation

**1.1 Rebase vs merge, the real trade-off**

Merging preserves exactly what happened, including every side branch, at the cost of a busier graph. Rebasing rewrites your branch's commits so they appear to have been built on top of the latest main, producing a straight line, at the cost of changing commit hashes for anything that gets rebased.

The single hard rule of rebasing: **never rebase a branch that other people have already pulled and are building on top of.** Rebasing rewrites history; if someone else already has copies of the old commits, they will have painful, confusing conflicts when they try to sync. This is often phrased as: rebase local or personal branches freely, never rebase shared or public branches.

A common professional workflow: rebase your own feature branch onto main before opening a PR, to get a clean linear diff and avoid unnecessary merge commits, then let the PR be merged into main using whatever strategy the team has agreed on — merge commit or squash.

**1.2 Interactive rebase for commit hygiene**

Interactive rebase lets you edit, reorder, combine, or drop your own commits before they become permanent shared history. This is how professionals turn a messy sequence of work-in-progress commits into the clean, atomic story described back in Part 1.

**1.3 From GitHub Pages to Vercel, why the jump is necessary**

GitHub Pages, as covered in Part 4, only serves static files. The moment your project needs any of the following, you need a platform that actually executes server-side code on every request: server-rendered pages that depend on request data, API routes, database access, authentication with secrets, background jobs, or preview environments per pull request.

Vercel is built specifically around the Git workflow you already know. It does not change how you use Git at all, it changes what happens automatically after you push.

**1.4 Vercel's Git integration model**

Once a GitHub repository is connected to a Vercel project, Vercel listens to the same two events your whole team already cares about. A push to any branch produces an ephemeral preview deployment with its own unique URL, and a push or merge to the production branch, usually main, produces a production deployment automatically. This means a pull request is no longer just a code review, it is also a live, clickable preview of the actual change, attached automatically as a comment or check on the PR itself.

---

### Section 2: Implementation, step by step commands

**2.1 Interactive rebase, cleaning up your own branch before a PR**

Start work as usual:
```
git switch main
git pull
git switch -c feature/user-profile
```

Make several small, messy commits:
```
echo profile draft one > profile.js
git add .
git commit -m "wip"

echo profile draft two >> profile.js
git add .
git commit -m "wip more"

echo final touch >> profile.js
git add .
git commit -m "wip fix typo"
```

Clean it up before anyone else sees it:
```
git log --oneline
git rebase -i HEAD~3
```

This opens an editor listing the three commits, oldest first, each prefixed with the word `pick`. Change the file so only the first line stays `pick`, and the other two become `squash` (or the short form `s`):
```
pick a1b2c3d wip
squash e4f5g6h wip more
squash h7i8j9k wip fix typo
```

Save and close. A second editor screen appears asking for the combined commit message — replace it entirely with one clean atomic message:
```
feat: add user profile page with avatar and bio fields
```

Save and close. Confirm the branch now has one clean commit:
```
git log --oneline
```

**2.2 Rebasing your feature branch onto an updated main**

While your feature branch was open, main moved forward. Rather than merging main into your branch (which creates a merge commit inside your feature branch), rebase to keep a straight line:
```
git fetch origin
git rebase origin/main
```

If a conflict appears during rebase, git pauses on the specific commit that conflicts:
```
git status
```

Edit the conflicting file exactly as in Part 2, removing the conflict markers, then continue instead of commit:
```
git add profile.js
git rebase --continue
```

If at any point the rebase becomes confusing or you want to bail out completely:
```
git rebase --abort
```

Once finished, since the commit hashes changed, you must force push your own feature branch — and only your own feature branch, never main:
```
git push --force-with-lease
```

`force-with-lease` is the safer form of force push — it refuses to overwrite the remote branch if someone else pushed to it since you last fetched, protecting you from accidentally destroying a collaborator's work.

**2.3 Connecting a project to Vercel**

Install the CLI (optional, but useful for local testing of the exact production build):
```
npm install -g vercel
```

Log in (opens a browser once):
```
vercel login
```

From inside your project folder, link it:
```
vercel link
```

Deploy a one-off preview manually:
```
vercel
```

Deploy straight to production manually:
```
vercel --prod
```

The far more common professional setup is connecting the GitHub repository directly on vercel.com: **Add New → Project → Import Git Repository**, select the repo, confirm the framework preset Vercel detects (for a Next.js app this is automatic), and click **Deploy**. From this point forward you never run the `vercel` command manually — you just use git the way you already do.

**2.4 The day-to-day workflow once Vercel is connected**
```
git switch main
git pull
git switch -c feature/dashboard-widgets
```

Do the work, commit atomically as always:
```
git add .
git commit -m "feat: add revenue widget to dashboard"
git push -u origin feature/dashboard-widgets
```

Open the pull request on GitHub exactly as in Part 3. Within roughly a minute, a bot comment from Vercel appears on the PR with a unique preview URL, for example `my-app-git-feature-dashboard-widgets-yourteam.vercel.app`. Anyone on the team, including non-engineers, can click that link and see the actual running change, with real server-side rendering and API routes working, before a single line is merged.

Once the PR is approved and merged into main:
```
git switch main
git pull
```

Vercel automatically detects the push to the production branch and redeploys the real production URL, no manual step required. This is the same core idea from Part 4 — deployment is just pushing to the right branch — generalized to a platform that runs full server-side code instead of only static files.

**2.5 Environment variables and secrets in a CI pipeline**

Recall from Part 1 that secrets must never be committed to git. Vercel's dashboard, under Project Settings → Environment Variables, lets you define values such as `DATABASE_URL` or API keys, scoped separately to Production, Preview, and Development. Your local `.env` file, still correctly listed in `.gitignore`, is used only for your machine — Vercel injects its own copies at build and run time, so the two never conflict and secrets never touch the git history.

**2.6 A minimal GitHub Actions quality gate before deployment**

Many teams add an automated check that must pass before a PR can even be merged, independent of whichever deploy platform is used. Create `.github/workflows/ci.yml` with a job named `build-and-test` that runs on every push and pull request, checks out the code, sets up Node 20, runs `npm ci`, then `npm run lint`, then `npm run build`. Configure this as a required status check under the repository's branch protection rules for main (**Settings → Branches → Add rule**), so GitHub physically blocks the merge button on any PR whose build or lint step fails.
```
git add .github/workflows/ci.yml
git commit -m "ci: add build and lint quality gate for pull requests"
git push
```

---

### Section 3: Practice Exercise

**Step 1:** Create a feature branch and deliberately make four small, messy work-in-progress commits touching the same file.

**Step 2:** Use interactive rebase to squash all four into one clean, well-written atomic commit message.

**Step 3:** Meanwhile simulate main moving forward — on main, make and push one unrelated commit, then go back to your feature branch and rebase it onto the updated main, resolving any conflict that appears.

**Step 4:** Force push the rebased branch with `--force-with-lease` and open a pull request.

**Step 5:** If you have a Vercel account available, connect any small Next.js or static project's GitHub repository to Vercel and confirm that opening a pull request produces an automatic preview URL, then confirm merging it triggers an automatic production deployment.

---

### Section 4: Solution and Explanation

```
git switch main
git pull
git switch -c feature/search-bar

echo start of search bar > search.js
git add .
git commit -m "wip1"

echo added input element >> search.js
git add .
git commit -m "wip2"

echo wired up state >> search.js
git add .
git commit -m "wip3"

echo fixed styling >> search.js
git add .
git commit -m "wip4"

git rebase -i HEAD~4
```
In the editor: keep `pick` on the first commit, set `squash` on the remaining three, save, then replace the combined message with `feat: add search bar with live input state`, save.
```
git switch main
echo unrelated change >> README.md
git add .
git commit -m "docs: unrelated update to simulate team progress"
git push

git switch feature/search-bar
git fetch origin
git rebase origin/main
```
If `search.js` does not conflict with `README.md` there will be no conflict here — this specific pairing is chosen so students see a successful, conflict-free rebase; for a guaranteed conflict exercise, repeat Part 2's technique on the same file from both branches instead.
```
git push --force-with-lease
```
Open the PR on GitHub as in Part 3, and if Vercel is connected, watch the automatic preview URL appear on the PR within about a minute, then merge and confirm the production URL updates.

**Why this is correct:** The interactive rebase step demonstrates that atomic commit hygiene, taught as a philosophy in Part 1, is not something you must get right on the very first try — professionals write messy work-in-progress commits constantly and clean them up before anyone else ever sees the history, using exactly this tool. The rebase onto `origin/main` demonstrates keeping a personal branch current without polluting it with merge commits, and `force-with-lease` demonstrates the one safe way to force push, since it will refuse to run if a teammate's unseen work is on the remote. Finally, the Vercel connection demonstrates the entire point of this series' final lesson: once the Git fundamentals from Parts 1 through 5 are solid, deployment infrastructure of any sophistication — from a static GitHub Pages folder to a fully automated preview-per-pull-request pipeline — is just a listener attached to the same push and merge events you already perform every day.

---

**Next up:** the Appendices note — the full command cheat sheet, a troubleshooting dictionary of common errors, and a deployment strategy matrix comparing GitHub Pages and Vercel.
