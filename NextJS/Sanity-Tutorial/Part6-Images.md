# Sanity Mastery - Part 6: Images

## Step 1: The image URL builder

```ts
// src/sanity/image.ts
import createImageUrlBuilder from "@sanity/image-url";
import type { Image } from "sanity";
import { client } from "./client";

const builder = createImageUrlBuilder(client);

// Sanity image *fields* in query results are just references — this builder
// turns { asset: { _ref: "image-abc-800x600-jpg" } } into a real, transformable CDN URL.
export function urlFor(source: Image) {
  return builder.image(source);
}
```

## Step 2: Chainable transforms

```ts
urlFor(post.coverImage)
  .width(1200)
  .height(630)
  .fit("crop")       // crop | clip | fill | fillmax | max | min | scale
  .quality(80)
  .auto("format")    // let Sanity serve WebP/AVIF automatically when supported
  .url();
```

| Method | Purpose |
|---|---|
| `.width(n)` / `.height(n)` | Resize (Sanity's image pipeline resizes on the CDN, no build-time work) |
| `.fit("crop")` | How to fit into given dimensions |
| `.crop("focalpoint")` + hotspot data | Smart-crop using the editor-picked focal point |
| `.quality(n)` | JPEG/WebP quality 0–100 |
| `.auto("format")` | Serve modern formats automatically |
| `.blur(n)` | Generate a blurred placeholder variant |

## Step 3: Respecting the editor's hotspot/crop

Recall in Part 2 we set `options: { hotspot: true }` on `coverImage` and `photo`. Editors drag a focal point in Studio; `@sanity/image-url` automatically uses it when you crop:

```tsx
// The builder reads hotspot/crop metadata from the image object automatically —
// no extra code needed, as long as the full image object (not just the URL) is passed in.
<Image
  src={urlFor(post.coverImage).width(1200).height(630).fit("crop").url()}
  alt={post.coverImage?.alt ?? post.title}
  width={1200}
  height={630}
/>
```

## Step 4: Integrating with `next/image`

```ts
// next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "cdn.sanity.io", // Sanity's asset CDN — required allowlist entry
      },
    ],
  },
};

export default nextConfig;
```

```tsx
// src/components/CoverImage.tsx
import Image from "next/image";
import { urlFor } from "@/sanity/image";
import type { SanityImage } from "@/sanity/types";

export function CoverImage({
  image,
  alt,
  priority = false,
}: {
  image?: SanityImage;
  alt: string;
  priority?: boolean;
}) {
  if (!image) return null;

  return (
    <Image
      src={urlFor(image).width(1600).height(900).fit("crop").auto("format").url()}
      alt={alt}
      width={1600}
      height={900}
      // `priority` should be true for above-the-fold images (e.g. the post
      // detail page's hero) to avoid Next.js lazy-loading them and hurting LCP.
      priority={priority}
      className="rounded-xl object-cover w-full h-auto"
    />
  );
}
```

## Step 5: Low-Quality Placeholder (blur-up) Pattern

```ts
// src/sanity/image.ts (extended)
export function urlForBlur(source: Image) {
  return builder.image(source).width(20).height(12).blur(10).quality(20).url();
}
```

```tsx
// Usage: generate a tiny blurred version to use as `placeholder="blur"` fallback
// (next/image's built-in blurDataURL prop expects a base64 data URI in real
// production setups — many teams instead fetch this at build/query time via
// Sanity's metadata.lqip field, shown below, which is simpler.)
```

### Simpler alternative: query Sanity's built-in LQIP metadata directly

```groq
// Add to any query that selects an image field:
coverImage{
  ...,
  "lqip": asset->metadata.lqip,      // ready-to-use base64 blur data URI
  "dimensions": asset->metadata.dimensions
}
```

```tsx
<Image
  src={urlFor(post.coverImage).width(1600).height(900).url()}
  alt={post.title}
  width={1600}
  height={900}
  placeholder="blur"
  blurDataURL={post.coverImage.lqip} // straight from Sanity, zero extra computation
/>
```

> This is the recommended production pattern — Sanity computes and stores the LQIP once at upload time, so you get free blur-up placeholders with a one-line query addition instead of a runtime image transform.

## Checkpoint ✅
- [ ] `src/sanity/image.ts` created with `urlFor` helper
- [ ] `next.config.ts` allowlists `cdn.sanity.io`
- [ ] `CoverImage` component renders cropped, hotspot-aware images via `next/image`
- [ ] You understand the `metadata.lqip` GROQ pattern for free blur placeholders

**Next: Part 7 — Draft Mode & Live Preview**
