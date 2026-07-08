## Blog Tutorial - Appendix C: Troubleshooting & Common Errors

## Next.js 16 migration pitfalls (read this section first)

### "params is a Promise" / "Cannot read properties of undefined" on slug
This is the single most common error when following this tutorial. In Next.js 16, `params` in any dynamic route file (`page.tsx`, `generateMetadata`, `opengraph-image.tsx`) is a `Promise`, not a plain object. If you write:

```tsx
// ❌ Wrong — Next.js 14/15 style, breaks in Next.js 16
export default async function PostPage({ params }: { params: { slug: string } }) {
  const post = await client.fetch(POST_QUERY, { slug: params.slug }); // params.slug is undefined
```

...you'll get a runtime error or `undefined` slug. Fix it by typing `params` as a Promise and awaiting it:

```tsx
// ✅ Correct — Next.js 16 style
export default async function PostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await client.fetch(POST_QUERY, { slug });
```

Apply this in every file listed in Appendix A's "Next.js 16 checklist" section: `posts/[slug]/page.tsx`, `posts/[slug]/opengraph-image.tsx`, `categories/[slug]/page.tsx`, `authors/[slug]/page.tsx`.

### Signed-in users incorrectly see the members-only paywall
Caused by forgetting to `await` Clerk's `auth()`:

```tsx
// ❌ Wrong
const { userId } = auth(); // userId is always undefined, since this destructures a Promise

// ✅ Correct
const { userId } = await auth();
```

If `canViewFullContent` is always `false` for logged-in users, this missing `await` is the first thing to check.

### Comments silently fail with "You must be signed in" even when signed in
Same root cause as above, but inside the `submitComment` Server Action (Part 8) — check that both `auth()` and `currentUser()` are awaited:

```ts
const { userId } = await auth();
const user = await currentUser();
```

### Build fails with a TypeScript error mentioning "Promise<{ slug: string }>" is not assignable
This usually means one function in a route file was updated to the async `params` shape but another (e.g. `generateMetadata` was fixed but the default page export wasn't, or vice versa) still uses the old synchronous type. All functions in the same route file — the page component, `generateMetadata`, and any other exports reading `params` — must consistently use `params: Promise<{ slug: string }>` and `await params`.

### "next dev" or "next build" behaves unexpectedly / mentions Turbopack
Next.js 16 uses Turbopack by default for both `next dev` and `next build` — this is expected and not an error. If you see Turbopack-specific warnings referencing a plugin or loader that only worked with the older Webpack-based pipeline, check that package's release notes for Turbopack/Next.js 16 compatibility; most mainstream packages used in this tutorial (Sanity, Clerk, Tailwind v4, next-themes, react-syntax-highlighter) work fine.

### Node version errors during install or build ("Unsupported engine" or similar)
Next.js 16 requires Node.js 20.9+. Run `node -v` locally; if it's below 20.9, install Node 22 LTS (`nvm install 22 && nvm use 22`). On Vercel, check Settings → General → Node.js Version and set it to 20.x or newer.

## Module / dependency errors

## "Module not found" or import errors
- Confirm you installed all packages listed for that Part (`npm install ...`).
- Confirm your `tsconfig.json` has the `@/*` path alias pointing to `./src/*` (create-next-app sets this up automatically if you chose the `src/` directory option in Part 1).
- Restart the dev server after installing new packages or editing config files (`Ctrl+C` then `npm run dev`).

## Tailwind v4 styling not applying at all
- Confirm `src/app/globals.css` starts with `@import "tailwindcss";` — the old `@tailwind base; @tailwind components; @tailwind utilities;` trio from Tailwind v3 does not work in v4.
- Confirm there is **no leftover `tailwind.config.ts`** file causing confusion — Tailwind v4 in this project is configured entirely in CSS.
- Restart the dev server after editing `globals.css`.

## Sanity Studio at /studio shows a blank page or errors
- Check `.env.local` has correct `NEXT_PUBLIC_SANITY_PROJECT_ID` and `NEXT_PUBLIC_SANITY_DATASET` — typos here are the most common cause.
- Confirm `sanity.config.ts` is in the **project root** (same level as `package.json`), not inside `src/`.
- Confirm the route file is exactly `src/app/studio/[[...tool]]/page.tsx` (double square brackets, "tool" literal).
- Clear `.next` cache and restart: delete the `.next` folder, then `npm run dev` again.

## "CORS origin not allowed" error fetching Sanity data
- Go to sanity.io/manage → your project → API → CORS Origins, and add the exact URL you're browsing from (including `http://` vs `https://`, and the exact port, e.g. `http://localhost:3000`).
- In production, add your real Vercel URL (and any custom domain) the same way.
- If using authenticated write requests from the browser (we don't in this tutorial — writes happen server-side only), you'd also need "Allow credentials" checked.

## Images not loading / "hostname not configured" error
- Add the image's domain to `next.config.ts` under `images.remotePatterns`. This tutorial requires both `cdn.sanity.io` (Part 4) and `img.clerk.com` (Part 8).
- Restart the dev server after editing `next.config.ts` — Next.js only reads this file on startup.

## Clerk: "Publishable key not valid" or middleware errors
- Confirm `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY` are both set and copy-pasted without extra whitespace.
- Confirm `src/middleware.ts` exists at `src/middleware.ts` (not inside `app/`) — this is a Next.js convention requirement, not a Clerk one.
- If `/studio` stops working after adding Clerk, double check your middleware `matcher` excludes `studio` as shown in Part 7.
- Confirm your installed `@clerk/nextjs` version explicitly supports Next.js 16 (check its changelog) — older versions predating Next.js 16 may not implement the async `auth()` API correctly.

## Comments don't appear after submitting
- Confirm `SANITY_API_WRITE_TOKEN` is set and has **Editor** (not just Viewer) permissions.
- Check the terminal running `npm run dev` for a thrown error from the Server Action — errors in Server Actions often only show in the server terminal, not the browser console.
- Confirm `revalidatePath` in `src/app/actions/comments.ts` uses the exact same path as the post page URL.
- Confirm `await auth()` and `await currentUser()` are both awaited (see Next.js 16 pitfalls section above).

## Members-only paywall shows for everyone, even signed-in users
- Confirm you're calling `await auth()` from `@clerk/nextjs/server` (not the client-side `useAuth()` hook, and not without `await`) inside a Server Component.
- Confirm the post actually has `isMembersOnly: true` set and published in the Studio, and that you're signed in with the same browser session you're testing in (not an incognito window from an earlier test).

## Build fails on Vercel but works locally
- Almost always caused by a missing environment variable in Vercel's dashboard — compare your Vercel env var list against your local `.env.local` line by line.
- Check the Vercel build log for the actual TypeScript/lint error — `next build` is stricter than `next dev` (it also runs a full type check), and Next.js 16 will specifically flag any remaining synchronous `params` usage as a type error.
- Confirm Vercel's Node.js Version setting is 20.x+ (see Next.js 16 pitfalls section above).
- If the error mentions `generateStaticParams` or fetch failures during build, confirm your Sanity CORS origins include the domain Vercel's build process fetches from — usually not required (build-time fetches from Vercel's servers aren't browser CORS requests) but double check your Sanity Project ID/dataset env vars are correctly set in Vercel.

## Open Graph image route returns an error or 500
- Confirm `export const runtime = "edge";` is present in `opengraph-image.tsx` — the `ImageResponse` API requires the Edge runtime.
- Confirm `params` is typed as `Promise<{ slug: string }>` and awaited (see Next.js 16 pitfalls section above) — this file is easy to forget when updating the rest of the post route.
- Keep the JSX inside `ImageResponse` simple — it supports a limited subset of CSS (flexbox layouts work well; complex CSS like `grid` or custom fonts require extra setup not covered in this tutorial).

## Dark mode flashes light mode briefly on page load
- Confirm `suppressHydrationWarning` is on the `<html>` tag in `layout.tsx`.
- Confirm you're using `next-themes`'s `ThemeProvider` with `attribute="class"` matching the `@custom-variant dark (&:where(.dark, .dark *));` rule in `globals.css` — a mismatch here (e.g., forgetting the `@custom-variant dark` line, which is Tailwind v4's replacement for the old `darkMode: "class"` config option) is the most common cause of dark mode not applying at all.

## General debugging tips
- Read the exact error message and file/line number first — most Next.js errors point precisely at the problem.
- After editing `.env.local`, always restart `npm run dev` — environment variables are only read at server startup.
- When you hit any bug involving a dynamic route or auth check, check for a missing `await` first — this accounts for the large majority of bugs when migrating tutorial code to Next.js 16.
- When in doubt, compare your file against the exact code block in the relevant tutorial Part or Appendix A — every snippet in this series is complete and intended to be copy-paste accurate.
