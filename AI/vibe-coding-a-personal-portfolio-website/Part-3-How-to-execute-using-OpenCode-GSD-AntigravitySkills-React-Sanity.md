# Part 3: How to Execute Using OpenCode + GSD + Antigravity + React + Sanity  
*The Implementation System for High-Velocity, High-Fidelity Vibe Coding*

***

## From Architecture to Living Codebase

You now have:
- **Part 1**: The philosophy—why AI development fails without architecture  
- **Part 2**: The business architecture—three planes (Content, Transactional, Experience)  

Now it's time to **execute**.

This implementation system is designed for **high-velocity, high-fidelity development**. We treat the codebase not as a stagnant file, but as an **evolving living organism** that:
- Documents every decision transparently  
- Decomposes into atomic 30-minute sprints  
- Prioritizes lift over heaviness  
- Maintains architectural integrity while vibing  

***

## The Implementation Stack

### OpenCode: Radical Transparency Protocol

OpenCode is your **radical transparency protocol** that:
- Documents every decision, dependency, and AI-generated prompt **within the codebase itself**  
- Creates `ARCHITECTURE.md` or `prompt-manifest.txt` files tracking AI's "thought process"  
- Prevents **black box syndrome** where you can't audit why code exists  
- Enables later review of AI decisions for maintenance or refactoring  

**Why this matters**: From Part 1, the Black Box Problem is when "nobody understands why the system behaves the way it does." OpenCode prevents this by making AI decisions **auditable**.

```bash
# OpenCode workflow with transparency
opencode plan --task "Generate Sanity schema"
# → Creates plan.md with decision rationale
opencode build
# → Creates prompt-manifest.txt with exact prompt used
# → Makes atomic commit with decision documented
```

**Critical rule**: Never commit code without documenting the prompt and rationale.

***

### GSD (Get Stuff Done): Tactical Execution Rhythm

GSD is your **tactical execution rhythm** that:
- Decomposes the build into **atomic, 30-minute "sprints"**  
- Enforces: "If a task takes longer than 30 minutes, it is too big"  
- Breaks tasks down until **granular enough for a single, focused AI prompt**  
- Prevents context rot through **spec-driven planning**  

**Why 30 minutes matters**: AI works best with focused, single-purpose prompts. Large tasks create hallucination risk. Small tasks create atomic, reviewable commits.

```bash
# GSD sprint decomposition
gsd plan --task "Build project page"
# Too big → breaks into:
# - Create Sanity fetcher for projects
# - Create ProjectGrid component
# - Create ProjectDetail component
# - Add SEO metadata
# - Write tests

# Each sprint = 30 minutes = 1 prompt = 1 atomic commit
```

**Critical rule**: Never prompt for tasks larger than one sprint.

***

### Antigravity: Force-Multiplier Philosophy

Antigravity is your **force-multiplier philosophy** that:
- Builds for **"lift," not "heaviness"**  
- Prioritizes **lightweight dependencies** and **clear abstractions** over feature-bloat  
- Adds **only code that directly serves conversion goals**  
- Enforces the three core principles:
  - **No Premature Abstraction**: Don't create complex generic interfaces if a simple type works  
  - **Component Minimalism**: If a component doesn't do one specific thing, split it  
  - **State Locality**: If state can live in Sanity, it stays in Sanity. If in React, keep it local. Avoid Redux/Zustand unless cross-component persistence is required  

**Why this matters**: From Part 1, "Every generated line of code creates a future maintenance obligation." Antigravity minimizes this by enforcing **cognitive overhead budget**.

***

## The Execution Workflow

To maintain architectural integrity while "vibe coding," follow this **linear progression**:

***

### Phase 1: Schema-First Initialization (Sanity)

**Before touching React, define your `sanity/schema.ts`**. If your data isn't modeled correctly, your UI will be brittle.

#### Action: Prompt AI to Generate Schema Based on Entities

```bash
# GSD plan this phase
gsd plan phase schema-initialization

# OpenCode prompt for schema generation
opencode plan --task "Generate Sanity schema for Service, Project, Inquiry, CaseStudy, Testimonial"
```

**Constraint**: All fields must have:
- Clear descriptions (for AI understanding)  
- Validation rules (for data integrity)  
- Business intent documented (for future maintenance)

#### Example: Enhanced Schema with Documentation

```typescript
// sanity/schema/service.ts
import { defineField, defineType } from 'sanity'

export default defineType({
  name: 'service',
  title: 'Service',
  type: 'document',
  // OPENCODE DECISION: Using document type for REST API access
  // RATIONALE: Services need to be queryable via API for Stripe integration
  // PROMPT: "Create Sanity schema for productized service with pricing"
  fields: [
    defineField({
      name: 'title',
      title: 'Service Title',
      type: 'string',
      // VALIDATION: Required for UI display
      validation: Rule => Rule.required().min(3).max(100),
      // DESCRIPTION: Clear name for client understanding
      description: 'e.g., "Portfolio Site in 3 Weeks" or "1-Hour Architecture Review"',
    }),
    defineField({
      name: 'slug',
      title: 'Slug',
      type: 'slug',
      options: { source: 'title' },
      // OPENCODE DECISION: Auto-generate from title for consistency
      // RATIONALE: Prevents manual slug errors, ensures SEO consistency
    }),
    defineField({
      name: 'price',
      title: 'Price (USD)',
      type: 'number',
      // VALIDATION: Required for commerce, must be non-negative
      validation: Rule => Rule.required().min(0),
      // DESCRIPTION: Business-critical field, never hardcoded in React
      description: 'Price in USD. NEVER hardcode in React components. Always fetch from Sanity.',
      // OPENCODE DECISION: Number type for Stripe API compatibility
      // RATIONALE: Stripe expects numeric values, not strings
    }),
    defineField({
      name: 'scopeDescription',
      title: 'Scope Description',
      type: 'text',
      validation: Rule => Rule.required().min(50),
      description: 'Detailed explanation of what client receives. Minimum 50 characters for clarity.',
    }),
    defineField({
      name: 'deliveryTimeframe',
      title: 'Delivery Timeframe',
      type: 'string',
      description: 'e.g., "3 weeks", "24 hours", "Monthly ongoing"',
    }),
    defineField({
      name: 'idealClient',
      title: 'Ideal Client Profile',
      type: 'text',
      description: 'Who should buy this service? e.g., "Solo founders building MVP" or "Enterprise teams needing architecture review"',
    }),
    defineField({
      name: 'ctaType',
      title: 'CTA Type',
      type: 'string',
      options: {
        list: [
          { title: 'Contact', value: 'contact' },
          { title: 'Book', value: 'book' },
          { title: 'Hire', value: 'hire' },
        ],
      },
      description: 'Determines CTA button behavior and link destination',
    }),
    defineField({
      name: 'ctaLink',
      title: 'CTA Link',
      type: 'url',
      description: 'Destination URL for CTA button. Required for ctaType !== "contact"',
    }),
    defineField({
      name: 'ctaText',
      title: 'CTA Text',
      type: 'string',
      description: 'e.g., "Book Now", "Contact Me", "Hire for Project"',
    }),
  ],
  // OPENCODE DECISION: Preview config for Sanity Studio
  // RATIONALE: Makes schema easier to navigate in Studio
  preview: {
    select: {
      title: 'title',
      price: 'price',
    },
    prepare({ title, price }) {
      return `${title} — $${price}`
    },
  },
})
```

**This is radical transparency**: Every decision, rationale, and prompt is documented inline.

***

### Phase 2: The Skeleton Build (React + Next.js)

**Build the "plumbing" before the "paint."**

#### Action: Create Layout Components + Sanity Fetcher Utility

```bash
# GSD sprint 1: Fetcher utility
gsd plan --task "Create Sanity fetcher with strict TypeScript types"
opencode plan --task "Create lib/sanity.ts with fetchQuery function and strict types"
opencode build

# GSD sprint 2: Layout components
gsd plan --task "Create root layout and page structure"
opencode plan --task "Create app/layout.tsx with metadata and Sanity client"
opencode build
```

**Antigravity Rule**: Use **strict TypeScript types** for all Sanity queries. This prevents the "undefined" runtime errors that plague most AI-generated code.

#### Example: Strict Type-Safe Fetcher

```typescript
// src/lib/sanity.ts
// OPENCODE DECISION: Using sanity-presentation for SSR + streaming
// RATIONALE: Better performance than REST API, supports streaming
// PROMPT: "Create type-safe Sanity fetcher with TypeScript interfaces"

import { createClient } from 'sanity-presentation'
import type { Project, Service, Inquiry } from '@/types/sanity'

// STRICT TYPE: Define query result interface
export interface ProjectQueryResult {
  projects: Project[]
}

export interface ServiceQueryResult {
  services: Service[]
}

// STRICT TYPE: Define fetch function signature
export async function fetchProjects(): Promise<ProjectQueryResult> {
  const client = createClient({
    projectId: process.env.SANITY_PROJECT_ID,
    dataset: process.env.SANITY_DATASET,
    token: process.env.SANITY_TOKEN,
  })

  const query = `
    {
      projects[] {
        title,
        slug,
        client,
        techStack,
        results { metric, value },
        caseStudy { title, slug },
        testimonial { clientName, quote }
      }
    }
  `

  // STRICT TYPE: Enforce result type
  const result = await client.query<ProjectQueryResult>({ query })
  return result
}

export async function fetchServices(): Promise<ServiceQueryResult> {
  const client = createClient({
    projectId: process.env.SANITY_PROJECT_ID,
    dataset: process.env.SANITY_DATASET,
    token: process.env.SANITY_TOKEN,
  })

  const query = `
    {
      services[] {
        title,
        slug,
        price,
        scopeDescription,
        deliveryTimeframe,
        idealClient,
        ctaType,
        ctaLink,
        ctaText
      }
    }
  `

  const result = await client.query<ServiceQueryResult>({ query })
  return result
}
```

#### Example: Type Definitions

```typescript
// src/types/sanity.ts
// OPENCODE DECISION: Separate type file for maintainability
// RATIONALE: Centralizes type definitions, prevents inline type duplication
// PROMPT: "Create TypeScript interfaces for Sanity content types"

export interface Project {
  title: string
  slug: { current: string }
  client: string
  techStack: string[]
  results: Array<{ metric: string; value: string; description?: string }>
  caseStudy?: { title: string; slug: { current: string } }
  testimonial?: { clientName: string; quote: string }
  duration?: string
}

export interface Service {
  title: string
  slug: { current: string }
  price: number
  scopeDescription: string
  deliveryTimeframe: string
  idealClient: string
  ctaType: 'contact' | 'book' | 'hire'
  ctaLink: string
  ctaText: string
}

export interface Inquiry {
  contactInfo: {
    name: string
    email: string
    phone?: string
  }
  budgetRange: 'low' | 'medium' | 'high' | 'enterprise'
  projectIntent: string
  serviceInterest?: Service
  timeline?: string
}
```

**Critical**: No `undefined` types. Every field is explicitly typed.

***

### Phase 3: Incremental GSD Sprints

Break development into **specific buckets**:

***

#### Bucket A: The Content Pipeline

**Implementing the `client.fetch` logic to pull from Sanity.**

```bash
# GSD sprint: ProjectGrid data layer
gsd plan --task "Create ProjectGrid with Sanity data fetching"
opencode plan --task "Create ProjectGrid component that calls fetchProjects() and renders ProjectCard"
opencode build

# GSD sprint: ServicesPage data layer
gsd plan --task "Create ServicesPage with Sanity data fetching"
opencode plan --task "Create ServicesPage component that calls fetchServices() and renders ServiceCard"
opencode build
```

**Antigravity check**: Is this component doing one specific thing? Yes. Keep it minimal.

***

#### Bucket B: The Interaction Layer

**Handling form states, input validation, and loading skeletons.**

```bash
# GSD sprint: InquiryForm validation
gsd plan --task "Create InquiryForm with validation and state management"
opencode plan --task "Create InquiryForm with useState for form data, validation function, and submit handler"
opencode build

# GSD sprint: Loading skeletons
gsd plan --task "Create loading skeletons for ProjectGrid and ServicesPage"
opencode plan --task "Create ProjectGridSkeleton and ServicesSkeleton components for loading states"
opencode build
```

**Antigravity principle**: State locality. Form state lives in the component, not global store.

***

#### Bucket C: The Commerce Bridge

**Connecting your Stripe/payment state to front-end components.**

```bash
# GSD sprint: Stripe integration
gsd plan --task "Create Stripe checkout integration for Book service"
opencode plan --task "Create API route /api/stripe/checkout that creates Stripe session and returns URL"
opencode build

# GSD sprint: CTA handler
gsd plan --task "Add Stripe checkout to ServiceCard CTA for book type"
opencode plan --task "Modify ServiceCard to call /api/stripe/checkout when ctaType === 'book'"
opencode build
```

**Antigravity check**: Is Stripe required for conversion? Yes, for paid consultations. Keep it isolated.

***

## Applying the "Antigravity" Mindset

When prompting the AI, use these **constraints** to keep code lightweight:

### 1. No Premature Abstraction

```tsx
// ❌ WRONG: Complex generic interface
interface Component<T extends Record<string, unknown>> {
  data: T
  render: (data: T) => React.ReactNode
  transform?: (data: T) => T
}

// ✅ CORRECT: Simple type
interface ProjectCardProps {
  project: Project
}
```

**Prompt constraint**: "Use simple TypeScript types, not generic interfaces. Only abstract if重用 is obvious."

***

### 2. Component Minimalism

```tsx
// ❌ WRONG: Component doing too much
export function ProjectPage() {
  const [projects, setProjects] = useState([])
  const [filter, setFilter] = useState('')
  const [search, setSearch] = useState('')
  
  useEffect(() => { fetchProjects().then(setProjects) })
  
  const filtered = projects.filter(p => 
    p.title.includes(filter) && p.client.includes(search)
  )
  
  return (
    <div>
      <input value={filter} onChange={e => setFilter(e.target.value)} />
      <input value={search} onChange={e => setSearch(e.target.value)} />
      {filtered.map(p => <ProjectCard project={p} />)}
      <Footer />
      <Newsletter />
    </div>
  )
}

// ✅ CORRECT: Split into single-purpose components
export function ProjectPage() {
  return (
    <div>
      <ProjectFilters />
      <ProjectGrid />
      <Footer />
      <Newsletter />
    </div>
  )
}

export function ProjectFilters() { /* filter logic */ }
export function ProjectGrid() { /* fetch + render */ }
export function Footer() { /* footer only */ }
export function Newsletter() { /* newsletter only */ }
```

**Prompt constraint**: "If a component does more than one thing, split it. Each component should have one responsibility."

***

### 3. State Locality

```tsx
// ❌ WRONG: Global state for simple form
const [inquiryForm] = useZustand(inquiryStore) // Global store for form

// ✅ CORRECT: Local state
export function InquiryForm() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    projectIntent: '',
  })
  // Local state is sufficient
}
```

**Prompt constraint**: "Keep state local unless cross-component persistence is required. Avoid Redux/Zustand for form data."

***

## Debugging with "OpenCode"

When code inevitably fails:

### Step 1: Audit the Prompt

```bash
# Check prompt-manifest.txt
cat prompt-manifest.txt | grep "ProjectGrid"
```

**Did you give the AI full context, or just a snippet?**

If context was incomplete:
```bash
# Re-prompt with full context
opencode plan --task "Fix ProjectGrid null error" \
  --context "Project type has optional caseStudy field, need to handle undefined" \
  --previous-prompt "Create ProjectGrid component"
```

***

### Step 2: Isolate the Plane

Determine if error is in:

| Plane | Error Type | Debug Approach |
|-------|------------|----------------|
| **Content Plane** | Query failure, schema mismatch | Check Sanity query, validate schema types |
| **Transactional Plane** | API/Stripe failure | Check API route, Stripe config, environment variables |
| **Experience Plane** | UI/Event failure | Check component state, event handlers, TypeScript types |

**Example**: ProjectGrid shows "undefined" error

```bash
# Isolate plane
# Check query: Is Sanity returning data?
# → Content Plane issue if query fails

# Check types: Is TypeScript matching schema?
# → Content Plane issue if type mismatch

# Check component: Is rendering logic correct?
# → Experience Plane issue if component bug
```

***

### Step 3: Ask AI to "Explain Like an Architect"

```bash
# If code is unclear
opencode plan --task "Explain this ProjectGrid code like an architect"
```

**Critical rule**: If you don't understand what AI wrote, **do not commit it**. Ask for explanation first.

***

## Execution Checklist

Before moving to Part 4:

| Check | Item | Verification |
|-------|------|--------------|
| ✅ | **Schema Locked** | Does your Sanity studio match your business model? |
| ✅ | **Types Defined** | Do you have interface definitions for every piece of data from Sanity? |
| ✅ | **No "Magic" Code** | If you don't understand what AI wrote, did you ask for explanation? |
| ✅ | **Prompt Manifest Created** | Does `prompt-manifest.txt` exist with all prompts documented? |
| ✅ | **Architecture.md Created** | Does `ARCHITECTURE.md` explain the three-plane model? |
| ✅ | **Sprints ≤ 30 Minutes** | Is each GSD task granular enough for one focused prompt? |
| ✅ | **No Premature Abstraction** | Are types simple, not generic interfaces? |
| ✅ | **Components Minimal** | Does each component do one specific thing? |
| ✅ | **State Local** | Is form state in component, not global store? |
| ✅ | **Business Logic in Sanity** | Are prices, services, and scope in Sanity, not React? |

***

## The Living Codebase Philosophy

Your codebase is not static. It's **evolving**:

```
Schema → Skeleton → Sprints → Debug → Document → Evolve
```

Each cycle:
1. **Schema-First**: Data model drives UI  
2. **Skeleton Build**: Plumbing before paint  
3. **GSD Sprints**: Atomic 30-minute tasks  
4. **Antigravity**: Lightweight, conversion-focused  
5. **OpenCode**: Transparent, auditable decisions  
6. **Document**: Update prompt-manifest and ARCHITECTURE.md  
7. **Evolve**: Repeat for next feature  

This prevents the "Frankenstein trap" from Part 1: functional components that have never been organized into a coherent system.

***

## Closing Perspective

You now have the **complete execution system**:

| Component | Purpose | Key Principle |
|-----------|---------|---------------|
| **OpenCode** | Radical transparency | Document every decision in codebase |
| **GSD** | Tactical execution | 30-minute atomic sprints |
| **Antigravity** | Force multiplier | Lift over heaviness |
| **Schema-First** | Data integrity | Sanity before React |
| **Skeleton Build** | Plumbing first | Types before components |
| **Incremental Sprints** | Focused prompts | One task = one prompt |
| **Debug System** | Isolate planes | Content → Transactional → Experience |

This system:
- Generates code quickly (GSD sprints)  
- Maintains architectural integrity (OpenCode transparency)  
- Prevents black box syndrome (prompt-manifest)  
- Minimizes cognitive overhead (Antigravity principles)  
- Ensures type safety (strict TypeScript)  
- Keeps business logic in Sanity (schema-first)  

In **Part 4**, you'll get the **Prompt Library**—the exact prompts to use with OpenCode for each phase, bucket, and sprint of portfolio development.

***

*Next: Part 4 — Prompt Library (exact prompts for OpenCode + GSD + Antigravity)*
