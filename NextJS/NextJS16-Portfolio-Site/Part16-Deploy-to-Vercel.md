# Part 16: Deploying to Vercel for Free

Time to put your portfolio live on the internet — completely free, using Vercel's Hobby tier.

## Step 1: Push Your Code to GitHub

If you haven't already created a GitHub repository:

1. Go to https://github.com/new
2. Name it `my-portfolio` (or anything you like), leave it **Public** or **Private** (either works with Vercel's free tier), don't initialize with a README (we already have a project)
3. Click **Create repository**

Back in your terminal, inside the `my-portfolio` folder:

```bash
git remote add origin https://github.com/YOUR_USERNAME/my-portfolio.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

## Step 2: Create a Free Vercel Account

1. Go to https://vercel.com/signup
2. Sign up using **Continue with GitHub** — this is the smoothest path and automatically grants Vercel permission to import your repos
3. No credit card is required for the Hobby (free) plan

## Step 3: Import Your Project

1. From the Vercel dashboard, click **Add New...** → **Project**
2. Find `my-portfolio` in the list of your GitHub repos and click **Import**
3. Vercel will auto-detect this as a **Next.js** project and pre-fill the build settings — you don't need to change the Framework Preset, Build Command, or Output Directory

## Step 4: Add Environment Variables

Before clicking Deploy, expand **Environment Variables** and add every variable from your `.env.local`:

| Key | Value |
|---|---|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | your Sanity project ID |
| `NEXT_PUBLIC_SANITY_DATASET` | `production` |
| `NEXT_PUBLIC_SANITY_API_VERSION` | `2024-06-01` (or whatever you used) |
| `NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY` | your Web3Forms access key |
| `SANITY_REVALIDATE_SECRET` | your generated webhook secret |
| `NEXT_PUBLIC_SITE_URL` | leave blank for now — we'll fill this in Step 6 after we know the real URL |

Click **Deploy**. Vercel will install dependencies, run `next build` (with Turbopack), and deploy — this usually takes 1-3 minutes.

## Step 5: Visit Your Live Site

Once deployment finishes, Vercel shows a preview screenshot and a URL like:

```
https://my-portfolio-yourusername.vercel.app
```

Click it — your portfolio should be live! Check a few pages: homepage, `/projects`, `/blog`, `/about`, `/contact`, and `/studio` (the embedded Sanity Studio should also work in production).

## Step 6: Set the Real Site URL and Redeploy

Now that you know your real domain:

1. In Vercel, go to your project → **Settings** → **Environment Variables**
2. Add/update `NEXT_PUBLIC_SITE_URL` to your actual deployed URL, e.g. `https://my-portfolio-yourusername.vercel.app`
3. Go to the **Deployments** tab → click the **⋯** menu on the latest deployment → **Redeploy** (so the new env var takes effect — env var changes require a redeploy, they don't apply retroactively)

## Step 7: Add Your Production Domain to Sanity's CORS Origins

1. Go to https://www.sanity.io/manage → your project → **API** → **CORS Origins**
2. Click **Add CORS origin**, paste your Vercel URL (e.g. `https://my-portfolio-yourusername.vercel.app`), check **Allow credentials**, save

Without this, your deployed Studio at `/studio` won't be able to talk to Sanity's API.

## Step 8: Finalize the Sanity Webhook URL

Back in Part 15 we created a webhook with a placeholder URL. Now:

1. Go to https://www.sanity.io/manage → your project → **API** → **Webhooks**
2. Edit the `Revalidate Next.js Cache` webhook
3. Set the URL to: `https://your-real-domain.vercel.app/api/revalidate`
4. Save

### Test the Full Loop

1. Go to `https://your-real-domain.vercel.app/studio`
2. Edit any project's summary text and click **Publish**
3. Within a few seconds, refresh `https://your-real-domain.vercel.app/projects` — the change should appear immediately, with no redeploy needed

## Step 9: (Optional) Add a Custom Domain

If you own a domain name (e.g. from Namecheap, Google Domains, Cloudflare):

1. In Vercel, go to your project → **Settings** → **Domains**
2. Enter your domain and follow the DNS instructions (usually adding a CNAME or A record at your registrar)
3. Vercel automatically issues a free SSL certificate via Let's Encrypt

This step is entirely optional — the free `.vercel.app` subdomain works great and is genuinely permanent, not a trial.

## Step 10: Automatic Future Deployments

From now on, every time you `git push` to your `main` branch, Vercel automatically rebuilds and redeploys your site — this is called **Continuous Deployment**, and it's included free. Try it:

```bash
# make any small code change, e.g. tweak text in Hero.tsx
git add .
git commit -m "Tweak hero copy"
git push
```

Watch the **Deployments** tab in Vercel — a new deployment should kick off automatically within seconds of your push.

## Checkpoint ✅

You now have:
- Your code pushed to a GitHub repository
- A live, free, publicly accessible portfolio site on Vercel's Hobby tier
- All environment variables correctly configured in production
- Sanity Studio working live at `/studio` on your production domain
- CORS configured so Sanity's API accepts requests from your deployed domain
- A working end-to-end webhook: edits in Sanity Studio appear on the live site within seconds
- Continuous deployment: every `git push` auto-deploys

**Congratulations — your portfolio is live!** Share the link, add it to your resume, and keep it updated any time straight from `/studio`.

Next up: the series **Conclusion**, where we recap everything you've built and suggest where to go from here.
