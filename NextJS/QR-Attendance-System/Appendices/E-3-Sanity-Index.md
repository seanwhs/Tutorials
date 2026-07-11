## File

```text
src/lib/sanity/index.ts
```

---

### Purpose

This file acts as the public API for the Sanity infrastructure.

Nothing outside `lib/sanity` imports individual files.

Everything imports from:

```ts
import {
    sanityReadClient,
    sanityWriteClient,
    urlFor,
    getSanityClient
} from "@/lib/sanity";
```

instead of

```ts
import { sanityReadClient } from "@/lib/sanity/client";
import { urlFor } from "@/lib/sanity/image";
```

Large codebases almost always do this.

---

## Source

```typescript
/**
 * ============================================================================
 * File: src/lib/sanity/index.ts
 *
 * Public exports for the Sanity infrastructure.
 *
 * This module provides a single import location for the rest of
 * the application.
 * ============================================================================
 */

export {
  sanityReadClient,
  sanityWriteClient,
  sanityPreviewClient,
  getSanityClient,
} from "./client";

export {
  urlFor,
} from "./image";

export {
  groq,
} from "next-sanity";
```

---

## Why use an index?

As the application grows,

instead of

```ts
import { sanityReadClient } from "@/lib/sanity/client";
import { urlFor } from "@/lib/sanity/image";
import { groq } from "next-sanity";
```

you write

```ts
import {
    sanityReadClient,
    urlFor,
    groq
} from "@/lib/sanity";
```

Cleaner.

More maintainable.

---

## Next

Now we move into the image helper.

```
src/lib/sanity/image.ts
```

This is where I want to significantly raise the quality of the reference implementation.

Instead of the simplistic helper found in most tutorials, we'll build a production-ready image utility that supports responsive images, automatic width/height handling, blur placeholders, hotspot-aware cropping, modern formats (WebP/AVIF where appropriate), and reusable presets. That gives readers something much closer to what they'd expect in a real-world Next.js 16 application rather than a minimal demo.
