# Appendix A: Full Codebase Reference (7 of 8)

This note covers: the about page and contact page.

## app/(site)/about/page.tsx

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
  title: "About",
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

## app/(site)/contact/page.tsx

```tsx
// File: app/(site)/contact/page.tsx
import type { Metadata } from "next";
import Container from "@/components/ui/Container";
import ContactForm from "@/components/contact/ContactForm";
import { sanityFetch } from "@/sanity/fetch";
import { siteSettingsQuery } from "@/sanity/queries";
import type { SiteSettings } from "@/sanity/types";

export const metadata: Metadata = {
  title: "Contact",
  description: "Get in touch with me.",
};

export default async function ContactPage() {
  const settings = await sanityFetch<SiteSettings | null>({
    query: siteSettingsQuery,
    tags: ["siteSettings"],
  });

  return (
    <main className="py-16">
      <Container>
        <div className="mx-auto max-w-xl">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Get in Touch
          </h1>
          <p className="mt-3 text-gray-600 dark:text-gray-300">
            Have a project in mind, or just want to say hi? Fill out the form
            below.
          </p>

          <div className="mt-8">
            <ContactForm />
          </div>

          {settings?.socialLinks && settings.socialLinks.length > 0 && (
            <div className="mt-10 border-t border-gray-200 pt-6 dark:border-gray-800">
              <p className="text-sm font-medium text-gray-500">
                Or find me on:
              </p>
              <ul className="mt-3 flex flex-wrap gap-4">
                {settings.socialLinks.map((link) => (
                  <li key={link.platform}>
                    <a
                      href={link.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm font-medium text-brand-600 hover:underline dark:text-brand-500"
                    >
                      {link.platform}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </Container>
    </main>
  );
}
```

Continue to **Appendix A (8 of 8)** for the API revalidate route, sitemap, robots.txt, and OG image routes.
