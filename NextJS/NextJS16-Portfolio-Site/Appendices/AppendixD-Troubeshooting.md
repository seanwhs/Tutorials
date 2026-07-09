# Appendix D: Troubleshooting Guide

Common issues encountered while building this series, and how to fix them.

## Setup & Environment

**"next: command not found" or dev server won't start**
- Make sure you ran `npm install` inside the project folder
- Confirm Node version: `node -v` should show 20.9+ (ideally 22.x). Next.js 16 will refuse to run on older Node versions with a clear error message.

**Changes to `.env.local` aren't taking effect**
- Environment variables are only read when the dev server starts. Stop it (`Ctrl+C`) and run `npm run dev` again.
- On Vercel, you must trigger a new deployment after changing env vars (Settings → Environment Variables won't retroactively apply to existing deployments).

**"Module not found" errors after pulling/copying code**
- Run `npm install` again — you likely added a new dependency (e.g. `next-sanity`, `@portabletext/react`, `next-themes`) in that part but haven't installed it yet. Check the part's Step 1 for the install command.

## Sanity / Studio

**`/studio` shows a blank page or infinite spinner**
- Double-check `NEXT_PUBLIC_SANITY_PROJECT_ID` and `NEXT_PUBLIC_SANITY_DATASET` in `.env.local` exactly match what's shown at https://www.sanity.io/manage
- Restart the dev server after fixing env vars

**"CORS error" when the Studio tries to save/load content**
- Go to https://www.sanity.io/manage → your project → API → CORS Origins
- Make sure `http://localhost:3000` (local) and your Vercel domain (production) are both added, with "Allow credentials" checked

**Content edited/published in Studio doesn't show up on the site**
- Confirm you clicked **Publish**, not just saved a draft — `sanityFetch`/GROQ queries in this series only read published documents (Sanity's default published dataset behavior)
- If using `useCdn: true` (our default), the CDN can lag by a minute for uncached content — this is expected before Part 15's webhook is wired up. After Part 15/16, edits should propagate within seconds via `revalidateTag`.
- Check the browser console / terminal for GROQ query errors — a typo in a field name (e.g. `slug.current` vs `slug`) will silently return `undefined` rather than throwing

**Images don't load / broken image icon**
- Confirm `next.config.ts` has `images.remotePatterns` including `cdn.sanity.io` (Part 8, Step 2) — restart dev server after editing `next.config.ts`
- Confirm the field actually has an image uploaded and published in the Studio

## Next.js 16 Specific Issues

**TypeScript error: "Property 'slug' does not exist on type 'Promise<...>'"**
- This means you're trying to read `params.slug` without `await`-ing `params` first. In Next.js 16, always do:
  ```ts
  const { slug } = await params;
  ```
  before accessing any property, in both page components and `generateMetadata`.

**"searchParams"/"params" related build errors**
- Same root cause as above — Next.js 16 made these Promises across Server Components, Route Handlers, and metadata functions. Audit every dynamic route/page for missing `await`.

**Turbopack-specific build warnings**
- Turbopack is the default in Next.js 16 for both dev and build. Most warnings are safe to ignore during development; if a production build fails specifically under Turbopack, check the Next.js changelog/GitHub issues for your exact version — this is actively evolving but stable for the patterns used in this series.

## Contact Form (Web3Forms)

**Form submits but no email arrives**
- Check spam/junk folder first
- Confirm `NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY` is correct and the email was verified when you signed up at web3forms.com
- Open browser DevTools → Network tab, submit the form, and inspect the response from `api.web3forms.com/submit` for an error message

**"Failed to fetch" error on submit**
- This is usually a network/ad-blocker issue in local dev — some ad blockers block `web3forms.com` requests. Try disabling extensions or testing in an incognito window.

## Deployment (Vercel)

**Build fails on Vercel but works locally**
- Check the build logs in Vercel's Deployments tab for the exact error
- Most common cause: an environment variable is missing in Vercel's settings that exists in your local `.env.local` — cross-reference against Appendix C
- Confirm your Node version compatibility — Vercel auto-detects, but you can pin it in `package.json`:
  ```json
  { "engines": { "node": ">=20.9.0" } }
  ```

**Webhook not triggering revalidation in production**
- Confirm the webhook URL in Sanity's dashboard exactly matches `https://your-domain.vercel.app/api/revalidate` (Part 16, Step 8)
- Confirm `SANITY_REVALIDATE_SECRET` is set identically in both Vercel's environment variables AND the Sanity webhook's "Secret" field
- Check Vercel's Function Logs (Project → Deployments → select deployment → Functions) for errors from `/api/revalidate`

**Studio works locally but not on the deployed site**
- Add your production domain to Sanity's CORS Origins (Part 16, Step 7) — this is the #1 cause of a working local Studio but broken production Studio

## General Debugging Tips

- Read error messages fully — Next.js's error overlay usually points to the exact file/line
- Use the Sanity Studio's built-in **Vision** tool (the tab next to the content structure, added in Part 5) to test GROQ queries directly against your real dataset before wiring them into code
- When in doubt, compare your file against the exact code block in the relevant Part note — a missing import or typo'd field name is the most common source of bugs
