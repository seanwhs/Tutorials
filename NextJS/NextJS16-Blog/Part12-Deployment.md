## Blog Tutorial — Part 12: Deployment to Vercel

### Step 1: Pre-Deployment Preparation

Before deploying, ensure your sensitive data is excluded from version control and your repository is ready:

1. Verify that your `.env.local` is listed in your `.gitignore` file to prevent leaking secrets.
2. Commit and push your progress to your repository:
```bash
git add .
git commit -m "Complete blog: Next.js 16 + Sanity + Clerk + Tailwind v4, ready to deploy"
git push

```



### Step 2: Vercel Configuration

1. Import your repository into Vercel and ensure the Node.js version is set to **20.x or higher** in *Settings → General*.
2. **Environment Variables:** Add all production equivalents of your `.env.local` variables in the Vercel project settings.
3. **Site URL:** After the initial deployment, update `NEXT_PUBLIC_SITE_URL` with your unique Vercel production URL and trigger a **Redeploy** so the change propagates.

### Step 3: API & Authentication Setup

* **Sanity CORS:** Navigate to your Sanity project dashboard, go to the **API** tab, and add your Vercel production URL to the **CORS Origins** list. Ensure "Allow credentials" is checked.
* **Clerk Domains:** Add your production Vercel URL to your Clerk dashboard's allowed domains list to ensure authentication functions correctly in the live environment.

### Step 4: Verification

Once redeployed, confirm the following functionality in your production environment:

* **Data Fetching:** The homepage loads posts from Sanity.
* **Authentication:** Sign-in and sign-up flows work as expected.
* **Security:** Members-only posts correctly display the paywall when signed out.
* **SEO:** Verify that `sitemap.xml`, `robots.txt`, and generated OG images function correctly on your production domain.

---

### Checkpoint ✅

* [ ] **Deployment:** Site is live and public via your Vercel URL.
* [ ] **Environment:** Node.js 20.x+ is configured for production builds.
* [ ] **External Services:** Sanity CORS and Clerk domains are mapped to the production URL.
* [ ] **CI/CD:** Git pushes now trigger automatic, seamless redeployments.

**Conclusion:** Congratulations! You have successfully built and deployed a sophisticated, full-stack blog using Next.js 16, Sanity, and Clerk. Your architecture now supports modular content management, secure user authentication, and automated SEO—all ready for production scale.
