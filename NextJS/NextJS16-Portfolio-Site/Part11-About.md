# Part 11: About / Resume Page

Now we build `/about` — a full bio page combining the `author`, `skill`, and `experience` documents, plus a downloadable resume PDF from `siteSettings`.

## Step 1: Build a SkillBadge Component

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

## Step 2: Build an ExperienceItem Component

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

## Step 3: Build the About Page

```tsx
// File: app/(site)/about/page.tsx
import type { Metadata } from "next";
import Image from "next/image";
import Container from "@/components/ui/Container";
import RichText from "@/components/ui/RichText";
import SkillBadge from "@/components/ui/SkillBadge";
import ExperienceItem from "@/components/about/ExperienceItem";
import { urlFor } from "@/sanity/image";
import { sanityFetch } from "@/sanity/fetch";
import {
  authorQuery,
  skillsQuery,
  experienceQuery,
  siteSettingsQuery,
} from "@/sanity/queries";
import type { Author, Skill, Experience, SiteSettings } from "@/sanity/types";

export const metadata: Metadata = {
  title: "About | My Portfolio",
  description: "My background, skills, and work experience.",
};

function groupByCategory(skills: Skill[]) {
  return skills.reduce<Record<string, Skill[]>>((acc, skill) => {
    const key = skill.category || "Other";
    acc[key] = acc[key] ? [...acc[key], skill] : [skill];
    return acc;
  }, {});
}

export default async function AboutPage() {
  const [author, skills, experiences, settings] = await Promise.all([
    sanityFetch<Author | null>({ query: authorQuery, tags: ["author"] }),
    sanityFetch<Skill[]>({ query: skillsQuery, tags: ["skill"] }),
    sanityFetch<Experience[]>({
      query: experienceQuery,
      tags: ["experience"],
    }),
    sanityFetch<SiteSettings | null>({
      query: siteSettingsQuery,
      tags: ["siteSettings"],
    }),
  ]);

  const grouped = groupByCategory(skills);

  return (
    <main className="py-16">
      <Container>
        <div className="mx-auto max-w-3xl">
          <div className="flex flex-col items-center gap-6 text-center sm:flex-row sm:text-left">
            {author?.photo && (
              <Image
                src={urlFor(author.photo).width(160).height(160).url()}
                alt={author.name}
                width={160}
                height={160}
                className="h-40 w-40 shrink-0 rounded-full object-cover"
              />
            )}
            <div>
              <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
                {author?.name ?? "Your Name"}
              </h1>
              <p className="mt-2 text-gray-600 dark:text-gray-300">
                {author?.shortBio}
              </p>
              {settings?.resumeUrl && (
                <a
                  href={settings.resumeUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  download
                  className="mt-4 inline-block rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700"
                >
                  Download Résumé (PDF)
                </a>
              )}
            </div>
          </div>

          {author?.longBio && (
            <section className="mt-12">
              <h2 className="text-2xl font-bold tracking-tight">Bio</h2>
              <RichText value={author.longBio} />
            </section>
          )}

          {skills.length > 0 && (
            <section className="mt-12">
              <h2 className="text-2xl font-bold tracking-tight">Skills</h2>
              <div className="mt-6 space-y-6">
                {Object.entries(grouped).map(([category, items]) => (
                  <div key={category}>
                    <h3 className="text-sm font-semibold uppercase tracking-wide text-gray-500">
                      {category}
                    </h3>
                    <div className="mt-3 flex flex-wrap gap-2">
                      {items.map((skill) => (
                        <SkillBadge key={skill._id} name={skill.name} />
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </section>
          )}

          {experiences.length > 0 && (
            <section className="mt-12">
              <h2 className="text-2xl font-bold tracking-tight">Experience</h2>
              <div className="mt-6 space-y-8">
                {experiences.map((experience) => (
                  <ExperienceItem key={experience._id} experience={experience} />
                ))}
              </div>
            </section>
          )}
        </div>
      </Container>
    </main>
  );
}
```

## Step 4: Add Test Content

In `/studio`:
1. Fill out your **Author** document's `longBio` (a paragraph or two of rich text).
2. Create a few **Skill** documents (e.g. "React" / Frameworks, "TypeScript" / Languages, "Figma" / Design).
3. Create one or two **Experience** documents with role, company, dates, and a short rich-text description.
4. Upload a PDF to **Site Settings** → **Resume (PDF)** field (any placeholder PDF works for now) and **Publish**.

## Step 5: Test It

```bash
npm run dev
```

Visit http://localhost:3000/about — you should see your photo, name, short bio, a "Download Résumé" button, your long bio, skills grouped by category, and your experience timeline.

## Checkpoint ✅

You now have:
- A fully data-driven `/about` page combining four different content types
- Skills grouped and rendered by category
- An experience timeline rendered with Portable Text descriptions
- A working resume PDF download link, served directly from Sanity's asset CDN

Commit your progress:

```bash
git add .
git commit -m "Add About/Resume page with skills and experience"
```

Next up: **Part 12: Contact Page with Free Form Handling**, where we build a working contact form using Web3Forms — no backend of our own required.
