# Part 12: Deploying to Vercel and Inngest Cloud

## 1. Push to GitHub

```bash
git init
git add .
git commit -m "TaskFlow: complete Inngest tutorial build"
```

Create a new GitHub repo and push.

## 2. Create an Inngest Cloud account

Sign up at inngest.com (free tier, no credit card). Create an app matching your `id` (`taskflow`). Go to **Manage → Keys** and copy:

- **Event Key** — used by your app to send events to Inngest Cloud
- **Signing Key** — used by Inngest Cloud to authenticate calls to your `/api/inngest` route

## 3. Deploy to Vercel

Import your GitHub repo at vercel.com (free Hobby tier). Add environment variables in the Vercel project settings:

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
CLERK_WEBHOOK_SECRET=
DATABASE_URL=
RESEND_API_KEY=
INNGEST_EVENT_KEY=
INNGEST_SIGNING_KEY=
```

Deploy. Vercel builds with Turbopack (Next.js 16 default) and gives you a production URL like `https://taskflow.vercel.app`.

## 4. Connect Inngest Cloud to your deployed app

In the Inngest Cloud dashboard, go to your app's settings and register your production endpoint: `https://taskflow.vercel.app/api/inngest`. Inngest calls this URL's `PUT` method to discover/sync your functions — this happens automatically shortly after your first production deploy with the `INNGEST_SIGNING_KEY` env var set, but you can also manually trigger a "Sync" from the dashboard if functions don't appear right away.

Confirm success: the Inngest Cloud dashboard's **Functions** tab should list every function from your `serve()` call (`hello-world`, `sync-user-on-create`, `onboarding-email-drip`, `fan-out-task-created-notifications`, `create-notification-row`, `send-task-assigned-email`, `daily-digest`, `send-digest-email`, `overdue-task-sweep`, `task-review-workflow`).

## 5. Update the Clerk webhook to point at production

In the Clerk dashboard, update (or add a second) webhook endpoint to `https://taskflow.vercel.app/api/webhooks/clerk`, subscribed to `user.created`. You can keep the ngrok endpoint for local dev alongside this one — Clerk supports multiple webhook endpoints simultaneously.

## 6. Verify end-to-end in production

1. Sign up a brand-new user on your live Vercel URL.
2. Check Inngest Cloud's Runs tab — `sync-user-on-create` and `onboarding-email-drip` should both run.
3. Check your inbox for the welcome email (Resend's dashboard Logs tab works here too).
4. Create a project and task on the live site, confirm fan-out notifications and assignment emails work.
5. Wait for (or manually invoke via the Cloud dashboard) `daily-digest` and `overdue-task-sweep` to confirm cron functions are live.

## 7. A note on local vs. production behavior

Locally, the Inngest Dev Server (`inngest-cli dev`) simulates everything Inngest Cloud does, but state doesn't persist as durably and cron schedules can be invoked manually for convenience. In production, Inngest Cloud is the real, durable, always-on scheduler and step-execution engine — your Vercel functions are stateless and only invoked exactly when a step needs to run, which is what keeps costs low even for functions with multi-day sleeps.

## Checkpoint

- [ ] Code pushed to GitHub
- [ ] Inngest Cloud account created, app ID matches your local `id: "taskflow"`
- [ ] Deployed to Vercel with all env vars set, including `INNGEST_EVENT_KEY` and `INNGEST_SIGNING_KEY`
- [ ] Inngest Cloud dashboard shows all functions synced
- [ ] Clerk webhook updated to point at the production URL
- [ ] Full flow (signup → welcome email → project/task creation → notifications → digest/sweep) verified live

## Troubleshooting

**Functions don't appear in Inngest Cloud after deploying.** Check that `INNGEST_SIGNING_KEY` is set correctly in Vercel's env vars and redeploy; then manually trigger a sync from the Inngest Cloud dashboard's app settings page.

**Webhook 500s in production but works locally.** Check Vercel's function logs (Vercel dashboard → your project → Logs) for the actual error — a common cause is forgetting to set `CLERK_WEBHOOK_SECRET` for the production webhook endpoint specifically (it's per-endpoint, not global).

**Emails work locally but not in production.** Confirm `RESEND_API_KEY` is set in Vercel and that you're not still using a Resend sandbox restriction that only allows sending to your own verified email.

Congratulations — TaskFlow is now live, and you've used nearly every core Inngest feature in a real, working app. Read the **Conclusion** next for a recap and ideas on where to go from here — want me to bring that up?
