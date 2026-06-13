# Step-by-Step Tutorial: Building a Freelance Commerce Platform with React + Sanity + OpenCode + GSD + Antigravity Skills

> **Target**: Freelance consultant, trainer, and developer  
> **Stack**: React (Next.js App Router) + Sanity CMS + Tailwind CSS  
> **AI Tools**: OpenCode with GSD (Get Shit Done) + Antigravity Awesome Skills  
> **Time**: 4-6 hours for MVP  
> **Location**: Singapore-based freelance pivot

---

## Prerequisites

```bash
# Required tools
node >= 18.x
npm >= 9.x
git >= 2.x

# Install globally
npm install -g @opencode-ai/cli
npm install -g antigravity-awesome-skills

# Verify installations
opencode --version
antigravity --version
```

---

## Phase 1: Project Initialization (30 minutes)

### Step 1.1: Create the Project

```bash
# Create Next.js project with TypeScript and Tailwind
npx create-next-app@latest freelance-platform --typescript --tailwind --app --no-src-dir --import-alias "@/*"

# Navigate into project
cd freelance-platform

# Install Sanity
npm install @sanity/client @sanity/image-url @sanity/next-edge
npm install -D @sanity/cli

# Initialize Sanity
npx sanity init --env

# This will create:
# - sanity/schema.js
# - sanity/checklist.json
# - sanity/studio.config.ts
```

### Step 1.2: Create GSD Project Files

```bash
# Create docs directory
mkdir -p docs

# Create PROJECT.md
cat > docs/PROJECT.md << 'EOF'
# Project Name
Sean Wong - Freelance Consultant, Trainer, Developer

## System Intent
A freelance engineering commerce platform for consulting, training, and development that expresses expertise, documents outcomes, sells curriculum, and enables booking.

## Tech Stack
- Frontend: React + Next.js App Router
- CMS: Sanity (headless)
- Styling: Tailwind CSS
- AI Tool: OpenCode with GSD + Antigravity skills
- Deployment: Vercel

## Primary Audiences
1. Companies/CEOs (consulting)
2. Enterprise Leaders (training)
3. Product Teams/Engineering Managers (development)

## Content Types
- Service Offering (consulting, training, development)
- Case Study
- Curriculum + Modules + Labs
- Testimonial
- Package + Pricing Tier
- Booking Slot
- Article

## Success Metrics
- Booking conversion rate
- Contact form submissions
- Curriculum sign-ups
- Service page engagement
- SEO ranking for consulting/training keywords

## Constraints
- Lightweight, laptop-friendly AI solutions
- Fast iteration cycle
- Content-first architecture
- Commerce-enabled from day one
EOF

# Create ROADMAP.md
cat > docs/ROADMAP.md << 'EOF'
# Roadmap: Freelance Commerce Platform

## Milestone 1: System Intent + Content Model
- Define system intent
- Identify content types
- Map relationships
- Create PROJECT.md, ROADMAP.md, CONTEXT.md

## Milestone 2: Sanity Schemas
- Service Offering schema
- Case Study schema
- Curriculum schema
- Testimonial schema
- Package schema
- Booking Slot schema
- Article schema

## Milestone 3: React Components
- ServiceCard component
- CaseStudyAnatomy component
- CurriculumList component
- TestimonialGrid component
- PackagePricing component
- BookingForm component
- Hero section

## Milestone 4: Pages and Routing
- Home page
- Services page
- Case Studies page
- Curriculum page
- Testimonials page
- Packages page
- Booking page
- About page
- Contact page

## Milestone 5: Testing + Deployment
- Lint checks
- Component tests
- Page rendering tests
- Booking flow tests
- Deploy to Vercel

## Milestone 6: Iteration
- Add new services
- Add new courses
- Add new case studies
- Optimize conversion
- SEO improvements
EOF
```

### Step 1.3: Initialize GSD Workflow

```bash
# Run GSD project initialization in OpenCode
opencode /gsd:new-project freelance-platform

# This will create:
# - docs/PROJECT.md (already created)
# - docs/ROADMAP.md (already created)
# - docs/CONTEXT.md (auto-generated)
```

---

## Phase 2: Sanity Schema Setup (1 hour)

### Step 2.1: Create Sanity Studio Configuration

```bash
# Create sanity directory
mkdir -p sanity

# Create sanity/studio.config.ts
cat > sanity/studio.config.ts << 'EOF'
import { defineConfig } from 'sanity'
import { structureTool } from 'sanity/structure'
import { visionTool } from '@sanity/vision'

export default defineConfig({
  name: 'freelance-platform',
  title: 'Freelance Commerce Platform',
  projectId: process.env.SANITY_STUDIO_PROJECT_ID,
  dataset: process.env.SANITY_STUDIO_DATASET || 'production',
  plugins: [structureTool(), visionTool()],
})
EOF

# Create sanity/schema.ts
cat > sanity/schema.ts << 'EOF'
import { defineSchema, defineDoc } from 'sanity'

export const schema = defineSchema({
  types: [
    // Import all schemas here
    defineDoc('service'),
    defineDoc('caseStudy'),
    defineDoc('curriculum'),
    defineDoc('module'),
    defineDoc('lab'),
    defineDoc('testimonial'),
    defineDoc('package'),
    defineDoc('pricingTier'),
    defineDoc('bookingSlot'),
    defineDoc('article'),
  ],
})
EOF
```

### Step 2.2: Create Service Schema

```bash
# Create sanity/schemas/service.ts
cat > sanity/schemas/service.ts << 'EOF'
import { defineType, defineField } from 'sanity'

export const service = defineType({
  name: 'service',
  title: 'Service Offering',
  type: 'document',
  fields: [
    defineField({
      name: 'title',
      title: 'Title',
      type: 'string',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'slug',
      title: 'Slug',
      type: 'slug',
      options: { source: 'title' },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'serviceType',
      title: 'Service Type',
      type: 'string',
      options: {
        list: [
          { title: 'Consulting', value: 'consulting' },
          { title: 'Training', value: 'training' },
          { title: 'Development', value: 'development' },
        ],
      },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'problemDomain',
      title: 'Problem Domain',
      type: 'string',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'constraints',
      title: 'Constraints',
      type: 'text',
    }),
    defineField({
      name: 'architectureApproach',
      title: 'Architecture Approach',
      type: 'text',
    }),
    defineField({
      name: 'tradeoffs',
      title: 'Tradeoffs',
      type: 'text',
    }),
    defineField({
      name: 'outcomes',
      title: 'Outcomes',
      type: 'text',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'lessonsLearned',
      title: 'Lessons Learned',
      type: 'text',
    }),
    defineField({
      name: 'pricing',
      title: 'Pricing',
      type: 'string',
    }),
    defineField({
      name: 'imageUrl',
      title: 'Image URL',
      type: 'image',
    }),
    defineField({
      name: 'tags',
      title: 'Tags',
      type: 'array',
      of: [{ type: 'string' }],
    }),
  ],
  preview: {
    select: {
      title: 'title',
      media: 'imageUrl',
      serviceType: 'serviceType',
    },
  },
})
EOF
```

### Step 2.3: Create Case Study Schema

```bash
# Create sanity/schemas/caseStudy.ts
cat > sanity/schemas/caseStudy.ts << 'EOF'
import { defineType, defineField } from 'sanity'

export const caseStudy = defineType({
  name: 'caseStudy',
  title: 'Case Study',
  type: 'document',
  fields: [
    defineField({
      name: 'title',
      title: 'Title',
      type: 'string',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'slug',
      title: 'Slug',
      type: 'slug',
      options: { source: 'title' },
    }),
    defineField({
      name: 'service',
      title: 'Related Service',
      type: 'reference',
      to: [{ type: 'service' }],
    }),
    defineField({
      name: 'problem',
      title: 'Problem',
      type: 'text',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'constraints',
      title: 'Constraints',
      type: 'text',
    }),
    defineField({
      name: 'assumptions',
      title: 'Assumptions',
      type: 'text',
    }),
    defineField({
      name: 'architecture',
      title: 'Architecture',
      type: 'text',
    }),
    defineField({
      name: 'tradeoffs',
      title: 'Tradeoffs',
      type: 'text',
    }),
    defineField({
      name: 'adrs',
      title: 'Architecture Decision Records',
      type: 'text',
    }),
    defineField({
      name: 'outcomes',
      title: 'Outcomes',
      type: 'text',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'lessonsLearned',
      title: 'Lessons Learned',
      type: 'text',
    }),
    defineField({
      name: 'clientName',
      title: 'Client Name',
      type: 'string',
    }),
    defineField({
      name: 'clientIndustry',
      title: 'Client Industry',
      type: 'string',
    }),
    defineField({
      name: 'timeline',
      title: 'Timeline',
      type: 'string',
    }),
    defineField({
      name: 'imageUrl',
      title: 'Image URL',
      type: 'image',
    }),
  ],
  preview: {
    select: {
      title: 'title',
      media: 'imageUrl',
      client: 'clientName',
    },
  },
})
EOF
```

### Step 2.4: Create Curriculum Schema

```bash
# Create sanity/schemas/curriculum.ts
cat > sanity/schemas/curriculum.ts << 'EOF'
import { defineType, defineField } from 'sanity'

export const curriculum = defineType({
  name: 'curriculum',
  title: 'Curriculum',
  type: 'document',
  fields: [
    defineField({
      name: 'title',
      title: 'Title',
      type: 'string',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'slug',
      title: 'Slug',
      type: 'slug',
      options: { source: 'title' },
    }),
    defineField({
      name: 'targetAudience',
      title: 'Target Audience',
      type: 'string',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'learningObjectives',
      title: 'Learning Objectives',
      type: 'text',
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: 'modules',
      title: 'Modules',
      type: 'array',
      of: [{ type: 'reference', to: [{ type: 'module' }] }],
    }),
    defineField({
      name: 'certificationPath',
      title: 'Certification Path',
      type: 'string',
    }),
    defineField({
      name: 'duration',
      title: 'Duration',
      type: 'string',
    }),
    defineField({
      name: 'price',
      title: 'Price',
      type: 'number',
    }),
    defineField({
      name: 'imageUrl',
      title: 'Image URL',
      type: 'image',
    }),
    defineField({
      name: 'tags',
      title: 'Tags',
      type: 'array',
      of: [{ type: 'string' }],
    }),
  ],
  preview: {
    select: {
      title: 'title',
      media: 'imageUrl',
      audience: 'targetAudience',
    },
  },
})
EOF
```

### Step 2.5: Register All Schemas

```bash
# Update sanity/schema.ts to import all schemas
cat > sanity/schema.ts << 'EOF'
import { defineSchema, defineDoc } from 'sanity'
import { service } from './schemas/service'
import { caseStudy } from './schemas/caseStudy'
import { curriculum } from './schemas/curriculum'
import { module } from './schemas/module'
import { lab } from './schemas/lab'
import { testimonial } from './schemas/testimonial'
import { package } from './schemas/package'
import { pricingTier } from './schemas/pricingTier'
import { bookingSlot } from './schemas/bookingSlot'
import { article } from './schemas/article'

export const schema = defineSchema({
  types: [
    defineDoc('service', service),
    defineDoc('caseStudy', caseStudy),
    defineDoc('curriculum', curriculum),
    defineDoc('module', module),
    defineDoc('lab', lab),
    defineDoc('testimonial', testimonial),
    defineDoc('package', package),
    defineDoc('pricingTier', pricingTier),
    defineDoc('bookingSlot', bookingSlot),
    defineDoc('article', article),
  ],
})
EOF

# Create remaining schemas (module, lab, testimonial, package, pricingTier, bookingSlot, article)
# Follow the same pattern as above
```

### Step 2.6: Run Sanity Studio

```bash
# Start Sanity Studio
npx sanity dev

# This will open Sanity Studio at http://localhost:3000/studio
# You can now create and edit content
```

---

## Phase 3: React Component Setup (1.5 hours)

### Step 3.1: Create Component Directory Structure

```bash
# Create component directories
mkdir -p src/components/services
mkdir -p src/components/case-studies
mkdir -p src/components/curriculum
mkdir -p src/components/testimonials
mkdir -p src/components/packages
mkdir -p src/components/booking
mkdir -p src/components/common
```

### Step 3.2: Create ServiceCard Component

```bash
# Create src/components/services/ServiceCard.tsx
cat > src/components/services/ServiceCard.tsx << 'EOF'
import { Image } from 'next/image'
import { cn } from '@/lib/utils'

interface ServiceCardProps {
  title: string
  serviceType: 'consulting' | 'training' | 'development'
  problemDomain: string
  outcomes: string
  imageUrl?: string
  className?: string
}

export function ServiceCard({
  title,
  serviceType,
  problemDomain,
  outcomes,
  imageUrl,
  className,
}: ServiceCardProps) {
  const typeColors = {
    consulting: 'bg-blue-500',
    training: 'bg-green-500',
    development: 'bg-purple-500',
  }

  return (
    <div
      className={cn(
        'group rounded-lg border border-gray-200 bg-white p-6 shadow-sm transition-all hover:shadow-md hover:border-gray-300',
        className,
      )}
    >
      {imageUrl && (
        <Image
          src={imageUrl}
          alt={title}
          width={400}
          height={200}
          className="mb-4 rounded-lg object-cover"
        />
      )}
      
      <div className={cn('inline-block px-2 py-1 text-xs font-semibold text-white rounded', typeColors[serviceType])}>
        {serviceType.charAt(0).toUpperCase() + serviceType.slice(1)}
      </div>
      
      <h3 className="mt-3 text-xl font-bold text-gray-900">{title}</h3>
      
      <p className="mt-2 text-sm text-gray-600">{problemDomain}</p>
      
      <div className="mt-4 border-t border-gray-100 pt-4">
        <h4 className="text-sm font-semibold text-gray-900">Outcomes</h4>
        <p className="mt-1 text-sm text-gray-600">{outcomes}</p>
      </div>
    </div>
  )
}
EOF
```

### Step 3.3: Create CaseStudyAnatomy Component

```bash
# Create src/components/case-studies/CaseStudyAnatomy.tsx
cat > src/components/case-studies/CaseStudyAnatomy.tsx << 'EOF'
interface CaseStudyAnatomyProps {
  problem: string
  constraints: string
  assumptions: string
  architecture: string
  tradeoffs: string
  adrs: string
  outcomes: string
  lessonsLearned: string
  clientName?: string
  clientIndustry?: string
  timeline?: string
}

export function CaseStudyAnatomy({
  problem,
  constraints,
  assumptions,
  architecture,
  tradeoffs,
  adrs,
  outcomes,
  lessonsLearned,
  clientName,
  clientIndustry,
  timeline,
}: CaseStudyAnatomyProps) {
  return (
    <div className="space-y-6">
      {clientName && (
        <div className="flex items-center gap-2 text-sm text-gray-600">
          <span className="font-semibold">{clientName}</span>
          {clientIndustry && <span>-  {clientIndustry}</span>}
          {timeline && <span>-  {timeline}</span>}
        </div>
      )}

      <section>
        <h4 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">Problem</h4>
        <p className="mt-2 text-gray-700">{problem}</p>
      </section>

      <section>
        <h4 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">Constraints</h4>
        <p className="mt-2 text-gray-700">{constraints}</p>
      </section>

      <section>
        <h4 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">Assumptions</h4>
        <p className="mt-2 text-gray-700">{assumptions}</p>
      </section>

      <section>
        <h4 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">Architecture</h4>
        <p className="mt-2 text-gray-700">{architecture}</p>
      </section>

      <section>
        <h4 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">Tradeoffs</h4>
        <p className="mt-2 text-gray-700">{tradeoffs}</p>
      </section>

      <section>
        <h4 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">Architecture Decision Records</h4>
        <p className="mt-2 text-gray-700">{adrs}</p>
      </section>

      <section>
        <h4 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">Outcomes</h4>
        <p className="mt-2 text-gray-700">{outcomes}</p>
      </section>

      <section>
        <h4 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">Lessons Learned</h4>
        <p className="mt-2 text-gray-700">{lessonsLearned}</p>
      </section>
    </div>
  )
}
EOF
```

### Step 3.4: Create Hero Component

```bash
# Create src/components/common/Hero.tsx
cat > src/components/common/Hero.tsx << 'EOF'
interface HeroProps {
  title: string
  subtitle: string
  services: Array<{ type: string; count: number }>
}

export function Hero({ title, subtitle, services }: HeroProps) {
  return (
    <section className="bg-gradient-to-br from-gray-900 to-gray-800 py-20 text-white">
      <div className="mx-auto max-w-4xl px-6">
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">{title}</h1>
        <p className="mt-6 text-lg text-gray-300">{subtitle}</p>
        
        <div className="mt-10 flex gap-6">
          {services.map((service) => (
            <div className="rounded-lg bg-gray-800 px-4 py-2">
              <span className="text-sm font-semibold">{service.type}</span>
              <span className="ml-2 text-gray-400">{service.count}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
EOF
```

### Step 3.5: Create Other Components

```bash
# Create remaining components following the same pattern:
# src/components/curriculum/CurriculumList.tsx
# src/components/testimonials/TestimonialGrid.tsx
# src/components/packages/PackagePricing.tsx
# src/components/booking/BookingForm.tsx
```

---

## Phase 4: Pages Setup (1.5 hours)

### Step 4.1: Create Home Page

```bash
# Update src/app/page.tsx
cat > src/app/page.tsx << 'EOF'
import { Hero } from '@/components/common/Hero'
import { ServiceCard } from '@/components/services/ServiceCard'
import { client } from '@/lib/sanity'

const heroQuery = `
  {
    "services": [
      { "type": "Consulting", "count": *{ count: 1 } filter(_type == "service" && serviceType == "consulting") },
      { "type": "Training", "count": *{ count: 1 } filter(_type == "service" && serviceType == "training") },
      { "type": "Development", "count": *{ count: 1 } filter(_type == "service" && serviceType == "development") }
    ]
  }
`

export default async function Home() {
  const data = await client.query(heroQuery)
  
  return (
    <>
      <Hero
        title="Freelance Consultant, Trainer & Developer"
        subtitle="I help companies solve technical problems, teach teams modern engineering practices, and build systems with React, Next.js, and AI integration."
        services={data.services}
      />
      
      <section className="mx-auto max-w-6xl px-6 py-16">
        <h2 className="text-3xl font-bold text-gray-900">Services</h2>
        <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {/* Fetch and display services */}
        </div>
      </section>
    </>
  )
}
EOF
```

### Step 4.2: Create Services Page

```bash
# Create src/app/services/page.tsx
mkdir -p src/app/services
cat > src/app/services/page.tsx << 'EOF'
import { ServiceCard } from '@/components/services/ServiceCard'
import { client } from '@/lib/sanity'

const servicesQuery = `
  * {
    title,
    serviceType,
    problemDomain,
    outcomes,
    imageUrl
  }
`

export default async function ServicesPage() {
  const services = await client.query(servicesQuery)
  
  return (
    <div className="mx-auto max-w-6xl px-6 py-16">
      <h1 className="text-4xl font-bold text-gray-900">Services</h1>
      <p className="mt-4 text-lg text-gray-600">
        Consulting, training, and development services for companies and teams.
      </p>
      
      <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {services.map((service: any) => (
          <ServiceCard
            title={service.title}
            serviceType={service.serviceType}
            problemDomain={service.problemDomain}
            outcomes={service.outcomes}
            imageUrl={service.imageUrl}
          />
        ))}
      </div>
    </div>
  )
}
EOF
```

### Step 4.3: Create Booking Page

```bash
# Create src/app/booking/page.tsx
mkdir -p src/app/booking
cat > src/app/booking/page.tsx << 'EOF'
import { BookingForm } from '@/components/booking/BookingForm'

export default function BookingPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-4xl font-bold text-gray-900">Book a Consultation</h1>
      <p className="mt-4 text-lg text-gray-600">
        Schedule a consultation to discuss your project, training needs, or technical challenges.
      </p>
      
      <div className="mt-8">
        <BookingForm />
      </div>
    </div>
  )
}
EOF
```

### Step 4.4: Create Remaining Pages

```bash
# Create remaining pages following the same pattern:
# src/app/case-studies/page.tsx
# src/app/curriculum/page.tsx
# src/app/testimonials/page.tsx
# src/app/packages/page.tsx
# src/app/about/page.tsx
# src/app/contact/page.tsx
```

---

## Phase 5: Sanity Client Setup (30 minutes)

### Step 5.1: Create Sanity Client

```bash
# Create src/lib/sanity.ts
cat > src/lib/sanity.ts << 'EOF'
import { createClient } from '@sanity/client'
import { unstable_tryOptimize } from '@sanity/next-edge'

export const client = createClient({
  projectId: process.env.SANITY_PROJECT_ID,
  dataset: process.env.SANITY_DATASET || 'production',
  apiVersion: '2024-01-01',
  useCdn: true,
})

// Optimize for Next.js
unstable_tryOptimize(client)
EOF
```

### Step 5.2: Add Environment Variables

```bash
# Create .env.local
cat > .env.local << 'EOF'
SANITY_PROJECT_ID=your_project_id
SANITY_DATASET=production
SANITY_STUDIO_PROJECT_ID=your_project_id
SANITY_STUDIO_DATASET=production
EOF

# Create .env.example
cat > .env.example << 'EOF'
SANITY_PROJECT_ID=
SANITY_DATASET=production
SANITY_STUDIO_PROJECT_ID=
SANITY_STUDIO_DATASET=production
EOF
```

---

## Phase 6: Testing and Deployment (30 minutes)

### Step 6.1: Run Lint Checks

```bash
# Run ESLint
npm run lint

# Run TypeScript check
npm run build

# Check for Tailwind issues
npm run lint:tailwind
```

### Step 6.2: Deploy to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel deploy --prod

# Or use GitHub integration:
# 1. Push to GitHub
# 2. Connect to Vercel
# 3. Add environment variables
```

### Step 6.3: Add Vercel Environment Variables

```bash
# In Vercel dashboard, add:
SANITY_PROJECT_ID=your_project_id
SANITY_DATASET=production
```

---

## Phase 7: GSD Workflow Commands (15 minutes)

### Step 7.1: Run GSD Commands

```bash
# Initialize project
opencode /gsd:new-project freelance-platform

# Plan phase
opencode /gsd:plan-phase

# Execute phase
opencode /gsd:execute-phase

# Verify work
opencode /gsd:verify-work

# Review milestone
opencode /gsd:review
```

### Step 7.2: Invoke Antigravity Skills

```bash
# In OpenCode prompts, invoke skills:
@brainstorming
@concise-planning
@lint-and-validate
@git-pushing
@systematic-debugging
@frontend-design
@react-best-practices
@tailwind-patterns
@seo-audit
@conversion-optimization
@pricing-structure
@testimonials-integration
@case-study-structure
@booking-flow
```

---

## Phase 8: Content Creation (1 hour)

### Step 8.1: Add Services in Sanity Studio

```bash
# Open Sanity Studio
npx sanity dev

# Navigate to Studio
http://localhost:3000/studio

# Create Service entries:
# 1. Consulting Service
# 2. Training Service
# 3. Development Service
```

### Step 8.2: Add Case Studies

```bash
# Create Case Study entries with engineering anatomy:
# - Problem
# - Constraints
# - Assumptions
# - Architecture
# - Tradeoffs
# - ADRs
# - Outcomes
# - Lessons Learned
```

### Step 8.3: Add Curriculum

```bash
# Create Curriculum entries with:
# - Target audience
# - Learning objectives
# - Modules
# - Labs
# - Certification path
# - Duration
# - Price
```

---

## Quick Reference: File Structure

```
freelance-platform/
  docs/
    PROJECT.md
    ROADMAP.md
    CONTEXT.md
    PLAN.md
    PROMPTS.md
  
  sanity/
    studio.config.ts
    schema.ts
    schemas/
      service.ts
      caseStudy.ts
      curriculum.ts
      module.ts
      lab.ts
      testimonial.ts
      package.ts
      pricingTier.ts
      bookingSlot.ts
      article.ts
  
  src/
    app/
      page.tsx
      services/page.tsx
      case-studies/page.tsx
      curriculum/page.tsx
      testimonials/page.tsx
      packages/page.tsx
      booking/page.tsx
      about/page.tsx
      contact/page.tsx
    
    components/
      services/
        ServiceCard.tsx
      case-studies/
        CaseStudyAnatomy.tsx
      curriculum/
        CurriculumList.tsx
      testimonials/
        TestimonialGrid.tsx
      packages/
        PackagePricing.tsx
      booking/
        BookingForm.tsx
      common/
        Hero.tsx
    
    lib/
      sanity.ts
      utils.ts
  
  .env.local
  .env.example
  package.json
  tsconfig.json
  tailwind.config.ts
```

---

## Next Steps

1. **Add more services** – Expand your consulting, training, and development offerings
2. **Add more case studies** – Document more engineering outcomes
3. **Add more curriculum** – Create more courses and learning paths
4. **Optimize conversion** – Use @conversion-optimization to improve booking flow
5. **SEO improvements** – Use @seo-audit to optimize for search engines
6. **Add testimonials** – Use @testimonials-integration to display client quotes
7. **Iterate on pricing** – Use @pricing-structure to refine pricing tiers

---

## System Intent

**A freelance engineering commerce platform for consulting, training, and development that expresses expertise, documents outcomes, sells curriculum, and enables booking.**

Build that system.  
Then prompt.

---

## Contact

Built with:
- React + Next.js App Router
- Sanity CMS
- Tailwind CSS
- OpenCode with GSD + Antigravity skills

Authored by: Sean Wong  
Location: Singapore  
Role: Freelance Consultant, Trainer, Developer
