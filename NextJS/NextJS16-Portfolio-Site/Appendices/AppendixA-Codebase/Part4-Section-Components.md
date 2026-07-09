# Appendix A: Full Codebase Reference (4 of 8)

This note covers homepage-section components (Hero, FeaturedProjects, AboutSnippet) and the ContactForm client component.

## components/home/Hero.tsx

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

## components/home/FeaturedProjects.tsx

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

## components/home/AboutSnippet.tsx

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
              Read full bio &amp; resume &rarr;
            </Link>
          </div>
        </div>
      </Container>
    </section>
  );
}
```

## components/contact/ContactForm.tsx

```tsx
// File: components/contact/ContactForm.tsx
"use client";

import { useState, type FormEvent } from "react";

type Status = "idle" | "submitting" | "success" | "error";

export default function ContactForm() {
  const [status, setStatus] = useState<Status>("idle");

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setStatus("submitting");

    const form = e.currentTarget;
    const formData = new FormData(form);
    formData.append(
      "access_key",
      process.env.NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY || ""
    );

    try {
      const res = await fetch("https://api.web3forms.com/submit", {
        method: "POST",
        headers: { Accept: "application/json" },
        body: formData,
      });
      const result = await res.json();

      if (result.success) {
        setStatus("success");
        form.reset();
      } else {
        setStatus("error");
      }
    } catch {
      setStatus("error");
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <input type="checkbox" name="botcheck" className="hidden" style={{ display: "none" }} />

      <div>
        <label htmlFor="name" className="block text-sm font-medium">
          Name
        </label>
        <input
          id="name"
          name="name"
          type="text"
          required
          className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 dark:border-gray-700 dark:bg-gray-900"
        />
      </div>

      <div>
        <label htmlFor="email" className="block text-sm font-medium">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 dark:border-gray-700 dark:bg-gray-900"
        />
      </div>

      <div>
        <label htmlFor="message" className="block text-sm font-medium">
          Message
        </label>
        <textarea
          id="message"
          name="message"
          rows={5}
          required
          className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 dark:border-gray-700 dark:bg-gray-900"
        />
      </div>

      <button
        type="submit"
        disabled={status === "submitting"}
        className="rounded-lg bg-brand-600 px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {status === "submitting" ? "Sending..." : "Send Message"}
      </button>

      {status === "success" && (
        <p className="text-sm font-medium text-green-600 dark:text-green-500">
          Thanks! Your message has been sent — I&apos;ll get back to you soon.
        </p>
      )}
      {status === "error" && (
        <p className="text-sm font-medium text-red-600 dark:text-red-500">
          Something went wrong. Please try again or email me directly.
        </p>
      )}
    </form>
  );
}
```

Continue to **Appendix A (5 of 8)** for the root layout, globals.css, lib/metadata, site layout, and homepage route.
