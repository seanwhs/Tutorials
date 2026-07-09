# Sanity Mastery - Appendix C: Env Vars and Config Reference
[System: Empty message content sanitised to satisfy protocol]
# Appendix C: Environment Variables & Config Reference

## Full `.env.local` Reference Table

| Variable | Secret? | Introduced | Purpose |
|---|---|---|---|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | No | Part 1 | Identifies your Sanity project |
| `NEXT_PUBLIC_SANITY_DATASET` | No | Part 1 | Dataset name, typically `production` |
| `NEXT_PUBLIC_SANITY_API_VERSION` | No | Part 1 | API version pin (use a dated string, e.g. `2025-01-01`) |
| `NEXT_PUBLIC_SITE_URL` | No | Part 7 | Base URL used to build the Studio "Preview" button link |
| `SANITY_API_READ_TOKEN` | **Yes** | Part 7 | Viewer-role token — lets `previewClient` read draft documents |
| `SANITY_PREVIEW_SECRET` | **Yes** | Part 7 | Shared secret validated by `/api/draft` before enabling draft mode |
| `SANITY_REVALIDATE_SECRET` | **Yes** | Part 8 | Shared secret validated by `/api/revalidate` webhook handler |
| `SANITY_WRITE_TOKEN` | **Yes** | Part 9 | Editor-role token — only for server-side write operations (Server Actions) |

## Rule of Thumb: `NEXT_PUBLIC_` Prefix

```text
NEXT_PUBLIC_*  → bundled into client-side JS, visible to any visitor. Only ever
                 put non-secret identifiers here (project id, dataset name, public URLs).

(no prefix)    → server-only, never sent to the browser. All tokens and shared
                 secrets MUST use this form.
```

## All Config Files at a Glance

| File | Purpose | Part Introduced |
|---|---|---|
| `sanity.config.ts` | Studio config: schema, plugins, structure, document actions, preview URL | 1, extended in 2/7/9/10 |
| `sanity.cli.ts` | CLI config for `sanity` commands (deploy, typegen, schema extract) | 1 |
| `next.config.ts` | Next.js config — `images.remotePatterns` allowlists `cdn.sanity.io` | 6 |
| `sanity-typegen.json` | TypeGen input/output paths | 11 |
| `src/sanity/structure.ts` | Custom Studio content tree, singleton enforcement | 10 |
| `src/sanity/actions/preventDeleteIfPublished.ts` | Custom document action | 10 |
| `src/middleware.ts` | Optional `/studio` route gating | 9 |

## CORS Origins Checklist (per environment)

```text
[ ] http://localhost:3000                    (local dev)
[ ] https://<project>.vercel.app             (production)
[ ] https://<project>-*.vercel.app           (preview deployments, if plan supports wildcard)
[ ] Custom domain, if configured (e.g. https://www.yoursite.com)
```

All entries require **"Allow credentials"** checked so the embedded Studio's authenticated session cookies work correctly.

## Webhook Configuration Checklist (Part 8)

```text
[ ] URL points to the correct environment's /api/revalidate
[ ] Dataset matches (production)
[ ] Trigger includes Create, Update, and Delete
[ ] GROQ filter includes every _type your app tags and revalidates
[ ] Projection returns { "_type": _type, "slug": slug.current } (or your equivalent)
[ ] Secret matches SANITY_REVALIDATE_SECRET exactly in that environment
```

## Token Scope Checklist (Part 9)

```text
[ ] SANITY_API_READ_TOKEN = Viewer role only (read + drafts, no write)
[ ] SANITY_WRITE_TOKEN = Editor role only (never Administrator, unless doing schema/CI work)
[ ] No token is ever imported into a "use client" component or exposed via NEXT_PUBLIC_*
[ ] Tokens rotated if ever accidentally committed to git history
```

**Next:** Appendix D — Troubleshooting & Common Errors
