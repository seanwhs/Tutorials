# Sanity Mastery - Appendix A (5 of 5): API Routes and Components
Final part of Appendix A. Continues from Appendix A (4 of 5) — this note covers `/api/draft`, `/api/draft/disable`, `/api/revalidate`, `/api/revalidate/manual`, the like-increment Server Action, and shared React components (`PortableTextRenderer`, `CoverImage`, `PreviewBanner`, `LikeButton`), plus root layout and middleware.

## src/app/api/draft/route.ts

```ts
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";
import { client } from "@/sanity/client";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const secret = searchParams.get("secret");
  const slug = searchParams.get("slug");
  const type = searchParams.get("type") ?? "post";

  if (secret !== process.env.SANITY_PREVIEW_SECRET) {
    return new Response("Invalid preview secret", { status: 401 });
  }

  if (!slug) {
    return new Response("Missing slug", { status: 400 });
  }

  const exists = await client.fetch(
    `*[_type == $type && slug.current == $slug][0]._id`,
    { type, slug }
  );
  if (!exists) {
    return new Response("Post not found", { status: 404 });
  }

  const draft = await draftMode();
  draft.enable();

  redirect(`/blog/${slug}`);
}
```

## src/app/api/draft/disable/route.ts

```ts
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";

export async function GET() {
  const draft = await draftMode();
  draft.disable();
  redirect("/blog");
}
```

## src/app/api/revalidate/route.ts

```ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";
import { parseBody } from "next-sanity/webhook";

type WebhookPayload = {
  _type: string;
  slug?: string;
};

export async function POST(req: NextRequest) {
  try {
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

    revalidateTag(body._type);

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

## src/app/api/revalidate/manual/route.ts

```ts
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

## src/app/actions/incrementLikes.ts

```ts
"use server";

import { writeClient } from "@/sanity/writeClient";
import { revalidateTag } from "next/cache";

export async function incrementLikes(postId: string) {
  await writeClient.patch(postId).inc({ likes: 1 }).commit();
  revalidateTag(`post:${postId}`);
}
```

## src/components/PortableTextRenderer.tsx

```tsx
import { PortableText, type PortableTextComponents } from "@portabletext/react";
import Image from "next/image";
import { urlFor } from "@/sanity/image";

const components: PortableTextComponents = {
  block: {
    h2: ({ children }) => <h2 className="text-2xl font-bold mt-8 mb-4">{children}</h2>,
    h3: ({ children }) => <h3 className="text-xl font-semibold mt-6 mb-3">{children}</h3>,
    blockquote: ({ children }) => (
      <blockquote className="border-l-4 border-gray-300 pl-4 italic my-4">
        {children}
      </blockquote>
    ),
    normal: ({ children }) => <p className="mb-4 leading-relaxed">{children}</p>,
  },
  marks: {
    strong: ({ children }) => <strong className="font-semibold">{children}</strong>,
    em: ({ children }) => <em className="italic">{children}</em>,
    code: ({ children }) => (
      <code className="bg-gray-100 rounded px-1 py-0.5 text-sm">{children}</code>
    ),
    link: ({ value, children }) => {
      const target = value?.blank ? "_blank" : undefined;
      return (
        <a
          href={value?.href}
          target={target}
          rel={target ? "noopener noreferrer" : undefined}
          className="text-blue-600 underline hover:text-blue-800"
        >
          {children}
        </a>
      );
    },
  },
  types: {
    image: ({ value }) => (
      <div className="my-6">
        <Image
          src={urlFor(value).width(800).height(450).fit("crop").url()}
          alt={value.alt || ""}
          width={800}
          height={450}
          className="rounded-lg"
        />
      </div>
    ),
    codeBlock: ({ value }) => (
      <pre className="bg-gray-900 text-gray-100 rounded-lg p-4 overflow-x-auto my-6">
        <code className={`language-${value.language}`}>{value.code}</code>
      </pre>
    ),
  },
  list: {
    bullet: ({ children }) => <ul className="list-disc pl-6 mb-4">{children}</ul>,
    number: ({ children }) => <ol className="list-decimal pl-6 mb-4">{children}</ol>,
  },
  listItem: {
    bullet: ({ children }) => <li className="mb-1">{children}</li>,
    number: ({ children }) => <li className="mb-1">{children}</li>,
  },
};

export function PortableTextRenderer({ value }: { value: unknown[] }) {
  return <PortableText value={value as never} components={components} />;
}
```

## src/components/CoverImage.tsx

```tsx
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
      priority={priority}
      className="rounded-xl object-cover w-full h-auto"
    />
  );
}
```

## src/components/PreviewBanner.tsx

```tsx
import { draftMode } from "next/headers";
import Link from "next/link";

export async function PreviewBanner() {
  const { isEnabled } = await draftMode();

  if (!isEnabled) return null;

  return (
    <div className="bg-yellow-400 text-black text-sm px-4 py-2 flex items-center justify-between">
      <span>Preview Mode - viewing draft content</span>
      <Link href="/api/draft/disable" className="underline font-medium">
        Exit preview
      </Link>
    </div>
  );
}
```

## src/components/LikeButton.tsx

```tsx
"use client";

import { incrementLikes } from "@/app/actions/incrementLikes";
import { useTransition } from "react";

export function LikeButton({ postId }: { postId: string }) {
  const [isPending, startTransition] = useTransition();

  return (
    <button
      disabled={isPending}
      onClick={() => startTransition(() => incrementLikes(postId))}
      className="rounded-full border px-3 py-1 text-sm hover:bg-gray-50 disabled:opacity-50"
    >
      Like
    </button>
  );
}
```

## src/app/layout.tsx (relevant excerpt)

```tsx
import { PreviewBanner } from "@/components/PreviewBanner";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <PreviewBanner />
        {children}
      </body>
    </html>
  );
}
```

## src/middleware.ts (optional Studio gating, Part 9)

```ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith("/studio")) {
    const isTeamMember = request.cookies.get("team_member")?.value === "true";
    if (!isTeamMember) {
      return NextResponse.redirect(new URL("/", request.url));
    }
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/studio/:path*"],
};
```

This concludes Appendix A. See Appendix B for full schema-only reference, Appendix C for env/config reference, Appendix D for troubleshooting, and Appendix E for the GROQ cheat sheet.

(Index left unchanged, as requested.)
