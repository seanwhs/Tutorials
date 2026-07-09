# Sanity Mastery - Part 0: Architecture Primer

## What Sanity Actually Is

Sanity is **not** a plug-and-play CMS like WordPress. It's a **headless content platform** made of three decoupled pieces:

| Piece | What it is | Where it lives |
|---|---|---|
| **Content Lake** | A hosted, real-time document database (JSON documents, versioned) | Sanity's cloud |
| **Studio** | An open-source, React-based content editing UI, fully customizable in code | You deploy it — or embed it directly inside Next.js at `/studio` |
| **API** (GROQ / GraphQL / REST) | How any frontend reads/writes content, CDN-cached for reads | Called from anywhere: your Next.js app, scripts, mobile apps |

```text
Content Lake (hosted, real-time JSON document DB)
   ▲ write                          ▲ write
   │                                │
Studio (editors, at /studio)   Direct API calls (migrations, scripts)
   │
   ▼ read (GROQ / GraphQL, CDN-cached)
Next.js 16 App (your frontend — Server Components, Route Handlers)
```

**Key mental model shift for beginners:** there is no fixed "posts" table with a rigid column schema. You *define* content types in code as plain JS/TS objects ("schemas"), and the entire Studio editing UI — forms, validation, relationships — is generated automatically from those schema definitions. Content itself is just JSON documents tagged with a `_type` field.

```ts
// This is literally what a Sanity document looks like on the wire — just JSON.
{
  "_id": "a1b2c3d4-...",
  "_type": "post",              // <- tells Sanity/Studio which schema this document follows
  "_createdAt": "2025-01-01T10:00:00Z",
  "_updatedAt": "2025-01-02T09:00:00Z",
  "_rev": "xyz123",             // internal revision id, used for optimistic concurrency
  "title": "Hello World",
  "slug": { "_type": "slug", "current": "hello-world" },
  "body": [ /* Portable Text blocks — covered in Part 2 */ ]
}
```

## Why Documents Are "Schemaless but Typed"

Sanity's Content Lake will happily store *any* JSON shape — there's no database-level enforcement. Structure comes entirely from:

1. **Schema definitions** (your code) — these drive the Studio's editing forms and *client-side* validation.
2. **GROQ query shapes** (your code) — you decide exactly which fields come back from a query.
3. **TypeScript types** — either hand-written or generated (Part 11) from your schemas/queries.

This is powerful because the same Content Lake can back a website, a mobile app, and an internal admin tool simultaneously — each consumer just queries the fields it needs.

## Why Sanity Pairs Well With Next.js 16

| Sanity Feature | Next.js 16 Feature | Result |
|---|---|---|
| CDN-cached GROQ reads | `fetch` caching + `next: { tags }` | Fast reads, precise on-demand invalidation (Part 4, Part 8) |
| Embedded Studio (`<NextStudio>`) | App Router catch-all routes | Zero extra hosting — editors log in at `yourapp.com/studio` |
| Draft documents (`drafts.*` ids) | Async `draftMode()` API | True live-preview editing without exposing drafts publicly (Part 7) |
| Webhooks (GROQ-filtered) | Route Handlers + `revalidateTag` | Instant published-content updates without redeploying (Part 8) |
| `sanity typegen` | TypeScript | End-to-end type safety from schema → query → component props (Part 11) |

## The Two Client "Modes" You'll Use Constantly

```ts
// Mode 1: Public, CDN-cached reads (fast, eventually-consistent, no token needed)
// Used for all normal published-content rendering.
const client = createClient({ projectId, dataset, apiVersion, useCdn: true });

// Mode 2: Authenticated, non-CDN reads (always fresh, sees drafts, needs a token)
// Used for preview/draft mode and any write operations.
const previewClient = createClient({
  projectId,
  dataset,
  apiVersion,
  useCdn: false,
  token: process.env.SANITY_API_READ_TOKEN,
  perspective: "previewDrafts", // see drafts, not just published docs
});
```

You'll see this exact split reused in Parts 4 and 7 — it's the backbone of how Sanity apps balance speed (CDN) against freshness (draft/live preview).

## Terminology Glossary (reference as you go)

| Term | Meaning |
|---|---|
| **Project** | Top-level container in Sanity's cloud; has an ID (e.g. `abc123xy`) |
| **Dataset** | A named partition of content within a project (commonly `production`, sometimes `staging`) |
| **Document** | A top-level content record with its own `_id` (e.g. a `post`, an `author`) |
| **Object** | A reusable non-document type embedded inside documents (e.g. an `address` object, `seo` object) |
| **Reference** | A pointer from one document to another (`_type: "reference", _ref: "<id>"`) — like a foreign key |
| **Portable Text** | Sanity's structured, portable rich-text format (JSON blocks, not HTML) |
| **GROQ** | "Graph-Relational Object Queries" — Sanity's native query language |
| **Studio** | The React admin app where editors create/edit content |
| **Draft** | An unpublished version of a document, stored as `drafts.<id>` alongside the published `<id>` |
| **Perspective** | Which "view" of the dataset a query uses: `published`, `previewDrafts`, or `raw` |

## Checkpoint ✅
- [ ] You understand Sanity = Content Lake + Studio + API, not a monolithic CMS
- [ ] You understand schemas drive the Studio UI, not a rigid DB schema
- [ ] You understand the CDN-client vs authenticated-client split
- [ ] You've skimmed the glossary — you'll reference it constantly in later parts

**Next: Part 1 — Project Setup (Embedding Studio in Next.js 16)**
