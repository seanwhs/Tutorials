# Part 5: Embedding Sanity Studio Inside the Next.js App

Instead of hosting Sanity Studio as a separate app, we'll embed it directly inside our Next.js project at `/studio`. This means one codebase, one deployment, and your content editor lives right alongside your site.

## Step 1: Install Dependencies

From your `my-portfolio` project root:

```bash
npm install sanity next-sanity @sanity/vision styled-components
```

- **`sanity`** — the core Studio package and schema builder
- **`next-sanity`** — official helpers for using Sanity inside Next.js (client, image URLs, live preview tools)
- **`@sanity/vision`** — a GROQ query-testing tool inside the Studio (handy for debugging)
- **`styled-components`** — a peer dependency the Studio UI needs

## Step 2: Set Environment Variables

Create a file named `.env.local` in your project root:

```bash
# File: .env.local
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id_here
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2024-06-01
```

Replace `your_project_id_here` with the Project ID from Part 4. Fill it in now.

> Important: `.env.local` is already listed in `.gitignore` by `create-next-app`, so it will never be committed to Git. We'll revisit environment variables fully in Appendix C and set them again on Vercel in Part 16.

## Step 3: Create the Sanity Config File

Create `sanity.config.ts` in your project root:

```ts
// File: sanity.config.ts
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { visionTool } from "@sanity/vision";
import { schemaTypes } from "./sanity/schemaTypes";

const projectId = process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!;
const dataset = process.env.NEXT_PUBLIC_SANITY_DATASET!;

export default defineConfig({
  name: "default",
  title: "My Portfolio CMS",
  basePath: "/studio",
  projectId,
  dataset,
  plugins: [structureTool(), visionTool()],
  schema: {
    types: schemaTypes,
  },
});
```

- `basePath: "/studio"` tells the Studio to expect to live at `yoursite.com/studio`
- `structureTool()` gives us the default content editing UI
- `visionTool()` adds a "Vision" tab for testing raw GROQ queries inside the Studio — very useful for development

## Step 4: Create an Empty Schema Registry (We'll Fill This in Part 6)

Create the folder and file:

```bash
mkdir -p sanity/schemaTypes
```

```ts
// File: sanity/schemaTypes/index.ts
import { type SchemaTypeDefinition } from "sanity";

export const schemaTypes: SchemaTypeDefinition[] = [
  // We'll add our document schemas here in Part 6
];
```

This keeps the app buildable right now, even with no content types defined yet.

## Step 5: Mount the Studio at `/studio`

Next.js's App Router lets us mount the entire Studio UI with a "catch-all" route. Create:

```bash
mkdir -p app/studio/[[...tool]]
```

```tsx
// File: app/studio/[[...tool]]/page.tsx
import { NextStudio } from "next-sanity/studio";
import config from "../../../sanity.config";

export const dynamic = "force-static";

export default function StudioPage() {
  return <NextStudio config={config} />;
}
```

The `[[...tool]]` folder name is a Next.js **optional catch-all route** — it matches `/studio`, `/studio/desk`, `/studio/vision`, and any other sub-path the Studio's internal router needs, all handled by this one file.

## Step 6: Add Metadata to Avoid Layout Conflicts

The Studio needs full control over its own page (no navbar/footer squeezing it). Create a dedicated layout for the studio segment:

```tsx
// File: app/studio/layout.tsx
export const metadata = {
  title: "Studio - My Portfolio CMS",
};

export default function StudioLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
```

Because this layout doesn't render `<Navbar />`/`<Footer />`, and Next.js layouts nest, we do still need to prevent the *root* layout's navbar/footer from wrapping the Studio. The cleanest fix in App Router is to use a **route group** so `/studio` opts out of the site's chrome. Let's restructure slightly:

Update `app/layout.tsx` to keep only the truly global `<html>`/`<body>` and fonts (no Navbar/Footer):

```tsx
// File: app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "My Portfolio",
  description: "Personal portfolio site built with Next.js, Tailwind CSS, and Sanity.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="antialiased font-sans">{children}</body>
    </html>
  );
}
```

Now create a route group `(site)` for all public pages, and move the Navbar/Footer wrapping there instead:

```bash
mkdir -p "app/(site)"
```

```tsx
// File: app/(site)/layout.tsx
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";

export default function SiteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen flex-col">
      <Navbar />
      <div className="flex-1">{children}</div>
      <Footer />
    </div>
  );
}
```

Move your homepage into the route group:

```bash
mkdir -p "app/(site)"
```

Move `app/page.tsx` → `app/(site)/page.tsx` (same file contents, just relocated). In VS Code: drag the file, or in terminal:

```bash
mv app/page.tsx "app/(site)/page.tsx"
```

Route groups (folders in parentheses) don't affect the URL — `app/(site)/page.tsx` is still served at `/`, but now only pages inside `(site)/` get the Navbar/Footer, while `/studio` (outside the group) does not.

Your folder structure now looks like:

```txt
app/
├── (site)/
│   ├── layout.tsx     ← Navbar + Footer wrapper
│   └── page.tsx       ← homepage, still served at "/"
├── studio/
│   ├── layout.tsx
│   └── [[...tool]]/
│       └── page.tsx
├── layout.tsx          ← root: <html>/<body>, fonts only
└── globals.css
```

## Step 7: Run It

```bash
npm run dev
```

Visit http://localhost:3000 — your homepage should look exactly as before (Navbar + Footer intact).

Now visit http://localhost:3000/studio — after a moment, you should see the Sanity Studio interface load, asking you to log in (if not already) and then showing an empty content structure (since we haven't defined schemas yet).

## Checkpoint ✅

You now have:
- Sanity Studio dependencies installed
- `.env.local` with your Project ID and dataset
- `sanity.config.ts` configured with `structureTool` and `visionTool`
- The Studio mounted and working at `/studio`
- A route group `(site)` cleanly separating your public site's layout from the Studio

Commit your progress:

```bash
git add .
git commit -m "Embed Sanity Studio at /studio route"
```

Next up: **Part 6: Designing Content Schemas**, where we'll define the actual document types — `project`, `post`, `author`, `skill`, `experience`, and `siteSettings` — that power the whole site.

---

Ready for Part 6?
