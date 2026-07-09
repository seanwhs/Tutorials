# Appendix A: Full Codebase Reference (6 of 8)

This note covers: projects pages and blog pages (listing + dynamic detail).

## app/(site)/projects/page.tsx

```tsx
// File: app/(site)/projects/page.tsx
import type { Metadata } from "next";
import Container from "@/components/ui/Container";
import ProjectCard from "@/components/ui/ProjectCard";
import { sanityFetch } from "@/sanity/fetch";
import { allProjectsQuery } from "@/sanity/queries";
import type { Project } from "@/sanity/types";

export const metadata: Metadata = {
  title: "Projects",
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
            No projects published yet &mdash; add some in /studio!
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

## app/(site)/projects/[slug]/page.tsx

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
    title: project.title,
    description: project.summary,
  };
}

export default async function ProjectPage({ params }: Props) {
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

## app/(site)/blog/page.tsx

```tsx
// File: app/(site)/blog/page.tsx
import type { Metadata } from "next";
import Container from "@/components/ui/Container";
import BlogCard from "@/components/ui/BlogCard";
import { sanityFetch } from "@/sanity/fetch";
import { allPostsQuery } from "@/sanity/queries";
import type { Post } from "@/sanity/types";

export const metadata: Metadata = {
  title: "Blog",
  description: "Thoughts on web development, design, and more.",
};

export default async function BlogPage() {
  const posts = await sanityFetch<Post[]>({
    query: allPostsQuery,
    tags: ["post"],
  });

  return (
    <main className="py-16">
      <Container>
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">Blog</h1>
        <p className="mt-3 max-w-2xl text-gray-600 dark:text-gray-300">
          Notes on things I&apos;m learning and building.
        </p>

        {posts.length === 0 ? (
          <p className="mt-10 text-gray-500">
            No posts published yet &mdash; add some in /studio!
          </p>
        ) : (
          <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {posts.map((post) => (
              <BlogCard key={post._id} post={post} />
            ))}
          </div>
        )}
      </Container>
    </main>
  );
}
```

## app/(site)/blog/[slug]/page.tsx

```tsx
// File: app/(site)/blog/[slug]/page.tsx
import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import Container from "@/components/ui/Container";
import RichText from "@/components/ui/RichText";
import { urlFor } from "@/sanity/image";
import { sanityFetch } from "@/sanity/fetch";
import { postBySlugQuery, allPostSlugsQuery } from "@/sanity/queries";
import type { Post } from "@/sanity/types";

type Props = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  const slugs = await sanityFetch<string[]>({ query: allPostSlugsQuery });
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = await sanityFetch<Post | null>({
    query: postBySlugQuery,
    params: { slug },
    tags: [`post:${slug}`],
  });

  if (!post) return { title: "Post Not Found" };

  return {
    title: post.title,
    description: post.excerpt,
  };
}

function formatDate(dateStr?: string) {
  if (!dateStr) return "";
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export default async function BlogPostPage({ params }: Props) {
  const { slug } = await params;

  const post = await sanityFetch<Post | null>({
    query: postBySlugQuery,
    params: { slug },
    tags: [`post:${slug}`],
  });

  if (!post) {
    notFound();
  }

  return (
    <main className="py-16">
      <Container>
        <article className="mx-auto max-w-3xl">
          <p className="text-sm font-medium uppercase tracking-wide text-gray-500">
            {formatDate(post.publishedAt)}
          </p>
          <h1 className="mt-1 text-3xl font-bold tracking-tight sm:text-4xl">
            {post.title}
          </h1>

          {post.author && (
            <div className="mt-4 flex items-center gap-3">
              {post.author.photo && (
                <Image
                  src={urlFor(post.author.photo).width(40).height(40).url()}
                  alt={post.author.name}
                  width={40}
                  height={40}
                  className="rounded-full"
                />
              )}
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                {post.author.name}
              </span>
            </div>
          )}

          {post.coverImage && (
            <div className="relative mt-8 aspect-video w-full overflow-hidden rounded-xl">
              <Image
                src={urlFor(post.coverImage).width(1200).url()}
                alt={post.title}
                fill
                className="object-cover"
                priority
              />
            </div>
          )}

          {post.body && <RichText value={post.body} />}
        </article>
      </Container>
    </main>
  );
}
```

Continue to **Appendix A (7 of 8)** for the about page and contact page.
