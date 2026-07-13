## Blog Tutorial — Part 12: Deployment to Vercel (Free Tier)

Since you don't have a Vercel account yet, we will walk through the entire process—from account creation to the final "live" status. Vercel’s generous free tier for personal projects is the industry standard for deploying Next.js applications, offering automatic SSL, global CDN, and seamless CI/CD integration.

---

### Step 1: Account Setup & Initial Connection

1. **Create Your Account:** Go to [vercel.com](https://vercel.com) and click **"Sign Up"**. It is highly recommended to sign up using the **GitHub** account that hosts your project repository. This grants Vercel permission to watch your repo and deploy automatically.
2. **Verify Access:** Once logged in, navigate to your Vercel Dashboard. Click **"Add New..."** and select **"Project"**.
3. **Import Repo:** You will see a list of your GitHub repositories. Find the one for your blog and click **"Import"**.

### Step 2: Configure Build Settings

Vercel usually detects Next.js settings automatically, but it is best practice to verify them to ensure a smooth build:

1. **Framework Preset:** Ensure this is set to **Next.js**.
2. **Root Directory:** Keep this as `./` unless your project is in a subfolder.
3. **Build Command:** Usually `next build`.
4. **Install Command:** Usually `npm install`, `yarn install`, or `pnpm install` (depending on your lockfile).
5. **Node.js Version:** In **Settings → General → Node.js Version**, explicitly select **20.x or higher** to ensure compatibility with Next.js 16 requirements.

### Step 3: Injecting Secrets (Environment Variables)

Your code cannot function without your API keys. You must move these from your local machine to Vercel's secure cloud storage:

1. In your Project Dashboard, go to **Settings → Environment Variables**.
2. Add every key present in your `.env.local` file one by one:
* `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
* `CLERK_SECRET_KEY`
* `NEXT_PUBLIC_SANITY_PROJECT_ID`
* `SANITY_API_READ_TOKEN` (and any others your app requires).


3. **Note:** These are encrypted at rest and never exposed to the public.
4. **Trigger Deployment:** After adding variables, click **Deployments** in the sidebar, find your latest build, and select **"Redeploy"** to ensure these variables are injected into the build process.

### Step 4: Configuring External Service Origins

For security, Sanity and Clerk block requests from unknown domains. You must "whitelist" your new Vercel production URL (e.g., `your-blog-name.vercel.app`):

* **Sanity CORS:**
1. Log into your [Sanity Manage dashboard](https://www.google.com/search?q=https://manage.sanity.io/).
2. Go to your project → **API** tab → **CORS Origins**.
3. Click **"Add origin"**, paste your production URL, and ensure **"Allow credentials"** is checked.


* **Clerk Domains:**
1. Go to the [Clerk Dashboard](https://www.google.com/search?q=https://dashboard.clerk.com/).
2. Navigate to **"Configure" → "Domains"**.
3. Add your Vercel production URL to the list of allowed domains. This ensures your authentication redirects (Sign-in/Sign-up) know where to send users back after they complete the flow.



### Step 5: Updating the Site URL

If your application relies on a `NEXT_PUBLIC_SITE_URL` variable (often used for canonical URLs or OG Image generation):

1. Copy your live Vercel URL.
2. Go back to Vercel **Settings → Environment Variables**.
3. Edit `NEXT_PUBLIC_SITE_URL` to match your new production domain.
4. **Important:** You must perform another **Redeploy** so the application code registers this new global constant.

---

### Verification Checklist ✅

* [ ] **Account:** Vercel account created and linked to your GitHub.
* [ ] **Build:** Deployment succeeded (Green "Ready" status in Vercel).
* [ ] **Secrets:** All `env` variables mapped correctly in Vercel Settings.
* [ ] **CORS:** Vercel production domain added to Sanity API/CORS settings.
* [ ] **Auth:** Clerk allowed domains updated with your production URL.
* [ ] **Functionality:** Homepage, Login, and Protected Routes verified in the live browser.
* [ ] **Automation:** A test push to your `main` branch automatically updates your site.

---

**Conclusion:** You have effectively moved from a local development environment to a professional, cloud-hosted production architecture. Your blog is now capable of handling traffic, scaling with your content, and maintaining secure user sessions—all hosted for free on Vercel's global infrastructure.
