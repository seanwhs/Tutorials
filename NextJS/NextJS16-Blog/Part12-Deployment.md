## Blog Tutorial — Part 12: Deployment to Vercel (Free Tier)

Since you don't have a Vercel account yet, we will walk through the entire process—from account creation to the final "live" status. Vercel’s generous free tier for personal projects is the industry standard for deploying Next.js applications, offering automatic SSL, global CDN, and seamless CI/CD integration.

---

### Phase 1: Create and Link Your Account

If you don't have an account, start here to bridge your identity to your codebase.

1. **Sign Up:** Go to [vercel.com](https://vercel.com) and click **"Sign Up"**. It is highly recommended to sign up using the **GitHub** account that hosts your project repository. This grants Vercel permission to watch your repository and deploy automatically.
2. **Existing Account:** If you already signed up with Google, simply log in to your [Vercel Dashboard](https://vercel.com/dashboard), click your **profile avatar** (top-right) → **Settings** → **Authentication**. Find **GitHub** in the list and click **Connect**. This allows Vercel to "see" your repositories.

---

### Phase 2: Project Deployment

Now that your accounts are linked, you can import your project and go live:

1. **Import:** From your Vercel Dashboard, click **"Add New..."** and select **Project**.
2. **Select Repository:** Your repositories will now appear under the "Import Git Repository" section. Find your blog repo and click **Import**.
3. **Build Settings:** Vercel usually detects Next.js automatically. Verify these essentials:
* **Framework Preset:** Ensure this is set to **Next.js**.
* **Root Directory:** Keep as `./`.
* **Node.js Version:** Go to **Settings → General**, and set this to **20.x or higher** to satisfy Next.js 16 requirements.



---

### Phase 3: Injecting Secrets (Environment Variables)

Your application cannot function without its API keys. You must migrate these from your local machine to Vercel's secure, encrypted storage:

1. Navigate to **Settings → Environment Variables**.
2. Add your keys one-by-one from your `.env.local`:
* `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
* `CLERK_SECRET_KEY`
* `NEXT_PUBLIC_SANITY_PROJECT_ID`
* `NEXT_PUBLIC_SANITY_DATASET` (plus any others your app requires).


3. **Trigger a Redeploy:** After saving these, go to the **Deployments** tab in the sidebar, locate your latest build, and select **"Redeploy"** to ensure the build process has access to these keys.

---

### Phase 4: Configuring External Service Origins

Sanity and Clerk act as security gatekeepers; you must "whitelist" your new Vercel production URL so they recognize incoming requests.

* **Sanity CORS:** Log into the [Sanity Manage dashboard](https://www.google.com/search?q=https://manage.sanity.io/), go to your project → **API** tab → **CORS Origins**. Click **"Add origin"**, paste your production URL, and ensure **"Allow credentials"** is checked.
* **Clerk Domains:** In the [Clerk Dashboard](https://www.google.com/search?q=https://dashboard.clerk.com/), navigate to **"Configure" → "Domains"**. Add your Vercel production URL. This allows Clerk to redirect users correctly after authentication flows.

---

### Phase 5: Setting the Site URL

If your code references `NEXT_PUBLIC_SITE_URL` for canonical links or OG images:

1. Go to Vercel **Settings → Environment Variables**.
2. Edit `NEXT_PUBLIC_SITE_URL` to match your new production domain.
3. **Important:** Perform a final **Redeploy** so the application code recognizes the new global constant.

---

### Verification Checklist ✅

* [ ] **Account:** Vercel account created and successfully linked to GitHub.
* [ ] **Build:** Deployment completed (Green "Ready" status).
* [ ] **Secrets:** All `env` variables mapped correctly in Vercel Settings.
* [ ] **CORS:** Vercel domain whitelisted in Sanity API/CORS settings.
* [ ] **Auth:** Clerk allowed domains updated with your production URL.
* [ ] **Functionality:** Homepage, Login, and Protected Routes verified live.
* [ ] **Automation:** A `git push` to your main branch now automatically updates the site.

---

> **Note on Account Conflicts:** If you ever encounter an error saying an account already exists with your GitHub email, it is likely you created a separate Vercel account using that email in the past. If this occurs, simply log out and sign in using your GitHub credentials to manage or merge your settings.

**Conclusion:** You have successfully moved from a local environment to a professional, cloud-hosted production architecture. Your blog is now capable of handling traffic, scaling with your content, and maintaining secure user sessions—all hosted for free on Vercel's global infrastructure.
