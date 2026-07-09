# Part 12: Contact Page with Free Form Handling

A portfolio needs a way for visitors to reach you. Rather than building/hosting our own email backend, we'll use **Web3Forms** — a free API that emails you form submissions directly, with no server of our own required.

## Step 1: Get a Free Web3Forms Access Key

1. Go to https://web3forms.com
2. Enter your email address in the "Create Access Key" box on the homepage
3. Check your email for a confirmation link and click it
4. You'll receive an **Access Key** (a UUID string) — copy it

Web3Forms's free tier includes 250 submissions/month, no credit card, no account/password needed — it just emails submissions to the address you registered.

## Step 2: Add the Access Key to Environment Variables

Add to `.env.local`:

```bash
# File: .env.local (add this line)
NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY=your_access_key_here
```

We use `NEXT_PUBLIC_` because this key is safe to expose client-side — Web3Forms access keys are designed to be used directly from browser JavaScript (they only allow sending mail to the email you verified, and rate-limit abuse).

## Step 3: Build the Contact Form as a Client Component

Since this form needs interactivity (state, submit handling) it must be a **Client Component** — marked with `"use client"` at the top of the file. This is one of the few places in our app that isn't a Server Component.

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
      {/* Honeypot field to reduce spam — hidden from real users */}
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

The hidden `botcheck` checkbox is Web3Forms' recommended honeypot spam trap — legitimate users never see or fill it (real spam bots often do), and Web3Forms silently discards submissions where it's checked.

## Step 4: Build the Contact Page

```tsx
// File: app/(site)/contact/page.tsx
import type { Metadata } from "next";
import Container from "@/components/ui/Container";
import ContactForm from "@/components/contact/ContactForm";
import { sanityFetch } from "@/sanity/fetch";
import { siteSettingsQuery } from "@/sanity/queries";
import type { SiteSettings } from "@/sanity/types";

export const metadata: Metadata = {
  title: "Contact | My Portfolio",
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

## Step 5: Add Social Links (Optional)

In `/studio`, open your **Site Settings** document, add a couple of entries to **Social Links** (e.g. platform: "GitHub", url: "https://github.com/yourusername"; platform: "LinkedIn", url: "https://linkedin.com/in/yourusername"), then **Publish**.

## Step 6: Test It

```bash
npm run dev
```

Visit http://localhost:3000/contact, fill out the form, and submit. You should see the "Thanks! Your message has been sent" success message, and — within a minute or two — an email in the inbox you registered with Web3Forms, containing the submitted name, email, and message.

## Checkpoint ✅

You now have:
- A free Web3Forms account and access key
- A working, spam-protected contact form built as a Client Component
- Real email delivery on submission, with zero backend code of our own
- Social links pulled from Sanity's Site Settings

Commit your progress (make sure `.env.local` is NOT committed — it's already gitignored):

```bash
git add .
git commit -m "Add contact page with Web3Forms integration"
```

Next up: **Part 13: Dark Mode, Navigation, Footer & UI Polish**, where we add a dark mode toggle and refine the shared UI.
