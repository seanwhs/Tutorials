## Appendices

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
Companion reference to all 10 parts.

---

## Appendix A: Codebase Reference

### Full Project File Tree

```
orbit/
├── .env.local
├── .gitignore
├── .npmrc
├── next.config.ts
├── package.json
├── tsconfig.json
├── components.json
├── sanity.config.ts
├── sanity/
│   └── schemaTypes/
│       ├── index.ts
│       ├── servicePackage.ts
│       └── article.ts
├── prisma/
│   ├── schema.prisma
│   ├── seed.ts
│   └── migrations/
│       └── ...
└── src/
    ├── proxy.ts
    ├── app/
    │   ├── layout.tsx
    │   ├── globals.css
    │   ├── page.tsx
    │   ├── (auth)/
    │   │   ├── sign-in/[[...sign-in]]/page.tsx
    │   │   └── sign-up/[[...sign-up]]/page.tsx
    │   ├── (dashboard)/
    │   │   ├── layout.tsx
    │   │   └── dashboard/
    │   │       ├── page.tsx
    │   │       ├── projects/
    │   │       │   ├── page.tsx
    │   │       │   ├── actions.ts
    │   │       │   ├── [id]/
    │   │       │   │   ├── page.tsx
    │   │       │   │   └── comment-actions.ts
    │   │       │   └── new/
    │   │       │       ├── page.tsx
    │   │       │       └── request-project-form.tsx
    │   │       ├── admin/
    │   │       │   └── active-projects/page.tsx
    │   │       └── settings/page.tsx
    │   ├── studio/
    │   │   └── [[...tool]]/
    │   │       ├── page.tsx
    │   │       ├── studio-client.tsx
    │   │       └── layout.tsx
    │   └── api/
    │       ├── admin/set-role/route.ts
    │       ├── inngest/route.ts
    │       └── sanity/revalidate/route.ts
    ├── components/
    │   ├── ui/                  (shadcn/ui generated primitives)
    │   ├── dashboard/
    │   │   ├── sidebar.tsx
    │   │   ├── project-card.tsx
    │   │   └── project-card-skeleton.tsx
    │   └── shared/
    └── lib/
        ├── utils.ts
        ├── clerk/
        │   └── roles.ts
        ├── sanity/
        │   ├── client.ts
        │   ├── queries.ts
        │   └── image.ts
        ├── db/
        │   ├── prisma.ts
        │   ├── queries.ts
        │   └── authorize.ts
        ├── inngest/
        │   ├── client.ts
        │   └── functions/
        │       ├── handle-project-requested.ts
        │       └── weekly-digest.ts
        ├── validations/
        │   ├── project.ts
        │   ├── comment.ts
        │   ├── webhooks.ts
        │   └── validate-action.ts
        └── security/
            └── rate-limit.ts
```

### Template `.env.local`

```bash
# --- Clerk (Part 2) ---
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up

# --- Sanity (Part 2 / Part 7) ---
NEXT_PUBLIC_SANITY_PROJECT_ID=
NEXT_PUBLIC_SANITY_DATASET=production
SANITY_API_TOKEN=
SANITY_WEBHOOK_SECRET=

# --- Neon + Prisma (Part 3) ---
DATABASE_URL=
DIRECT_URL=

# --- Inngest (Part 6) ---
INNGEST_EVENT_KEY=
INNGEST_SIGNING_KEY=

# --- Optional: bundle analysis (Part 9) ---
ANALYZE=false
```

---

## Appendix B: The Free & Open-Source Service Matrix

| Service | Role | Free Tier Scope Used | Verified Within Free Limits? |
|---|---|---|---|
| **Next.js 16** | Orchestration / UI framework | Open-source (MIT), no tier limits | ✅ Yes |
| **Vercel** | Hosting / CI/CD | Hobby plan: unlimited personal projects, generous serverless execution, automatic preview deployments | ✅ Yes |
| **Clerk** | Auth / Identity | Free tier: up to 10,000 MAU, unlimited social/email auth methods | ✅ Yes |
| **Sanity** | Structured Content (CMS) | Free "Team" plan: 3 datasets, ~2 non-admin Studio users, generous document/API quota | ✅ Yes |
| **Neon** | Persistent State (Postgres) | Free tier: 0.5 GB storage, generous compute hours, database branching included | ✅ Yes |
| **Prisma** | ORM / type-safe DB client | Fully open-source (Apache 2.0); no paid add-ons used | ✅ Yes |
| **Inngest** | Background Process Orchestration | Free "Hobby" plan: generous monthly function-run/step allotment, unlimited functions | ✅ Yes |
| **Tailwind CSS** | Styling | Fully open-source (MIT) | ✅ Yes |
| **shadcn/ui** | UI components | Open-source (MIT); copies source, no runtime dependency | ✅ Yes |
| **Zod** | Validation | Fully open-source (MIT) | ✅ Yes |
| **GitHub** | Source control / Vercel trigger | Free tier: unlimited public/private repos for individual use | ✅ Yes |

**Summary:** every service in this series can run indefinitely at zero cost for a small SaaS demo, agency internal tool, or portfolio piece. Hitting any of these limits is itself a signal of real usage that justifies a paid upgrade — the free tiers are production-viable starting points, not toy sandboxes.

---

## Appendix C: Deployment Checklist

**One-time setup:**
- [ ] GitHub repo created, `.env.local` confirmed git-ignored, code pushed to `main`.
- [ ] Vercel project created and linked to the GitHub repo.
- [ ] All env vars from Appendix A's template added to Vercel, correctly scoped to Production / Preview / Development.
- [ ] Neon `preview` branch created and its connection strings assigned to Vercel's *Preview* environment scope.
- [ ] `package.json` build script updated to `prisma migrate deploy && next build`.
- [ ] Clerk dashboard: production domain added to allowed Domains.
- [ ] Clerk dashboard: first user manually promoted to `ADMIN` via public metadata.
- [ ] Inngest: production app registered pointing at `https://<domain>/api/inngest`.
- [ ] Sanity: production webhook registered pointing at `https://<domain>/api/sanity/revalidate`, matching secret, filtered to `servicePackage`/`article` types.

**Every deploy:**
- [ ] `pnpm typecheck` and `pnpm lint` pass locally before pushing.
- [ ] `pnpm build` succeeds locally.
- [ ] Open a PR first for non-trivial changes — verify the Preview deployment against its isolated Neon preview branch before merging.
- [ ] After merge/deploy to Production, run the Part 10 §2.10 smoke test.

**Ongoing hygiene:**
- [ ] Rotate Clerk/Sanity/Inngest secrets periodically; update in Vercel without a code change.
- [ ] Monitor Neon storage/compute and Inngest function-run usage against free-tier limits as usage grows.
- [ ] Keep `prisma/migrations/` committed and linear — never edit an already-applied migration; always generate a new one.
