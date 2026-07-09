# Sanity Mastery - Appendix D: Troubleshooting and Common Errors

# Appendix D: Troubleshooting & Common Errors

## Studio / Setup Issues (Part 1)

| Error / Symptom | Cause | Fix |
|---|---|---|
| `projectId is required` | `.env.local` missing or not loaded | Confirm file exists at project root, restart `npm run dev` |
| Blank white screen at `/studio` | Missing `"use client"` directive | Must be the very first line in `page.tsx`, before imports |
| Studio loads, shows "Unauthorized" | Logged into wrong Sanity account | Log out, log in with the account that owns the project |
| Turbopack can't resolve `sanity.config` | Wrong relative import depth | Count folder levels from `src/app/studio/[[...tool]]/page.tsx` back to root exactly |

## Schema Issues (Part 2)

| Error / Symptom | Cause | Fix |
|---|---|---|
| New document type doesn't appear in Studio | Not added to `schemaTypes/index.ts` `types` array | Import and add it, restart dev server |
| "Cannot read property of undefined" in preview `prepare()` | `select` keys don't match actual field paths | Double-check dot-path in `select`, e.g. `"author.name"` requires author to be expanded |
| Reference field shows no options | Referenced document type has zero documents yet | Create at least one document of the target type first |

## GROQ Issues (Part 3)

| Error / Symptom | Cause | Fix |
|---|---|---|
| Query returns `null` for a field that has data | Forgot to expand a reference with `->` | Add `->{ fields }` after the reference field name |
| Query returns an array when you expected one object | Forgot `[0]` at the end of a single-document query | Add `[0]` to unwrap |
| Params seem ignored, query returns everything | Used string interpolation instead of `$param` | Always pass params as the second argument to `.fetch()`, reference as `$name` in the query string |

## Fetching / Caching Issues (Part 4, 8)

| Error / Symptom | Cause | Fix |
|---|---|---|
| Page shows stale data after publishing | Tag mismatch between `sanityFetch` call and `revalidateTag` call | Audit exact tag strings — they must match character-for-character |
| `params` is `undefined` / TypeError destructuring params | Forgot to `await params` (Next.js 16 breaking change) | `const { slug } = await params;`, never destructure directly off the prop |
| Build fails: "params should be awaited" warning/error | Same as above, in `generateMetadata` or another lifecycle function | Await params in every function that receives it, not just the page component |
| `generateStaticParams` doesn't pre-render anything | GROQ query in it returns empty array | Test the query directly in `/studio/vision` against real data |

## Draft Mode / Preview Issues (Part 7)

| Error / Symptom | Cause | Fix |
|---|---|---|
| Preview always shows published content, never drafts | `sanityFetch` not checking `draftMode()`, or checking it without `await` | Ensure `const { isEnabled } = await draftMode();` before branching |
| "Invalid preview secret" on `/api/draft` | `SANITY_PREVIEW_SECRET` mismatch between Studio config and `.env.local` | Confirm identical string in both places, per-environment in Vercel |
| Preview banner never disappears | `/api/draft/disable` not calling `draft.disable()` correctly, or route not hit | Confirm the "Exit preview" link points to the correct route |
| Studio's "Preview" button 404s | `NEXT_PUBLIC_SITE_URL` unset or wrong in that environment | Set it correctly per-environment in Vercel env vars |

## Webhook / Revalidation Issues (Part 8)

| Error / Symptom | Cause | Fix |
|---|---|---|
| Webhook shows "failed" in dashboard | URL unreachable (e.g. testing against `localhost` without a tunnel) | Use `ngrok`/`untun` for local testing, real domain in production |
| `isValidSignature: false` always | Secret mismatch, or `parseBody` given the wrong secret var | Confirm `SANITY_REVALIDATE_SECRET` matches the webhook dashboard's configured secret exactly |
| Webhook succeeds (200) but nothing updates | Tag mismatch (see Fetching Issues above), or `_type` not covered by the GROQ filter | Widen webhook filter, confirm tag names |

## Images Issues (Part 6)

| Error / Symptom | Cause | Fix |
|---|---|---|
| `next/image` throws "hostname not configured" | Missing `remotePatterns` entry | Add `cdn.sanity.io` to `next.config.ts` |
| Image looks cropped wrong, ignoring editor's focal point | Hotspot not passed through — using a plain URL string instead of the full image object | Always call `urlFor(fullImageObject)`, not a pre-extracted URL string, so hotspot metadata is available |
| Blur placeholder is a solid gray box | `lqip` not selected in the GROQ projection | Add `"lqip": asset->metadata.lqip` to the query |

## Auth / CORS Issues (Part 9)

| Error / Symptom | Cause | Fix |
|---|---|---|
| Browser console: CORS error calling Sanity API | Origin not in the CORS allowlist | Add the exact origin (protocol + domain + port) in sanity.io/manage → API → CORS Origins |
| Studio login works locally but not in production | Production origin missing from CORS allowlist, or "Allow credentials" unchecked | Add production domain, check the credentials box |
| Token appears in browser Network tab | Accidentally used a secret token inside a Client Component or `NEXT_PUBLIC_*` var | Move the token usage into a Server Action / Route Handler / Server Component only |

## TypeGen Issues (Part 11)

| Error / Symptom | Cause | Fix |
|---|---|---|
| `types.generated.ts` is empty or missing queries | `sanity-typegen.json`'s `path` glob doesn't match your actual query file locations | Adjust `path` to cover all directories containing `` groq`...` `` literals |
| Generated types don't match a query you just edited | Forgot to re-run `npm run typegen` after editing the query or schema | Re-run after every schema/query change; consider a pre-commit hook |

**Next:** Appendix E — GROQ Cheat Sheet
