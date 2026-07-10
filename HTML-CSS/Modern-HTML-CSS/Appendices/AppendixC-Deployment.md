# Appendix C: Deployment Checklist

NovaFolio is a fully static site (HTML + CSS, zero build step, zero server-side code), which makes it a perfect fit for free static hosts. Below are complete, free paths for both **GitHub Pages** and **Vercel**.

## Pre-flight checklist (do this before deploying to either host)

- [ ] Run `index.html` through the free W3C validator (validator.w3.org) — zero errors.
- [ ] Confirm exactly one `<main>` landmark and a logical heading order using your browser's Accessibility Tree panel (Part 1).
- [ ] Confirm `box-sizing: border-box` is applied globally (Part 2) — no unexpected horizontal scrollbars at any viewport width.
- [ ] Test the page at 320px, 768px, 1024px, and 1440px widths using browser dev tools' device toolbar (Part 3).
- [ ] Confirm `prefers-reduced-motion` disables all animations/transitions when toggled in your OS accessibility settings (Part 5).
- [ ] Check that all image paths in `assets/` are **relative**, not absolute (`assets/images/foo.png`, not `/Users/you/novafolio/assets/images/foo.png`) — absolute local paths will 404 once deployed.
- [ ] Double check `<link rel="stylesheet" href="css/main.css">` and all `@import` paths inside `main.css` are relative and case-correct — GitHub Pages' underlying storage is case-sensitive even if your local OS filesystem isn't.

## Option A: GitHub Pages (fully free, git-based)

### 1. Create a GitHub repository

- Sign up for a free GitHub account at github.com if you don't have one.
- Create a new repository, e.g. `novafolio`. Public repos get GitHub Pages for free; private repos require a paid plan for Pages.

### 2. Push your project

```
cd novafolio
git init
git add .
git commit -m "Initial NovaFolio commit"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/novafolio.git
git push -u origin main
```

### 3. Enable Pages

- In the repository on GitHub: **Settings → Pages**.
- Under "Build and deployment", set **Source** to "Deploy from a branch".
- Set **Branch** to `main` and folder to `/ (root)` (since `index.html` sits at the repo root).
- Click **Save**.

### 4. Access your live site

- GitHub will build and publish to `https://YOUR-USERNAME.github.io/novafolio/`. This can take 1-2 minutes on first deploy.
- Every subsequent `git push` to `main` automatically redeploys the updated site within a minute or two — no manual redeploy step needed.

### 5. (Optional) Custom domain on GitHub Pages

- Add a `CNAME` file at the repo root containing just your domain, e.g. `www.yourname.dev`.
- In your domain registrar's DNS settings, add a `CNAME` record pointing `www` to `YOUR-USERNAME.github.io`.
- Back in **Settings → Pages**, enter the custom domain and enable **Enforce HTTPS** once GitHub finishes provisioning the certificate (also free).

## Option B: Vercel (fully free tier, git-integrated with instant previews)

### 1. Sign up

- Go to vercel.com and sign up (free "Hobby" tier) using your GitHub account for the smoothest integration.

### 2. Import the project

- From the Vercel dashboard: **Add New → Project**.
- Select your `novafolio` GitHub repository (you'll need to have pushed it to GitHub first, same as Option A steps 1-2).
- Vercel auto-detects a static site with no framework — for a plain HTML/CSS project, leave **Framework Preset** set to "Other" and **Build Command** / **Output Directory** blank; Vercel will simply serve the repo's static files as-is.

### 3. Deploy

- Click **Deploy**. Vercel builds and assigns a live URL immediately, typically `https://novafolio-yourname.vercel.app`.

### 4. Automatic deployments and previews

- Every push to `main` triggers an automatic production redeploy.
- Every push to any other branch, or every pull request, automatically gets its own unique **preview URL** — extremely useful for reviewing a change (e.g., a new "Testimonials" section from Part 1's exercise) before merging it into `main`.

### 5. (Optional) Custom domain on Vercel

- In the project dashboard: **Settings → Domains** → add your domain.
- Vercel provides the exact DNS records (usually an `A` record or `CNAME`) to add at your registrar.
- HTTPS certificates are provisioned automatically and free once DNS propagates.

## Which one should you pick?

| | GitHub Pages | Vercel |
|---|---|---|
| Cost for a static site like this | Free | Free |
| Setup complexity | Slightly more manual (Settings → Pages toggle) | Slightly more automatic (auto-detects on import) |
| Preview deployments per branch/PR | No (native) | Yes, built-in |
| Custom domain + free HTTPS | Yes | Yes |
| Best for | Simple, "set it and forget it" static hosting tied directly to a GitHub repo | Projects likely to grow (e.g., later adding a framework) and that benefit from PR preview links |

For a pure HTML/CSS learning project like NovaFolio, either is equally valid — GitHub Pages keeps everything inside GitHub's ecosystem with no third-party sign-up, while Vercel gives you PR preview links for free, which is a genuinely useful habit to build even on simple projects.

## Post-deployment sanity check

- [ ] Visit the live URL on an actual phone, not just dev tools' emulator, and confirm the `dvh`-based hero height (Part 3) renders correctly with the real mobile browser chrome.
- [ ] Run the live URL through Google's free PageSpeed Insights or Lighthouse (built into Chrome DevTools → Lighthouse tab) — a zero-framework static site like this should score close to 100 on Performance and Accessibility with no extra work, which is a good proof point for how far semantic HTML + modern CSS alone can go before ever reaching for a framework.

---

This completes the full **Modern Foundations: Essential HTML5 and CSS3 for the Modern Web** series — Parts 1-5 plus Appendices A, B, and C. Return to the **Modern Foundations - INDEX (Start Here)** note for the full series map.
