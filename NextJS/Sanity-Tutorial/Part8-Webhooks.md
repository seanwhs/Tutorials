# Sanity Mastery - Part 8: On-Demand Revalidation via Webhooks

Goal: the instant an editor **publishes** in Studio, the live site updates — no waiting for a timer, no redeploy.

## Step 1: Create the webhook in Sanity's dashboard

1. https://www.sanity.io/manage → your project → **API** → **Webhooks** → **Create webhook**
2. **Name:** `Next.js Revalidate`
3. **URL:** `https://yourapp.com/api/revalidate`
4. **Dataset:** `production`
5. **Trigger on:** Create, Update, Delete
6. **Filter (GROQ):** `_type == "post" || _type == "author" || _type == "category" || _type == "siteSettings"`
   — only fires the webhook for document types we actually cache/tag
7. **Projection:** `{ "_type": _type, "slug": slug.current }` — keeps the payload small
8. **Secret:** paste a new random string (same idea as `SANITY_PREVIEW_SECRET` in Part 7, different value)

```bash
# .env.local
SANITY_REVALIDATE_SECRET=another_long_random_string_here
```

## Step 2: The Route Handler that verifies and revalidates

```ts
// src/app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";
import { parseBody } from "next-sanity/webhook";

// Shape of the projection we configured in the webhook dashboard (Step 1.7)
type WebhookPayload = {
  _type: string;
  slug?: string;
};

export async function POST(req: NextRequest) {
  try {
    // next-sanity's parseBody verifies the Sanity-Webhook-Signature header
    // using SANITY_REVALIDATE_SECRET — this proves the request really came
    // from Sanity and wasn't forged by a random POST to guess your tags.
    const { isValidSignature, body } = await parseBody<WebhookPayload>(
      req,
      process.env.SANITY_REVALIDATE_SECRET
    );

    if (!isValidSignature) {
      return new NextResponse("Invalid signature", { status: 401 });
    }

    if (!body?._type) {
      return new NextResponse("Bad Request", { status: 400 });
    }

    // Always bust the broad, type-level tag (covers list pages like /blog)
    revalidateTag(body._type);

    // Additionally bust the specific document's tag if we have a slug —
    // this matches the `post:${slug}` tag pattern established in Part 4.
    if (body.slug) {
      revalidateTag(`${body._type}:${body.slug}`);
    }

    return NextResponse.json({
      revalidated: true,
      type: body._type,
      slug: body.slug ?? null,
      now: Date.now(),
    });
  } catch (err) {
    console.error("Revalidation error:", err);
    return new NextResponse("Error revalidating", { status: 500 });
  }
}
```

## Step 3: Make sure every relevant query is tagged consistently

This is a recap/audit of tags established across earlier parts — revalidation only works if tags match exactly between the `fetch` call and the `revalidateTag` call.

```ts
// src/sanity/queries.ts — tags used at each call site (for reference)

// allPostsQuery  -> tags: ["post"]                     (Part 4, blog index page)
// postBySlugQuery -> tags: ["post", `post:${slug}`]    (Part 4, post detail page)
// authorQuery     -> tags: ["author"]
// categoryQuery   -> tags: ["category"]
// siteSettingsQuery -> tags: ["siteSettings"]
```

```ts
// Example: editing an author's bio triggers the webhook with _type: "author"
// -> revalidateTag("author") busts every page that fetched with tags: ["author"],
//    e.g. an /authors/[slug] page, without touching unrelated /blog pages.
```

## Step 4: Testing locally with a tunnel

Webhooks need a public URL, so local testing requires a tunnel:

```bash
npx untun@latest tunnel http://localhost:3000
# or: ngrok http 3000
```

Temporarily point the Sanity webhook's URL at the tunnel's HTTPS URL + `/api/revalidate`, edit a post in Studio, publish, and confirm your terminal logs the `POST` hit and the site updates without a manual refresh-cache.

## Step 5: Manual/admin-triggered revalidation (optional escape hatch)

Sometimes you want a manual "flush cache" button for admins, independent of webhooks:

```ts
// src/app/api/revalidate/manual/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const { secret, tag } = await req.json();

  if (secret !== process.env.SANITY_REVALIDATE_SECRET) {
    return new NextResponse("Invalid secret", { status: 401 });
  }
  if (!tag) {
    return new NextResponse("Missing tag", { status: 400 });
  }

  revalidateTag(tag);
  return NextResponse.json({ revalidated: true, tag });
}
```

## Debugging Checklist

| Symptom | Likely Cause |
|---|---|
| Webhook shows "failed" in Sanity dashboard | Route not publicly reachable, or wrong URL/path |
| `isValidSignature: false` always | `SANITY_REVALIDATE_SECRET` mismatch between `.env.local` and dashboard webhook secret |
| Webhook succeeds (200) but page doesn't update | Tag mismatch — the tag used in `revalidateTag()` doesn't exactly match a tag used in a `fetch` call |
| Works for `post` but not `author` | Forgot to add `author` to the webhook's GROQ filter, or forgot the `tags: ["author"]` on that query |

## Checkpoint ✅
- [ ] Webhook created in Sanity dashboard, filtered to relevant `_type`s, with a projection and secret
- [ ] `/api/revalidate` verifies the signature and calls `revalidateTag`
- [ ] Publishing an edit in Studio updates the live site within seconds, no redeploy
- [ ] Tags audited: every `sanityFetch` call site's `tags` array has a matching `revalidateTag` path

**Next: Part 9 — Auth, Tokens, CORS & Roles**
