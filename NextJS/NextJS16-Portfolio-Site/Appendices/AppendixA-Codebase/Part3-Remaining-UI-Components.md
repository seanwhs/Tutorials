# Appendix A: Full Codebase Reference (3 of 8)

This note covers UI primitive components: Container, ProjectCard, BlogCard, SkillBadge, RichText, and the About/ExperienceItem component.

## components/ui/Container.tsx

```tsx
// File: components/ui/Container.tsx
import { ReactNode } from "react";

export default function Container({ children }: { children: ReactNode }) {
  return (
    <div className="mx-auto w-full max-w-5xl px-4 sm:px-6 lg:px-8">
      {children}
    </div>
  );
}
```

## components/ui/ProjectCard.tsx

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

## components/ui/BlogCard.tsx

```tsx
// File: components/ui/BlogCard.tsx
import Image from "next/image";
import Link from "next/link";
import { urlFor } from "@/sanity/image";
import type { Post } from "@/sanity/types";

function formatDate(dateStr?: string) {
  if (!dateStr) return "";
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export default function BlogCard({ post }: { post: Post }) {
  return (
    <Link
      href={`/blog/${post.slug.current}`}
      className="group block overflow-hidden rounded-xl border border-gray-200 transition-shadow hover:shadow-lg dark:border-gray-800"
    >
      {post.coverImage && (
        <div className="relative aspect-video w-full overflow-hidden bg-gray-100 dark:bg-gray-900">
          <Image
            src={urlFor(post.coverImage).width(800).height(450).url()}
            alt={post.title}
            fill
            className="object-cover transition-transform duration-300 group-hover:scale-105"
            sizes="(max-width: 768px) 100vw, 33vw"
          />
        </div>
      )}
      <div className="p-5">
        <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
          {formatDate(post.publishedAt)}
        </p>
        <h3 className="mt-1 text-lg font-semibold">{post.title}</h3>
        <p className="mt-2 line-clamp-2 text-sm text-gray-600 dark:text-gray-300">
          {post.excerpt}
        </p>
      </div>
    </Link>
  );
}
```

## components/ui/SkillBadge.tsx

```tsx
// File: components/ui/SkillBadge.tsx
export default function SkillBadge({ name }: { name: string }) {
  return (
    <span className="rounded-full border border-gray-300 px-3 py-1 text-sm font-medium text-gray-700 dark:border-gray-700 dark:text-gray-300">
      {name}
    </span>
  );
}
```

## components/ui/RichText.tsx

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

## components/about/ExperienceItem.tsx

```tsx
// File: components/about/ExperienceItem.tsx
import RichText from "@/components/ui/RichText";
import type { Experience } from "@/sanity/types";

function formatRange(start?: string, end?: string) {
  const opts: Intl.DateTimeFormatOptions = { year: "numeric", month: "short" };
  const startStr = start
    ? new Date(start).toLocaleDateString("en-US", opts)
    : "";
  const endStr = end ? new Date(end).toLocaleDateString("en-US", opts) : "Present";
  return `${startStr} — ${endStr}`;
}

export default function ExperienceItem({ experience }: { experience: Experience }) {
  return (
    <div className="border-l-2 border-gray-200 pl-6 dark:border-gray-800">
      <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
        {formatRange(experience.startDate, experience.endDate)}
      </p>
      <h3 className="mt-1 text-lg font-semibold">
        {experience.role} · {experience.company}
      </h3>
      {experience.description && <RichText value={experience.description} />}
    </div>
  );
}
```

Continue to **Appendix A (4 of 8)** for the home-section components (Hero, FeaturedProjects, AboutSnippet) and the ContactForm component.
