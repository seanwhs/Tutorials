# Part 8: Building the Homepage

Now we build a real homepage: hero section, featured projects grid, and an about snippet — all powered by the Sanity queries from Part 7.

## Step 1: A Reusable ProjectCard Component

```tsx
// File: components/ui/ProjectCard.tsx
import Image from "next/image";
import Link from "next/link";
import { urlFor } from "@/sanity/image";
import type { Project } from "@/sanity/types";

export default function ProjectCard({ project }: { project: Project }) {
  return (
    <Link
      href={`/projects/${project.slug.current}`}
      className="group block overflow-hidden rounded-xl border border-gray-200 transition-shadow hover:shadow-lg dark:border-gray-800"
    >
      {project.coverImage && (
        <div className="relative aspect-video w-full overflow-hidden bg-gray-100 dark:bg-gray-900">
          <Image
            src={urlFor(project.coverImage).width(800).height(450).url()}
            alt={project.title}
            fill
            className="object-cover transition-transform duration-300 group-hover:scale-105"
            sizes="(max-width: 768px) 100vw, 33vw"
          />
        </div>
      )}
      <div className="p-5">
        <h3 className="text-lg font-semibold">{project.title}</h3>
        <p className="mt-2 line-clamp-2 text-sm text-gray-600 dark:text-gray-300">
          {project.summary}
        </p>
        {project.tags && (
          <ul className="mt-3 flex flex-wrap gap-2">
            {project.tags.map((tag) => (
              <li
                key={tag}
                className="rounded-full bg-brand-50 px-2.5 py-1 text-xs font-medium text-brand-700 dark:bg-brand-500/10 dark:text-brand-500"
              >
                {tag}
              </li>
            ))}
          </ul>
        )}
      </div>
    </Link>
  );
}
```

## Step 2: Configure Next.js Image for Sanity's CDN

Next.js's `<Image>` component needs to know Sanity's image domain is allowed. Update `next.config.ts`:

```ts
// File: next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "cdn.sanity.io",
      },
    ],
  },
};

export default nextConfig;
```

Restart the dev server after this change (`Ctrl+C`, then `npm run dev`) — `next.config.ts` is only read on server start.

## Step 3: Build the Hero Section

```tsx
// File: components/home/Hero.tsx
import Link from "next/link";
import Container from "@/components/ui/Container";
import type { SiteSettings } from "@/sanity/types";

export default function Hero({ settings }: { settings: SiteSettings | null }) {
  return (
    <section className="py-20 sm:py-28">
      <Container>
        <h1 className="text-4xl font-bold tracking-tight sm:text-6xl">
          {settings?.title ?? "Hi, I'm Your Name."}
        </h1>
        <p className="mt-6 max-w-2xl text-lg text-gray-600 dark:text-gray-300">
          {settings?.tagline ??
            "I build fast, accessible, and thoughtful web experiences."}
        </p>
        <div className="mt-8 flex gap-4">
          <Link
            href="/projects"
            className="rounded-lg bg-brand-600 px-5 py-3 text-sm font-semibold text-white transition-colors hover:bg-brand-700"
          >
            View my work
          </Link>
          <Link
            href="/contact"
            className="rounded-lg border border-gray-300 px-5 py-3 text-sm font-semibold transition-colors hover:border-brand-600 hover:text-brand-600 dark:border-gray-700"
          >
            Get in touch
          </Link>
        </div>
      </Container>
    </section>
  );
}
```

## Step 4: Build the Featured Projects Section

```tsx
// File: components/home/FeaturedProjects.tsx
import Link from "next/link";
import Container from "@/components/ui/Container";
import ProjectCard from "@/components/ui/ProjectCard";
import type { Project } from "@/sanity/types";

export default function FeaturedProjects({ projects }: { projects: Project[] }) {
  if (projects.length === 0) return null;

  return (
    <section className="py-16">
      <Container>
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold tracking-tight">Featured Projects</h2>
          <Link
            href="/projects"
            className="text-sm font-medium text-brand-600 hover:underline dark:text-brand-500"
          >
            View all →
          </Link>
        </div>
        <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {projects.map((project) => (
            <ProjectCard key={project._id} project={project} />
          ))}
        </div>
      </Container>
    </section>
  );
}
```

## Step 5: Build the About Snippet Section

```tsx
// File: components/home/AboutSnippet.tsx
import Image from "next/image";
import Link from "next/link";
import Container from "@/components/ui/Container";
import { urlFor } from "@/sanity/image";
import type { Author } from "@/sanity/types";

export default function AboutSnippet({ author }: { author: Author | null }) {
  if (!author) return null;

  return (
    <section className="py-16">
      <Container>
        <div className="flex flex-col items-center gap-8 rounded-2xl border border-gray-200 p-8 sm:flex-row dark:border-gray-800">
          {author.photo && (
            <Image
              src={urlFor(author.photo).width(160).height(160).url()}
              alt={author.name}
              width={160}
              height={160}
              className="h-40 w-40 shrink-0 rounded-full object-cover"
            />
          )}
          <div>
            <h2 className="text-2xl font-bold tracking-tight">
              About {author.name}
            </h2>
            <p className="mt-3 text-gray-600 dark:text-gray-300">
              {author.shortBio}
            </p>
            <Link
              href="/about"
              className="mt-4 inline-block text-sm font-medium text-brand-600 hover:underline dark:text-brand-500"
            >
              Read full bio & resume →
            </Link>
          </div>
        </div>
      </Container>
    </section>
  );
}
```

## Step 6: Assemble the Homepage

```tsx
// File: app/(site)/page.tsx
import Hero from "@/components/home/Hero";
import FeaturedProjects from "@/components/home/FeaturedProjects";
import AboutSnippet from "@/components/home/AboutSnippet";
import { sanityFetch } from "@/sanity/fetch";
import {
  siteSettingsQuery,
  featuredProjectsQuery,
  authorQuery,
} from "@/sanity/queries";
import type { SiteSettings, Project, Author } from "@/sanity/types";

export default async function Home() {
  const [settings, projects, author] = await Promise.all([
    sanityFetch<SiteSettings | null>({
      query: siteSettingsQuery,
      tags: ["siteSettings"],
    }),
    sanityFetch<Project[]>({
      query: featuredProjectsQuery,
      tags: ["project"],
    }),
    sanityFetch<Author | null>({
      query: authorQuery,
      tags: ["author"],
    }),
  ]);

  return (
    <main>
      <Hero settings={settings} />
      <FeaturedProjects projects={projects} />
      <AboutSnippet author={author} />
    </main>
  );
}
```

We use `Promise.all` to fire all three Sanity queries concurrently rather than waiting on each one sequentially — this keeps the homepage fast even as we add more sections.

## Step 7: Add More Test Content

Go back to http://localhost:3000/studio and:
1. Mark your test project(s) as **Featured** (toggle the `featured` boolean) and make sure they have a cover image and `publishedAt` date set, then **Publish**.
2. Make sure your **Author** document has a photo and short bio, then **Publish**.

Refresh http://localhost:3000 — you should see your hero, a grid of featured projects with images/tags, and an about snippet with your photo and bio.

## Checkpoint ✅

You now have:
- A `ProjectCard` component, reused across the site
- Next.js `<Image>` configured to load images from Sanity's CDN
- A fully assembled, data-driven homepage: Hero, Featured Projects, About Snippet
- Concurrent data fetching via `Promise.all`

Commit your progress:

```bash
git add .
git commit -m "Build homepage: hero, featured projects, about snippet"
```

Next up: **Part 9: Projects Listing & Dynamic Project Pages**, where we build out `/projects` and `/projects/[slug]` using Next.js 16's async `params`.
