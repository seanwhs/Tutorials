# Part 8: Deploying to Vercel for Free

---

### Why Deploy to Vercel?
Vercel is the best platform for Next.js apps — free tier is generous, automatic deployments from GitHub, and excellent environment variable management.

---

#### Step 8.1: The Target — Prepare Your Code for Production

**Implementation**:

1. Update `next.config.ts` (if needed):
```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
};

export default nextConfig;
```

2. Make sure `.env.local` is **not** committed (it should be in `.gitignore`).

3. Create a `vercel.json` at root (optional but useful):
```json
{
  "env": {
    "NODE_ENV": "production"
  }
}
```

---

#### Step 8.2: The Target — Deploy to Vercel

**Step-by-step Instructions**:

1. **Push your code to GitHub**
   ```bash
   git init
   git add .
   git commit -m "Initial commit - Privacy by Design MindfulLog"
   git branch -M main
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Go to [vercel.com](https://vercel.com)** and sign up (free) with GitHub.

3. **Import your repository** → Select the MindfulLog repo.

4. **Configure Environment Variables** (Critical!):
   In Vercel Dashboard → Project Settings → Environment Variables, add **all** these:

   - `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
   - `CLERK_SECRET_KEY`
   - `DATABASE_URL` (Neon)
   - `HMAC_SALT`
   - `KMS_KEY_NAME`
   - `UPSTASH_REDIS_REST_URL`
   - `UPSTASH_REDIS_REST_TOKEN`

   Set them for **Production** environment.

---

#### Step 8.3: The Target — Final Production Checks

**Before Deploying**:
- Run `npm run build` locally first.
- Test encryption and consent flows one more time.
- Confirm all secrets are in Vercel (not hardcoded).

**Verification After Deploy**:
- Visit your deployed URL.
- Sign up / sign in with Clerk.
- Create a mood log with notes.
- Go to consent settings and toggle options.
- Check that data is encrypted in Neon.

---

**Part 8 Complete!**

Your fully functional, privacy-first application is now live on the internet **for free**.

---

**Full Series Summary** (Parts 0–8)

You have built a complete production application following **Privacy by Design** principles:
- Strong foundations & documentation
- Minimized & encrypted schema
- Field-level encryption + zero-trust policies
- Ethical consent management
- Full user rights (export + deletion)
- Automated privacy CI/CD
- Professional deployment

This is a serious achievement.
