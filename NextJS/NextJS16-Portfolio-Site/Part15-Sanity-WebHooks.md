# Part 15: On-Demand Revalidation with Sanity Webhooks

Our pages are cached by Next.js for speed. But right now, if you edit content in `/studio`, the live site won't reflect the change until the cache naturally expires or you redeploy. In this part we set up a **webhook**: Sanity notifies our app the instant content is published, and we surgically revalidate just the affected cache tags — instantly, for free.

## Step 1: Create a Revalidation API Route

This is a Next.js **Route Handler** — a serverless API endpoint that lives right inside our app, deployed automatically with the rest of the project on Vercel (no separate hosting needed).

```ts
// File: app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";
import { parseBody } from "next-sanity/webhook";

type WebhookPayload = {
  _type: string;
  slug?: { current?: string };
};

export async function POST(req: NextRequest) {
  try {
    const { isValidSignature, body } = await parseBody<WebhookPayload>(
      req,
      process.env.SANITY_REVALIDATE_SECRET
    );

    if (!isValidSignature) {
      return NextResponse.json(
        { message: "Invalid signature" },
        { status: 401 }
      );
    }

    if (!body?._type) {
      return NextResponse.json({ message: "Bad request" }, { status: 400 });
    }

    // Revalidate the general tag for this document type
    revalidateTag(body._type);

    // If it has a slug, also revalidate the specific document's tag
    if (body.slug?.current) {
      revalidateTag(`${body._type}:${body.slug.current}`);
    }

    return NextResponse.json({
      revalidated: true,
      type: body._type,
      slug: body.slug?.current ?? null,
      now: Date.now(),
    });
  } catch (err) {
    console.error(err);
    return NextResponse.json(
      { message: "Error revalidating", error: `${err}` },
      { status: 500 }
    );
  }
}
```

This matches the cache tags we've been passing to `sanityFetch` since Part 7 (e.g. `["project"]`, `["project:my-slug"]`) — so a publish event for a specific project instantly busts the cache for its listing page AND its detail page, without touching unrelated pages.

## Step 2: Generate a Webhook Secret

Run this in your terminal to generate a random secret string:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Copy the output. Add it to `.env.local`:

```bash
# File: .env.local (add this line)
SANITY_REVALIDATE_SECRET=paste_the_generated_secret_here
```

Note this variable does **not** have the `NEXT_PUBLIC_` prefix — it must stay server-side only, since it's used to verify that webhook requests genuinely came from Sanity.

## Step 3: Create the Webhook in Sanity

1. Go to https://www.sanity.io/manage and open your project
2. Navigate to **API** → **Webhooks** → **Create webhook**
3. Fill in:
   - **Name**: `Revalidate Next.js Cache`
   - **URL**: `https://your-deployed-domain.vercel.app/api/revalidate` (we'll update this after Part 16's deployment; for now you can leave a placeholder and edit it later, or test locally with a tunneling tool — see the note below)
   - **Dataset**: `production`
   - **Trigger on**: Create, Update, Delete
   - **Filter**: leave blank (fires for all document types) — our route handles filtering internally
   - **Projection**: `{ _type, slug }`
   - **HTTP method**: `POST`
   - **API version**: latest (or match `NEXT_PUBLIC_SANITY_API_VERSION`)
   - **Secret**: paste the same secret from Step 2 into the **Secret** field

4. Click **Save**.

> **Testing locally (optional):** Since Sanity's webhook needs a public URL to reach your app, you can't fully test this against `localhost` without a tunneling tool like `ngrok` — but it's entirely optional here since we'll finish wiring the real webhook URL once deployed in Part 16. Feel free to skip live-testing until after deployment.

## Step 4: Understand What Just Happened

- Every time you **Publish** (create, update, or delete) a document in `/studio`, Sanity sends a signed POST request to `/api/revalidate`.
- Our route verifies the request's signature using `SANITY_REVALIDATE_SECRET` (via `parseBody` from `next-sanity/webhook`) so nobody else can trigger fake revalidations.
- We call `revalidateTag(...)` for the document's `_type` (e.g. `"project"`) and, if applicable, its specific slug tag (e.g. `"project:my-slug"`).
- Next.js immediately marks matching cached data as stale and refetches it on the next request — so your homepage's featured projects, the `/projects` listing, and that specific project's detail page all reflect the edit within seconds, without a redeploy.

## Step 5: (Optional) Also Revalidate the Sitemap

Since `app/sitemap.ts` also depends on project/post slugs, add a tag to those specific fetches too, if you'd like the sitemap to update instantly as well — this is optional since sitemaps are less time-sensitive:

```ts
// File: app/sitemap.ts (excerpt — add tags to fetch calls)
const projectSlugs = await sanityFetch<string[]>({
  query: allProjectSlugsQuery,
  tags: ["project"],
});
const postSlugs = await sanityFetch<string[]>({
  query: allPostSlugsQuery,
  tags: ["post"],
});
```

## Checkpoint ✅

You now have:
- A `/api/revalidate` Route Handler that verifies Sanity webhook signatures
- A generated, secret-protected revalidation secret in `.env.local`
- A webhook configured in Sanity's dashboard (URL to be finalized once deployed)
- An understanding of how tag-based on-demand revalidation keeps your live site instantly in sync with Sanity content, for free, with no polling or redeploys

Commit your progress:

```bash
git add .
git commit -m "Add on-demand revalidation webhook route"
```

Next up: **Part 16: Deploying to Vercel for Free**, where we push our code to GitHub, deploy to Vercel, set environment variables, and finalize the Sanity webhook URL.
