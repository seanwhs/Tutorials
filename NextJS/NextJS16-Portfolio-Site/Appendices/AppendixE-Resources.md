# Appendix E: Further Resources & Next Steps

Official documentation and free learning resources for everything used in this series, plus feature ideas if you want to keep extending your portfolio.

## Official Documentation

- **Next.js**: https://nextjs.org/docs — start with the App Router fundamentals section; the "Data Fetching," "Rendering," and "Caching" pages are especially relevant to what we built
- **React 19**: https://react.dev — the official React docs, includes the new `use()` hook and Server Components explanations
- **Tailwind CSS v4**: https://tailwindcss.com/docs — the "Theme variables" and "Dark mode" pages cover what we used in Parts 3 and 13
- **Sanity**: https://www.sanity.io/docs — the "Content Modeling," "GROQ," and "Webhooks" sections map directly to Parts 6, 7, and 15
- **GROQ Query Language Cheat Sheet**: https://www.sanity.io/docs/query-cheat-sheet
- **@portabletext/react**: https://github.com/portabletext/react-portabletext
- **next-sanity**: https://github.com/sanity-io/next-sanity
- **next-themes**: https://github.com/pacocoursey/next-themes
- **Vercel**: https://vercel.com/docs — "Environment Variables," "Deployments," and "Domains" sections
- **Web3Forms**: https://docs.web3forms.com

## Free Learning Resources

- **Next.js Learn course** (official, free, interactive): https://nextjs.org/learn
- **Sanity's own Next.js + Sanity starter templates** for inspiration on more advanced patterns: https://www.sanity.io/templates
- **web.dev** (Google's free web development learning site) for deeper performance/accessibility guidance: https://web.dev

## Feature Ideas to Extend Your Portfolio

Roughly ordered from easiest to more involved:

1. **RSS feed** for the blog — write an `app/feed.xml/route.ts` Route Handler that queries all posts and returns an XML string
2. **Reading time estimate** on blog posts — compute word count from the Portable Text body and display "~5 min read"
3. **Related projects** — on a project detail page, query other projects sharing at least one tag
4. **Search** — add a client-side search input that filters the projects/posts arrays already fetched (fine for a personal site's scale; no need for a search service)
5. **Testimonials section** — new `testimonial` schema + homepage section, as mentioned in Appendix B
6. **View counters** — track page views via a free service like Vercel Analytics, or a simple Sanity mutation incrementing a counter field (careful with cache implications)
7. **Draft preview mode** — use Next.js Draft Mode + Sanity's `perspective: "previewDrafts"` so you can preview unpublished edits before hitting Publish
8. **Multi-author blog** — the `post.author` reference field already supports this; just create more Author documents (you'd want to relax the "singleton" assumption from Part 8's `authorQuery` for the homepage snippet, though — that one's still hardcoded to the first Author)
9. **Comments** — Giscus (https://giscus.app) is a free, open-source, GitHub Discussions-backed commenting widget that embeds easily in a Next.js blog post page
10. **Custom domain + email** — pair your custom domain (Part 16, Step 9) with a free email forwarding service like Cloudflare Email Routing for a `you@yourdomain.com` address

## A Note on Staying Current

This series was written for **Next.js 16**. Frameworks evolve — always sanity-check core patterns (pun intended) against the current official docs before starting a brand new project, particularly:
- Whether dynamic APIs are still `Promise`-based (`params`, `searchParams`, `cookies()`, `headers()`)
- The current default bundler and any new build/dev flags
- Sanity's current recommended API version string

The architecture, GROQ concepts, and component patterns in this series will very likely remain relevant even as minor version numbers change — the fundamentals of "headless CMS + React framework + static/ISR hosting" are stable, well-established patterns.

Thanks again for following along, and good luck with your portfolio!

---

That's the **entire series, complete**: INDEX → Parts 1–16 → Conclusion → Appendix A (8 parts) → Appendix B → Appendix C → Appendix D → Appendix E.
