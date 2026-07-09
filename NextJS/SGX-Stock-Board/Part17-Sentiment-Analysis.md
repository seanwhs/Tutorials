# Part 17: News + Sentiment Analysis

## Concept

We pull recent news headlines relevant to a ticker (via RSS feeds, free and key-less) and use our free AI models from Part 14 to classify each headline as bullish, bearish, or neutral for the stock, with a short one-sentence reason. This both feeds real headlines into Part 14's AI Summary (closing that loop) and stands alone as a "News" tab with sentiment badges.

## Step 1: News sources

We use `rss-parser` (installed in Part 2) against free, public RSS feeds — e.g. a general SGX/Singapore business news feed. Because RSS feed URLs and availability can change, we design this to degrade gracefully: if a feed fails to fetch, we log a warning and simply show fewer or no news items rather than erroring the whole page.

## Step 2: The news fetcher

Create `src/lib/news/rss-fetcher.ts`:

```typescript
// src/lib/news/rss-fetcher.ts
import Parser from "rss-parser";

const parser = new Parser();
const FEEDS = ["https://www.businesstimes.com.sg/rss.xml"];

export interface NewsHeadline {
  title: string;
  url: string;
  source: string;
  publishedAt: string;
}

export async function fetchNewsForTicker(ticker: string, companyName: string): Promise<NewsHeadline[]> {
  const results: NewsHeadline[] = [];
  const terms = [ticker.replace(".SI", ""), companyName].map((s) => s.toLowerCase());

  for (const feedUrl of FEEDS) {
    try {
      const feed = await parser.parseURL(feedUrl);
      for (const item of feed.items) {
        const text = `${item.title ?? ""} ${item.contentSnippet ?? ""}`.toLowerCase();
        if (terms.some((term) => term && text.includes(term))) {
          results.push({
            title: item.title ?? "Untitled",
            url: item.link ?? "#",
            source: feed.title ?? "RSS",
            publishedAt: item.isoDate ?? new Date().toISOString(),
          });
        }
      }
    } catch (e) {
      console.warn(`[rss] feed ${feedUrl} failed:`, (e as Error).message);
    }
  }

  return results.slice(0, 10);
}
```

This function: fetches one or more configured RSS feeds, filters items whose title or content mentions the ticker or company name (simple case-insensitive substring match — good enough for a tutorial), maps matches to `{ title, url, source, publishedAt }` capped at 10, and is wrapped so a single failing feed never crashes the whole fetch.

## Step 3: Persisting news + AI sentiment

Create `src/lib/news/sentiment.ts`:

```typescript
// src/lib/news/sentiment.ts
import { generateWithFallback } from "@/lib/ai/summarize";

export async function classifyNewsSentiment(headline: string, ticker: string) {
  try {
    const prompt = `Classify this headline for ${ticker}. Return strict JSON only, no other text: {"sentiment":"bullish|bearish|neutral","reason":"short reason"}. Headline: ${headline}`;
    const result = await generateWithFallback(prompt);
    return JSON.parse(result.text);
  } catch {
    return { sentiment: "neutral", reason: "Unable to classify" };
  }
}
```

This builds a small prompt (reusing the `generateWithFallback` helper from Part 14) instructing the model to respond with strict JSON, given only the headline text and ticker context, and explicitly telling the model not to invent details beyond the headline. The JSON parse is wrapped in try/catch, falling back to `{ sentiment: "neutral", reason: "Unable to classify" }` if parsing fails.

> **Next.js 16 note:** As with every dynamic route in this series (see Part 7), `params` here is `Promise`-based and must be awaited.

Create `src/app/api/news/[ticker]/route.ts`:

```typescript
// src/app/api/news/[ticker]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { cached, CACHE_TTL } from "@/lib/redis";
import { fetchNewsForTicker } from "@/lib/news/rss-fetcher";
import { classifyNewsSentiment } from "@/lib/news/sentiment";
import { normalizeTicker } from "@/lib/tickers";
import { resolveStock } from "@/lib/stock-service";

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  const { ticker: rawTicker } = await params;
  const ticker = normalizeTicker(rawTicker);
  const stock = await resolveStock(ticker);

  const { data: news } = await cached(`news:${ticker}`, CACHE_TTL.NEWS, async () => {
    const freshHeadlines = await fetchNewsForTicker(ticker, stock.name);

    for (const headline of freshHeadlines) {
      const existing = await prisma.newsItem.findUnique({ where: { url: headline.url } });
      if (existing) continue;

      const sentiment = await classifyNewsSentiment(headline.title, ticker);

      await prisma.newsItem.upsert({
        where: { url: headline.url },
        update: {},
        create: {
          ticker,
          title: headline.title,
          url: headline.url,
          source: headline.source,
          publishedAt: new Date(headline.publishedAt),
          sentiment: sentiment.sentiment,
          sentimentReason: sentiment.reason,
        },
      });
    }

    return prisma.newsItem.findMany({
      where: { ticker },
      orderBy: { publishedAt: "desc" },
      take: 10,
    });
  });

  return NextResponse.json({ ticker, news });
}
```

This route: resolves the stock, fetches news via `fetchNewsForTicker`, for each headline not already stored in the `NewsItem` table (checked by unique `url`), runs `classifyNewsSentiment` and upserts a new `NewsItem` row with the sentiment fields populated — already-stored headlines are read straight from Postgres without re-classifying (avoids wasting free AI quota reclassifying the same headline on every request). The whole result is cached in Redis for 30 minutes to avoid hitting the RSS feed and the AI models excessively.

## Step 4: The News UI

Build a `NewsFeed` component: a list of cards, each showing the headline (linking out to the source URL), source name, relative published time (using `date-fns`'s `formatDistanceToNow`), and a colored sentiment badge (green Bullish, red Bearish, gray Neutral) with the AI's one-line reason shown as a tooltip (shadcn `Tooltip` component) on hover.

## Step 5: Feeding news into the AI Summary (closing the loop from Part 14)

Part 14's AI Summary route already queries the latest 3 `NewsItem` rows for the ticker and passes their titles into `buildStockSummaryPrompt`. Now that this part populates real `NewsItem` rows, the AI Summary can genuinely reference real recent headlines, e.g. "DBS dropped 2.3% this week amid rate cut fears reported by [source]."

## Step 6: Wire into the stock page

Add a "News" tab to the stock detail page's tab set showing the `NewsFeed` component, passing the already-resolved `ticker` string down as a prop (same pattern as every other tab added since Part 9).

## Checkpoint

- [ ] RSS fetching works against at least one real feed and degrades gracefully if the feed is unreachable
- [ ] News items are correctly filtered to those mentioning the ticker/company name
- [ ] Sentiment classification returns valid, defensively-parsed JSON for real headlines
- [ ] News route uses `params: Promise<{ ticker: string }>` and `await params`
- [ ] `NewsItem` rows persist with sentiment populated, and re-fetching doesn't reclassify already-stored headlines
- [ ] `NewsFeed` UI shows headlines with correct color-coded sentiment badges and tooltips
- [ ] AI Summary (Part 14) now incorporates real recent headlines when available

Next: Part 18, Auth & Watchlists using Clerk, where we finally let users create accounts and persist their own tracked tickers and target alert prices.
