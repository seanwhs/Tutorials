# Additional Resources

## Official Documentation

- **Next.js 16**: https://nextjs.org/docs
- **Tailwind CSS v4**: https://tailwindcss.com/docs (see "CSS-first configuration" / `@theme`)
- **Clerk**: https://clerk.com/docs — `clerkMiddleware` and async `auth()` for App Router
- **Neon**: https://neon.tech/docs — serverless driver: https://neon.tech/docs/serverless/serverless-driver
- **Drizzle ORM**: https://orm.drizzle.team/docs/overview — kit/migrations: https://orm.drizzle.team/docs/kit-overview
- **Vercel AI SDK**: https://ai-sdk.dev/docs — tool calling: https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
- **AI SDK Testing (`ai/test`, `MockLanguageModelV2`)**: https://ai-sdk.dev/docs/ai-sdk-core/testing
- **@ai-sdk/openai-compatible**: https://ai-sdk.dev/providers/openai-compatible-providers
- **Groq**: https://console.groq.com/docs — rate limits: https://console.groq.com/docs/rate-limits
- **Together AI**: https://docs.together.ai — pricing/free models: https://www.together.ai/pricing
- **Hugging Face Inference API**: https://huggingface.co/docs/api-inference
- **Tavily**: https://docs.tavily.com
- **Firecrawl**: https://docs.firecrawl.dev
- **Vitest**: https://vitest.dev/guide
- **Vercel limits / Hobby plan**: https://vercel.com/docs/limits/overview · https://vercel.com/pricing

## Troubleshooting FAQ

**Q: First chat message fails with "relation does not exist."** A: Run migrations (`npm run db:generate` / `db:migrate`) — Steps 1.5 & 6.3.

**Q: `resolveModel` throws a missing API key error despite setting it in Vercel.** A: Redeploy after adding env vars — they only apply going forward.

**Q: Sign-in loops after deploy.** A: Add your production domain to Clerk's allowed origins (Step 6.2).

**Q: A tool call in `ThoughtDashboard` hangs forever.** A: Usually free-tier quota exhaustion on Tavily/Firecrawl — check provider dashboards (Step 6.4).

**Q: Agent loops on `webSearch` and never answers.** A: Confirm `stopWhen: stepCountIs(MAX_AGENT_STEPS)` is intact in `agent-loop.ts` (Steps 2.5, 5.4).

**Q: `ReportView` renders raw unstyled text.** A: Model didn't follow the "## Key Findings/## Sources" contract — more common on smaller free models; try a stronger `MODEL_REGISTRY` entry or tighten the prompt.

**Q: Vitest fails on "API_KEY is not set" despite mocking fetch.** A: Also `vi.stubEnv(...)` the key — key checks happen before the fetch call (Steps 5.2/5.3).

**Q: Production times out on complex questions.** A: Lower `MAX_AGENT_STEPS`, don't push `maxDuration` past Hobby's ceiling (Step 6.1).
