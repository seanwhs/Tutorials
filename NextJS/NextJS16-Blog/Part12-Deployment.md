## Blog Tutorial — Part 12: Deployment to Vercel (Free Tier)

Since you’ve already initialized your Vercel account via Google, we’ll bridge that connection to your GitHub repository. Vercel’s free tier is the industry gold standard for deploying Next.js, providing automatic SSL, a global CDN, and seamless CI/CD that triggers every time you push code to your repository.

---

### Phase 1: Linking GitHub to Your Existing Vercel Account

Before importing your project, Vercel needs "eyes" on your GitHub repositories.

1. **Access Settings:** Log in to your [Vercel Dashboard](https://vercel.com/dashboard), click your **profile avatar** (top-right), and select **Settings**.
2. **Authentication:** In the sidebar menu, navigate to the **Authentication** tab.
3. **Connect GitHub:** Locate "Login Methods" or "Connections," find **GitHub**, and click **Connect**. Follow the authorization prompts to grant Vercel access to your repositories.
4. **Verification:** Once authorized, GitHub will appear as a connected method. You can now pull your code directly from the cloud.

---

### Phase 2: Project Deployment

Now that your account is linked, you can import your project and go live:

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
* `SANITY_API_READ_TOKEN` (plus any others your app requires).


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

* [ ] **Account:** Google-based Vercel account successfully linked to GitHub.
* [ ] **Build:** Deployment completed (Green "Ready" status).
* [ ] **Secrets:** All `env` variables mapped correctly in Vercel Settings.
* [ ] **CORS:** Vercel domain whitelisted in Sanity API/CORS settings.
* [ ] **Auth:** Clerk allowed domains updated with your production URL.
* [ ] **Functionality:** Homepage, Login, and Protected Routes verified live.
* [ ] **Automation:** A `git push` to your main branch now automatically updates the site.

---

> **Note on Account Conflicts:** If you ever encounter an error saying an account already exists with your GitHub email, it is likely you created a separate Vercel account using that email in the past. If this occurs, simply log out and sign in using your GitHub credentials to manage or merge your settings.

**Conclusion:** You have successfully moved from a local environment to a professional, cloud-hosted production architecture. Your blog is now capable of handling traffic, scaling with your content, and maintaining secure user sessions—all hosted for free on Vercel's global infrastructure.
