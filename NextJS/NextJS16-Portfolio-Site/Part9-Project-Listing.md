# Part 9: Projects Listing & Dynamic Project Pages

We'll build `/projects` (a grid of all projects) and `/projects/[slug]` (an individual case study page). This part is a good showcase of **Next.js 16's async dynamic APIs** — `params` is a `Promise` you must `await`.

## Step 1: Install Portable Text Rendering

Our `project.body` and `post.body` fields are Portable Text (Sanity's rich-text format). We need a renderer:

```bash
npm install @portabletext/react
```

## Step 2: Build a Shared PortableText Renderer Component

```tsx
// File: components/ui/RichText.tsx
import { PortableText, type PortableTextComponents } from "@portabletext/react";
import Image from "next/image";
import { urlFor } from "@/sanity/image";

const components: PortableTextComponents = {
  types: {
    image: ({ value }) => (
      <div className="relative my-8 aspect-video w-full overflow-hidden rounded-lg">
        <Image
          src={urlFor(value).width(1200).url()}
          alt={value.alt || ""}
          fill
          className="object-cover"
        />
      </div>
    ),
  },
  block: {
    h2: ({ children }) => (
      <h2 className="mt-10 text-2xl font-bold tracking-tight">{children}</h2>
    ),
    h3: ({ children }) => (
      <h3 className="mt-8 text-xl font-semibold tracking-tight">{children}</h3>
    ),
    normal: ({ children }) => (
      <p className="mt-4 leading-relaxed text-gray-700 dark:text-gray-300">
        {children}
      </p>
    ),
    blockquote: ({ children }) => (
      <blockquote className="mt-4 border-l-4 border-brand-500 pl-4 italic text-gray-600 dark:text-gray-400">
        {children}
      </blockquote>
    ),
  },
  marks: {
    link: ({ children, value }) => (
      <a
        href={value?.href}
        target="_blank"
        rel="noopener noreferrer"
        className="text-brand-600 underline hover:text-brand-700 dark:text-brand-500"
      >
        {children}
      </a>
    ),
  },
  list: {
    bullet: ({ children }) => (
      <ul className="mt-4 list-disc space-y-1 pl-6">{children}</ul>
    ),
    number: ({ children }) => (
      <ol className="mt-4 list-decimal space-y-1 pl-6">{children}</ol>
    ),
  },
};

export default function RichText({ value }: { value: unknown }) {
  return <PortableText value={value as never} components={components} />;
}
```

## Step 3: Build the Projects Listing Page

```tsx
// File: app/(site)/projects/page.tsx
import type { Metadata } from "next";
import Container from "@/components/ui/Container";
import ProjectCard from "@/components/ui/ProjectCard";
import { sanityFetch } from "@/sanity/fetch";
import { allProjectsQuery } from "@/sanity/queries";
import type { Project } from "@/sanity/types";

export const metadata: Metadata = {
  title: "Projects | My Portfolio",
  description: "A collection of things I've built.",
};

export default async function ProjectsPage() {
  const projects = await sanityFetch<Project[]>({
    query: allProjectsQuery,
    tags: ["project"],
  });

  return (
    <main className="py-16">
      <Container>
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Projects
        </h1>
        <p className="mt-3 max-w-2xl text-gray-600 dark:text-gray-300">
          A collection of things I&apos;ve built, from side projects to
          production apps.
        </p>

        {projects.length === 0 ? (
          <p className="mt-10 text-gray-500">
            No projects published yet — add some in /studio!
          </p>
        ) : (
          <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {projects.map((project) => (
              <ProjectCard key={project._id} project={project} />
            ))}
          </div>
        )}
      </Container>
    </main>
  );
}
```

## Step 4: Build the Dynamic Project Detail Page

This is the key Next.js 16 pattern: the second argument to a page component (`props`) contains `params`, which is now a **Promise**. You must `await` it before reading `.slug`.

```tsx
// File: app/(site)/projects/[slug]/page.tsx
import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import Container from "@/components/ui/Container";
import RichText from "@/components/ui/RichText";
import { urlFor } from "@/sanity/image";
import { sanityFetch } from "@/sanity/fetch";
import { projectBySlugQuery, allProjectSlugsQuery } from "@/sanity/queries";
import type { Project } from "@/sanity/types";

type Props = {
  params: Promise<{ slug: string }>;
};

// Pre-render all known project pages at build time for speed.
export async function generateStaticParams() {
  const slugs = await sanityFetch<string[]>({ query: allProjectSlugsQuery });
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const project = await sanityFetch<Project | null>({
    query: projectBySlugQuery,
    params: { slug },
    tags: [`project:${slug}`],
  });

  if (!project) return { title: "Project Not Found" };

  return {
    title: `${project.title} | My Portfolio`,
    description: project.summary,
  };
}

export default async function ProjectPage({ params }: Props) {
  // In Next.js 16, params is a Promise — always await it before use.
  const { slug } = await params;

  const project = await sanityFetch<Project | null>({
    query: projectBySlugQuery,
    params: { slug },
    tags: [`project:${slug}`],
  });

  if (!project) {
    notFound();
  }

  return (
    <main className="py-16">
      <Container>
        <div className="mx-auto max-w-3xl">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
            {project.title}
          </h1>
          <p className="mt-3 text-lg text-gray-600 dark:text-gray-300">
            {project.summary}
          </p>

          {project.tags && (
            <ul className="mt-4 flex flex-wrap gap-2">
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

          <div className="mt-6 flex gap-4">
            {project.liveUrl && (
              <a
                href={project.liveUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700"
              >
                Live Site
              </a>
            )}
            {project.repoUrl && (
              <a
                href={project.repoUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-semibold hover:border-brand-600 hover:text-brand-600 dark:border-gray-700"
              >
                View Code
              </a>
            )}
          </div>

          {project.coverImage && (
            <div className="relative mt-8 aspect-video w-full overflow-hidden rounded-xl">
              <Image
                src={urlFor(project.coverImage).width(1200).url()}
                alt={project.title}
                fill
                className="object-cover"
                priority
              />
            </div>
          )}

          {project.body && <RichText value={project.body} />}
        </div>
      </Container>
    </main>
  );
}
```

### Why `params` is a Promise

Next.js 16 made `params` (and `searchParams`) asynchronous across the board — for both pages and layouts. This was done so Next.js can start streaming a route's shell before all dynamic data is resolved. In practice, this just means: **always `await params` (and `searchParams`, if used) before accessing their properties**, in both your page component and in `generateMetadata`/`generateStaticParams`-adjacent functions that receive them. We've done that consistently above.

## Step 5: Test It

```bash
npm run dev
```

Visit http://localhost:3000/projects — you should see your project(s) in a grid. Click into one — you should land on `/projects/your-slug` with the full case study, tags, links, cover image, and rendered body content.

Try visiting a nonsense slug, e.g. http://localhost:3000/projects/does-not-exist — you should see Next.js's built-in 404 page (triggered by our `notFound()` call).

## Checkpoint ✅

You now have:
- `/projects` — a listing page of all published projects
- `/projects/[slug]` — a dynamic detail page using async `params`, `generateStaticParams`, and `generateMetadata`
- A shared `RichText` component rendering Portable Text (headings, paragraphs, images, links, lists)
- Proper 404 handling via `notFound()`

Commit your progress:

```bash
git add .
git commit -m "Add projects listing and dynamic project detail pages"
```

Next up: **Part 10: Blog with Portable Text**, where we build `/blog` and `/blog/[slug]` following the same pattern.
